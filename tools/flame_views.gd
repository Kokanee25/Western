extends SceneTree
## The fire's flames on a plain stage, for looking at them quickly (the art session's; the fire
## flipbooks, docs/briefs/fire-look.md "The next approach"): a floor and a back wall at dusk, and
## burning-member sheets as FireFX stands them (a wall's boards with dark posts in front, a lying
## board's lick, a door head's sheet), drawn either way: the drawn fire sheets on the left, the
## flipbooks on the right.
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 24 -s res://tools/flame_views.gd \
##       -- --out=DIR [--frames=N] [--only=flipbooks|sheets] [--flipbook=bands:4,...]
## Writes DIR/flames_####.png, N frames (default one) at 1280x720; with --fixed-fps 24 the shaders'
## time steps a 24th of a second a frame, however slow the render, so the frames play as a film.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://flame_views"
	var frames := 1
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--frames="):
			frames = int(a.substr(9))
		elif a.begins_with("--only="):
			only = a.substr(7)
		elif a.begins_with("--flipbook="):
			for m in FireFlipbook.passes():
				for kv in a.substr(11).split(","):
					m.set_shader_parameter(kv.get_slice(":", 0), float(kv.get_slice(":", 1)))
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.13, 0.2)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.35, 0.28, 0.35)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment.glow_enabled = true
	w.add_child(env)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.55, 0.2)
	lamp.light_energy = 3.0
	lamp.omni_range = 9.0
	lamp.position = Vector3(0, 1.2, 0.6)
	w.add_child(lamp)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.26, 0.2)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(16, 8)
	floor_mesh.material_override = wood
	w.add_child(floor_mesh)
	var wall := MeshInstance3D.new()
	wall.mesh = BoxMesh.new()
	(wall.mesh as BoxMesh).size = Vector3(16, 6, 0.1)
	wall.material_override = wood
	wall.position = Vector3(0, 3, -0.9)
	w.add_child(wall)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.6, 9.0)
	cam.rotation_degrees = Vector3(-6, 0, 0)
	cam.fov = 60.0
	w.add_child(cam)
	cam.make_current()
	# By path: naming FireFX here compiles the fire's scripts before the autoloads they use exist.
	var ffx: Variant = load("res://src/fire/fire_fx.gd")
	ffx.flipbooks = false
	var sheet_mat: ShaderMaterial = ffx._sheet_material()
	# A burning wall as FireFX stands it: a sheet to each board (0.3 m apart, up its face and a grown
	# tongue over its top: 5 m), dark posts of its frame in front with their fire behind them, a
	# lying board's lick and a door head's sheet in the opening. [x, size across, size up, heat, behind]
	var stands := []
	for i in 9:
		stands.append([-1.2 + i * 0.3, 0.6, 5.0, 0.6 + 0.4 * float(i % 3) / 2.0, 0.0])
	stands.append([-1.8, 0.9, 1.0, 1.0, 0.0])
	stands.append([1.9, 1.0, 3.06, 0.8, 0.0])
	var post := StandardMaterial3D.new()
	post.albedo_color = Color(0.08, 0.05, 0.04)
	for side: int in [-1, 1]:
		var flipbook := side > 0
		if (only == "flipbooks" and not flipbook) or (only == "sheets" and flipbook):
			continue
		for px in [-0.9, 0.3, 1.2]:
			var p := MeshInstance3D.new()
			p.mesh = BoxMesh.new()
			(p.mesh as BoxMesh).size = Vector3(0.15, 2.6, 0.15)
			p.material_override = post
			p.position = Vector3(side * 3.4 + px, 1.3, 0.3)
			w.add_child(p)
			stands.append([px, 0.6, 5.0, 1.0, 1.0])
		for s in stands:
			var q := MeshInstance3D.new()
			q.mesh = QuadMesh.new()
			q.material_override = FireFlipbook.material() if flipbook else sheet_mat
			q.custom_aabb = AABB(Vector3(-6, -6, -6), Vector3(12, 12, 12))
			w.add_child(q)
			var behind: float = s[4]
			q.position = Vector3(side * 3.4 + float(s[0]), 0.0, 0.3 if behind > 0.0 else 0.0)
			q.set_instance_shader_parameter(&"size", Vector2(s[1], s[2]))
			q.set_instance_shader_parameter(&"heat", s[3])
			q.set_instance_shader_parameter(&"behind", behind)
			q.set_instance_shader_parameter(&"half_box", Vector3(0.075, 1.3, 0.075))
		stands.resize(stands.size() - 3)
	for i in 10:
		await process_frame
	var t0 := Time.get_ticks_msec()
	for f in frames:
		await process_frame
		vp.get_texture().get_image().save_png(out.path_join("flames_%04d.png" % f))
	print("flame_views: %d frames in %.1f s to %s" % [frames, (Time.get_ticks_msec() - t0) / 1000.0, out])
	quit()
