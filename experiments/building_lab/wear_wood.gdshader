shader_type spatial;
// The game's wood (texel_grid.gdshaderinc) with the lived-in marks laid on it (wear.gdshaderinc,
// through its WEAR hook): the building lab's, for the saloon's worn renders.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#define WEAR
#include "res://experiments/building_lab/wear.gdshaderinc"
#include "res://src/render/texel_grid.gdshaderinc"
