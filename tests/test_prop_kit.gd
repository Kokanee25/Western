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
	# A floor of boards on joists, 0.3 m up: what a prop in a room stands on (3.4 m: the bar fits).
	floor_s = Structure.new()
	floor_s.structure_id = &"floor"
	world.add_child(floor_s)
	for x in [-1.0, 1.0]:
		floor_s.add_member("joist%d" % int(x), &"joist", &"framing", Vector3(0.05, 0.25, 3.0), Vector3(x, 0.125, 0))
	for i in 12:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(3.4, 0.05, 0.25), Vector3(0, 0.275, -1.375 + 0.25 * i))
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
		var def := PropKit.definition(id)
		if String(def.get("kind", "members")) != "members" or def.has("hangs"):
			continue  # props that shatter: tests/test_glass_props.gd; hung ones: test_wall_props.gd
		# Its box's middle over the floor's (a trough's origin is at its end).
		var mid := PropKit.bounds(def).get_center()
		var p := await _place(id, Vector3(-mid.x, 0.3, -mid.z))
		# A fixture (a counter, shelves) may be few: its long boards.
		check(p.member_count() >= (3 if def.get("fixture", false) else 8), "%s is built of members (%d)" % [id, p.member_count()])
		check(p.settle().is_empty(), "%s stands: nothing breaks or falls" % id)
		check(not p.loose, "%s stands on its feet" % id)
		check(p.batch_count() <= 3, "%s draws untouched in a few batches (%d)" % [id, p.batch_count()])
		# A fixture (the bar) is new to the game: it replaces no drawn prop.
		check(not def.get("replaces", "").is_empty() or def.get("fixture", false), "%s names the drawn prop it replaces" % id)
		if def.has("replaces"):
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
	# Sat back, his weight's 5 cm inside the other three legs, and what's left of the kick pushes
	# away from the corner that's gone: he stays on three legs (a back leg out tips him: above).
	check(not man.limp and not chair2.loose, "a front leg kicked out from under a man sat back leaves him on three legs")


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


func test_a_stick_beside_the_table_throws_it_over_and_brings_its_lamp_down() -> void:
	var fittings := Fittings.new()
	world.add_child(fittings)
	var table := PropKit.spawn(&"card_table")
	table.position = Vector3(0, 0.3, 0)
	world.add_child(table)
	# The lamp on it, in a structure's props as the saloon's are (Fittings takes those).
	var props := Node3D.new()
	props.name = "Props"
	floor_s.add_child(props)
	var lamp := OilLamp.new()
	props.add_child(lamp)
	lamp.global_position = table.global_position + Vector3(0.12, 0.761, -0.1)
	await physics_frames(Fittings.SETTLE_FRAMES + 4)
	check(fittings.items.any(func(it: Dictionary) -> bool: return it.node == lamp), "the lamp stands on the table (a fitting)")
	Blast.detonate(world, table.global_position + Vector3(-1.0, 0.02, 0), Blast.t().tnt_per_stick)
	await physics_frames(40)
	check(table.loose, "the table's thrown")
	var top: Vector3 = table.get_meta(&"blast_push", Vector3.ZERO)
	check(top.y > 0.0 and top.length() / 46.0 > 1.0, "the blast lifts it, faster than a metre a second (%s N·s)" % top)
	check(fittings.items.any(func(it: Dictionary) -> bool: return it.node == lamp and it.down), "the lamp comes down with it")


func test_both_back_legs_out_from_under_him_the_stretchers_tear_out_and_it_goes_over() -> void:
	var chair := await _place(&"chair")
	var man := Sitter.new(80.0)
	world.add_child(man)
	chair.sit(man)
	await physics_frames(2)
	chair.break_members([_m(chair, "post_back_l"), _m(chair, "post_back_r")] as Array[StructureMember], [Vector3.ZERO, Vector3.ZERO] as Array[Vector3])
	await physics_frames(3)
	check(chair.loose and man.limp, "the chair goes over with him")
	for side in ["l", "r"]:
		var st := _m(chair, "stretcher_" + side)
		check(chair.rubble.any(func(rb: Variant) -> bool: return is_instance_valid(rb) and (rb as Node).get_meta(&"members", []) == [st.member_id]),
				"the %s stretcher, its back leg gone, tears out at the front leg (no skid under it)" % side)


func test_a_kick_at_a_back_leg_under_him_breaks_it() -> void:
	var chair := await _place(&"chair")
	var man := Sitter.new(80.0)
	world.add_child(man)
	chair.sit(man)
	var post := _m(chair, "post_back_l")
	var at := Vector3(post.global_position.x, 0.42, post.global_position.z)
	check_eq(chair.take_blow(post, at, Vector3(0, 0, 48.0)), &"broke", "the back post's stretch below the seat takes the kick and breaks")


func test_a_hard_sweep_kick_takes_both_back_legs_and_a_soft_one_only_the_first() -> void:
	for kick in [80.0, 48.0]:
		var chair := await _place(&"chair", Vector3(0, 0.3, 0.0 if kick > 60.0 else 1.2))
		var man := Sitter.new(80.0)
		world.add_child(man)
		chair.sit(man)
		await physics_frames(1)
		var near := _m(chair, "post_back_l")
		var far := _m(chair, "post_back_r")
		var at := Vector3(near.global_position.x - 0.02, 0.42, near.global_position.z)
		chair.take_blow(near, at, Vector3(kick, 0, 0))
		await physics_frames(2)
		check(near.has_meta(&"snapped") or near.broken, "%d N·s: the near back leg goes" % kick)
		if kick > 60.0:
			check(far.has_meta(&"snapped"), "80 N·s: the boot carries on through the far one too")
		else:
			check(not far.has_meta(&"snapped"), "48 N·s: what's left of the boot doesn't break the far one")


func test_a_ball_through_a_barrel_holes_its_staves_and_it_stands() -> void:
	var barrel := await _place(&"barrel")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var stave := _m(barrel, "stave10")
	var from := stave.global_position + Vector3(-5, 0, 0)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (stave.global_position - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	check(not stave.broken, "a .45 hole in a 12 cm oak stave leaves it whole (section left %.2f)" % stave.section_left(barrel.tuning))
	check(not barrel.loose, "the barrel stands")


func test_a_kicked_barrel_moves_whole_and_a_stick_close_by_throws_it() -> void:
	var barrel := await _place(&"barrel")
	var stave := _m(barrel, "stave10")
	check_eq(barrel.take_blow(stave, stave.global_position, Vector3(48.0, 0, 0)), &"moved", "oak staves don't break to a kick: it moves")
	check(barrel.rubble.any(func(rb: RigidBody3D) -> bool: return is_instance_valid(rb) and (rb.get_meta(&"members", []) as Array).size() == barrel.member_count()),
			"hooped, it goes as one piece")
	var other := await _place(&"barrel", Vector3(0, 0.3, 1.5))
	Events.exploded.emit(other.global_position + Vector3(-1.5, 0.1, 0), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(other.loose, "a stick 1.5 m off throws it")


func test_a_crate_stacked_on_another_comes_down_when_the_one_under_it_goes() -> void:
	var under := await _place(&"crate")
	var top := await _place(&"crate", Vector3(0, 0.9, 0))
	check(not top.loose, "a crate stands on the crate below")
	under.go_loose(Vector3(3.0, 0, 0))
	await physics_frames(60)
	check(top.loose, "the one under it knocked away, it comes down")


func test_a_stool_leg_out_from_under_him_tips_him_but_an_empty_one_balances() -> void:
	var stool := await _place(&"bar_stool")
	var man := Sitter.new(80.0)
	world.add_child(man)
	check(stool.sit(man), "he sits")
	await physics_frames(3)
	check(stool.settle().is_empty() and not stool.loose, "an oak stool carries him")
	stool.break_member(_m(stool, "leg1"))
	await physics_frames(3)
	check(stool.loose and man.limp, "a leg out, the stool goes over and he goes down")
	var empty := await _place(&"bar_stool", Vector3(0, 0.3, 1.2))
	empty.break_member(_m(empty, "leg1"))
	await physics_frames(3)
	# The feet beside the gap are splayed blocks 32 mm square, and the leg's own weight has gone:
	# its weight's 3 cm inside the line between them, less than a seated man sways.
	check(not empty.loose, "empty, a leg gone, it balances on three")


func test_a_kick_slides_an_empty_stool_but_breaks_a_leg_under_a_man() -> void:
	var stool := await _place(&"bar_stool")
	var leg := _m(stool, "leg2")
	var at := Vector3(leg.global_position.x, 0.42, leg.global_position.z)
	check_eq(stool.take_blow(leg, at, Vector3(48.0, 0, 0)), &"moved", "empty and light, it goes skidding")
	var stool2 := await _place(&"bar_stool", Vector3(0, 0.3, 1.2))
	var man := Sitter.new(80.0)
	world.add_child(man)
	stool2.sit(man)
	var leg2 := _m(stool2, "leg2")
	at = Vector3(leg2.global_position.x, 0.42, leg2.global_position.z)
	check_eq(stool2.take_blow(leg2, at, Vector3(48.0, 0, 0)), &"broke", "pinned under him, a leg snaps")
	await physics_frames(3)
	check(stool2.loose and man.limp, "and the stool goes over with him")
