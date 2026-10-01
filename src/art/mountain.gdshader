shader_type spatial;
// Distant rock (src/art/mountains.gd): the texel-grid material at a coarse texel size, with its
// own haze in place of the scene's fog (which would bury it at 400-600 m).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, fog_disabled;

#define HAZE
#include "res://src/render/texel_grid.gdshaderinc"
