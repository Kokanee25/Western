shader_type spatial;
// A flame: a billboard tongue from the drawn flipbook (tools/textures/draw_flames.py,
// docs/briefs/fire-look.md step 1), solid colour as drawn, drawn a little towards the camera so it
// sits in front of the board it's burning on instead of being cut off by it (walls further in
// front still hide it). Not additive: the painting's flames keep their hue where they overlap,
// and additive sprites went cream. Each square is in or out (alpha scissor, so no sorting), and a
// flame fades by losing squares (the particle's alpha against a threshold per square), as a
// pixel-art flame would. The particle's colour is not used (the sheet's are the painting's).
// No fog: the haze and the burning building's own smoke laid a dull brown over the flames; the
// painting's flames are the brightest, cleanest colour in the picture.
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque, fog_disabled;

#include "res://src/render/aces.gdshaderinc"

uniform sampler2D sprite : source_color, filter_nearest;
uniform float toward_camera = 0.22;
// Scales the tongue's quad about its base, on top of FireFX's size by heat: at 1.8 the tongues off
// a burning front run together into the painting's mass of fire (judge, the fire view: 0.689 as
// drawn, 0.583 at 1.8, rounds 2026-10-10_r1/_r2). Trials: tools/screenshots.gd --flame=grow:N.
uniform float grow = 1.8;
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
	// Grown about the quad's bottom edge, so a bigger tongue still stands on what's burning.
	vec3 v = VERTEX;
	float bottom = -abs(VERTEX.y); // a quad's corners are at plus and minus half its height
	v.xy = vec2(v.x * grow, bottom + (v.y - bottom) * grow);
	vec4 view_pos = MODELVIEW_MATRIX * vec4(v, 1.0);
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
	// The fade, square by square, from the tip down: the tongue keeps its whole shape while the
	// particle's alpha is over 0.6, then loses its upper squares first, each row a little ragged
	// (a random square-by-square dissolve read as speckle all over the fire).
	vec2 squares = vec2(textureSize(sprite, 0)) * cell;
	vec2 square = floor(UV * squares);
	float height = 1.0 - (square.y + 0.5) / squares.y;
	float left = clamp(COLOR.a / 0.6, 0.0, 1.0);
	float keep = step(height * 0.85 + hash(square + seed * 13.0) * 0.15, left);
	// Through the tonemap's inverse, so the sheet's colours land on screen as drawn (ACES turns a
	// bright orange cream).
	ALBEDO = aces_inverse(t.rgb);
	ALPHA = t.a * keep;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
