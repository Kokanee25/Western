extends TestCase
## The fire's member tick has two cores (more-cores step 8): the native plugin's `FireCore` and
## FireCoreScript, the same rules in GDScript for where the plugin isn't. They must give the same
## numbers to the last bit: fed the same calls, the same events and the same state, banded or not;
## and a wall of boards burnt through FireSystem comes out the same on either. A member's fire
## numbers read and write through to its core once the fire has met it.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	await physics_frames(1)


func after_each() -> void:
	FireSystem.native_core = ClassDB.class_exists(&"FireCore")
	world.queue_free()
	await physics_frames(1)


func _native() -> bool:
	if ClassDB.class_exists(&"FireCore"):
		return true
	check(false, "FireCore is registered by addons/saltcreek_native (build it: cargo build --release there)")
	return false


## Every slot's numbers and flags, as one array (to compare two cores).
func _state(core: Object) -> Array:
	var out := []
	for s in core.size():
		out.append([core.temperature(s), core.wet(s), core.char_depth(s), core.burn_time(s),
				core.flag(s, 1), core.flag(s, 2), core.flag(s, 4), core.flag(s, 8), core.flag(s, 64), core.flag(s, 128)])
	return out


func _first_difference(a: Array, b: Array) -> String:
	if a.size() != b.size():
		return "sizes %d and %d" % [a.size(), b.size()]
	for i in a.size():
		if a[i] != b[i]:
			return "slot %d: %s and %s" % [i, a[i], b[i]]
	return ""


func test_the_two_cores_agree_to_the_last_bit() -> void:
	if not _native():
		return
	var cores: Array = [ClassDB.instantiate(&"FireCore"), FireCoreScript.new()]
	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	var n := 300
	# The same slots in both: a mix of hot, burning, wet, glass, broken, far and near members.
	for i in n:
		var flags := FireCoreScript.F_ACTIVE
		if rng.randf() < 0.3:
			flags |= FireCoreScript.F_BURNING
		if rng.randf() < 0.85:
			flags |= FireCoreScript.F_FLAMMABLE
		elif rng.randf() < 0.5:
			flags |= FireCoreScript.F_GLASS
		if rng.randf() < 0.1:
			flags |= FireCoreScript.F_BROKEN
		var temp := rng.randf_range(15.0, 700.0)
		var wet := rng.randf_range(0.0, 0.4) if rng.randf() < 0.2 else 0.0
		var size := Vector3(rng.randf_range(0.01, 3.0), rng.randf_range(0.01, 0.3), rng.randf_range(0.006, 0.2))
		var h := rng.randi()
		var st := rng.randi_range(-1, 3)
		var burn := rng.randf_range(0.0, 40.0) if flags & FireCoreScript.F_BURNING else 0.0
		for c: Object in cores:
			c.add(temp, wet, 0.0, burn, flags, size, h, st)
	for c: Object in cores:
		c.tune("growth_seconds", 32.0)
	# Their boxes in the grid: a jumble about 8 m across, so each has a few within reach.
	for i in n:
		var b := AABB(Vector3(rng.randf_range(-4, 4), rng.randf_range(0, 4), rng.randf_range(-4, 4)), Vector3(rng.randf_range(0.02, 2.0), rng.randf_range(0.02, 2.0), rng.randf_range(0.02, 0.4)))
		for c: Object in cores:
			c.place(i, b)
	var bands := PackedInt32Array([1, 2, 4, 1])
	for tick in 600:
		var banded := tick % 3 != 0
		# The slice: every slot, in a shuffled order, a third at a time (as a tick spread over frames).
		var order := PackedInt32Array()
		for i in n:
			order.append(i)
		for i in range(n - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t := order[i]
			order[i] = order[j]
			order[j] = t
		for part in 3:
			var slots := order.slice(part * n / 3, (part + 1) * n / 3)
			var ev: Array = [cores[0].visit(slots, 0.25, banded, tick, bands), cores[1].visit(slots, 0.25, banded, tick, bands)]
			if ev[0] != ev[1]:
				check(false, "tick %d: events %s and %s" % [tick, ev[0], ev[1]])
				return
			for k in range(0, (ev[0] as PackedInt32Array).size(), 2):
				if ev[0][k] == FireCoreScript.EV_GONE:
					for c: Object in cores:
						c.forget(slots[ev[0][k + 1]])
		# Something moving (rubble re-placed where it lies now).
		var mv := rng.randi_range(0, n - 1)
		var nb := AABB(Vector3(rng.randf_range(-4, 4), rng.randf_range(0, 4), rng.randf_range(-4, 4)), Vector3(rng.randf_range(0.02, 2.0), 0.1, 0.1))
		for c: Object in cores:
			c.unplace(mv)
			c.place(mv, nb)
		# Now and then something from outside: water, a spill's heat, a pane gone, a member freed.
		var s := rng.randi_range(0, n - 1)
		var amount := rng.randf_range(0.0, 900.0)
		match rng.randi_range(0, 5):
			0:
				for c: Object in cores:
					c.set_wet(s, 0.3)
			1:
				var got: Array = [cores[0].heat(s, amount), cores[1].heat(s, amount)]
				check(got[0] == got[1], "heat says the same")
			2:
				for c: Object in cores:
					c.set_flag(s, FireCoreScript.F_BROKEN, true)
			3:
				if rng.randf() < 0.1:
					for c: Object in cores:
						c.release(s)
		for c: Object in cores:
			c.age_near(0.25)
		var diff := _first_difference(_state(cores[0]), _state(cores[1]))
		if diff != "":
			check(false, "tick %d: %s" % [tick, diff])
			return
	for s2 in n:
		if cores[0].near_of(s2) != cores[1].near_of(s2):
			check(false, "slot %d heats %s and %s" % [s2, cores[0].near_of(s2), cores[1].near_of(s2)])
			return
	var burning: int = cores[0].burning_count()
	check(burning == cores[1].burning_count(), "the same burning (%d)" % burning)
	check(burning > 0, "some still burning at the end (%d)" % burning)
	# fire_near's answers: the same boxes, the same counts, nearest points and distances.
	for q in 50:
		var at := Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 5), rng.randf_range(-12, 12))
		var r := rng.randf_range(0.5, 20.0)
		var got: Array = [cores[0].burning_near(at, r), cores[1].burning_near(at, r)]
		check(got[0] == got[1], "burning_near %s and %s" % [got[0], got[1]])


## A wall of boards over a floor, one board lit: on either core, every member ends with the same
## numbers, and the same ones burnt away.
func test_a_wall_burns_the_same_on_either_core() -> void:
	if not _native():
		return
	var results := []
	for native in [true, false]:
		FireSystem.native_core = native
		var place := Node3D.new()
		world.add_child(place)
		var fire := FireSystem.new()
		place.add_child(fire)
		var s := Structure.new()
		s.structure_id = &"wall"
		s.collapses = false
		place.add_child(s)
		for i in 12:
			for j in 4:
				s.add_member("b%d_%d" % [i, j], &"board", &"weathered_pine", Vector3(0.24, 0.6, 0.025), Vector3(i * 0.25, 0.3 + j * 0.62, 0))
		for i in 12:
			s.add_member("f%d" % i, &"floor_board", &"pine", Vector3(0.24, 0.03, 3.0), Vector3(i * 0.25, 0.0, 1.0))
		s.add_member("stone", &"board", &"stone", Vector3(0.4, 2.0, 0.4), Vector3(-0.4, 1.0, 0))
		s.infer_supports()
		await physics_frames(1)
		fire.ignite(s.get_member(&"wall/b5_0"))
		for k in 1600:
			fire.step(0.5)
		var out := []
		for m in s.get_members():
			out.append([String(m.member_id), m.temperature, m.char_depth, m.burn_time, m.wet, m.burning, m.consumed])
		results.append(out)
		place.queue_free()
		await physics_frames(1)
	check(results[0].size() > 0, "a wall")
	var diff := _first_difference(results[0], results[1])
	check(diff == "", "the same on both: %s" % diff)
	var burnt := 0
	for r: Array in results[0]:
		if r[6]:
			burnt += 1
	check(burnt > 10, "it burnt (%d burnt away)" % burnt)


func test_a_member_reads_and_writes_through_its_core() -> void:
	var fire := FireSystem.new()
	world.add_child(fire)
	# On its own (freed at the end, so not in a structure).
	var a := StructureMember.new()
	a.member_id = &"a"
	a.kind = &"board"
	a.wood = &"weathered_pine"
	a.size = Vector3(0.24, 2.0, 0.025)
	world.add_child(a)
	a.temperature = 120.0
	a.wet = 0.1
	check(a.fire_slot == -1, "not the fire's yet")
	fire.ignite(a)
	check(a.fire_slot >= 0, "the fire has it")
	check(a.temperature >= 370.0 and a.burning, "lit (%.0f °C)" % a.temperature)
	check(is_equal_approx(a.wet, 0.1), "its water went with it")
	a.char_depth = 0.004
	check(is_equal_approx(fire._core.char_depth(a.fire_slot), 0.004), "written through")
	check(is_equal_approx(a.thickness(), 0.025 - 0.008), "its thickness reads it")
	var slot := a.fire_slot
	var core: Object = fire._core
	a.free()
	check(not core.flag(slot, FireCoreScript.F_VALID), "freed: out of the fire")
