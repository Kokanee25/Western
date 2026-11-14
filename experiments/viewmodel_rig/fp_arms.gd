extends Node3D
## Harlan's first-person arms, option 2 of #890's fallback (#896): the MetaHuman's hands cut at the
## wrist with modelled sleeves (tools/blender/fp_arms.py -> private/harlan_fp.glb), on a rig of their
## own posed per gun from data (poses/<gun>.json), not driven by the full body's skeleton. A lab's:
## nothing in the game uses it. Untyped where it touches game classes (a -s script loads it).
##
## Hand space is HeldHand's, so a pose reads the same on either (and the gun lab's placements carry
## over): the index knuckle at the origin, the fingers along -Z, the knuckles running down -Y from the
## index to the little finger, +X the back of a right hand (a left hand is the mirror: +X its palm).
## A hand is placed by `place(side, at, along, palm)`: its index knuckle `at`, its wrist back along
## `along` from the knuckles, its palm towards `palm` (all in global space), and its forearm aimed
## back along `forearm` from the wrist (the wrist bends; the sleeve rides the forearm).
##
## Fingers: `curl(side, finger, [a, b, c])` degrees each joint, positive towards the palm (about the
## axis across each bone, from his own bones' rest lines); `spread(side, finger, deg)` the knuckle
## turned towards the thumb; `thumb(side, [x, y, z], [b1, b2])` the thumb's root turned in hand space
## (degrees about X, Y, Z: X lifts it off the palm, Y swings it across, Z rolls it) then its joints bent.

const GLB := "res://experiments/viewmodel_rig/private/harlan_fp.glb"
const FINGERS := ["thumb", "index", "middle", "ring", "little"]
## A finger's grip as one number (HeldHand.GRASP's coupling: the joints bend together, the middle most).
const GRASP := [0.75, 1.0, 0.55]

var skel: Skeleton3D
var meshes := []
var ok := false
## side -> {"hand0": Transform3D (hand space in skeleton space at rest), "rest": {bone: Transform3D},
##          "axis": {bone: Vector3 (curl axis, hand space)}, "dir": {bone: Vector3}, "len": {bone: float}}
var _side := {}
## side -> what's asked: "frame" (Transform3D hand space -> global), "forearm" (Vector3 global),
## "curl" {finger: [a,b,c]}, "spread" {finger: deg}, "thumb_root" Vector3 degrees.
var _ask := {}


func _ready() -> void:
	if not ResourceLoader.exists(GLB):
		push_warning("fp_arms: %s missing (tools/blender/fp_arms.py makes it from the Studio's MetaHuman)" % GLB)
		return
	var scene: Node = (load(GLB) as PackedScene).instantiate()
	add_child(scene)
	skel = scene.find_children("*", "Skeleton3D", true, false)[0]
	for m in scene.find_children("*", "MeshInstance3D", true, false):
		meshes.append(m)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.custom_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
		if String(m.name).begins_with("fp_hands"):
			_skin_look(m)
	for s in ["r", "l"]:
		_side[s] = _rests(s)
		_ask[s] = {"frame": null, "forearm": Vector3.ZERO, "curl": {}, "spread": {}, "thumb_root": Vector3.ZERO}
	ok = true


## His skin's own maps (the MetaHuman's albedo, normal, roughness) with a little light through it, as
## skin takes light; the game's real look draws the rest.
func _skin_look(m: MeshInstance3D) -> void:
	for i in m.mesh.get_surface_count():
		var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
		if mat == null:
			continue
		mat = mat.duplicate()
		mat.subsurf_scatter_enabled = true
		mat.subsurf_scatter_strength = 0.35
		mat.subsurf_scatter_skin_mode = true
		m.set_surface_override_material(i, mat)


func _rests(s: String) -> Dictionary:
	var rest := {}
	for i in skel.get_bone_count():
		var n := String(skel.get_bone_name(i))
		if n.ends_with("_" + s) or n.contains("_%s_" % s):
			rest[n] = skel.get_bone_global_rest(i)
	var ki: Vector3 = rest["finger_index_%s_0" % s].origin
	var km: Vector3 = rest["finger_middle_%s_0" % s].origin
	var kl: Vector3 = rest["finger_little_%s_0" % s].origin
	var w: Vector3 = rest["hand_" + s].origin
	var z := (w - km).normalized()
	var y := ki - kl
	y = (y - z * y.dot(z)).normalized()
	var x := y.cross(z)
	var hand0 := Transform3D(Basis(x, y, z), ki)
	var inv := hand0.affine_inverse()
	var palm := Vector3(-1, 0, 0) if s == "r" else Vector3(1, 0, 0)
	var axis := {}
	var dir := {}
	var lens := {}
	for f in FINGERS:
		for k in 3:
			var bn := "finger_%s_%s_%d" % [f, s, k]
			var a: Vector3 = inv * (rest[bn] as Transform3D).origin
			var nx := "finger_%s_%s_%d" % [f, s, k + 1]
			var b: Vector3
			if rest.has(nx):
				b = inv * (rest[nx] as Transform3D).origin
			else:
				b = a + (dir["finger_%s_%s_%d" % [f, s, k - 1]] as Vector3) * float(lens["finger_%s_%s_%d" % [f, s, k - 1]]) * 0.85
			var d := (b - a).normalized()
			dir[bn] = d
			lens[bn] = (b - a).length()
			# The thumb closes across the palm towards the little finger; the fingers straight in.
			var p := palm if f != "thumb" else (palm * 0.6 + Vector3(0, -0.8, 0)).normalized()
			axis[bn] = d.cross(p).normalized()
	var fa: Transform3D = rest["forearm_" + s]
	return {"hand0": hand0, "rest": rest, "axis": axis, "dir": dir, "len": lens,
			"wrist": inv * w, "forearm_dir": (inv * fa.origin - inv * w).normalized()}


## The hand placed (global): its index knuckle at `at`, its wrist back along `along` from the
## knuckles, its palm towards `palm`; the forearm back along `forearm` (global; zero keeps it in line).
func place(s: String, at: Vector3, along: Vector3, palm: Vector3, forearm := Vector3.ZERO) -> void:
	var z := along.normalized()
	var x := (palm - z * palm.dot(z)).normalized() * (-1.0 if s == "r" else 1.0)
	_ask[s]["frame"] = Transform3D(Basis(x, z.cross(x), z), at)
	_ask[s]["forearm"] = forearm
	_ask[s]["elbow"] = null
	_ask[s]["hidden"] = false


## The forearm aimed from the wrist back at `elbow` (global): where the arm's elbow would be.
func aim_elbow(s: String, elbow: Vector3) -> void:
	_ask[s]["elbow"] = elbow


## Back to open hands, nothing placed (a new pose starts from here).
func reset(s: String) -> void:
	_ask[s] = {"frame": null, "forearm": Vector3.ZERO, "elbow": null, "curl": {}, "spread": {}, "thumb_root": Vector3.ZERO, "hidden": true}


## The hand's frame (hand space -> global) as placed, or null.
func frame(s: String):
	return _ask[s]["frame"]


func curl(s: String, f: String, angles: Array) -> void:
	_ask[s]["curl"][f] = angles


func grasp(s: String, f: String, amount: float) -> void:
	curl(s, f, [amount * GRASP[0], amount * GRASP[1], amount * GRASP[2]])


func spread(s: String, f: String, deg: float) -> void:
	_ask[s]["spread"][f] = deg


func thumb(s: String, root_deg: Vector3, bends: Array) -> void:
	_ask[s]["thumb_root"] = root_deg
	_ask[s]["curl"]["thumb"] = [0.0, bends[0], bends[1]]


## A pose from data: {"fingers": {"index": [a,b,c] | number (grasp)}, "spread": {f: deg},
## "thumb": {"root": [x,y,z], "bend": [b1,b2]}}.
func fingers_from(s: String, d: Dictionary) -> void:
	for f in d.get("fingers", {}):
		var v = d["fingers"][f]
		if v is Array:
			curl(s, f, v)
		else:
			grasp(s, f, float(v))
	for f in d.get("spread", {}):
		spread(s, f, float(d["spread"][f]))
	if d.has("thumb"):
		var t: Dictionary = d["thumb"]
		var r: Array = t.get("root", [0, 0, 0])
		thumb(s, Vector3(r[0], r[1], r[2]), t.get("bend", [0, 0]))


## Hides a side (a one-handed hold: the other arm is off screen).
func show_side(s: String, on: bool) -> void:
	_ask[s]["hidden"] = not on


## Poses the skeleton from what's asked (call after placing, before the frame is drawn).
func apply() -> void:
	if not ok:
		return
	# The node goes where the hands are: the meshes' bounds (custom_aabb, +-2 m) are about it, so
	# left at the world's origin the hands are culled anywhere but there (the town: 15 m off).
	for s in _side:
		if _ask[s]["frame"] != null and not _ask[s].get("hidden", false):
			global_position = (_ask[s]["frame"] as Transform3D).origin
			break
	var to_skel := skel.global_transform.affine_inverse()
	for s in _side:
		var a: Dictionary = _ask[s]
		var r: Dictionary = _side[s]
		var hidden: bool = a.get("hidden", false) or a["frame"] == null
		var frame_g: Transform3D = a["frame"] if a["frame"] != null else Transform3D(Basis.IDENTITY, Vector3(0, -100, 0))
		# Hand space -> skeleton space, now.
		var m: Transform3D = to_skel * frame_g
		var move: Transform3D = m * (r.hand0 as Transform3D).affine_inverse()   # skeleton rest -> now
		if hidden:
			move = Transform3D(Basis.IDENTITY.scaled(Vector3(0.001, 0.001, 0.001)), Vector3(0, -50, 0)) * move
		var rest: Dictionary = r.rest
		var hand_g: Transform3D = move * (rest["hand_" + s] as Transform3D)
		# The forearm (the root: set first, the hand's pose is taken from it): turned about the wrist so it lies back along what's asked.
		var w: Vector3 = move * (rest["hand_" + s] as Transform3D).origin
		var fa: Transform3D = move * (rest["forearm_" + s] as Transform3D)
		var want_s: Vector3 = (to_skel.basis * (a["forearm"] as Vector3))
		if a.get("elbow") != null:
			want_s = to_skel * (a["elbow"] as Vector3) - w
		if want_s.length() > 1e-4 and not hidden:
			want_s = want_s.normalized()
			var now_dir := (fa.origin - w).normalized()
			var q := Quaternion(now_dir, want_s)
			fa = Transform3D(Basis(q), w) * Transform3D(Basis.IDENTITY, -w) * fa
		_set_global("forearm_" + s, fa)
		_set_global("hand_" + s, hand_g)
		# The fingers, root to tip, each joint turned about its own across-axis.
		for f in FINGERS:
			var angles: Array = a["curl"].get(f, [0.0, 0.0, 0.0])
			var parent_now := hand_g
			var parent_rest: Transform3D = rest["hand_" + s]
			for k in 3:
				var bn := "finger_%s_%s_%d" % [f, s, k]
				var brest: Transform3D = rest[bn]
				var local := parent_rest.affine_inverse() * brest
				var g := parent_now * local
				# Axes in skeleton space as the bone is now: rotate about them at the joint.
				var turn := Basis.IDENTITY
				if k == 0:
					var sp: float = a["spread"].get(f, 0.0)
					if sp != 0.0:
						var d0: Vector3 = r.dir[bn]
						# about d x Y (hand space): positive swings the finger towards the index side
						var sa: Vector3 = (g.basis * (brest.basis.inverse() * (r.hand0.basis * d0.cross(Vector3.UP)))).normalized()
						turn = Basis(sa, deg_to_rad(sp)) * turn
					if f == "thumb":
						var tr: Vector3 = a["thumb_root"]
						var hx: Vector3 = g.basis * (brest.basis.inverse() * (r.hand0.basis * Vector3.RIGHT))
						var hy: Vector3 = g.basis * (brest.basis.inverse() * (r.hand0.basis * Vector3.UP))
						var hz: Vector3 = g.basis * (brest.basis.inverse() * (r.hand0.basis * Vector3.BACK))
						var sx := 1.0 if s == "r" else -1.0
						turn = Basis(hz.normalized(), deg_to_rad(tr.z) * sx) * Basis(hy.normalized(), deg_to_rad(tr.y) * sx) * Basis(hx.normalized(), deg_to_rad(tr.x)) * turn
				var ang := float(angles[k]) if k < angles.size() else 0.0
				if ang != 0.0:
					var ax: Vector3 = r.axis[bn]
					var ax_now: Vector3 = (turn * (g.basis * (brest.basis.inverse() * (r.hand0.basis * ax)))).normalized()
					turn = Basis(ax_now, deg_to_rad(ang)) * turn
				g = Transform3D(turn * g.basis, g.origin)
				_set_global(bn, g)
				parent_now = g
				parent_rest = brest


## Each bone's global pose (skeleton space) as set this apply: a child's local pose is taken from its
## parent's here, not from the skeleton's cache (it updates later).
var _now := {}


func _set_global(bn: String, g: Transform3D) -> void:
	var i := skel.find_bone(bn)
	if i < 0:
		return
	_now[bn] = g
	var p := skel.get_bone_parent(i)
	var local := g
	if p >= 0:
		var pn := String(skel.get_bone_name(p))
		var pg: Transform3D = _now[pn] if _now.has(pn) else skel.get_bone_global_pose(p)
		local = pg.affine_inverse() * g
	skel.set_bone_pose(i, local)


## A bone's place now (global), for measuring a finger against the gun.
func bone_global(bn: String) -> Transform3D:
	var i := skel.find_bone(bn)
	return skel.global_transform * skel.get_bone_global_pose(i)


## A finger's tip now (global): its last joint plus its length along its line.
func tip(s: String, f: String) -> Vector3:
	var bn := "finger_%s_%s_2" % [f, s]
	var r: Dictionary = _side[s]
	var g := bone_global(bn)
	var brest: Transform3D = r.rest[bn]
	var d: Vector3 = r.hand0.basis * (r.dir[bn] as Vector3)
	return g * (brest.basis.inverse() * d * float(r.len[bn]))
