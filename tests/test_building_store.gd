extends TestCase
## The general store (#858, the building lab's third building): built from its spec
## (config/buildings/store.json) it is destructible through and through, stands (the upper floor on two
## beam lines over a cellar), is built right (nothing across a door or window, every opening framed and
## glazed), fits a man at every door and use point, every room has its people's places and a lamp
## (the cellar's lantern waits on the bulkhead, #695), and its walls and windows are as judged (#826).
## It writes every member to build/store_members.json for the X-ray sheet (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://config/buildings/store.json"

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


func test_the_store_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 3000, "the building is members (%d)" % r.members)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var n := Checks.export_members(b, ProjectSettings.globalize_path("res://build/store_members.json"))
	print("  exported %d members to build/store_members.json" % n)


func test_the_store_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors: %s" % [r.crowd.worst])


func test_the_store_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 30):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening framed and glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_the_store_and_its_rooms_are_used() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 20):
		print("    ", f)
	check(fit.ok, "doors, stairs and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])


func test_what_the_store_costs_to_draw() -> void:
	var r := Checks.draw_calls(lab)
	print("  draws: %s" % [r])
	check(true, "counted")

func test_a_post_knocked_out_brings_down_what_it_carried() -> void:
	var b: Structure = lab.building
	var posts: Array = []
	for m in b.members_of_kind(&"post"):
		if String(m.member_id).begins_with("%s/post/" % b.structure_id):
			posts.append(m.member_id)
	var free: Array = lab.spec.posts.free
	check(posts.size() == free.size(), "the beams' free posts (%d of %d)" % [posts.size(), free.size()])
	var gone := 0
	for r: Dictionary in Checks.knockouts(b, posts):
		print("  %s gone: %d fall, %d over %s" % [r.post, r.falls, r.over, r.over_first])
		gone += 1 if int(r.falls) + int(r.over) > 0 else 0
	check(gone == posts.size(), "each post knocked out: what it carried gives (%d of %d posts)" % [gone, posts.size()])


## #824: every room people use but the cellar (its lantern waits on #695) has a lamp of its own on its
## level; RoomLight gets every outer door and window; the indoor fill reaches the outer walls.
func test_the_stores_rooms_have_their_own_light() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var upper_y: float = float(spec.levels.upper.top) - 0.5
	var lit := {}
	for lamp: OilLamp in b.lamps:
		var at: Vector3 = b.to_local(lamp.global_position)
		for r: Dictionary in spec.rooms:
			var rc: Array = r.rect
			var upper: bool = r.level == "upper"
			if at.x > float(rc[0]) - 0.2 and at.x < float(rc[2]) + 0.2 \
					and at.z > float(rc[1]) - 0.2 and at.z < float(rc[3]) + 0.2 \
					and (at.y > upper_y) == upper and at.y > float(spec.levels.cellar.floor) + 0.5 \
					and (r.level != "cellar"):
				lit[r.id] = true
	for r: Dictionary in spec.rooms:
		if r.id != "cellar":
			check(lit.has(r.id), "the %s has a lamp" % r.id)
	var n := 0
	for w: Dictionary in spec.walls:
		if not w.get("partition", false):
			n += (w.get("openings", []) as Array).size()
	var ops: Array = b.light_openings()
	check(ops.size() == n, "RoomLight gets every outer opening (%d of %d)" % [ops.size(), n])
	for o: Dictionary in ops:
		var rect: Rect2 = o.rect
		check(rect.size.x > 0.3, "an opening of a size: %s" % rect)
	var probe := b.get_node(^"InteriorAmbient") as ReflectionProbe
	check(probe.size.x >= b.width - 0.01 and probe.size.z >= b.depth - 0.01, "the fill reaches the outer walls (%s)" % probe.size)
	check(b.has_meta(&"room_fill") and b.get_meta(&"room_fill") is Color, "the fill's colour is the spec's")


## #826: inside boards at the width their paint was judged at, a skirting on every boarded ground
## wall, casings in the trim's finish, a pane a light, each pane its own glass that breaks alone.
func test_the_stores_walls_and_windows_are_as_judged() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var judged := float(MaterialLibrary.entry("painted_pale_tg").board_w)
	var drawn := 0
	var off := 0
	var members := 0
	for m: StructureMember in b.get_members():
		var id := String(m.member_id)
		if not (id.contains("/in_ground/board/") or id.contains("/m/board/") or id.contains("/p/board/")):
			continue
		members += 1
		var mi: MeshInstance3D = m.drawn_node()
		if mi == null or not (mi.mesh as Mesh).has_meta(&"strip_widths"):
			continue
		var ws: Array = mi.mesh.get_meta(&"strip_widths")
		for i in ws.size():
			drawn += 1
			# (the last board of a member may be ripped to what's left at a wall's end)
			if i < ws.size() - 1 and absf(float(ws[i]) - judged) > judged * 0.2:
				off += 1
	print("  inside boards: %d members drawn as %d boards, %d off the judged %.2f m" % [members, drawn, off, judged])
	check(members > 100 and drawn >= members * 2, "the inside boards drawn as narrow boards (%d members, %d boards)" % [members, drawn])
	check(off == 0, "every board drawn within a fifth of its paint's judged width (%d off)" % off)
	var skirts := 0
	var casings := 0
	var trim_casings := 0
	for m: StructureMember in b.get_members():
		var id := String(m.member_id)
		if id.contains("/skirt"):
			skirts += 1
			check(b._finish_of(m) == "trim", "a skirting in the trim's finish: %s" % id)
		if id.contains("/casing"):
			casings += 1
			trim_casings += 1 if b._finish_of(m) == "trim" else 0
	print("  %d skirting pieces, %d casing pieces" % [skirts, casings])
	check(skirts > 20, "skirting along the boarded walls (%d)" % skirts)
	check(casings > 0 and trim_casings == casings, "the casings in the trim's finish (%d of %d)" % [trim_casings, casings])
	# Every boarded ground-floor wall face has a skirting.
	for w: Dictionary in spec.walls:
		for fin: Dictionary in w.get("inside", []):
			if fin.finish != "boards" or fin.get("level", w.get("level", "ground")) != "ground":
				continue
			var pre: String = "%s/%s/" % [b.structure_id, w.id]
			var found := false
			for m: StructureMember in b.get_members():
				if String(m.member_id).begins_with(pre) and String(m.member_id).contains("/skirt"):
					found = true
					break
			check(found, "%s has a skirting" % w.id)
	# The windows: a pane a light (built_right counts them per opening), each its own glass.
	var lights := 0
	for w: Dictionary in spec.walls:
		for o: Dictionary in w.get("openings", []):
			lights += int(o.get("lights", 0))
	var panes: Array[StructureMember] = []
	for m: StructureMember in b.get_members():
		if m.kind == &"glass" and String(m.member_id).contains("/window_"):
			panes.append(m)
	check(panes.size() == lights, "a pane for each light (%d of %d)" % [panes.size(), lights])
	check(panes.size() > 0 and panes[0].collision_layer & Layers.WORLD != 0, "a pane is in the world (Sight holds it as glass)")
	# One pane of the front's first window broken: the other three stand, and so does its sash.
	var pre := "%s/front/window_" % b.structure_id
	var west: Array[StructureMember] = []
	for p in panes:
		if String(p.member_id).begins_with(pre) and p.position.x > 2.9 and p.position.x < 4.9 and p.position.y < 4.0:
			west.append(p)
	check(west.size() == 4, "the front's first window has four panes (%d)" % west.size())
	if west.size() == 4:
		b.break_member(west[0])
		await physics_frames(20)
		check(west[0].broken, "the pane shot is broken")
		for p in west.slice(1):
			check(not p.broken, "the next pane stands: %s" % p.member_id)
		for m: StructureMember in b.get_members():
			if String(m.member_id).begins_with(pre) and m.kind == &"trim" and m.position.x > 2.9 and m.position.x < 4.9 and m.position.y < 4.0:
				check(not m.broken, "its sash stands: %s" % m.member_id)
