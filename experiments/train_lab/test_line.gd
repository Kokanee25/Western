extends RefCounted
## The train lab's test line (issue #543): ~1.5 km laid out south and then east of town, on the
## flat (config/town.json's ground is level there), clear of the hills to the north:
##
##   s 0-400      straight, level, south (+Z): mark A (the depot) at 120
##   s 400-648    a left-hand bend of 120 m radius, 90 degrees in all, eased in and out by
##                30 m spirals, so the line turns east (+X)
##   s 750-1050   the climb, 2.5 % (7.5 m up on a fill), eased over 60 m at each change
##   s 1050-1350  the descent, 2.5 %
##   s 1350-1500  level: mark B (the mine) at 1440, the end of the line at 1500
##
##   var line: TrackLine = load("res://experiments/train_lab/test_line.gd").make(tuning)
##   load("res://experiments/train_lab/test_line.gd").build(street, tuning)  # drawn, with its train

## Where the line starts in the street's space, and its rail top above the ground.
const ORIGIN := Vector3(60.0, 0.0, 80.0)
const HEADING := 180.0  # degrees from north: south
const RADIUS := 120.0
const SPIRAL := 30.0
const MARKS := {"A": 120.0, "B": 1440.0}
## Lab scenarios: the level straight, the climb's foot and crest.
const CLIMB := [750.0, 1050.0]
const DESCENT := [1050.0, 1350.0]


static func make(t: TrainTuning) -> TrackLine:
	var line := TrackLine.new()
	line.name = "TrainLabLine"
	line.tuning = t
	var k := 1.0 / RADIUS
	var arc := (PI * 0.5 - SPIRAL * k) / k  # two spirals turn SPIRAL*k between them
	var segs := [
		{"length": 400.0, "k0": 0.0, "k1": 0.0},
		{"length": SPIRAL, "k0": 0.0, "k1": k},
		{"length": arc, "k0": k, "k1": k},
		{"length": SPIRAL, "k0": k, "k1": 0.0},
	]
	var so_far := 0.0
	for s in segs:
		so_far += float(s.length)
	segs.append({"length": 1500.0 - so_far, "k0": 0.0, "k1": 0.0})
	line.segments = segs
	line.grades = [[0.0, 0.0], [CLIMB[0], 0.025], [CLIMB[1], -0.025], [DESCENT[1], 0.0]]
	line.vertical_curve = 60.0
	line.marks = MARKS
	line.start_height = t.ballast_depth + t.tie_size.y + t.rail_size.y + 0.25
	line.lay_out()
	return line


## The line drawn in the street, its own ground under it past the game's drawn ground, and a
## train standing at mark A. Returns the TrackLine (its Train is `line.get_node("Train")`).
static func build(parent: Node3D, t: TrainTuning) -> TrackLine:
	var old := parent.get_node_or_null(^"TrainLabLine")
	if old:
		old.free()
	var line := make(t)
	line.position = ORIGIN
	line.rotation_degrees.y = 360.0 - HEADING
	parent.add_child(line)
	line.build()
	var ground := MeshInstance3D.new()
	ground.name = "LabGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1400.0, 1400.0)
	ground.mesh = plane
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.40, 0.32, 0.22)
	m.roughness = 1.0
	ground.material_override = m
	parent.add_child(ground)
	ground.global_position = line.to_global(Vector3(-450.0, 0.0, -450.0)) * Vector3(1, 0, 1) + Vector3.UP * -0.03
	# The painted country is rings 260-650 m round the town; the line runs out through them, so
	# while the lab's here they're hidden (the flat desert out to the sky).
	for b in parent.find_children("Backdrop", "", true, false):
		(b as Node3D).visible = false
	var train := Train.new()
	train.name = "Train"
	line.add_child(train)
	train.setup(line, t)
	train.place(float(MARKS.A))
	return line
