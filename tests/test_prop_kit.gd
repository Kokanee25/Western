extends TestCase
## The prop kit (docs/briefs/prop-lab.md): kit props are built from their files as members and
## stand on the floor; a seated man's weight is on the seat; a leg shot or kicked out from under
## him tips the chair and he goes down with it; an empty chair kicked slides rather than breaks;
## when the floor under it goes, so does the prop; a blast pushes what it doesn't break.

var world: Node3D
var floor_s: Structure


## A stand-in for a seated man: his weight, going limp, falling (what KitProp asks of a HumanBody).
class Sitter:
	extends Node3D
	signal fell(conscious: bool)
	var limp := false
	var parts := {}

	func _init(kg := 80.0) -> void:
		var n := Node3D.new()
		n.set_meta(&"mass", kg)
		parts[&"pelvis"] = n

	func go_limp(_push := Vector3.ZERO) -> void:
		limp = true
		fell.emit(true)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			for n: Node in parts.values():
				n.free()


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
	# A floor of boards on joists, 0.3 m up: what a prop in a room stands on.
	floor_s = Structure.new()
	floor_s.structure_id = &"floor"
	world.add_child(floor_s)
	for x in [-1.0, 1.0]:
		floor_s.add_member("joist%d" % int(x), &"joist", &"framing", Vector3(0.05, 0.25, 3.0), Vector3(x, 0.125, 0))
	for i in 12:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(2.4, 0.05, 0.25), Vector3(0, 0.275, -1.375 + 0.25 * i))
	floor_s.infer_supports()


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _place(id: StringName, at := Vector3(0, 0.3, 0), yaw := 0.0) -> KitProp:
	var p := PropKit.spawn(id)
	p.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	return p


func _m(p: KitProp, id: String) -> StructureMember:
	return p.get_member(StringName("%s/%s" % [p.structure_id, id]))


func test_every_kit_file_builds_and_stands() -> void:
	check(PropKit.ids().size() >= 2, "the chair and the card table are in the kit")
	for id in PropKit.ids():
		var p := await _place(id)
		var def := PropKit.definition(id)
		check(p.member_count() >= 8, "%s is built of members (%d)" % [id, p.member_count()])
		check(p.settle().is_empty(), "%s stands: nothing breaks or falls" % id)
		check(not p.loose, "%s stands on its feet" % id)
		check(p.batch_count() <= 3, "%s draws untouched in a few batches (%d)" % [id, p.batch_count()])
		check(not def.get("replaces", "").is_empty(), "%s names the drawn prop it replaces" % id)
		var size: Vector3 = PropLibrary.size_of(StringName(def.replaces))
		var box := AABB()
		for m in p.get_members():
			box = m.structure_aabb() if box.size == Vector3.ZERO else box.merge(m.structure_aabb())
		check_near(box.size.y, size.y, 0.03, "%s stands as tall as the drawn one" % id)
		p.queue_free()
		await physics_frames(1)


func test_a_seated_man_is_on_the_seat_and_the_chair_holds_him() -> void:
	var chair := await _place(&"chair")
	var man := Sitter.new(80.0)
	world.add_child(man)
	check(chair.sit(man), "he sits")
	check_near(_m(chair, "seat").extra_load, 80.0 * 0.75 * 9.81, 1.0, "three quarters of his weight on the seat")
	await physics_frames(3)
	check(chair.settle().is_empty(), "an oak chair carries him")
	check(not chair.loose and not man.limp, "he's still sat")


func test_a_back_leg_out_from_under_him_tips_him_over() -> void:
	var chair := await _place(&"chair")
	var man := Sitter.new(80.0)
	world.add_child(man)
	chair.sit(man)
	await physics_frames(2)
	chair.break_member(_m(chair, "post_back_l"))
	await physics_frames(3)
	check(chair.loose, "the chair goes over")
	check(man.limp, "and he goes down with it")
	check(chair.rubble.any(func(rb: RigidBody3D) -> bool: return is_instance_valid(rb) and (rb.get_meta(&"members", []) as Array).size() >= 8),
			"what's left of it falls as one piece")


func test_an_empty_chair_stands_on_three_legs() -> void:
	var chair := await _place(&"chair")
	chair.break_member(_m(chair, "leg_front_l"))
	await physics_frames(3)
	check(not chair.loose, "an empty chair with a front leg gone still stands (its weight's over the other three)")


func test_a_ball_through_a_leg_splits_it() -> void:
	var chair := await _place(&"chair")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var leg := _m(chair, "leg_front_l")
	var from := leg.global_position + Vector3(-5, 0, 0)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (leg.global_position - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	check(leg.broken, "a .45 ball through a 35 mm oak leg splits it (section left %.2f)" % leg.section_left(chair.tuning))


func test_a_kick_slides_an_empty_chair_but_breaks_the_leg_under_a_man() -> void:
	var chair := await _place(&"chair")
	var leg := _m(chair, "leg_front_l")
	# A hard kick: a leg of ~8 kg at 6 m/s.
	var kick := Vector3(48.0, 0, 0)
	check_eq(chair.take_blow(leg, leg.global_position, kick), &"moved", "the empty chair goes skidding")
	check(not leg.has_meta(&"snapped") and chair.rubble.any(func(rb: RigidBody3D) -> bool:
			return is_instance_valid(rb) and (rb.get_meta(&"members", []) as Array).has(leg.member_id) \
				and (rb.get_meta(&"members", []) as Array).size() == chair.member_count()), "its leg holds: it goes whole")
	var chair2 := await _place(&"chair", Vector3(0, 0.3, 1.0))
	var man := Sitter.new(80.0)
	world.add_child(man)
	chair2.sit(man)
	var leg2 := _m(chair2, "leg_front_l")
	check_eq(chair2.take_blow(leg2, leg2.global_position, kick), &"broke", "pinned under him, the leg snaps")
	check(leg2.has_meta(&"snapped") or leg2.broken, "the leg's broken")
	await physics_frames(3)
	check(man.limp, "and he goes down (his weight was over that corner by less than he sways)")


func test_when_the_floor_under_it_goes_so_does_the_table() -> void:
	var table := await _place(&"card_table")
	check(table.footprint().size() >= 3, "it stands on its feet")
	for m in floor_s.get_members():
		if m.kind == &"floor_board" and absf(m.position.z) < 0.6:
			floor_s.break_member(m)
	await physics_frames(int(KitProp.CHECK_EVERY * 60.0) + 4)
	check(table.loose, "the boards gone from under its feet, it falls")


func test_a_blast_close_by_knocks_the_chair_over() -> void:
	var chair := await _place(&"chair")
	# Far enough that the blast breaks nothing of it, close enough to throw it.
	Events.exploded.emit(chair.global_position + Vector3(-1.5, 0.1, 0), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(chair.loose, "a stick 1.5 m off throws it")
	var far := await _place(&"chair", Vector3(0, 0.3, 1.0))
	Events.exploded.emit(far.global_position + Vector3(-12, 0.1, 0), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(not far.loose, "12 m off it stays put")
