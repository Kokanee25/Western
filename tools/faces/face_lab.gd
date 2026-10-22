extends SceneTree
## The face lab: a talking man (tools/faces/talking_face.py) built as the game builds him
## (HumanBody, his game materials), in plain neutral light, his blend shapes set by hand.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/faces/face_lab.gd -- \
##       --id=bold_cowboy_talking --out=DIR --mode=sheet [--turns=0,-40] [--size=WxH] [--fov=18 --dist=1.4]
##       [--aim=X,Y (where it looks)] [--head=pitch,yaw,roll (his head turned)] [--only=rest,jaw_open]
##       [--bandana=none|neck|mask (tools/faces/bandana.py's, at his neck or over his face)]
##   ... --mode=take --take=FILE.json [--turn=-20]
## sheet: one picture per expression and turn (DIR/<expression>_<turn>.png, "rest" the face at rest).
## take: FILE.json {"fps": 30, "names": [...], "frames": [[w, ...], ...]} (tools/faces/arkit_take.py)
## played frame by frame, each saved as DIR/f_00000.png (the audio is put on by ffmpeg after).
## gaze: a marker moved round him (GAZE_PATH), his eyes and head on it (FaceGaze), a fixed step a
## frame, each saved as DIR/f_00000.png; --check prints which way his head turned.
## life: FaceLife on him as in the game (his Senses real, his brain a stand-in): a man walks past, a
## shot to his right, then he's afraid, then hurt, then dead (LIFE_BEATS), each frame saved as
## DIR/f_00000.png at 30 a second and the beats to DIR/beats.txt (run with --fixed-fps 30).
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

const EYE := 1.76
## The marker's path for --mode=gaze: [seconds, degrees to his left, degrees up, metres from his eyes]
## held from one to the next (a jump) or eased ("~" in front: a slow move to it).
const GAZE_PATH := [
	[0.0, "cam"], [1.2, 35.0, 0.0, 0.55], [2.6, "~", -35.0, 5.0, 0.55], [4.4, 20.0, 22.0, 0.55],
	[5.6, -25.0, -28.0, 0.55], [6.8, "cam"], [8.2, "~", 8.0, 6.0, 0.55], [9.0, "~", -8.0, -4.0, 0.55],
	[9.8, "cam"], [11.0, "end"]]
## --mode=life's beats: [seconds, what happens].
const LIFE_BEATS := [[0.0, "alone"], [1.5, "a man walks past"], [7.5, "a shot to his right"],
	[11.0, "afraid"], [14.5, "hurt"], [18.0, "dead"], [21.0, "end"]]


## A brain's few fields FaceLife reads, for --mode=life (no behaviour of its own).
class LabBrain extends Node:
	var fear := 0.0
	var senses: Node
	var target: Node3D


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
	var aim := Vector3(0, EYE - 0.05, 0)  # --aim=x,y: the point the camera looks at, level with it
	var head_turn := Vector3.ZERO  # --head=pitch,yaw,roll degrees: his head turned over his pose
	var bandana := "none"  # --bandana=none|neck|mask: his bandana (tools/faces/bandana.py) at his neck or over his face
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bandana="):
			bandana = a.substr(10)
		elif a.begins_with("--id="):
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
		elif a.begins_with("--aim="):
			var p := a.substr(6).split(",")
			aim = Vector3(float(p[0]), float(p[1]), 0)
		elif a.begins_with("--head="):
			var h := a.substr(7).split(",")
			head_turn = Vector3(float(h[0]), float(h[1]), float(h[2]))
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
	if bandana == "none":
		m.bandana_color = Color(0, 0, 0, 0)
	m.masked = bandana == "mask"
	m.face_life = mode == "life"   # his face is set by hand in the other modes
	w.add_child(m)
	m.global_position = Vector3.ZERO
	cam.position = Vector3(aim.x, aim.y + 0.02, -dist)
	cam.look_at(aim)
	var faces := _faces(m)
	var names := []
	if faces.is_empty():
		print("face_lab: %s has no blend shapes on his head (only his face at rest)" % id)
	else:
		var mesh := (faces[0] as MeshInstance3D).mesh as ArrayMesh
		for k in mesh.get_blend_shape_count():
			names.append(String(mesh.get_blend_shape_name(k)))
	print("face_lab: %d head pieces with %d expressions: %s" % [faces.size(), names.size(), ", ".join(names)])
	if mode == "gaze":
		await _gaze(m, out)
	elif mode == "life":
		await _life(m, out)
	elif mode == "take":
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
		var list := ["rest"] + names + ["rest2"]
		if not only.is_empty():
			list = Array(only)
		for turn: float in turns:
			m.process_mode = Node.PROCESS_MODE_INHERIT
			_turn(m, turn, head_turn)
			for f in 6:
				await physics_frame
			# Held still (no breathing, no idle) while his expressions are drawn: each picture
			# differs from the rest one by its expression alone.
			m.process_mode = Node.PROCESS_MODE_DISABLED
			for e: String in list:
				for nm: String in names:
					_weight(faces, nm, 1.0 if nm == e else 0.0)
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				var path := "%s/%s_%d.png" % [out, e, int(turn)]
				vp.get_texture().get_image().save_png(path)
	print("face_lab: done")
	quit()


func _turn(m: Node, turn: float, head := Vector3.ZERO) -> void:
	var dir := Vector3(sin(deg_to_rad(-turn)), 0, -cos(deg_to_rad(-turn)))
	m.face(m.global_position + dir * 5.0)
	m.set_pose(&"stand")
	if head != Vector3.ZERO:
		m.pose_offsets = {&"head": head}
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


## His eyes and head following a marker along GAZE_PATH (the camera itself where it says "cam").
func _gaze(m: Node, out: String) -> void:
	var dt := 1.0 / 30.0
	var g = load("res://src/bodies/face_gaze.gd").new()
	g.body = m
	g.auto = false
	g.rng_seed = 3
	m.add_child(g)
	var marker := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.025
	sm.height = 0.05
	marker.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = mat
	(m.get_parent() as Node3D).add_child(marker)
	var cam := (m.get_viewport() as Viewport).get_camera_3d()
	_turn(m, 0.0)
	for f in 6:
		await physics_frame
	m.process_mode = Node.PROCESS_MODE_DISABLED   # driven a fixed step a frame below
	var c: Array = load("res://src/bodies/people_bodies.gd").report(m.body_model).get("facerig", {}).get("eye_centre", [0, EYE, 0])
	var eye := Vector3(c[0], c[1], c[2])
	var t := 0.0
	var n := 0
	var check := "--check" in OS.get_cmdline_user_args()
	while true:
		var p: Variant = _gaze_point(t, eye, cam.global_position)
		if p == null:
			break
		marker.global_position = p
		marker.visible = (p as Vector3).distance_to(cam.global_position) > 0.05
		g.target_point = p
		g.step(dt)
		m._apply_pose(dt)
		m._update_skeleton()   # (his own _process would; he's held to the fixed step here)
		await RenderingServer.frame_post_draw
		if not check:
			vp_save(m, "%s/f_%05d.png" % [out, n])
		elif n % 15 == 0:
			var head := m.parts[&"head"] as Node3D
			var fwd := -head.global_transform.basis.z
			print("face_lab: t %.1f looking %s head forward %s (his left is -x)" % [t, g.looking(), fwd])
		n += 1
		t += dt
	print("face_lab: %d frames of gaze" % n)


func _life(m: Node, out: String) -> void:
	var w := m.get_parent() as Node3D
	var brain := LabBrain.new()
	brain.name = "Brain"
	var senses = load("res://src/people/senses.gd").new()
	senses.name = "Senses"
	senses.body = m
	senses.light = 1.0
	brain.senses = senses
	m.add_child(brain)
	m.add_child(senses)
	var passer = load("res://src/bodies/human_body.gd").new()
	passer.person_id = &"facelab_passer"
	passer.rng_seed = 11
	w.add_child(passer)
	passer.global_position = Vector3(4.0, 0, -3.5)
	_turn(m, 0.0)
	var life = m.get_node(^"FaceLife")
	var events := root.get_node(^"Events")
	var beats := FileAccess.open(out + "/beats.txt", FileAccess.WRITE)
	var dt := 1.0 / 30.0
	var t := 0.0
	var n := 0
	var beat := 0
	while t < float(LIFE_BEATS[-1][0]):
		while beat < LIFE_BEATS.size() - 1 and t >= float(LIFE_BEATS[beat][0]):
			var what: String = LIFE_BEATS[beat][1]
			beats.store_line("%d %s" % [n, what])
			print("face_lab: %.1f s %s" % [t, what])
			if what == "a shot to his right":
				events.noise.emit(m.global_position + Vector3(7.0, 1.0, -1.0), 600.0, &"gunshot", null)
			elif what == "afraid":
				brain.fear = 0.9
			elif what == "hurt":
				brain.fear = 0.0
				m.physiology.adrenaline = 0.0
				m.physiology.pain = 1.4
				m.physiology.wound_pain = 1.4
			elif what == "dead":
				m.physiology.pain = 0.0
				m.physiology.alive = false
				# Held where he stands (no fall: the film's on his face); his face goes on.
				m.process_mode = Node.PROCESS_MODE_DISABLED
				life.process_mode = Node.PROCESS_MODE_ALWAYS
			beat += 1
		# The passer walks from his right to his left, 3.5 m out, from 1.5 s to 6.5 s.
		var u := clampf((t - 1.5) / 5.0, 0.0, 1.0)
		passer.global_position = Vector3(lerpf(4.0, -4.0, u), 0, -3.5)
		passer.face(passer.global_position + Vector3(-1, 0, 0))
		if t >= 1.5 and t < 6.5:
			passer.set_pose(&"walk")
		elif passer.pose == &"walk":
			passer.set_pose(&"stand")
		if m.physiology.alive:
			m.physiology.adrenaline = 0.0
		await physics_frame
		await RenderingServer.frame_post_draw
		vp_save(m, "%s/f_%05d.png" % [out, n])
		n += 1
		t += dt
	beats.close()
	print("face_lab: %d frames of life" % n)


func vp_save(m: Node, path: String) -> void:
	(m.get_viewport() as Viewport).get_texture().get_image().save_png(path)


## The marker at time t along GAZE_PATH: a point (or null past its end).
func _gaze_point(t: float, eye: Vector3, cam: Vector3) -> Variant:
	var at := func(k: Array) -> Vector3:
		if k[1] is String and k[1] == "cam":
			return cam
		var o := 1 if k[1] is String else 0
		var yaw := deg_to_rad(float(k[1 + o]))
		var pitch := deg_to_rad(float(k[2 + o]))
		var d := float(k[3 + o])
		return eye + Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)) * d
	for i in GAZE_PATH.size() - 1:
		var a: Array = GAZE_PATH[i]
		var b: Array = GAZE_PATH[i + 1]
		if t >= float(a[0]) and t < float(b[0]):
			if b[1] is String and b[1] == "~":
				var u := (t - float(a[0])) / (float(b[0]) - float(a[0]))
				return at.call(a).lerp(at.call(b), u * u * (3.0 - 2.0 * u))
			return at.call(a)
		if b[1] is String and b[1] == "end" and t >= float(b[0]):
			return null
	return null
