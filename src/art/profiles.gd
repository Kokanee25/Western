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
