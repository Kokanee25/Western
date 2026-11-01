class_name TrainSim
extends RefCounted
## The train in one dimension (docs/briefs/train.md, steps 1 and 2): each car its own mass on the
## line, at `x[i]` (its front's distance along the track, m) and `vel[i]` (m/s, + toward the
## track's end), coupled to the next by a coupler with free play (`coupler_slack`) and a draft
## gear's spring-damper past it. The forces on each car:
##   - the engine's tractive effort (car 0 only), the least of: the steam's effort (falling with
##     speed, as the cylinders fill less each stroke), the boiler's power over speed, and the
##     drivers' adhesion;
##   - resistance in the Davis form (journals and flanges by the car's weight, air shared), the
##     curve's, and breaking away from a stand (each car its own, so they start one by one);
##   - gravity on the grade under the car;
##   - its brakes (weak against the mass, gripping harder as the wheels slow: cast iron shoes),
##     coming on car by car down the train (`brake_propagation`);
##   - the couplers either side, when their slack has run out.
## So on a start the slack runs out car by car (each coupler takes up its play before the car behind
## moves), and on braking it bunches. Each coupler's change from slack to taut (stretched or bunched)
## is an event in `events` (step 4's clanks).
##
## The engineer's hand is `throttle` (0..1) and `brake_lever` (0..1); the regulator follows the
## throttle at a rate, the steam the regulator with a lag. Fixed steps (`substeps` a tick), no
## dice: the same inputs give the same run to the bit.
##
## `s` and `v` are the engine's (its front, its speed): where the train is, for the cab, the
## timetable and the old step-1 callers. The track is anything with `grade_at(s)`,
## `curvature_at(s)` and `length` (TrackLine). Cars: `cars[i]` = {name, kind, length, mass, trucks
## (Vector2 from the car's front), front (its front behind the train's front at the couplers'
## middle, m)}.

const G := 9.81

var tuning: TrainTuning
var track: Object
var cars: Array[Dictionary] = []
var mass := 0.0
var length := 0.0  # front of the engine to back of the last car, couplers at the middle of their play

## State: each car's front along the line and its speed, and the same a tick ago (for drawing).
var x := PackedFloat64Array()
var vel := PackedFloat64Array()
var x_before := PackedFloat64Array()
var car_brake := PackedFloat32Array()  # each car's brakes as applied, 0..1
## The engine's (car 0's): where the train is and how fast.
var s := 0.0
var v := 0.0
var s_before := 0.0
var throttle := 0.0  # the engineer's hand on the regulator, 0..1
var brake_lever := 0.0  # the brake handle, 0..1
var reverser := 1  # +1 forward (toward the track's end), -1 back
var regulator := 0.0  # where the regulator actually is
var steam := 0.0  # the cylinders' share of full effort
var brake := 0.0  # the engine's brakes as applied (the cab's gauge), 0..1
var time := 0.0
var at_end := false  # run into the end of the line

## Each coupler (between car i and i+1): -1 bunched (pushing), 0 in its slack, +1 stretched (pulling).
var coupler_state := PackedInt32Array()
## The coupler's force now, N (+ pulling, - pushing), and its gap (m) beyond the nominal.
var coupler_force := PackedFloat32Array()
## Every slack-out and bunch: {t, coupler, kind ("out" stretched / "in" bunched), speed (closing
## m/s), bang (bool), s (where along the line)}. Cleared by whoever reads it (`take_events`).
var events: Array[Dictionary] = []
var event_count := 0

## The last tick's forces on the whole train (N), for the graphs.
var f_tractive := 0.0
var f_resist := 0.0
var f_grade := 0.0
var f_brake := 0.0
var limit := &"none"  # what capped the effort: adhesion, steam, power

var _lever_hist := PackedFloat32Array()  # the brake handle a tick, newest last (for propagation)
var _m_eff := PackedFloat64Array()
var _k := 0.0
var _c := PackedFloat64Array()


func _init(t: TrainTuning, on_track: Object = null) -> void:
	tuning = t
	track = on_track
	_make_consist()


func _make_consist() -> void:
	cars.clear()
	var front := 0.0
	var t := tuning
	var counts := {}
	for spec: Dictionary in t.consist:
		var kind := StringName(spec.kind)
		counts[kind] = int(counts.get(kind, 0)) + 1
		var nm := kind if kind in [&"engine", &"tender"] else StringName("%s%d" % [kind, counts[kind]])
		var tr: Variant = spec.trucks
		var trucks: Vector2 = tr if tr is Vector2 else Vector2(tr[0], tr[1])
		cars.append({"name": nm, "kind": kind, "length": float(spec.length), "mass": float(spec.mass),
			"trucks": trucks, "front": front})
		front += float(spec.length) + t.coupler_gap
	length = front - t.coupler_gap
	mass = 0.0
	var n := cars.size()
	x.resize(n)
	vel.resize(n)
	x_before.resize(n)
	car_brake.resize(n)
	_m_eff.resize(n)
	for i in n:
		mass += cars[i].mass
		_m_eff[i] = float(cars[i].mass) * (1.0 + t.rotating_share)
	coupler_state.resize(maxi(n - 1, 0))
	coupler_force.resize(maxi(n - 1, 0))
	_k = t.draft_stiffness
	_c.resize(maxi(n - 1, 0))
	for j in n - 1:
		# Critical damping for the two cars on this coupler (their reduced mass).
		var mr: float = _m_eff[j] * _m_eff[j + 1] / (_m_eff[j] + _m_eff[j + 1])
		_c[j] = t.draft_damping * 2.0 * sqrt(_k * mr)


## Put the train with its front at `at`, standing. `slack`: -1 every coupler bunched (as a train
## stands after it's stopped: the slack all in, so a start takes it up car by car), 0 at the middle
## of its play, +1 stretched.
func place(at: float, slack := -1.0) -> void:
	var half := tuning.coupler_slack * 0.5 * clampf(slack, -1.0, 1.0)
	for i in cars.size():
		x[i] = at - float(cars[i].front) - half * i
		vel[i] = 0.0
		x_before[i] = x[i]
		car_brake[i] = clampf(brake_lever, 0.0, 1.0)
	for j in coupler_state.size():
		coupler_state[j] = -1 if slack <= -1.0 else (1 if slack >= 1.0 else 0)
		coupler_force[j] = 0.0
	regulator = 0.0
	steam = 0.0
	at_end = false
	_lever_hist.clear()
	_sync()
	s_before = s


## Every car at this speed (m/s), the couplers left as they are.
func set_speed(speed: float) -> void:
	for i in cars.size():
		vel[i] = speed
	v = speed


func _sync() -> void:
	s = x[0]
	v = vel[0]
	brake = car_brake[0]


## Where along the track a car's front truck (0) or back truck (1) is; `frac` between a tick ago
## (0) and now (1), for drawing between ticks.
func truck_s(car: int, which: int, frac := 1.0) -> float:
	var c: Dictionary = cars[car]
	var tr: Vector2 = c.trucks
	return lerpf(x_before[car], x[car], frac) - (tr.x if which == 0 else tr.y)


## A car's front along the line (frac as truck_s).
func car_front(car: int, frac := 1.0) -> float:
	return lerpf(x_before[car], x[car], frac)


## Where the back of the train is (the last car's back), m.
func back_s() -> float:
	var n := cars.size() - 1
	return x[n] - float(cars[n].length)


func speed_kmh() -> float:
	return v * 3.6


## The effort the drivers can give at this speed with the steam as it is (N, >= 0).
func effort(speed: float) -> float:
	var t := tuning
	var sp := absf(speed)
	var by_steam := steam * t.tractive_effort * maxf(0.0, 1.0 - sp / t.effort_fade_speed)
	var by_power := steam * t.power / maxf(sp, 0.1)
	var by_grip := t.adhesion * t.adhesive_mass * G
	var f := minf(by_steam, minf(by_power, by_grip))
	if f <= 0.0:
		limit = &"none"
	elif f == by_grip:
		limit = &"adhesion"
	elif f == by_power:
		limit = &"power"
	else:
		limit = &"steam"
	return f


## One fixed step of `dt` seconds (the physics tick), in `substeps` steps for the couplers.
func step(dt: float) -> void:
	var t := tuning
	var n := cars.size()
	for i in n:
		x_before[i] = x[i]
	s_before = s
	time += dt
	# The engineer's hand -> the regulator -> the steam.
	regulator = move_toward(regulator, clampf(throttle, 0.0, 1.0), dt / maxf(t.regulator_open_time, 0.001))
	steam += (regulator - steam) * (1.0 - exp(-dt / maxf(t.steam_lag, 0.001)))
	# The brake handle -> each car's shoes, the rear ones later.
	_lever_hist.append(clampf(brake_lever, 0.0, 1.0))
	var keep := int(ceil(t.brake_propagation * (n - 1) / dt)) + 1
	if _lever_hist.size() > keep:
		_lever_hist = _lever_hist.slice(_lever_hist.size() - keep)
	for i in n:
		var back := int(round(t.brake_propagation * i / dt))
		var want: float = _lever_hist[maxi(0, _lever_hist.size() - 1 - back)]
		var rate := t.brake_apply_time if want > car_brake[i] else t.brake_release_time
		car_brake[i] = move_toward(car_brake[i], want, dt / maxf(rate, 0.001))
	# The grade and curve under each car, fixed over the tick (they change over metres, not mm).
	var grade := PackedFloat64Array()
	var curve := PackedFloat64Array()
	grade.resize(n)
	curve.resize(n)
	for i in n:
		if track:
			var mid: float = x[i] - float(cars[i].length) * 0.5
			grade[i] = track.grade_at(mid)
			curve[i] = absf(track.curvature_at(mid))
	var sub := maxi(1, t.substeps)
	var h := dt / sub
	var ft := 0.0
	var fr := 0.0
	var fg := 0.0
	var fb := 0.0
	var air := t.davis_c / n  # the air's drag shared along the train
	for k in sub:
		# Coupler forces from where the cars are now.
		var cf := PackedFloat64Array()
		cf.resize(n)
		for j in n - 1:
			var f := _coupler(j)
			cf[j] -= f  # pulling (+) holds the car ahead back
			cf[j + 1] += f  # and draws the car behind on
		for i in n:
			var w: float = float(cars[i].mass) * G
			var sp := absf(vel[i])
			var drive := cf[i] - w * grade[i]
			if i == 0:
				var tr := float(reverser) * effort(vel[0])
				drive += tr
				ft += tr
			var hold := w * (t.davis_a + t.davis_b * sp + t.curve_resistance * curve[i]) + air * vel[i] * vel[i]
			if sp < t.breakaway_speed:
				hold += w * t.breakaway * (1.0 - sp / t.breakaway_speed)
			var fbk := car_brake[i] * t.brake_g * w * (1.0 + t.brake_low_speed_gain * exp(-sp / t.brake_low_speed))
			fr += hold
			fb += fbk
			fg += -w * grade[i]
			hold += fbk
			var m: float = _m_eff[i]
			if vel[i] == 0.0:
				if absf(drive) > hold:
					vel[i] = signf(drive) * (absf(drive) - hold) / m * h
			else:
				var nv: float = vel[i] + (drive - signf(vel[i]) * hold) / m * h
				if signf(nv) != signf(vel[i]):  # it stopped within the step (it may start back next)
					nv = 0.0
				vel[i] = nv
			x[i] += vel[i] * h
		# The ends of the line: the train stops against them.
		if track:
			var over := 0.0
			if x[0] > track.length:
				over = track.length - x[0]
			elif back_s() < 0.0:
				over = -back_s()
			if over != 0.0:
				for i in n:
					x[i] += over
					vel[i] = 0.0
				at_end = true
	f_tractive = ft / sub
	f_resist = fr / sub
	f_grade = fg / sub
	f_brake = fb / sub
	_sync()


## The force in coupler j (between car j and j+1), N: + pulling, - pushing, 0 in its slack. Notes
## the moment it goes from slack to taut.
func _coupler(j: int) -> float:
	var t := tuning
	var gap: float = x[j] - float(cars[j].length) - x[j + 1]
	var lo := t.coupler_gap - t.coupler_slack * 0.5
	var hi := t.coupler_gap + t.coupler_slack * 0.5
	var rel: float = vel[j] - vel[j + 1]  # + the cars drawing apart
	var f := 0.0
	var state := 0
	if gap > hi:
		f = maxf(0.0, _k * (gap - hi) + _c[j] * rel)
		state = 1
	elif gap < lo:
		f = minf(0.0, -_k * (lo - gap) + _c[j] * rel)
		state = -1
	if state != 0 and state != coupler_state[j]:
		var speed := absf(rel)
		events.append({"t": time, "coupler": j, "kind": "out" if state > 0 else "in", "speed": speed,
			"bang": speed >= t.coupler_bang_speed, "s": x[j] - float(cars[j].length)})
		event_count += 1
	coupler_state[j] = state
	coupler_force[j] = f
	return f


## The events since the last call, and forget them.
func take_events() -> Array[Dictionary]:
	var out := events
	events = []
	return out


## The state as numbers (for the lab's log and later the save).
func to_dict() -> Dictionary:
	return {"s": s, "v": v, "throttle": throttle, "brake_lever": brake_lever, "reverser": reverser,
		"regulator": regulator, "steam": steam, "brake": brake, "time": time,
		"x": Array(x), "vel": Array(vel), "car_brake": Array(car_brake), "coupler_state": Array(coupler_state)}


func from_dict(d: Dictionary) -> void:
	for k in d:
		if k in ["x", "vel"]:
			var a := PackedFloat64Array(d[k])
			set(k, a)
		elif k == "car_brake":
			car_brake = PackedFloat32Array(d[k])
		elif k == "coupler_state":
			coupler_state = PackedInt32Array(d[k])
		else:
			set(k, d[k])
	x_before = x.duplicate()
	_sync()
	s_before = s
