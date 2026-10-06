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
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.2;
// Never coarsened into bigger squares far off (min_square_px): a sign's lettering has to stay
// legible down the street, as the painting's does.
uniform bool fixed_squares = false;
// A cube-built mesh: light each face where the fragment is, not at the texel's centre (VoxelTrial).
uniform bool cube_faces = false;
// The surface-blocks look: the colour the lower bands of light lean toward (wood's half-light a
// warm brown, not grey); white = none. PixelArt.material sets it per material.
uniform vec3 shade_tint : source_color = vec3(1.0);

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

void fragment() {
	vec2 size = vec2(textureSize(albedo_tex, 0));
	vec4 col;
	// The texture coordinates whose texels the lighting snaps to: the UVs, or for triplanar the
	// projection that faces this surface most.
	vec2 grid_uv;
	vec2 uv_scale = vec2(texels_per_meter) / size;
	float b = 1.0;
	bool soft = block_soft > 0.0;
	if (mapping == 0) {
		grid_uv = UV * uv_scale + uv_offset.xy;
		b = fixed_squares || soft ? 1.0 : tile_square(grid_uv * size);
		if (soft) {
			col = tile_sample_soft(albedo_tex, tile_soft_point(grid_uv * size), size, dFdx(grid_uv), dFdy(grid_uv));
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
		} else if (b > 1.0) {
			col = square_sample(uv_z, size, b) * tri_weights.z + square_sample(uv_y, size, b) * tri_weights.y + square_sample(uv_x, size, b) * tri_weights.x;
		} else {
			col = grid_sample(uv_z) * tri_weights.z + grid_sample(uv_y) * tri_weights.y + grid_sample(uv_x) * tri_weights.x;
		}
	}
	vec2 texel = grid_uv * size;
	// Where the light is worked out: the tile's centre, or under soft edges the soft point, so the
	// light too slides from one block's to the next across the edge.
	vec2 centre = soft ? tile_soft_point(texel) : (b > 1.0 ? (floor(texel / b) + 0.5) * b : tile_centre(texel));
	float edge = 1.0;
	if (mapping == 0 && UV2.x > 0.0) {
		// Members (MemberMesh) carry their face's size in metres in UV2; the face runs from UV 0
		// to it. Keep the point the light is worked out at on this face: a face thinner than a
		// texel (a plank's edge) would otherwise be lit from a point off it, above the plank and
		// out of its neighbour's shadow.
		vec2 lo = uv_offset.xy * size;
		vec2 hi = lo + UV2 * uv_scale * size;
		vec2 inset = min(vec2(0.25 * b), (hi - lo) * 0.5);
		centre = clamp(centre, lo + inset, hi - inset);
		// Which texel of the face this is, from its near corner: the first and last row are the
		// board's edges.
		vec2 at = UV * texels_per_meter;
		vec2 across = UV2 * texels_per_meter;
		if (b > 1.0) {
			// In big squares: the square's own place, the line a square wide and fainter.
			at = (centre / size - uv_offset.xy) / uv_scale * texels_per_meter;
		}
		float line = b > 1.0 ? b * 0.5 : 1.0;
		float shade = b > 1.0 ? mix(edge_shade, 1.0, 0.5) : edge_shade;
		if (at.y < line || at.y > across.y - line) {
			edge = shade;
		} else if (at.x < line || at.x > across.x - line) {
			edge = mix(shade, 1.0, 0.4);
		}
		// The line between boards is a line, not a row of squares: the painting draws it a pixel
		// or so wide and dark however far off the wall is, while its squares grow with distance
		// (and ours coarsen into bigger squares, min_square_px, where a texel-wide line went faint
		// and dotted). So within a screen pixel and a half of a long edge, the dark line, always.
		if (seam_px > 0.0) {
			float v_px = min(UV.y, UV2.y - UV.y) / max(fwidth(UV.y), 1e-6);
			if (v_px < seam_px) {
				edge = min(edge, seam_shade);
			}
		}
	}
	if (tile_ragged > 0.0 && b <= 1.0 && !soft) {
		// Ragged tiles: one colour a tile, its own texel's, so the edges between colours wander too.
		vec2 g = centre / size;
		col = use_mipmaps ? textureGrad(albedo_tex, g, dFdx(grid_uv), dFdy(grid_uv)) : textureLod(albedo_tex, g, 0.0);
	}
	vec3 albedo = col.rgb * tint.rgb * edge;
	// A cube-built mesh (the voxel trial, VoxelTrial): each cube face is its own tile, far smaller
	// than a texel, so the light stays where the fragment is (the texel's centre would be off the
	// face, inside the thing, and in its shadow).
	if (!cube_faces) {
		tile_light_at(texel, centre, VERTEX, NORMAL, LIGHT_VERTEX, NORMAL, 0.15 * b);
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
