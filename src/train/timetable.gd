class_name Timetable
extends RefCounted
## A train's timetable as data (docs/briefs/train.md, step 2): the stops by name (a route's marks,
## TrackRoute), each with its leave time or its dwell. The arrival times aren't written down: they
## are worked out from the sim (`work_out`), the engineer's own run between each pair of stops at
## the schedule speed, padded by `pad` and rounded up to `round` seconds, so a longer or shorter
## route only changes them. A stop may give its `arrive` and `leave` itself; the run times are
## still measured and a time that can't be kept is listed in `problems`.
##
## The file (JSON):
##   name, route (the route's name: it must match the line's)
##   pad      the share added to each measured run (the time a late train can make up), 0.06
##   round    arrive times rounded up to this many seconds
##   stops    [{at: mark, leave: "HH:MM" | dwell: s, min_dwell: s, arrive: "HH:MM"}, ...]
## The first stop needs a leave time; each later stop a dwell (or a leave). `min_dwell`: the least
## it stops for when the train's late (default: its dwell).
##
## After work_out: `stops[i]` = {at, s, arrive, leave, dwell, min_dwell} (times in s of the day),
## `legs[i]` (stop i to i + 1) = {from, to, ref (the measured run, s), run (the timetable's), profile
## (the measured run's time at every PROFILE_STEP m of the leg)}.

const PROFILE_STEP := 10.0
## The reference runs' step (the run times only; a coarser step than the game's).
const REF_DT := 1.0 / 30.0

var name := ""
var route := ""
var pad := 0.06
var round_to := 30.0
var stops: Array[Dictionary] = []
var legs: Array[Dictionary] = []
var problems := PackedStringArray()


static func read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Timetable: can't open %s" % path)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


## "08:05" or "08:05:30" -> seconds of the day; a number is taken as seconds.
static func clock_of(v: Variant) -> float:
	if v is float or v is int:
		return float(v)
	var parts := String(v).split(":")
	var sec := 0.0
	for i in parts.size():
		sec += float(parts[i]) * [3600.0, 60.0, 1.0][i]
	return sec


## Seconds of the day -> "08:05:30".
static func clock_text(sec: float) -> String:
	var s := int(round(sec))
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


## The timetable from its data, its run times measured on `line` with the train `t` (its consist,
## or `consist`), its times filled in.
static func work_out(data: Dictionary, line: TrackLine, t: TrainTuning, consist: Array = []) -> Timetable:
	var tt := Timetable.new()
	tt.name = String(data.get("name", ""))
	tt.route = String(data.get("route", ""))
	tt.pad = float(data.get("pad", 0.06))
	tt.round_to = maxf(float(data.get("round", 30.0)), 1.0)
	if tt.route != "" and line.route_name != &"" and tt.route != String(line.route_name):
		tt.problems.append("the timetable is for route %s, the line is %s" % [tt.route, line.route_name])
	for st: Dictionary in data.get("stops", []):
		var at := StringName(st.get("at", ""))
		if not line.marks.has(at):
			tt.problems.append("stop %s isn't a mark on %s" % [at, line.route_name])
			continue
		var dwell := float(st.get("dwell", 0.0))
		tt.stops.append({"at": at, "s": float(line.marks[at]), "dwell": dwell,
			"min_dwell": float(st.get("min_dwell", dwell)),
			"given_leave": clock_of(st.leave) if st.has("leave") else NAN,
			"given_arrive": clock_of(st.arrive) if st.has("arrive") else NAN})
	if tt.stops.size() < 2 or is_nan(float(tt.stops[0].given_leave)):
		tt.problems.append("a timetable needs two stops and the first one's leave time")
		return tt
	# The engineer's own runs, stop to stop, at the schedule speed: the run times.
	var sim := TrainSim.new(t, line, consist)
	sim.brake_lever = 1.0
	sim.place(float(tt.stops[0].s))
	var e := TrainEngineer.new(sim, line, t)
	for i in tt.stops.size() - 1:
		var to: Dictionary = tt.stops[i + 1]
		var profile := PackedFloat32Array([0.0])
		e.run_to(float(to.s), t.schedule_kmh)
		var t0 := sim.time
		var from_s := sim.s
		while e.state == &"running" and sim.time - t0 < 3600.0:
			e.tick(REF_DT)
			sim.step(REF_DT)
			var gone := absf(sim.s - from_s)
			while gone >= float(profile.size()) * PROFILE_STEP:
				profile.append(sim.time - t0)
		var ref := sim.time - t0
		if e.state != &"stopped":
			tt.problems.append("the run from %s to %s didn't stop on its mark" % [tt.stops[i].at, to.at])
		# Standing a moment, as at a stop (the brakes on, the slack where it fell).
		for k in int(5.0 / REF_DT):
			e.tick(REF_DT)
			sim.step(REF_DT)
		var run := ceilf(ref * (1.0 + tt.pad) / tt.round_to) * tt.round_to
		tt.legs.append({"from": tt.stops[i].at, "to": to.at, "ref": ref, "run": run, "profile": profile,
			"stopped_off": (sim.s - float(to.s))})
	# The times: leave + run = arrive, + dwell = leave (a given time wins if it can be kept).
	var clock := float(tt.stops[0].given_leave)
	tt.stops[0].arrive = clock
	tt.stops[0].leave = clock
	for i in range(1, tt.stops.size()):
		var st: Dictionary = tt.stops[i]
		var arrive := clock + float(tt.legs[i - 1].run)
		if not is_nan(float(st.given_arrive)):
			if float(st.given_arrive) < clock + float(tt.legs[i - 1].ref):
				tt.problems.append("%s's arrival %s can't be kept (the run takes %d s)" % [st.at, clock_text(float(st.given_arrive)), int(tt.legs[i - 1].ref)])
			arrive = float(st.given_arrive)
			tt.legs[i - 1].run = arrive - clock
		st.arrive = arrive
		st.leave = arrive + float(st.dwell)
		if not is_nan(float(st.given_leave)):
			st.leave = maxf(float(st.given_leave), arrive)
		clock = float(st.leave)
	return tt


## The timetable's time at `m` metres into the leg to stop `i` (its measured run stretched to the
## timetable's run time).
func due_at(i: int, m: float) -> float:
	var leg: Dictionary = legs[i - 1]
	return float(stops[i - 1].leave) + _ref_at(leg, m) * float(leg.run) / maxf(float(leg.ref), 1.0)


## The measured run's time still to go from `m` metres into the leg to stop `i`, s.
func run_left(i: int, m: float) -> float:
	var leg: Dictionary = legs[i - 1]
	return maxf(float(leg.ref) - _ref_at(leg, m), 0.0)


func _ref_at(leg: Dictionary, m: float) -> float:
	var p: PackedFloat32Array = leg.profile
	var x := clampf(m / PROFILE_STEP, 0.0, float(p.size() - 1))
	var k := int(x)
	if k >= p.size() - 1:
		return minf(float(p[p.size() - 1]) + (m - float(p.size() - 1) * PROFILE_STEP) / 2.0, float(leg.ref))
	return lerpf(p[k], p[k + 1], x - k)


## The timetable as text rows (for the lab's reports).
func summary() -> Array:
	var out := []
	for i in stops.size():
		var st: Dictionary = stops[i]
		var row := {"stop": String(st.at), "s": st.s, "arrive": clock_text(float(st.arrive)), "leave": clock_text(float(st.leave))}
		if i > 0:
			row.run_s = legs[i - 1].run
			row.measured_s = snappedf(float(legs[i - 1].ref), 0.1)
		out.append(row)
	return out
