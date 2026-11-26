shader_type spatial;
// The light pass's finish (issue #318, LightFinish): a soft vignette, a fine film grain, and heat
// shimmer on what's far off in the day (the far street, the mesa). A full-screen quad the game
// camera carries, drawn in the transparent pass (it writes ALPHA: the screen texture only exists
// there; see depth_mosaic.gdshader). The grain is by luminance, strongest in the mid tones, as
// film's is; the shimmer moves the far pixels a little, sideways and up, in bands that rise, the
// way hot air over a road wobbles the picture behind it (the idea only: a refraction offset).
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
// 0 none; the corners this much darker (a smooth fall from `vignette_from` of the half-diagonal).
uniform float vignette = 0.0;
uniform float vignette_from = 0.45;
// Grain: the noise's share of the pixel's light (render pixels, re-cut `grain_fps` a second).
uniform float grain = 0.0;
uniform float grain_fps = 24.0;
// Shimmer: render pixels of wobble at full strength, past `shimmer_from` metres (full at
// `shimmer_full`), only below `shimmer_top` of the frame's height, and only on level ground seen
// low over the horizon (#1266; never a building). Scaled by `day` (DayCycle: hot air is the noon sun's).
uniform float shimmer = 0.0;
uniform float shimmer_from = 40.0;
uniform float shimmer_full = 160.0;
uniform float shimmer_top = 0.35;
// The ground only (#1266): how level a surface must be (its normal's up share), how far under the
// horizon the view may look (the sine of the angle), and how far the light it borrows may stand
// above or below it (m).
uniform float shimmer_flat = 0.9;
uniform float shimmer_band = 0.06;
uniform float shimmer_rise = 0.4;
uniform float day = 1.0;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p.yx + 19.19);
	return fract((p.x + p.y) * p.x);
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / VIEWPORT_SIZE;
	if (shimmer > 0.0 && day > 0.0) {
		// Only hot ground seen low over the horizon (#1266, Sean's walk: the church and the other
		// buildings zig-zagged): a mirage's wobble is the air over a sunlit flat bending the light
		// that grazes it. So a pixel wobbles only where what it shows is (1) past `shimmer_from`,
		// (2) ground: its surface faces up (`shimmer_flat`, from the depth's own screen slopes), and
		// (3) seen at a grazing angle, the view ray less than `shimmer_band` (its sine) under the
		// horizon; and it takes its light only from a pixel that's the same ground (as far, as level,
		// within `shimmer_rise` m of its height), so a wall never moves and never smears into the
		// ground. Below `shimmer_top` of the frame's height as before.
		float d = texture(depth_tex, uv).r;
		vec4 v = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, d, 1.0);
		vec3 vp = v.xyz / v.w;
		float dist = -vp.z;
		vec3 wp = (INV_VIEW_MATRIX * vec4(vp, 1.0)).xyz;
		vec3 ray = normalize(mat3(INV_VIEW_MATRIX) * vp);
		vec3 wn = normalize(mat3(INV_VIEW_MATRIX) * cross(dFdx(vp), dFdy(vp)));
		float far_k = smoothstep(shimmer_from, shimmer_full, dist);
		float low = smoothstep(shimmer_top - 0.1, shimmer_top + 0.05, uv.y);
		float flat_k = smoothstep(shimmer_flat - 0.05, shimmer_flat + 0.03, abs(wn.y));
		float graze = smoothstep(0.0, 0.004, -ray.y) * (1.0 - smoothstep(shimmer_band * 0.6, shimmer_band, -ray.y));
		float k = shimmer * day * far_k * low * flat_k * graze;
		if (k > 0.0) {
			float y = uv.y * VIEWPORT_SIZE.y;
			float t = TIME;
			vec2 off = vec2(sin(y * 0.9 + t * 5.0) + 0.5 * sin(y * 2.3 - t * 7.3),
					0.4 * sin(y * 1.7 + t * 4.1)) * k * px;
			float d2 = texture(depth_tex, uv + off).r;
			vec4 v2 = INV_PROJECTION_MATRIX * vec4((uv + off) * 2.0 - 1.0, d2, 1.0);
			vec3 vp2 = v2.xyz / v2.w;
			vec3 wp2 = (INV_VIEW_MATRIX * vec4(vp2, 1.0)).xyz;
			if (-vp2.z > shimmer_from && abs(wp2.y - wp.y) < shimmer_rise) {
				uv += off;
			}
		}
	}
	vec3 c = texture(screen_tex, uv).rgb;
	if (vignette > 0.0) {
		vec2 q = (SCREEN_UV - 0.5) * vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0);
		float r = length(q) / length(vec2(VIEWPORT_SIZE.x / VIEWPORT_SIZE.y, 1.0) * 0.5);
		c *= 1.0 - vignette * smoothstep(vignette_from, 1.0, r);
	}
	if (grain > 0.0) {
		float frame = floor(TIME * grain_fps);
		float n = hash(floor(FRAGCOORD.xy) + frame * vec2(17.0, 59.0)) - 0.5;
		float lum = dot(c, vec3(0.2126, 0.7152, 0.0722));
		// Film grain shows most in the mid tones: none in black, less in the brightest.
		float mid = smoothstep(0.0, 0.25, lum) * (1.0 - 0.5 * smoothstep(0.6, 2.0, lum));
		c *= 1.0 + n * grain * 2.0 * mid;
	}
	ALBEDO = c;
	ALPHA = 1.0;
}
