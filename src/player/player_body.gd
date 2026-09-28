class_name PlayerBody
extends Node3D
## The body you see when you look down: shirt and vest, gun belt and holster, legs and boots.
## Placeholder primitives until real character models. The head, hat and arms only cast shadows,
## so your shadow on the street is a whole person without blocking the camera.

const HIP_HEIGHT := 0.95
const CROUCH_HIP_HEIGHT := 0.5
const THIGH := 0.46
const SHIN := 0.41
## The body sits a little behind the eyes; looking down pushes it further back so you see your boots.
const BACK_OFFSET := 0.08
const LOOK_DOWN_BACK_OFFSET := 0.14

var _hips: Node3D
var _torso: Node3D
var _thighs: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _stride_amount := 0.0

static var _materials := {}


func _ready() -> void:
	_build()


func _build() -> void:
	_hips = Node3D.new()
	_hips.name = "Hips"
	_hips.position = Vector3(0.0, HIP_HEIGHT, BACK_OFFSET)
	add_child(_hips)

	_torso = Node3D.new()
	_torso.name = "Torso"
	_hips.add_child(_torso)
	_box(_torso, "Shirt", Vector3(0.36, 0.56, 0.2), Vector3(0.0, 0.31, 0.0), _mat(&"shirt", Color(0.74, 0.67, 0.54)))
	_box(_torso, "Vest", Vector3(0.37, 0.4, 0.21), Vector3(0.0, 0.3, 0.0), _mat(&"vest", Color(0.24, 0.17, 0.12)))
	_box(_torso, "Belt", Vector3(0.38, 0.06, 0.215), Vector3(0.0, 0.04, 0.0), _mat(&"leather", Color(0.36, 0.2, 0.1)))
	_box(_torso, "Buckle", Vector3(0.05, 0.04, 0.01), Vector3(0.0, 0.04, -0.11), _mat(&"brass", Color(0.7, 0.55, 0.25), 0.6))
	_box(_torso, "Holster", Vector3(0.05, 0.22, 0.1), Vector3(0.215, -0.08, 0.0), _mat(&"leather", Color(0.36, 0.2, 0.1)))
	var grip := _box(_torso, "RevolverGrip", Vector3(0.035, 0.1, 0.035), Vector3(0.215, 0.06, 0.03), _mat(&"walnut", Color(0.2, 0.12, 0.07)))
	grip.rotation.x = deg_to_rad(-25.0)

	# Shadow-only parts: you never see them, the sun does.
	var shadow := GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_sphere(_torso, "Head", 0.11, Vector3(0.0, 0.72, -0.02), _mat(&"skin", Color(0.72, 0.53, 0.4))).cast_shadow = shadow
	_cylinder(_torso, "HatBrim", 0.23, 0.02, Vector3(0.0, 0.8, -0.02), _mat(&"hat", Color(0.3, 0.22, 0.15))).cast_shadow = shadow
	_cylinder(_torso, "HatCrown", 0.11, 0.13, Vector3(0.0, 0.87, -0.02), _mat(&"hat", Color(0.3, 0.22, 0.15))).cast_shadow = shadow
	for side in [-1.0, 1.0]:
		var arm := _capsule(_torso, "Arm", 0.05, 0.62, Vector3(side * 0.23, 0.26, 0.0), _mat(&"shirt", Color(0.74, 0.67, 0.54)))
		arm.cast_shadow = shadow

	for side in [-1.0, 1.0]:
		var thigh := Node3D.new()
		thigh.name = "ThighL" if side < 0.0 else "ThighR"
		thigh.position = Vector3(side * 0.1, 0.0, 0.0)
		_hips.add_child(thigh)
		_capsule(thigh, "Thigh", 0.08, THIGH + 0.08, Vector3(0.0, -THIGH * 0.5, 0.0), _mat(&"trousers", Color(0.3, 0.27, 0.24)))
		var knee := Node3D.new()
		knee.name = "Knee"
		knee.position = Vector3(0.0, -THIGH, 0.0)
		thigh.add_child(knee)
		_capsule(knee, "Shin", 0.065, SHIN, Vector3(0.0, -SHIN * 0.5, 0.0), _mat(&"trousers", Color(0.3, 0.27, 0.24)))
		_box(knee, "Boot", Vector3(0.11, 0.2, 0.27), Vector3(0.0, -SHIN + 0.02, -0.05), _mat(&"boot", Color(0.17, 0.1, 0.06)))
		_thighs.append(thigh)
		_knees.append(knee)


## Pose the body for this frame. crouch is 0 (standing) to 1 (crouched); stride_phase counts head
## bobs, two per stride; pitch is the view pitch in degrees.
func update_pose(delta: float, speed: float, crouch: float, on_floor: bool, stride_phase: float, pitch: float) -> void:
	var look_down := clampf(-pitch / 80.0, 0.0, 1.0)
	_hips.position = Vector3(0.0, lerpf(HIP_HEIGHT, CROUCH_HIP_HEIGHT, crouch), BACK_OFFSET + LOOK_DOWN_BACK_OFFSET * look_down)
	var target_stride := clampf(speed / 3.0, 0.0, 1.3) if on_floor else 0.3
	_stride_amount = move_toward(_stride_amount, target_stride, delta * 4.0)
	var swing := sin(stride_phase * PI) * 0.45 * _stride_amount
	for i in 2:
		var s := swing if i == 0 else -swing
		var thigh_angle := lerpf(s, deg_to_rad(80.0), crouch)
		var knee_angle := lerpf(-maxf(0.0, -s) * 1.4 - 0.05, deg_to_rad(-120.0), crouch)
		_thighs[i].rotation.x = thigh_angle
		_knees[i].rotation.x = knee_angle


func _box(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(parent, n, mesh, pos, mat)


func _sphere(parent: Node3D, n: String, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _instance(parent, n, mesh, pos, mat)


func _cylinder(parent: Node3D, n: String, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return _instance(parent, n, mesh, pos, mat)


func _capsule(parent: Node3D, n: String, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	return _instance(parent, n, mesh, pos, mat)


func _instance(parent: Node3D, n: String, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _mat(id: StringName, color: Color, metallic := 0.0) -> StandardMaterial3D:
	if not _materials.has(id):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.85
		m.metallic = metallic
		_materials[id] = m
	return _materials[id]
