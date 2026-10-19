extends SceneTree
## The "works" check for one man (docs/style_test/two-tests-2026-10-19): a people.json id in the
## game's HumanBody, plainly lit and seen orthographically, in the pose check (stand, walk, run,
## hands up, aim, sit, crouch) and a ragdoll fall, his hat knocked off, and a .45 through his chest
## (the wound and the blood). Each pose's skin measured against his rest: every triangle's longest
## edge over its own at rest (a sheet stretched between arm and side, a torn or pulled seam).
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/works_check.gd -- \
##       --id=bold_cowboy_whole --out=DIR
## Writes DIR/<check>_<view>.png and DIR/works.json (the numbers, and a pass/fail line for each).
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

## A triangle stretched past this (its longest edge over its own at rest) and longer than
## SHEET_M posed is a sheet: drawn across a gap, not a joint's own small triangles bending (the
## Oct 14 bold cowboy, whose MakeHuman body bends cleanly, doubles ~200 small ones round his
## shoulders and hips with his hands up or sitting).
const SHEET := 2.0
const SHEET_M := 0.05
## ... and the pose fails with more than this many of them.
const SHEETS_ALLOWED := 10

var out := "/tmp/works"
var id := "bold_cowboy_whole"
var vp: SubViewport
var w: Node3D
var cam: Camera3D
var report := {}
var poses := ["stand", "walk", "run", "hands_up", "aim", "sit", "crouch"]
## --poses-only: the pose check alone (no fall, hat or wounds).
var poses_only := false
## --ref=works.json: another man's check (the Oct 14 bold cowboy's, who bends cleanly): a pose
## passes with up to REF_SHARE of his sheets (or SHEETS_ALLOWED), not only SHEETS_ALLOWED.
var ref := {}
const REF_SHARE := 1.25
## ... or this much of them (cm²) at least.
const SHEET_CM2_ALLOWED := 20.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--id="):
			id = a.substr(5)
		elif a.begins_with("--poses="):
			poses = Array(a.substr(8).split(","))
		elif a == "--poses-only":
			poses_only = true
		elif a.begins_with("--ref="):
			var r = JSON.parse_string(FileAccess.get_file_as_string(a.substr(6)))
			if r is Dictionary:
				ref = r
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new()
	vp.size = Vector2i(420, 640)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	w = Node3D.new()
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
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	w.add_child(ground)
	var floor_mesh := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor_mesh.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.42, 0.4, 0.38)
	floor_mesh.material_override = fm
	w.add_child(floor_mesh)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.3
	w.add_child(cam)
	cam.current = true
	var ballistics = load("res://src/ballistics/ballistics.gd").new()
	w.add_child(ballistics)

	# The poses: one man, posed as the game poses him (walk and run by his gait).
	var man = _man()
	for f in 12:
		await physics_frame
	report["rest"] = _rest(man)
	for pose in poses:
		if pose in ["walk", "run"]:
			man.set_pose(&"stand")
			man._apply_pose(0.0, true)
			# Caught mid-stride: his feet furthest apart over a second or two of it.
			var best := 0.0
			for f in 240:
				man.walk_to(man.global_position + Vector3(0, 0, -5), 1.4 if pose == "walk" else 3.5, 1.0 / 60.0, false)
				man.global_position = Vector3.ZERO
				await physics_frame
				var apart: float = (man.parts[&"foot_r"] as Node3D).global_position.distance_to((man.parts[&"foot_l"] as Node3D).global_position)
				if OS.get_environment("WORKS_DEBUG") != "" and f % 5 == 0:
					print("%s f%d apart %.3f" % [pose, f, apart])
				# A second and a half to learn his widest stride, then the next time he reaches it.
				if f < 90:
					best = maxf(best, apart)
				elif apart >= best * 0.95:
					break
		else:
			man.set_pose(StringName(pose))
			man._apply_pose(0.0, true)
			# Poses ease in: settled before he's measured and drawn.
			for f in 40:
				await physics_frame
		# Held where he is for the pictures (left alone, his stride eases back to standing).
		man.set_physics_process(false)
		man.set_process(false)
		await _shots(pose, man, ["front", "side"])
		report[pose] = _stretch(man)
		man.set_physics_process(true)
		man.set_process(true)
	man.queue_free()
	await physics_frame
	if poses_only:
		_finish()
		return

	# The ragdoll fall: limp with a push, three seconds down.
	man = _man()
	for f in 12:
		await physics_frame
	man.go_limp(Vector3(0, 0, 2.5))
	for f in 180:
		await physics_frame
	await _shots("ragdoll", man, ["front", "side"], Vector3(0, 0.4, 0))
	report["ragdoll"] = _stretch(man)
	man.queue_free()
	await physics_frame

	# His hat: shot off (take_hat_shot, as a ball through the crown does in the game).
	man = _man()
	for f in 12:
		await physics_frame
	var had_hat: bool = man.hat_body != null
	var crown: Vector3 = man.hat_body.global_position if had_hat else Vector3.ZERO
	var kept := 0.0
	if had_hat:
		kept = man.take_hat_shot(crown, Vector3(1, 0, 0), 600.0, null)
	for f in 90:
		await physics_frame
	var hats := root.get_tree().get_nodes_in_group(&"hats")
	var hat_meshes_left := 0
	for mi in man._hat_pieces():
		if mi.visible and mi.is_visible_in_tree():
			hat_meshes_left += 1
	report["hat"] = {"had_his_own_hat": had_hat, "hat_off": man.hat_off, "hats_fallen": hats.size(),
			"hat_meshes_still_on_him": hat_meshes_left, "ball_energy_kept_j": kept,
			"pass": had_hat and man.hat_off and hats.size() > 0 and hat_meshes_left == 0}
	await _shots("hat_off", man, ["front", "three_quarter"])
	man.queue_free()
	await physics_frame

	# A .45 through his upper arm from 3 m (the wound on his sleeve while he stands), then one
	# through his chest (he goes down; the blood).
	man = _man()
	man.has_gun = false
	for f in 12:
		await physics_frame
	var t = load("res://config/revolver.tres")
	for seg in [&"upper_arm_r", &"chest"]:
		var part: Node3D = man.parts[seg]
		var at: Vector3 = part.global_position
		var from := at + Vector3(0.0, 0.05, 3.0)
		var b = ballistics.fire(from, (at - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
		for f in 60:
			await physics_frame
			if not b.alive:
				break
		if seg == &"upper_arm_r":
			for f in 30:
				await physics_frame
			cam.size = 0.8
			await _shots("wound_arm", man, ["front"], Vector3(0, 0.45, 0))
	for f in 240:
		await physics_frame
	var words: PackedStringArray = man.describe_wounds()
	report["wounds"] = {"wounds": Array(words), "openings": man.openings.size(), "pass": words.size() > 0}
	cam.size = 1.6
	await _shots("wound_blood", man, ["above"])
	cam.size = 2.3
	man.queue_free()

	_finish()


func _finish() -> void:
	for k in report:
		if report[k] is Dictionary and report[k].has("sheets") and ref.has(k) and ref[k] is Dictionary:
			# By their area (what shows), not their count: a finer mesh stretches more, smaller ones.
			var allowed := maxf(SHEET_CM2_ALLOWED, float(ref[k].get("sheet_cm2", 0.0)) * REF_SHARE)
			report[k]["ref_sheets"] = ref[k].get("sheets", 0)
			report[k]["ref_sheet_cm2"] = ref[k].get("sheet_cm2", 0.0)
			report[k]["pass"] = float(report[k]["sheet_cm2"]) <= allowed
	var fails := []
	for k in report:
		if report[k] is Dictionary and report[k].has("pass") and not report[k]["pass"]:
			fails.append(k)
	report["fails"] = fails
	var f := FileAccess.open(out + "/works.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, " "))
	f.close()
	print("works_check: %s %s" % [id, "PASS" if fails.is_empty() else "FAIL " + str(fails)])
	quit()


func _man():
	var m = load("res://src/bodies/human_body.gd").new()
	m.body_model = StringName(id)
	m.person_id = StringName(id + "_works")
	m.rng_seed = 7
	w.add_child(m)
	m.global_position = Vector3.ZERO
	m.face(Vector3(0, 0, 5))
	return m


## Each skinned mesh's triangles' rest edge lengths, by mesh key.
var _rest_edges := {}
## Where (at rest) a stretched sheet of each mesh is, for the report.
var _worst_at := {}


func _rest(man) -> Dictionary:
	var n := 0
	for key: String in man.skin_meshes:
		var mi: MeshInstance3D = man.skin_meshes[key]
		var arr := mi.mesh.surface_get_arrays(0)
		_rest_edges[key] = _edges(arr[Mesh.ARRAY_VERTEX], arr[Mesh.ARRAY_INDEX])
		n += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return {"meshes": man.skin_meshes.keys(), "triangles": n}


func _edges(v: PackedVector3Array, idx: PackedInt32Array) -> PackedFloat32Array:
	var e := PackedFloat32Array()
	e.resize(idx.size() / 3)
	for t in idx.size() / 3:
		var a := v[idx[t * 3]]
		var b := v[idx[t * 3 + 1]]
		var c := v[idx[t * 3 + 2]]
		e[t] = maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a)))
	return e


## The posed skin against his rest: triangles whose longest edge grew past SHEET.
func _stretch(man) -> Dictionary:
	var worst := 1.0
	var sheets := 0
	var area := 0.0
	var where := {}
	for key: String in man.skin_meshes:
		var mi: MeshInstance3D = man.skin_meshes[key]
		# Every piece, drawn or not (while he's whole they're drawn merged, the same triangles).
		if not _rest_edges.has(key):
			continue
		var arr := mi.mesh.surface_get_arrays(0)
		var posed := _skinned(man, mi, arr)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var now := _edges(posed, idx)
		var rest: PackedFloat32Array = _rest_edges[key]
		for t in mini(now.size(), rest.size()):
			if rest[t] < 0.002:
				continue
			var r := now[t] / rest[t]
			worst = maxf(worst, r)
			if r > SHEET and now[t] > SHEET_M:
				sheets += 1
				area += (posed[idx[t * 3 + 1]] - posed[idx[t * 3]]).cross(posed[idx[t * 3 + 2]] - posed[idx[t * 3]]).length() * 0.5
				where[key] = where.get(key, 0) + 1
				if r > worst * 0.999 or not _worst_at.has(key):
					var rv: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
					var ri: PackedInt32Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
					_worst_at[key] = (rv[ri[t * 3]] + rv[ri[t * 3 + 1]] + rv[ri[t * 3 + 2]]) / 3.0
	var at := {}
	for k in _worst_at:
		at[k] = [snappedf(_worst_at[k].x, 0.01), snappedf(_worst_at[k].y, 0.01), snappedf(_worst_at[k].z, 0.01)]
	_worst_at.clear()
	return {"worst_stretch": snappedf(worst, 0.01), "sheets": sheets, "sheet_cm2": snappedf(area * 1e4, 0.1),
			"sheets_in": where, "sheet_at_rest": at, "pass": sheets <= SHEETS_ALLOWED}


## His mesh's vertices where his skeleton has them now: each the weighted sum of its bones' moves
## (pose × the skin's bind), as the GPU skins him.
func _skinned(man, mi: MeshInstance3D, arr: Array) -> PackedVector3Array:
	var sk: Skeleton3D = man.skeleton
	# Its global poses as they are this frame (read straight after a pose they were the last one's).
	man._update_skeleton()
	sk.force_update_all_bone_transforms()
	var moves := []
	for b in mi.skin.get_bind_count():
		var bone := mi.skin.get_bind_bone(b)
		if bone < 0:
			bone = b
		moves.append(sk.get_bone_global_pose(bone) * mi.skin.get_bind_pose(b))
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / maxi(v.size(), 1)
	var out := PackedVector3Array()
	out.resize(v.size())
	for i in v.size():
		var p := Vector3.ZERO
		var total := 0.0
		for k in per:
			var wt := weights[i * per + k]
			if wt <= 0.0:
				continue
			p += (moves[bones[i * per + k]] as Transform3D) * v[i] * wt
			total += wt
		out[i] = p / total if total > 0.0 else v[i]
	return out


func _shots(name: String, man, views: Array, aim := Vector3.ZERO) -> void:
	var at: Vector3 = man.global_position + Vector3(0, 0.95, 0) + aim
	if name == "ragdoll" and man.parts.has(&"chest"):
		at = (man.parts[&"chest"] as Node3D).global_position + Vector3(0, 0.1, 0)
	if name == "wound_blood":
		at = (man.parts[&"chest"] as Node3D).global_position
	for view in views:
		var to := Vector3(0, 0, 5)
		if view == "side":
			to = Vector3(5, 0, 0)
		elif view == "three_quarter":
			to = Vector3(3.5, 0, 3.5)
		elif view == "above":
			to = Vector3(0.0, 4.0, 2.5)
		cam.look_at_from_position(at + to, at)
		for f in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("%s/%s_%s.png" % [out, name, view])
