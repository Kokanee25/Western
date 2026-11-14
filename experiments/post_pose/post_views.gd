extends SceneTree
## A Studio man bladed behind the saloon's gallery post (issue #531, PostPose), four views and the
## checks, or a sheet of seeds (the family):
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/post_pose/post_views.gd -- \
##       --out=DIR [--man=bold_cowboy_s3_talking] [--seeds=1,2,3] [--views=front,three_quarter,overhead,side] [--size=640x640]
## The threat stands 6 m north of the post (-Z), eye 1.6 m up; the man south of it, facing east (+X).
## Writes DIR/<man>_s<seed>_<view>.png and DIR/checks.json (each seed's dials and measures).

const THREAT := Vector3(0.0, 0.0, -6.0)
const EYE := 1.6
const VIEWS := {
	"front": [Vector3(0.0, 1.55, -4.2), Vector3(0.0, 1.0, 0.15)],
	"three_quarter": [Vector3(2.3, 1.75, -2.2), Vector3(0.05, 1.05, 0.2)],
	"overhead": [Vector3(0.15, 8.0, 0.3), Vector3(0.15, 0.0, 0.3)],
	"side": [Vector3(3.6, 1.2, 0.25), Vector3(0.0, 1.0, 0.25)],
}

var vp: SubViewport
var w: Node3D
var cam: Camera3D
var PP  # PostPose (by load(): a -s script compiles before the autoloads it would need)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/post_pose"
	var man_id := "bold_cowboy_s3_talking"
	var seeds := [1]
	var views := ["front", "three_quarter", "overhead", "side"]
	var size := Vector2i(640, 640)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--man="):
			man_id = a.substr(6)
		elif a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--views="):
			views = Array(a.substr(8).split(","))
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	DirAccess.make_dir_recursive_absolute(out)
	PP = load("res://src/bodies/post_pose.gd")
	_stage(size)
	var post = load("res://experiments/post_pose/post_stand.gd").new()
	post.structure_id = &"post_stand"
	w.add_child(post)
	var checks := {}
	var body_script = load("res://src/bodies/human_body.gd")
	for s in seeds:
		var m = body_script.new()
		m.body_model = StringName(man_id)
		m.person_id = StringName("%s_post%d" % [man_id, s])
		m.rng_seed = s
		m.face_life = false
		w.add_child(m)
		m.global_position = Vector3(0.0, 0.0, 0.6)
		for f in 10:
			await physics_frame
		m.draw_gun()
		var d: Dictionary = m.take_post(THREAT + Vector3.UP * EYE)
		for f in 90:
			await physics_frame
		PP.place_at(m, Vector3.ZERO, THREAT, float(d.peek))
		for f in 10:
			await physics_frame
		var c := _checks(m)
		c["dials"] = _plain(d)
		checks[str(s)] = c
		print("seed %d: %s" % [s, JSON.stringify(c)])
		for v in views if views != ["none"] else []:
			var at: Array = VIEWS[v]
			# Overhead square on (orthographic), so the post's top doesn't swamp him.
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL if v == "overhead" else Camera3D.PROJECTION_PERSPECTIVE
			cam.size = 1.9
			cam.look_at_from_position(at[0], at[1], Vector3.FORWARD if v == "overhead" else Vector3.UP)
			for f in 4:
				await process_frame
			vp.get_texture().get_image().save_png("%s/%s_s%d_%s.png" % [out, man_id, s, v])
		m.queue_free()
		for f in 3:
			await process_frame
	var fa := FileAccess.open(out + "/checks.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(checks, "\t"))
	fa.close()
	print("saved to ", out)
	quit()


static func _plain(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d:
		var v = d[k]
		o[k] = String(v) if v is StringName else (snappedf(v, 0.01) if v is float else v)
	return o


## What the issue asks to check, measured from his joints and capsules where they are.
func _checks(m) -> Dictionary:
	var pv: Dictionary = m.pivots
	var sh: Vector3 = (pv[&"upper_arm_r"] as Node3D).global_position
	var el: Vector3 = (pv[&"forearm_r"] as Node3D).global_position
	var wr: Vector3 = (pv[&"hand_r"] as Node3D).global_position
	var shl: Vector3 = (pv[&"upper_arm_l"] as Node3D).global_position
	var ell: Vector3 = (pv[&"forearm_l"] as Node3D).global_position
	var fore := wr - el
	var to_threat := THREAT - el
	var c := {}
	c["upper_arm_r_from_vertical"] = snappedf(rad_to_deg((el - sh).angle_to(Vector3.DOWN)), 0.1)
	c["elbow"] = snappedf(rad_to_deg((sh - el).angle_to(wr - el)), 0.1)
	c["forearm_from_level"] = snappedf(rad_to_deg(asin(clampf(fore.normalized().y, -1.0, 1.0))), 0.1)
	c["forearm_off_threat"] = snappedf(rad_to_deg(Vector2(fore.x, fore.z).angle_to(Vector2(to_threat.x, to_threat.z))), 0.1)
	c["upper_arm_l_from_vertical"] = snappedf(rad_to_deg((ell - shl).angle_to(Vector3.DOWN)), 0.1)
	var caps: Array = PP.capsules_now(m)
	var trunk: Array = caps.filter(func(k): return k[0] in [&"abdomen", &"chest", &"pelvis"])
	var gap := INF
	for k: Array in caps:
		if k[0] == &"forearm_r" or k[0] == &"hand_r":
			for t: Array in trunk:
				gap = minf(gap, PP.seg_distance(k[1], k[2], t[1], t[2]) - float(k[3]) - float(t[3]))
	c["forearm_to_trunk_gap"] = snappedf(gap, 0.001)
	# Into the post: any capsule's overlap with the post's box (m, 0 none).
	var into := 0.0
	var into_what := ""
	for k: Array in caps:
		var i := _into_post(k[1], k[2], float(k[3]))
		if i > into:
			into = i
			into_what = String(k[0])
	c["body_into_post"] = snappedf(into, 0.001)
	c["body_into_post_what"] = into_what
	# Seen by the threat: threat-facing surface points of each capsule whose line to his eye the post
	# cuts, by group.
	var eye := THREAT + Vector3.UP * EYE
	var groups := {"head": [&"head", &"neck"], "trunk": [&"chest", &"abdomen", &"pelvis"],
			"gun_arm": [&"upper_arm_r", &"forearm_r", &"hand_r"], "left_arm": [&"upper_arm_l", &"forearm_l", &"hand_l"],
			"legs": [&"thigh_r", &"thigh_l", &"shin_r", &"shin_l", &"foot_r", &"foot_l"]}
	var hid_all := 0
	var n_all := 0
	var hidden := {}
	for g in groups:
		var hid := 0
		var n := 0
		for k: Array in caps:
			if not k[0] in groups[g]:
				continue
			for i in 7:
				var p: Vector3 = (k[1] as Vector3).lerp(k[2], i / 6.0)
				var toward := (eye - p).normalized()
				var side := toward.cross(Vector3.UP).normalized()
				for off: Vector3 in [toward, (toward + side).normalized(), (toward - side).normalized(),
						(toward + Vector3.UP * 0.8).normalized(), (toward - Vector3.UP * 0.8).normalized()]:
					var q := p + off * float(k[3])
					n += 1
					if _post_cuts(q, eye):
						hid += 1
		hidden[g] = snappedf(float(hid) / maxf(n, 1), 0.01)
		hid_all += hid
		n_all += n
	hidden["all"] = snappedf(float(hid_all) / maxf(n_all, 1), 0.01)
	c["hidden_from_threat"] = hidden
	c["eye_sees_threat"] = not _post_cuts(PP.eye_now(m), eye)
	c["lean"] = snappedf(-((m.post_pose[&"abdomen"] as Vector3).x + (m.post_pose[&"chest"] as Vector3).x), 0.1)
	# His trunk's middle off the post's middle, across the threat's line (m; the post is 0.2 wide).
	var lo := INF
	var hi := -INF
	for k: Array in trunk:
		for p: Vector3 in [k[1], k[2]]:
			lo = minf(lo, p.x - float(k[3]))
			hi = maxf(hi, p.x + float(k[3]))
	c["trunk_off_post"] = snappedf((lo + hi) * 0.5, 0.001)
	# Where his head, chest and hips face, off the threat (degrees, level).
	for sid in [&"head", &"chest", &"pelvis"]:
		var f: Vector3 = -(pv[sid] as Node3D).global_basis.z
		var to_eye: Vector3 = eye - (pv[sid] as Node3D).global_position
		c["%s_off_threat" % sid] = snappedf(rad_to_deg(Vector2(f.x, f.z).angle_to(Vector2(to_eye.x, to_eye.z))), 0.1)
	# The gun: into the post, and its muzzle's line to the threat.
	var gun: Node3D = m.held_gun
	if gun != null:
		var box := AABB()
		var first := true
		for g in gun.find_children("*", "MeshInstance3D", true, false):
			var mi := g as MeshInstance3D
			var bb := mi.global_transform * mi.get_aabb()
			box = bb if first else box.merge(bb)
			first = false
		var post := AABB(Vector3(-0.1, 0.0, -0.1), Vector3(0.2, 3.66, 0.2))
		c["gun_into_post"] = box.intersects(post)
		var barrel: Vector3 = (gun.global_transform.basis * Vector3.FORWARD).normalized()  # the model's barrel is its -Z
		var muzzle := gun.global_position
		var far := -INF
		for k in 8:
			var corner := box.get_endpoint(k)
			if (corner - gun.global_position).dot(barrel) > far:
				far = (corner - gun.global_position).dot(barrel)
				muzzle = corner
		c["muzzle_seen_by_threat"] = not _post_cuts(muzzle, eye)
		c["barrel_off_threat"] = snappedf(rad_to_deg(Vector2(barrel.x, barrel.z).angle_to(Vector2(eye.x - muzzle.x, eye.z - muzzle.z))), 0.1)
		c["gun_height"] = snappedf(gun.global_position.y, 0.01)
	return c


## How far a capsule goes into the post's box (m).
static func _into_post(a: Vector3, b: Vector3, r: float) -> float:
	var worst := 0.0
	for i in 11:
		var p := a.lerp(b, i / 10.0)
		if p.y < 0.0 or p.y > 3.66:
			continue
		var dx := absf(p.x) - 0.1
		var dz := absf(p.z) - 0.1
		var dist := Vector2(maxf(dx, 0.0), maxf(dz, 0.0)).length() if (dx > 0.0 or dz > 0.0) else maxf(dx, dz)
		worst = maxf(worst, r - dist)
	return maxf(worst, 0.0)


## Whether the post stands between p and the eye.
static func _post_cuts(p: Vector3, eye: Vector3) -> bool:
	var box := AABB(Vector3(-0.1, 0.0, -0.1), Vector3(0.2, 3.66, 0.2))
	return box.intersects_segment(p, eye) != null and not box.has_point(p)


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
	sun.rotation_degrees = Vector3(-50, 150, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
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
	# A mark on the floor toward the threat (north), so each view says which way it is.
	var arrow := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(0.05, 0.006, 1.2)
	arrow.mesh = am
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.6, 0.12, 0.08)
	arrow.material_override = amat
	arrow.position = Vector3(0.0, 0.003, -0.9)
	w.add_child(arrow)
	cam = Camera3D.new()
	cam.fov = 40.0
	w.add_child(cam)
	cam.current = true
