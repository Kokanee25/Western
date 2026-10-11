shader_type spatial;
// A burning building's smoke column against the sky (docs/briefs/fire-look.md step 3, after
// docs/concept/livery-fire.png): an upright quad from the roofline up, turned to face the camera
// about the vertical, on which billows climb and lean with the wind, cut into the painting's smoke
// tones in world squares. The simulated smoke (SmokeField, a FogVolume) draws the smoke round the
// building; it can't draw over the sky (the sky keeps all fog off itself, or the street's haze
// would wash it out), so above the roofline this sheet draws it. SmokeColumn sets it from the fire
// under it: where it burns, how much, the wind.
//
// The painting's smoke: dark maroon-brown billows, lighter and purple where they thin into the
// sky, lit red-orange from underneath by the fire, with embers scattered through it.
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_opaque, fog_disabled;

#include "res://src/render/aces.gdshaderinc"

// 0 (nothing burning) to 1 (a building well alight): how tall and thick the column is.
instance uniform float strength = 1.0;
// The sheet's size in metres: across (the column's width at the roof) and up.
instance uniform vec2 size = vec2(4.0, 18.0);
// How far the column leans with the wind, metres sideways a metre up (world x, z).
instance uniform vec2 lean = vec2(0.0);
uniform float squares_per_m = 8.0;
// How fast the billows climb (m/s), and how many times a second they're redrawn.
uniform float rise = 0.9;
uniform float fps = 8.0;
// The billows' size (how many to a metre).
uniform float billows = 0.25;
// How much wider the column grows a metre up, as a share of its width at the roof.
uniform float widen = 0.05;
// Drawn this far back from the camera, so the fire's tongues over the roof stand in front of it.
uniform float away = 1.5;
// Metres over the roofline it takes to thicken, rising out of the fire.
uniform float fade_in = 3.0;
// Embers: how many squares in a thousand carry one.
uniform float embers = 6.0;

// The painting's smoke, darkest to the edge where it thins into the sky (sRGB).
const vec3 SMOKE[6] = vec3[6](
	vec3(40.0, 16.0, 16.0), vec3(56.0, 21.0, 20.0), vec3(73.0, 27.0, 21.0), vec3(86.0, 32.0, 27.0),
	vec3(102.0, 39.0, 48.0), vec3(125.0, 53.0, 76.0));
// Lit from underneath by the fire.
const vec3 LIT[3] = vec3[3](vec3(120.0, 40.0, 22.0), vec3(165.0, 62.0, 26.0), vec3(205.0, 95.0, 38.0));

varying vec3 world;
varying float rel; // metres over the sheet's foot
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

float billow(vec2 p, float t) {
	vec2 q = vec2(p.x, p.y - t * rise);
	return noise(q * billows) * 0.62 + noise(q * billows * 2.3 + vec2(7.1, 3.3)) * 0.38;
}

void vertex() {
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 to_cam = CAMERA_POSITION_WORLD - NODE_POSITION_WORLD;
	vec3 right = normalize(cross(up, to_cam));
	vec3 back = normalize(vec3(to_cam.x, 0.0, to_cam.z));
	// The quad is wide enough for the column at its top, leaning either way.
	float reach = size.x * (0.5 + widen * size.y) + abs(dot(vec3(lean.x, 0.0, lean.y), right)) * size.y;
	rel = (VERTEX.y + 0.5) * size.y;
	world = NODE_POSITION_WORLD - back * away + right * VERTEX.x * 2.0 * reach + up * rel;
	vec4 view_pos = VIEW_MATRIX * vec4(world, 1.0);
	view_at = view_pos.xyz;
	POSITION = PROJECTION_MATRIX * view_pos;
}

void fragment() {
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec2 p = floor(vec2(dot(world, right), world.y) * squares_per_m) / squares_per_m;
	float t = floor(TIME * fps) / fps;
	float h = (p.y - NODE_POSITION_WORLD.y); // metres over the roofline, square by square
	float u = h / max(size.y, 0.01);
	// Across the column: from its middle, leaning with the wind as it climbs.
	float mid = dot(NODE_POSITION_WORLD, right) + dot(vec3(lean.x, 0.0, lean.y), right) * h;
	float half_w = size.x * (0.5 + widen * max(h, 0.0));
	float across = abs(p.x - mid) / max(half_w, 0.05);
	float n = billow(p, t);
	// Thick in the middle, torn at its sides by the billows; it rises only as far as the fire
	// drives it, and thins out at its top.
	float body = 1.0 - across + (n - 0.5) * 0.9;
	float top = strength * (0.75 + 0.35 * n);
	body -= smoothstep(top * 0.55, top, u) * 1.2;
	// Fading in over the first few metres, raggedly, so it rises out of the fire's tongues rather
	// than sitting on the roofline.
	body -= clamp(1.0 - h / fade_in, 0.0, 1.0) * (0.9 + (0.5 - n) * 0.8);
	if (body <= 0.0 || h < 0.0) {
		discard;
	}
	// Billow tops catch the light: brighter where the field climbs.
	float lit_top = clamp((n - billow(p - vec2(0.0, 0.6), t)) * 3.0 + 0.5, 0.0, 1.0);
	// Darkest in the thick of it, lighter and purple toward the edge where it thins.
	float thin = clamp(1.0 - body * 0.9, 0.0, 1.0);
	int k = clamp(int(floor(thin * 4.0 + lit_top * 2.0)), 0, 5);
	vec3 c = SMOKE[k];
	// Lit from underneath by the fire, near the roofline, and more the more it burns.
	float glow = clamp(1.0 - h / (2.5 + strength * 2.0), 0.0, 1.0) * (1.0 - lit_top * 0.5) * strength;
	glow = glow * (0.7 + 0.6 * noise(p * 1.7 + vec2(0.0, -t * 2.0)));
	if (glow > 0.25) {
		c = LIT[clamp(int(floor((glow - 0.25) * 4.0)), 0, 2)];
	}
	vec3 lin = pow(c / 255.0, vec3(2.2));
	// Embers: a few squares carrying a spark, climbing faster than the smoke.
	vec2 ember_at = floor(vec2(p.x * squares_per_m, (p.y - t * rise * 2.4) * squares_per_m));
	// Thick near the fire, few higher up (they burn out as they climb).
	float ember_share = embers / 1000.0 * strength * clamp(1.0 - h / (size.y * 0.6), 0.0, 1.0) * 2.0;
	float ember = step(1.0 - ember_share, hash(ember_at + vec2(17.0, 3.0)));
	ember *= step(0.2, body);
	if (ember > 0.5) {
		lin = pow(vec3(255.0, 150.0, 60.0) / 255.0, vec3(2.2));
	}
	ALBEDO = aces_inverse(lin);
	if (ember > 0.5) {
		ALBEDO *= 1.6;
	}
	ALPHA = 1.0;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
