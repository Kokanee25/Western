extends TestCase
## The bug-report key (BugRecorder, F12) and its replay (tools/replay.gd): a few seconds of play
## (walk, turn, draw), the report saved as one file with everything in it, and the replay, in a
## Godot of its own, ends up where the play did.

var main: Node


func before_each() -> void:
	Settings.autosave = false
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await physics_frames(3)


func after_each() -> void:
	main.queue_free()
	await physics_frames(3)


func _key(action: StringName, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _play() -> void:
	_key(&"move_forward", true)
	await physics_frames(60)
	Events.look_input.emit(Vector2(30.0, -5.0))
	await physics_frames(40)
	_key(&"move_forward", false)
	_key(&"holster", true)
	await physics_frames(3)
	_key(&"holster", false)
	await physics_frames(60)


func test_f12_saves_everything_in_one_file() -> void:
	var recorder := main.get_node(^"BugRecorder") as BugRecorder
	check(recorder != null, "the game always has a recorder")
	await _play()
	var path: String = await recorder.save()
	check(path != "" and FileAccess.file_exists(path), "the report is written (%s)" % path)
	var zip := ZIPReader.new()
	check_eq(zip.open(path), OK, "it's one zip")
	var names := zip.get_files()
	for n in ["report.json", "recording.json"]:
		check(names.has(n), "with %s in it (%s)" % [n, names])
	var report: Dictionary = JSON.parse_string(zip.read_file("report.json").get_string_from_utf8())
	check(report.has("build") and report.has("player") and report.has("people") and report.has("settings"), "the build, you, everyone, the settings")
	var rec: Dictionary = JSON.parse_string(zip.read_file("recording.json").get_string_from_utf8())
	check_eq(rec.from, "start", "a short session replays from the start")
	var moves := (rec.inputs as Array).filter(func(e: Array) -> bool: return rec.actions[int(e[1])] == "move_forward")
	check_eq(moves.size(), 2, "the walk's press and release are in it")
	check(not (rec.looks as Array).is_empty(), "and the turn")
	zip.close()
	DirAccess.remove_absolute(path)


func test_the_replay_ends_where_the_play_did() -> void:
	var recorder := main.get_node(^"BugRecorder") as BugRecorder
	await _play()
	var player := main.find_child("Player", true, false) as Player
	var played_to := player.global_position
	check(played_to.distance_to(Vector3(11.0, 0.0, -9.0)) > 1.0, "the play went somewhere (%s)" % played_to)
	var path: String = await recorder.save()
	var out := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--fixed-fps", "60", "--path",
			ProjectSettings.globalize_path("res://"), "-s", "res://tools/replay.gd", "--",
			ProjectSettings.globalize_path(path)], out, true)
	var text := "\n".join(out)
	var said := Array(text.split("\n")).filter(func(l: String) -> bool: return l.begins_with("replay") or l.contains("went differently"))
	check_eq(code, 0, "the replay matches the play: %s" % "; ".join(PackedStringArray(said)))
	check(text.contains("replay matched"), "and says so")
	var m := RegEx.create_from_string("(\\d+) checkpoints").search(text)
	check(m != null and int(m.get_string(1)) >= 3, "having compared everyone's place each second (%s)" % (m.get_string(1) if m else "none"))
	DirAccess.remove_absolute(path)
