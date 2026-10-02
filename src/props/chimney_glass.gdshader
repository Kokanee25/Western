shader_type spatial;
// A lamp's glass chimney, as the saloon painting draws it: lit, it glows amber from the flame
// inside, brightest at the flame and in squares like everything else; unlit, it's faint clear
// glass. Unshaded (lit by a flame a few centimetres inside it, shaded glass burns white).
// `glow` is per lamp (OilLamp sets it when it's lit). No fog on it: the room's haze, lit by a flame
// centimetres away, laid cream over the whole glass (the halo shows on what's behind it).
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

#include "res://src/render/aces.gdshaderinc"

instance uniform float glow = 0.0;
// The flame's height in the lamp's own space, and the squares' size (a metre / this).
uniform float flame_y = 0.205;
uniform float squares_per_m = 110.0;

varying vec3 local_pos;
varying vec3 local_eye;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void vertex() {
	local_pos = VERTEX;
	local_eye = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

void fragment() {
	vec3 q = floor(local_pos * squares_per_m);
	vec3 p = (q + 0.5) / squares_per_m;
	float y = p.y;
	// How near the flame: hot over it, cooling up the chimney and quickly below.
	float heat = y > flame_y ? exp(-(y - flame_y) * 26.0) : exp(-(flame_y - y) * 40.0);
	// The flame seen through the glass: how close the line of sight through this square passes
	// to the flame's middle (a teardrop, taller than it's wide).
	vec3 dir = normalize(p - local_eye);
	vec3 f = vec3(0.0, flame_y + 0.015, 0.0);
	vec3 off = (local_eye + dir * dot(f - local_eye, dir)) - f;
	float flame = exp(-(off.x * off.x + off.z * off.z) / (0.016 * 0.016) - off.y * off.y / (0.03 * 0.03));
	// The painting's colours as they show on screen (orange glass, near-white over the flame),
	// turned back through the tonemap so they land as painted (a bright orange through ACES
	// comes out cream).
	vec3 shown = mix(vec3(0.82, 0.48, 0.18), vec3(1.0, 0.8, 0.45), heat * 0.6);
	shown = mix(shown, vec3(1.0, 0.97, 0.86), clamp(flame * 1.4, 0.0, 1.0));
	shown *= 0.9 + 0.2 * hash(q);
	vec3 lit = aces_inverse(from_srgb(clamp(shown, 0.0, 1.0)));
	vec3 clear = aces_inverse(from_srgb(vec3(0.5, 0.52, 0.5)));
	ALBEDO = mix(clear, lit, glow);
	ALPHA = mix(0.16, 0.8 + 0.2 * max(heat, flame), glow);
}
