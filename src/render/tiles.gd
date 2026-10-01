class_name Tiles
## Materials on the mosaic tiles (tiles.gdshaderinc): every texel is a tile lit as one colour, the
## painting's look. StandardMaterial3D can't do that, so surfaces that should read like the
## painting use tiled_lit.gdshader through here. Settings.tile_look switches all of them (P).

const SHADER := preload("res://src/render/tiled_lit.gdshader")
const SHADER_DOUBLE := preload("res://src/render/tiled_lit_double.gdshader")


## A tiled material. `on_grid`: UVs (or triplanar positions) are in metres and follow the world's
## texel density (PixelArt, F7); otherwise UVs are taken as they are (0..1 over a baked texture).
static func material(tex: Texture2D, tint := Color.WHITE, rough := 0.9, metal := 0.0,
		triplanar := false, on_grid := true, double_sided := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_DOUBLE if double_sided else SHADER
	m.set_shader_parameter(&"albedo_tex", tex)
	m.set_shader_parameter(&"albedo_color", tint)
	m.set_shader_parameter(&"roughness", rough)
	m.set_shader_parameter(&"metallic", metal)
	m.set_shader_parameter(&"triplanar", triplanar)
	if on_grid:
		PixelArt.track_tiled(m)
	return m
