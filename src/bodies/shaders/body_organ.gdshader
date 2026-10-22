shader_type spatial;
// What's inside a torn-open body part (muscle, organs, vessels, bones), drawn only where it's seen
// through an opening (wounds.gdshaderinc sight_through): built to the anatomy's size, it would
// otherwise show through a man slimmer than it (experiments/body_lab, the blood look).

#include "res://src/bodies/shaders/wounds.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0);
uniform float roughness_v = 0.35;
uniform float sight_slack = 1.25;

varying vec3 local_pos;
varying vec3 eye_local;

void vertex() {
	local_pos = VERTEX;
	eye_local = (inverse(MODEL_MATRIX) * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
}

void fragment() {
	if (reduced_gore || sight_through(eye_local, local_pos) > sight_slack) {
		discard;
	}
	ALBEDO = texture(albedo_tex, UV * uv_scale).rgb;
	ROUGHNESS = roughness_v;
}
