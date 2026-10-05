class_name BugRecorder
extends Node
## The bug-report key (docs/briefs/automated-checks.md, item 1). Always listening, cheaply: every
## physics tick it notes which actions changed (keys, buttons, sticks, as strengths) and how far the
## mouse turned the view, and every second where everyone is. F12 writes one file,
## user://bug_reports/<date-time>.saltbug (a zip): the screenshot, the recording, the game's log,
## the build, where you are and what you're holding, the settings, what's been happening.
## `tools/replay.gd FILE` plays the recording back and says where the game went differently.
##
## A session under REPLAY_FROM_START minutes is replayed from the start (the most faithful: the
## same scene, the same seeds, every input since); a longer one from a snapshot of where everyone
## was 30 s before the report (people put back where they stood, which is close but not exact).

const DIR := "user://bug_reports"
const REPLAY_FROM_START := 20.0
const KEEP_SECONDS := 30.0
const CHECK_EVERY := 60  # ticks between position checkpoints
## Actions that aren't play (menus) aren't recorded.
const SKIP_PREFIX := ["ui_"]

var _actions: Array[StringName] = []
var _strength := PackedFloat32Array()
var _start_tick := 0
## [tick, action index, strength] whenever an action changes.
var _inputs: Array = []
## [tick, dx, dy] mouse/touch look, summed per tick.
var _looks: Array = []
var _look_acc := Vector2.ZERO
## [tick, {path: [x, y, z, yaw]}] every CHECK_EVERY ticks.
var _checks: Array = []
## Snapshots of where everyone is, every KEEP_SECONDS (the last two kept).
var _snapshots: Array = []
var _events: Array = []
var _toast_left := 0.0
var _toast: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in InputMap.get_actions():
		if not SKIP_PREFIX.any(func(p: String) -> bool: return String(a).begins_with(p)):
			_actions.append(a)
	_actions.sort()
	_strength.resize(_actions.size())
	_start_tick = Engine.get_physics_frames()
	Events.look_input.connect(func(d: Vector2) -> void: _look_acc += d)
	_listen()
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_toast = Label.new()
	_toast.position = Vector2(16, 16)
	_toast.modulate = Color(1.0, 0.85, 0.5)
	_toast.visible = false
	layer.add_child(_toast)


func _physics_process(_delta: float) -> void:
	var tick := Engine.get_physics_frames() - _start_tick
	for i in _actions.size():
		var s := snappedf(Input.get_action_strength(_actions[i]), 0.01)
		if s != _strength[i]:
			_strength[i] = s
			_inputs.append([tick, i, s])
	if _look_acc != Vector2.ZERO:
		_looks.append([tick, snappedf(_look_acc.x, 0.001), snappedf(_look_acc.y, 0.001)])
		_look_acc = Vector2.ZERO
	if tick % CHECK_EVERY == 0:
		_checks.append([tick, positions(get_tree())])
	if tick % int(KEEP_SECONDS * Engine.physics_ticks_per_second) == 0:
		var snap := snapshot(get_tree(), tick)
		snap[&"held"] = Array(_strength)
		_snapshots.append(snap)
		if _snapshots.size() > 2:
			_snapshots.pop_front()
	_trim(tick)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"bug_report") or (event is InputEventJoypadButton and event.pressed
			and (event as InputEventJoypadButton).button_index == JOY_BUTTON_Y and Input.is_joy_button_pressed(event.device, JOY_BUTTON_BACK)):
		save()


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0


## Past REPLAY_FROM_START minutes only the last KEEP_SECONDS (and the snapshot before them) are kept.
func _trim(tick: int) -> void:
	var tps := Engine.physics_ticks_per_second
	if tick < REPLAY_FROM_START * 60.0 * tps or tick % tps != 0:
		return
	var from: int = _snapshots[0][&"tick"] if not _snapshots.is_empty() else tick - int(KEEP_SECONDS * tps)
	_inputs = _inputs.filter(func(e: Array) -> bool: return e[0] >= from)
	_looks = _looks.filter(func(e: Array) -> bool: return e[0] >= from)
	_checks = _checks.filter(func(e: Array) -> bool: return e[0] >= from)


## Write the report. Returns its path.
func save() -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/%s.saltbug" % [DIR, stamp]
	var shot: Image = null
	if DisplayServer.get_name() != "headless":  # headless, nothing is drawn (and no frame is posted)
		await RenderingServer.frame_post_draw
		shot = get_viewport().get_texture().get_image()
	var tick := Engine.get_physics_frames() - _start_tick
	var long := tick > REPLAY_FROM_START * 60.0 * Engine.physics_ticks_per_second
	var recording := {
		"tick": tick, "ticks_per_second": Engine.physics_ticks_per_second,
		"actions": _actions.map(func(a: StringName) -> String: return String(a)),
		"from": "start" if not long else "snapshot",
		"snapshot": _snapshots[0] if long and not _snapshots.is_empty() else {},
		"inputs": _inputs, "looks": _looks, "checks": _checks,
	}
	var zip := ZIPPacker.new()
	if zip.open(ProjectSettings.globalize_path(path)) != OK:
		_say("couldn't write %s" % path)
		return ""
	_put(zip, "report.json", JSON.stringify(report(get_tree(), tick, _events), "  "))
	_put(zip, "recording.json", JSON.stringify(recording))
	var log_path := "user://logs/godot.log"
	if FileAccess.file_exists(log_path):
		_put(zip, "godot.log", FileAccess.get_file_as_string(log_path))
	if shot:
		zip.start_file("screenshot.png")
		zip.write_file(shot.save_png_to_buffer())
		zip.close_file()
	zip.close()
	_say("Bug report saved: %s" % ProjectSettings.globalize_path(path))
	print("[bug report] %s" % ProjectSettings.globalize_path(path))
	return path


static func _put(zip: ZIPPacker, name: String, text: String) -> void:
	zip.start_file(name)
	zip.write_file(text.to_utf8_buffer())
	zip.close_file()


func _say(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_left = 6.0


# -- What goes in it -------------------------------------------------------------------------------

## The build, the clock, you, everyone near, the settings and what's been happening.
static func report(tree: SceneTree, tick: int, events: Array) -> Dictionary:
	var player := tree.get_first_node_in_group(&"player") as Player
	var clock := tree.root.find_child("DayCycle", true, false) as DayCycle
	var settings := tree.root.get_node_or_null(^"Settings")
	var out := {
		"build": load("res://src/debug/debug_overlay.gd").build_label(), "engine": Engine.get_version_info().string,
		"os": OS.get_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"video": RenderingServer.get_video_adapter_name(), "game_seconds": snappedf(float(tick) / Engine.physics_ticks_per_second, 0.01),
		"clock": clock.get_clock_text() if clock else "", "fps": Engine.get_frames_per_second(),
		"events": events,
	}
	if player:
		out["player"] = {"at": _arr(player.global_position), "yaw": snappedf(rad_to_deg(player.rotation.y), 0.1),
			"pitch": snappedf(player.get_pitch_degrees(), 0.1),
			"weapon": String(player.weapon.name) if player.weapon else "none",
			"health": player.wounds.physiology.describe() if player.wounds and player.wounds.physiology else ""}
	if settings:
		out["settings"] = {"internal_resolution": str(settings.internal_resolution), "mosaic": settings.mosaic,
			"quantise_once": settings.quantise_once, "tile_look": String(settings.tile_look),
			"texels_per_meter": settings.texels_per_meter, "reduced_gore": settings.reduced_gore}
	var people := []
	for n in tree.get_nodes_in_group(&"people"):
		var man := n as HumanBody
		if man and man.physiology:
			people.append({"name": String(man.person_id), "at": _arr(man.global_position),
				"alive": man.physiology.alive, "how": man.physiology.describe()})
	out["people"] = people
	return out


## Where everyone is (the player and each person by their path in the street): [x, y, z, yaw].
static func positions(tree: SceneTree) -> Dictionary:
	var out := {}
	var street := street_of(tree)
	var player := tree.get_first_node_in_group(&"player") as Node3D
	if player:
		out["player"] = _pose(player)
	for n in tree.get_nodes_in_group(&"people"):
		if n is Node3D and (n as Node).is_inside_tree() and street and street.is_ancestor_of(n):
			out[String(street.get_path_to(n))] = _pose(n)
	return out


static func street_of(tree: SceneTree) -> Node:
	return tree.root.find_child("TestStreet", true, false)


## Enough to put the world back roughly as it was: the clock and everyone's place.
static func snapshot(tree: SceneTree, tick: int) -> Dictionary:
	var clock := tree.root.find_child("DayCycle", true, false) as DayCycle
	var player := tree.get_first_node_in_group(&"player") as Player
	return {&"tick": tick, &"hour": clock.time_of_day if clock else 12.0, &"positions": positions(tree),
		&"pitch": player.get_pitch_degrees() if player else 0.0}


static func _pose(n: Node3D) -> Array:
	var p := n.global_position
	return [snappedf(p.x, 0.001), snappedf(p.y, 0.001), snappedf(p.z, 0.001), snappedf(n.rotation.y, 0.0001)]


static func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]


func _listen() -> void:
	var note := func(kind: String, text: String) -> void:
		_events.append({"t": snappedf(float(Engine.get_physics_frames() - _start_tick) / Engine.physics_ticks_per_second, 0.1),
			"kind": kind, "text": text})
		if _events.size() > 80:
			_events.pop_front()
	var who := func(n: Variant) -> String:
		if n == null or not is_instance_valid(n):
			return "someone"
		if (n as Node).is_in_group(&"player"):
			return "you"
		return String(n.person_id) if n is HumanBody else String((n as Node).name)
	Events.spoke.connect(func(w: Node, text: String) -> void: note.call("said", "%s: %s" % [who.call(w), text]))
	Events.shot_fired.connect(func(_o: Vector3, _d: Vector3, s: Node) -> void: note.call("shot", "%s fired" % who.call(s)))
	Events.body_hit.connect(func(info: Dictionary) -> void: note.call("hit", "%s hit (%s)" % [who.call(info.get("person")), info.get("segment", "?")]))
	Events.person_died.connect(func(p: Node, cause: StringName) -> void: note.call("died", "%s died (%s)" % [who.call(p), cause]))
	Events.exploded.connect(func(at: Vector3, kg: float) -> void: note.call("blast", "%.2f kg at %s" % [kg, _arr(at)]))
