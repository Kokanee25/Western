extends TestCase
## A limp man thrown into timber breaks it (BodyImpacts): through a 1 m railing at a run, not by
## slumping against it, and never through boards he lands on from above (Sean, 2026-10-21).

var world: Node3D
var rail: Structure


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


## A railing on the ground along x at z = -0.5: newels at its ends and middle, balusters every 0.12,
## a 70 x 60 oak cap at 1.0 in two spans (the walkway's, as the lab builds it).
func _railing() -> Structure:
	var s := Structure.new()
	s.structure_id = &"test_rail"
	world.add_child(s)
	# A sill on the ground (tier 0: grounded), so the railing has its load path.
	s.add_member("deck", &"sill", &"floor", Vector3(4.0, 0.05, 2.0), Vector3(0, 0.025, 0.45))
	for x: float in [-1.2, 0.0, 1.2]:
		s.add_member("newel_%d" % int(x * 10), &"furniture_frame", &"dark_trim", Vector3(0.09, 0.95, 0.09), Vector3(x, 0.525, -0.5))
	for span in 2:
		var a := -1.2 + 1.2 * span
		for k in range(1, 10):
			s.add_member("baluster_%d_%d" % [span, k], &"trim", &"dark_trim", Vector3(0.035, 0.89, 0.035),
					Vector3(a + 0.12 * k, 0.05 + 0.445, -0.5))
		s.add_member("cap_%d" % span, &"trim", &"dark_trim", Vector3(1.11, 0.06, 0.07), Vector3(a + 0.6, 0.97, -0.5))
	s.infer_supports()
	return s


func _man(at: Vector3, yaw := 0.0) -> HumanBody:
	var man := HumanBody.new()
	world.add_child(man)
	man.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	return man


func _broken(s: Structure) -> Array[StringName]:
	var out: Array[StringName] = []
	for m in s.get_members():
		if m.broken:
			out.append(m.member_id)
	return out


func test_a_man_thrown_into_a_railing_at_a_run_breaks_it() -> void:
	var s := _railing()
	var man := _man(Vector3(0.6, 0.05, 0.6))
	await physics_frames(2)
	man.go_limp()
	for rb: Variant in man.parts.values():
		(rb as RigidBody3D).linear_velocity = Vector3(0, 0, -3.5)
	await physics_frames(120)
	var gone := _broken(s)
	check(gone.has(&"test_rail/cap_1"), "the cap he hit broke (%s)" % [gone])
	check(gone.size() >= 3, "and the balusters in his way with it (%d)" % gone.size())
	check(not gone.has(&"test_rail/newel_-12"), "the far newel stands (only what he hit went)")


func test_he_carries_on_through_the_railing_he_breaks() -> void:
	# The rail takes only what breaks it; the rest of his speed goes on with him (BodyImpacts
	# _give_back): through it, not stopped dead at it.
	_railing()
	var man := _man(Vector3(0.6, 0.05, 0.6))
	await physics_frames(2)
	man.go_limp()
	for rb: Variant in man.parts.values():
		(rb as RigidBody3D).linear_velocity = Vector3(0, 0, -3.5)
	var chest := man.parts[&"chest"] as RigidBody3D
	await physics_frames(24)
	check(chest.linear_velocity.z < -1.0, "his chest still going on through at 0.4 s (%.2f m/s)" % chest.linear_velocity.z)


func test_slumping_against_a_railing_breaks_nothing() -> void:
	var s := _railing()
	var man := _man(Vector3(0.6, 0.05, -0.2), PI)
	await physics_frames(2)
	man.go_limp()
	await physics_frames(240)
	check_eq(_broken(s).size(), 0, "a faint against it leaves it whole")


func test_a_man_dropped_onto_boards_breaks_none() -> void:
	var s := Structure.new()
	s.structure_id = &"test_floor"
	world.add_child(s)
	for i in 8:
		s.add_member("board_%d" % i, &"floor_board", &"floor", Vector3(3.0, 0.025, 0.14), Vector3(0, 0.0125, -0.6 + 0.15 * i))
	s.infer_supports()
	var man := _man(Vector3(0, 1.6, 0))
	await physics_frames(2)
	man.go_limp()
	for rb: Variant in man.parts.values():
		(rb as RigidBody3D).linear_velocity = Vector3(0.5, -2.0, 0.0)
	await physics_frames(180)
	check_eq(_broken(s).size(), 0, "boards bear a man landing on them")
