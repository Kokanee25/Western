class_name StreetWear
extends Node3D
## The street's wear (the light pass, round 2; Sean, #321: "damp dark ground by the trough and
## hitching rails, scattered straw, droppings"): the ground darkened and glossy round each trough
## and rail (the ground shader's damp_spots), and straw and horse droppings scattered round them and
## loose over the street, each kind one MultiMesh (two draw calls). Numbers in config/street_wear.json.

const CONFIG := "res://config/street_wear.json"
const MAX_SPOTS := 16

var _cfg: Dictionary


func _ready() -> void:
	_cfg = LookPreset.load_file(CONFIG)
	_build.call_deferred()  # the troughs and rails are placed first


## Each trough and hitching rail as [x, z, radius, strength] (and whether it's a rail).
func spots() -> Array:
	var out := []
	var trough: Array = _cfg.get("damp_trough", [2.2, 1.0])
	var rail: Array = _cfg.get("damp_rail", [1.8, 0.7])
	for n in get_tree().root.find_children("*", "WaterTrough", true, false):
		var p := (n as Node3D).global_position
		out.append([p.x, p.z, float(trough[0]), float(trough[1]), false])
	for n in get_tree().root.find_children("*Rail", "Node3D", true, false):
		if n.get_node_or_null(^"Bar") == null:
			continue
		var p := (n as Node3D).global_position
		out.append([p.x, p.z, float(rail[0]), float(rail[1]), true])
	return out.slice(0, MAX_SPOTS)


func _build() -> void:
	var s := spots()
	_damp(s)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_cfg.get("seed", 11))
	_straw(s, rng)
	_droppings(s, rng)


func _damp(s: Array) -> void:
	var packed := PackedVector4Array()
	for sp: Array in s:
		packed.append(Vector4(sp[0], sp[1], sp[2], sp[3]))
	for m in LookPreset._materials(get_tree(), "ground"):
		m.set_shader_parameter(&"damp_spots", packed)
		m.set_shader_parameter(&"damp_count", packed.size())


## A point loose over the street: along it within street_box's x, and across it as far either side
## of its middle as the box is wide (the street bends: TownLayout.street_z), on the ground (it
## slopes west of the store: TownLayout.ground_height).
func _box_point(rng: RandomNumberGenerator) -> Vector3:
	var b: Array = _cfg.get("street_box", [-80.0, -17.0, 30.0, 0.0])
	var x := rng.randf_range(b[0], b[2])
	var half := (float(b[3]) - float(b[1])) * 0.5
	return Vector3(x, TownLayout.ground_height(x), TownLayout.street_z(x) + rng.randf_range(-half, half))


func _near(sp: Array, reach: float, rng: RandomNumberGenerator) -> Vector3:
	var a := rng.randf() * TAU
	var r := sqrt(rng.randf()) * reach
	var x: float = sp[0] + cos(a) * r
	return Vector3(x, TownLayout.ground_height(x), sp[1] + sin(a) * r)


func _straw(s: Array, rng: RandomNumberGenerator) -> void:
	var size: Array = _cfg.get("straw_size", [0.2, 0.012])
	var quad := QuadMesh.new()
	quad.size = Vector2(size[0], size[1])
	quad.orientation = PlaneMesh.FACE_Y
	var at: Array[Vector3] = []
	for sp: Array in s:
		for i in int(_cfg.get("straw_round_spot", 70)):
			at.append(_near(sp, float(_cfg.get("straw_spot_reach", 3.0)), rng))
	for i in int(_cfg.get("straw_loose", 500)):
		at.append(_box_point(rng))
	var mm := _multimesh(quad, at.size())
	for i in at.size():
		var b := Basis(Vector3.UP, rng.randf() * TAU).rotated(Vector3.FORWARD, rng.randf_range(-0.15, 0.15))
		var k := rng.randf_range(0.6, 1.4)
		mm.set_instance_transform(i, Transform3D(b.scaled(Vector3(k, 1.0, 1.0)), at[i] + Vector3.UP * 0.008))
	_add("Straw", mm, _colour("straw_colour", Color(0.78, 0.66, 0.38)), 0.9)


func _droppings(s: Array, rng: RandomNumberGenerator) -> void:
	var lump := SphereMesh.new()
	lump.radius = 0.045
	lump.height = 0.05
	lump.radial_segments = 6
	lump.rings = 3
	var rails := s.filter(func(sp: Array) -> bool: return sp[4])
	var at: Array[Vector3] = []
	for p in int(_cfg.get("droppings_piles", 26)):
		var c := _near(rails[rng.randi() % rails.size()], 2.5, rng) if not rails.is_empty() \
				and rng.randf() < float(_cfg.get("droppings_near_rails", 0.6)) else _box_point(rng)
		for k in rng.randi_range(3, 6):
			at.append(c + Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12)))
	var mm := _multimesh(lump, at.size())
	for i in at.size():
		var k := rng.randf_range(0.7, 1.3)
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(k, k * 0.8, k * 1.2)), at[i] + Vector3.UP * 0.012))
	_add("Droppings", mm, _colour("droppings_colour", Color(0.2, 0.15, 0.1)), 0.6)


func _multimesh(mesh: Mesh, n: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	return mm


func _colour(key: String, fallback: Color) -> Color:
	var c: Array = _cfg.get(key, [])
	return Color(c[0], c[1], c[2]) if c.size() >= 3 else fallback


func _add(n: String, mm: MultiMesh, colour: Color, roughness: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = roughness
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MultiMeshInstance3D.new()
	mi.name = n
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
