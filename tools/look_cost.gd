extends SceneTree
## What a look costs to draw (docs/briefs/renderer.md, "Cost"): the game viewport's measured
## render time, CPU and GPU, and the frame's wall clock, averaged over a still of the saloon
## shot and the street shot at 1280x720. Run it once per look and compare:
##
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://tools/look_cost.gd -- [--blocks | --quantise-once] [--frames=120] [--views=saloon_night,street_golden_hour] [--out=file.json]
##
## The look flags are Settings' own (read from the command line, nothing saved). Under lavapipe
## the "GPU" time is the software rasteriser's CPU time, so only the ratio between looks means
## anything for a real card; the render CPU (the engine's own work a frame) is the number the
## frame budget holds (config/frame_budget.tres). Untyped where it touches game classes: -s
## scripts compile before the autoloads exist.

var frames := 120
var views := ["saloon_night", "street_golden_hour"]
var out := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="):
			frames = int(a.substr(9))
		elif a.begins_with("--views="):
			views = Array(a.substr(8).split(","))
		elif a.begins_with("--out="):
			out = a.substr(6)
	_run.call_deferred()


func _run() -> void:
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	settings.internal_resolution = Vector2i(1280, 720)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var viewport: SubViewport = main.get_node(^"GameViewport")
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var clock = street.get_node(^"DayCycle")
	var player = street.get_node(^"Player")
	var town = main.find_child("TownLife", true, false)
	if town:
		town.gang_arrives = 1e9
	player.input_enabled = false
	clock.set_physics_process(false)
	var shots: Variant = load("res://tools/screenshots.gd")
	var report := {"look": settings.look_description(), "frames": frames, "views": {}}
	for name in views:
		var v: Array = []
		for s in shots.VIEWS:
			if s[0] == name:
				v = s
		if v.is_empty():
			push_error("no view " + str(name))
			continue
		clock.set_time(v[1])
		player.global_position = v[2]
		player.velocity = Vector3.ZERO
		player.rotation = Vector3(0.0, deg_to_rad(v[3]), 0.0)
		player.input_enabled = true
		player.add_look(Vector2(0.0, v[4] - player.get_pitch_degrees()))
		player.input_enabled = false
		for w in player.weapons:
			w.selected = false
			w.drawn = false
			w.visible = false
		for i in 90:
			await process_frame
		var cpu := 0.0
		var gpu := 0.0
		var wall := 0.0
		var draws := 0.0
		var t0 := Time.get_ticks_usec()
		for i in frames:
			await process_frame
			var t1 := Time.get_ticks_usec()
			wall += float(t1 - t0) / 1000.0
			t0 = t1
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid())
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid())
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var r := {"frame_ms": wall / frames, "render_cpu_ms": cpu / frames, "render_gpu_ms": gpu / frames,
				"draw_calls": draws / frames}
		report.views[name] = r
		print("%-20s %-32s frame %6.2f ms  render cpu %5.2f ms  gpu %6.2f ms  draws %5.0f" % [
				name, report.look, r.frame_ms, r.render_cpu_ms, r.render_gpu_ms, r.draw_calls])
	if out != "":
		var fh := FileAccess.open(out, FileAccess.WRITE)
		fh.store_string(JSON.stringify(report, " "))
		fh.close()
	quit()
