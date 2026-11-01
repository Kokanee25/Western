class_name TrainEngineer
extends RefCounted
## The engineer (step 2, #551): a man in the cab who drives the train by the same three controls
## the debug cab has (the regulator, the brake handle, the reverser) to a timetable written as data
## (TrainTimetable). Each tick, before the train's own tick, `drive()` sets his hands:
##
##   - Standing at a stop he holds the brake. He leaves at the timetable's time (late, after his
##     least dwell, `dwell_min`), the reverser set toward the next stop.
##   - Running, he holds a speed: the one that gets him to the next stop on time (from the time and
##     distance left, as a man reckons it), never more than the timetable's `max_kmh`. Late, that
##     speed is higher, so he makes the time up over the run. Downhill he holds it with the brake.
##   - He brakes for the mark from the stopping distance the brakes give on the grade he's on (the
##     same 1D numbers as the train: the shoes' grip, the grade, a lead for the seconds they take
##     to set down the train), meaning to use only `service_brake` of them, so he has some in hand;
##     then he brakes as hard as stopping on the mark needs, easing off as he comes onto it. Stopped
##     short, he creeps up; past it, he sets back.
##
## A man's hands, not a script: he can't do what the train can't (a short stop on a steep grade
## comes out long), and if he's dead (`body` limp, or gone) nobody drives: the levers stay where
## they were.
##
## `rows` a row every half second {t, odo (m run), s, kmh, delay (s late against the timetable at
## this point), leg, state}; `stop_log` a row a stop {mark, target, stopped_at, error (m past the
## mark, + overshot), arrive, scheduled, delay}.

enum { WAIT, RUN, DONE }

var sim: TrainSim
var line: TrackLine
var tuning: TrainTuning
var timetable: TrainTimetable
## His body (a HumanBody in the cab), or null to drive regardless (the headless runs).
var body: Node3D

var state := DONE
var stop := 0  # the stop he's at (WAIT) or last left (RUN)
var target := 0.0  # where he's bound (the next mark's s)
var dir := 1  # which way along the line he's going
var cruise := 0.0  # the speed he's holding, m/s
var braking := false
var late_until := 0.0  # a late start: he's not ready to leave the first stop before this
var arrived_t := 0.0
var odo := 0.0
var rows: Array[Dictionary] = []
var stop_log: Array[Dictionary] = []

var _plain_kmh := 0.0  # go_to's speed (no timetable)
var _leg_from := 0.0
var _last_s := 0.0
var _next_log := 0.0
var _next_cruise := 0.0


func _init(train_sim: TrainSim, on_line: TrackLine) -> void:
	sim = train_sim
	line = on_line
	tuning = sim.tuning
	_last_s = sim.s


## Run to `at` at `kmh` and stop on it (no timetable): the measured run.
func go_to(at: float, kmh: float) -> void:
	timetable = null
	_plain_kmh = kmh
	_start_leg(at)


## Follow a timetable (filled for this line) from its first stop, where the train stands. `late`:
## he can't leave before this many seconds past the timetable's start (a late start).
func run(tt: TrainTimetable, late := 0.0) -> void:
	timetable = tt
	stop = 0
	state = WAIT
	arrived_t = sim.time
	late_until = float(tt.data.get("start", 0.0)) + late
	_last_s = sim.s


func arrived() -> bool:
	return state == DONE or (timetable == null and state == WAIT)


func now() -> float:
	return sim.time


func _alive() -> bool:
	if body == null:
		return true
	if not is_instance_valid(body):
		return false
	return not bool(body.get(&"limp"))


func _start_leg(at: float) -> void:
	target = at
	dir = 1 if at >= sim.s else -1
	_leg_from = sim.s
	braking = false
	state = RUN
	_next_cruise = 0.0
	sim.reverser = dir


## His hands for this tick (call before the train's step).
func drive(dt: float) -> void:
	odo += absf(sim.s - _last_s)
	_last_s = sim.s
	if not _alive():
		return
	match state:
		WAIT:
			_wait()
		RUN:
			_run(dt)
		DONE:
			sim.throttle = 0.0
			sim.brake_lever = 1.0
	if sim.time >= _next_log:
		_next_log = sim.time + 0.5
		rows.append({"t": sim.time, "odo": odo, "s": sim.s, "kmh": sim.v * 3.6, "delay": delay(),
			"leg": stop, "state": ["wait", "run", "done"][state]})


func _wait() -> void:
	sim.throttle = 0.0
	sim.brake_lever = 1.0
	if timetable == null:
		return
	if stop >= timetable.stops.size() - 1:
		state = DONE
		return
	var here: Dictionary = timetable.stops[stop]
	var leave := float(here.depart)
	if stop > 0:  # late in, he still stands his least dwell (it loads)
		leave = maxf(leave, arrived_t + minf(float(here.dwell), tuning.dwell_min))
	else:
		leave = maxf(leave, late_until)
	if sim.time >= leave and sim.v == 0.0:
		_start_leg(float(timetable.stops[stop + 1].s))


## How late he is now against the timetable, s (- early).
func delay() -> float:
	if timetable == null or timetable.stops.is_empty():
		return 0.0
	match state:
		RUN:
			return sim.time - timetable.scheduled_at(stop, absf(sim.s - _leg_from))
		WAIT:
			var here: Dictionary = timetable.stops[stop]
			var late_in := arrived_t - float(here.arrive) if here.has("arrive") else -INF
			var late_out := sim.time - float(here.depart) if here.has("depart") else -INF
			if stop == 0:
				return late_out
			return maxf(late_in, late_out)
	return 0.0


## The deceleration full brake gives at this speed on the grade under the train, going `dir` (m/s²).
func full_brake_decel(speed: float) -> float:
	var t := tuning
	var grade := line.grade_at(sim.s - dir * sim.length * 0.5) * dir  # + uphill helps him stop
	return G * (t.brake_g * (1.0 + t.brake_low_speed_gain * exp(-speed / t.brake_low_speed))
		+ t.davis_a + grade) / (1.0 + t.rotating_share)

const G := 9.81
## He reckons to be in this many seconds before the timetable's time (his reckoning is a man's).
const AIM_EARLY := 8.0


func _run(_dt: float) -> void:
	var t := tuning
	var d := (target - sim.s) * dir  # still to go, m
	var vd := sim.v * dir  # his speed toward it
	var a_full := maxf(full_brake_decel(maxf(vd, 0.0)), 0.02)
	var a_plan := t.service_brake * a_full
	# Arrived: standing on the mark.
	if absf(d) <= t.stop_tolerance and absf(sim.v) < 0.01:
		_arrive(d)
		return
	# Off the mark and standing (short, or past it): creep to it.
	if absf(sim.v) < 0.01 and absf(d) > t.stop_tolerance and (braking or d < 0.0):
		_creep(d)
		return
	if sim.time >= _next_cruise:
		_next_cruise = sim.time + 1.0
		cruise = _cruise_speed(d, a_plan)
	# Where he must be braking to stop on the mark: the speed he can still carry here.
	var reach := maxf(d - maxf(vd, 0.0) * t.brake_lead, 0.0)
	var v_allow := sqrt(2.0 * a_plan * reach)
	if not braking and vd > 0.05 and vd >= v_allow:
		braking = true
	elif braking and vd < v_allow * 0.8 and d > 15.0 and vd < cruise:
		braking = false  # braked for a grade that's behind him: run on to the mark
	if braking:
		sim.throttle = 0.0
		if d <= 0.0:
			sim.brake_lever = 1.0
			return
		# As hard as stopping on the mark needs (with the shoes' lag reckoned in), easing off on to it.
		var a_req := vd * vd / (2.0 * maxf(d - vd * t.brake_lead * 0.35, 0.05))
		var lever := a_req / a_full
		if vd < t.creep_speed and d > t.stop_tolerance:
			lever = minf(lever, 0.5)  # don't let the shoes hold him short
		sim.brake_lever = clampf(lever, 0.0, 1.0)
		if vd < 0.2 and d > 3.0:
			braking = false  # well short and nearly stopped: run on to it
		return
	# Holding his speed.
	var grade := line.grade_at(sim.s - dir * sim.length * 0.5) * dir
	if vd < cruise:
		sim.throttle = clampf(0.12 + t.throttle_gain * (cruise - vd) + maxf(grade, 0.0) * 12.0, 0.0, 1.0)
		sim.brake_lever = 0.0
	else:
		sim.throttle = clampf(0.12 - t.throttle_gain * (vd - cruise) * 2.0 + maxf(grade, 0.0) * 12.0, 0.0, 1.0)
		# Downhill he holds it on the brake: as much as the grade takes, and more as he gains on it.
		var need := clampf(-grade / t.brake_g, 0.0, 1.0)
		sim.brake_lever = clampf(need * 0.8 + t.hold_brake_gain * (vd - cruise - 0.3), 0.0, 1.0) if grade < -0.003 and vd > cruise else 0.0


## The speed that gets him to the next stop on time, m/s: with T left and d to go, braking at a,
## d = v (T - v / 2a) (the braking costs him v / 2a); never more than the timetable's max, nor less
## than a walking-pace crawl. Without a timetable, go_to's speed.
func _cruise_speed(d: float, a: float) -> float:
	if timetable == null:
		return _plain_kmh / 3.6
	var lo := 8.0 / 3.6
	var hi := timetable.max_kmh() / 3.6
	var arrive := float(timetable.stops[stop + 1].arrive)
	var left := arrive - AIM_EARLY - sim.time
	# Getting up to speed costs him too (from a stand, at about the start's pull).
	var a_eff := 1.0 / (1.0 / a + (1.0 / 0.35 if absf(sim.v) < 3.0 else 0.0))
	var disc := left * left - 2.0 * d / a_eff
	if left <= 0.0 or disc <= 0.0:
		return hi
	return clampf(a_eff * (left - sqrt(disc)), lo, hi)


func _creep(d: float) -> void:
	# Brakes off, a breath of steam toward the mark (setting back if he's past it).
	var way := 1 if d > 0.0 else -1
	sim.reverser = dir * way
	if sim.brake > 0.15:
		sim.brake_lever = 0.0
		sim.throttle = 0.0
		return
	sim.brake_lever = 0.0
	sim.throttle = 0.35
	braking = false
	if way < 0:  # past it: back up to it, then stop as from any run
		target = sim.s + d * dir
		dir = -dir
		sim.reverser = dir


func _arrive(d: float) -> void:
	sim.throttle = 0.0
	sim.brake_lever = 1.0
	arrived_t = sim.time
	var rec := {"target": target, "stopped_at": sim.s, "error": -d, "t": sim.time}
	if timetable:
		stop += 1
		var here: Dictionary = timetable.stops[stop]
		rec.mark = here.mark
		rec.scheduled = here.arrive
		rec.delay = sim.time - float(here.arrive)
	stop_log.append(rec)
	state = WAIT if timetable == null or stop < timetable.stops.size() - 1 else DONE
	braking = false
