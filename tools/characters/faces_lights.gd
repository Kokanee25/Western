extends SceneTree
## The faces test's judge in three lights (docs/briefs/faces.md, step 6): men's heads side by side,
## close and orthographic as tools/people_lineup.gd shows them, under a warm lamp, a golden-hour
## sun and deep shade with a fill, from the front, three-quarters and the side. Writes
## <out>/<light>_<view>.png and <out>/stamps.json: where each of a man's stamps (his report's
## "stamps": tools/blender/house_head.py) and the squares round it land in each picture, and which
## way it faces there, for tools/characters/faces_judge.py.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/faces_lights.gd -- \
##       --out=DIR [--ids=faces_test,stranger2s]

const LIGHTS := ["lamp", "sun", "shade"]
const VIEWS := {"front": Vector3(0, 0, 5), "three_quarter": Vector3(3.5, 0, 3.5), "side": Vector3(5, 0, 0)}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/faces_lights"
	var ids := ["faces_test", "stranger2s"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(500 * ids.size(), 500)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.32, 0.32, 0.34)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	w.add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.shadow_enabled = true
	lamp.omni_range = 3.0
	w.add_child(lamp)
	var body_script = load("res://src/bodies/human_body.gd")
	var men := []
	for i in ids.size():
		var m = body_script.new()
		m.body_model = StringName(ids[i])
		m.person_id = StringName(String(ids[i]) + "_faces")
		m.rng_seed = 7 + i
		w.add_child(m)
		m.global_position = Vector3((i - (ids.size() - 1) * 0.5) * 0.42, 0.0, 0.0)
		men.append(m)
	for f in 12:
		await physics_frame
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.42
	w.add_child(cam)
	cam.current = true
	cam.position = Vector3(0, 1.62, 8)
	var record := []
	for light in LIGHTS:
		_light(light, e, sun, lamp)
		for view in VIEWS:
			var to: Vector3 = VIEWS[view]
			for m in men:
				m.face(m.global_position + to)
				m.set_pose(&"stand")
				m._apply_pose(0.0, true)
			# The lamp stays on the man's front and right as he turns (your right as you face him).
			for f in 8:
				await physics_frame
			await RenderingServer.frame_post_draw
			var path := "%s/%s_%s.png" % [out, light, view]
			vp.get_texture().get_image().save_png(path)
			for i in men.size():
				var m = men[i]
				var stamps: Dictionary = load("res://src/bodies/people_bodies.gd").report(StringName(ids[i])).get("stamps", {})
				var part: Node3D = m.parts[&"head"]
				var centre: Vector3 = m.anatomy.segment_center(&"head")
				for name: String in stamps:
					var st: Dictionary = stamps[name]
					var at := []
					for p in st.at:
						var s := cam.unproject_position(part.global_transform * (Vector3(p[0], p[1], p[2]) - centre))
						at.append([s.x, s.y])
					var rnd := []
					for p in st.round:
						var s := cam.unproject_position(part.global_transform * (Vector3(p[0], p[1], p[2]) - centre))
						rnd.append([s.x, s.y])
					var f: Array = st.facing
					var facing: Vector3 = part.global_basis * Vector3(f[0], f[1], f[2])
					record.append({"man": ids[i], "light": light, "view": view, "stamp": name, "at": at,
							"round": rnd, "toward_you": facing.normalized().z})
			print("wrote ", path)
	var fa := FileAccess.open(out + "/stamps.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify({"ids": ids, "size": [vp.size.x, vp.size.y], "points": record}))
	fa.close()
	quit()


## The three lights. lamp: a warm oil lamp low on your right, a dim warm room; sun: a low gold sun
## from his left front, a blue sky fill; shade: no direct light, a cool sky and a faint fill.
func _light(which: String, e: Environment, sun: DirectionalLight3D, lamp: OmniLight3D) -> void:
	sun.visible = which != "lamp"
	lamp.visible = which == "lamp"
	match which:
		"lamp":
			lamp.position = Vector3(0.45, 1.45, 0.7)
			lamp.light_color = Color(1.0, 0.74, 0.48)
			lamp.light_energy = 1.6
			e.ambient_light_color = Color(0.5, 0.38, 0.28)
			e.ambient_light_energy = 0.25
		"sun":
			sun.light_color = Color(1.0, 0.8, 0.55)
			sun.light_energy = 1.5
			sun.global_basis = Basis.looking_at(-Vector3(-0.8, 0.3, 1.0).normalized(), Vector3.UP)
			e.ambient_light_color = Color(0.55, 0.6, 0.72)
			e.ambient_light_energy = 0.35
		"shade":
			sun.light_color = Color(0.85, 0.88, 0.95)
			sun.light_energy = 0.25
			sun.global_basis = Basis.looking_at(-Vector3(0.1, 0.2, 1.0).normalized(), Vector3.UP)
			e.ambient_light_color = Color(0.6, 0.64, 0.72)
			e.ambient_light_energy = 0.55
