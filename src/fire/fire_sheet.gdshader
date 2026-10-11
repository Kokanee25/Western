shader_type spatial;
// A burning member's fire as one sheet (docs/briefs/fire-look.md, after docs/concept/livery-fire.png):
// an upright quad turned to face the camera about the vertical, on which a field of heat rises and
// cools and is cut into the painting's bands: tall tongues stretched up and climbing, white and
// yellow inside, red only at each tongue's edge, ending in points. The idea is the old
// "Doom fire" effect (heat carried up row by row and losing a little at random, as Fabien
// Sanglard's write-up of the PSX Doom fire describes it), done here as a noise field scrolled
// upward rather than a simulation: no state, so any number of sheets cost the same.
//
// Every sheet samples the same field, in world squares: across, the distance along the camera's
// right (all the sheets near you face the same way), up, the height. So where two burning members'
// sheets overlap they draw the same fire, and a burning front reads as one mass of flame, not a
// row of sprites; where they cross at different depths the hotter square wins (`hottest_wins`). A
// frame member's fire is drawn behind it (`behind`), so the timber stands dark against it as the
// painting's frame does. The squares are a fixed size in the world (`squares_per_m`), as the walls' are,
// so a fire close up is no chunkier than the boards it burns.
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque, fog_disabled;

#include "res://src/render/aces.gdshaderinc"

// 0 (a lick just catching) to 1 (fully alight): how much of the sheet the fire fills.
instance uniform float heat = 1.0;
// The sheet's size in metres (FireFX sets it with the quad).
instance uniform vec2 size = vec2(1.0, 2.0);
uniform float squares_per_m = 16.0;
// Drawn a little towards the camera, so the board it burns on doesn't cut it.
uniform float toward_camera = 0.15;
// A frame member's fire (a post, a stud, a beam: FireFX sets it) is drawn behind it instead, by
// its depth as the camera sees it (`half_box`, its half size in the world's axes), so the timber
// stands dark against its own flames as the painting's frame does. 0 for boards and siding.
instance uniform float behind = 0.0;
instance uniform vec3 half_box = vec3(0.0);
// How fast the fire climbs (m/s) and how many times a second it's redrawn (a pixel-art flame
// steps; it doesn't slide).
uniform float rise = 1.6;
uniform float fps = 12.0;
// How far over white the core is drawn, so the glow pass gives the fire its halo.
uniform float bloom = 0.8;
// How tall the fire's heat runs, in metres: the bands go by height over a sheet's foot on this one
// scale, so sheets of different heights (a gable's boards, a wall's) draw the same fire where they
// overlap.
uniform float fire_height = 5.5;
// Heat added everywhere: more of the fire in its yellow and white bands, less in its reds.
uniform float core = 0.5;
// The tongues' size: how many to a metre across, and how stretched up (a lower number, taller).
uniform float tongues_x = 3.0;
uniform float tongues_y = 0.8;
// How much the climbing noise eats into the heat: more, more separate tongues.
uniform float wear = 0.9;
// Where up the sheet (a share of its height) its fire starts to die away, so it ends in points at
// its top, never a straight edge.
uniform float fade = 0.45;
// The sheet reaches this far under its foot and fades in there (metres), so a fire on a beam
// overhead joins the fire below it without a hard edge.
uniform float foot_fade = 0.5;
// The hotter of two sheets that overlap is drawn: each square's depth is brought nearer the camera
// by its heat times this (metres), so where a wall's sheets cross the fire is the hottest of them,
// not whichever sheet is nearer.
uniform float hottest_wins = 0.15;
// A sheet raised off the ground (a burning beam, a gable's boards) starts this share of its height
// up the fire's scale, as the upper part of the fire under it is, so it isn't white at its foot.
uniform float lifted = 0.0;

// The painting's fire, edge to core (sRGB), as tools/textures/draw_flames.py has them.
const vec3 TONES[7] = vec3[7](
	vec3(150.0, 38.0, 8.0), vec3(178.0, 52.0, 10.0), vec3(226.0, 69.0, 9.0), vec3(247.0, 109.0, 22.0),
	vec3(250.0, 162.0, 47.0), vec3(252.0, 212.0, 101.0), vec3(255.0, 242.0, 186.0));

varying vec3 world;
varying float rel; // metres over the sheet's foot
// Where the sheet is drawn, in view space (POSITION is set here, so VERTEX isn't it).
varying vec3 view_at;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	// Turned about the vertical to face the camera, kept upright.
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 to_cam = CAMERA_POSITION_WORLD - NODE_POSITION_WORLD;
	vec3 right = normalize(cross(up, to_cam));
	vec3 back = normalize(vec3(to_cam.x, 0.0, to_cam.z));
	vec3 centre = NODE_POSITION_WORLD;
	// Behind a frame member: as far back as its box reaches toward the camera, and a little more
	// (and the most a square is brought forward to win against another sheet).
	float depth = abs(back.x) * half_box.x + abs(back.z) * half_box.z + 0.04 + hottest_wins;
	centre -= back * depth * behind;
	// The node stands at the sheet's foot (a 1 x 1 quad, here from `foot_fade` under the foot to
	// `size.y` over it, `size.x` across).
	rel = -foot_fade + (VERTEX.y + 0.5) * (size.y + foot_fade);
	world = centre + right * VERTEX.x * size.x + up * rel;
	vec4 view_pos = VIEW_MATRIX * vec4(world, 1.0);
	view_pos.xyz += normalize(-view_pos.xyz) * toward_camera * (1.0 - behind);
	view_at = view_pos.xyz;
	POSITION = PROJECTION_MATRIX * view_pos;
}

void fragment() {
	// The square this fragment is in, in the world: across along the camera's right, up the height.
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec2 p = floor(vec2(dot(world, right), world.y) * squares_per_m) / squares_per_m;
	float t = floor(TIME * fps) / fps;
	float up = rel / max(size.y, 0.01); // 0 at the sheet's foot, 1 at its top
	float u = UV.x;
	float sides = smoothstep(0.0, 0.18, min(u, 1.0 - u));
	// Tongues: noise stretched up and climbing with the fire, swaying a little as it goes, at two
	// scales (the tongues, and the ragged edges of each). Its bands follow each tongue's outline, red
	// only at the edge, yellow to white inside, as the painting's are. The field is the same on every
	// sheet in the world's squares: a sheet's own height and `heat` only trim where it dies away.
	float sway = 0.25 * sin(p.y * 1.3 - t * 2.0 + p.x * 0.7);
	float x = p.x + sway;
	float n = noise(vec2(x * tongues_x, (p.y - t * rise) * tongues_y)) * 0.6
			+ noise(vec2(x * tongues_x * 2.5, (p.y - t * rise * 1.5) * tongues_y * 3.0)) * 0.4;
	float over = clamp((rel + max(NODE_POSITION_WORLD.y - 0.8, 0.0) * lifted) / fire_height, 0.0, 1.0);
	float h = pow(1.0 - over, 1.3) - n * wear + core;
	// Dying away towards the top of this member's fire (its `heat` of the sheet), and at its sides.
	float top = max(heat, 0.05);
	h -= clamp((up - fade * top) / ((1.0 - fade) * top), 0.0, 1.0);
	// Its sides are cut raggedly, not cooled: the sheet beside or behind it shows there (cooled to
	// red, every stud's sheet drew a red stripe down a burning wall).
	if (sides < noise(vec2(p.x * 9.0, p.y * 5.0 - t * rise * 3.0))) {
		discard;
	}
	// Fading in under its foot.
	h -= clamp(-rel / max(foot_fade, 0.01), 0.0, 1.0);
	if (h <= 0.0) {
		discard;
	}
	int band = clamp(int(floor(h * 7.0)), 0, 6);
	// The tones are sRGB; the shader works in linear light (the flipbook's sheet is a texture read
	// as source_color, which converts it). Used as linear they came out washed to a pale cream.
	vec3 c = pow(TONES[band] / 255.0, vec3(2.2));
	ALBEDO = aces_inverse(c);
	// Written, so the fire is drawn as the flipbook was, where fog_disabled holds: drawn without it,
	// the dusk haze greyed the fire toward the sky's purple.
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	if (band == 6) {
		ALBEDO *= 1.0 + bloom;
	}
	// The hotter square nearer the camera (see `hottest_wins`).
	vec3 v = view_at + normalize(-view_at) * clamp(h, 0.0, 1.0) * hottest_wins;
	vec4 clip = PROJECTION_MATRIX * vec4(v, 1.0);
	DEPTH = clip.z / clip.w;
}
