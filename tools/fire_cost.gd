extends SceneTree
## What the fire's flames cost to draw (the art session's; docs/briefs/fire-look.md, the flipbooks):
## the livery with every member alight and grown (a building fully alight), seen from the fire
## painting's view (livery_fire_dusk), measured three ways in one run: the drawn fire sheets
## (fire_sheet.gdshader), the simulated flipbooks (FireFlipbook: haze, core, tips), and with the
## flames hidden (what's left: the char, the smoke, the lights). Each is the frame's wall clock and
## the game viewport's measured render time, CPU and GPU, averaged over `frames`.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://tools/fire_cost.gd -- [--frames=180] [--out=file.json]
##
## Under lavapipe the GPU time is the software rasteriser's, so only the ratio means anything for
## a real card; the render CPU is what the frame budget holds. Untyped where it touches the game's
## classes: -s scripts compile before the autoloads exist.

var frames := 180
var out := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="):
			frames = int(a.substr(9))
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
	var view: Array = []
	for s in load("res://tools/screenshots.gd").VIEWS:
		if s[0] == "livery_fire_dusk":
			view = s
	clock.set_time(view[1])
	player.global_position = view[2]
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, deg_to_rad(view[3]), 0.0)
	player.input_enabled = true
	player.add_look(Vector2(0.0, view[4] - player.get_pitch_degrees()))
	player.input_enabled = false
	for w in player.weapons:
		w.selected = false
		w.drawn = false
		w.visible = false
	# Every member of the livery alight and grown (the fire's growth_seconds, and a little more).
	var livery = main.find_child("Livery", true, false)
	var fire = main.find_child("FireSystem", true, false)
	var members: Array = livery.get_members()
	for m in members:
		if m.wood != &"glass":
			fire.ignite(m)
	for i in 80:
		fire.step(0.5)
	var report := {"frames": frames, "members": members.size(), "modes": {}}
	var ffx: Variant = load("res://src/fire/fire_fx.gd")
	for mode in ["sheets", "flipbooks", "hidden"]:
		ffx.flipbooks = mode == "flipbooks"
		# FireFX swaps a share of the members' sheets a frame (FireSystem._refresh_fx).
		for i in 150:
			await process_frame
		var sheets := 0
		var burning := 0
		for m in members:
			if m.burning:
				burning += 1
		for n in main.find_children("*", "MeshInstance3D", true, false):
			if n.has_meta(&"flame"):
				sheets += 1
				n.visible = mode != "hidden"
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
				"draw_calls": draws / frames, "burning": burning, "sheets": sheets}
		report.modes[mode] = r
		print("fire_cost %-10s burning %3d sheets %3d  frame %7.2f ms  render cpu %5.2f ms  gpu %7.2f ms  draws %5.0f" % [
				mode, burning, sheets, r.frame_ms, r.render_cpu_ms, r.render_gpu_ms, r.draw_calls])
	if out != "":
		var fh := FileAccess.open(out, FileAccess.WRITE)
		fh.store_string(JSON.stringify(report, " "))
		fh.close()
	quit()
