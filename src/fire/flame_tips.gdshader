shader_type spatial;
// The simulated fire's tips and smoke (flipbook.gdshaderinc), drawn over its core
// (flame_core.gdshader): where the flame thins toward its ragged top, the painting's deep reds and
// oranges, see-through as they thin; above and round them the fire's own smoke, warm and dark,
// lit orange from the flame underneath. Alpha-blended, not added: it darkens what it's over, as
// the painting's smoke does.
render_mode unshaded, cull_disabled, shadows_disabled, blend_mix, depth_draw_never, fog_disabled;

#include "res://src/fire/flipbook.gdshaderinc"

uniform sampler2D ramp : source_color, filter_linear, repeat_disable;
// The flame from which the tips start to show, and the core's start (flame_core's `core_from`).
uniform float tips_from = 0.09;
uniform float core_from = 0.22;
uniform float tip_bands = 3.0;
// Where the tips' bands sit on the painting's ramp.
uniform vec2 tip_ramp = vec2(0.0, 0.3);
// How solid the tips get at the core's edge.
uniform float tip_alpha = 1.0;
// The smoke: its colour (the painting's darkest heaps and the underside the fire lights, from
// fire_sheets.json) and how solid at the sheet's thickest.
uniform vec3 smoke_dark : source_color = vec3(0.26, 0.12, 0.12);
uniform vec3 smoke_lit : source_color = vec3(0.53, 0.24, 0.2);
uniform float smoke_alpha = 0.35;

void vertex() {
	FB_VERTEX
}

void fragment() {
	vec2 uv = fb_uv(UV, INV_VIEW_MATRIX);
	uv.y = min(uv.y, 0.995);
	vec4 s = fb_sample(uv, TIME);
	float foot = fb_foot();
	float f = s.r * foot;
	if (f >= core_from) {
		discard;
	}
	float tip = clamp((f - tips_from) / (core_from - tips_from), 0.0, 1.0);
	float band = floor(min(tip, 0.999) * tip_bands);
	vec3 tc = texture(ramp, vec2(mix(tip_ramp.x, tip_ramp.y, (band + 0.5) / tip_bands), 0.5)).rgb;
	float ta = f > tips_from ? tip_alpha * (0.7 + 0.3 * (band + 1.0) / tip_bands) : 0.0;
	// Smoke, lit by the flame and the heat under it.
	float sa = s.g * smoke_alpha * foot;
	vec3 sc = mix(smoke_dark, smoke_lit, clamp(s.b * 1.5 + f * 2.0, 0.0, 1.0));
	float a = ta + sa * (1.0 - ta);
	if (a < 0.02) {
		discard;
	}
	vec3 c = (tc * ta + sc * sa * (1.0 - ta)) / a;
	ALBEDO = aces_inverse(c);
	ALPHA = a * fb_soft(SCREEN_UV, INV_PROJECTION_MATRIX);
}
