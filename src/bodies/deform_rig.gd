class_name DeformRig
extends RefCounted
## The fuller skeleton's deform bones (issue #696): a clavicle a side and two twist bones in each
## upper arm and forearm, in every man's skin after his 17 segment bones and his 30 finger bones.
## They only shape the skin: the ragdoll, the hitboxes, the anatomy, the wounds and the gore stay
## on the 17 segments, and nothing here moves a part. Each tick (HumanBody._update_skeleton, after
## the 17 bones follow the parts) the clavicles are driven by the arms' raise and reach in the
## chest's frame (a shoulder girdle's limits, SkeletonTuning), plus a pose's own lift (POSES'
## `clavicle_r`/`clavicle_l`: [rise, forward] degrees) or a clip's channel (a quaternion in the
## chest's frame, MotionClip frames' `clavicle_r`/`clavicle_l`); the twist bones take shares of the
## limb's roll about its own length (a swing-twist split of the joint's turn), so a turned wrist
## or a rolled upper arm twists the skin along the limb instead of wringing it at the joint.
##
## A model without weights of its own for them (BodyMesh's, MakeHuman's, the Studio's Rodin men)
## gets them at load from its 17-bone weights (`spread`): the clavicle from the chest's over the
## shoulder, the twists from the limb's along its length. A model that has them (the Studio's
## MetaHuman route: his own clavicle and finger weights) keeps its own.

const CLAVICLES: Array[StringName] = [&"clavicle_r", &"clavicle_l"]
## Off: every deform bone moves exactly as the bone it's part of (the clavicles as the chest, the
## twists as their limb), so his skin deforms as the 17-bone skeleton did (the labs' "before").
static var on := true
const NAMES: Array[StringName] = [&"clavicle_r", &"clavicle_l",
		&"upper_arm_twist_r_0", &"upper_arm_twist_r_1", &"upper_arm_twist_l_0", &"upper_arm_twist_l_1",
		&"forearm_twist_r_0", &"forearm_twist_r_1", &"forearm_twist_l_0", &"forearm_twist_l_1"]
## The segment each deform bone's skin is part of (its piece, its wounds).
const PART_OF := {&"clavicle_r": &"chest", &"clavicle_l": &"chest",
		&"upper_arm_twist_r_0": &"upper_arm_r", &"upper_arm_twist_r_1": &"upper_arm_r",
		&"upper_arm_twist_l_0": &"upper_arm_l", &"upper_arm_twist_l_1": &"upper_arm_l",
		&"forearm_twist_r_0": &"forearm_r", &"forearm_twist_r_1": &"forearm_r",
		&"forearm_twist_l_0": &"forearm_l", &"forearm_twist_l_1": &"forearm_l"}


## Whether the anatomy has what the rig hangs on (an anatomy not loaded, `Anatomy.new()`, doesn't).
static func can_rig(anatomy: Anatomy) -> bool:
	for sid: StringName in [&"chest", &"upper_arm_r", &"upper_arm_l", &"forearm_r", &"forearm_l", &"hand_r", &"hand_l"]:
		if not anatomy.segments.has(sid):
			return false
	return true


## Where the deform bones' binds start: after the anatomy's bones and the finger bones.
static func first_bind(anatomy: Anatomy) -> int:
	return anatomy.segment_order().size() + PeopleBodies.finger_bone_names().size()


## Name -> bind index for every deform bone.
static func bind_index(anatomy: Anatomy) -> Dictionary:
	var out := {}
	var b := first_bind(anatomy)
	for k in NAMES.size():
		out[NAMES[k]] = b + k
	return out


## Each deform bone's bind -> its segment's (split_pieces' `piece_of`).
static func piece_of(anatomy: Anatomy) -> Dictionary:
	var order := anatomy.segment_order()
	var out := {}
	var di := bind_index(anatomy)
	for n: StringName in di:
		out[di[n]] = order.find(PART_OF[n])
	return out


## A clavicle's rest ends (sternal, acromial) for a side, from the anatomy's bone.
static func clavicle_ends(anatomy: Anatomy, side: String) -> Array:
	var st := anatomy.structure(StringName("clavicle_" + side))
	if st.is_empty():
		var sx := 1.0 if side == "r" else -1.0
		var top: Vector3 = anatomy.segments[&"upper_arm_" + side].a
		return [Vector3(0.02 * sx, top.y, -0.05), top]
	return [st.a, st.b]


# --- The skin's weights ---------------------------------------------------------------------------

## What a model's weights already have of the deform bones: {clavicle: bool, twist: bool}.
static func has_own(bones: PackedInt32Array, weights: PackedFloat32Array, anatomy: Anatomy) -> Dictionary:
	var b0 := first_bind(anatomy)
	var out := {"clavicle": false, "twist": false}
	for i in bones.size():
		if weights[i] <= 0.0:
			continue
		var k := bones[i] - b0
		if k >= 0 and k < NAMES.size():
			if k < 2:
				out.clavicle = true
			else:
				out.twist = true
	return out


## Shares out a mesh's weights (4 a vertex, the anatomy's bone indices, finger bones and helpers
## after them) onto the deform bones in place: the chest's over each shoulder to that clavicle
## (`clavicle`), each upper arm's and forearm's along its length to its twist bones (`twist`).
## Keeps the four strongest of each vertex, renormalised.
static func spread(verts: PackedVector3Array, bones: PackedInt32Array, weights: PackedFloat32Array,
		anatomy: Anatomy, clavicle := true, twist := true, tuning: SkeletonTuning = null) -> void:
	if not can_rig(anatomy):
		return
	var t := tuning if tuning != null else SkeletonTuning.shared()
	var order := anatomy.segment_order()
	var at := {}
	for i in order.size():
		at[order[i]] = i
	var di := bind_index(anatomy)
	var chest: int = at.get(&"chest", -1)
	var clav := []  # per side: [sternal end, acromial end]
	for side in ["r", "l"]:
		clav.append(clavicle_ends(anatomy, side))
	var limbs := []  # [segment bone, a, b, [bones at t = 0, 0.5, 1]]
	for side in ["r", "l"]:
		var ua: Dictionary = anatomy.segments[StringName("upper_arm_" + side)]
		limbs.append([at[StringName("upper_arm_" + side)], ua.a, ua.b,
				[di[StringName("upper_arm_twist_%s_0" % side)], di[StringName("upper_arm_twist_%s_1" % side)],
				at[StringName("upper_arm_" + side)]]])
		var fa: Dictionary = anatomy.segments[StringName("forearm_" + side)]
		limbs.append([at[StringName("forearm_" + side)], fa.a, fa.b,
				[at[StringName("forearm_" + side)], di[StringName("forearm_twist_%s_0" % side)],
				di[StringName("forearm_twist_%s_1" % side)]]])
	for v in verts.size():
		var p := verts[v]
		var pairs := {}  # bone -> weight
		for k in 4:
			var w := weights[v * 4 + k]
			if w > 0.0:
				pairs[bones[v * 4 + k]] = float(pairs.get(bones[v * 4 + k], 0.0)) + w
		var changed := false
		if clavicle and chest >= 0 and pairs.has(chest):
			var side := 0 if p.x >= 0.0 else 1
			var g := _clav_reach(p, clav[side][0], clav[side][1], t)
			if g > 0.0:
				var wc: float = pairs[chest]
				var move := wc * g * t.clav_weight
				pairs[chest] = wc - move
				var cb: int = di[CLAVICLES[side]]
				pairs[cb] = float(pairs.get(cb, 0.0)) + move
				changed = true
		if twist:
			for limb: Array in limbs:
				var seg: int = limb[0]
				if not pairs.has(seg):
					continue
				var a: Vector3 = limb[1]
				var b: Vector3 = limb[2]
				var ab := b - a
				var u := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
				var ws: float = pairs[seg]
				pairs.erase(seg)
				var chain: Array = limb[3]
				var lo := 0 if u < 0.5 else 1
				var f := (u - 0.5 * lo) / 0.5
				var b0: int = chain[lo]
				var b1: int = chain[lo + 1]
				pairs[b0] = float(pairs.get(b0, 0.0)) + ws * (1.0 - f)
				pairs[b1] = float(pairs.get(b1, 0.0)) + ws * f
				changed = true
		if not changed:
			continue
		var list := []
		for bone: int in pairs:
			if float(pairs[bone]) > 1e-6:
				list.append([bone, float(pairs[bone])])
		list.sort_custom(func(x: Array, y: Array) -> bool: return x[1] > y[1])
		var total := 0.0
		for k in mini(4, list.size()):
			total += float(list[k][1])
		for k in 4:
			if k < list.size() and total > 0.0:
				bones[v * 4 + k] = list[k][0]
				weights[v * 4 + k] = float(list[k][1]) / total
			else:
				bones[v * 4 + k] = 0
				weights[v * 4 + k] = 0.0


## How much of a chest vertex at p is its shoulder's clavicle's (0..1): along the clavicle's outer
## part, above the armpit, near its line front to back.
static func _clav_reach(p: Vector3, sc: Vector3, ac: Vector3, t: SkeletonTuning) -> float:
	var d := ac - sc
	var along := (p - sc).dot(d) / d.length_squared()
	var g_along := smoothstep(t.clav_from, t.clav_full, along)
	if g_along <= 0.0:
		return 0.0
	var g_up := smoothstep(ac.y - t.clav_below - t.clav_fade, ac.y - t.clav_below, p.y)
	var dz := absf(p.z - lerpf(sc.z, ac.z, clampf(along, 0.0, 1.0)))
	var g_depth := 1.0 - smoothstep(t.clav_depth, t.clav_depth + t.clav_fade, dz)
	return g_along * g_up * g_depth


# --- The bones in his skeleton ---------------------------------------------------------------------

## One deform bone: its bone, what drives it, the numbers its pose takes.
class Bone:
	var bone: int
	var kind := 0  ## 0 clavicle, 1 upper arm twist, 2 forearm twist
	var side := 0  ## 0 right, 1 left
	var parent: int  ## the bone it moves with (chest, upper arm, forearm)
	var child: int  ## the bone whose roll or raise drives it (upper arm, upper arm, hand)
	var pivot: Vector3  ## rest: the joint it turns about (sternal end; shoulder; elbow)
	var axis: Vector3  ## rest: the limb's length (twists) or the clavicle's (sternal to acromial)
	var hang: Vector3  ## rest: the upper arm hanging (the clavicle's driver)
	var share := 0.0
	var rest: Transform3D
	var parent_unrest: Transform3D
	var child_unrest: Transform3D
	var lift := Vector2.ZERO  ## the pose's own extra [rise, forward], blended (degrees)


## The rig a man's skeleton gets: the bones added (in NAMES' order, at `first_bind`) with their
## binds in his skin. `bone_parts`: the anatomy's bones by index.
static func add(skeleton: Skeleton3D, skin: Skin, anatomy: Anatomy, bone_parts: Array,
		tuning: SkeletonTuning = null) -> Array[Bone]:
	var t := tuning if tuning != null else SkeletonTuning.shared()
	var out: Array[Bone] = []
	if not can_rig(anatomy):
		return out
	if skeleton.get_bone_count() != first_bind(anatomy):
		push_error("DeformRig: expected the deform bones at bind %d, the skeleton has %d" % [first_bind(anatomy), skeleton.get_bone_count()])
		return out
	for name: StringName in NAMES:
		var e := Bone.new()
		var s := String(name)
		var side := "r" if s.contains("_r") else "l"
		e.side = 0 if side == "r" else 1
		if s.begins_with("clavicle"):
			e.kind = 0
			var ends := clavicle_ends(anatomy, side)
			e.pivot = ends[0]
			e.axis = ((ends[1] as Vector3) - (ends[0] as Vector3)).normalized()
			e.parent = bone_parts.find(&"chest")
			e.child = bone_parts.find(StringName("upper_arm_" + side))
			var ua: Dictionary = anatomy.segments[StringName("upper_arm_" + side)]
			e.hang = ((ua.b as Vector3) - (ua.a as Vector3)).normalized()
		elif s.begins_with("upper_arm"):
			e.kind = 1
			var ua: Dictionary = anatomy.segments[StringName("upper_arm_" + side)]
			e.pivot = ua.a
			e.axis = ((ua.b as Vector3) - (ua.a as Vector3)).normalized()
			e.parent = bone_parts.find(&"chest")
			e.child = bone_parts.find(StringName("upper_arm_" + side))
			e.share = t.upper_twist_shares[int(s.right(1))]
		else:
			e.kind = 2
			var fa: Dictionary = anatomy.segments[StringName("forearm_" + side)]
			e.pivot = fa.a
			e.axis = ((fa.b as Vector3) - (fa.a as Vector3)).normalized()
			e.parent = bone_parts.find(StringName("forearm_" + side))
			e.child = bone_parts.find(StringName("hand_" + side))
			e.share = t.fore_twist_shares[int(s.right(1))]
		if e.parent < 0 or e.child < 0:
			push_error("DeformRig: %s has no %s" % [name, "parent" if e.parent < 0 else "driver"])
			return []
		# Its rest: the sternal end (the clavicle), its limb's bone's (the twists), unturned as every
		# bone of his is at rest.
		e.rest = Transform3D(Basis.IDENTITY, e.pivot) if e.kind == 0 \
				else skeleton.get_bone_rest(e.child if e.kind == 1 else e.parent)
		e.parent_unrest = skeleton.get_bone_rest(e.parent).affine_inverse()
		e.child_unrest = skeleton.get_bone_rest(e.child).affine_inverse()
		e.bone = skeleton.get_bone_count()
		skeleton.add_bone(String(name))
		skeleton.set_bone_rest(e.bone, e.rest)
		skin.add_bind(e.bone, e.rest.affine_inverse())
		out.append(e)
	return out


## The rig posed from the 17 bones as they are now (all root bones: their poses are in the
## skeleton's space). `extra`: the pose's own clavicle lift per side ([rise, forward] degrees,
## Vector2), `clip`: a clip's clavicle turn per side (Quaternion in the chest's frame) and its
## weight; `delta` blends the extra lift in (0: at once).
static func pose(skeleton: Skeleton3D, rig: Array[Bone], extra: Array, clip: Array, clip_w: float, delta: float,
		tuning: SkeletonTuning = null) -> void:
	var t := tuning if tuning != null else SkeletonTuning.shared()
	for e in rig:
		var mp := skeleton.get_bone_pose(e.parent) * e.parent_unrest
		var mc := skeleton.get_bone_pose(e.child) * e.child_unrest
		var rel := (mp.basis.inverse() * mc.basis).get_rotation_quaternion()
		var turn: Quaternion
		if not on:
			skeleton.set_bone_pose(e.bone, (mc if e.kind == 1 else mp) * e.rest)
			continue
		if e.kind == 0:
			var want: Vector2 = extra[e.side] if e.side < extra.size() else Vector2.ZERO
			if delta <= 0.0:
				e.lift = want
			else:
				e.lift = e.lift.lerp(want, clampf(delta * t.clav_blend, 0.0, 1.0))
			turn = clavicle_turn(rel, e.hang, e.axis, e.lift, t)
			if clip_w > 0.0 and e.side < clip.size() and clip[e.side] is Quaternion:
				turn = turn.slerp(clip[e.side], clamp(clip_w, 0.0, 1.0))
		else:
			var tw := twist_of(rel, e.axis)
			# The upper arm's twist bones keep its swing (they hang where the arm does) and take a share
			# of its roll; the forearm's keep the forearm's own turn and take a share of the hand's roll.
			turn = (rel * tw.inverse()) * Quaternion.IDENTITY.slerp(tw, e.share) if e.kind == 1 \
					else Quaternion.IDENTITY.slerp(tw, e.share)
		var b := Basis(turn)
		var m := mp * Transform3D(b, e.pivot - b * e.pivot)
		skeleton.set_bone_pose(e.bone, m * e.rest)


## A turn's twist about an axis (the swing-twist split: q = swing * twist), the shorter way round.
static func twist_of(q: Quaternion, axis: Vector3) -> Quaternion:
	var v := Vector3(q.x, q.y, q.z)
	var p := axis * v.dot(axis)
	var tw := Quaternion(p.x, p.y, p.z, q.w)
	if tw.length_squared() < 1e-12:
		return Quaternion.IDENTITY
	tw = tw.normalized()
	return tw if tw.w >= 0.0 else -tw


## A clavicle's turn in the chest's frame for the upper arm's turn there (`rel`, from rest), the
## arm hanging along `hang` and the clavicle along `axis` at rest, plus a pose's extra lift: its
## rise with the arm's raise past `clav_raise_from`, forward with the arm's reach in front of him
## (back behind him, and a little back as it rises), each within the girdle's limits.
static func clavicle_turn(rel: Quaternion, hang: Vector3, axis: Vector3, lift: Vector2, t: SkeletonTuning) -> Quaternion:
	var arm := rel * hang
	var raise := rad_to_deg(acos(clampf(-arm.y, -1.0, 1.0)))
	var past := maxf(0.0, raise - t.clav_raise_from)
	var rise := clampf(past * t.clav_rise_per_deg + lift.x, -t.clav_drop_max, t.clav_rise_max)
	var fwd := clampf(-arm.z * t.clav_forward_per_reach - past * t.clav_back_per_deg + lift.y,
			-t.clav_back_max, t.clav_forward_max)
	var up_axis := axis.cross(Vector3.UP).normalized()
	var fwd_axis := axis.cross(Vector3.FORWARD).normalized()
	return Quaternion(fwd_axis, deg_to_rad(fwd)) * Quaternion(up_axis, deg_to_rad(rise))
