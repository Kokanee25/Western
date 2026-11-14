shader_type spatial;
// The char over a structure's batch (#434: a burning building's members stay in their batches, so
// a saloon burning whole is a few hundred draws, not 18,000): each vertex carries its member's
// place in the batch (CUSTOM2.x, Structure._build_batch), and `looks` holds each place's
// (char_amount, glow), sent by Structure.show_fire. The look is char.gdshaderinc's, as a member
// drawn on its own has it (char_overlay.gdshader).
render_mode blend_mix, depth_draw_never, cull_back;

#include "res://src/fire/char.gdshaderinc"

// Structure.BATCH_PIECE members a batch at most.
uniform vec2 looks[64];

varying flat vec2 look;

void vertex() {
	look = looks[clamp(int(CUSTOM2.x + 0.5), 0, 63)];
}

void fragment() {
	vec3 albedo;
	vec3 emission;
	float alpha;
	char_look(UV, look.x, look.y, TIME, albedo, emission, alpha);
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	EMISSION = emission;
	ALPHA = alpha;
}
