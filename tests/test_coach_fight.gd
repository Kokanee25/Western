extends TestCase
## The coach heist after the hit (#815, CoachFight): the hit's seed sets each guard's daze and
## nerve the same way every time; the door on top of the wreck swings open on its hinge though the
## coach is rubble; the strongbox hauled out stands, its padlock shot off opens it and the papers are
## taken; where the guards fight (the cut, off the ram's bank); the way out up the rimrock trail; and
## what it came to goes into the story.

var world: Node3D


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
	StoryState.clear("coach.")
	await physics_frames(2)


## A cut with nothing built (no ram, no coach): its middle at the origin, the road along x, the
## ram's bank to +z.
func _bare_cut() -> CoachCut:
	var cut := CoachCut.new()
	cut.middle = Vector3.ZERO
	cut.road_dir = Vector3.RIGHT
	cut.side = Vector3.BACK
	cut.road_from = -3.2
	cut.road_to = 3.3
	cut.height_at = func(_x: float, _z: float) -> float: return 0.0
	world.add_child(cut)
	return cut


func _fight(cut: CoachCut) -> CoachFight:
	var f := CoachFight.new()
	f.cut = cut
	cut.fight = f
	cut.add_child(f)
	return f


func _m(p: KitProp, id: String) -> StructureMember:
	return p.get_member(StringName("%s/%s" % [p.structure_id, id]))


func test_the_hits_seed_sets_each_guards_daze_and_nerve() -> void:
	var outs: Array = []
	for i in 2:
		var f := _fight(_bare_cut())
		f.seed_value = 7
		for k in 3:
			var man := HumanBody.new()
			man.body_model = &"outlaw"
			man.has_gun = false
			man.person_id = StringName("guard_%d" % k if k < 2 else "messenger")
			world.add_child(man)
			f.add_man(man, &"inside" if k < 2 else &"box")
		f.on_hit([])
		outs.append(f.men.map(func(g: Dictionary) -> Array: return [g.daze, g.nerve, g.hurt]))
		check(f.state == CoachFight.State.ON, "the hit starts it")
		var t := f.tuning
		for g: Dictionary in f.men:
			var most := (t.daze_min + t.daze_spread) * (t.box_daze_share if g.role == &"box" else 1.0)
			check(g.daze >= t.daze_min * (t.box_daze_share if g.role == &"box" else 1.0) - 1e-4 and g.daze <= most + 1e-4,
					"%s dazed %.1f s, within the dial's range" % [g.id, g.daze])
			check(g.nerve >= t.nerve_min and g.nerve <= t.nerve_max, "his nerve %.2f within its range" % g.nerve)
			check(g.leads == (g.id == "messenger"), "the messenger leads them")
	check_eq(outs[0], outs[1], "the same seed, the same daze, nerve and hurts")


func test_a_knock_on_the_head_dazes_him_longer() -> void:
	var f := _fight(_bare_cut())
	var g := {"knocks": [30.0, 120.0, 240.0]}
	check_near(f._knock_daze(g), 2.0 + 4.0, 1e-4, "each knock past 60 J adds its daze (a light one nothing)")


func test_the_door_on_top_of_the_wreck_swings_open() -> void:
	var cut := _bare_cut()
	var c := PropKit.spawn(&"baron_coach")
	cut.add_child(c)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	cut.coach = c
	var f := _fight(cut)
	var bodies := c.go_loose()
	f.on_hit(bodies)
	f.door = "door_l"
	var shape: CollisionShape3D = null
	for ch in f.body.get_children():
		if ch is CollisionShape3D and ch.get_meta(&"member", &"") == StringName("%s/door_l" % c.structure_id):
			shape = ch
	check(shape != null, "the door's shape is in the wreck's body")
	if shape == null:
		return
	var was := (f.body.global_transform * shape.transform).origin
	f._open_door()
	var now := (f.body.global_transform * shape.transform).origin
	var out_l := f.coach_basis() * Vector3(0, 0, -1)
	check((now - was).dot(out_l) > 0.25, "swung out on its hinge (%.2f m out)" % (now - was).dot(out_l))
	check(f.in_coach(f.at_coach(Vector3(0, 1.75, 0))) and not f.in_coach(f.at_coach(Vector3(0, 1.75, 1.2))), "inside is inside")


func test_the_strongbox_hauled_out_opens_when_its_padlock_is_shot_and_the_papers_are_taken() -> void:
	var cut := _bare_cut()
	var f := _fight(cut)
	f.state = CoachFight.State.ON
	f.settled_t = 0.0
	f.hatch_top = Vector3(0, 1.8, 0)
	f.lee_dir = Vector3.FORWARD
	await physics_frames(1)
	f.haul_out()
	check_eq(f.box_state, &"out", "it's out on the road")
	await physics_frames(KitProp.SETTLE_FRAMES + 6)
	var box := f.box
	check(box != null and not box.loose, "standing")
	check(Vector2(box.global_position.x, box.global_position.z).length() > 0.5, "clear of the door")
	check(box.is_locked("lid"), "padlocked")
	f.open_box()
	check_eq(f.box_state, &"out", "locked, it won't open")
	box.break_member(_m(box, "padlock"))
	await physics_frames(KitProp.SETTLE_FRAMES + 4)
	check(not box.loose, "the padlock shot off, it still stands (%s)" % box.loose)
	check(not box.is_locked("lid"), "unlocked")
	f.open_box()
	check_eq(f.box_state, &"open", "the lid up")
	f.take_papers()
	check_eq(f.took, "papers", "the papers yours")
	check(not _m(box, "papers").visible, "gone from the box")


func test_where_they_fight_and_the_way_out() -> void:
	var cut := _bare_cut()
	var f := _fight(cut)
	check(f.in_reach(Vector3(5, 0, -10)), "across the road, up the far bank")
	check(not f.in_reach(Vector3(0, 0, 12)), "not up the ram's bank")
	check(not f.in_reach(Vector3(60, 0, 0)), "nor far off down the road")
	cut.layout = ValleyLayout.main()
	var line := cut.layout.road_line("rimrock_trail")
	var a := Vector3(line[0].x, 0.0, line[0].y)
	var u := Vector3(line[1].x - line[0].x, 0.0, line[1].y - line[0].y).normalized()
	check(f.on_trail(a + u * (f.tuning.trail_along + 2.0)), "up the trail past the mark")
	check(not f.on_trail(a + u * 5.0), "not at its foot")
	check(not f.on_trail(a + u * 40.0 + u.cross(Vector3.UP) * 30.0), "nor off it")


func test_what_it_came_to_goes_into_the_story() -> void:
	var f := _fight(_bare_cut())
	f.state = CoachFight.State.ON
	f.took = "papers"
	f._win()
	check_eq(StoryState.get_fact("coach.outcome"), "won", "won")
	check_eq(StoryState.get_fact("coach.took"), "papers", "the papers")
	check_eq(StoryState.get_fact("coach.guards_alive"), 0, "no men to count")
	f._lose(&"you_down", "You're down.")
	check_eq(f.state, CoachFight.State.WON, "once won, it stays won")
