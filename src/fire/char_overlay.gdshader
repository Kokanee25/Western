shader_type spatial;
// Drawn over a member's own material as it scorches, chars and burns, when it's drawn on its own
// (broken, holed, cut: Structure.unbatch); its amounts in steps, one material a step shared by
// every member at it (Structure._char_material: instance uniforms ran out on a town's charred
// rubble). A member still in its structure's batch is charred by char_batch.gdshader.
// The look is char.gdshaderinc's.
render_mode blend_mix, depth_draw_never, cull_back;

#include "res://src/fire/char.gdshaderinc"

uniform float char_amount : hint_range(0.0, 1.0) = 0.0;
uniform float glow : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 albedo;
	vec3 emission;
	float alpha;
	char_look(UV, char_amount, glow, TIME, albedo, emission, alpha);
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	EMISSION = emission;
	ALPHA = alpha;
}
