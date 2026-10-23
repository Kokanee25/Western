extends Node
## The gun lab's quick views, the work (views.gd launches it once the game's autoloads are up).

const STATES := {
	"revolver": ["rest", "aim", "cocked", "reload_open", "reload_eject", "reload_insert", "look_down", "detail_left", "detail_right", "detail_below", "detail_cocked"],
	"shotgun": ["rest", "aim", "cocked", "open", "pulled", "loaded", "look_down", "detail_left", "detail_right", "detail_below", "detail_open"],
}
## The detail views: a camera 0.45 m off the gun (in its own space: from its left, right, below).
const DETAIL := {"left": Vector3(-0.42, 0.06, -0.08), "right": Vector3(0.42, 0.06, -0.08), "below": Vector3(0.12, -0.4, -0.12)}

var _detail: Camera3D

var _player: Player


func _arg(name: String, default := "") -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return default


func run() -> void:
	var out := _arg("out", "build/gun_lab/views")
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(out)
	var world := Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.68, 0.74)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.62, 0.6, 0.58)
	env.environment.ambient_light_energy = 0.7
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 150, 0)  # low behind the right shoulder, as the town's 16:00
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor := StaticBody3D.new()
	floor.collision_layer = Layers.WORLD
	var fs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.2, 60)
	fs.shape = box
	fs.position.y = -0.1
	floor.add_child(fs)
	var fm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	fm.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.6, 0.45)
	fm.material_override = mat
	floor.add_child(fm)
	world.add_child(floor)
	_player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	world.add_child(_player)
	for i in 10:
		await get_tree().process_frame
	_player.camera.make_current()
	var guns := ["revolver", "shotgun"] if _arg("gun") == "" else [_arg("gun")]
	var only := _arg("only").split(",", false)
	for g: String in guns:
		var w: WeaponViewmodel = _player.revolver() if g == "revolver" else _player.shotgun()
		w.needs_captured_mouse = false
		_player.select_weapon(w)
		w.take_out()
		for i in 80:
			await get_tree().process_frame
		if _arg("fit") != "":
			_fit(w)
		for st: String in STATES[g]:
			if not only.is_empty() and not only.has(st):
				continue
			await _state(w, st)
			print("POSE %s %s pos %s rot %s tuck %.2f" % [g, st, (w.position * 100).snappedf(0.1), w.rotation_degrees.snappedf(0.1), w.tuck])
			if st.begins_with("detail"):
				_detail_cam(w, st)
				_print_hand(w)
				await _frames(2)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s.png" % [g, st]))
			_player.camera.make_current()
			await _reset(w)
	get_tree().quit()


## A camera looking at the gun from DETAIL's side (its model's space), narrow, its own light on.
func _detail_cam(w: WeaponViewmodel, st: String) -> void:
	if _detail == null:
		_detail = Camera3D.new()
		_detail.fov = 40.0
		_detail.near = 0.02
		_detail.cull_mask = _player.camera.cull_mask
		add_child(_detail)
	var side := "left"
	for k: String in DETAIL:
		if st.contains(k):
			side = k
	var gun: Node3D = w.get(&"model")
	var at := gun.global_transform * Vector3(0.0, -0.02, -0.04)
	_detail.global_position = gun.global_transform * DETAIL[side]
	_detail.look_at(at, gun.global_basis.y if side != "below" else -gun.global_basis.z)
	_detail.make_current()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _reset(w: WeaponViewmodel) -> void:
	Input.action_release(&"aim")
	_player.rotation = Vector3.ZERO
	_player.add_look(Vector2(0.0, -_player.get_pitch_degrees()))
	if w is RevolverViewmodel:
		var r := (w as RevolverViewmodel).state
		r.gate_open = false
		r.hammer = RevolverState.Hammer.DOWN
		r.chambers.fill(RevolverState.Chamber.LOADED)
		r.busy = 0.0
	else:
		var s := (w as ShotgunViewmodel).state
		s.open = false
		s.barrels.assign([ShotgunState.Barrel.LOADED, ShotgunState.Barrel.LOADED])
		s.cocked_hammers.assign([false, false])
		s.busy = 0.0
	await _frames(30)


func _state(w: WeaponViewmodel, st: String) -> void:
	match st:
		"rest":
			await _frames(30)
		"aim":
			Input.action_press(&"aim")
			await _frames(60)
		"look_down":
			w.put_away()
			await _frames(60)
			_player.add_look(Vector2(0.0, -60.0 - _player.get_pitch_degrees()))
			await _frames(10)
			w.take_out()
		"cocked", "detail_cocked":
			w.call(&"cock_press")
			await _frames(6)
		"detail_open":
			_spend(w)
			w.call(&"reload_press")
			await _frames(30)
		"reload_open", "open":
			_spend(w)
			w.call(&"reload_press")
			await _frames(30)
		"reload_eject", "pulled":
			_spend(w)
			w.call(&"reload_press")
			await _until_free(w)
			w.call(&"reload_press")
			await _frames(8)
		"reload_insert", "loaded":
			_spend(w)
			for i in 2:
				w.call(&"reload_press")
				await _until_free(w)
			w.call(&"reload_press")
			await _frames(8)


func _spend(w: WeaponViewmodel) -> void:
	if w is RevolverViewmodel:
		(w as RevolverViewmodel).state.chambers.fill(RevolverState.Chamber.SPENT)
	else:
		(w as ShotgunViewmodel).state.barrels.assign([ShotgunState.Barrel.SPENT, ShotgunState.Barrel.SPENT])


func _until_free(w: WeaponViewmodel) -> void:
	var st: Object = w.get(&"state")
	var t := 0
	while not st.call(&"ready") and t < 120:
		await get_tree().process_frame
		t += 1


## Where the grip and every bone are, in the gun model's space (cm), for placing a hand.
func _print_hand(w: WeaponViewmodel) -> void:
	var gun: Node3D = w.get(&"model")
	var inv := gun.global_transform.affine_inverse()
	for n in ["Grip/Panels", "Stock/Wrist", "Barrels/Forend"]:
		var mi := gun.get_node_or_null(n) as MeshInstance3D
		if mi:
			var b := mi.get_aabb()
			var lo := Vector3.INF
			var hi := -Vector3.INF
			for i in 8:
				var p := inv * (mi.global_transform * b.get_endpoint(i))
				lo = lo.min(p)
				hi = hi.max(p)
			print("GRIP %s cm: %s .. %s" % [n, (lo * 100).snappedf(0.1), (hi * 100).snappedf(0.1)])
			var half := (mi.mesh as BoxMesh).size * 0.5 if mi.mesh is BoxMesh else Vector3.ZERO
			for c in [Vector3(0, half.y, -half.z), Vector3(0, half.y, half.z), Vector3(0, -half.y, -half.z), Vector3(0, -half.y, half.z)]:
				print("  corner (top/bottom, front/back) %s" % (inv * (mi.global_transform * c) * 100).snappedf(0.1))
	# Any hand with finger pivots (HandModel's, HeldHand's): by what it has, not its class.
	for h in w.find_children("*", "", true, false):
		if not (h is Node3D and h.get(&"fingers") is Dictionary and h.get(&"wrist") is Node3D):
			continue
		var hand := h as Node3D
		var fingers: Dictionary = hand.get(&"fingers")
		for f: String in fingers:
			var line := ""
			for b: Node3D in fingers[f]:
				line += str((inv * b.global_position * 100).snappedf(0.1)) + " "
			print("HAND %s %s: %s" % [hand.name, f, line])
		print("HAND %s wrist %s" % [hand.name, (inv * (hand.get(&"wrist") as Node3D).global_position * 100).snappedf(0.1)])
		var sk := hand.get_node_or_null("Skeleton") as Skeleton3D
		if sk:
			for bn in ["forearm_r", "forearm_l", "upper_arm_r", "upper_arm_l"]:
				var i := sk.find_bone(bn)
				if i >= 0:
					print("HAND %s %s at %s" % [hand.name, bn, (inv * (sk.global_transform * sk.get_bone_pose(i).origin) * 100).snappedf(0.1)])
		if hand.has_method(&"surface_points"):
			_print_gaps(gun, hand)


## Each finger bone's skin against what it holds: the nearest of its points to the grip's (or the
## stock's wrist, or the forend's) surface, mm; negative = into the wood. A finger closed round a
## grip reads 0 to 3 on every bone it wraps with; the index's tip against the trigger.
func _print_gaps(gun: Node3D, hand: Node3D) -> void:
	var boxes: Array[MeshInstance3D] = []
	for n in ["Grip/Panels", "Grip/Backstrap", "Stock/PistolGrip/Grip", "Stock/Wrist", "Barrels/Forend", "Trigger/Blade", "Trigger0/Blade", "Hammer/Spur", "Hammer0/Spur"]:
		var mi := gun.get_node_or_null(n) as MeshInstance3D
		if mi and mi.mesh is BoxMesh:
			boxes.append(mi)
	var side := "r" if bool(hand.get(&"right")) else "l"
	var fingers: Dictionary = hand.get(&"fingers")
	for f: String in fingers:
		var line := ""
		for k in 3:
			var pts: PackedVector3Array = hand.call(&"surface_points", "finger_%s_%s_%d" % [f, side, k])
			var best := INF
			var what := ""
			for mi in boxes:
				var half := (mi.mesh as BoxMesh).size * 0.5
				var to_box := mi.global_transform.affine_inverse()
				for p in pts:
					var q := (to_box * p).abs() - half
					var d := q.max(Vector3.ZERO).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0)
					if d < best:
						best = d
						what = mi.name
			line += "%s %+.0f  " % [what, best * 1000.0]
		print("GAP %s %s mm: %s" % [hand.name, f, line])


## --fit: close the hand's fingers round what they hold, bone by bone from the knuckle, each joint
## turned until the finger past it first comes within FIT_MM of the wood (a grasp closing until it
## touches), and print the angles to bake into the hand's model. The index closes on the trigger.
const FIT_MM := 1.5
## A joint closes until the skin past this share of its own bone touches (its knuckle's own skin
## already rests on the wood's edge).
const FIT_FROM := 0.4


func _fit(w: WeaponViewmodel) -> void:
	var gun: Node3D = w.get(&"model")
	for h in w.find_children("*", "", true, false):
		if not h.has_method(&"surface_points"):
			continue
		var hand := h as Node3D
		var grip: Array[MeshInstance3D] = []
		for n in ["Grip/Panels", "Grip/Backstrap", "Grip/Butt", "Stock/PistolGrip/Grip", "Stock/PistolGrip/Cap", "Stock/Wrist", "Barrels/Forend", "Barrels/Barrel0", "Barrels/Barrel1"]:
			var mi := gun.get_node_or_null(n) as MeshInstance3D
			if mi:
				grip.append(mi)
		var trig: Array[MeshInstance3D] = []
		for n in ["Trigger/Blade", "Trigger0/Blade"]:
			var mi := gun.get_node_or_null(n) as MeshInstance3D
			if mi:
				trig.append(mi)
		var fingers: Dictionary = hand.get(&"fingers")
		for f: String in ["middle", "ring", "little", "index"]:
			if not fingers.has(f):
				continue
			if f == "index" and bool(hand.get(&"right")) and gun.get_node_or_null("Trigger0/Blade"):
				_fit_reach(hand, gun)
				continue
			# Each finger closes as one (HeldHand.grasp: its joints coupled) until it touches the
			# wood; the right index on its trigger.
			var on := trig if f == "index" and not trig.is_empty() and bool(hand.get(&"right")) else grip
			var lo := 0.0
			var hi := 140.0
			for it in 14:
				var mid := (lo + hi) * 0.5
				hand.call(&"grasp", f, mid)
				if _min_gap(hand, f, 0, on) <= FIT_MM * 0.001:
					hi = mid
				else:
					lo = mid
			hand.call(&"grasp", f, hi)
			print("FIT %s %s: grasp %.0f (gap %+.1f mm)" % [hand.name, f, hi, _min_gap(hand, f, 0, on) * 1000.0])
		if fingers.has("thumb") and bool(hand.get(&"right")):
			var revolver := gun.get_node_or_null("Hammer/Spur") != null
			var solid: Array[MeshInstance3D] = []
			for n in ["Frame", "RecoilShield", "Grip/Panels", "Grip/Backstrap", "Hammer/Body", "Hammer/Spur",
					"Stock/Wrist", "Stock/PistolGrip/Grip", "Tang", "Breech", "LockplateR", "LockplateL", "Hammer0/Body", "Hammer0/Spur", "Hammer1/Body", "Hammer1/Spur"]:
				var mi := gun.get_node_or_null(n) as MeshInstance3D
				if mi and mi.mesh is BoxMesh:
					solid.append(mi)
			_fit_thumb(hand, gun, solid, "rest", THUMB_REST_TIP if revolver else SHOTGUN_THUMB_REST_TIP)
			_fit_thumb(hand, gun, solid, "cock", THUMB_COCK_TIP if revolver else SHOTGUN_THUMB_COCK_TIP)
		elif fingers.has("thumb") and gun.get_node_or_null("Barrels/Forend"):
			var forend: Array[MeshInstance3D] = [gun.get_node("Barrels/Forend") as MeshInstance3D]
			_fit_thumb(hand, gun, forend, "rest", SHOTGUN_LEFT_THUMB_TIP)


func _min_gap(hand: Node3D, f: String, from_bone: int, boxes: Array[MeshInstance3D]) -> float:
	var side := "r" if bool(hand.get(&"right")) else "l"
	var best := INF
	for k in range(from_bone, 3):
		var pts: PackedVector3Array = hand.call(&"surface_points", "finger_%s_%s_%d" % [f, side, k], FIT_FROM if k == from_bone else 0.0)
		for mi in boxes:
			var to_box := mi.global_transform.affine_inverse()
			for i in range(0, pts.size(), 4):
				best = minf(best, _solid_distance(mi, to_box * pts[i]))
	return best


## A point's signed distance to a box's or a tube's surface (in the part's own space; a tube's
## axis is its mesh's Y), negative inside.
func _solid_distance(mi: MeshInstance3D, p: Vector3) -> float:
	if mi.mesh is CylinderMesh:
		var c := mi.mesh as CylinderMesh
		var d := Vector2(Vector2(p.x, p.z).length() - c.top_radius, absf(p.y) - c.height * 0.5)
		return d.max(Vector2.ZERO).length() + minf(maxf(d.x, d.y), 0.0)
	var q := p.abs() - (mi.mesh as BoxMesh).size * 0.5
	return q.max(Vector3.ZERO).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0)


## Where the thumb's tip goes on the revolver (its model's space, m): resting high on the left of
## the frame behind the cylinder, and on top of the hammer's spur to cock it.
const THUMB_REST_TIP := Vector3(-0.026, 0.02, 0.004)
const THUMB_COCK_TIP := Vector3(0.0, 0.068, 0.018)
## The coach gun's: over the top of the stock's wrist by the tang, and on the right hammer's spur.
const SHOTGUN_THUMB_REST_TIP := Vector3(-0.026, -0.012, 0.005)
const SHOTGUN_THUMB_COCK_TIP := Vector3(0.018, 0.038, 0.002)
## The left thumb up the left of the forend (the gun closed: the barrels at rest).
const SHOTGUN_LEFT_THUMB_TIP := Vector3(-0.03, -0.014, -0.19)


## The thumb's root turn and bends that bring its tip nearest `target` without its skin going into
## the gun: a search over the root's euler angles and the two bends, the nearest few checked for
## the skin.
func _fit_thumb(hand: Node3D, gun: Node3D, solid: Array[MeshInstance3D], what: String, target: Vector3, finger := "thumb") -> void:
	var want := gun.global_transform * target
	var tried := []
	for rx in range(-60, 61, 12):
		for ry in range(-60, 61, 12):
			for rz in range(-60, 61, 12):
				for b in [[0, 0], [15, 10], [30, 25], [45, 40]]:
					hand.call(&"pose_finger", finger, Vector3(rx, ry, rz), b[0], b[1])
					var bones: Array = (hand.get(&"fingers") as Dictionary)[finger]
					var tip := (bones[2] as Node3D).global_transform * (hand.call(&"tip_dir", bones[2]) as Vector3 * float(hand.get(&"lengths")[finger][2]))
					tried.append([tip.distance_to(want), Vector3(rx, ry, rz), b[0], b[1]])
	tried.sort_custom(func(a: Array, c: Array) -> bool: return a[0] < c[0])
	var side := "r" if bool(hand.get(&"right")) else "l"
	for t: Array in tried.slice(0, 250):
		hand.call(&"pose_finger", finger, t[1], t[2], t[3])
		var gap := INF
		for k in 3:
			var pts: PackedVector3Array = hand.call(&"surface_points", "finger_%s_%s_%d" % [finger, side, k])
			for mi in solid:
				var half := (mi.mesh as BoxMesh).size * 0.5
				var to_box := mi.global_transform.affine_inverse()
				for i in range(0, pts.size(), 3):
					var q := (to_box * pts[i]).abs() - half
					gap = minf(gap, q.max(Vector3.ZERO).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0))
		if gap >= -0.003:
			print("FIT %s %s %s: %s, %d, %d (tip %.0f mm off, skin %+.0f mm)" % [hand.name, finger, what, t[1], t[2], t[3], t[0] * 1000.0, gap * 1000.0])
			return
	print("FIT %s %s %s: nothing clear of the gun in the nearest 250" % [hand.name, finger, what])


## The coach gun's index: its knuckle spread forward (HeldHand.grasp's `spread`) and the finger
## closed together until its pad is nearest the front trigger's blade without going into the guard
## or the stock; at rest, the same spread a little less closed.
func _fit_reach(hand: Node3D, gun: Node3D) -> void:
	var blade := gun.get_node("Trigger0/Blade") as MeshInstance3D
	var solid: Array[MeshInstance3D] = []
	for n in ["GuardBottom", "GuardBack", "GuardFront", "Stock/Wrist", "Stock/PistolGrip/Grip", "Trigger1/Blade"]:
		solid.append(gun.get_node(n) as MeshInstance3D)
	var side := "r" if bool(hand.get(&"right")) else "l"
	var best := [INF, 0.0, 0.0]
	for spread in range(-30, 31, 5):
		for amount in range(0, 121, 5):
			hand.call(&"grasp", "index", float(amount), float(spread))
			var tip: PackedVector3Array = hand.call(&"surface_points", "finger_index_%s_2" % side, 0.5)
			var near := INF
			for p in tip:
				near = minf(near, _solid_distance(blade, blade.global_transform.affine_inverse() * p))
			if near >= best[0]:
				continue
			if _min_gap(hand, "index", 0, solid) < -0.0015:
				continue
			best = [near, float(spread), float(amount)]
	hand.call(&"grasp", "index", best[2], best[1])
	print("FIT %s index: spread %.0f, grasp %.0f (pad %.0f mm off the trigger)" % [hand.name, best[1], best[2], best[0] * 1000.0])
