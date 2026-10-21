// The shared material for everything on the texel grid (PixelArt.material()): a small pixel-art
// texture tiled at PixelArt.texels_per_meter with nearest filtering, each texel a tile lit as one
// colour (tiles.gdshaderinc, P: off / square / ragged). Members' UVs are in metres with the grain
// along u; blockouts and props map by position instead (triplanar, like StandardMaterial3D's).
// Included by texel_grid.gdshader and, with HOLES defined, by member_holes.gdshader.

#include "res://src/render/tiles.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
// Offset of the texture, in repeats (0..1 of the texture). The texture repeats every
// texels_per_meter / its own size metres (code-painted textures are 64 square, the texture
// factory's any size), so every texel is the same size whatever texture it's in.
uniform vec3 uv_offset = vec3(0.0);
uniform float texels_per_meter = 40.0;
// Off: every texel crisp all the way out (the chunky texel presets).
uniform bool use_mipmaps = true;
// 0: the mesh's UVs; 1: triplanar in mesh space; 2: triplanar in world space.
uniform int mapping = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
// Members' board edges: the texels along a face's long edges this much darker (the line between
// two boards the painting draws on every plank), the ends a little less; 1 = no line.
uniform float edge_shade : hint_range(0.0, 1.0) = 0.7;
// The painting's seam: within this many screen pixels of a member face's long edges, this dark
// (global: set by the look; 0 = off, only the texel-wide line above).
global uniform float seam_px;
uniform float seam_shade : hint_range(0.0, 1.0) = 0.45;
uniform float seam_lip : hint_range(1.0, 2.0) = 1.3;
// A member's long edges as the exterior wood sheet draws a board's: the near one (v 0) a lit lip,
// the far one the dark seam (edge_shade), each a texel row of the board's own; 0 = both shaded
// alike, as before. The material lab's woods only (PixelArt.lab).
uniform float edge_lip : hint_range(0.0, 2.0) = 0.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.2;
// Never coarsened into bigger squares far off (min_square_px): a sign's lettering has to stay
// legible down the street, as the painting's does.
uniform bool fixed_squares = false;
// Texels a side of the squares the texture is drawn in, each one colour (the mean of its texels)
// and lit as one: the man's painted squares (roadmap 1.4, "surfaces to the man": the game's woods
// are 128 texels a metre, their squares 4 of them, 32 a metre, his face's and coat's 36-48). A
// whole power of two (the mip lines up with the squares). 1: every texel its own, as before.
uniform float square_texels = 1.0;
// End grain's squares, texels of end_tex a side (its rings are finer than the long faces' squares).
uniform float end_square_texels = 1.0;
// A cube-built mesh: light each face where the fragment is, not at the texel's centre (VoxelTrial).
uniform bool cube_faces = false;
// The surface-blocks look: the colour the lower bands of light lean toward (wood's half-light a
// warm brown, not grey); white = none. PixelArt.material sets it per material.
uniform vec3 shade_tint : source_color = vec3(1.0);

// The material lab's end grain (2026-10-14, LabGeometry): faces its meshes flag as a member's cut
// ends (COLOR r 1, g 0) are drawn from this texture, at the same density; off everywhere else.
uniform sampler2D end_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool use_end_tex = false;
varying float end_face;
// The material lab (lab3): a painted board's paint worn through to `wear_tex` (its bare wood)
// within about `end_wear` m of the board's own ends, ragged row by row (0: never). Long faces of
// flagged (LabGeometry) members only, which carry their face's length in UV2.x.
uniform sampler2D wear_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform float end_wear = 0.0;
varying float lab_face;
// lab4: end grain at its own density (texels a metre; 0: texels_per_meter), and each flagged
// member's long faces starting `lab_u0` m along its strip (COLOR.b x 2 m: LabGeometry's per-member
// offset, so members sharing a strip don't show the same knot at the same place).
uniform float end_texels = 0.0;
varying float lab_u0;
// The board's edge lines at least a screen pixel wide (material lab round 3, 2026-10-21): a
// texel-wide line on a fine wood (384 a metre: 2.6 mm) is under a pixel past a metre or two and
// broke into dashes as it fell on and off the pixels' centres (both blind critics' "black dashes
// along the seams"). On: the line a pixel wide where a texel is smaller, as dark as the share of
// that pixel the texel row covers (never under half: the painting draws every seam). The material
// lab's sets only, until Sean picks a wood.
uniform bool edge_aa = false;

// Weathering as a layer of the building, not the board (material lab round 3, Sean 2026-10-21;
// docs/briefs/material-lab.md): mud splashed up from the ground across several boards, rain
// streaks hanging from a drip line (an eave, a deck's edge, a tread's nosing) and from nail heads,
// grime gathered low and at the ends, the sun's bleach on what faces the sky. One fetch of a
// painted stain sheet (`weather_tex`, masks not colour: R mud splash, G streaks, B grime, A bleach;
// tools/textures/stain_sheet.py), laid in the structure's own space (the mesh's), the same shapes
// running across neighbouring boards whatever their wood or strip; the colours are the set's (one
// muddy palette for every wood). Only on members that ask: their meshes carry CUSTOM0 (ground y,
// drip line y, amount, 0) and CUSTOM1 (nail pitch along, first nail, row pitch, first row y) in
// mesh space (MaterialStand; production: docs/briefs/material-lab.md); amount 0 = none, no fetch.
uniform sampler2D weather_tex : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform bool use_weather = false;
// The sheet's size on the building, metres a side.
uniform float weather_metres = 3.0;
// The stains' colours: mud laid over (mix), streaks and grime multiplied, the bleach a tint about
// the board's own grey.
uniform vec3 weather_mud : source_color = vec3(0.36, 0.27, 0.19);
uniform vec3 weather_streak : source_color = vec3(0.62, 0.56, 0.50);
uniform vec3 weather_grime : source_color = vec3(0.58, 0.50, 0.43);
uniform vec3 weather_bleach : source_color = vec3(0.80, 0.78, 0.74);
// How strong each is (mud, streaks, grime, bleach), 0-1.
uniform vec4 weather_amounts = vec4(0.8, 0.6, 0.6, 0.5);
// How far each reaches, metres: mud up from the ground, streaks down from the drip line, grime up
// from the ground, a nail's streak down from its head.
uniform vec4 weather_reach = vec4(0.8, 1.2, 1.1, 0.25);
// Each stain's cover stepped into this many tones (the men's paint: a few close tones with clean
// edges between them); 0 = smooth.
uniform float weather_tones = 3.0;
varying vec4 weather_frame;
varying vec4 weather_nails;
varying vec3 weather_n;

varying vec3 tri_pos;
varying vec3 tri_weights;
varying vec3 local_pos;

#ifdef HOLES
uniform int hole_count = 0;
uniform vec4 hole_a[16]; // entry.xyz (member space), radius
uniform vec4 hole_b[16]; // exit.xyz (member space), 1 = went through

float seg_dist(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-8), 0.0, 1.0);
	return length(p - (a + ab * t));
}
#endif

void vertex() {
	local_pos = VERTEX;
	end_face = use_end_tex && COLOR.g < 0.5 ? COLOR.r : 0.0;
	lab_face = use_end_tex && COLOR.g < 0.5 ? 1.0 - COLOR.r : 0.0;
	lab_u0 = lab_face > 0.5 ? COLOR.b * 2.0 : 0.0;
	weather_frame = use_weather ? CUSTOM0 : vec4(0.0);
	weather_nails = use_weather ? CUSTOM1 : vec4(0.0);
	weather_n = NORMAL;
	// Triplanar textures are square: one scale for every axis.
	float uv_scale = texels_per_meter / float(textureSize(albedo_tex, 0).x);
	if (mapping == 2) {
		tri_weights = abs(mat3(MODEL_MATRIX) * NORMAL);
		tri_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv_scale + uv_offset;
	} else {
		tri_weights = abs(NORMAL);
		tri_pos = VERTEX * uv_scale + uv_offset;
	}
	tri_weights /= dot(tri_weights, vec3(1.0));
	tri_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 grid_sample(vec2 uv) {
	return use_mipmaps ? texture(albedo_tex, uv) : textureLod(albedo_tex, uv, 0.0);
}

// The colour of the square of `b` texels that uv falls in: the one texel at its centre, so a far
// square keeps the texture's own contrast (the painting's far squares are a mosaic of distinct
// shades; the mip's average of the square read as plain, smooth 3D).
vec4 square_sample(vec2 uv, vec2 size, float b) {
	vec2 c = (floor(uv * size / b) + 0.5) * b / size;
	return textureLod(albedo_tex, c, 0.0);
}

// How much of a stain shows where its painted mask is `m` and where it belongs `env` (0-1): the
// place sets the mask's threshold, so far from the ground only the biggest splashes still reach
// (shapes thin out, they don't fade), stepped into weather_tones tones.
float weather_cover(float m, float env) {
	float c = smoothstep(1.0 - env, 1.0 - env + 0.3, m) * step(0.001, env);
	return weather_tones > 0.0 ? floor(c * weather_tones + 0.35) / weather_tones : c;
}

// The board's colour `c0` weathered where it is on its building (`p`, `n`: mesh space; `uv1`, `uv2`:
// the face's UV and size, for its ends).
vec3 weathered(vec3 c0, vec3 p, vec3 n, vec3 dpx, vec3 dpy, vec2 uv1, vec2 uv2) {
	vec3 c = c0;
	float h = p.y - weather_frame.x;
	float d = weather_frame.y - p.y;
	float side = 1.0 - abs(n.y);
	float sky = clamp(n.y, 0.0, 1.0);
	// Walls by height above their ground (the sheet's foot on the ground), along whichever way the
	// face runs; decks and undersides flat in plan.
	float along = abs(n.x) > abs(n.z) ? p.z : p.x;
	bool planar = abs(n.y) > 0.5;
	bool run_z = abs(n.x) > abs(n.z);
	vec2 uv = planar ? p.xz : vec2(along, -h);
	// Its screen derivatives from the position's, taken outside the branch this runs in.
	vec2 gx = planar ? dpx.xz : vec2(run_z ? dpx.z : dpx.x, -dpx.y);
	vec2 gy = planar ? dpy.xz : vec2(run_z ? dpy.z : dpy.x, -dpy.y);
	vec4 m = textureGrad(weather_tex, uv / weather_metres, gx / weather_metres, gy / weather_metres);
	// Sun-bleach on what faces the sky, and a little on walls away from their drip line's shade:
	// greyer and a touch lighter, never white.
	float bleach = weather_cover(m.a, max(sky, side * 0.45 * smoothstep(0.1, 0.8, d))) * weather_amounts.w;
	float grey = dot(c, vec3(0.3, 0.55, 0.15));
	c = mix(c, grey * weather_bleach / max(dot(weather_bleach, vec3(0.3, 0.55, 0.15)), 1e-3) * 1.06, bleach * 0.7);
	// Grime gathered low and toward a face's ends (the corners boards meet in), a little everywhere.
	float ends = uv2.x > 0.0 ? 1.0 - smoothstep(0.0, 0.3, min(uv1.x - lab_u0, uv2.x - (uv1.x - lab_u0))) : 0.0;
	float low = 1.0 - smoothstep(0.0, weather_reach.z, h);
	float grime = weather_cover(m.b, max(max(low * 0.85, ends * 0.45), 0.2)) * weather_amounts.z;
	c *= mix(vec3(1.0), weather_grime, grime);
	// Rain streaks hanging from the drip line above, on walls.
	float streak = d >= 0.0 ? weather_cover(m.g, (1.0 - smoothstep(0.0, weather_reach.y, d)) * side) : 0.0;
	// And from nail heads: a short soft drip under some of them, its strength the sheet's streaks'.
	if (weather_nails.x > 0.0 && weather_nails.z > 0.0 && side > 0.5) {
		float k = floor((along - weather_nails.y) / weather_nails.x + 0.5);
		float j = ceil((p.y - weather_nails.w) / weather_nails.z);
		for (int r = 0; r < 2; r++) {
			float dn = weather_nails.w + (j + float(r)) * weather_nails.z - p.y;
			// About one nail in four bleeds, each driven a little off the stud's line.
			float rnd = fract(sin(dot(vec2(k, j + float(r)), vec2(12.9898, 78.233))) * 43758.5453);
			float lucky = step(0.75, rnd);
			float dx = abs(along - (weather_nails.y + k * weather_nails.x + (fract(rnd * 17.0) - 0.5) * 0.02));
			float w = 0.01 + 0.02 * dn;
			float drip = (1.0 - smoothstep(w * 0.4, w, dx)) * (1.0 - smoothstep(0.0, weather_reach.w, dn)) * lucky;
			streak = max(streak, drip * (0.5 + 0.5 * m.g) * step(0.0, dn));
		}
	}
	c *= mix(vec3(1.0), weather_streak, streak * weather_amounts.y);
	// Mud splashed up from the ground, over everything, on walls (and a little on decks).
	float mud = weather_cover(m.r, (1.0 - smoothstep(0.0, weather_reach.x, h)) * mix(0.3, 1.0, side)) * weather_amounts.x;
	return mix(c0, mix(c, weather_mud, mud), clamp(weather_frame.z, 0.0, 1.0));
}

void fragment() {
	bool endf = end_face > 0.5;
	vec2 size = vec2(endf ? textureSize(end_tex, 0) : textureSize(albedo_tex, 0));
	vec4 col;
	// The texture coordinates whose texels the lighting snaps to: the UVs, or for triplanar the
	// projection that faces this surface most.
	vec2 grid_uv;
	vec2 uv_scale = vec2(endf && end_texels > 0.0 ? end_texels : texels_per_meter) / size;
	float b = 1.0;
	bool soft = block_soft > 0.0;
	// The squares the texture is drawn in (square_texels, end_square_texels), texels a side.
	float sq = soft ? 1.0 : max(endf ? end_square_texels : square_texels, 1.0);
	if (mapping == 0 && endf) {
		grid_uv = UV * uv_scale + uv_offset.xy;
		if (sq > 1.0) {
			col = tile_block_sample(end_tex, grid_uv * size, size, vec2(sq), use_mipmaps);
		} else {
			col = use_mipmaps ? texture(end_tex, grid_uv) : textureLod(end_tex, grid_uv, 0.0);
		}
	} else if (mapping == 0) {
		grid_uv = UV * uv_scale + uv_offset.xy;
		b = fixed_squares || soft ? 1.0 : tile_square(grid_uv * size);
		if (soft) {
			col = tile_sample_soft(albedo_tex, tile_soft_point(grid_uv * size), size, dFdx(grid_uv), dFdy(grid_uv));
		} else if (sq > 1.0) {
			col = tile_block_sample(albedo_tex, grid_uv * size, size, vec2(max(b, sq)), use_mipmaps);
		} else {
			col = b > 1.0 ? square_sample(grid_uv, size, b) : grid_sample(grid_uv);
		}
	} else {
		vec2 uv_z = tri_pos.xy;
		vec2 uv_y = tri_pos.xz;
		vec2 uv_x = tri_pos.zy * vec2(-1.0, 1.0);
		if (tri_weights.z >= tri_weights.y && tri_weights.z >= tri_weights.x) {
			grid_uv = uv_z;
		} else if (tri_weights.y >= tri_weights.x) {
			grid_uv = uv_y;
		} else {
			grid_uv = uv_x;
		}
		b = fixed_squares || soft ? 1.0 : tile_square(grid_uv * size);
		if (soft) {
			col = tile_sample_soft(albedo_tex, tile_soft_point(uv_z * size), size, dFdx(uv_z), dFdy(uv_z)) * tri_weights.z
					+ tile_sample_soft(albedo_tex, tile_soft_point(uv_y * size), size, dFdx(uv_y), dFdy(uv_y)) * tri_weights.y
					+ tile_sample_soft(albedo_tex, tile_soft_point(uv_x * size), size, dFdx(uv_x), dFdy(uv_x)) * tri_weights.x;
		} else if (sq > 1.0) {
			vec2 bs = vec2(max(b, sq));
			col = tile_block_sample(albedo_tex, uv_z * size, size, bs, use_mipmaps) * tri_weights.z
					+ tile_block_sample(albedo_tex, uv_y * size, size, bs, use_mipmaps) * tri_weights.y
					+ tile_block_sample(albedo_tex, uv_x * size, size, bs, use_mipmaps) * tri_weights.x;
		} else if (b > 1.0) {
			col = square_sample(uv_z, size, b) * tri_weights.z + square_sample(uv_y, size, b) * tri_weights.y + square_sample(uv_x, size, b) * tri_weights.x;
		} else {
			col = grid_sample(uv_z) * tri_weights.z + grid_sample(uv_y) * tri_weights.y + grid_sample(uv_x) * tri_weights.x;
		}
	}
	if (end_wear > 0.0 && mapping == 0 && lab_face > 0.5 && UV2.x > 0.0) {
		// Which end, how far from it, and a ragged reach a texel row (and a little a texel).
		vec2 tx = floor(UV * texels_per_meter / sq);
		float far_end = UV.x - lab_u0 > UV2.x * 0.5 ? 1.0 : 0.0;
		float d = far_end > 0.5 ? UV2.x - (UV.x - lab_u0) : UV.x - lab_u0;
		float row = fract(sin(dot(vec2(tx.y, far_end + floor(UV2.x * 7.0)), vec2(12.9898, 78.233))) * 43758.5453);
		float cell = fract(sin(dot(tx, vec2(39.346, 11.135))) * 24634.6345);
		if (d < end_wear * row * row * (0.7 + 0.6 * cell)) {
			if (sq > 1.0) {
				col = tile_block_sample(wear_tex, grid_uv * size, size, vec2(max(b, sq)), use_mipmaps);
			} else {
				col = use_mipmaps ? texture(wear_tex, grid_uv) : textureLod(wear_tex, grid_uv, 0.0);
			}
		}
	}
	vec3 dpx = dFdx(local_pos);
	vec3 dpy = dFdy(local_pos);
	if (use_weather && weather_frame.z > 0.0) {
		col.rgb = weathered(col.rgb, local_pos, normalize(weather_n), dpx, dpy, UV, UV2);
	}
	vec2 texel = grid_uv * size;
	// Where the light is worked out: the tile's centre, or under soft edges the soft point, so the
	// light too slides from one block's to the next across the edge.
	// With drawn squares (sq), the square's centre: lit as one, as the man's squares are.
	float lb = max(b, sq);
	vec2 centre = soft ? tile_soft_point(texel) : (lb > 1.0 ? (floor(texel / lb) + 0.5) * lb : tile_centre(texel));
	float edge = 1.0;
	// Texels of the board a screen pixel covers, along and across (edge_aa), outside the branch.
	vec2 at_px = max(fwidth((UV - vec2(lab_u0, 0.0)) * texels_per_meter), vec2(1e-4));
	if (mapping == 0 && UV2.x > 0.0) {
		// Members (MemberMesh) carry their face's size in metres in UV2; the face runs from UV 0
		// to it. Keep the point the light is worked out at on this face: a face thinner than a
		// texel (a plank's edge) would otherwise be lit from a point off it, above the plank and
		// out of its neighbour's shadow.
		vec2 lo = (uv_offset.xy + vec2(lab_u0, 0.0) * uv_scale) * size;
		vec2 hi = lo + UV2 * uv_scale * size;
		vec2 inset = min(vec2(0.25 * lb), (hi - lo) * 0.5);
		centre = clamp(centre, lo + inset, hi - inset);
		// Which texel of the face this is, from its near corner: the first and last row are the
		// board's edges.
		vec2 at = (UV - vec2(lab_u0, 0.0)) * texels_per_meter;
		vec2 across = UV2 * texels_per_meter;
		if (b > 1.0) {
			// In big squares: the square's own place, the line a square wide and fainter.
			at = (centre / size - uv_offset.xy) / uv_scale * texels_per_meter;
		}
		float line = b > 1.0 ? b * 0.5 : 1.0;
		float shade = b > 1.0 ? mix(edge_shade, 1.0, 0.5) : edge_shade;
		float lip = mix(edge_lip, 1.0, b > 1.0 ? 0.5 : 0.0);
		// edge_aa: at least a pixel wide (texels a pixel, at_px), as strong as its share of it.
		vec2 lw = vec2(line);
		vec2 strength = vec2(1.0);
		if (edge_aa) {
			lw = max(lw, at_px);
			strength = clamp(vec2(line) / at_px, vec2(0.5), vec2(1.0));
		}
		if (edge_lip > 0.0 && at.y < lw.y) {
			edge = mix(1.0, lip, strength.y);
		} else if (at.y < lw.y || at.y > across.y - lw.y) {
			edge = mix(1.0, shade, strength.y);
		} else if (at.x < lw.x || at.x > across.x - lw.x) {
			edge = mix(1.0, mix(shade, 1.0, 0.4), strength.x);
		}
		// The line between boards is a line, not a row of squares: the painting draws it a pixel
		// or so wide and dark however far off the wall is, while its squares grow with distance
		// (and ours coarsen into bigger squares, min_square_px, where a texel-wide line went faint
		// and dotted). So within a screen pixel and a half of a long edge, the dark line, always.
		// One long edge (the top of a lap board: v runs up a member's face) takes the dark line, the
		// other a lit lip a pixel wide, as the painting draws a board's edge catching the sun, so
		// boards stand off the wall rather than being lines drawn on it.
		if (seam_px > 0.0) {
			float px = max(fwidth(UV.y), 1e-6);
			if ((UV2.y - UV.y) / px < seam_px) {
				edge = seam_shade;
			} else if (UV.y / px < seam_px) {
				edge = seam_lip;
			} else if (at.y < line || at.y > across.y - line) {
				edge = 1.0;  // the seam's line and lip do the edge's work here
			}
		}
	}
	if (tile_ragged > 0.0 && lb <= 1.0 && !soft && !endf) {
		// Ragged tiles: one colour a tile, its own texel's, so the edges between colours wander too.
		vec2 g = centre / size;
		col = use_mipmaps ? textureGrad(albedo_tex, g, dFdx(grid_uv), dFdy(grid_uv)) : textureLod(albedo_tex, g, 0.0);
	}
	vec3 albedo = col.rgb * tint.rgb * edge;
	// A cube-built mesh (the voxel trial, VoxelTrial): each cube face is its own tile, far smaller
	// than a texel, so the light stays where the fragment is (the texel's centre would be off the
	// face, inside the thing, and in its shadow).
	if (!cube_faces) {
		tile_light_at(texel, centre, VERTEX, NORMAL, LIGHT_VERTEX, NORMAL, 0.15 * lb);
	}
#ifdef HOLES
	// Bullet holes, tested at the centre of the texel (so they're drawn in whole texels).
	// Holes that went right through are cut out, so you see — and the sun shines — through
	// them; the ones that stopped inside are dark pits. Fresh splintered wood rings each.
	vec3 p = tile_snap(local_pos, tile_step(texel, floor(texel) + 0.5));
	float min_r = 1.05 / texels_per_meter;
	for (int i = 0; i < hole_count; i++) {
		float r = max(hole_a[i].w, min_r);
		bool through = hole_b[i].w > 0.5;
		float d = through ? seg_dist(p, hole_a[i].xyz, hole_b[i].xyz) : length(p - hole_a[i].xyz);
		if (d < r) {
			if (through) {
				discard;
			}
			albedo *= 0.12;
		} else if (d < r * 2.2) {
			// raw splintered wood round the hole, much paler than the weathered surface
			albedo = mix(albedo, vec3(0.78, 0.66, 0.48), 0.8);
		}
	}
#endif
	ALBEDO = albedo;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
}

#ifdef BLOCKS
// The surface-blocks look's light (texel_grid_blocks.gdshader, member_holes_blocks.gdshader):
// Lambert cut into light_bands per light (the bands' sum is banded too, so the whole direct light
// steps), the lower bands leaning toward the material's shade_tint; a small banded highlight.
void light() {
	float k = tile_band(clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION);
	DIFFUSE_LIGHT += k * LIGHT_COLOR * mix(shade_tint, vec3(1.0), k) / PI;
	vec3 h = normalize(VIEW + LIGHT);
	float s = pow(clamp(dot(NORMAL, h), 0.0, 1.0), mix(64.0, 8.0, ROUGHNESS)) * specular * 0.5;
	SPECULAR_LIGHT += tile_band(s * ATTENUATION) * LIGHT_COLOR / PI;
}
#endif
