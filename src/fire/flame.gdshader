shader_type spatial;
// A flame: a billboard sprite in the particle's colour, drawn a little towards the camera so it sits
// in front of the board it's burning on instead of being cut off by it (walls further in front still
// hide it). Additive, unlit, pixel texture.
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D sprite : source_color, filter_nearest;
uniform float toward_camera = 0.22;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view_pos.xyz += normalize(-view_pos.xyz) * toward_camera;
	POSITION = PROJECTION_MATRIX * view_pos;
}

void fragment() {
	vec4 t = texture(sprite, UV);
	ALBEDO = t.rgb * COLOR.rgb;
	ALPHA = t.a * COLOR.a;
}
