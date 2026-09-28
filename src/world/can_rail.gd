class_name CanRail
extends Structure
## A rail on two posts with tin cans lined up on it. Cans are loose physics objects: a bullet goes
## through the tin and knocks them flying. Rail runs along +X.

@export var length := 2.4
@export var can_count := 6

var cans: Array[RigidBody3D] = []

static var _tin: StandardMaterial3D


func build() -> void:
	for i in 2:
		var x := 0.06 if i == 0 else length - 0.06
		add_member("post%d" % i, &"post", &"framing", Vector3(0.1, 1.1, 0.1), Vector3(x, 0.55, 0.0))
	add_member("rail", &"beam", &"weathered_pine", Vector3(length + 0.1, 0.08, 0.12), Vector3(length * 0.5, 1.14, 0.0))
	for c in cans:
		if is_instance_valid(c):
			c.free()
	cans.clear()
	for i in can_count:
		var can := RigidBody3D.new()
		can.name = "Can%d" % i
		can.mass = 0.06
		can.set_meta(&"ballistic_thickness", 0.0004)
		can.add_to_group(&"cans")
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.034
		cyl.height = 0.12
		shape.shape = cyl
		can.add_child(shape)
		GunParts.tube(can, "Tin", 0.034, 0.12, Vector3.ZERO, _tin_material(), 10, Vector3.ZERO)
		add_child(can)
		can.position = Vector3(0.25 + i * (length - 0.5) / maxf(can_count - 1, 1), 1.18 + 0.06, 0.0)
		can.sleeping = true
		cans.append(can)


static func _tin_material() -> StandardMaterial3D:
	if _tin == null:
		_tin = GunParts.material("tin", PixelArt.metal("tin", Color(0.62, 0.6, 0.55), 111), 0.8, 0.4)
	return _tin
