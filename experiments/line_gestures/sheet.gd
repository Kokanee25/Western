extends SceneTree
## The before/after contact sheet of #1316: a man says a line of each delivery tag and is caught on its
## beat, once with LineGesture off (the game before: only his mouth moves) and once on; then a man
## mocking another with a third by, caught as they answer. By day on a plain stage (saloon B at night
## crashes the software renderer, #1260). Writes <out>/<before|after>_<tag>.png; sheet.py lays them out.
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/line_gestures/sheet.gd -- --out=DIR

const LINES := [
	["angry", "You *never paid me for that horse."],
	["laughing", "And the mule walked in after him!"],
	["mocking", "Your mother still *dress you, Wilbur?"],
	["scared", "Somebody's out there. I *heard him."],
	["sly", "I never saw a *thing, Marshal."],
	["sad", "She was a good woman. *Too good for here."],
	["low", "Don't look now. He's *watching us."],
	["proud", "Built every board of it *myself."],
	["pleading", "Please, mister. I got *children."],
	["calm", "Coffee's on, if you want it."],
]
const MAN := &"bold_cowboy_talking"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/line_gestures"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(420, 420)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.52, 0.48)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.72, 0.68)
	e.ambient_light_energy = 0.7
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	w.add_child(sun)
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	var floor := StaticBody3D.new()
	var fs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	fs.shape = box
	floor.add_child(fs)
	w.add_child(floor)
	floor.position = Vector3(0, -0.1, 0)
	var cam := Camera3D.new()
	cam.fov = 40.0
	w.add_child(cam)
	cam.current = true
	# Loaded by path: a -s script compiles before the autoloads exist.
	var body_script = load("res://src/bodies/human_body.gd")
	var lg_script = load("res://src/bodies/line_gesture.gd")
	var dl = load("res://src/people/delivery.gd")
	var events = root.get_node(^"Events")
	for mode in ["before", "after"]:
		lg_script.enabled = mode == "after"
		for i in LINES.size():
			var tag: String = LINES[i][0]
			var m = body_script.new()
			m.body_model = MAN
			m.person_id = StringName("sheet_%s_%s" % [mode, tag])
			m.rng_seed = 11
			w.add_child(m)
			m.global_position = Vector3.ZERO
			m.face(Vector3(0, 1.5, 5))
			cam.position = Vector3(0.0, 1.4, 1.9)
			cam.look_at(Vector3(0, 1.22, 0))
			for f in 40:
				await physics_frame
			var clean: String = dl.remember(LINES[i][1], StringName(tag))
			events.spoke.emit(m, clean)
			var beat: float = _beat_of(clean, dl.of(clean), StringName(tag))
			var t := 0.0
			while t < beat + 0.05:
				await physics_frame
				t += 1.0 / 60.0
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png("%s/%s_%s.png" % [out, mode, tag])
			# His face, the same moment (a frame on).
			var head: Vector3 = m.parts[&"head"].global_position
			cam.position = head + Vector3(0.0, 0.03, 0.62)
			cam.look_at(head + Vector3(0, 0.02, 0))
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png("%s/%s_%s_face.png" % [out, mode, tag])
			print("wrote %s %s beat %.2f" % [mode, tag, beat])
			m.queue_free()
			for f in 3:
				await physics_frame
		# The listeners: a man mocks another, a third stood by.
		var men := []
		for j in 3:
			var m = body_script.new()
			m.body_model = MAN
			m.person_id = StringName("sheet_%s_l%d" % [mode, j])
			m.rng_seed = 21 + j
			w.add_child(m)
			men.append(m)
		men[0].global_position = Vector3(-0.75, 0, 0)
		men[1].global_position = Vector3(0.75, 0, 0)
		men[2].global_position = Vector3(0.1, 0, -0.9)
		men[0].face(men[1].global_position + Vector3.UP * 1.5)
		men[1].face(men[0].global_position + Vector3.UP * 1.5)
		men[2].face(Vector3(-0.3, 1.5, 0.5))
		cam.position = Vector3(0.0, 1.55, 2.6)
		cam.look_at(Vector3(0, 1.4, 0))
		for f in 40:
			await physics_frame
		var line: String = dl.remember("Your mother still *dress you, Wilbur?", &"mocking")
		events.overheard.emit(men[0], line, {"to": men[1], "tag": &"mocking", "r": {"men": {&"a": men[0], &"b": men[1], &"c": men[2]}}})
		var beat2: float = _beat_of(line, dl.of(line), &"mocking") + 0.75
		var t2 := 0.0
		while t2 < beat2:
			await physics_frame
			t2 += 1.0 / 60.0
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("%s/%s_listeners.png" % [out, mode])
		print("wrote %s listeners" % mode)
		for m in men:
			m.queue_free()
		for f in 3:
			await physics_frame
	quit()


func _beat_of(text: String, d: Dictionary, tag: StringName) -> float:
	var fs = load("res://src/bodies/face_speech.gd")
	var lg = load("res://src/bodies/line_gesture.gd")
	var dl = load("res://src/people/delivery.gd")
	var plan: Dictionary = fs.plan(text)
	return lg._beat(plan, int(d.beat), String(dl.entry(tag).get("beat", "stress")), float(plan.voice[0]), maxf(float(plan.voice[1]), float(plan.voice[0]) + 0.2))
