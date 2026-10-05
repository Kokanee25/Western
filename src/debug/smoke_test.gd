class_name SmokeTest
extends Node
## The exported builds' smoke test (docs/briefs/automated-checks.md, item 5): `-- --smoke-test` on
## any build, a release export included. 30 s of the street with things happening (the gang rides
## in, a stick goes off out of the way, a member's set alight, a shot), every engine and script
## error counted, then one line and quit: "[smoke] ok ..." with exit 0, or "[smoke] FAILED ..."
## with exit 1; `--smoke-out=FILE` writes the same lines there too (a Windows export's console
## output may not reach the shell that started it). CI runs it on each export on its own runner
## (.github/workflows/build.yml, smoke).

const SECONDS := 30.0

class Catcher:
	extends Logger
	var errors: PackedStringArray = []
	var _m := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _bt: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_m.lock()
		if errors.size() < 20:
			errors.append("%s (%s:%d in %s)" % [rationale if rationale != "" else code, file, line, function])
		_m.unlock()

var main: Node
var _catcher := Catcher.new()
var _start := 0
var _frames := 0
var _done := {}


static func maybe_start(main_node: Node) -> SmokeTest:
	if not "--smoke-test" in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		return null
	var s := SmokeTest.new()
	s.name = "SmokeTest"
	s.main = main_node
	main_node.add_child(s)
	return s


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	OS.add_logger(_catcher)
	_start = Time.get_ticks_msec()
	Settings.autosave = false
	print("[smoke] %s on %s, %s" % [load("res://src/debug/debug_overlay.gd").build_label(),
			OS.get_name(), RenderingServer.get_current_rendering_method()])


func _process(_delta: float) -> void:
	_frames += 1
	var t := (Time.get_ticks_msec() - _start) / 1000.0
	var street := main.find_child("TestStreet", true, false)
	if street == null:
		return
	if t > 2.0 and not _done.has("gang"):
		_done["gang"] = true
		var town := street.get_node_or_null(^"TownLife")
		if town:
			town.bring_gang()
	if t > 8.0 and not _done.has("blast"):
		_done["blast"] = true
		Blast.detonate(street, Vector3(40.0, 0.2, 25.0), 0.2)  # out on the range, away from everyone
	if t > 12.0 and not _done.has("fire"):
		_done["fire"] = true
		var members := street.find_children("*", "StructureMember", true, false)
		var fire := FireSystem.find(get_tree())
		if fire and not members.is_empty():
			fire.ignite(members[members.size() / 2])
	if t > 16.0 and not _done.has("shot"):
		_done["shot"] = true
		var ballistics := street.find_child("Ballistics", true, false) as Ballistics
		if ballistics:
			ballistics.fire(Vector3(30.0, 1.5, 20.0), Vector3(1, 0, 0), 274.0, 0.0165, 0.0115)
	if t >= SECONDS:
		_finish(street, t)


func _finish(street: Node, t: float) -> void:
	set_process(false)
	OS.remove_logger(_catcher)
	var people := get_tree().get_nodes_in_group(&"people").size()
	var problems := PackedStringArray(_catcher.errors)
	if people < 3:
		problems.append("only %d people in the street" % people)
	if street.get_node_or_null(^"Player") == null:
		problems.append("no player")
	if _frames < 30:
		problems.append("only %d frames in %.0f s" % [_frames, t])
	var lines := PackedStringArray()
	if problems.is_empty():
		lines.append("[smoke] ok: %.0f s, %d frames, %d people, %d nodes" % [t, _frames, people, Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	else:
		lines.append("[smoke] FAILED:")
		for p in problems:
			lines.append("[smoke]   " + p)
	for l in lines:
		print(l)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-out="):
			var f := FileAccess.open(a.substr(12), FileAccess.WRITE)
			if f:
				f.store_string("\n".join(lines) + "\n")
				f.close()
	get_tree().quit(0 if problems.is_empty() else 1)
