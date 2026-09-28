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
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--only="):
			only = arg.substr(7)
	DirAccess.make_dir_recursive_absolute(out)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
		for i in 40:
			await process_frame
		var img := viewport.get_texture().get_image()
		img.save_png("%s/%s.png" % [out, v[0]])
		var big := img.duplicate()
		big.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
		big.save_png("%s/%s_x3.png" % [out, v[0]])
		print("saved ", v[0])
	quit()
