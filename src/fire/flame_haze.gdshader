shader_type spatial;
// The heat haze behind and over the simulated fire (flipbook.gdshaderinc): where the flame's heat
// (the sheet's B) is, the scene behind is drawn back shifted by a rising wobble, a few of the
// screen's pixels. Drawn before the flame's own passes (a lower render priority), so the haze
// shimmers what's behind the fire and the fire is drawn sharp over it.
render_mode unshaded, cull_disabled, shadows_disabled, blend_mix, depth_draw_never, fog_disabled;

#include "res://src/fire/flipbook.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
// The most it shifts the scene (pixels of the game's frame) and how fast its wobble climbs (m/s).
uniform float haze_px = 2.5;
uniform float haze_rise = 1.2;
// Wobbles a metre.
uniform float haze_scale = 5.0;

float hz_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(fb_hash(i), fb_hash(i + vec2(1.0, 0.0)), f.x), mix(fb_hash(i + vec2(0.0, 1.0)), fb_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	FB_VERTEX
}

void fragment() {
	vec2 uv = fb_uv(UV, INV_VIEW_MATRIX);
	uv.y = min(uv.y, 0.995);
	vec4 s = fb_sample(uv, TIME);
	float heat_here = s.b * fb_foot() * (1.0 - smoothstep(0.1, 0.4, s.r));
	if (heat_here < 0.03) {
		discard;
	}
	vec2 p = vec2(UV.x * flame.x, rel - TIME * haze_rise) * haze_scale + seed * 17.0;
	vec2 wobble = vec2(hz_noise(p), hz_noise(p + vec2(5.2, 1.3))) - 0.5;
	vec2 shift = wobble * 2.0 * haze_px * heat_here / VIEWPORT_SIZE;
	ALBEDO = textureLod(screen_tex, SCREEN_UV + shift, 0.0).rgb;
	ALPHA = clamp(heat_here * 4.0, 0.0, 1.0) * fb_soft(SCREEN_UV, INV_PROJECTION_MATRIX);
}
