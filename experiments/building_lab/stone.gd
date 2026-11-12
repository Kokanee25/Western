extends RefCounted
## A load-bearing stone building from its spec (#780, the jail; the building lab's step 3): what
## spec_building.gd builds when the spec's frame has `stone_wall`. Everything it makes is a member
## of the building (its Structure), in the builder's bands (FORMAT.md "Bands"):
##
## - **Stone walls in pieces** (`_lay`): each wall in rows (the spec's 0.6 m courses, broken at every
##   level that matters: a set-off, an opening's sill and head, a lintel's top, the coping), each row
##   cut into pieces of at most `piece` along it, staggered row to row, round its openings: a dressed
##   sill stone under each window (`<wall>/opening<j>/sill`) and a lintel over each opening
##   (`<wall>/opening<j>/lintel`), what Checks.built_right counts as framed. Every piece is kind
##   `sill` of the game's `stone`, so a piece rests on the one under it (the support ladder's
##   "beneath"), and the lowest row stands on its footing, `footing_below` under the ground (the
##   spec's ground plane: the foot follows the fall). A wall's thickness by height is its `profile`
##   ([from y, d_lo, d_hi], d along its `out`, 0 its outer face): set-offs under the floor's joists and
##   girders, a 6 in ledge where the roof's joists bear (the parapet above it the thinner). Where a
##   wall's end butts another (`ends`), it runs to that wall's inner face at each row.
## - **Floors** by the builder's `_floor` (joists, headers round a hatch, boards), the girders
##   between the walls' set-offs on stone piers, the cell wing's flags on a stone fill.
## - **The flat roofs** as floors of their own joists (the office's on the front, cross and back
##   walls' ledges; the ell's across), tin sheets over the boards.
## - **The cages**: riveted strap-iron lattices of members (`iron`), their doors and the corridor's
##   grille gate of kind `door`, a plank bunk in each.
## - **The yard's stone walls**, their tops stepped with the ground, gates open in them.
## The masonry lab's step 8 lays the walls as its stones and joints instead (the spec's `masonry`).

const STONE := &"stone"
const IRON := &"iron"

var b: Node  # the SpecBuilding
var spec: Dictionary
var fr: Dictionary
var sw: Dictionary
var plane: Array
var floor_top: float
var walls_by_id := {}


func _init(building: Node) -> void:
	b = building
	spec = b.spec
	fr = spec.frame
	sw = fr.stone_wall
	plane = (spec.lot.get("ground", {}) as Dictionary).get("plane", [0.0, 0.0, 0.0])
	floor_top = float(spec.levels.ground.top)
	for w: Dictionary in spec.walls:
		walls_by_id[w.id] = w


## The ground's height at (x, z) of the building's space (the spec's plane).
func ground(x: float, z: float) -> float:
	return float(plane[0]) + float(plane[1]) * x + float(plane[2]) * z


func build() -> void:
	b._lv["ell_roof"] = float(spec.levels.get("ell_roof", spec.levels.upper.top))
	b.band = 1
	for w: Dictionary in spec.walls:
		if w.get("stone", false):
			_stone_wall(w)
	_girders()
	for f: Dictionary in spec.floors:
		if f.level == "ground" and f.get("kind", "") != "flags":
			b._floor(f, spec.girders.get("x", []))
	_flags()
	b._partitions("ground", 2)
	b.band = 2
	_cells()
	_ladders()
	b.band = 1
	_steps()
	b.band = 3
	for f: Dictionary in spec.floors:
		if f.level != "ground":
			b._floor(f, [])
	b.band = 4
	_tin()
	b.band = 1
	_yard_walls()
	b.band = 0


# --- the walls ------------------------------------------------------------------------------------

func _wall_dict(w: Dictionary) -> Dictionary:
	var a := Vector3(w.line[0][0], 0, w.line[0][1])
	var e := Vector3(w.line[1][0], 0, w.line[1][1])
	var along := (e - a).normalized()
	var out: Vector3 = b._axis(String(w.out))
	var length := a.distance_to(e)
	return b._wall(String(w.id), a, along, out, length, 0.0, length)


## A profile's band [d_lo, d_hi] at height y.
static func band_at(profile: Array, y: float) -> Vector2:
	var out := Vector2(profile[0][1], profile[0][2])
	for p: Array in profile:
		if y >= float(p[0]) - 0.0001:
			out = Vector2(p[1], p[2])
	return out


## How far a wall's end moves along it at height y where it butts `other` (+ shorter, - longer):
## to the other's inner face at that height.
func _end_shift(wall: Dictionary, end: int, other_id: Variant, y: float) -> float:
	if other_id == null or not walls_by_id.has(other_id):
		return 0.0
	var o: Dictionary = walls_by_id[other_id]
	var p := Vector3(o.line[0][0], 0, o.line[0][1])
	var n: Vector3 = b._axis(String(o.out))
	var pt: Vector3 = (wall.origin as Vector3) + (wall.along as Vector3) * (0.0 if end == 0 else float(wall.length))
	var base := (pt - p).dot(-n)
	var d := band_at(o.profile, y)
	return -d.x - base


func _stone_wall(w: Dictionary) -> void:
	var wall := _wall_dict(w)
	b.walls[w.id] = {"dict": wall, "spec": w}
	var holes := []
	var j := 0
	for o: Dictionary in w.get("openings", []):
		var lvl: String = o.get("level", w.get("level", "ground"))
		var y0 := float(spec.levels[lvl].top) + float(o.get("sill", 0.0))
		var r := Rect2(float(o.at) - float(o.width) * 0.5, y0, float(o.width), float(o.height))
		holes.append({"r": r, "j": j, "sill": o.type == "window" and float(o.get("sill", 0.0)) > 0.4, "lintel": true, "o": o})
		j += 1
	_lay(wall, String(w.id), 0.0, float(wall.length), float(w.top), w.profile, w.get("ends", [null, null]), holes, [floor_top])
	_dress_openings(w, wall, holes)


## Lay a wall's run from s_lo to s_hi up to `top` in rows of pieces (see the top).
func _lay(wall: Dictionary, id: String, s_lo: float, s_hi: float, top: float, profile: Array, ends: Array, holes: Array, extra: Array) -> void:
	var course := float(sw.course)
	var piece := float(sw.piece)
	var below := float(sw.footing_below)
	var coping := float(sw.coping.height)
	var lintel_h := float(sw.lintel.height)
	var sill_h := float(sw.sill.height)
	# The levels every row breaks at, then the courses between them.
	var special: Array[float] = [top, top - coping]
	for e: float in extra:
		special.append(e)
	for p: Array in profile:
		if float(p[0]) > -5.0:
			special.append(float(p[0]))
	for h: Dictionary in holes:
		var r: Rect2 = h.r
		if h.sill:
			special.append_array([r.position.y - sill_h, r.position.y])
		elif r.position.y > -5.0:
			special.append(r.position.y)
		if h.lintel:
			special.append_array([r.end.y, r.end.y + lintel_h])
	var lowest := 0.0
	for s in [s_lo, s_hi]:
		lowest = minf(lowest, _foot(wall, s, profile))
	var levels: Array[float] = []
	for y in special:
		if y < top + 0.001:
			levels.append(y)
	var y := floorf(lowest / course) * course
	while y < top - coping - 0.05:
		var near := false
		for sp in special:
			if absf(sp - y) < 0.25:
				near = true
		if not near:
			levels.append(y)
		y += course
	levels.sort()
	var lv: Array[float] = []
	for l in levels:
		if lv.is_empty() or l - lv.back() > 0.005:
			lv.append(l)
	var row := 0
	for i in lv.size() - 1:
		var ya := lv[i]
		var yb := lv[i + 1]
		var mid := (ya + yb) * 0.5
		var d := band_at(profile, mid)
		var s0 := s_lo + _end_shift(wall, 0, ends[0], mid) if ends.size() > 0 else s_lo
		var s1 := s_hi - _end_shift(wall, 1, ends[1], mid) if ends.size() > 1 else s_hi
		# Cuts: the run's ends, the holes' edges, a sill's or lintel's bearing, the stagger.
		var cuts: Array[float] = [s0, s1]
		var named := {}  # a span's start -> its name
		var whole: Array[Vector2] = []  # spans the stagger mustn't cut (a lintel, a sill)
		for h: Dictionary in holes:
			var r: Rect2 = h.r
			if r.end.x < s0 or r.position.x > s1:
				continue
			if ya < r.end.y - 0.001 and yb > r.position.y + 0.001:
				cuts.append_array([r.position.x, r.end.x])
			elif h.lintel and absf(ya - r.end.y) < 0.002:
				var bear := float(sw.lintel.bear)
				cuts.append_array([r.position.x - bear, r.end.x + bear])
				named[snappedf(r.position.x - bear, 0.001)] = "%s/opening%d/lintel" % [id, h.j]
				whole.append(Vector2(r.position.x - bear, r.end.x + bear))
			elif h.sill and absf(yb - r.position.y) < 0.002:
				cuts.append_array([r.position.x - 0.1, r.end.x + 0.1])
				named[snappedf(r.position.x - 0.1, 0.001)] = "%s/opening%d/sill" % [id, h.j]
				whole.append(Vector2(r.position.x - 0.1, r.end.x + 0.1))
		var off := piece * 0.5 if row % 2 == 1 else 0.0
		var g := floorf((s0 - off) / piece) * piece + off
		while g < s1:
			var inside := false
			for wsp: Vector2 in whole:
				if g > wsp.x - 0.25 and g < wsp.y + 0.25:
					inside = true
			if g > s0 and not inside:
				cuts.append(g)
			g += piece
		cuts.sort()
		var keep: Array[float] = []
		for c in cuts:
			if c < s0 - 0.001 or c > s1 + 0.001:
				continue
			if keep.is_empty() or c - keep.back() > 0.001:
				keep.append(c)
		# Merge slivers: a stagger cut within 0.25 of another goes.
		var final: Array[float] = []
		for k in keep.size():
			var c := keep[k]
			var is_grid := not (c in [s0, s1])
			for h: Dictionary in holes:
				var r: Rect2 = h.r
				for e in [r.position.x, r.end.x, r.position.x - float(sw.lintel.bear), r.end.x + float(sw.lintel.bear), r.position.x - 0.1, r.end.x + 0.1]:
					if absf(c - e) < 0.0015:
						is_grid = false
			if is_grid and ((not final.is_empty() and c - final.back() < 0.25) or (k + 1 < keep.size() and keep[k + 1] - c < 0.25)):
				continue
			final.append(c)
		var n := 0
		for k in final.size() - 1:
			var a := final[k]
			var e := final[k + 1]
			if e - a < 0.02:
				continue
			var m := (a + e) * 0.5
			var bottom := ya
			var cap := yb
			var hole := false
			for h: Dictionary in holes:
				var r: Rect2 = h.r
				if m > r.position.x and m < r.end.x:
					if h.get("gate", false):
						# A gate: open from the ground up (a footing under it).
						if yb > r.position.y + 0.001:
							cap = minf(cap, r.position.y)
					elif ya < r.end.y - 0.001 and yb > r.position.y + 0.001:
						hole = true
			if hole or cap - bottom < 0.03:
				continue
			var foot := _foot(wall, m, profile)
			if cap <= foot + 0.02:
				continue
			bottom = maxf(bottom, foot)
			var name: String = named.get(snappedf(a, 0.001), "")
			if name == "":
				name = "%s/r%02d/%02d" % [id, row, n]
			b._wall_member(name, &"sill", STONE, wall, a, e, bottom, cap, d.x, d.y)
			n += 1
		row += 1


## The footing's foot under a point of a wall (at its middle's thickness).
func _foot(wall: Dictionary, s: float, profile: Array) -> float:
	var d := band_at(profile, -9.0)
	var p: Vector3 = (wall.origin as Vector3) + (wall.along as Vector3) * s + (wall.out as Vector3) * ((d.x + d.y) * 0.5)
	return ground(p.x, p.z) - float(sw.footing_below)


## Glass, bars, a transom and a door's leaf in each opening of a stone wall.
func _dress_openings(w: Dictionary, wall: Dictionary, holes: Array) -> void:
	var t := -band_at(w.profile, floor_top + 1.0).x  # the wall's thickness at a man's height
	for h: Dictionary in holes:
		var o: Dictionary = h.o
		var r: Rect2 = h.r
		if o.type == "window":
			if o.get("glass", true):
				b._glass(wall, r)
			if o.get("bars", false):
				b._bars(wall, r)
		elif o.type == "door":
			var lr := r
			var tr := float(o.get("transom", 0.0))
			if tr > 0.0:
				lr.size.y -= tr
				var bar := Rect2(lr.position.x, lr.end.y, lr.size.x, 0.05)
				b._wall_member("%s/transom_bar_%d" % [w.id, int(lr.position.x * 100)], &"trim", &"dark_trim", wall, bar.position.x, bar.end.x, bar.position.y, bar.end.y, -0.12, -0.04)
				var light := Rect2(lr.position.x, lr.end.y + 0.05, lr.size.x, tr - 0.05)
				b._glass(wall, light)
				b._bars(wall, light)
			b._leaf(wall, lr, String(o.get("leaf", "inward")) == "outward", -t)


# --- floors, the cells' flags, the girders --------------------------------------------------------

## The girders front to back under the office's floors (`girders.x`), each between the set-offs of
## the walls at its ends (the front, cross and back walls'), on stone piers.
func _girders() -> void:
	var g: Array = fr.girder.section
	var every := float(fr.girder.pier_every)
	var pier := float(fr.pier.size)
	for f: Dictionary in spec.floors:
		if f.level != "ground" or f.get("kind", "") == "flags":
			continue
		var r: Array = f.rect
		var top := floor_top - float(fr.floor_board.thick) - float(fr.joist.section[1])
		for gx: float in spec.girders.get("x", []):
			var z0 := float(r[1])
			var z1 := float(r[3])
			b.band = 1
			b.add_member("girder/%s_%d" % [f.id, int(gx * 100)], &"sill", &"framing", Vector3(g[0], g[1], z1 - z0), Vector3(gx, top - float(g[1]) * 0.5, (z0 + z1) * 0.5))
			var z := z0 + every * 0.5
			var k := 0
			while z < z1 - 0.3:
				var foot := ground(gx, z) - 0.6
				var pt := top - float(g[1])
				b.band = 0
				b.add_member("pier/%s_%d_%02d" % [f.id, int(gx * 100), k], &"sill", STONE, Vector3(pier, pt - foot, pier), Vector3(gx, (pt + foot) * 0.5, z))
				z += every
				k += 1
	b.band = 1


## The cell wing's floor: a stone fill (rammed earth and rubble) to under the flags, the flags on it.
func _flags() -> void:
	for f: Dictionary in spec.floors:
		if f.get("kind", "") != "flags":
			continue
		var r: Array = f.rect
		var x0 := float(r[0])
		var z0 := float(r[1])
		var x1 := float(r[2])
		var z1 := float(r[3])
		var ft := 0.1
		var fill_top := floor_top - ft
		# The fill in blocks about 2 m square, down to the walls' footings' depth.
		var nx := maxi(1, ceili((x1 - x0) / 2.0))
		var nz := maxi(1, ceili((z1 - z0) / 2.2))
		for i in nx:
			for k in nz:
				var a := x0 + (x1 - x0) * i / nx
				var e := x0 + (x1 - x0) * (i + 1) / nx
				var c := z0 + (z1 - z0) * k / nz
				var d := z0 + (z1 - z0) * (k + 1) / nz
				var foot := ground((a + e) * 0.5, (c + d) * 0.5) - 0.3
				b.add_member("floor/%s/fill_%d_%d" % [f.id, i, k], &"sill", STONE, Vector3(e - a - 0.004, fill_top - foot, d - c - 0.004), Vector3((a + e) * 0.5, (fill_top + foot) * 0.5, (c + d) * 0.5))
		var fl := float(f.get("flag", 0.6))
		var mx := maxi(1, roundi((x1 - x0) / fl))
		var mz := maxi(1, roundi((z1 - z0) / fl))
		for i in mx:
			for k in mz:
				var a := x0 + (x1 - x0) * i / mx
				var e := x0 + (x1 - x0) * (i + 1) / mx
				var c := z0 + (z1 - z0) * k / mz
				var d := z0 + (z1 - z0) * (k + 1) / mz
				b.add_member("floor/%s/flag_%02d_%02d" % [f.id, i, k], &"sill", STONE, Vector3(e - a - 0.006, ft, d - c - 0.006), Vector3((a + e) * 0.5, fill_top + ft * 0.5, (c + d) * 0.5))


## Stone steps up to a door: a stoop at the floor and a block a step, each down to the ground.
func _steps() -> void:
	for st: Dictionary in spec.get("stairs", []):
		if st.get("wood", "") != "stone":
			continue
		var r: Array = st.stoop
		var x0 := float(r[0])
		var z0 := float(r[1])
		var x1 := float(r[2])
		var z1 := float(r[3])
		var foot := ground((x0 + x1) * 0.5, (z0 + z1) * 0.5) - 0.4
		b.add_member("stair/%s/stoop" % st.id, &"sill", STONE, Vector3(x1 - x0, floor_top - foot, z1 - z0), Vector3((x0 + x1) * 0.5, (floor_top + foot) * 0.5, (z0 + z1) * 0.5))
		var down: Vector3 = -b._axis(String(st.dir))
		var risers := int(st.risers)
		var rise := (floor_top - float(st.from)) / risers
		var going := float(st.going)
		var head := Vector3(st.head[0], 0, st.head[1])
		var across := Vector3(absf(down.z), 0, absf(down.x))
		for k in risers - 1:
			var top := floor_top - rise * (k + 1)
			var c := head + down * going * (k + 0.5) + across * float(st.width) * 0.5
			var f := ground(c.x, c.z) - 0.3
			if top - f < 0.05:
				continue
			b.add_member("stair/%s/step_%d" % [st.id, k], &"sill", STONE, down.abs() * (going - 0.004) + Vector3.UP * (top - f) + across * float(st.width), Vector3(c.x, (top + f) * 0.5, c.z))


## Tin sheets over each roof's boards, lapped a little, round its hatch.
func _tin() -> void:
	var tin: Dictionary = fr.get("tin", {})
	if tin.is_empty():
		return
	var sw_: float = float(tin.sheet[0])
	var sl: float = float(tin.sheet[1])
	var th := float(tin.thick)
	for f: Dictionary in spec.floors:
		if f.level == "ground":
			continue
		var r: Array = f.rect
		var top := float(b._lv[f.level])
		var x0 := float(r[0])
		var z0 := float(r[1])
		var x1 := float(r[2])
		var z1 := float(r[3])
		var nx := ceili((x1 - x0) / sw_)
		var nz := ceili((z1 - z0) / sl)
		for i in nx:
			for k in nz:
				var a := x0 + (x1 - x0) * i / nx
				var e := x0 + (x1 - x0) * (i + 1) / nx
				var c := z0 + (z1 - z0) * k / nz
				var d := z0 + (z1 - z0) * (k + 1) / nz
				var skip := false
				for o: Dictionary in f.get("openings", []):
					var orr: Array = o.rect
					if e > float(orr[0]) and a < float(orr[2]) and d > float(orr[1]) and c < float(orr[3]):
						skip = true
				if skip:
					continue
				b.add_member("roof/%s/tin_%02d_%02d" % [f.id, i, k], &"board", IRON, Vector3(e - a - 0.004, th, d - c - 0.004), Vector3((a + e) * 0.5, top + th * 0.5, (c + d) * 0.5))


## An inside ladder up through a hatch (the game's Ladder, with stiles and rungs as members).
func _ladders() -> void:
	for l: Dictionary in spec.get("ladders", []):
		if not l.get("inside", false):
			continue
		var face: Vector3 = b._axis(String(l.face))
		var across := Vector3(absf(face.z), 0, absf(face.x))
		var foot := Vector3(l.at[0], float(l.from), l.at[1])
		var h := float(l.to) - float(l.from)
		var lw := float(l.width)
		for e in 2:
			var c := foot + across * (lw * 0.5 * (1 if e == 0 else -1)) + Vector3.UP * (h * 0.5 + 0.45)
			b.add_member("ladder/%s/stile_%d" % [l.id, e], &"post", &"framing", across * 0.05 + Vector3.UP * (h + 0.9) + face.abs() * 0.07, c)
		var y := 0.3
		var k := 0
		while y < h + 0.8:
			b.add_member("ladder/%s/rung_%d" % [l.id, k], &"trim", &"framing", across * lw + Vector3.UP * 0.035 + face.abs() * 0.035, foot + Vector3.UP * y)
			y += 0.3
			k += 1
		var ld := Ladder.new()
		ld.name = "Ladder_" + String(l.id)
		ld.height = h
		ld.width = lw
		ld.transform = Transform3D(Basis.looking_at(face, Vector3.UP), foot)
		b._furnish.add_child(ld)


# --- the cells ------------------------------------------------------------------------------------

## Three strap-iron cages (spec.cells): the lattice's verticals on the flags, its horizontals woven
## on them, straps over the top; a door on the corridor side; the bunk; the corridor's grille gate.
func _cells() -> void:
	var c: Dictionary = spec.get("cells", {})
	if c.is_empty():
		return
	var st: Array = c.strap
	var sw_ := float(st[0])
	var stt := float(st[1])
	var vx := float(c.vertical_every)
	var hz := float(c.horizontal_every)
	var hgt := float(c.height)
	var y0 := floor_top
	var x0 := float(c.x[0])
	var x1 := float(c.x[1])
	var zs: Array = c.z
	var dw := float(c.door.width)
	# The faces: [id, start, end, fixed coordinate, along x?, door gaps along it]
	var faces := []
	var doors := []
	for k in zs.size() - 1:
		var za := float(zs[k])
		var zb := float(zs[k + 1])
		var zm := (za + zb) * 0.5
		doors.append(Vector2(zm - dw * 0.5, zm + dw * 0.5))
		faces.append(["cage%d/west" % (k + 1), za, zb, x0, false, [Vector2(zm - dw * 0.5, zm + dw * 0.5)]])
		faces.append(["cage%d/east" % (k + 1), za, zb, x1, false, []])
	for k in zs.size():
		faces.append(["cage_z%d" % k, x0, x1, float(zs[k]), true, []])
	for f: Array in faces:
		var a := float(f[1])
		var e := float(f[2])
		var fixed := float(f[3])
		var along_x: bool = f[4]
		var gaps: Array = f[5]
		var n := maxi(2, roundi((e - a) / vx))
		for i in n + 1:
			var p := a + (e - a) * i / n
			var in_door := false
			for gp: Vector2 in gaps:
				if p > gp.x - 0.01 and p < gp.y + 0.01:
					in_door = true
			# A door's straps are the lattice's own (they rest as the lattice does), named for it.
			var size := Vector3(sw_, hgt, stt) if along_x else Vector3(stt, hgt, sw_)
			var at := Vector3(p, y0 + hgt * 0.5, fixed) if along_x else Vector3(fixed, y0 + hgt * 0.5, p)
			b.add_member("cells/%s/%s%02d" % [f[0], "door_v" if in_door else "v", i], &"stud", IRON, size, at)
		# The horizontals, on the verticals' inside (a strap's thickness in), cut at the door.
		var rows := maxi(2, ceili(hgt / hz))
		for r in rows + 1:
			var y := y0 + 0.05 + (hgt - 0.1) * r / rows
			var spans := [Vector2(a, e)]
			for gp: Vector2 in gaps:
				spans = [Vector2(a, gp.x - 0.02), Vector2(gp.x, gp.y), Vector2(gp.y + 0.02, e)]
			for si in spans.size():
				var s: Vector2 = spans[si]
				var in_door := gaps.size() > 0 and si == 1
				var inset := stt if not along_x else stt
				var size := Vector3(s.y - s.x, sw_, stt) if along_x else Vector3(stt, sw_, s.y - s.x)
				var at := Vector3((s.x + s.y) * 0.5, y, fixed + inset) if along_x else Vector3(fixed + (inset if fixed < (x0 + x1) * 0.5 else -inset), y, (s.x + s.y) * 0.5)
				b.add_member("cells/%s/%s%d_%d" % [f[0], "door_h" if in_door else "h", r, si], &"plate", IRON, size, at)
	# Over the top: straps across the cages (x) at the horizontal spacing, laid on the top rails.
	var top := y0 + hgt
	var za0 := float(zs[0])
	var zb0 := float(zs[zs.size() - 1])
	var n := maxi(2, roundi((zb0 - za0) / hz))
	for i in n + 1:
		var z := za0 + (zb0 - za0) * i / n
		b.add_member("cells/top/x%02d" % i, &"board", IRON, Vector3(x1 - x0, stt, sw_), Vector3((x0 + x1) * 0.5, top + stt * 0.5, z))
	# A bunk in each: planks hung on chains from the east lattice.
	var bk: Dictionary = c.bunk
	for k in zs.size() - 1:
		var zm := (float(zs[k]) + float(zs[k + 1])) * 0.5
		b.add_member("cells/cage%d/bunk" % (k + 1), &"board", &"framing", Vector3(float(bk.width), 0.05, float(bk.length)),
				Vector3(x1 - stt * 0.5 - float(bk.width) * 0.5 - 0.002, y0 + float(bk.height), zm))
	# The corridor's grille gate.
	var gt: Dictionary = c.get("gate", {})
	if not gt.is_empty():
		var ga := float(gt.x[0])
		var gb := float(gt.x[1])
		var gz := float(gt.z)
		var m := maxi(2, roundi((gb - ga) / vx))
		for i in m + 1:
			b.add_member("cells/gate/v%02d" % i, &"stud", IRON, Vector3(sw_, hgt, stt), Vector3(ga + 0.03 + (gb - ga - 0.06) * i / m, y0 + hgt * 0.5, gz))
		for r in 3:
			b.add_member("cells/gate/h%d" % r, &"plate", IRON, Vector3(gb - ga - 0.04, sw_, stt), Vector3((ga + gb) * 0.5, y0 + 0.05 + (hgt - 0.1) * r / 2.0, gz + stt))


# --- the yard's walls -----------------------------------------------------------------------------

## The yard's stone walls (spec.yard_walls): each in lengths of `step`, each length's top the
## height over the ground at its middle; the gates open from the ground up, their leaves standing
## open into the yard.
func _yard_walls() -> void:
	var yw: Dictionary = spec.get("yard_walls", {})
	if yw.is_empty():
		return
	var t := float(yw.thick)
	var hgt := float(yw.height)
	var step := float(yw.step)
	var profile := [[-9, -t, 0]]
	for w: Dictionary in yw.walls:
		w.profile = profile
		walls_by_id[w.id] = w
	for w: Dictionary in yw.walls:
		var wall := _wall_dict(w)
		var L := float(wall.length)
		var holes := []
		for g: Dictionary in w.get("gates", []):
			var s := float(g.at)
			var p: Vector3 = (wall.origin as Vector3) + (wall.along as Vector3) * s
			var gy := ground(p.x, p.z)
			holes.append({"r": Rect2(s - float(g.width) * 0.5, gy, float(g.width), 99.0), "j": 0, "sill": false, "lintel": false, "gate": true})
		var n := maxi(1, roundi(L / step))
		for k in n:
			var a := L * k / n
			var e := L * (k + 1) / n
			var m: Vector3 = (wall.origin as Vector3) + (wall.along as Vector3) * ((a + e) * 0.5)
			var top := snappedf(ground(m.x, m.z) + hgt, 0.05)
			var ends := [w.ends[0] if k == 0 else null, w.ends[1] if k == n - 1 else null]
			_lay(wall, "%s/%d" % [w.id, k], a, e, top, profile, ends, holes, [])
		# The gates' leaves, two to a gate, standing open into the yard against the wall.
		for g: Dictionary in w.get("gates", []):
			var s := float(g.at)
			var gw := float(g.width)
			var p: Vector3 = (wall.origin as Vector3) + (wall.along as Vector3) * s
			var gy := ground(p.x, p.z) + 0.05
			var into := -(wall.out as Vector3)
			for e in 2:
				# Against the wall's inside face beside the opening, its hinge stile on the opening's edge.
				var hinge := s + (gw * 0.5 + 0.02) * (-1 if e == 0 else 1)
				var lw := gw * 0.5 - 0.04
				var c: Vector3 = (wall.origin as Vector3) + (wall.along as Vector3) * hinge + into * (t + lw * 0.5)
				c.y = gy + 1.2
				var size: Vector3 = into.abs() * lw + Vector3.UP * 2.4 + (wall.along as Vector3).abs() * 0.05
				b.add_member("gate/%s_%d_%d" % [w.id, int(s * 10), e], &"door", &"painted_rust", size, c)
