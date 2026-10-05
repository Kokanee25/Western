extends SceneTree
## Men standing side by side to judge a new body's proportions and how it moves: each a
## HumanBody with his body_model, in one pose, lit plainly, seen orthographically (sizes compare
## straight) from the front, the side and three-quarters. Writes <out>/<pose>_<view>.png.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd -- --out=DIR
##   [--ids=outlaw,kid] (people.json ids; outlaw, the MakeHuman man, is our skeleton's own build)
##   [--poses=stand,hands_up,aim] (HumanBody.POSES)
## A Tripo man fitted by tools/blender/fit_tripo.py is checked here before he goes in the game:
## hands up and aiming show anything of him Tripo fused together (an arm to his side).

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/people_lineup"
	var ids := ["outlaw", "kid"]
	var poses := ["stand", "hands_up", "aim"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
		elif a.begins_with("--poses="):
			poses = Array(a.substr(8).split(","))
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(400 * ids.size(), 900)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.5, 0.52)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.72, 0.68)
	e.ambient_light_energy = 0.7
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	w.add_child(sun)
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	# Loaded by path: a -s script compiles before the autoloads exist (CLAUDE.md, ShotMatch.model).
	var body_script = load("res://src/bodies/human_body.gd")
	var men := []
	for i in ids.size():
		var m = body_script.new()
		m.body_model = StringName(ids[i])
		m.person_id = StringName(String(ids[i]) + "_lineup")
		m.rng_seed = 7 + i
		w.add_child(m)
		m.global_position = Vector3((i - (ids.size() - 1) * 0.5) * 0.85, 0.0, 0.0)
		men.append(m)
	for f in 12:
		await physics_frame
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.3
	w.add_child(cam)
	cam.current = true
	cam.position = Vector3(0, 1.0, 8)
	for pose in poses:
		for view in ["front", "side", "three_quarter"]:
			var to := Vector3(0, 0, 5)
			if view == "side":
				to = Vector3(5, 0, 0)
			elif view == "three_quarter":
				to = Vector3(3.5, 0, 3.5)
			for m in men:
				m.face(m.global_position + to)
				m.set_pose(StringName(pose))
				m._apply_pose(0.0, true)
			for f in 8:
				await physics_frame
			await RenderingServer.frame_post_draw
			var path := "%s/%s_%s.png" % [out, pose, view]
			vp.get_texture().get_image().save_png(path)
			print("wrote ", path)
	quit()
