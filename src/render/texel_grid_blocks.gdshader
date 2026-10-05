shader_type spatial;
// The texel-grid material under the surface-blocks look (docs/briefs/renderer.md): the same
// texel_grid.gdshaderinc with its banded, tinted light(). PixelArt.material picks it when
// PixelArt.blocks is on (Settings.surface_blocks).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#define BLOCKS
#include "res://src/render/texel_grid.gdshaderinc"
