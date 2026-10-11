shader_type spatial;
// A burning member's fire as one sheet (docs/briefs/fire-look.md, after docs/concept/livery-fire.png):
// an upright quad turned to face the camera about the vertical, on which a field of heat rises and
// cools and is cut into the painting's bands (a near-white core low down, orange through the body,
// deep red at the ragged top), with licks tearing off the top and floating up. The idea is the old
// "Doom fire" effect (heat carried up row by row and losing a little at random, as Fabien
// Sanglard's write-up of the PSX Doom fire describes it), done here as a noise field scrolled
// upward rather than a simulation: no state, so any number of sheets cost the same.
//
// Every sheet samples the same field, in world squares: across, the distance along the camera's
// right (all the sheets near you face the same way), up, the height. So where two burning members'
// sheets overlap they draw the same fire, and a burning front reads as one mass of flame, not a
// row of sprites. The squares are a fixed size in the world (`squares_per_m`), as the walls' are,
// so a fire close up is no chunkier than the boards it burns.
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque, fog_disabled;

#include "res://src/render/aces.gdshaderinc"

// 0 (a lick just catching) to 1 (fully alight): how much of the sheet the fire fills.
instance uniform float heat = 1.0;
// The sheet's size in metres (FireFX sets it with the quad).
instance uniform vec2 size = vec2(1.0, 2.0);
uniform float squares_per_m = 16.0;
// Drawn a little towards the camera, so the board it burns on doesn't cut it.
uniform float toward_camera = 0.25;
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

// The painting's fire, edge to core (sRGB), as tools/textures/draw_flames.py has them.
const vec3 TONES[7] = vec3[7](
	vec3(150.0, 38.0, 8.0), vec3(178.0, 52.0, 10.0), vec3(226.0, 69.0, 9.0), vec3(247.0, 109.0, 22.0),
	vec3(250.0, 162.0, 47.0), vec3(252.0, 212.0, 101.0), vec3(255.0, 242.0, 186.0));

varying vec3 world;

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
	vec3 centre = NODE_POSITION_WORLD;
	// The node stands at the sheet's foot (a 1 x 1 quad, scaled here by `size`).
	world = centre + right * VERTEX.x * size.x + up * (VERTEX.y + 0.5) * size.y;
	vec4 view_pos = VIEW_MATRIX * vec4(world, 1.0);
	view_pos.xyz += normalize(-view_pos.xyz) * toward_camera;
	POSITION = PROJECTION_MATRIX * view_pos;
}

void fragment() {
	// The square this fragment is in, in the world: across along the camera's right, up the height.
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec2 p = floor(vec2(dot(world, right), world.y) * squares_per_m) / squares_per_m;
	vec2 local = vec2(UV.x, 1.0 - UV.y); // 0 at the sheet's foot, 1 at its top
	float t = floor(TIME * fps) / fps;
	// Heat: full at the foot, falling off up the sheet, narrowing at its sides, worn into tongues by
	// noise climbing with the fire (two scales: the tongues, and the ragged edges of each). The
	// field is the same on every sheet (a wall's boards share a foot and a height): `heat` only
	// trims how far up it reaches, so neighbouring sheets that overlap draw the same squares (each
	// with its own heat drew the wall in stripes).
	float up = local.y;
	// Flat across the sheet, the fire lower only near its own edges (tapered all the way across,
	// every board's sheet peaked at its own middle and a wall's fire drew in stripes).
	float sides = smoothstep(0.0, 0.18, min(local.x, 1.0 - local.x));
	float n = noise(vec2(p.x * 2.2, (p.y - t * rise) * 1.3)) * 0.65
			+ noise(vec2(p.x * 6.0, (p.y - t * rise * 1.4) * 4.0)) * 0.35;
	float over = clamp((world.y - NODE_POSITION_WORLD.y) / fire_height, 0.0, 1.0);
	float h = pow(1.0 - over, 1.3) - n * 0.7 + 0.2;
	// Licks: above the body, a sparse few squares where the noise peaks, as if torn off the top.
	float lick = step(0.82, noise(vec2(p.x * 5.0, (p.y - t * rise * 1.8) * 3.0))) * step(0.85, up) * step(up, 1.0) * step(0.5, sides);
	h = max(h, lick * 0.12);
	// How far up this member's fire reaches: a ragged line under its `heat`, lower towards the
	// sheet's sides (rounded shoulders, not a gap: neighbouring sheets meet without a seam).
	float reach = heat * mix(0.35, 1.0, sides) + (n - 0.5) * 0.25;
	if (h <= 0.0 || up > reach) {
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
}
