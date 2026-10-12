## The shader-paint trial (tools/characters/shader_paint.py, body_paint.gdshader): puts the trial
## shader on a man already built, in place of his body_skin pieces' material. Off everywhere; the
## tools take --shader-paint[=name:value,...] (any of the shader's uniforms).
##   ShaderPaint.apply(human_body, "stranger2s", {"cell_m": 0.008})
const SHADER := "res://tools/characters/body_paint.gdshader"
const DIR := "res://assets/people/"


## Uniforms from "name:value,name:value" (numbers only).
static func parse(spec: String) -> Dictionary:
	var out := {}
	for pair in spec.split(",", false):
		if ":" in pair:
			out[pair.get_slice(":", 0)] = float(pair.get_slice(":", 1))
	return out


static func _texture(path: String, mips: bool) -> ImageTexture:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null:
		return null
	if mips:
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func apply(man: Node, id: String, values := {}) -> int:
	var base := _texture(DIR + id + "_sp_base.png", true)
	var palette := _texture(DIR + id + "_sp_palette.png", false)
	if base == null or palette == null:
		push_warning("shader paint: no %s_sp_base.png / _sp_palette.png (tools/characters/shader_paint.py)" % id)
		return 0
	var shader := load(SHADER) as Shader
	var n := 0
	for mi: MeshInstance3D in man.skin_meshes.values():
		var old := mi.material_override as ShaderMaterial
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter(&"albedo_tex", base)
		m.set_shader_parameter(&"palette_tex", palette)
		m.set_shader_parameter(&"palette_size", palette.get_width())
		if old:
			for k: StringName in [&"eye_r_pos", &"eye_l_pos", &"eye_radius", &"eye_gain",
					&"wound_count", &"wounds", &"reduced_gore"]:
				var v: Variant = old.get_shader_parameter(k)
				if v != null:
					m.set_shader_parameter(k, v)
		for k: String in values:
			m.set_shader_parameter(StringName(k), values[k])
		mi.material_override = m
		n += 1
	return n
