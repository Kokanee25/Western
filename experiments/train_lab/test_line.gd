extends RefCounted
## The train lab's lines (issues #543, #551). Since step 2 a line is a route file (TrainRoute):
## `routes/test_line.json` is step 1's line (1.5 km south then east of town: a 400 m straight, a
## 120 m bend, 2.5 % up and down; the depot at 120, the mine at 1440), `routes/relaid.json` the
## re-laid one the route-moves test runs. Every place on a line is a named mark.
##
##   var line: TrackLine = load("res://experiments/train_lab/test_line.gd").make(tuning)
##   load("res://experiments/train_lab/test_line.gd").build(street, tuning)  # drawn, with its train

const ROUTE := "res://experiments/train_lab/routes/test_line.json"
const RELAID := "res://experiments/train_lab/routes/relaid.json"


static func route(file := ROUTE) -> TrainRoute:
	return TrainRoute.load_file(file)


static func make(t: TrainTuning, file := ROUTE) -> TrackLine:
	var line := route(file).make_line(t)
	line.name = "TrainLabLine"
	return line


## The line drawn in the street, its own ground under it past the game's drawn ground, and a
## train standing at the depot. Returns the TrackLine (its Train is `line.get_node("Train")`).
static func build(parent: Node3D, t: TrainTuning, file := ROUTE) -> TrackLine:
	var old := parent.get_node_or_null(^"TrainLabLine")
	if old:
		old.free()
	var r := route(file)
	var line := r.make_line(t)
	line.name = "TrainLabLine"
	line.position = r.origin()
	line.rotation_degrees.y = 360.0 - r.heading()
	parent.add_child(line)
	line.build()
	var ground := MeshInstance3D.new()
	ground.name = "LabGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1600.0, 1600.0)
	ground.mesh = plane
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.40, 0.32, 0.22)
	m.roughness = 1.0
	ground.material_override = m
	line.add_child(ground)
	# Under the line's middle, a hair below the game's ground (the line's node sits on the ground).
	var mid := line.point_at(line.length * 0.5)
	ground.position = Vector3(mid.x, -0.03, mid.z)
	# The painted country is rings 260-650 m round the town; the line runs out through them, so
	# while the lab's here they're hidden (the flat desert out to the sky).
	for b in parent.find_children("Backdrop", "", true, false):
		(b as Node3D).visible = false
	var train := Train.new()
	train.name = "Train"
	line.add_child(train)
	train.setup(line, t)
	train.place(line.mark_s("depot"))
	return line
