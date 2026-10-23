class_name HeldHand
extends Node3D
## A hand holding something, for the guns in your hands (and later a man's): a Character Studio
## man's own skinned, painted forearm and hand (tools/faces/hands.py: MakeHuman's hand on his arm,
## painted into his skin's texture, 15 finger bones), cut out of his model with his shirt sleeve,
## so the hand you hold the gun with is drawn in the same painted hand as the men you shoot at
## (Sean, 2026-10-22, #249: "it needs to match the art style of the new characters"). Every finger
## bone is a pivot, so a finger can curl round a grip, squeeze a trigger, or later be shot away.
##
## Hand space (a right hand; a left hand is its mirror in X): the palm faces -X (towards what it
## holds) and the back of the hand +X; the fingers point -Z from their knuckles, which run down
## -Y from the index (at the origin) to the little finger; the thumb is on the +Y side; the wrist is
## at `wrist` and the forearm runs back (+Z) from it, turned by `wrist.rotation`. A finger's curl
## turns each bone towards the palm (degrees, positive = closing), about the man's own joint.

## Whose arms you have: the Studio man whose shirt and vest your body wears (PlayerBody): Sean's,
## the palest and least orange of the eight with hands (every one's forearm is bare to the elbow).
const MODEL := &"sean_s3_talking"
const FINGERS := ["index", "middle", "ring", "little"]
## A finger's last bone has no joint past it: its length is this share of the bone before.
const TIP_SHARE := 0.85

var right := true
## name -> Array[Node3D]: a pivot a bone, root first ("index", ..., "thumb").
var fingers := {}
## name -> Array[float]: each bone's length (m), root first.
var lengths := {}
## The forearm's pivot at the wrist: turn it to aim the forearm back towards the shoulder (its +Z).
var wrist: Node3D
## The skinned arm (null where the man's model can't be loaded: the pivots still pose).
var mesh: MeshInstance3D
## Where this arm's shoulder is, in the space of the camera the hand hangs under (the player's):
## when set, the arm is two bones from the shoulder to the wrist with the elbow between, solved
## each frame (the elbow towards `elbow_pole`, a direction in the same space), not a straight rod
## from the wrist. Unset (or with no camera above it) the forearm follows `wrist`'s aim.
var shoulder := Vector3.ZERO
var elbow_pole := Vector3(0.0, -1.0, 0.0)

var _skeleton: Skeleton3D
var _src: Dictionary
## Skeleton bone -> the pivot whose transform it takes (a finger bone), in hand space.
var _bone_pivot := {}
var _tip_dir := {}   # pivot -> the bone's direction in its own space (to its next joint)

## side ("r"/"l") -> what's cut from the man's model, in hand space (built once).
static var _sources := {}


func _init(is_right := true) -> void:
	right = is_right


func _ready() -> void:
	build()


func _process(_delta: float) -> void:
	_pose()


## Builds it once (it's built when it enters the tree, or by calling this first to pose it sooner).
func build() -> void:
	if not fingers.is_empty():
		return
	_src = source("r" if right else "l")
	var rests: Dictionary = _src.get("rests", {})
	var side := "r" if right else "l"
	for f: String in FINGERS + ["thumb"]:
		var chain: Array[Node3D] = []
		var lens: Array = []
		var parent: Node3D = self
		var parent_rest := Transform3D.IDENTITY
		for k in 3:
			var bn := "finger_%s_%s_%d" % [f, side, k]
			var rest: Transform3D = rests.get(bn, Transform3D.IDENTITY)
			# The joint's frame (the man's rest, relative to the bone before) and its pivot inside it.
			var frame := Node3D.new()
			frame.name = "%s%dRest" % [f.capitalize(), k]
			frame.transform = parent_rest.affine_inverse() * rest
			parent.add_child(frame)
			var pivot := Node3D.new()
			pivot.name = "%s%d" % [f.capitalize(), k]
			frame.add_child(pivot)
			chain.append(pivot)
			_bone_pivot[bn] = pivot
			var next: Transform3D = rests.get("finger_%s_%s_%d" % [f, side, k + 1], Transform3D.IDENTITY)
			if k < 2 and rests.has("finger_%s_%s_%d" % [f, side, k + 1]):
				var d := rest.affine_inverse() * next.origin
				lens.append(d.length())
				_tip_dir[pivot] = d.normalized()
			else:
				lens.append(float(lens[-1]) * TIP_SHARE if not lens.is_empty() else 0.02)
				_tip_dir[pivot] = _tip_dir.get(chain[k - 1], Vector3.DOWN) if k > 0 else Vector3.DOWN
			parent = pivot
			parent_rest = rest
		fingers[f] = chain
		lengths[f] = lens
	wrist = Node3D.new()
	wrist.name = "Wrist"
	wrist.position = (rests.get("hand_" + side, Transform3D.IDENTITY) as Transform3D).origin
	add_child(wrist)
	if _src.has("mesh"):
		_skeleton = Skeleton3D.new()
		_skeleton.name = "Skeleton"
		add_child(_skeleton)
		var names: Array = _src.names
		for i in names.size():
			_skeleton.add_bone(names[i])
			_skeleton.set_bone_rest(i, rests[names[i]])
			_skeleton.set_bone_pose(i, rests[names[i]])
		mesh = MeshInstance3D.new()
		mesh.name = "Arm"
		mesh.mesh = _src.mesh
		mesh.skin = _src.skin
		mesh.material_override = _src.material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.custom_aabb = AABB(Vector3(-0.6, -0.6, -0.6), Vector3(1.2, 1.2, 1.2))
		_skeleton.add_child(mesh)
		mesh.skeleton = NodePath("..")
	_pose()


## Aims the forearm back along `dir` (a direction in this hand's parent's space) from the wrist.
func aim_forearm(dir: Vector3) -> void:
	var local := (basis.inverse() * dir).normalized()
	var up := Vector3.UP if absf(local.y) < 0.95 else Vector3.RIGHT
	wrist.basis = Basis.looking_at(-local, up)


## A finger closing as fingers do: its three joints bend together, the middle joint most and the
## last about half as much (the tendons couple them; a hand round a 3-4 cm grip has its knuckle at
## ~55, middle ~75, last ~40 degrees). `amount` is the middle joint's bend.
const GRASP := [0.75, 1.0, 0.55]


func grasp(finger: String, amount: float, spread := 0.0) -> void:
	curl(finger, [amount * GRASP[0], amount * GRASP[1], amount * GRASP[2]])
	# `spread`: the knuckle turned sideways (degrees, towards the thumb positive), as a trigger
	# finger reaches forward.
	var bones: Array = fingers.get(finger, [])
	if not bones.is_empty() and spread != 0.0:
		(bones[0] as Node3D).rotation.x = deg_to_rad(spread)


## Curl a finger: degrees a bone, root first, positive towards the palm.
func curl(finger: String, angles: Array) -> void:
	var bones: Array = fingers.get(finger, [])
	var sx := -1.0 if right else 1.0
	for i in mini(bones.size(), angles.size()):
		(bones[i] as Node3D).rotation = Vector3(0.0, 0.0, deg_to_rad(float(angles[i])) * sx)


## Curl a finger so it wraps a round grip `radius` m from the bone's middle line: each bone turns by
## the arc its length covers round it (`extra` degrees added to the root, for where it starts).
func wrap(finger: String, radius: float, extra := 0.0) -> void:
	var lens: Array = lengths.get(finger, [])
	var angles: Array = []
	for i in lens.size():
		angles.append(rad_to_deg(float(lens[i]) / maxf(radius, 0.005)) * (0.5 if i == 0 else 1.0) + (extra if i == 0 else 0.0))
	curl(finger, angles)


## The thumb: its root turned (euler degrees about its own joint, mirrored for a left hand) and its
## two joints bent towards the palm.
func thumb_pose(root_deg: Vector3, bend1: float, bend2: float) -> void:
	pose_finger("thumb", root_deg, bend1, bend2)


## Any finger posed as the thumb is: its knuckle turned every way (to reach a trigger that a
## plain curl can't), its two joints bent towards the palm.
func pose_finger(finger: String, root_deg: Vector3, bend1: float, bend2: float) -> void:
	var t: Array = fingers.get(finger, [])
	if t.size() < 3:
		return
	var sx := -1.0 if right else 1.0
	(t[0] as Node3D).rotation_degrees = root_deg if right else Vector3(root_deg.x, -root_deg.y, -root_deg.z)
	(t[1] as Node3D).rotation = Vector3(0.0, 0.0, deg_to_rad(bend1) * sx)
	(t[2] as Node3D).rotation = Vector3(0.0, 0.0, deg_to_rad(bend2) * sx)


## A bone's direction in its own space, from its joint towards the next (its pivot's).
func tip_dir(pivot: Node3D) -> Vector3:
	return _tip_dir.get(pivot, Vector3.DOWN)


## Every bone's end point (fingertips and knuckles) in this hand's parent's space: for measuring
## how close the fingers come to what they hold.
func bone_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for f: String in fingers:
		var bones: Array = fingers[f]
		for i in bones.size():
			var b := bones[i] as Node3D
			out.append(b.global_position)
			out.append(b.global_transform * ((_tip_dir[b] as Vector3) * float(lengths[f][i])))
	return out


## The skin a bone carries, posed as it is now, in global space (each point by its strongest bone);
## of a finger bone only what lies past `from_share` of its length from its joint.
func surface_points(bone: String, from_share := 0.0) -> PackedVector3Array:
	_pose()
	var out := PackedVector3Array()
	var pts: PackedVector3Array = (_src.get("points", {}) as Dictionary).get(bone, PackedVector3Array())
	var i := _skeleton.find_bone(bone) if _skeleton else -1
	if i < 0:
		return out
	var rest := _skeleton.get_bone_rest(i)
	var xf := global_transform * _skeleton.get_bone_pose(i) * rest.affine_inverse()
	var pivot: Node3D = _bone_pivot.get(bone)
	var dir: Vector3 = _tip_dir.get(pivot, Vector3.ZERO)
	var from := 0.0
	if pivot and from_share > 0.0:
		var bits := bone.split("_")
		from = float(lengths[bits[1]][int(bits[3])]) * from_share
	var inv := rest.affine_inverse()
	for p in pts:
		if from <= 0.0 or (inv * p).dot(dir) >= from:
			out.append(xf * p)
	return out


## The skeleton takes the pivots: each finger bone where its pivot is, the forearm and upper arm
## turned about the wrist from the man's rest to where `wrist` aims them.
func _pose() -> void:
	if _skeleton == null or not is_inside_tree():
		return
	var inv := global_transform.affine_inverse()
	for bn: String in _bone_pivot:
		var i := _skeleton.find_bone(bn)
		if i >= 0:
			_skeleton.set_bone_pose(i, inv * (_bone_pivot[bn] as Node3D).global_transform)
	var side := "r" if right else "l"
	var rests: Dictionary = _src.rests
	var w: Vector3 = wrist.position
	if shoulder != Vector3.ZERO and _arm_to_shoulder(inv, side, rests, w):
		return
	var turn := Basis(Quaternion(_src.forearm_dir as Vector3, wrist.basis.z.normalized()))
	var about := Transform3D(Basis.IDENTITY, w) * Transform3D(turn, Vector3.ZERO) * Transform3D(Basis.IDENTITY, -w)
	for bn: String in ["upper_arm_" + side, "forearm_" + side]:
		var i := _skeleton.find_bone(bn)
		if i >= 0:
			_skeleton.set_bone_pose(i, about * (rests[bn] as Transform3D))


## The arm as two bones from the shoulder (in the camera above's space) to the wrist: the elbow
## where the forearm's and upper arm's lengths meet, bent towards `elbow_pole`; each bone swung from
## its rest to its new line (the twist left as the man's own). Out of reach, the arm points
## straight at the shoulder. False where there's no camera above.
func _arm_to_shoulder(inv: Transform3D, side: String, rests: Dictionary, w: Vector3) -> bool:
	var cam: Node = get_parent()
	while cam != null and not cam is Camera3D:
		cam = cam.get_parent()
	if cam == null:
		return false
	var cxf := (cam as Camera3D).global_transform
	var s := inv * (cxf * shoulder)
	var pole := (inv.basis * (cxf.basis * elbow_pole)).normalized()
	var r_up: Transform3D = rests["upper_arm_" + side]
	var r_fo: Transform3D = rests["forearm_" + side]
	var r_ha: Transform3D = rests["hand_" + side]
	var l1 := r_fo.origin.distance_to(r_ha.origin)   # elbow to wrist
	var l2 := r_up.origin.distance_to(r_fo.origin)   # shoulder to elbow
	var to_s := s - w
	var reach := to_s.length()
	var n := to_s / maxf(reach, 0.0001)
	var d := clampf(reach, absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var perp := pole - n * pole.dot(n)
	perp = perp.normalized() if perp.length() > 0.0001 else Vector3.DOWN
	var e := w + n * a + perp * h
	var s_used := w + n * d
	var q_fo := Quaternion((r_ha.origin - r_fo.origin).normalized(), (w - e).normalized())
	var q_up := Quaternion((r_fo.origin - r_up.origin).normalized(), (e - s_used).normalized())
	var i_fo := _skeleton.find_bone("forearm_" + side)
	var i_up := _skeleton.find_bone("upper_arm_" + side)
	if i_fo >= 0:
		_skeleton.set_bone_pose(i_fo, Transform3D(Basis(q_fo) * r_fo.basis, e))
	if i_up >= 0:
		_skeleton.set_bone_pose(i_up, Transform3D(Basis(q_up) * r_up.basis, s_used))
	return true


## The man's arm cut out of his model at the shoulder, in hand space (see the class notes): its
## mesh (every triangle whose corners are all on this side's arm, hand or finger bones), its skin
## and the bones' rests. Empty where his model can't be loaded.
static func source(side: String) -> Dictionary:
	if _sources.has(side):
		return _sources[side]
	var out := {}
	_sources[side] = out
	var scene := load(PeopleBodies.PATH % MODEL) as PackedScene if PeopleBodies.has_model(MODEL) else null
	if scene == null:
		return out
	var root := scene.instantiate()
	var mi: MeshInstance3D = null
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if String(m.name).to_lower() == "body_skin":
			mi = m
	var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D if mi else null
	if skel == null or mi.skin == null:
		root.free()
		return out
	var model_rest := {}
	for b in skel.get_bone_count():
		model_rest[String(skel.get_bone_name(b))] = skel.get_bone_global_rest(b)
	# Hand space from his hand: the index knuckle the origin, -Z from the wrist to the middle
	# knuckle, +Y from the little finger's knuckle to the index's, +X the back of the hand.
	var k_index: Vector3 = (model_rest["finger_index_%s_0" % side] as Transform3D).origin
	var k_middle: Vector3 = (model_rest["finger_middle_%s_0" % side] as Transform3D).origin
	var k_little: Vector3 = (model_rest["finger_little_%s_0" % side] as Transform3D).origin
	var w: Vector3 = (model_rest["hand_" + side] as Transform3D).origin
	var z := (w - k_middle).normalized()
	var y := (k_index - k_little)
	y = (y - z * y.dot(z)).normalized()
	# y x z is the back of a right hand and the palm of a left one: the left is the mirror.
	var x := y.cross(z)
	var to_hand := Transform3D(Basis(x, y, z), k_index).affine_inverse()
	var names: Array = ["upper_arm_" + side, "forearm_" + side, "hand_" + side]
	for f: String in FINGERS + ["thumb"]:
		for k in 3:
			names.append("finger_%s_%s_%d" % [f, side, k])
	var rests := {}
	for n: String in names:
		var r: Transform3D = to_hand * (model_rest[n] as Transform3D)
		rests[n] = r.orthonormalized()
	out["names"] = names
	out["rests"] = rests
	var elbow: Vector3 = (rests["forearm_" + side] as Transform3D).origin
	out["forearm_dir"] = (elbow - (rests["hand_" + side] as Transform3D).origin).normalized()
	# The mesh: its bone numbers are the skin's binds; ours are `names` (anything else on the arm,
	# the shoulder's chest share, goes to the upper arm).
	var bind_of := PackedInt32Array()
	for b in mi.skin.get_bind_count():
		var n := String(mi.skin.get_bind_name(b))
		if n == "":
			n = String(skel.get_bone_name(mi.skin.get_bind_bone(b)))
		bind_of.append(names.find(n))
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var src_bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var src_weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var tris: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var per := src_bones.size() / maxi(verts.size(), 1)
	var on_arm := PackedByteArray()
	on_arm.resize(verts.size())
	var xf := to_hand * mi.transform
	# Each bone's own skin (the vertices it carries most), for measuring a finger against what it holds.
	var points := {}
	for v in verts.size():
		var best := 0
		for k in per:
			if src_weights[v * per + k] > src_weights[v * per + best]:
				best = k
		var b := src_bones[v * per + best]
		on_arm[v] = 1 if b < bind_of.size() and bind_of[b] >= 0 else 0
		if on_arm[v]:
			var pts: PackedVector3Array = points.get(names[bind_of[b]], PackedVector3Array())
			pts.append(xf * verts[v])   # a packed array is a value: put back
			points[names[bind_of[b]]] = pts
	out["points"] = points
	var new_index := {}
	var o_verts := PackedVector3Array()
	var o_normals := PackedVector3Array()
	var o_uvs := PackedVector2Array()
	var o_bones := PackedInt32Array()
	var o_weights := PackedFloat32Array()
	var o_tris := PackedInt32Array()
	for t in range(0, tris.size(), 3):
		if not (on_arm[tris[t]] and on_arm[tris[t + 1]] and on_arm[tris[t + 2]]):
			continue
		for c in 3:
			var v := tris[t + c]
			if not new_index.has(v):
				new_index[v] = o_verts.size()
				o_verts.append(xf * verts[v])
				o_normals.append((xf.basis * normals[v]).normalized())
				o_uvs.append(uvs[v])
				var total := 0.0
				var bw := [0, 0, 0, 0]
				var ww := [0.0, 0.0, 0.0, 0.0]
				for k in mini(per, 4):
					var b := src_bones[v * per + k]
					var mapped := bind_of[b] if b < bind_of.size() else -1
					ww[k] = src_weights[v * per + k] if mapped >= 0 else 0.0
					bw[k] = maxi(mapped, 0)
					total += ww[k]
				for k in 4:
					o_bones.append(bw[k])
					o_weights.append(ww[k] / total if total > 0.0 else (1.0 if k == 0 else 0.0))
			o_tris.append(new_index[v])
	root.free()
	if o_tris.is_empty():
		return out
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = o_verts
	a[Mesh.ARRAY_NORMAL] = o_normals
	a[Mesh.ARRAY_TEX_UV] = o_uvs
	a[Mesh.ARRAY_BONES] = o_bones
	a[Mesh.ARRAY_WEIGHTS] = o_weights
	a[Mesh.ARRAY_INDEX] = o_tris
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	out["mesh"] = am
	var skin := Skin.new()
	for i in names.size():
		skin.add_bind(i, (rests[names[i]] as Transform3D).affine_inverse())
	out["skin"] = skin
	out["material"] = _material()
	out["triangles"] = o_tris.size() / 3
	return out


## His skin's painted texture in the men's own shader (HumanBody's whole men: _baked_cloth then
## BodyInterior.skin_material), so your hand takes light as theirs do.
static func _material() -> ShaderMaterial:
	var png := PeopleBodies.TEXTURE_PATH % [MODEL, "skin"]
	var base := StandardMaterial3D.new()
	base.albedo_texture = load(png) as Texture2D if ResourceLoader.exists(png) else null
	base.roughness = 0.95
	base.uv1_scale = Vector3.ONE
	var m := BodyInterior.skin_material(base)
	m.set_shader_parameter(&"use_uv", true)
	m.set_shader_parameter(&"uv_scale", 1.0)
	m.set_shader_parameter(&"shade_tint", PixelArt.SHADE_TINT)
	return m
