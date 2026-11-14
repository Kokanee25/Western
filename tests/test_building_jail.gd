extends TestCase
## The sheriff's office and jail (#780, the building lab's second practice building, the first in
## stone): built from its spec (experiments/building_lab/jail/jail.json) it is destructible through
## and through, stands, is built right (#695: nothing across a door or window, every opening in its
## stone walls under a lintel and every window on a sill, glazed but the slits), fits a man at every
## door and use point, every room has its people's places, and the jailbreak's wall breached at its
## foot brings down only what was over the hole. It writes every member to build/jail_members.json
## for the X-ray sheet (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://experiments/building_lab/jail/jail.json"

var lab: Node3D


func before_each() -> void:
	Lab.spec_path = SPEC
	lab = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	await physics_frames(3)


func after_each() -> void:
	lab.queue_free()
	await physics_frames(2)


func test_the_jail_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 1500, "the building is members (%d)" % r.members)
	var stone := 0
	for m in b.get_members():
		if m.wood == &"stone":
			stone += 1
	print("  %d of them stone" % stone)
	check(stone > 800, "its walls are stone pieces (%d)" % stone)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var n := Checks.export_members(b, ProjectSettings.globalize_path("res://build/jail_members.json"))
	print("  exported %d members to build/jail_members.json" % n)


func test_the_jail_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors and roof: %s" % [r.crowd.worst])


func test_the_jail_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 30):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening under its lintel, windows glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_the_jail_and_its_rooms_are_used() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 20):
		print("    ", f)
	check(fit.ok, "doors and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])


## The jailbreak by the rules (the masonry lab's step 8 does it with its stones and physics): the
## cell wing's end wall blown through at its foot, a hole 1.5 m wide and 1.8 m high round the slit's
## line. What loses its load path is over the hole; the cages, the wing's roof and the office stand.
func test_the_jailbreak_wall_breached_at_its_foot() -> void:
	var b: Structure = lab.building
	var sid := String(b.structure_id) + "/"
	var ids: Array = []
	var mid := (6.09 + 10.97) * 0.5
	for m in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		if not id.begins_with("ell_south/"):
			continue
		var p := m.transform.origin
		if absf(p.x - mid) < 0.75 + m.size.x * 0.5 - 0.05 and p.y > -0.2 and p.y < 1.8:
			ids.append(m.member_id)
	print("  %d pieces blown out" % ids.size())
	check(ids.size() >= 2, "a hole's worth of pieces (%d)" % ids.size())
	var gone := {}
	for id in ids:
		gone[id] = true
	var falling := b.members_without_load_path(gone)
	var far := []
	for fid: StringName in falling:
		var mm := b.get_member(fid)
		var p := mm.transform.origin
		if absf(p.x - mid) > 2.0 or p.z < 21.5:
			far.append(String(mm.member_id).trim_prefix(sid))
	print("  %d lose their load path; away from the hole: %s" % [falling.size(), far.slice(0, 8)])
	check(far.is_empty(), "only what was over the hole falls (%d away from it)" % far.size())


func test_what_the_jail_costs_to_draw() -> void:
	var r := Checks.draw_calls(lab)
	print("  draws: %s" % [r])
	check(true, "counted")


## #811 (the doctor's rules, #824-#826, #829): every room people use has a lamp of its own on its
## stone (the cages lit by the corridor's lantern through their straps, the roof by none); RoomLight
## gets every outer door and window and the spec's daylight; each barred window is a sash inside its
## bars, lined through the stone; the office's floor is the library's worn fir, never a wall's or the
## trim's entry, and the sashes, casings and skirting take the trim's finish.
func test_the_jails_rooms_are_lit_and_finished() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var lit := {}
	for lamp: OilLamp in b.lamps:
		var at: Vector3 = b.to_local(lamp.global_position)
		for r: Dictionary in spec.rooms:
			var rc: Array = r.rect
			if at.x > float(rc[0]) - 0.2 and at.x < float(rc[2]) + 0.2 and at.z > float(rc[1]) - 0.2 \
					and at.z < float(rc[3]) + 0.2 and at.y < 4.0:
				lit[r.id] = true
	for r: Dictionary in spec.rooms:
		if r.id != "roof" and not String(r.id).begins_with("cell_"):
			check(lit.has(r.id), "the %s has a lamp" % r.id)
	var n := 0
	for w: Dictionary in spec.walls:
		if not w.get("partition", false):
			n += (w.get("openings", []) as Array).size()
	var ops: Array = b.light_openings()
	check(ops.size() == n, "RoomLight gets every outer opening (%d of %d)" % [ops.size(), n])
	var probe := b.get_node(^"InteriorAmbient") as ReflectionProbe
	check(probe.has_meta(&"day_ambient") and float(probe.get_meta(&"day_ambient")) < 0.2, "a low fill by day: the windows light the rooms")
	check(b.has_meta(&"room_window_gain"), "the windows' daylight is the spec's")
	# The sashes inside the bars, the linings through the stone.
	for m: StructureMember in b.get_members():
		var id := String(m.member_id)
		if id.contains("/window_") and id.contains("/lining_jamb0"):
			var w: Dictionary = b.walls[id.trim_prefix(String(b.structure_id) + "/").get_slice("/", 0)].dict
			var d := ((m.transform.origin - (w.origin as Vector3)).dot(w.out as Vector3))
			check(d < -0.2 and m.size[m.size.min_axis_index()] < 0.05, "a lining through the stone: %s at d %.2f" % [id, d])
	var floors := {}
	for m: StructureMember in b.get_members():
		var id := String(m.member_id)
		var fn: String = b._finish_of(m)
		if id.contains("floor/ground") and id.contains("/board"):
			floors[fn] = true
		if id.contains("/window_") and m.kind != &"glass" or id.contains("/skirt") or id.contains("/casing"):
			check(fn == "trim", "%s in the trim's finish (%s)" % [id, fn])
	check(floors.keys() == ["floor"], "the floor's boards all the floor's finish (%s)" % [floors.keys()])
	check(String(b.finish("floor").entry) == "floor_fir_worn", "the floor the library's worn fir (%s)" % b.finish("floor"))
	check(b.finish("floor").entry != b.finish("inside").entry and b.finish("floor").entry != b.finish("trim").entry, "the floor never a wall's or the trim's wood")


## #860 and #857: the stone's drawing data (StoneFinish: quoins at the footprint's convex corners, the
## drips within the shader's 48), the parapet stepped over the door with piers at the corners (2a), the
## cell wing's parapet about a metre under the office's, the yard wall 7 ft (3b); once the materials
## judge has passed the library's rubble, every stone piece drawn in it, one material for the building.
func test_the_jails_stone_and_parapet() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var corners: Array = b.get_meta(&"stone_corners", [])
	var drips: Array = b.get_meta(&"stone_drips", [])
	print("  corners %s; %d drips" % [corners, drips.size()])
	for c: Vector2 in [Vector2(0, 0), Vector2(6.09, 23.16), Vector2(10.97, 23.16), Vector2(30.8, 0), Vector2(30.8, 38.1), Vector2(0, 38.1)]:
		check(corners.any(func(q: Vector2) -> bool: return q.distance_to(c) < 0.01), "a quoin corner at %s" % c)
	check(corners.size() == 6, "only the convex corners (%d)" % corners.size())
	check(drips.size() <= 96 and drips.size() > 10, "the drips fit the shader (%d)" % drips.size())
	var tops := {}
	for m: StructureMember in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		var w := id.get_slice("/", 0)
		var t: float = m.transform.origin.y + m.size.y * 0.5
		tops[w] = maxf(float(tops.get(w, -INF)), t)
	check(absf(float(tops.front) - 5.75) < 0.02, "the front parapet steps up over the door (%.2f)" % tops.front)
	check(float(tops.ell_south) < float(tops.west) - 0.9, "the cell wing's parapet a metre under the office's (%.2f, %.2f)" % [tops.ell_south, tops.west])
	var yard_top := -INF
	var yard_foot := INF
	for m: StructureMember in b.get_members():
		if String(m.member_id).trim_prefix(sid).begins_with("yard_lane/") and m.wood == &"stone":
			yard_top = maxf(yard_top, m.transform.origin.y + m.size.y * 0.5)
	var pl: Array = lab.spec.lot.ground.plane
	var g := float(pl[0]) + float(pl[1]) * 15.0 + float(pl[2]) * 38.1
	check(yard_top - g < 2.3 and yard_top - g > 2.0, "the yard wall 7 ft over the lane (%.2f)" % (yard_top - g))
	if b.stone_material != null:
		var n := 0
		for m: StructureMember in b.get_members():
			if m.wood == &"stone":
				check(m.drawn_node().material_override == b.stone_material, "%s in the library's stone" % m.member_id)
				n += 1
				if n > 40:
					break
