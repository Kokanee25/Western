extends SceneTree
## Measures average frame time on the test street before and after a shot, with parts of the
## effect switched off, to find what costs the most. Needs a GPU (or lavapipe):
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/perf_probe.gd
## Untyped on purpose: -s scripts compile before autoloads exist.


func _initialize() -> void:
	_run.call_deferred()


func _avg(frames: int) -> float:
	var t0 := Time.get_ticks_usec()
	for i in frames:
		await process_frame
	return (Time.get_ticks_usec() - t0) / 1000.0 / frames


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.get_node(^"Settings").autosave = false
	await process_frame
	var street = main.get_node(^"GameViewport/TestStreet")
	var player = street.get_node(^"Player")
	player.input_enabled = false
	street.get_node(^"DayCycle").set_physics_process(false)
	player.global_position = Vector3(14, 0, -8.4)
	player.rotation = Vector3(0, deg_to_rad(-90), 0)
	var gun = player.get_node(^"Head/Camera3D/Gun")
	for i in 30:
		await process_frame
	print("baseline      %.1f ms" % await _avg(40))
	for mode in ["full", "no_fog_volume", "no_particles", "no_particle_shadows"]:
		for c in root.find_children("*", "GunSmoke", true, false):
			c.free()
		for i in 10:
			await process_frame
		gun.state.busy = 0.0
		gun.state.chambers.fill(1)
		gun.state.cock()
		gun.state.busy = 0.0
		gun.pull_trigger()
		await process_frame
		for s in root.find_children("*", "GunSmoke", true, false):
			if mode == "no_fog_volume":
				for f in s.find_children("*", "FogVolume", true, false):
					f.free()
				s._fog = null
			if mode == "no_particles":
				for p in s.find_children("*", "GPUParticles3D", true, false):
					p.free()
			if mode == "no_particle_shadows":
				for p in s.find_children("*", "GPUParticles3D", true, false):
					p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in 10:
			await process_frame
		print("%-14s %.1f ms" % [mode, await _avg(40)])
	quit()
