extends SceneTree
## The gun and hand in your hands, alone, for working on how they look (docs/briefs/guns.md).
## The game camera (75 degrees) and the viewmodel in one of its poses, lit like golden hour on the
## street (a low warm sun ahead and to the left, the viewmodel's own HeldFill), on a transparent
## background laid over the street painting; or a side view of the model alone.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/gun_lab.gd -- \
##       --out=FILE [--gun=revolver|shotgun] [--pose=hip|aim|loading|side] [--size=1280x720]
##       [--bg=street|grey] [--cocked] [--open] [--pos=x,y,z --rot=x,y,z]
##       [--pose=view --cam=x,y,z --camrot=x,y,z]
## --pos/--rot put the viewmodel somewhere other than its pose (trying a new pose).

func _initialize() -> void:
	_run.call_deferred()


func _arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return fallback


func _vec(s: String) -> Vector3:
	var p := s.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _run() -> void:
	var size := _arg("size", "1280x720").split("x")
	var vp := SubViewport.new()
	vp.size = Vector2i(int(size[0]), int(size[1]))
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# The street's low-sun ambient: a little warm bounce, most of the light from the sun.
	env.environment.ambient_light_color = Color(0.62, 0.5, 0.42)
	env.environment.ambient_light_energy = 0.35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	# Golden hour down the street: the sun low, ahead and a little left, warm.
	sun.rotation_degrees = Vector3(-12, 160, 0)
	sun.light_color = Color(1.0, 0.72, 0.45)
	sun.light_energy = 1.6
	w.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 75
	cam.near = 0.02
	w.add_child(cam)
	cam.current = true
	var gun := _arg("gun", "revolver")
	var vm
	if gun == "shotgun":
		vm = load("res://src/weapons/shotgun_viewmodel.gd").new()
	else:
		vm = load("res://src/weapons/revolver_viewmodel.gd").new()
	cam.add_child(vm)
	await process_frame
	await process_frame
	vm.set_process(false)
	vm.set_physics_process(false)
	var pose := _arg("pose", "hip")
	if pose == "side" or pose == "view":
		# The model alone from its right side, as a gunsmith's photograph; or (view) the gun and
		# hand from anywhere: --cam=x,y,z --camrot=x,y,z (degrees), fov 18.
		vm.hand.visible = pose == "view"
		if gun == "shotgun":
			vm.left_hand.visible = pose == "view"
		vm.reparent(w, false)
		vm.position = Vector3.ZERO
		vm.rotation = Vector3.ZERO
		cam.position = Vector3(0.9 if gun == "revolver" else 2.6, 0.02 if gun == "revolver" else -0.03, -0.12 if gun == "revolver" else -0.1)
		cam.rotation_degrees = Vector3(0, 90, 0)
		cam.fov = 18
		if pose == "view":
			cam.position = _vec(_arg("cam", "0.9,0.02,-0.02"))
			cam.rotation_degrees = _vec(_arg("camrot", "0,90,0"))
		sun.rotation_degrees = Vector3(-40, 60, 0)
		sun.light_color = Color(1, 0.95, 0.9)
		env.environment.ambient_light_color = Color(0.75, 0.75, 0.78)
		env.environment.ambient_light_energy = 0.6
	else:
		var idx: int = {"hip": 0, "aim": 1, "loading": 2}.get(pose, 0)
		var p: Array = vm.POSES[idx]
		vm._pose_pos = _vec(_arg("pos", "")) if _arg("pos", "") != "" else p[0]
		vm._pose_rot = _vec(_arg("rot", "")) if _arg("rot", "") != "" else p[1]
		vm._draw = 1.0
		vm._apply_pose(1.0)
	if OS.get_cmdline_user_args().has("--cocked") and gun == "revolver":
		vm.model.hammer.rotation_degrees.x = -44.0
		vm.hand.set_thumb(1.0)
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var bg := _arg("bg", "grey" if pose == "side" or pose == "view" else "street")
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	if bg == "street":
		var paint := Image.load_from_file(ProjectSettings.globalize_path("res://docs/concept/street-golden-hour.png"))
		paint.convert(Image.FORMAT_RGBA8)
		paint.resize(img.get_width(), img.get_height(), Image.INTERPOLATE_BILINEAR)
		out.copy_from(paint)
	else:
		out.fill(Color(0.55, 0.55, 0.57))
	out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
	out.save_png(_arg("out", "/tmp/gun_lab.png"))
	quit()
