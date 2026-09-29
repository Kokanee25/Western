shader_type spatial;
// Drawn over a member's own material as it scorches, chars and burns: blackened patches that
// spread in texel-sized pixels as the char deepens, and glowing embers flickering in them while
// it burns. Coordinates are the mesh's own, in metres, so it sticks to the timber as it falls.
render_mode blend_mix, depth_draw_never, cull_back;

uniform float char_amount : hint_range(0.0, 1.0) = 0.0;
uniform float glow : hint_range(0.0, 1.0) = 0.0;
uniform float texels_per_meter = 40.0;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void fragment() {
	vec3 q = floor(local_pos * texels_per_meter);
	float fine = hash(q);
	float coarse = hash(floor(local_pos * texels_per_meter * 0.2));
	float coverage = step(1.0 - char_amount * 1.35, fine * 0.45 + coarse * 0.55);
	vec3 scorched = vec3(0.2, 0.12, 0.07);
	vec3 charcoal = vec3(0.035, 0.03, 0.028);
	ALBEDO = mix(scorched, charcoal, clamp(char_amount * 1.6, 0.0, 1.0));
	ROUGHNESS = 1.0;
	// Embers: the odd dull-red glowing pixel in deep char, not a pattern over the whole board.
	float flick = floor(TIME * 1.2 + fine * 5.0);
	float deep = smoothstep(0.55, 0.9, char_amount);
	float ember = step(0.975, hash(q + vec3(flick))) * glow * coverage * deep;
	EMISSION = vec3(0.75, 0.16, 0.02) * ember * 0.9;
	ALPHA = max(coverage * min(char_amount * 2.2 + 0.25, 1.0), ember);
}
