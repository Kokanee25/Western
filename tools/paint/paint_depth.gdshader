shader_type spatial;
// A view's depth map for tools/paint_bake.gd: distance from the camera over depth_far, in 16 bits
// across red (high byte) and green (low byte), so the bake can tell what the view really saw.
render_mode unshaded, cull_back, shadows_disabled;

#include "res://tools/paint/srgb.gdshaderinc"

uniform float depth_far = 4.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = clamp(distance(wpos, CAMERA_POSITION_WORLD) / depth_far, 0.0, 0.99999) * 255.0;
	float hi = floor(d) / 255.0;
	float lo = fract(d);
	ALBEDO = vec3(srgb_to_linear(hi), srgb_to_linear(lo), 0.0);
}
