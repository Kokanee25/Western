extends SceneTree
## Men standing side by side to judge a new body's proportions and how it moves: each a
## HumanBody with his body_model, in one pose, lit plainly, seen orthographically (sizes compare
## straight) from the front, the side, three-quarters and the back. Writes <out>/<pose>_<view>.png.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd -- --out=DIR
##   [--ids=outlaw,kid] (people.json ids; outlaw, the MakeHuman man, is our skeleton's own build)
##   [--poses=stand,hands_up,aim] (HumanBody.POSES; docs/briefs/characters.md's pose check is
##   stand,sit,hands_up,crouch) [--head] (their heads close: the paint)
##   [--sheet-style] (the character-sheet trial, SheetStyle: the men in their squared textures
##   under plain warm light, on the sheet's dark grey, with its 3/4 back view too) [--bg=r,g,b]
##   [--light=sun:1,ambient:0.15,fill:0,pitch:-40,yaw:-40] (that light without the trial's textures)
## A Tripo man fitted by tools/blender/fit_tripo.py is checked here before he goes in the game:
## hands up and aiming show anything of him Tripo fused together (an arm to his side).

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/people_lineup"
	var ids := ["outlaw", "kid"]
	var poses := ["stand", "hands_up", "aim"]
	var close := false
	var sheet := "--sheet-style" in OS.get_cmdline_user_args()
	# --light=sun:1.6,ambient:0.55,fill:0 (the sheet light's knobs, for matching the sheet's).
	var lit := sheet
	# Defaults matched to the sheet's turnaround (tools/sheet_judge.py, 2026-10-11).
	var light := {"sun": 1.0, "ambient": 0.15, "fill": 0.0, "pitch": -40.0, "yaw": -40.0}
	var bg := Color(0.17, 0.17, 0.18) if sheet else Color(0.5, 0.5, 0.52)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
		elif a.begins_with("--poses="):
			poses = Array(a.substr(8).split(","))
		elif a == "--head":
			close = true
		elif a.begins_with("--light="):
			lit = true
			for kv in a.substr(8).split(","):
				light[kv.get_slice(":", 0)] = float(kv.get_slice(":", 1))
		elif a.begins_with("--bg="):
			var c := a.substr(5).split(",")
			bg = Color(float(c[0]), float(c[1]), float(c[2]))
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	# Close (--head): a square of 0.42 m a man, the men that far apart.
	var spacing := 0.42 if close else 0.85
	vp.size = Vector2i(500 * ids.size(), 500) if close else Vector2i(400 * ids.size(), 900)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = bg
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
	if lit:
		e.background_color = bg if bg != Color(0.5, 0.5, 0.52) else Color(0.17, 0.17, 0.18)
		# Plain warm light, as the sheet's turnaround: a warm key from front-left, a cool dim fill.
		e.ambient_light_color = Color(0.62, 0.58, 0.55)
		e.ambient_light_energy = light.ambient
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		sun.light_color = Color(1.0, 0.86, 0.68)
		sun.light_energy = light.sun
		sun.rotation_degrees = Vector3(light.pitch, light.yaw, 0)
		if light.fill > 0.0:
			var fill := DirectionalLight3D.new()
			w.add_child(fill)
			fill.light_color = Color(0.7, 0.78, 0.95)
			fill.light_energy = light.fill
			fill.rotation_degrees = Vector3(-10, 150, 0)
	# Loaded by path: a -s script compiles before the autoloads exist (CLAUDE.md, ShotMatch.model).
	var body_script = load("res://src/bodies/human_body.gd")
	var men := []
	for i in ids.size():
		var m = body_script.new()
		m.body_model = StringName(ids[i])
		m.person_id = StringName(String(ids[i]) + "_lineup")
		m.rng_seed = 7 + i
		w.add_child(m)
		m.global_position = Vector3((i - (ids.size() - 1) * 0.5) * spacing, 0.0, 0.0)
		men.append(m)
	for f in 12:
		await physics_frame
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.42 if close else 2.3
	w.add_child(cam)
	cam.current = true
	cam.position = Vector3(0, 1.62 if close else 1.0, 8)
	for pose in poses:
		var views := ["front", "side", "three_quarter", "back"]
		if sheet:
			views = ["front", "three_quarter", "side", "back", "three_quarter_back"]
		for view in views:
			var to := Vector3(0, 0, 5)
			if view == "side":
				to = Vector3(5, 0, 0)
			elif view == "three_quarter":
				to = Vector3(3.5, 0, 3.5)
			elif view == "back":
				to = Vector3(0, 0, -5)
			elif view == "three_quarter_back":
				to = Vector3(3.5, 0, -3.5)
			for m in men:
				m.face(m.global_position + to)
				m.set_pose(StringName(pose))
				m._apply_pose(0.0, true)
			for f in 8:
				await physics_frame
			await RenderingServer.frame_post_draw
			var path := "%s/%s%s_%s.png" % [out, "head_" if close else "", pose, view]
			vp.get_texture().get_image().save_png(path)
			print("wrote ", path)
	quit()
