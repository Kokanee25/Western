// The simulated fire's flipbooks (docs/briefs/fire-look.md, "The next approach"): what the three
// passes share (flame_core.gdshader, flame_tips.gdshader, flame_haze.gdshader). The sheets are
// baked from a Mantaflow fire by tools/textures/fire_sim/ (assets/textures/fire/): 64 frames in an
// 8 x 8 grid, R the flame, G the smoke, B the heat, and a sheet of motion vectors beside each.
//
// FireFX stands each burning member's fire on the same quad and instance uniforms as the fire
// sheet (fire_sheet.gdshader): `size` (metres across and up from its foot), `heat` (how grown),
// `behind` and `half_box` (a frame member's fire drawn behind it). Here that quad holds one
// simulated flame, turned about the vertical to face the camera: a big column on a tall sheet
// (a wall's boards), a tongue or a small lick on shorter ones, picked per sheet by its height and
// a number from its place, so a burning front is a mix of the three; each starts at its own
// frame and some are mirrored, so neighbours never move together.
//
// Frames are blended by their motion vectors (the flipbook blending of games' VFX, as Guerrilla's
// and SideFX's talks describe it): the frame before pushed forward along its vectors, the frame
// after pulled back along its own, mixed by the time between, so 24 frames a second play smooth.

#include "res://src/render/aces.gdshaderinc"

instance uniform float heat = 1.0;
instance uniform vec2 size = vec2(1.0, 2.0);
instance uniform float behind = 0.0;
instance uniform vec3 half_box = vec3(0.0);

uniform sampler2D lick_sheet : filter_linear, repeat_disable;
uniform sampler2D lick_mv : filter_linear, repeat_disable;
uniform sampler2D tongue_sheet : filter_linear, repeat_disable;
uniform sampler2D tongue_mv : filter_linear, repeat_disable;
uniform sampler2D column_sheet : filter_linear, repeat_disable;
uniform sampler2D column_mv : filter_linear, repeat_disable;
// Each type's frame in squares (across, up), its size in metres (across, up) and its motion range
// (UV a frame): from assets/textures/fire/fire_sheets.json, set by FireFlipbook.
uniform vec2 lick_squares = vec2(32.0, 48.0);
uniform vec2 tongue_squares = vec2(32.0, 72.0);
uniform vec2 column_squares = vec2(64.0, 128.0);
uniform vec2 lick_metres = vec2(0.5, 0.75);
uniform vec2 tongue_metres = vec2(0.7, 1.6);
uniform vec2 column_metres = vec2(2.0, 4.0);
uniform vec3 mv_range = vec3(0.04, 0.04, 0.04);
uniform float fps = 24.0;
// How tall the flame stands against the sheet's height (a share, at full heat) and how wide
// against its own frame's shape (under 1, narrower than the simulation's).
uniform float stand = 0.75;
uniform float width_scale = 0.9;
// Sheets at least this tall (metres) take a column; under `tongue_under`, a lick (some sheets
// take the next size down, by `smaller`).
uniform float column_over = 3.2;
uniform float tongue_under = 1.4;
uniform float smaller = 0.35;
// The fire drawn in squares fixed in the world (as the walls' are), this many a metre (0: as
// smooth as the sheet).
uniform float squares_per_m = 16.0;
uniform float toward_camera = 0.25;
// How far under its foot it fades in (metres).
uniform float foot_fade = 0.6;
// Where it meets a wall or the floor, it fades out over this depth (metres): soft edges.
uniform float soft = 0.12;
// The most flames side by side on one wide sheet.
uniform float max_tiles = 4.0;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;

varying vec3 world;
varying float rel; // metres over the sheet's foot
varying vec3 view_at;
varying flat float seed;
varying flat float kind; // 0 lick, 1 tongue, 2 column
varying flat vec2 flame; // one flame's size here (metres across, up)
varying flat float tiles; // flames side by side across the sheet

float fb_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 kind_metres(float k) {
	return k < 0.5 ? lick_metres : (k < 1.5 ? tongue_metres : column_metres);
}

struct FbVert {
	vec4 position;
	vec3 world;
	float rel;
	vec3 view_at;
	float seed;
	float kind;
	vec2 flame;
	float tiles;
};

// Each pass's vertex() is FB_VERTEX: a shader function may not set varyings, so it hands them back.
#define FB_VERTEX FbVert o = fb_vertex(VERTEX, NODE_POSITION_WORLD, CAMERA_POSITION_WORLD, VIEW_MATRIX, PROJECTION_MATRIX); POSITION = o.position; world = o.world; rel = o.rel; view_at = o.view_at; seed = o.seed; kind = o.kind; flame = o.flame; tiles = o.tiles;

FbVert fb_vertex(vec3 vertex, vec3 node, vec3 camera, mat4 view, mat4 proj) {
	FbVert o;
	o.seed = fb_hash(node.xz * 3.17 + vec2(node.y * 1.31, 0.71));
	float k = size.y >= column_over ? 2.0 : (size.y < tongue_under ? 0.0 : 1.0);
	if (fb_hash(vec2(o.seed, 4.2)) < smaller) {
		k = max(k - 1.0, 0.0);
	}
	o.kind = k;
	vec2 m = kind_metres(k);
	float h = size.y * stand * clamp(heat, 0.05, 1.0);
	o.flame = vec2(h * m.x / m.y * width_scale, h);
	// A sheet much wider than one flame (a rafter, a long board on its side) holds a row of them,
	// half a flame apart so they overlap into one fire, each at its own frame (a row of separate
	// flames along a roof read as candles).
	o.tiles = clamp(floor(size.x / max(o.flame.x * 0.5, 0.01)) - 1.0, 1.0, max_tiles);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 to_cam = camera - node;
	vec3 right = normalize(cross(up, to_cam));
	vec3 back = normalize(vec3(to_cam.x, 0.0, to_cam.z));
	vec3 centre = node;
	float depth = abs(back.x) * half_box.x + abs(back.z) * half_box.z + 0.04;
	centre -= back * depth * behind;
	// A 1 x 1 quad: from `foot_fade` under the foot to the flame's top, the flame's width across.
	o.rel = -foot_fade + (vertex.y + 0.5) * (o.flame.y + foot_fade);
	o.world = centre + right * vertex.x * o.flame.x * (o.tiles + 1.0) * 0.5 + up * o.rel;
	vec4 v = view * vec4(o.world, 1.0);
	v.xyz += normalize(-v.xyz) * toward_camera * (1.0 - behind);
	o.view_at = v.xyz;
	o.position = proj * v;
	return o;
}

vec4 fb_tex(float k, vec2 uv) {
	return k < 0.5 ? textureLod(lick_sheet, uv, 0.0) : (k < 1.5 ? textureLod(tongue_sheet, uv, 0.0) : textureLod(column_sheet, uv, 0.0));
}

vec2 fb_mv(float k, vec2 uv) {
	vec2 t = k < 0.5 ? textureLod(lick_mv, uv, 0.0).rg : (k < 1.5 ? textureLod(tongue_mv, uv, 0.0).rg : textureLod(column_mv, uv, 0.0).rg);
	float r = k < 0.5 ? mv_range.x : (k < 1.5 ? mv_range.y : mv_range.z);
	return (t - 0.5) * 2.0 * r;
}

// The sheet's UV of a point in one frame (`f`, 0..63) at `uv` in that frame, kept a half square
// inside its cell so frames don't bleed into each other.
vec2 fb_cell(float k, float f, vec2 uv) {
	vec2 sq = k < 0.5 ? lick_squares : (k < 1.5 ? tongue_squares : column_squares);
	vec2 inner = clamp(uv, 0.5 / sq, 1.0 - 0.5 / sq);
	return (vec2(mod(f, 8.0), floor(f / 8.0)) + inner) / 8.0;
}

// The flame here, now: R flame, G smoke, B heat, blended between its two frames along their
// motion. `uv` is the frame's (0..1, y down); outside it, nothing.
vec4 fb_sample(vec2 uv, float time, float sd) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	float t = time * fps + sd * 64.0;
	float f0 = mod(floor(t), 64.0);
	float f1 = mod(f0 + 1.0, 64.0);
	float a = fract(t);
	vec2 m0 = fb_mv(kind, fb_cell(kind, f0, uv));
	vec2 m1 = fb_mv(kind, fb_cell(kind, f1, uv));
	vec4 c0 = fb_tex(kind, fb_cell(kind, f0, uv - m0 * a));
	vec4 c1 = fb_tex(kind, fb_cell(kind, f1, uv + m1 * (1.0 - a)));
	return mix(c0, c1, a);
}

// The fire here, now (R flame, G smoke, B heat) and `uv`, this fragment's place in its flame's
// frame (y 0 at the top). Snapped to the middle of its square of the world's grid (across along the
// camera's right, up the height, as the fire sheet's squares are). On a sheet of several flames
// (`tiles`, half a flame apart) a point is in two of them, each at its own frame and some mirrored;
// the hotter is drawn.
vec4 fb_fire(vec2 quad_uv, mat4 inv_view, float time, out vec2 uv) {
	float width = (tiles + 1.0) * 0.5; // the sheet, in flames
	float u = quad_uv.x * width;
	float r = rel;
	if (squares_per_m > 0.0) {
		vec3 right = normalize(vec3(inv_view[0].x, 0.0, inv_view[0].z));
		float across = dot(world, right);
		u += ((floor(across * squares_per_m) + 0.5) / squares_per_m - across) / max(flame.x, 0.01);
		r += (floor(world.y * squares_per_m) + 0.5) / squares_per_m - world.y;
	}
	float v = min(1.0 - r / max(flame.y, 0.01), 0.995);
	vec4 best = vec4(0.0);
	uv = vec2(0.5, v);
	float last = floor(u * 2.0);
	for (float i = last - 1.0; i <= last; i += 1.0) {
		if (i < 0.0 || i > tiles - 1.0) {
			continue;
		}
		float x = u - i * 0.5;
		float sd = i < 0.5 ? seed : fb_hash(vec2(seed * 7.3, i + 0.37));
		if (fb_hash(vec2(sd, 9.1)) < 0.5) {
			x = 1.0 - x;
		}
		vec4 c = fb_sample(vec2(x, v), time, sd);
		if (c.r >= best.r) {
			best = max(best, c);
			uv = vec2(x, v);
		} else {
			best.gb = max(best.gb, c.gb);
		}
	}
	return best;
}

// Fading in under the foot (1 over it).
float fb_foot() {
	return clamp(1.0 + rel / max(foot_fade, 0.01), 0.0, 1.0);
}

// How far the scene behind is past this fragment (metres), for the soft edges.
float fb_soft(vec2 screen_uv, mat4 inv_proj) {
	float d = texture(depth_tex, screen_uv).r;
	vec4 v = inv_proj * vec4(screen_uv * 2.0 - 1.0, d, 1.0);
	float scene = -v.z / v.w;
	return clamp((scene - (-view_at.z)) / max(soft, 0.001), 0.0, 1.0);
}
