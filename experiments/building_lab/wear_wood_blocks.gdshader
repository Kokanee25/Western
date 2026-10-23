shader_type spatial;
// wear_wood.gdshader under the surface-blocks look (texel_grid_blocks.gdshader's light).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#define WEAR
#define BLOCKS
#include "res://experiments/building_lab/wear.gdshaderinc"
#include "res://src/render/texel_grid.gdshaderinc"
