extends TestCase
## Loads and strength: the weight of a building comes down through its members to the ground,
## nothing is overloaded as built, and taking away what holds something up brings it down: the
## overloaded snap, the unsupported fall, what's nailed together falls together, and the rubble
## stays where it lands.

var world: Node3D
var store: FalseFrontBuilding


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	store = FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _porch() -> Array[StructureMember]:
	var out: Array[StructureMember] = []
	for m in store.get_members():
		if String(m.member_id).begins_with("store/porch/"):
			out.append(m)
	return out


func test_beam_rules() -> void:
	var sup: Array[float] = [-1.0, 1.0]
	var r := StructuralAnalysis.beam(2.0, 0.0, [[0.0, 1000.0]], sup)
	check_near(r.moment, 500.0, 0.01, "PL/4 for a point load mid-span")
	check_near(r.reactions[0] + r.reactions[1], 1000.0, 0.01, "reactions carry the load")
	r = StructuralAnalysis.beam(2.0, 100.0, [], sup)
	check_near(r.moment, 50.0, 0.01, "wL²/8 for its own weight")
	var one: Array[float] = [-1.0]
	r = StructuralAnalysis.beam(2.0, 0.0, [[1.0, 100.0]], one)
	check_near(r.moment, 200.0, 0.01, "a cantilever: load times reach")
	check_near(r.reactions[0], 100.0, 0.01, "one support takes it all")


func test_as_built_it_all_stands() -> void:
	for s: Structure in [store, SaloonBuilding.new(), Boardwalk.new(), HitchingRail.new(), WaterTrough.new()]:
		if s != store:
			world.add_child(s)
		var a := StructuralAnalysis.new().analyse(s)
		var total := 0.0
		for m in s.get_members():
			total += m.weight(a.tuning) + m.extra_load
		var name: String = s.get_script().get_global_name()
		check_near(a.ground_load, total, total * 0.001, "%s: all its weight reaches the ground" % name)
		check(a.overloaded().is_empty(), "%s: nothing overloaded as built: %s" % [name, a.overloaded().slice(0, 5)])
		check(a.falling.is_empty(), "%s: nothing unsupported" % name)


func test_the_street_buildings_stand_as_built() -> void:
	for b: Array in StreetDressing.BUILDINGS:
		var s := FalseFrontBuilding.new()
		s.structure_id = StringName((b[0] as String).to_snake_case())
		s.width = (b[2] as float) - (b[1] as float)
		s.furnished = false
		var settings: Dictionary = b[4]
		for k in settings:
			s.set(k, settings[k])
		world.add_child(s)
		var a := StructuralAnalysis.new().analyse(s)
		check(a.overloaded().is_empty(), "%s: nothing overloaded as built: %s" % [b[0], a.overloaded().slice(0, 5)])
		check(a.falling.is_empty(), "%s: nothing unsupported: %s" % [b[0], a.falling.slice(0, 5)])
		s.queue_free()


func test_untouched_members_are_drawn_together_until_something_happens_to_one() -> void:
	# One mesh per material: a wood has up to seven board strips (WoodMaterials), so a store with
	# four or five woods draws in ~20-25 meshes, not ~500.
	check(store.batch_count() > 0 and store.batch_count() < 32,
			"%d members in %d meshes" % [store.member_count(), store.batch_count()])
	var post := store.get_member(&"store/porch/post0")
	var own := post.get_child(0) as MeshInstance3D
	check(not own.visible, "a post in the batch isn't drawn on its own")
	post.add_hole(post.global_position + Vector3(0, 0, -0.07), null, 0.006)
	check(own.visible, "holed, it's drawn on its own (with the hole)")
	await physics_frames(2)
	var batched := 0
	for c in store.get_children(true):
		if c is MeshInstance3D and c.name.begins_with("Batch"):
			batched += (c as MeshInstance3D).mesh.get_faces().size()
	check(batched > 0, "the rest still drawn together")
	var glass := store.members_of_kind(&"glass")[0]
	check((glass.get_child(0) as MeshInstance3D).visible, "glass is always its own")


func test_porch_comes_down_without_its_posts() -> void:
	var a := StructuralAnalysis.new().analyse(store, {&"store/porch/post0": true, &"store/porch/post1": true})
	check(&"store/porch/beam" in a.falling, "the beam has nothing under it")
	var rafter := &"store/porch/rafter/03"
	check(a.utilisation.get(rafter, 0.0) > 1.0, "the rafters can't hang off the ledger's nails alone (%.1f×)" % a.utilisation.get(rafter, 0.0))
	check_eq(a.mode.get(rafter), &"joint", "it's the nails that give")
	store.break_member(store.get_member(&"store/porch/post0"))
	store.break_member(store.get_member(&"store/porch/post1"))
	var standing := 0
	for m in _porch():
		if not m.broken and m.kind != &"ledger":
			standing += 1
	check_eq(standing, 0, "the whole awning comes down")
	check(not store.get_member(&"store/roof/ridge").broken and not store.get_member(&"store/front/sign").broken, "the store stands")
	check(store.rubble.size() >= 2, "as rubble (%d pieces)" % store.rubble.size())
	# Down on the ground: every piece's lowest corner near the ground (a rafter may end up leaning
	# on the wall).
	var lowest := func(rb: RigidBody3D) -> float:
		var y := INF
		for c in rb.get_children():
			if c is CollisionShape3D:
				var cs := c as CollisionShape3D
				var half: Vector3 = (cs.shape as BoxShape3D).size * 0.5
				for i in 8:
					var corner := Vector3(half.x * (1 if i & 1 else -1), half.y * (1 if i & 2 else -1), half.z * (1 if i & 4 else -1))
					y = minf(y, (cs.global_transform * corner).y)
		return y
	# Nearly all of it (a piece can end up propped on the post that's left or leaning on the wall).
	var down_share := func() -> float:
		var n := 0
		var down := 0
		for rb in store.rubble:
			if is_instance_valid(rb):
				n += 1
				if lowest.call(rb) < 0.6:
					down += 1
		return float(down) / maxf(n, 1)
	await wait_until(func() -> bool: return down_share.call() >= 0.95, 60 * 6)
	var share: float = down_share.call()
	check(share >= 0.85, "and it's on the ground within a few seconds (%.0f%% of pieces)" % (share * 100.0))
	var asleep := func() -> Vector2i:
		var n := Vector2i.ZERO
		for rb in store.rubble:
			if is_instance_valid(rb):
				n.y += 1
				if rb.sleeping:
					n.x += 1
		return n
	await wait_until(func() -> bool: var n: Vector2i = asleep.call(); return n.x >= n.y * 0.8, 60 * 12)
	var count: Vector2i = asleep.call()
	var sleeping := count.x
	var alive := count.y
	check(alive > 0 and sleeping >= alive * 0.8, "then it lies still (%d of %d asleep)" % [sleeping, alive])


func test_one_stud_is_nothing() -> void:
	var gone := store.break_member(store.get_member(&"store/left/stud/05"))
	var framing := gone.filter(func(id: StringName) -> bool: return store.get_member(id).kind != &"board")
	check_eq(framing, [&"store/left/stud/05"] as Array[StringName], "the wall shrugs off one stud (lost %s)" % [gone])


func test_holes_weaken_until_it_snaps() -> void:
	# A 2-inch plank across a 3 m gap with a 150 kg load on it: holds, until it's shot through.
	var bridge := Structure.new()
	bridge.structure_id = &"bridge"
	world.add_child(bridge)
	bridge.add_member("left", &"post", &"framing", Vector3(0.2, 1.0, 0.3), Vector3(-1.6, 0.5, 0))
	bridge.add_member("right", &"post", &"framing", Vector3(0.2, 1.0, 0.3), Vector3(1.6, 0.5, 0))
	var plank := bridge.add_member("plank", &"floor_board", &"floor", Vector3(3.4, 0.05, 0.25), Vector3(0, 1.025, 0))
	plank.extra_load = 150.0 * 9.81
	bridge.infer_supports()
	var a := StructuralAnalysis.new().analyse(bridge)
	var sound: float = a.utilisation[plank.member_id]
	check(sound < 1.0, "a sound plank takes it (%.0f%%)" % (sound * 100.0))
	var shots := 0
	while not plank.broken and shots < 30:
		# Straight down through the middle.
		var x := randf_range(-0.2, 0.2)
		plank.add_hole(plank.to_global(Vector3(x, 0.025, randf_range(-0.1, 0.1))), plank.to_global(Vector3(x, -0.025, 0.0)), 0.0057)
		shots += 1
		await physics_frames(1)
	check(plank.broken, "shot through enough times it snaps (%d holes)" % shots)
	check(shots >= 3, "but not from one hole")
	check_eq(bridge.rubble.size(), 2, "in two halves")


func test_changes_are_saved() -> void:
	store.break_member(store.get_member(&"store/porch/post0"))
	store.break_member(store.get_member(&"store/porch/post1"))
	var d := store.to_dict()
	check(d.broken.has("store/porch/beam"), "broken members listed")
	check(not d.rubble.is_empty(), "rubble positions kept")


## The analysis keeps what doesn't change about a standing member (where it bears on its supports,
## its axis); it must come out the same as working it all out afresh, however the building's been
## knocked about and charred.
func test_what_the_analysis_keeps_gives_the_same_answer() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var members := store.get_members()
	var answer := func() -> String:
		var a := StructuralAnalysis.new(store.tuning).analyse(store)
		var out := str(a.falling) + var_to_str(a.ground_load)
		for id: StringName in a.load:
			out += "%s %s %s %s %s|" % [id, var_to_str(a.load[id]), var_to_str(a.utilisation.get(id, -1.0)),
					a.mode.get(id, &""), var_to_str(a.critical_t.get(id, 0.0))]
		return out
	for round_ in 3:
		var kept: String = answer.call()  # second time round, from what it kept
		kept = answer.call()
		for m in members:
			m.analysis_cache = {}
		check_eq(answer.call(), kept, "round %d: the same as afresh" % round_)
		# Knock it about: a few members gone, some charred, some loaded.
		for k in 3:
			var m: StructureMember = members[rng.randi() % members.size()]
			if not m.broken:
				store.break_member(m)
		for k in 20:
			members[rng.randi() % members.size()].char_depth += rng.randf() * 0.004
		await physics_frames(1)
