extends Node3D
## The arm the glove comes off (#895; lab only): kinematic shapes fitted inside his own skin, on a
## physics layer only the glove looks for, following his bones each tick. His hitboxes (the 17
## segments' capsules) are a hand's breadth off his skin in places; the cloth would hang off them
## or sink into him. Each segment is cut in slices along it and each slice gets a capsule a little
## inside the skin there (the skin's median distance from the bone's line, less `margin`);
## the palm is a box in the hand bone's frame, each finger bone a capsule.
## Also counts the glove's points inside the arm (`through`): inside a shape by more than 1 mm.

## The physics bit the glove and these shapes share (nothing else in the game uses it).
const LAYER := 1 << 12
## Inside the skin by this (m), so a point resting on a shape is drawn just outside his skin.
var margin := 0.0015
var friction := 0.0
var side := "l"

var skeleton: Skeleton3D
## Each shape: {body, bone, local (in the bone's posed frame), kind, a, b (capsule ends in local),
## r, half (box)}
var shapes: Array[Dictionary] = []
## A node at each bone that something is pinned to (bone index -> Node3D), carried with it.
var carriers := {}


## Fitted to `skin_mi`'s (Skin_whole) bind mesh, from the cuff (`cuff_t` down the upper arm) to
## the fingertips.
func fit(man: Node, skin_mi: MeshInstance3D, cuff_t: float, on_side := "l") -> void:
	side = on_side
	skeleton = man.skeleton
	var skin := skin_mi.skin
	var arrays := skin_mi.mesh.surface_get_arrays(0)
	var sv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var sb: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var sw: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := sb.size() / sv.size()
	var bind_of := {}
	var bind_bone := PackedInt32Array()
	for b in skin.get_bind_count():
		var bi := skin.get_bind_bone(b)
		if bi < 0:
			bi = skeleton.find_bone(skin.get_bind_name(b))
		bind_bone.append(bi)
		bind_of[bi] = b
	# Which segment each skin vertex is on (its heaviest bone, twists counted as their limb's).
	var seg_of := func(bone_name: String) -> String:
		if bone_name.begins_with("upper_arm_twist_" + side):
			return "upper_arm_" + side
		if bone_name.begins_with("forearm_twist_" + side):
			return "forearm_" + side
		return bone_name
	var by_seg := {}
	for i in sv.size():
		var best := -1.0
		var bb := -1
		for k in per:
			if sw[i * per + k] > best:
				best = sw[i * per + k]
				bb = bind_bone[sb[i * per + k]]
		var s: String = seg_of.call(skeleton.get_bone_name(bb))
		if not by_seg.has(s):
			by_seg[s] = PackedVector3Array()
		var got: PackedVector3Array = by_seg[s]  # (a packed array in a dictionary is a copy)
		got.append(sv[i])
		by_seg[s] = got
	var rest := func(n: String) -> Vector3:
		var bi := skeleton.find_bone(n)
		return skin.get_bind_pose(bind_of[bi]).affine_inverse().origin
	var sh: Vector3 = rest.call("upper_arm_" + side)
	var el: Vector3 = rest.call("forearm_" + side)
	var wr: Vector3 = rest.call("hand_" + side)
	var kn: Vector3 = rest.call("finger_middle_%s_0" % side)
	# Each limb's shapes stop short of its joints: a bent elbow folds the skin in past where a rigid
	# shape of either bone would be.
	_limb("upper_arm_" + side, sh.lerp(el, cuff_t - 0.06), sh.lerp(el, 0.86), by_seg.get("upper_arm_" + side, PackedVector3Array()), 3, skin, bind_of)
	_limb("forearm_" + side, el.lerp(wr, 0.1), el.lerp(wr, 0.97), by_seg.get("forearm_" + side, PackedVector3Array()), 4, skin, bind_of)
	_palm("hand_" + side, wr, kn, by_seg.get("hand_" + side, PackedVector3Array()), skin, bind_of)
	for f in ["thumb", "index", "middle", "ring", "little"]:
		for k in 3:
			var bn := "finger_%s_%s_%d" % [f, side, k]
			var a: Vector3 = rest.call(bn)
			var b: Vector3
			if k < 2:
				b = rest.call("finger_%s_%s_%d" % [f, side, k + 1])
			else:
				b = _tip_end(a, a - rest.call("finger_%s_%s_1" % [f, side]), by_seg.get(bn, PackedVector3Array()))
			_limb(bn, a, b, by_seg.get(bn, PackedVector3Array()), 1, skin, bind_of, 0.35, 0.002)


## A finger's end: as far out along it as its skin goes.
func _tip_end(a: Vector3, dir: Vector3, pts: PackedVector3Array) -> Vector3:
	var d := dir.normalized()
	var far := 0.012
	for p in pts:
		far = maxf(far, (p - a).dot(d))
	return a + d * (far - 0.004)


## Capsules along a <-> b, `n` slices, each a little inside the skin of `pts` there.
func _limb(bone: String, a: Vector3, b: Vector3, pts: PackedVector3Array, n: int, skin: Skin, bind_of: Dictionary,
		pct := 0.5, inside := -1.0) -> void:
	if inside < 0.0:
		inside = margin
	var axis := b - a
	var len2 := axis.length_squared()
	for s in n:
		var t0 := float(s) / n
		var t1 := float(s + 1) / n
		var radii: Array[float] = []
		for p in pts:
			var t := (p - a).dot(axis) / len2
			if t >= t0 and t <= t1:
				radii.append((p - (a + axis * t)).length())
		if radii.size() < 6:
			continue
		radii.sort()
		var r := radii[int(radii.size() * pct)] - inside
		if r < 0.003:
			continue
		var pa := a + axis * t0
		var pb := a + axis * t1
		# Capsule ends pulled in by the radius so the slices meet, not overlap far past.
		var mid := (pa + pb) * 0.5
		var half := maxf((pb - pa).length() * 0.5, 0.0005)
		r = minf(r, half * 4.0)
		var dir := axis.normalized()
		_add(bone, {"kind": "capsule", "a": mid - dir * half, "b": mid + dir * half, "r": r}, skin, bind_of)


## The palm: a box between the wrist and the middle knuckle, as wide and thick as his hand's skin
## (its 6th to 94th percentiles across, 10th to 90th through), in a frame along the hand.
func _palm(bone: String, wr: Vector3, kn: Vector3, pts: PackedVector3Array, skin: Skin, bind_of: Dictionary) -> void:
	var x := (kn - wr).normalized()
	# The hand's flat: the spread of its skin across x (its widest direction across).
	var cov := [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var m := Vector3.ZERO
	for p in pts:
		m += p - (p - wr).dot(x) * x
	m /= maxf(pts.size(), 1)
	var cxx := 0.0
	var cyy := 0.0
	var cxy := 0.0
	var u := x.cross(Vector3.UP).normalized()
	if u.length() < 0.5:
		u = x.cross(Vector3.FORWARD).normalized()
	var v := x.cross(u)
	for p in pts:
		var d := p - m
		var du := d.dot(u)
		var dv := d.dot(v)
		cxx += du * du
		cyy += dv * dv
		cxy += du * dv
	var ang := 0.5 * atan2(2.0 * cxy, cxx - cyy)
	var wide := (u * cos(ang) + v * sin(ang)).normalized()
	var thick := x.cross(wide).normalized()
	var ex: Array[float] = []
	var ew: Array[float] = []
	var et: Array[float] = []
	for p in pts:
		var d := p - wr
		var along := d.dot(x)
		if along < 0.0 or along > (kn - wr).length():
			continue
		ex.append(along)
		ew.append(d.dot(wide))
		et.append(d.dot(thick))
	if ew.size() < 10:
		return
	ew.sort()
	et.sort()
	var lo_w := ew[int(ew.size() * 0.06)]
	var hi_w := ew[int(ew.size() * 0.94)]
	var lo_t := et[int(et.size() * 0.1)]
	var hi_t := et[int(et.size() * 0.9)]
	var len_x := (kn - wr).length()
	var centre := wr + x * (len_x * 0.5) + wide * ((lo_w + hi_w) * 0.5) + thick * ((lo_t + hi_t) * 0.5)
	var half := Vector3(len_x * 0.5, (hi_w - lo_w) * 0.5 - margin, (hi_t - lo_t) * 0.5 - margin)
	_add(bone, {"kind": "box", "xf": Transform3D(Basis(x, wide, thick).orthonormalized(), centre), "half": half}, skin, bind_of)


func _add(bone: String, spec: Dictionary, skin: Skin, bind_of: Dictionary) -> void:
	var bi := skeleton.find_bone(bone)
	var bind := skin.get_bind_pose(bind_of[bi])  # mesh (bind) space -> the bone's own
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	body.collision_layer = LAYER
	body.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = friction
	body.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var local: Transform3D
	if spec.kind == "capsule":
		var a: Vector3 = bind * (spec.a as Vector3)
		var b: Vector3 = bind * (spec.b as Vector3)
		var cap := CapsuleShape3D.new()
		cap.radius = spec.r
		cap.height = (b - a).length() + float(spec.r)  # its round ends half over the slice's
		cs.shape = cap
		var y := (b - a).normalized()
		var xx := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
		local = Transform3D(Basis(xx, y, xx.cross(y)).orthonormalized(), (a + b) * 0.5)
		var cyl := maxf(cap.height * 0.5 - cap.radius, 0.0)  # (the shape's own line, for `through`)
		spec.a = Vector3(0, -cyl, 0)
		spec.b = Vector3(0, cyl, 0)
	else:
		var box := BoxShape3D.new()
		box.size = (spec.half as Vector3) * 2.0
		cs.shape = box
		local = bind * (spec.xf as Transform3D)
	body.add_child(cs)
	add_child(body)
	spec.body = body
	spec.bone = bi
	spec.local = local
	shapes.append(spec)


# --- Or his skin itself (a mesh shape posed each tick) ------------------------------------------

## The skin as a collision mesh: the glove's own points pulled back to just over his skin, skinned on the CPU each tick and handed to a concave shape. Closer than any set of
## rigid shapes (a skinned arm bends and bulges), at the cost of rebuilding it each tick the cloth is
## near (only while the handoff runs).
var skin_body: AnimatableBody3D
var skin_shape: ConcavePolygonShape3D
var _glove: RefCounted
var _inset := PackedVector3Array()
var _skin_on := false
var rebuild_us := 0


func use_skin(glove: RefCounted) -> void:
	_glove = glove
	_inset.resize(glove.verts.size())
	for i in glove.verts.size():
		var fing: String = glove.finger_of[i]
		var bn: String = skeleton.get_bone_name(glove.main_bone[i])
		var gap: float = glove.gap_fingers if (fing != "" or bn.begins_with("hand")) else glove.gap_arm
		# Just outside his skin (the glove's gap less 0.7 mm): the cloth's triangles are chords a
		# couple of cm across, and they'd cut under a curved skin the cloth's points only rest on.
		_inset[i] = glove.verts[i] - glove.normals[i] * maxf(gap - 0.0007, 0.0)
	skin_body = AnimatableBody3D.new()
	skin_body.name = "ArmSkin"
	skin_body.sync_to_physics = false
	skin_body.collision_layer = LAYER
	skin_body.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = friction
	skin_body.physics_material_override = pm
	var cs := CollisionShape3D.new()
	skin_shape = ConcavePolygonShape3D.new()
	skin_shape.backface_collision = true
	cs.shape = skin_shape
	skin_body.add_child(cs)
	add_child(skin_body)
	_skin_on = true
	for s: Dictionary in shapes:
		(s.body as CollisionObject3D).collision_layer = 0  # the skin takes their place
	_skin_step()


func _skin_step() -> void:
	var t0 := Time.get_ticks_usec()
	var pts: PackedVector3Array = _glove.posed_points(_inset)
	var faces := PackedVector3Array()
	var idx: PackedInt32Array = _glove.indices
	faces.resize(idx.size())
	for k in idx.size():
		faces[k] = pts[idx[k]]
	skin_shape.set_faces(faces)
	rebuild_us = Time.get_ticks_usec() - t0


## Nothing more to meet (the glove's off him): the skin shape and the fitted shapes out of the
## physics, nothing done a tick.
func off() -> void:
	_skin_on = false
	if skin_body:
		skin_body.collision_layer = 0
	for s: Dictionary in shapes:
		(s.body as CollisionObject3D).collision_layer = 0
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	var pt := Prof.start()
	follow()
	if _skin_on:
		_skin_step()
	Prof.stop(&"glove_arm", pt)


## Every shape to where his bone is now.
func follow() -> void:
	if skeleton == null:
		return
	var sx := skeleton.global_transform
	for bi: int in carriers:
		(carriers[bi] as Node3D).global_transform = sx * skeleton.get_bone_global_pose(bi)
	for s: Dictionary in shapes:
		(s.body as Node3D).global_transform = sx * skeleton.get_bone_global_pose(int(s.bone)) * (s.local as Transform3D)


## A node that goes where bone `bi` goes (made the first time it's asked for).
func carrier(bi: int) -> Node3D:
	if not carriers.has(bi):
		var n := Node3D.new()
		n.name = "Carry_" + skeleton.get_bone_name(bi)
		add_child(n)
		n.global_transform = skeleton.global_transform * skeleton.get_bone_global_pose(bi)
		carriers[bi] = n
	return carriers[bi]


## Which shape (its bone's name) each point of `pts` is inside, for the debug.
func inside_which(pts: PackedVector3Array, depth := 0.001) -> Dictionary:
	var out := {}
	for i in pts.size():
		for s: Dictionary in shapes:
			var q := (s.body as Node3D).global_transform.affine_inverse() * pts[i]
			var inside := false
			if s.kind == "capsule":
				var a: Vector3 = s.a
				var b: Vector3 = s.b
				var t := clampf((q - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
				inside = (q - (a + (b - a) * t)).length() < float(s.r) - depth
			else:
				var h: Vector3 = s.half
				inside = absf(q.x) < h.x - depth and absf(q.y) < h.y - depth and absf(q.z) < h.z - depth
			if inside:
				out[i] = skeleton.get_bone_name(int(s.bone))
				break
	return out


## How many of `pts` (world) are inside the arm: inside a shape by more than `depth` (m).
func through(pts: PackedVector3Array, depth := 0.001) -> int:
	var n := 0
	var inv: Array[Transform3D] = []
	for s: Dictionary in shapes:
		inv.append((s.body as Node3D).global_transform.affine_inverse())
	for p in pts:
		for k in shapes.size():
			var s: Dictionary = shapes[k]
			var q := inv[k] * p
			if s.kind == "capsule":
				var a: Vector3 = s.a
				var b: Vector3 = s.b
				var t := clampf((q - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
				if (q - (a + (b - a) * t)).length() < float(s.r) - depth:
					n += 1
					break
			else:
				var h: Vector3 = s.half
				if absf(q.x) < h.x - depth and absf(q.y) < h.y - depth and absf(q.z) < h.z - depth:
					n += 1
					break
	return n


## The shapes drawn (for the debug film): translucent.
func show_shapes(on: bool) -> void:
	for s: Dictionary in shapes:
		var body := s.body as Node3D
		for c in body.get_children():
			if c is MeshInstance3D:
				c.queue_free()
		if not on:
			continue
		var mi := MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.8, 0.3, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if s.kind == "capsule":
			var cm := CapsuleMesh.new()
			var cap := ((body.get_child(0) as CollisionShape3D).shape as CapsuleShape3D)
			cm.radius = cap.radius
			cm.height = cap.height
			mi.mesh = cm
		else:
			var bm := BoxMesh.new()
			bm.size = (s.half as Vector3) * 2.0
			mi.mesh = bm
		mi.material_override = mat
		body.add_child(mi)
