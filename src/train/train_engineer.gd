class_name TrainEngineer
extends RefCounted
## The engineer (docs/briefs/train.md, step 2): drives the train by the same regulator, brake
## handle and reverser as the lab's cab (TrainSim's `throttle`, `brake_lever`, `reverser`), from
## stop to stop of a Timetable, and stops with the engine's front on each stop's mark.
##
## How he drives (every number a dial in config/train.tres, "The engineer"):
##   - He runs at a cruising speed: the schedule speed when he's on time, more (up to `max_kmh`)
##     when he's late, less (down to `min_kmh`) when he's early. Every `reckon_every` s he weighs
##     the time the timetable's own run (the schedule speed's) needs from here against the time he
##     has left to the next arrival.
##   - He brakes for the mark on a braking curve from the 1D stopping distance: the speed from which
##     a service stop (`service_decel`) ends `stop_aim` short of the mark, reckoned ahead by how long
##     the brakes take to set down the train. On the curve he works the brake handle to it.
##   - Stopped short of the mark he creeps up to it; within `stop_tolerance` he's on it.
##   - At a stop he waits for the leave time, or for `min_dwell` when he's late (the loading can't
##     be cut shorter), and then sets off: reverser toward the next stop, brakes off, regulator open.
## His hand on the levers: the regulator (or the brake) for the force the speed he wants needs on
## this grade, plus a little for how far off he is; the regulator's and brakes' own lags are the
## train's (TrainSim). Deterministic: no dice.
##
## Without a timetable (`run_to`), he runs to one mark at the speed he's given: how the timetable's
## run times are measured (Timetable.work_out).

var sim: TrainSim
var line: Object
var tuning: TrainTuning
var timetable: Timetable

## The time of day, s (his watch).
var clock := 0.0
## How late he leaves the first stop, s (a late start).
var late_start := 0.0
## &"waiting" at a stop, &"running" to the next, &"stopped" on a mark with no timetable (run_to),
## &"done" at the timetable's last stop.
var state := &"waiting"
## The stop he's at or running to (the timetable's index).
var stop_i := 0
var target_s := 0.0
var direction := 1
var cruise_kmh := 25.0
## Metres run in all (the delay graph's x).
var run_m := 0.0
## Where this leg began, and the metres run on it.
var leg_from := 0.0
var leg_m := 0.0
## When he got to the stop he's at (clock), and when he'll leave it.
var arrived_at := 0.0
var leave_at := 0.0

## What happened: a row a second running ({clock, run_m, s, kmh, cruise, delay, state}) and a row
## each arrival ({stop, mark, at, off, arrive, due, delay, leave, leave_due}).
var log: Array[Dictionary] = []
var arrivals: Array[Dictionary] = []

var _since_log := 0.0
var _since_reckon := 0.0
var _last_s := 0.0
var _still := 0.0  # seconds every car has been standing


func _init(train_sim: TrainSim, on_line: Object, t: TrainTuning) -> void:
	sim = train_sim
	line = on_line
	tuning = t
	cruise_kmh = t.schedule_kmh
	_last_s = sim.s


## Drive to a timetable, the train standing at its first stop; the clock set to `start_clock` (s of
## day, default a minute before the first leave).
func follow(tt: Timetable, start_clock := NAN) -> void:
	timetable = tt
	stop_i = 0
	state = &"waiting"
	clock = start_clock if not is_nan(start_clock) else float(tt.stops[0].leave) - 60.0
	arrived_at = clock
	leave_at = float(tt.stops[0].leave) + late_start
	target_s = float(tt.stops[0].s)
	sim.brake_lever = 1.0
	sim.throttle = 0.0
	run_m = 0.0
	log.clear()
	arrivals.clear()


## Run to `to_s` at `kmh` with no timetable (measuring a run).
func run_to(to_s: float, kmh: float) -> void:
	timetable = null
	cruise_kmh = kmh
	_set_off(to_s)


func _set_off(to_s: float) -> void:
	target_s = to_s
	direction = 1 if to_s >= sim.s else -1
	sim.reverser = direction
	sim.brake_lever = 0.0
	leg_from = sim.s
	leg_m = 0.0
	_still = 0.0
	_since_reckon = INF
	state = &"running"


## One tick of `dt`, before the train's own step.
func tick(dt: float) -> void:
	clock += dt
	var moved := absf(sim.s - _last_s)
	_last_s = sim.s
	run_m += moved
	leg_m += moved
	match state:
		&"waiting":
			sim.throttle = 0.0
			sim.brake_lever = 1.0
			if timetable and clock >= leave_at:
				if stop_i + 1 >= timetable.stops.size():
					state = &"done"
				else:
					stop_i += 1
					_set_off(float(timetable.stops[stop_i].s))
					if timetable:
						_reckon()
		&"running":
			_since_reckon += dt
			if timetable and _since_reckon >= tuning.reckon_every:
				_reckon()
			_drive(dt)
		_:
			sim.throttle = 0.0
			sim.brake_lever = 1.0
	_since_log += dt
	if _since_log >= 1.0:
		_since_log = 0.0
		log.append({"clock": clock, "run_m": run_m, "s": sim.s, "kmh": sim.v * 3.6, "cruise": cruise_kmh,
			"delay": delay(), "state": String(state), "throttle": sim.throttle, "brake": sim.brake_lever})


## How far the engine's front has to go to the mark, along the way he's going (m; < 0 past it).
func to_go() -> float:
	return (target_s - sim.s) * float(direction)


## How late he is (s; < 0 early): against the timetable's own run at this point of the leg, or,
## standing at a stop, against its leave time (or its arrival, not yet there).
func delay() -> float:
	if timetable == null:
		return 0.0
	var st: Dictionary = timetable.stops[stop_i]
	if state == &"waiting" or state == &"done":
		return maxf(clock, leave_at) - float(st.leave)
	return clock - timetable.due_at(stop_i, leg_m)


## Weigh the time left against the timetable's run from here: the speed to cruise at.
func _reckon() -> void:
	_since_reckon = 0.0
	var due: float = timetable.stops[stop_i].arrive
	var left := due - clock
	var need := timetable.run_left(stop_i, leg_m)
	var t := tuning
	if left <= 1.0:
		cruise_kmh = t.max_kmh
	else:
		cruise_kmh = clampf(t.schedule_kmh * need / left, t.min_kmh, t.max_kmh)


## The levers for this tick: the speed he wants (cruising, or on the braking curve), and the force
## that needs on this grade.
func _drive(_dt: float) -> void:
	var t := tuning
	var d := to_go()
	var v_along := sim.v * float(direction)
	var n := sim.cars.size()
	# The brakes take time to set down the train: reckon the curve that far ahead (less as they're on).
	var lead := (t.brake_apply_time * 0.5 + t.brake_propagation * float(n) * 0.5) * (1.0 - sim.brake)
	var room := d - t.stop_aim - maxf(v_along, 0.0) * lead
	var on_curve := sqrt(2.0 * t.service_decel * maxf(room, 0.0))
	var want := minf(cruise_kmh / 3.6, on_curve)
	var braking_curve := on_curve < cruise_kmh / 3.6
	if d > t.stop_tolerance and want < t.creep_kmh / 3.6:
		want = t.creep_kmh / 3.6  # short of it: creep up
	if d <= t.stop_tolerance or d < 0.0:
		want = 0.0
	var all_still := true
	for i in n:
		if sim.u[i] != 0.0:
			all_still = false
			break
	_still = _still + _dt if all_still else 0.0
	if want == 0.0:
		sim.throttle = 0.0
		sim.brake_lever = 1.0
		if all_still and _still > 0.5:
			_arrive()
		return
	# The force along the way he's going that the speed he wants needs: resistance, the grade, and
	# the change of speed (down the braking curve, its deceleration).
	var err := want - v_along
	var accel := clampf(err * 0.5, -t.service_decel * 1.5, 0.25)
	if braking_curve and want < v_along + 0.5:
		accel = -t.service_decel + err * 0.6
	var w := sim.mass * TrainSim.G
	var sp := absf(sim.v)
	var grade := 0.0
	for i in n:
		grade += float(sim.cars[i].mass) * line.grade_at(sim.x[i] - float(sim.cars[i].length) * 0.5)
	grade /= sim.mass
	var resist := w * (t.davis_a + t.davis_b * sp) + t.davis_c * sp * sp
	if sp < t.breakaway_speed:
		resist += w * t.breakaway
	var need := sim.mass * (1.0 + t.rotating_share) * accel + resist + w * grade * float(direction)
	if need > 0.0:
		var full := minf(t.tractive_effort * maxf(0.0, 1.0 - sp / t.effort_fade_speed), minf(t.power / maxf(sp, 0.1), t.adhesion * t.adhesive_mass * TrainSim.G))
		sim.throttle = clampf(need / maxf(full, 1.0) + t.throttle_gain * err * 3.6, 0.0, 1.0)
		# Off the brakes as the regulator takes it (holding them on against the steam wastes it).
		sim.brake_lever = 0.0
	else:
		var full_b := t.brake_g * w * (1.0 + t.brake_low_speed_gain * exp(-sp / t.brake_low_speed))
		sim.throttle = 0.0
		sim.brake_lever = clampf(-need / full_b - t.brake_gain * err, 0.0, 1.0)


## Standing on (or as near as he got to) the mark.
func _arrive() -> void:
	sim.throttle = 0.0
	sim.brake_lever = 1.0
	if timetable == null:
		state = &"stopped"
		return
	var st: Dictionary = timetable.stops[stop_i]
	arrived_at = clock
	var min_dwell := float(st.min_dwell)
	leave_at = maxf(float(st.leave), clock + min_dwell)
	arrivals.append({"stop": String(st.at), "mark": float(st.s), "at": sim.s, "off": (sim.s - float(st.s)) * float(direction),
		"arrive": clock, "due": float(st.arrive), "delay": clock - float(st.arrive), "leave": leave_at,
		"leave_due": float(st.leave), "run_m": run_m})
	state = &"waiting" if stop_i + 1 < timetable.stops.size() else &"done"
