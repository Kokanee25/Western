class_name TrainRoute
extends RefCounted
## A railroad's route as data (issue #542, "The route can move"; step 2, #551): one JSON file that
## lays the line out the way a surveyor would, so moving the line is editing the file and nothing
## else. Everything on the line hangs off it by name (the stops, the depot, the mine's loading
## spot), never off world positions, so they move with it.
##
##   {
##     "name": "...",
##     "origin": [x, y, z], "heading": degrees from north (0 = -Z, 90 = east),   (where it starts)
##     "plan": [                                          (the line seen from above, in order)
##       {"straight": 400},                               a straight, m
##       {"bend": {"radius": 120, "turn": 90, "spirals": 30, "side": "left"}},
##                                                        spiral in, arc, spiral out: turn degrees in all
##       {"straight_to": 1500}                            a straight to make the line this long
##     ],
##     "profile": {"vertical_curve": 60,                  (grades in %, + rising toward the end)
##                 "grades": [[0, 0], [750, 2.5], [1050, -2.5], [1350, 0]]},
##     "marks": {"depot": 120, "mine": 1440},             named points, m along the line
##     "height": 0.78                                     the rail top above the ground at the start (optional)
##   }
##
## Distances in the file are along the line as laid (the plan's metres); `TrackLine.mark_s()` gives
## them along the drawn curve (they differ by well under a part in a thousand).

var data: Dictionary = {}
var path := ""


static func load_file(file: String) -> TrainRoute:
	var r := TrainRoute.new()
	r.path = file
	var txt := FileAccess.get_file_as_string(file)
	var d: Variant = JSON.parse_string(txt)
	if not (d is Dictionary):
		push_error("TrainRoute: can't read %s" % file)
		return null
	r.data = d
	return r


static func from_dict(d: Dictionary) -> TrainRoute:
	var r := TrainRoute.new()
	r.data = d
	return r


func route_name() -> String:
	return str(data.get("name", path.get_file()))


func origin() -> Vector3:
	var o: Array = data.get("origin", [0, 0, 0])
	return Vector3(o[0], o[1], o[2])


func heading() -> float:
	return float(data.get("heading", 0.0))


## The plan as TrackLine segments ({length, k0, k1}; curvature + to the left).
func segments() -> Array:
	var segs := []
	var so_far := 0.0
	for item: Dictionary in data.get("plan", []):
		if item.has("straight"):
			segs.append({"length": float(item.straight), "k0": 0.0, "k1": 0.0})
			so_far += float(item.straight)
		elif item.has("straight_to"):
			var l := maxf(0.0, float(item.straight_to) - so_far)
			if l > 0.0:
				segs.append({"length": l, "k0": 0.0, "k1": 0.0})
				so_far += l
		elif item.has("bend"):
			var b: Dictionary = item.bend
			var k := 1.0 / float(b.radius) * (1.0 if str(b.get("side", "left")) == "left" else -1.0)
			var sp := float(b.get("spirals", 0.0))
			var turn := deg_to_rad(float(b.turn))
			# The two spirals turn sp*|k| between them; the arc the rest.
			var arc := (turn - sp * absf(k)) / absf(k)
			if arc < 0.0:
				push_error("TrainRoute: a bend's spirals turn more than the bend (%s)" % [b])
				arc = 0.0
			if sp > 0.0:
				segs.append({"length": sp, "k0": 0.0, "k1": k})
			segs.append({"length": arc, "k0": k, "k1": k})
			if sp > 0.0:
				segs.append({"length": sp, "k0": k, "k1": 0.0})
			so_far += arc + 2.0 * sp
	return segs


## The profile as TrackLine grades ([[s, rise over run], ...]).
func grades() -> Array:
	var p: Dictionary = data.get("profile", {})
	var out := []
	for g: Array in p.get("grades", [[0, 0]]):
		out.append([float(g[0]), float(g[1]) / 100.0])
	return out


func vertical_curve() -> float:
	return float((data.get("profile", {}) as Dictionary).get("vertical_curve", 60.0))


## Named marks: name -> metres along the line as laid.
func marks() -> Dictionary:
	var out := {}
	var m: Dictionary = data.get("marks", {})
	for k in m:
		out[String(k)] = float(m[k])
	return out


## The line laid out (not drawn): a TrackLine with its marks along the drawn curve.
func make_line(t: TrainTuning) -> TrackLine:
	var line := TrackLine.new()
	line.name = "TrainLine"
	line.tuning = t
	line.segments = segments()
	line.grades = grades()
	line.vertical_curve = vertical_curve()
	line.start_height = float(data.get("height", t.ballast_depth + t.tie_size.y + t.rail_size.y + 0.25))
	line.lay_out()
	var ms := {}
	var m := marks()
	for k in m:
		ms[k] = line.along(float(m[k]))
	line.marks = ms
	return line
