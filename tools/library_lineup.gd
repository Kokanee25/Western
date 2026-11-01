extends SceneTree
## The library clips on the game's men (issue #529): three Studio men side by side on each clip in
## turn, walking where the clip walks, as frames for a film (`--film`), or each clip's worst frame
## for the knees, hips, shoulders and elbows as a contact sheet (`--sheet`: the frame each joint
## is bent furthest from its rest, front and side).
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 30 -s res://tools/library_lineup.gd -- \
##       --out=DIR --film|--sheet|--measure [--men=a,b,c] [--moves=walk,run] [--size=960x540] [--takes]
## --takes: every candidate take of the moves (build/library/takes/<move>_<n>.json, from
## `library_motion.py takes`) in place of the picked clips, to choose between them.
## The film's frames are DIR/frames/%05d.png (ffmpeg makes the mp4: experiments/library_motion/film.sh).

const MEN := ["bold_cowboy_s3_talking", "old_rancher_s3_talking", "young_drifter_s3_talking"]
## Each move: how he goes (speed m/s; "ahead", "back", "right", "left" of his facing), seconds.
const PLAN := [
	["idle", 0.0, "", 3.0], ["walk", 1.3, "ahead", 3.5], ["run", 3.2, "ahead", 3.0],
	["walk_back", 0.8, "back", 3.0], ["strafe_l", 0.8, "left", 3.0], ["strafe_r", 0.8, "right", 3.0],
	["crouch_idle", 0.0, "", 3.0], ["crouch_walk", 0.7, "ahead", 3.5], ["pistol_aim", 0.0, "", 2.5],
	["pistol_shoot", 0.0, "", 2.0], ["reload", 0.0, "", 2.0], ["long_aim", 0.0, "", 2.5],
	["long_shoot", 0.0, "", 2.0], ["long_reload", 0.0, "", 2.5], ["hit_front", 0.0, "hit", 3.0],
	["hit_head", 0.0, "hit_head", 3.0]]
const JOINTS := [&"thigh_l", &"thigh_r", &"shin_l", &"shin_r", &"upper_arm_l", &"upper_arm_r", &"forearm_l", &"forearm_r"]

var vp: SubViewport
var w: Node3D
var cam: Camera3D
var label: Label3D
var men := []
var plan := PLAN.duplicate()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/library_lineup"
	var mode := "film"
	var ids: Array = MEN
	var moves := []
	var size := Vector2i(960, 540)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--film" or a == "--sheet" or a == "--measure":
			mode = a.substr(2)
		elif a.begins_with("--men="):
			ids = Array(a.substr(6).split(","))
		elif a.begins_with("--moves="):
			moves = Array(a.substr(8).split(","))
		elif a == "--takes":
			plan = _takes()
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	DirAccess.make_dir_recursive_absolute(out + "/frames")
	var lib_on := not "--off" in OS.get_cmdline_user_args()  # --off: the game's own gait, to measure against
	root.get_node("/root/Settings").set("library_motion", lib_on)
	_stage(size)
	var body_script = load("res://src/bodies/human_body.gd")
	for i in ids.size():
		var m = body_script.new()
		m.body_model = StringName(ids[i])
		m.person_id = StringName(String(ids[i]) + "_lineup")
		m.rng_seed = 11 + i
		m.has_gun = false
		m.walk_clip = &"none"  # his own walk (config/walks.json) would lead the library's
		w.add_child(m)
		m.global_position = Vector3(i * 1.1, 0.0, -i * 1.4)
		m.global_rotation.y = -PI / 2  # facing +x
		men.append(m)
	for f in 20:
		await physics_frame
	if mode == "film" or mode == "measure":
		await _film(out, moves, mode == "measure")
	else:
		await _sheet(out, moves, size)
	quit()


## The PLAN with each move's candidate takes in its place, loaded into LibraryMotion's clips under
## their own names (run_0, run_1...).
func _takes() -> Array:
	var lib = load("res://src/bodies/library_motion.gd")
	lib.preload_clips()
	var dir := ProjectSettings.globalize_path("res://build/library/takes")
	var out := []
	for step in PLAN:
		for n in 8:
			var path := "%s/%s_%d.json" % [dir, step[0], n]
			if not FileAccess.file_exists(path):
				break
			var c = load("res://src/bodies/motion_clip.gd").new()
			c._read(StringName("%s_%d" % [step[0], n]), JSON.parse_string(FileAccess.get_file_as_string(path)))
			lib._clips[StringName("%s_%d" % [step[0], n])] = c
			var s2: Array = step.duplicate()
			s2[0] = "%s_%d" % [step[0], n]
			out.append(s2)
	return out


func _stage(size: Vector2i) -> void:
	vp = SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	w = Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.6, 0.56)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.74, 0.68)
	e.ambient_light_energy = 0.75
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	w.add_child(sun)
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 40)
	cs.shape = box
	ground.add_child(cs)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.47, 0.37)
	mesh.material_override = mat
	ground.add_child(mesh)
	ground.position.y = -0.5
	w.add_child(ground)
	# Marks on the ground a metre apart: the feet should stand on them, not skate.
	for x in range(-20, 200):
		var tick := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.04, 0.005, 4.4)
		tick.mesh = tm
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color(0.36, 0.3, 0.24)
		tick.material_override = tmat
		tick.position = Vector3(x, 0.003, -1.4)
		w.add_child(tick)
	cam = Camera3D.new()
	cam.fov = 40.0
	w.add_child(cam)
	cam.current = true
	label = Label3D.new()
	label.font_size = 64
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.1, 0.08, 0.06)
	label.outline_size = 0
	w.add_child(label)


func _centre() -> Vector3:
	var c := Vector3.ZERO
	for m in men:
		c += m.global_position
	return c / men.size()


func _aim_camera() -> void:
	var c := _centre()
	cam.global_position = c + Vector3(2.2, 1.35, 6.2)
	cam.look_at(c + Vector3(0.4, 0.85, 0.0))
	label.global_position = c + Vector3(0.4, 2.35, 1.0)


## Measured while he goes (each man, from the clip's second half second): `slide` the foot
## carrying him's level speed (m/s; the lower foot, on the ground, both frames: 0 is planted), `bounce`
## his hips' rise and fall (m), `travel` how far he went. One line a move: the men's mean.
func _film(out: String, moves: Array, measure_only := false) -> void:
	var n := 0
	# A tick's worth each tick (the loop wakes every physics tick, 60 a second; the film keeps every
	# second one, 30 a second of game time).
	var dt := 1.0 / Engine.physics_ticks_per_second
	for step in plan:
		var mv: String = step[0]
		if not moves.is_empty() and not mv in moves and not mv.rsplit("_", true, 1)[0] in moves:
			continue
		var speed: float = step[1]
		var how: String = step[2]
		var secs: float = step[3]
		label.text = mv.replace("_", " ")
		for m in men:
			m.global_rotation.y = -PI / 2
			m.set_pose(&"crouch" if mv.begins_with("crouch") else &"stand")
			if m._lib != null:
				m._lib.force = StringName(mv) if not how.begins_with("hit") else &"idle"
				m._lib.force_at = -1.0
		var frames := int(secs * Engine.physics_ticks_per_second)
		var track := []  # a man each: [[foot_l, foot_r, hips] a frame]
		for m in men:
			track.append([])
		for f in frames:
			for m in men:
				if speed > 0.0:
					var fwd := Vector3(1, 0, 0)
					var dir: Vector3 = {"ahead": fwd, "back": -fwd, "right": Vector3(0, 0, 1), "left": Vector3(0, 0, -1)}[how]
					m.walk_to(m.global_position + dir * 5.0, speed, dt, false)
				elif how.begins_with("hit") and f % 60 == 20:
					var seg := &"head" if how == "hit_head" else &"chest"
					m._lib.on_hit(m, {"segment": seg, "direction": Vector3(-1, 0, 0)})
			await physics_frame
			if f % 2 == 0:
				continue
			for k in men.size():
				var mm = men[k]
				track[k].append([(mm.pivots[&"foot_l"] as Node3D).global_position, (mm.pivots[&"foot_r"] as Node3D).global_position,
						(mm.pivots[&"pelvis"] as Node3D).global_position])
			if measure_only:
				continue
			_aim_camera()
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png("%s/frames/%05d.png" % [out, n])
			n += 1
		var sl := 0.0
		var bo := 0.0
		var tr := 0.0
		for t: Array in track:
			var r := _measure(t.slice(15))
			sl += r[0]
			bo += r[1]
			tr += r[2]
		print("measure %s: slide %.3f m/s, bounce %.3f m, travel %.2f m" % [mv, sl / men.size(), bo / men.size(), tr / men.size()])
		print("filmed %s (%d frames so far)" % [mv, n])
		# Back to standing between moves, where they are.
		for m in men:
			if m._lib != null:
				m._lib.force = &"idle"
		for f in 8:
			await physics_frame


## [slide m/s, bounce m, travel m] over a man's frames ([foot_l, foot_r, hips] each, 30 a second).
func _measure(t: Array) -> Array:
	if t.size() < 3:
		return [0.0, 0.0, 0.0]
	var low := [INF, INF]
	var hy := []
	for fr in t:
		low[0] = minf(low[0], (fr[0] as Vector3).y)
		low[1] = minf(low[1], (fr[1] as Vector3).y)
		hy.append((fr[2] as Vector3).y)
	var slide := 0.0
	var planted := 0
	for i in range(1, t.size()):
		# The foot carrying him: the lower one, both frames (a real walker's swinging foot clears
		# the ground by only a centimetre or two, so "near the ground" would count it).
		var s := 0 if (t[i][0] as Vector3).y < (t[i][1] as Vector3).y else 1
		var on: bool = (t[i][s] as Vector3).y < low[s] + 0.025 and (t[i - 1][s] as Vector3).y < low[s] + 0.025
		if on and (t[i - 1][s] as Vector3).y < (t[i - 1][1 - s] as Vector3).y:
			var a: Vector3 = t[i - 1][s]
			var b: Vector3 = t[i][s]
			slide += Vector2(b.x - a.x, b.z - a.z).length()
			planted += 1
	var p0: Vector3 = t[0][2]
	var p1: Vector3 = t[t.size() - 1][2]
	return [slide / maxf(planted, 1) * 30.0, hy.max() - hy.min(), Vector2(p1.x - p0.x, p1.z - p0.z).length()]


## Each clip's worst frame for his joints: the time each of the eight is turned furthest from its
## rest; the frame with the most of them is shown, front and side, beside his rest.
func _sheet(out: String, moves: Array, size: Vector2i) -> void:
	var tiles := []
	for step in plan:
		var mv: String = step[0]
		if not moves.is_empty() and not mv in moves and not mv.rsplit("_", true, 1)[0] in moves:
			continue
		var c = load("res://src/bodies/library_motion.gd").clip(StringName(mv))
		if c == null:
			continue
		var worst_t := 0.0
		var worst := -1.0
		for i in c.frames.size():
			var bend := 0.0
			for j: StringName in JOINTS:
				if (c.frames[i] as Dictionary).has(j):
					var q: Quaternion = c.frames[i][j]
					bend += q.get_angle()
			if bend > worst:
				worst = bend
				worst_t = i / c.fps
		for view in ["front", "side"]:
			label.text = "%s  %.2f s  %s" % [mv.replace("_", " "), worst_t, view]
			for k in men.size():
				var m = men[k]
				m.set_pose(&"crouch" if mv.begins_with("crouch") else &"stand")
				m._lib.force = StringName(mv)
				m._lib.force_at = worst_t
				m.global_position = Vector3(k * 1.0, 0.0, 0.0)
				m.global_rotation.y = PI if view == "front" else -PI / 2
			for f in 12:
				await physics_frame
			var ctr := _centre()
			cam.global_position = ctr + Vector3(0.0, 1.0, 4.6)
			cam.look_at(ctr + Vector3(0.0, 0.85, 0.0))
			label.global_position = ctr + Vector3(0.0, 2.1, 0.0)
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			img.resize(size.x / 2, size.y / 2)
			tiles.append(img)
		print("sheet %s at %.2f s" % [mv, worst_t])
	var cols := 4
	var tw: int = tiles[0].get_width()
	var th: int = tiles[0].get_height()
	var rows := ceili(tiles.size() / float(cols))
	var sheet := Image.create(tw * cols, th * rows, false, tiles[0].get_format())
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, tw, th), Vector2i((i % cols) * tw, (i / cols) * th))
	sheet.save_png(out + "/deformation_sheet.png")
	print("wrote ", out, "/deformation_sheet.png")
