extends TestCase
## A piece a man's boot just broke off goes away at his boot's speed, against his own leg: it isn't
## a blow on him (Structure._on_rubble_hit, `broken_by` set by HumanBody's clip blow; No Law's kicked
## chair, where Cody went down to his own kick's spindle, #887). Anyone else it hits, it hurts; and
## once the moment's past, him too.


class Struck extends Node:
	var blows := 0

	func take_blow(_c: Node3D, _j: float, _at: Vector3, _dir := Vector3.DOWN, _p := -1.0) -> PackedStringArray:
		blows += 1
		return PackedStringArray()


var s: Structure
var made: Array[Node] = []


func after_each() -> void:
	for n in made:
		if is_instance_valid(n):
			n.queue_free()
	made.clear()
	await physics_frames(2)


func _piece() -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.mass = 1.5
	rb.set_meta(&"v", Vector3(6.7, 0.0, 0.0))
	s.add_child(rb)
	return rb


func _leg_of(man: Struck) -> Node:
	var leg := Node3D.new()
	leg.set_meta(&"human_body", man)
	man.add_child(leg)
	return leg


func _setup() -> Array[Struck]:
	s = Structure.new()
	add_child(s)
	made.append(s)
	var kicker := Struck.new()
	var other := Struck.new()
	for n: Node in [kicker, other]:
		add_child(n)
		made.append(n)
	await physics_frames(2)
	return [kicker, other]


func test_the_piece_his_boot_broke_spares_him() -> void:
	var men := await _setup()
	var kicker := men[0]
	var other := men[1]
	s.set_meta(&"broken_by", [kicker, Engine.get_physics_frames()])
	s._on_rubble_hit(_leg_of(kicker), _piece())
	s._on_rubble_hit(_leg_of(other), _piece())
	await physics_frames(2)
	check_eq(kicker.blows, 0, "the man who broke it isn't hurt by its piece")
	check_eq(other.blows, 1, "another man it hits is")


func test_after_the_moment_it_hurts_him_too() -> void:
	var men := await _setup()
	var kicker := men[0]
	s.set_meta(&"broken_by", [kicker, Engine.get_physics_frames() - Structure.BREAKER_SPARED_FRAMES - 5])
	s._on_rubble_hit(_leg_of(kicker), _piece())
	await physics_frames(2)
	check_eq(kicker.blows, 1, "a piece coming down on him later still does")
