extends RefCounted
## The train lab's scenarios (issues #543, #551), run on the 1D train alone at 60 ticks a second:
## the same inputs give the same numbers to the bit (tests/test_train.gd holds them). The places are
## the route's named marks (routes/test_line.json): depot, mine, climb_foot, crest, descent_foot.
##
##   start    from a stand at the depot, regulator full: to 25 km/h (its time and distance), then on
##            to the top speed the straight allows
##   stop30   at 30 km/h on the level straight, regulator shut and full brake: the stopping distance
##   climb    into the 2.5 % climb at 25 km/h on full regulator: how far the speed falls
##   descent  over the crest at 15 km/h, regulator shut, no brake: how it gathers speed
##   run      the whole line depot to mine, as a driver would: full regulator to 25, hold it
##            near 25, coast the descent, brake for the mine (step 1's simple driver; the
##            engineer, TrainEngineer, is step 2's and stops on the mark)
##
## Each returns {rows: [...], summary: {...}}. `rows` a dict a tick (Train.row()'s fields).

const DT := 1.0 / 60.0
const LINE := preload("res://experiments/train_lab/test_line.gd")


static func make(t: TrainTuning, file := LINE.ROUTE) -> Dictionary:
	var line := LINE.make(t, file)
	var sim := TrainSim.new(t, line)
	return {"line": line, "sim": sim}


static func _row(sim: TrainSim, line: TrackLine) -> Dictionary:
	return {"t": sim.time, "s": sim.s, "v": sim.v, "throttle": sim.throttle, "regulator": sim.regulator,
		"steam": sim.steam, "brake_lever": sim.brake_lever, "brake": sim.brake, "f_tractive": sim.f_tractive,
		"f_resist": sim.f_resist, "f_grade": sim.f_grade, "f_brake": sim.f_brake,
		"grade": line.grade_at(sim.s - sim.length * 0.5), "limit": String(sim.limit)}


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
	sim.place(maxf(sim.length + 1.0, at - 420.0), 0.0)
	while sim.s < at and sim.time < 900.0:
		sim.throttle = 1.0 if sim.v * 3.6 < kmh else 0.0
		sim.brake_lever = 0.0
		sim.step(DT)
		if sim.v * 3.6 > kmh:
			sim.set_speed(kmh / 3.6)  # the run-in is a set-up, not a measurement
	sim.set_speed(kmh / 3.6)
	sim.time = 0.0
	sim.take_events()


static func start(t: TrainTuning) -> Dictionary:
	var m := make(t)
	var sim: TrainSim = m.sim
	var depot: float = m.line.mark_s("depot")
	sim.place(depot)
	var hit := {}
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 1.0
		if not hit.has("t25") and x.v * 3.6 >= 25.0:
			hit.t25 = x.time
			hit.s25 = x.s - depot
		if not hit.has("t10") and x.v * 3.6 >= 10.0:
			hit.t10 = x.time
		return x.s < 395.0, 300.0)
	hit.slack_out = _slack_order(sim.take_events(), "out")
	var top := 0.0
	for r in rows:
		top = maxf(top, r.v * 3.6)
	hit.top_on_straight_kmh = top
	hit.at_s = sim.s
	return {"rows": rows, "summary": hit}


## The level top speed: run long enough on the level that it settles (a straight as long as it takes).
static func top_speed(t: TrainTuning) -> float:
	var sim := TrainSim.new(t, null)
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


static func stop30(t: TrainTuning) -> Dictionary:
	var m := make(t)
	var sim: TrainSim = m.sim
	_run_in(sim, 30.0, 330.0)
	var from := sim.s
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 0.0
		x.brake_lever = 1.0
		return x.v > 0.0 or x.time < 0.05, 120.0)
	var ev := sim.take_events()
	return {"rows": rows, "summary": {"distance": sim.s - from, "time": sim.time, "from_s": from,
		"bunched": _slack_order(ev, "in")}}


## The couplers in the order their slack ran out ("out") or bunched ("in"): [{coupler, t, speed}].
static func _slack_order(ev: Array, kind: String) -> Array:
	var seen := {}
	var out := []
	for e: Dictionary in ev:
		if e.kind == kind and not seen.has(e.coupler):
			seen[e.coupler] = true
			out.append({"coupler": e.coupler, "t": snappedf(e.t, 0.001), "speed": snappedf(e.speed, 0.001), "bang": e.bang})
	return out


static func climb(t: TrainTuning) -> Dictionary:
	# Full regulator into the climb at the speed it carries on the level straight before it: how
	# far the speed falls on 2.5 % (to where the effort meets the grade), and the regulator that
	# holds 25 km/h on the level (how little a level line asks of him).
	var entry := 38.0
	var m := make(t)
	var sim: TrainSim = m.sim
	_run_in(sim, entry, m.line.mark_s("climb_foot") - 40.0)
	sim.regulator = 1.0
	sim.steam = 1.0
	var low := {"kmh": 99.0}
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 1.0
		x.brake_lever = 0.0
		low.kmh = minf(low.kmh, x.v * 3.6)
		return x.s < m.line.mark_s("crest") + 10.0 and x.v > 0.0, 400.0)
	return {"rows": rows, "summary": {"entry_kmh": entry, "lowest_kmh": low.kmh, "crest_kmh": sim.v * 3.6,
		"time": sim.time, "balance_on_climb_kmh": balance_speed(t, 0.025),
		"regulator_for_25_level": cruise_regulator(t, 25.0)}}


## The regulator that holds `kmh` on the level (by halving).
static func cruise_regulator(t: TrainTuning, kmh: float) -> float:
	var lo := 0.0
	var hi := 1.0
	for i in 30:
		var mid := (lo + hi) * 0.5
		var sim := TrainSim.new(t, null)
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
static func balance_speed(t: TrainTuning, grade: float) -> float:
	var sim := TrainSim.new(t, null)
	sim.steam = 1.0
	var w := sim.mass * TrainSim.G
	var best := 0.0
	for i in 600:
		var v := i * 0.025
		var r := w * (t.davis_a + t.davis_b * v + grade) + t.davis_c * v * v
		if sim.effort(v) >= r:
			best = v
	return best * 3.6


static func descent(t: TrainTuning) -> Dictionary:
	var m := make(t)
	var sim: TrainSim = m.sim
	_run_in(sim, 15.0, m.line.mark_s("crest") + sim.length * 0.5)
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		x.throttle = 0.0
		x.brake_lever = 0.0
		return x.s < m.line.mark_s("descent_foot") + 20.0, 300.0)
	return {"rows": rows, "summary": {"entry_kmh": 15.0, "foot_kmh": sim.v * 3.6, "time": sim.time}}


## The whole line as a driver would: the film's run.
static func whole_run(t: TrainTuning) -> Dictionary:
	var m := make(t)
	var sim: TrainSim = m.sim
	var rows := _run(sim, m.line, func(x: TrainSim) -> bool:
		_driver(x, m.line, 25.0)
		return not (x.v == 0.0 and x.time > 5.0 and x.brake_lever > 0.0), 900.0)
	return {"rows": rows, "summary": {"stopped_at": sim.s, "short_of_B": m.line.mark_s("mine") - sim.s, "time": sim.time}}


## A simple driver: open up to `kmh`, hold it (a touch of brake downhill to keep it there),
## and brake for the mine by the stopping distance the brakes give on the grade he's on (so he
## stops near it, not on it to the metre: that's step 2's engineer).
static func _driver(x: TrainSim, line: TrackLine, kmh: float) -> void:
	var b := line.mark_s("mine")
	var to_go := b - x.s
	var grade := line.grade_at(x.s - x.length * 0.5)
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


# --- Step 2 (#551): the engineer, the timetable, the slack --------------------------------------

const TIMETABLE := "res://experiments/train_lab/timetable.json"

## Ten runs, each stopping on a named mark (the proof: within 1 m): both lines, both ways, slow
## and fast, a light train, weak brakes, a late start on the timetable.
const TEN := [
	{"name": "depot to mine, 22 km/h", "route": "test_line", "from": "depot", "to": "mine", "kmh": 22.0},
	{"name": "mine to depot (tender first), 22 km/h", "route": "test_line", "from": "mine", "to": "depot", "kmh": 22.0},
	{"name": "depot to mine, 15 km/h", "route": "test_line", "from": "depot", "to": "mine", "kmh": 15.0},
	{"name": "depot to mine, 32 km/h", "route": "test_line", "from": "depot", "to": "mine", "kmh": 32.0},
	{"name": "depot to mine, ore cars empty", "route": "test_line", "from": "depot", "to": "mine", "kmh": 25.0, "empty": true},
	{"name": "depot to mine, worn shoes (brakes 0.035 g)", "route": "test_line", "from": "depot", "to": "mine", "kmh": 25.0, "brake_g": 0.035},
	{"name": "re-laid: depot to water, 22 km/h", "route": "relaid", "from": "depot", "to": "water", "kmh": 22.0},
	{"name": "re-laid: water to mine, 28 km/h", "route": "relaid", "from": "water", "to": "mine", "kmh": 28.0},
	{"name": "re-laid: mine to depot (tender first), 25 km/h", "route": "relaid", "from": "mine", "to": "depot", "kmh": 25.0},
	{"name": "timetable, 3 minutes late: depot to mine", "route": "test_line", "from": "depot", "to": "mine", "timetable": 180.0},
]


static func route_file(r: String) -> String:
	return LINE.ROUTE if r == "test_line" else LINE.RELAID


## One of the ten: {name, error (m past the mark, + overshot), time, kmh, ...}.
static func stop_run(t: TrainTuning, spec: Dictionary) -> Dictionary:
	var tt := t
	if spec.has("empty") or spec.has("brake_g"):
		tt = t.duplicate(true)
		if spec.has("brake_g"):
			tt.brake_g = float(spec.brake_g)
		if spec.get("empty", false):
			var cs: Array = tt.consist.duplicate(true)
			for c: Dictionary in cs:
				if c.kind == "ore":
					c.mass = 4500.0
			tt.consist = cs
	var line := LINE.make(tt, route_file(spec.route))
	var sim := TrainSim.new(tt, line)
	var a := line.mark_s(spec.from)
	var b := line.mark_s(spec.to)
	sim.place(a)
	var eng := TrainEngineer.new(sim, line)
	var top := 0.0
	if spec.has("timetable"):
		var timetable := TrainTimetable.load_file(TIMETABLE)
		timetable.fill(line, tt)
		eng.run(timetable, float(spec.timetable))
	else:
		eng.go_to(b, float(spec.kmh))
	while sim.time < 2400.0:
		eng.drive(DT)
		sim.step(DT)
		top = maxf(top, absf(sim.v) * 3.6)
		if eng.stop_log.size() > 0:
			break
	var rec: Dictionary = eng.stop_log[0] if eng.stop_log.size() > 0 else {"error": NAN, "t": sim.time}
	line.free()
	return {"name": spec.name, "mark": spec.to, "error": snappedf(float(rec.error), 0.001), "time": snappedf(float(rec.t), 0.1),
		"top_kmh": snappedf(top, 0.1), "delay": snappedf(float(rec.get("delay", 0.0)), 0.1), "slack_events": sim.event_count}


static func ten_stops(t: TrainTuning) -> Array:
	var out := []
	for spec: Dictionary in TEN:
		out.append(stop_run(t, spec))
	return out


## The timetable run round (depot, mine, depot), `late` s late: the engineer's rows (delay against
## distance run) and his stops.
static func timetable_run(t: TrainTuning, late: float, file := LINE.ROUTE) -> Dictionary:
	var line := LINE.make(t, file)
	var timetable := TrainTimetable.load_file(TIMETABLE)
	timetable.fill(line, t)
	var sim := TrainSim.new(t, line)
	sim.place(line.mark_s("depot"))
	var eng := TrainEngineer.new(sim, line)
	eng.run(timetable, late)
	while eng.state != TrainEngineer.DONE and sim.time < 3600.0:
		eng.drive(DT)
		sim.step(DT)
	var r := {"rows": eng.rows, "stops": eng.stop_log, "timetable": timetable.describe(),
		"legs": timetable.legs.map(func(l: Dictionary) -> Dictionary: return {"time": l.time, "allowed": l.allowed}),
		"finished": sim.time}
	line.free()
	return r


## The slack on a start and on a stop, car by car: each car's speed a tick (v0..vN) and the couplers'
## forces, from a stand at the depot to 20 km/h, the regulator shut (the steam let die), then full
## brake to a stand.
static func slack(t: TrainTuning) -> Dictionary:
	var m := make(t)
	var sim: TrainSim = m.sim
	sim.place(m.line.mark_s("depot"))
	var rows := []
	var phase := "start"
	var events := []
	while sim.time < 120.0:
		if phase == "start":
			sim.throttle = 1.0
			sim.brake_lever = 0.0
			if sim.v * 3.6 >= 20.0:
				phase = "shut"
		elif phase == "shut":  # he shuts off first, and lets the steam die, then brakes
			sim.throttle = 0.0
			if sim.steam < 0.02:
				phase = "stop"
		else:
			sim.throttle = 0.0
			sim.brake_lever = 1.0
			if sim.v == 0.0:
				break
		sim.step(DT)
		var r := {"t": sim.time, "phase": phase}
		for i in sim.cars.size():
			r["v%d" % i] = sim.vel[i]
			r["x%d" % i] = sim.x[i] - float(sim.cars[i].front)
		for j in sim.coupler_force.size():
			r["c%d" % j] = sim.coupler_force[j]
		rows.append(r)
		for e in sim.take_events():
			e.phase = phase
			events.append(e)
	m.line.free()
	return {"rows": rows, "events": events}
