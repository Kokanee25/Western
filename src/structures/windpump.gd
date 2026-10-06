class_name Windpump
extends Structure
## A windpump: a timber tower on four legs with girts and braces, a platform at the top, and the
## wheel and tail turning into the wind; its rod works the pump at the foot, which fills the
## stock tank beside it (a WaterTrough of its own in the scene). The wheel and tail are drawn,
## not members (they come down with the platform: Fittings). Centred on its origin.

@export var height := 7.5
@export var spread := 1.2
@export var wheel_radius := 1.4
## Turns a second in a light breeze.
@export var turns := 0.35

var _wheel: Node3D


func build() -> void:
	var half := spread * 0.5
	for i in 4:
		var x := half * (1.0 if i % 2 == 0 else -1.0)
		var z := half * (1.0 if i < 2 else -1.0)
		add_member("leg%d" % i, &"post", &"framing", Vector3(0.1, height, 0.1), Vector3(x, height * 0.5, z))
	var girts := 3
	for g in girts:
		var y := height * (g + 1) / (girts + 1)
		for side in 2:
			var z := half * (1.0 if side == 0 else -1.0)
			add_member("girt%d/x%d" % [g, side], &"beam", &"weathered_pine", Vector3(spread + 0.1, 0.08, 0.05), Vector3(0.0, y, z + 0.075 * (1.0 if side == 0 else -1.0)))
			var x := half * (1.0 if side == 0 else -1.0)
			add_member("girt%d/z%d" % [g, side], &"beam", &"weathered_pine", Vector3(0.05, 0.08, spread + 0.1), Vector3(x + 0.075 * (1.0 if side == 0 else -1.0), y, 0.0))
	add_member("platform", &"floor_board", &"floor", Vector3(spread + 0.5, 0.05, spread + 0.5), Vector3(0.0, height + 0.025, 0.0))
	add_member("rod", &"trim", &"iron", Vector3(0.025, height - 0.4, 0.025), Vector3(0.0, (height - 0.4) * 0.5 + 0.4, 0.0))
	add_member("pump", &"post", &"iron", Vector3(0.16, 0.8, 0.16), Vector3(0.0, 0.4, 0.0))
	add_member("spout", &"trim", &"iron", Vector3(0.6, 0.05, 0.05), Vector3(0.38, 0.7, 0.0))
	_build_wheel()


func _build_wheel() -> void:
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, height + 0.35, 0.0)
	add_child(head)
	var mat := WoodMaterials.get_material(&"iron", 0)
	var hub := MeshInstance3D.new()
	hub.name = "Hub"
	var hub_mesh := BoxMesh.new()
	hub_mesh.size = Vector3(0.18, 0.18, 0.5)
	hub.mesh = hub_mesh
	hub.material_override = mat
	head.add_child(hub)
	_wheel = Node3D.new()
	_wheel.name = "Wheel"
	_wheel.position = Vector3(0.0, 0.0, -0.3)
	head.add_child(_wheel)
	var blades := 16
	var blade := BoxMesh.new()
	blade.size = Vector3(0.22, wheel_radius * 0.6, 0.01)
	var vane_mat := WoodMaterials.get_material(&"weathered_pine", 1)
	for i in blades:
		var b := MeshInstance3D.new()
		b.mesh = blade
		b.material_override = vane_mat
		var a := TAU * i / blades
		var basis := Basis(Vector3.BACK, a) * Basis(Vector3.UP, deg_to_rad(25.0))
		b.transform = Transform3D(basis, basis * Vector3(0.0, wheel_radius * 0.65, 0.0))
		_wheel.add_child(b)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = wheel_radius - 0.04
	torus.outer_radius = wheel_radius
	torus.rings = 24
	ring.mesh = torus
	ring.material_override = mat
	ring.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	_wheel.add_child(ring)
	var tail := MeshInstance3D.new()
	tail.name = "Tail"
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.02, 0.7, 1.2)
	tail.mesh = tail_mesh
	tail.material_override = vane_mat
	tail.position = Vector3(0.0, 0.15, 1.0)
	head.add_child(tail)


func _process(delta: float) -> void:
	if _wheel and is_instance_valid(_wheel):
		_wheel.rotate_z(TAU * turns * delta)
