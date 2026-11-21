class_name LogWall
extends RefCounted
## A wall of hewn logs as members (#1126, Harlan's cabin; the line shack and later homesteads use it):
## the part a spec's outer wall takes with `log: true` (FORMAT.md "A log building's parts"), laid by
## SpecBuilding in place of studs, siding and finish. Every piece is a member of the building, so it
## breaks, burns and can be replaced as a board does:
##
## - **Courses of hewn logs** (`<wall>/log/<course>_<piece>`), each log flat-hewn inside and out to
##   the wall's `thick`, `log` high, lying on the course under it through a band of **chinking**
##   (`<wall>/chink/<course>_<piece>`: split wood and lime daub, kind `sill` as the log, set in from
##   both faces so the logs stand proud of it). Both are kind `sill`: a log rests on the chinking under
##   it and that on the log under it (the support ladder's "beneath"), the bottom course on the sill.
## - **The corners notched**: course by course one wall's log runs through the corner and `over` past
##   it, the other's butts against it; the next course the other way about (the logs' ends alternate up
##   the corner, as a notched corner's do; Kniffen and Glassie 1966, "Building in Wood in the Eastern
##   United States", the square-hewn half-dovetail's look; the courses here stay level all round, so a
##   log's end lands on the crossing log's top and not on air). No chinking past a corner.
## - **Openings framed in the logs**: the courses cut either side of a door or window, a plank buck
##   (`<wall>/opening<j>/buck/jamb0|jamb1|head|sill`, 2 in thick through the wall) pinned to the cut ends, the
##   log over the head spanning the opening on the logs beside it (Weslager 1969, "The Log Cabin in
##   America": the door and windows sawn out after the walls were raised, then cased with boards).
##   What goes in the opening (the leaf, the sash) is the builder's (SashWindow, `_leaf`).
## - **A gable of boards** over the top log on a `top: "gable"` wall: studs on the top log, vertical
##   boards with battens lapping the top log by `lap`, cut to the roof's underside.
##
## A log is drawn by the building's finishes as a board is (spec.materials.surfaces `/log/`), the
## chinking in its own wood. A piece named in `new` (its course and piece, `[c, p]`) is a replaced log:
## its id ends `_new` (a surface pattern gives it the pale new wood).

## A log wall's numbers (spec.frame.log_wall), in metres: `thick` the hewn faces apart, `course` a log
## and its chinking, `chink` the chinking's height, `inset` how far the chinking stands back from each
## face, `over` a log's end past the corner, `piece` the longest log, `buck` the plank buck's thickness
## (along the wall), `wood` the logs' wood, `chink_wood` the daub's.
const DEFAULTS := {"thick": 0.17, "course": 0.27, "chink": 0.05, "inset": 0.025, "over": 0.14, "piece": 6.5,
		"buck": 0.05, "wood": "framing", "chink_wood": "stone", "lap": 0.06, "gable_wood": "weathered_pine",
		"stud_spacing": 0.61}


static func numbers(fr: Dictionary) -> Dictionary:
	var n := DEFAULTS.duplicate()
	n.merge(fr.get("log_wall", {}), true)
	return n


## How many courses a wall from `foot` to `top` takes, and each one's height (the spec's course,
## stretched or squeezed a little so the top log's top is the plate).
static func courses(foot: float, top: float, lw: Dictionary) -> Vector2:
	var n := maxi(1, roundi((top - foot) / float(lw.course)))
	return Vector2(n, (top - foot) / n)


## Lay the wall `w` (its spec) on `wall` (the builder's wall dict: its line the logs' outer face, `out`
## outward, x along it from the line's start) from `foot` (the sill's top) to `top` (the plate: the top
## log's top). `rects` its openings (x along, y up). `passes` whether this wall's log runs through its
## corners on the even courses (the other walls on the odd). `gable_top` (a Callable x -> y, or null):
## the roof's underside over a gable wall. Returns what it made.
static func lay(b: FalseFrontBuilding, wall: Dictionary, w: Dictionary, rects: Array[Rect2], lw: Dictionary,
		foot: float, top: float, passes: bool, gable_top: Variant = null) -> Array[StructureMember]:
	var made: Array[StructureMember] = []
	var n: String = wall.name
	var length: float = wall.length
	var t := float(lw.thick)
	var over := float(lw.over)
	var ch := float(lw.chink)
	var ins := float(lw.inset)
	var buck := float(lw.buck)
	var wood := StringName(lw.wood)
	var cw := StringName(lw.chink_wood)
	var cn := courses(foot, top, lw)
	var h := cn.y
	var news: Array = w.get("new", [])
	# A course is cut where an opening (with its bucks) crosses it.
	for c in int(cn.x):
		var y0 := foot + h * c
		var y1 := y0 + h
		var log_top := y1 - ch if c < int(cn.x) - 1 else y1  # the top log carries the plate's height
		var through := (c % 2 == 0) == passes
		var s0 := -over if through else t
		var s1 := length + over if through else length - t
		var cuts: Array[Vector2] = []
		for o in rects:
			if o.position.y < y1 - 0.01 and o.end.y > y0 + 0.01:
				cuts.append(Vector2(o.position.x - buck, o.end.x + buck))
		var spans := _spans(s0, s1, cuts, float(lw.piece))
		for p in spans.size():
			var sp: Vector2 = spans[p]
			var id := "%s/log/%02d_%d" % [n, c, p]
			if news.has([c, p]) or news.has([float(c), float(p)]):
				id += "_new"
			var m := b._wall_member(id, &"sill", wood, wall, sp.x, sp.y, y0, log_top, -t, 0.0)
			m.set_meta(&"log", true)
			made.append(m)
			if log_top < y1 - 0.001:
				# The chinking over it, inside the wall's body (none past the corners: air between the ends).
				var a := maxf(sp.x, 0.0)
				var e := minf(sp.y, length)
				if e - a > 0.04:
					made.append(b._wall_member("%s/chink/%02d_%d" % [n, c, p], &"sill", cw, wall, a, e, log_top, y1, -t + ins, -ins))
	# The bucks: plank jambs the opening's height, a head over it to the course over the opening, a
	# sill board under a window, all through the wall's thickness.
	for j in rects.size():
		var o := rects[j]
		# (named by the opening's place in the wall's list, as the stud walls' kings and headers are:
		# Checks.built_right reads `<wall>/opening<j>/`)
		var bid := "%s/opening%d/buck" % [n, j]
		# The head buck up to the bottom of the first course whose log spans the opening.
		var k := ceili((o.end.y - foot) / h - 0.001)
		var head_top := minf(foot + h * k, top)
		var bottom := o.position.y
		if bottom > foot + 0.02:
			# A window: its sill board on the log under it, the course's top at the sill.
			var kb := floori((o.position.y - foot) / h + 0.001)
			var under := foot + h * kb
			made.append(b._wall_member(bid + "/sill", &"stud", &"framing", wall, o.position.x - buck, o.end.x + buck, under, o.position.y, -t, 0.0))
		else:
			bottom = foot
		made.append(b._wall_member(bid + "/jamb0", &"stud", &"framing", wall, o.position.x - buck, o.position.x, bottom, o.end.y, -t, 0.0))
		made.append(b._wall_member(bid + "/jamb1", &"stud", &"framing", wall, o.end.x, o.end.x + buck, bottom, o.end.y, -t, 0.0))
		if head_top > o.end.y + 0.01:
			made.append(b._wall_member(bid + "/head", &"stud", &"framing", wall, o.position.x - buck, o.end.x + buck, o.end.y, head_top, -t, 0.0))
	if gable_top is Callable:
		_gable(b, wall, lw, top, gable_top, made)
	return made


## The pieces of [s0, s1] left round `cuts`, none longer than `piece` (a long wall's logs scarfed).
static func _spans(s0: float, s1: float, cuts: Array[Vector2], piece: float) -> Array[Vector2]:
	var spans: Array[Vector2] = [Vector2(s0, s1)]
	for c in cuts:
		var nxt: Array[Vector2] = []
		for sp in spans:
			if c.y <= sp.x or c.x >= sp.y:
				nxt.append(sp)
				continue
			if c.x - sp.x > 0.05:
				nxt.append(Vector2(sp.x, c.x))
			if sp.y - c.y > 0.05:
				nxt.append(Vector2(c.y, sp.y))
		spans = nxt
	var out: Array[Vector2] = []
	for sp in spans:
		var k := maxi(1, ceili((sp.y - sp.x) / piece))
		for i in k:
			out.append(Vector2(lerpf(sp.x, sp.y, float(i) / k), lerpf(sp.x, sp.y, float(i + 1) / k)))
	return out


## A board gable over the top log: studs standing on it at `stud_spacing`, each cut to the roof's
## underside, vertical boards nailed to them lapping down over the top log, a batten on every joint.
static func _gable(b: FalseFrontBuilding, wall: Dictionary, lw: Dictionary, top: float, gable_top: Callable, made: Array[StructureMember]) -> void:
	var n: String = wall.name
	var length: float = wall.length
	var t := float(lw.thick)
	var gw := StringName(lw.gable_wood)
	var sp := float(lw.stud_spacing)
	var x := 0.3
	var i := 0
	while x < length - 0.3:
		var ht: float = gable_top.call(x) - 0.03
		if ht - top > 0.12:
			made.append(b._wall_member("%s/gable/stud_%d" % [n, i], &"stud", &"framing", wall, x - 0.025, x + 0.025, top, ht, -t * 0.5 - 0.05, -t * 0.5 + 0.05))
		x += sp
		i += 1
	# A ledger along the top log's outer face carries the boards' feet (they hang on it, nailed).
	made.append(b._wall_member("%s/gable/nailer" % n, &"plate", &"framing", wall, 0.0, length, top, top + 0.09, -t * 0.5 + 0.05, 0.0))
	var bw := FalseFrontBuilding.VERTICAL_BOARD_W
	var lap := float(lw.lap)
	var x0 := 0.0
	var k := 0
	while x0 < length - 0.02:
		var x1 := minf(x0 + bw, length)
		var ht: float = minf(gable_top.call(x0), gable_top.call(x1))
		if ht > top + 0.05:
			made.append(b._wall_member("%s/gable/board_%02d" % [n, k], &"board", gw, wall, x0, x1 - 0.004, top - lap, ht, 0.0, FalseFrontBuilding.BOARD_T))
			if x1 < length - 0.02:
				var hb: float = minf(gable_top.call(x1 - 0.03), gable_top.call(x1 + 0.03))
				if hb > top + 0.08:
					made.append(b._wall_member("%s/gable/batten_%02d" % [n, k], &"trim", gw, wall, x1 - 0.03, x1 + 0.03, top - lap, hb, FalseFrontBuilding.BOARD_T, FalseFrontBuilding.BOARD_T + 0.018))
		x0 = x1
		k += 1
