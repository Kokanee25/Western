extends TestCase
## The project loads, the main scene runs, and the pixel pipeline renders the 3D world at the
## internal resolution and scales it to the window with hard pixels.

var main: Node


func before_each() -> void:
	Settings.reset_to_defaults()
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await process_frames(3)


func after_each() -> void:
	main.queue_free()
	await process_frames(2)
	Settings.reset_to_defaults()


func test_main_scene_is_configured() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/main.tscn", "main scene")
	check(main.get_node_or_null(^"GameViewport/TestStreet") != null, "test street is inside the game viewport")
	check(get_tree().get_first_node_in_group(&"player") is Player, "a player exists")
	check(get_tree().get_first_node_in_group(&"day_cycle") is DayCycle, "a day cycle exists")


func test_autoloads_present() -> void:
	for n in ["Events", "Settings", "Controls"]:
		check(get_tree().root.has_node(n), "autoload %s" % n)
	for action in [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"run", &"crouch", &"crouch_toggle", &"look_left", &"debug_time_scale"]:
		check(InputMap.has_action(action), "input action %s" % action)


func test_controller_bindings() -> void:
	var has_pad_move := false
	for ev in InputMap.action_get_events(&"move_forward"):
		if ev is InputEventJoypadMotion and ev.axis == JOY_AXIS_LEFT_Y:
			has_pad_move = true
	check(has_pad_move, "left stick moves")
	var has_pad_look := false
	for ev in InputMap.action_get_events(&"look_right"):
		if ev is InputEventJoypadMotion and ev.axis == JOY_AXIS_RIGHT_X:
			has_pad_look = true
	check(has_pad_look, "right stick looks")
	var has_pad_jump := false
	for ev in InputMap.action_get_events(&"jump"):
		if ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_A:
			has_pad_jump = true
	check(has_pad_jump, "A jumps")


func test_renders_at_internal_resolution() -> void:
	var vp: SubViewport = main.get_node(^"GameViewport")
	check_eq(vp.size, Vector2i(1280, 720), "default internal resolution")
	var screen: TextureRect = main.get_node(^"Screen")
	check_eq(screen.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "nearest-neighbour upscale")
	check(screen.texture == vp.get_texture(), "screen shows the game viewport")
	var camera := vp.get_camera_3d()
	check(camera != null and camera.get_parent().get_parent() is Player, "player camera renders the viewport")


func test_resolution_is_a_setting() -> void:
	var vp: SubViewport = main.get_node(^"GameViewport")
	Settings.set_internal_resolution(Vector2i(320, 180))
	await process_frames(1)
	check_eq(vp.size, Vector2i(320, 180), "viewport follows the setting")
	var screen: TextureRect = main.get_node(^"Screen")
	var window := main.get_viewport().get_visible_rect().size
	check(screen.size.x <= window.x + 0.5 and screen.size.y <= window.y + 0.5, "fits in the window")
	check_near(screen.size.x / screen.size.y, 16.0 / 9.0, 0.02, "keeps aspect")

func test_fit_to_window() -> void:
	var fit: Callable = main.fit_rect
	check_eq(fit.call(Vector2(1920, 1080), Vector2(640, 360), false), Rect2(0, 0, 1920, 1080), "1080p is exactly 3x")
	check_eq(fit.call(Vector2(2560, 1440), Vector2(640, 360), false), Rect2(0, 0, 2560, 1440), "1440p is exactly 4x")
	var wide: Rect2 = fit.call(Vector2(2560, 1080), Vector2(640, 360), false)
	check_eq(wide.size, Vector2(1920, 1080), "ultrawide keeps 16:9")
	check_eq(wide.position, Vector2(320, 0), "and is centred")
	var odd: Rect2 = fit.call(Vector2(1366, 768), Vector2(640, 360), true)
	check_eq(odd.size, Vector2(1280, 720), "integer scaling rounds down to 2x")
	check_eq(odd.position, Vector2(43, 24), "and letterboxes evenly")


func test_modern_lighting_enabled() -> void:
	var env: Environment = (main.get_node(^"GameViewport/TestStreet/WorldEnvironment") as WorldEnvironment).environment
	check(env.fog_enabled, "fog")
	check(env.glow_enabled, "glow")
	check(env.volumetric_fog_enabled, "volumetric fog")
	var sun: DirectionalLight3D = main.get_node(^"GameViewport/TestStreet/Sun")
	check(sun.shadow_enabled, "sun shadows")


func test_build_label() -> void:
	var overlay := load("res://src/debug/debug_overlay.gd")
	check_eq(overlay.build_label(), "dev build", "no stamp: dev build")
	var f := FileAccess.open("res://build_info.json", FileAccess.WRITE)
	f.store_string('{"number": "99", "commit": "abc1234"}')
	f.close()
	check_eq(overlay.build_label(), "build 99 (abc1234)", "CI stamp shows")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://build_info.json"))


func test_master_output_is_protected() -> void:
	var master := AudioServer.get_bus_index(&"Master")
	var limited := false
	var cut := false
	for i in AudioServer.get_bus_effect_count(master):
		var e := AudioServer.get_bus_effect(master, i)
		limited = limited or e is AudioEffectHardLimiter
		cut = cut or e is AudioEffectHighPassFilter
	check(limited, "a limiter on the master output (no clipping)")
	check(cut, "sub-bass cut on the master output")


func test_native_resolution_follows_the_window() -> void:
	var vp: SubViewport = main.get_node(^"GameViewport")
	Settings.set_internal_resolution(Settings.NATIVE)
	await process_frames(1)
	var window := main.get_viewport().get_visible_rect().size
	check_eq(vp.size, Vector2i(window), "renders at the window's own size")
	check(Settings.look_description().begins_with("native"), "described: %s" % Settings.look_description())
	check_eq(Settings.RESOLUTION_PRESETS[-1], Settings.NATIVE, "F2's last stop")
	Settings.reset_to_defaults()
	await process_frames(1)
	check_eq(vp.size, Vector2i(1280, 720), "back to the default")
