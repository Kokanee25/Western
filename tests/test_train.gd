extends TestCase
## The train's 1D simulation and its track (src/train/, the train lab: issues #543, #551,
## docs/briefs/train.md): the same inputs give the same run; the start, the stop from 30 km/h and
## the top speed fall in their proposed ranges; it slows on a climb and gathers speed down one;
## the brakes hold it standing on the grade; the track's curve is the line's length and its
## grade and curvature are as laid; the cars stand on the line where the 1D distance says.
## Step 2: the couplers' slack runs out car by car and bunches on a stop, the same each time; the
## engineer stops on the mark; the timetable is read from data and its run times are the sim's;
## a second, different route file builds, runs, stops on every mark and keeps its timetable.

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
	check_eq(w1.stopped_at, w2.stopped_at, "two runs A to B stop at the same spot")
	# Step 1's simple scripted driver, not the engineer (he stops within 1 m: test_engineer_stops_on_the_mark).
	check_near(w1.short_of_mine, 0.0, 12.0, "step 1's simple driver brings the six cars to the mine within 12 m")


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
	check_eq(line.route_name, &"test_line", "laid from its route file")
	check_eq(line.mark(&"depot"), 120.0, "the depot's mark by name")
	check_eq(line.mark(&"mine"), 1440.0, "the mine's mark by name")
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
	sim.v = 25.0 / 3.6
	var view := TrainView.new()
	view.setup(line, sim)
	check(view.bodies[0] is AnimatableBody3D and view.bodies[0].get_child_count() > 3, "the cars are solids with shapes")
	var gap := []
	var walked := 0.0
	var last := Vector3.INF
	var s0 := sim.s
	for i in 60 * 20:  # 20 s through the bend
		sim.step(1.0 / 60.0)
		view.place_cars()
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


func test_slack_runs_out_car_by_car() -> void:
	var a: Dictionary = SC.slack_start(tuning).summary
	var b: Dictionary = SC.slack_start(tuning).summary
	check_eq(JSON.stringify(a.events), JSON.stringify(b.events), "the slack runs out the same way twice, to the bit")
	var starts: Array = a.starts
	for i in range(1, starts.size()):
		check(float(starts[i].moves_at) > float(starts[i - 1].moves_at),
			"%s starts after %s (%.2f s, %.2f s)" % [starts[i].car, starts[i - 1].car, starts[i].moves_at, starts[i - 1].moves_at])
	var outs := {}
	for e in a.events:
		if e.kind == "out":
			outs[int(e.coupler)] = true
	check_eq(outs.size(), tuning.consist.size() - 1, "every coupler runs out on the start (an event each)")


func test_slack_bunches_on_a_stop() -> void:
	var r: Dictionary = SC.slack_stop(tuning).summary
	var ins := {}
	for e in r.events:
		if e.kind == "in":
			ins[int(e.coupler)] = true
	check_eq(ins.size(), tuning.consist.size() - 1, "every coupler bunches as it brakes (an event each)")
	var rng := tuning.stop_from_30_range
	check(r.distance >= rng.x and r.distance <= rng.y, "the six cars stop from 30 km/h in %.1f m (proposed %s)" % [r.distance, rng])


func test_engineer_stops_on_the_mark() -> void:
	for run in [["depot", "mine", 25.0], ["mine", "depot", 32.0], ["depot", "climb_foot", tuning.max_kmh]]:
		var m := SC.make(tuning)
		var sim: TrainSim = m.sim
		var line: TrackLine = m.line
		sim.brake_lever = 1.0
		sim.place(line.mark(StringName(run[0])))
		var e := TrainEngineer.new(sim, line, tuning)
		var to := line.mark(StringName(run[1]))
		e.run_to(to, float(run[2]))
		while e.state == &"running" and sim.time < 900.0:
			e.tick(1.0 / 60.0)
			sim.step(1.0 / 60.0)
		check_eq(e.state, &"stopped", "%s to %s at %d km/h: he stops" % run)
		check_near(sim.s, to, 1.0, "%s to %s at %d km/h: on the mark within 1 m (%.2f off)" % [run[0], run[1], run[2], sim.s - to])
		line.free()


func test_timetable_from_data() -> void:
	var line := LINE.make(tuning)
	var data := LINE.timetable_data("test_line")
	var tt := Timetable.work_out(data, line, tuning)
	check(tt.problems.is_empty(), "the timetable works out (%s)" % ", ".join(tt.problems))
	check_eq(tt.stops.size(), 3, "three stops, by name")
	check_eq(tt.stops[1].at, &"mine", "the second stop is the mine")
	check_eq(tt.stops[1].s, line.mark(&"mine"), "found on the route by its name")
	check_eq(tt.stops[0].leave, Timetable.clock_of("08:00"), "it leaves the depot at 08:00")
	for i in tt.legs.size():
		var leg: Dictionary = tt.legs[i]
		check(float(leg.run) >= float(leg.ref), "leg %d's run time (%d s) covers the sim's run (%.1f s)" % [i, leg.run, leg.ref])
		check_eq(fmod(float(leg.run), tt.round_to), 0.0, "leg %d rounded to %d s" % [i, tt.round_to])
	check_eq(float(tt.stops[1].leave) - float(tt.stops[1].arrive), float(data.stops[1].dwell), "the mine's dwell from the data")
	var bad := data.duplicate(true)
	bad.stops[1].at = "nowhere"
	check(not Timetable.work_out(bad, line, tuning).problems.is_empty(), "a stop that isn't a mark is a problem")
	line.free()


func test_late_start_recovers() -> void:
	var r: Dictionary = SC.timetable(tuning, 180.0).summary
	check(r.done, "the late train runs the whole timetable")
	check(r.worst_off_m <= 1.0, "every stop on its mark within 1 m (worst %.2f)" % r.worst_off_m)
	check(float(r.arrivals[0].delay) < 180.0 - 30.0, "he makes up time on the run (%.0f s late at the mine, of 180)" % r.arrivals[0].delay)
	check(r.last_delay_s <= 0.0, "back on time by the last stop (%.1f s)" % r.last_delay_s)


func test_relaid_route() -> void:
	var route := LINE.route("relaid")
	check(TrackRoute.check(route).is_empty(), "the second route file is good")
	var line := LINE.make(tuning, "relaid")
	check_near(line.length, float(route.length), 2.0, "it's laid as long as its file says")
	check_near(line.curvature_at(360.0), -1.0 / 150.0, 0.0001, "its first curve bends right, 150 m radius")
	line.free()
	var r: Dictionary = SC.timetable(tuning, 0.0, "relaid").summary
	check(r.problems.is_empty(), "its timetable works out from the sim (%s)" % ", ".join(r.problems))
	check(r.done, "the train runs its whole timetable")
	check_eq(r.arrivals.size(), 4, "it calls at every stop (tank, mine, tank, depot)")
	for a in r.arrivals:
		check(absf(float(a.off)) <= 1.0, "%s: on the mark within 1 m (%.2f)" % [a.stop, a.off])
		check(float(a.delay) <= 0.0, "%s: on time (%.1f s)" % [a.stop, a.delay])
	var bad := route.duplicate(true)
	bad.marks.mine = 9999.0
	check(not TrackRoute.check(bad).is_empty(), "a mark off the line is caught")
