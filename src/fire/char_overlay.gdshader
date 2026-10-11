shader_type spatial;
// Drawn over a member's own material as it scorches, chars and burns (docs/briefs/fire-look.md
// step 2, after docs/concept/livery-fire.png): whole squares going brown, then black, the char
// creeping over the board in broad patches; the edge where char meets sound wood glowing orange
// while it burns; and deep char cracked into checks along the grain, their seams glowing. The
// squares are the drawn wood's own (texels_per_meter, stretched along the grain as the boards'
// are), in the member's UVs (metres, the grain along U), so the char sticks to the timber as it
// falls.
render_mode blend_mix, depth_draw_never, cull_back;

uniform float char_amount : hint_range(0.0, 1.0) = 0.0;
uniform float glow : hint_range(0.0, 1.0) = 0.0;
uniform float texels_per_meter = 32.0;
// A square's length along the grain, in squares across (the drawn boards' are two to six).
uniform float along = 3.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth noise over squares: the char's broad patches.
float patches(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// The square this fragment is in: `along` times longer along the grain (U) than across.
	vec2 sq = floor(UV * texels_per_meter / vec2(along, 1.0));
	// Where the char reaches first: broad patches (about 0.3 m) with each square a little off.
	float lead = patches(sq * vec2(along, 1.0) / 9.0) * 0.88 + hash(sq) * 0.12;
	// 0 = sound, 1 = charred through. A square chars when the amount passes its lead.
	float depth = clamp((char_amount * 1.3 - (1.0 - lead)) * 3.0, 0.0, 1.0);
	float scorched = step(0.001, depth);
	vec3 brown = vec3(0.22, 0.12, 0.06);
	vec3 black = vec3(0.04, 0.032, 0.03);
	// Stepped, not blended: brown, a dark brown, black.
	vec3 col = depth < 0.34 ? brown : (depth < 0.67 ? mix(brown, black, 0.6) : black);
	// Deep char cracks into checks along the grain: the seams between them, a square wide.
	// Checks five squares long and four across, each row of them shifted along by its own amount.
	vec2 check = sq / vec2(5.0, 4.0);
	vec2 within = fract(check + vec2(hash(floor(check.yy)), 0.0));
	float seam = step(0.85, depth) * max(step(within.x, 0.19), step(within.y, 0.24)) * step(0.6, hash(sq + 3.0));
	// The burning front: a rim of squares just where char meets sound wood, while it's spreading.
	float front = scorched * (1.0 - step(0.1, depth)) * (1.0 - smoothstep(0.85, 1.0, char_amount));
	// A slow wander, not a strobe: each glowing square brightens and dims on its own.
	float wander = 0.65 + 0.35 * sin(TIME * 1.3 + hash(sq + 7.0) * 6.28);
	float hot = max(front, seam * 0.6) * glow * wander;
	ALBEDO = mix(col, vec3(0.9, 0.3, 0.05), hot * 0.6);
	ROUGHNESS = 1.0;
	EMISSION = vec3(1.0, 0.36, 0.06) * hot * 1.2;
	ALPHA = scorched;
}
