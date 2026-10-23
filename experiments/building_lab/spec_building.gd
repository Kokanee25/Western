extends FalseFrontBuilding
## A building built from its spec (experiments/building_lab/FORMAT.md; the saloon's is saloon.json):
## the building lab's builder (docs/briefs/building-pipeline.md, step 3). Everything it makes is a
## member of this structure, a kit prop (PropKit), a fitting that falls with what holds it (an
## OilLamp on a member), or one of the few exceptions the destructibility test lists. It changes
## nothing in the game: it reuses FalseFrontBuilding's wall helpers (`_wall`, `_wall_member`,
## `_lap_siding`, `_vertical_siding`, `_opening_trim`, `_glass`, `_build_door`, `_build_batwings`,
## `_table`, `_shelves`) and adds, here, what a second storey needs:
##
## - **Bands of the support ladder.** StructureMember's tiers are one ladder (sill, post, stud,
##   plate, board, trim), enough for one storey: a joist can't rest on a beam, nor a floor board on
##   an upper joist, nor a partition's stud on a floor board. Every member here also has a band (its
##   meta `band`, set by `band` as it's added): it rests on what it touches in a lower band, and
##   within its band by the usual ladder. 0 the foundation, posts and beams; 1 the ground floor and
##   the outer walls; 2 what stands on the ground floor; 3 the upper floor and balconies; 4 what
##   stands on that; 5 the trusses; 6 the roof's covering (FORMAT.md "Bands").
## - **A broadphase.** Structure.infer_supports tries every pair (977 members, 0.4 s; this saloon
##   has ~6000); this one tries the pairs that share a 2 m cell, with the same rules and order.
## - **Ramps that go with their stair** (a stair's walking ramp is freed once its stringers break).

const Stair := preload("res://experiments/building_lab/stair.gd")
const Marks := preload("res://experiments/building_lab/marks.gd")
const CELL := 2.0
const SPEC := "res://experiments/building_lab/saloon.json"

var spec_path := SPEC
var spec: Dictionary
## The band members added now go in (see the top).
var band := 0
## [StaticBody3D ramp, [stringers]] for each stair.
var ramps: Array = []
var lamps: Array[OilLamp] = []
var kit_props: Array[KitProp] = []
## What the lived-in pass marked (Marks.place: by cause, by kind, what it couldn't place).
var marks := {}
## Where things are: the walls (id -> {wall dict, finish faces}), the levels' heights.
var walls := {}
var _lv := {}
var _fr := {}
var _furnish: Node3D
var _ramp_t := 0.0


func _init() -> void:
	structure_id = &"saloon_spec"
	furnished = false
	porch = false


static func load_spec(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func add_member(id_path: String, kind: StringName, wood: StringName, size: Vector3, center: Vector3, basis := Basis()) -> StructureMember:
	var m := super(id_path, kind, wood, size, center, basis)
	m.set_meta(&"band", band)
	return m


# --- the support ladder in bands ------------------------------------------------------------------

func _tier(m: StructureMember) -> int:
	return StructureMember.tier_of(m.kind) + 10 * int(m.get_meta(&"band", 0))


func _place_in_stack(m: StructureMember, box: AABB) -> void:
	m.grounded = StructureMember.tier_of(m.kind) <= 1 and box.position.y <= GROUND_EPSILON
	m.stack_key = _tier(m) * 100.0 + box.position.y


func _link(m: StructureMember, box: AABB, other: StructureMember, other_box: AABB) -> void:
	var grown := box.grow(CONTACT_EPSILON)
	if not grown.intersects(other_box):
		return
	m.touching.append(other.member_id)
	var tier := _tier(m)
	var other_tier := _tier(other)
	var beneath := other_tier == tier and other.kind == m.kind and other_box.end.y <= box.position.y + CONTACT_EPSILON \
			and other_box.position.y < box.position.y - CONTACT_EPSILON
	if other_tier < tier or beneath:
		m.supported_by.append(other.member_id)
		var contact := grown.intersection(other_box)
		m.support_points[other.member_id] = contact.get_center()
		m.support_boxes[other.member_id] = contact


## Structure.infer_supports with a grid: the same links in the same order, from the pairs that
## share a cell.
func infer_supports() -> void:
	_by_stack.clear()
	var boxes := {}
	var grid := {}
	for i in _order.size():
		var m := _order[i]
		var b := m.structure_aabb()
		boxes[m] = b
		for c in _cells(b.grow(CONTACT_EPSILON)):
			if not grid.has(c):
				grid[c] = []
			(grid[c] as Array).append(i)
	for i in _order.size():
		var m := _order[i]
		m.supported_by.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
		var box: AABB = boxes[m]
		_place_in_stack(m, box)
		var seen := {}
		for c in _cells(box.grow(CONTACT_EPSILON)):
			for j: int in grid.get(c, []):
				seen[j] = true
		var near: Array = seen.keys()
		near.sort()
		for j: int in near:
			if j != i:
				_link(m, box, _order[j], boxes[_order[j]])


static func _cells(b: AABB) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var lo := Vector3i((b.position / CELL).floor())
	var hi := Vector3i((b.end / CELL).floor())
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				out.append(Vector3i(x, y, z))
	return out


# --- the build ------------------------------------------------------------------------------------

func build() -> void:
	if spec.is_empty():
		spec = load_spec(spec_path)
	var lot: Dictionary = spec.lot
	var lv: Dictionary = spec.levels
	_fr = spec.frame
	width = float(lot.width)
	depth = float(lot.depth)
	floor_top = float(lv.ground.top)
	wall_height = float(lv.plate)
	front_height = float(lv.false_front)
	roof_pitch_degrees = float(lv.roof_pitch)
	sign_text = String(spec.front.sign)
	sign_from = float(spec.front.sign_from)
	var joist: Array = _fr.joist.section
	_lv = {
		"cellar": float(lv.cellar.floor), "ground": floor_top, "upper": float(lv.upper.top),
		"ground_joist_bottom": floor_top - float(_fr.floor_board.thick) - float(joist[1]),
		"upper_joist_bottom": float(lv.upper.top) - float(_fr.floor_board.thick) - float(joist[1]),
	}
	ramps.clear()
	lamps.clear()
	kit_props.clear()
	walls.clear()
	# What the last build made that isn't a member (Structure.rebuild frees only those).
	for c in get_children():
		if c == _furnish or String(c.name).begins_with("Ramp_") or c.name in [&"InteriorAmbient", &"RoomHaze"]:
			c.free()
	_furnish = Node3D.new()
	_furnish.name = "Furnishings"
	add_child(_furnish)

	band = 0
	_foundation()
	_cellar()
	_posts_and_beams()
	band = 1
	_ground_floor()
	_outer_walls()
	band = 2
	_partitions("ground", 2)
	_stairs_inside()
	band = 3
	_upper_floors()
	_balconies()
	_gallery_rails()
	band = 4
	_partitions("upper", 4)
	_outside_stair()
	band = 1
	_false_front()
	band = 5
	_trusses()
	band = 6
	_roof_cover()
	_chandelier()
	band = 2
	_furniture_members()
	band = 0
	_outbuildings()
	_lamps()
	_kit()
	_use_points()
	_add_interior_ambient()
	marks = Marks.place(self, spec)


# --- foundation, cellar, posts and beams (band 0) -------------------------------------------------

func _foundation() -> void:
	var f: Dictionary = _fr.foundation
	var t := float(f.thick)
	var top := float(f.top)
	var w := width
	var d := depth
	var cel: Array = spec.cellar.rect
	var floor: float = _lv.cellar
	# The perimeter wall, in pieces (a charge breaks a length of it), down to the cellar's floor
	# where it walls the cellar.
	var runs := [["front", Vector2(0, 0), Vector2(w, 0)], ["back", Vector2(0, d - t), Vector2(w, d - t)],
			["west", Vector2(0, t), Vector2(0, d - t)], ["east", Vector2(w - t, t), Vector2(w - t, d - t)]]
	for r in runs:
		_stone_run("foundation/" + r[0], r[1], r[2], t, top, cel, floor)
	# The cellar's own walls inside the house: on each side of its rect that isn't the outer wall.
	var c0 := Vector2(cel[0], cel[1])
	var c1 := Vector2(cel[2], cel[3])
	# Along x from inside the outer wall (or past the corner), along z the same.
	var xa := t if c0.x < 0.01 else c0.x - t * 0.5
	var xb := w - t if c1.x > w - 0.01 else c1.x + t * 0.5
	var za := (t if c0.y < 0.01 else c0.y + t * 0.5)
	var zb := (d - t if c1.y > d - 0.01 else c1.y - t * 0.5)
	if c0.y > 0.01:
		_stone_run("cellar/wall_z0", Vector2(xa, c0.y - t * 0.5), Vector2(xb, c0.y - t * 0.5), t, top, [], floor)
	if c1.y < d - 0.01:
		_stone_run("cellar/wall_z1", Vector2(xa, c1.y - t * 0.5), Vector2(xb, c1.y - t * 0.5), t, top, [], floor)
	if c0.x > 0.01:
		_stone_run("cellar/wall_x0", Vector2(c0.x - t * 0.5, za), Vector2(c0.x - t * 0.5, zb), t, top, [], floor)
	if c1.x < w - 0.01:
		_stone_run("cellar/wall_x1", Vector2(c1.x - t * 0.5, za), Vector2(c1.x - t * 0.5, zb), t, top, [], floor)
	# Wood sills on the wall's top, under the studs.
	var sill: Array = _fr.sill.section
	var sy := top + float(sill[1]) * 0.5
	_pieces("sill/front", Vector3(0, sy, float(sill[0]) * 0.5), Vector3.RIGHT, w, Vector2(sill[1], sill[0]), &"sill", &"framing")
	_pieces("sill/back", Vector3(0, sy, d - float(sill[0]) * 0.5), Vector3.RIGHT, w, Vector2(sill[1], sill[0]), &"sill", &"framing")
	_pieces("sill/west", Vector3(float(sill[0]) * 0.5, sy, float(sill[0])), Vector3.BACK, d - float(sill[0]) * 2.0, Vector2(sill[1], sill[0]), &"sill", &"framing")
	_pieces("sill/east", Vector3(w - float(sill[0]) * 0.5, sy, float(sill[0])), Vector3.BACK, d - float(sill[0]) * 2.0, Vector2(sill[1], sill[0]), &"sill", &"framing")


## A stone wall along x or z from a to b (its near edge on the line), `t` thick, in pieces; where it
## runs along the cellar's rect it goes down to the cellar's floor.
func _stone_run(id: String, a: Vector2, b: Vector2, t: float, top: float, cellar: Array, cellar_floor: float) -> void:
	var piece := float(_fr.foundation.piece)
	var bottom := float(_fr.foundation.bottom)
	var along_x := absf(b.y - a.y) < 0.001
	var length := (b.x - a.x) if along_x else (b.y - a.y)
	var n := maxi(1, ceili(length / piece))
	for i in n:
		var s0 := length * i / n
		var s1 := length * (i + 1) / n
		var c0 := Vector2(a.x + s0, a.y) if along_x else Vector2(a.x, a.y + s0)
		var c1 := Vector2(a.x + s1, a.y + t) if along_x else Vector2(a.x + t, a.y + s1)
		var mid := (c0 + c1) * 0.5
		# The cellar's own walls go down to its floor; the outer wall does where it walls the cellar.
		var low := cellar_floor if cellar.is_empty() else bottom
		if not cellar.is_empty() and mid.x > float(cellar[0]) and mid.x < float(cellar[2]) and mid.y > float(cellar[1]) and mid.y < float(cellar[3]):
			low = cellar_floor
		var size := Vector3(c1.x - c0.x, top - low, c1.y - c0.y)
		add_member("%s/%02d" % [id, i], &"sill", &"stone", size, Vector3(mid.x, (top + low) * 0.5, mid.y))


func _cellar() -> void:
	var c: Dictionary = spec.cellar
	var r: Array = c.rect
	var t := float(_fr.foundation.thick)
	var floor: float = _lv.cellar
	# Stone flags on the cellar's floor.
	var flag := float(c.flag)
	# Inside its walls: the outer wall's full thickness, the cellar's own walls' half.
	var x_lo := float(r[0]) + (t if float(r[0]) < 0.01 else t * 0.5)
	var x_hi := float(r[2]) - (t if float(r[2]) > width - 0.01 else t * 0.5)
	var z_lo := float(r[1]) + (t if float(r[1]) < 0.01 else t * 0.5)
	var z_hi := float(r[3]) - (t if float(r[3]) > depth - 0.01 else t * 0.5)
	var x := x_lo
	var i := 0
	while x < x_hi - 0.05:
		var x1 := minf(x + flag, x_hi)
		var z := z_lo
		while z < z_hi - 0.05:
			var z1 := minf(z + flag, z_hi)
			add_member("cellar/flag/%02d" % i, &"sill", &"stone", Vector3(x1 - x - 0.01, 0.08, z1 - z - 0.01), Vector3((x + x1) * 0.5, floor + 0.04, (z + z1) * 0.5))
			i += 1
			z = z1
		x = x1
	# Its posts under the girders.
	var g: Array = _fr.girder.section
	var top := float(_fr.foundation.top)
	for k in (c.posts as Array).size():
		var p: Array = c.posts[k]
		var m := add_member("cellar/post/%d" % k, &"post", &"framing", Vector3(0.2, top - floor - 0.08, 0.2), Vector3(p[0], (top + floor + 0.08) * 0.5, p[1]))
		m.set_meta(&"girder_post", true)


func _posts_and_beams() -> void:
	var ps: Array = _fr.post.section
	var bs: Array = _fr.beam.section
	var top := float(_fr.foundation.top)
	var pier := float(_fr.pier.size)
	var beam_top: float = _lv.upper_joist_bottom
	var beam_bottom := beam_top - float(bs[1])
	for k in (spec.posts.free as Array).size():
		var p: Array = spec.posts.free[k]
		add_member("pier/post_%02d" % k, &"sill", &"stone", Vector3(pier, top + 0.3, pier), Vector3(p[0], (top - 0.3) * 0.5, p[1]))
		var m := add_member("post/%02d" % k, &"post", &"framing", Vector3(ps[0], beam_bottom - top, ps[1]), Vector3(p[0], (beam_bottom + top) * 0.5, p[1]))
		PropKit.dress_member(m, {"shape": "profile", "profile": "chamfered", "along": "y", "up": "z", "args": [float(_fr.post.chamfer)]}, String(_fr.post.look))
	var wp: Array = _fr.wall_post.section
	var sill_top := top + float(_fr.sill.section[1])
	for k in (spec.posts.wall as Array).size():
		var p: Array = spec.posts.wall[k]
		var on_x := float(p[0]) < 0.3 or float(p[0]) > width - 0.3
		var size := Vector3(0.1, beam_bottom - sill_top, wp[0]) if on_x else Vector3(wp[0], beam_bottom - sill_top, 0.1)
		var cx := (0.05 if float(p[0]) < 0.3 else width - 0.05) if on_x else float(p[0])
		add_member("wall_post/%d" % k, &"post", &"framing", size, Vector3(cx, (beam_bottom + sill_top) * 0.5, p[1]))
	for b: Dictionary in spec.beams:
		var a := Vector3(b.from[0], 0, b.from[1])
		var e := Vector3(b.to[0], 0, b.to[1])
		var dir := (e - a).normalized()
		# Pieces between the posts on it (a beam is cut over a post), each its own member.
		var cuts: Array[float] = [0.0]
		for p: Array in spec.posts.free:
			var q := Vector3(p[0], 0, p[1]) - a
			var s := q.dot(dir)
			if q.distance_to(dir * s) < 0.05 and s > 0.5 and s < a.distance_to(e) - 0.5:
				cuts.append(s)
		cuts.append(a.distance_to(e))
		cuts.sort()
		for i in cuts.size() - 1:
			var s0 := cuts[i]
			var s1 := cuts[i + 1]
			var c := a + dir * ((s0 + s1) * 0.5)
			c.y = (beam_top + beam_bottom) * 0.5
			var size := dir.abs() * (s1 - s0) + Vector3.UP * float(bs[1]) + Vector3(dir.z, 0, dir.x).abs() * float(bs[0])
			var m := add_member("beam/%s/%d" % [b.id, i], &"beam", &"framing", size, c)
			PropKit.dress_member(m, {"shape": "profile", "profile": "chamfered", "along": "x" if absf(dir.x) > 0.5 else "z", "up": "y", "args": [float(_fr.beam.chamfer)]}, String(_fr.beam.look))
		# Brackets under it, each side of each post along it.
		for p: Array in spec.posts.free:
			var q := Vector3(p[0], 0, p[1]) - a
			var s := q.dot(dir)
			if q.distance_to(dir * s) > 0.05 or s < -0.05 or s > a.distance_to(e) + 0.05:
				continue
			for side in [-1.0, 1.0]:
				var reach := float(_fr.bracket.reach)
				if s + side * (float(ps[0]) * 0.5 + reach) < 0.0 or s + side * (float(ps[0]) * 0.5 + reach) > a.distance_to(e):
					continue
				_bracket("bracket/%s/%d_%d" % [b.id, int(s * 100), int(side)], Vector3(p[0], beam_bottom, p[1]), dir * side, float(ps[0]) * 0.5)


## A curved bracket under a beam against a post: `at` the post's centre at the beam's underside,
## `out` along the beam away from the post.
func _bracket(id: String, at: Vector3, out: Vector3, half_post: float) -> void:
	var l := float(_fr.bracket.reach)
	var t := float(_fr.bracket.thick)
	var along_x := absf(out.x) > 0.5
	var size := Vector3(l, l, t) if along_x else Vector3(t, l, l)
	var c := at + out * (half_post + l * 0.5) + Vector3.DOWN * (l * 0.5)
	var m := add_member(id, &"trim", &"framing", size, c)
	# The cove from the beam's underside down the post, in the member's own space (its centre the
	# box's): along the beam from the post, down from the beam.
	var lip := 0.035
	var pts := [[0.0, 0.0], [l, 0.0], [l, -lip]]
	for i in range(1, 12):
		var ang := PI * 0.5 + PI * 0.5 * float(i) / 12.0
		pts.append([l + cos(ang) * (l - lip), -l + sin(ang) * (l - lip)])
	pts.append([lip, -l])
	pts.append([0.0, -l])
	var sign := (out.x if along_x else out.z)
	var outline: Array = []
	for p in pts:
		outline.append([(float(p[0]) - l * 0.5) * sign, float(p[1]) + l * 0.5])
	if sign < 0.0:
		outline.reverse()
	PropKit.dress_member(m, {"shape": "cut", "outline": outline, "plane": "xy" if along_x else "zy"}, String(_fr.bracket.look))


## Lengths of timber along `dir` from `start` (its centre line), cut every ~4.9 m (stock lengths).
func _pieces(id: String, start: Vector3, dir: Vector3, length: float, section: Vector2, kind: StringName, wood: StringName, look := "") -> void:
	var n := maxi(1, ceili(length / 4.9))
	for i in n:
		var s0 := length * i / n
		var s1 := length * (i + 1) / n
		var size := dir.abs() * (s1 - s0 - 0.004) + Vector3.UP * section.x + Vector3(dir.z, 0, dir.x).abs() * section.y
		var m := add_member("%s/%d" % [id, i], kind, wood, size, start + dir * ((s0 + s1) * 0.5))
		if look != "":
			PropKit.dress_member(m, {}, look)


# --- floors ---------------------------------------------------------------------------------------

func _ground_floor() -> void:
	var g: Array = _fr.girder.section
	var top := float(_fr.foundation.top)
	var pier := float(_fr.pier.size)
	var every := float(_fr.girder.pier_every)
	var cel: Array = spec.cellar.rect
	var gz: Array = spec.girders.z
	band = 1
	for z: float in gz:
		# Piers under it outside the cellar; inside, the cellar's posts (or its front wall).
		var x := every
		var k := 0
		while x < width - 0.4:
			var in_cellar := x > float(cel[0]) - 0.2 and x < float(cel[2]) + 0.2 and z > float(cel[1]) - 0.2 and z < float(cel[3]) + 0.2
			if not in_cellar:
				band = 0
				add_member("pier/g%d_%02d" % [int(z * 100), k], &"sill", &"stone", Vector3(pier, top + 0.3, pier), Vector3(x, (top - 0.3) * 0.5, z))
				band = 1
			x += every
			k += 1
		_pieces("girder/%d" % int(z * 100), Vector3(0.2, top + float(g[1]) * 0.5, z), Vector3.RIGHT, width - 0.4, Vector2(g[1], g[0]), &"sill", &"framing")
	for f: Dictionary in spec.floors:
		if f.level == "ground":
			_floor(f, gz)


func _upper_floors() -> void:
	for f: Dictionary in spec.floors:
		if f.level == "upper":
			_floor(f, [])


## A floor: joists along its `joists` axis at their spacing across `rect` (cut at `breaks` along
## them, the girders), framed round its openings (headers on the trimmers, the cut joists on the
## headers), the boards across them.
func _floor(f: Dictionary, breaks: Array) -> void:
	var r: Array = f.rect
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var js: Array = _fr.joist.section
	var spacing := float(_fr.joist.spacing)
	var top := _lv[f.level] as float
	var bt := float(_fr.floor_board.thick)
	var jt := top - bt
	var jb := jt - float(js[1])
	var along_z: bool = f.joists == "z"
	var openings: Array = f.get("openings", [])
	var id: String = "floor/" + f.id
	var a0 := x0 if along_z else z0  # across the joists
	var a1 := x1 if along_z else z1
	var l0 := z0 if along_z else x0  # along them
	var l1 := z1 if along_z else x1
	var stops: Array[float] = [l0]
	for b: float in breaks:
		if b > l0 + 0.3 and b < l1 - 0.3:
			stops.append(b)
	stops.append(l1)
	var lines: Array[float] = []
	var p := a0 + float(js[0]) * 0.5 + 0.02
	while p < a1 - float(js[0]) * 0.5:
		lines.append(p)
		p += spacing
	if a1 - float(js[0]) * 0.5 - lines.back() > 0.15:
		lines.append(a1 - float(js[0]) * 0.5 - 0.005)
	var n := 0
	for li in lines.size():
		var q := lines[li]
		for si in stops.size() - 1:
			var s0 := stops[si]
			var s1 := stops[si + 1]
			# The stretch an opening takes out of this joist.
			var parts: Array = [[s0, s1]]
			for o: Dictionary in openings:
				var orr: Array = o.rect
				var oa0 := float(orr[0]) if along_z else float(orr[1])
				var oa1 := float(orr[2]) if along_z else float(orr[3])
				var ol0 := float(orr[1]) if along_z else float(orr[0])
				var ol1 := float(orr[3]) if along_z else float(orr[2])
				if q > oa0 and q < oa1 and ol0 < s1 and ol1 > s0:
					parts = [[s0, ol0 - float(js[0]) * 0.5], [ol1 + float(js[0]) * 0.5, s1]]
			for pr: Array in parts:
				if float(pr[1]) - float(pr[0]) < 0.1:
					continue
				var cut: bool = parts.size() > 1
				var size := Vector3(js[0], js[1], float(pr[1]) - float(pr[0]))
				var c := Vector3(q, (jt + jb) * 0.5, (float(pr[0]) + float(pr[1])) * 0.5)
				if not along_z:
					size = Vector3(size.z, size.y, size.x)
					c = Vector3(c.z, c.y, c.x)
				# A joist cut short at an opening rests on its header (a tail: hung on it).
				add_member("%s/joist/%03d" % [id, n], &"rafter" if cut else &"joist", &"framing", size, c)
				n += 1
	# Headers across each opening's ends, on the trimmers either side.
	for o: Dictionary in openings:
		var orr: Array = o.rect
		var oa0 := float(orr[0]) if along_z else float(orr[1])
		var oa1 := float(orr[2]) if along_z else float(orr[3])
		var t0 := a0
		var t1 := a1
		for q in lines:
			if q < oa0 and q > t0:
				t0 = q
			if q > oa1 and q < t1:
				t1 = q
		for e in 2:
			var l := (float(orr[1]) if along_z else float(orr[0])) if e == 0 else (float(orr[3]) if along_z else float(orr[2]))
			var size := Vector3(t1 - t0 + float(js[0]), js[1], js[0])
			var c := Vector3((t0 + t1) * 0.5, (jt + jb) * 0.5, l + (-0.5 if e == 0 else 0.5) * float(js[0]))
			if not along_z:
				size = Vector3(size.z, size.y, size.x)
				c = Vector3(c.z, c.y, c.x)
			add_member("%s/%s/header_%d" % [id, o.id, e], &"beam", &"framing", size, c)
		# The trap's leaves, hinged on its +x side and folded back flat on the floor.
		var leaves := int(o.get("hatch", 0))
		var ow := float(orr[2]) - float(orr[0])
		var ol := float(orr[3]) - float(orr[1])
		for k in leaves:
			var ll := ol / leaves - 0.02
			var c := Vector3(float(orr[2]) + ow * 0.5 + 0.01, top + 0.02, float(orr[1]) + (ll + 0.02) * (k + 0.5))
			add_member("%s/%s/leaf_%d" % [id, o.id, k], &"door", &"floor", Vector3(ow - 0.02, 0.04, ll), c)
	# The boards, across the joists, in stock lengths, round the openings.
	var bw := float(_fr.floor_board.width)
	var rough: Array = f.get("rough", [])
	var b := l0
	var row := 0
	while b < l1 - 0.02:
		var b1 := minf(b + bw, l1)
		var spans: Array = [[a0, a1]]
		for o: Dictionary in openings:
			var orr: Array = o.rect
			var oa0 := float(orr[0]) if along_z else float(orr[1])
			var oa1 := float(orr[2]) if along_z else float(orr[3])
			var ol0 := float(orr[1]) if along_z else float(orr[0])
			var ol1 := float(orr[3]) if along_z else float(orr[2])
			if b1 > ol0 + 0.001 and b < ol1 - 0.001:
				var nxt: Array = []
				for sp: Array in spans:
					if float(sp[0]) < oa0:
						nxt.append([sp[0], minf(oa0, sp[1])])
					if float(sp[1]) > oa1:
						nxt.append([maxf(oa1, sp[0]), sp[1]])
				spans = nxt
		var piece := 0
		for sp: Array in spans:
			var length := float(sp[1]) - float(sp[0])
			var cuts := maxi(1, ceili(length / 4.9))
			# Each joint on a joist (half the joist's width each side), staggered row to row.
			var joints: Array[float] = [float(sp[0])]
			for k in range(1, cuts):
				var want := float(sp[0]) + length * k / cuts + (0.4 if row % 2 == 1 else 0.0)
				var best := want
				for q in lines:
					if absf(q - want) < absf(best - want) or best == want:
						best = q
				joints.append(best)
			joints.append(float(sp[1]))
			for k in cuts:
				var s0 := joints[k]
				var s1 := joints[k + 1]
				if s1 - s0 < 0.1:
					continue
				var size := Vector3(s1 - s0 - 0.003, bt, b1 - b - 0.004)
				var c := Vector3((s0 + s1) * 0.5, top - bt * 0.5, (b + b1) * 0.5)
				if not along_z:
					size = Vector3(size.z, size.y, size.x)
					c = Vector3(c.z, c.y, c.x)
				var m := add_member("%s/board/%03d_%d" % [id, row, piece], &"floor_board", &"floor", size, c)
				piece += 1
				var is_rough := false
				for rr: Array in rough:
					if c.x > float(rr[0]) and c.x < float(rr[2]) and c.z > float(rr[1]) and c.z < float(rr[3]):
						is_rough = true
				if not is_rough and f.has("look"):
					(m.get_child(0) as MeshInstance3D).material_override = WoodMaterials.get_material(StringName(String(f.look).trim_prefix("wood:")), hash(m.member_id))
		b = b1
		row += 1


# --- walls ----------------------------------------------------------------------------------------

## The wall dict FalseFrontBuilding's helpers take, for an outer wall (its line the studs' outer face).
func _outer_dict(w: Dictionary) -> Dictionary:
	var a := Vector3(w.line[0][0], 0, w.line[0][1])
	var e := Vector3(w.line[1][0], 0, w.line[1][1])
	var along := (e - a).normalized()
	var out := _axis(String(w.out))
	var length := a.distance_to(e)
	var sd := STUD_D if absf(along.z) > 0.5 else 0.0
	return _wall(String(w.id), a, along, out, length, sd, length - sd)


static func _axis(n: String) -> Vector3:
	var v := {"x": Vector3.RIGHT, "y": Vector3.UP, "z": Vector3.BACK}[n.trim_prefix("-").trim_prefix("+")] as Vector3
	return -v if n.begins_with("-") else v


## A wall's openings as Rect2s (x along it, y up), and their specs alongside.
func _openings(w: Dictionary, level := "") -> Array:
	var out := []
	for o: Dictionary in w.get("openings", []):
		var lvl: String = o.get("level", w.get("level", "ground"))
		if level != "" and lvl != level:
			continue
		var y0 := (_lv[lvl] as float) + float(o.get("sill", 0.0))
		out.append([Rect2(float(o.at) - float(o.width) * 0.5, y0, float(o.width), float(o.height)), o, lvl])
	return out


func _outer_walls() -> void:
	var sill_top := float(_fr.foundation.top) + float(_fr.sill.section[1])
	var tanp := tan(deg_to_rad(roof_pitch_degrees))
	for w: Dictionary in spec.walls:
		if w.get("partition", false):
			continue
		var wall := _outer_dict(w)
		walls[w.id] = {"dict": wall, "spec": w}
		var ops := _openings(w)
		var rects: Array[Rect2] = []
		for o in ops:
			rects.append(o[0])
		var top_at: Callable
		var board_top: Callable
		var top_kind: String = w.top if w.top is String else "height"
		match top_kind:
			"plate":
				top_at = func(_x: float) -> float: return wall_height - PLATE_H
				# The boards on up to the roof's underside, closing the eave over the plate (the
				# roof stands on trusses and purlins above it).
				var under := _roof_under()
				board_top = func(_x: float) -> float: return under
			"gable":
				# Up the end of the roof, to the common rafters' underside, then the boards to their top.
				var under := _roof_under()
				top_at = func(x: float) -> float: return under + maxf(minf(x, width - x), 0.0) * tanp - 0.02
				board_top = func(x: float) -> float: return under + maxf(minf(x, width - x), 0.0) * tanp + float(_fr.truss.rafter[1])
			_:
				var h := float(w.top)
				top_at = func(_x: float) -> float: return h - PLATE_H
				board_top = func(_x: float) -> float: return h
		var tall: Dictionary = _fr.stud.get("tall", {})
		var sw := float(tall.section[0]) if (tall.get("walls", []) as Array).has(w.id) else STUD_W
		_studs(wall, sill_top, top_at, rects, -STUD_D, 0.0, sw)
		# The plate on top, the ribbon the upper joists sit on.
		var length: float = wall.length
		var x0: float = wall.x_start
		var x1: float = wall.x_end
		if top_kind == "plate":
			var ph: float = top_at.call(0.0)
			_wall_run(wall, "%s/plate" % w.id, &"plate", x0, x1, ph, ph + PLATE_H, -STUD_D, 0.0, rects, x0 + sw * 0.5)
		var rb := _lv.upper_joist_bottom as float
		var rs: Array = _fr.ribbon.section
		_wall_run(wall, "%s/ribbon" % w.id, &"ledger", x0, x1, rb - float(rs[1]), rb, -STUD_D - float(rs[0]), -STUD_D, rects, x0 + sw * 0.5)
		# Outside: siding, cut round the openings and where a balcony's ledger is nailed to the studs.
		var cut := rects.duplicate()
		for b: Dictionary in spec.balconies:
			for l: Dictionary in b.ledgers:
				if l.wall == w.id:
					cut.append(Rect2(float(l.from), rb, float(l.to) - float(l.from), float(_fr.joist.section[1])))
		var wood := StringName(w.outside.wood)
		if w.outside.siding == "lap":
			_lap_siding(wall, float(w.top) if w.top is float else wall_height, cut, wood)
		else:
			_vertical_siding(wall, board_top, cut, -BOARD_T, length + BOARD_T if absf((wall.along as Vector3).x) > 0.5 else length, wood)
		for o in ops:
			var spec_o: Dictionary = o[1]
			var window: bool = spec_o.type == "window"
			_opening_trim(wall, o[0], window)
			if window:
				_glass(wall, o[0])
		# Inside: the finish on its inner face, level by level.
		for fin: Dictionary in w.inside:
			var lvl: String = fin.level
			var y0 := _lv[lvl] as float
			# The ground floor's finish on up to the upper floor (where no floor meets the wall, the
			# hall's open well, the joist band would show).
			var y1 := (_lv.upper as float) if lvl == "ground" else (wall_height - PLATE_H)
			if lvl == "upper" and top_kind == "gable":
				y1 = wall_height - PLATE_H
			var face := _face(wall, -STUD_D, -1.0)
			_finish(face, "%s/in_%s" % [w.id, lvl], float(fin.from), float(fin.to), y0, y1, String(fin.finish), _rects_on(ops, lvl), 1)
		# Doors in it.
		for o in ops:
			var so: Dictionary = o[1]
			if so.type == "door":
				band = 4 if o[2] == "upper" else 1  # a leaf stands on the floor it opens on
				_leaf(wall, o[0], String(so.get("leaf", "inward")) == "outward", -STUD_D)
				band = 1
			elif so.type == "batwings":
				door_rect = o[0]
				_build_door()
				_build_batwings()
				# They swing: a man (you, or anyone) walks through them; a ball still hits them (as
				# debris is: on everything a bullet can hit, not on what a walker stands or slides on).
				for i in 2:
					var leaf := get_member(StringName("%s/front/batwing%d" % [structure_id, i]))
					if leaf:
						leaf.collision_layer = Layers.DEBRIS


## A wall's run of one member kind along it (plates, ribbons) in stock lengths, each joint over a
## stud (on the stud spacing from `first`), never over an opening (it goes on to the king stud).
func _wall_run(wall: Dictionary, id: String, kind: StringName, x0: float, x1: float, y0: float, y1: float, d0: float, d1: float,
		avoid: Array[Rect2] = [], first := -1.0) -> void:
	var n := maxi(1, ceili((x1 - x0) / 4.9))
	var spacing := float(_fr.stud.spacing)
	var cuts: Array[float] = [x0]
	for i in range(1, n):
		var c := x0 + (x1 - x0) * i / n
		if first >= 0.0:
			c = first + roundf((c - first) / spacing) * spacing
		for o in avoid:
			if c > o.position.x - 0.1 and c < o.end.x + 0.1:
				c = o.end.x + STUD_W
		cuts.append(c)
	cuts.append(x1)
	for i in n:
		if cuts[i + 1] - cuts[i] > 0.05:
			_wall_member("%s/%d" % [id, i], kind, &"framing", wall, cuts[i], cuts[i + 1] - 0.003, y0, y1, d0, d1)


static func _rects_on(ops: Array, lvl: String) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for o in ops:
		if o[2] == lvl:
			out.append(o[0])
	return out


## Studs from `foot` to `top_at(x)` at their spacing, with king studs, headers, rough sills and
## cripples round the openings (FalseFrontBuilding._frame_wall's rules, from any foot, at any depth).
func _studs(wall: Dictionary, foot: float, top_at: Callable, openings: Array[Rect2], d0: float, d1: float, sw := STUD_W) -> void:
	var n: String = wall.name
	var x_start: float = wall.x_start
	var x_end: float = wall.x_end
	var spacing := float(_fr.stud.spacing)
	var xs: Array[float] = []
	var x := x_start + sw * 0.5
	while x <= x_end - sw * 0.5 + 0.001:
		xs.append(x)
		x += spacing
	if x_end - sw * 0.5 - xs.back() > 0.1:
		xs.append(x_end - sw * 0.5)
	var count := 0
	for sx in xs:
		var inside := -1
		var blocked := false
		for j in openings.size():
			var o := openings[j]
			if sx > o.position.x and sx < o.end.x:
				inside = j
			elif sx + sw * 0.5 > o.position.x - sw * 2.0 - 0.01 and sx - sw * 0.5 < o.end.x + sw * 2.0 + 0.01:
				blocked = true
		if blocked and inside < 0:
			continue
		var top: float = top_at.call(sx)
		if inside < 0:
			_wall_member("%s/stud/%03d" % [n, count], &"stud", &"framing", wall, sx - sw * 0.5, sx + sw * 0.5, foot, top, d0, d1)
		else:
			# Above and below the opening (and between two openings over each other).
			var spans: Array = [[foot, top]]
			for o in openings:
				if sx > o.position.x and sx < o.end.x:
					var nxt: Array = []
					for sp: Array in spans:
						if float(sp[0]) < o.position.y - PLATE_H:
							nxt.append([sp[0], minf(sp[1], o.position.y - PLATE_H)])
						if float(sp[1]) > o.end.y + HEADER_H:
							nxt.append([maxf(sp[0], o.end.y + HEADER_H), sp[1]])
					spans = nxt
			var k := 0
			for sp: Array in spans:
				if float(sp[1]) - float(sp[0]) > 0.05:
					var kind := &"stud" if float(sp[0]) <= foot + 0.001 else &"cripple"
					_wall_member("%s/stud/%03d_%d" % [n, count, k], kind, &"framing", wall, sx - sw * 0.5, sx + sw * 0.5, sp[0], sp[1], d0, d1)
					k += 1
		count += 1
	# King studs doubled (two nailed together, as period framing doubles them at an opening: they
	# carry the header and what's over it, a balcony's ledger among it).
	for j in openings.size():
		var o := openings[j]
		for side in 2:
			var kx := o.position.x - sw if side == 0 else o.end.x + sw
			_wall_member("%s/opening%d/king%d" % [n, j, side], &"stud", &"framing", wall, kx - sw, kx + sw,
					foot, top_at.call(kx), d0, d1)
		_wall_member("%s/opening%d/header" % [n, j], &"header", &"framing", wall, o.position.x, o.end.x, o.end.y, o.end.y + HEADER_H, d0, d1)
		if o.position.y > foot + 0.4:
			_wall_member("%s/opening%d/sill" % [n, j], &"header", &"framing", wall, o.position.x, o.end.x, o.position.y - PLATE_H, o.position.y, d0, d1)


## A face of a wall to finish: its origin, the way along it, the way into the room (`normal`) and the
## depth its finish starts from.
func _face(wall: Dictionary, d: float, into: float) -> Dictionary:
	return {"wall": wall, "d": d, "into": into, "along": wall.along, "normal": (wall.out as Vector3) * into}


## A member on a face: `s0..s1` along it, `y0..y1`, `t0..t1` out from the face into the room.
func _on_face(face: Dictionary, id: String, kind: StringName, wood: StringName, s0: float, s1: float, y0: float, y1: float, t0: float, t1: float) -> StructureMember:
	var d: float = face.d
	var k: float = face.into
	# Into the room is -out for an outer wall's inside (into -1), +out for a partition's + face.
	var a := d + k * t0
	var b := d + k * t1
	return _wall_member(id, kind, wood, face.wall, s0, s1, y0, y1, minf(a, b), maxf(a, b))


## The inside finish of a face from s0 to s1 along it, y0 to y1: "wainscot" (panelled to 0.9 m,
## beaded boards over it, a picture rail), "boards" (beaded boards), "rough" (the studs show).
func _finish(face: Dictionary, id: String, s0: float, s1: float, y0: float, y1: float, finish: String, holes: Array[Rect2], _side: int) -> void:
	if finish == "rough":
		return
	var hall := finish == "wainscot"
	var wains := 0.9 if hall else 0.0
	var bw := 0.15 if hall else 0.24
	var t := 0.02
	var along_axis := "x" if absf((face.along as Vector3).x) > 0.5 else "z"
	var n_axis := ("" if (face.normal as Vector3).dot(Vector3.ONE) > 0.0 else "-") + ("z" if along_axis == "x" else "x")
	var look := "wood:" + String(spec.materials.wall_boards)
	# Nailers: 1x4 blocking let in flush between the studs, what the boards are nailed to (a board
	# narrower than the studs' spacing may touch none), cut where an opening goes through.
	var nail_ys: Array = [y0 + 0.1, y0 + wains + 0.05, (y0 + wains + y1) * 0.5, y1 - 0.12]
	for ni in nail_ys.size():
		var ny: float = nail_ys[ni]
		var runs: Array = [[s0, s1]]
		for o in holes:
			if o.position.y < ny + 0.05 and o.end.y > ny - 0.05:
				var nxt: Array = []
				for r: Array in runs:
					if o.position.x > float(r[0]):
						nxt.append([r[0], minf(o.position.x, r[1])])
					if o.end.x < float(r[1]):
						nxt.append([maxf(o.end.x, r[0]), r[1]])
				runs = nxt
		for ri in runs.size():
			var r: Array = runs[ri]
			var length := float(r[1]) - float(r[0])
			var pieces := maxi(1, ceili(length / 4.9))
			for k in pieces:
				if length < 0.1:
					continue
				var a0 := float(r[0]) + length * k / pieces
				var a1 := float(r[0]) + length * (k + 1) / pieces
				# (a cripple's tier: the boards rest on it, the cripples over openings don't)
				_on_face(face, "%s/nailer/%d_%d_%d" % [id, ni, ri, k], &"cripple", &"framing", a0, a1 - 0.003, ny - 0.045, ny + 0.045, -0.025, 0.0)
	var s := s0
	var i := 0
	while s < s1 - 0.02:
		var e := minf(s + bw, s1)
		var spans: Array = [[y0 + wains, y1]]
		for o in holes:
			if o.position.x < e + 0.02 and o.end.x > s - 0.02:
				var nxt: Array = []
				for sp: Array in spans:
					if float(sp[0]) < o.position.y:
						nxt.append([sp[0], minf(sp[1], o.position.y)])
					if float(sp[1]) > o.end.y:
						nxt.append([maxf(sp[0], o.end.y), sp[1]])
				spans = nxt
		var k := 0
		for sp: Array in spans:
			if float(sp[1]) - float(sp[0]) > 0.05:
				var m := _on_face(face, "%s/board/%03d_%d" % [id, i, k], &"board", &"framing", s + 0.002, e - 0.002, sp[0], sp[1], 0.0, t)
				if hall:
					PropKit.dress_member(m, {"shape": "profile", "profile": "beaded", "along": "y", "up": n_axis, "across": along_axis, "args": [0.006]}, look)
				else:
					(m.get_child(0) as MeshInstance3D).material_override = WoodMaterials.get_material(StringName(spec.materials.wall_boards), hash(m.member_id))
				k += 1
		s = e
		i += 1
	var oak := String(spec.materials.woodwork)
	# Casings round each opening on the face.
	for j in holes.size():
		var o := holes[j]
		if o.end.x < s0 or o.position.x > s1:
			continue
		var cw := 0.11
		var cid := "%s/casing%d" % [id, j]
		for side in 2:
			var cx0 := o.position.x - cw if side == 0 else o.end.x
			var m := _on_face(face, "%s/jamb%d" % [cid, side], &"trim", &"oak", cx0, cx0 + cw, o.position.y - (0.04 if o.position.y > y0 + 0.3 else 0.0), o.end.y, t, t + 0.022)
			PropKit.dress_member(m, {"shape": "profile", "profile": "beaded", "along": "y", "up": n_axis, "across": along_axis, "args": [0.006]}, oak)
		var hd := _on_face(face, "%s/head" % cid, &"trim", &"oak", o.position.x - cw - 0.03, o.end.x + cw + 0.03, o.end.y, o.end.y + 0.13, t, t + 0.03)
		PropKit.dress_member(hd, {"shape": "profile", "profile": "ogee", "along": along_axis, "up": n_axis, "across": "y"}, oak)
		if o.position.y > y0 + 0.3:
			_on_face(face, "%s/stool" % cid, &"trim", &"oak", o.position.x - cw - 0.02, o.end.x + cw + 0.02, o.position.y - 0.04, o.position.y, 0.0, 0.07)
	if not hall:
		return
	# The wainscot in the runs between the openings that come down through it, and the picture rail.
	var runs: Array = [[s0, s1]]
	for o in holes:
		if o.position.y < y0 + 0.3:
			var nxt: Array = []
			for r: Array in runs:
				if o.position.x - 0.12 > float(r[0]):
					nxt.append([r[0], minf(o.position.x - 0.12, r[1])])
				if o.end.x + 0.12 < float(r[1]):
					nxt.append([maxf(o.end.x + 0.12, r[0]), r[1]])
			runs = nxt
	for ri in runs.size():
		var r: Array = runs[ri]
		if float(r[1]) - float(r[0]) > 0.3:
			_wainscot(face, "%s/wainscot%d" % [id, ri], r[0], r[1], y0, along_axis, n_axis, oak)
	var pr := _on_face(face, "%s/picture_rail" % id, &"trim", &"oak", s0, s1, y0 + 2.6, y0 + 2.645, t, t + 0.04)
	PropKit.dress_member(pr, {"shape": "profile", "profile": "ogee", "along": along_axis, "up": n_axis, "across": "y"}, oak)


## The interior stand's wainscot as members: a skirting, top and bottom rails, stiles ~0.6 m apart,
## a raised panel a bay, a moulded cap. Each piece no longer than a stock length.
func _wainscot(face: Dictionary, id: String, s0: float, s1: float, y0: float, along_axis: String, n_axis: String, oak: String) -> void:
	const SKIRT := 0.18
	const TOP := 0.9
	const RAIL := 0.09
	const STILE := 0.09
	var t := 0.022
	var len := s1 - s0
	var n := maxi(1, ceili(len / 3.0))
	for k in n:
		var a := s0 + len * k / n
		var b := s0 + len * (k + 1) / n
		var sk := _on_face(face, "%s/skirt%d" % [id, k], &"trim", &"oak", a, b, y0, y0 + SKIRT, 0.0, t + 0.008)
		PropKit.dress_member(sk, {"shape": "profile", "profile": "rounded", "along": along_axis, "up": n_axis, "across": "y", "args": [0.008, [1]]}, oak)
		for rr in [[y0 + SKIRT, y0 + SKIRT + RAIL, "rail_lo"], [y0 + TOP - 0.03 - RAIL, y0 + TOP - 0.03, "rail_hi"]]:
			var m := _on_face(face, "%s/%s%d" % [id, rr[2], k], &"trim", &"oak", a, b, rr[0], rr[1], 0.0, t)
			PropKit.dress_member(m, {"shape": "profile", "profile": "chamfered", "along": along_axis, "up": n_axis, "across": "y", "args": [0.004]}, oak)
		var cap := _on_face(face, "%s/cap%d" % [id, k], &"trim", &"oak", a, b, y0 + TOP - 0.03, y0 + TOP + 0.015, 0.0, t + 0.03)
		PropKit.dress_member(cap, {"shape": "profile", "profile": "ogee", "along": along_axis, "up": "y", "across": n_axis}, oak)
	var bays := maxi(int(round(len / 0.6)), 1)
	var bay := (len - STILE) / bays
	var py0 := y0 + SKIRT + RAIL
	var py1 := y0 + TOP - 0.03 - RAIL
	for bi in bays + 1:
		var s := s0 + STILE * 0.5 + bi * bay
		var st := _on_face(face, "%s/stile%02d" % [id, bi], &"trim", &"oak", s - STILE * 0.5, s + STILE * 0.5, py0, py1, 0.0, t)
		PropKit.dress_member(st, {"shape": "profile", "profile": "chamfered", "along": "y", "up": n_axis, "across": along_axis, "args": [0.004]}, oak)
		if bi < bays:
			var pn := _on_face(face, "%s/panel%02d" % [id, bi], &"trim", &"oak", s + STILE * 0.5 + 0.005, s + bay - STILE * 0.5 - 0.005, py0 + 0.005, py1 - 0.005, 0.0, 0.018)
			PropKit.dress_member(pn, {"shape": "panel", "out": n_axis, "bevel": 0.045}, oak)


## A door's leaf standing open at right angles to its wall, into the room (or out of it).
func _leaf(wall: Dictionary, o: Rect2, outward: bool, d: float) -> void:
	var lw := o.size.x - 0.05
	var lh := o.size.y - 0.05
	var into := (wall.out as Vector3) * (1.0 if outward else -1.0)
	var along: Vector3 = wall.along
	var hinge: Vector3 = wall.origin + along * (o.position.x + 0.03) + (wall.out as Vector3) * (0.0 if outward else d)
	var c := hinge + into * (lw * 0.5 + 0.03) + along * 0.025
	c.y = o.position.y + 0.01 + lh * 0.5
	var size := into.abs() * lw + Vector3.UP * lh + along.abs() * 0.04
	add_member("%s/door_%d" % [wall.name, int(o.position.x * 100)], &"door", &"painted_rust", size, c)


func _partitions(level: String, b: int) -> void:
	band = b
	for w: Dictionary in spec.walls:
		if not w.get("partition", false) or w.level != level:
			continue
		var a := Vector3(w.line[0][0], 0, w.line[0][1])
		var e := Vector3(w.line[1][0], 0, w.line[1][1])
		var along := (e - a).normalized()
		var out := Vector3.BACK if absf(along.x) > 0.5 else Vector3.RIGHT
		var wall := _wall(String(w.id), a, along, out, a.distance_to(e), 0.0, a.distance_to(e))
		walls[w.id] = {"dict": wall, "spec": w}
		var foot := _lv[level] as float
		# A ground-floor partition carries the joists over it; one upstairs stops short of the
		# trusses' ties (they span wall to wall: a tie on a partition would load the floor under it).
		var top := (_lv.upper_joist_bottom as float) - PLATE_H if level == "ground" else wall_height - PLATE_H - 0.02
		var ops := _openings(w, level)
		var rects: Array[Rect2] = []
		for o in ops:
			rects.append(o[0])
		var top_at := func(_x: float) -> float: return top
		_studs(wall, foot, top_at, rects, -STUD_D * 0.5, STUD_D * 0.5)
		_wall_run(wall, "%s/plate" % w.id, &"plate", 0.0, wall.length, top, top + PLATE_H, -STUD_D * 0.5, STUD_D * 0.5, rects, STUD_W * 0.5)
		for fin: Dictionary in w.inside:
			var plus: bool = fin.side == "+"
			var face := _face(wall, STUD_D * 0.5 * (1.0 if plus else -1.0), 1.0 if plus else -1.0)
			_finish(face, "%s/%s" % [w.id, "p" if plus else "m"], 0.0, wall.length, foot, top + PLATE_H, String(fin.finish), rects, 1)
		for o in ops:
			_leaf(wall, o[0], false, -STUD_D * 0.5)


# --- stairs, balconies, rails ---------------------------------------------------------------------

func _stair(st: Dictionary, lower: float, upper: float) -> void:
	var up := _axis(String(st.get("dir", "+z")))
	var across := Vector3(absf(up.z), 0, absf(up.x))
	var head := Vector3(st.head[0], upper, st.head[1])
	var risers := int(st.risers)
	var rise := (upper - lower) / risers
	var posts: Array = []
	var run := float(st.going) * (risers - 1)
	for p: Array in st.get("posts", []):
		# Posts given in plan: [along from the foot, across from the head's corner].
		var foot := head - up * run
		var q := Vector3(p[0], 0, p[1]) - Vector3(foot.x, 0, foot.z)
		posts.append([q.dot(up), q.dot(across)])
	var made := Stair.build(self, "stair/" + String(st.id), head, up, across, float(st.width), risers, rise, float(st.going),
			{"rail": 1 if _axis(String(st.get("rail", "+x"))).dot(across) > 0.0 else -1, "posts": posts, "wood": StringName(st.get("wood", "framing")), "look": st.get("look", ""),
			"stringer_look": st.get("stringer_look", st.get("look", ""))})
	ramps.append([made.ramp, made.stringers])


func _stairs_inside() -> void:
	for st: Dictionary in spec.stairs:
		if st.from is String and st.from == "ground":
			_stair(st, _lv.ground, _lv[st.to])
	var c: Dictionary = spec.cellar.stair
	_stair({"id": "cellar", "head": c.head, "dir": c.dir, "width": c.width, "risers": c.risers, "going": c.going},
			_lv.cellar + 0.08, _lv.ground)


func _outside_stair() -> void:
	for st: Dictionary in spec.stairs:
		if not (st.from is String):
			_stair(st, float(st.from), _lv[st.to])


func _balconies() -> void:
	var js: Array = _fr.joist.section
	var top := _lv.upper as float
	var jt := top - float(_fr.floor_board.thick)
	var jb := jt - float(js[1])
	for b: Dictionary in spec.balconies:
		var wood := StringName(b.wood)
		var ps: Array = b.post
		var bs: Array = b.beam
		band = 0
		for k in (b.posts as Array).size():
			var p: Array = b.posts[k]
			add_member("%s/post/%d" % [b.id, k], &"post", wood, Vector3(ps[0], jb - float(bs[1]), ps[1]), Vector3(p[0], (jb - float(bs[1])) * 0.5, p[1]))
		for k in (b.beams as Array).size():
			var be: Array = b.beams[k]
			var a := Vector3(be[0][0], 0, be[0][1])
			var e := Vector3(be[1][0], 0, be[1][1])
			var dir := (e - a).normalized()
			var size := dir.abs() * a.distance_to(e) + Vector3.UP * float(bs[1]) + Vector3(dir.z, 0, dir.x).abs() * float(bs[0])
			add_member("%s/beam/%d" % [b.id, k], &"beam", wood, size, (a + e) * 0.5 + Vector3.UP * (jb - float(bs[1]) * 0.5))
		band = 1
		for l: Dictionary in b.ledgers:
			var wall: Dictionary = walls[l.wall].dict
			_wall_member("%s/ledger_%s" % [b.id, l.wall], &"ledger", wood, wall, float(l.from), float(l.to), jb, jt, 0.0, 0.05)
		band = 3
		for k in (b.decks as Array).size():
			var dk: Dictionary = b.decks[k]
			_floor({"id": "%s_%d" % [b.id, k], "level": "upper", "rect": dk.rect, "joists": dk.joists}, [])
		for k in (b.rails as Array).size():
			var r: Array = b.rails[k]
			Railing.build(self, "%s/rail/%d" % [b.id, k], Vector3(r[0][0], top, r[0][1]), Vector3(r[1][0], top, r[1][1]),
					{"height": 1.0, "spacing": 0.15, "wood": wood})
	band = 3


func _gallery_rails() -> void:
	var g: Dictionary = spec.galleries
	var top := _lv.upper as float
	var look := String(g.look)
	for k in (g.rails as Array).size():
		var r: Array = g.rails[k]
		var a := Vector3(r[0][0], top, r[0][1])
		var e := Vector3(r[1][0], top, r[1][1])
		var made := Railing.build(self, "gallery/rail/%d" % k, a, e, {"height": 1.0, "spacing": 0.12, "baluster": 0.045,
				"rail": Vector2(0.075, 0.06), "wood": &"oak"})
		for m in made:
			if m.kind == &"trim":
				PropKit.dress_member(m, {"shape": "profile", "profile": "handrail", "along": "x", "up": "y"}, look)
			else:
				PropKit.dress_member(m, {}, look)
		# Square newels with caps at its ends.
		for p in [a, e]:
			var nw := add_member("gallery/newel/%d_%d" % [k, int(p.x * 10 + p.z)], &"furniture_frame", &"oak", Vector3(0.125, 1.15, 0.125), p + Vector3.UP * 0.575)
			PropKit.dress_member(nw, {"shape": "profile", "profile": "chamfered", "along": "y", "up": "z", "args": [0.015]}, look)


# --- the false front and the roof -----------------------------------------------------------------

func _false_front() -> void:
	var front: Dictionary = walls["front"].dict
	var w := width
	var d0 := BOARD_T
	var h := front_height
	_wall_member("front/corner_left", &"trim", &"dark_trim", front, -BOARD_T, 0.14, 0.05, h, d0, d0 + TRIM_T)
	_wall_member("front/corner_right", &"trim", &"dark_trim", front, w - 0.14, w + BOARD_T, 0.05, h, d0, d0 + TRIM_T)
	_wall_member("front/cornice", &"trim", &"dark_trim", front, -0.15, w + 0.15, h - 0.3, h - 0.05, d0, d0 + 0.18)
	_wall_member("front/cornice_band", &"trim", &"dark_trim", front, -0.05, w + 0.05, h - 0.55, h - 0.45, d0, d0 + 0.05)
	_wall_member("front/cap", &"trim", &"dark_trim", front, -0.2, w + 0.2, h, h + 0.04, -STUD_D - 0.02, d0 + 0.22)
	var sign := _wall_member("front/sign", &"trim", &"sign", front, 1.5, w - 1.5, sign_from + 0.2, h - 0.8, d0, d0 + 0.03)
	SignArt.hang(self, sign, sign_text)


## The height of the common rafters' underside over the wall's outer face.
func _roof_under() -> float:
	var t: Dictionary = _fr.truss
	var ang := deg_to_rad(roof_pitch_degrees)
	return wall_height + float(t.tie[1]) + (float(t.principal[1]) + float(t.purlin[1])) / cos(ang)


func _slope(side: int) -> Dictionary:
	var ang := deg_to_rad(roof_pitch_degrees)
	var dir := Vector3(cos(ang), sin(ang), 0) if side == 0 else Vector3(-cos(ang), sin(ang), 0)
	var normal := Vector3(-sin(ang), cos(ang), 0) if side == 0 else Vector3(sin(ang), cos(ang), 0)
	return {"dir": dir, "normal": normal, "basis": Basis(dir, normal, dir.cross(normal)), "eave": Vector3(0.0 if side == 0 else width, 0, 0)}


func _trusses() -> void:
	var t: Dictionary = _fr.truss
	var tie: Array = t.tie
	var pr: Array = t.principal
	var qp: Array = t.queen
	var ang := deg_to_rad(roof_pitch_degrees)
	var y0 := wall_height
	var yt := y0 + float(tie[1])
	var half := width * 0.5
	var plen := half / cos(ang)
	var zs: Array = t.at
	for k in zs.size():
		var z := float(zs[k])
		var id := "truss/%d" % k
		add_member(id + "/tie", &"beam", &"framing", Vector3(width, tie[1], tie[0]), Vector3(half, (y0 + yt) * 0.5, z))
		for side in 2:
			var sl := _slope(side)
			var foot := (sl.eave as Vector3) + Vector3(0, yt, z)
			var c := foot + (sl.dir as Vector3) * (plen * 0.5) + (sl.normal as Vector3) * (float(pr[1]) * 0.5)
			add_member("%s/principal_%d" % [id, side], &"rafter", &"framing", Vector3(plen, pr[1], pr[0]), c, sl.basis)
		for qx in [width / 3.0, width * 2.0 / 3.0]:
			var under := yt + minf(qx, width - qx) * tan(ang)
			add_member("%s/queen_%d" % [id, int(qx)], &"board", &"framing", Vector3(qp[0], under - yt, qp[1]), Vector3(qx, (under + yt) * 0.5, z))
		# The purlins on its principals, to the next truss.
		if k == zs.size() - 1:
			continue
		var z1 := float(zs[k + 1])
		var pu: Array = t.purlin
		for side in 2:
			var sl := _slope(side)
			for d: float in t.purlins:
				var p := (sl.eave as Vector3) + Vector3(0, yt, 0) + (sl.dir as Vector3) * d + (sl.normal as Vector3) * (float(pr[1]) + float(pu[1]) * 0.5)
				p.z = (z + z1) * 0.5
				add_member("%s/purlin_%d_%d" % [id, side, int(d * 10)], &"ridge", &"framing", Vector3(pu[0], pu[1], z1 - z), p, sl.basis)


func _roof_cover() -> void:
	var t: Dictionary = _fr.truss
	var ang := deg_to_rad(roof_pitch_degrees)
	var under := _roof_under()
	var rf: Array = t.rafter
	var half := width * 0.5
	var over := eave_overhang / cos(ang)
	var slope := half / cos(ang) + over
	for side in 2:
		var sl := _slope(side)
		var dir: Vector3 = sl.dir
		var normal: Vector3 = sl.normal
		# The rafters' underside line, from its eave (overhanging the wall) to the ridge.
		var base := (sl.eave as Vector3) + Vector3(0, under * 1.0, 0) - dir * over
		var zs: Array = t.at
		var z := float(zs[0])
		var i := 0
		while z <= float(zs.back()) + 0.001:
			var c := base + dir * (slope * 0.5) + normal * (float(rf[1]) * 0.5)
			c.z = z
			add_member("roof/rafter_%d/%02d" % [side, i], &"rafter", &"framing", Vector3(slope, rf[1], rf[0]), c, sl.basis)
			z += float(t.rafter_spacing)
			i += 1
		# Boards across them in stock lengths, their joints staggered.
		var row := 0
		var s := 0.0
		while s < slope - 0.02:
			var bw := minf(0.195, slope - s)
			var c := base + dir * (s + bw * 0.5) + normal * (float(rf[1]) + BOARD_T * 0.5)
			var spans := [[0.1, 5.8 + 0.6 * (row % 2)], [5.8 + 0.6 * (row % 2), 11.6 + 0.6 * (row % 2)], [11.6 + 0.6 * (row % 2), depth + 0.3]]
			for k in spans.size():
				var sp: Array = spans[k]
				var cz := c
				cz.z = (float(sp[0]) + float(sp[1])) * 0.5
				add_member("roof/board_%d/%02d_%d" % [side, row, k], &"roof_board", &"weathered_pine", Vector3(bw, BOARD_T, float(sp[1]) - float(sp[0]) - 0.004), cz, sl.basis)
			s += 0.2
			row += 1
	var ridge_y := under + half * tan(ang) + (float(rf[1]) + BOARD_T) / cos(ang)
	add_member("roof/ridge_cap", &"trim", &"dark_trim", Vector3(0.34, BOARD_T, depth + 0.2), Vector3(half, ridge_y + BOARD_T * 0.5 - 0.005, depth * 0.5 + 0.1))


func _chandelier() -> void:
	var c: Dictionary = spec.lamps.chandelier
	var at := Vector3(c.at[0], c.y, c.at[1])
	var r := float(c.radius)
	var tie_bottom := wall_height
	band = 6
	# Three iron rods from the truss's tie down to the wheel, its rim in eight felloes, four spokes and a hub.
	for k in 3:
		var p := at + Vector3((k - 1) * r * 0.8, 0, 0)
		add_member("chandelier/rod_%d" % k, &"rafter", &"iron", Vector3(0.012, tie_bottom - at.y, 0.012), Vector3(p.x, (tie_bottom + at.y) * 0.5, float(c.truss)))
	var n := 8
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		var p0 := at + Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := at + Vector3(cos(a1), 0, sin(a1)) * r
		var dir := (p1 - p0).normalized()
		var m := add_member("chandelier/felloe_%d" % k, &"trim", &"oak", Vector3(p0.distance_to(p1) + 0.02, 0.07, 0.06), (p0 + p1) * 0.5,
				Basis(dir, Vector3.UP, dir.cross(Vector3.UP)))
		PropKit.dress_member(m, {}, String(_fr.post.look))
	for k in 2:
		var a := PI * 0.5 * k
		var m := add_member("chandelier/spoke_%d" % k, &"board", &"oak", Vector3(r * 2.0 - 0.08, 0.04, 0.04), at, Basis(Vector3.UP, a))
		PropKit.dress_member(m, {}, String(_fr.post.look))
	var hub := add_member("chandelier/hub", &"board", &"oak", Vector3(0.16, 0.12, 0.16), at)
	PropKit.dress_member(hub, {}, String(_fr.post.look))


# --- furniture, lamps, kit, use points ------------------------------------------------------------

func _furniture_members() -> void:
	for f: Dictionary in spec.furniture:
		if not f.has("members"):
			continue
		var r: Array = f.rect
		var keep := floor_top
		band = 0 if f.level == "cellar" else 2
		floor_top = (_lv.cellar + 0.08) if f.level == "cellar" else (_lv[f.level] as float)
		match String(f.members):
			"table":
				_table(String(f.id), r[0], r[2], r[1], r[3], float(f.height))
			"shelves":
				_shelves(String(f.id), r[0], r[2], r[1], r[3], int(f.boards))
		floor_top = keep
	band = 2


func _outbuildings() -> void:
	for o: Dictionary in spec.outbuildings:
		if o.kind != "outhouse":
			continue
		band = 0
		var at := Vector3(o.at[0], 0, o.at[1])
		var w := float(o.size[0])
		var d := float(o.size[1])
		var h := float(o.height)
		var wood := StringName(o.wood)
		var id := String(o.id)
		var x0 := at.x - w * 0.5
		var z0 := at.z - d * 0.5  # its door on the -z side, toward the house
		for k in 2:
			add_member("%s/sill_%d" % [id, k], &"sill", &"framing", Vector3(0.1, 0.1, d), Vector3(x0 + 0.05 + k * (w - 0.1), 0.05, at.z))
		var i := 0
		var bz := z0
		while bz < z0 + d - 0.01:
			var bw := minf(0.15, z0 + d - bz)
			add_member("%s/floor/%d" % [id, i], &"floor_board", &"floor", Vector3(w, 0.025, bw - 0.004), Vector3(at.x, 0.1125, bz + bw * 0.5))
			bz += bw
			i += 1
		var back_h := h - 0.25
		for k in 4:
			var px := x0 + 0.04 if k % 2 == 0 else x0 + w - 0.04
			var pz := z0 + 0.04 if k < 2 else z0 + d - 0.04
			var ph := h if k < 2 else back_h
			add_member("%s/post_%d" % [id, k], &"post", &"framing", Vector3(0.08, ph - 0.1, 0.08), Vector3(px, 0.1 + (ph - 0.1) * 0.5, pz))
		for k in 2:
			var gy := 0.9 if k == 0 else back_h - 0.04
			add_member("%s/girt_side_%d_l" % [id, k], &"beam", &"framing", Vector3(0.05, 0.08, d - 0.16), Vector3(x0 + 0.025, gy, at.z))
			add_member("%s/girt_side_%d_r" % [id, k], &"beam", &"framing", Vector3(0.05, 0.08, d - 0.16), Vector3(x0 + w - 0.025, gy, at.z))
			add_member("%s/girt_back_%d" % [id, k], &"beam", &"framing", Vector3(w - 0.16, 0.08, 0.05), Vector3(at.x, gy, z0 + d - 0.025))
		add_member("%s/head" % id, &"beam", &"framing", Vector3(w - 0.16, 0.1, 0.05), Vector3(at.x, h - 0.05, z0 + 0.04))
		# Boards up the sides and back (board and batten), the front round its door.
		var door_w := 0.66
		for side in 3:
			var n := int(ceil((d if side < 2 else w) / 0.2))
			for k in n:
				var s := (k + 0.5) * (d if side < 2 else w) / n
				var top := h - (h - back_h) * (s / d) if side < 2 else back_h
				var size := Vector3(0.02, top - 0.12, (d if side < 2 else w) / n - 0.01)
				var c := Vector3(x0 - 0.01 if side == 0 else x0 + w + 0.01, 0.12 + (top - 0.12) * 0.5, z0 + s)
				if side == 2:
					size = Vector3(size.z, size.y, size.x)
					c = Vector3(x0 + s, c.y, z0 + d + 0.01)
				add_member("%s/board_%d_%02d" % [id, side, k], &"board", wood, size, c)
		var fb := (w - door_w) * 0.5
		for k in 2:
			add_member("%s/front_%d" % [id, k], &"board", wood, Vector3(fb - 0.02, h - 0.12, 0.02), Vector3(x0 + fb * 0.5 + k * (w - fb), 0.12 + (h - 0.12) * 0.5, z0 - 0.01))
		add_member("%s/door" % id, &"door", wood, Vector3(0.04, h - 0.4, door_w - 0.04), Vector3(x0 + fb - 0.02, 0.15 + (h - 0.4) * 0.5, z0 - 0.02 - (door_w - 0.04) * 0.5))
		# The bench across the back with its two holes.
		var by := 0.45
		add_member("%s/bench_front" % id, &"furniture_frame", &"framing", Vector3(w - 0.1, by - 0.125, 0.025), Vector3(at.x, 0.125 + (by - 0.125) * 0.5, z0 + d * 0.45))
		var seat_z0 := z0 + d * 0.45
		var seat_z1 := z0 + d - 0.06
		var holes := [x0 + w * 0.3, x0 + w * 0.7]
		var cuts := [x0 + 0.05, holes[0] - 0.13, holes[0] + 0.13, holes[1] - 0.13, holes[1] + 0.13, x0 + w - 0.05]
		for k in 3:
			var a: float = cuts[k * 2]
			var b: float = cuts[k * 2 + 1]
			add_member("%s/seat_%d" % [id, k], &"furniture_top", &"framing", Vector3(b - a, 0.025, seat_z1 - seat_z0), Vector3((a + b) * 0.5, by + 0.0125, (seat_z0 + seat_z1) * 0.5))
		# A shed roof falling to the back.
		var ang := atan2(h - back_h, d)
		var rlen := (d + 0.3) / cos(ang)
		for k in 3:
			var rx := x0 + 0.04 + k * (w - 0.08) / 2.0
			add_member("%s/rafter_%d" % [id, k], &"rafter", &"framing", Vector3(0.05, 0.08, rlen), Vector3(rx, (h + back_h) * 0.5 + 0.04, at.z + 0.05), Basis(Vector3.RIGHT, ang))
		for k in 5:
			add_member("%s/roof_%d" % [id, k], &"roof_board", wood, Vector3(0.3 - 0.004, 0.02, rlen), Vector3(x0 - 0.1 + (k + 0.5) * (w + 0.2) / 5.0, (h + back_h) * 0.5 + 0.09, at.z + 0.05), Basis(Vector3.RIGHT, ang))


func _lamp(at: Vector3, sconce := false) -> OilLamp:
	var lamp := OilLamp.new()
	lamp.name = "Lamp%02d" % lamps.size()
	lamp.casts_shadows = false
	lamp.lit_from_hour = 17
	lamp.lit_until_hour = 4
	if sconce:
		lamp.energy = SaloonDressing.SCONCE_ENERGY
		lamp.attenuation = SaloonDressing.SCONCE_FALLOFF
		lamp.light_range = SaloonDressing.SCONCE_REACH
	else:
		lamp.energy = 1.1
		lamp.light_range = 6.0
	lamp.position = at
	_furnish.add_child(lamp)
	lamps.append(lamp)
	return lamp


func _lamps() -> void:
	var L: Dictionary = spec.lamps
	# Sconces: a bracket shelf nailed to the wall's boards, the lamp standing on it.
	for sc: Dictionary in L.sconces:
		var wl: Dictionary = walls[sc.wall]
		var wall: Dictionary = wl.dict
		var partition: bool = wl.spec.get("partition", false)
		# On an outer wall's inside; on a partition's - side or its + side (`side`).
		var plus: bool = partition and sc.get("side", "-") == "+"
		var face_d := (STUD_D * 0.5 + 0.02 if plus else -STUD_D * 0.5 - 0.02) if partition else -STUD_D - 0.02
		var into := (wall.out as Vector3) if plus else -(wall.out as Vector3)
		band = 1 if not partition else (2 if sc.level == "ground" else 4)
		for s: float in sc.at:
			var y := (_lv[sc.level] as float) + float(sc.height)
			var p: Vector3 = wall.origin + (wall.along as Vector3) * s + (wall.out as Vector3) * face_d
			var c := p + into * 0.07 + Vector3.UP * (y - 0.015)
			var m := add_member("sconce/%s_%s_%d" % [sc.wall, sc.level, int(s * 100)], &"trim", &"oak", into.abs() * 0.14 + Vector3.UP * 0.03 + (wall.along as Vector3).abs() * 0.12, c)
			PropKit.dress_member(m, {}, String(spec.materials.woodwork))
			_lamp(p + into * 0.08 + Vector3.UP * y, true)
	band = 0
	# The chandelier's lamps on its rim.
	var c: Dictionary = L.chandelier
	for k in int(c.lamps):
		var a := TAU * (k + 0.5) / int(c.lamps)
		var p := Vector3(c.at[0], float(c.y) + 0.035, c.at[1]) + Vector3(cos(a), 0, sin(a)) * float(c.radius) * cos(PI / 8.0)
		_lamp(p)


## The kit's fixtures and furniture, and the lamps that stand on them.
func _kit() -> void:
	var f0 := floor_top
	for fx: Dictionary in spec.fixtures:
		var rep: Dictionary = fx.get("repeat", {"count": 1, "step": [0, 0]})
		for k in int(rep.count):
			var at := Vector3(fx.at[0] + float(rep.step[0]) * k, f0, fx.at[1] + float(rep.step[1]) * k)
			_spawn(StringName(fx.kit), at, float(fx.facing))
	for lp: Array in spec.lamps.on_bar:
		var top := PropKit.bounds(PropKit.definition(&"bar")).end.y
		_lamp(Vector3(lp[0], f0 + top, lp[1]))
	for f: Dictionary in spec.furniture:
		if not f.has("kit"):
			continue
		var at := Vector3(f.at[0], f0, f.at[1])
		_spawn(StringName(f.kit), at, float(f.get("facing", 15.0)))
		if f.kit == "card_table":
			for k in int(f.get("chairs", 0)):
				var a := deg_to_rad(15.0 + 90.0 * k)
				var off := Vector3(sin(a), 0.0, cos(a)) * 0.85
				# A chair faces +Z: turned to look at the table.
				_spawn(&"chair", at + off, rad_to_deg(atan2(-off.x, -off.z)))
			if spec.lamps.get("on_tables", false):
				var top := PropKit.bounds(PropKit.definition(&"card_table")).end.y
				_lamp(at + Vector3(0.1, top, -0.1))


func _spawn(id: StringName, at: Vector3, yaw: float) -> KitProp:
	var p := PropKit.spawn(id, StringName("%s_%s_%d" % [structure_id, id, kit_props.size()]))
	p.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)
	_furnish.add_child(p)
	kit_props.append(p)
	return p


func _use_points() -> void:
	var root := Node3D.new()
	root.name = "UsePoints"
	_furnish.add_child(root)
	for u: Dictionary in spec.use_points:
		if u.has("seats"):
			continue  # the kit's seats are its use points (KitProp.sit)
		var m := Marker3D.new()
		m.name = String(u.id)
		m.position = Vector3(u.at[0], u.at[1], u.at[2])
		m.rotation.y = deg_to_rad(float(u.get("facing", 0.0)))
		m.set_meta(&"use", u.use)
		m.set_meta(&"who", u.who)
		root.add_child(m)


# --- a stair's ramp goes with it ------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	super(delta)
	_ramp_t += delta
	if _ramp_t < 0.5:
		return
	_ramp_t = 0.0
	for r: Array in ramps:
		var ramp: StaticBody3D = r[0]
		if not is_instance_valid(ramp):
			continue
		var standing := false
		for m: StructureMember in r[1]:
			if is_instance_valid(m) and not m.broken and not m.consumed:
				standing = true
		if not standing:
			ramp.queue_free()
