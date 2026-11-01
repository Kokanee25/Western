extends RefCounted
## The train lab's lines (issue #543; data since step 2, #551): each a route file in `routes/`
## (TrackRoute's format), laid out on the flat round town. `test_line.json` is step 1's line:
##
##   s 0-400      straight, level, south (+Z): the depot's mark at 120
##   s 400-648    a left-hand bend of 120 m radius, 90 degrees in all, eased in and out by
##                30 m spirals, so the line turns east (+X)
##   s 750-1050   the climb, 2.5 % (7.5 m up on a fill), eased over 60 m at each change
##   s 1050-1350  the descent, 2.5 %
##   s 1350-1500  level: the mine's mark at 1440, the end of the line at 1500
##
## `relaid.json` is a different line for the re-laying test (2.3 km, an S, a water tank stop, a 3 %
## climb to the mine). Nothing here knows either line's numbers: they come from the files.
##
##   var line: TrackLine = load("res://experiments/train_lab/test_line.gd").make(tuning)
##   load("res://experiments/train_lab/test_line.gd").build(street, tuning)  # drawn, with its train

const ROUTE := "res://experiments/train_lab/routes/test_line.json"
const ROUTES := "res://experiments/train_lab/routes/"
const TIMETABLES := "res://experiments/train_lab/timetables/"


## A route by name (`test_line`, `relaid`) or path.
static func route(which := ROUTE) -> Dictionary:
	return TrackRoute.read(which if which.begins_with("res://") else ROUTES + which + ".json")


## The route's timetable data (timetables/<route>.json).
static func timetable_data(route_name: String) -> Dictionary:
	return Timetable.read(TIMETABLES + route_name + ".json")


static func make(t: TrainTuning, which := ROUTE) -> TrackLine:
	return TrackRoute.make_line(route(which), t)


## The line drawn in the street, its own ground under it past the game's drawn ground, and a
## train standing at its first stop. Returns the TrackLine (its Train is `line.get_node("Train")`).
static func build(parent: Node3D, t: TrainTuning, which := ROUTE) -> TrackLine:
	var old := parent.get_node_or_null(^"TrainLabLine")
	if old:
		old.free()
	var old_ground := parent.get_node_or_null(^"LabGround")
	if old_ground:
		old_ground.free()
	var r := route(which)
	var line := TrackRoute.make_line(r, t)
	TrackRoute.place(line, r)
	parent.add_child(line)
	line.build()
	# Flat desert under the whole line (a margin round it).
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var at := 0.0
	while at <= line.length:
		var p := line.to_global(line.point_at(at))
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
		at += 20.0
	var ground := MeshInstance3D.new()
	ground.name = "LabGround"
	var plane := PlaneMesh.new()
	plane.size = (hi - lo) + Vector2(500.0, 500.0)
	ground.mesh = plane
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.40, 0.32, 0.22)
	m.roughness = 1.0
	ground.material_override = m
	parent.add_child(ground)
	var mid := (lo + hi) * 0.5
	ground.global_position = Vector3(mid.x, -0.03, mid.y)
	# The painted country is rings 260-650 m round the town; the line runs out through them, so
	# while the lab's here they're hidden (the flat desert out to the sky).
	for b in parent.find_children("Backdrop", "", true, false):
		(b as Node3D).visible = false
	var train := Train.new()
	train.name = "Train"
	line.add_child(train)
	train.setup(line, t)
	train.place(float(line.marks[line.stops[0]]) if not line.stops.is_empty() else t.consist.size() * 12.0)
	return line
