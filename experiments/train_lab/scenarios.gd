extends RefCounted
## The train lab's scenarios (issues #543, #551), run on the 1D train alone at 60 ticks a second:
## the same inputs give the same numbers to the bit (tests/test_train.gd holds them).
##
## Step 1's:
##   start    from a stand at the depot, regulator full: to 25 km/h (its time and distance), then on
##            to the top speed the straight allows
##   stop30   at 30 km/h on the level straight, regulator shut and full brake: the stopping distance
##   climb    into the 2.5 % climb at 38 km/h on full regulator: how far the speed falls
##   descent  over the crest at 15 km/h, regulator shut, no brake: how it gathers speed
##   run      the whole line depot to mine, as a simple driver would
## Step 2's:
##   slack_start  from a bunched stand, regulator full: when each car starts, the couplers running out
##   slack_stop   full brake from 30 km/h: the cars running in, the couplers bunching
##   marks        ten runs of the engineer to a mark, at speeds and loads and both ways: how far off
##   timetable    the engineer to the timetable, on time and with a late start: the delay against distance
##   relaid       the second route (routes/relaid.json) with its own timetable: built, run, kept
##
## Each returns {rows: [...], summary: {...}}; `rows` a dict a tick (Train.row()'s fields).
## `consist` [] is config/train.tres's (Sean's six); STEP1 is step 1's three box cars.

const DT := 1.0 / 60.0
const LINE := preload("res://experiments/train_lab/test_line.gd")
## Step 1's train: engine and tender and three loaded 30 ft box cars (106 t, 45.5 m).
const STEP1 := [
	{"name": &"engine", "kind": &"engine", "length": 9.4, "mass": 31000.0, "trucks": Vector2(1.4, 6.6), "width": 2.2, "height": 3.4},
	{"name": &"tender", "kind": &"tender", "length": 6.4, "mass": 24000.0, "trucks": Vector2(1.2, 5.2), "width": 2.1, "height": 2.3},
	{"name": &"car1", "kind": &"box", "length": 9.1, "mass": 17000.0, "trucks": Vector2(1.3, 7.8), "width": 2.3, "height": 3.1},
	{"name": &"car2", "kind": &"box", "length": 9.1, "mass": 17000.0, "trucks": Vector2(1.3, 7.8), "width": 2.3, "height": 3.1},
	{"name": &"car3", "kind": &"box", "length": 9.1, "mass": 17000.0, "trucks": Vector2(1.3, 7.8), "width": 2.3, "height": 3.1},
]


static func make(t: TrainTuning, consist: Array = [], which := LINE.ROUTE) -> Dictionary:
	var line := LINE.make(t, which)
	var sim := TrainSim.new(t, line, consist)
	return {"line": line, "sim": sim}


static func mark(line: TrackLine, name: StringName) -> float:
	return line.mark(name)


static func _row(sim: TrainSim, line: TrackLine) -> Dictionary:
	var r := {"t": sim.time, "s": sim.s, "v": sim.v, "throttle": sim.throttle, "regulator": sim.regulator,
		"steam": sim.steam, "brake_lever": sim.brake_lever, "brake": sim.brake, "f_tractive": sim.f_tractive,
		"f_resist": sim.f_resist, "f_grade": sim.f_grade, "f_brake": sim.f_brake,
		"grade": line.grade_at(sim.middle()) if line else 0.0, "limit": String(sim.limit)}
	for i in sim.cars.size():
		r["v%d" % i] = sim.u[i]
		r["x%d" % i] = sim.x[i]
	for j in sim.cars.size() - 1:
		r["gap%d" % j] = sim.gap(j)
	return r


## Run `drive(sim) -> bool` (false ends it) each tick, up to `max_t` seconds.
static func _run(sim: TrainSim, line: TrackLine, drive: Callable, max_t := 600.0) -> Array:
	var rows := [_row(sim, line)]
	while sim.time < max_t:
		if not drive.call(sim):
			break
		sim.step(DT)
		rows.append(_row(sim, line))
	return rows


## Bring it to `kmh` at `at` (a steady run-in, then held there) without recording.
static func _run_in(sim: TrainSim, kmh: float, at: float) -> void:
	# Place it far enough back, open up, then hold the speed until its front reaches `at`.
	sim.place(maxf(sim.length + 1.0, at - 420.0))
	while sim.s < at and sim.time < 900.0:
		sim.throttle = 1.0 if sim.v * 3.6 < kmh else 0.0
		sim.brake_lever = 0.0
		sim.step(DT)
		if sim.v * 3.6 > kmh:
			sim.v = kmh / 3.6  # the run-in is a set-up, not a measurement
	sim.v = kmh / 3.6
	sim.time = 0.0


static func start(t: TrainTuning, consist: Array = []) -> Dictionary:
	var m := make(t, consist)
	var sim: TrainSim = m.sim
	var a := mark(m.line, &"depot")
	sim.place(a)
	var hit := {}
	var end := mark(m.line, &"depot") + 275.0  # the straight's end, before the bend
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 1.0
		if not hit.has("t25") and x.v * 3.6 >= 25.0:
			hit.t25 = x.time
			hit.s25 = x.s - a
		if not hit.has("t10") and x.v * 3.6 >= 10.0:
			hit.t10 = x.time
		return x.s < end, 300.0)
	var top := 0.0
	for r in rows:
		top = maxf(top, r.v * 3.6)
	hit.top_on_straight_kmh = top
	hit.at_s = sim.s
	m.line.free()
	return {"rows": rows, "summary": hit}


## The level top speed: run long enough on the level that it settles (a straight as long as it takes).
static func top_speed(t: TrainTuning, consist: Array = []) -> float:
	var sim := TrainSim.new(t, null, consist)
	sim.place(0.0)
	sim.throttle = 1.0
	var last := -1.0
	for i in 60 * 900:
		sim.step(DT)
		if i > 0 and i % 600 == 0:
			if absf(sim.v - last) < 0.002:
				break
			last = sim.v
	return sim.v * 3.6


static func stop30(t: TrainTuning, consist: Array = []) -> Dictionary:
	var m := make(t, consist)
	var sim: TrainSim = m.sim
	_run_in(sim, 30.0, 330.0)
	var from := sim.s
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 0.0
		x.brake_lever = 1.0
		return _moving(x) or x.time < 0.05, 120.0)
	m.line.free()
	return {"rows": rows, "summary": {"distance": sim.s - from, "time": sim.time, "from_s": from}}


static func _moving(sim: TrainSim) -> bool:
	for i in sim.u.size():
		if sim.u[i] != 0.0:
			return true
	return false


static func climb(t: TrainTuning, consist: Array = []) -> Dictionary:
	# Full regulator into the climb at the speed it carries on the level straight before it: how
	# far the speed falls on 2.5 % (to where the effort meets the grade), and the regulator that
	# holds 25 km/h on the level (how little a level line asks of him).
	var entry := 38.0
	var m := make(t, consist)
	var sim: TrainSim = m.sim
	var foot := mark(m.line, &"climb_foot")
	var crest := mark(m.line, &"crest")
	_run_in(sim, entry, foot - 40.0)
	sim.regulator = 1.0
	sim.steam = 1.0
	var low := {"kmh": 99.0}
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 1.0
		x.brake_lever = 0.0
		low.kmh = minf(low.kmh, x.v * 3.6)
		return x.s < crest + 10.0 and x.v > 0.0, 400.0)
	m.line.free()
	return {"rows": rows, "summary": {"entry_kmh": entry, "lowest_kmh": low.kmh, "crest_kmh": sim.v * 3.6,
		"time": sim.time, "balance_on_climb_kmh": balance_speed(t, 0.025, consist),
		"regulator_for_25_level": cruise_regulator(t, 25.0, consist)}}


## The regulator that holds `kmh` on the level (by halving).
static func cruise_regulator(t: TrainTuning, kmh: float, consist: Array = []) -> float:
	var lo := 0.0
	var hi := 1.0
	for i in 30:
		var mid := (lo + hi) * 0.5
		var sim := TrainSim.new(t, null, consist)
		sim.steam = mid
		sim.regulator = mid
		var f := sim.effort(kmh / 3.6)
		var w := sim.mass * TrainSim.G
		var v := kmh / 3.6
		var r := w * (t.davis_a + t.davis_b * v) + t.davis_c * v * v
		if f > r:
			hi = mid
		else:
			lo = mid
	return (lo + hi) * 0.5


## The speed full regulator settles at on a steady grade (where effort meets resistance).
static func balance_speed(t: TrainTuning, grade: float, consist: Array = []) -> float:
	var sim := TrainSim.new(t, null, consist)
	sim.steam = 1.0
	var w := sim.mass * TrainSim.G
	var best := 0.0
	for i in 600:
		var v := i * 0.025
		var r := w * (t.davis_a + t.davis_b * v + grade) + t.davis_c * v * v
		if sim.effort(v) >= r:
			best = v
	return best * 3.6


static func descent(t: TrainTuning, consist: Array = []) -> Dictionary:
	var m := make(t, consist)
	var sim: TrainSim = m.sim
	var foot := mark(m.line, &"descent_foot")
	_run_in(sim, 15.0, mark(m.line, &"crest") + sim.length * 0.5)
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 0.0
		x.brake_lever = 0.0
		return x.s < foot + 20.0, 300.0)
	m.line.free()
	return {"rows": rows, "summary": {"entry_kmh": 15.0, "foot_kmh": sim.v * 3.6, "time": sim.time}}


## The whole line as a simple driver would (step 1's film run).
static func whole_run(t: TrainTuning, consist: Array = []) -> Dictionary:
	var m := make(t, consist)
	var sim: TrainSim = m.sim
	sim.place(mark(m.line, &"depot"))
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		_driver(x, m.line, 25.0)
		return not (not _moving(x) and x.time > 5.0 and x.brake_lever > 0.0), 900.0)
	var b := mark(m.line, &"mine")
	m.line.free()
	return {"rows": rows, "summary": {"stopped_at": sim.s, "short_of_mine": b - sim.s, "time": sim.time}}


## Step 1's simple driver: open up to `kmh`, hold it (a touch of brake downhill to keep it there),
## and brake for the mine by the stopping distance the brakes give on the grade he's on.
static func _driver(x: TrainSim, line: TrackLine, kmh: float) -> void:
	var b := line.mark(&"mine")
	var to_go := b - x.s
	var grade := line.grade_at(x.middle())
	var dec := (x.tuning.brake_g - grade - x.tuning.davis_a) * 9.81 / (1.0 + x.tuning.rotating_share)
	var need := x.v * x.v / (2.0 * maxf(dec, 0.05)) + x.v * x.tuning.brake_apply_time * 0.5 + 2.0
	if to_go <= need or (x.brake_lever >= 1.0 and to_go < 400.0):
		x.throttle = 0.0
		x.brake_lever = 1.0
		return
	var kph := x.v * 3.6
	if grade < -0.005:
		x.throttle = 0.0
		x.brake_lever = 0.6 if kph > kmh + 1.0 else (0.0 if kph < kmh - 2.0 else x.brake_lever)
		return
	x.throttle = 1.0 if kph < kmh - 1.0 else (0.35 if kph < kmh else 0.0)
	x.brake_lever = 0.0


# --- Step 2 -------------------------------------------------------------------------------------

## From a bunched stand at the depot, full regulator: when each car first moves (1 cm), and the
## couplers running out one after another.
static func slack_start(t: TrainTuning, consist: Array = []) -> Dictionary:
	var m := make(t, consist)
	var sim: TrainSim = m.sim
	sim.place(mark(m.line, &"depot"))
	var x0 := sim.x.duplicate()
	var moved := {}
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 1.0
		for i in x.cars.size():
			if not moved.has(i) and absf(x.x[i] - x0[i]) > 0.01:
				moved[i] = x.time
		return x.time < 20.0, 30.0)
	var starts := []
	for i in sim.cars.size():
		starts.append({"car": String(sim.cars[i].name), "moves_at": moved.get(i, -1.0)})
	m.line.free()
	return {"rows": rows, "summary": {"starts": starts, "events": _events(sim), "slack_per_coupler_m": t.coupler_slack}}


## Full brake from 30 km/h: the cars behind running in on the ones ahead.
static func slack_stop(t: TrainTuning, consist: Array = []) -> Dictionary:
	var m := make(t, consist)
	var sim: TrainSim = m.sim
	_run_in(sim, 30.0, 330.0)
	sim.events.clear()
	var from := sim.s
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 0.0
		x.brake_lever = 1.0
		return _moving(x) or x.time < 0.05, 120.0)
	var bunched := 0
	for j in sim.coupler_state.size():
		if sim.coupler_state[j] < 0:
			bunched += 1
	m.line.free()
	return {"rows": rows, "summary": {"distance": sim.s - from, "time": sim.time, "events": _events(sim),
		"bunched_at_rest": bunched, "couplers": sim.coupler_state.size()}}


static func _events(sim: TrainSim) -> Array:
	var out := []
	for e in sim.events:
		out.append({"t": snappedf(e.t, 0.001), "coupler": e.coupler, "kind": String(e.kind), "speed": snappedf(e.speed, 0.001),
			"between": "%s-%s" % e.between})
	return out


## Ten runs of the engineer to a mark: both ways, at speeds from 15 to the most he'll run, loaded
## and with the ore cars empty: where the engine's front stops against the mark.
static func marks(t: TrainTuning, consist: Array = []) -> Dictionary:
	var empty := []
	for c: Dictionary in (consist if not consist.is_empty() else t.consist):
		var e := c.duplicate()
		if e.get("kind") == &"ore":
			e.load = 0.0
		empty.append(e)
	var runs := [
		["depot", "mine", 25.0, "loaded"], ["depot", "mine", 15.0, "loaded"], ["depot", "mine", 32.0, "loaded"],
		["depot", "mine", t.max_kmh, "loaded"], ["depot", "mine", 25.0, "empty"], ["mine", "depot", 25.0, "loaded"],
		["mine", "depot", 18.0, "loaded"], ["mine", "depot", 32.0, "empty"], ["mine", "climb_foot", 25.0, "loaded"],
		["depot", "climb_foot", 30.0, "empty"],
	]
	var out := []
	var rows := []
	for r in runs:
		var m := make(t, empty if r[3] == "empty" else consist)
		var sim: TrainSim = m.sim
		sim.brake_lever = 1.0
		sim.place(mark(m.line, StringName(r[0])))
		var e := TrainEngineer.new(sim, m.line, t)
		var to := mark(m.line, StringName(r[1]))
		e.run_to(to, float(r[2]))
		var top := 0.0
		while e.state == &"running" and sim.time < 900.0:
			e.tick(DT)
			sim.step(DT)
			top = maxf(top, absf(sim.v) * 3.6)
			if out.is_empty():
				rows.append(_row(sim, m.line))
		out.append({"from": r[0], "to": r[1], "kmh": r[2], "load": r[3], "top_kmh": snappedf(top, 0.1),
			"off_m": snappedf((sim.s - to) * float(e.direction), 0.01), "time_s": snappedf(sim.time, 0.1),
			"stopped": e.state == &"stopped"})
		m.line.free()
	var worst := 0.0
	for o in out:
		worst = maxf(worst, absf(float(o.off_m)))
	return {"rows": rows, "summary": {"runs": out, "worst_off_m": worst}}


## The engineer to the route's timetable, leaving `late` s late: a row a second (the delay against
## the metres run), and each arrival.
static func timetable(t: TrainTuning, late := 0.0, route_name := "test_line", consist: Array = []) -> Dictionary:
	var line := LINE.make(t, route_name)
	var tt := Timetable.work_out(LINE.timetable_data(route_name), line, t, consist)
	var sim := TrainSim.new(t, line, consist)
	sim.brake_lever = 1.0
	sim.place(float(tt.stops[0].s))
	var e := TrainEngineer.new(sim, line, t)
	e.late_start = late
	e.follow(tt)
	while e.state != &"done" and sim.time < 4.0 * 3600.0:
		e.tick(DT)
		sim.step(DT)
	var worst := 0.0
	for a in e.arrivals:
		worst = maxf(worst, absf(float(a.off)))
	var last: Dictionary = e.arrivals[e.arrivals.size() - 1] if not e.arrivals.is_empty() else {}
	line.free()
	return {"rows": e.log, "summary": {"route": route_name, "late_start_s": late, "timetable": tt.summary(),
		"problems": Array(tt.problems), "arrivals": e.arrivals, "worst_off_m": worst,
		"last_delay_s": float(last.get("delay", INF)), "done": e.state == &"done"}}
