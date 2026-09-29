// A person's skin and clothes: the pixel texture laid on in the mesh's own space (like the rest of
// the body parts) or by its UVs (the generated body: BodyMesh), opened where wounds have torn it
// (see wounds.gdshaderinc). Included by body_skin.gdshader (one-sided) and
// body_skin_double.gdshader (open garments seen from inside: vests, brims, bandanas).

#include "res://src/bodies/shaders/wounds.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float uv_scale = 5.0;
uniform float roughness_value = 0.8;
// The generated body: texture by UV (uv_scale per UV unit), and wounds placed by the rest-pose
// position in the segment's own space, carried in CUSTOM0 (the mesh itself is skinned).
uniform bool use_uv = false;
uniform bool use_custom_pos = false;
// The eyes are wet: within eye_radius of either eyeball's centre (same space as local_pos) the
// surface is glossy, so a lamp puts a glint in them. The head's pieces only; radius 0 = none.
uniform vec3 eye_r_pos = vec3(0.0);
uniform vec3 eye_l_pos = vec3(0.0);
uniform float eye_radius = 0.0;

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = use_custom_pos ? CUSTOM0.xyz : VERTEX;
	local_normal = NORMAL;
}

vec3 triplanar(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return texture(albedo_tex, p.zy * uv_scale).rgb * w.x
			+ texture(albedo_tex, p.xz * uv_scale).rgb * w.y
			+ texture(albedo_tex, p.xy * uv_scale).rgb * w.z;
}

void fragment() {
	vec3 base = (use_uv ? texture(albedo_tex, UV * uv_scale).rgb : triplanar(local_pos, local_normal)) * tint.rgb;
	float reach = wound_reach(local_pos);
	ROUGHNESS = roughness_value;
	if (eye_radius > 0.0 && min(distance(local_pos, eye_r_pos), distance(local_pos, eye_l_pos)) < eye_radius) {
		ROUGHNESS = 0.12;
		SPECULAR = 0.9;
	}
	if (reach < 1.0) {
		if (!reduced_gore) {
			discard;
		}
		base = vec3(0.16, 0.02, 0.02);
		ROUGHNESS = 0.35;
	} else if (reach < 1.4) {
		// Torn edge: raw flesh at the lip, then soaked cloth or skin.
		float lip = step(reach, 1.15);
		base = mix(vec3(0.3, 0.03, 0.03), vec3(0.55, 0.12, 0.1), lip * (reduced_gore ? 0.0 : 1.0));
		ROUGHNESS = 0.4;
	} else if (reach < 2.2) {
		base = mix(base * vec3(0.45, 0.12, 0.1), base, (reach - 1.4) / 0.8);
	}
	ALBEDO = base;
}
