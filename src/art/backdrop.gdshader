shader_type spatial;
// The painted backdrop (src/art/backdrop.gd): a strip of the image model's red-rock country cut
// to squares, on a ring round the town, lit here by the time of day rather than by the scene's
// lights (it's a painting of things miles off). With the sun high it shows as painted; with the
// sun low the side facing the sun goes gold and the side with the sun behind it goes dark and
// violet with gold rims along its skyline; at night it's dark blue shapes. Its own haze (the
// scene's fog is off it, as it buried the old mountains), the haze's colour the fog's. Colours are
// worked out as they should show and turned back through the tonemap (src/render/aces.gdshaderinc)
// so they land as written.
render_mode unshaded, cull_disabled, fog_disabled;

#include "res://src/render/aces.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
// The strip's size in texels (the rim looks one texel up and either side).
uniform vec2 texels = vec2(1200.0, 129.0);
// The ring's middle (world), so each texel knows which way it faces.
uniform vec3 centre = vec3(0.0);
// DayCycle's sun (unit, toward it) and colour, how much day there is, and the haze's colour (the
// fog's), all as they show (sRGB).
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform vec3 sun_color = vec3(1.0);
uniform float daylight = 1.0;
uniform vec3 haze_color = vec3(0.8, 0.7, 0.6);
// How much haze this layer has (the far one most).
uniform float haze = 0.2;
// How the land looks by night, and in its own shadow at sunset (multipliers on the painting).
uniform vec3 night_tint = vec3(0.1, 0.11, 0.17);
uniform vec3 shade_tint = vec3(0.88, 0.6, 0.5);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 t = texture(albedo_tex, UV);
	if (t.a < 0.5) {
		discard;
	}
	vec2 px = 1.0 / texels;
	// The skyline: land with sky above it (or beside it) is the rim the low sun catches.
	float above = texture(albedo_tex, UV - vec2(0.0, px.y)).a;
	float above2 = texture(albedo_tex, UV - vec2(0.0, 2.0 * px.y)).a;
	float sides = min(texture(albedo_tex, UV - vec2(px.x, 0.0)).a, texture(albedo_tex, UV + vec2(px.x, 0.0)).a);
	float rim = max(1.0 - step(0.5, above), (1.0 - step(0.5, sides)) * 0.7);
	float rim2 = (1.0 - step(0.5, above2)) * (1.0 - rim) * 0.5;

	vec3 a = to_srgb(t.rgb);
	vec3 out_dir = normalize(vec3(world_pos.x - centre.x, 0.0, world_pos.z - centre.z));
	vec3 s = normalize(vec3(sun_dir.x, 0.0, sun_dir.z) + vec3(1e-4, 0.0, 0.0));
	// 1: the sun's behind this land (you see its shadowed face); -1: it faces the sun.
	float f = dot(out_dir, s);
	float front = clamp(-f, 0.0, 1.0);
	float back = clamp(f, 0.0, 1.0);
	float sun_up = smoothstep(-0.06, 0.08, sun_dir.y);
	float low = (1.0 - smoothstep(0.12, 0.55, sun_dir.y)) * sun_up;
	vec3 sun_tint = sun_color / max(max(sun_color.r, sun_color.g), max(sun_color.b, 0.01));
	// By day: as painted at noon; low sun: gold on the faces toward it, violet shade away from it.
	vec3 lit = mix(vec3(1.0), sun_tint * (0.75 + 0.45 * front), low * (1.0 - back));
	lit = mix(lit, shade_tint, low * back);
	vec3 col = a * lit;
	// The rim: the skyline's texel goes the low sun's gold (not added: added light burnt it cream).
	vec3 gold = vec3(1.0, 0.72, 0.36) * mix(vec3(1.0), sun_tint, 0.4);
	col = mix(col, gold, clamp(rim * 0.8 + rim2 * 0.4, 0.0, 1.0) * back * low);
	col = mix(col, gold * 0.9, rim * front * low * 0.25);
	// Night: dark shapes, a little moonlit.
	col = mix(a * night_tint, col, daylight);
	col = mix(col, haze_color, haze * mix(0.7, 1.0, daylight));
	ALBEDO = aces_inverse(from_srgb(clamp(col, 0.0, 1.0)));
}
