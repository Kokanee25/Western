class_name TrainTimetable
extends RefCounted
## A train's timetable as data (step 2, #551; #542 "The timetable names stops, not distances"):
## the stops by the route's mark names, how long it stands at each, and when it leaves the first.
## Arrive and leave times are given per stop, or, left out, worked out from the line itself: the
## run between two stops is driven once by the engineer at the planned speed (`measure`), and the
## timetable allows that and `padding` more. So a longer or shorter route just changes them.
##
##   {
##     "name": "...",
##     "start": 0,             the first departure, s of the run (step 6 makes it a clock time)
##     "planned_kmh": 22,      the line speed the run times are measured at
##     "max_kmh": 32,          the most the engineer will run to make up time (a dial)
##     "padding": 0.15,        recovery time on each run, a share of it
##     "stops": [
##       {"mark": "depot"},
##       {"mark": "mine", "dwell": 180},         stands 180 s (loads); "arrive"/"depart" may be given
##       {"mark": "depot"}
##     ]
##   }
##
## After `fill()` every stop has `s` (where along the line), `arrive` and `depart` (s of the run;
## the first has no arrive, the last no depart), and `legs[k]` the planned run from stop k to k+1:
## {time (as driven), allowed, profile: [[distance from stop k, time], ...]}.

var data: Dictionary = {}
var stops: Array[Dictionary] = []
var legs: Array[Dictionary] = []
var path := ""


static func load_file(file: String) -> TrainTimetable:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not (d is Dictionary):
		push_error("TrainTimetable: can't read %s" % file)
		return null
	var tt := from_dict(d)
	tt.path = file
	return tt


static func from_dict(d: Dictionary) -> TrainTimetable:
	var tt := TrainTimetable.new()
	tt.data = d
	return tt


func planned_kmh() -> float:
	return float(data.get("planned_kmh", 22.0))


func max_kmh() -> float:
	return float(data.get("max_kmh", 32.0))


## Work out where each stop is on `line` and, where the file leaves them out, the times.
func fill(line: TrackLine, t: TrainTuning) -> void:
	stops.clear()
	legs.clear()
	for st: Dictionary in data.get("stops", []):
		var s := line.mark_s(str(st.mark))
		if is_nan(s):
			push_error("TrainTimetable: no mark '%s' on the line" % st.mark)
			continue
		var stop := st.duplicate()
		stop.s = s
		stop.dwell = float(st.get("dwell", 0.0))
		stops.append(stop)
	var clock := float(data.get("start", 0.0))
	var pad := float(data.get("padding", 0.15))
	for k in stops.size():
		var stop: Dictionary = stops[k]
		if k > 0:
			var leg := measure(line, t, float(stops[k - 1].s), float(stop.s), planned_kmh())
			leg.allowed = snappedf(float(leg.time) * (1.0 + pad), 5.0)
			legs.append(leg)
			stop.arrive = float(stop.get("arrive", clock + float(leg.allowed)))
			clock = stop.arrive
		if k < stops.size() - 1:
			stop.depart = float(stop.get("depart", clock + float(stop.dwell)))
			clock = stop.depart


## The run from `a` to `b` (the engine's front from mark to mark), standing to standing, driven by
## the engineer at `kmh` with no timetable to keep: {time, distance, profile, stopped_at}.
static func measure(line: TrackLine, t: TrainTuning, a: float, b: float, kmh: float) -> Dictionary:
	var sim := TrainSim.new(t, line)
	sim.place(a)
	var eng := TrainEngineer.new(sim, line)
	eng.go_to(b, kmh)
	var profile := [[0.0, 0.0]]
	var dt := 1.0 / 60.0
	var next_sample := 5.0
	while not eng.arrived() and sim.time < 1800.0:
		eng.drive(dt)
		sim.step(dt)
		if absf(sim.s - a) >= next_sample:
			profile.append([absf(sim.s - a), sim.time])
			next_sample += 5.0
	profile.append([absf(sim.s - a), sim.time])
	return {"time": sim.time, "distance": absf(b - a), "profile": profile, "stopped_at": sim.s}


## When the timetable has the train at `dist` metres into leg `k` (from stop k to k+1), s of the
## run: the planned run's own time there, stretched by the padding to the time allowed.
func scheduled_at(k: int, dist: float) -> float:
	var leg: Dictionary = legs[k]
	var prof: Array = leg.profile
	var tm := float(prof[prof.size() - 1][1])
	for i in range(1, prof.size()):
		if float(prof[i][0]) >= dist:
			var p0: Array = prof[i - 1]
			var p1: Array = prof[i]
			var f := clampf((dist - float(p0[0])) / maxf(float(p1[0]) - float(p0[0]), 1e-6), 0.0, 1.0)
			tm = lerpf(float(p0[1]), float(p1[1]), f)
			break
	return float(stops[k].depart) + tm * float(leg.allowed) / maxf(float(leg.time), 1e-6)


## The timetable as lines (for the README and the bridge).
func describe() -> Array:
	var out := []
	for st in stops:
		out.append({"mark": st.mark, "s": snappedf(st.s, 0.01), "arrive": st.get("arrive", null),
			"depart": st.get("depart", null), "dwell": st.dwell})
	return out
