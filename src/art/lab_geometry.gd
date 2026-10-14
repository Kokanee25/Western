class_name LabGeometry
## The material lab's member meshes (art, 2026-10-14; docs/briefs/material-lab-timber.md): drawn over
## a built structure's own members, their collision, ids and physics untouched, so the lab can test
## what geometry adds to the new woods. Nothing in the game calls this.
##
## Every face carries a vertex colour: r 1 on a member's end faces (the cut ends: texel_grid's
## end_tex draws end grain there), 0 on its long faces; g 0 marks the mesh as flagged (a mesh with
## no colours reads white, so g 1 = "not flagged": never end grain by accident).
## `reshape`: the long edges chamfered (posts and beams more than planks; siding left square), and
## the boardwalk's planks made `plank_t` thick, their tops where they were, reaching `overhang` past
## their street ends, as rough-sawn period planks over a fascia.

## `build` (the timber pass's finish, Sean's notes of 2026-10-14: the planks' ends hidden by a
## broad pale fascia, the walk not reading as built from lumber): the boardwalk drawn as it would be
## built. Its sleepers (solid blocks to the ground in the game) as joists on edge on short pads;
## the fascia as a rim joist under the planks' overhang (`RIM_H` deep, `RIM_T` thick, its own wood),
## so the planks' cut ends stand clear above it; each plank's end a little off square and its
## overhang off its neighbours' (hand-cut); the steps as treads, a riser and stringers; two nails
## where each plank crosses a joist. Painted siding below `LOW_Y` takes its wood's "_low" boards
## (splashed and worn). Only what's drawn: collision, ids and the support graph are the game's.

## Chamfer a long edge by this much (m), by the member's wood.
const CHAMFER := {&"timber": 0.012, &"framing": 0.01, &"floor": 0.005}
const RIM_H := 0.2
const RIM_T := 0.045
const JOIST_W := 0.05
const PAD := Vector3(0.12, 0.0, 0.12)
const PAD_STEP := 1.2
const TREAD_T := 0.045
const LOW_Y := 1.0
static var _wind := 0.0


## Flag (and with `reshape`, chamfer and thicken) every member under root. Returns how many meshes.
static func apply(root: Node, reshape := false, plank_t := 0.045, overhang := 0.03, build := false) -> int:
	var n := 0
	var nails: Array[Transform3D] = []
	for m in root.find_children("*", "StructureMember", true, false):
		var mi: MeshInstance3D = null
		for c in m.get_children():
			if c is MeshInstance3D:
				mi = c
				break
		if mi == null:
			continue
		var size: Vector3 = m.size
		var shift := Vector3.ZERO
		var chamfer := 0.0
		if reshape:
			chamfer = float(CHAMFER.get(m.wood, 0.0))
			if m.kind == &"floor_board":
				# Thicker, downward (the walking surface stays), and out past the fascia at the
				# street end (-Z in the walk's space: the long axis is z).
				var dt := plank_t - size.y
				size.y = plank_t
				size.z += overhang
				shift = Vector3(0.0, -dt * 0.5, -overhang * 0.5)
		var walk: Node = m.get_parent()
		if build and walk != null and "walk_depth" in walk:
			var built := _walk_member(m, walk, plank_t, overhang, nails)
			if built != null:
				mi.mesh = built
				mi.visible = true
				n += 1
				continue
		if build and m.wood in [&"saloon_red", &"store_boards"] and m.kind == &"board" \
				and (m as Node3D).global_position.y - (root as Node3D).global_position.y < LOW_Y:
			var low := StringName(String(m.wood) + "_low")
			if load("res://src/structures/wood_materials.gd").strip_count(low) > 0:
				mi.material_override = load("res://src/structures/wood_materials.gd").get_material(low, hash(m.member_id))
		mi.mesh = box(size, chamfer, shift)
		# Shown again: a batched member's own mesh is hidden, and the batches are built only from
		# visible ones (Structure._batch_all hides them again).
		mi.visible = true
		n += 1
	# A structure draws its members through batches built from their meshes (Structure: one a
	# material); rebuilt from the new ones.
	for s in root.find_children("*", "Structure", true, false):
		if s.has_method("_batch_all"):
			s.call("_batch_all")
	if not nails.is_empty():
		_nails(root, nails)
	return n


## A boardwalk's member as built (`build`), in its own space; null for a member drawn as usual.
static func _walk_member(m: Node, walk: Node, plank_t: float, overhang: float, nails: Array[Transform3D]) -> ArrayMesh:
	var id := String(m.member_id).get_slice("/", 1)
	var wd: float = walk.walk_depth
	var top: float = walk.top
	var at: Vector3 = (m as Node3D).position
	var size: Vector3 = m.size
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(m.member_id)
	var under := top - plank_t
	# The rim joist's street face: against the outer joist's face (the outer sleeper's centre line).
	var outer_z := -wd + 0.08 - JOIST_W * 0.5
	var rim_face := outer_z - RIM_T
	var arrays := _arrays()
	if id == "fascia":
		_add_box(arrays, Vector3(size.x, RIM_H, RIM_T), 0.0, Vector3(0.0, under - RIM_H * 0.5, outer_z - RIM_T * 0.5) - at)
		var wm = load("res://src/structures/wood_materials.gd")
		if wm.strip_count(&"fascia") > 0:
			for c in m.get_children():
				if c is MeshInstance3D:
					c.material_override = wm.get_material(&"fascia", hash(m.member_id))
		return _mesh(arrays)
	if id.begins_with("sleeper"):
		# A joist on edge under the planks, on pads at the ends and every PAD_STEP between.
		var jh := RIM_H
		_add_box(arrays, Vector3(size.x, jh, JOIST_W), CHAMFER[&"framing"] * 0.5, Vector3(0.0, under - jh * 0.5 - at.y, 0.0))
		var pad_h := under - jh
		var k := maxi(1, ceili(size.x / PAD_STEP))
		for i in k + 1:
			var px := -size.x * 0.5 + PAD.x * 0.5 + (size.x - PAD.x) * float(i) / k
			_add_box(arrays, Vector3(PAD.x, pad_h, PAD.z), 0.0, Vector3(px, pad_h * 0.5 - at.y, 0.0))
		return _mesh(arrays)
	if id.begins_with("plank"):
		# Thicker downward, the top a hair up or down; out past the rim by `overhang`, give or take,
		# its street end a little off square.
		var street_end := at.z - size.z * 0.5
		var target := rim_face - overhang + rng.randf_range(-0.008, 0.008)
		var ext := street_end - target
		var s2 := Vector3(size.x, plank_t, size.z + ext)
		var top_y := size.y * 0.5 + rng.randf_range(-0.0015, 0.0015)
		var shift := Vector3(0.0, top_y - plank_t * 0.5, -ext * 0.5)
		_add_box(arrays, s2, CHAMFER[&"floor"], shift, rng.randf_range(-0.005, 0.005))
		# Two cut nails where it crosses each joist (the sleepers' lines).
		var wt: Transform3D = (walk as Node3D).global_transform
		for jz in [-wd + 0.08, -wd * 0.5, -0.1]:
			for side in [-1.0, 1.0]:
				var p := Vector3(at.x + side * (size.x * 0.5 - 0.035), at.y + top_y + 0.0008, jz + rng.randf_range(-0.006, 0.006))
				nails.append(Transform3D(wt.basis * Basis(Vector3.UP, rng.randf_range(0.0, 1.5)), wt * p))
		return _mesh(arrays)
	if id.begins_with("step/"):
		# A tread (two boards, a nosing out front), a riser under its nose and two stringers.
		var h := size.y
		var d := size.z
		var w := size.x
		var nose := 0.025
		var bd := (d + nose - 0.006) * 0.5
		for b in 2:
			var zc := d * 0.5 - bd * 0.5 - b * (bd + 0.006)
			_add_box(arrays, Vector3(w, TREAD_T, bd), CHAMFER[&"floor"], Vector3(0.0, h * 0.5 - TREAD_T * 0.5, zc))
		_add_box(arrays, Vector3(w - 0.01, h - TREAD_T, 0.025), 0.0, Vector3(0.0, -TREAD_T * 0.5, -d * 0.5 + 0.0125))
		for side in [-1.0, 1.0]:
			_add_box(arrays, Vector3(0.045, h - TREAD_T, d - 0.03), 0.0,
					Vector3(side * (w * 0.5 - 0.0225), -TREAD_T * 0.5, 0.015))
		return _mesh(arrays)
	return null


## The nails: one multimesh (a draw), dark iron heads a centimetre square.
static func _nails(root: Node, at: Array[Transform3D]) -> void:
	var head := BoxMesh.new()
	head.size = Vector3(0.011, 0.002, 0.011)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.115, 0.1)
	mat.roughness = 0.6
	mat.metallic = 0.3
	head.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = head
	mm.instance_count = at.size()
	for i in at.size():
		mm.set_instance_transform(i, at[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "LabNails"
	mmi.multimesh = mm
	mmi.top_level = true
	root.add_child(mmi)
	mmi.global_transform = Transform3D.IDENTITY


## A box `size` (centred, moved by `shift`), its four long edges chamfered by `c`, UVs in metres with
## u along the long axis (MemberMesh's convention), UV2 the face's size, the end flag in COLOR.
static func box(size: Vector3, c := 0.0, shift := Vector3.ZERO, skew := 0.0) -> ArrayMesh:
	var arrays := _arrays()
	_add_box(arrays, size, c, shift, skew)
	return _mesh(arrays)


## Vertex, normal, uv, uv2, colour: what _add_box appends to and _mesh builds a mesh from.
static func _arrays() -> Array:
	return [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(), PackedVector2Array(), PackedColorArray()]


static func _mesh(a: Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = a[0]
	arrays[Mesh.ARRAY_NORMAL] = a[1]
	arrays[Mesh.ARRAY_TEX_UV] = a[2]
	arrays[Mesh.ARRAY_TEX_UV2] = a[3]
	arrays[Mesh.ARRAY_COLOR] = a[4]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Appends a box (as `box`) to `a`; `skew` moves its -long-axis end's corners along the long axis
## by up to that much across its width (an end cut off square).
static func _add_box(a: Array, size: Vector3, c := 0.0, shift := Vector3.ZERO, skew := 0.0) -> void:
	if _wind == 0.0:
		_wind = _box_winding()
	var la := 0
	for ax in 3:
		if size[ax] > size[la]:
			la = ax
	var xa := (la + 1) % 3
	var ya := (la + 2) % 3
	var L := size[la]
	var A := size[xa]
	var B := size[ya]
	c = minf(c, minf(A, B) * 0.3)
	# The cross-section, round its outline (corners cut by c).
	var poly: Array[Vector2] = []
	if c > 0.0:
		poly = [Vector2(-A / 2 + c, -B / 2), Vector2(A / 2 - c, -B / 2), Vector2(A / 2, -B / 2 + c), Vector2(A / 2, B / 2 - c),
				Vector2(A / 2 - c, B / 2), Vector2(-A / 2 + c, B / 2), Vector2(-A / 2, B / 2 - c), Vector2(-A / 2, -B / 2 + c)]
	else:
		poly = [Vector2(-A / 2, -B / 2), Vector2(A / 2, -B / 2), Vector2(A / 2, B / 2), Vector2(-A / 2, B / 2)]
	var v: PackedVector3Array = a[0]
	var nr: PackedVector3Array = a[1]
	var uv: PackedVector2Array = a[2]
	var uv2: PackedVector2Array = a[3]
	var col: PackedColorArray = a[4]
	var to3 := func(l: float, p: Vector2) -> Vector3:
		var r := Vector3.ZERO
		r[la] = l + (skew * p.x / maxf(A, 1e-4) if l < 0.0 else 0.0)
		r[xa] = p.x
		r[ya] = p.y
		return r + shift
	# Long faces: one quad an outline edge, u along the length, v along the edge.
	var vstart := 0.0
	for i in poly.size():
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[(i + 1) % poly.size()]
		var e := p1 - p0
		var el := e.length()
		var n2 := Vector2(e.y, -e.x).normalized()
		if n2.dot((p0 + p1) * 0.5) < 0.0:
			n2 = -n2
		var nn: Vector3 = to3.call(0.0, n2) - shift
		var q := [to3.call(-L / 2, p0), to3.call(L / 2, p0), to3.call(L / 2, p1), to3.call(-L / 2, p1)]
		var quv := [Vector2(0, 0), Vector2(L, 0), Vector2(L, el), Vector2(0, el)]
		_quad(v, nr, uv, uv2, col, q, quv, nn, Vector2(L, el), Color(0, 0, 0, 1))
		vstart += el
	# The two ends: the outline as a fan, u along the end's larger side.
	for s in [-1.0, 1.0]:
		var nn: Vector3 = Vector3.ZERO
		nn[la] = s
		var centre: Vector3 = to3.call(s * L / 2, Vector2.ZERO)
		var big_x := A >= B
		var esize := Vector2(maxf(A, B), minf(A, B))
		for i in poly.size():
			var p0: Vector2 = poly[i]
			var p1: Vector2 = poly[(i + 1) % poly.size()]
			var pts := [centre, to3.call(s * L / 2, p0), to3.call(s * L / 2, p1)]
			var uvs := [Vector2(A / 2, B / 2), p0 + Vector2(A / 2, B / 2), p1 + Vector2(A / 2, B / 2)]
			if not big_x:
				uvs = [Vector2(B / 2, A / 2), Vector2(p0.y + B / 2, p0.x + A / 2), Vector2(p1.y + B / 2, p1.x + A / 2)]
			_tri(v, nr, uv, uv2, col, pts, uvs, nn, esize, Color(1, 0, 0, 1))
	a[0] = v
	a[1] = nr
	a[2] = uv
	a[3] = uv2
	a[4] = col


static func _quad(v, nr, uv, uv2, col, q: Array, quv: Array, n: Vector3, fs: Vector2, c: Color) -> void:
	_tri(v, nr, uv, uv2, col, [q[0], q[1], q[2]], [quv[0], quv[1], quv[2]], n, fs, c)
	_tri(v, nr, uv, uv2, col, [q[0], q[2], q[3]], [quv[0], quv[2], quv[3]], n, fs, c)


static func _tri(v, nr, uv, uv2, col, p: Array, t: Array, n: Vector3, fs: Vector2, c: Color) -> void:
	# The engine's front-face winding, as its own BoxMesh has it.
	var order := [0, 1, 2]
	if ((p[1] - p[0]) as Vector3).cross(p[2] - p[0]).dot(n) * _wind < 0.0:
		order = [0, 2, 1]
	for k in order:
		v.append(p[k])
		nr.append(n)
		uv.append(t[k])
		uv2.append(fs)
		col.append(c)


## +1 or -1: the sign of (b - a) x (c - a) . normal on a BoxMesh's front faces.
static func _box_winding() -> float:
	var arr := BoxMesh.new().get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var a := vs[idx[0]]
	var b := vs[idx[1]]
	var c := vs[idx[2]]
	return signf((b - a).cross(c - a).dot(ns[idx[0]]))
