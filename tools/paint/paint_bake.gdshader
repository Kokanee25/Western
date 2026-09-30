shader_type spatial;
// Bakes a painted view of a person into one of his textures (tools/paint_bake.gd). The piece is
// drawn flat in its texture's own space (its UVs, inside uv_rect); each texel finds where it lands
// in the painted view (the view's camera) and takes the painting's colour there if that view really
// saw it: nothing nearer in the view's depth map, and facing the camera.
// mode 0: colour (alpha 1 where seen); mode 1: how much to trust it (facing², in red).
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled;

#include "res://tools/paint/srgb.gdshaderinc"

uniform sampler2D painted : source_color, filter_nearest, repeat_disable;
uniform sampler2D depth_map : filter_nearest, repeat_disable;
uniform mat4 view_proj;
uniform vec3 cam_pos;
// Which part of the view's frame the painted image covers (x, y, w, h in 0..1 of the frame).
uniform vec4 crop = vec4(0.0, 0.0, 1.0, 1.0);
uniform float depth_far = 4.0;
// How much further than the nearest surface a point may be and still count as seen (m).
uniform float slack = 0.012;
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform int mode = 0;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 t = (UV - uv_rect.xy) / uv_rect.zw;
	// Clip space y points down the image in Godot's Forward+ renderer (Vulkan), which the bake runs
	// on: texel row t.y lands on image row t.y.
	POSITION = vec4(t.x * 2.0 - 1.0, t.y * 2.0 - 1.0, 0.5, 1.0);
}

void fragment() {
	vec4 clip = view_proj * vec4(wpos, 1.0);
	float seen_w = 0.0;
	vec3 col = vec3(0.0);
	if (clip.w > 0.0) {
		vec2 ndc = clip.xy / clip.w;
		vec2 frame = vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
		vec2 p = (frame - crop.xy) / crop.zw;
		if (p.x >= 0.0 && p.y >= 0.0 && p.x <= 1.0 && p.y <= 1.0 && frame.x >= 0.0 && frame.y >= 0.0 && frame.x <= 1.0 && frame.y <= 1.0) {
			vec4 dm = texture(depth_map, frame);
			float nearest = (dm.r * 255.0 + dm.g) / 255.0 * depth_far;
			float facing = dot(normalize(wnrm), normalize(cam_pos - wpos));
			vec4 pc = texture(painted, p);
			// Transparent where the painting doesn't show him (its background, or past his outline).
			if (distance(wpos, cam_pos) <= nearest + slack && facing > 0.0 && pc.a > 0.5) {
				seen_w = facing * facing;
				col = pc.rgb;
			}
		}
	}
	ALBEDO = mode == 0 ? col : vec3(srgb_to_linear(seen_w));
	ALPHA = seen_w > 0.0 ? 1.0 : 0.0;
}
