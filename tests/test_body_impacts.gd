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


## A railing on the ground along x at z = -0.5 (the game's railing part): newels at its ends and
## middle, and between them a bay of balusters every 0.12 under a 70 x 60 oak cap at 1.0.
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
		Railing.build(s, "bay_%d" % span, Vector3(a + 0.045, 0.05, -0.5), Vector3(a + 1.155, 0.05, -0.5),
				{"height": 0.95, "spacing": 0.12, "rail": Vector2(0.07, 0.06), "overhang": 0.0})
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
	check(gone.has(&"test_rail/bay_1/rail/00"), "the cap he hit broke (%s)" % [gone])
	check(gone.size() >= 3, "and the balusters in his way with it (%d)" % gone.size())
	check(not gone.has(&"test_rail/newel_-12"), "the far newel stands (only what he hit went)")


func test_he_carries_on_through_the_railing_he_breaks() -> void:
	# The rail takes only what breaks it; the rest of what the engine took from him goes back
	# (BodyImpacts._give_back): a member that took four times what it could hold gives back half
	# the impulse (energy goes with its square), and one that held gives back nothing.
	var part := RigidBody3D.new()
	part.mass = 10.0
	part.gravity_scale = 0.0
	part.linear_damp = 0.0
	world.add_child(part)
	BodyImpacts._give_back({part: Vector3(0, 0, 20)}, 4.0, 1.0)
	await physics_frames(1)
	check_near(part.linear_velocity.z, -1.0, 0.02, "half the 20 N·s back on 10 kg: 1 m/s on through")
	part.linear_velocity = Vector3.ZERO
	BodyImpacts._give_back({part: Vector3(0, 0, 20)}, 1.0, 1.0)
	await physics_frames(1)
	check_near(part.linear_velocity.z, 0.0, 0.001, "a member that held gives nothing back")


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


## The prop kit's chair, standing at `at` facing +z (its seat toward him).
func _kit_chair(at: Vector3) -> KitProp:
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_position = at
	return chair


func test_a_man_thrown_into_a_kit_chair_knocks_it_over() -> void:
	# A kit prop takes him as a blow on its own terms (KitProp.take_blow), not by the timber rule.
	var chair := _kit_chair(Vector3(0, 0, -0.6))
	await physics_frames(5)
	var man := _man(Vector3(0, 0.05, 0.4))
	await physics_frames(2)
	man.go_limp()
	for rb: Variant in man.parts.values():
		(rb as RigidBody3D).linear_velocity = Vector3(0, 0, -3.0)
	await physics_frames(90)
	check(chair.loose, "the chair goes over or skids away under him")


func test_a_slow_touch_leaves_a_kit_chair_standing() -> void:
	# A part drifting into it under BodyImpacts.QUIET_SPEED (a man lying against it, settling) is
	# no blow; at a run it is. (A man fainting back onto a chair does knock it: ~2 m/s into 5 kg.)
	var chair := _kit_chair(Vector3(0, 0, -0.6))
	await physics_frames(5)
	var leg := chair.get_member(StringName("%s/post_back_l" % chair.structure_id))
	var part := RigidBody3D.new()
	part.mass = 5.0
	world.add_child(part)
	var impacts := BodyImpacts.new()
	var kit := {}
	impacts._kit_contact(kit, chair, leg, part, Vector3(0, 0, 1), Vector3(0, 0, -0.4), leg.global_position)
	check(kit.is_empty(), "0.4 m/s into it brings it nothing")
	impacts._kit_contact(kit, chair, leg, part, Vector3(0, 0, 1), Vector3(0, 0, -3.0), leg.global_position)
	check_near(float((kit[chair] as Array)[1]), 5.0, 0.01, "3 m/s into it: a blow from the part's 5 kg")
	impacts._kit_blows(kit, [] as Array[StructureMember])
	check(chair.loose or leg.broken, "and the chair goes over or its leg breaks")


## Issue #446 (HumanBody.keep_stride): shot in the back at a run toward a card table, he keeps his
## speed into it and it skids off with him (0.16-0.34 m over eight starts a few centimetres apart)
## and goes over about half the time (its feet reach nearly as far as its top: pushed at the rim it
## would rather slide). Before, the stumble braked him, `_slide`
## stopped him at it, and a hit on a kit prop counted only the few parts touching it (a hand, a
## shin: a blow from a kilo or two), so he knelt against its foot and it stood (Sean, 2026-10-28:
## "that table doesn't move or flip").
func test_shot_running_he_takes_a_card_table_with_him() -> void:
	HumanBody.keep_stride = true
	var table := PropLibrary.spawn(&"card_table") as KitProp
	world.add_child(table)
	table.global_position = Vector3(0, 0, -3.0)
	await physics_frames(5)
	var man := _man(Vector3.ZERO)
	await physics_frames(2)
	for i in 22:  # 0.37 s at a run: hit 1.2 m short of its near edge
		man.walk_to(Vector3(0, 0, -10), 3.5, 1.0 / 60.0)
		await physics_frames(1)
	var chest := man.parts[&"chest"] as Node3D
	man._knocked(&"chest", chest.global_position + man.global_basis.z * 0.12, -man.global_basis.z, 4.5)
	await physics_frames(240)
	HumanBody.keep_stride = HumanBody.KEEP_STRIDE_GAME
	check(table.loose, "the table's knocked loose")
	var moved := 0.0
	var tilt := 0.0
	for rb: Variant in table.rubble:
		if is_instance_valid(rb):
			var p := (rb as Node3D).global_position
			moved = maxf(moved, Vector2(p.x, p.z + 3.0).length())
			tilt = maxf(tilt, rad_to_deg((rb as Node3D).global_basis.y.angle_to(Vector3.UP)))
	print("  the table moved %.2f m, tipped %.0f deg" % [moved, tilt])
	check(moved > 0.12 or tilt > 30.0, "and it skidded off or went over (%.2f m, %.0f deg)" % [moved, tilt])
