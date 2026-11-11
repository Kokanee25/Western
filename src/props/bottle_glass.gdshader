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

void fragment() {
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - facing, 1.5);
	ALBEDO = tint.rgb * (1.0 - 0.25 * rim);
	ALPHA = clamp(tint.a + (1.0 - tint.a) * rim * edge, 0.0, 1.0);
	ROUGHNESS = 0.06;
	SPECULAR = 0.7;
	METALLIC = 0.0;
}
