extends SceneTree
## Men standing side by side to judge a new body's proportions and how it moves: each a
## HumanBody with his body_model, in one pose, lit plainly, seen orthographically (sizes compare
## straight) from the front, the side, three-quarters and the back. Writes <out>/<pose>_<view>.png.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd -- --out=DIR
##   [--ids=outlaw,kid] (people.json ids; outlaw, the MakeHuman man, is our skeleton's own build)
##   [--poses=stand,hands_up,aim] (HumanBody.POSES; docs/briefs/characters.md's pose check is
##   stand,sit,hands_up,crouch) [--head] (their heads close: the paint) [--hatless] [--unarmed]
##   Besides HumanBody.POSES: `walk` and `run` (his stride at its widest, from the gait overlay),
##   `wounds` (standing, shot from the front in the chest, right upper arm and left thigh) and
##   `hat` (a ball through his hat from the front: it comes off) and `fall` (shot down: limp, a
##   push back, 2.5 s of ragdoll on a floor, seen from above). `fall` comes last: he's a ragdoll
##   after it.
## A Tripo man fitted by tools/blender/fit_tripo.py is checked here before he goes in the game:
## hands up and aiming show anything of him Tripo fused together (an arm to his side).

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/people_lineup"
	var ids := ["outlaw", "kid"]
	var poses := ["stand", "hands_up", "aim"]
	var close := false
	var hatless := false
	var unarmed := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
		elif a.begins_with("--poses="):
			poses = Array(a.substr(8).split(","))
		elif a == "--head":
			close = true
		elif a == "--hatless":
			hatless = true
		elif a == "--unarmed":
			unarmed = true
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
	# Loaded by path: a -s script compiles before the autoloads exist (docs/LAYOUT.md, ShotMatch.model).
	var body_script = load("res://src/bodies/human_body.gd")
	var men := []
	for i in ids.size():
		var m = body_script.new()
		m.body_model = StringName(ids[i])
		m.person_id = StringName(String(ids[i]) + "_lineup")
		m.rng_seed = 7 + i
		if hatless:
			m.hat_color = Color(0, 0, 0, 0)
		if unarmed:
			m.has_gun = false
		w.add_child(m)
		m.global_position = Vector3((i - (ids.size() - 1) * 0.5) * spacing, 0.0, 0.0)
		men.append(m)
	# A floor for the falls.
	var floor := StaticBody3D.new()
	floor.collision_layer = 1
	var fs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	fs.shape = box
	floor.add_child(fs)
	w.add_child(floor)
	floor.position = Vector3(0, -0.5, 0)
	for f in 12:
		await physics_frame
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.42 if close else 2.3
	w.add_child(cam)
	cam.current = true
	cam.position = Vector3(0, 1.62 if close else 1.0, 8)
	for pose in poses:
		for view in ["front", "side", "three_quarter", "back"]:
			var to := Vector3(0, 0, 5)
			if view == "side":
				to = Vector3(5, 0, 0)
			elif view == "three_quarter":
				to = Vector3(3.5, 0, 3.5)
			elif view == "back":
				to = Vector3(0, 0, -5)
			for m in men:
				if m.limp and pose != "fall":
					continue
				if pose == "fall":
					if view == "front":
						_fall(m, to)
					continue
				m.set_physics_process(true)
				m.face(m.global_position + to)
				m.set_pose(&"stand" if pose in ["walk", "run", "wounds", "hat"] else StringName(pose))
				m._apply_pose(0.0, true)
				if pose == "wounds" and view == "front":
					_shoot(m, to)
				if pose == "hat" and view == "front" and m.hat_body != null:
					m.take_hat_shot(m.hat_body.global_position + to.normalized() * 0.3, -to.normalized(), 400.0, null)
				if pose in ["walk", "run", "wounds"]:
					# Held still: the gait overlay at its widest (walking's own tick would end it).
					m.set_physics_process(false)
					m.gait = StringName(pose) if pose != "wounds" else &""
					m.move_speed = 4.0 if pose == "run" else (1.4 if pose == "walk" else 0.0)
					m._gait_phase = PI * 0.5
					m._apply_pose(0.0, true)
			for f in (150 if pose == "fall" and view == "front" else (40 if pose == "hat" and view == "front" else 8)):
				await physics_frame
			if pose == "fall":
				# Round the men where they lie (they fall once, at the first view).
				var at := Vector3.ZERO
				for m in men:
					at += (m.parts[&"pelvis"] as Node3D).global_position / men.size()
				at.y = 0.0
				cam.size = 3.2
				cam.position = at + Vector3(to.x, 0, to.z).normalized() * 4.0 + Vector3.UP * 2.4
				cam.look_at(at)
				await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var path := "%s/%s%s_%s.png" % [out, "head_" if close else "", pose, view]
			vp.get_texture().get_image().save_png(path)
			print("wrote ", path)
	quit()


## Shot from the front (`to` is where he faces): chest, right upper arm, left thigh.
func _shoot(m, to: Vector3) -> void:
	var dir := -to.normalized()
	for seg in [&"chest", &"upper_arm_r", &"thigh_l"]:
		var part: Node3D = m.parts[seg]
		var at: Vector3 = part.global_position - dir * 0.3 + Vector3.UP * 0.03
		m.take_bullet(part, at, dir, 150.0 if seg != &"chest" else 120.0, 0.0057)


## Shot down: limp, pushed back from the front (`to`), left to fall on the floor.
func _fall(m, to: Vector3) -> void:
	m.set_physics_process(true)
	m.face(m.global_position + to)
	m.set_pose(&"stand")
	m._apply_pose(0.0, true)
	m.go_limp(-to.normalized() * 0.6)
