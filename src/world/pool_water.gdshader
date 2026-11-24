shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
// Still water in a spring's box or a trough (#1160): a dark green-brown body a little clear at the
// edges, a slow ripple in the normal (sums of sines in the world's x/z, nothing sampled) and the
// sky's reflection at grazing angles by Schlick's fresnel; not a mirror head-on.
uniform vec3 body : source_color = vec3(0.13, 0.17, 0.13);
uniform float clarity : hint_range(0.0, 1.0) = 0.72;
uniform float ripple : hint_range(0.0, 1.0) = 0.35;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME;
	vec2 p = wpos.xz;
	float a = sin(p.x * 9.0 + t * 0.7) + sin(p.y * 11.0 - t * 0.55) + sin((p.x + p.y) * 6.0 + t * 0.4);
	float b = sin(p.x * 13.0 - t * 0.6 + 1.3) + sin(p.y * 7.0 + t * 0.8) + sin((p.x - p.y) * 10.0 - t * 0.5);
	vec3 n = vec3(a * 0.04 * ripple, b * 0.04 * ripple, 1.0);
	NORMAL_MAP = normalize(n) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
	float f = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 4.0);
	ALBEDO = body;
	ROUGHNESS = 0.14;
	SPECULAR = 0.55 + 0.4 * f;
	METALLIC = 0.0;
	ALPHA = mix(0.96, clarity, 0.6) + 0.15 * f;
}
