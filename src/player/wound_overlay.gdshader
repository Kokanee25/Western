shader_type canvas_item;
// The player's wounds on screen: a red flash when hit, the edges closing in grey-red with shock,
// a throb with pain, black when passing out. Drawn into the low-res game view.

uniform float flash = 0.0;
uniform float shock = 0.0;
uniform float pain = 0.0;
uniform float black = 0.0;

void fragment() {
	vec2 d = UV - 0.5;
	d.x *= 1.6;
	float edge = smoothstep(0.35 - shock * 0.25, 0.95, length(d));
	float throb = pain * (0.55 + 0.45 * sin(TIME * 5.0)) * 0.35;
	float a = flash * (0.18 + 0.55 * edge) + (shock * 0.85 + throb) * edge;
	vec3 red = mix(vec3(0.5, 0.02, 0.0), vec3(0.08, 0.05, 0.05), shock);
	vec4 c = vec4(red, clamp(a, 0.0, 1.0));
	COLOR = mix(c, vec4(0.0, 0.0, 0.0, 1.0), black);
}
