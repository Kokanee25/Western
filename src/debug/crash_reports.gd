class_name CrashReports
extends Node
## Crash and freeze reports that survive (issue #624). F12's report needs the game alive; these
## don't.
##
## - **The black box.** Every BOX_EVERY seconds the last BOX_SECONDS of the bug recorder (its
##   recording from the snapshot before, its events), the timing rings (PerfRing), the people and
##   you (BugRecorder.report) and the last LOG_LINES lines of the log are copied on the main thread
##   (packed arrays: a memcpy) and written by a worker into `user://blackbox/box_0|1.json`, the two
##   taken in turn, so a crash mid-write leaves the other.
## - **The marker.** `user://blackbox/running.json` is written at the start and removed by a clean
##   quit (GameQuit). Found at the next start, the run before didn't quit: everything in the black
##   box folder (the newest box, the native notes and dumps, the run's godot.log) is packed into
##   one `crash_<date-time>.saltbug.zip` in the reports folder, and a line on the screen says what
##   happened and where the file is.
## - **The native half** (`CrashGuard`, addons/saltcreek_native/src/crash_guard.rs): the crash
##   handlers (crash.txt, crash.dmp on Windows, panic.txt) and the freeze watchdog (freeze.txt,
##   freeze.dmp, the process ended at 60 s), all into the black box folder. Without the plugin (the
##   web) only the black box and the marker.
## - **The reports folder** (`folder()`): `Salt Creek crash reports` on the desktop (F12's reports
##   go there too), else `user://crash_reports`; `-- --crash-dir=DIR` for one run.
## - A stall (no frame for 5 s, then it came back) is packed at once as `stall_<date-time>`
##   (STALLS_KEPT a run at most; none in the first QUIET_START seconds: the shaders compiling).
## - Trying it (hidden): `-- --hang-at=S` hangs the main thread S s after the first frame, `-- --crash-at=S`
##   crashes it (`--crash-at=S:thread` a native thread, `:abort`, `:panic`, `:script` a call on a
##   freed object, as a release build makes of one); `-- --crash-watch=FREEZE,END` the watchdog's
##   seconds (5, 60).

const BOX := "user://blackbox"
const FOLDER_NAME := "Salt Creek crash reports"
const BOX_EVERY := 3.0
const BOX_SECONDS := 60.0
const LOG_LINES := 300
const STALLS_KEPT := 3
const QUIET_START := 30.0  # s after the first frame when a stall isn't packed (the shaders compiling)
const NOTES: PackedStringArray = ["crash.txt", "freeze.txt", "panic.txt"]
const DUMPS: PackedStringArray = ["crash.dmp", "freeze.dmp"]

## The native guard (null without the plugin, or in a script run).
static var guard: Object
static var box_dir := BOX
## The report this start packed from the run before: {path, kind, line}, {} if none.
static var packed := {}
static var lines: Lines
static var _started := false
static var _task := -1
## Set by the clean quit: no box is written after it (#624: one posted in the quit's last frames was
## never waited for, and freed after the script language had gone: build 3230's drawn smoke crashed so).
static var _closed := false
static var _box_n := 0
static var _stalls := 0
static var _first_frame := 0
static var _hang_at := -1.0
static var _crash_at := -1.0
static var _crash_how := "segv"
static var _copy_us_sum := 0
static var _copies := 0
static var _write_us := 0  # the last write's time on the worker

var recorder: BugRecorder
var _next_box := 0  # ms (the wall's: a frame's delta crawls while the game starts)


## The last LOG_LINES lines of the log (prints, errors and warnings), from any thread.
class Lines:
	extends Logger
	var _ring: PackedStringArray = []
	var _m := Mutex.new()

	func _log_message(message: String, error: bool) -> void:
		_add(("[err] " if error else "") + message.strip_edges(false, true))

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _bt: Array[ScriptBacktrace]) -> void:
		var kind: String = ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"][clampi(error_type, 0, 3)]
		_add("%s: %s (%s:%d in %s)" % [kind, rationale if rationale != "" else code, file, line, function])

	func _add(text: String) -> void:
		_m.lock()
		_ring.append(text)
		if _ring.size() > LOG_LINES + 50:
			_ring = _ring.slice(_ring.size() - LOG_LINES)
		_m.unlock()

	func take() -> PackedStringArray:
		_m.lock()
		var out := _ring.slice(maxi(0, _ring.size() - LOG_LINES))
		_m.unlock()
		return out


## From main.gd once the scene is in (every start and every reset, GameReset): the first time, the
## run before is packed if it didn't quit, the marker written and the guard armed; every time, this
## scene's node that keeps the black box and beats.
static func start(main: Node, rec: BugRecorder) -> void:
	if tool_run():
		return
	if not _started:
		_started = true
		_read_args()
		DirAccess.make_dir_recursive_absolute(box_dir)
		if FileAccess.file_exists(box_dir.path_join("running.json")):
			packed = pack(box_dir, folder(), "")
			_tell(rec)
		write_marker(box_dir)
		lines = Lines.new()
		OS.add_logger(lines)
		if ClassDB.class_exists(&"CrashGuard"):
			guard = ClassDB.instantiate(&"CrashGuard")
			var watch := _arg("--crash-watch=")
			if watch != "":
				var w := watch.split(",")
				guard.configure(float(w[0]), float(w[1]) if w.size() > 1 else 60.0, 300.0)
			elif "--smoke-test" in OS.get_cmdline_user_args():
				# The smoke test runs on CI's software Vulkan, ~6 s a frame (build 3222: 15 frames in
				# 85 s): there a frame over 5 s isn't a freeze, and each report's gdb stalls it more
				# till one gap passes 60 s (#624: builds 3230, 3244). Reports at 30 s, never ended.
				guard.configure(30.0, 0.0, 300.0)
			guard.install(ProjectSettings.globalize_path(box_dir), _info())
	# The start is a load until FIRST_FRAMES frames have been drawn (the node ends it): the first
	# frame's draw compiles the shaders, over 60 s under CI's software Vulkan, and the watchdog
	# ended a game that wasn't frozen (#624: main's builds 3230 and 3244, the drawn smoke).
	begin_load("the first frames (the shaders)")
	var node := CrashReports.new()
	node.name = "CrashReports"
	node.recorder = rec
	main.add_child(node)
	if rec and rec.perf_on and rec.perf.clock:
		rec.perf.clock.guard = guard


## A script run (the tools, the tests, `-s`): none of this.
static func tool_run() -> bool:
	var args := OS.get_cmdline_args()
	return args.has("-s") or args.has("--script") or OS.has_feature("editor") and Engine.is_editor_hint()


## A load starts or ends (the reset, the train lab's line): the watchdog gives it 300 s.
static func loading(on: bool, what: String) -> void:
	if guard:
		guard.loading(on, what)


## The scene's load (the start, a reset), open till its first frames are drawn: once, however
## often it's begun (a reset during the first frames doesn't count it twice).
static var _load_open := false


static func begin_load(what: String) -> void:
	if not _load_open:
		_load_open = true
		loading(true, what)


static func end_load() -> void:
	if _load_open:
		_load_open = false
		loading(false, "")


## Where the reports go: the desktop's `Salt Creek crash reports` (made if need be), else
## user://crash_reports.
static func folder() -> String:
	var given := _arg("--crash-dir=")
	if given != "":
		DirAccess.make_dir_recursive_absolute(given)
		return given
	var desk := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if desk != "" and DirAccess.dir_exists_absolute(desk) and DisplayServer.get_name() != "headless":
		var d := desk.path_join(FOLDER_NAME)
		if DirAccess.make_dir_recursive_absolute(d) == OK or DirAccess.dir_exists_absolute(d):
			return d
	var u := ProjectSettings.globalize_path("user://crash_reports")
	DirAccess.make_dir_recursive_absolute(u)
	return u


static func write_marker(dir: String) -> void:
	var f := FileAccess.open(dir.path_join("running.json"), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"pid": OS.get_process_id(), "started": Time.get_datetime_string_from_system(),
				"build": _build(), "args": " ".join(OS.get_cmdline_user_args())}))


## A clean quit (GameQuit): the marker and the black box go; the guard stands down.
static func clean_quit() -> void:
	if not _started:
		return
	_closed = true
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if guard:
		guard.uninstall()
		# (held in a static, it would be let go after the plugin has unloaded: a crash at exit)
		guard = null
	if lines:
		OS.remove_logger(lines)  # (a script's logger called after the script language has gone aborts the exit)
		lines = null
	clear(box_dir, true)


## The black box folder emptied (`marker` too: running.json).
static func clear(dir: String, marker: bool) -> void:
	var names := ["box_0.json", "box_1.json", "box_0.json.tmp", "box_1.json.tmp"] + Array(NOTES) + Array(DUMPS)
	if marker:
		names.append("running.json")
	for n: String in names:
		if FileAccess.file_exists(dir.path_join(n)):
			DirAccess.remove_absolute(dir.path_join(n))


## Is the black box being written (GameQuit waits for it)?
static func writing() -> bool:
	return _task >= 0 and not WorkerThreadPool.is_task_completed(_task)


# -- Each frame -------------------------------------------------------------------------------------

## Frames drawn before the scene's load counts as over (the first draw compiles the shaders).
const FIRST_FRAMES := 3
var _drawn := 0


func _count_draw() -> void:
	_drawn += 1
	if _drawn >= FIRST_FRAMES:
		end_load()
		if RenderingServer.frame_post_draw.is_connected(_count_draw):
			RenderingServer.frame_post_draw.disconnect(_count_draw)


func _ready() -> void:
	# Headless nothing is drawn (and no frame is posted): frames counted in _process instead.
	if DisplayServer.get_name() != "headless":
		RenderingServer.frame_post_draw.connect(_count_draw)
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 1001  # the last of the frame's scripts, after the bug recorder: its beat is the frame done
	_next_box = Time.get_ticks_msec() + 1000


## Leaving the tree (a reset, the quit): a write in flight is waited for, so the pool lets its task go now.
func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_count_draw):
		RenderingServer.frame_post_draw.disconnect(_count_draw)
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _process(_delta: float) -> void:
	if _closed:
		return
	var now := Time.get_ticks_msec()
	if _first_frame == 0:
		_first_frame = now
	var t := (now - _first_frame) / 1000.0  # (--hang-at and --crash-at count from the first frame)
	if _hang_at >= 0.0 and t >= _hang_at:
		_hang_at = -1.0
		print("[crash reports] --hang-at: the main thread hangs now, on purpose")
		var n := 0
		while true:  # (the watchdog reports it at 5 s and ends it at 60)
			n += 1
	if _crash_at >= 0.0 and t >= _crash_at:
		_crash_at = -1.0
		print("[crash reports] --crash-at: a crash now, on purpose (%s)" % _crash_how)
		_crash(_crash_how)
	if _drawn < FIRST_FRAMES and DisplayServer.get_name() == "headless":
		_count_draw()
	if guard:
		guard.beat()  # (after the tries above: a hang there is the frame's _process, as a real one would be)
	if now >= _next_box and not writing():
		_next_box = now + int(BOX_EVERY * 1000.0)
		write_box()
	if guard and Engine.get_process_frames() % 30 == 0 and guard.take_recovered():
		if t < QUIET_START or _stalls >= STALLS_KEPT:
			# The first seconds' stalls are the shaders compiling: not packed.
			for n in NOTES + DUMPS:
				if FileAccess.file_exists(box_dir.path_join(n)):
					DirAccess.remove_absolute(box_dir.path_join(n))
		else:
			_stalls += 1
			_pack_stall()


## Copy what the black box keeps (here, the main thread) and write it on a worker.
func write_box(now := false) -> void:
	if _closed:
		return
	var t0 := Time.get_ticks_usec()
	var snap := snapshot()
	snap["copy_us"] = Time.get_ticks_usec() - t0  # what it cost the main thread (#624: well under 0.1 ms a frame)
	_copy_us_sum += int(snap.copy_us)
	_copies += 1
	var path := box_dir.path_join("box_%d.json" % (_box_n % 2))
	_box_n += 1
	if _task >= 0:
		# The pool keeps a task (its callable and the copy bound to it) till it's waited for: one
		# never waited for lives to the exit and is let go after the script language has gone (the
		# smoke test's exit crashed so). It's done here (`writing()` was false), so this doesn't wait.
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if now:
		_write(snap, path)
		return
	_task = WorkerThreadPool.add_task(_write.bind(snap, path), true, "the black box")


func snapshot() -> Dictionary:
	var out := {"written": Time.get_datetime_string_from_system(), "unix": Time.get_unix_time_from_system(),
			"pid": OS.get_process_id(), "log": lines.take() if lines else PackedStringArray()}
	if recorder == null or not is_instance_valid(recorder):
		return out
	var tick := Engine.get_physics_frames() - recorder.start_tick()
	out["report"] = BugRecorder.report(get_tree(), tick, recorder.events())
	out["recording"] = recorder.recording(BOX_SECONDS)
	if recorder.perf_on:
		out["perf"] = recorder.perf.copy()
	return out


## On a worker: the copy as JSON, to a temporary file renamed over the box.
static func _write(snap: Dictionary, path: String) -> void:
	var t0 := Time.get_ticks_usec()
	var perf: PerfRing = snap.get("perf")
	var out := snap.duplicate()
	out.erase("perf")
	if perf:
		var rep: Dictionary = out.get("report", {})
		rep["perf_summary"] = perf.summary()
		out["perf"] = perf.to_dict()
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	out["write_us_before"] = _write_us
	f.store_string(JSON.stringify(out, "", false))
	f.close()
	_write_us = Time.get_ticks_usec() - t0
	DirAccess.rename_absolute(path + ".tmp", path)


func _pack_stall() -> void:
	write_box(true)
	var r := pack(box_dir, folder(), "stall")
	if r.is_empty():
		return
	print("[crash reports] %s" % r.line)
	if recorder:
		recorder.say(r.line, 15.0)


static func _crash(how: String) -> void:
	if how == "script":
		# What a release build makes of a call on a freed object (the train's, #624): no check.
		var n := Node.new()
		n.free()
		n.call(&"get_tree")
		return
	if guard:
		guard.crash_now(how)
	else:
		OS.crash("--crash-at with no native plugin")


# -- The next start: packing ------------------------------------------------------------------------

## Pack the black box folder `dir` into one zip in `out_dir`: {path, kind, line}, {} if nothing
## to pack. `kind` "" says what the notes say (crash, freeze, unknown); "stall" packs a stall the
## game came back from (the marker and the box stay).
static func pack(dir: String, out_dir: String, kind: String) -> Dictionary:
	var marker := _json(dir.path_join("running.json"))
	var notes := {}
	for n in NOTES:
		var p := dir.path_join(n)
		if FileAccess.file_exists(p):
			notes[n] = FileAccess.get_file_as_string(p)
	if kind == "":
		kind = what_happened(notes)
	var box := newest_box(dir)
	var stamp := String(box.get("written", marker.get("started", Time.get_datetime_string_from_system()))).replace(":", "-")
	var prefix := "stall" if kind == "stall" else "crash"
	var path := out_dir.path_join("%s_%s.saltbug.zip" % [prefix, stamp])
	var n2 := 2
	while FileAccess.file_exists(path):
		path = out_dir.path_join("%s_%s-%d.saltbug.zip" % [prefix, stamp, n2])
		n2 += 1
	var zip := ZIPPacker.new()
	if zip.open(path) != OK:
		push_warning("crash reports: couldn't write %s" % path)
		return {}
	var report: Dictionary = box.get("report", {})
	report["crash"] = {"kind": kind, "what": describe(kind, notes), "notes": notes.keys(), "marker": marker,
			"box_written": box.get("written", ""), "box_found": not box.is_empty()}
	_put(zip, "report.json", JSON.stringify(report, "  ", false).to_utf8_buffer())
	if box.has("recording"):
		_put(zip, "recording.json", JSON.stringify(box.recording).to_utf8_buffer())
	if box.has("perf"):
		_put(zip, "perf.json", JSON.stringify(box.perf, "", false).to_utf8_buffer())
	_put(zip, "log.txt", "\n".join(box.get("log", [])).to_utf8_buffer())
	var log := _run_log(kind == "stall")
	if log != "":
		_put(zip, "godot.log", FileAccess.get_file_as_bytes(log))
	for n: String in notes:
		_put(zip, n, String(notes[n]).to_utf8_buffer())
	for d in DUMPS:
		var p := dir.path_join(d)
		if FileAccess.file_exists(p):
			_put(zip, d, FileAccess.get_file_as_bytes(p))
	zip.close()
	if kind == "stall":
		for n in NOTES + DUMPS:
			if FileAccess.file_exists(dir.path_join(n)):
				DirAccess.remove_absolute(dir.path_join(n))
	else:
		clear(dir, true)
	var shown := BugRecorder.shown_path(path)
	return {"path": path, "kind": kind, "line": describe(kind, notes) + " The report: " + shown + " (drag it into a GitHub issue)"}


## crash, freeze or unknown, by the notes the native guard left.
static func what_happened(notes: Dictionary) -> String:
	var crash := String(notes.get("crash.txt", ""))
	if notes.has("freeze.txt") and (crash == "" or crash.contains("watchdog ending a freeze")):
		return "freeze"
	if crash != "" or notes.has("panic.txt"):
		return "crash"
	return "unknown"


static func describe(kind: String, notes: Dictionary) -> String:
	match kind:
		"crash":
			var first := String(notes.get("crash.txt", notes.get("panic.txt", ""))).get_slice("\n", 0)
			return "Salt Creek crashed last time (%s)." % first.trim_prefix("crash: ")
		"freeze":
			var text := String(notes.get("freeze.txt", ""))
			if text.contains("\nended:"):
				var s := text.get_slice("\nended: still frozen ", 1).get_slice(" s after", 0)
				return "Salt Creek froze last time; the watchdog ended it after %s s." % s
			return "Salt Creek froze last time (closed while frozen)."
		"stall":
			return "The game stalled over 5 s just now (it came back)."
	return "Salt Creek didn't quit cleanly last time (closed from outside, or a crash nothing caught)."


## The newer of the two boxes that reads as JSON, {} if neither.
static func newest_box(dir: String) -> Dictionary:
	var best := {}
	for n in ["box_0.json", "box_1.json"]:
		var d := _json(dir.path_join(n))
		if not d.is_empty() and float(d.get("unix", 0.0)) >= float(best.get("unix", -1.0)):
			best = d
	return best


## The crashed run's own log: Godot moved it aside at this start (logs/godot<date>.log, the newest);
## a stall's is this run's (logs/godot.log).
static func _run_log(this_run: bool) -> String:
	var dir := "user://logs"
	if this_run:
		return dir.path_join("godot.log") if FileAccess.file_exists(dir.path_join("godot.log")) else ""
	var best := ""
	var best_t := 0
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("godot") and f.ends_with(".log") and f != "godot.log":
			var t := FileAccess.get_modified_time(dir.path_join(f))
			if t >= best_t:
				best_t = t
				best = dir.path_join(f)
	return best


static func _tell(rec: BugRecorder) -> void:
	if packed.is_empty():
		return
	print("[crash reports] %s" % packed.line)
	if rec:
		rec.say.call_deferred(packed.line, 25.0)


static func _put(zip: ZIPPacker, name: String, bytes: PackedByteArray) -> void:
	zip.start_file(name)
	zip.write_file(bytes)
	zip.close_file()


static func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


static func _arg(prefix: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""


static func _read_args() -> void:
	# A box of its own (the labs' games run side by side: each read the other's running marker as
	# a run that didn't quit, and put the notice over its film).
	var box := _arg("--crash-box=")
	if box != "":
		box_dir = box
	var h := _arg("--hang-at=")
	if h != "":
		_hang_at = float(h)
	var c := _arg("--crash-at=")
	if c != "":
		_crash_at = float(c.get_slice(":", 0))
		if c.contains(":"):
			_crash_how = c.get_slice(":", 1)


static func _build() -> String:
	return load("res://src/debug/debug_overlay.gd").build_label()


static func _info() -> String:
	return "build %s, Godot %s, %s, pid %d" % [_build(), Engine.get_version_info().string, OS.get_name(), OS.get_process_id()]
