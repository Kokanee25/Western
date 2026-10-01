shader_type spatial;
// Pixel-art texture on the texel grid, lit per texel when texel lighting is on.
// All of it lives in texel_grid.gdshaderinc (shared with member_holes.gdshader).
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://src/render/texel_grid.gdshaderinc"
