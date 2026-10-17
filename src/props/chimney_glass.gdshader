shader_type spatial;
// A lamp's glass chimney, as the saloon painting draws it: lit, clear glass glowing gold from the
// flame inside, near-white over the flame, its edges catching the light (smooth since 2026-10-17,
// painted illustration: it was drawn in squares, the critic's "frosted beige blob"); unlit, it's
// faint clear glass. Unshaded (lit by a flame a few centimetres inside it, shaded glass burns white).
// `glow` is per lamp (OilLamp sets it when it's lit). No fog on it: the room's haze, lit by a flame
// centimetres away, laid cream over the whole glass (the halo shows on what's behind it). Round the
// flame it's drawn well over white (`bloom`), so the glow pass gives it the painting's halo.
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

#include "res://src/render/aces.gdshaderinc"

instance uniform float glow = 0.0;
// The flame's height in the lamp's own space.
uniform float flame_y = 0.205;
// How much the glass's edges (where it turns away from the eye) catch the light.
uniform float rim = 0.6;
// How far over display white the glass goes round the flame (scene-linear): the one thing in the
// room that blooms (the environment's glow threshold sits above every lit surface).
uniform float bloom = 3.0;

varying vec3 local_pos;
varying vec3 local_eye;

void vertex() {
	local_pos = VERTEX;
	local_eye = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

void fragment() {
	vec3 p = local_pos;
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
	// The glass's edge: where it turns away from the eye it's seen through more glass and
	// catches the light (the painting's bright outline round the chimney).
	float edge = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	vec3 shown = mix(vec3(0.86, 0.6, 0.3), vec3(1.0, 0.84, 0.52), heat * 0.6);
	shown = mix(shown, vec3(1.0, 0.97, 0.86), clamp(flame * 1.4 + edge * rim * 0.5, 0.0, 1.0));
	vec3 lit = aces_inverse(from_srgb(clamp(shown, 0.0, 1.0)));
	lit *= 1.0 + bloom * clamp(heat * 0.5 + flame + edge * rim * 0.3, 0.0, 1.0);
	vec3 clear = aces_inverse(from_srgb(vec3(0.5, 0.52, 0.5)));
	ALBEDO = mix(clear, lit, glow);
	// Clear glass: the room shows through away from the flame, less at the edges.
	ALPHA = mix(0.16 + 0.3 * edge, clamp(0.45 + 0.55 * max(heat, flame) + rim * edge * 0.4, 0.0, 1.0), glow);
}
