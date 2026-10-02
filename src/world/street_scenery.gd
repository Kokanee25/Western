class_name StreetScenery
extends Node3D
## Everything around the test buildings that isn't built from members: a placeholder church,
## sagebrush, rocks, distant hills, props. Deterministic from the seed.

@export var scenery_seed := 1882
@export var road_center_z := -8.4
@export var road_half_width := 6.0

var _rng := RandomNumberGenerator.new()
var _materials := {}


func _ready() -> void:
	var ground := get_node_or_null(^"../Ground/Mesh") as MeshInstance3D
	if ground and ground.mesh and ground.mesh.surface_get_material(0) is ShaderMaterial:
		PixelArt.track(ground.mesh.surface_get_material(0) as ShaderMaterial)
	_rng.seed = scenery_seed
	_build_blockouts()
	_build_props()
	_build_sagebrush()
	_build_hills()


func _mat(color: Color, rough := 0.9, textured := true) -> Material:
	var key := "%s:%s" % [color.to_html(), textured]
	if not _materials.has(key):
		if textured:
			# Blockouts get painted-board pixel art so they sit with the real buildings.
			var tex := PixelArt.painted("blockout:%s" % color.to_html(), color, Color(0.56, 0.48, 0.39), hash(key) % 1000, 0.25)
			_materials[key] = PixelArt.material(tex, Color.WHITE, PixelArt.Mapping.WORLD_TRIPLANAR, Vector3.ZERO, rough, 0.0, 0.5)
		else:
			var m := StandardMaterial3D.new()
			m.roughness = rough
			m.albedo_color = color
			_materials[key] = m
	return _materials[key]


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, collide := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


## The church at the far end of the street (a placeholder; the false fronts down the street are
## member-built now: StreetDressing).
func _build_blockouts() -> void:
	var root := Node3D.new()
	root.name = "TownBlockouts"
	add_child(root)
	# A church at the far end of the street.
	_box(root, Vector3(8.0, 5.0, 14.0), Vector3(-58.0, 2.5, 4.0), Color(0.78, 0.74, 0.66))
	_box(root, Vector3(3.0, 11.0, 3.0), Vector3(-58.0, 5.5, -4.0), Color(0.8, 0.76, 0.68))
	var spire := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 2.0
	cone.height = 5.0
	cone.radial_segments = 4
	spire.mesh = cone
	spire.material_override = _mat(Color(0.3, 0.26, 0.24))
	spire.position = Vector3(-58.0, 13.5, -4.0)
	spire.rotation.y = PI * 0.25
	root.add_child(spire)


func _build_props() -> void:
	var root := Node3D.new()
	root.name = "Props"
	add_child(root)
	# Barrels on the boardwalk and a couple of crates.
	for p in [Vector3(-1.2, 0.38, -0.6), Vector3(-1.85, 0.38, -0.5), Vector3(7.7, 0.0, -0.6)]:
		var barrel := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.26
		mesh.bottom_radius = 0.26
		mesh.height = 0.85
		mesh.radial_segments = 12
		barrel.mesh = mesh
		barrel.material_override = _mat(Color(0.4, 0.27, 0.16))
		barrel.position = p + Vector3(0.0, 0.425, 0.0)
		root.add_child(barrel)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.26
		shape.height = 0.85
		cs.shape = shape
		body.add_child(cs)
		barrel.add_child(body)
	_box(root, Vector3(0.6, 0.45, 0.5), Vector3(4.6, 0.38 + 0.225, -0.5), Color(0.55, 0.45, 0.3))
	_box(root, Vector3(0.5, 0.4, 0.45), Vector3(4.65, 0.83 + 0.2, -0.5), Color(0.5, 0.41, 0.28))
	# Fence posts marking the edge of town to the east.
	for i in 12:
		var z := 2.0 + i * 2.5
		_box(root, Vector3(0.12, 1.2, 0.12), Vector3(9.5 + _rng.randf_range(-0.1, 0.1), 0.6, z), Color(0.35, 0.28, 0.22))


func _build_sagebrush() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 0.7
	mesh.radial_segments = 7
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.44, 0.31)
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	mesh.material = mat
	mm.mesh = mesh
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	while transforms.size() < 400:
		var p := Vector3(_rng.randf_range(-120.0, 120.0), 0.0, _rng.randf_range(-120.0, 120.0))
		if absf(p.z - road_center_z) < road_half_width + 1.5:
			continue
		if p.x > -34.0 and p.x < 15.0 and p.z > -32.0 and p.z < 12.0:
			continue  # keep the built-up area clear
		var s := _rng.randf_range(0.4, 1.3)
		var t := Transform3D(Basis.from_scale(Vector3(s, s * _rng.randf_range(0.6, 0.9), s)).rotated(Vector3.UP, _rng.randf() * TAU), p + Vector3(0, s * 0.15, 0))
		transforms.append(t)
		colors.append(Color(1, 1, 1).lerp(Color(1.25, 1.15, 1.1), _rng.randf()))
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Sagebrush"
	mmi.multimesh = mm
	add_child(mmi)


func _build_hills() -> void:
	var root := Node3D.new()
	root.name = "Hills"
	add_child(root)
	var colors := [Color(0.55, 0.36, 0.25), Color(0.62, 0.45, 0.3), Color(0.45, 0.35, 0.3), Color(0.5, 0.4, 0.33)]
	for i in 16:
		var angle := float(i) / 16.0 * TAU + _rng.randf_range(-0.15, 0.15)
		var dist := _rng.randf_range(170.0, 260.0)
		var hill := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		mesh.radial_segments = 10
		mesh.rings = 5
		hill.mesh = mesh
		hill.material_override = _mat(colors[i % colors.size()], 1.0, false)
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var r := _rng.randf_range(40.0, 80.0)
		hill.scale = Vector3(r, _rng.randf_range(14.0, 38.0), r * _rng.randf_range(0.6, 1.0))
		hill.position = Vector3(cos(angle) * dist, -2.0, sin(angle) * dist)
		root.add_child(hill)
