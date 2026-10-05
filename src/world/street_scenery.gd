class_name StreetScenery
extends Node3D
## Everything around the town that isn't built from members: sagebrush (the country beyond is the painted Backdrop; the street's props are StreetDressing's). Deterministic from the
## seed.

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
	_build_sagebrush()


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
