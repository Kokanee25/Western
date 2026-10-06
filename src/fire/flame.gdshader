shader_type spatial;
// A flame: a billboard tongue from the drawn flipbook (tools/textures/draw_flames.py,
// docs/briefs/fire-look.md step 1), solid colour as drawn, drawn a little towards the camera so it
// sits in front of the board it's burning on instead of being cut off by it (walls further in
// front still hide it). Not additive: the painting's flames keep their hue where they overlap,
// and additive sprites went cream. Each square is in or out (alpha scissor, so no sorting), and a
// flame fades by losing squares (the particle's alpha against a threshold per square), as a
// pixel-art flame would. The particle's colour is not used (the sheet's are the painting's).
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque;

#include "res://src/render/aces.gdshaderinc"

uniform sampler2D sprite : source_color, filter_nearest;
uniform float toward_camera = 0.22;
// The sheet: frames across, shapes down (draw_flames.py FRAMES, SHAPES).
uniform int frames = 6;
uniform int shapes = 3;
// Frames a second (each flame starts at its own frame).
uniform float fps = 10.0;

varying float seed;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

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
	// One number per flame for its whole life: its slot in its emitter, and the emitter's place.
	seed = hash(NODE_POSITION_WORLD.xz * 3.17 + vec2(float(INSTANCE_ID) * 0.137, 0.71));
}

void fragment() {
	float shape = floor(seed * float(shapes));
	float frame = mod(floor(TIME * fps + seed * 97.0), float(frames));
	vec2 cell = vec2(1.0 / float(frames), 1.0 / float(shapes));
	vec2 uv = (vec2(frame, shape) + clamp(UV, vec2(0.001), vec2(0.999))) * cell;
	vec4 t = texture(sprite, uv);
	// The fade, square by square: each square of the sprite drops out at its own alpha.
	vec2 square = floor(UV * vec2(textureSize(sprite, 0)) * cell);
	float keep = step(hash(square + seed * 13.0) * 0.98 + 0.01, COLOR.a);
	// Through the tonemap's inverse, so the sheet's colours land on screen as drawn (ACES turns a
	// bright orange cream).
	ALBEDO = aces_inverse(t.rgb);
	ALPHA = t.a * keep;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
