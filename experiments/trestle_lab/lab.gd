extends "res://experiments/train_lab/lab.gd"
## The trestle lab in a running game (#623): the train lab's lab (its cameras, the engineer, the
## passengers, the walk along the train, the bridge's `train_*` commands all work on it), on the
## gorge line (`routes/gorge.json`, 2.6 km east of town, the viaduct its crossing) with its gorge.
## Made by the `trestle_lab` bridge command as the node "TrainLab", so the train lab's commands find it.

const LAB_LINE := preload("res://experiments/trestle_lab/lab_line.gd")

var trestle_tuning: TrestleTuning


func ensure_built() -> TrackLine:
	if line and is_instance_valid(line):
		return line
	if street == null or not is_instance_valid(street):
		street = get_tree().root.find_child("TestStreet", true, false) as Node3D
		player = get_tree().root.find_child("Player", true, false) as Player
	tuning = load("res://config/train.tres")
	line = LAB_LINE.build(street, tuning, route_file if route_file.begins_with("res://experiments/trestle_lab") else LAB_LINE.ROUTE, trestle_tuning, "start")
	route_file = LAB_LINE.ROUTE
	train = line.get_node(^"Train")
	train.rider = player
	return line


func trestle() -> Trestle:
	ensure_built()
	return line.trestles[0] if not line.trestles.is_empty() else null


## The train lab's save, and the viaduct's damage and rubble (by the crossing's name).
func save_state() -> Dictionary:
	var d := super.save_state()
	var tr := trestle()
	if tr:
		d["trestle"] = tr.save_dict()
	return d


## Built again (the line, the viaduct, the gorge) and the save put back: the viaduct's wreck first,
## then the track's damage and the train's wreck where the save had them.
func load_state(d: Dictionary, file := "") -> Dictionary:
	if line and is_instance_valid(line):
		line.free()
	line = null
	engineer = null
	engineer_body = null
	driver = &""
	ensure_built()
	await get_tree().physics_frame
	var missed_bridge := 0
	if d.has("trestle"):
		missed_bridge = trestle().restore_dict(d.trestle)
	var missed := line.state.from_dict(d.get("track", {}))
	var bodies := 0
	if d.has("wreck"):
		var w := TrainWreck.restore(train, d.wreck)
		bodies = w.bodies.size()
	return {"missed": missed, "missed_bridge": missed_bridge, "wreck_bodies": bodies}
