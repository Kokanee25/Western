shader_type spatial;
// member_holes.gdshader under the surface-blocks look (docs/briefs/renderer.md): bullet holes
// and the banded, tinted light(). PixelArt.hole_material picks it when PixelArt.blocks is on.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#define HOLES
#define BLOCKS
#include "res://src/render/texel_grid.gdshaderinc"
