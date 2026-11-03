extends TestCase
## The breakable track (train step 5, #616; src/train/track_chunk.gd, track_state.gd): the ties and
## rails are members that stand on their own, at rest (nothing drawn or ticking each); a charge on
## the line splinters ties and tears rails loose or bends them, never snaps one; the track's state
## names the stretch broken, bent or blocked, by the route's section and the distance along it; the
## save puts the damage back on a re-laid route where its same section is.

const LINE := preload("res://experiments/train_lab/test_line.gd")

var world: Node3D
var tuning: TrainTuning


func before_each() -> void:
	tuning = load("res://config/train.tres")
	world = Node3D.new()
	add_child(world)
	# The flat the line's laid on (its fill meets it).
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4000, 1, 4000)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _line(file := LINE.ROUTE) -> TrackLine:
	var line := LINE.make(tuning, file)
	world.add_child(line)
	line.build()
	return line


func test_the_track_is_members_that_stand() -> void:
	var line := _line()
	check(line.chunks.size() >= 14, "the 1.5 km line in chunks of whole rails (%d)" % line.chunks.size())
	var ties := 0
	var rails := 0
	var resting := 0
	var total := 0
	for c in line.chunks:
		ties += c.ties.size()
		rails += c.rails.size()
		for m in c.get_members():
			total += 1
			if m.resting():
				resting += 1
		check(c.members_without_load_path().is_empty(), "%s stands" % c.name)
	check_near(ties, line.length / tuning.tie_spacing, 3.0, "a tie every %.1f m (%d)" % [tuning.tie_spacing, ties])
	check_near(rails, 2.0 * line.length / tuning.rail_length, 4.0, "two rails every %.2f m (%d)" % [tuning.rail_length, rails])
	check_eq(resting, total, "every member at rest in its chunk's batch (%d of %d)" % [resting, total])
	var c0: TrackChunk = line.chunks[0]
	var broke := c0.settle()
	check(broke.is_empty(), "nothing breaks under its own weight (%s)" % [broke])
	var r: StructureMember = c0.rails[0].member
	check(r.supported_by.size() >= 15, "a rail rests on the %d ties under it" % r.supported_by.size())


func test_a_charge_on_the_line_breaks_it_and_rails_never_snap() -> void:
	var line := _line()
	await physics_frames(2)
	var s := 200.0
	var f := line.global_transform * line.transform_at(s)
	check(line.state.damage().is_empty(), "a new line has nothing wrong with it")
	var rails_before := 0
	for c in line.chunks:
		rails_before += c.rails.size()
	# One stick planted on a tie beside the left rail (0.2 kg, the game's): a tie or two splintered,
	# the rail over them bowed: a stretch no train should run over fast.
	var at := f.origin + f.basis.x * -0.3 + f.basis.y * -0.06
	Blast.detonate(world, at, 0.2)
	await physics_frames(3)
	var d := line.state.damage()
	var here := func(x: Dictionary) -> bool: return float(x.from_s) < s + 5.0 and float(x.to_s) > s - 5.0
	check(d.any(func(x: Dictionary) -> bool: return here.call(x) and x.kind in [&"broken", &"bent"]), "one stick on a tie bends or breaks the line there: %s" % [d])
	# Two more there: broken.
	for k in 2:
		Blast.detonate(world, at + f.basis.z * (0.6 * (k * 2 - 1)), 0.2)
		await physics_frames(3)
	d = line.state.damage()
	var broken := d.filter(func(x: Dictionary) -> bool: return here.call(x) and x.kind == &"broken")
	check(not broken.is_empty(), "three sticks there break it: %s" % [d])
	var c := line.chunk_at(s)
	var snapped := 0
	for m in c.get_members():
		if m.kind == &"rail" and m.has_meta(&"cut"):
			snapped += 1
	check_eq(snapped, 0, "no rail is cut or snapped")
	var rails_after := 0
	for cc in line.chunks:
		rails_after += cc.rails.size()
	check_eq(rails_after, rails_before, "a rail torn loose is one piece, not two")
	if not broken.is_empty():
		var k: Dictionary = broken[0].key
		check_eq(String(k.section), "p0", "keyed by the route's section (%s)" % [k])
		check_near(line.s_of(k), float(broken[0].from_s), 0.01, "and the distance along it")


func test_bent_rails_and_blocks() -> void:
	var line := _line()
	var c := line.chunk_at(300.0)
	var r := c.rail_at(1, 300.0)
	c.bend(r, 0.12)
	var d := line.state.damage()
	check(d.any(func(x: Dictionary) -> bool: return x.kind == &"bent" and int(x.side) == 1), "a rail bowed 12 cm is a bent stretch: %s" % [d])
	# A crate on the line is a block; the scan finds it.
	var crate := RigidBody3D.new()
	crate.mass = 40.0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	cs.shape = box
	crate.add_child(cs)
	crate.freeze = true
	world.add_child(crate)
	var f := line.global_transform * line.transform_at(350.0)
	crate.global_position = f.origin + f.basis.y * 0.3
	await physics_frames(2)
	var found := line.state.scan(world.get_world_3d(), 330.0, 370.0, 20, 1.0)
	check(not found.is_empty(), "the scan finds the crate on the line")
	check(line.state.first_ahead(320.0, 1).get("kind", &"") == &"blocked", "the first thing ahead past the bend's rail is the crate")
	check(line.state.first_ahead(250.0, 1).get("kind", &"") == &"bent", "and before it the bent rail")


func test_damage_saved_by_section_lands_on_a_relaid_route() -> void:
	var line := _line()
	var c := line.chunk_at(150.0)
	c.tear_loose(c.rail_at(-1, 150.0))
	c.bend(c.rail_at(1, 160.0), 0.1)
	var saved := line.state.to_dict()
	var keys: Array = line.state.damage().map(func(x: Dictionary) -> String: return "%s %s %.1f" % [x.kind, x.key.section, x.key.at])
	check_eq(saved.rails.size(), 1, "one rail gone in the save")
	line.free()
	# The same route again: the same places.
	var again := _line()
	check_eq(again.state.from_dict(saved), 0, "every saved piece placed")
	var keys2: Array = again.state.damage().map(func(x: Dictionary) -> String: return "%s %s %.1f" % [x.kind, x.key.section, x.key.at])
	check_eq(keys2, keys, "the same stretches, at the same places")
	again.free()
	# A re-laid route whose first section is the same straight, laid elsewhere and pointing another way.
	var r := TrainRoute.load_file(LINE.ROUTE)
	r.data.origin = [-300.0, 0.0, 500.0]
	r.data.heading = 70.0
	(r.data.plan as Array).insert(0, {"straight": 80, "id": "approach"})
	(r.data.plan[1] as Dictionary)["id"] = "p0"
	var moved := r.make_line(tuning)
	world.add_child(moved)
	moved.build()
	check_eq(moved.state.from_dict(saved), 0, "placed on the re-laid route")
	var d := moved.state.damage()
	check(not d.is_empty(), "the damage is on the re-laid line")
	for x: Dictionary in d:
		check_eq(String(x.key.section), "p0", "in its same section (%s)" % [x.key])
		check(float(x.from_s) > 80.0, "past the new approach (at %.1f)" % float(x.from_s))


## A train on the line in the world, standing with its front at `s`.
func _train(line: TrackLine, s: float) -> Train:
	var train := Train.new()
	train.name = "Train"
	line.add_child(train)
	train.setup(line, tuning)
	train.place(s)
	return train


func test_the_wheels_run_over_a_man_down_between_the_rails() -> void:
	var line := _line()
	var train := _train(line, 300.0)
	# A man lying across the rails 30 m ahead.
	var f := line.global_transform * line.transform_at(330.0)
	var man := HumanBody.new()
	man.person_id = &"on_the_line"
	man.rng_seed = 616
	man.has_gun = false
	man.enter(world, f * Vector3(0.0, -tuning.rail_size.y + 0.05, 0.0), f.basis.get_euler().y + PI * 0.5)
	await physics_frames(5)
	man.go_limp()
	await physics_frames(60)
	# The train comes on at 18 km/h, coasting.
	train.sim.set_speed(5.0)
	var ok := await wait_until(func() -> bool: return train.sim.s > 330.0 + train.sim.length + 2.0, 60 * 30)
	check(ok, "the train passes the spot")
	var over: Array = train.struck.filter(func(x: Dictionary) -> bool: return String(x.who) == "on_the_line" and String(x.how).begins_with("run over"))
	check(not over.is_empty(), "he's run over, not passed over: %s" % [train.struck])
	var off: Array = over.filter(func(x: Dictionary) -> bool: return String(x.how).contains(" off"))
	check(Settings.reduced_gore or not off.is_empty(), "a limb on the rail is cut off (gore on): %s" % [over])
	check(man.limp, "he's limp")


## A rail torn out at `at` (the left one), the train coming on at `kmh` from 60 m short, nobody
## braking: returns the train once it's derailed and `settle` s have passed.
func _derail_run(kmh: float, at := 400.0, settle := 6.0) -> Train:
	var line := _line()
	var c := line.chunk_at(at)
	c.tear_loose(c.rail_at(-1, at + 1.0))
	var train := _train(line, at - 60.0)
	await physics_frames(2)
	train.sim.set_speed(kmh / 3.6)
	await wait_until(func() -> bool: return not train.derail.is_empty(), 60 * 120)
	await physics_frames(int(settle * 60.0))
	return train


func test_a_derail_hands_the_train_over_with_its_momentum() -> void:
	var line := _line()
	var c := line.chunk_at(400.0)
	c.tear_loose(c.rail_at(-1, 401.0))
	var train := _train(line, 340.0)
	await physics_frames(2)
	train.sim.set_speed(30.0 / 3.6)
	var p1d := [0.0]
	train.derailed.connect(func(_i: Dictionary) -> void:
		var p := Vector3.ZERO
		var m := 0.0
		for b: Dictionary in train.wreck.bodies:
			var rb := b.body as RigidBody3D
			p += rb.linear_velocity * rb.mass
			m += rb.mass
		p1d[0] = p.length() / m)
	var mom := 0.0
	for i in train.sim.cars.size():
		mom += float(train.sim.cars[i].mass)
	var ok := await wait_until(func() -> bool: return not train.derail.is_empty(), 60 * 60)
	check(ok, "it leaves the rails at the break")
	check_near(float(train.derail.s), 400.0, 10.0, "where the rail's gone (%.1f)" % float(train.derail.s))
	check_eq(train.wreck.bodies.size(), train.sim.cars.size(), "a body a car")
	# The momentum the bodies were given is the 1D train's (all its cars at about the same speed).
	check_near(float(p1d[0]), float(train.derail.kmh) / 3.6, 0.6, "handed over at its speed (%.2f m/s of %.2f)" % [float(p1d[0]), float(train.derail.kmh) / 3.6])
	await physics_frames(60 * 8)
	var off := 0.0
	for b: Dictionary in train.wreck.bodies:
		var rb := b.body as RigidBody3D
		var local := line.global_transform.affine_inverse() * rb.global_position
		var s := line.curve.get_closest_offset(local)
		off = maxf(off, local.distance_to(line.point_at(s)))
	check(off > 0.3, "the cars are off the line (%.2f m at most)" % off)


## The engineer driving (no body: he drives regardless) toward a torn-out rail at `at`.
func _engineer_run(line: TrackLine, kmh: float, at: float, daylight: float, seed_value := 616) -> Train:
	var c := line.chunk_at(at)
	c.tear_loose(c.rail_at(-1, at + 0.5))
	var train := _train(line, at - 300.0)
	train.lookout.daylight = daylight
	train.lookout.reset(seed_value)
	train.sim.set_speed(kmh / 3.6)
	var e := TrainEngineer.new(train.sim, line)
	e.go_to(line.length - 3.0, kmh)
	e.lookout = train.lookout
	var drive := func() -> void: e.drive(1.0 / 60.0)
	get_tree().physics_frame.connect(drive)
	await wait_until(func() -> bool: return not train.derail.is_empty() or (train.lookout.alarmed() and absf(train.sim.v) < 0.02), 60 * 120)
	get_tree().physics_frame.disconnect(drive)
	return train


func test_the_engineer_sees_the_break_and_stops_short() -> void:
	var line := _line()
	var train: Train = await _engineer_run(line, 20.0, 380.0, 1.0)
	check(train.derail.is_empty(), "by day at 20 km/h he stops short")
	check(not train.lookout.log.is_empty(), "he saw it")
	var d1: float = train.lookout.log[0].distance if not train.lookout.log.is_empty() else 0.0
	var s1 := train.sim.s
	check(s1 < 380.0, "short of the break (front at %.1f)" % s1)
	line.free()
	await physics_frames(2)
	var again: Train = await _engineer_run(_line(), 20.0, 380.0, 1.0)
	check_near(float(again.lookout.log[0].distance) if not again.lookout.log.is_empty() else -1.0, d1, 0.01, "the same seed, the same sighting")
	check_near(again.sim.s, s1, 0.5, "and the same stop")


func test_by_night_he_sees_it_later() -> void:
	var day: Train = await _engineer_run(_line(), 40.0, 380.0, 1.0)
	var d_day: float = day.lookout.log[0].distance if not day.lookout.log.is_empty() else 0.0
	day.track.free()
	await physics_frames(2)
	var night: Train = await _engineer_run(_line(), 40.0, 380.0, 0.0)
	var d_night: float = night.lookout.log[0].distance if not night.lookout.log.is_empty() else 0.0
	check(d_night < d_day * 0.5, "the headlight shows it at %.0f m, the day at %.0f m" % [d_night, d_day])
	check(not night.derail.is_empty(), "at 40 km/h by night he can't stop in that")


func test_off_screen_it_derails_in_numbers() -> void:
	var line := _line()
	var c := line.chunk_at(380.0)
	c.tear_loose(c.rail_at(1, 380.5))
	var train := _train(line, 330.0)
	train.physical = false
	train.sim.set_speed(20.0 / 3.6)
	var ok := await wait_until(func() -> bool: return not train.derail.is_empty() and absf(train.sim.v) < 0.01, 60 * 60)
	check(ok, "off the rails, and stood")
	check(bool(train.derail.get("numeric", false)), "in numbers (no bodies)")
	check(train.wreck == null, "no wreck of bodies")
	var plough: float = pow(20.0 / 3.6, 2) / (2.0 * tuning.plough_g * 9.81)
	check(train.sim.s - float(train.derail.s) < plough * 2.0 + 5.0, "ploughs %.1f m past the break (%.1f at plough_g)" % [train.sim.s - float(train.derail.s), plough])


func test_the_wreck_and_the_damage_stay_after_a_save_and_load() -> void:
	var lab_line := _line()
	var c := lab_line.chunk_at(400.0)
	c.tear_loose(c.rail_at(-1, 401.0))
	var train := _train(lab_line, 340.0)
	train.sim.set_speed(20.0 / 3.6)
	await wait_until(func() -> bool: return not train.derail.is_empty(), 60 * 60)
	await physics_frames(60 * 6)
	var saved := {"track": lab_line.state.to_dict(), "wreck": train.wreck.to_dict()}
	var where := []
	for b: Dictionary in train.wreck.bodies:
		if is_instance_valid(b.body) and b.part != "broken":
			where.append((b.body as RigidBody3D).global_position)
	var damage: Array = lab_line.state.damage().map(func(x: Dictionary) -> String: return "%s %s %.1f" % [x.kind, x.key.section, x.key.at])
	for b: Dictionary in train.wreck.bodies:
		if is_instance_valid(b.body):
			(b.body as Node).queue_free()
	lab_line.queue_free()
	await physics_frames(3)
	var line := _line()
	var t2 := _train(line, 120.0)
	check_eq(line.state.from_dict(saved.track), 0, "every piece of track damage placed")
	var w := TrainWreck.restore(t2, saved.wreck)
	check_eq(w.bodies.size(), where.size(), "every wreck body laid again")
	var worst := 0.0
	for i in mini(where.size(), w.bodies.size()):
		worst = maxf(worst, (w.bodies[i].body as RigidBody3D).global_position.distance_to(where[i]))
	check(worst < 0.05, "where they lay (%.3f m at most)" % worst)
	var damage2: Array = line.state.damage().map(func(x: Dictionary) -> String: return "%s %s %.1f" % [x.kind, x.key.section, x.key.at])
	check_eq(damage2, damage, "the track's damage as it was")


func test_the_crew_mends_the_line_and_the_next_train_runs_through() -> void:
	var line := _line()
	var c := line.chunk_at(380.0)
	c.tear_loose(c.rail_at(-1, 380.5))
	# A crate on the line by it as well.
	var crate := RigidBody3D.new()
	crate.mass = 60.0
	crate.add_to_group(&"rubble")
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	cs.shape = box
	crate.add_child(cs)
	world.add_child(crate)
	var f := line.global_transform * line.transform_at(384.0)
	crate.global_position = f.origin + f.basis.y * 0.3
	await physics_frames(30)
	check(not line.state.damage().is_empty(), "the line's broken")
	var t := tuning.duplicate() as TrainTuning
	t.tie_s = 2.0
	t.rail_s = 4.0
	t.clear_s_per_t = 20.0
	line.repair.tuning = t
	line.repair.call_now()
	var ok := await wait_until(func() -> bool: return line.repair.state >= TrackRepair.LEAVING or line.repair.state == TrackRepair.IDLE and line.repair.log.size() > 3, 60 * 240)
	check(ok, "the crew comes and works: %s" % [line.repair.log])
	check(line.state.damage().filter(func(x: Dictionary) -> bool: return x.kind != &"blocked").is_empty(), "the line's whole again: %s" % [line.state.damage()])
	var local := line.global_transform.affine_inverse() * crate.global_position
	var s := line.curve.get_closest_offset(local)
	check(local.distance_to(line.point_at(s)) > 1.5, "the crate's off the line")
	var train := _train(line, 300.0)
	train.sim.set_speed(5.0)
	await wait_until(func() -> bool: return train.sim.s > 450.0 or not train.derail.is_empty(), 60 * 60)
	check(train.derail.is_empty(), "the next train runs through")
