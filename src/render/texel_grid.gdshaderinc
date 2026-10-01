// The shared material for everything on the texel grid (PixelArt.material()): a small pixel-art
// texture tiled at PixelArt.texels_per_meter with nearest filtering, lit per texel when
// texel lighting is on (texel_lighting.gdshaderinc). Members' UVs are in metres with the grain
// along u; blockouts and props map by position instead (triplanar, like StandardMaterial3D's).
// Included by texel_grid.gdshader and, with HOLES defined, by member_holes.gdshader.

#include "res://src/render/texel_lighting.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
// Texture repeats per metre: texels_per_meter / texture size.
uniform float uv_scale = 0.625;
uniform vec3 uv_offset = vec3(0.0);
uniform float texels_per_meter = 40.0;
// Off: every texel crisp all the way out (the chunky texel presets).
uniform bool use_mipmaps = true;
// 0: the mesh's UVs; 1: triplanar in mesh space; 2: triplanar in world space.
uniform int mapping = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.95;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.2;

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

void fragment() {
	vec2 size = vec2(textureSize(albedo_tex, 0));
	vec4 col;
	// The texture coordinates whose texels the lighting snaps to: the UVs, or for triplanar the
	// projection that faces this surface most.
	vec2 grid_uv;
	if (mapping == 0) {
		grid_uv = UV * uv_scale + uv_offset.xy;
		col = grid_sample(grid_uv);
	} else {
		vec2 uv_z = tri_pos.xy;
		vec2 uv_y = tri_pos.xz;
		vec2 uv_x = tri_pos.zy * vec2(-1.0, 1.0);
		col = grid_sample(uv_z) * tri_weights.z + grid_sample(uv_y) * tri_weights.y + grid_sample(uv_x) * tri_weights.x;
		if (tri_weights.z >= tri_weights.y && tri_weights.z >= tri_weights.x) {
			grid_uv = uv_z;
		} else if (tri_weights.y >= tri_weights.x) {
			grid_uv = uv_y;
		} else {
			grid_uv = uv_x;
		}
	}
	vec3 albedo = col.rgb * tint.rgb;
	vec2 texel = grid_uv * size;
	vec2 centre = floor(texel) + 0.5;
	if (mapping == 0 && UV2.x > 0.0) {
		// Members (MemberMesh) carry their face's size in metres in UV2; the face runs from UV 0
		// to it. Keep the point the light is worked out at on this face: a face thinner than a
		// texel (a plank's edge) would otherwise be lit from a point off it, above the plank and
		// out of its neighbour's shadow.
		vec2 lo = uv_offset.xy * size;
		vec2 hi = lo + UV2 * uv_scale * size;
		vec2 inset = min(vec2(0.25), (hi - lo) * 0.5);
		centre = clamp(centre, lo + inset, hi - inset);
	}
	vec2 to_centre = texel_step_to(texel, centre);
#ifdef HOLES
	// Bullet holes, tested at the centre of the texel (so they're drawn in whole texels).
	// Holes that went right through are cut out, so you see — and the sun shines — through
	// them; the ones that stopped inside are dark pits. Fresh splintered wood rings each.
	vec3 p = texel_snap(local_pos, to_centre);
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
	if (texel_lighting) {
		LIGHT_VERTEX = texel_snap(VERTEX, to_centre);
	}
}
