extends SceneTree
## Renders the test street from fixed views at several times of day and saves PNGs, for
## comparing against docs/concept/. Needs a real (or software) GPU, not --headless:
##   godot --path . -s res://tools/screenshots.gd -- --out=/some/dir [--scale=2]
## Untyped on purpose: -s scripts compile before autoloads exist, so no DayCycle/Player types.
## The views: [name, hour, position, yaw degrees, pitch degrees].

const VIEWS := [
	["street_golden_hour", 17.6, Vector3(11.0, 0.0, -9.0), 121.0, 2.0],
	["store_front_noon", 12.0, Vector3(3.0, 0.0, -9.5), 180.0, 8.0],
	["porch_dusk", 18.7, Vector3(7.5, 0.38, -1.8), 100.0, 0.0],
	["inside_store_afternoon", 16.0, Vector3(1.5, 0.38, 7.8), -20.0, -8.0],
	["inside_store_night", 22.0, Vector3(1.5, 0.38, 7.8), -20.0, -8.0],
	["street_night", 23.0, Vector3(9.0, 0.0, -10.0), 135.0, 4.0],
	["street_morning", 7.0, Vector3(-12.0, 0.0, -7.0), -95.0, 3.0],
	["look_down_body", 15.0, Vector3(3.0, 0.0, -6.0), 180.0, -75.0],
	["gun_hip_range", 16.0, Vector3(14.0, 0.0, -8.4), -90.0, -1.0],
	["gun_aim_range", 16.0, Vector3(14.0, 0.0, -8.4), -90.0, -1.2, "aim"],
	["gun_loading", 16.0, Vector3(14.0, 0.0, -8.4), -90.0, -6.0, "loading"],
	["gun_smoke_saloon", 21.5, Vector3(5.2, 0.38, -27.3), -158.0, -4.0, "shot"],
	["holes_from_inside", 15.0, Vector3(3.0, 0.38, 3.2), 0.0, 2.0, "holes"],
	["wall_closeup_noon", 12.5, Vector3(1.6, 0.38, -1.4), 180.0, 5.0],
	["saloon_front_dusk", 19.0, Vector3(7.0, 0.0, -7.5), 0.0, 8.0],
	["saloon_night", 21.5, Vector3(10.0, 0.38, -18.3), 35.0, -6.0],
	["saloon_back_wall_night", 21.5, Vector3(7.0, 0.38, -19.0), 0.0, 4.0],
	["saloon_toward_door_night", 21.5, Vector3(5.2, 0.38, -27.3), -158.0, -4.0],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://screenshots"
	var only := ""
	var window_shot := false
	var suffix := ""
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--only="):
			only = arg.substr(7)
		# Look experiments: --texels=20 --nomip --shade --res=480x270 --window --suffix=_b
		elif arg.begins_with("--texels="):
			PixelArt.texels_per_meter = float(arg.substr(9))
		elif arg == "--nomip":
			PixelArt.use_mipmaps = false
		elif arg == "--shade":
			settings.pixel_shading = true
		elif arg.begins_with("--res="):
			var wh := arg.substr(6).split("x")
			settings.internal_resolution = Vector2i(int(wh[0]), int(wh[1]))
		elif arg == "--window":
			window_shot = true
		elif arg.begins_with("--suffix="):
			suffix = arg.substr(9)
	if window_shot:
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	DirAccess.make_dir_recursive_absolute(out)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var viewport: SubViewport = main.get_node(^"GameViewport")
	var clock = main.get_node(^"GameViewport/TestStreet/DayCycle")
	var player = main.get_node(^"GameViewport/TestStreet/Player")
	clock.set_physics_process(false)
	player.input_enabled = false
	for v in VIEWS:
		if only != "" and not String(v[0]).contains(only):
			continue
		clock.set_time(v[1])
		player.global_position = v[2]
		player.velocity = Vector3.ZERO
		player.rotation = Vector3(0.0, deg_to_rad(v[3]), 0.0)
		player.input_enabled = true
		player.add_look(Vector2(0.0, v[4] - player.get_pitch_degrees()))
		player.input_enabled = false
		var gun = player.get_node_or_null(^"Head/Camera3D/Gun")
		var setup: String = v[5] if v.size() > 5 else ""
		if gun:
			gun.aiming = setup == "aim"
			if setup == "loading" and not gun.state.gate_open:
				gun.state.busy = 0.0
				gun.state.open_gate()
			elif setup != "loading" and gun.state.gate_open:
				gun.state.busy = 0.0
				gun.state.close_gate()
		if setup == "shot" and gun:
			gun.state.busy = 0.0
			gun.state.cock()
			gun.state.busy = 0.0
			gun.pull_trigger()
			for i in 90:
				await physics_frame
		if setup == "holes" and gun:
			# Shoot the front wall from the boardwalk, then look at it from inside.
			var inside: Vector3 = player.global_position
			player.global_position = Vector3(3.0, 0.38, -2.0)
			player.rotation = Vector3(0.0, PI, 0.0)
			for k in 7:
				player.input_enabled = true
				player.add_look(Vector2([-22, -15, 16, 24, -18, 20, -26][k] - (0.0 if k == 0 else [-22, -15, 16, 24, -18, 20, -26][k - 1]), ([8, -2, 4, 12, 20, 22, -6][k]) - player.get_pitch_degrees()))
				player.input_enabled = false
				await physics_frame
				gun.state.busy = 0.0
				if gun.state.rounds_loaded() == 0:
					gun.state.chambers.fill(RevolverState.Chamber.LOADED)
				gun.state.cock()
				gun.state.busy = 0.0
				gun.pull_trigger()
				for i in 12:
					await physics_frame
			for i in 30:
				await physics_frame
			for n in get_nodes_in_group(&"spent_cases"):
				n.queue_free()
			for c in root.find_children("*", "GunSmoke", true, false):
				c.queue_free()
			player.global_position = inside
			player.rotation = Vector3(0.0, deg_to_rad(v[3]), 0.0)
			player.input_enabled = true
			player.add_look(Vector2(0.0, v[4] - player.get_pitch_degrees()))
			player.input_enabled = false
			gun.toggle_holster()
		for i in 40:
			await process_frame
		if window_shot:
			root.get_texture().get_image().save_png("%s/%s%s.png" % [out, v[0], suffix])
			print("saved ", v[0])
			continue
		var img := viewport.get_texture().get_image()
		img.save_png("%s/%s.png" % [out, v[0]])
		var big := img.duplicate()
		big.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
		big.save_png("%s/%s_x3.png" % [out, v[0]])
		print("saved ", v[0])
	quit()
