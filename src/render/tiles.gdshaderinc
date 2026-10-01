// Mosaic tiles (DESIGN.md §4, "the painting's pixels are tiles on the surfaces"). Every texel of
// a surface's texture is a tile of a fixed real size: big up close, tiny far away, squashed on a
// surface seen at an angle, bending round a curve. Each tile is one flat colour of light: lights
// and shadows are worked out once, at the tile's centre (LIGHT_VERTEX), not per screen pixel.
// Ragged tiles: each tile's centre wanders a little, so tiles get the uneven edges of paint dabs.
// Two shader globals switch it for every material at once (project.godot; Settings.tile_look).
//
// Use (fragment): t = UV in texels; c = tile_centre(t); sample the texture at c (one colour per
// tile); then s = tile_screen_offset(t, c) and move LIGHT_VERTEX / NORMAL by dFdx/dFdy * s.
// Call these before any discard: they take screen derivatives.

global uniform float tile_light;
global uniform float tile_ragged;

float tile_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// The centre of the tile that texel-space point t falls in: the texel's centre, or with ragged
// tiles the nearest of the jittered centres round it (mostly square distance, a little round, so
// tiles stay blocky dabs rather than cobblestones). A centre never leaves its own texel, so a tile
// always shows its own texel's colour; only the edges between tiles move.
vec2 tile_centre(vec2 t) {
	vec2 c = floor(t);
	if (tile_ragged <= 0.0) {
		return c + 0.5;
	}
	float wander = min(tile_ragged, 0.45);
	vec2 best = c + 0.5;
	float best_d = 1e9;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cell = c + vec2(float(i), float(j));
			vec2 p = cell + 0.5 + (vec2(tile_hash(cell), tile_hash(cell + 19.19)) - 0.5) * 2.0 * wander;
			vec2 d = abs(t - p);
			float dist = max(d.x, d.y) + 0.35 * min(d.x, d.y);
			if (dist < best_d) {
				best_d = dist;
				best = p;
			}
		}
	}
	return best;
}

// Screen pixels from this fragment to the texel-space point `target`, `t` being the fragment's own
// texel-space position: the inverse of how t changes across the screen. Zero when tile light is
// off or the surface is edge-on.
vec2 tile_screen_offset(vec2 t, vec2 target) {
	vec2 tx = dFdx(t);
	vec2 ty = dFdy(t);
	float det = tx.x * ty.y - ty.x * tx.y;
	if (abs(det) < 1e-12) {
		return vec2(0.0);
	}
	vec2 d = target - t;
	vec2 s = vec2(ty.y * d.x - ty.x * d.y, -tx.y * d.x + tx.x * d.y) / det;
	return clamp(s, vec2(-64.0), vec2(64.0)) * tile_light;
}
