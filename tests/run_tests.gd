extends SceneTree
## Headless test runner: loads every tests/test_*.gd, runs its test_* methods, and exits with
## status 1 if any check fails or any script error is logged while a test runs.
##   godot --headless --fixed-fps 60 -s res://tests/run_tests.gd [-- --only=<file or method>]


class ErrorCatcher:
	extends Logger
	var errors: PackedStringArray = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		errors.append("%s (%s:%d in %s)" % [rationale if rationale != "" else code, file, line, function])
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var out := errors
		errors = PackedStringArray()
		_mutex.unlock()
		return out


var _catcher := ErrorCatcher.new()


func _initialize() -> void:
	OS.add_logger(_catcher)
	_run.call_deferred()


func _run() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
	var settings := root.get_node_or_null(^"Settings")
	if settings:
		settings.autosave = false
		settings.reset_to_defaults()

	var files := Array(DirAccess.get_files_at("res://tests")).filter(
			func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd")
	files.sort()
	var passed := 0
	var failed: PackedStringArray = []
	var started := Time.get_ticks_msec()
	_catcher.take()
	for file in files:
		var path := "res://tests/%s" % file
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failed.append("%s: could not load" % file)
			continue
		var methods: Array[String] = []
		for m in script.get_script_method_list():
			var n: String = m.name
			if n.begins_with("test_") and not methods.has(n) and (only == "" or file.contains(only) or n == only):
				methods.append(n)
		if methods.is_empty():
			continue
		var case: TestCase = script.new()
		case.name = file.get_basename()
		root.add_child(case)
		for method in methods:
			case.current_test = "%s::%s" % [file.get_basename(), method]
			case.failures.clear()
			await case.before_each()
			await case.call(method)
			await case.after_each()
			for e in _catcher.take():
				case.failures.append("%s: script error: %s" % [case.current_test, e])
			if case.failures.is_empty():
				passed += 1
				print("  ok   %s" % case.current_test)
			else:
				for f in case.failures:
					failed.append(f)
					print("  FAIL %s" % f)
		case.queue_free()
		await process_frame

	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("\n%d passed, %d failed (%.1fs)" % [passed, failed.size(), seconds])
	for f in failed:
		print("  - %s" % f)
	quit(1 if failed.size() > 0 else 0)
