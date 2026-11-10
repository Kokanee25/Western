extends SceneTree
## The Winchester in the game's own first-person viewmodel (Winchester73Viewmodel, its HeldHands)
## under a bare camera, a sun and a sky: a quick sheet for fitting the holds (seconds a run, not the
## street's ten minutes). #777.
##
##   xvfb-run -a -s "-screen 0 960x540x24" godot --path . --rendering-driver vulkan --resolution 960x540 \
##       -s res://experiments/gun_lab/win73/fp_fit.gd -- --out=build/win73_fit

var out := "build/win73_fit"
var cam: Camera3D
var vm


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = Sky.new()
	e.sky.sky_material = ProceduralSkyMaterial.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 150.0, 0.0)
	sun.light_energy = 1.2
	root.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.55, 0.45, 0.33)
	ground.material_override = gm
	root.add_child(ground)
	for i in 6:
		var post := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.3, 3.0, 0.3)
		post.mesh = bm
		post.position = Vector3(-6.0 + i * 2.4, 1.5, -25.0)
		root.add_child(post)
	cam = Camera3D.new()
	cam.position = Vector3(0, 1.62, 0)
	cam.fov = 75.0
	cam.near = 0.03
	root.add_child(cam)
	cam.make_current()
	vm = load("res://src/weapons/winchester73_viewmodel.gd").new()
	vm.needs_captured_mouse = false
	vm.steady_hands = true
	cam.add_child(vm)
	for i in 30:
		await process_frame
	var shots := [["hip", false, 0], ["aim", true, 0], ["aim_lever", true, 1], ["hip_lever", false, 1],
			["turned", false, 2], ["aim_half", true, 3]]
	for s in shots:
		vm.state.busy = 0.0
		vm.state.lever_open = s[2] == 1
		vm.state.loading = s[2] == 2
		vm.state.hammer = 1 if s[2] == 3 else 2
		vm.state.chamber = 1
		if s[1]:
			Input.action_press(&"aim")
		else:
			Input.action_release(&"aim")
		for i in 60:
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("%s/%s.png" % [out, s[0]])
		print("saved ", s[0])
	quit()
