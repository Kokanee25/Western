class_name TrainSim
extends RefCounted
## The train in one dimension (docs/briefs/train.md, step 1): how far along the track its front is
## (`s`, metres) and how fast (`v`, m/s, + toward the track's end), from the forces on it:
##   - tractive effort, the least of: the steam's effort (falling with speed, as the cylinders fill
##     less each stroke), the boiler's power over speed, and the drivers' adhesion;
##   - resistance in the Davis form (journals, flanges, air), the curves', and breaking away from a stand;
##   - gravity on the grade under each car (the train's weight where it is, not at its front);
##   - brakes, weak against the mass, gripping harder as the wheels slow (cast iron shoes).
## The engineer's hand is `throttle` (0..1) and `brake_lever` (0..1); the regulator follows the
## throttle at a rate, the steam follows the regulator with a lag, the brakes set and release over
## seconds. Deterministic: no dice, the same inputs give the same run to the bit.
##
## The track is anything with `grade_at(s)` and `curvature_at(s)` and `length` (TrackLine).
## Cars: `cars[i]` = {name, length, mass, trucks (Vector2: from the car's front), front (the car's
## front behind the train's front, m)}. A car's truck at `s - front - trucks.x`.

const G := 9.81

var tuning: TrainTuning
var track: Object
var cars: Array[Dictionary] = []
var mass := 0.0
var length := 0.0

## State.
var s := 0.0
var v := 0.0
var s_before := 0.0  # s a tick ago (for drawing between ticks)
var throttle := 0.0  # the engineer's hand on the regulator, 0..1
var brake_lever := 0.0  # the brake handle, 0..1
var reverser := 1  # +1 forward (toward the track's end), -1 back
var regulator := 0.0  # where the regulator actually is
var steam := 0.0  # the cylinders' share of full effort
var brake := 0.0  # the brakes as applied, 0..1
var time := 0.0
var at_end := false  # run into the end of the line

## The last tick's forces (N), for the graphs.
var f_tractive := 0.0
var f_resist := 0.0
var f_grade := 0.0
var f_brake := 0.0
var limit := &"none"  # what capped the effort: adhesion, steam, power


func _init(t: TrainTuning, on_track: Object = null) -> void:
	tuning = t
	track = on_track
	_make_consist()


func _make_consist() -> void:
	cars.clear()
	var front := 0.0
	var t := tuning
	_add(&"engine", t.engine_length, t.engine_mass, t.engine_trucks, front)
	front += t.engine_length + t.coupler_gap
	_add(&"tender", t.tender_length, t.tender_mass, t.tender_trucks, front)
	front += t.tender_length + t.coupler_gap
	for i in t.car_count:
		_add(StringName("car%d" % (i + 1)), t.car_length, t.car_mass, t.car_trucks, front)
		front += t.car_length + t.coupler_gap
	length = front - t.coupler_gap
	mass = 0.0
	for c in cars:
		mass += c.mass


func _add(car_name: StringName, l: float, m: float, trucks: Vector2, front: float) -> void:
	cars.append({"name": car_name, "length": l, "mass": m, "trucks": trucks, "front": front})


## Put the train with its front at `at`, standing.
func place(at: float) -> void:
	s = at
	s_before = at
	v = 0.0
	regulator = 0.0
	steam = 0.0
	brake = brake_lever
	at_end = false


## Where along the track a car's front truck (0) or back truck (1) is.
func truck_s(car: int, which: int, at := INF) -> float:
	var c: Dictionary = cars[car]
	var tr: Vector2 = c.trucks
	return (s if at == INF else at) - c.front - (tr.x if which == 0 else tr.y)


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


## One fixed step of `dt` seconds.
func step(dt: float) -> void:
	var t := tuning
	s_before = s
	time += dt
	# The engineer's hand -> the regulator -> the steam; the brake handle -> the shoes.
	regulator = move_toward(regulator, clampf(throttle, 0.0, 1.0), dt / maxf(t.regulator_open_time, 0.001))
	steam += (regulator - steam) * (1.0 - exp(-dt / maxf(t.steam_lag, 0.001)))
	var want := clampf(brake_lever, 0.0, 1.0)
	var rate := t.brake_apply_time if want > brake else t.brake_release_time
	brake = move_toward(brake, want, dt / maxf(rate, 0.001))
	# Grade and curves under each car, by its weight (+ uphill toward the track's end).
	var grade := 0.0
	var curve := 0.0
	if track:
		for c in cars:
			var mid: float = s - c.front - c.length * 0.5
			grade += c.mass * track.grade_at(mid)
			curve += c.mass * absf(track.curvature_at(mid))
		grade /= mass
		curve /= mass
	var weight := mass * G
	var sp := absf(v)
	f_tractive = float(reverser) * effort(v)
	f_grade = -weight * grade
	f_resist = weight * (t.davis_a + t.davis_b * sp + t.curve_resistance * curve) + t.davis_c * v * v
	if sp < t.breakaway_speed:
		f_resist += weight * t.breakaway * (1.0 - sp / t.breakaway_speed)
	f_brake = brake * t.brake_g * weight * (1.0 + t.brake_low_speed_gain * exp(-sp / t.brake_low_speed))
	var m_eff := mass * (1.0 + t.rotating_share)
	var drive := f_tractive + f_grade  # pushes one way or the other whatever the motion
	var hold := f_resist + f_brake  # only ever opposes the motion
	if v == 0.0:
		if absf(drive) > hold:
			v = signf(drive) * (absf(drive) - hold) / m_eff * dt
	else:
		var nv := v + (drive - signf(v) * hold) / m_eff * dt
		if signf(nv) != signf(v):  # it stopped within the step (it may start back next step)
			nv = 0.0
		v = nv
	s += v * dt
	# The ends of the line: it stops against them.
	if track:
		var lo := length
		var hi: float = track.length
		if s > hi or s < lo:
			s = clampf(s, lo, hi)
			v = 0.0
			at_end = true


## The state as numbers (for the lab's log and later the save).
func to_dict() -> Dictionary:
	return {"s": s, "v": v, "throttle": throttle, "brake_lever": brake_lever, "reverser": reverser,
		"regulator": regulator, "steam": steam, "brake": brake, "time": time}


func from_dict(d: Dictionary) -> void:
	for k in d:
		set(k, d[k])
	s_before = s
