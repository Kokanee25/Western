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


## F12's frame timing (PerfRing, #433): with F3 closed the ring has every frame's split and no
## systems; with F3 up (the profiler on) each frame carries its biggest systems, and the summary
## at the top of report.json names the three biggest.
func test_f12_carries_the_frames_numbers() -> void:
	var recorder := main.get_node(^"BugRecorder") as BugRecorder
	await process_frames(30)
	var perf := await _press_f12(recorder)
	for k in ["frames_columns", "frames", "seconds_columns", "seconds", "recorder_us"]:
		check(perf.has(k), "perf.json has %s" % k)
	var cols: Array = perf.frames_columns
	for f in PerfRing.FIELDS:
		check(cols.has(f), "a frame has %s" % f)
	check((perf.frames as Array).size() >= 20, "every frame is in it (%d)" % (perf.frames as Array).size())
	var row: Array = perf.frames[-1]
	check_eq(row.size(), cols.size(), "a row is its columns")
	check(float(row[cols.find("frame_ms")]) > 0.0 and float(row[cols.find("nodes")]) > 100.0, "with the frame's time and the nodes (%s)" % [row])
	check((row[-1] as Dictionary).is_empty(), "and no systems with F3 closed")
	check(not (perf.seconds as Array).is_empty(), "the per-second ring has this second at least")
	check(float(perf.recorder_us.f3_closed.mean) < 100.0, "the recorder takes under 0.1 ms a frame (%.1f µs)" % float(perf.recorder_us.f3_closed.mean))
	_key(&"debug_overlay", true)  # F3: the profiler on
	await process_frames(2)
	_key(&"debug_overlay", false)
	await process_frames(60)
	check(Prof.on, "F3 turns the profiler on")
	perf = await _press_f12(recorder)
	_key(&"debug_overlay", true)  # F3 again: off
	await process_frames(2)
	_key(&"debug_overlay", false)
	await process_frames(1)
	check(not Prof.on, "and F3 again turns it off")
	var named := (perf.frames as Array).filter(func(r: Array) -> bool: return not (r[-1] as Dictionary).is_empty())
	check(named.size() >= 30, "with F3 up the frames name their systems (%d)" % named.size())
	var zip := ZIPReader.new()
	zip.open(_last)
	var text := zip.read_file("report.json").get_string_from_utf8()
	zip.close()
	check(text.strip_edges().begins_with("{\n  \"perf_summary\""), "perf_summary leads report.json")
	var s: Dictionary = JSON.parse_string(text).perf_summary
	check(s.has("worst") and s.has("mean_ms") and float(s.worst.frame_ms) >= float(s.mean_ms), "the worst frame and the mean (%s)" % [s.get("worst")])
	check_eq((s.biggest as Array).size(), 3, "and the three biggest named costs (%s)" % [s.biggest])
	check(not (s.biggest as Array).any(func(b: Dictionary) -> bool: return String(b.name).begins_with("q_") or String(b.name).begins_with("n_")), "costs, not counts")
	check(PerfRing.summary_lines(s).size() >= 3, "which the replay prints")
	DirAccess.remove_absolute(_last)


var _last := ""


## Press F12 (the action, as the key would) and read the report's perf.json.
func _press_f12(recorder: BugRecorder) -> Dictionary:
	var before := recorder.last_path
	_key(&"bug_report", true)
	await process_frames(2)
	_key(&"bug_report", false)
	await process_frames(1)
	check(recorder.last_path != "" and recorder.last_path != before, "F12 writes a report")
	if _last != "" and _last != recorder.last_path:
		DirAccess.remove_absolute(_last)
	_last = recorder.last_path
	var zip := ZIPReader.new()
	if not check_eq(zip.open(_last), OK, "it's one zip"):
		return {}
	check(zip.file_exists("perf.json"), "with perf.json in it")
	var perf: Variant = JSON.parse_string(zip.read_file("perf.json").get_string_from_utf8())
	zip.close()
	return perf if perf is Dictionary else {}
