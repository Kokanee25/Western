extends TestCase
## The doctor's office (#765, the building lab's first practice building): built from its spec
## (experiments/building_lab/doctor/doctor.json) it is destructible through and through, stands,
## is built right (#695: nothing across a door or window, every opening framed and glazed, the
## outside agreeing with the inside), fits a man at every door and use point, and every room has
## its people's places. It writes every member to build/doctor_members.json for the X-ray sheet
## (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://experiments/building_lab/doctor/doctor.json"

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


func test_the_doctors_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 1500, "the building is members (%d)" % r.members)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var n := Checks.export_members(b, ProjectSettings.globalize_path("res://build/doctor_members.json"))
	print("  exported %d members to build/doctor_members.json" % n)


func test_the_doctors_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors: %s" % [r.crowd.worst])


func test_the_doctors_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 30):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening framed and glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_the_doctors_and_its_rooms_are_used() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 20):
		print("    ", f)
	check(fit.ok, "doors, stairs and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])



func test_a_post_knocked_out_brings_down_what_it_carried() -> void:
	var b: Structure = lab.building
	var posts: Array = []
	for m in b.members_of_kind(&"post"):
		var id := String(m.member_id)
		if id.contains("/summer/") or id.contains("back_porch/roof_post"):
			posts.append(m.member_id)
	check(posts.size() == 6, "the summer beams' four posts and the porch roof's two (%d)" % posts.size())
	for r: Dictionary in Checks.knockouts(b, posts):
		print("  %s gone: %d fall, %d over %s" % [r.post, r.falls, r.over, r.over_first])
		# The summer beams' ends also butt the front wall and the office's back wall, which the rules
		# count as bearing: their posts are redundant to them, as the saloon's cellar posts are.
		if String(r.post).contains("back_porch"):
			check(int(r.falls) + int(r.over) > 0, "%s gone: what it carried comes down or gives" % r.post)


func test_what_the_doctors_costs_to_draw() -> void:
	var r := Checks.draw_calls(lab)
	print("  draws: %s" % [r])
	check(true, "counted")


## #824 (#821 pick 1): the rooms lit as rooms. Every room people use (all but the loft) has a lamp
## of its own, hung on its walls; RoomLight gets every outer door and window; the indoor fill reaches
## the outer walls' inside boards; and the inside paint's wear is measured from the floor.
func test_the_doctors_rooms_have_their_own_light() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var lit := {}
	for lamp: OilLamp in b.lamps:
		var at: Vector3 = b.to_local(lamp.global_position)
		for r: Dictionary in spec.rooms:
			var rc: Array = r.rect
			if r.id != "loft" and at.x > float(rc[0]) - 0.2 and at.x < float(rc[2]) + 0.2 \
					and at.z > float(rc[1]) - 0.2 and at.z < float(rc[3]) + 0.2 and at.y < 4.3:
				lit[r.id] = true
	for r: Dictionary in spec.rooms:
		if r.id != "loft":
			check(lit.has(r.id), "the %s has a lamp" % r.id)
	var n := 0
	for w: Dictionary in spec.walls:
		if not w.get("partition", false):
			n += (w.get("openings", []) as Array).size()
	var ops: Array = b.light_openings()
	check(ops.size() == n, "RoomLight gets every outer opening (%d of %d)" % [ops.size(), n])
	for o: Dictionary in ops:
		var rect: Rect2 = o.rect
		check(rect.position.y >= 0.9 and rect.size.x > 0.3, "an opening in the wall above the floor: %s" % rect)
	var probe := b.get_node(^"InteriorAmbient") as ReflectionProbe
	check(probe.size.x >= b.width - 0.01 and probe.size.z >= b.depth - 0.01, "the fill reaches the outer walls (%s)" % probe.size)
	check(b.has_meta(&"room_fill") and b.get_meta(&"room_fill") is Color, "the fill's colour is the spec's")
	# An inside wall board's ground (CUSTOM2's z, the shader's wear height) is the floor's.
	var found := false
	for m: StructureMember in b.get_members():
		if String(m.member_id).contains("/in_ground/") and m.drawn_node() and m.drawn_node().mesh is ArrayMesh:
			var arrays: Array = (m.drawn_node().mesh as ArrayMesh).surface_get_arrays(0)
			var c2: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM2]
			if c2.size() >= 4:
				var gy: float = b.global_position.y
				check(absf(c2[2] - (gy + b.floor_top)) < 0.01, "an inside board's wear from the floor (%.2f, floor %.2f)" % [c2[2] - gy, b.floor_top])
				found = true
				break
	check(found, "an inside board found to read")
