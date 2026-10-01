// Texel-space lighting: light, shadows and fog worked out once per texture texel, at the texel's
// centre, instead of once per screen pixel, so every texel shows as one flat lit colour (the
// blocks in docs/concept/). Godot evaluates lights, shadows and fog at LIGHT_VERTEX, so a
// material moves LIGHT_VERTEX to the centre of the texel the fragment shows:
//     LIGHT_VERTEX = texel_light_vertex(texel, VERTEX);
// `texel` is the fragment's position in texels (texture coordinates × texture size).
// A triangle is flat, so position is an affine function of texel coordinates over it; the screen
// derivatives of both give that map exactly, and the step to the texel's centre goes through it.
// Switched for every material at once by the global `texel_lighting` (Settings.texel_lighting).

global uniform bool texel_lighting;

// The step across the screen, in pixels (x, y), from this fragment to `target` (in texels).
vec2 texel_step_to(vec2 texel, vec2 target) {
	vec2 tx = dFdx(texel);
	vec2 ty = dFdy(texel);
	float det = tx.x * ty.y - tx.y * ty.x;
	if (abs(det) < 1e-12) {
		return vec2(0.0); // edge-on: no texel grid to speak of
	}
	vec2 d = target - texel;
	return vec2(d.x * ty.y - d.y * ty.x, tx.x * d.y - tx.y * d.x) / det;
}

// The step to the centre of this fragment's texel.
vec2 texel_centre_step(vec2 texel) {
	return texel_step_to(texel, floor(texel) + 0.5);
}

// Any interpolated position (view, mesh or world space) moved by that step.
vec3 texel_snap(vec3 p, vec2 step) {
	return p + dFdx(p) * step.x + dFdy(p) * step.y;
}

vec3 texel_light_vertex(vec2 texel, vec3 vertex) {
	if (!texel_lighting) {
		return vertex;
	}
	return texel_snap(vertex, texel_centre_step(texel));
}
