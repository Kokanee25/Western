shader_type spatial;
// A window pane of old glass (SashWindow, #826): the faint green film the single pane had
// (WoodMaterials.glass: 0.55, 0.65, 0.60 at 28 %), with the dust two dry years leave on a town
// window: gathered in the corners and along the bottom where the rail stops it, a thin film over
// the rest, mottled. Each pane is its own member and mesh (a box); `half_size` is its box's half
// size, set per pane, so the dust is measured in metres from its own edges.
render_mode blend_mix, depth_draw_opaque, cull_back;

instance uniform vec3 half_size = vec3(0.3, 0.4, 0.002);
uniform vec3 tint : source_color = vec3(0.55, 0.65, 0.60);
uniform float clear_alpha = 0.22;
uniform vec3 dust : source_color = vec3(0.60, 0.55, 0.46);
// How much dust: the film over all, in the corners and edges, along the bottom.
uniform float film = 0.10;
uniform float edges = 0.45;
uniform float bottom = 0.35;
// How far in from an edge the dust reaches (metres).
uniform float reach = 0.05;

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	// The pane's plane: its two longer axes (y is always up; across is x or z, whichever is wider).
	bool along_x = half_size.x > half_size.z;
	float across = along_x ? v_local.x : v_local.z;
	float half_a = along_x ? half_size.x : half_size.z;
	float ex = half_a - abs(across);
	float ey = half_size.y - abs(v_local.y);
	float eb = v_local.y + half_size.y;
	// Dust in from the edges, most in the corners (where two edges' dust meet), more at the bottom.
	float de = exp(-ex / reach) + exp(-ey / reach);
	float db = exp(-eb / (reach * 1.6));
	vec2 p = vec2(across, v_local.y);
	float mottle = 0.55 + 0.9 * noise(p * 23.0) * noise(p * 5.0 + 3.1);
	float d = clamp((film + edges * de + bottom * db) * mottle, 0.0, 0.9);
	ALBEDO = mix(tint, dust, clamp(d * 1.6, 0.0, 1.0));
	ALPHA = clamp(clear_alpha + d, 0.0, 0.92);
	ROUGHNESS = mix(0.12, 0.85, clamp(d * 1.4, 0.0, 1.0));
	SPECULAR = mix(0.8, 0.3, clamp(d * 1.4, 0.0, 1.0));
	METALLIC = 0.0;
}
