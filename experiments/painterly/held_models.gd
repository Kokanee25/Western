extends RefCounted
## The modelled revolver and hand (the painterly test, `--painterly`): RevolverModel and HandModel
## ask here first and keep their code-built parts when nothing's here. The glbs are built by
## tools/blender/held_revolver.py and held_hand.py in the code-built gun's own space, with the same
## moving parts at the same pivots, so the viewmodel drives them as it does those.

const DIR := "res://assets/held/"
const SHADER := preload("res://experiments/painterly/held_metal.gdshader")
const SKIN := preload("res://experiments/painterly/held_skin.gdshader")

static var _mats := {}


## Fills `m` (a RevolverModel) with the modelled gun; false if there's none.
static func revolver(m: Node3D) -> bool:
	if not ResourceLoader.exists(DIR + "revolver.glb"):
		return false
	var inst: Node = (load(DIR + "revolver.glb") as PackedScene).instantiate()
	var root := inst.get_node("Revolver")
	for c in root.get_children():
		root.remove_child(c)
		m.add_child(c)
	inst.free()
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		_dress(mi)
	m.hammer = m.get_node("Hammer")
	m.trigger = m.get_node("Trigger")
	m.cylinder = m.get_node("Cylinder")
	m.gate = m.get_node("Gate")
	m.ejector = m.get_node("Ejector")
	m.muzzle = Marker3D.new()
	m.muzzle.name = "Muzzle"
	m.muzzle.position = Vector3(0, 0.0405, -0.259)
	m.add_child(m.muzzle)
	m.gate_point = Marker3D.new()
	m.gate_point.name = "GatePoint"
	m.gate_point.position = Vector3(0.012, 0.037, 0.0)
	m.add_child(m.gate_point)
	for i in 6:
		m._rims.append(m.cylinder.get_node("Rim%d" % i))
		m._primers.append(m.cylinder.get_node("Primer%d" % i))
	return true


## Fills `h` (a HandModel) with the modelled hand, cuff and sleeve; false if there's none. Its
## fingers are markers at the knuckles (the code that counts them finds them); the index's squeeze
## and the thumb's reach for the hammer are the mesh's shapes (`set_shapes`).
static func hand(h: Node3D) -> bool:
	if not ResourceLoader.exists(DIR + "hand.glb"):
		return false
	var inst: Node = (load(DIR + "hand.glb") as PackedScene).instantiate()
	for c in inst.get_children():
		inst.remove_child(c)
		h.add_child(c)
	inst.free()
	for mi in h.find_children("*", "MeshInstance3D", true, false):
		var slot: String = mi.mesh.surface_get_material(0).resource_name if mi.mesh.surface_get_material(0) else ""
		mi.material_override = material(slot)
	for f in ["thumb", "index", "middle", "ring", "little"]:
		var segs: Array[Node3D] = []
		var parent: Node3D = h
		for k in (2 if f == "thumb" else 3):
			var m := Node3D.new()
			m.name = "%s%d" % [f.capitalize(), k]
			parent.add_child(m)
			segs.append(m)
			parent = m
		h.fingers[f] = segs
	h.index = h.fingers["index"]
	h.thumb = h.fingers["thumb"]
	return true


## The hand's shapes: 0..1 the index squeezing, 0..1 the thumb on the hammer.
static func set_shapes(h: Node3D, squeeze: float, thumb: float) -> void:
	var mi := h.get_node_or_null(^"Hand") as MeshInstance3D
	if mi == null:
		return
	var a := mi.find_blend_shape_by_name(&"trigger")
	var b := mi.find_blend_shape_by_name(&"thumb")
	if a >= 0:
		mi.set_blend_shape_value(a, squeeze)
	if b >= 0:
		mi.set_blend_shape_value(b, thumb)


## The material a part's slot names.
static func _dress(mi: MeshInstance3D) -> void:
	var slot := ""
	if mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0):
		slot = mi.mesh.surface_get_material(0).resource_name
	mi.material_override = material(slot)


static func material(slot: String) -> Material:
	if _mats.has(slot):
		return _mats[slot]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	match slot:
		"case":
			_params(m, "case", 9.0, 0.7, 0.42, Color(0.66, 0.65, 0.63))
		"blued":
			_params(m, "blued", 12.0, 0.65, 0.42, Color(0.6, 0.61, 0.63))
		"brass", "rim":
			_params(m, "brass", 30.0, 0.95, 0.32, Color(0.85, 0.72, 0.45))
		"walnut":
			_params(m, "walnut", 14.0, 0.0, 0.42, Color(0.5, 0.3, 0.16))
			m.set_shader_parameter(&"uv_rot", -0.34)
			m.set_shader_parameter(&"worn_metallic", 0.0)
			m.set_shader_parameter(&"worn_roughness", 0.3)
			m.set_shader_parameter(&"wear_from", 0.55)
			m.set_shader_parameter(&"wear_to", 1.2)
		"skin":
			m.shader = SKIN
			m.set_shader_parameter(&"mottle_tex", load(DIR + "skin.png"))
		"cuff":
			_params(m, "linen", 220.0, 0.0, 0.85, Color(0.8, 0.76, 0.66))
			m.set_shader_parameter(&"tint", Color(0.84, 0.79, 0.68))
			m.set_shader_parameter(&"wear_from", 2.0)
			m.set_shader_parameter(&"wear_to", 3.0)
		"coat":
			_params(m, "wool", 180.0, 0.0, 0.95, Color(0.3, 0.22, 0.15))
			m.set_shader_parameter(&"tint", Color(0.36, 0.25, 0.16))
			m.set_shader_parameter(&"wear_from", 2.0)
			m.set_shader_parameter(&"wear_to", 3.0)
		"primer":
			_params(m, "brass", 30.0, 0.95, 0.4, Color(0.8, 0.5, 0.35))
			m.set_shader_parameter(&"tint", Color(1.0, 0.75, 0.6))
		_:  # bore, and anything unnamed: dark and dull
			_params(m, "blued", 25.0, 0.5, 0.7, Color(0.1, 0.1, 0.1))
			m.set_shader_parameter(&"tint", Color(0.25, 0.25, 0.25))
			m.set_shader_parameter(&"wear_from", 2.0)
			m.set_shader_parameter(&"wear_to", 3.0)
	_mats[slot] = m
	return m


static func _params(m: ShaderMaterial, tex: String, scale: float, metallic: float, rough: float, worn: Color) -> void:
	m.set_shader_parameter(&"albedo_tex", load(DIR + tex + ".png"))
	m.set_shader_parameter(&"tex_scale", scale)
	m.set_shader_parameter(&"metallic", metallic)
	m.set_shader_parameter(&"roughness", rough)
	m.set_shader_parameter(&"worn", worn)
