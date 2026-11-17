extends TestCase
## The regulator wall clock (#1030, #789): its hands show DayCycle's time, its pendulum swings, it ticks
## as a placed sound, and its case hangs like any wall prop.

var world: Node3D
var clock: WallClock
var wall: Structure


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	# A wall facing +Z, its face at z = 0: studs, and boards across them (as test_wall_props).
	wall = Structure.new()
	wall.structure_id = &"wall"
	world.add_child(wall)
	for x in [-1.2, -0.6, 0.0, 0.6, 1.2]:
		wall.add_member("stud%d" % int(x * 10), &"stud", &"framing", Vector3(0.05, 3.0, 0.1), Vector3(x, 1.5, -0.07))
	for i in 20:
		wall.add_member("board%d" % i, &"board", &"framing", Vector3(2.6, 0.15, 0.02), Vector3(0, 0.075 + 0.15 * i, -0.01))
	wall.infer_supports()


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _make() -> WallClock:
	clock = PropKit.make(&"wall_clock") as WallClock
	check(clock != null, "the kit makes a WallClock")
	clock.position = Vector3(0, 0.6, 0.0)
	world.add_child(clock)
	return clock


func test_hand_angles_follow_the_time() -> void:
	check_near(WallClock.hand_angles(3.0).x, 90.0, 0.001, "three o'clock: the hour hand at 90")
	check_near(WallClock.hand_angles(3.0).y, 0.0, 0.001, "three o'clock: the minute hand at twelve")
	check_near(WallClock.hand_angles(17.5).x, 165.0, 0.001, "half past five: the hour hand halfway to six")
	check_near(WallClock.hand_angles(17.5).y, 180.0, 0.001, "half past: the minute hand at six")
	check_near(WallClock.hand_angles(0.25).y, 90.0, 0.001, "a quarter past: 90")
	check_near(WallClock.hand_angles(12.0).x, 0.0, 0.001, "noon: the hour hand at twelve")


func test_the_hands_turn_to_the_set_time() -> void:
	_make()
	await physics_frames(2)
	for hour: float in [0.0, 3.0, 8.5, 17.75, 23.99]:
		clock.show_time(hour)
		var a := WallClock.hand_angles(hour)
		var hp := clock.get_node("Works").get_child(1) as Node3D
		var mp := clock.get_node("Works").get_child(2) as Node3D
		check_near(rad_to_deg(-hp.rotation.z), a.x, 0.01, "%.2f: the hour hand" % hour)
		check_near(rad_to_deg(-mp.rotation.z), a.y, 0.01, "%.2f: the minute hand" % hour)


func test_the_hands_read_the_day_cycles_time() -> void:
	var day := DayCycle.new()
	day.add_to_group(&"day_cycle")
	world.add_child(day)
	day.set_time(14.5)
	_make()
	await physics_frames(2)
	var hp := clock.get_node("Works").get_child(1) as Node3D
	var mp := clock.get_node("Works").get_child(2) as Node3D
	check_near(rad_to_deg(-hp.rotation.z), 75.0, 0.01, "half past two on the day cycle: the hour hand")
	check_near(rad_to_deg(-mp.rotation.z), 180.0, 0.01, "the minute hand")


func test_the_pendulum_swings_each_way() -> void:
	_make()
	await physics_frames(1)
	var period: float = clock.definition.pendulum.period
	check_near(clock.pendulum_angle(0.0), 0.0, 0.001, "at the bottom to start")
	check(clock.pendulum_angle(period * 0.25) > 3.0, "out one way")
	check(clock.pendulum_angle(period * 0.75) < -3.0, "and the other")
	check_near(clock.pendulum_angle(period), 0.0, 0.001, "back after one period")


func test_the_case_hangs_and_holds() -> void:
	_make()
	await physics_frames(KitProp.SETTLE_FRAMES + 3)
	check(clock.case_prop != null and clock.case_prop.hung(), "the case hangs on its nail")
	check(clock.case_prop.member_count() >= 15, "it's a case of members (%d)" % clock.case_prop.member_count())
	check(not clock.stopped, "running")


func _ticks() -> Array:
	var out := []
	var holder := get_viewport().get_node_or_null(^"GameAudio")
	if holder == null:
		return out
	for c in holder.get_children():
		if c is AudioStreamPlayer3D and not c.is_queued_for_deletion():
			var st := (c as AudioStreamPlayer3D).stream
			if st == SynthSounds.get_sound(&"clock_tick") or st == SynthSounds.get_sound(&"clock_tock"):
				out.append(c)
	return out


func test_it_ticks_as_a_placed_sound_and_a_crowd_loses_it() -> void:
	_make()
	await physics_frames(2)
	clock._tick_now()
	var quiet := _ticks()
	check(quiet.size() >= 1, "a tick is played (%d)" % quiet.size())
	var quiet_db := (quiet[0] as AudioStreamPlayer3D).volume_db if not quiet.is_empty() else 0.0
	for p in quiet:
		(p as Node).queue_free()
	await physics_frames(2)
	for i in 6:
		var man := Node3D.new()
		man.add_to_group(&"people")
		world.add_child(man)
		man.global_position = clock.global_position + Vector3(0.5 * i, 0, 2.0)
	clock._tick_now()
	var busy := _ticks()
	var busy_db := (busy[0] as AudioStreamPlayer3D).volume_db if not busy.is_empty() else -99.0
	check(busy_db < quiet_db - 6.0, "six people round it take it down (%.0f dB, was %.0f)" % [busy_db, quiet_db])
