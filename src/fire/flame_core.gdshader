shader_type spatial;
// The simulated fire's bright core (flipbook.gdshaderinc; docs/briefs/fire-look.md, "The next
// approach"): where the flame is thick, drawn in the fire painting's colours (fire_ramp.png, from
// docs/concept/livery-fire-painted.png) in a few flat bands, near-white at the roots, orange
// through the body. Each band is one colour wherever it falls, so where flames overlap they keep
// their hue (additive sprites went cream). The thinner flame at the tips and the smoke over it
// are the next pass (flame_tips.gdshader); the heat haze is drawn before both (flame_haze).
// Unshaded, unfogged and through the tonemap's inverse, so the colours land on screen as painted.
render_mode unshaded, cull_disabled, shadows_disabled, blend_mix, depth_draw_always, fog_disabled;

#include "res://src/fire/flipbook.gdshaderinc"

uniform sampler2D ramp : source_color, filter_linear, repeat_disable;
// Flame (the sheet's R) from which it's core, and how many bands the core is drawn in.
uniform float core_from = 0.22;
uniform float bands = 5.0;
// Where the core's bands sit on the painting's ramp (0 its reds, 1 its near-white).
uniform vec2 core_ramp = vec2(0.3, 1.0);
// How much hotter its roots are drawn than its body: the band goes by the flame times this much
// more toward the frame's foot (the painting's near-white is low, its reds at the tips).
uniform float root_heat = 0.9;
// How far over white the hottest band is drawn, so the glow pass gives it its halo.
uniform float bloom = 0.6;

void vertex() {
	FB_VERTEX
}

void fragment() {
	vec2 uv = fb_uv(UV, INV_VIEW_MATRIX);
	uv.y = min(uv.y, 0.995);
	vec4 s = fb_sample(uv, TIME);
	float f = s.r * fb_foot();
	if (f < core_from) {
		discard;
	}
	float hot = f * (0.6 + root_heat * pow(uv.y, 1.5));
	float t = clamp((hot - core_from) / (1.0 - core_from), 0.0, 0.999);
	float band = floor(t * bands);
	float p = mix(core_ramp.x, core_ramp.y, (band + 0.5) / bands);
	vec3 c = texture(ramp, vec2(p, 0.5)).rgb;
	ALBEDO = aces_inverse(c) * (band >= bands - 1.0 ? 1.0 + bloom : 1.0);
	ALPHA = fb_soft(SCREEN_UV, INV_PROJECTION_MATRIX);
}
