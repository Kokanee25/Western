// The game's tonemap undone: colours a shader wants to land on screen as written (a painted man, a
// lamp's glowing glass) are turned into the scene colour Godot's ACES maps to them. Shared by
// body_skin.gdshaderinc and src/props/chimney_glass.gdshader.

// Godot 4.7's ACES (servers/rendering/renderer_rd/shaders/effects/tonemap.glsl, white 1.0), inverted:
// the scene-linear colour it maps to `c` (linear, 0..1).
vec3 aces_inverse(vec3 c) {
	const float KA = 0.0245786;
	const float KB = 0.000090537;
	const float KC = 0.983729;
	const float KD = 0.432951;
	const float KE = 0.238081;
	const float WHITE = 0.781071;  // the curve at 1.8 (white 1.0 × the exposure bias)
	const mat3 RGB_TO_RRT = mat3(
			vec3(0.59719 * 1.8, 0.35458 * 1.8, 0.04823 * 1.8),
			vec3(0.07600 * 1.8, 0.90834 * 1.8, 0.01566 * 1.8),
			vec3(0.02840 * 1.8, 0.13383 * 1.8, 0.83777 * 1.8));
	const mat3 ODT_TO_RGB = mat3(
			vec3(1.60475, -0.53108, -0.07367),
			vec3(-0.10208, 1.10813, -0.00605),
			vec3(-0.00327, -0.07276, 1.07602));
	vec3 t = clamp((c * WHITE) * inverse(ODT_TO_RGB), vec3(0.0), vec3(1.0));
	// (u² + Au − B) / (Cu² + Du + E) = t, for u.
	vec3 a = 1.0 - t * KC;
	vec3 b = KA - t * KD;
	vec3 u = (-b + sqrt(b * b + 4.0 * a * (KB + t * KE))) / (2.0 * a);
	return max(u * inverse(RGB_TO_RRT), vec3(0.0));
}

vec3 to_srgb(vec3 c) {
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

vec3 from_srgb(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
