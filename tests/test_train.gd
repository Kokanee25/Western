extends TestCase
## The train's 1D simulation and its track (src/train/, the train lab: issues #543, #551,
## docs/briefs/train.md): the same inputs give the same run; the start, the stop from 30 km/h and
## the top speed fall in their proposed ranges; it slows on a climb and gathers speed down one;
## the brakes hold it standing on the grade; the track's curve is the line's length and its
## grade and curvature are as laid; the cars stand on the line where the 1D distance says.
## Step 2: the slack runs out car by car on a start and bunches on a stop, the same every time;
## the engineer stops on the mark; the timetable is read from data, its times from the line; a
## re-laid line (a second route file) builds, and the same timetable runs it, on every mark.

const SC := preload("res://experiments/train_lab/scenarios.gd")
const LINE := preload("res://experiments/train_lab/test_line.gd")

var tuning: TrainTuning


func before_each() -> void:
	tuning = load("res://config/train.tres")


func test_same_inputs_same_stop() -> void:
	var a: Dictionary = SC.stop30(tuning).summary
	var b: Dictionary = SC.stop30(tuning).summary
	check_eq(a.distance, b.distance, "two stops from 30 km/h end at the same distance, to the bit")
	var w1: Dictionary = SC.whole_run(tuning).summary
	var w2: Dictionary = SC.whole_run(tuning).summary
	check_eq(w1.stopped_at, w2.stopped_at, "two runs depot to mine stop at the same spot")
	check_near(w1.short_of_B, 0.0, 15.0, "step 1's simple driver brings it near the mine (the engineer stops on it)")


func test_start_in_range() -> void:
	var r: Dictionary = SC.start(tuning).summary
	check(r.has("t25"), "it reaches 25 km/h on the straight")
	var rng := tuning.start_to_25_range
	check(r.t25 >= rng.x and r.t25 <= rng.y, "0 to 25 km/h takes %.1f s (proposed %s)" % [r.t25, rng])
	check(r.t10 > r.t25 * 0.25, "a slow start: 10 km/h comes at %.1f s of %.1f" % [r.t10, r.t25])


func test_stop_from_30_in_range() -> void:
	var r: Dictionary = SC.stop30(tuning).summary
	var rng := tuning.stop_from_30_range
	check(r.distance >= rng.x and r.distance <= rng.y, "stops from 30 km/h in %.1f m (proposed %s)" % [r.distance, rng])


func test_top_speed_in_range() -> void:
	var top := SC.top_speed(tuning)
	var rng := tuning.top_speed_range
	check(top >= rng.x and top <= rng.y, "top speed on the level %.1f km/h (proposed %s)" % [top, rng])


func test_slows_on_the_climb_gathers_downhill() -> void:
	var c: Dictionary = SC.climb(tuning).summary
	check(c.lowest_kmh < c.entry_kmh - 4.0, "full regulator falls from %.0f to %.1f km/h on 2.5 %%" % [c.entry_kmh, c.lowest_kmh])
	check(c.balance_on_climb_kmh < SC.top_speed(tuning) - 8.0, "it settles slower on the climb than the level")
	var d: Dictionary = SC.descent(tuning).summary
	check(d.foot_kmh > d.entry_kmh + 10.0, "coasting the descent it gathers from %.0f to %.1f km/h" % [d.entry_kmh, d.foot_kmh])


func test_brakes_hold_it_on_the_grade() -> void:
	var line := LINE.make(tuning)
	var sim := TrainSim.new(tuning, line)
	sim.brake_lever = 1.0
	sim.place(900.0)  # on the climb
	for i in 600:
		sim.step(1.0 / 60.0)
	check_eq(sim.v, 0.0, "full brake holds it standing on 2.5 %")
	sim.brake_lever = 0.0
	for i in 60 * 20:
		sim.step(1.0 / 60.0)
	check(sim.v < -0.5, "brakes off, it rolls back down the grade (%.2f m/s)" % sim.v)
	line.free()


func test_track_as_laid() -> void:
	var line := LINE.make(tuning)
	check_near(line.length, 1500.0, 1.5, "the line is 1.5 km along its curve")
	check_near(line.grade_at(900.0), 0.025, 0.0005, "2.5 % up in the climb's middle")
	check_near(line.grade_at(1200.0), -0.025, 0.0005, "2.5 % down in the descent's middle")
	check_near(line.grade_at(200.0), 0.0, 0.0001, "level on the first straight")
	check_near(line.curvature_at(520.0), 1.0 / 120.0, 0.0001, "the bend's middle is 120 m radius")
	check_near(line.curvature_at(415.0), 0.5 / 120.0, 0.0005, "halfway into the spiral, half the bend")
	var a := line.point_at(0.0)
	var b := line.point_at(line.length)
	check_near(b.y - a.y, 0.0, 0.05, "it ends as high as it starts (up 7.5 m and down again)")
	# The heading after the bend is a quarter turn.
	var t0 := line.transform_at(100.0).basis.z
	var t1 := line.transform_at(900.0).basis.z
	check_near(absf(Vector2(t0.x, t0.z).angle_to(Vector2(t1.x, t1.z))), PI * 0.5, 0.01, "the bend turns it 90 degrees")
	line.free()


func test_cars_stand_where_the_sim_says() -> void:
	var line := LINE.make(tuning)
	var sim := TrainSim.new(tuning, line)
	sim.place(430.0)
	sim.set_speed(25.0 / 3.6)
	var view := TrainView.new()
	view.with_solids = false
	view.setup(line, sim)
	var gap := []
	var walked := 0.0
	var last := Vector3.INF
	var s0 := sim.s
	for i in 60 * 20:  # 20 s through the bend
		sim.step(1.0 / 60.0)
		view.place()
		if i % 120 == 0:
			for c in sim.cars.size():
				var want := line.point_at(sim.truck_s(c, 0))
				check(view.trucks[c * 2].position.distance_to(want) < 0.001, "car %d's front truck on the line" % c)
		var p := view.trucks[0].position
		if last != Vector3.INF:
			walked += p.distance_to(last)
		last = p
		gap.append(view.trucks[0].position.distance_to(view.trucks[1].position))
	check_near(walked, sim.s - s0, (sim.s - s0) * 0.001, "the engine's truck walked as far as the 1D distance (%.2f of %.2f m)" % [walked, sim.s - s0])
	var lo: float = gap.min()
	var hi: float = gap.max()
	check(hi - lo < 0.01, "the engine's trucks keep their spacing through the bend (%.4f m)" % (hi - lo))
	view.free()
	line.free()



# --- Step 2 (#551) ----------------------------------------------------------------------------

func test_slack_runs_out_car_by_car_and_bunches() -> void:
	var a: Dictionary = SC.slack(tuning)
	var b: Dictionary = SC.slack(tuning)
	check_eq(a.events.size(), b.events.size(), "two runs, the same slack events")
	var same := true
	for i in mini(a.events.size(), b.events.size()):
		if a.events[i].t != b.events[i].t or a.events[i].coupler != b.events[i].coupler:
			same = false
	check(same, "two runs, the same slack events to the tick")
	var n := tuning.consist.size() - 1
	var first_out := {}
	var first_in := {}
	for e: Dictionary in a.events:
		var into: Dictionary = first_out if e.kind == "out" else first_in
		if e.phase == ("start" if e.kind == "out" else "stop") and not into.has(e.coupler):
			into[e.coupler] = e.t
	check_eq(first_out.size(), n, "on the start every coupler's slack runs out")
	var in_order := true
	for j in range(1, n):
		if float(first_out.get(j, INF)) <= float(first_out.get(j - 1, INF)):
			in_order = false
	check(in_order, "front to back, one after another: %s" % [first_out])
	check(float(first_out[n - 1]) - float(first_out[0]) > 1.0, "the coach starts well after the engine (%.2f s)" % (float(first_out[n - 1]) - float(first_out[0])))
	check_eq(first_in.size(), n, "on the stop every coupler bunches")


func test_engineer_stops_on_the_mark() -> void:
	for spec: Dictionary in [SC.TEN[0], SC.TEN[1], SC.TEN[3]]:
		var r: Dictionary = SC.stop_run(tuning, spec)
		check(absf(r.error) <= 1.0, "%s: stops %.2f m from the mark (within 1 m)" % [r.name, r.error])
	var again: Dictionary = SC.stop_run(tuning, SC.TEN[0])
	check_eq(again.error, SC.stop_run(tuning, SC.TEN[0]).error, "the same run stops at the same spot")


func test_timetable_from_data() -> void:
	var line := LINE.make(tuning)
	var tt := TrainTimetable.load_file(SC.TIMETABLE)
	tt.fill(line, tuning)
	check_eq(tt.stops.size(), 3, "three stops, by name")
	check_eq(tt.stops[1].mark, "mine", "the second is the mine")
	check_near(tt.stops[1].s, line.mark_s("mine"), 0.001, "where the route's mark is")
	check_eq(float(tt.stops[1].depart) - float(tt.stops[1].arrive), 180.0, "it stands 180 s at the mine, as the file says")
	check(float(tt.legs[0].allowed) > float(tt.legs[0].time), "the run allowed is the measured run and some (%.0f of %.0f s)" % [tt.legs[0].allowed, tt.legs[0].time])
	var given := TrainTimetable.from_dict({"start": 60, "stops": [{"mark": "depot"}, {"mark": "mine", "arrive": 500, "depart": 600}]})
	given.fill(line, tuning)
	check_eq(given.stops[1].arrive, 500.0, "a time given in the file is kept")
	check_eq(given.stops[0].depart, 60.0, "it leaves at the file's start")
	line.free()
	var r: Dictionary = SC.timetable_run(tuning, 0.0)
	check_eq(r.stops.size(), 2, "the engineer runs it to the mine and back")
	for st: Dictionary in r.stops:
		check(absf(st.error) <= 1.0, "%s: on the mark (%.2f m)" % [st.mark, st.error])
		check(absf(st.delay) <= 15.0, "%s: on time (%.1f s)" % [st.mark, st.delay])
	var late: Dictionary = SC.timetable_run(tuning, 180.0)
	check(late.stops[0].delay < 120.0, "3 minutes late, he's made up time by the mine (%.0f s late)" % late.stops[0].delay)
	check(absf(late.stops[1].delay) <= 15.0, "and is back on time at the depot (%.1f s)" % late.stops[1].delay)


func test_route_relaid() -> void:
	# A second, different route file: other bends, grades and length, and a water stop.
	var line := LINE.make(tuning, LINE.RELAID)
	check_near(line.length, 2100.0, 3.0, "the re-laid line is 2.1 km")
	check(line.marks.has("water") and line.marks.has("depot") and line.marks.has("mine"), "its marks by name")
	check(line.curvature_at(line.mark_s("depot") + 250.0) < 0.0, "it bends the other way (right-hand)")
	check_near(line.grade_at(750.0), 0.03, 0.0005, "3 % up in its climb")
	line.build()
	check(line.get_child_count() > 20, "its track builds (%d chunks and marks)" % line.get_child_count())
	line.free()
	var r: Dictionary = SC.timetable_run(tuning, 0.0, LINE.RELAID)
	check_eq(r.stops.size(), 2, "the same timetable runs it, to the mine and back")
	for st: Dictionary in r.stops:
		check(absf(st.error) <= 1.0, "%s: on the mark (%.2f m)" % [st.mark, st.error])
		check(absf(st.delay) <= 15.0, "%s: keeps the timetable (%.1f s)" % [st.mark, st.delay])
	check(float(r.legs[0].time) > 300.0, "its times come from the line (%.0f s to the mine, longer than the test line's)" % r.legs[0].time)
	for spec: Dictionary in [SC.TEN[6], SC.TEN[7]]:
		var s: Dictionary = SC.stop_run(tuning, spec)
		check(absf(s.error) <= 1.0, "%s: on the mark (%.2f m)" % [s.name, s.error])


func test_cars_are_solids_where_drawn() -> void:
	var line := LINE.make(tuning)
	var sim := TrainSim.new(tuning, line)
	sim.place(300.0)
	var view := TrainView.new()
	view.setup(line, sim)
	view.place()
	view.place_solids()
	check_eq(view.solids.size(), sim.cars.size(), "a solid a car")
	for i in sim.cars.size():
		var b := view.solids[i]
		check(b.collision_layer & Layers.WORLD != 0, "car %d on the world's layer (walked on, shot, shoves)" % i)
		check(b.get_child_count() >= 2, "car %d has its shapes" % i)
		check(b.transform.origin.distance_to(view.bodies[i].transform.origin) < 0.001, "car %d's solid where it's drawn" % i)
	view.free()
	line.free()
