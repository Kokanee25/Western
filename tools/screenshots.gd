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
	["window_shot", 13.0, Vector3(1.1, 0.38, -2.2), 180.0, -8.0, "window"],
	["smoke_drift_street", 16.0, Vector3(14.0, 0.0, -8.4), -60.0, 2.0, "drift"],
	["wall_closeup_noon", 12.5, Vector3(1.6, 0.38, -1.4), 180.0, 5.0],
	["saloon_front_dusk", 19.0, Vector3(7.0, 0.0, -7.5), 0.0, 8.0],
	["saloon_night", 21.5, Vector3(10.0, 0.38, -18.3), 35.0, -6.0],
	["saloon_back_wall_night", 21.5, Vector3(7.0, 0.38, -19.0), 0.0, 4.0],
	["outlaw_range", 15.0, Vector3(17.0, 0.0, -12.5), -90.0, -2.0],
	["outlaw_close", 15.0, Vector3(23.6, 0.0, -12.3), -95.0, -8.0],
	["outlaw_fight", 15.0, Vector3(16.0, 0.0, -12.5), -90.0, 0.0, "outlaw_fight"],
	["outlaw_surrender", 15.0, Vector3(22.0, 0.0, -12.2), -94.0, -3.0, "outlaw_surrender"],
	["outlaw_down", 15.0, Vector3(23.2, 0.0, -12.0), -100.0, -45.0, "outlaw_down"],
	["outlaw_graze", 15.0, Vector3(25.1, 0.0, -11.3), 5.0, -12.0, "outlaw_graze"],
	["outlaw_open", 15.0, Vector3(23.9, 0.0, -12.45), -90.0, -12.0, "outlaw_open"],
	["outlaw_open_close", 15.0, Vector3(24.45, 0.0, -12.5), -90.0, -18.0, "outlaw_open"],
	["outlaw_open_reduced", 15.0, Vector3(23.9, 0.0, -12.45), -90.0, -12.0, "outlaw_open_reduced"],
	["outlaw_neck", 15.0, Vector3(22.8, 0.0, -11.6), -115.0, -4.0, "outlaw_neck"],
	["outlaw_xray", 15.0, Vector3(22.9, 0.0, -12.5), -90.0, -8.0, "outlaw_xray"],
	["porch_collapse", 15.0, Vector3(1.5, 0.0, -8.0), 165.0, 6.0, "porch_collapse"],
	["store_fire_night", 21.0, Vector3(3.0, 0.0, -11.0), 180.0, 10.0, "store_fire"],
	["store_fire_close", 21.0, Vector3(1.4, 0.0, -4.2), 175.0, 12.0, "store_fire"],
	["store_fire_later", 21.0, Vector3(3.0, 0.0, -13.0), 180.0, 12.0, "store_fire_later"],
	["saloon_toward_door_night", 21.5, Vector3(5.2, 0.38, -27.3), -158.0, -4.0],
	["outlaw_face", 15.0, Vector3(24.0, 0.0, -12.5), -90.0, 0.0, "outlaw_calm"],
	["outlaw_face_evening", 18.2, Vector3(24.0, 0.0, -12.5), -90.0, 0.0, "outlaw_calm"],
	["outlaw_side", 15.0, Vector3(25.0, 0.0, -14.4), 180.0, -12.0, "outlaw_calm"],
	["outlaw_back", 15.0, Vector3(27.2, 0.0, -12.5), 90.0, -12.0, "outlaw_calm"],
	["gun_at_wall", 16.0, Vector3(1.5, 0.38, 7.5), 90.0, -4.0, "wall"],
	["gun_at_wall_aim", 16.0, Vector3(1.5, 0.38, 7.5), 90.0, -4.0, "wall_aim"],
	["shotgun_hip_range", 16.0, Vector3(14.0, 0.0, -8.4), -90.0, -1.0, "sg_hip"],
	["shotgun_aim_range", 16.0, Vector3(14.0, 0.0, -8.4), -90.0, -1.2, "sg_aim"],
	["shotgun_open", 16.0, Vector3(14.0, 0.0, -8.4), -90.0, -10.0, "sg_open"],
	["shotgun_shot_saloon", 21.5, Vector3(5.2, 0.38, -27.3), -158.0, -4.0, "sg_shot"],
	["dynamite_lit", 16.0, Vector3(14.0, 0.0, -8.4), -90.0, -4.0, "dy_lit"],
	["dynamite_store_blast", 13.0, Vector3(3.0, 0.0, -9.5), 180.0, 8.0, "store_blast"],
	["dynamite_store_after", 13.0, Vector3(3.0, 0.0, -9.5), 180.0, 8.0, "store_blast_after"],
	["outlaw_blast", 15.0, Vector3(23.2, 0.0, -12.0), -100.0, -40.0, "outlaw_blast"],
	["outlaw_wary", 15.0, Vector3(20.0, 0.0, -12.5), -90.0, -4.0, "outlaw_wary"],
	["outlaw_covering_you", 15.0, Vector3(20.0, 0.0, -12.5), -90.0, -4.0, "outlaw_covering"],
	["outlaw_in_cover", 15.0, Vector3(14.0, 0.0, -8.4), -60.0, -3.0, "outlaw_cover"],
	["outlaw_peeking", 15.0, Vector3(14.0, 0.0, -8.4), -60.0, -3.0, "outlaw_peek"],
	["outlaw_buckshot_room", 15.0, Vector3(23.9, 0.0, -12.45), -90.0, -12.0, "outlaw_buckshot_room"],
	["outlaw_buckshot", 15.0, Vector3(23.9, 0.0, -12.45), -90.0, -12.0, "outlaw_buckshot"],
	["outlaw_buckshot_close", 15.0, Vector3(24.45, 0.0, -12.5), -90.0, -18.0, "outlaw_buckshot"],
	["shot_match_saloon", 23.67, Vector3(9.12, 0.38, -26.2), 180.0, -8.0, "shot_match"],
	# The street painting's shot (src/art/street_match.gd sets the place, turn and lens).
	["shot_match_street", 17.6, Vector3(3.0, 0.0, -7.4), 100.0, 0.0, "street_match"],
	["coat_hands_up", 18.0, Vector3(0.0, 0.0, -9.0), -90.0, 0.0, "coat_hands_up"],
	["portrait_day", 17.5, Vector3(20.0, 0.0, -12.5), -90.0, 0.0, "portrait"],
	["shot_match_close", 23.67, Vector3(9.12, 0.38, -26.2), 180.0, -8.0, "shot_match_close"],
	["town_holdup", 15.0, Vector3(2.0, 0.38, 1.3), -128.0, -6.0, "town_holdup"],
	["town_bar", 15.0, Vector3(7.4, 0.38, -18.4), 22.0, -6.0, "town_bar"],
	["town_duel", 18.0, Vector3(-1.0, 0.0, -9.0), -90.0, -1.0, "town_duel"],
	# Tile lighting comparisons (render with --tiles=off and without): low sun, shadow edges
	# falling across timber and ground close to the camera.
	["texel_rail_shadow", 17.0, Vector3(5.2, 0.0, -6.2), 170.0, -38.0],
	["texel_porch", 17.0, Vector3(2.0, 0.0, -4.8), 180.0, -12.0],
	["texel_store_golden", 17.6, Vector3(3.0, 0.0, -7.5), 180.0, 6.0],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://screenshots"
	var only := ""
	var window_shot := false
	var screen_squares := 0.0
	var mosaic_steps := 14.0
	var suffix := ""
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--only="):
			only = arg.substr(7)
		# --only=a,b renders every view whose name contains a or b.
		elif arg.begins_with("--model="):
			# The seated man's body (outlaw, stranger). Loaded at run time: naming ShotMatch here
			# makes the game's scripts compile with this one, before the autoloads exist.
			var shot: Variant = load("res://src/art/shot_match.gd")
			shot.model = StringName(arg.substr(8))
		# Look experiments: --texels=20 --nomip --shade --no-finish --res=480x270 --tiles=ragged --window --suffix=_b
		elif arg.begins_with("--texels="):
			PixelArt.texels_per_meter = float(arg.substr(9))
		elif arg == "--nomip":
			PixelArt.use_mipmaps = false
		elif arg == "--shade":
			settings.pixel_shading = true
		elif arg == "--no-finish":
			settings.set_finish(false)
		elif arg.begins_with("--res="):
			var wh := arg.substr(6).split("x")
			settings.internal_resolution = Vector2i(int(wh[0]), int(wh[1]))
		elif arg.begins_with("--tiles="):
			settings.set_tile_look(StringName(arg.substr(8)))
		elif arg.begins_with("--min-square="):
			RenderingServer.global_shader_parameter_set(&"min_square_px", float(arg.substr(13)))
		elif arg.begins_with("--screen-squares="):
			screen_squares = float(arg.substr(17))
		# The painting's mosaic in screen space (DepthMosaic, on by default: Settings.mosaic):
		# --mosaic=5 (block px x metres), --steps=14 (tones of light, 0 smooth), --no-mosaic.
		elif arg.begins_with("--mosaic="):
			screen_squares = float(arg.substr(9))
		elif arg == "--no-mosaic":
			settings.set_mosaic(false)
		# The voxel trial (src/art/voxel_trial.gd): --voxel=props,hat,eyes or all; --cubes=64.
		elif arg.begins_with("--voxel="):
			var trial: Variant = load("res://src/art/voxel_trial.gd")
			var which := arg.substr(8)
			trial.props = which == "all" or "props" in which
			trial.hat = which == "all" or "hat" in which
			trial.eyes = which == "all" or "eyes" in which
		elif arg.begins_with("--cubes="):
			load("res://src/art/voxel_trial.gd").cubes = int(arg.substr(8))
		elif arg.begins_with("--steps="):
			mosaic_steps = float(arg.substr(8))
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
	if screen_squares > 0.0:
		load("res://src/render/depth_mosaic.gd").attach(player.camera, screen_squares, mosaic_steps)
	clock.set_physics_process(false)
	player.input_enabled = false
	for v in VIEWS:
		if only != "" and not Array(only.split(",")).any(func(o: String) -> bool: return String(v[0]).contains(o)):
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
		var sg = player.get_node_or_null(^"Head/Camera3D/Shotgun")
		if sg and gun:
			_hold(player, gun, sg, setup.begins_with("sg_"))
		var dy = player.get_node_or_null(^"Head/Camera3D/Dynamite")
		if dy and setup == "dy_lit":
			_hold(player, gun, dy, true)
			dy.lit = true
			dy.fuse_left = 1000.0  # frames are slow here; it mustn't go off in the picture
			sg.visible = false
		elif dy and dy.visible:
			dy.selected = false
			dy.drawn = false
			dy._draw = 0.0
			dy.visible = false
		if setup.begins_with("store_blast"):
			var store = main.find_child("Store", true, false)
			var m = store.get_member(&"store/front/siding/r02_0")
			var n: Vector3 = m.global_basis.z.normalized()
			if n.dot(m.global_position - store.global_position) < 0.0:
				n = -n
			for k in 2:
				load("res://src/blast/blast.gd").detonate(main.find_child("TestStreet", true, false), Vector3(m.global_position.x + 0.6 * k, 0.5, m.global_position.z) + n * 0.3, 0.15)
			var wait := 6 if setup == "store_blast" else 240
			for i in wait:
				await physics_frame
		if sg and setup.begins_with("sg_"):
			sg.aiming = setup == "sg_aim"
			sg.state.busy = 0.0
			if setup == "sg_open" and not sg.state.open:
				sg.state.open_action()
			elif setup != "sg_open" and sg.state.open:
				sg.state.close_action()
			sg.state.busy = 0.0
			if setup == "sg_shot":
				sg.state.cock()
				sg.state.busy = 0.0
				sg.pull_trigger()
				for i in 90:
					await physics_frame
		if setup == "shot" and gun:
			gun.state.busy = 0.0
			gun.state.cock()
			gun.state.busy = 0.0
			gun.pull_trigger()
			for i in 90:
				await physics_frame
		if setup == "window" and gun:
			gun.state.busy = 0.0
			gun.state.cock()
			gun.state.busy = 0.0
			gun.pull_trigger()
			for i in 50:
				await physics_frame
		if setup == "drift" and gun:
			for k in 3:
				gun.state.busy = 0.0
				gun.state.cock()
				gun.state.busy = 0.0
				gun.pull_trigger()
				for i in 20:
					await physics_frame
			for i in 240:
				await physics_frame
		if setup == "store_fire" or setup == "store_fire_later":
			var store = main.find_child("Store", true, false)
			var fire = main.find_child("FireSystem", true, false)
			fire.ignite(store.get_member(&"store/front/siding/r02_0"))
			fire.ignite(store.get_member(&"store/front/siding/r02_1"))
			fire.ignite(store.get_member(&"store/porch/post0"))
			var sim := 40 if setup == "store_fire" else 130
			for i in sim:
				fire.step(0.5)
			for i in 90:
				await physics_frame
		if setup == "porch_collapse":
			var store = main.find_child("Store", true, false)
			store.break_member(store.get_member(&"store/porch/post0"), Vector3(0, 0, -1.0))
			for i in 200:
				await physics_frame
		if setup.begins_with("wall"):
			# Walk up until the eye is 0.36 m from whatever is straight ahead (the capsule's 0.3 m
			# radius stops you about there): the gun should tuck back, not poke through.
			gun.aiming = setup == "wall_aim"
			await physics_frame
			var cam = player.get_node(^"Head/Camera3D")
			var fwd: Vector3 = -(cam.global_transform.basis.z as Vector3)
			var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + fwd * 8.0, 1)
			q.exclude = [player.get_rid()]
			var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(q)
			if not hit.is_empty():
				var flat := Vector3(fwd.x, 0, fwd.z).normalized()
				player.global_position += flat * (Vector2(hit.position.x - cam.global_position.x, hit.position.z - cam.global_position.z).length() - 0.36)
			for i in 30:
				await physics_frame
		if setup.begins_with("outlaw_"):
			await _outlaw_setup(main, setup, player)
		if setup.begins_with("town_"):
			await _town_setup(main, setup, player)
		if setup == "portrait":
			await _portrait_setup(main, player)
		if setup == "coat_hands_up":
			var town = main.find_child("TownLife", true, false)
			town.bring_gang([&"brody"])
			var man = town.gang[0]
			man.get_node("Brain").set_physics_process(false)
			man.global_position = Vector3(3.5, 0.0, -9.0)
			man.rotation.y = -PI * 0.5
			man.set_pose(&"hands_up")
			for i in 60:
				await physics_frame
		if setup == "street_match":
			var sm = load("res://src/art/street_match.gd")
			sm.stage(main.find_child("TestStreet", true, false))
			# Undo what an earlier staged view (the saloon's) left: player still, body hidden, gun away.
			player.set_physics_process(true)
			player.body.visible = true
			_hold(player, gun, sg, false)
			gun.visible = true
			sm.frame_camera(player)
			for i in 60:
				await physics_frame
			sm.frame_camera(player)
		if setup == "shot_match" or setup == "shot_match_close":
			await _shot_match_setup(main, player, setup == "shot_match_close")
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


## Put the shotgun in the hands at once (or the revolver back).
func _hold(player, gun, sg, shotgun: bool) -> void:
	var take = sg if shotgun else gun
	var leave = gun if shotgun else sg
	leave.selected = false
	leave.drawn = false
	leave._draw = 0.0
	leave.visible = false
	take.selected = true
	take.drawn = true
	take._draw = 1.0
	player.weapon = take
	if player.body:
		player.body.set_gun_holstered(shotgun)


## Face to face with the range outlaw, as close as you'd stand to talk (the view in Sean's
## screenshot): his brain off so he stays put, the camera 0.9 m from his face.
func _portrait_setup(main, player) -> void:
	var spawner = main.find_child("OutlawSpawn", true, false)
	var man = spawner.spawn()
	man.get_node("Brain").set_physics_process(false)
	var gun = player.get_node(^"Head/Camera3D/Gun")
	gun._draw = 0.0
	load("res://src/art/shot_match.gd").hands_off_camera(player)
	player.set_physics_process(false)
	player.body.visible = false
	for i in 30:
		await physics_frame
	var head = man.parts[&"head"]
	var at: Vector3 = head.global_position + Vector3(0, -0.05, 0)
	var eye: Vector3 = at + (-man.global_basis.z) * 0.9 + Vector3(0, 0.03, 0)
	player.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
	player.camera.fov = 40.0


## The painting's shot (src/art/shot_match.gd): sat at the card table, the man across the lamp.
func _shot_match_setup(main, player, close := false) -> void:
	var street = main.find_child("TestStreet", true, false)
	var spawner = main.find_child("OutlawSpawn", true, false)
	if spawner.outlaw:
		spawner.outlaw.queue_free()
	var town = main.find_child("TownLife", true, false)
	town.gang_arrives = 1e9
	var sm = load("res://src/art/shot_match.gd")
	sm.stage(street)
	var gun = player.get_node(^"Head/Camera3D/Gun")
	gun._draw = 0.0
	player.set_physics_process(false)
	player.body.visible = false
	for i in 30:
		await physics_frame
	sm.frame_camera(player, street)
	if close:
		# His face and chest, from in front of him across the table.
		var head = street.find_child("SeatedMan", true, false).parts[&"head"]
		var at: Vector3 = head.global_position + Vector3(0, -0.12, 0)
		var eye: Vector3 = at + head.global_basis.z * -0.0 + (-head.global_basis.z) * 0.9 + Vector3(0, 0.05, 0)
		player.camera.global_transform = Transform3D(Basis.looking_at(at - eye, Vector3.UP), eye)
		player.camera.fov = 40.0


## Stage the town's day: Lyle holding up the storekeeper; the gang at the bar; Lyle facing you
## in the street.
func _town_setup(main, setup, player) -> void:
	var spawner = main.find_child("OutlawSpawn", true, false)
	if spawner.outlaw:
		spawner.outlaw.queue_free()
	var town = main.find_child("TownLife", true, false)
	for i in 5:
		await physics_frame
	var places = town.places
	if setup == "town_holdup":
		town.bring_gang([&"lyle"])
		var lyle = town.gang[0]
		lyle.global_position = places.at(&"store_counter")
		lyle.get_node("Brain").agenda.assign([{"do": &"harass", "who": town.storekeeper, "seconds": 999.0, "rough": true, "draw_after": 0.5}])
		for i in 150:
			await physics_frame
	elif setup == "town_bar":
		town.bring_gang()
		for g in town.gang:
			var b = g.get_node("Brain")
			g.global_position = places.at(b.bar_spot)
			b.agenda.assign([{"do": &"drink", "seconds": 999.0, "face": places.at(b.bar_spot) + Vector3(-2.0, 1.2, 0.0)}])
		for i in 60:
			await physics_frame
	elif setup == "town_duel":
		# Your gun in its holster: nobody's drawn yet.
		var rev = player.get_node(^"Head/Camera3D/Gun")
		rev.drawn = false
		rev._draw = 0.0
		rev.visible = false
		town.bring_gang([&"lyle"])
		var lyle = town.gang[0]
		lyle.global_position = Vector3(6.0, 0.0, -9.0)
		lyle.get_node("Brain").agenda.assign([{"do": &"duel", "who": player}])
		for i in 60:
			await physics_frame
		lyle.get_node("Brain").set_physics_process(false)


## Stage the test outlaw: provoked and shooting, shot and surrendering, or dead on the ground.
func _outlaw_setup(main, setup, player) -> void:
	var spawner = main.find_child("OutlawSpawn", true, false)
	var man = spawner.spawn()
	for i in 5:
		await physics_frame
	var brain = man.get_node("Brain")
	var ballistics = main.find_child("Ballistics", true, false)
	var eye = player.global_position + Vector3.UP * 1.6
	var parts = man.parts
	var t = load("res://config/revolver.tres")
	var targets = []
	if setup == "outlaw_fight":
		targets = [man.global_position + Vector3(0.0, 1.7, 0.9)]
	elif setup == "outlaw_neck" or setup == "outlaw_xray":
		brain.set_physics_process(false)
		# Through the side of the neck, in front of the spine: both carotids, not the cord.
		var neck = parts[&"neck"]
		var at = neck.global_transform * Vector3(0.0, -0.015, -0.022)
		targets = [[at - man.global_basis.x * 3.0, at]]
		if setup == "outlaw_xray":
			targets.append(parts[&"upper_arm_r"].global_position)
	elif setup == "outlaw_open" or setup == "outlaw_open_reduced":
		brain.set_physics_process(false)
		root.get_node(^"Settings").reduced_gore = setup == "outlaw_open_reduced"
		man.open_wound(&"chest", Vector3(-0.05, 0.02, -0.125), 1600.0)
		man.open_wound(&"abdomen", Vector3(0.04, -0.02, -0.12), 900.0)
		man.physiology.step(30.0)
	elif setup == "outlaw_buckshot" or setup == "outlaw_buckshot_room":
		brain.set_physics_process(false)
		# Kept on his feet for the picture (he'd go down).
		man.physiology.tuning = man.physiology.tuning.duplicate()
		man.physiology.tuning.knockdown_max = 0.0
		man.set_physics_process(false)
		var st = load("res://config/shotgun.tres")
		var chest = parts[&"chest"].global_position + man.global_basis * Vector3(0.04, 0.02, 0.0)
		var front = -man.global_basis.z
		var from = chest + front * (0.3 if setup == "outlaw_buckshot" else 7.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		var ex: Array[RID] = [player.get_rid()]
		ballistics.fire_charge(from, (chest - from).normalized(), st.pellets, deg_to_rad(st.pattern_degrees),
				st.muzzle_velocity, st.pellet_mass, st.pellet_diameter, ex, rng, st.blast_joules, st.blast_reach)
		for i in 10:
			await physics_frame
		for i in 60:
			await physics_frame
	elif setup == "outlaw_wary" or setup == "outlaw_covering":
		brain.nerve = 99.0
		var rev = player.get_node(^"Head/Camera3D/Gun")
		if setup == "outlaw_wary":
			player.rotation = Vector3(0.0, deg_to_rad(-60.0), 0.0)  # gun out, not on him
		rev.needs_captured_mouse = false
		rev.take_out()
		var want = 2 if setup == "outlaw_wary" else 4  # Relations.Stance WARY / THREAT
		for i in 900:
			await physics_frame
			if brain.relations.stance(player) >= want and i > 60:
				break
		for i in 40:
			await physics_frame
		brain.set_physics_process(false)
		player.rotation = Vector3(0.0, deg_to_rad(-90.0), 0.0)
	elif setup == "outlaw_cover" or setup == "outlaw_peek":
		brain.nerve = 99.0
		var from = player.get_node(^"Head/Camera3D").global_position
		var near = man.global_position + Vector3(0.0, 1.6, 1.0)
		var ex: Array[RID] = [player.get_rid()]
		var b = ballistics.fire(from, (near - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, ex)
		b.shooter = player
		var want = 2 if setup == "outlaw_cover" else 3  # OutlawBrain.Tactic.HIDDEN / PEEKING
		for i in 900:
			await physics_frame
			if brain.tactic == want and i > 60:
				break
		for i in 20:
			await physics_frame
		# Freeze him as he is for the picture.
		brain.set_physics_process(false)
	elif setup == "outlaw_blast":
		brain.set_physics_process(false)
		var foot = parts[&"foot_l"].global_position
		load("res://src/blast/blast.gd").detonate(man.get_parent(), foot + (-man.global_basis.z) * 0.15 + Vector3.UP * 0.05, 0.15)
		for i in 150:
			await physics_frame
		man.physiology.step(0.0)
	elif setup == "outlaw_graze":
		brain.set_physics_process(false)
		# Skimming the outside of his left upper arm and left thigh.
		var arm = parts[&"upper_arm_l"]
		var a = arm.global_transform * (Vector3(-0.258, 1.28, 0.0) - man.anatomy.segment_center(&"upper_arm_l"))
		var thigh = parts[&"thigh_l"]
		var b = thigh.global_transform * (Vector3(-0.166, 0.72, 0.0) - man.anatomy.segment_center(&"thigh_l"))
		var along = -man.global_basis.z
		targets = [[a - along * 3.0, a], [b - along * 3.0, b]]
	elif setup == "outlaw_surrender":
		brain.nerve = 99.0
		targets = [parts[&"abdomen"].global_position + Vector3(0, 0.03, -0.06), parts[&"thigh_l"].global_position + Vector3(0, 0.08, 0.06)]
	elif setup == "outlaw_down":
		targets = [parts[&"chest"].global_position + Vector3(0, 0.02, 0.05)]
	var exclude: Array[RID] = [player.get_rid()]
	for target in targets:
		var from = eye
		if target is Array:
			from = target[0]
			target = target[1]
		var b = ballistics.fire(from, (target - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, exclude)
		b.shooter = player
		for i in 10:
			await physics_frame
	if setup == "outlaw_fight":
		for i in 70:
			await physics_frame
	elif setup == "outlaw_neck":
		for i in 50:
			await physics_frame
	elif setup == "outlaw_graze":
		man.physiology.step(20.0)
		for i in 20:
			await physics_frame
	elif setup == "outlaw_xray":
		man.set_xray(true)
		for i in 5:
			await physics_frame
	elif setup == "outlaw_surrender":
		man.physiology.step(40.0)
		brain.set_physics_process(true)
		brain._surrender()
		for i in 60:
			await physics_frame
	elif setup == "outlaw_down":
		man.physiology.blood_ml = 2400.0
		for i in 150:
			await physics_frame
		man.physiology.step(0.0)
		for i in 30:
			await physics_frame
	player.wounds.physiology = Physiology.new()
