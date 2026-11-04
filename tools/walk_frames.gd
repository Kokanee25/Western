extends SceneTree
## A walk down Main Street drawn, every frame timed (#643, the lurch every few steps): the game's
## street loaded as the game loads it, the player set in the street's middle facing west, then
## walked forward for --ticks physics ticks; each drawn frame's wall time, the viewport's measured
## CPU and GPU render time, the ticks it ran and where the eyes were go to --out (CSV). Prints the
## median, p90 and worst frame, the frames over 1.25x the median and how far apart (m) they came:
## a hitch tied to distance walked comes at an even spacing.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 640x360 \
##       -s res://tools/walk_frames.gd -- [--real|--painted] [--sdfgi=on|off] [--ticks=600] \
##       [--out=build/walk_frames.csv] [--limit-ms=25]
##
## --limit-ms: exit 1 if any walking frame is over it (for a real GPU; under lavapipe every frame is
## a second or more, so read the ratios). #643's numbers (lavapipe, 640x360, 600 ticks, 28 m):
## real look with SDFGI 32 frames over 1.25x, worst 1.81x, every ~0.84 m; SDFGI off 8, 1.47x; the
## painted look 18, 1.40x, neither evenly spaced.
## Untyped on purpose: -s scripts compile before autoloads exist.

const X0 := 30.0
const SETTLE_FRAMES := 120  # TAA/FSR2 and SDFGI settle before the walk


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var ticks_to_walk := 600
	var out := "res://build/walk_frames.csv"
	var limit_ms := 0.0
	var sdfgi := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks_to_walk = int(a.substr(8))
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--limit-ms="):
			limit_ms = float(a.substr(11))
		elif a.begins_with("--sdfgi="):
			sdfgi = a.substr(8)
	var settings = root.get_node(^"Settings")
	settings.autosave = false  # --real / --painted are read by Settings itself
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 30:
		await physics_frame
	var player = get_first_node_in_group(&"player")
	var town_layout = load("res://src/world/town_layout.gd")
	player.global_position = Vector3(X0, 0.5, town_layout.street_z(X0))
	player.rotation = Vector3(0.0, PI / 2.0, 0.0)
	if sdfgi != "":
		await process_frame
		var preset = load("res://src/debug/look_preset.gd")
		preset.environment(self).sdfgi_enabled = sdfgi == "on"
	var vp_rid: RID = player.get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	for i in SETTLE_FRAMES:
		await process_frame
	print("walk_frames: real look %s, SDFGI %s, %d ticks from x %.1f" % ["on" if settings.real_look else "off",
			"on" if _sdfgi_on() else "off", ticks_to_walk, X0])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_line("frame,ms,ticks,cam_x,cam_z,footfall,render_cpu_ms,render_gpu_ms")
	var cam: Camera3D = player.get_node(^"Head/Camera3D")
	var start := Engine.get_physics_frames()
	var ph0 := start
	var t0 := Time.get_ticks_usec()
	var frames: Array[float] = []
	var xs: Array[float] = []
	Input.action_press(&"move_forward")
	var i := 0
	while Engine.get_physics_frames() - start < ticks_to_walk:
		await process_frame
		var now := Time.get_ticks_usec()
		var ph := Engine.get_physics_frames()
		var ms := (now - t0) / 1000.0
		f.store_line("%d,%.2f,%d,%.4f,%.4f,%d,%.2f,%.2f" % [i, ms, ph - ph0, cam.global_position.x, cam.global_position.z,
				1 if player.motion.footfall else 0, RenderingServer.viewport_get_measured_render_time_cpu(vp_rid),
				RenderingServer.viewport_get_measured_render_time_gpu(vp_rid)])
		frames.append(ms)
		xs.append(cam.global_position.x)
		t0 = now
		ph0 = ph
		i += 1
	Input.action_release(&"move_forward")
	f.close()
	var sorted := frames.duplicate()
	sorted.sort()
	var med: float = sorted[sorted.size() / 2]
	var worst: float = sorted[-1]
	var over: Array[float] = []
	for k in frames.size():
		if frames[k] > med * 1.25:
			over.append(xs[k])
	var gaps: Array[float] = []
	for k in range(1, over.size()):
		gaps.append(absf(over[k] - over[k - 1]))
	gaps.sort()
	print("walk_frames: %d frames, median %.1f ms, p90 %.1f, worst %.1f (%.2fx the median)" % [frames.size(), med,
			sorted[int(sorted.size() * 0.9)], worst, worst / med])
	print("walk_frames: %d frames over 1.25x the median; their spacing median %.2f m (%s)" % [over.size(),
			gaps[gaps.size() / 2] if not gaps.is_empty() else 0.0, out])
	var code := 0
	if limit_ms > 0.0 and worst > limit_ms:
		print("walk_frames: FAIL, a walking frame of %.1f ms is over %.1f ms" % [worst, limit_ms])
		code = 1
	main.queue_free()
	await process_frame
	quit(code)


func _sdfgi_on() -> bool:
	var preset = load("res://src/debug/look_preset.gd")
	var env = preset.environment(self)
	return env != null and env.sdfgi_enabled
