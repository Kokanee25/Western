class_name TrackRoute
extends RefCounted
## A railroad route as data (docs/briefs/train.md, step 2; #542 "The route can move"): one JSON
## file of plan, profile and named marks, from which a TrackLine is laid. Change the file and the
## rails, ties, ballast and fill all rebuild; everything on the line (stops, the depot, the mine's
## loading spot, later the trestle, signs and mile posts) is placed by a mark's name, never by a
## world position, so it moves with the line. The format:
##
##   name       the route's id (a timetable names it)
##   origin     [x, y, z] where the line starts, in its parent's space; heading: degrees from north
##              (-Z) toward east (+X), the way it sets off
##   length     the whole line, m (the plan's last piece is a straight on to it)
##   plan       in order: {"straight": m}, or {"curve": "left"|"right", "radius": m, "degrees": the
##              whole turn, "spiral": m of easement in and out (0 for none)}
##   profile    {"vertical_curve": m, "grades": [[s, per cent], ...]}: the grade from each s on
##              (+ rises toward the line's end), each change eased over the vertical curve
##   marks      {name: s}: named points along the line (stops, grade posts)
##   stops      the marks a train stops at (drawn as stop boards; the rest as plain posts)
##
## A save's damage to the line (step 5) keeps the route's name and the distance along it.

## Read a route file: the parsed dictionary, or {} (an error printed) if it can't be read.
static func read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("TrackRoute: can't open %s" % path)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary:
		push_error("TrackRoute: %s isn't a JSON object" % path)
		return {}
	var problems := check(d)
	if not problems.is_empty():
		push_error("TrackRoute: %s: %s" % [path, "; ".join(problems)])
		return {}
	return d


## What's wrong with a route (empty if nothing).
static func check(r: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for k in ["name", "length", "plan", "profile", "marks"]:
		if not r.has(k):
			out.append("no %s" % k)
	if not out.is_empty():
		return out
	var segs := segments(r)
	var laid := 0.0
	for seg: Dictionary in segs:
		laid += float(seg.length)
	if laid > float(r.length) + 0.01:
		out.append("its plan (%.1f m) is longer than its length (%.1f m)" % [laid, float(r.length)])
	for m in r.marks:
		var at := float(r.marks[m])
		if at < 0.0 or at > float(r.length):
			out.append("mark %s at %.1f is off the line" % [m, at])
	for st in r.get("stops", []):
		if not r.marks.has(st):
			out.append("stop %s isn't a mark" % st)
	return out


## The plan as TrackLine's segments ({length, k0, k1}: curvature from k0 to k1, + to the left),
## the last straight run on to the route's length.
static func segments(r: Dictionary) -> Array:
	var out := []
	var laid := 0.0
	for p: Dictionary in r.plan:
		if p.has("straight"):
			out.append({"length": float(p.straight), "k0": 0.0, "k1": 0.0})
			laid += float(p.straight)
		elif p.has("curve"):
			var k := (1.0 if String(p.curve) == "left" else -1.0) / float(p.radius)
			var sp := float(p.get("spiral", 0.0))
			var turn := deg_to_rad(float(p.degrees))
			# Two spirals turn sp * |k| between them; the arc the rest.
			var arc := (turn - sp * absf(k)) / absf(k)
			if arc < 0.0:
				push_error("TrackRoute: a %s degree curve is too short for its %s m spirals" % [p.degrees, sp])
				arc = 0.0
			if sp > 0.0:
				out.append({"length": sp, "k0": 0.0, "k1": k})
			out.append({"length": arc, "k0": k, "k1": k})
			if sp > 0.0:
				out.append({"length": sp, "k0": k, "k1": 0.0})
			laid += arc + 2.0 * sp
	var rest := float(r.get("length", laid)) - laid
	if rest > 0.01:
		out.append({"length": rest, "k0": 0.0, "k1": 0.0})
	return out


## The profile as TrackLine's grades ([[s, rise over run], ...]).
static func grades(r: Dictionary) -> Array:
	var out := []
	for g in r.profile.get("grades", [[0.0, 0.0]]):
		out.append([float(g[0]), float(g[1]) * 0.01])
	return out


## A TrackLine laid out from the route (not drawn, not in the tree: for the headless runs).
static func make_line(r: Dictionary, t: TrainTuning) -> TrackLine:
	var line := TrackLine.new()
	line.name = "TrainLabLine"
	line.route_name = StringName(r.get("name", ""))
	line.tuning = t
	line.segments = segments(r)
	line.grades = grades(r)
	line.vertical_curve = float(r.profile.get("vertical_curve", 60.0))
	line.marks = {}
	for m in r.marks:
		line.marks[StringName(m)] = float(r.marks[m])
	line.stops = []
	for st in r.get("stops", []):
		line.stops.append(StringName(st))
	line.start_height = t.ballast_depth + t.tie_size.y + t.rail_size.y + 0.25
	line.lay_out()
	return line


## Where the line sits in its parent: origin and heading.
static func place(line: TrackLine, r: Dictionary) -> void:
	var o: Array = r.get("origin", [0.0, 0.0, 0.0])
	line.position = Vector3(float(o[0]), float(o[1]), float(o[2]))
	line.rotation_degrees.y = 360.0 - float(r.get("heading", 0.0))
