// Mosaic tiles (DESIGN.md §4, "the painting's pixels are tiles on the surfaces"): the one
// per-texel lighting for the world (texel_grid.gdshaderinc, ground.gdshader), people
// (body_skin.gdshaderinc) and props. Every texel of a surface's texture is a tile of a fixed real
// size: big up close, tiny far away, squashed on a surface seen at an angle, bending round a curve.
// Each tile is one flat colour of light: lights, shadows and fog are worked out once, at the tile's
// centre (LIGHT_VERTEX; Godot evaluates all three there in Forward+ and Compatibility), not per
// screen pixel. Ragged tiles: each tile's centre wanders a little, so tiles get the uneven edges of
// paint dabs. Two shader globals switch it for every material at once (project.godot
// [shader_globals]; Settings.tile_look, P: off / square / ragged).
//
// Use (fragment): t = UV in texels; c = tile_centre(t); sample the texture at c (one colour per
// tile); then tile_light_at(t, c, VERTEX, NORMAL, LIGHT_VERTEX, NORMAL, jump).
// Call these before any discard: they take screen derivatives.

global uniform float tile_light;
global uniform float tile_ragged;
// The smallest a tile may get on screen, in render pixels (0: no limit, tiles shrink with distance
// as they are). Where a texel would be smaller, tiles of 2, 4, 8... texels are drawn instead, each
// one colour and lit as one: the far half of the street stays chunky, as the painting's does
// (texel_grid reads the texture's mip of that size at the tile's centre; the ground snaps to it).
// Settings.min_square sets it.
global uniform float min_square_px;
// The finish (docs/ART_REVIEW.md §8.7): light is worked out this share of the way back from the
// tile's centre toward the fragment, so each tile carries a faint gradient of the real lighting
// across it (never noise). 0: flat tiles. Settings.finish sets it.
global uniform float tile_gradient;
// The surface-blocks look (docs/briefs/renderer.md; Settings.surface_blocks, M): soft block
// edges, this many render pixels of blend across a texel's edge (0: hard edges, as the looks
// above). The blend is the pixel-art anti-aliasing trick (a texel is sampled at its centre
// everywhere but within a pixel of its edge, where the sample slides to the neighbour), so a
// block edge neither pops nor shimmers as it crosses the screen's pixels, and far off, where a
// texel is smaller than a pixel, the texture's mip takes over by itself: nothing chunks.
global uniform float block_soft;
// The same look's light: each light's share cut into this many bands (gamma space; 0: smooth),
// so the light on a surface steps square by square as the paintings' does.
global uniform float light_bands;

// The texel-space point to sample at under soft edges (block_soft > 0; see above).
vec2 tile_soft_point(vec2 t) {
	vec2 w = max(fwidth(t) * block_soft, vec2(1e-5));
	vec2 f = fract(t) - 0.5;
	return floor(t) + 0.5 + clamp(f / w, vec2(-0.5), vec2(0.5));
}

// A bilinear sample of a nearest-filtered texture at texel-space point `p`: four fetches at
// the mip the fragment's own derivatives (of the texture's UV) pick, mixed by where `p` lies
// between their centres. Flat inside a texel when `p` is a tile_soft_point, blended on its edge.
vec4 tile_sample_soft(sampler2D tex, vec2 p, vec2 size, vec2 ddx, vec2 ddy) {
	vec2 q = p - 0.5;
	vec2 i = floor(q);
	vec2 f = q - i;
	vec2 o = 1.0 / size;
	vec2 base = (i + 0.5) * o;
	vec4 a = textureGrad(tex, base, ddx, ddy);
	vec4 b = textureGrad(tex, base + vec2(o.x, 0.0), ddx, ddy);
	vec4 c = textureGrad(tex, base + vec2(0.0, o.y), ddx, ddy);
	vec4 d = textureGrad(tex, base + o, ddx, ddy);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// A light's share cut into light_bands steps (even steps in gamma space); as it is when off.
float tile_band(float k) {
	if (light_bands <= 0.0) {
		return k;
	}
	float g = pow(clamp(k, 0.0, 1.0), 1.0 / 2.2);
	return pow(floor(g * light_bands + 0.5) / light_bands, 2.2);
}

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

// How many texels a side the tiles here are (1, 2, 4...): enough that one is min_square_px across
// on screen, from how many texels a screen pixel covers (by area, so a surface seen at an angle
// isn't taken by its squashed side alone). `t`: the fragment's texel-space position.
float tile_square(vec2 t) {
	if (min_square_px <= 0.0) {
		return 1.0;
	}
	vec2 tx = dFdx(t);
	vec2 ty = dFdy(t);
	float per_px = sqrt(max(abs(tx.x * ty.y - ty.x * tx.y), 1e-12));
	return exp2(clamp(ceil(log2(min_square_px * per_px)), 0.0, 6.0));
}

// Screen pixels from this fragment to the texel-space point `target`, `t` being the fragment's own
// texel-space position: the inverse of how t changes across the screen. Zero when the surface is
// edge-on. Whatever the tile look (bullet holes use it to draw in whole texels).
vec2 tile_step(vec2 t, vec2 target) {
	vec2 tx = dFdx(t);
	vec2 ty = dFdy(t);
	float det = tx.x * ty.y - ty.x * tx.y;
	if (abs(det) < 1e-12) {
		return vec2(0.0);
	}
	vec2 d = target - t;
	vec2 s = vec2(ty.y * d.x - ty.x * d.y, -tx.y * d.x + tx.x * d.y) / det;
	return clamp(s, vec2(-64.0), vec2(64.0));
}

// The same, zero when tile light is off.
vec2 tile_screen_offset(vec2 t, vec2 target) {
	return tile_step(t, target) * tile_light * (1.0 - tile_gradient);
}

// Any interpolated position (view, mesh or world space) moved by a screen step.
vec3 tile_snap(vec3 p, vec2 step) {
	return p + dFdx(p) * step.x + dFdy(p) * step.y;
}

// Moves the point (LIGHT_VERTEX) and normal that light is worked out at from this fragment to the
// tile's centre: `t` is the fragment's texel-space position, `centre` its tile's (tile_centre()).
// A quad of pixels across a seam (a UV island's edge) gives nonsense derivatives, so a jump longer
// than `max_jump` (metres) is left out.
void tile_light_at(vec2 t, vec2 centre, vec3 vertex, vec3 normal, inout vec3 light_vertex,
		inout vec3 normal_out, float max_jump) {
	vec2 s = tile_screen_offset(t, centre);
	vec3 off = dFdx(vertex) * s.x + dFdy(vertex) * s.y;
	vec3 n = normal + dFdx(normal) * s.x + dFdy(normal) * s.y;
	if (length(off) < max_jump) {
		light_vertex = vertex + off;
	}
	if (length(n - normal) < 0.4) {
		normal_out = normalize(n);
	}
}
