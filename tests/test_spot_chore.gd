extends TestCase
## Spots (townsfolk step 4, #957; docs/briefs/townsfolk.md §3 "Spots"): SpotChore's kinds as a
## townsman's chore, each a loop with breaks picked by his seed; the spots row of the brief's §8 (no
## pose held 20 s, watched 10 minutes) by its plan; each kind run on a body on flat ground; trouble
## stops it and what's in his hands goes down.

const KINDS := [&"stand", &"lean", &"sit", &"counter", &"sweep", &"carry", &"talk", &"drink", &"work"]

var world: Node3D


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


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _man(id: String, seed_value: int, at: Vector3, faces: Vector3, kind: StringName, spot := {}) -> SpotChore:
	var man := HumanBody.new()
	man.body_model = &"storekeeper_s1_talking"
	man.person_id = StringName(id)
	man.rng_seed = seed_value
	man.has_gun = false
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = at
	brain.faces = faces
	man.add_child(brain)
	world.add_child(man)
	man.global_position = at
	man.face(faces)
	var c := SpotChore.new(man, kind, at, faces, spot)
	brain.chores = [c]
	return c


## The brief's spots row by the plan: ten minutes of each kind, five men each: nothing held 20 s,
## the breaks more than one and never the same twice running, two men's days not in step.
func test_the_plan_breaks_every_doing_under_twenty_seconds() -> void:
	for k: StringName in KINDS:
		var orders := {}
		for s in [11, 502, 781, 903, 1234]:
			var plan := SpotChore.plan(s, k, 600.0)
			var longest := 0.0
			var breaks := {}
			var last := &""
			var twice := false
			for d: Array in plan:
				longest = maxf(longest, float(d[1]))
				if d[0] != SpotChore.KINDS[k].main:
					breaks[d[0]] = true
					twice = twice or d[0] == last
					last = d[0]
			check(longest < 20.0, "%s (seed %d): nothing held 20 s (%.1f)" % [k, s, longest])
			check(breaks.size() >= 2, "%s (seed %d): more than one break (%s)" % [k, s, breaks.keys()])
			check(not twice, "%s (seed %d): no break twice running" % [k, s])
			check(plan.size() >= 600.0 / 15.0, "%s (seed %d): %d changes in ten minutes" % [k, s, plan.size()])
			orders[str(plan.slice(0, 6).map(func(d: Array) -> String: return String(d[0])))] = true
		check(orders.size() >= 3, "%s: the five men not all in the same order (%d)" % [k, orders.size()])


## Each kind on a body: it has him, his doing changes, his hands go where it says, the work gets done.
func test_each_kind_on_a_body() -> void:
	var chair := PropKit.make(&"chair")
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3(-8.0, 0.0, 0.0))  # facing -z
	var wall := StaticBody3D.new()
	var ws := CollisionShape3D.new()
	var wb := BoxShape3D.new()
	wb.size = Vector3(3.0, 3.0, 0.2)
	ws.shape = wb
	wall.add_child(ws)
	wall.position = Vector3(-4.0, 1.5, 0.55)
	world.add_child(wall)
	var cs := {}
	cs[&"stand"] = _man("a", 501, Vector3(-12.0, 0, 0), Vector3(-12.0, 1.5, -6.0), &"stand")
	cs[&"lean"] = _man("b", 502, Vector3(-4.0, 0, 0.1), Vector3(-4.0, 1.5, -6.0), &"lean")
	var sit := _man("c", 503, Seating.spot(chair), Seating.faces(chair), &"sit")
	sit.sit = SitChore.new(sit.man, chair)
	cs[&"sit"] = sit
	cs[&"counter"] = _man("d", 504, Vector3(0.0, 0, 0), Vector3(0.0, 1.4, -6.0), &"counter", {"top": Vector3(0.0, 1.05, -0.5)})
	cs[&"sweep"] = _man("e", 505, Vector3(4.0, 0, 0), Vector3(4.0, 1.5, -6.0), &"sweep", {"reach": 1.0})
	cs[&"carry"] = _man("f", 506, Vector3(8.0, 0, 0), Vector3(8.0, 1.5, -6.0), &"carry", {"to_at": Vector3(11.0, 0.0, 0.0)})
	cs[&"talk"] = _man("g", 507, Vector3(14.0, 0, 0), Vector3(15.1, 1.5, 0.0), &"talk")
	var other := _man("h", 508, Vector3(15.1, 0, 0), Vector3(14.0, 1.5, 0.0), &"talk")
	cs[&"drink"] = _man("i", 509, Vector3(20.0, 0, 0), Vector3(20.0, 1.4, -6.0), &"drink", {"top": Vector3(20.0, 1.05, -0.5)})
	cs[&"work"] = _man("j", 510, Vector3(24.0, 0, 0), Vector3(24.0, 1.5, -6.0), &"work", {"tool": "anvil"})
	var reached := {}
	var spoke := false
	for i in 60 * 40:
		await physics_frames(1)
		for k: StringName in cs:
			var c: SpotChore = cs[k]
			if not c.man._reach.is_empty():
				reached[k] = true
		var sp := cs[&"talk"].man.get_node_or_null(^"FaceSpeech") as FaceSpeech
		spoke = spoke or (sp != null and sp.speaking())
	for k: StringName in cs:
		var c: SpotChore = cs[k]
		check(c.busy(), "%s: it has him (%s)" % [k, c.doing])
		check(c.changes >= 2, "%s: his doing changed in 40 s (%d, longest %.1f)" % [k, c.changes, c.longest])
		check(c.longest < 20.0, "%s: nothing held 20 s (%.1f)" % [k, c.longest])
	for k in [&"counter", &"sweep", &"carry", &"drink", &"work", &"lean"]:
		check(reached.has(k), "%s: his hands at it" % k)
	check(sit.sit.busy() and chair.seated == sit.man, "sit: sat in the chair")
	check(cs[&"lean"]._wall != Vector3.INF, "lean: found the wall behind him")
	check(cs[&"sweep"].strokes >= 8, "sweep: strokes (%d)" % cs[&"sweep"].strokes)
	check(cs[&"carry"].strokes >= 1, "carry: a sack set down at the far end (%d)" % cs[&"carry"].strokes)
	check(cs[&"work"].strokes >= 8, "work: hammer blows (%d)" % cs[&"work"].strokes)
	check(cs[&"drink"].strokes >= 1, "drink: a sip (%d)" % cs[&"drink"].strokes)
	check(spoke, "talk: his mouth going")
	var a: HumanBody = cs[&"talk"].man
	var to := other.man.global_position - a.global_position
	check((-a.global_basis.z).dot(to.normalized()) > 0.8, "talk: they face each other")
	check(other.busy(), "talk: the other talking too")


## Trouble (a shot close by): it lets him go at once; the broom goes down on the boards, the sack he
## had at his feet; calm again, he goes back to it.
func test_trouble_stops_it_and_puts_things_down() -> void:
	var sweep := _man("e", 505, Vector3(0.0, 0, 0), Vector3(0.0, 1.5, -6.0), &"sweep", {"reach": 1.0})
	var carry := _man("f", 506, Vector3(6.0, 0, 0), Vector3(6.0, 1.5, -6.0), &"carry", {"to_at": Vector3(9.0, 0.0, 0.0)})
	var held := await wait_until(func() -> bool: return carry._held >= 0 and carry._carry_step == &"carrying" and sweep.doing == &"sweep", 60 * 40)
	check(held, "a sack on his shoulder (%s, %s)" % [carry._carry_step, sweep.doing])
	Events.noise.emit(Vector3(3.0, 1.5, 2.0), DeedWatch.GUNSHOT, &"gunshot", null)
	await physics_frames(60)  # (a beat after it reaches them, townsfolk step 5)
	check(not sweep._on and not carry._on, "both let go (%s, %s)" % [sweep.doing, carry.doing])
	check(sweep._tool.global_position.y < 0.2, "the broom's on the boards (%.2f)" % sweep._tool.global_position.y)
	var low := true
	for s in carry._sacks:
		low = low and s.global_position.y < 0.8
	check(low, "no sack left in the air")
	check(not sweep.man.pose_offsets.has(&"chest"), "his lean let go")
	var back := await wait_until(func() -> bool: return sweep._on and carry._on, 60 * 120)
	check(back, "calm again, back at it")


## In the valley: the day's blocks hand each spot its chore (the storekeeper sweeps at six, the wife
## and the loudmouth on the store's chairs at ten, the smith at his anvil).
func test_the_valley_s_blocks_name_their_chores() -> void:
	var holder := Node.new()
	holder.name = "Main"
	add_child(holder)
	ValleyFolk.murder_auto = false
	var valley: ValleyWorld = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var f := valley.folk
	var clock := valley.get_node(^"DayCycle") as DayCycle
	f.data.walk_in_h = 0.0
	var want := {6.2: {&"storekeeper": &"sweep", &"landlady": &"sweep", &"smith": &"work", &"liveryman": &"lean"},
			10.5: {&"store_wife": &"sit", &"loudmouth": &"sit", &"undertaker": &"work", &"smith": &"work"},
			12.5: {&"townsman": &"lean", &"loudmouth": &"lean"},
			19.2: {&"landlady": &"talk", &"townsman": &"talk", &"barkeep": &"counter", &"miner": &"drink"}}
	for h: float in want:
		clock.set_time(h)
		await physics_frames(1)
		f._look = 0.0
		await physics_frames(90)
		for id: StringName in want[h]:
			# On an errand round (#1167) his leg says it: in at a door (no body to ask), or its own spot's.
			var b := f.block_now(f._person(id), h)
			if b.has("leg") and b.has("in"):
				continue
			if b.has("leg"):
				want[h][id] = StringName(String(b.do))
			var man: HumanBody = f.people.get(id)
			var brain := man.get_node_or_null(^"Brain") as CivilianBrain if man else null
			var c: SpotChore = null
			if brain:
				for x: RefCounted in brain.chores:
					if x is SpotChore:
						c = x
			check(c != null and c.kind == want[h][id], "%.1f %s: %s (%s)" % [h, id, want[h][id], c.kind if c else "none"])
			if c and c.kind == &"sit":
				check(c.sit != null and c.sit.busy(), "%.1f %s: sat on the store's chair" % [h, id])
	holder.queue_free()
	await physics_frames(2)
