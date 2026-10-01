shader_type spatial;
// A structure member's wood (the texel-grid material, texel_grid.gdshaderinc) with bullet holes
// cut in it: through-holes are cut out, the rest are dark pits ringed with fresh wood.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#define HOLES
#include "res://src/render/texel_grid.gdshaderinc"
