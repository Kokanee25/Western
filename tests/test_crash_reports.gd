extends TestCase
## Crash and freeze reports (issue #624; src/debug/crash_reports.gd, the plugin's crash_guard.rs):
## the marker is written and a clean quit takes it away; a black box folder left by a crash, a
## freeze or a run that didn't quit is packed into one zip that says which; the black box is
## written and reads back; the recording's last seconds start at the snapshot before them; the
## watchdog reports a frame that doesn't finish and that it came back, and stands down for a load.

const DIR := "user://test_blackbox"
const OUT := "user://test_crash_out"


func before_each() -> void:
	for d in [DIR, OUT]:
		DirAccess.make_dir_recursive_absolute(d)
		for f in DirAccess.get_files_at(d):
			DirAccess.remove_absolute(d.path_join(f))


func _box(unix: float, extra := {}) -> Dictionary:
	var box := {"written": "2026-11-04T10:00:%02d" % int(unix), "unix": unix, "pid": 1,
			"log": ["one line", "another"],
			"report": {"build": "test", "game_seconds": 40.0, "events": [{"t": 35.0, "kind": "shot", "text": "you fired"}]},
			"recording": {"tick": 2400, "ticks_per_second": 60, "inputs": [], "looks": [], "checks": []}}
	box.merge(extra, true)
	return box


func _put(name: String, text: String) -> void:
	var f := FileAccess.open(DIR.path_join(name), FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _zip_names(path: String) -> PackedStringArray:
	var z := ZIPReader.new()
	if z.open(path) != OK:
		return []
	var out := z.get_files()
	z.close()
	return out


func _zip_report(path: String) -> Dictionary:
	var z := ZIPReader.new()
	z.open(path)
	var d: Dictionary = JSON.parse_string(z.read_file("report.json").get_string_from_utf8())
	z.close()
	return d


func test_marker_written_and_a_clean_quit_takes_it() -> void:
	CrashReports.write_marker(DIR)
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join("running.json")))
	check_eq(int(m.get("pid", 0)), OS.get_process_id(), "the marker names this run")
	_put("box_0.json", JSON.stringify(_box(1.0)))
	CrashReports.clear(DIR, true)
	check(not FileAccess.file_exists(DIR.path_join("running.json")), "a clean quit takes the marker")
	check(not FileAccess.file_exists(DIR.path_join("box_0.json")), "and the black box")


func test_a_crash_packed() -> void:
	CrashReports.write_marker(DIR)
	_put("box_0.json", JSON.stringify(_box(1.0)))
	_put("box_1.json", JSON.stringify(_box(4.0, {"report": {"build": "newer", "game_seconds": 43.0}})))
	_put("crash.txt", "crash: SIGSEGV (a bad memory access), address 0x8\nthread 7 'godot' (the main thread)\n")
	var r := CrashReports.pack(DIR, ProjectSettings.globalize_path(OUT), "")
	check_eq(r.get("kind"), "crash", "a crash note: a crash")
	check(String(r.get("line", "")).contains("crashed last time") and String(r.get("line", "")).contains(".saltbug.zip"),
			"the line says so and where (%s)" % r.get("line", ""))
	var names := _zip_names(r.get("path", ""))
	for n in ["report.json", "recording.json", "log.txt", "crash.txt"]:
		check(names.has(n), "the zip has %s (%s)" % [n, names])
	var rep := _zip_report(r.path)
	check_eq(rep.get("build"), "newer", "the newer of the two boxes")
	check_eq((rep.get("crash", {}) as Dictionary).get("kind"), "crash", "report.json says what happened")
	check(not FileAccess.file_exists(DIR.path_join("running.json")) and not FileAccess.file_exists(DIR.path_join("crash.txt")),
			"the folder emptied after")
	check(String(r.path).get_file().begins_with("crash_"), "named crash_<date-time> (%s)" % String(r.path).get_file())


func test_a_freeze_packed() -> void:
	CrashReports.write_marker(DIR)
	_put("box_0.json", JSON.stringify(_box(2.0)))
	_put("freeze.txt", "freeze: the main thread hasn't finished a frame for 5.0 s\n\nended: still frozen 60 s after the last frame; ...\n")
	_put("crash.txt", "crash: SIGSEGV (sent, not a fault)\n(this is the watchdog ending a freeze: ...)\n")
	var r := CrashReports.pack(DIR, ProjectSettings.globalize_path(OUT), "")
	check_eq(r.get("kind"), "freeze", "the watchdog's end of a freeze is a freeze, not a crash")
	check(String(r.get("line", "")).contains("ended it after 60 s"), "it says the watchdog ended it (%s)" % r.get("line", ""))
	check(_zip_names(r.path).has("freeze.txt"), "freeze.txt in the zip")


func test_an_unclean_quit_packed() -> void:
	CrashReports.write_marker(DIR)
	var r := CrashReports.pack(DIR, ProjectSettings.globalize_path(OUT), "")
	check_eq(r.get("kind"), "unknown", "only the marker: it didn't quit cleanly")
	check(not (_zip_report(r.path).get("crash", {}) as Dictionary).get("box_found", true), "and it says there was no black box")


func test_the_black_box_written_and_read() -> void:
	var node := CrashReports.new()
	add_child(node)
	var was := CrashReports.box_dir
	CrashReports.box_dir = DIR
	node.write_box(true)
	CrashReports.box_dir = was
	var box := CrashReports.newest_box(DIR)
	check(box.has("written") and box.has("log"), "a box that reads back (%s)" % str(box.keys()))
	node.free()


func test_recording_since_the_snapshot() -> void:
	var rows := [[10, 0, 1.0], [20, 0, 0.0], [30, 1, 1.0], [40, 1, 0.0]]
	check_eq(BugRecorder._since(rows, 25).size(), 2, "from the first at or after the tick")
	check_eq(BugRecorder._since(rows, 0).size(), 4, "from the start")


func test_watchdog_reports_a_stall_and_stands_down_for_a_load() -> void:
	if not ClassDB.class_exists(&"CrashGuard"):
		check(false, "the native plugin has CrashGuard")
		return
	var g: Object = ClassDB.instantiate(&"CrashGuard")
	var dir := ProjectSettings.globalize_path(DIR)
	g.set_stacks(false)
	g.configure(0.5, 0.0, 3.0)
	check(g.install(dir, "test"), "installed")
	g.beat()
	OS.delay_msec(1200)  # the main thread stuck past the 0.5 s
	check(FileAccess.file_exists(DIR.path_join("freeze.txt")), "a frame that doesn't finish: freeze.txt")
	g.beat()
	OS.delay_msec(300)  # (under the 0.5 s: no second report)
	check(g.take_recovered(), "it came back: a stall, recovered")
	check(FileAccess.get_file_as_string(DIR.path_join("freeze.txt")).contains("recovered"), "freeze.txt says it came back")
	DirAccess.remove_absolute(DIR.path_join("freeze.txt"))
	g.beat()
	g.loading(true, "a test load")
	OS.delay_msec(1200)
	check(not FileAccess.file_exists(DIR.path_join("freeze.txt")), "a load stands it down")
	g.loading(false, "")
	OS.delay_msec(300)
	check(not FileAccess.file_exists(DIR.path_join("freeze.txt")), "the load's end counts as a frame")
	g.uninstall()
	g.set_stacks(true)
	g.configure(5.0, 60.0, 300.0)
	check(not g.installed(), "stood down")
