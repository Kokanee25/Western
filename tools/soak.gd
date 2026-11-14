extends SceneTree
## The soak test (docs/briefs/automated-checks.md, item 2): the game left running for hours of game
## time, headless and as fast as it goes, with things happening: the gang rides in again whenever
## it's gone, every few minutes one of them picks a fight with you, a building's set alight now and
## then and a stick goes off; the clock runs 30x so day and night come round. It fails on:
## - any script or engine error (logged once each, with a count),
## - memory or the node count still climbing at the end (not just higher: climbing),
## - nodes out of the tree piling up: the orphans less those held on purpose (a member at rest keeps
##   its mesh and shape aside, StructureMember.rest; so does rubble drawn by its cell, RubbleRest),
##   climbing (#863: the count at the end was the rule, and members at rest are most of it),
## - the members' mesh cache past its limit (MemberMesh.CACHE_LIMIT),
## - anyone stuck (on his way somewhere and not a metre further in a minute),
## - anyone or any loose piece under the ground or off the map,
## - the frame time creeping (the last window's median several times the first's).
##
##   godot --headless --fixed-fps 60 -s res://tools/soak.gd -- --minutes=240 --out=build/soak
##
## Each problem is printed as it's found and each window prints the process's resident memory, so
## a run the CI runner kills still leaves its log; past RUNAWAY_MB it stops early and reports.
## A frozen game prints nothing, so every 600 frames it writes the game clock to <out>/clock.txt:
## the nightly workflow watches the log and that clock, and dumps every thread when they stop
## (soak #10 sat silent four hours at game minute 95, 2026-10-13). `--hang-at=S` hangs it on purpose
## to try that.
##
## In the valley (`-- --world=valley`, docs/briefs/valley-plan.md G2): nobody lives there yet, so
## the player is carried round the valley at a gallop (the ground's levels built and freed as he
## goes), and when the town has a stick a stick goes off on the dirt near him, and when it has a
## fire a hole is dug and filled (`--every=S`: both every S seconds, the craters' stress run);
## "under the ground" is under the valley's ground there, "off the map" outside its envelope.
##
## (--fixed-fps 60: each frame is a 60th of a second of game time and the loop runs flat out, about
## 3.4x real time here, so the frame times are what the game costs, not the engine's pacing.)
##
## Writes <out>/soak.md (the report) and soak.json; exit 1 on any failure. The nightly workflow
## (.github/workflows/nightly.yml) runs it.

const WINDOW := 300.0  # seconds of game time a measuring window
const FLOOR_Y := -1.5
const MAP_RADIUS := 400.0
const STUCK_SECONDS := 60.0
const CREEP := 3.0  # the last window's median frame over the first's
const MEMORY_GROWTH := 1.5  # the last window's memory over the first's, while still climbing
const RUNAWAY_MB := 6000.0  # resident memory: stop and report (the CI runner has 16 GB)

var OB: Script  # OutlawBrain, loaded once the game is up (a -s script can't name game classes)

class Catcher:
	extends Logger
	var counts := {}
	var _m := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _bt: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var key := "%s (%s:%d in %s)" % [rationale if rationale != "" else code, file, line, function]
		_m.lock()
		counts[key] = int(counts.get(key, 0)) + 1
		_m.unlock()

var _catcher := Catcher.new()
var _minutes := 60.0
var _out := "build/soak"
var _main: Node
var _street: Node3D
var _town
var _player
var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _windows: Array = []  # {t, frame_ms, p99_ms, memory_mb, rss_mb, nodes, orphans, held, unheld, rubble, ...}
var _kinds_first := {}  # node kind -> how many, at the first full window (what grew, at the end)
var _kinds_last := {}
var _frame_ms := PackedFloat32Array()
var _problems := {}
var _track := {}  # person (instance id) -> {at, since}
var _happened: Array[String] = []
var _runaway := false
var _frames := 0
var _hang_at := -1.0
## The valley (Settings.world): its Ground and envelope, the tour's legs and how far along it is.
var _valley := false
var _ground
var _envelope := Rect2()
var _tour: Array[Vector2] = []
var _tour_s := 0.0
const TOUR_SPEED := 15.0  # m/s, a gallop
var _every := 0.0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			_minutes = float(a.substr(10))
		elif a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--every="):
			_every = float(a.substr(8))
		elif a.begins_with("--hang-at="):  # hang on purpose at this game second (for trying it)
			_hang_at = float(a.substr(10))
	OS.add_logger(_catcher)
	_rng.seed = 1882
	root.get_node(^"Settings").autosave = false
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	await process_frame
	OB = load("res://src/bodies/outlaw_brain.gd")
	_valley = root.get_node(^"Settings").world == &"valley"
	_street = _main.find_child("Valley" if _valley else "TestStreet", true, false)
	_town = null if _valley else _street.get_node(^"TownLife")
	_player = _street.get_node(^"Player")
	if _valley:
		_ground = _street.get_node(^"Ground")
		_envelope = load("res://src/world/valley_layout.gd").main().envelope()
		var e := _envelope.grow(-60.0)
		_tour = [Vector2.ZERO, Vector2(1300, 200), Vector2(e.end.x, e.end.y), Vector2(e.position.x, e.end.y),
				Vector2(e.position.x, e.position.y), Vector2(e.end.x, e.position.y), Vector2.ZERO]
	_player.input_enabled = false
	_street.get_node(^"DayCycle").set_time_scale(30.0)
	print("soak: %.0f minutes of game time" % _minutes)
	DirAccess.make_dir_recursive_absolute(_out)
	_run()


func _run() -> void:
	var dt := 1.0 / Engine.physics_ticks_per_second
	var next_gang := 0.0
	var next_fight := 150.0
	var next_check := 1.0
	var window_end := WINDOW
	# Every 100 minutes: a fire at 20 and 70, a stick at 30 and 80.
	var events := []
	var cycle := 0.0
	# (in the valley a hole dug where the town has a fire; `--every=S`: a stick and a hole every S
	# seconds instead, the craters' stress run)
	var cycle_events := [[1200.0, "fire"], [1800.0, "blast"], [4200.0, "fire"], [4800.0, "blast"]]
	var cycle_len := 6000.0
	if _valley and _every > 0.0:
		cycle_events = [[_every * 0.5, "blast"], [_every, "dig"]]
		cycle_len = _every
	while cycle < _minutes * 60.0:
		for e in cycle_events:
			events.append([cycle + float(e[0]), e[1]])
		cycle += cycle_len
	var last := Time.get_ticks_usec()
	while _t < _minutes * 60.0 and not _runaway:
		await physics_frame
		_frames += 1
		if _frames % 600 == 0:
			# The game clock, for the nightly workflow: a frozen game and a crawling one both go
			# quiet in the log; this says which.
			var hb := FileAccess.open(_out.path_join("clock.txt"), FileAccess.WRITE)
			if hb:
				hb.store_line("%s frame %d" % [_clock(), _frames])
		if _hang_at >= 0.0 and _t >= _hang_at:
			while true:
				_hang_at += 0.0
		var now := Time.get_ticks_usec()
		_frame_ms.append((now - last) / 1000.0)
		last = now
		_t += dt
		if _valley:
			_ride(dt)
		if _town and _t >= next_gang:
			next_gang += 240.0
			if _town.gang.is_empty() or _town.gang.all(func(g): return not is_instance_valid(g)):
				_town.bring_gang()
				_happened.append("%s the gang rides in" % _clock())
		if _town and _t >= next_fight:
			next_fight += 300.0
			var live: Array = _town.gang.filter(func(g): return is_instance_valid(g))
			if not live.is_empty():
				var man = live[_rng.randi_range(0, live.size() - 1)]
				var b = man.get_node_or_null(^"Brain")
				if b and b.relations:
					b.relations.provoke(_player)
					_happened.append("%s %s picks a fight" % [_clock(), man.person_id])
		while not events.is_empty() and _t >= float(events[0][0]):
			_event(String(events.pop_front()[1]))
		if _t >= next_check:
			next_check += 1.0
			_check()
		if _t >= window_end:
			window_end += WINDOW
			_close_window()
	_finish()


func _clock() -> String:
	return "%3d:%02d" % [int(_t) / 60, int(_t) % 60]


func _event(kind: String) -> void:
	if _valley:
		_valley_event(kind)
		return
	var members: Array = _street.find_children("*", "StructureMember", true, false).filter(
			func(m): return not m.broken and not m.burning)
	if members.is_empty():
		return
	var m = members[_rng.randi_range(0, members.size() - 1)]
	if kind == "fire":
		load("res://src/fire/fire_system.gd").find(self).ignite(m)
	else:
		load("res://src/blast/blast.gd").detonate(_street, m.global_position + Vector3(0, 0.3, 0.5), 0.2)
	_happened.append("%s %s at %s" % [_clock(), kind, m.member_id])


## The valley's tour: the player carried along its legs, on the ground.
func _ride(dt: float) -> void:
	_tour_s += TOUR_SPEED * dt
	var s := _tour_s
	var k := 0
	while true:
		var leg := _tour[k].distance_to(_tour[k + 1])
		if s <= leg:
			var p := _tour[k].lerp(_tour[k + 1], s / leg)
			_player.global_position = Vector3(p.x, _ground.height_at(p.x, p.y) + 0.05, p.y)
			_player.velocity = Vector3.ZERO
			return
		s -= leg
		k += 1
		if k >= _tour.size() - 1:
			_tour_s = 0.0
			k = 0
			s = 0.0


## In the valley: a stick on the dirt near the player ("blast"), or a hole dug and filled back in
## (the town's "fire", or "dig").
func _valley_event(kind: String) -> void:
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(8.0, 30.0)
	var x: float = _player.global_position.x + cos(a) * r
	var z: float = _player.global_position.z + sin(a) * r
	var y: float = _ground.height_at(x, z)
	if kind == "blast":
		load("res://src/blast/blast.gd").detonate(_street, Vector3(x, y + 0.03, z), 0.2)
		_happened.append("%s a stick on the dirt at (%.0f, %.1f, %.0f)" % [_clock(), x, y, z])
	else:  # "fire" or "dig": a hole
		var at := Vector3(x, y, z)
		var bank: float = _ground.take(at, 0.9, 0.7)
		_ground.put(at, bank, 0.9)
		_happened.append("%s a hole dug and filled at (%.0f, %.1f, %.0f)" % [_clock(), x, y, z])


func _problem(kind: String, text: String) -> void:
	var list: Array = _problems.get(kind, [])
	if list.size() < 10:
		list.append("%s %s" % [_clock(), text])
		print("soak problem, %s: %s %s" % [kind, _clock(), text])
	_problems[kind] = list


## The process's resident memory (MB), everything in it (the engine, Jolt, the native plugin):
## Linux only, 0 elsewhere.
static func _rss_mb() -> float:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return 0.0
	while not f.eof_reached():  # line by line: /proc files report no length, so get_as_text() is empty
		var line := f.get_line()
		if line.begins_with("VmRSS:"):
			return float(line.split(":")[1].strip_edges().split(" ")[0]) / 1024.0
	return 0.0


## What a lost body is, for the report: where it hangs, what made it, how fast it's going.
func _describe(n: Node) -> String:
	var what := "%s (%s" % [_street.get_path_to(n) if _street.is_ancestor_of(n) else n.get_path(), n.get_class()]
	var sc: Script = n.get_script()
	if sc:
		what += " " + sc.resource_path.get_file()
	if n.has_meta(&"members"):
		var ids: Array = n.get_meta(&"members")
		what += ", %d members: %s" % [ids.size(), ", ".join(ids.slice(0, 3).map(func(i): return String(i)))]
	if n is RigidBody3D:
		var shapes := n.get_children().filter(func(c): return c is CollisionShape3D)
		what += ", %.0f m/s, %d shapes (%d solid)" % [(n as RigidBody3D).linear_velocity.length(), shapes.size(),
				shapes.filter(func(c): return not c.disabled and not c.is_queued_for_deletion()).size()]
	return what + ")"


func _check() -> void:
	var rss := _rss_mb()
	if rss > RUNAWAY_MB and not _runaway:
		_problem("memory", "runaway: %.0f MB resident, stopped early" % rss)
		_runaway = true
	for n in _street.find_children("*", "", true, false):
		if not (n is PhysicsBody3D) or n is StaticBody3D:
			continue
		var p := (n as Node3D).global_position
		if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)):
			_problem("lost", "%s isn't anywhere" % _describe(n))
		elif p.y < (_ground.height_at(p.x, p.z) + FLOOR_Y if _valley else FLOOR_Y):
			_problem("under the ground", "%s at y %.1f" % [_describe(n), p.y])
		elif not _envelope.grow(300.0).has_point(Vector2(p.x, p.z)) if _valley else Vector2(p.x, p.z).length() > MAP_RADIUS:
			_problem("off the map", "%s at %s" % [_describe(n), p])
	# Men gone (left town, freed): a new one of the same name takes his path and, riding in where
	# the last one rode out, would inherit his "not a metre in minutes" (the soak, 2026-10-13).
	for id in _track.keys():
		if not is_instance_id_valid(id):
			_track.erase(id)
	for n in root.get_tree().get_nodes_in_group(&"people"):
		var man = n
		if man.get(&"physiology") == null or not man.is_inside_tree() or not man.physiology.alive:
			continue
		var b = man.get_node_or_null(^"Brain")
		var going := false
		if b and b.get(&"agenda") != null:
			var step: String = String(b.agenda[0].get("do", "")) if not b.agenda.is_empty() else ""
			going = (b.mood == OB.Mood.CALM and step in ["go", "leave", "call_out"]) or b.tactic == OB.Tactic.MOVING
		var key: int = man.get_instance_id()
		if not going or man.limp:
			_track.erase(key)
			continue
		var tr: Dictionary = _track.get(key, {"at": man.global_position, "since": _t})
		if man.global_position.distance_to(tr.at) > 1.0:
			tr = {"at": man.global_position, "since": _t}
		elif _t - float(tr.since) > STUCK_SECONDS:
			var step: Dictionary = b.agenda[0] if not b.agenda.is_empty() else {}
			_problem("stuck", "%s hasn't moved a metre in %.0f s (%s, %s) at %s, going to %s; %s; route %s, brain %s" % [
					man.person_id, _t - float(tr.since), OB.Mood.keys()[b.mood], step.get("do", OB.Tactic.keys()[b.tactic]),
					_v(man.global_position), step.get("to", "?"), b.describe(), b._route.map(_v),
					"on" if b.is_physics_processing() else "off"])
			tr = {"at": man.global_position, "since": _t}
		_track[key] = tr


static func _v(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


func _close_window() -> void:
	var sorted := _frame_ms.duplicate()
	sorted.sort()
	var w := {"t": int(_t), "frame_ms": snappedf(sorted[sorted.size() / 2], 0.01),
		"p99_ms": snappedf(sorted[int(sorted.size() * 0.99)], 0.1),
		"memory_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"people": root.get_tree().get_nodes_in_group(&"people").size(), "rss_mb": snappedf(_rss_mb(), 1.0)}
	w.merge(_census())
	w["unheld"] = w.orphans - w.held
	_windows.append(w)
	_frame_ms = PackedFloat32Array()
	print("soak %s: frame %.2f ms (p99 %.1f), %.0f MB (resident %.0f), %d nodes, %d orphans (%d held), %d people, %d rubble (%d empty), %d members at rest, rubble rest %s, mesh cache %d" % [
			_clock(), w.frame_ms, w.p99_ms, w.memory_mb, w.rss_mb, w.nodes, w.orphans, w.held, w.people, w.rubble,
			w.rubble_empty, w.at_rest, w.rubble_rest, w.mesh_cache])


## What's in the world, each window (#863): the rubble and what's held out of the tree on purpose,
## the mesh cache, and every kind of node counted (the report says which kinds grew).
func _census() -> Dictionary:
	var at_rest := 0
	for m in _street.find_children("*", "StructureMember", true, false):
		if m.resting():
			at_rest += 1
	var rubble := root.get_tree().get_nodes_in_group(&"rubble")
	var empty := 0
	for rb: Node in rubble:
		if rb.get_child_count() == 0 and (rb as CollisionObject3D).get_shape_owners().is_empty():
			empty += 1
	var rest = _street.get_node_or_null(^"RubbleRest")
	var rr := {}
	var rest_held := 0
	if rest:
		var st: Dictionary = rest.state()
		rr = {"pieces": rest.piece_count(), "drawn": st.drawn, "cells": st.cells, "jobs": st.jobs}
		rest_held = rest.held_nodes()
	var kinds := {}
	for n in root.find_children("*", "", true, false):
		var sc: Script = n.get_script()
		var k: String = sc.resource_path.get_file() if sc and sc.resource_path != "" else n.get_class()
		kinds[k] = int(kinds.get(k, 0)) + 1
	if _windows.size() == 1:
		_kinds_first = kinds
	_kinds_last = kinds
	return {"at_rest": at_rest, "held": at_rest * 2 + rest_held, "rubble": rubble.size(), "rubble_empty": empty,
			"rubble_rest": rr, "mesh_cache": load("res://src/structures/member_mesh.gd").cached()}


## Climbing: each of the last four windows above the one before.
func _climbing(key: String) -> bool:
	return climbing(_windows, key)


static func climbing(windows: Array, key: String) -> bool:
	if windows.size() < 5:
		return false
	for i in range(windows.size() - 4, windows.size()):
		if float(windows[i][key]) <= float(windows[i - 1][key]):
			return false
	return true


## The orphan rule (#863): nodes out of the tree less those held on purpose, still climbing and
## 1000 past the first full window's. "" when all's well. (tests/test_soak_rules.gd)
static func orphans_problem(windows: Array) -> String:
	if windows.size() < 3:
		return ""
	var first: Dictionary = windows[1]
	var last: Dictionary = windows[-1]
	if climbing(windows, "unheld") and int(last.unheld) > int(first.unheld) + 1000:
		return "still climbing: %d nodes out of the tree and not held, %d at the start" % [last.unheld, first.unheld]
	return ""


func _finish() -> void:
	OS.remove_logger(_catcher)
	if not _catcher.counts.is_empty():
		for k: String in _catcher.counts:
			_problem("errors", "%s (x%d)" % [k, _catcher.counts[k]])
	if _windows.size() >= 3:
		var first: Dictionary = _windows[1]  # the first window is warming up
		var last: Dictionary = _windows[-1]
		if float(last.frame_ms) > float(first.frame_ms) * CREEP:
			_problem("frame time", "creeping: %.2f ms a frame at the end, %.2f at the start" % [last.frame_ms, first.frame_ms])
		if float(last.memory_mb) > float(first.memory_mb) * MEMORY_GROWTH and _climbing("memory_mb"):
			_problem("memory", "still climbing: %.0f MB at the end, %.0f at the start" % [last.memory_mb, first.memory_mb])
		if _climbing("nodes") and int(last.nodes) > int(first.nodes) * 1.3:
			_problem("nodes", "still climbing: %d at the end, %d at the start" % [last.nodes, first.nodes])
		# Held on purpose (members at rest, rubble in its cell) isn't lost; what's left climbing is.
		var orphans := orphans_problem(_windows)
		if orphans != "":
			_problem("orphans", orphans)
		if int(last.rubble_empty) > 0:
			_problem("rubble", "%d pieces of rubble with nothing left on them" % last.rubble_empty)
	var cache_limit: int = load("res://src/structures/member_mesh.gd").CACHE_LIMIT
	if not _windows.is_empty() and int(_windows[-1].mesh_cache) > cache_limit:
		_problem("mesh cache", "%d sizes, past its %d" % [_windows[-1].mesh_cache, cache_limit])
	var ok := _problems.is_empty()
	DirAccess.make_dir_recursive_absolute(_out)
	var md := "# Soak (%s): %s\n\n%.0f minutes of game time, %s.\n\n" % ["the valley" if _valley else "the town", "passed" if ok else "FAILED", _minutes, load("res://src/debug/debug_overlay.gd").build_label()]
	for kind: String in _problems:
		md += "## %s\n\n" % kind.capitalize()
		for line: String in _problems[kind]:
			md += "- %s\n" % line
		md += "\n"
	md += "## Windows\n\n| t (s) | frame ms | p99 ms | memory MB | resident MB | nodes | orphans | held | people | rubble | at rest | mesh cache |\n|---|---|---|---|---|---|---|---|---|---|---|---|\n"
	for w: Dictionary in _windows:
		md += "| %d | %.2f | %.1f | %.0f | %.0f | %d | %d | %d | %d | %d | %d | %d |\n" % [w.t, w.frame_ms, w.p99_ms, w.memory_mb, w.rss_mb,
				w.nodes, w.orphans, w.held, w.people, w.rubble, w.at_rest, w.mesh_cache]
	md += "\n## The kinds of node that grew most (first window to last)\n\n"
	var grew := []
	for k: String in _kinds_last:
		grew.append([int(_kinds_last[k]) - int(_kinds_first.get(k, 0)), k])
	grew.sort_custom(func(a, b): return a[0] > b[0])
	for g: Array in grew.slice(0, 8):
		md += "- %s: %+d (%d now)\n" % [g[1], g[0], _kinds_last[g[1]]]
	md += "\n## What happened\n\n" + "\n".join(_happened.map(func(h: String) -> String: return "- " + h)) + "\n"
	var f := FileAccess.open(_out.path_join("soak.md"), FileAccess.WRITE)
	f.store_string(md)
	f = FileAccess.open(_out.path_join("soak.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"ok": ok, "problems": _problems, "windows": _windows, "happened": _happened,
			"world": "valley" if _valley else "town"}, "  "))
	print(md)
	# Its work waited for first (#435); loaded, not named: a -s script compiles before the autoloads.
	load("res://src/main/game_quit.gd").quit(self, 0 if ok else 1)
