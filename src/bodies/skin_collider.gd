class_name SkinCollider
extends Node3D
## A man's skin under a garment as a collision shape (#917, from the garment lab's arm_colliders.gd,
## #895): the garment's own points pulled back to just over his skin, skinned on the CPU each tick
## and handed to a ConcavePolygonShape3D on a physics bit only garment cloth looks for (LAYER). The
## lab found rigid shapes inside the skin let 62 of the glove's 371 points through: a skinned arm
## bends at the elbow and wrist and isn't round, so the skin itself is the collider.
##
## Cost (#917): only the triangles near the free cloth are rebuilt (`near`), only the binds the
## garment uses are posed (a MetaHuman has hundreds), and it does nothing until `on` or after `off`.

## The physics bit garment cloth and this shape share (nothing else in the game uses it).
const LAYER := 1 << 12
## Just over his skin: the garment's gap less this (m). The cloth's triangles are chords a couple of
## cm across, and they'd cut under a curved skin the cloth's points only rest on.
const SKIN_PAD := 0.0007
## A triangle is rebuilt while one of its points is this near the free cloth's box (m).
const NEAR := 0.04
## Every point re-posed this often (ticks), in case his arm has moved what was far.
const FULL_EVERY := 12


var garment: WornGarment
var body: AnimatableBody3D
var shape: ConcavePolygonShape3D
var active := false
## Only the triangles near `free_box` (the handoff sets it each tick); all of them if false.
var near := true
## Rebuilt every this many ticks (his arm moves a mm a tick at most while it's drawn).
var every := 1
## The free cloth's box (world); empty: all of them.
var free_box := AABB()
## The last rebuild's time (µs) and triangles.
var rebuild_us := 0
var last_tris := 0

var _inset := PackedVector3Array()


func setup(g: WornGarment) -> void:
	garment = g
	var sk := g.skeleton
	_inset.resize(g.verts.size())
	for i in g.verts.size():
		var bn := sk.get_bone_name(g.main_bone[i])
		var gap := g.gap_fingers if (g.finger_of[i] != "" or bn.begins_with("hand")) else g.gap_arm
		var lift := g.relief[i] if g.relief.size() > i else 0.0
		_inset[i] = g.verts[i] - g.normals[i] * maxf(gap - SKIN_PAD - lift, 0.0)
	var lists: Array = []
	lists.resize(g.verts.size())
	for i in lists.size():
		lists[i] = PackedInt32Array()
	for t in g.indices.size() / 3:
		for k in 3:
			var i := g.indices[t * 3 + k]
			var got: PackedInt32Array = lists[i]
			got.append(t)
			lists[i] = got
	_tri_at.append(0)
	for l: PackedInt32Array in lists:
		_tri_of.append_array(l)
		_tri_at.append(_tri_of.size())
	body = AnimatableBody3D.new()
	body.name = "Skin"
	body.sync_to_physics = false
	body.collision_layer = 0
	body.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = 0.0
	body.physics_material_override = pm
	var cs := CollisionShape3D.new()
	shape = ConcavePolygonShape3D.new()
	shape.backface_collision = true
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


## On from now (the cloth's out): posed this tick.
func on() -> void:
	active = true
	body.collision_layer = LAYER
	step()


## Nothing more to meet (the garment's off him): out of the physics, nothing done a tick.
func off() -> void:
	active = false
	if body:
		body.collision_layer = 0
		shape.set_faces(PackedVector3Array())


## His skin where it's drawn now: the triangles near the free cloth (a point of theirs, where it was
## last posed, within NEAR of `free_box`; every point re-posed each FULL_EVERY ticks), or all of them.
## (Jolt rebuilds a concave shape in the world at ~1 µs a triangle: fewer is what makes it cheap.)
func step() -> void:
	if not active:
		return
	_tick += 1
	if every > 1 and _tick % every != 1 and _last.size() == _inset.size():
		rebuild_us = 0
		return
	var t0 := Time.get_ticks_usec()
	var idx: PackedInt32Array = garment.indices
	var all := not near or free_box.size == Vector3.ZERO or _last.size() != _inset.size() or _tick % FULL_EVERY == 0
	var pts: PackedVector3Array
	var faces := PackedVector3Array()
	if all:
		pts = garment.posed_points(_inset)
		_last = pts
		faces.resize(idx.size())
		for k in idx.size():
			faces[k] = pts[idx[k]]
	else:
		var box := free_box.grow(NEAR)
		var last := _last
		var tri_on := PackedByteArray()
		tri_on.resize(idx.size() / 3)
		var tri_of := _tri_of
		var tri_at := _tri_at
		var n := 0
		for i in last.size():
			if box.has_point(last[i]):
				for k in range(tri_at[i], tri_at[i + 1]):
					var t := tri_of[k]
					if tri_on[t] == 0:
						tri_on[t] = 1
						n += 1
		var pt_on := PackedByteArray()
		pt_on.resize(last.size())
		faces.resize(n * 3)
		for t in tri_on.size():
			if tri_on[t] == 1:
				pt_on[idx[t * 3]] = 1
				pt_on[idx[t * 3 + 1]] = 1
				pt_on[idx[t * 3 + 2]] = 1
		pts = garment.posed_points(_inset, pt_on)
		for i in last.size():
			if pt_on[i] == 1:
				last[i] = pts[i]
		_last = last
		var f := 0
		for t in tri_on.size():
			if tri_on[t] == 1:
				faces[f] = pts[idx[t * 3]]
				faces[f + 1] = pts[idx[t * 3 + 1]]
				faces[f + 2] = pts[idx[t * 3 + 2]]
				f += 3
	shape.set_faces(faces)
	last_tris = faces.size() / 3
	rebuild_us = Time.get_ticks_usec() - t0


var _last := PackedVector3Array()
var _tick := 0
var _tri_of := PackedInt32Array()   # each point's triangles, by _tri_at
var _tri_at := PackedInt32Array()   # where each point's start in _tri_of (size + 1)
