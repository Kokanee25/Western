extends SceneTree
## Fit the seated man (ShotMatch) to the painting's man: his outline from your seat against the
## painting's traced outline (IoU, at a quarter of the painting's size), his eyes onto its eyes, the
## cup in his hand onto its cup (and its size), and his palm in front of the mug. Coordinate descent
## over [turn°, dx, dz (m), head xyz°, chest y x z°, upper arm xyz°, forearm xy°, neck xyz°,
## abdomen z°, hand xyz°], all on top of what ShotMatch stages; print the result and copy it into
## ShotMatch (SEAT, TURN, pose_offsets).
##   python3 - (write the painting's outline mask: tools/paint/align.py SHOT_OUTLINE, 418x235) > mask
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/fit_shot.gd -- mask.png
##       [--start=[...]] [--grid] [--dump=[...]|out.png]
const Q := Vector2i(418, 235)
const WANT_R := Vector2(614, 360)  # the painting's eyes (1672x941): his right, his left
const WANT_L := Vector2(685, 386)
const WANT_CUP := Vector2(778, 688)
var stage
var set: Dictionary
var vp: SubViewport
var man
var want: PackedByteArray
var base_pos: Vector3
var base_yaw: float
var eyes := []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	stage = load("res://tools/lab_stage.gd")
	root.get_node(^"Settings").autosave = false
	vp = SubViewport.new()
	vp.size = Q
	root.add_child(vp)
	set = stage.build(vp, stage.default_energy())
	man = set.man
	for i in 90:
		await physics_frame
	var white := StandardMaterial3D.new()
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var black := white.duplicate()
	black.albedo_color = Color.BLACK
	for gi: GeometryInstance3D in set.world.find_children("*", "GeometryInstance3D", true, false):
		gi.material_override = white if man.is_ancestor_of(gi) else black
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	(set.camera as Camera3D).environment = env
	var img := Image.load_from_file(OS.get_cmdline_user_args()[0])
	img.convert(Image.FORMAT_L8)
	want = img.get_data()
	base_pos = man.global_position
	base_yaw = man.global_rotation.y
	for id in [&"eye_r", &"eye_l"]:
		eyes.append((man.anatomy.structure(id).a as Vector3) - man.anatomy.segment_center(&"head"))
	# params: yaw (deg), dx, dz (m, world), head x, y, z (deg), chest y (deg)
	var p := [0.0, 0.0, 0.0, 6.0, -8.5, 16.0, 0.0, 0.0, 0.0]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--start="):
			p = JSON.parse_string(a.substr(8))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dump="):
			var parts := a.substr(7).split("|")
			var q: Array = JSON.parse_string(parts[0])
			var sc: Array = await _score(q)
			vp.get_texture().get_image().save_png(parts[1])
			print("DUMP ", parts[1], " ", sc)
			var cup := man.find_child("HeldCup", true, false) as Node3D
			var cam: Camera3D = set.camera
			var kk := 1672.0 / Q.x
			var top := cam.unproject_position(cup.global_position + Vector3.UP * 0.05) * kk
			var bot := cam.unproject_position(cup.global_position - Vector3.UP * 0.05) * kk
			print("CUP height px ", top.distance_to(bot), " centre ", cam.unproject_position(cup.global_position) * kk, " dist ", cam.global_position.distance_to(cup.global_position))
			var hand: Node3D = man.parts[&"hand_r"]
			var fa: Node3D = man.parts[&"forearm_r"]
			print("HAND at ", cam.unproject_position(hand.global_position) * kk, " forearm at ", cam.unproject_position(fa.global_position) * kk, " hand dist ", cam.global_position.distance_to(hand.global_position))
	if " ".join(OS.get_cmdline_user_args()).contains("--dump="):
		quit()
		return
	if OS.get_cmdline_user_args().has("--grid"):
		var rows := []
		for yaw in [-30.0, -20.0, -10.0, 0.0, 10.0, 20.0, 30.0]:
			for dx in [-0.2, -0.1, 0.0, 0.1, 0.2]:
				for ch in [-20.0, 0.0, 20.0]:
					var g: Array = await _score([yaw, dx, 0.0, 6.0, -8.5, 16.0, ch])
					rows.append([g[1], yaw, dx, ch])
		rows.sort_custom(func(a, b): return a[0] > b[0])
		for r in rows.slice(0, 12):
			print("GRID iou %.3f yaw %d dx %.2f chest %d" % r)
		quit()
		return
	var steps := [6.0, 0.1, 0.05, 4.0, 4.0, 4.0, 6.0, 6.0, 10.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 8.0, 10.0, 10.0, 10.0, 10.0]
	while p.size() < steps.size():
		p.append(0.0)
	var best: Array = await _score(p)
	print("start ", best, " ", p)
	for round_i in 5:
		var improved := true
		while improved:
			improved = false
			for k in p.size():
				for sgn in [-1.0, 1.0]:
					var q := p.duplicate()
					q[k] += sgn * steps[k]
					var s: Array = await _score(q)
					if s[0] < best[0] - 1e-4:
						best = s
						p = q
						improved = true
		print("round ", round_i, " ", best, " ", p)
		for k in steps.size():
			steps[k] *= 0.5
	print("FIT ", JSON.stringify(p), " score ", best)
	quit()

func _apply(p: Array) -> void:
	man.global_position = base_pos + Vector3(p[1], 0, p[2])
	man.global_rotation.y = base_yaw + deg_to_rad(p[0])
	var po := {&"head": Vector3(p[3], p[4], p[5]), &"chest": Vector3(p[7], p[6], p[8])}
	if p.size() > 9:
		po[&"upper_arm_r"] = Vector3(p[9], p[10], p[11])
		po[&"forearm_r"] = Vector3(p[12], p[13], 0)
	if p.size() > 14:
		po[&"neck"] = Vector3(p[14], p[15], p[16])
		po[&"abdomen"] = Vector3(0, 0, p[17])
	if p.size() > 18:
		po[&"hand_r"] = Vector3(p[18], p[19], p[20])
	man.pose_offsets = po
	man._breath = 0.0
	man._apply_pose(0.0, true)

func _score(p: Array) -> Array:
	_apply(p)
	for i in 2:
		await physics_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_L8)
	var d := img.get_data()
	var inter := 0
	var uni := 0
	for i in d.size():
		var a := d[i] > 127
		var b := want[i] > 127
		if a and b:
			inter += 1
		if a or b:
			uni += 1
	var iou: float = float(inter) / maxf(uni, 1.0)
	var head: Node3D = man.parts[&"head"]
	var cam: Camera3D = set.camera
	var k := 1672.0 / Q.x
	var er := cam.unproject_position(head.global_transform * (eyes[0] as Vector3)) * k
	var el := cam.unproject_position(head.global_transform * (eyes[1] as Vector3)) * k
	var eye_err := (er.distance_to(WANT_R) + el.distance_to(WANT_L)) * 0.5
	var cup := man.find_child("HeldCup", true, false) as Node3D
	var cp := cam.unproject_position(cup.global_position) * k if cup else WANT_CUP
	var cup_err := cp.distance_to(WANT_CUP)
	var cup_h := 0.0
	if cup:
		cup_h = (cam.unproject_position(cup.global_position + Vector3.UP * 0.05) - cam.unproject_position(cup.global_position - Vector3.UP * 0.05)).length() * k
	var size_err := absf(cup_h - 128.0)
	# The back of his hand towards you: his palm between you and the mug, by a few centimetres.
	var behind := 0.0
	if cup:
		var hand_d := cam.global_position.distance_to((man.parts[&"hand_r"] as Node3D).global_position)
		behind = maxf(0.0, hand_d - cam.global_position.distance_to(cup.global_position) + 0.03)
	return [1.0 - iou + 0.004 * eye_err + 0.002 * cup_err + 0.0005 * size_err + 10.0 * behind, iou, eye_err, er, el, cup_err, cp, cup_h, behind]
