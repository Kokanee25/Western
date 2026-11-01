// A realistic test man's hair cards, their soft fringe: realistic_hair.gdshader's next pass, blended
// over what's behind, writing no depth (#547 step 3; realistic_hair.gdshaderinc).
shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_never;
#define RL_FRINGE
#include "res://src/bodies/shaders/realistic_hair.gdshaderinc"
