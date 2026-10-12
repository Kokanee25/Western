shader_type spatial;
// The painterly trial's grade (grade.gd): over the finished frame, in order,
// 1. brush: a Kuwahara filter of brush_px (each pixel the mean of the most even of four windows
//    round it), so surfaces read as flat dabs with crisp edges; 0 = off;
// 2. grade: shadows lifted toward a warm brown and highlights toward cream (a split tone), a
//    gentle S-curve, colour a little richer;
// 3. a soft vignette and a fine, still grain (the same each frame: grain that moves reads as noise).
// Writes ALPHA (the rule for anything full-screen that reads the screen texture).
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;

uniform float brush_px = 0.0;
uniform vec3 shadow_tint : source_color = vec3(0.30, 0.20, 0.14);
uniform float shadow_lift = 0.035;
uniform vec3 high_tint : source_color = vec3(1.0, 0.93, 0.80);
uniform float high_mix = 0.12;
uniform float contrast = 1.08;
uniform float saturation = 1.06;
uniform float vignette = 0.28;
uniform float grain = 0.025;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 kuwahara(vec2 uv, vec2 px, int r) {
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

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec3 c = brush_px >= 1.0 ? kuwahara(SCREEN_UV, px, int(brush_px)) : texture(screen_tex, SCREEN_UV).rgb;
	// Grade in gamma space.
	vec3 g = pow(max(c, vec3(0.0)), vec3(1.0 / 2.2));
	float l = lum(g);
	g = mix(vec3(l), g, saturation);
	g = (g - 0.5) * contrast + 0.5;
	g += shadow_tint * shadow_lift * (1.0 - smoothstep(0.0, 0.45, l));
	g = mix(g, g * high_tint, high_mix * smoothstep(0.4, 1.0, l));
	vec2 d = SCREEN_UV - 0.5;
	g *= 1.0 - vignette * smoothstep(0.25, 0.85, dot(d, d) * 2.2);
	g += (hash(floor(SCREEN_UV * VIEWPORT_SIZE)) - 0.5) * grain;
	ALBEDO = pow(clamp(g, vec3(0.0), vec3(1.0)), vec3(2.2));
	ALPHA = 1.0;
}
