extends SceneTree
## The library clips on the game's men (issue #529): three Studio men side by side on each clip in
## turn, walking where the clip walks, as frames for a film (`--film`), or each clip's worst frame
## for the knees, hips, shoulders and elbows as a contact sheet (`--sheet`: the frame each joint
## is bent furthest from its rest, front and side).
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 30 -s res://tools/library_lineup.gd -- \
##       --out=DIR --film|--sheet [--men=a,b,c] [--moves=walk,run] [--size=960x540] [--takes]
## --takes: every candidate take of the moves (build/library/takes/<move>_<n>.json, from
## `library_motion.py takes`) in place of the picked clips, to choose between them.
## The film's frames are DIR/frames/%05d.png (ffmpeg makes the mp4: experiments/library_motion/film.sh).

const MEN := ["bold_cowboy_s3_talking", "old_rancher_s3_talking", "young_drifter_s3_talking"]
## Each move: how he goes (speed m/s; "ahead", "back", "right", "left" of his facing), seconds.
const PLAN := [
	["idle", 0.0, "", 3.0], ["walk", 1.3, "ahead", 3.5], ["run", 3.8, "ahead", 3.0],
	["walk_back", 1.2, "back", 3.0], ["strafe_l", 3.0, "left", 2.5], ["strafe_r", 3.0, "right", 2.5],
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
		elif a == "--film" or a == "--sheet":
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
	root.get_node("/root/Settings").set("library_motion", true)
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
	if mode == "film":
		await _film(out, moves)
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


func _film(out: String, moves: Array) -> void:
	var n := 0
	var dt := 1.0 / 30.0
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
			m._lib.force = StringName(mv) if not how.begins_with("hit") else &"idle"
			m._lib.force_at = -1.0
		var frames := int(secs * 30.0)
		for f in frames:
			for m in men:
				if speed > 0.0:
					var fwd := Vector3(1, 0, 0)
					var dir: Vector3 = {"ahead": fwd, "back": -fwd, "right": Vector3(0, 0, 1), "left": Vector3(0, 0, -1)}[how]
					m.walk_to(m.global_position + dir * 5.0, speed, dt, false)
				elif how.begins_with("hit") and f % 30 == 10:
					var seg := &"head" if how == "hit_head" else &"chest"
					m._lib.on_hit(m, {"segment": seg, "direction": Vector3(-1, 0, 0)})
			await physics_frame
			_aim_camera()
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png("%s/frames/%05d.png" % [out, n])
			n += 1
		print("filmed %s (%d frames so far)" % [mv, n])
		# Back to standing between moves, where they are.
		for m in men:
			m._lib.force = &"idle"
		for f in 8:
			await physics_frame


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
