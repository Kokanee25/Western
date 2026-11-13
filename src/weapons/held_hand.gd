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
const ARM_SKIN := "res://assets/weapons/held_arm_skin.png"
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
## pivot -> degrees the man's finger is already closed at rest (a MetaHuman's rest hand is curled):
## taken off every curl, so a pose's angles mean the same finger whoever's hand it is.
var _rest_curl := {}

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
			_rest_curl[pivot] = float((_src.get("rest_curl", {}) as Dictionary).get(bn, 0.0))
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
		for part: Dictionary in _src.parts:
			var mi := MeshInstance3D.new()
			mi.name = part.name
			mi.mesh = part.mesh
			mi.skin = _src.skin
			mi.material_override = part.material
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.custom_aabb = AABB(Vector3(-0.6, -0.6, -0.6), Vector3(1.2, 1.2, 1.2))
			_skeleton.add_child(mi)
			mi.skeleton = NodePath("..")
			if mesh == null:
				mesh = mi
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
		var c := float(angles[i]) - float(_rest_curl.get(bones[i], 0.0))
		(bones[i] as Node3D).rotation = Vector3(0.0, 0.0, deg_to_rad(c) * sx)


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
	var r := root_deg + Vector3(0.0, 0.0, float(_rest_curl.get(t[0], 0.0)))
	(t[0] as Node3D).rotation_degrees = r if right else Vector3(r.x, -r.y, -r.z)
	(t[1] as Node3D).rotation = Vector3(0.0, 0.0, deg_to_rad(bend1 - float(_rest_curl.get(t[1], 0.0))) * sx)
	(t[2] as Node3D).rotation = Vector3(0.0, 0.0, deg_to_rad(bend2 - float(_rest_curl.get(t[2], 0.0))) * sx)


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


## Where the arms come from: Harlan's first-person arms (the Character Studio's `tools/fp_arms.py`, from
## MetaHuman Sean: his skin, his shirt sleeves rolled to the forearm) where that private file is here,
## else the painted Studio man's (`MODEL`). MetaHuman files never go in this public repo (#692): the
## arms file is fetched into the git-ignored `assets/people/private/` (tools/characters/fetch_arms.sh).
const PRIVATE_ARMS := "res://assets/people/private/harlan_arms.glb"
## Off, the painted arms even where the private file is (the labs' "before"; tests; the game started
## with `-- --painted-arms`).
static var use_private := not OS.get_cmdline_user_args().has("--painted-arms")


static func arms_path() -> String:
	if use_private and ResourceLoader.exists(PRIVATE_ARMS):
		return PRIVATE_ARMS
	return PeopleBodies.PATH % MODEL if PeopleBodies.has_model(MODEL) else ""


## True when the hands are the MetaHuman arms (their own skin and shirt, not the painted man's).
static func metahuman() -> bool:
	return arms_path() == PRIVATE_ARMS


## Holds fitted to the MetaHuman hand, by gun and name (a viewmodel asks `hold(key, painted)`). His
## hand is a real big hand: its fingers ~25% longer than the painted man's (middle 4.5 cm to his
## 3.6), so the painted hand's angles overshoot or float; these are the gun lab's `views.gd --fit`
## for his (`--gun=revolver`, `--gun=winchester`), each finger closed until it touches.
const MH_HOLDS := {
	"colt.grip": {"middle": 71.0, "ring": 59.0, "little": 52.0},
	"colt.trigger_rest": 30.0,
	"colt.trigger_pull": 38.0,
	"colt.thumb_rest": [Vector3(-24.0, -36.0, 24.0), 15.0, 15.0],
	"colt.thumb_cock": [Vector3(48.0, 24.0, 12.0), 45.0, 40.0],
	# The Winchester's left hand: placed up and across (design inches) and its palm rolled onto the
	# forend so the fingers wrap up its right side (the painted hand's place left his knuckles 2-4 cm
	# under the wood: the search in `_fit_win73_left`).
	"win73.l_hand_ful": Vector3(8.2, -2.05, -0.25),
	"win73.l_roll": 30.0,
	"win73.l_grip": {"index": 20.0, "middle": 40.0, "ring": 75.0, "little": 75.0},
}


## The hold called `key` for the hands you have: the MetaHuman's fitted one where his arms are in,
## else `painted` (the viewmodel's own constant).
static func hold(key: String, painted: Variant) -> Variant:
	return MH_HOLDS.get(key, painted) if metahuman() else painted


## Forgets the cut arms (after `use_private` changes, so the next hand is cut again).
static func reset() -> void:
	_sources.clear()


## The man's arm cut out of his model at the shoulder, in hand space (see the class notes): its
## meshes (every triangle whose corners are all on this side's arm, hand or finger bones: his skin,
## and the MetaHuman arms' shirt sleeve), its skin and the bones' rests. Empty where his model can't
## be loaded.
static func source(side: String) -> Dictionary:
	if _sources.has(side):
		return _sources[side]
	var out := {}
	_sources[side] = out
	var path := arms_path()
	var scene := load(path) as PackedScene if path != "" else null
	if scene == null:
		return out
	var mh := path == PRIVATE_ARMS
	var root := scene.instantiate()
	var mi: MeshInstance3D = null
	var cloth: Array[MeshInstance3D] = []
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var nm := String(m.name).to_lower()
		if nm == "body_skin":
			mi = m
		elif mh and nm.begins_with("cloth_"):
			cloth.append(m)
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
	if mh:
		out["rest_curl"] = _canonical_fingers(rests, side)
	out["names"] = names
	out["rests"] = rests
	var elbow: Vector3 = (rests["forearm_" + side] as Transform3D).origin
	out["forearm_dir"] = (elbow - (rests["hand_" + side] as Transform3D).origin).normalized()
	# The arm's twist bones (a fuller-skeleton model's) carry their segment's share.
	var alias := {}
	for k in 2:
		alias["upper_arm_twist_%s_%d" % [side, k]] = "upper_arm_" + side
		alias["forearm_twist_%s_%d" % [side, k]] = "forearm_" + side
	var points := {}
	var cut := _cut(mi, skel, names, alias, to_hand, points)
	out["points"] = points
	if cut == null:
		root.free()
		return out
	out["mesh"] = cut
	out["material"] = _own_material(mi, true) if mh else _material()
	out["triangles"] = cut.surface_get_array_index_len(0) / 3
	var parts: Array = [{"name": "Arm", "mesh": cut, "material": out.material}]
	for c in cloth:
		var cm := _cut(c, skel, names, alias, to_hand, {})
		if cm:
			parts.append({"name": String(c.name).to_pascal_case(), "mesh": cm, "material": _own_material(c, false)})
			out["triangles"] = int(out.triangles) + cm.surface_get_array_index_len(0) / 3
	out["parts"] = parts
	root.free()
	var skin := Skin.new()
	for i in names.size():
		skin.add_bind(i, (rests[names[i]] as Transform3D).affine_inverse())
	out["skin"] = skin
	return out


## A MetaHuman's finger bones in the painted men's frames, in place (hand space): each bone's +Y back
## along it from its next joint, +Z the knuckle's hinge (across the hand, -Y), so a curl is a turn
## about Z as theirs is (his own point +Y to the tip, Z flipped, and lean ~25 degrees). Returns each
## bone's curl at rest (degrees towards the palm from the bone before it, the first from the hand's
## line): his rest hand is half closed.
static func _canonical_fingers(rests: Dictionary, side: String) -> Dictionary:
	var curl := {}
	var palm := Vector3(-1.0, 0.0, 0.0) if side == "r" else Vector3(1.0, 0.0, 0.0)
	for f: String in FINGERS + ["thumb"]:
		var o: Array[Vector3] = []
		for k in 3:
			o.append((rests["finger_%s_%s_%d" % [f, side, k]] as Transform3D).origin)
		var dirs: Array[Vector3] = [(o[1] - o[0]).normalized(), (o[2] - o[1]).normalized()]
		dirs.append(dirs[1])
		var before := Vector3(0.0, 0.0, -1.0)
		for k in 3:
			var bn := "finger_%s_%s_%d" % [f, side, k]
			var yb := -dirs[k]
			var zb := Vector3(0.0, -1.0, 0.0)
			zb = (zb - yb * zb.dot(yb)).normalized()
			var xb := yb.cross(zb)
			rests[bn] = Transform3D(Basis(xb, yb, zb), o[k])
			# Its bend from the bone before, in the hinge's plane, closing (towards the palm) positive.
			var a := before - zb * before.dot(zb)
			var b := dirs[k] - zb * dirs[k].dot(zb)
			var ang := rad_to_deg(a.angle_to(b)) if k < 2 else 0.0
			curl[bn] = ang if (b - a).dot(palm) >= 0.0 else -ang
			before = dirs[k]
	return curl


## One mesh's triangles on this arm, in hand space, their weights on `names` (an `alias`ed bone
## counts as its segment; anything else, the shoulder's chest share, is dropped). `points` takes each
## bone's own skin (the vertices it carries most), for measuring a finger against what it holds.
static func _cut(mi: MeshInstance3D, skel: Skeleton3D, names: Array, alias: Dictionary,
		to_hand: Transform3D, points: Dictionary) -> ArrayMesh:
	var bind_of := PackedInt32Array()
	for b in mi.skin.get_bind_count():
		var n := String(mi.skin.get_bind_name(b))
		if n == "":
			n = String(skel.get_bone_name(mi.skin.get_bind_bone(b)))
		bind_of.append(names.find(alias.get(n, n)))
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var tangents = arrays[Mesh.ARRAY_TANGENT]
	var src_bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var src_weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var tris: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var per := src_bones.size() / maxi(verts.size(), 1)
	var on_arm := PackedByteArray()
	on_arm.resize(verts.size())
	var xf := to_hand * mi.transform
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
	var new_index := {}
	var o_verts := PackedVector3Array()
	var o_normals := PackedVector3Array()
	var o_uvs := PackedVector2Array()
	var o_tangents := PackedFloat32Array()
	var has_tangents: bool = tangents is PackedFloat32Array and (tangents as PackedFloat32Array).size() == verts.size() * 4
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
				if has_tangents:
					var tg := xf.basis * Vector3(tangents[v * 4], tangents[v * 4 + 1], tangents[v * 4 + 2])
					tg = tg.normalized()
					o_tangents.append_array([tg.x, tg.y, tg.z, tangents[v * 4 + 3] * signf(xf.basis.determinant())])
				# The strongest four of this vertex's bones that are on the arm, summed by bone.
				var acc := {}
				for k in per:
					var b := src_bones[v * per + k]
					var mapped := bind_of[b] if b < bind_of.size() else -1
					if mapped >= 0 and src_weights[v * per + k] > 0.0:
						acc[mapped] = float(acc.get(mapped, 0.0)) + src_weights[v * per + k]
				var keys := acc.keys()
				keys.sort_custom(func(p, q): return acc[p] > acc[q])
				var total := 0.0
				for k in mini(keys.size(), 4):
					total += float(acc[keys[k]])
				for k in 4:
					o_bones.append(int(keys[k]) if k < keys.size() else 0)
					o_weights.append(float(acc[keys[k]]) / total if k < keys.size() and total > 0.0 else (1.0 if k == 0 and keys.is_empty() else 0.0))
			o_tris.append(new_index[v])
	if o_tris.is_empty():
		return null
	# A painted man's mesh is split at nearly every triangle (a texture seam each: 11,615 vertices on
	# 3,036 points), so each face shaded flat and the arm drew in facets: every vertex takes the mean
	# normal of all those at its point (an arm has no hard edge to keep).
	var at := {}
	for i in o_verts.size():
		var k := o_verts[i].snappedf(0.0001)
		at[k] = (at.get(k, Vector3.ZERO) as Vector3) + o_normals[i]
	for i in o_verts.size():
		o_normals[i] = (at[o_verts[i].snappedf(0.0001)] as Vector3).normalized()
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = o_verts
	a[Mesh.ARRAY_NORMAL] = o_normals
	a[Mesh.ARRAY_TEX_UV] = o_uvs
	if has_tangents:
		a[Mesh.ARRAY_TANGENT] = o_tangents
	a[Mesh.ARRAY_BONES] = o_bones
	a[Mesh.ARRAY_WEIGHTS] = o_weights
	a[Mesh.ARRAY_INDEX] = o_tris
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return am


## A MetaHuman arms mesh's own material (his skin maps, the shirt's weave), as the Studio draws
## him: skin with subsurface scattering in skin mode, so the light through his fingers' edges warms.
static func _own_material(mi: MeshInstance3D, skin: bool) -> Material:
	var m := mi.mesh.surface_get_material(0) if mi.mesh.get_surface_count() > 0 else null
	if m == null:
		m = mi.get_surface_override_material(0)
	var std := m.duplicate() as StandardMaterial3D if m is StandardMaterial3D else StandardMaterial3D.new()
	if skin:
		std.subsurf_scatter_enabled = true
		std.subsurf_scatter_strength = 0.35
		std.subsurf_scatter_skin_mode = true
	else:
		std.uv1_scale = Vector3.ONE
	return std


## His skin's painted texture in the men's own shader (HumanBody's whole men: _baked_cloth then
## BodyInterior.skin_material), so your hand takes light as theirs do.
static func _material() -> ShaderMaterial:
	# His skin's texture with your arms repainted in the men's hand (the gun lab's
	# blender/arm_blender.py), where it's been made; his own elsewhere.
	var png := ARM_SKIN if ResourceLoader.exists(ARM_SKIN) else PeopleBodies.TEXTURE_PATH % [MODEL, "skin"]
	var base := StandardMaterial3D.new()
	base.albedo_texture = load(png) as Texture2D if ResourceLoader.exists(png) else null
	base.roughness = 0.95
	base.uv1_scale = Vector3.ONE
	var m := BodyInterior.skin_material(base)
	m.set_shader_parameter(&"use_uv", true)
	m.set_shader_parameter(&"uv_scale", 1.0)
	m.set_shader_parameter(&"shade_tint", PixelArt.SHADE_TINT)
	return m
