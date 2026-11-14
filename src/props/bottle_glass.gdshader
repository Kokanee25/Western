shader_type spatial;
// A bottle's glass (#805; the kit look `glass:<colour>`, PropModels.tinted_glass): coloured glass
// lit by the room, seen through where it faces you and denser where it turns away (you look through
// more of it there, so its colour and the light on it gather at its outline, as a real bottle's do).
// Both walls drawn, so the far side's outline shows through the near one.
render_mode blend_mix, cull_disabled, depth_draw_never;

// Its colour (albedo) and how much light it stops facing you (alpha).
uniform vec4 tint : source_color = vec4(0.62, 0.8, 0.76, 0.28);
// How much its outline darkens and thickens with colour.
uniform float edge = 0.65;
// How much its outline catches the room's light (glass seen edge-on mirrors what's beside it: a
// bottle's bright rim and highlight line; the rooms have no reflection probe of their own yet, so
// the mirror alone shows dark: round 1's critic, "dull solid objects").
uniform float sheen = 0.35;

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - facing, 1.5);
	ALBEDO = mix(tint.rgb * (1.0 - 0.25 * rim), vec3(0.85), sheen * pow(rim, 2.5));
	ALPHA = clamp(tint.a + (1.0 - tint.a) * rim * edge, 0.0, 1.0);
	ROUGHNESS = 0.04;
	SPECULAR = 0.9;
	METALLIC = 0.0;
}
