extends SceneTree
## The face lab: a talking man (tools/faces/talking_face.py) built as the game builds him
## (HumanBody, his game materials), in plain neutral light, his blend shapes set by hand.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/faces/face_lab.gd -- \
##       --id=bold_cowboy_talking --out=DIR --mode=sheet [--turns=0,-40] [--size=WxH] [--fov=18 --dist=1.4]
##   ... --mode=take --take=FILE.json [--turn=-20]
## sheet: one picture per expression and turn (DIR/<expression>_<turn>.png, "rest" the face at rest).
## take: FILE.json {"fps": 30, "names": [...], "frames": [[w, ...], ...]} (tools/faces/arkit_take.py)
## played frame by frame, each saved as DIR/f_00000.png (the audio is put on by ffmpeg after).
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

const EYE := 1.76


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var id := "bold_cowboy_talking"
	var out := "/tmp/face_lab"
	var mode := "sheet"
	var turns := [0.0, -40.0]
	var size := Vector2i(900, 900)
	var fov := 16.0
	var dist := 1.4
	var take_path := ""
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="):
			id = a.substr(5)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--turns="):
			turns = Array(a.substr(8).split(",")).map(func(x: String) -> float: return float(x))
		elif a.begins_with("--turn="):
			turns = [float(a.substr(7))]
		elif a.begins_with("--size="):
			var wh := a.substr(7).split("x")
			size = Vector2i(int(wh[0]), int(wh[1]))
		elif a.begins_with("--fov="):
			fov = float(a.substr(6))
		elif a.begins_with("--dist="):
			dist = float(a.substr(7))
		elif a.begins_with("--take="):
			take_path = a.substr(7)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.5, 0.52)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.68)
	env.ambient_light_energy = 0.7
	env_node.environment = env
	w.add_child(env_node)
	var sun := DirectionalLight3D.new()
	w.add_child(sun)
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	var cam := Camera3D.new()
	cam.fov = fov
	w.add_child(cam)
	cam.current = true
	var m = load("res://src/bodies/human_body.gd").new()
	m.body_model = StringName(id)
	m.person_id = StringName(id + "_facelab")
	m.rng_seed = 7
	m.hat_color = Color(0, 0, 0, 0)
	w.add_child(m)
	m.global_position = Vector3.ZERO
	cam.position = Vector3(0, EYE - 0.03, -dist)
	cam.look_at(Vector3(0, EYE - 0.05, 0))
	var faces := _faces(m)
	if faces.is_empty():
		push_error("face_lab: %s has no blend shapes on his head" % id)
		quit(1)
		return
	var names := []
	var mesh := (faces[0] as MeshInstance3D).mesh as ArrayMesh
	for k in mesh.get_blend_shape_count():
		names.append(String(mesh.get_blend_shape_name(k)))
	print("face_lab: %d head pieces with %d expressions: %s" % [faces.size(), names.size(), ", ".join(names)])
	if mode == "take":
		var take: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(take_path))
		var tnames: Array = take.names
		var turn: float = turns[0]
		_turn(m, turn)
		for f in 6:
			await physics_frame
		var n := 0
		var heads: Array = take.get("head", [])
		for frame: Array in take.frames:
			for k in tnames.size():
				_weight(faces, String(tnames[k]), float(frame[k]))
			# His head as the performer's (ARKit's radians: yaw, pitch, roll), over his standing pose.
			if n < heads.size():
				var hd: Array = heads[n]
				m.pose_offsets = {&"head": Vector3(rad_to_deg(-float(hd[1])), rad_to_deg(float(hd[0])), rad_to_deg(float(hd[2])))}
				m._apply_pose(0.0, true)
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png("%s/f_%05d.png" % [out, n])
			n += 1
		print("face_lab: %d frames" % n)
	else:
		var list := ["rest"] + names
		if not only.is_empty():
			list = Array(only)
		for turn: float in turns:
			_turn(m, turn)
			for f in 6:
				await physics_frame
			for e: String in list:
				for nm: String in names:
					_weight(faces, nm, 1.0 if nm == e else 0.0)
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				var path := "%s/%s_%d.png" % [out, e, int(turn)]
				vp.get_texture().get_image().save_png(path)
	print("face_lab: done")
	quit()


func _turn(m: Node, turn: float) -> void:
	var dir := Vector3(sin(deg_to_rad(-turn)), 0, -cos(deg_to_rad(-turn)))
	m.face(m.global_position + dir * 5.0)
	m.set_pose(&"stand")
	m._apply_pose(0.0, true)


func _weight(faces: Array, name: String, w: float) -> void:
	for mi: MeshInstance3D in faces:
		var k: int = mi.find_blend_shape_by_name(StringName(name))
		if k >= 0:
			mi.set_blend_shape_value(k, w)


## His head's pieces that carry expressions.
func _faces(n: Node) -> Array:
	var out := []
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var am := (c as MeshInstance3D).mesh as ArrayMesh
		if am != null and am.get_blend_shape_count() > 0:
			out.append(c)
	return out
