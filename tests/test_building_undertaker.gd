extends TestCase
## The undertaker's (#1141, #1174: the building lab's fifth building): built from its spec
## (config/buildings/undertaker.json) it is destructible through and through, stands (the loft on two
## summer beams, the floor on girders carried in the cellar by its posts and walls), is built right,
## fits a man at every door and use point, every room has its people's places and a lamp, the cellar
## is rooms of members, and a man walks down the workroom's stair into the cellar, through it and up
## the bulkhead into the yard, and up the side door's ramp. It writes every member to
## build/undertaker_members.json for the X-ray sheet (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://config/buildings/undertaker.json"

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


func test_the_undertakers_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 2000, "the building is members (%d)" % r.members)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var n := Checks.export_members(b, ProjectSettings.globalize_path("res://build/undertaker_members.json"))
	print("  exported %d members to build/undertaker_members.json" % n)


func test_the_undertakers_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors: %s" % [r.crowd.worst])
	# RECIPE (saloon B): the game's own settle on the built building finds nothing to drop.
	var settled: Variant = lab.building.settle()
	check(settled == null or (settled is Array and (settled as Array).is_empty()) or (settled is Dictionary and (settled as Dictionary).is_empty()),
			"the game's settle drops nothing: %s" % [settled])


func test_the_undertakers_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 30):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening framed and glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_the_undertakers_and_its_rooms_are_used() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 20):
		print("    ", f)
	check(fit.ok, "doors, stairs and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])


func test_what_the_undertakers_costs_to_draw() -> void:
	var r := Checks.draw_calls(lab)
	print("  draws: %s" % [r])
	var bodies := 0
	for m: StructureMember in lab.building.get_members():
		bodies += 1
	print("  members (each a body until batched at rest): %d" % bodies)
	check(true, "counted")


## The cellar is rooms of members (#1141): its stone walls and flags, its two plank walls, the ice
## room's thick door, and a lamp each room on its level (#824), as every room upstairs has.
func test_the_cellar_is_rooms_and_every_room_is_lit() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var sid := String(b.structure_id) + "/"
	var counts := {"flag": 0, "cel_cross": 0, "cel_ice": 0, "post": 0}
	var ice_leaf: StructureMember = null
	for m: StructureMember in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		if id.begins_with("cellar/flag/"):
			counts.flag += 1
		elif id.begins_with("cellar/post/"):
			counts.post += 1
		elif id.begins_with("cel_cross/"):
			counts.cel_cross += 1
		elif id.begins_with("cel_ice/"):
			counts.cel_ice += 1
			if m.kind == &"door":
				ice_leaf = m
	print("  cellar: %s" % [counts])
	for k: String in counts:
		check(int(counts[k]) > (2 if k == "post" else 10), "the cellar's %s (%d)" % [k, counts[k]])
	check(ice_leaf != null and ice_leaf.size[ice_leaf.size.min_axis_index()] > 0.08, "the ice room's door is thick")
	var lit := {}
	for lamp: OilLamp in b.lamps:
		var at: Vector3 = b.to_local(lamp.global_position)
		for r: Dictionary in spec.rooms:
			var rc: Array = r.rect
			var lv: Dictionary = spec.levels[r.level]
			var y := float(lv.get("top", lv.get("floor", 0.0)))
			if at.x > float(rc[0]) - 0.2 and at.x < float(rc[2]) + 0.2 and at.z > float(rc[1]) - 0.2 and at.z < float(rc[3]) + 0.2 \
					and at.y > y and at.y < y + 2.4:
				lit[r.id] = true
	for r: Dictionary in spec.rooms:
		if r.id != "loft":
			check(lit.has(r.id), "the %s has a lamp" % r.id)
	var probe := b.get_node(^"InteriorAmbient") as ReflectionProbe
	check(probe.size.x >= b.width - 0.01 and probe.size.z >= b.depth - 0.01, "the fill reaches the outer walls (%s)" % probe.size)


## The bulkhead (Bulkhead, the part): the passage through the foundation under its lintel is open,
## its two doors stand open on the cheeks, its steps run from the yard to the cellar's flags.
func test_the_bulkhead_is_open_and_its_steps_go_down() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var sid := String(b.structure_id) + "/"
	var bk: Dictionary = spec.bulkhead
	check(b.get_member(StringName(sid + "foundation/west_lintel")) != null, "a lintel over the passage")
	var doors := 0
	for m: StructureMember in b.get_members():
		if String(m.member_id).begins_with(sid + "bulkhead/door_"):
			doors += 1
			check(m.global_basis.x.normalized().y > 0.9 or m.global_basis.y.normalized().y < 0.3, "%s stands open" % m.member_id)
	check(doors == 2, "a pair of doors (%d)" % doors)
	# Nothing in the passage: a man's box through the foundation.
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(0.7, 1.85, (float(bk.z[1]) - float(bk.z[0])) - 0.3)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.transform = Transform3D(Basis(), b.to_global(Vector3(0.2, float(spec.levels.cellar.top) + 0.95, (float(bk.z[0]) + float(bk.z[1])) * 0.5)))
	q.collision_mask = Layers.WORLD
	var in_way := []
	for hit in space.intersect_shape(q, 8):
		var m := hit.collider as StructureMember
		if m:
			in_way.append(String(m.member_id).trim_prefix(sid))
	check(in_way.is_empty(), "the passage through the foundation is clear: %s" % [in_way])


## A man walks (Waypoints' own test of a step: no step up he can't take, room for his body) from the
## workroom down the stair into the coffin store, into the embalming room and the ice room, back,
## through the passage and up the bulkhead into the yard, round to the side door's ramp and up it
## into the workroom again (Sean, #1141: the cellar walkable).
func test_a_man_walks_down_into_the_cellar_and_up_the_bulkhead() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var g := float(spec.levels.ground.top)
	var c := float(spec.levels.cellar.top)
	var bk: Dictionary = spec.bulkhead
	var bz := (float(bk.z[0]) + float(bk.z[1])) * 0.5
	var yard := float(bk.grade)
	var ramp_z := float(spec.side_ramp.at)
	# [x, the floor he's on (a guess the foot is found from), z]
	var route: Array = [Vector3(1.5, g, 9.8), Vector3(3.2, g, 9.8), Vector3(6.3, c, 9.8), Vector3(6.6, c, 10.6), Vector3(5.07, c, 10.6),
			Vector3(5.07, c, 11.7), Vector3(4.0, c, 12.45), Vector3(2.6, c, 12.45), Vector3(4.0, c, 12.45), Vector3(5.07, c, 11.7), Vector3(5.07, c, 10.65),
			Vector3(6.9, c, 10.65), Vector3(6.9, c, 8.4), Vector3(1.2, c, 8.4), Vector3(1.2, c, bz), Vector3(0.2, c, bz), Vector3(-0.5, c, bz), Vector3(-float(bk.out) - 0.6, yard, bz),
			Vector3(-float(spec.side_ramp.run) - 1.0, yard + 0.05, ramp_z), Vector3(0.8, g, ramp_z)]
	var names := ["workroom", "the stair's head", "the stair's foot", "coffin store", "the embalming door", "embalming room", "the ice door",
			"ice room", "the ice door", "embalming room", "coffin store", "the store's east end", "past the posts", "the store's west end", "the passage", "the foundation", "the bulkhead's foot", "the yard",
			"the ramp's foot", "workroom"]
	var feet := func(p: Vector3) -> Vector3:
		var at: Vector3 = b.to_global(p)
		var y := Waypoints._foot_height(space, at, at.y + 0.9, at.y - 0.6, [])
		return Vector3(at.x, y, at.z)
	var bad := []
	for i in route.size() - 1:
		var a: Vector3 = route[i]
		var e: Vector3 = route[i + 1]
		var n := maxi(1, ceili(Vector2(a.x, a.z).distance_to(Vector2(e.x, e.z)) / 0.3))
		var prev: Vector3 = feet.call(a)
		for k in range(1, n + 1):
			var here: Vector3 = feet.call(a.lerp(e, float(k) / n))
			if prev.y == -INF or here.y == -INF or not Waypoints._walkable(space, prev, here, []):
				bad.append("%s -> %s at %d/%d (%s to %s)" % [names[i], names[i + 1], k, n, b.to_local(prev).snappedf(0.01), b.to_local(here).snappedf(0.01)])
				break
			prev = here
	var down: Vector3 = b.to_local(feet.call(route[3]))
	check(absf(down.y - c) < 0.05, "down in the cellar on its flags (%.2f)" % down.y)
	check(bad.is_empty(), "walked every stretch: %s" % [bad])


## The yard (#1171): the hearse shed stands at its back with its stall, its doors open; the wagon
## gate in the front fence; the side fence on the rising ground.
func test_the_yard_has_its_hearse_shed_and_gate() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var shed := 0
	var stall := 0
	for m: StructureMember in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		if id.begins_with("hearse_shed/"):
			shed += 1
			if id.contains("stall"):
				stall += 1
	check(shed > 80, "the hearse shed is members (%d)" % shed)
	check(stall >= 4, "its stall (%d)" % stall)
	check(b.get_member(StringName(sid + "fence/gate_0")) != null, "the wagon gate")
