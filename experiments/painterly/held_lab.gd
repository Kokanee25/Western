extends SceneTree
## The revolver and hand in your grip, alone, for judging their shape and look:
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/painterly/held_lab.gd -- \
##       --out=DIR [--painterly] [--views=side,eye,three,close,left,below] [--size=WxH] [--pose=hip|aim|loading]
## Writes DIR/<view>.png. Lit by a low warm sun and a cool fill, on a plain grey ground.

const VIEWS := {
	# position, look-at, fov
	"side": [Vector3(0.75, 0.0, -0.08), Vector3(0, -0.01, -0.08), 22.0],
	"left": [Vector3(-0.75, 0.0, -0.08), Vector3(0, -0.01, -0.08), 22.0],
	"three": [Vector3(0.42, 0.18, 0.28), Vector3(0, -0.01, -0.07), 30.0],
	"close": [Vector3(0.22, 0.08, 0.1), Vector3(0, 0.0, -0.03), 30.0],
	"below": [Vector3(0.35, -0.4, 0.05), Vector3(0, -0.02, -0.06), 30.0],
	"top": [Vector3(0.0, 0.8, -0.08), Vector3(0, 0, -0.08001), 22.0],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/held"
	var size := Vector2i(1280, 720)
	var views := ["side", "three", "close", "eye", "aim"]
	var pose := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--views="):
			views = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = size
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.4, 0.38)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.6, 0.7)
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.82, 0.6)
	sun.light_energy = 2.2
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-28, 55, 0)
	w.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.6, 0.7, 0.9)
	fill.light_energy = 0.5
	fill.rotation_degrees = Vector3(-20, -140, 0)
	w.add_child(fill)
	var holder := Camera3D.new()  # the viewmodel's parent camera, not current
	w.add_child(holder)
	var gun = load("res://src/weapons/revolver_viewmodel.gd").new()
	holder.add_child(gun)
	await process_frame
	gun.set_process(false)
	gun.position = Vector3.ZERO
	gun.rotation = Vector3.ZERO
	gun.visible = true
	gun.model.show_chambers([1, 1, 1, 1, 1, 0] as Array[int])
	var cam := Camera3D.new()
	cam.near = 0.01
	w.add_child(cam)
	cam.current = true
	for v in views:
		if v == "eye" or v == "aim":
			# Where it sits in the game: the camera at the eye, the gun at the pose.
			var p: Array = gun.POSES[gun.Pose.HIP if v == "eye" else gun.Pose.AIM]
			gun.position = p[0]
			gun.rotation_degrees = p[1]
			cam.global_transform = holder.global_transform
			cam.fov = 75.0 if v == "eye" else 60.0
		else:
			gun.position = Vector3.ZERO
			gun.rotation = Vector3.ZERO
			var d: Array = VIEWS[v]
			cam.position = d[0]
			cam.fov = d[2]
			cam.look_at(d[1])
		for i in 8:
			await process_frame
		vp.get_texture().get_image().save_png("%s/%s.png" % [out, v])
	quit()
