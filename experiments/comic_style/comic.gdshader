shader_type spatial;
// The comic-book trial (comic.gd): the lit frame drawn as a Western comic page. In order:
// 1. flatten: a Kuwahara filter (each pixel the mean of the most even of four windows round it),
//    so photo grain and texture squares go and edges stay sharp;
// 2. tones: lightness cut into `tones` flat steps (gamma space), hue kept, colour a little bolder;
// 3. hatching: below `hatch_from` lightness, ink lines fixed to the world (the surface's own
//    plane, from depth and normals), crossed below `cross_from`; their spacing is a few screen
//    pixels, stepped by powers of two with distance so they don't crawl;
// 4. ink: a line on every silhouette (depth jumps away) and hard crease (normals turn).
// The sky is only flattened and toned.
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest, repeat_disable;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;

uniform float flatten_px = 3.0;
uniform float tones = 4.0;
uniform float tone_soft = 0.08;      // share of a step blended at its edge (0: hard)
uniform float saturation = 1.15;
uniform float lift = 0.04;           // the darkest tone isn't black: ink is
uniform vec3 ink : source_color = vec3(0.07, 0.05, 0.045);
uniform float ink_px = 1.6;
uniform float depth_jump = 0.04;
uniform float crease = 0.6;
uniform float ink_far = 60.0;        // lines thin out past this distance (metres)
uniform float hatch_from = 0.30;     // gamma lightness under which shade is hatched
uniform float cross_from = 0.16;
uniform float hatch_px = 5.0;        // line spacing on screen, near
uniform float hatch_width = 0.32;    // share of a spacing that's ink
uniform float hatch_ink = 0.75;      // how dark a hatch line is (1: ink)
uniform vec3 paper : source_color = vec3(1.0, 0.975, 0.93);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 view_pos(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return v.xyz / v.w;
}

vec3 kuwahara(vec2 uv, vec2 px) {
	int r = int(flatten_px);
	vec3 best = texture(screen_tex, uv).rgb;
	float best_var = 1e9;
	for (int q = 0; q < 4; q++) {
		vec2 dir = vec2(q % 2 == 0 ? -1.0 : 1.0, q < 2 ? -1.0 : 1.0);
		vec3 sum = vec3(0.0);
		float s1 = 0.0;
		float s2 = 0.0;
		float n = 0.0;
		for (int y = 0; y <= r; y++) {
			for (int x = 0; x <= r; x++) {
				vec3 c = texture(screen_tex, uv + dir * vec2(float(x), float(y)) * px).rgb;
				float l = lum(c);
				sum += c;
				s1 += l;
				s2 += l * l;
				n += 1.0;
			}
		}
		float m = s1 / n;
		float v = s2 / n - m * m;
		if (v < best_var) {
			best_var = v;
			best = sum / n;
		}
	}
	return best;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec3 vp = view_pos(SCREEN_UV, INV_PROJECTION_MATRIX);
	float dist = -vp.z;
	bool sky = texture(depth_tex, SCREEN_UV).r <= 0.0000001;
	vec3 c = kuwahara(SCREEN_UV, px);
	// Tones, in gamma space, hue kept.
	vec3 g = pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
	float l = lum(g);
	float grey = l;
	g = mix(vec3(grey), g, saturation);
	float steps = sky ? max(tones * 2.0, 6.0) : tones;
	float x = l * steps;
	float f = fract(x);
	float stepped = (floor(x) + smoothstep(0.5 - tone_soft * 0.5, 0.5 + tone_soft * 0.5, f)) / steps;
	stepped = max(stepped, lift);
	g *= stepped / max(l, 1e-4);
	g *= paper;
	float ink_amt = 0.0;
	if (!sky) {
		// Hatching, fixed to the surface: the world position on the plane it mostly faces.
		vec3 wp = (INV_VIEW_MATRIX * vec4(vp, 1.0)).xyz;
		vec3 vn = texture(normal_tex, SCREEN_UV).xyz * 2.0 - 1.0;
		vec3 wn = normalize(mat3(INV_VIEW_MATRIX) * vn);
		vec3 an = abs(wn);
		vec2 p = an.x > an.y && an.x > an.z ? wp.zy : (an.y > an.z ? wp.xz : wp.xy);
		// Spacing: hatch_px screen pixels where this is, stepped to a power of two in metres.
		float pix_m = dist * 2.0 / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
		float spacing = exp2(ceil(log2(max(hatch_px * pix_m, 1e-4))));
		if (l < hatch_from) {
			float u = (p.x + p.y) / spacing;
			float line = step(1.0 - hatch_width, fract(u));
			float k = smoothstep(hatch_from, hatch_from - 0.06, l);
			ink_amt = max(ink_amt, line * k * hatch_ink);
		}
		if (l < cross_from) {
			float u = (p.x - p.y) / spacing;
			float line = step(1.0 - hatch_width, fract(u));
			float k = smoothstep(cross_from, cross_from - 0.05, l);
			ink_amt = max(ink_amt, line * k * hatch_ink);
		}
		// Ink lines on silhouettes and creases.
		float edge = 0.0;
		float t = ink_px * mix(1.0, 0.5, smoothstep(ink_far * 0.5, ink_far, dist));
		for (int i = 0; i < 4; i++) {
			vec2 dir = vec2(i == 0 ? 1.0 : (i == 1 ? -1.0 : 0.0), i == 2 ? 1.0 : (i == 3 ? -1.0 : 0.0));
			vec2 uv = SCREEN_UV + dir * px * t;
			float dn = -view_pos(uv, INV_PROJECTION_MATRIX).z;
			if (dn - dist > depth_jump * dist) {
				edge = 1.0;
			}
			vec3 nn = texture(normal_tex, uv).xyz * 2.0 - 1.0;
			if (dot(vn, nn) < crease && abs(dn - dist) < depth_jump * dist * 2.0) {
				edge = max(edge, 0.85);
			}
		}
		ink_amt = max(ink_amt, edge);
	}
	vec3 lin = pow(max(g, vec3(0.0)), vec3(2.2));
	ALBEDO = mix(lin, ink, ink_amt);
	ALPHA = 1.0;
}
