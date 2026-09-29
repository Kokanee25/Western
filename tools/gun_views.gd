extends SceneTree
## Renders the shotgun viewmodel (gun and hands) alone, for checking its shape:
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/gun_views.gd -- out.png --view=side|eye|top [--open]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(900, 500)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.6, 0.65, 0.7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	w.add_child(sun)
	var holder := Camera3D.new()  # a parent camera so the viewmodel is happy; not current
	w.add_child(holder)
	var sg = load("res://src/weapons/shotgun_viewmodel.gd").new()
	holder.add_child(sg)
	await process_frame
	sg.set_process(false)
	sg.position = Vector3.ZERO
	sg.rotation = Vector3.ZERO
	var args := OS.get_cmdline_user_args()
	if args.has("--open"):
		sg.model.barrels.rotation_degrees.x = -32.0
	var cam := Camera3D.new()
	w.add_child(cam)
	var view := "side"
	for a in args:
		if a.begins_with("--view="):
			view = a.substr(7)
	match view:
		"side":
			cam.position = Vector3(1.2, 0.0, -0.15)
			cam.rotation_degrees = Vector3(0, 90, 0)
			cam.fov = 45
		"eye":
			cam.position = Vector3(0, 0.056, 0.32)
			cam.fov = 75
			cam.near = 0.05
		"top":
			cam.position = Vector3(0, 1.2, -0.15)
			cam.rotation_degrees = Vector3(-90, 0, 0)
			cam.fov = 45
	cam.current = true
	for i in 10:
		await process_frame
	vp.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	quit()
