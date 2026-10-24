class_name Moment
extends Node
## A showcase moment (docs/briefs/showcase-moments.md): a situation set up from data
## (`config/moments/<name>.json`: who, where, when) and played out by the systems, so it can go
## differently each time and the player can break it. Started from the dev bridge (`moment NAME
## [key=value...]`, then `moment_result`) or at launch with `-- --moment=NAME`. Each moment is a
## script named in its data (`script`), extending this; its `result()` says what happened.

signal finished(moment: Moment)

var moment_name: StringName
var data := {}
var street: Node3D
var town: TownLife
var opts := {}
var state := &"setup"
var t := 0.0  ## game seconds since it started
var done := false


## Read `config/moments/<name>.json`, make its script's node under `street` and start it.
static func start_named(n: StringName, street_node: Node3D, town_node: TownLife, options := {}) -> Moment:
	var path := "res://config/moments/%s.json" % n
	if not FileAccess.file_exists(path):
		push_warning("Moment: no config/moments/%s.json" % n)
		return null
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary or not (d as Dictionary).has("script"):
		push_warning("Moment: %s isn't a moment (no script)" % path)
		return null
	var script: GDScript = load(d.script)
	if script == null:
		return null
	var m: Moment = script.new()
	m.moment_name = n
	m.name = "Moment_%s" % n
	m.data = d
	m.street = street_node
	m.town = town_node
	m.opts = options
	street_node.add_child(m)
	m.begin()
	return m


## At launch with `-- --moment=NAME`: the moment starts once the town's in (a couple of seconds).
static func maybe_start(main_node: Node) -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--moment="):
			var n := StringName(a.get_slice("=", 1))
			var street_node := main_node.find_child("TestStreet", true, false) as Node3D
			if street_node == null:
				return
			var timer := main_node.get_tree().create_timer(2.0)
			timer.timeout.connect(func() -> void:
				Moment.start_named(n, street_node, street_node.get_node_or_null(^"TownLife") as TownLife))


## Set the scene up (people placed, the clock set): the first beat starts in the next tick.
func begin() -> void:
	pass


## What happened, for the bridge and the runs (filled in by each moment).
func result() -> Dictionary:
	return {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done}


## Take back what it put in the world (its people, its props), so it can run again.
func reset() -> void:
	queue_free()


func _finish(final_state: StringName) -> void:
	if done:
		return
	state = final_state
	done = true
	finished.emit(self)


## The places by name (the town's, else the test street's).
func places() -> Waypoints:
	return town.places if town != null else Waypoints.test_street()


## A point from the data: a place's name, else [x, y, z].
func point(name_key: String, point_key: String, d: Dictionary) -> Vector3:
	if d.has(name_key) and places().has(StringName(d[name_key])):
		return places().at(StringName(d[name_key]))
	var p: Array = d.get(point_key, [0, 0, 0])
	return Vector3(p[0], p[1], p[2])


## The clock set to the data's hour (`hour`, or the option), held there.
func set_hour() -> void:
	var hour := float(opts.get("hour", data.get("hour", -1.0)))
	if hour < 0.0:
		return
	var clock := street.find_child("DayCycle", true, false) as DayCycle
	if clock != null:
		clock.set_time(hour)
