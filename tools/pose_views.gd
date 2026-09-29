extends SceneTree
## Renders the test outlaw in each pose (side and three-quarter), for checking the code-made poses:
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/pose_views.gd -- --out=DIR [--poses=a,b] [--gait=walk]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/poses"
	var poses := ["stand", "aim", "crouch", "crouch_aim", "duck", "tend", "clutch", "prone", "prone_aim"]
	var gait := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--poses="):
			poses = a.substr(8).split(",")
		elif a.begins_with("--gait="):
			gait = a.substr(7)
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(480, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.66, 0.7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.75)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	w.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(10, 10)
	ground.mesh = pm
	w.add_child(ground)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	cs.shape = box
	sb.add_child(cs)
	sb.position.y = -0.5
	w.add_child(sb)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.current = true
	cam.fov = 40.0
	for p in poses:
		var man = load("res://src/bodies/human_body.gd").new()
		w.add_child(man)
		for i in 3:
			await process_frame
		man.get_node("Brain").queue_free() if man.has_node("Brain") else null
		if p.begins_with("prone"):
			man.prone = true
		man.set_pose(StringName(p))
		for i in 40:
			if gait != "":
				man.walk_to(man.global_position + Vector3(0, 0, -5), 1.4 if gait == "walk" else 3.5, 1.0 / 60.0, false)
				man.global_position = Vector3.ZERO
			await physics_frame
		for view in [["side", Vector3(4.5, 1.0, -0.3), Vector3(0, 0.8, -0.3)], ["front", Vector3(2.4, 1.3, -3.6), Vector3(0, 0.8, -0.3)]]:
			cam.look_at_from_position(view[1], view[2])
			for i in 3:
				await process_frame
			vp.get_texture().get_image().save_png("%s/%s%s_%s.png" % [out, p, ("_" + gait) if gait != "" else "", view[0]])
		man.queue_free()
		await process_frame
	print("saved poses to ", out)
	quit()
