shader_type spatial;
// The inside wall of a torn-open body part, seen through the opening: wet dark flesh, drawn from
// inside (front faces culled), and opened too where a wound goes right through.
render_mode cull_front;

#include "res://src/bodies/shaders/wounds.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform float uv_scale = 5.0;

// Seen only through an opening: the line of sight within this many of its radii of one.
uniform float sight_slack = 1.25;

varying vec3 local_pos;
varying vec3 eye_local;

void vertex() {
	local_pos = VERTEX;
	eye_local = (inverse(MODEL_MATRIX) * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
}

void fragment() {
	if (wound_reach(local_pos) < 1.0 || sight_through(eye_local, local_pos) > sight_slack) {
		discard;
	}
	vec3 flesh = texture(albedo_tex, local_pos.xy * uv_scale + local_pos.z * 0.37 * uv_scale).rgb;
	ALBEDO = flesh;
	ROUGHNESS = 0.3;
	SPECULAR = 0.6;
}
