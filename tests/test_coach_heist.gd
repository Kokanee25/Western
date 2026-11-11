extends TestCase
## The coach heist's systems (issue #770, Sean's 1B 2C and "dents OK" on #784; the ram, Sean's
## call on #791, #794; experiments/coach_heist/): dents in iron plate by the energy put into it
## (Dents, DentWatch), the log as a rigid body of green pine held by its deck's members
## (RollingLog), the swinging ram (SwingingRam), the Baron's coach driven and handed to physics
## when struck (CoachDrive), a loose body weighed by its members (Structure.mass_by_members), and a
## hard knock on the head dazing an outlaw.

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


## A post with an 8 mm iron plate on its face (a kit prop of the lab's).
func _plated() -> KitProp:
	var id := &"test_plated_post"
	PropKit._defs[id] = {"id": "test_plated_post", "kind": "members", "wood": "oak", "members": [
		{"id": "post", "kind": "post", "size": [0.3, 1.6, 0.3], "at": [0.0, 0.8, 0.0]},
		{"id": "plate", "kind": "trim", "wood": "iron", "size": [0.6, 0.6, 0.008], "at": [0.0, 1.2, 0.154], "plate": true},
	]}
	var p := PropKit.spawn(id)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	return p


func _m(p: KitProp, id: String) -> StructureMember:
	return p.get_member(StringName("%s/%s" % [p.structure_id, id]))


# --- The rules -------------------------------------------------------------------------------------

func test_dent_depth_goes_by_the_square_root_of_the_energy() -> void:
	var dt := DentTuning.new()
	# #784's figures: 8 mm wrought iron at 190 MPa.
	check_near(Dents.joules_for(0.01, 0.008, dt), 477.5, 1.0, "1 cm takes ~0.48 kJ")
	check_near(Dents.joules_for(0.04, 0.008, dt), 7640.0, 10.0, "4 cm takes ~7.6 kJ")
	check_near(Dents.depth_for(Dents.joules_for(0.023, 0.008, dt), 0.008, dt), 0.023, 1e-6, "depth and energy are each other's inverse")
	check_near(Dents.depth_for(4.0 * 1000.0, 0.008, dt) / Dents.depth_for(1000.0, 0.008, dt), 2.0, 1e-6, "four times the energy, twice as deep")
	# B's log through the step, #784: ~23 kJ at 30%: ~4 cm.
	check_near(Dents.depth_for(23000.0 * dt.share, 0.008, dt), 0.038, 0.003, "the plan's log dent")
	# A .45 ball's ~620 J at 5%: a dimple of 2-3 mm.
	var ball := Dents.depth_for(620.0 * dt.ball_share, 0.008, dt)
	check(ball > 0.002 and ball < 0.003, "a ball dimples it 2-3 mm (%.4f)" % ball)


func test_the_dented_mesh_is_pushed_in_where_the_dent_is_and_flat_elsewhere() -> void:
	var size := Vector3(0.6, 0.6, 0.008)
	var dents := [{"c": [0.0, 0.0, 0.0], "ax": [0.0, 0.0, 0.0], "len": 0.0, "r": 0.15, "d": 0.03, "s": -1}]
	var mesh := Dents.dented_mesh(size, dents, 0.025)
	var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var lowest := 0.0
	var corner_moved := 0.0
	for v in verts:
		lowest = minf(lowest, v.z)
		if Vector2(v.x, v.y).length() > 0.25:
			corner_moved = maxf(corner_moved, absf(absf(v.z) - size.z * 0.5))
	var deepest := lowest + size.z * 0.5
	check_near(deepest, -0.03, 0.0015, "its middle pushed in by the dent's depth (the grid's nearest point)")
	check(corner_moved < 1e-5, "outside the dent it's flat (%.6f)" % corner_moved)
	var flat := Dents.dented_mesh(size, [], 0.025)
	check(flat.surface_get_array_len(0) > 1000, "built dense: squares of 2.5 cm")
	# Its front faces wind so the undented face looks out (Godot: clockwise from outside).
	var idx: PackedInt32Array = flat.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var fv: PackedVector3Array = flat.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var n := (fv[idx[1]] - fv[idx[0]]).cross(fv[idx[2]] - fv[idx[0]])
	var centre := (fv[idx[0]] + fv[idx[1]] + fv[idx[2]]) / 3.0
	check(n.dot(centre) < 0.0, "the first face winds clockwise seen from outside")


func test_a_plate_dents_where_it_is_struck_and_blows_there_add_up() -> void:
	var p: KitProp = await _plated()
	var plate := _m(p, "plate")
	check(Dents.can_dent(plate), "a plate member dents")
	check(not Dents.can_dent(_m(p, "post")), "the oak post doesn't")
	var at := plate.global_position + Vector3(0.0, 0.0, 0.004)
	var r := Dents.dent(plate, at, 2000.0, Vector3.BACK * -1.0, 0.15)
	check_near(float(r.depth), Dents.depth_for(2000.0, 0.008), 1e-4, "the dent's depth from its energy")
	var r2 := Dents.dent(plate, at + Vector3(0.02, 0.0, 0.0), 2000.0, Vector3.FORWARD, 0.15)
	check_eq(Dents.on(plate).size(), 1, "a second blow in the same place deepens the first")
	check_near(float(r2.depth), Dents.depth_for(4000.0, 0.008), 1e-4, "their energies add")
	Dents.dent(plate, plate.global_position + Vector3(0.25, 0.25, 0.0), 500.0, Vector3.FORWARD, 0.05)
	check_eq(Dents.on(plate).size(), 2, "one elsewhere is its own")
	check(Dents.mesh_of(plate).mesh.get_faces().size() > 3000, "its mesh is the dense dented one")
	# Saved and put back on a fresh copy.
	var saved := Dents.state(p)
	check(saved.has(String(plate.member_id)), "the plate's dents saved")
	var q: KitProp = await _plated()
	Dents.restore(q, {String(_m(q, "plate").member_id): saved[String(plate.member_id)]})
	check_eq(Dents.on(_m(q, "plate")).size(), 2, "restored")


func test_past_the_tear_depth_the_plate_comes_off() -> void:
	var p: KitProp = await _plated()
	var plate := _m(p, "plate")
	var r := Dents.dent(plate, plate.global_position, Dents.joules_for(0.09, 0.008), Vector3.FORWARD, 0.2)
	check(bool(r.torn), "a 9 cm dent tears it")
	await physics_frames(2)
	check(plate.broken, "off its rivets: broken out of the prop")
	check(not _m(p, "post").broken, "the post behind it stands")


func test_a_ball_dimples_a_plate() -> void:
	var p: KitProp = await _plated()
	var watch := DentWatch.new()
	world.add_child(watch)
	var plate := _m(p, "plate")
	Events.bullet_hit.emit({"position": plate.global_position + Vector3(0.0, 0.0, 0.004), "normal": Vector3.BACK,
			"direction": Vector3.FORWARD, "collider": plate, "member_id": plate.member_id, "penetrated": false,
			"energy_before": 620.0, "energy_after": 0.0, "mass": 0.016})
	check_eq(watch.made.size(), 1, "one dent")
	var d := Dents.deepest(plate)
	check(d > 0.002 and d < 0.003, "2-3 mm (%.4f)" % d)


# --- The log ---------------------------------------------------------------------------------------

func test_the_log_weighs_its_green_pine_and_rolls_once_its_last_hold_goes() -> void:
	var lg := RollingLog.new()
	world.add_child(lg)
	check_near(lg.mass, PI * 0.09 * 6.0 * 740.0, 1.0, "0.6 x 6 m of green pine: ~1.25 t")
	check_near(RollingLog.rolling_speed(5.5), 8.48, 0.01, "rolling off a 5.5 m drop: sqrt(4/3 g h)")
	var id := &"test_log_holds"
	PropKit._defs[id] = {"id": "test_log_holds", "kind": "members", "wood": "oak", "members": [
		{"id": "wedge", "kind": "post", "size": [0.25, 0.12, 0.14], "at": [3.0, 0.06, 0.0]},
		{"id": "pin", "kind": "post", "size": [0.1, 0.3, 0.1], "at": [-3.0, 0.15, 0.0]}]}
	var deck := PropKit.spawn(id)
	world.add_child(deck)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	lg.global_position = Vector3(0.0, 0.3, 0.0)
	lg.hold_by(deck, ["wedge", "pin"])
	check(lg.freeze, "held")
	deck.break_member(_m(deck, "wedge"))
	await physics_frames(1)
	check(lg.freeze, "one hold left: still held")
	deck.break_member(_m(deck, "pin"))
	await physics_frames(1)
	check(not lg.freeze and not lg.held, "the last hold gone: it's let go")


func test_the_log_rolls_down_a_bank_nearly_as_fast_as_it_would_without_losses() -> void:
	# A 1:1.5 bank 2 m high (the lab measured 97% at every drop).
	var bank := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([Vector3(-4, 0, 0), Vector3(-4, 2, -3), Vector3(-4, 0, -3), Vector3(4, 0, 0), Vector3(4, 2, -3), Vector3(4, 0, -3)])
	cs.shape = shape
	bank.add_child(cs)
	world.add_child(bank)
	var lg := RollingLog.new()
	world.add_child(lg)
	lg.global_position = Vector3(0.0, 2.0 + 0.3, -3.0 + 0.02)
	lg.linear_velocity = Vector3(0, 0, 0.4)
	var at_foot := -1.0
	for i in 240:
		await physics_frames(1)
		if lg.global_position.z >= 0.0:
			at_foot = lg.linear_velocity.length()
			break
	check(at_foot > 0.93 * RollingLog.rolling_speed(2.0), "at the foot %.2f m/s of the lossless %.2f" % [at_foot, RollingLog.rolling_speed(2.0)])


# --- The coach -------------------------------------------------------------------------------------

func _coach() -> KitProp:
	var c := PropKit.spawn(&"baron_coach")
	world.add_child(c)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	return c


## A log thrown sideways into the standing coach at `y`: how far over it leans.
func _strike(y: float, v: float) -> float:
	var c: KitProp = await _coach()
	var drive := CoachDrive.new()
	world.add_child(drive)
	drive.start(c)
	drive.driving = false
	var lg := RollingLog.new()
	world.add_child(lg)
	lg.global_position = Vector3(0.0, y, -0.71 - 0.3 - 0.08)
	lg.linear_velocity = Vector3(0, 0, v)
	drive.strikers.append(lg)
	var most := 0.0
	for i in 240:
		await physics_frames(1)
		if drive.loose:
			most = maxf(most, drive.lean())
	check(drive.loose, "struck: handed to physics")
	check(c.mass_by_members and not c.breaks_up, "weighed by its members, kept whole")
	return most


func test_struck_high_the_coach_goes_over() -> void:
	var lean := await _strike(2.0, 8.0)
	check(lean > 60.0, "B's log at 8 m/s on the upper plates puts it over (%.0f deg)" % lean)


func test_struck_at_its_middle_the_coach_is_shoved_not_tipped() -> void:
	# At its centre of weight's height the blow has no lever: it slides (the lab: up to 12 m/s).
	var lean := await _strike(1.39, 6.0)
	check(lean < 30.0, "B's log at 6 m/s at 1.39 m shoves it (%.0f deg)" % lean)


func test_a_driven_coach_moves_along_its_heading_and_its_riders_with_it() -> void:
	var c: KitProp = await _coach()
	var drive := CoachDrive.new()
	world.add_child(drive)
	drive.start(c)
	var man := HumanBody.new()
	man.body_model = &"outlaw"
	man.has_gun = false
	world.add_child(man)
	var seat: Dictionary = (c.definition.seats_at as Array)[0]
	drive.seat(man, PropKit.vec(seat.at), 1.105)
	var x0 := c.global_position.x
	var off := man.global_position - c.global_position
	await physics_frames(60)
	check_near(c.global_position.x - x0, -drive.speed, 0.05, "a second at the team's walk, front first (-x)")
	check((man.global_position - c.global_position).distance_to(off) < 0.01, "the guard rides along in his seat")


func test_the_strongbox_rides_in_its_place_while_the_coach_is_driven() -> void:
	var c := PropKit.spawn(&"baron_coach")
	world.add_child(c)
	c.position = Vector3(8.0, 0.0, 0.0)  # (placed after it's in the tree, as the lab and the cut do)
	var drive := CoachDrive.new()
	world.add_child(drive)
	drive.start(c)
	var sb := c.carried("strongbox")
	await physics_frames(90)
	check(not sb.loose, "it stands under the rear bench while the coach drives")
	check(c.to_local(sb.global_position).distance_to(Vector3(1.04, 1.105, 0.0)) < 0.01, "in its place")
	drive.hand_off("test")
	await physics_frames(2)
	check(sb.loose, "handed off, it's loose inside the coach")


func test_the_loose_body_weighs_where_its_members_do() -> void:
	var id := &"test_two_woods"
	PropKit._defs[id] = {"id": "test_two_woods", "kind": "members", "wood": "oak", "members": [
		{"id": "base", "kind": "post", "wood": "weathered_pine", "size": [1.0, 0.2, 1.0], "at": [0.0, 0.1, 0.0]},
		{"id": "lump", "kind": "post", "wood": "iron", "size": [0.2, 0.2, 0.2], "at": [0.4, 0.3, 0.0]}]}
	var p := PropKit.spawn(id)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	p.mass_by_members = true
	var bodies := p.go_loose()
	check_eq(bodies.size(), 1, "one body")
	var rb := bodies[0]
	var kg_base := 0.2 * 420.0
	var kg_lump := 0.008 * 7600.0
	var want := (Vector3(0, 0.1, 0) * kg_base + Vector3(0.4, 0.3, 0) * kg_lump) / (kg_base + kg_lump)
	check_eq(rb.center_of_mass_mode, RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM, "its own centre of weight")
	check((rb.global_transform * rb.center_of_mass).distance_to(p.global_transform * want) < 0.01,
			"by the members' weights, toward the iron (%s)" % (rb.global_transform * rb.center_of_mass))


# --- The ram (#794) ---------------------------------------------------------------------------------

func _ram(drop := 3.3) -> SwingingRam:
	var ram := SwingingRam.new()
	ram.pull_up = drop
	world.add_child(ram)
	ram.position = Vector3(0.0, 0.0, -1.03)
	ram.build()
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	return ram


func test_the_ram_hangs_held_on_its_frame_until_its_pin_goes() -> void:
	var ram := await _ram()
	check(ram.frame.settle().is_empty() and not ram.frame.loose, "the frame stands")
	check(ram.frame.members_without_load_path().is_empty(), "every member of it has its way down")
	check(not ram.trip.loose, "the trip's stake stands on the ground")
	await physics_frames(30)
	check(ram.is_held() and ram.log_body.freeze, "held back up its arc")
	check_near(ram.to_local(ram.log_body.global_position).y, 2.0 + 3.3, 0.01, "its middle 3.3 m over the bottom of its swing")
	ram.release()
	await physics_frames(2)
	check(not ram.is_held() and not ram.log_body.freeze, "the pin out, it swings")


func test_the_ram_swings_to_the_bottom_at_the_speed_its_drop_gives() -> void:
	var ram := await _ram()
	ram.release()
	var at_bottom := {}
	for i in 120:
		await physics_frames(1)
		if ram.to_local(ram.log_body.global_position).z >= 0.0:
			at_bottom = {"t": i / 60.0, "v": ram.log_body.linear_velocity.length(), "y": ram.to_local(ram.log_body.global_position).y,
					"pull": ram.tension[0] + ram.tension[1]}
			break
	check(not at_bottom.is_empty(), "it reached the bottom")
	check_near(float(at_bottom.get("v", 0.0)), sqrt(2.0 * 9.81 * 3.3), 0.1, "~8 m/s, sqrt(2 g h)")
	check_near(float(at_bottom.get("y", 0.0)), 2.0, 0.05, "2 m up: the upper plates")
	check_near(float(at_bottom.get("t", 0.0)), 1.28, 0.05, "~1.3 s from the pin")
	# Both ropes: its weight and its turn, m (g + v^2 / L), ~27 kN (1-inch manila holds ~40 kN).
	var m := ram.log_body.mass
	var want := m * (9.81 + 2.0 * 9.81 * 3.3 / ram.pivot_length())
	check_near(float(at_bottom.get("pull", 0.0)), want, want * 0.05, "the ropes' pull at the bottom (%.0f N)" % want)
	check(ram.most_tension < 20000.0, "neither rope past 20 kN")


func test_a_ball_through_the_pin_lets_the_ram_go() -> void:
	var ram := await _ram()
	var pin := ram.pin_position()
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var from := pin + Vector3(6.0, 1.5, 0.0)
	var b := ballistics.fire(from, (pin - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	check(not ram.is_held(), "the pin split, the log's let go")


func test_a_rope_lets_go_when_its_cap_breaks() -> void:
	var ram := await _ram()
	ram.release()
	await physics_frames(5)
	check_eq(ram.ropes_on(), 2, "both ropes on")
	var cap: StructureMember = ram.frame.members[StringName("%s/cap_0" % ram.frame.structure_id)]
	ram.frame.break_member(cap, Vector3.UP)
	await physics_frames(2)
	check_eq(ram.ropes_on(), 1, "the broken cap's rope is gone")


func test_the_ram_tips_the_coach_and_dents_its_upper_plates() -> void:
	var c: KitProp = await _coach()
	var drive := CoachDrive.new()
	world.add_child(drive)
	drive.start(c)
	drive.driving = false
	# Its six riders fill the coach's contact report: the dents are read from the ram's side.
	for s: Dictionary in c.definition.seats_at:
		var man := HumanBody.new()
		man.body_model = &"outlaw"
		man.has_gun = false
		world.add_child(man)
		var at := PropKit.vec(s.at)
		drive.seat(man, at, at.y - 0.405 if s.has("who") else 1.105, float(s.yaw))
	var watch := DentWatch.of(get_tree())
	watch.made.clear()
	var ram := await _ram()
	drive.strikers.append(ram.log_body)
	ram.release()
	var most := 0.0
	for i in 240:
		await physics_frames(1)
		if drive.loose:
			most = maxf(most, drive.lean())
	check(drive.loose, "struck: handed to physics")
	check(most > 60.0, "over (%.0f deg)" % most)
	var deepest := 0.0
	var upper := 0
	for d: Dictionary in watch.made:
		deepest = maxf(deepest, float(d.depth))
		if String(d.member).contains("_up"):
			upper += 1
	check(upper >= 3, "the upper plates dented (%d)" % upper)
	check(deepest > 0.025 and deepest < 0.05, "the deepest ~3-4 cm (%.1f cm)" % (deepest * 100.0))
	check_eq(watch.meshes_waiting(), 0, "every dented plate's mesh rebuilt by now")


func test_a_seated_mans_blocker_doesnt_shove_the_coach_at_the_hand_off() -> void:
	var c: KitProp = await _coach()
	var drive := CoachDrive.new()
	world.add_child(drive)
	drive.start(c)
	var man := HumanBody.new()
	man.body_model = &"outlaw"
	man.has_gun = false
	world.add_child(man)
	var seat: Dictionary = (c.definition.seats_at as Array)[4]
	drive.seat(man, PropKit.vec(seat.at), float(seat.at[1]) - 0.405, float(seat.yaw))
	await physics_frames(10)
	drive.hand_off("test")
	await physics_frames(3)
	var v := drive.main_body().linear_velocity
	check(v.distance_to(drive.heading * drive.speed) < 0.5, "it rolls on at the team's walk (%s)" % v)


# --- The guards ------------------------------------------------------------------------------------

func test_a_hard_knock_on_the_head_dazes_an_outlaw() -> void:
	check_eq(OutlawBrain.head_stun_seconds({"segment": &"head", "joules": 30.0}), 0.0, "a light knock: nothing")
	check_near(OutlawBrain.head_stun_seconds({"segment": &"head", "joules": 60.0}), 1.0, 1e-6, "from 60 J, a second")
	check_near(OutlawBrain.head_stun_seconds({"segment": &"head", "joules": 240.0}), 4.0, 1e-6, "harder, longer")
	check_near(OutlawBrain.head_stun_seconds({"segment": &"head", "joules": 5000.0}), OutlawBrain.HEAD_STUN_MAX, 1e-6, "to the most")
	check_eq(OutlawBrain.head_stun_seconds({"segment": &"chest", "joules": 500.0}), 0.0, "a knock elsewhere doesn't daze him")
