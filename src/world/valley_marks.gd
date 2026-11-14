class_name ValleyMarks
extends RefCounted
## What the valley's ground is at each of the bake's points, for the greybox (G4, #720;
## docs/briefs/valley-plan.md §11, §12): the roads and the town's streets at their widths, the
## places' pads and their outlines, the fords, the creek's and the arroyo's beds, the Baron's
## reserved range's edge. One byte a bake point (ValleyTerrain's grid, 2 m), painted once from
## config/valley.json; ValleyGround tints its vertex colours by it, so the marks are drawn as the
## ground is, at every level, with no meshes of their own (nothing to fight the ground's depth or
## to draw past its levels).
##
## Painted in order, a later kind over an earlier: pads, the water's beds, streets and roads (the
## wider classes first), fords, the outlines.

enum { NONE, PAD, WATER, STREET, WAGON, LANE, TRACK, PATH, FORD, OUTLINE }
const KIND_NAMES := ["none", "pad", "water", "street", "wagon", "lane", "track", "path", "ford", "outline"]
## A road's class -> its kind.
const CLASS_KIND := {"street": STREET, "wagon": WAGON, "lane": LANE, "track": TRACK, "path": PATH}
## Narrow roads are drawn at least this wide each side of their middle (m), so a 1 m path still
## covers a bake point wherever it runs.
const MIN_HALF := 1.2
## An outline's width (m: more than the bake's 2 m, so every edge has points), and a ford's patch round
## where the road meets the water (m).
const OUTLINE_W := 2.4
const FORD_RADIUS := 6.0

var width := 0
var depth := 0
var spacing := 2.0
var x0 := 0.0
var z0 := 0.0
## width x depth kinds, row by row along x (ValleyTerrain's order).
var kinds := PackedByteArray()
## How long painting took (ms).
var build_ms := 0.0

static var _main: ValleyMarks


## The game's marks (config/valley.json over the bake), painted the first time.
static func main() -> ValleyMarks:
	if _main == null:
		_main = ValleyMarks.make(ValleyLayout.main(), ValleyTerrain.main())
	return _main


static func make(l: ValleyLayout, t: ValleyTerrain) -> ValleyMarks:
	var m := ValleyMarks.new()
	var u := Time.get_ticks_usec()
	m.width = t.width
	m.depth = t.depth
	m.spacing = t.spacing
	m.x0 = t.x0
	m.z0 = t.z0
	m.kinds.resize(t.width * t.depth)
	m._paint(l)
	m.build_ms = (Time.get_ticks_usec() - u) / 1000.0
	return m


## The kind at bake point (i, j) (NONE off the grid).
func at_index(i: int, j: int) -> int:
	if i < 0 or j < 0 or i >= width or j >= depth:
		return NONE
	return kinds[j * width + i]


## The kind at the bake point nearest (x, z).
func at(x: float, z: float) -> int:
	return at_index(roundi((x - x0) / spacing), roundi((z - z0) / spacing))


## How many points of each kind ({name: count}).
func census() -> Dictionary:
	var n := []
	n.resize(KIND_NAMES.size())
	n.fill(0)
	for k in kinds:
		n[k] += 1
	var out := {}
	for i in range(1, n.size()):
		out[KIND_NAMES[i]] = n[i]
	return out


func _paint(l: ValleyLayout) -> void:
	# The places' pads, filled.
	for p: Dictionary in l.places():
		var pad: Dictionary = p.get("pad", {})
		if not pad.is_empty():
			_rect(ValleyLayout.xz(p.at), float(pad.w), float(pad.d), float(pad.get("heading", 90.0)), PAD, -1.0)
	# The water's beds (their flat floor's width: each row x, z, bed, half, floor, power).
	for key in ["creek", "arroyo"]:
		var rows: Array = l.water_rows(key)
		for i in range(1, rows.size()):
			var a: Array = rows[i - 1]
			var b: Array = rows[i]
			_segment(Vector2(a[0], a[1]), Vector2(b[0], b[1]), float(a[4]), float(b[4]), WATER)
	# The town's streets, then the roads, the widest classes first.
	for r: Dictionary in town_streets(l):
		_line(ValleyLayout.xz_line(r.line), float(r.width) * 0.5, STREET)
	var roads: Array = l.roads().duplicate()
	roads.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("width", 0)) > float(b.get("width", 0)))
	for r: Dictionary in roads:
		var kind: int = CLASS_KIND.get(String(r.get("class", "")), -1)
		if kind < 0:
			continue
		_line(ValleyLayout.xz_line(r.line), maxf(float(r.get("width", 2.0)) * 0.5, MIN_HALF), kind)
	for f: Dictionary in fords(l):
		_disc(f.at, FORD_RADIUS, FORD)
	# The outlines: every pad's, and a reserved area's edge.
	for p: Dictionary in l.places():
		var pad: Dictionary = p.get("pad", {})
		var area: Dictionary = p.get("area", {})
		if not pad.is_empty():
			_rect(ValleyLayout.xz(p.at), float(pad.w), float(pad.d), float(pad.get("heading", 90.0)), OUTLINE, OUTLINE_W)
		elif not area.is_empty():
			_rect(ValleyLayout.xz(p.at), float(area.w), float(area.d), 90.0, OUTLINE, OUTLINE_W * 2.0)


## The town's streets as roads ({id, width, line}): Main Street between its fronts, the North-South
## Street, Back Street, the rear lane and Creek Street (the residential rows' street), each its
## full width over its length (valley_plan.py draws them so on the town map).
static func town_streets(l: ValleyLayout) -> Array:
	var t := l.town()
	if t.is_empty():
		return []
	var out := []
	var ms: Dictionary = t.get("main_street", {})
	var mx := l.main_street_x()
	out.append({"id": "main_street", "width": float(ms.get("width_between_fronts", 20.0)), "line": [[mx.x, 0.0], [mx.y, 0.0]]})
	var ns: Dictionary = t.get("ns_street", {})
	if not ns.is_empty():
		out.append({"id": "ns_street", "width": float(ns.width), "line": [[float(ns.x), float(ns.z[0])], [float(ns.x), float(ns.z[1])]]})
	for key in ["back_street", "rear_lane"]:
		var s: Dictionary = t.get(key, {})
		if not s.is_empty():
			var zm := (float(s.z[0]) + float(s.z[1])) * 0.5
			out.append({"id": key, "width": absf(float(s.z[1]) - float(s.z[0])), "line": [[float(s.x[0]), zm], [float(s.x[1]), zm]]})
	for ex: Dictionary in t.get("extras", []):
		for row: Dictionary in ex.get("rows", []):
			if row.get("street", false):
				var zm := (float(row.z[0]) + float(row.z[1])) * 0.5
				out.append({"id": "creek_street", "width": absf(float(row.z[1]) - float(row.z[0])), "line": [[mx.x, zm], [mx.y, zm]]})
	return out


## Every ford on the roads: {road, what, at (Vector2)} (a road's `crosses` that says "ford").
static func fords(l: ValleyLayout) -> Array:
	var out := []
	for r: Dictionary in l.roads():
		for c: Dictionary in r.get("crosses", []):
			if "ford" in String(c.get("what", "")):
				out.append({"road": String(r.id), "what": String(c.what), "at": ValleyLayout.xz(c.at)})
	return out


## A line's points within `half` of it.
func _line(line: PackedVector2Array, half: float, kind: int) -> void:
	for i in range(1, line.size()):
		_segment(line[i - 1], line[i], half, half, kind)


## The points within a half-width (from ha at a to hb at b) of the segment a-b: walked a point's
## spacing at a time, each step the points round it tested against the segment itself (so the
## strip's edges are straight, and a long diagonal costs its length, not its box).
func _segment(a: Vector2, b: Vector2, ha: float, hb: float, kind: int) -> void:
	var ab := b - a
	var len := ab.length()
	var ll := maxf(len * len, 1e-9)
	var steps := maxi(1, ceili(len / spacing))
	var r := maxf(ha, hb) + spacing
	var cells := ceili(r / spacing)
	for k in steps + 1:
		var c := a + ab * (float(k) / steps)
		var ci := roundi((c.x - x0) / spacing)
		var cj := roundi((c.y - z0) / spacing)
		for j in range(maxi(0, cj - cells), mini(depth - 1, cj + cells) + 1):
			var z := z0 + j * spacing
			var row := j * width
			for i in range(maxi(0, ci - cells), mini(width - 1, ci + cells) + 1):
				if kinds[row + i] == kind:
					continue
				var p := Vector2(x0 + i * spacing, z)
				var t := clampf((p - a).dot(ab) / ll, 0.0, 1.0)
				if p.distance_to(a + ab * t) <= lerpf(ha, hb, t):
					kinds[row + i] = kind


func _disc(c: Vector2, r: float, kind: int) -> void:
	_segment(c, c, r, r, kind)


## A rectangle w (along its heading) x d about c, its heading in compass degrees (90: w along x, as a
## pad's); `ring` < 0 fills it, else only its edge, a band `ring` wide inside it (drawn as four
## segments: a reserved range's edge is kilometres long).
func _rect(c: Vector2, w: float, d: float, heading: float, kind: int, ring: float) -> void:
	var hd := deg_to_rad(heading)
	var u := Vector2(sin(hd), -cos(hd))
	var v := Vector2(-u.y, u.x)
	if ring >= 0.0:
		var hw := w * 0.5 - ring * 0.5
		var hh := d * 0.5 - ring * 0.5
		var corners := [c + u * hw + v * hh, c - u * hw + v * hh, c - u * hw - v * hh, c + u * hw - v * hh]
		for k in 4:
			_segment(corners[k], corners[(k + 1) % 4], ring * 0.5, ring * 0.5, kind)
		return
	var r := Vector2(w, d).length() * 0.5
	var lo := (c - Vector2(r, r) - Vector2(x0, z0)) / spacing
	var hi := (c + Vector2(r, r) - Vector2(x0, z0)) / spacing
	for j in range(maxi(0, floori(lo.y)), mini(depth - 1, ceili(hi.y)) + 1):
		for i in range(maxi(0, floori(lo.x)), mini(width - 1, ceili(hi.x)) + 1):
			var p := Vector2(x0 + i * spacing, z0 + j * spacing) - c
			if absf(p.dot(u)) <= w * 0.5 and absf(p.dot(v)) <= d * 0.5:
				kinds[j * width + i] = kind
