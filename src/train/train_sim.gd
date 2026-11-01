class_name TrainSim
extends RefCounted
## The train in one dimension (docs/briefs/train.md, steps 1 and 2): each car its own mass on the
## line, where its front end is (`x[i]`, metres along the track) and how fast (`u[i]`, m/s, + toward
## the track's end), joined by couplers with slack: free play, then a stiff spring and a damper
## (the draft gear). So on a start the engine moves alone until its coupler runs out, then takes the
## tender, then the first car, one after another down the train; braking, the cars behind run in on
## the ones ahead (each car's brakes set a little after the one ahead's). Each coupler running out
## or bunching hard is an event (`events`), what step 4's coupler bangs hang on.
##
## The forces on each car:
##   - the engine's tractive effort (on the engine alone), the least of: the steam's effort (falling
##     with speed, as the cylinders fill less each stroke), the boiler's power over speed, and the
##     drivers' adhesion;
##   - resistance in the Davis form (journals and flanges by its weight; the air mostly on the
##     leading car), the curve's under it, and breaking away from a stand;
##   - gravity on the grade under it;
##   - its brakes, weak against the mass, gripping harder as the wheels slow (cast iron shoes);
##   - the couplers to the cars either side.
## The engineer's hand is `throttle` (0..1), `brake_lever` (0..1) and `reverser`; the regulator
## follows the throttle at a rate, the steam the regulator with a lag, each car's brakes the handle
## after its delay down the train. Deterministic: no dice, the same inputs give the same run to the bit.
##
## `s` and `v` are the engine's (the train's front, as the track's distance runs); setting them
## moves (or speeds) the whole train. The track is anything with `grade_at(s)`, `curvature_at(s)`
## and `length` (TrackLine). Cars: `cars[i]` = {name, kind, length, mass, trucks (Vector2: from its
## front), front (its front's nominal distance behind the train's front, the couplers in the middle
## of their play), width, height}.

const G := 9.81
## Events kept (the oldest dropped).
const EVENTS_KEPT := 512

var tuning: TrainTuning
var track: Object
var cars: Array[Dictionary] = []
var mass := 0.0
## Front to back with the couplers in the middle of their play, m.
var length := 0.0

## State: each car's front along the track and its speed, and a tick ago (for drawing between ticks).
var x := PackedFloat64Array()
var u := PackedFloat64Array()
var x_before := PackedFloat64Array()
var throttle := 0.0  # the engineer's hand on the regulator, 0..1
var brake_lever := 0.0  # the brake handle, 0..1
var reverser := 1  # +1 forward (toward the track's end), -1 back
var regulator := 0.0  # where the regulator actually is
var steam := 0.0  # the cylinders' share of full effort
var brakes := PackedFloat64Array()  # each car's brakes as set, 0..1
var time := 0.0
var at_end := false  # run into the end of the line

## Each coupler (between car i and i + 1): 0 in its play, 1 run out (pulling), -1 bunched (pushing).
var coupler_state := PackedInt32Array()
## The force each coupler carries, N (+ pulling).
var coupler_force := PackedFloat64Array()
## Coupler events: {t, coupler, kind (&"out" ran out / &"in" bunched), speed (m/s closing), s}.
var events: Array[Dictionary] = []
var event_count := 0

## The last tick's forces on the whole train (N), for the graphs.
var f_tractive := 0.0
var f_resist := 0.0
var f_grade := 0.0
var f_brake := 0.0
var limit := &"none"  # what capped the effort: adhesion, steam, power

var s: float:
	get:
		return x[0] if x.size() > 0 else 0.0
	set(value):
		var d := value - s
		for i in x.size():
			x[i] += d
			x_before[i] = x[i]

var v: float:
	get:
		return u[0] if u.size() > 0 else 0.0
	set(value):
		for i in u.size():
			u[i] = value

## The engine's position a tick ago.
var s_before: float:
	get:
		return x_before[0] if x_before.size() > 0 else 0.0

## The brakes as set, the train's mean (weighted by each car's weight).
var brake: float:
	get:
		var b := 0.0
		for i in cars.size():
			b += brakes[i] * float(cars[i].mass)
		return b / maxf(mass, 1.0)

var _lever_hist := PackedFloat32Array()  # the brake handle a tick, newest first (the delay down the train)
var _dt_seen := 1.0 / 60.0


func _init(t: TrainTuning, on_track: Object = null, consist: Array = []) -> void:
	tuning = t
	track = on_track
	_make_consist(consist if not consist.is_empty() else t.consist)


func _make_consist(consist: Array) -> void:
	cars.clear()
	var front := 0.0
	for c: Dictionary in consist:
		var car := {"name": StringName(c.get("name", "car")), "kind": StringName(c.get("kind", "box")),
			"length": float(c.length), "mass": float(c.get("mass", 10000.0)) + float(c.get("load", 0.0)),
			"trucks": c.get("trucks", Vector2(1.3, float(c.length) - 1.3)), "front": front,
			"width": float(c.get("width", 2.3)), "height": float(c.get("height", 3.1))}
		cars.append(car)
		front += float(c.length) + tuning.coupler_gap
	length = front - tuning.coupler_gap
	mass = 0.0
	for c in cars:
		mass += c.mass
	var n := cars.size()
	x.resize(n)
	u.resize(n)
	x_before.resize(n)
	brakes.resize(n)
	coupler_state.resize(maxi(n - 1, 0))
	coupler_force.resize(maxi(n - 1, 0))
	place(0.0)


## Put the train with its front at `at`, standing, its couplers bunched (as a train stands after a
## stop: a start then takes them up car by car), or `bunched` false: in the middle of their play.
func place(at: float, bunched := true) -> void:
	var gap := tuning.coupler_gap - (tuning.coupler_slack * 0.5 if bunched else 0.0)
	var front := at
	for i in cars.size():
		x[i] = front
		x_before[i] = front
		u[i] = 0.0
		brakes[i] = clampf(brake_lever, 0.0, 1.0)
		front -= float(cars[i].length) + gap
	for j in coupler_state.size():
		coupler_state[j] = -1 if bunched else 0
		coupler_force[j] = 0.0
	regulator = 0.0
	steam = 0.0
	at_end = false
	_lever_hist.clear()


## Where along the track a car's front truck (0) or back truck (1) is: where the car is now, or, given
## `at`, where it would be with the train's front at `at` and the couplers in the middle of their play.
func truck_s(car: int, which: int, at := INF) -> float:
	var c: Dictionary = cars[car]
	var tr: Vector2 = c.trucks
	var front: float = x[car] if at == INF else at - float(c.front)
	return front - (tr.x if which == 0 else tr.y)


## Where a car's front was `f` of the way from the last tick to this one (for drawing between ticks).
func car_s(car: int, f := 1.0) -> float:
	return lerpf(x_before[car], x[car], f)


## The gap between car j's back end and car j + 1's front end, m.
func gap(j: int) -> float:
	return x[j] - float(cars[j].length) - x[j + 1]


## The train's middle (for the grade under it, as step 1 reckoned it).
func middle() -> float:
	return (x[0] + x[x.size() - 1] - float(cars[cars.size() - 1].length)) * 0.5


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
	var n := cars.size()
	_dt_seen = dt
	for i in n:
		x_before[i] = x[i]
	time += dt
	# The engineer's hand -> the regulator -> the steam.
	regulator = move_toward(regulator, clampf(throttle, 0.0, 1.0), dt / maxf(t.regulator_open_time, 0.001))
	steam += (regulator - steam) * (1.0 - exp(-dt / maxf(t.steam_lag, 0.001)))
	# The brake handle -> each car's brakes, after its delay down the train.
	_lever_hist.insert(0, clampf(brake_lever, 0.0, 1.0))
	var keep := int(ceil(t.brake_propagation * float(n) / dt)) + 2
	if _lever_hist.size() > keep:
		_lever_hist.resize(keep)
	for i in n:
		var k := mini(int(round(t.brake_propagation * float(i) / dt)), _lever_hist.size() - 1)
		var want := _lever_hist[k]
		var rate := t.brake_apply_time if want > brakes[i] else t.brake_release_time
		brakes[i] = move_toward(brakes[i], want, dt / maxf(rate, 0.001))
	# Grade and curves under each car (they change slowly: once a tick).
	var grade := PackedFloat64Array()
	var curve := PackedFloat64Array()
	grade.resize(n)
	curve.resize(n)
	if track:
		for i in n:
			var mid: float = x[i] - float(cars[i].length) * 0.5
			grade[i] = track.grade_at(mid)
			curve[i] = absf(track.curvature_at(mid))
	# The air: the leading car (by the way it's going) takes its share, the rest spread.
	var lead := 0 if v >= 0.0 else n - 1
	var c_lead := t.davis_c * (t.air_lead_share if n > 1 else 1.0)
	var c_rest := (t.davis_c - c_lead) / maxf(float(n - 1), 1.0)
	f_tractive = 0.0
	f_resist = 0.0
	f_grade = 0.0
	f_brake = 0.0
	var steps := maxi(t.coupler_substeps, 1)
	var h := dt / float(steps)
	var force := PackedFloat64Array()
	var hold := PackedFloat64Array()
	force.resize(n)
	hold.resize(n)
	for k in steps:
		var last := k == steps - 1
		# The couplers: free in their play, a spring and damper past it.
		for i in n:
			force[i] = 0.0
		for j in n - 1:
			var g := x[j] - float(cars[j].length) - x[j + 1]
			var e := g - (t.coupler_gap + t.coupler_slack * 0.5)
			var state := 1
			if e <= 0.0:
				e = g - (t.coupler_gap - t.coupler_slack * 0.5)
				state = -1 if e < 0.0 else 0
			var f := 0.0
			if state != 0:
				var closing := u[j] - u[j + 1]  # the gap's rate of change
				f = t.coupler_stiffness * e + t.coupler_damping * closing
				f = maxf(f, 0.0) if state > 0 else minf(f, 0.0)  # a coupler only pushes or pulls
			if last:
				_coupler_moved(j, state, u[j] - u[j + 1])
				coupler_force[j] = f
			force[j] -= f
			force[j + 1] += f
		# Each car's own forces.
		for i in n:
			var m: float = cars[i].mass
			var w := m * G
			var sp := absf(u[i])
			var fg := -w * grade[i]
			var fr := w * (t.davis_a + t.davis_b * sp + t.curve_resistance * curve[i])
			fr += (c_lead if i == lead else c_rest) * u[i] * u[i]
			if sp < t.breakaway_speed:
				fr += w * t.breakaway * (1.0 - sp / t.breakaway_speed)
			var fb := brakes[i] * t.brake_g * w * (1.0 + t.brake_low_speed_gain * exp(-sp / t.brake_low_speed))
			var ft := 0.0
			if i == 0:
				ft = float(reverser) * effort(u[0])
			force[i] += ft + fg
			hold[i] = fr + fb
			if last:
				f_tractive += ft
				f_grade += fg
				f_resist += fr
				f_brake += fb
		# Each car's speed and where it is: what pushes it one way or the other whatever the motion,
		# against what only ever opposes the motion (the resistance and brakes).
		for i in n:
			var m_eff: float = float(cars[i].mass) * (1.0 + t.rotating_share)
			var drive := force[i]
			var ui := u[i]
			if ui == 0.0:
				if absf(drive) > hold[i]:
					ui = signf(drive) * (absf(drive) - hold[i]) / m_eff * h
			else:
				var nu := ui + (drive - signf(ui) * hold[i]) / m_eff * h
				if signf(nu) != signf(ui):  # it stopped within the step (it may start back next step)
					nu = 0.0
				ui = nu
			u[i] = ui
			x[i] += ui * h
	# The ends of the line: the train stops against them.
	if track:
		var hi: float = track.length
		if x[0] > hi:
			_stop_against(x[0] - hi)
		var tail := x[n - 1] - float(cars[n - 1].length)
		if tail < 0.0:
			_stop_against(tail)


func _stop_against(over: float) -> void:
	for i in x.size():
		x[i] -= over
		u[i] = 0.0
	at_end = true


## A coupler's state changed: running out or bunching at speed is an event.
func _coupler_moved(j: int, state: int, closing: float) -> void:
	var was := coupler_state[j]
	if state == was:
		return
	coupler_state[j] = state
	if state == 0:
		return
	var speed := absf(closing)
	if speed < tuning.coupler_event_speed:
		return
	event_count += 1
	events.append({"t": time, "coupler": j, "kind": &"out" if state > 0 else &"in", "speed": speed,
		"s": x[j] - float(cars[j].length), "between": [cars[j].name, cars[j + 1].name]})
	if events.size() > EVENTS_KEPT:
		events.pop_front()


## The state as numbers (for the lab's log and later the save).
func to_dict() -> Dictionary:
	return {"x": Array(x), "u": Array(u), "throttle": throttle, "brake_lever": brake_lever,
		"reverser": reverser, "regulator": regulator, "steam": steam, "brakes": Array(brakes),
		"time": time, "coupler_state": Array(coupler_state)}


func from_dict(d: Dictionary) -> void:
	for k in d:
		match k:
			"x":
				x = PackedFloat64Array(d.x)
				x_before = PackedFloat64Array(d.x)
			"u":
				u = PackedFloat64Array(d.u)
			"brakes":
				brakes = PackedFloat64Array(d.brakes)
			"coupler_state":
				coupler_state = PackedInt32Array(d.coupler_state)
			_:
				set(k, d[k])
