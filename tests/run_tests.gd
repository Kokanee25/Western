extends SceneTree
## Headless test runner: loads every tests/test_*.gd, runs its test_* methods, and exits with
## status 1 if any check fails or any script error is logged while a test runs.
##   godot --headless --fixed-fps 60 -s res://tests/run_tests.gd [-- --only=<file or method>[,<another>...]]
##       [--shard=K/N] [--files=test_a.gd,test_b.gd]
## `--files=` (#1234) runs only those files (whole names; CI's pull requests pass
## tools/test_select.py's choice), before any `--shard` splits them.
## `--shard=K/N` (#1015) runs only the K-th of N shares of the files (CI's parallel test jobs),
## split by config/test_times.json's seconds per file: longest first, each to the lightest share.
## A file not in the table counts as 30 s; refresh it with tools/test_times.py from CI's logs.
## `--shuffle=SEED` (#1326) runs the files (after any shard's split) in an order shuffled by SEED
## (`--shuffle=random` picks one and prints it), so a test that only passes after another shows up by
## name; main's nightly runs it. Rerun the same order with the seed it printed.
## After every file the runner checks what it left behind (tests/leak_check.gd, #1326): nodes in the
## tree, physics bodies, autoload signals, class statics, the engine's dials, tweens. A file that
## leaks fails, naming what, and what it left is taken away before the next file. Files in
## config/test_leaks.json's "known" print their leaks without failing (a ratchet: fix one, take it
## off; a known file that comes up clean says so). `--leaks=off` skips the check.


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
var _settings_at_start := {}
const LEAKS_PATH := "res://config/test_leaks.json"


func _initialize() -> void:
	# The private cast (config/private_cast.json, #1282) only in the game: tests make their men as they say,
	# whether or not a session has the private man laid in (test_people_lod checks the cast itself).
	PeopleBodies.cast_suspended = true
	Engine.set_meta(&"town_seed", 0)  # the town's run seed fixed (ValleyFolk.run_seed, #1167): the same town every run
	OS.add_logger(_catcher)
	# Budgets by count, not the clock: a test's world doesn't depend on how busy the machine is.
	World.deterministic = true
	_run.call_deferred()


## `--only=` takes one name or several with commas between (files by a part of their name, or
## methods by their whole name): the files still run in the suite's order.
static func _wanted(only: String, file: String, method: String) -> bool:
	if only == "":
		return true
	for o: String in only.split(",", false):
		if file.contains(o) or method == o:
			return true
	return false


const TIMES_PATH := "res://config/test_times.json"
const MISSING_SECONDS := 30.0


## The files of shard `k` (0-based) of `n`: every file goes to exactly one shard. Longest first
## (by `times`, seconds per file; a missing file weighs MISSING_SECONDS), each to the shard with
## the least so far, the lowest number on a tie; ties in weight go by name. Deterministic, so
## every CI job computes the same split. tools/test_times.py --check does the same in Python.
static func shard_files(files: Array, times: Dictionary, k: int, n: int) -> Array:
	var weight := func(f: String) -> float: return float(times.get(f, MISSING_SECONDS))
	var order := files.duplicate()
	order.sort_custom(func(a: String, b: String) -> bool:
		var wa: float = weight.call(a)
		var wb: float = weight.call(b)
		return wa > wb if wa != wb else a < b)
	var loads: Array[float] = []
	loads.resize(n)
	loads.fill(0.0)
	var mine: Array = []
	for f: String in order:
		var best := 0
		for i in range(1, n):
			if loads[i] < loads[best]:
				best = i
		loads[best] += weight.call(f)
		if best == k:
			mine.append(f)
	mine.sort()
	return mine


## The suite's files that `--files=` names (whole names, commas between), in the suite's order. A
## name that isn't a test file is an error, not a quiet skip: a renamed test must not drop out of CI.
static func pick_files(files: Array, chosen: String) -> Array:
	var want := {}
	for name: String in chosen.split(",", false):
		want[name.strip_edges()] = true
	for name: String in want:
		if not files.has(name):
			push_error("--files: no test file %s" % name)
	return files.filter(func(f: String) -> bool: return want.has(f))


## `files` in an order shuffled by `seed_n` (the same seed, the same order, on any machine).
static func shuffled(files: Array, seed_n: int) -> Array:
	var out := files.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = out[i]
		out[i] = out[j]
		out[j] = t
	return out


## config/test_leaks.json's "known": file -> why (files whose leaks print but don't fail yet).
static func load_known_leaks() -> Dictionary:
	var text := FileAccess.get_file_as_string(LEAKS_PATH)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	return parsed.get("known", {}) if parsed is Dictionary else {}


static func load_times() -> Dictionary:
	var text := FileAccess.get_file_as_string(TIMES_PATH)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	return parsed if parsed is Dictionary else {}


## Each file starts as the game does (#1015): GameReset.clear_statics (the props' per-id counters,
## so each prop's id, variant and seed; the lamp list, blood, smoke, the story), every setting as the
## suite started (twenty test files set library_motion, real_look, people_threads and the like, not all
## of them back) and the engine's physics catch-up as the project has it (the dev bridge raises it).
## So a file's world is the same whichever files ran before it: alone, in its CI shard or in the
## whole suite. GameReset is loaded once the autoloads are up: named here, the runner's own
## compile would pull in scripts that use Events and Settings before they exist.
func _fresh_start() -> void:
	(load("res://src/main/game_reset.gd") as GDScript).call(&"clear_statics")
	var settings := root.get_node_or_null(^"Settings")
	if settings:
		for key: String in _settings_at_start:
			if settings.get(key) != _settings_at_start[key]:
				settings.set(key, _settings_at_start[key])
	Engine.max_physics_steps_per_frame = ProjectSettings.get_setting(
			"physics/common/max_physics_steps_per_frame", 8)


func _run() -> void:
	var only := ""
	var shard := ""
	var chosen := ""
	var shuffle := ""
	var leak_check := true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
		elif arg.begins_with("--shuffle="):
			shuffle = arg.substr(10)
		elif arg == "--leaks=off":
			leak_check = false
		elif arg.begins_with("--files="):
			chosen = arg.substr(8)
		elif arg.begins_with("--shard="):
			shard = arg.substr(8)
	var settings := root.get_node_or_null(^"Settings")
	if settings:
		settings.autosave = false
		settings.reset_to_defaults()
		# Every setting as the suite starts (reset_to_defaults leaves some, e.g. library_motion,
		# people_threads, room_light, as they are), put back before each file.
		for prop: Dictionary in settings.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var v: Variant = settings.get(prop.name)
				_settings_at_start[prop.name] = v.duplicate(true) if v is Array or v is Dictionary else v

	var files := Array(DirAccess.get_files_at("res://tests")).filter(
			func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd")
	files.sort()
	if chosen != "":
		files = pick_files(files, chosen)
		print("files: %d chosen (--files)" % files.size())
	if shard != "":
		var parts := shard.split("/")
		var k := int(parts[0]) if parts.size() == 2 else 0
		var n := int(parts[1]) if parts.size() == 2 else 0
		if n < 1 or k < 1 or k > n:
			push_error("--shard wants K/N with 1 <= K <= N, got %s" % shard)
			quit(1)
			return
		var times := load_times()
		files = shard_files(files, times, k - 1, n)
		var expect := 0.0
		for f: String in files:
			expect += float(times.get(f, MISSING_SECONDS))
		print("shard %d/%d: %d files, ~%.0f s by %s" % [k, n, files.size(), expect, TIMES_PATH])
	if shuffle != "":
		var seed_n := randi() % 1000000 if shuffle == "random" else int(shuffle)
		files = shuffled(files, seed_n)
		print("order: shuffled by seed %d (rerun it: --shuffle=%d)" % [seed_n, seed_n])
	var leaks: RefCounted = (load("res://tests/leak_check.gd") as GDScript).new() if leak_check else null
	var known := load_known_leaks()
	var leaked_files: PackedStringArray = []
	var ran_files := 0
	var passed := 0
	var failed: PackedStringArray = []
	var started := Time.get_ticks_msec()
	_catcher.take()
	for file in files:
		var file_started := Time.get_ticks_msec()
		_fresh_start()
		if leaks:
			await physics_frame
			leaks.call(&"take", root)
		var path := "res://tests/%s" % file
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failed.append("%s: could not load" % file)
			continue
		var methods: Array[String] = []
		for m in script.get_script_method_list():
			var n: String = m.name
			if n.begins_with("test_") and not methods.has(n) and _wanted(only, file, n):
				methods.append(n)
		if methods.is_empty():
			continue
		ran_files += 1
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
		if leaks:
			# (a few frames for what the file queue_freed at its end, then the space asked in a physics frame)
			for i in 3:
				await process_frame
			await physics_frame
			var left: PackedStringArray = leaks.call(&"leaks", root)
			leaks.call(&"free_system_nodes", root)
			if not left.is_empty():
				leaked_files.append(file)
				var head := "leaks (known, config/test_leaks.json)" if known.has(file) else "leaks"
				for l in left:
					print("  %s %s: %s" % ["LEAK" if not known.has(file) else "leak", file, l])
				if not known.has(file):
					failed.append("%s: %s: %s" % [file, head, "; ".join(left)])
				leaks.call(&"free_leaks", root)
				await process_frame
			elif known.has(file):
				print("  clean %s: listed in config/test_leaks.json but left nothing behind (take it off)" % file)
		# Read by tools/test_times.py to refresh config/test_times.json (#1015).
		print("  time %s %.1fs" % [file, (Time.get_ticks_msec() - file_started) / 1000.0])

	_fresh_start()  # (what the statics hold goes before the engine's own teardown)
	await process_frame
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("\n%d passed, %d failed (%.1fs)" % [passed, failed.size(), seconds])
	if leaks:
		print("leaks: %d of %d files left something behind%s" % [leaked_files.size(), ran_files,
				(": " + " ".join(leaked_files)) if not leaked_files.is_empty() else ""])
	for f in failed:
		print("  - %s" % f)
	await _quit_as_the_game_does()
	quit(1 if failed.size() > 0 else 0)


## What GameQuit.quit does before the tree quits, but its watchdog (#435): our worker tasks waited
## for (at most 2 s), the sound warm-up finished, and the black box closed (a no-op under -s).
## Without it, #1015's shards 2, 4 and 6 crashed in the engine's cleanup after every test passed
## (SIGABRT from a segfault on a null mutex); the whole suite in one run didn't.
func _quit_as_the_game_does() -> void:
	var game_quit := load("res://src/main/game_quit.gd") as GDScript
	var t0 := Time.get_ticks_msec()
	while not (game_quit.call(&"in_flight", self) as PackedStringArray).is_empty() and Time.get_ticks_msec() - t0 < 2000:
		await process_frame
	(load("res://src/audio/synth_sounds.gd") as GDScript).call(&"finish_warm")
	(load("res://src/debug/crash_reports.gd") as GDScript).call(&"clean_quit")
