extends SceneTree
## Plays a bug report back (src/debug/bug_recorder.gd, F12 in game): the same scene, every key,
## button, stick and mouse turn on the tick it happened, and says where the game went differently
## from the recording (everyone's place each second). Headless is quickest; drawn, it saves the last
## frame beside the report's own screenshot.
##
##   godot --headless --fixed-fps 60 -s res://tools/replay.gd -- FILE.saltbug
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://tools/replay.gd -- FILE.saltbug --out=DIR
##
## Exit code 0 when it stayed within DRIFT_M of the recording all the way, 1 otherwise. A report
## from a long session replays from the snapshot 30 s before (people put back where they were), so
## expect more drift from those. --drift=M changes the line.

const DRIFT_M := 0.25

var _rec: Dictionary
var _report: Dictionary
var _shot := PackedByteArray()
var _main: Node
var _offset := 0  # recording tick = recorder tick + _offset
var _recorder: Node
var _inputs: Array
var _looks: Array
var _checks: Array
var _actions: Array
var _ii := 0
var _li := 0
var _ci := 0
var _worst := 0.0
var _worst_at := ""
var _first_off := -1.0
var _limit := DRIFT_M
var _out := ""


func _initialize() -> void:
	var file := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--drift="):
			_limit = float(a.substr(8))
		elif not a.begins_with("--"):
			file = a
	if file == "" or not _read(file):
		printerr("replay: give it a .saltbug file (%s)" % file)
		quit(2)
		return
	print("replaying %s: %s, %.1f s of play, from the %s" % [file.get_file(), _report.get("build", "?"),
			float(_rec.tick) / float(_rec.ticks_per_second), _rec.from])
	if String(_report.get("build", "")) != load("res://src/debug/debug_overlay.gd").build_label():
		print("  note: recorded on %s, replaying on %s" % [_report.get("build"), load("res://src/debug/debug_overlay.gd").build_label()])
	root.get_node(^"Settings").autosave = false
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_recorder = _main.get_node(^"BugRecorder")
	var player = _main.find_child("Player", true, false)
	for w in player.weapons:
		w.needs_captured_mouse = false
	_actions = _rec.actions
	_inputs = _rec.inputs
	_looks = _rec.looks
	_checks = _rec.checks
	if _rec.from == "snapshot":
		_restore(_rec.snapshot)
	_offset = int(_rec.get("snapshot", {}).get("tick", 0)) - _now()
	physics_frame.connect(_tick)


func _read(path: String) -> bool:
	var zip := ZIPReader.new()
	if zip.open(path) != OK:
		return false
	_rec = JSON.parse_string(zip.read_file("recording.json").get_string_from_utf8())
	_report = JSON.parse_string(zip.read_file("report.json").get_string_from_utf8())
	if zip.file_exists("screenshot.png"):
		_shot = zip.read_file("screenshot.png")
	zip.close()
	return _rec is Dictionary and _report is Dictionary


func _now() -> int:
	return Engine.get_physics_frames() - int(_recorder._start_tick)


## Put the clock and everyone where the snapshot had them, and press what was held.
func _restore(snap: Dictionary) -> void:
	var clock = _main.find_child("DayCycle", true, false)
	clock.set_time(float(snap.hour))
	var places: Dictionary = snap.positions
	for path: String in places:
		var street: Node = _main.find_child("TestStreet", true, false)
		var n: Node3D = _main.find_child("Player", true, false) if path == "player" else street.get_node_or_null(NodePath(path))
		if n:
			var p: Array = places[path]
			n.global_position = Vector3(p[0], p[1], p[2])
			n.rotation.y = p[3]
	var held: Array = snap.get("held", [])
	for i in held.size():
		if float(held[i]) > 0.0:
			_act(String(_actions[i]), float(held[i]))


func _tick() -> void:
	var t := _now() + _offset
	# Mouse turns on this tick; key changes for the next (an input event is read at the start of
	# the frame after it's sent).
	while _li < _looks.size() and int(_looks[_li][0]) <= t:
		var l: Array = _looks[_li]
		if int(l[0]) == t:
			root.get_node(^"Events").look_input.emit(Vector2(l[1], l[2]))
		_li += 1
	while _ii < _inputs.size() and int(_inputs[_ii][0]) <= t + 1:
		var e: Array = _inputs[_ii]
		_act(String(_actions[int(e[1])]), float(e[2]))
		_ii += 1
	while _ci < _checks.size() and int(_checks[_ci][0]) < t:
		_compare(_checks[_ci])
		_ci += 1
	if t >= int(_rec.tick):
		physics_frame.disconnect(_tick)
		_finish()


func _act(action: String, strength: float) -> void:
	var ev := InputEventAction.new()
	ev.action = StringName(action)
	ev.pressed = strength > 0.0
	ev.strength = strength
	Input.parse_input_event(ev)


func _compare(check: Array) -> void:
	var now: Dictionary = load("res://src/debug/bug_recorder.gd").positions(self)
	var then: Dictionary = check[1]
	for who: String in then:
		var a: Array = then[who]
		var off := 0.0
		if not now.has(who):
			off = INF
		else:
			var b: Array = now[who]
			off = Vector3(a[0], a[1], a[2]).distance_to(Vector3(b[0], b[1], b[2]))
		var secs := float(check[0]) / float(_rec.ticks_per_second)
		if off > _worst:
			_worst = off
			_worst_at = "%s at %.1f s" % [who.get_file(), secs]
		if off > _limit and _first_off < 0.0:
			_first_off = secs
			print("  went differently at %.1f s: %s %s" % [secs, who.get_file(), "is gone" if is_inf(off) else "%.2f m off" % off])


func _finish() -> void:
	var same := _first_off < 0.0
	print("replay %s: %d checkpoints, worst %s%s" % ["matched" if same else "differed", _ci,
			"%.2f m" % _worst if not is_inf(_worst) else "someone missing", " (%s)" % _worst_at if _worst_at != "" else ""])
	if _out != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_out)
		await RenderingServer.frame_post_draw  # drawn, so a frame is posted
		root.get_texture().get_image().save_png(_out.path_join("replayed.png"))
		if not _shot.is_empty():
			var f := FileAccess.open(_out.path_join("reported.png"), FileAccess.WRITE)
			f.store_buffer(_shot)
		print("  the replay's last frame and the report's screenshot are in %s" % _out)
	quit(0 if same else 1)
