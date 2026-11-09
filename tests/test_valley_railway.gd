extends TestCase
## The valley's main line (docs/briefs/valley-plan.md §4, §5, §12 G3; #716, train step 6 #542):
## config/valley.json's route laid as it stands where the plan's tables put it, on the bake's
## formation; the trestle lab's Trestle standing in the bake's canyon, its bents footed on it; Bridge
## B over the cutting clear of the train, the west portal on its mark; the daily timetable run on
## the real line (every stop on its mark and on time) and the train put by the game's clock.

const TT := "res://config/valley_timetable.json"

var tuning: TrainTuning


func before_each() -> void:
	tuning = load("res://config/train.tres")


func _line() -> TrackLine:
	return ValleyRailway.make_line(ValleyLayout.main(), tuning, ValleyTerrain.main())


## The railway built in a world of its own: the line, the bridges, the portal (and the train).
func _built(with_train := false) -> ValleyRailway:
	var world := Node3D.new()
	world.name = "RailWorld"
	add_child(world)
	var rw := ValleyRailway.new()
	rw.with_train = with_train
	world.add_child(rw)
	return rw


func test_the_line_is_where_the_plan_s_tables_put_it() -> void:
	var line := _line()
	check_near(line.length, 4600.0, 5.0, "4.6 km to the tunnel's end (%.1f)" % line.length)
	# The tables (docs/briefs/valley-tables.md "The railway"): x, z to the metre, rail Y to 5 cm.
	var table := {"east_portal": [2401, -334, -1.7], "overpass": [1912, -230, 5.7], "trestle_mid": [1183, -80, 7.1],
		"depot": [61, -75, 3.6], "ore_works": [-1542, -234, 25.3], "west_portal": [-1971, -360, 34.0]}
	for m: String in table:
		var p := line.transform * line.point_at(line.mark_s(m))
		var want: Array = table[m]
		check(Vector2(p.x, p.z).distance_to(Vector2(want[0], want[1])) < 1.5, "%s at (%.0f, %.0f) (the tables' (%d, %d))" % [m, p.x, p.z, want[0], want[1]])
		check_near(p.y, float(want[2]), 0.06, "%s's rail top at %.2f" % [m, p.y])
	check_near(line.grade_at(line.mark_s("overpass")), 0.015, 0.0005, "1.5 % up under the overpass")
	check_near(line.grade_at(line.mark_s("depot")), 0.0, 0.0001, "the depot level")
	check_near(line.grade_at(line.mark_s("west_portal") - 100.0), 0.025, 0.0005, "2.5 % up to the portal")
	check(line.curvature_at(line.mark_s("trestle_mid")) < 0.0, "the trestle on a right-hand bend")
	line.free()


func test_the_line_sits_on_the_bake_s_formation() -> void:
	var rw := _built()
	var g := rw.ground_check(5.0, 0.1)
	print("    the line against the bake: %d points, worst %.3f m, %d runs over 10 cm: %s" % [g.points, g.worst, g.runs.size(), g.runs])
	check(int(g.points) > 800, "checked along the line (%d points)" % g.points)
	check(float(g.worst) < 0.25, "the ground under the line's middle is the formation, rail less 1 m, within 25 cm (worst %.3f)" % g.worst)
	# Ground.height_at is the bake (G2), so the line's fill meets the ground the game stands on.
	var ter := ValleyTerrain.main()
	var line := rw.line
	for s in [300.0, 1000.0, 2416.0, 3500.0]:
		var f := line.global_transform * line.transform_at(s)
		var off: Vector3 = f.origin + f.basis.x * 12.0
		check_near(float(line.ground_y.call((line.transform.affine_inverse() * off).x, (line.transform.affine_inverse() * off).z)) + line.position.y,
				ter.height(off.x, off.z), 0.001, "the line's ground at %.0f m is the bake's" % s)
	rw.get_parent().queue_free()
	await physics_frames(2)


func test_the_great_trestle_stands_in_the_canyon() -> void:
	var rw := _built()
	await physics_frames(2)
	var line := rw.line
	check_eq(line.trestles.size(), 1, "one trestle")
	var tr: Trestle = line.trestles[0]
	check_eq(tr.crossing_id, "great_trestle", "at the route's crossing")
	check_near(tr.from_s, line.mark_s("trestle_east"), 0.5, "from the east rim's mark")
	check_near(tr.to_s, line.mark_s("trestle_west"), 0.5, "to the west rim's mark")
	var ter := ValleyTerrain.main()
	var tallest := 0.0
	for b: Dictionary in tr.bents:
		var f := line.global_transform * line.transform_at(float(b.s))
		check_near(float(b.ground) + line.position.y, ter.height(f.origin.x, f.origin.z), 0.01, "bent %d footed on the bake" % b.index)
		tallest = maxf(tallest, float(b.height))
	check(tallest > 25.0 and tallest < 29.0, "its tallest bent %.1f m, rail to creek ~27 m (the plan's 27.2)" % tallest)
	var mid := line.global_transform * line.transform_at(line.mark_s("trestle_mid"))
	check(mid.origin.y - ter.height(mid.origin.x, mid.origin.z) > 24.0, "the canyon's floor %.1f m under the middle" % (mid.origin.y - ter.height(mid.origin.x, mid.origin.z)))
	check(tr.members_without_load_path().is_empty(), "every member has its load path (%d without)" % tr.members_without_load_path().size())
	rw.get_parent().queue_free()
	await physics_frames(2)


func test_bridge_b_over_the_cutting_clears_the_train() -> void:
	var rw := _built()
	await physics_frames(2)
	var br := rw.overpass
	check(br != null and br.member_count() > 100, "Bridge B built as members (%d)" % (br.member_count() if br else 0))
	if br == null:
		return
	var line := rw.line
	var s := line.mark_s("overpass")
	var f := line.global_transform * line.transform_at(s)
	var rail := f.origin
	var ter := ValleyTerrain.main()
	# The cutting is the bake's: the ground beside the line rises to the natural ground.
	check(ter.height(rail.x, rail.z) < rail.y - 0.9, "the line's bed in the cutting")
	var under := br.underside_over(rail)
	check(under - rail.y >= 3.9 + 0.5, "the deck's underside %.2f m over the rail: the engine's 3.9 m stack and half a metre" % (under - rail.y))
	check_near(br.deck_from.y - rail.y, 5.45, 0.01, "the road 5.45 m over the rail (the plan's)")
	check(br.length() > 20.0, "the deck spans the cutting (%.1f m)" % br.length())
	var closest := INF
	for b: Dictionary in br.bents:
		for p: StructureMember in b.posts:
			var pp := p.global_position
			var local := f.affine_inverse() * pp
			closest = minf(closest, absf(local.x))
	check(closest > tuning.car_width * 0.5 + 1.5, "no post within %.1f m of the rails' middle (closest %.2f)" % [tuning.car_width * 0.5 + 1.5, closest])
	for e in [br.deck_from, br.deck_to]:
		check(absf(ter.height(e.x, e.z) - (e.y - 0.5)) < 0.6, "a deck end on the ground (%.2f under it)" % (e.y - ter.height(e.x, e.z)))
	check(br.members_without_load_path().is_empty(), "it stands: every member has its load path")
	rw.get_parent().queue_free()
	await physics_frames(2)


func test_the_west_portal() -> void:
	var rw := _built()
	await physics_frames(2)
	var tp := rw.portal
	check(tp != null and tp.posts.size() == 2, "the portal's posts")
	if tp == null:
		return
	var line := rw.line
	var f := line.global_transform * line.transform_at(line.mark_s("west_portal"))
	check(tp.frame.origin.distance_to(f.origin) < 0.01, "on the west_portal mark")
	for p in tp.posts:
		check(absf((f.affine_inverse() * p.global_position).x) > tuning.car_width * 0.5 + 0.5, "a post clear of the cars")
	check(tp.header.global_position.y - f.origin.y > 4.5, "the header over the engine")
	check(tp.members_without_load_path().is_empty(), "it stands")
	check(rw.get_node_or_null(^"Mouth") != null, "the dark mouth behind it")
	rw.get_parent().queue_free()
	await physics_frames(2)


## The daily timetable on the valley's line, 1D (the train lab's timetable_run on this route): every
## stop on its mark and on time, its times from the line.
func test_the_daily_timetable_runs_the_valley_line() -> void:
	var line := _line()
	var tt := TrainTimetable.load_file(TT)
	tt.fill(line, tuning)
	check_eq(tt.stops.size(), 4, "east, the depot, the Ore Works, the tunnel")
	var sim := TrainSim.new(tuning, line)
	sim.place(line.mark_s("east_start"))
	var eng := TrainEngineer.new(sim, line)
	eng.run(tt)
	var dt := 1.0 / 60.0
	var fastest := 0.0
	while eng.state != TrainEngineer.DONE and sim.time < 7200.0:
		eng.drive(dt)
		sim.step(dt)
		fastest = maxf(fastest, sim.v * 3.6)
	check_eq(eng.state, TrainEngineer.DONE, "it ran the day (%.0f s)" % sim.time)
	check_eq(eng.stop_log.size(), 3, "three stops after east_start")
	for st: Dictionary in eng.stop_log:
		check(absf(float(st.error)) <= 1.0, "%s: on the mark (%.2f m)" % [st.mark, st.error])
		check(float(st.delay) <= 15.0, "%s: not late (%.1f s)" % [st.mark, st.delay])
		# (Into the tunnel he may be early: up the 2.5 % at his least running speed the leg's padding
		# isn't used. He never leaves a stop early: TrainEngineer._wait.)
		if st.mark != "tunnel":
			check(float(st.delay) >= -15.0, "%s: on time (%.1f s)" % [st.mark, st.delay])
	check(fastest <= tt.max_kmh() + 1.0, "never past %.0f km/h (%.1f)" % [tt.max_kmh(), fastest])
	# Its times from the line: the depot about noon by the game's clock (a game hour 112.5 s).
	var depot_h := float(tt.data.start_hour) + float(tt.stops[1].arrive) / 112.5
	print("    the valley's timetable: %s; the depot at %.2f h" % [tt.describe(), depot_h])
	check(depot_h > 10.5 and depot_h < 13.0, "the morning train at the depot about noon (%.2f h)" % depot_h)
	line.free()


## The train put where the timetable has it by the clock, and run from there by the engineer.
func test_the_train_by_the_clock() -> void:
	var rw := _built(true)
	await physics_frames(2)
	check(rw.train != null and not rw.timed, "the train, standing while its timetable's worked out (on a worker)")
	var t0 := Time.get_ticks_msec()
	while not rw.timed and Time.get_ticks_msec() - t0 < 60000:  # (a worker's seconds, not ticks)
		await physics_frames(1)
	check(rw.timed, "its timetable worked out (%.1f s)" % ((Time.get_ticks_msec() - t0) / 1000.0))
	await physics_frames(2)
	check(rw.engineer != null, "its engineer")
	print("    the railway's build (ms): %s" % rw.build_ms)
	if rw.train == null:
		return
	var line := rw.line
	var tt := rw.timetable
	rw.start_run(-30.0, 1)
	await physics_frames(2)
	check_near(rw.train.sim.s, line.mark_s("east_start"), 0.5, "before it leaves: standing at east_start")
	check_eq(rw.engineer.state, TrainEngineer.WAIT, "waiting")
	var at_depot := float(tt.stops[1].arrive) + 20.0
	rw.start_run(at_depot, 1)
	await physics_frames(2)
	check_near(rw.train.sim.s, line.mark_s("depot"), 0.5, "mid-morning's dwell: at the depot")
	check_eq(rw.engineer.stop, 1, "his stop the depot")
	check(rw.engineer_body != null and rw.engineer_body.get_parent() == rw.train.view.solids[0], "the engineer in the cab")
	# Late out of the depot: he leaves at once (his least dwell counted from the timetable's arrival).
	rw.start_run(float(tt.stops[1].depart) + 60.0, 1)
	await physics_frames(900)
	check(rw.train.sim.s - line.mark_s("depot") > 2.0, "a minute late, he's away (%.2f m on)" % (rw.train.sim.s - line.mark_s("depot")))
	# Half way between the depot and the Ore Works by the clock: running there, at the planned run's speed.
	rw.start_run((float(tt.stops[1].depart) + float(tt.stops[2].arrive)) * 0.5, 1)
	await physics_frames(2)
	var s := rw.train.sim.s
	check(s > line.mark_s("depot") + 300.0 and s < line.mark_s("ore_works") - 300.0, "mid-leg: between the depot and the Ore Works (%.0f m)" % s)
	check(rw.train.sim.v > 2.0, "and running (%.1f km/h)" % (rw.train.sim.v * 3.6))
	check_eq(rw.engineer.state, TrainEngineer.RUN, "the engineer driving on")
	await physics_frames(300)
	check(absf(rw.engineer.delay()) < 20.0, "about on time (%.1f s)" % rw.engineer.delay())
	rw.start_run(float(tt.stops[3].arrive) + 1.0, 1)
	await physics_frames(2)
	check_near(rw.train.sim.s, line.mark_s("tunnel"), 0.5, "the day's run done: in the tunnel")
	var tail := rw.train.sim.s - rw.train.sim.length
	check(tail > line.mark_s("west_portal"), "all of it past the portal (its tail %.0f m in)" % (tail - line.mark_s("west_portal")))
	rw.get_parent().queue_free()
	await physics_frames(3)
