extends RefCounted
## The trestle lab's line (#623): `routes/gorge.json` (1.3 km laid east, 2.6 km east of town, the
## viaduct its crossing "gorge") with its gorge cut to fit (gorge.gd), and the train.
##
##   var line := LAB_LINE.make(tuning)            # laid out, the gorge's ground set, not built
##   LAB_LINE.build(parent, tuning)               # built: the line, the viaduct, the gorge, a train
##
## Nothing in the town changes.

const ROUTE := "res://experiments/trestle_lab/routes/gorge.json"
const GORGE := preload("res://experiments/trestle_lab/gorge.gd")


static func route(file := ROUTE) -> TrainRoute:
	return TrainRoute.load_file(file)


## Laid out with its gorge's ground (`line.get_meta("gorge")`), not built.
static func make(t: TrainTuning, file := ROUTE, tune: TrestleTuning = null) -> TrackLine:
	var r := route(file)
	var line := r.make_line(t)
	line.name = "TrestleLabLine"
	line.trestle_tuning = tune
	var g = GORGE.new(line, r.data.get("gorge", {}))
	line.ground_y = g.height
	line.set_meta(&"gorge", g)
	line.position = r.origin()
	line.rotation_degrees.y = 360.0 - r.heading()
	return line


## Built under `parent`: the line and viaduct, the gorge's ground, and a train at `at` (a mark).
static func build(parent: Node3D, t: TrainTuning, file := ROUTE, tune: TrestleTuning = null, at := "start", with_train := true) -> TrackLine:
	var old := parent.get_node_or_null(^"TrestleLabLine")
	if old:
		old.free()
	var line := make(t, file, tune)
	parent.add_child(line)
	line.build()
	var g = line.get_meta(&"gorge")
	line.add_child(g.build())
	for b in parent.find_children("Backdrop", "", true, false):
		(b as Node3D).visible = false
	# The sight world takes new bodies at the first look after they're added: the viaduct's
	# 7,700 members and the gorge's ground were ~300 ms on the first look after a charge (the
	# engineer's). Taken now, at the build, as the game's buildings are at load.
	var mid := line.to_global(line.point_at(line.length * 0.5))
	Sight.see(line, mid + Vector3.UP * 3.0, mid + Vector3.UP * 4.0)
	if with_train:
		var train := Train.new()
		train.name = "Train"
		line.add_child(train)
		train.setup(line, t)
		train.place(line.mark_s(at))
	return line
