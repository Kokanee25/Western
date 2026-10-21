class_name FireFlipbook
extends RefCounted
## The simulated fire's material (docs/briefs/fire-look.md, "The next approach"; the art session's):
## the flame flipbooks baked from a Mantaflow fire (tools/textures/fire_sim/, assets/textures/fire/)
## drawn in three passes on each of FireFX's fire sheets, in place of fire_sheet.gdshader's drawn
## field when Settings.fire_flipbooks is on: the heat haze first (flame_haze), the bright core
## (flame_core), then the tips and the smoke over it (flame_tips). The passes share the sheet's
## instance uniforms (`size`, `heat`, `behind`, `half_box`), so FireFX places it as it places a sheet.

const SHEETS := "res://assets/textures/fire/fire_sheets.json"
const KINDS := ["lick", "tongue", "column"]

static var _mat: ShaderMaterial


## The core pass, with the tips and the haze chained after it (one material for every sheet).
static func material() -> ShaderMaterial:
	if _mat != null:
		return _mat
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHEETS))
	var core := _pass(load("res://src/fire/flame_core.gdshader"), meta, 0)
	var tips := _pass(load("res://src/fire/flame_tips.gdshader"), meta, 1)
	var haze := _pass(load("res://src/fire/flame_haze.gdshader"), meta, -1)
	var ramp: Texture2D = load("res://assets/textures/fire/fire_ramp.png")
	core.set_shader_parameter(&"ramp", ramp)
	tips.set_shader_parameter(&"ramp", ramp)
	var dark: Array = meta.get("smoke_dark", [0.26, 0.12, 0.12])
	var lit: Array = meta.get("smoke_lit", [0.53, 0.24, 0.2])
	tips.set_shader_parameter(&"smoke_dark", Color(dark[0], dark[1], dark[2]))
	tips.set_shader_parameter(&"smoke_lit", Color(lit[0], lit[1], lit[2]))
	core.next_pass = tips
	tips.next_pass = haze
	_mat = core
	return _mat


## Every pass of the material, for setting a uniform on all of them (trials: --flipbook=).
static func passes() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	var m: Material = material()
	while m != null:
		out.append(m as ShaderMaterial)
		m = m.next_pass
	return out


static func _pass(shader: Shader, meta: Dictionary, priority: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.render_priority = priority
	var types: Dictionary = meta.get("types", {})
	var ranges := Vector3.ZERO
	for i in KINDS.size():
		var kind: String = KINDS[i]
		var t: Dictionary = types[kind]
		m.set_shader_parameter(kind + "_sheet", load("res://assets/textures/fire/fire_%s.png" % kind))
		m.set_shader_parameter(kind + "_mv", load("res://assets/textures/fire/fire_%s_mv.png" % kind))
		m.set_shader_parameter(kind + "_squares", Vector2(t.squares[0], t.squares[1]))
		m.set_shader_parameter(kind + "_metres", Vector2(t.size[0], t.size[1]))
		ranges[i] = float(t.mv_range)
		m.set_shader_parameter(&"fps", float(t.fps))
	m.set_shader_parameter(&"mv_range", ranges)
	return m
