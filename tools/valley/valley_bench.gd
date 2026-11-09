extends SceneTree
## The valley's ground on the frame budget (docs/briefs/valley-plan.md §12, G2's gate): the game
## (main scene) in the valley, the player stood at the crossroads, the envelope's four far corners
## and the trestle overlook, each looking over the valley; at each, after the ground's levels have
## settled, the frame, render CPU (the viewport's measured render time: a drawn run), draw calls,
## primitives and the blocks drawn, averaged over `--frames`. Also how long the valley takes to
## load. `--world=town` runs the same at perf_bench's street view, for a reference on this machine.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://tools/valley/valley_bench.gd -- --world=valley [--frames=60] [--out=build/valley_bench.json]
##   godot --headless --fixed-fps 60 -s res://tools/valley/valley_bench.gd -- --world=valley --ride
## --ride: no spots; a ride at a gallop (15 m/s) from the crossroads east past the trestle and on to
## the far corner and back, the ground's own frame (Prof `valley_ground`: choosing and building its
## blocks) each frame, its mean and worst (the levels' streaming as you travel).
## The main line and its train (G3, #716) are in the valley: at each spot the train is put running
## its timetable at the end of the line far from you (from east_start, or from the Ore Works for a
## spot east of the depot), and the train's own systems (Prof `train*`, `people_*` for its engineer)
## are averaged too. `--no-railway` (a game arg, ValleyWorld) is the valley without it: the before.
##
## Scaled to Sean's by FrameBudget's clock_scale (0.65; CLAUDE.md "Frame budget"). Untyped where it
## names game classes: -s scripts compile before autoloads exist.

var frames := 60
var out_path := ""
var ride := false
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="):
			frames = int(a.substr(9))
		elif a.begins_with("--out="):
			out_path = a.substr(6)
		elif a == "--ride":
			ride = true
	_run.call_deferred()


func _spots(world: StringName) -> Array:
	if world != &"valley":
		return [["street", Vector3(11.0, 0.0, -9.0), 121.0]]
	var lay = load("res://src/world/valley_layout.gd").main()
	var env: Rect2 = lay.envelope()
	var mid := env.get_center()
	var out := [["crossroads", Vector3.ZERO, 270.0]]
	for c in [["corner_nw", env.position], ["corner_ne", Vector2(env.end.x, env.position.y)],
			["corner_sw", Vector2(env.position.x, env.end.y)], ["corner_se", env.end]]:
		var at: Vector2 = (c[1] as Vector2).move_toward(mid, 50.0)
		out.append([c[0], Vector3(at.x, 0.0, at.y), _heading(at, mid)])
	var vp: Dictionary = lay.viewpoint("vp_trestle_overlook")
	var o := Vector2(vp.at[0], vp.at[1])
	out.append(["trestle_overlook", Vector3(o.x, 0.0, o.y), _heading(o, mid)])
	return out


## The compass heading (0 north, 90 east) from `a` to `b`.
static func _heading(a: Vector2, b: Vector2) -> float:
	var d := b - a
	return fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)


func _run() -> void:
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	var t0 := Time.get_ticks_usec()
	if settings.world == &"valley":
		load("res://src/world/valley_terrain.gd").main()
	var t1 := Time.get_ticks_usec()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var t2 := Time.get_ticks_usec()
	await process_frame
	var world_root: Node = main.find_child("Valley", true, false) if settings.world == &"valley" else main.find_child("TestStreet", true, false)
	var player = world_root.get_node(^"Player")
	player.input_enabled = false
	var ground = world_root.get_node_or_null(^"Ground")
	var vp: Viewport = main.get_node_or_null(^"GameViewport")
	var rid: RID = vp.get_viewport_rid() if vp else RID()
	if rid.is_valid():
		RenderingServer.viewport_set_measure_render_time(rid, true)
	var budget = load("res://config/frame_budget.tres")
	var scale: float = budget.clock_scale if budget and "clock_scale" in budget else 0.65
	var report := {"world": String(settings.world), "load_ms": {"bake": (t1 - t0) / 1000.0, "scene": (t2 - t1) / 1000.0},
			"clock_scale": scale, "spots": {}}
	print("load: bake %.0f ms, scene %.0f ms" % [report.load_ms.bake, report.load_ms.scene])
	if ride and ground and ground.valley:
		report["ride"] = await _ride(player, ground)
		_write(report)
		quit(0)
		return
	var rw = world_root.get_node_or_null(^"Railway")
	if rw and rw.train:
		var tw := Time.get_ticks_usec()
		while not rw.timed and Time.get_ticks_usec() - tw < 30000000:
			await process_frame
		report.load_ms["timetable_after"] = (Time.get_ticks_usec() - tw) / 1000.0
	for s: Array in _spots(settings.world):
		var at: Vector3 = s[1]
		if ground:
			at.y = ground.height_at(at.x, at.z) + 0.05
		player.global_position = at
		player.velocity = Vector3.ZERO
		player.rotation = Vector3(0.0, -deg_to_rad(float(s[2])), 0.0)
		var tp := Time.get_ticks_usec()
		if ground and ground.valley:
			ground.valley.prime(at + Vector3.UP * 1.6)
		var prime_ms := (Time.get_ticks_usec() - tp) / 1000.0
		var far := _train_far(world_root, at)
		for i in 60:
			await process_frame
		var m := await _measure(rid)
		if far != "":
			m["train_from"] = far
			m["train_s"] = snappedf(float(world_root.get_node(^"Railway").train.sim.s), 0.1)
		m["prime_ms"] = prime_ms
		if ground and ground.valley:
			m["blocks"] = ground.valley.census()
		m["sean_render_cpu_ms"] = snappedf(float(m.render_cpu_ms) * scale, 0.01)
		m["at"] = [at.x, at.y, at.z, s[2]]
		report.spots[s[0]] = m
		print("%-17s frame %.1f ms (p99 %.1f)  render CPU %.2f ms (Sean's %.2f)  draws %d  prims %dk  blocks %s  prime %.0f ms  train %.3f ms  people %.3f ms  nodes %d" % [
				s[0], m.avg_ms, m.p99_ms, m.render_cpu_ms, m.sean_render_cpu_ms, m.draw_calls, m.primitives / 1000.0,
				m.get("blocks", {}).get("by_level", {}), prime_ms, m.train_ms, m.people_ms, m.nodes])
	_write(report)
	quit(0)


func _write(report: Dictionary) -> void:
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "\t"))


## At 15 m/s along a line of legs, the player carried (not walked: the ground's streaming is what's
## measured), the ground's own frame each frame.
func _ride(player: Node3D, ground: Node) -> Dictionary:
	var legs := [Vector2(0, 0), Vector2(1300, 200), Vector2(2300, 2100), Vector2(-1900, 2100), Vector2(-1900, -1300), Vector2(0, 0)]
	var prof = load("res://src/debug/prof.gd")
	prof.on = true
	var speed := 15.0 / 60.0
	var times := PackedFloat32Array()
	var built0: int = ground.valley.built
	var t0 := Time.get_ticks_usec()
	for k in legs.size() - 1:
		var a: Vector2 = legs[k]
		var b: Vector2 = legs[k + 1]
		var steps := ceili(a.distance_to(b) / speed)
		for i in steps:
			var p := a.lerp(b, float(i) / steps)
			player.global_position = Vector3(p.x, ground.height_at(p.x, p.y) + 0.05, p.y)
			player.velocity = Vector3.ZERO
			var before: int = int(prof._sum.get(&"valley_ground", 0))
			await process_frame
			times.append((int(prof._sum.get(&"valley_ground", 0)) - before) / 1000.0)
	var sorted := times.duplicate()
	sorted.sort()
	var avg := 0.0
	for t in times:
		avg += t / times.size()
	var out := {"frames": times.size(), "km": snappedf(times.size() * speed / 1000.0, 0.01), "mean_ms": snappedf(avg, 0.003),
			"p99_ms": snappedf(sorted[int(sorted.size() * 0.99)], 0.01), "max_ms": snappedf(sorted[sorted.size() - 1], 0.01),
			"blocks_built": int(ground.valley.built) - built0, "wall_s": (Time.get_ticks_usec() - t0) / 1e6, "census": ground.valley.census()}
	print("ride: %s" % out)
	return out


## The train running its timetable at the end of the line far from `at`: from east_start (moving
## off), or from the Ore Works for a spot east of the depot. "" with no railway.
func _train_far(world_root: Node, at: Vector3) -> String:
	var rw = world_root.get_node_or_null(^"Railway")
	if rw == null or rw.train == null:
		return ""
	var from := "east_start" if at.x < 600.0 else "ore_works"
	var k := 0 if from == "east_start" else 2
	rw.driving = true
	rw.start_run(float(rw.timetable.stops[k].get("depart", 0.0)) + 30.0, rw.run_day)
	return from


func _measure(rid: RID) -> Dictionary:
	var prof = load("res://src/debug/prof.gd")
	prof.on = true
	var before := {}
	for k in prof._sum:
		before[k] = int(prof._sum[k])
	var times := PackedFloat32Array()
	var render := 0.0
	var draws := 0.0
	var phys := 0.0
	var proc := 0.0
	var prims := 0.0
	var last := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		if rid.is_valid():
			render += RenderingServer.viewport_get_measured_render_time_cpu(rid) / frames
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME) / frames
		phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0 / frames
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0 / frames
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / frames
	var sorted := times.duplicate()
	sorted.sort()
	var avg := 0.0
	for t in times:
		avg += t / times.size()
	var train_us := 0
	var people_us := 0
	var parts := {}
	for k in prof._sum:
		var d := int(prof._sum[k]) - int(before.get(k, 0))
		if String(k) in ["train", "train_view", "train_sound"]:
			train_us += d  # (`train` holds the lookout, the strike, the bridge's carry: not added twice)
		if d / 1000.0 / frames >= 0.005:
			parts[String(k)] = snappedf(d / 1000.0 / frames, 0.003)
		if String(k).begins_with("people") or String(k) == "senses":
			people_us += d
	return {"avg_ms": snappedf(avg, 0.01), "p99_ms": snappedf(sorted[int(sorted.size() * 0.99) - 1], 0.01),
			"render_cpu_ms": snappedf(render, 0.01), "physics_ms": snappedf(phys, 0.01), "process_ms": snappedf(proc, 0.01), "draw_calls": roundi(draws), "primitives": roundi(prims),
			"train_ms": snappedf(train_us / 1000.0 / frames, 0.001), "systems": parts, "people_ms": snappedf(people_us / 1000.0 / frames, 0.001),
			"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}
