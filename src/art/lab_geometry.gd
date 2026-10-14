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

## Chamfer a long edge by this much (m), by the member's wood.
const CHAMFER := {&"timber": 0.012, &"framing": 0.01, &"floor": 0.005}
static var _wind := 0.0


## Flag (and with `reshape`, chamfer and thicken) every member under root. Returns how many meshes.
static func apply(root: Node, reshape := false, plank_t := 0.045, overhang := 0.03) -> int:
	var n := 0
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
	return n


## A box `size` (centred, moved by `shift`), its four long edges chamfered by `c`, UVs in metres with
## u along the long axis (MemberMesh's convention), UV2 the face's size, the end flag in COLOR.
static func box(size: Vector3, c := 0.0, shift := Vector3.ZERO) -> ArrayMesh:
	if _wind == 0.0:
		_wind = _box_winding()
	var la := 0
	for a in 3:
		if size[a] > size[la]:
			la = a
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
	var v := PackedVector3Array()
	var nr := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var col := PackedColorArray()
	var to3 := func(l: float, p: Vector2) -> Vector3:
		var r := Vector3.ZERO
		r[la] = l
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
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = nr
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_COLOR] = col
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


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
