class_name Profiles
## The interior woodwork's profiles (Sean 2026-10-21, his saloon picture; docs/briefs/interior-woodwork.md):
## the cross-sections a board is run along (MaterialStand._profiled), as data so the stand, the
## saloon's builder and gameplay's railing draw with the same shapes. A profile is an Array of runs,
## each a PackedVector2Array of points in the board's section (x across its width, y up its
## thickness, both centred on the board's axis), counter-clockwise round the outline: shaded smooth
## within a run, a hard edge where one run meets the next (each run starts where the last ended, the
## last ends where the first starts). Sizes in metres. Shapes from the usual period joinery (chamfer,
## bead, bullnose, ogee, the moulded handrail); sizes per piece are the brief's.

const ARC_STEPS := 6


## A plain rectangle.
static func rect(w: float, t: float) -> Array:
	var a := Vector2(-w * 0.5, -t * 0.5)
	var b := Vector2(w * 0.5, -t * 0.5)
	var c := Vector2(w * 0.5, t * 0.5)
	var d := Vector2(-w * 0.5, t * 0.5)
	return [PackedVector2Array([a, b]), PackedVector2Array([b, c]), PackedVector2Array([c, d]), PackedVector2Array([d, a])]


## Square stock with its four arrises chamfered `c` at 45 degrees (posts, beams): eight flat faces.
static func chamfered(w: float, t: float, c: float) -> Array:
	var hw := w * 0.5
	var ht := t * 0.5
	var pts := [Vector2(-hw + c, -ht), Vector2(hw - c, -ht), Vector2(hw, -ht + c), Vector2(hw, ht - c), Vector2(hw - c, ht),
			Vector2(-hw + c, ht), Vector2(-hw, ht - c), Vector2(-hw, -ht + c)]
	return _loop(pts)


## Square stock with the chosen corners rounded `r` (0 bottom-right, 1 top-right, 2 top-left,
## 3 bottom-left): a worn or eased arris, a bar top's edge.
static func rounded(w: float, t: float, r: float, corners := [1, 2]) -> Array:
	var hw := w * 0.5
	var ht := t * 0.5
	var runs := []
	var centres := [Vector2(hw - r, -ht + r), Vector2(hw - r, ht - r), Vector2(-hw + r, ht - r), Vector2(-hw + r, -ht + r)]
	var sharp := [Vector2(hw, -ht), Vector2(hw, ht), Vector2(-hw, ht), Vector2(-hw, -ht)]
	# Walk the four corners counter-clockwise from the bottom-right; each corner is a point or an arc.
	var outline := []
	for k in 4:
		if corners.has(k):
			var arc := PackedVector2Array()
			var a0 := -PI * 0.5 + k * PI * 0.5
			for i in ARC_STEPS + 1:
				var a := a0 + PI * 0.5 * float(i) / ARC_STEPS
				arc.append(centres[k] + Vector2(cos(a), sin(a)) * r)
			outline.append(arc)
		else:
			outline.append(PackedVector2Array([sharp[k]]))
	for k in 4:
		var cur: PackedVector2Array = outline[k]
		var nxt: PackedVector2Array = outline[(k + 1) % 4]
		if cur.size() > 1:
			runs.append(cur)
		runs.append(PackedVector2Array([cur[cur.size() - 1], nxt[0]]))
	return runs


## A bar top: flat top and bottom, its front (+x) a full bullnose of half its thickness, the back
## edge eased.
static func bar_top(w: float, t: float) -> Array:
	var hw := w * 0.5
	var ht := t * 0.5
	var r := ht
	var nose := PackedVector2Array()
	for i in ARC_STEPS * 2 + 1:
		var a := -PI * 0.5 + PI * float(i) / (ARC_STEPS * 2)
		nose.append(Vector2(hw - r + cos(a) * r, sin(a) * r))
	var e := 0.006
	return [PackedVector2Array([Vector2(-hw + e, -ht), Vector2(hw - r, -ht)]), nose,
			PackedVector2Array([Vector2(hw - r, ht), Vector2(-hw + e, ht)]),
			PackedVector2Array([Vector2(-hw + e, ht), Vector2(-hw, ht - e)]),
			PackedVector2Array([Vector2(-hw, ht - e), Vector2(-hw, -ht + e)]),
			PackedVector2Array([Vector2(-hw, -ht + e), Vector2(-hw + e, -ht)])]


## The gallery's moulded handrail: a flat underside the balusters meet, the sides stepping in at a
## small groove and rising into a broad rounded top (the period "toad's back").
static func handrail(w: float, t: float) -> Array:
	var hw := w * 0.5
	var ht := t * 0.5
	var foot := hw * 0.62
	var side := PackedVector2Array([Vector2(foot, -ht), Vector2(foot, -ht + t * 0.18)])
	var groove := PackedVector2Array([Vector2(foot, -ht + t * 0.18), Vector2(foot * 0.88, -ht + t * 0.26), Vector2(hw * 0.9, -ht + t * 0.36),
			Vector2(hw, -ht + t * 0.48)])
	var top := PackedVector2Array()
	var y0 := -ht + t * 0.48
	for i in ARC_STEPS * 2 + 1:
		var a := PI * float(i) / (ARC_STEPS * 2)
		top.append(Vector2(cos(a) * hw, y0 + sin(a) * (ht - y0)))
	var groove_l := PackedVector2Array()
	for i in range(groove.size() - 1, -1, -1):
		groove_l.append(Vector2(-groove[i].x, groove[i].y))
	return [PackedVector2Array([Vector2(-foot, -ht), Vector2(foot, -ht)]), side, groove, top, groove_l,
			PackedVector2Array([Vector2(-foot, -ht + t * 0.18), Vector2(-foot, -ht)])]


## A cap or cornice moulding: its back (-x) and bottom flat, its face an ogee (a cyma: hollow
## below, round above) rising to a small fillet on top; for the wainscot's cap rail, the back
## bar's cornice, the casings' heads.
static func ogee(w: float, t: float) -> Array:
	var hw := w * 0.5
	var ht := t * 0.5
	var curve := PackedVector2Array()
	# From the bottom front, an S: the cove (hollow) then the round, out to the full width.
	var x0 := -hw + w * 0.35
	var y0 := -ht + t * 0.12
	var fil := t * 0.12
	for i in ARC_STEPS * 2 + 1:
		var s := float(i) / (ARC_STEPS * 2)
		var x := x0 + (hw - x0) * (0.5 - 0.5 * cos(PI * s))
		var y := y0 + (ht - fil - y0) * s
		x += (hw - x0) * 0.18 * sin(TAU * s)
		curve.append(Vector2(minf(x, hw), y))
	curve[curve.size() - 1] = Vector2(hw, ht - fil)
	return [PackedVector2Array([Vector2(-hw, -ht), Vector2(x0, -ht)]), PackedVector2Array([Vector2(x0, -ht), Vector2(x0, y0)]), curve,
			PackedVector2Array([Vector2(hw, ht - fil), Vector2(hw, ht)]), PackedVector2Array([Vector2(hw, ht), Vector2(-hw, ht)]),
			PackedVector2Array([Vector2(-hw, ht), Vector2(-hw, -ht)])]


## Board with a bead run along one face's edge (+y face, at +x): casings, wainscot stiles.
static func beaded(w: float, t: float, r: float) -> Array:
	var hw := w * 0.5
	var ht := t * 0.5
	var bead := PackedVector2Array()
	for i in ARC_STEPS + 1:
		var a := -PI * 0.5 + PI * float(i) / ARC_STEPS
		bead.append(Vector2(hw - r + cos(a) * r, ht - r + sin(a) * r))
	# The quirk: a small groove where the bead meets the board's face.
	var q := Vector2(hw - r * 2.0, ht)
	return [PackedVector2Array([Vector2(-hw, -ht), Vector2(hw, -ht)]), PackedVector2Array([Vector2(hw, -ht), bead[0]]), bead,
			PackedVector2Array([bead[bead.size() - 1], Vector2(hw - r, ht - r * 0.6), q]), PackedVector2Array([q, Vector2(-hw, ht)]),
			PackedVector2Array([Vector2(-hw, ht), Vector2(-hw, -ht)])]


## A profile's whole outline (each run's points once), counter-clockwise.
static func outline(runs: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for run in runs:
		var r: PackedVector2Array = run
		for i in r.size() - 1:
			out.append(r[i])
	return out


## Its bounds (width and thickness it really takes up).
static func size_of(runs: Array) -> Vector2:
	var o := outline(runs)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in o:
		lo = lo.min(p)
		hi = hi.max(p)
	return hi - lo


## Closed polygon as one flat run per side (every edge hard).
static func _loop(pts: Array) -> Array:
	var runs := []
	for i in pts.size():
		runs.append(PackedVector2Array([pts[i], pts[(i + 1) % pts.size()]]))
	return runs


## --- The shapes as triangles (one place for the lab's stands and the prop kit's draw shapes) ---
## Each triangle: [p0, p1, p2, n0, n1, n2, uv0, uv1, uv2, face size (UV2), flag colour], in the
## shape's own frame; `emit` and `to_mesh` lay them where they go, wound to face their normals.
## Flags as every board's (texel_grid): COLOR (0, 0, u0 / 2) a long face starting u0 along its
## strip, (1, 0, 0) a cut end in end grain.

## A profile run `length` along x (centred), its section's x along y and its y along z.
static func extrude_tris(runs: Array, length: float, u0: float) -> Array:
	var out := []
	var flag := Color(0.0, 0.0, u0 * 0.5, 1.0)
	var endf := Color(1.0, 0.0, 0.0, 1.0)
	var at := func(x: float, q: Vector2) -> Vector3: return Vector3(x, q.x, q.y)
	for run in runs:
		var r: PackedVector2Array = run
		var segs := PackedVector2Array()
		for i in r.size() - 1:
			var d := r[i + 1] - r[i]
			segs.append(Vector2(d.y, -d.x).normalized())
		var norms := []
		for i in r.size():
			var a := segs[maxi(i - 1, 0)]
			var b := segs[mini(i, segs.size() - 1)]
			var nn := (a + b).normalized()
			norms.append(Vector3(0.0, nn.x, nn.y))
		var total := 0.0
		for i in r.size() - 1:
			total += r[i].distance_to(r[i + 1])
		var size := Vector2(length, total)
		var v := 0.0
		var x0 := -length * 0.5
		var x1 := length * 0.5
		for i in r.size() - 1:
			var v1 := v + r[i].distance_to(r[i + 1])
			var p00: Vector3 = at.call(x0, r[i])
			var p10: Vector3 = at.call(x1, r[i])
			var p01: Vector3 = at.call(x0, r[i + 1])
			var p11: Vector3 = at.call(x1, r[i + 1])
			out.append([p00, p10, p11, norms[i], norms[i], norms[i + 1],
					Vector2(u0, v), Vector2(u0 + length, v), Vector2(u0 + length, v1), size, flag])
			out.append([p00, p11, p01, norms[i], norms[i + 1], norms[i + 1],
					Vector2(u0, v), Vector2(u0 + length, v1), Vector2(u0, v1), size, flag])
			v = v1
	var ring := outline(runs)
	var idx := Geometry2D.triangulate_polygon(ring)
	var sz := size_of(runs)
	var half := sz * 0.5
	for e in [[-length * 0.5, Vector3(-1, 0, 0)], [length * 0.5, Vector3(1, 0, 0)]]:
		for k in range(0, idx.size(), 3):
			var q := [ring[idx[k]], ring[idx[k + 1]], ring[idx[k + 2]]]
			out.append([at.call(e[0], q[0]), at.call(e[0], q[1]), at.call(e[0], q[2]), e[1], e[1], e[1],
					q[0] + half, q[1] + half, q[2] + half, sz, endf])
	return out


## A raised panel w (x) by h (y), its field standing t proud (z) and bevelled down over `bevel` to
## its edges (left at 35% of t), grain up the panel (u along y).
static func panel_tris(w: float, h: float, t: float, bevel: float, u0: float) -> Array:
	var out := []
	var flag := Color(0.0, 0.0, u0 * 0.5, 1.0)
	var e := t * 0.35
	var hw := w * 0.5
	var hh := h * 0.5
	var iw := hw - bevel
	var ih := hh - bevel
	var uv := func(x: float, y: float) -> Vector2: return Vector2(u0 + y + hh, x + hw)
	var size := Vector2(h, w)
	var z := Vector3(0, 0, 1)
	var f := [Vector3(-iw, -ih, t), Vector3(iw, -ih, t), Vector3(iw, ih, t), Vector3(-iw, ih, t)]
	out.append([f[0], f[1], f[2], z, z, z, uv.call(-iw, -ih), uv.call(iw, -ih), uv.call(iw, ih), size, flag])
	out.append([f[0], f[2], f[3], z, z, z, uv.call(-iw, -ih), uv.call(iw, ih), uv.call(-iw, ih), size, flag])
	var o := [Vector3(-hw, -hh, e), Vector3(hw, -hh, e), Vector3(hw, hh, e), Vector3(-hw, hh, e)]
	for k in 4:
		var k1 := (k + 1) % 4
		var n: Vector3 = ((o[k] - f[k]) as Vector3).cross(o[k1] - f[k]).normalized()
		if n.z < 0.0:
			n = -n
		out.append([o[k], o[k1], f[k1], n, n, n, uv.call(o[k].x, o[k].y), uv.call(o[k1].x, o[k1].y), uv.call(f[k1].x, f[k1].y), size, flag])
		out.append([o[k], f[k1], f[k], n, n, n, uv.call(o[k].x, o[k].y), uv.call(f[k1].x, f[k1].y), uv.call(f[k].x, f[k].y), size, flag])
		# Its edge, down to the back.
		var b0 := Vector3(o[k].x, o[k].y, 0.0)
		var b1 := Vector3(o[k1].x, o[k1].y, 0.0)
		var en := Vector3(n.x, n.y, 0.0).normalized()
		var el: float = ((o[k1] as Vector3) - (o[k] as Vector3)).length()
		out.append([b0, b1, o[k1], en, en, en, Vector2(u0, 0), Vector2(u0 + el, 0), Vector2(u0 + el, e), Vector2(el, e), flag])
		out.append([b0, o[k1], o[k], en, en, en, Vector2(u0, 0), Vector2(u0 + el, e), Vector2(u0, e), Vector2(el, e), flag])
	return out


## A board cut to `outline` (x, y), t thick along z (centred), its faces and cut edges long grain
## along x.
static func cut_tris(shape: PackedVector2Array, t: float, u0: float) -> Array:
	var out := []
	var flag := Color(0.0, 0.0, u0 * 0.5, 1.0)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in shape:
		lo = lo.min(q)
		hi = hi.max(q)
	var size := hi - lo
	var uv := func(q: Vector2) -> Vector2: return Vector2(u0 + q.x - lo.x, q.y - lo.y)
	var idx := Geometry2D.triangulate_polygon(shape)
	for side in [[t * 0.5, Vector3(0, 0, 1)], [-t * 0.5, Vector3(0, 0, -1)]]:
		for k in range(0, idx.size(), 3):
			var q := [shape[idx[k]], shape[idx[k + 1]], shape[idx[k + 2]]]
			out.append([Vector3(q[0].x, q[0].y, side[0]), Vector3(q[1].x, q[1].y, side[0]), Vector3(q[2].x, q[2].y, side[0]),
					side[1], side[1], side[1], uv.call(q[0]), uv.call(q[1]), uv.call(q[2]), size, flag])
	var total := 0.0
	for i in shape.size():
		total += shape[i].distance_to(shape[(i + 1) % shape.size()])
	var v := 0.0
	var ccw := not Geometry2D.is_polygon_clockwise(shape)
	for i in shape.size():
		var a := shape[i]
		var b := shape[(i + 1) % shape.size()]
		var d := b - a
		var e2 := Vector2(d.y, -d.x).normalized() * (1.0 if ccw else -1.0)
		var en := Vector3(e2.x, e2.y, 0.0)
		var v1 := v + d.length()
		var a0 := Vector3(a.x, a.y, -t * 0.5)
		var a1 := Vector3(a.x, a.y, t * 0.5)
		var b0 := Vector3(b.x, b.y, -t * 0.5)
		var b1 := Vector3(b.x, b.y, t * 0.5)
		out.append([a0, b0, b1, en, en, en, Vector2(u0 + v, 0), Vector2(u0 + v1, 0), Vector2(u0 + v1, t), Vector2(total, t), flag])
		out.append([a0, b1, a1, en, en, en, Vector2(u0 + v, 0), Vector2(u0 + v1, t), Vector2(u0 + v, t), Vector2(total, t), flag])
		v = v1
	return out


## Triangles into a mesh, moved by `xf` (normals by its basis), each wound to face its normals;
## indexed (a structure's batch keeps the first mesh's indices: PropKit.draw_mesh).
static func to_mesh(tris: Array, xf := Transform3D.IDENTITY) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nb := xf.basis.inverse().transposed()
	for tr in tris:
		var p := [xf * (tr[0] as Vector3), xf * (tr[1] as Vector3), xf * (tr[2] as Vector3)]
		var n := [(nb * (tr[3] as Vector3)).normalized(), (nb * (tr[4] as Vector3)).normalized(), (nb * (tr[5] as Vector3)).normalized()]
		var order := [0, 1, 2]
		if ((p[1] - p[0]) as Vector3).cross(p[2] - p[0]).dot(n[0] + n[1] + n[2]) > 0.0:
			order = [0, 2, 1]
		for i in order:
			st.set_color(tr[10])
			st.set_normal(n[i])
			st.set_uv(tr[6 + i])
			st.set_uv2(tr[9])
			st.add_vertex(p[i])
	st.index()
	return st.commit()


## A profile by its name and numbers (the prop kit's data: [width, thickness, then its own]).
static func by_name(name: String, a: Array) -> Array:
	match name:
		"rect":
			return rect(a[0], a[1])
		"chamfered":
			return chamfered(a[0], a[1], a[2] if a.size() > 2 else 0.006)
		"rounded":
			return rounded(a[0], a[1], a[2] if a.size() > 2 else 0.008, a[3] if a.size() > 3 else [1, 2])
		"bar_top":
			return bar_top(a[0], a[1])
		"handrail":
			return handrail(a[0], a[1])
		"ogee":
			return ogee(a[0], a[1])
		"beaded":
			return beaded(a[0], a[1], a[2] if a.size() > 2 else 0.006)
	push_warning("Profiles: no profile %s" % name)
	return rect(a[0], a[1])
