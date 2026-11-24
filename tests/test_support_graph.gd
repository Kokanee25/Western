extends TestCase
## The support graph (#1239): Structure.infer_from_geometry (a sweep over the boxes, native or in
## script) must give exactly the graph the old ways did, in the same order: every member's
## supported_by, dependents, touching, support_points, support_boxes, grounded and stack_key. The old
## ways are kept here as the reference: every pair (Structure's, for kit props, the cemetery, ...) and
## the 2 m grid (SpecBuilding's). Built: the saloon, the hotel (config/buildings/hotel.json, not on
## its lot), the undertaker (rafters), two kit props and the cemetery.

const SpecBuilding := preload("res://src/structures/spec_building.gd")
const HOTEL := "res://config/buildings/hotel.json"
const UNDERTAKER := "res://config/buildings/undertaker.json"
const CELL := 2.0

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	Structure.native_pairs = ClassDB.class_exists(&"BoxPairs")
	world.queue_free()
	await physics_frames(2)


func test_the_saloon_graph_is_unchanged() -> void:
	var b := SpecBuilding.new()
	world.add_child(b)
	_same(b, true)


func test_the_hotel_graph_is_unchanged() -> void:
	var b := SpecBuilding.new()
	b.spec_path = HOTEL
	b.structure_id = &"hotel_spec"
	world.add_child(b)
	_same(b, true)


## A common-rafter roof: its tilted members touch only what their oriented boxes meet.
func test_the_undertaker_graph_is_unchanged() -> void:
	var b := SpecBuilding.new()
	b.spec_path = UNDERTAKER
	b.structure_id = &"undertaker_spec"
	world.add_child(b)
	check(b._tilted_test, "the undertaker's roof is rafters (the oriented-box test is on)")
	_same(b, true)


func test_kit_props_graphs_are_unchanged() -> void:
	for id: StringName in [&"bar", &"back_bar"]:
		var p := PropKit.spawn(id)
		world.add_child(p)
		_same(p, false)


func test_the_cemetery_graph_is_unchanged() -> void:
	var yard := Cemetery.new()
	world.add_child(yard)
	_same(yard, false)


func test_near_lists_native_and_script_agree() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1239
	var boxes: Array[AABB] = []
	for i in 400:
		var at := Vector3(rng.randf_range(0, 10), rng.randf_range(0, 4), rng.randf_range(0, 10))
		boxes.append(AABB(at, Vector3(rng.randf_range(0.02, 3), rng.randf_range(0.02, 1), rng.randf_range(0.02, 0.5))))
	Structure.native_pairs = false
	var script := Structure.near_lists(boxes, Structure.CONTACT_EPSILON)
	# Every pair the exact test keeps is listed, and the lists are ascending.
	var missed := 0
	for i in boxes.size():
		var grown := boxes[i].grow(Structure.CONTACT_EPSILON)
		for j in boxes.size():
			if j != i and grown.intersects(boxes[j]) and not script[i].has(j):
				missed += 1
		var sorted := script[i].duplicate()
		sorted.sort()
		check(sorted == script[i] and not script[i].has(i), "box %d's list is ascending, without itself" % i)
	check_eq(missed, 0, "the sweep misses no touching pair")
	if ClassDB.class_exists(&"BoxPairs"):
		Structure.native_pairs = true
		check(Structure.near_lists(boxes, Structure.CONTACT_EPSILON) == script, "the native sweep gives the same lists")


## The graph `s` has now, by the new way (native, then script), against the old way's.
func _same(s: Structure, grid: bool) -> void:
	var n := s.get_members().size()
	check(n > 0, "%s has members" % s.name)
	var t0 := Time.get_ticks_usec()
	if grid:
		_old_grid(s)
	else:
		_old_all_pairs(s)
	var t1 := Time.get_ticks_usec()
	var want := _snapshot(s)
	var ways := {}
	for native: bool in [true, false]:
		if native and not ClassDB.class_exists(&"BoxPairs"):
			continue
		Structure.native_pairs = native
		_wipe(s)
		var u0 := Time.get_ticks_usec()
		s.infer_from_geometry()
		ways["native" if native else "script"] = (Time.get_ticks_usec() - u0) / 1000.0
		var got := _snapshot(s)
		var first := -1
		for i in mini(got.size(), want.size()):
			if got[i] != want[i]:
				first = i
				break
		check(first < 0 and got.size() == want.size(), "%s (%d members, %s sweep): the same graph%s" % [
				s.name, n, "native" if native else "script",
				"" if first < 0 else ", first differs at %d:\n  got  %s\n  want %s" % [first, got[first], want[first]]])
	# And `_link`, one pair at a time (what a cut member's pieces are relinked by), keeps the rules.
	_wipe(s)
	if grid:
		_old_grid(s, true)
	else:
		_old_all_pairs(s, true)
	check(_snapshot(s) == want, "%s: Structure._link, pair by pair, gives the same graph" % s.name)
	print("  %s: %d members; old %.0f ms, new %s" % [s.name, n, (t1 - t0) / 1000.0, ways])


## Nothing left from the last way, so the next must make it all.
static func _wipe(s: Structure) -> void:
	for m: StructureMember in s.get_members():
		m.supported_by.clear()
		m.dependents.clear()
		m.touching.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.grounded = not m.grounded
		m.stack_key = -1.0


static func _snapshot(s: Structure) -> PackedStringArray:
	var out := PackedStringArray()
	for m: StructureMember in s.get_members():
		out.append(var_to_str([m.member_id, m.supported_by, m.dependents, m.touching,
				m.support_points.keys(), m.support_points.values(), m.support_boxes.keys(),
				m.support_boxes.values(), m.grounded, m.stack_key]))
	return out


# --- the old ways (main before #1239), the reference ----------------------------------------------

## Structure.infer_supports: every member against every other.
static func _old_all_pairs(s: Structure, new_link := false) -> void:
	var order := s.get_members()
	var boxes := {}
	for m in order:
		boxes[m] = m.structure_aabb()
		m.dependents.clear()
	for m in order:
		m.supported_by.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
		var box: AABB = boxes[m]
		s._place_in_stack(m, box)
		for other in order:
			if other != m:
				if new_link:
					s._link(m, box, other, boxes[other])
				else:
					_old_link(s, m, box, other, boxes[other])


## SpecBuilding.infer_supports: the pairs that share a 2 m cell, in build order.
static func _old_grid(s: Structure, new_link := false) -> void:
	var order := s.get_members()
	var boxes := {}
	var grid := {}
	for i in order.size():
		var m := order[i]
		var b := m.structure_aabb()
		boxes[m] = b
		m.dependents.clear()
		for c in _cells(b.grow(Structure.CONTACT_EPSILON)):
			if not grid.has(c):
				grid[c] = []
			(grid[c] as Array).append(i)
	for i in order.size():
		var m := order[i]
		m.supported_by.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
		var box: AABB = boxes[m]
		s._place_in_stack(m, box)
		var seen := {}
		for c in _cells(box.grow(Structure.CONTACT_EPSILON)):
			for j: int in grid.get(c, []):
				seen[j] = true
		var near: Array = seen.keys()
		near.sort()
		for j: int in near:
			if j != i:
				if new_link:
					s._link(m, box, order[j], boxes[order[j]])
				else:
					_old_spec_link(s, m, box, order[j], boxes[order[j]])


## Structure._link: `m` notes the touch, and rests on `other` if that's a lower tier, or the same
## tier stacked underneath it.
static func _old_link(s: Structure, m: StructureMember, box: AABB, other: StructureMember, other_box: AABB) -> void:
	var grown := box.grow(Structure.CONTACT_EPSILON)
	if not grown.intersects(other_box):
		return
	m.touching.append(other.member_id)
	var tier := StructureMember.tier_of(m.kind)
	var other_tier := StructureMember.tier_of(other.kind)
	var beneath := other_tier == tier and other_box.end.y <= box.position.y + Structure.CONTACT_EPSILON \
			and other_box.position.y < box.position.y - Structure.CONTACT_EPSILON
	if other_tier < tier or beneath:
		_old_rest(m, other, grown, other_box)


## SpecBuilding._link: its bands, the same kind beneath, rafters by their oriented boxes.
static func _old_spec_link(s: Structure, m: StructureMember, box: AABB, other: StructureMember, other_box: AABB) -> void:
	var grown := box.grow(Structure.CONTACT_EPSILON)
	if not grown.intersects(other_box):
		return
	if s._tilted_test and (Structure._tilted(m) or Structure._tilted(other)) and not _old_boxes_meet(m, other):
		return
	m.touching.append(other.member_id)
	var tier: int = s._tier(m)
	var other_tier: int = s._tier(other)
	var same := other.kind == m.kind or (m.kind == &"glass" and other.kind == &"trim")
	var beneath := other_tier == tier and same and other_box.end.y <= box.position.y + Structure.CONTACT_EPSILON \
			and other_box.position.y < box.position.y - Structure.CONTACT_EPSILON
	if other_tier < tier or beneath:
		_old_rest(m, other, grown, other_box)


## SpecBuilding._boxes_meet: the separating axes of both boxes' faces.
static func _old_boxes_meet(a: StructureMember, b: StructureMember) -> bool:
	var ta := a.transform
	var tb := b.transform
	var ha := a.size * 0.5 + Vector3.ONE * Structure.CONTACT_EPSILON
	var hb := b.size * 0.5
	var d := tb.origin - ta.origin
	for pair in [[ta.basis, ha, tb.basis, hb], [tb.basis, hb + Vector3.ONE * Structure.CONTACT_EPSILON, ta.basis, a.size * 0.5]]:
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


static func _old_rest(m: StructureMember, other: StructureMember, grown: AABB, other_box: AABB) -> void:
	m.supported_by.append(other.member_id)
	other.dependents.append(m.member_id)
	var contact := grown.intersection(other_box)
	m.support_points[other.member_id] = contact.get_center()
	m.support_boxes[other.member_id] = contact


static func _cells(b: AABB) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var lo := Vector3i((b.position / CELL).floor())
	var hi := Vector3i((b.end / CELL).floor())
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				out.append(Vector3i(x, y, z))
	return out
