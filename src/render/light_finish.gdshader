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
// `shimmer_full`), only below `shimmer_top` of the frame's height (the ground and the far hills,
// not the sky overhead). Scaled by `day` (DayCycle: hot air is the noon sun's).
uniform float shimmer = 0.0;
uniform float shimmer_from = 40.0;
uniform float shimmer_full = 160.0;
uniform float shimmer_top = 0.35;
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
		float d = texture(depth_tex, uv).r;
		vec4 v = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, d, 1.0);
		float dist = -v.z / v.w;
		float far_k = smoothstep(shimmer_from, shimmer_full, dist);
		// Below the frame's top share only (screen y grows down).
		float low = smoothstep(shimmer_top - 0.1, shimmer_top + 0.05, uv.y);
		float k = shimmer * day * far_k * low;
		if (k > 0.0) {
			float y = uv.y * VIEWPORT_SIZE.y;
			float t = TIME;
			vec2 off = vec2(sin(y * 0.9 + t * 5.0) + 0.5 * sin(y * 2.3 - t * 7.3),
					0.4 * sin(y * 1.7 + t * 4.1)) * k * px;
			// Only from pixels as far off (a near post doesn't smear into the haze behind it).
			float d2 = texture(depth_tex, uv + off).r;
			vec4 v2 = INV_PROJECTION_MATRIX * vec4((uv + off) * 2.0 - 1.0, d2, 1.0);
			if (-v2.z / v2.w > shimmer_from) {
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
