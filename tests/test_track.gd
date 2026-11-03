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
