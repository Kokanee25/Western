extends TestCase
## The train's 1D simulation and its track (src/train/, the train lab: issue #543,
## docs/briefs/train.md): the same inputs give the same run; the start, the stop from 30 km/h and
## the top speed fall in their proposed ranges; it slows on a climb and gathers speed down one;
## the brakes hold it standing on the grade; the track's curve is the line's length and its
## grade and curvature are as laid; the cars stand on the line where the 1D distance says.

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
	check_near(w1.short_of_B, 0.0, 6.0, "the scripted driver brings it to B within 6 m")


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
	check_near(line.curvature_at(520.0), 1.0 / LINE.RADIUS, 0.0001, "the bend's middle is 120 m radius")
	check_near(line.curvature_at(415.0), 0.5 / LINE.RADIUS, 0.0005, "halfway into the spiral, half the bend")
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
	var gap := []
	var walked := 0.0
	var last := Vector3.INF
	var s0 := sim.s
	for i in 60 * 20:  # 20 s through the bend
		sim.step(1.0 / 60.0)
		view.place(sim.s)
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
