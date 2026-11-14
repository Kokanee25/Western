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
const StoneBuilder := preload("res://experiments/building_lab/stone.gd")
const CELL := 2.0
const SPEC := "res://experiments/building_lab/saloon.json"

var spec_path := SPEC
var spec: Dictionary
## Furniture laid in on top of the spec's for the next building built (the gunfight lab's `dress`:
## more to hide behind in the hall, an experiment; the spec's own file is unchanged).
static var extra_furniture: Array = []
## The band members added now go in (see the top).
var band := 0
## [StaticBody3D ramp, [stringers]] for each stair.
var ramps: Array = []
var lamps: Array[OilLamp] = []
var kit_props: Array[KitProp] = []
## The spec's `dressing` as placed (#844): batch -> {entry id -> its node} (PropDressing).
var dressed := {}
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
	# In a common-rafter roof a tilted member's box is far bigger than it is (a rafter's spans the
	# loft): it touches only what its oriented box truly meets.
	if _tilted_test and (_tilted(m) or _tilted(other)) and not _boxes_meet(m, other):
		return
	m.touching.append(other.member_id)
	var tier := _tier(m)
	var other_tier := _tier(other)
	# (A pane rests on its sash's rail and bars as one trim on another: SashWindow, #826.)
	var same := other.kind == m.kind or (m.kind == &"glass" and other.kind == &"trim")
	var beneath := other_tier == tier and same and other_box.end.y <= box.position.y + CONTACT_EPSILON \
			and other_box.position.y < box.position.y - CONTACT_EPSILON
	if other_tier < tier or beneath:
		m.supported_by.append(other.member_id)
		other.dependents.append(m.member_id)
		var contact := grown.intersection(other_box)
		m.support_points[other.member_id] = contact.get_center()
		m.support_boxes[other.member_id] = contact


var _tilted_test := false


static func _tilted(m: StructureMember) -> bool:
	var b := m.transform.basis
	return absf(b.x.y) > 0.01 or absf(b.y.x) > 0.01 or absf(b.y.z) > 0.01 or absf(b.z.y) > 0.01


## Whether two members' oriented boxes overlap (within the contact distance), by the separating
## axes of both boxes' faces (6 of the 15: enough for timber meeting timber).
static func _boxes_meet(a: StructureMember, b: StructureMember) -> bool:
	var ta := a.transform
	var tb := b.transform
	var ha := a.size * 0.5 + Vector3.ONE * CONTACT_EPSILON
	var hb := b.size * 0.5
	var d := tb.origin - ta.origin
	for pair in [[ta.basis, ha, tb.basis, hb], [tb.basis, hb + Vector3.ONE * CONTACT_EPSILON, ta.basis, a.size * 0.5]]:
		var ba: Basis = pair[0]
		var h1: Vector3 = pair[1]
		var bb: Basis = pair[2]
		var h2: Vector3 = pair[3]
		for i in 3:
			var ax := ba[i].normalized()
			var r2 := absf(ax.dot(bb[0].normalized())) * h2.x + absf(ax.dot(bb[1].normalized())) * h2.y + absf(ax.dot(bb[2].normalized())) * h2.z
			if absf(ax.dot(d)) > h1[i] + r2:
				return false
	return true


## Structure.infer_supports with a grid: the same links in the same order, from the pairs that
## share a cell.
func infer_supports() -> void:
	_tilted_test = _fr.has("rafters")
	invalidate_analysis()
	_by_stack.clear()
	var boxes := {}
	var grid := {}
	for i in _order.size():
		var m := _order[i]
		var b := m.structure_aabb()
		boxes[m] = b
		m.dependents.clear()  # before any linking: the others' links fill it
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
		if not extra_furniture.is_empty():
			spec.furniture = (spec.furniture as Array) + extra_furniture
	var lot: Dictionary = spec.lot
	var lv: Dictionary = spec.levels
	_fr = spec.frame
	width = float(lot.width)
	depth = float(lot.depth)
	floor_top = float(lv.ground.top)
	wall_height = float(lv.plate)
	front_height = float(lv.false_front)
	roof_pitch_degrees = float(lv.roof_pitch)
	var front: Dictionary = spec.get("front", {})
	sign_text = String(front.get("sign", ""))
	sign_from = float(front.get("sign_from", -1.0))
	var joist: Array = _fr.joist.section
	# An upper floor may name its own joists (the doctor's loft on 2x8 ceiling joists, frame.ceiling_joist).
	var up_joist: Array = joist
	for f: Dictionary in spec.floors:
		if f.level == "upper" and f.has("joist"):
			up_joist = (_fr[f.joist] as Dictionary).section
	_lv = {
		"cellar": float((lv.get("cellar", {}) as Dictionary).get("floor", floor_top - 2.4)), "ground": floor_top, "upper": float(lv.upper.top),
		"ground_joist_bottom": floor_top - float(_fr.floor_board.thick) - float(joist[1]),
		"upper_joist_bottom": float(lv.upper.top) - float(_fr.floor_board.thick) - float(up_joist[1]),
	}
	ramps.clear()
	lamps.clear()
	kit_props.clear()
	dressed.clear()
	walls.clear()
	# What the last build made that isn't a member (Structure.rebuild frees only those).
	for c in get_children():
		if c == _furnish or String(c.name).begins_with("Ramp_") or c.name in [&"InteriorAmbient", &"RoomHaze"]:
			c.free()
	_furnish = Node3D.new()
	_furnish.name = "Furnishings"
	add_child(_furnish)

	_chimney_openings()
	if _fr.has("stone_wall"):
		# A load-bearing stone building (#780, the jail): stone.gd lays it; then what every building has.
		StoneBuilder.new(self).build()
		band = 0
		_lamps()
		_kit()
		_use_points()
		_add_interior_ambient()
		marks = Marks.place(self, spec)
		_library_finishes()
		_stone_finish()
		return
	band = 0
	_foundation()
	_cellar()
	_posts_and_beams()
	band = 1
	_ground_floor()
	_outer_walls()
	if spec.has("corner"):
		_corner_entrance()
	band = 2
	_partitions("ground", 2)
	_stairs_inside()
	_summer_beams()
	band = 3
	_upper_floors()
	_balconies()
	_gallery_rails()
	band = 4
	_partitions("upper", 4)
	_outside_stair()
	band = 2 if _fr.get("stacked", false) else 1
	if _has_false_front():
		_false_front()
	band = 1
	if spec.has("porch"):
		_porch()
	if _fr.has("rafters"):
		# A common-rafter roof tied by the loft's joists (the doctor's), then what a small building has.
		band = 1
		_braces()
		band = 6
		_rafter_roof()
		band = 4
		_ceilings()
		band = 0
		_chimneys()
		band = 1
		_gable_sign()
		_back_porch()
		_stoops()
		band = 0
		_yard_front()
		_ladders()
	else:
		band = 5
		_trusses()
		band = 6
		_roof_cover()
		band = 1
		_stoops()
	if (spec.get("lamps", {}) as Dictionary).has("chandelier"):
		_chandelier()
	band = 2
	_furniture_members()
	band = 0
	_outbuildings()
	_lamps()
	_kit()
	_dressing()
	_use_points()
	_add_interior_ambient()
	marks = Marks.place(self, spec)
	_library_finishes()
	_stone_finish()


# --- the room's light (#824) -------------------------------------------------------------------------

## The building's indoor fill (FalseFrontBuilding's probe) reaching its outer walls' inside boards:
## the base's box stops at the studs' inner face and fades over 0.3 m, so those boards took almost
## none of the room's fill and the sky's cool one instead, beside a partition in the full amber
## (the doctor's orange / blue-grey corner, docs/reviews/2026-11-doctor-room.md cause 1; proved by
## its test render, experiments/building_lab/doctor/results/2026-11-11_light/). The box runs to the
## wall lines (the siding outside stays out of it), blending over its last 5 cm. The spec's
## `light.fill` is the fill's colour (near neutral: the windows and lamps give the room its shape;
## RoomLight reads the meta `room_fill`).
func _add_interior_ambient() -> void:
	super()
	var probe := get_node_or_null(^"InteriorAmbient") as ReflectionProbe
	var haze := get_node_or_null(^"RoomHaze") as FogVolume
	var light: Dictionary = spec.get("light", {})
	if probe == null or light.is_empty():
		return
	probe.size = Vector3(width, probe.size.y, depth)
	probe.blend_distance = 0.05
	if haze:
		haze.size = probe.size
	if light.has("window_day"):
		set_meta(&"room_window_gain", float(light.window_day))
	if light.has("day_fill"):
		# The fill's level by day (DayCycle's interior_ambient_day else, 0.45: one even level that
		# made the rooms flat, #829): low, so the windows and the sun's patches light the rooms.
		probe.set_meta(&"day_ambient", float(light.day_fill))
	if light.has("fill"):
		var c: Array = light.fill
		set_meta(&"room_fill", Color(c[0], c[1], c[2]))
		probe.ambient_color = Color(c[0], c[1], c[2])


## Every outer door and window, for RoomLight (its soft sky or moon light just inside each): {wall
## (front/back/left/right by the way it faces), rect (along the wall from its line's start, up from
## the building's 0), kind, frame {origin, along, inward}}. Only a spec with `light` gives them
## (the saloon's keep RoomLight's front door and windows).
func light_openings() -> Array:
	var out := []
	if not spec.has("light"):
		return [{"wall": "front", "rect": door_rect, "kind": "door"}]
	for id: String in walls:
		var wl: Dictionary = walls[id]
		if wl.spec.get("partition", false):
			continue
		var d: Dictionary = wl.dict
		var o: Vector3 = d.out
		var side := "front" if o.z < -0.5 else ("back" if o.z > 0.5 else ("left" if o.x < -0.5 else "right"))
		for op: Array in _openings(wl.spec):
			if String(op[1].type) == "void":
				continue
			var kind := "door" if String(op[1].type) == "door" else "window"
			out.append({"wall": side, "rect": op[0], "kind": kind,
					"frame": {"origin": d.origin, "along": d.along, "inward": -o}})
	if spec.has("corner"):
		# The corner's double doors and their transom, in the diagonal wall.
		var c := _corner_frame()
		var dw := float(spec.corner.door.width)
		var dh := float(spec.corner.door.height) + float(spec.corner.door.get("transom", 0.0))
		out.append({"wall": "front", "rect": Rect2((float(c.length) - dw) * 0.5, floor_top, dw, dh), "kind": "door",
				"frame": {"origin": c.origin, "along": c.along, "inward": -(c.out as Vector3)}})
	return out


# --- foundation, cellar, posts and beams (band 0) -------------------------------------------------

func _foundation() -> void:
	var f: Dictionary = _fr.foundation
	var t := float(f.thick)
	var top := float(f.top)
	var w := width
	var d := depth
	var cel: Array = (spec.get("cellar", {}) as Dictionary).get("rect", [])
	var floor: float = _lv.cellar
	if cel.is_empty():
		# No cellar (a farmhouse): the perimeter wall down to its footing all round.
		for r in [["front", Vector2(0, 0), Vector2(width, 0)], ["back", Vector2(0, depth - t), Vector2(width, depth - t)],
				["west", Vector2(0, t), Vector2(0, depth - t)], ["east", Vector2(width - t, t), Vector2(width - t, depth - t)]]:
			_stone_run("foundation/" + r[0], r[1], r[2], t, top, [], float(f.bottom))
		_sills()
		return
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
	_sills()


## Wood sills on the foundation's top, under the studs.
func _sills() -> void:
	var top := float(_fr.foundation.top)
	var w := width
	var d := depth
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
	if not spec.has("cellar"):
		return
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
	if not spec.has("posts"):
		return
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
		# Brackets under it, each side of each post along it (`brackets: false`: none, the girder the
		# Baron's men saw in saloon B: a bracket would catch its cut halves).
		for p: Array in (spec.posts.free if b.get("brackets", true) else []):
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
	var cel: Array = (spec.get("cellar", {}) as Dictionary).get("rect", [-9, -9, -9, -9])
	var gz: Array = spec.girders.get("z", [])
	band = 1
	# Girders running front to back (`girders.x`: the doctor's, under the hall's walls), on piers.
	for gx: float in spec.girders.get("x", []):
		var z := every
		var k := 0
		while z < depth - 0.4:
			band = 0
			add_member("pier/gx%d_%02d" % [int(gx * 100), k], &"sill", &"stone", Vector3(pier, top + 0.3, pier), Vector3(gx, (top - 0.3) * 0.5, z))
			band = 1
			z += every
			k += 1
		_pieces("girder/x%d" % int(gx * 100), Vector3(gx, top + float(g[1]) * 0.5, 0.2), Vector3.BACK, depth - 0.4, Vector2(g[1], g[0]), &"sill", &"framing")
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
	# A girder under a bearing partition that runs with the joists (`girders.under`: saloon B's stair
	# hall and store room walls): from the piers to the floor's top, the joists beside it and the
	# boards butted to it each side, so the wall's studs stand on the girder and not on a board.
	var slots := []
	for u: Dictionary in spec.girders.get("under", []):
		var ux := float(u.x)
		var z0 := float(u.z[0])
		var z1 := float(u.z[1])
		var h := floor_top - top
		slots.append({"id": "under%d" % int(ux * 100), "slot": true, "rect": [ux - float(g[0]) * 0.5, z0, ux + float(g[0]) * 0.5, z1]})
		var z := z0 + 0.3
		var k := 0
		while z < z1:
			band = 0
			add_member("pier/u%d_%02d" % [int(ux * 100), k], &"sill", &"stone", Vector3(pier, top + 0.3, pier), Vector3(ux, (top - 0.3) * 0.5, z))
			band = 1
			z += every
			k += 1
		_pieces("girder/under%d" % int(ux * 100), Vector3(ux, top + h * 0.5, z0), Vector3.BACK, z1 - z0, Vector2(h, g[0]), &"sill", &"framing")
	for f: Dictionary in spec.floors:
		if f.level == "ground":
			var fl := f
			if not slots.is_empty():
				fl = f.duplicate()
				fl.openings = (f.get("openings", []) as Array) + slots
			_floor(fl, spec.girders.get("x", []) if spec.girders.has("x") else gz)


func _upper_floors() -> void:
	for f: Dictionary in spec.floors:
		if f.level == "upper":
			# `breaks`: where its joists are cut over a bearing wall under them (along them).
			_floor(f, f.get("breaks", []))


## A floor: joists along its `joists` axis at their spacing across `rect` (cut at `breaks` along
## them, the girders), framed round its openings (headers on the trimmers, the cut joists on the
## headers), the boards across them.
func _floor(f: Dictionary, breaks: Array) -> void:
	var r: Array = f.rect
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var jf: Dictionary = _fr[f.get("joist", "joist")]
	var js: Array = jf.section
	var spacing := float(jf.spacing)
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
				# A joist is cut a little short of what it butts (a floor's `end_gap`, saloon B's dance
				# floor): when its girder goes it hinges down on its other end, and a piece as long as
				# its bay would jam end to end against the next one (a rigid body's corner swings out).
				var gap := float(f.get("end_gap", 0.0))
				pr = [float(pr[0]) + gap, float(pr[1]) - gap]
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
		if o.get("slot", false):
			continue  # a girder's own slot in the boards (`girders.under`): nothing to head
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
		var top_kind: String = w.top if w.top is String else ("slope" if w.top is Array else "height")
		match top_kind:
			"slope":
				# A lean-to's end wall: its top falling from `top[0]` at the line's start to `top[1]`
				# at its end, under its rafters (and the boards on up to their top).
				var a := float(w.top[0])
				var b := float(w.top[1])
				var run := Vector2(w.line[0][0], w.line[0][1]).distance_to(Vector2(w.line[1][0], w.line[1][1]))
				var rf := float(_fr.truss.rafter[1])
				# With `plate`, a plate on the studs carries the rafters (a lean-to's back wall).
				var under_plate := PLATE_H if w.get("plate", false) else 0.0
				top_at = func(x: float) -> float: return lerpf(a, b, clampf(x / run, 0.0, 1.0)) - 0.02 - under_plate
				board_top = func(x: float) -> float: return lerpf(a, b, clampf(x / run, 0.0, 1.0)) + rf
				if String(w.get("boards", "")) == "under":
					# A wall the rafters cross (a lean-to's back): its boards stop under them.
					board_top = func(x: float) -> float: return lerpf(a, b, clampf(x / run, 0.0, 1.0)) - 0.03
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
		band = 1
		_studs(wall, sill_top, top_at, rects, -STUD_D, 0.0, sw)
		# With openings stacked and a corner cut off (saloon B: `frame.stacked`), what the studs carry
		# goes a band up: over an opening the wall's studs are cripples on its header (a tier above
		# plates, ribbons and nailers), and a plate, a ribbon, a board or a sash must rest on them.
		var clad := 2 if _fr.get("stacked", false) else 1
		band = clad
		# The plate on top, the ribbon the upper joists sit on.
		var length: float = wall.length
		var x0: float = wall.x_start
		var x1: float = wall.x_end
		if top_kind == "plate" or (top_kind == "slope" and w.get("plate", false)):
			var ph: float = top_at.call(0.0)
			_wall_run(wall, "%s/plate" % w.id, &"plate", x0, x1, ph, ph + PLATE_H, -STUD_D, 0.0, rects, x0 + sw * 0.5)
		var rb := _lv.upper_joist_bottom as float
		var rs: Array = _fr.ribbon.section
		if w.get("ribbon", true):
			_wall_run(wall, "%s/ribbon" % w.id, &"ledger", x0, x1, rb - float(rs[1]), rb, -STUD_D - float(rs[0]), -STUD_D, rects, x0 + sw * 0.5)
		# Outside: siding, cut round the openings and where a balcony's ledger is nailed to the studs.
		var cut := rects.duplicate()
		for b: Dictionary in spec.get("balconies", []):
			for l: Dictionary in b.ledgers:
				if l.wall == w.id:
					# (the balcony's own joists: 2x10s under a floor of deeper ones, saloon B's)
					var bj := float(_fr.joist.section[1])
					cut.append(Rect2(float(l.from), (_lv.upper as float) - float(_fr.floor_board.thick) - bj, float(l.to) - float(l.from), bj))
		# Where the porch roof's ledger and a lean-to's are nailed to the studs.
		if w.id == "front" and spec.has("porch"):
			cut.append(Rect2(-1.0, float(spec.porch.height) + 0.21, width + 2.0, 0.17))
		for o: Dictionary in spec.get("outbuildings", []):
			if o.kind == "lean_to" and o.get("wall", "") == w.id:
				cut.append(Rect2(float(o.rect[0]) - 0.01, float(o.high) - 0.16, float(o.rect[2]) - float(o.rect[0]) + 0.02, 0.17))
		var wood := StringName(w.outside.wood)
		if w.outside.siding == "lap" and w.outside.has("exposure"):
			_lap_courses(wall, board_top, cut, wood, float(w.outside.exposure))
			_corner_boards(wall, board_top)
		elif w.outside.siding == "lap":
			_lap_siding(wall, float(w.top) if w.top is float else wall_height, cut, wood)
		else:
			_vertical_siding(wall, board_top, cut, -BOARD_T, length + BOARD_T if absf((wall.along as Vector3).x) > 0.5 else length, wood)
		for o in ops:
			var spec_o: Dictionary = o[1]
			var window: bool = spec_o.type == "window"
			if spec_o.type == "void":
				continue  # a cut corner: open, the porch under the upper floor (`_corner_entrance`)
			_opening_trim(wall, o[0], window or spec_o.type == "hatch")
			if window and spec_o.has("lights"):
				# A sash window (#826): lined, two sashes, a pane a light (SashWindow, the part).
				SashWindow.build(self, wall, o[0], int(spec_o.lights), {"wood": StringName(spec.materials.get("trim_outside", "dark_trim"))})
			elif window:
				_glass(wall, o[0])
			if spec_o.get("bars", false):
				_bars(wall, o[0])
		# Inside: the finish on its inner face, level by level.
		for fin: Dictionary in w.inside:
			var lvl: String = fin.level
			var y0 := _lv[lvl] as float
			# The ground floor's finish on up to the upper floor (where no floor meets the wall, the
			# hall's open well, the joist band would show).
			var y1 := (_lv.upper as float) if lvl == "ground" else (wall_height - PLATE_H)
			if lvl == "ground" and spec.has("ceilings"):
				y1 = _lv.upper_joist_bottom as float
			if lvl == "upper" and top_kind == "gable":
				y1 = wall_height - PLATE_H
			y1 = minf(y1, float(fin.get("to_y", y1)))
			var face := _face(wall, -STUD_D, -1.0)
			# (a level's second stretch of finish on a wall takes its own ids: saloon B's stair well)
			var seg := 0
			for other: Dictionary in w.inside:
				if other == fin:
					break
				if other.level == lvl and String(other.finish) != "rough":
					seg += 1
			var fid := "%s/in_%s" % [w.id, lvl] if seg == 0 else "%s/in_%s/s%d" % [w.id, lvl, seg]
			_finish(face, fid, float(fin.from), float(fin.to), y0, y1, String(fin.finish), _rects_on(ops, lvl), 1)
		# Doors in it.
		for o in ops:
			var so: Dictionary = o[1]
			if so.type == "door":
				band = 4 if o[2] == "upper" else clad  # a leaf stands on the floor it opens on
				var lr: Rect2 = o[0]
				var tr := float(so.get("transom", 0.0))
				if tr > 0.0:
					# A transom light over the leaf: its bar and its glass in the one opening.
					lr.size.y -= tr
					var bar := Rect2(lr.position.x, lr.end.y, lr.size.x, 0.05)
					_wall_member("%s/transom_bar_%d" % [w.id, int(lr.position.x * 100)], &"trim", StringName(spec.materials.get("trim_outside", "dark_trim")), wall, bar.position.x, bar.end.x, bar.position.y, bar.end.y, -STUD_D, BOARD_T)
					_glass(wall, Rect2(lr.position.x, lr.end.y + 0.05, lr.size.x, tr - 0.05))
				_leaf(wall, lr, String(so.get("leaf", "inward")) == "outward", -STUD_D)
				band = clad
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
		band = 1


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
	# An opening stacked over another (a loft window over the street door): one of its kings stands
	# on the lower one's header, so its header, rough sill and what's over it go a band up (a header
	# can't rest on a cripple in the same band).
	var lifted := {}
	# (The doctor's rules, #765: the saloon's and farmhouse's frames are as they were until their turn.)
	var stacked: bool = _fr.has("rafters") or _fr.get("stacked", false)
	for j in openings.size() if stacked else 0:
		var o := openings[j]
		for q in openings:
			if q != o and q.end.y <= o.position.y + 0.001 and q.position.x < o.end.x + sw * 2.0 and q.end.x > o.position.x - sw * 2.0:
				lifted[j] = true
	var b0 := band
	var count := 0
	for sx in xs:
		band = b0  # (a stud after one lifted over a stacked opening is back in the wall's band)
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
				elif _fr.get("stacked", false) and sx + sw * 0.5 > o.position.x - sw * 2.0 - 0.01 and sx - sw * 0.5 < o.end.x + sw * 2.0 + 0.01:
					# Beside a narrower opening stacked on the one it's in (saloon B's upper windows
					# over wider ones): that opening's king stands here, not a cripple through its edge.
					spans = spans.filter(func(sp: Array) -> bool: return float(sp[1]) < o.position.y - PLATE_H or float(sp[0]) > o.end.y + HEADER_H)
			var k := 0
			for sp: Array in spans:
				if float(sp[1]) - float(sp[0]) > 0.05:
					var kind := &"stud" if float(sp[0]) <= foot + 0.001 else &"cripple"
					band = b0
					for jj: int in lifted:
						var lo := openings[jj]
						if sx > lo.position.x and sx < lo.end.x and float(sp[0]) >= lo.end.y + HEADER_H - 0.001:
							band = b0 + 1
					_wall_member("%s/stud/%03d_%d" % [n, count, k], kind, &"framing", wall, sx - sw * 0.5, sx + sw * 0.5, sp[0], sp[1], d0, d1)
					k += 1
		count += 1
	band = b0
	# King studs doubled (two nailed together, as period framing doubles them at an opening: they
	# carry the header and what's over it, a balcony's ledger among it).
	for j in openings.size():
		var o := openings[j]
		for side in 2:
			var kx := o.position.x - sw if side == 0 else o.end.x + sw
			# Between the openings stacked over and under this one (a door under a loft window): a
			# king runs from under the header of what's below it to under the rough sill of what's over.
			var k0 := foot
			var k1: float = top_at.call(kx)
			for q in openings if stacked else []:
				if q == o or kx + sw < q.position.x - 0.001 or kx - sw > q.end.x + 0.001:
					continue
				if q.position.y >= o.end.y - 0.001:
					k1 = minf(k1, q.position.y - PLATE_H)
				elif q.end.y <= o.position.y + 0.001:
					k0 = maxf(k0, q.end.y + HEADER_H)
			band = b0
			if kx - sw < x_start - 0.001 or kx + sw > x_end + 0.001:
				continue  # a void at the wall's end (saloon B's cut corner): its column stands there
			_wall_member("%s/opening%d/king%d" % [n, j, side], &"stud" if k0 <= foot + 0.001 else &"cripple", &"framing", wall, kx - sw, kx + sw,
					k0, k1, d0, d1)
		band = b0 + (1 if lifted.has(j) else 0)
		_wall_member("%s/opening%d/header" % [n, j], &"header", &"framing", wall, o.position.x, o.end.x, o.end.y, o.end.y + HEADER_H, d0, d1)
		if o.position.y > foot + 0.4:
			_wall_member("%s/opening%d/sill" % [n, j], &"header", &"framing", wall, o.position.x, o.end.x, o.position.y - PLATE_H, o.position.y, d0, d1)
	band = b0


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
	# #826 (#821 pick 3): with the spec's `inside_finish.boards` "judged", the boards are drawn at
	# the width their paint was judged at (painted_pale_tg: 9 cm, beaded): a member is as many of
	# them as come nearest the old 24 cm (three), drawn as that many boards (`strips`).
	var strip := 0.0 if hall else _judged_board_w(id + "/board/")
	if strip > 0.0:
		bw = strip * maxi(1, roundi(0.24 / strip))
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
		if strip > 0.0:
			# A member ends at an opening's side (#826: a 27 cm member cut out over a window's height
			# left a gap the 11 cm casing no longer covers), its last board ripped to fit.
			for o in holes:
				for edge in [o.position.x, o.end.x]:
					if edge > s + 0.02 and edge < e - 0.001:
						e = edge
		var spans: Array = [[y0 + wains, y1]]
		# (with boards as judged a member ends at an opening's side: one beside it isn't cut)
		var tol := -0.001 if strip > 0.0 else 0.02
		for o in holes:
			if o.position.x < e + tol and o.end.x > s - tol:
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
				# (judged boards close up: the joint is drawn, a gap showed the lit siding behind, #826)
				var gap := 0.0005 if strip > 0.0 else 0.002
				var m := _on_face(face, "%s/board/%03d_%d" % [id, i, k], &"board", &"framing", s + gap, e - gap, sp[0], sp[1], 0.0, t)
				if hall:
					PropKit.dress_member(m, {"shape": "profile", "profile": "beaded", "along": "y", "up": n_axis, "across": along_axis, "args": [0.006]}, look)
				else:
					(m.get_child(0) as MeshInstance3D).material_override = WoodMaterials.get_material(StringName(spec.materials.wall_boards), hash(m.member_id))
				if strip > 0.0:
					m.set_meta(&"strips", strip)
					m.set_meta(&"strips_across", 0 if along_axis == "x" else 2)
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
		var sk := float(spec.get("inside_finish", {}).get("skirting", 0.0))
		if sk > 0.0:
			_skirting(face, id, s0, s1, y0, sk, t, holes)
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


## A plain skirting (#826, #821 pick 3) along a boarded face, `h` high over its boards, in runs
## between the openings that come down to the floor (doors), each no longer than a stock length,
## its top edge rounded; the trim's finish (spec surfaces `/skirt`).
func _skirting(face: Dictionary, id: String, s0: float, s1: float, y0: float, h: float, t: float, holes: Array[Rect2]) -> void:
	var runs: Array = [[s0, s1]]
	for o in holes:
		if o.position.y < y0 + 0.3:
			var nxt: Array = []
			for r: Array in runs:
				# (stopped at the casing's foot, 11 cm out from the opening)
				if o.position.x - 0.11 > float(r[0]):
					nxt.append([r[0], minf(o.position.x - 0.11, r[1])])
				if o.end.x + 0.11 < float(r[1]):
					nxt.append([maxf(o.end.x + 0.11, r[0]), r[1]])
			runs = nxt
	for ri in runs.size():
		var r: Array = runs[ri]
		var length := float(r[1]) - float(r[0])
		if length < 0.06:
			continue
		var n := maxi(1, ceili(length / 4.9))
		for k in n:
			var a := float(r[0]) + length * k / n
			var b := float(r[0]) + length * (k + 1) / n
			_on_face(face, "%s/skirt%d_%d" % [id, ri, k], &"trim", &"oak", a, b - 0.002, y0, y0 + h, t, t + 0.022)


## The board width a finish was judged at (its library entry's `board_w`), for a member id the spec's
## surfaces give a finish, when the spec asks for boards as judged (`inside_finish.boards`); else 0.
func _judged_board_w(id: String) -> float:
	if String(spec.get("inside_finish", {}).get("boards", "")) != "judged":
		return 0.0
	for sf: Array in spec.materials.get("surfaces", []):
		if id.contains(String(sf[0])):
			var f := finish(String(sf[1]))
			if f.is_empty():
				return 0.0
			return float(MaterialLibrary.resolved(MaterialLibrary.entry(String(f.entry))).get("board_w", 0.0))
	return 0.0


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
		if not w.get("partition", false) or w.level != level or w.get("stone", false):
			continue  # (a stone partition is stone.gd's, #780)
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
			# Into the room it serves: a partition's leaf swings to its -out side unless its spec
			# says "outward" (the back rooms' doors open into the rooms, not across the gallery).
			if String((o[1] as Dictionary).type) == "door":  # (an arch and a hatch have no leaf)
				_leaf(wall, o[0], String((o[1] as Dictionary).get("leaf", "inward")) == "outward", -STUD_D * 0.5)


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
	if not spec.has("cellar"):
		return
	var c: Dictionary = spec.cellar.stair
	_stair({"id": "cellar", "head": c.head, "dir": c.dir, "width": c.width, "risers": c.risers, "going": c.going},
			_lv.cellar + 0.08, _lv.ground)


func _outside_stair() -> void:
	for st: Dictionary in spec.stairs:
		if not (st.from is String):
			_stair(st, float(st.from), float(st.to) if not (st.to is String) else (_lv[st.to] as float))


func _balconies() -> void:
	var js: Array = _fr.joist.section
	var top := _lv.upper as float
	var jt := top - float(_fr.floor_board.thick)
	var jb := jt - float(js[1])
	for b: Dictionary in spec.get("balconies", []):
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
		band = 2 if _fr.get("stacked", false) else 1
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
	if not spec.has("galleries"):
		return
	var g: Dictionary = spec.galleries
	var top := _lv.upper as float
	var look := String(g.look)
	for k in (g.rails as Array).size():
		var r: Array = g.rails[k]
		var a := Vector3(r[0][0], top, r[0][1])
		var e := Vector3(r[1][0], top, r[1][1])
		var rh := float(g.get("height", 1.0))
		var made := Railing.build(self, "gallery/rail/%d" % k, a, e, {"height": rh, "spacing": 0.12, "baluster": 0.045,
				"rail": Vector2(0.075, 0.06), "wood": &"oak"})
		for m in made:
			if m.kind == &"trim":
				PropKit.dress_member(m, {"shape": "profile", "profile": "handrail", "along": "x", "up": "y"}, look)
			else:
				PropKit.dress_member(m, {}, look)
		# Square newels with caps at its ends.
		for p in [a, e]:
			var nw := add_member("gallery/newel/%d_%d" % [k, int(p.x * 10 + p.z)], &"furniture_frame", &"oak", Vector3(0.125, rh + 0.15, 0.125), p + Vector3.UP * (rh + 0.15) * 0.5)
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
	if _fr.has("rafters"):
		return wall_height
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
		# Boards across them in stock lengths (~5.8 m), their joints staggered, from `roof_from` (behind
		# a false front; or out over a gable as its rake) to `roof_to`.
		var r0 := float(spec.levels.get("roof_from", 0.1))
		var r1 := float(spec.levels.get("roof_to", depth + 0.3))
		var row := 0
		var s := 0.0
		while s < slope - 0.02:
			var bw := minf(0.195, slope - s)
			var c := base + dir * (s + bw * 0.5) + normal * (float(rf[1]) + BOARD_T * 0.5)
			var spans := []
			var at := r0
			var cut := r0 + 5.8 + 0.6 * (row % 2)
			while at < r1 - 0.05:
				var nxt := minf(cut, r1) if r1 - cut > 1.0 else r1
				spans.append([at, nxt])
				at = nxt
				cut += 5.8
			for k in spans.size():
				var sp: Array = spans[k]
				var cz := c
				cz.z = (float(sp[0]) + float(sp[1])) * 0.5
				add_member("roof/board_%d/%02d_%d" % [side, row, k], &"roof_board", &"weathered_pine", Vector3(bw, BOARD_T, float(sp[1]) - float(sp[0]) - 0.004), cz, sl.basis)
			s += 0.2
			row += 1
	var ridge_y := under + half * tan(ang) + (float(rf[1]) + BOARD_T) / cos(ang)
	var rz0 := float(spec.levels.get("roof_from", 0.0))
	var rz1 := float(spec.levels.get("roof_to", depth + 0.2))
	# Down onto the boards' top rows either side of the ridge (on a steep roof they fall away under
	# its edges).
	var cap_drop := 0.17 * tan(ang) * 0.5 if ang > deg_to_rad(20.0) else 0.0
	add_member("roof/ridge_cap", &"trim", &"dark_trim", Vector3(0.34, BOARD_T, rz1 - rz0), Vector3(half, ridge_y + BOARD_T * 0.5 - 0.005 - cap_drop, (rz0 + rz1) * 0.5))


## Whether the front is a false front (the saloon's) rather than a gable (a farmhouse's).
func _has_false_front() -> bool:
	for w: Dictionary in spec.walls:
		if w.id == "front":
			return not (w.top is String and w.top == "gable")
	return false


## A porch roof across the front on two posts (FalseFrontBuilding's, the town's porches): its
## `depth` out and its beam's underside `height` up; the deck under it is a Boardwalk, set down by
## whoever places the building.
func _porch() -> void:
	var p: Dictionary = spec.porch
	porch_depth = float(p.depth)
	porch_height = float(p.height)
	porch_lantern = false
	_build_porch()


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
		var r: Array = f.get("rect", [])
		var keep := floor_top
		band = 0 if f.level == "cellar" else 2
		floor_top = (_lv.cellar + 0.08) if f.level == "cellar" else (_lv[f.level] as float)
		# A rect in the building's axes; or `at` (x, z) and `size` (in its own axes, turned `facing`).
		var cx := (float(r[0]) + float(r[2])) * 0.5 if f.has("rect") else float(f.at[0])
		var cz := (float(r[1]) + float(r[3])) * 0.5 if f.has("rect") else float(f.at[1])
		var sx := float(r[2]) - float(r[0]) if f.has("rect") else float(f.size[0])
		var sz := float(r[3]) - float(r[1]) if f.has("rect") else float(f.size[2])
		match String(f.members):
			"table":
				_table(String(f.id), r[0], r[2], r[1], r[3], float(f.height))
			"shelves":
				_shelves(String(f.id), r[0], r[2], r[1], r[3], int(f.boards))
			"bed":
				# The kit's table as a bed's frame (legs and a board bottom), a head board at its +x
				# or -x end (`head`), the tick on it a soft sack (grain sacks' canvas).
				var head := 1.0 if String(f.get("head", "+x")) == "+x" else -1.0
				var h := float(f.get("height", 0.45))
				_fixture(&"table", String(f.id), Vector2(cx, cz), Vector3(sx, h, sz), 0.0, {"top": {"wood": "framing", "look": "wood:" + String(inside_look(&"framing"))}},
						[{"id": "headboard", "kind": "furniture_frame", "wood": "framing", "size": [0.05, 0.6, sz], "at": [head * (sx * 0.5 - 0.025), h + 0.3, 0.0]},
						{"id": "tick", "kind": "furniture_top", "wood": "framing", "look": "prop:burlap", "size": [sx - 0.1, 0.12, sz - 0.08], "at": [0.0, h + 0.06, 0.0]}])
			"dresser":
				# The kit's counter turned to the room as a dresser: a front, two ends and a top.
				_fixture(&"counter", String(f.id), Vector2(cx, cz), Vector3(sx, float(f.get("size", [0, 0.95])[1]), sz), float(f.get("facing", 0.0)), {})
			"stove":
				# A cast-iron cook stove (iron: a ball or a charge doesn't break it): the kit's counter in
				# iron, its pipe up through the roof.
				var h := float(f.get("size", [0, 0.8])[1])
				var pipe_h := float(f.get("pipe", 2.0))
				_fixture(&"counter", String(f.id), Vector2(cx, cz), Vector3(sx, h, sz), float(f.get("facing", 0.0)),
						{"front": {"wood": "iron", "look": "prop:iron"}, "end_l": {"wood": "iron", "look": "prop:iron"},
						"end_r": {"wood": "iron", "look": "prop:iron"}, "top": {"wood": "iron", "look": "prop:iron"}},
						[{"id": "pipe", "kind": "trim", "wood": "iron", "look": "prop:iron", "size": [0.15, pipe_h, 0.15], "at": [0.0, h + pipe_h * 0.5, sz * 0.25]}])
		floor_top = keep
	band = 2


func _outbuildings() -> void:
	for o: Dictionary in spec.get("outbuildings", []):
		if o.kind == "lean_to":
			_lean_to(o)
			continue
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


## A lean-to (a farmhouse's kitchen) against one of the house's walls (`wall`, the back): its own
## stone footing and sills round `rect` (x0, z0, x1, z1; z0 on that wall's outer face), its floor at
## the house's (joists along z on its sills), its walls (in `walls` with the house's: their `top` a
## height or a `slope`, `ribbon` false) and a shed roof: rafters from a ledger on the house's studs
## at `high` (the siding cut for it) over the back wall's plate at `low`, boards across them.
func _lean_to(o: Dictionary) -> void:
	var r: Array = o.rect
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var id := String(o.id)
	var f: Dictionary = _fr.foundation
	var t := float(f.thick)
	var top := float(f.top)
	band = 0
	for run in [["front", Vector2(x0, z0), Vector2(x1, z0)], ["back", Vector2(x0, z1 - t), Vector2(x1, z1 - t)],
			["west", Vector2(x0, z0 + t), Vector2(x0, z1 - t)], ["east", Vector2(x1 - t, z0 + t), Vector2(x1 - t, z1 - t)]]:
		_stone_run("%s/foundation/%s" % [id, run[0]], run[1], run[2], t, top, [], float(f.bottom))
	var sill: Array = _fr.sill.section
	var sw := float(sill[0])
	var sy := top + float(sill[1]) * 0.5
	var sec := Vector2(sill[1], sill[0])
	_pieces(id + "/sill/front", Vector3(x0, sy, z0 + sw * 0.5), Vector3.RIGHT, x1 - x0, sec, &"sill", &"framing")
	_pieces(id + "/sill/back", Vector3(x0, sy, z1 - sw * 0.5), Vector3.RIGHT, x1 - x0, sec, &"sill", &"framing")
	_pieces(id + "/sill/west", Vector3(x0 + sw * 0.5, sy, z0 + sw), Vector3.BACK, z1 - z0 - sw * 2.0, sec, &"sill", &"framing")
	_pieces(id + "/sill/east", Vector3(x1 - sw * 0.5, sy, z0 + sw), Vector3.BACK, z1 - z0 - sw * 2.0, sec, &"sill", &"framing")
	band = 1
	_floor({"id": id, "level": "ground", "rect": [x0 + STUD_D, z0 + 0.03, x1 - STUD_D, z1 - STUD_D], "joists": "z", "look": o.get("floor_look", "")}, [])
	# The ledger on the house's studs (its siding cut), the rafters from it over the back wall's
	# plate, the boards across them.
	var house: Dictionary = walls[String(o.wall)].dict
	var high := float(o.high)
	var low := float(o.low)
	var lh := 0.15
	_wall_member("%s/ledger" % id, &"ledger", &"framing", house, x0, x1, high - lh, high, 0.0, 0.05)
	var rf: Array = _fr.truss.rafter
	var za := z0 + 0.055
	var zb := z1 - STUD_D * 0.5
	var ang := atan2(high - low, zb - za)
	var dir := Vector3(0.0, -sin(ang), cos(ang))
	var normal := Vector3(0.0, cos(ang), sin(ang))
	var over := 0.3
	var length := (zb - za + over) / cos(ang)
	var start := Vector3(0.0, high, za)
	var basis := Basis(Vector3.RIGHT, ang)
	var x := x0 + float(rf[0]) * 0.5 + 0.01
	var i := 0
	while x < x1 - float(rf[0]) * 0.5:
		var c := start + dir * (length * 0.5) + normal * (float(rf[1]) * 0.5)
		c.x = x
		add_member("%s/rafter/%02d" % [id, i], &"rafter", &"framing", Vector3(rf[0], rf[1], length), c, basis)
		i += 1
		x = minf(x + float(_fr.truss.rafter_spacing), x1 - float(rf[0]) * 0.5 - 0.01) if x < x1 - float(rf[0]) - 0.02 else x1
	var row := 0
	var sl := 0.0
	while sl < length - 0.02:
		var bw := minf(0.195, length - sl)
		var c := start + dir * (sl + bw * 0.5) + normal * (float(rf[1]) + BOARD_T * 0.5)
		c.x = (x0 + x1) * 0.5
		add_member("%s/roof/%02d" % [id, row], &"roof_board", StringName(o.get("roof_wood", "weathered_pine")), Vector3(x1 - x0 + 0.3, BOARD_T, bw - 0.004), c, basis)
		sl += 0.2
		row += 1


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
	for sc: Dictionary in L.get("sconces", []):
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
	for lp: Array in L.get("on_furniture", []):
		# A lamp standing on furniture (a table's top, a dresser's), [x, y over its floor, z].
		_lamp(Vector3(lp[0], floor_top + float(lp[1]), lp[2]))
	_kit_lamps(L)
	if not L.has("chandelier"):
		return
	# The chandelier's lamps on its rim.
	var c: Dictionary = L.chandelier
	for k in int(c.lamps):
		var a := TAU * (k + 0.5) / int(c.lamps)
		var p := Vector3(c.at[0], float(c.y) + 0.035, c.at[1]) + Vector3(cos(a), 0, sin(a)) * float(c.radius) * cos(PI / 8.0)
		_lamp(p)


## The kit's lamps hung on the walls (#824: a building names its lamps, a room each): `lamps.kit`,
## each {kit (a lamp the kit hangs on a nail: reflector_lamp), wall, level, at (along the wall),
## height (its foot over the floor), side (a partition's - or +), lit [from, until hours], energy,
## reach, shadows}. The prop hangs on its nail in the wall's boards (it falls when they go) and
## carries its OilLamp (the flame's light, lit by the clock; GlassProp takes it as its hitbox).
func _kit_lamps(L: Dictionary) -> void:
	for e: Dictionary in L.get("kit", []):
		var wl: Dictionary = walls[e.wall]
		var wall: Dictionary = wl.dict
		var partition: bool = wl.spec.get("partition", false)
		var plus: bool = partition and e.get("side", "-") == "+"
		var face_d := (STUD_D * 0.5 + 0.02 if plus else -STUD_D * 0.5 - 0.02) if partition else -STUD_D - 0.02
		var into := (wall.out as Vector3) if plus else -(wall.out as Vector3)
		var level := String(e.get("level", "ground"))
		var foot := (_lv[level] as float) + float(e.height)
		if wl.spec.get("stone", false):
			# A stone wall (#811, the jail): on its face at the lamp's height (its profile; a stone
			# partition's + side is its line, the - side its thickness in).
			var band := StoneBuilder.band_at(wl.spec.profile, foot)
			face_d = band.y if plus else band.x
		var p: Vector3 = wall.origin + (wall.along as Vector3) * float(e.at) + (wall.out as Vector3) * face_d
		var kit := StringName(e.get("kit", "reflector_lamp"))
		var def := PropKit.definition(kit)
		# Its back on the boards: the nail's tab is the back of its box.
		var back := absf(float((def.get("hangs", {}).get("nails", [[0, 0, -0.12]]) as Array)[0][2])) + 0.01
		var prop := PropKit.make(kit)
		prop.name = "KitLamp%02d" % lamps.size()
		prop.transform = Transform3D(Basis(Vector3.UP, atan2(into.x, into.z)), Vector3(p.x, foot, p.z) + into * back)
		_furnish.add_child(prop)
		var lamp := OilLamp.new()
		lamp.name = "Light"
		lamp.show_mesh = false
		var lit: Array = e.get("lit", [17, 23])
		lamp.lit_from_hour = int(lit[0])
		lamp.lit_until_hour = int(lit[1])
		lamp.energy = float(e.get("energy", 1.2))
		lamp.light_range = float(e.get("reach", 6.0))
		lamp.casts_shadows = bool(e.get("shadows", false))
		# The flame: over the fount, in front of the reflector.
		var flame: Array = e.get("flame", [0.0, 0.24, 0.04])
		lamp.position = Vector3(flame[0], flame[1], flame[2])
		prop.add_child(lamp)
		lamps.append(lamp)


## The kit's fixtures and furniture, and the lamps that stand on them.
func _kit() -> void:
	var f0 := floor_top
	for fx: Dictionary in spec.get("fixtures", []):
		var rep: Dictionary = fx.get("repeat", {"count": 1, "step": [0, 0]})
		for k in int(rep.count):
			var at := Vector3(fx.at[0] + float(rep.step[0]) * k, f0, fx.at[1] + float(rep.step[1]) * k)
			_spawn(StringName(fx.kit), at, float(fx.facing))
	for lp: Array in spec.lamps.get("on_bar", []):
		var top := PropKit.bounds(PropKit.definition(&"bar")).end.y
		_lamp(Vector3(lp[0], f0 + top, lp[1]))
	for f: Dictionary in spec.furniture:
		if not f.has("kit"):
			continue
		var at := Vector3(f.at[0], f0, f.at[1])
		_spawn(StringName(f.kit), at, float(f.get("facing", 15.0)))
		if f.kit == "card_table" or f.has("chairs"):
			for k in int(f.get("chairs", 0)):
				var a := deg_to_rad(15.0 + 90.0 * k)
				var off := Vector3(sin(a), 0.0, cos(a)) * 0.85
				# A chair faces +Z: turned to look at the table.
				_spawn(&"chair", at + off, rad_to_deg(atan2(-off.x, -off.z)))
			if spec.lamps.get("on_tables", false):
				var top := PropKit.bounds(PropKit.definition(&"card_table")).end.y
				_lamp(at + Vector3(0.1, top, -0.1))


## The spec's furniture and props laid into its rooms (#844, `dressing`: PropDressing), every batch;
## the labs that judge them read `dressed`, never a placement of their own.
func _dressing() -> void:
	if "--no-dressing" in OS.get_cmdline_user_args():
		return  # (the bench's before: the rooms bare)
	var d: Dictionary = spec.get("dressing", {})
	for b: String in d.get("batches", {}):
		var placed := PropDressing.place(_furnish, d.batches[b], floor_top, String(structure_id))
		dressed[b] = placed
		for n: Node3D in placed.values():
			if n is KitProp:
				kit_props.append(n)
	if not dressed.is_empty():
		# Its glass props' fixed parts (corks, labels, contents: ~750 meshes in the doctor's) drawn
		# as the town's are (StaticBatch: one draw a kind; a shot or a fall hands a prop back). The
		# valley has no StaticBatch of its own; its kit props join PropBatch by themselves.
		var batch := StaticBatch.new()
		batch.name = "DressingBatch"
		_furnish.add_child(batch)


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
		if u.has("prop"):
			# The dressing entry he sits or lies on (#844): the fit check leaves it out.
			m.set_meta(&"prop", StringName("%s_dress_%s" % [structure_id, u.prop]))
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
		for m: Variant in r[1]:  # (untyped: a member freed since; typed, each look was an error, #863)
			if is_instance_valid(m) and not (m as StructureMember).broken and not (m as StructureMember).consumed:
				standing = true
		if not standing:
			ramp.queue_free()


# --- a small gable-fronted building (the doctor's, #765): what the saloon and farmhouse don't have ---

## Lap siding in courses of `exposure` from just under the foundation's top up to the wall's own
## top at each course (`board_top`: the gable's rake, the plate), cut round the openings: the
## narrow planed clapboard of a fine building (FalseFrontBuilding's lap is 0.2 m from the ground).
func _lap_courses(wall: Dictionary, board_top: Callable, openings: Array[Rect2], wood: StringName, exposure: float) -> void:
	var n: String = wall.name
	var length: float = wall.length
	var y := float(_fr.foundation.top) - 0.04
	var row := 0
	while true:
		var y1 := y + exposure
		# Where along the wall this course fits under the top (a gable narrows it).
		var spans: Array[Vector2] = []
		var a := -1.0
		var x := 0.0
		while x <= length + 0.001:
			var ok: bool = (board_top.call(x) as float) >= y1 - 0.01
			if ok and a < 0.0:
				a = x
			if (not ok or x + 0.02 > length) and a >= 0.0:
				spans.append(Vector2(a, x if not ok else length))
				a = -1.0
			x += 0.02
		if spans.is_empty():
			break
		var cuts: Array[Vector2] = []
		for o in openings:
			if o.position.y < y1 and o.end.y > y:
				cuts.append(Vector2(o.position.x, o.end.x))
		var seg := 0
		for sp in spans:
			for piece in _subtract_spans(sp, cuts):
				if piece.y - piece.x > 0.04:
					_wall_member("%s/siding/r%02d_%d" % [n, row, seg], &"board", wood, wall, piece.x, piece.y, y, y1 - 0.003, 0.0, BOARD_T)
					seg += 1
		y = y1
		row += 1


## Corner boards (1x4 each side of the corner, the trim's colour) up each end of a lapped wall.
func _corner_boards(wall: Dictionary, board_top: Callable) -> void:
	var n: String = wall.name
	var length: float = wall.length
	var y0 := float(_fr.foundation.top) - 0.04
	var trim := StringName(spec.materials.get("trim_outside", "dark_trim"))
	for e in 2:
		var x0 := -BOARD_T if e == 0 else length - 0.09
		var x1 := 0.09 if e == 0 else length + BOARD_T
		var top: float = minf(board_top.call(0.05 if e == 0 else length - 0.05), board_top.call(maxf(x0, 0.0)))
		_wall_member("%s/corner_%d" % [n, e], &"trim", trim, wall, x0, x1, y0, top, BOARD_T, BOARD_T + TRIM_T)


## Each chimney (spec.chimneys) cut out of every floor it passes through: an opening a little wider
## than its stack, so the floor's joists are headered round it and its boards stop short (nothing
## of the floor rests on the brick; a chimney carries only itself).
func _chimney_openings() -> void:
	for c: Dictionary in (spec.get("chimneys", {}) as Dictionary).get("list", []):
		var h := float(c.size) * 0.5 + 0.05
		for f: Dictionary in spec.floors:
			# Across the joists the hole runs from trimmer to trimmer: out to the joist lines either side.
			var jf: Dictionary = _fr[f.get("joist", "joist")]
			var jw := float(jf.section[0])
			var along_z: bool = f.joists == "z"
			var fr: Array = f.rect
			var a0 := float(fr[0]) if along_z else float(fr[1])
			var cc := float(c.at[0]) if along_z else float(c.at[1])
			var line0 := a0 + jw * 0.5 + 0.02
			var sp := float(jf.spacing)
			var lo := line0 + floorf((cc - h - line0) / sp) * sp + jw * 0.5
			var hi := line0 + ceilf((cc + h - line0) / sp) * sp - jw * 0.5
			var r := [float(c.at[0]) - h, lo, float(c.at[0]) + h, hi] if not along_z else [lo, float(c.at[1]) - h, hi, float(c.at[1]) + h]
			var ops: Array = f.get("openings", [])
			var have := false
			for o: Dictionary in ops:
				if o.id == "chimney_" + String(c.id):
					have = true
			if not have:
				ops.append({"id": "chimney_" + String(c.id), "rect": r})
				f.openings = ops


## The rafters' lines along the building: one over each gable wall, and one beside each of the
## loft's joists (so every rafter's foot is spiked to a joist: the joists are the roof's ties).
func _rafter_lines() -> Array[float]:
	var rf: Array = _fr.rafters.rafter
	var out: Array[float] = [float(rf[0]) * 0.5 + 0.025]
	var cj: Dictionary = _fr.get("ceiling_joist", _fr.joist)
	var js: Array = cj.section
	for f: Dictionary in spec.floors:
		if f.level != "upper":
			continue
		var r: Array = f.rect
		var p := float(r[1]) + float(js[0]) * 0.5 + 0.02
		while p < float(r[3]) - float(js[0]) * 0.5:
			var z := p + (float(js[0]) + float(rf[0])) * 0.5
			if z > out.back() + float(rf[0]) + 0.05 and z < depth - float(rf[0]) - 0.1:
				out.append(z)
			p += float(cj.spacing)
		break
	out.append(depth - float(rf[0]) * 0.5 - 0.025)
	return out


## The roof (Hodgson 1883): common rafters from the plates (their feet spiked to the loft's joists)
## to a ridge board, collar ties high on every few pairs, the rafters headered round each chimney,
## boards across them in stock lengths, a ridge cap. The rafters' underside meets the walls' outer
## face at the plate's top (`_roof_under`), as the gable walls' studs and boards are cut to it.
func _rafter_roof() -> void:
	var r: Dictionary = _fr.rafters
	var rf: Array = r.rafter
	var rd: Array = r.ridge
	var ang := deg_to_rad(roof_pitch_degrees)
	var half := width * 0.5
	var over := float(r.eave) / cos(ang)
	var top_end := half / cos(ang)
	var holes := _roof_holes()
	band = 5
	var zs := _rafter_lines()
	for side in 2:
		var sl := _slope(side)
		var dir: Vector3 = sl.dir
		var normal: Vector3 = sl.normal
		var base: Vector3 = (sl.eave as Vector3) + Vector3(0, wall_height, 0)
		for i in zs.size():
			var z := zs[i]
			# Its stretch along the slope, less where a chimney comes through (headers either side).
			var parts: Array = [[-over, top_end]]
			for hl: Dictionary in holes:
				if hl.side == side and z > float(hl.z0) - float(rf[0]) * 0.5 and z < float(hl.z1) + float(rf[0]) * 0.5:
					parts = [[-over, float(hl.s0) - 0.1], [float(hl.s1) + 0.1, top_end]]
			for k in parts.size():
				var a := float(parts[k][0])
				var b := float(parts[k][1])
				if b - a < 0.15:
					continue
				# A rafter cut by a chimney: its upper length hangs on the header (over the rafters' band).
				band = 7 if k > 0 else 5
				var c := base + dir * ((a + b) * 0.5) + normal * (float(rf[1]) * 0.5)
				c.z = z
				add_member("roof/rafter_%d/%02d_%d" % [side, i, k], &"rafter", &"framing", Vector3(b - a, rf[1], rf[0]), c, sl.basis)
		# Doubled headers across each chimney's hole, from trimmer to trimmer.
		band = 6
		for hl: Dictionary in holes:
			if hl.side != side:
				continue
			var t0 := 0.0
			var t1 := depth
			for z in zs:
				if z < float(hl.z0) - float(rf[0]) * 0.5 and z > t0:
					t0 = z
				if z > float(hl.z1) + float(rf[0]) * 0.5 and z < t1:
					t1 = z
			for e in 2:
				var s := (float(hl.s0) - 0.1 + 0.05) if e == 0 else (float(hl.s1) + 0.1 - 0.05)
				var c := base + dir * s + normal * (float(rf[1]) * 0.5)
				c.z = (t0 + t1) * 0.5
				add_member("roof/%s/header_%d" % [hl.id, e], &"rafter", &"framing", Vector3(0.1, rf[1], t1 - t0 + float(rf[0])), c, sl.basis)
	# The ridge board, plumb, between the rafters' heads (held by them).
	band = 6
	var top_y := wall_height + half * tan(ang) + float(rf[1]) / cos(ang)
	_pieces("roof/ridge", Vector3(half, top_y - float(rd[1]) * 0.5, 0.0), Vector3.BACK, depth, Vector2(rd[1], rd[0]), &"ridge", &"framing")
	# Collar ties: a quarter of the rise down from the ridge on every `collar_every` pair, inside the gables.
	var rise := half * tan(ang)
	var yc := wall_height + rise * (1.0 - float(r.collar_down))
	var xc := half * (1.0 - float(r.collar_down))
	var ct: Array = r.collar
	for i in range(1, zs.size() - 1):
		if i % int(r.collar_every) != 0:
			continue
		add_member("roof/collar/%02d" % i, &"rafter", &"framing", Vector3(width - 2.0 * xc, ct[1], ct[0]),
				Vector3(half, yc + float(ct[1]) * 0.5, zs[i] + (float(rf[0]) + float(ct[0])) * 0.5))
	# Boards across the rafters, rows up each slope, cut round the chimneys.
	band = 8
	var r0 := float(spec.levels.get("roof_from", 0.0))
	var r1 := float(spec.levels.get("roof_to", depth))
	var slope := top_end + over
	for side in 2:
		var sl := _slope(side)
		var dir: Vector3 = sl.dir
		var normal: Vector3 = sl.normal
		var base: Vector3 = (sl.eave as Vector3) + Vector3(0, wall_height, 0) - dir * over
		var row := 0
		var s := 0.0
		while s < slope - 0.02:
			var bw := minf(0.145, slope - s)
			var sa := s - over  # along the slope from the wall's face
			var spans: Array = [[r0, r1]]
			for hl: Dictionary in holes:
				if hl.side == side and sa + bw > float(hl.s0) and sa < float(hl.s1):
					var nxt: Array = []
					for sp: Array in spans:
						if float(sp[0]) < float(hl.z0):
							nxt.append([sp[0], minf(float(hl.z0), sp[1])])
						if float(sp[1]) > float(hl.z1):
							nxt.append([maxf(float(hl.z1), sp[0]), sp[1]])
					spans = nxt
			var k := 0
			for sp: Array in spans:
				var at := float(sp[0])
				var cut := at + 4.9 + 0.6 * (row % 2)
				while at < float(sp[1]) - 0.05:
					var nx := minf(cut, float(sp[1])) if float(sp[1]) - cut > 1.0 else float(sp[1])
					var c := base + dir * (s + bw * 0.5) + normal * (float(rf[1]) + BOARD_T * 0.5)
					c.z = (at + nx) * 0.5
					add_member("roof/board_%d/%02d_%d" % [side, row, k], &"roof_board", StringName(spec.materials.get("roof", "weathered_pine")), Vector3(bw - 0.003, BOARD_T, nx - at - 0.004), c, sl.basis)
					k += 1
					at = nx
					cut += 4.9
			s += 0.15
			row += 1
	var ridge_y := top_y + BOARD_T / cos(ang)
	var cap_drop := 0.17 * tan(ang) * 0.5
	band = 9
	add_member("roof/ridge_cap", &"trim", StringName(spec.materials.get("trim_outside", "dark_trim")), Vector3(0.34, BOARD_T, r1 - r0), Vector3(half, ridge_y + BOARD_T * 0.5 - 0.005 - cap_drop, (r0 + r1) * 0.5))


## Where each chimney comes through the roof: its slope (0 the -x side), its stretch along the slope
## from the wall's face (`s0`..`s1`), and along the building (`z0`..`z1`), with a little clearance.
func _roof_holes() -> Array:
	var out := []
	var ang := deg_to_rad(roof_pitch_degrees)
	var half := width * 0.5
	for c: Dictionary in (spec.get("chimneys", {}) as Dictionary).get("list", []):
		var h := float(c.size) * 0.5 + 0.05
		var cx := float(c.at[0])
		var side := 0 if cx < half else 1
		var d0 := (cx - h) if side == 0 else (width - cx - h)
		var d1 := minf((cx + h) if side == 0 else (width - cx + h), half)
		out.append({"id": "chimney_" + String(c.id), "side": side, "s0": d0 / cos(ang), "s1": d1 / cos(ang) + 0.05,
				"z0": float(c.at[1]) - h, "z1": float(c.at[1]) + h})
	return out


## Brick chimneys on their own footings from under the foundation to over the ridge, in lengths
## (a blast breaks a length; each length rests on the one below).
func _chimneys() -> void:
	var ch: Dictionary = spec.get("chimneys", {})
	var ang := deg_to_rad(roof_pitch_degrees)
	var ridge := wall_height + width * 0.5 * tan(ang) + float(_fr.rafters.rafter[1]) / cos(ang)
	for c: Dictionary in ch.get("list", []):
		var sz := float(c.size)
		var y0 := float(_fr.foundation.bottom)
		var y1 := ridge + float(c.get("over_ridge", 0.6))
		var n := maxi(1, ceili((y1 - y0) / 1.2))
		for k in n:
			var a := y0 + (y1 - y0) * k / n
			var b := y0 + (y1 - y0) * (k + 1) / n
			add_member("chimney/%s/%d" % [c.id, k], &"post", StringName(ch.get("wood", "stone")), Vector3(sz, b - a - 0.002, sz), Vector3(c.at[0], (a + b) * 0.5, c.at[1]))


## Ceilings: beaded boards nailed up under the loft's joists across every ground-floor room, run
## along z (across the joists), cut round the floor's openings above (the scuttle, the chimneys).
func _ceilings() -> void:
	var y1: float = _lv.upper_joist_bottom
	var t := 0.016
	var bw := 0.14
	var strip := _judged_board_w("ceiling/")
	if strip > 0.0:
		bw = strip * maxi(1, roundi(bw / strip))
	var holes: Array = []
	for f: Dictionary in spec.floors:
		if f.level == "upper":
			holes.append_array(f.get("openings", []))
	for sb: Dictionary in spec.get("summer_beams", []):
		var hw := float(sb.section[0]) * 0.5
		holes.append({"rect": [float(sb.x) - hw, float(sb.z[0]), float(sb.x) + hw, float(sb.z[1])]})
	var look := StringName(spec.materials.wall_boards)
	for rm: Dictionary in spec.rooms:
		if rm.level != "ground":
			continue
		var r: Array = rm.rect
		var x := float(r[0])
		var i := 0
		while x < float(r[2]) - 0.02:
			var x1 := minf(x + bw, float(r[2]))
			var spans: Array = [[float(r[1]), float(r[3])]]
			for o: Dictionary in holes:
				var orr: Array = o.rect
				if x1 > float(orr[0]) and x < float(orr[2]):
					var nxt: Array = []
					for sp: Array in spans:
						if float(sp[0]) < float(orr[1]):
							nxt.append([sp[0], minf(float(orr[1]), sp[1])])
						if float(sp[1]) > float(orr[3]):
							nxt.append([maxf(float(orr[3]), sp[0]), sp[1]])
					spans = nxt
			var k := 0
			for sp: Array in spans:
				var a := float(sp[0])
				while a < float(sp[1]) - 0.05:
					var b := minf(a + 4.9, float(sp[1]))
					var m := add_member("ceiling/%s/%03d_%d" % [rm.id, i, k], &"board", &"framing", Vector3(x1 - x - 0.003, t, b - a - 0.003), Vector3((x + x1) * 0.5, y1 - t * 0.5, (a + b) * 0.5))
					(m.get_child(0) as MeshInstance3D).material_override = WoodMaterials.get_material(look, hash(m.member_id))
					if strip > 0.0:
						m.set_meta(&"strips", strip)
						m.set_meta(&"strips_across", 0)
					k += 1
					a = b
			x = x1
			i += 1


## The sign across a gable's foot (spec.gable_sign: its height and width), on the siding over the
## walk's porch roof, its lettering SignArt's.
func _gable_sign() -> void:
	var gs: Dictionary = (spec.get("front", {}) as Dictionary).get("gable_sign", {})
	if gs.is_empty() or not walls.has("front"):
		return
	var front: Dictionary = walls["front"].dict
	var w := float(gs.width)
	var x0 := (width - w) * 0.5
	var sign := _wall_member("front/sign", &"trim", &"sign", front, x0, x0 + w, float(gs.y[0]), float(gs.y[1]), BOARD_T, BOARD_T + 0.03)
	SignArt.hang(self, sign, String(spec.front.sign_text))


## A deck of members: a ledger on the wall it's against (`ledger`: the wall's id, or none), a beam
## on posts at its outer edge, joists across, boards on them. Its top at `top`.
func _deck(id: String, r: Array, top: float, against: String, posts: Array) -> void:
	var x0 := float(r[0])
	var z0 := float(r[1])
	var x1 := float(r[2])
	var z1 := float(r[3])
	var bt := 0.025
	var jd := 0.14
	var jt := top - bt
	var jb := jt - jd
	var along_z := against == "yard" or against == "lane"  # joists run out from the wall
	# The beam on its posts along the outer edge, the posts on stone blocks.
	for k in posts.size():
		var p: Array = posts[k]
		band = 0
		add_member("%s/block_%d" % [id, k], &"sill", &"stone", Vector3(0.25, 0.25, 0.25), Vector3(p[0], 0.05, p[1]))
		add_member("%s/post_%d" % [id, k], &"post", &"framing", Vector3(0.09, jb - 0.12 - 0.175, 0.09), Vector3(p[0], (0.175 + jb - 0.12) * 0.5, p[1]))
	band = 1
	if along_z:
		var bx := x0 + 0.05
		add_member("%s/beam" % id, &"beam", &"framing", Vector3(0.1, 0.12, z1 - z0), Vector3(bx, jb - 0.06, (z0 + z1) * 0.5))
	else:
		var bz := z1 - 0.05
		add_member("%s/beam" % id, &"beam", &"framing", Vector3(x1 - x0, 0.12, 0.1), Vector3((x0 + x1) * 0.5, jb - 0.06, bz))
	# The ledger on the wall's studs, through its siding.
	if along_z:
		add_member("%s/ledger" % id, &"ledger", &"framing", Vector3(0.05, jd, z1 - z0), Vector3(x1 - 0.025, (jt + jb) * 0.5, (z0 + z1) * 0.5))
	else:
		add_member("%s/ledger" % id, &"ledger", &"framing", Vector3(x1 - x0, jd, 0.05), Vector3((x0 + x1) * 0.5, (jt + jb) * 0.5, z0 + 0.025))
	band += 1
	var n := 0
	if along_z:
		var z := z0 + 0.03
		while z < z1 - 0.02:
			add_member("%s/joist_%d" % [id, n], &"joist", &"framing", Vector3(x1 - x0 - 0.05, jd, 0.05), Vector3((x0 + x1 - 0.05) * 0.5, (jt + jb) * 0.5, z))
			z = minf(z + 0.406, z1 - 0.03) if z < z1 - 0.06 else z1
			n += 1
	else:
		var x := x0 + 0.03
		while x < x1 - 0.02:
			add_member("%s/joist_%d" % [id, n], &"joist", &"framing", Vector3(0.05, jd, z1 - z0 - 0.05), Vector3(x, (jt + jb) * 0.5, (z0 + z1 + 0.05) * 0.5))
			x = minf(x + 0.406, x1 - 0.03) if x < x1 - 0.06 else x1
			n += 1
	# Boards along the wall.
	var i := 0
	if along_z:
		var x := x0
		while x < x1 - 0.02:
			var xb := minf(x + 0.14, x1)
			add_member("%s/board_%d" % [id, i], &"floor_board", StringName(spec.materials.get("deck", "weathered_pine")), Vector3(xb - x - 0.004, bt, z1 - z0), Vector3((x + xb) * 0.5, top - bt * 0.5, (z0 + z1) * 0.5))
			x = xb
			i += 1
	else:
		var z := z0
		while z < z1 - 0.02:
			var zb := minf(z + 0.14, z1)
			add_member("%s/board_%d" % [id, i], &"floor_board", StringName(spec.materials.get("deck", "weathered_pine")), Vector3(x1 - x0, bt, zb - z - 0.004), Vector3((x0 + x1) * 0.5, top - bt * 0.5, (z + zb) * 0.5))
			z = zb
			i += 1


## The back porch (spec.back_porch): its deck one step down from the floor, and a shed roof over it
## on two posts, its rafters from a ledger on the back wall's studs down to a beam on the posts.
func _back_porch() -> void:
	var bp: Dictionary = spec.get("back_porch", {})
	if bp.is_empty():
		return
	var r: Array = bp.rect
	var top := float(bp.deck_top)
	band = 1
	_deck("back_porch", r, top, "back", bp.posts)
	band = 3
	var rh := top + float(bp.roof_height)
	var hi := rh + 0.45
	var x0 := float(r[0])
	var x1 := float(r[2])
	var z0 := float(r[1])
	var z1 := float(r[3])
	for k in (bp.posts as Array).size():
		var p: Array = bp.posts[k]
		add_member("back_porch/roof_post_%d" % k, &"post", &"framing", Vector3(0.09, rh - 0.12 - top, 0.09), Vector3(p[0], (top + rh - 0.12) * 0.5, p[1]))
	add_member("back_porch/roof_beam", &"beam", &"framing", Vector3(x1 - x0 + 0.3, 0.12, 0.1), Vector3((x0 + x1) * 0.5, rh - 0.06, float(bp.posts[0][1])))
	add_member("back_porch/roof_ledger", &"ledger", &"framing", Vector3(x1 - x0 + 0.3, 0.14, 0.05), Vector3((x0 + x1) * 0.5, hi - 0.07, z0 + 0.025))
	# The rafters' underside from the ledger's top at the wall down over the beam's top, 0.3 m past it.
	var zb := float(bp.posts[0][1])
	var p0 := Vector2(z0 + 0.05, hi)
	var p1 := Vector2(zb, rh)
	var dv := (p1 - p0).normalized()
	var ang := atan2(hi - rh, zb - z0 - 0.05)
	var run := p0.distance_to(p1) + 0.3
	var bas := Basis(Vector3.RIGHT, ang)
	var nrm := Vector2(-dv.y, dv.x) if dv.x > 0.0 else Vector2(dv.y, -dv.x)  # up from the slope
	if nrm.y < 0.0:
		nrm = -nrm
	band = 4
	var x := x0 - 0.1
	var i := 0
	while x <= x1 + 0.15:
		var mid := p0 + dv * (run * 0.5) + nrm * 0.05
		add_member("back_porch/rafter_%d" % i, &"rafter", &"framing", Vector3(0.05, 0.1, run), Vector3(x, mid.y, mid.x), bas)
		x += 0.61
		i += 1
	band = 5
	var s := 0.0
	var j := 0
	while s < run:
		var w := minf(0.145, run - s)
		var q := p0 + dv * (s + w * 0.5) + nrm * (0.1 + BOARD_T * 0.5)
		add_member("back_porch/roof_board_%d" % j, &"roof_board", StringName(spec.materials.get("roof", "weathered_pine")), Vector3(x1 - x0 + 0.5, BOARD_T, w - 0.003), Vector3((x0 + x1) * 0.5, q.y, q.x), bas)
		s += 0.15
		j += 1


## Each stair's stoop (`stoop`: a small deck at the floor's top by its door, against the wall).
func _stoops() -> void:
	for st: Dictionary in spec.get("stairs", []):
		if not st.has("stoop"):
			continue
		var r: Array = st.stoop
		var against := "yard" if float(r[2]) <= 0.01 else ("lane" if float(r[0]) >= width - 0.01 else "back")
		var out_x := float(r[0]) if against == "yard" else float(r[2])
		band = 1
		var posts := [[out_x + (0.06 if against == "yard" else -0.06), float(r[1]) + 0.06], [out_x + (0.06 if against == "yard" else -0.06), float(r[3]) - 0.06]]
		if against == "back":
			# (a stoop at a back door: its beam along the wall, a post under each end)
			posts = [[float(r[0]) + 0.06, float(r[3]) - 0.06], [float(r[2]) - 0.06, float(r[3]) - 0.06]]
		_deck("stoop/" + String(st.id), r, floor_top, against, posts)


## The side yard's front (lot.yard_front): a picket fence on the front line from the building to the
## lot's edge, a wagon gate in it (two leaves standing open into the yard), on 4x4 posts.
func _yard_front() -> void:
	var yf: Dictionary = (spec.lot as Dictionary).get("yard_front", {})
	if yf.is_empty():
		return
	var yard: Array = spec.lot.yard
	var z := float(yf.fence_z) - 0.3
	var xa := minf(float(yard[0]), float(yard[2]))
	var xb := maxf(float(yard[0]), float(yard[2])) - 0.05
	var g0 := minf(float(yf.gate[0]), float(yf.gate[1]))
	var g1 := maxf(float(yf.gate[0]), float(yf.gate[1]))
	var wood := StringName(spec.materials.get("fence", "painted_white"))
	var runs := [[xa, g0], [g1, xb]]
	var k := 0
	for rr: Array in runs:
		var a := float(rr[0])
		var b := float(rr[1])
		var n := maxi(1, ceili((b - a) / 2.4))
		for i in n + 1:
			var px := a + (b - a) * i / n
			add_member("fence/post_%d" % k, &"post", &"framing", Vector3(0.09, 1.5, 0.09), Vector3(px, 0.5, z))
			k += 1
		for h in [0.35, 1.0]:
			add_member("fence/rail_%d_%d" % [int(a * 100), int(h * 100)], &"beam", &"framing", Vector3(b - a, 0.09, 0.04), Vector3((a + b) * 0.5, h, z + 0.065))
		var px := a + 0.1
		var j := 0
		while px < b - 0.08:
			add_member("fence/picket_%d_%d" % [int(a * 100), j], &"board", wood, Vector3(0.07, 1.1, 0.02), Vector3(px, 0.6, z + 0.095))
			px += 0.15
			j += 1
	# A board fence down the yard's far side (`side_fence`: the doctor's, against the alley), 6 ft:
	# its posts at `x`, the rails and boards outside them (toward -x), the boards' face on the lot line.
	var sf: Dictionary = yf.get("side_fence", {})
	if not sf.is_empty():
		var fx := float(sf.x)
		var za := float(sf.z[0])
		var zb := float(sf.z[1])
		var fh := float(sf.get("h", 1.8))
		var n := maxi(1, ceili((zb - za) / 2.4))
		for i in n + 1:
			add_member("fence/side_post_%d" % i, &"post", &"framing", Vector3(0.09, fh + 0.3, 0.09), Vector3(fx, (fh + 0.3) * 0.5 - 0.3, za + (zb - za) * i / n))
		for h in [0.3, fh - 0.25]:
			add_member("fence/side_rail_%d" % int(h * 100), &"beam", &"framing", Vector3(0.04, 0.09, zb - za), Vector3(fx - 0.065, h, (za + zb) * 0.5))
		var bz := za
		var j := 0
		while bz < zb - 0.05:
			add_member("fence/side_board_%d" % j, &"board", wood, Vector3(0.02, fh - 0.05, 0.14), Vector3(fx - 0.095, (fh - 0.05) * 0.5 + 0.05, bz + 0.07))
			bz += 0.15
			j += 1
	# The gate's leaves, standing open into the yard.
	var lw := (g1 - g0) * 0.5 - 0.03
	for e in 2:
		var hx := g0 + 0.03 if e == 0 else g1 - 0.03
		add_member("fence/gate_%d" % e, &"door", wood, Vector3(0.05, 1.1, lw), Vector3(hx, 0.65, z + lw * 0.5 + 0.06))


## Ladders (the game's Ladder part) fixed to a wall: its foot on the ground by the wall's face, up
## to `to` (a loft door's sill), with stiles and rungs as members on the wall's studs.
func _ladders() -> void:
	for l: Dictionary in spec.get("ladders", []):
		if not walls.has(l.wall):
			continue
		var wall: Dictionary = walls[l.wall].dict
		var out: Vector3 = wall.out
		var along: Vector3 = wall.along
		var foot: Vector3 = wall.origin + along * float(l.at) + out * (BOARD_T + 0.08)
		foot.y = float(l.from)
		var h := float(l.to) - float(l.from)
		var lw := float(l.width)
		band = 1
		for e in 2:
			var c := foot + along * (lw * 0.5 * (1 if e == 0 else -1)) + Vector3.UP * (h * 0.5 + 0.45)
			add_member("ladder/%s/stile_%d" % [l.id, e], &"post", &"framing", along.abs() * 0.05 + Vector3.UP * (h + 0.9) + out.abs() * 0.07, c)
		var y := 0.3
		var k := 0
		while y < h + 0.8:
			add_member("ladder/%s/rung_%d" % [l.id, k], &"trim", &"framing", along.abs() * lw + Vector3.UP * 0.035 + out.abs() * 0.035, foot + Vector3.UP * y)
			y += 0.3
			k += 1
		var ld := Ladder.new()
		ld.name = "Ladder_" + String(l.id)
		ld.height = h
		ld.width = lw
		ld.transform = Transform3D(Basis.looking_at(-out, Vector3.UP), foot)
		_furnish.add_child(ld)


## Summer beams (spec.summer_beams): where the loft's joists break over a room with no bearing wall
## under them (the doctor's front office, across the hall's lines), a beam on two posts standing on
## the floor over the girders, its top at the joists' underside, the posts let into the walls at its ends.
func _summer_beams() -> void:
	var y1: float = _lv.upper_joist_bottom
	for sb: Dictionary in spec.get("summer_beams", []):
		var sec: Array = sb.section
		var x := float(sb.x)
		var z0 := float(sb.z[0])
		var z1 := float(sb.z[1])
		var yb := y1 - float(sec[1])
		for k in (sb.posts as Array).size():
			# A post is its z, or [z, depth]: one let into a wall is the wall's depth (#844: the
			# doctor's front ones stood 0.15 m proud beside the street door, read as a metal post).
			var pe: Variant = sb.posts[k]
			var pz := float(pe[0]) if pe is Array else float(pe)
			var pd := float(pe[1]) if pe is Array else float(sec[0])
			add_member("summer/%s/post_%d" % [sb.id, k], &"post", &"framing", Vector3(sec[0], yb - floor_top, pd), Vector3(x, (floor_top + yb) * 0.5, pz))
		var m := add_member("summer/%s/beam" % sb.id, &"beam", &"framing", Vector3(sec[0], sec[1], z1 - z0), Vector3(x, (yb + y1) * 0.5, (z0 + z1) * 0.5))
		if spec.materials.has("timber"):
			PropKit.dress_member(m, {}, String(spec.materials.timber))


## Let-in corner braces (Bell 1858, Woodward 1865: a balloon frame braced at each corner): a 1x4 let
## into the studs' outer faces from the sill near each end of an outer wall up toward the plate,
## as steep as it needs to be to clear the wall's openings (none if no line clears them).
func _braces() -> void:
	var sill_top := float(_fr.foundation.top) + float(_fr.sill.section[1])
	for w: Dictionary in spec.walls:
		if w.get("partition", false) or not walls.has(w.id):
			continue
		var wall: Dictionary = walls[w.id].dict
		var length: float = wall.length
		var rects := _rects_on(_openings(w), "ground") + _rects_on(_openings(w), "upper")
		var y1 := wall_height - PLATE_H - 0.02
		for e in 2:
			for run: float in [2.0, 1.6, 1.2, 0.9, 0.6]:
				var a := Vector2(0.15 if e == 0 else length - 0.15, sill_top + 0.02)
				var b := Vector2(a.x + run * (1 if e == 0 else -1), y1)
				var clear := true
				for o in rects:
					var g := o.grow(0.06)
					for k in 21:
						var p := a.lerp(b, k / 20.0)
						if g.has_point(p):
							clear = false
				if not clear:
					continue
				var mid := (a + b) * 0.5
				var len := a.distance_to(b)
				var along: Vector3 = wall.along
				var out: Vector3 = wall.out
				var dir := (along * (b.x - a.x) + Vector3.UP * (b.y - a.y)).normalized()
				var c: Vector3 = wall.origin + along * mid.x + Vector3.UP * mid.y + out * (-0.0125)
				var bas := Basis(dir, out.cross(dir).normalized() if out.cross(dir).dot(Vector3.UP) >= 0.0 else -out.cross(dir).normalized(), out)
				bas = Basis(dir, bas.y, dir.cross(bas.y).normalized())
				add_member("%s/brace_%d" % [w.id, e], &"ledger", &"framing", Vector3(len, 0.09, 0.025), c, bas.orthonormalized())
				break


# --- finishes from the material library by name (#765; Sean, 2026-11-10: only woods the materials
# judge passed, #721; a building takes its finish from the library by name, so a finish that passes
# later appears without a rebuild) -----------------------------------------------------------------

const LIB_SHADER := "res://src/render/scan_wood.gdshader"
const LIB_AGES := {"new": 0.0, "few": 0.5, "old": 1.0}
var _lib_mats := {}

## The finish a surface takes (spec.materials.finishes[name]): its `want` when the library has that
## entry and it's passed at that age (the entry's `approved`), else its `use` (a swatch the
## materials judge passed: the spec says which round). {entry, age, role} or {}.
func finish(name: String) -> Dictionary:
	var f: Dictionary = (spec.materials.get("finishes", {}) as Dictionary).get(name, {})
	if f.is_empty():
		return {}
	var want: Dictionary = f.get("want", {})
	if not want.is_empty():
		var e := MaterialLibrary.entry(String(want.entry))
		if not e.is_empty() and (e.get("approved", []) as Array).has(String(want.get("age", "few"))):
			return want
	return f.get("use", {})


## Which finish a member takes (spec.materials.surfaces: [[pattern in its id, finish], ...] the
## first that matches; then `framing` for timber, none for stone, glass and the sign).
func _finish_of(m: StructureMember) -> String:
	var id := String(m.member_id).trim_prefix(String(structure_id) + "/")
	if m.kind == &"glass" or m.wood in [&"stone", &"brick", &"sign", &"glass"]:
		return ""
	for s: Array in spec.materials.get("surfaces", []):
		if id.contains(String(s[0])):
			return String(s[1])
	return "framing"


## Every member drawn as a board of its finish's library wood (the library's shader, a board mesh
## in its own frame carrying the shader's per-board channels: Structure batches such boards by the
## way they face). Members made later (a cut's ends) are drawn in their own wood as before.
func _library_finishes() -> void:
	if not (spec.materials.get("finishes", {}) as Dictionary).size():
		return
	var gy := global_position.y if is_inside_tree() else 0.0
	for m: StructureMember in get_members():
		var fname := _finish_of(m)
		if fname == "":
			continue
		var f := finish(fname)
		if f.is_empty():
			continue
		var mi := m.drawn_node()
		if mi == null:
			continue
		# A paint lies over a wood (#721's paint round): its boards' class and nails are the resolved entry's.
		var e := MaterialLibrary.resolved(MaterialLibrary.entry(String(f.entry)))
		var cls: Dictionary = SamplePanel.CLASSES.get(StringName(e.get("wood_class", "common")), SamplePanel.CLASSES[&"common"])
		var ai: int = ["new", "few", "old"].find(String(f.get("age", "few")))
		var warp := float(cls.warp[ai]) * float(e.get("warp_scale", 1.0))
		var nails := Vector2(float(e.get("nails", 1)), float(e.get("nail_at", 0.6)))
		# The board's frame in the member: X along its longest side, Y its next, Z through it.
		var s := m.size
		var order := [0, 1, 2]
		order.sort_custom(func(a: int, b: int) -> bool: return s[a] > s[b])
		var strip := float(m.get_meta(&"strips", 0.0))
		if strip > 0.0:
			# Boards drawn across a set axis (the wall's along, the ceiling's x), the grain the other way.
			var across := int(m.get_meta(&"strips_across", order[1]))
			order.erase(across)
			order.insert(1, across)
			if s[order[2]] > s[order[0]]:
				order = [order[2], order[1], order[0]]
		var ex := Vector3.ZERO
		ex[order[0]] = 1.0
		var ey := Vector3.ZERO
		ey[order[1]] = 1.0
		var ez := ex.cross(ey)
		var length: float = s[order[0]]
		var rng := hash(m.member_id)
		# Inside, the paint's wear (the hand band, scuffs, dust at the skirting) is measured from the
		# room's floor, not the street's ground (#821, the review's cause 7: the doctor's floor is
		# 0.95 m up, so his hand band fell at the floor line and the scuffs under it).
		var ground := gy + (_floor_under(m) if INSIDE_FINISHES.has(fname) else 0.0)
		if strip > 0.0:
			mi.mesh = strips_mesh(length, s[order[1]], s[order[2]], strip, rng, warp, nails, ground)
		else:
			mi.mesh = _board_mesh(length, s[order[1]], s[order[2]], float(rng % 100000) / 100000.0, warp, nails, ground)
		mi.transform = Transform3D(Basis(ex, ey, ez), -ex * length * 0.5)
		mi.material_override = _lib_material(f, gy)


## The finishes inside the rooms, whose wear is measured from their floor (`_floor_under`).
const INSIDE_FINISHES := ["inside", "ceiling", "floor"]


## The floor a member stands over, in the building's space: the highest level's top at or under its
## foot (a wall board's bottom; a ceiling's board over the room it closes).
func _floor_under(m: StructureMember) -> float:
	var foot := m.position.y - m.size.y * 0.5 + 0.05
	var best := -INF
	for k: String in ["cellar", "ground", "upper"]:
		var v := float(_lv.get(k, -INF))
		if v <= foot and v > best:
			best = v
	return best if best > -INF else 0.0


func _lib_material(f: Dictionary, gy: float) -> ShaderMaterial:
	var key := "%s/%s/%s" % [f.entry, f.get("age", "few"), f.get("role", "wall")]
	if _lib_mats.has(key):
		return _lib_mats[key]
	var mat := ShaderMaterial.new()
	mat.shader = load(LIB_SHADER)
	MaterialLibrary.apply(mat, MaterialLibrary.entry(String(f.entry)), float(LIB_AGES.get(String(f.get("age", "few")), 0.5)), StringName(f.get("role", "wall")))
	# Its walls' height (shelter under the eaves: the shader's `wall_top` over the ground).
	mat.set_shader_parameter(&"wall_top", wall_height)
	# A floor wood with feet's wear takes this building's ways (#825).
	if String(f.get("role", "")) == "floor" and float(MaterialLibrary.resolved(MaterialLibrary.entry(String(f.entry))).get("traffic", 0.0)) > 0.0:
		var tw := traffic_ways()
		if not (tw.ways as Array).is_empty():
			var gt := global_transform if is_inside_tree() else transform
			var gl := float(_lv.get("ground", 0.0))
			MaterialLibrary.set_traffic(mat, MaterialLibrary.traffic_image(tw.size, tw.ways, tw.rooms), gt * Vector3.ZERO,
					gt.basis.x, gt.basis.z, tw.size, (gt * Vector3(0.0, gl, 0.0)).y)
	_lib_mats[key] = mat
	return mat


## The ground floor's ways (#825), for its floor's traffic map: in each room, from every door to every
## other (through traffic) and from each use point on the floor to its nearest door and to the room's
## nearest outside door (where callers come in), heavier where someone works or serves. Doors are the walls' door openings on the ground level; rooms their
## rects. {ways: [[Vector2, Vector2, weight]], rooms: [[x0, z0, x1, z1]], size: Vector2} in the
## building's own x, z.
func traffic_ways() -> Dictionary:
	var ground := float(_lv.get("ground", 0.0))
	var rooms := []
	var size := Vector2.ZERO
	for r: Dictionary in spec.get("rooms", []):
		if String(r.get("level", "ground")) != "ground":
			continue
		var rc: Array = r.rect
		rooms.append([float(rc[0]), float(rc[1]), float(rc[2]), float(rc[3])])
		size = Vector2(maxf(size.x, float(rc[2]) + 0.1), maxf(size.y, float(rc[3]) + 0.1))
	var doors := []
	var outer := []
	for w: Dictionary in spec.get("walls", []):
		var a := Vector2(w.line[0][0], w.line[0][1])
		var e := Vector2(w.line[1][0], w.line[1][1])
		var dir := (e - a).normalized()
		for o: Dictionary in w.get("openings", []):
			if String(o.get("type", "")) in ["door", "arch"] and String(o.get("level", w.get("level", "ground"))) in ["ground", "<null>"]:
				doors.append(a + dir * float(o.at))
				if w.has("out"):
					outer.append(a + dir * float(o.at))
	if spec.has("corner"):
		var cf: Array = spec.corner.from
		var ct: Array = spec.corner.to
		var mid := Vector2((float(cf[0]) + float(ct[0])) * 0.5, (float(cf[1]) + float(ct[1])) * 0.5)
		doors.append(mid)
		outer.append(mid)
	var heavy := ["work", "serve", "operate", "buy"]
	var ways := []
	for rc: Array in rooms:
		var ds := doors.filter(func(d: Vector2) -> bool:
			return d.x > rc[0] - 0.3 and d.x < rc[2] + 0.3 and d.y > rc[1] - 0.3 and d.y < rc[3] + 0.3)
		for i in ds.size():
			for j in range(i + 1, ds.size()):
				ways.append([ds[i], ds[j], 0.8])
		if ds.is_empty():
			continue
		for u: Dictionary in spec.get("use_points", []):
			if not u.has("at"):
				continue  # a kit's seats (the card tables')
			var at: Array = u.at
			var p := Vector2(at[0], at[2])
			if absf(float(at[1]) - ground) > 0.2 or p.x < rc[0] or p.x > rc[2] or p.y < rc[1] or p.y > rc[3]:
				continue
			var near: Vector2 = ds[0]
			for d: Vector2 in ds:
				if d.distance_to(p) < near.distance_to(p):
					near = d
			var k := 1.0 if String(u.get("use", "")) in heavy else 0.7
			ways.append([near, p, k])
			var near_out := Vector2.INF
			for d: Vector2 in ds:
				if outer.has(d) and d.distance_to(p) < near_out.distance_to(p):
					near_out = d
			if near_out != Vector2.INF and near_out != near:
				ways.append([near_out, p, k * 0.8])
	return {"ways": ways, "rooms": rooms, "size": size}


## A board's mesh in the library shader's own layout (scan_wood.gdshader's header: X along 0..L,
## Y across, Z through; CUSTOM0 seed, x / L, 2y / W, face; CUSTOM1 L, W, T, warp; CUSTOM2 nails,
## their place, ground y, role), its grid coarser than the sample panel's (a building has thousands
## of boards: ~150 vertices a long board, not ~600), its arrays kept on it (MemberMesh.arrays_of:
## the batch merges them without a read back) and marked `board_frame` for Structure's batching.
static func _board_mesh(length: float, width: float, thick: float, seed: float, warp: float, nails: Vector2, ground_y: float) -> ArrayMesh:
	return PropKit.board_mesh(length, width, thick, seed, warp, nails, ground_y)  # (shared with the kit's props, #788)


## A member drawn as boards `strip` wide side by side across its width (#826: a wall cut 27 cm a
## member, drawn as the three 9 cm beaded boards its paint was judged at), the last one ripped to
## what's left; each a library board of its own (its own seed, grain, bead and nails), one mesh in
## the board frame (`_board_mesh`'s), so it batches as one board does.
static func strips_mesh(length: float, width: float, thick: float, strip: float, rng: int, warp: float, nails: Vector2, ground_y: float) -> ArrayMesh:
	var widths: Array[float] = []
	var left := width
	while left > 0.0005:
		var w := minf(strip, left)
		if left - w < 0.03 and widths.size() > 0 and left - w > 0.0005:
			w = left  # (no sliver: the last board takes it)
		widths.append(w)
		left -= w
	var parts: Array = []
	var y := -width * 0.5
	for i in widths.size():
		var wi: float = widths[i]
		var seed := float(hash(rng + i * 7919) % 100000) / 100000.0
		var arr: Array = PropKit.board_mesh(length, wi, thick, seed, warp, nails, ground_y).get_meta(&"arrays")
		parts.append([arr, y + wi * 0.5])
		y += wi
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var idx := PackedInt32Array()
	for p: Array in parts:
		var a: Array = p[0]
		var off := Vector3(0.0, float(p[1]), 0.0)
		var base := v.size()
		for q: Vector3 in a[Mesh.ARRAY_VERTEX]:
			v.append(q + off)
		n.append_array(a[Mesh.ARRAY_NORMAL])
		uv.append_array(a[Mesh.ARRAY_TEX_UV])
		c0.append_array(a[Mesh.ARRAY_CUSTOM0])
		c1.append_array(a[Mesh.ARRAY_CUSTOM1])
		c2.append_array(a[Mesh.ARRAY_CUSTOM2])
		for k: int in a[Mesh.ARRAY_INDEX]:
			idx.append(base + k)
	out[Mesh.ARRAY_VERTEX] = v
	out[Mesh.ARRAY_NORMAL] = n
	out[Mesh.ARRAY_TEX_UV] = uv
	out[Mesh.ARRAY_CUSTOM0] = c0
	out[Mesh.ARRAY_CUSTOM1] = c1
	out[Mesh.ARRAY_CUSTOM2] = c2
	out[Mesh.ARRAY_INDEX] = idx
	var fmt := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) \
			| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
			| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out, [], {}, fmt)
	mesh.custom_aabb = AABB(Vector3(-0.02, -width * 0.5 - 0.02, -thick * 0.5 - 0.02), Vector3(length + 0.04, width + 0.04, thick + 0.04))
	mesh.set_meta(&"arrays", out)
	mesh.set_meta(&"board_frame", true)
	mesh.set_meta(&"strip_widths", widths)
	return mesh



# --- the corner entrance (saloon B, #848) -------------------------------------------------------------

## The diagonal wall's frame: its line from `corner.from` to `corner.to` (the studs' outer face),
## `along` it, `out` to the street corner, and the basis its members take (x along, z into the room).
func _corner_frame() -> Dictionary:
	var c: Dictionary = spec.corner
	var a := Vector3(c.from[0], 0, c.from[1])
	var e := Vector3(c.to[0], 0, c.to[1])
	var along := (e - a).normalized()
	var out := Vector3(along.z, 0, -along.x)
	if out.dot(Vector3(width, 0, 0) - a) < 0.0:
		out = -out
	return {"origin": a, "along": along, "out": out, "length": a.distance_to(e), "basis": Basis(along, Vector3.UP, along.cross(Vector3.UP))}


## A member of the diagonal wall: `s0..s1` along it, `y0..y1`, `d0..d1` out from its line.
func _diag(c: Dictionary, id: String, kind: StringName, wood: StringName, s0: float, s1: float, y0: float, y1: float, d0: float, d1: float) -> StructureMember:
	var along: Vector3 = c.along
	var out: Vector3 = c.out
	var b: Basis = c.basis
	# (the basis' z is `along x up`: into the room when that is -out)
	var center: Vector3 = (c.origin as Vector3) + along * ((s0 + s1) * 0.5) + Vector3.UP * ((y0 + y1) * 0.5) + out * ((d0 + d1) * 0.5)
	return add_member(id, kind, wood, Vector3(s1 - s0, y1 - y0, d1 - d0), center, b)


## Payday Night's sabotage (`sabotage`, saloon B: the girder the Baron's men saw): the kerf cut
## through it (`cut`: metres along it from its middle), as Structure.cut_member; what it carried
## comes down when the structure next settles. Returns the two halves left on their posts.
func saw_girder() -> Array[StructureMember]:
	var sb: Dictionary = spec.get("sabotage", {})
	var g := get_member(StringName("%s/%s" % [structure_id, sb.get("girder", "")]))
	if g == null or g.broken:
		return []
	var c: Array = sb.get("cut", [-0.15, 0.15])
	return cut_member(g, float(c[0]), float(c[1]), Vector3.DOWN * 0.5)


## A corner cut off on the diagonal for the entrance (`corner`; the walls' `void` openings leave it
## open): one cast-iron column at the corner from the sill to the balcony's beam, a deep beam each
## way from it to the walls' studs under their headers (the upper floor runs on over the porch), and
## the diagonal wall: studs under a plate against the upper joists, glazed double doors standing
## open inward, a transom light over them, boarded both sides.
func _corner_entrance() -> void:
	var cs: Dictionary = spec.corner
	var c := _corner_frame()
	var sill_top := float(_fr.foundation.top) + float(_fr.sill.section[1])
	var col: Dictionary = cs.column
	var cw := float(col.size)
	var bj := float(_fr.joist.section[1])
	var balcony_beam := 0.25
	for b: Dictionary in spec.get("balconies", []):
		balcony_beam = float((b.beam as Array)[1])
		break
	var col_top := (_lv.upper as float) - float(_fr.floor_board.thick) - bj - balcony_beam
	band = 0
	var column := add_member("corner/column", &"post", StringName(col.get("wood", "iron")), Vector3(cw, col_top - sill_top, cw),
			Vector3(col.at[0], (col_top + sill_top) * 0.5, col.at[1]))
	column.set_meta(&"corner_column", true)
	# The beams under the two walls' headers over the cut (their voids), column to king studs.
	band = 1
	var bm: Array = cs.beam
	for w: Dictionary in spec.walls:
		if w.get("partition", false):
			continue
		for o: Dictionary in w.get("openings", []):
			if o.type != "void":
				continue
			var wall: Dictionary = walls[w.id].dict
			var top := floor_top + float(o.height)
			var s0 := float(o.at) - float(o.width) * 0.5
			var s1 := float(o.at) + float(o.width) * 0.5
			# Clear of the column's own square at the wall's corner end.
			if s0 < 0.01:
				s0 = cw
			if s1 > float(wall.length) - 0.01:
				s1 = float(wall.length) - cw
			_wall_member("corner/beam_%s" % w.id, &"header", &"framing", wall, s0, s1, top - float(bm[1]), top, -float(bm[0]), 0.0)
	# The diagonal wall, standing on the ground floor.
	band = 2
	var L: float = c.length
	var foot := floor_top
	var top := (_lv.upper_joist_bottom as float)
	var dw := float(cs.door.width)
	var dh := float(cs.door.height)
	var tr := float(cs.door.get("transom", 0.0))
	var d0 := (L - dw) * 0.5
	var d1 := (L + dw) * 0.5
	var head := foot + dh + tr
	_diag(c, "corner/plate", &"plate", &"framing", 0.0, L, top - PLATE_H, top, -STUD_D, 0.0)
	var k := 0
	for sx: Array in [[0.0, STUD_W], [L - STUD_W, L], [d0 - STUD_W * 2.0, d0], [d1, d1 + STUD_W * 2.0],
			[d0 * 0.5 - STUD_W, d0 * 0.5], [(d1 + L) * 0.5, (d1 + L) * 0.5 + STUD_W]]:
		_diag(c, "corner/stud/%d" % k, &"stud", &"framing", sx[0], sx[1], foot, top - PLATE_H, -STUD_D, 0.0)
		k += 1
	_diag(c, "corner/header", &"header", &"framing", d0, d1, head, head + HEADER_H, -STUD_D, 0.0)
	for i in 3:
		var sx := d0 + dw * (i + 1) / 4.0
		_diag(c, "corner/cripple/%d" % i, &"cripple", &"framing", sx - STUD_W * 0.5, sx + STUD_W * 0.5, head + HEADER_H, top - PLATE_H, -STUD_D, 0.0)
	# Boarded outside and in: each side of the doors, and over them.
	var trim := StringName(spec.materials.get("trim_outside", "dark_trim"))
	var n := 0
	for part: Array in [[0.0, d0, foot, top], [d1, L, foot, top], [d0, d1, head, top]]:
		var x := float(part[0])
		while x < float(part[1]) - 0.02:
			var x1 := minf(x + 0.25, float(part[1]))
			_diag(c, "corner/out/b%02d" % n, &"board", &"saloon_red", x, x1 - 0.004, float(part[2]) - 0.25, float(part[3]), 0.0, BOARD_T)
			_diag(c, "corner/in/board/%02d" % n, &"board", &"framing", x, x1 - 0.004, float(part[2]), float(part[3]) - 0.02, -STUD_D - 0.02, -STUD_D)
			x = x1
			n += 1
	# The transom: its bar and its light.
	if tr > 0.0:
		_diag(c, "corner/transom_bar", &"trim", trim, d0, d1, foot + dh, foot + dh + 0.05, -STUD_D, BOARD_T)
		_diag(c, "corner/transom_glass", &"glass", &"glass", d0 + 0.01, d1 - 0.01, foot + dh + 0.05, head - 0.005, -0.055, -0.045)
	# The two leaves, each glazed over a panel, standing open into the room at their jambs.
	var along: Vector3 = c.along
	var inward: Vector3 = -(c.out as Vector3)
	var lw := dw * 0.5 - 0.02
	var lh := dh - 0.02
	var lb := Basis(inward, Vector3.UP, inward.cross(Vector3.UP))
	for side in 2:
		var hinge: Vector3 = (c.origin as Vector3) + along * (d0 + 0.025 if side == 0 else d1 - 0.025) + inward * STUD_D
		var mid := hinge + inward * (lw * 0.5 + 0.02)
		var pre := "corner/leaf%d" % side
		var st := 0.11
		var panel := 0.95
		add_member(pre + "/panel", &"trim", trim, Vector3(lw, panel, 0.045), mid + Vector3.UP * (foot + 0.01 + panel * 0.5), lb)
		for e in 2:
			var off := inward * ((lw - st) * 0.5) * (-1.0 if e == 0 else 1.0)
			add_member("%s/stile%d" % [pre, e], &"trim", trim, Vector3(st, lh - panel - st, 0.045), mid + off + Vector3.UP * (foot + 0.01 + panel + (lh - panel - st) * 0.5), lb)
		add_member(pre + "/rail", &"trim", trim, Vector3(lw, st, 0.045), mid + Vector3.UP * (foot + 0.01 + lh - st * 0.5), lb)
		add_member(pre + "/glass", &"glass", &"glass", Vector3(lw - st * 2.0, lh - panel - st, 0.008), mid + Vector3.UP * (foot + 0.01 + panel + (lh - panel - st) * 0.5), lb)
	band = 1


# --- the stone in the library's stone and lime (#860, #857; StoneFinish) ---------------------------

var stone_material: ShaderMaterial

## Every stone member drawn in the library's stone (spec.materials.stone `want`, once the materials
## judge has passed it at that age; else the game's `stone` as before): one material for the
## building, each piece its own mesh with the arrises that show chamfered, dressed stone (lintels,
## sills, the coping, quoins, steps and flags) flagged for the shader; inside, the plaster or
## whitewash of the region a face looks into (spec.inside_finish.regions).
func _stone_finish() -> void:
	var st: Dictionary = spec.materials.get("stone", {}) if spec.materials.get("stone") is Dictionary else {}
	if st.is_empty():
		return
	var want: Dictionary = st.get("want", {})
	var e := MaterialLibrary.entry(String(want.get("entry", "")))
	var age := String(want.get("age", "few"))
	if e.is_empty() or not ((e.get("approved", []) as Array).has(age) or bool(st.get("trial", false))):
		return
	var ms: Array[StructureMember] = []
	var boxes := []
	for m: StructureMember in get_members():
		if m.wood != &"stone" or m.drawn_node() == null:
			continue
		ms.append(m)
		boxes.append(m.transform * AABB(-m.size * 0.5, m.size))
	if ms.is_empty():
		return
	stone_material = StoneFinish.material(e, float(LIB_AGES.get(age, 0.5)), float(LIB_AGES.get(String(st.get("inside_age", "few")), 0.5)))
	var faces := StoneFinish.exposed(boxes)
	var sid := String(structure_id) + "/"
	var all_dressed := bool(st.get("dressed", false))
	for i in ms.size():
		var m := ms[i]
		var id := String(m.member_id).trim_prefix(sid)
		var dressed := all_dressed or bool(m.get_meta(&"dressed", false)) or id.contains("/lintel") or id.contains("/sill") \
				or id.begins_with("stair/") or id.contains("/flag_")
		var rng := hash(m.member_id)
		var seed := float(rng % 100000) / 100000.0
		var c := (0.012 + 0.008 * seed) if dressed else (0.02 + 0.025 * seed)
		if id.contains("/flag_") or id.contains("/fill_") or id.begins_with("pier/"):
			c = 0.008
		var mi := m.drawn_node()
		mi.mesh = StoneFinish.piece_mesh(m.size, faces[i] if m.transform.basis.is_equal_approx(Basis()) else 0, c, seed, dressed)
		mi.transform = Transform3D()
		mi.material_override = stone_material
	refresh_stone_space()


## The stone's building space (world -> here, the ground, the rooms, the corners, the drips): again
## if the building moves.
func refresh_stone_space() -> void:
	if stone_material == null:
		return
	var gt := global_transform if is_inside_tree() else transform
	var regions: Array = (spec.get("inside_finish", {}) as Dictionary).get("regions", [])
	var plane: Array = (spec.lot.get("ground", {}) as Dictionary).get("plane", [-1000.0, 0.0, 0.0])
	StoneFinish.set_space(stone_material, gt.affine_inverse(), plane, regions, get_meta(&"stone_corners", []), get_meta(&"stone_drips", []))
