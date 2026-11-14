class_name MasonryExpander
extends RefCounted
## The masonry structure format's expander (config/destruction/structures/FORMAT.md, "The expander"):
## a file's authored walls laid out as elements (stones, blocks, adobes, brick clumps, footings) and
## the joints between them, seeded, so the same file and seed always give the same wall. The
## expanded form is written back into the file (tools/masonry_expand.gd) and committed: another
## engine reads `elements` and `joints` and never needs this script or Godot's random numbers.
##
## Pure data in, data out: no Node, no physics (tested headless, runs in a `-s` script).
## Coursed rubble (destruction-spec.md section 2; Baker 1889, ch. on rubble masonry): courses of
## roughly equal height, each stone's length and each course's height jittered by the material's
## `size_jitter`, head joints kept off those of the course below (`MIN_LAP` of a unit's length),
## the wall laid in `wall.wythes` leaves with `through_stones_per_m2` through-stones tying them.

## A head joint never lands closer than this share of a unit's length to one in the course below.
const MIN_LAP := 0.25
## A stretch left at a run's end shorter than this share of a unit is taken into its neighbour.
const MIN_PIECE := 0.5
## A course left at the top lower than this share of a unit's height is taken into the one below.
const MIN_COURSE := 0.6
## Decimals the expanded numbers are written with (stable files, the same on every machine).
const PLACES := 4
## Overlaps smaller than this (m) aren't contact.
const TOUCH := 0.001

var _rng := RandomNumberGenerator.new()


## `spec` (a structures/*.json file's Dictionary) with `elements` and `joints` worked out from its
## walls; the rest as given. `materials`: materials.json's Dictionary (MasonryMaterials.data()).
func expand(spec: Dictionary, materials: Dictionary) -> Dictionary:
	var out := spec.duplicate(true)
	var elements: Array = []
	var joints: Array = []
	_rng.seed = int(spec.get("seed", 1))
	var ground_y := float(spec.get("ground", {}).get("y", 0.0))
	for wall: Dictionary in spec.get("walls", []):
		_lay_wall(wall, materials, ground_y, elements, joints)
	out["elements"] = elements
	out["joints"] = joints
	return out


func _lay_wall(wall: Dictionary, materials: Dictionary, ground_y: float, elements: Array, joints: Array) -> void:
	var mat_id: String = wall.material
	var mat: Dictionary = materials.materials[mat_id]
	var unit: Dictionary = mat.unit
	var a := float(unit.size[0]) * float(mat.element.get("units_along", 1))
	var h := float(unit.size[1]) * float(mat.element.get("units_high", 1))
	var jitter := float(unit.get("size_jitter", 0.0))
	var thick := float(wall.get("thick", mat.wall.thick_typical))
	var wythes := int(mat.wall.get("wythes", 1))
	var through_p := float(mat.wall.get("through_stones_per_m2", 0.0))
	var from := Vector2(float(wall.from[0]), float(wall.from[1]))
	var to := Vector2(float(wall.to[0]), float(wall.to[1]))
	var length := from.distance_to(to)
	var dir := (to - from) / maxf(length, 1e-6)
	var turn := rad_to_deg(atan2(-dir.y, dir.x))  # about +y, x along the wall
	var bottom := float(wall.get("bottom", ground_y))
	var top := float(wall.get("top", bottom + 3.0))
	var mortar: String = mat.mortar
	var place := func(x: float, y: float, z: float) -> Array:
		# The wall's own space (x along, y up, z in from the outer face) into the file's.
		var p := from + dir * x + Vector2(-dir.y, dir.x) * z
		return [_r(p.x), _r(y), _r(p.y)]
	var shape_of := func(kind: String) -> String:
		return "%s/%d" % [String(unit.get("shape", "box")) if kind != "footing" else "footing", _rng.randi_range(0, 3)]
	# The footing: one course of long stones under the wall, wider than it, on the ground.
	var below: Array = []  # the course under: [{id, x0, x1, z0, z1, top}]
	var openings: Array = wall.get("openings", [])
	var footing: Dictionary = wall.get("footing", {})
	var wid: String = wall.id
	if not footing.is_empty():
		var f_mat: String = footing.get("material", mat_id)
		var deep := float(footing.get("deep", 0.3))
		var wider := float(footing.get("wider", 0.1))
		var row: Array = []
		var i := 0
		for run: Vector2 in _runs(length, 2.0 * a, jitter, [] as Array[float], 2.0 * a):
			var id := "%s/c00/w0/%02d" % [wid, i]
			var e := {"id": id, "material": f_mat, "kind": "footing",
				"at": place.call((run.x + run.y) * 0.5, bottom - deep * 0.5, thick * 0.5),
				"size": [_r(run.y - run.x), _r(deep), _r(thick + 2.0 * wider)], "turn": _r(turn),
				"course": 0, "wythe": 0, "shape": shape_of.call("footing"), "rests_on": ["ground"]}
			elements.append(e)
			row.append({"id": id, "x0": run.x, "x1": run.y, "z0": -wider, "z1": thick + wider, "h": deep})
			if i > 0:
				joints.append(_joint(row[i - 1].id, id, "head", deep * (thick + 2.0 * wider), mortar))
			i += 1
		below = row
	# The courses.
	var heights: Array[float] = []
	var y := bottom
	while top - y > 1e-4:
		var ch := h * _rng.randf_range(1.0 - jitter * 0.5, 1.0 + jitter * 0.5)
		if top - (y + ch) < h * MIN_COURSE:
			ch = top - y
		heights.append(ch)
		y += ch
	var leaf := thick / float(wythes)
	y = bottom
	for ci in heights.size():
		var course := ci + 1
		var ch: float = heights[ci]
		var row: Array = []
		# Through-stones first (wythe 0's runs, some made through the wall), then the other leaves
		# laid between them.
		var front := _runs(length, a, jitter, _ends(below, 0.0, leaf), a, openings, y, y + ch)
		var through: Array[Vector2] = []
		for run: Vector2 in front:
			if wythes > 1 and _rng.randf() < through_p * (run.y - run.x) * ch:
				through.append(run)
		for w in wythes:
			var z0 := leaf * w
			var z1 := leaf * (w + 1)
			var runs: Array[Vector2] = front if w == 0 else _runs(length, a, jitter, _ends(below, z0, z1), a, openings, y, y + ch, through)
			var i := 0
			for run: Vector2 in runs:
				var is_through := through.has(run)
				if is_through and w > 0:
					continue
				var zz1 := thick if is_through else z1
				var id := "%s/c%02d/w%d/%02d" % [wid, course, w, i]
				i += 1
				var rests: Array = []
				for b: Dictionary in below:
					if minf(run.y, b.x1) - maxf(run.x, b.x0) > TOUCH and minf(zz1, b.z1) - maxf(z0, b.z0) > TOUCH:
						rests.append(b.id)
						joints.append(_joint(id, b.id, "bed", (minf(run.y, b.x1) - maxf(run.x, b.x0)) * (minf(zz1, b.z1) - maxf(z0, b.z0)), mortar))
				if rests.is_empty():
					rests = ["ground"]
				var e := {"id": id, "material": mat_id, "kind": "through" if is_through else "unit",
					"at": place.call((run.x + run.y) * 0.5, y + ch * 0.5, (z0 + zz1) * 0.5),
					"size": [_r(run.y - run.x), _r(ch), _r(zz1 - z0)], "turn": _r(turn),
					"course": course, "wythe": w, "shape": shape_of.call("unit"), "rests_on": rests}
				elements.append(e)
				row.append({"id": id, "x0": run.x, "x1": run.y, "z0": z0, "z1": zz1, "h": ch})
		# Head joints (side by side, sharing depth) and collar joints (leaf to leaf, sharing length).
		for p in row.size():
			for q in range(p + 1, row.size()):
				var e1: Dictionary = row[p]
				var e2: Dictionary = row[q]
				var dz := minf(e1.z1, e2.z1) - maxf(e1.z0, e2.z0)
				var dx := minf(e1.x1, e2.x1) - maxf(e1.x0, e2.x0)
				if dz > TOUCH and absf(dx) <= TOUCH:
					joints.append(_joint(e1.id, e2.id, "head", ch * dz, mortar))
				elif dx > TOUCH and absf(dz) <= TOUCH:
					joints.append(_joint(e1.id, e2.id, "collar", ch * dx, mortar))
		below = row
		y += ch


## Where the course below has head joints, in the leaf z0..z1 (for keeping off them).
static func _ends(below: Array, z0: float, z1: float) -> Array[float]:
	var out: Array[float] = []
	for b: Dictionary in below:
		if minf(z1, b.z1) - maxf(z0, b.z0) > TOUCH:
			out.append(b.x0)
			out.append(b.x1)
	return out


## A course's leaf cut into runs (x0, x1) along 0..length: lengths about `a` jittered, kept
## `MIN_LAP` x `a` off `avoid` (the joints below), no stretch under MIN_PIECE x `a` (taken into its
## neighbour), never across an opening that this course's y0..y1 crosses, and broken at `fixed`
## runs (through-stones laid already: the leaf runs between them).
func _runs(length: float, a: float, jitter: float, avoid: Array[float], unit: float, openings := [],
		y0 := 0.0, y1 := 0.0, fixed: Array[Vector2] = []) -> Array[Vector2]:
	# The stretches to fill: the course minus openings and fixed runs.
	var gaps: Array[Vector2] = []
	for o: Dictionary in openings:
		if minf(y1, float(o.y[1])) - maxf(y0, float(o.y[0])) > TOUCH:
			gaps.append(Vector2(float(o.x[0]), float(o.x[1])))
	gaps.append_array(fixed)
	gaps.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
	var spans: Array[Vector2] = []
	var x := 0.0
	for g in gaps:
		if g.x - x > TOUCH:
			spans.append(Vector2(x, g.x))
		x = maxf(x, g.y)
	if length - x > TOUCH:
		spans.append(Vector2(x, length))
	var out: Array[Vector2] = []
	for sp in spans:
		var at := sp.x
		var run: Array[Vector2] = []
		while sp.y - at > TOUCH:
			var l := unit * _rng.randf_range(1.0 - jitter, 1.0 + jitter)
			var end := at + l
			# Off the joints below.
			for k in 3:
				var moved := false
				for j: float in avoid:
					if absf(end - j) < MIN_LAP * a:
						end = j + MIN_LAP * a * (1.0 if end >= j else -1.0)
						moved = true
				if not moved:
					break
			end = maxf(end, at + MIN_PIECE * a)
			if sp.y - end < MIN_PIECE * a:
				end = sp.y
			run.append(Vector2(at, end))
			at = end
		# A last piece too short (a span narrower than a half unit is one piece as it is).
		if run.size() > 1 and run[-1].y - run[-1].x < MIN_PIECE * a:
			var last := run.pop_back() as Vector2
			run[-1] = Vector2(run[-1].x, last.y)
		out.append_array(run)
	return out


static func _joint(a: String, b: String, type: String, area: float, mortar: String) -> Dictionary:
	return {"a": a, "b": b, "type": type, "area": _r(area), "mortar": mortar}


static func _r(v: float) -> float:
	return snappedf(v, pow(10.0, -PLACES))


## The expanded file as text (tabs, keys in the file's order, numbers as written): what
## tools/masonry_expand.gd writes and the test compares.
static func to_text(spec: Dictionary) -> String:
	return JSON.stringify(spec, "\t", false) + "\n"
