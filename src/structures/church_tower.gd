class_name ChurchTower
extends RefCounted
## The church's bell tower and what a plain frame building lacks for one (#1142, the building lab):
## a tower standing against the nave's gable front over its porch (the spec's `tower`), built as parts
## of the same Structure: its footing, sills and floor (`foundation`, `floor`); its three outer walls
## are ordinary spec walls (`walls`, a numeric `top`); then the belfry floor on joists, plates and
## corner posts, louvres, the bell beams, the pent skirt roof, the pyramidal spire of shingle courses on
## hip and common rafters with an iron finial (`belfry`); the windows' pointed heads are SashWindow's
## (`rise`). All of it members, so a ball breaks it and a lost post drops
## what it carried. SpecBuilding calls these two places in `build`; nothing else of it changed.
##
## The spec's `tower`: {x: [x0, x1], z: z of its front face, belfry_floor, belfry_top, spire: height,
## post, louvre: {from, to, slat, step, gap: [x0, x1, y0, y1] on the front}, finial, shingle: step}.
## Shingle courses stepped up a pyramid instead of a bent sheet: the Structure's members are boxes.

const PLATE := 0.1
const SKIN := 0.03
const STUD_D := 0.1

var b  # the SpecBuilding
var t: Dictionary
var x0: float
var x1: float
var z0: float


func _init(building: Node, tower: Dictionary) -> void:
	b = building
	t = tower
	x0 = float(t.x[0])
	x1 = float(t.x[1])
	z0 = float(t.z)


## Its footing and sills under the walls the spec gives it (its back is the nave's front wall).
func foundation() -> void:
	var f: Dictionary = b._fr.foundation
	var th := float(f.thick)
	var top := float(f.top)
	b.band = 0
	for run in [["front", Vector2(x0, z0), Vector2(x1, z0)], ["west", Vector2(x0, z0 + th), Vector2(x0, 0.0)],
			["east", Vector2(x1 - th, z0 + th), Vector2(x1 - th, 0.0)]]:
		b._stone_run("tower/foundation/%s" % run[0], run[1], run[2], th, top, [], float(f.bottom))
	var sill: Array = b._fr.sill.section
	var sw := float(sill[0])
	var sy := top + float(sill[1]) * 0.5
	var sec := Vector2(sill[1], sill[0])
	b._pieces("tower/sill/front", Vector3(x0, sy, z0 + sw * 0.5), Vector3.RIGHT, x1 - x0, sec, &"sill", &"framing")
	b._pieces("tower/sill/west", Vector3(x0 + sw * 0.5, sy, z0 + sw), Vector3.BACK, -z0 - sw, sec, &"sill", &"framing")
	b._pieces("tower/sill/east", Vector3(x1 - sw * 0.5, sy, z0 + sw), Vector3.BACK, -z0 - sw, sec, &"sill", &"framing")


## The porch floor: joists front to back, boards across (the lean-to's floor, a part).
func floor() -> void:
	b.band = 1
	b._floor({"id": "tower", "level": "ground", "rect": [x0 + STUD_D, z0 + 0.03, x1 - STUD_D, STUD_D], "joists": "z",
			"look": "wood:int_floor"}, [])


## The belfry, the louvres, the bell frame, the skirt roof, the spire and its finial.
func belfry() -> void:
	var fy := float(t.belfry_floor)
	var ty := float(t.belfry_top)
	var post := float(t.get("post", 0.15))
	var cx := (x0 + x1) * 0.5
	var cz := z0 + (-z0) * 0.5
	var w := x1 - x0
	# The plates on the walls' tops (a numeric `top` leaves the studs bare), carrying the floor.
	b.band = 1
	var walls_in_order: Array = []
	for id: String in ["tower_front", "tower_w", "tower_e"]:
		if b.walls.has(id):
			walls_in_order.append(b.walls[id].dict)
	for wd: Dictionary in walls_in_order:
		b._wall_member("%s/plate" % wd.name, &"plate", &"framing", wd, wd.x_start, wd.x_end, fy - PLATE, fy, -STUD_D, 0.0)
	# Joists across the tower between the east and west plates, boards over them, the hatch left open.
	b.band = 2
	var jh := 0.235
	var jzs: Array[float] = []
	var jn := ceili((-0.13 - (z0 + 0.13)) / 0.5)
	for i in jn + 1:
		jzs.append(lerpf(z0 + 0.13, -0.13, float(i) / float(jn)))
	# The ladder's hatch (x, z), between two joists by the nave's front wall (the second gap from it).
	var hatch := Rect2(cx + 0.62, jzs[jn - 2] + 0.04, 0.6, jzs[jn - 1] - jzs[jn - 2] - 0.08)
	var k := 0
	for z in jzs:
		b.add_member("tower/belfry/joist_%d" % k, &"joist", &"framing", Vector3(x1 - x0 - 0.06, jh, 0.05), Vector3(cx, fy + jh * 0.5, z))
		k += 1
	# Boards along z across the joists, the hatch left open.
	var bx := x0 + 0.1
	k = 0
	while bx < x1 - 0.1:
		var bw := minf(0.15, x1 - 0.1 - bx)
		if x1 - 0.1 - bx < 0.22:
			bw = x1 - 0.1 - bx  # the last board takes the remainder: no sliver
		var runs := [[z0 + 0.1, -0.1]]
		if bx + bw > hatch.position.x and bx < hatch.end.x:
			runs = [[z0 + 0.1, hatch.position.y], [hatch.end.y, -0.1]]
		var j := 0
		for rr: Array in runs:
			b.add_member("tower/belfry/board_%d_%d" % [k, j], &"floor_board", &"floor", Vector3(bw - 0.004, 0.032, float(rr[1]) - float(rr[0])),
					Vector3(bx + bw * 0.5, fy + jh + 0.016, (float(rr[0]) + float(rr[1])) * 0.5))
			j += 1
		bx += bw if bw > 0.15 else 0.15
		k += 1
	# Corner posts, and the ring of plates at their heads.
	b.band = 3
	var py := fy + jh + 0.025
	var ph := ty - py
	var px := [x0 + post * 0.5 + 0.02, x1 - post * 0.5 - 0.02]
	var pz := [z0 + post * 0.5 + 0.02, -post * 0.5 - 0.02]
	for ix in 2:
		for iz in 2:
			b.add_member("tower/belfry/post_%d%d" % [ix, iz], &"post", &"framing", Vector3(post, ph, post), Vector3(px[ix], py + ph * 0.5, pz[iz]))
	# The skirt where the clapboard stops (#1170): flared, a steep upper pitch off the posts kicking out
	# to a shallow lower one past the walls (the bell-cast eave of the pattern books), a pair of boards a side.
	b.band = 4
	_flare("tower/belfry/skirt", Vector2(cx, cz), Vector2(w * 0.5, -z0 * 0.5), w * 0.5 - 0.1, fy + jh + 0.25,
			[[0.46, 45.0], [0.36, 15.0]], &"weathered_pine", fy)
	b.band = 3
	# Each face: a pointed bell opening at its middle between two jamb posts (they carry the ring's
	# mid-span, where the spire's commons land), a louvred panel either side of it (#1170).
	var ow := float(t.get("opening", 1.0))
	var ys := ty - float(t.get("spring_down", 1.0))  # the opening's springing
	var apex_y := ty - 0.22
	var faces := _faces(cx, cz, post)
	for f: Dictionary in faces:
		for s in [-1.0, 1.0]:
			var u: float = f.c + s * (ow * 0.5 + post * 0.5)
			b.add_member("tower/belfry/jamb_%s_%d" % [f.id, int(s)], &"post", &"framing", Vector3(post, ph, post), _on(f, u, py + ph * 0.5, 0.0))
	b.band = 4
	var ring := Vector2(0.15, 0.25)  # (width, height)
	b.add_member("tower/belfry/ring_front", &"beam", &"framing", Vector3(w - 0.04, ring.y, ring.x), Vector3(cx, ty + ring.y * 0.5, z0 + 0.05 + 0.02))
	b.add_member("tower/belfry/ring_back", &"beam", &"framing", Vector3(w - 0.04, ring.y, ring.x), Vector3(cx, ty + ring.y * 0.5, -0.05 - 0.02))
	b.add_member("tower/belfry/ring_w", &"beam", &"framing", Vector3(ring.x, ring.y, -z0 - 0.04), Vector3(x1 - 0.05 - 0.02, ty + ring.y * 0.5, z0 + (-z0) * 0.5))
	b.add_member("tower/belfry/ring_e", &"beam", &"framing", Vector3(ring.x, ring.y, -z0 - 0.04), Vector3(x0 + 0.05 + 0.02, ty + ring.y * 0.5, z0 + (-z0) * 0.5))
	# The panels: boarded below the louvres and over them, slats tilted 40 degrees between; the opening's
	# sill, its pointed head (stepped boards to the slant, a slanted casing over them), a board over the point.
	var lv: Dictionary = t.get("louvre", {})
	var ly0 := float(lv.get("from", py + 0.6))
	var step := float(lv.get("step", 0.13))
	var slat_h := 0.12
	var tilt := deg_to_rad(40.0)
	var board := 0.03
	var hw := ow * 0.5
	var rise := apex_y - ys
	for f: Dictionary in faces:
		var fid: String = f.id
		var c: float = f.c
		var inner_a: float = f.lo + post + 0.002  # the corner post's inner face
		var inner_b: float = f.hi - post - 0.002
		var ja: float = c - hw - post - 0.002  # the jamb posts' outer faces
		var jb: float = c + hw + post + 0.002
		for pnl: Array in [["l", inner_a, ja], ["r", jb, inner_b]]:
			var a0: float = pnl[1]
			var a1: float = pnl[2]
			b.add_member("tower/belfry/panel_%s_%s_lo" % [fid, pnl[0]], &"board", &"framing", _size(f, a1 - a0, ly0 - py, board),
					_on(f, (a0 + a1) * 0.5, (py + ly0) * 0.5, 0.0))
			b.add_member("tower/belfry/panel_%s_%s_hi" % [fid, pnl[0]], &"board", &"framing", _size(f, a1 - a0, ty - ys, board),
					_on(f, (a0 + a1) * 0.5, (ys + ty) * 0.5, 0.0))
			var y := ly0 + 0.02
			var n := 0
			while y + slat_h < ys - 0.02:
				b.add_member("tower/belfry/louvre_%s_%s%d" % [fid, pnl[0], n], &"board", &"framing", _size(f, a1 - a0, slat_h, 0.02),
						_on(f, (a0 + a1) * 0.5, y + slat_h * 0.5, 0.0), Basis(f.u, -tilt))
				y += step
				n += 1
		var o0 := c - hw
		var o1 := c + hw
		b.add_member("tower/belfry/opening_%s_sill" % fid, &"board", &"framing", _size(f, ow, 0.05, post + 0.06), _on(f, c, ly0 - 0.025, 0.03))
		b.add_member("tower/belfry/opening_%s_apron" % fid, &"board", &"framing", _size(f, ow, ly0 - 0.05 - py, board), _on(f, c, (py + ly0 - 0.05) * 0.5, 0.0))
		var nstep := maxi(4, roundi(rise / 0.08))
		var dy := rise / nstep
		for i in nstep:
			var ya := ys + dy * i
			var inset := hw * (i + 0.5) / nstep  # the slant's distance in from the jamb at this step's middle
			for s in 2:
				var e0 := o0 if s == 0 else o1 - inset
				var e1 := o0 + inset if s == 0 else o1
				b.add_member("tower/belfry/opening_%s_head%s%d" % [fid, "lr"[s], i], &"board", &"framing", _size(f, e1 - e0 + 0.004, dy, board),
						_on(f, (e0 + e1) * 0.5, ya + dy * 0.5, 0.0))
		b.add_member("tower/belfry/opening_%s_key" % fid, &"board", &"framing", _size(f, ow, ty - apex_y, board), _on(f, c, (apex_y + ty) * 0.5, 0.0))
		var sl := sqrt(hw * hw + rise * rise)
		for s in 2:
			var foot := Vector2(o0 if s == 0 else o1, ys)
			var d := (Vector2(c, apex_y) - foot).normalized()
			var mid := (foot + Vector2(c, apex_y)) * 0.5
			var dir3: Vector3 = (f.u as Vector3) * d.x + Vector3.UP * d.y
			var nrm: Vector3 = f.n
			b.add_member("tower/belfry/opening_%s_arch%s" % [fid, "lr"[s]], &"trim", &"framing", Vector3(sl + 0.06, 0.1, 0.025),
					_on(f, mid.x, mid.y, board * 0.5 + 0.0125), Basis(dir3, nrm.cross(dir3).normalized(), nrm))
	_spire(ty + ring.y, cx, cz)
	_porch(cx)
	_boxed_eaves()


## The side walls' boxed eaves (#1170; the blind judge's first note on the side wall: "bare dark rafter ends"):
## a fascia board on the rafter tails, a soffit under them back to the siding, a frieze board on the siding under
## the soffit, white, in stock lengths. The spec's `eaves`: {walls, fascia, frieze} (heights in m).
func _boxed_eaves() -> void:
	var e: Dictionary = b.spec.get("eaves", {})
	if e.is_empty():
		return
	var over := float(b._fr.rafters.get("eave", 0.3))
	var ang := deg_to_rad(b.roof_pitch_degrees)
	var rf: Array = b._fr.rafters.rafter
	var wh: float = b.wall_height
	var tail_y := wh - over * tan(ang)  # the rafters' underside at their tails
	var reach := over + sin(ang) * float(rf[1])  # the tails' outer top corner out from the wall line
	var trim := StringName(b.spec.materials.get("trim_outside", "painted_white"))
	var bt := 0.025  # the siding's face (FalseFrontBuilding.BOARD_T)
	b.band = 5
	for id: String in e.walls:
		if not b.walls.has(id):
			continue
		var wall: Dictionary = b.walls[id].dict
		var length: float = wall.length
		var a0 := -float(e.get("past", 0.3))
		var a1 := length - a0
		var n := maxi(1, ceili((a1 - a0) / 4.9))
		for k in n:
			var s0 := a0 + (a1 - a0) * k / n
			var s1 := a0 + (a1 - a0) * (k + 1) / n - 0.003
			b._wall_member("%s/eave/soffit_%d" % [id, k], &"trim", trim, wall, s0, s1, tail_y - 0.022, tail_y + 0.002, bt, reach)
			b._wall_member("%s/eave/fascia_%d" % [id, k], &"trim", trim, wall, s0, s1, tail_y - 0.12, tail_y - 0.12 + float(e.get("fascia", 0.24)),
					reach - 0.003, reach + 0.022)
			b._wall_member("%s/eave/frieze_%d" % [id, k], &"trim", trim, wall, maxf(s0, 0.0), minf(s1, length), tail_y - 0.022 - float(e.get("frieze", 0.22)),
					tail_y - 0.022, bt, bt + 0.022)


## The front door's hood and the steps' handrails (#1170; the spec's `tower.hood`, `tower.handrails`): a small
## gable of shingles on two brackets over the pointed doors (an arm out from a plate on the siding, a brace
## under it), its barge boards white; an iron pipe rail either side of the three steps, set in the ground.
func _porch(cx: float) -> void:
	var h: Dictionary = t.get("hood", {})
	if not h.is_empty():
		b.band = 4
		var face := z0 - 0.025  # the siding's face
		var hw := float(h.width) * 0.5
		var out := float(h.out)
		var ye := float(h.y)
		var a := deg_to_rad(float(h.get("pitch", 40.0)))
		var trim := StringName(b.spec.materials.get("trim_outside", "painted_white"))
		for s in [-1.0, 1.0]:
			var x: float = cx + s * (hw - 0.04)
			b.add_member("tower/hood/plate_%d" % int(s), &"beam", trim, Vector3(0.08, 0.7, 0.04), Vector3(x, ye - 0.35, face - 0.02))
			b.add_member("tower/hood/arm_%d" % int(s), &"rafter", trim, Vector3(0.07, 0.09, out), Vector3(x, ye - 0.045, face - 0.04 - out * 0.5))
			var p0 := Vector3(x, ye - 0.62, face - 0.05)
			var p1 := Vector3(x, ye - 0.09, face - 0.04 - out * 0.8)
			var d := p1 - p0
			b.add_member("tower/hood/brace_%d" % int(s), &"cripple", trim, Vector3(0.06, 0.06, d.length()), (p0 + p1) * 0.5, Basis.looking_at(d.normalized(), Vector3.RIGHT))
		# The two roof boards: low edges on the arms, meeting at a ridge over the door's middle, running out from the wall.
		var roof := StringName(b.spec.materials.get("roof", "weathered_pine"))
		var span := hw / cos(a)
		for s in [-1.0, 1.0]:
			var up := Vector2(-s * cos(a), sin(a))  # from the low edge toward the ridge, in (x, y)
			var nrm := Vector3(s * sin(a), cos(a), 0.0)
			var c := Vector3(cx + s * hw, ye - 0.005, 0.0) + Vector3(up.x, up.y, 0.0) * (span * 0.5) + nrm * 0.016
			c.z = face - (out + 0.12) * 0.5
			var ax := Vector3(up.x, up.y, 0.0)
			b.add_member("tower/hood/roof_%d" % int(s), &"roof_board", roof, Vector3(span + 0.12, 0.032, out + 0.12), c, Basis(ax, nrm, ax.cross(nrm)).orthonormalized())
			# its barge board under the front edge, white
			b.add_member("tower/hood/barge_%d" % int(s), &"trim", trim, Vector3(span + 0.1, 0.12, 0.025), c - nrm * 0.07 + Vector3(0, 0, -(out + 0.12) * 0.5 + 0.0125),
					Basis(ax, nrm, ax.cross(nrm)).orthonormalized())
	var hr: Dictionary = t.get("handrails", {})
	if not hr.is_empty():
		b.band = 1
		var hgt := float(hr.get("height", 0.9))
		var z_top := z0 - 0.08
		var z_foot := z0 - float(hr.run)
		for s in [-1.0, 1.0]:
			var x: float = cx + s * float(hr.half)
			var top_y := float(hr.top) + hgt
			var foot_y := hgt
			b.add_member("tower/handrail/post_top_%d" % int(s), &"post", &"iron", Vector3(0.045, top_y, 0.045), Vector3(x, top_y * 0.5, z_top))
			b.add_member("tower/handrail/post_foot_%d" % int(s), &"post", &"iron", Vector3(0.045, foot_y, 0.045), Vector3(x, foot_y * 0.5, z_foot))
			var p0 := Vector3(x, foot_y + 0.02, z_foot - 0.1)
			var p1 := Vector3(x, top_y + 0.02, z_top)
			var d := p1 - p0
			b.add_member("tower/handrail/rail_%d" % int(s), &"beam", &"iron", Vector3(0.045, 0.045, d.length() + 0.04), (p0 + p1) * 0.5, Basis.looking_at(d.normalized(), Vector3.UP))


## The belfry's four faces: `id`, their outward normal `n`, the axis along them `u`, the plane they lie in
## (`plane`, through the posts' middles), and `lo`, `hi`, `c` along `u`.
func _faces(cx: float, cz: float, post: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append({"id": "front", "n": Vector3(0, 0, -1), "u": Vector3.RIGHT, "plane": z0 + post * 0.5 + 0.02, "lo": x0 + 0.02, "hi": x1 - 0.02, "c": cx})
	out.append({"id": "back", "n": Vector3(0, 0, 1), "u": Vector3.RIGHT, "plane": -post * 0.5 - 0.02, "lo": x0 + 0.02, "hi": x1 - 0.02, "c": cx})
	out.append({"id": "w", "n": Vector3(1, 0, 0), "u": Vector3.BACK, "plane": x1 - post * 0.5 - 0.02, "lo": z0 + 0.02, "hi": -0.02, "c": cz})
	out.append({"id": "e", "n": Vector3(-1, 0, 0), "u": Vector3.BACK, "plane": x0 + post * 0.5 + 0.02, "lo": z0 + 0.02, "hi": -0.02, "c": cz})
	return out


## A point on a face: `a` along it, `y` up, `out` from its plane along its normal.
func _on(f: Dictionary, a: float, y: float, out: float) -> Vector3:
	var u: Vector3 = f.u
	var n: Vector3 = f.n
	var p := Vector3(0.0, y, 0.0) + n * out
	if absf(u.x) > 0.5:
		p.x += a
		p.z += float(f.plane)
	else:
		p.z += a
		p.x += float(f.plane)
	return p


## A box `along` long on a face, `h` high, `thick` through it.
func _size(f: Dictionary, along: float, h: float, thick: float) -> Vector3:
	return Vector3(along, h, thick) if absf((f.u as Vector3).x) > 0.5 else Vector3(thick, h, along)


## A flared roof round the tower (#1170): for each side, a run of boards from `inner` (the distance out from
## the middle `c` where the top edge lies, at `y`) down and out, each [width, pitch in degrees]; the boards
## run past the corners so the sides lap there as hips do. `half` is the tower's half size (x, z).
## With `ledger_from` (a height), a timber laid on the walls' plates under the pitches' joint carries it (a sprocket's job).
func _flare(id: String, c: Vector2, half: Vector2, inner: float, y: float, segs: Array, wood: StringName, ledger_from := -1.0) -> void:
	for i in 4:
		var n: Vector3 = [Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][i]
		var along_x := absf(n.z) > 0.5
		var own := half.y if along_x else half.x  # this side's half depth out from the middle
		var other := half.x if along_x else half.y
		var start := Vector2(inner + (own - minf(half.x, half.y)), y)  # (out, up)
		var k := 0
		for sg: Array in segs:
			var wdt := float(sg[0])
			var a := deg_to_rad(float(sg[1]))
			var down := Vector2(cos(a), -sin(a))
			var mid := start + down * (wdt * 0.5)
			var reach := other + (mid.x - own) + wdt * 0.5 * cos(a)
			var tan_ := Vector3(n.z, 0, -n.x).abs()
			var dir3 := n * down.x + Vector3.UP * down.y
			var up3 := dir3.cross(tan_).normalized()
			if up3.y < 0.0:
				up3 = -up3
			var centre := Vector3(c.x, 0.0, c.y) + n * mid.x + Vector3.UP * mid.y + up3 * 0.015
			var bas := Basis(tan_, up3, tan_.cross(up3))
			# (the box's z along the slope: tan_ x up3 points along +/-dir3)
			b.add_member("%s_%d_%d" % [id, i, k], &"roof_board", wood, Vector3(2.0 * reach, 0.03, wdt + 0.04), centre, bas.orthonormalized())
			start += down * wdt
			if k == 0 and ledger_from >= 0.0 and segs.size() > 1:
				var lo := own - 0.1
				var hi := start.x + 0.02
				var top := start.y - 0.004
				var lc := Vector3(c.x, 0.0, c.y) + n * ((lo + hi) * 0.5) + Vector3.UP * ((ledger_from + top) * 0.5)
				var lsz := Vector3(2.0 * (other + 0.1), top - ledger_from, hi - lo) if along_x else Vector3(hi - lo, top - ledger_from, 2.0 * (other + 0.1))
				b.add_member("%s_ledger_%d" % [id, i], &"beam", &"framing", lsz, lc)
			k += 1


## The spire: shingle courses stepped up four faces, over four hip rafters and four common rafters
## from the belfry's ring plates, an iron cross on its apex.
func _spire(y0: float, cx: float, cz: float) -> void:
	var hs := float(t.spire)
	var eave := 0.16
	var half_x := (x1 - x0) * 0.5 - 0.06 + eave
	var half_z := -z0 * 0.5 - 0.06 + eave
	var s_ := maxf(half_x, half_z)  # a square spire over the tower's square plan: half a side
	var slope := atan2(hs, s_)
	var len_total := sqrt(s_ * s_ + hs * hs)
	var apex := Vector3(cx, y0 + hs, cz)
	# The seat: four beams laid on the ring, standing out past it by the eave, the hips' feet on them.
	b.band = 5
	for i in 4:
		var along_x := i < 2
		var sgn := 1.0 if i % 2 == 0 else -1.0
		var sz := Vector3(2.0 * s_ + 0.1, 0.1, 0.1) if along_x else Vector3(0.1, 0.1, 2.0 * s_ + 0.1)
		var cc := Vector3(cx, y0 + 0.03, cz + sgn * (s_ - 0.05)) if along_x else Vector3(cx + sgn * (s_ - 0.05), y0 + 0.03, cz)
		b.add_member("tower/spire/seat_%d" % i, &"beam", &"framing", sz, cc)
	for i in 4:
		var corner := Vector3(cx + (s_ if i % 2 == 0 else -s_), y0, cz + (s_ if i < 2 else -s_))
		var d := apex - corner
		var c := (corner + apex) * 0.5
		b.add_member("tower/spire/hip_%d" % i, &"rafter", &"framing", Vector3(0.1, 0.1, d.length()), c, Basis.looking_at(d.normalized(), Vector3.UP))
	for i in 4:
		var n: Vector3 = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][i]
		var base := Vector3(cx, y0, cz) + n * s_
		var d := (apex - base)
		b.add_member("tower/spire/common_%d" % i, &"rafter", &"framing", Vector3(0.08, 0.08, d.length()), (base + apex) * 0.5, Basis.looking_at(d.normalized(), Vector3.UP))
	b.band = 6
	var step := float(t.get("shingle", 0.22))
	var wood := StringName(b.spec.materials.get("roof", "weathered_pine"))
	for i in 4:
		var n: Vector3 = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)][i]
		var tan_ := Vector3(n.z, 0, -n.x)
		var nrm := n * sin(slope) + Vector3.UP * cos(slope)
		var s0 := 0.0
		var k := 0
		while s0 < len_total - 0.05:
			var s1 := minf(s0 + step, len_total)
			var sm := (s0 + s1) * 0.5
			var width := 2.0 * s_ * (1.0 - sm * sin(slope) / hs) + 0.1
			var p := Vector3(cx, y0, cz) + n * (s_ - sm * cos(slope)) + Vector3.UP * (sm * sin(slope)) + nrm * 0.06
			var bas := Basis(tan_.abs() if false else tan_, nrm, tan_.cross(nrm))
			if absf(tan_.x) + absf(tan_.z) < 0.5:
				continue
			b.add_member("tower/spire/shingle_%d_%02d" % [i, k], &"roof_board", wood, Vector3(width, SKIN, (s1 - s0) + 0.03), p, bas.orthonormalized())
			s0 = s1
			k += 1
	# The bell-cast eave (#1170): the spire's foot kicks out over the belfry on a shallow pitch, boards on the
	# seat beams lapping under its first course.
	b.band = 6
	_flare("tower/spire/kick", Vector2(cx, cz), Vector2(s_, s_), s_ - 0.12, y0 + 0.09, [[0.5, 20.0]], wood)
	# The iron finial: a tall rod, a cross at its head.
	var fh := float(t.get("finial", 0.9))
	b.add_member("tower/spire/finial", &"post", &"iron", Vector3(0.05, fh, 0.05), apex + Vector3(0, fh * 0.5 - 0.1, 0))
	b.add_member("tower/spire/finial_arm", &"beam", &"iron", Vector3(0.36, 0.045, 0.045), apex + Vector3(0, fh * 0.72, 0))
