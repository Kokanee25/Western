extends TestCase
## Saloon B, the corner saloon (#848 step 1: the spec and the frame): built from its spec
## (experiments/building_lab/saloon_b/saloon_b.json) it is destructible through and through, stands,
## is built right, fits a man at every door, stair and use point, and every room has its people's
## places and its own lamp. It writes every member to build/saloon_b_members.json for the X-ray
## sheet (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://experiments/building_lab/saloon_b/saloon_b.json"

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


func test_saloon_b_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 4000, "the building is members (%d)" % r.members)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var n := Checks.export_members(b, ProjectSettings.globalize_path("res://build/saloon_b_members.json"))
	print("  exported %d members to build/saloon_b_members.json" % n)
	print("  draws: %s" % [Checks.draw_calls(lab)])


func test_saloon_b_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors: %s" % [r.crowd.worst])


func test_saloon_b_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 40):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening framed and glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_saloon_b_and_its_rooms_are_used() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 40):
		print("    ", f)
	check(fit.ok, "doors, stairs and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])


## Payday Night (#809; Sean's answer 2 on #772): the girder the Baron's men saw. Sound, it carries
## the dance floor under a dancing crowd (70 lb/ft2, Hatfield) and nothing gives. Cut through
## (`sabotage`, SpecBuilding.saw_girder), its halves tip off their posts and the floor it carried
## comes down over the bar through the load paths: its 16 joists (hinged on the yard wall's ribbon
## and the west girder) and the boards on them, and nothing but that panel and what stood on it,
## and the few members its timbers hit where they land (watched, not listed: where they land is
## chaotic, #886).
func test_the_sawn_girder_drops_the_dance_floor_over_the_bar() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	for m: StructureMember in b.get_members():
		if m.kind == &"floor_board" and String(m.member_id).contains("/floor/dance/"):
			m.extra_load += 3352.0 * m.size.x * m.size.z
	b.invalidate_analysis()
	var gave: Array = b.settle()
	check(gave.is_empty(), "uncut, the floor carries a dancing crowd (%d gave: %s)" % [gave.size(), gave.slice(0, 4)])
	var girder: StructureMember = b.get_member(StringName(sid + String(lab.spec.sabotage.girder)))
	var gz0 := girder.position.z - girder.size.z * 0.5
	var gz1 := girder.position.z + girder.size.z * 0.5
	var bars := 0
	for f: Dictionary in lab.spec.fixtures:
		if f.kit == "bar":
			var z0 := float(f.at[1]) - 1.5
			var z1 := float(f.at[1]) + float(f.repeat.step[1]) * (int(f.repeat.count) - 1) + 1.5
			check(float(f.at[0]) < girder.position.x and z0 < gz0 and z1 > gz1, "the bar runs under the girder's panel (z %.1f-%.1f, the panel %.1f-%.1f)" % [z0, z1, gz0, gz1])
			bars += 1
	check(bars == 1, "there is a bar")
	# What the falling pieces land on (#886): where each timber lands is chaotic (a different
	# member clipped each run, by whatever the suite did before), so a member they hit may break
	# (Structure._on_rubble_hit), and what it brings down with it; nothing else may. Every piece is
	# watched from the moment it enters the tree, as the building's own hit handler is.
	var hit := {}
	var watch := func(n: Node) -> void:
		if n is RigidBody3D and n.is_in_group(&"rubble"):
			(n as RigidBody3D).body_entered.connect(func(o: Node) -> void:
				if o is StructureMember:
					hit[String((o as StructureMember).member_id).trim_prefix(sid)] = true)
	get_tree().node_added.connect(watch)
	var halves: Array = b.saw_girder()
	check(halves.size() == 2, "the saw leaves two halves on their posts (%d)" % halves.size())
	for k in 24:
		b.settle()
		await physics_frames(15)
	get_tree().node_added.disconnect(watch)
	var joists := 0
	var boards := 0
	var outside := []
	for m: StructureMember in b.get_members():
		if not m.broken:
			continue
		var id := String(m.member_id).trim_prefix(sid)
		if id.begins_with("floor/dance/joist/"):
			# One of the panel's, or one off it that must be explained as the rest are (below).
			if m.position.z > gz0 - 0.3 and m.position.z < gz1 + 0.3:
				joists += 1
			else:
				outside.append(id)
		elif id.begins_with("floor/dance/board/"):
			boards += 1
		# What may go with it: the girder, the gallery's rail that stood on those boards, and the
		# bar room's floor boards the timbers land on.
		elif not (id.begins_with("beam/east/2") or id.begins_with("gallery/") or id.begins_with("floor/ground/board/")):
			outside.append(id)
	# Outside the panel, a member may go only if a falling piece hit it, or it was nailed to one
	# that did and went (what that one carried), and so on out from what was hit: never what only
	# touched the panel (that would be the load paths failing, the fault this test is for).
	var landed := {}
	for id: String in outside:
		if hit.has(id):
			landed[id] = true
	var grew := true
	while grew:
		grew = false
		for id: String in outside:
			if landed.has(id):
				continue
			for t: StringName in (b.get_member(StringName(sid + id)) as StructureMember).touching:
				if landed.has(String(t).trim_prefix(sid)):
					landed[id] = true
					grew = true
					break
	var unexplained := outside.filter(func(id: String) -> bool: return not landed.has(id))
	print("  cut: %d joists, %d boards down; outside the panel: %s (%d hit by what fell, %d members hit in all)" % [joists, boards, outside.slice(0, 6), landed.size(), hit.size()])
	check(joists >= 14 and joists <= 24, "the panel's joists come down, both bays (%d)" % joists)
	check(boards >= 40, "and the boards on them, under the crowd (%d)" % boards)
	check(unexplained.is_empty(), "nothing else gives but what the falling floor hit: %s" % [unexplained.slice(0, 8)])
	check(landed.size() <= 12, "and the falling floor breaks only a few members where it lands (%d: %s)" % [landed.size(), landed.keys().slice(0, 8)])
	for id: String in ["beam/east/1", "beam/east/3", "beam/west/2", "truss/3/tie"]:
		check(not (b.get_member(StringName(sid + id)) as StructureMember).broken, "%s stands" % id)
	# For real: the pieces fall (none left hanging where they were), and over the bar.
	await physics_frames(360)
	var fell := 0
	var over_bar := 0
	var n := 0
	for rb: RigidBody3D in get_tree().get_nodes_in_group(&"rubble"):
		var ids: Array = rb.get_meta(&"members", [])
		if ids.is_empty() or not String(ids[0]).begins_with(sid + "floor/dance/joist/") and not String(ids[0]).begins_with(sid + "beam/east/2"):
			continue
		n += 1
		var p: Vector3 = b.to_local(rb.global_position)
		if p.y < float(b._lv.upper) - 1.0:
			fell += 1
			if p.x < girder.position.x + 0.5:
				over_bar += 1
	print("  %d pieces of the girder and its joists; %d fell a metre or more, %d of them on the bar's side" % [n, fell, over_bar])
	check(fell >= n * 0.6, "the girder's halves and its joists fall (%d of %d)" % [fell, n])
	check(over_bar >= 6, "and come down on the bar's side of the room (%d)" % over_bar)


## The open well (Sean's answer 1): a 36 in rail round it. A man leaning on it is held; a man
## thrown into it breaks the span he hits and goes over, 13 ft down to the bar room: a fall from
## height (#759).
func test_the_wells_rail_holds_a_leaning_man_and_breaks_to_a_thrown_one() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var upper := float(b._lv.upper)
	check(absf(upper - float(b._lv.ground) - 3.96) < 0.02, "13 ft from the gallery to the bar room's floor")
	var rails: Array[StructureMember] = []
	for m: StructureMember in b.get_members():
		if String(m.member_id).begins_with(sid + "gallery/rail/1/rail/"):
			rails.append(m)
	check(rails.size() >= 2, "the gallery's rail is in spans (%d)" % rails.size())
	check(absf(rails[0].position.y - upper - 0.915) < 0.06, "its top 36 in over the floor (%.2f)" % (rails[0].position.y - upper))
	# Leaning: a man walking into it at a stroll.
	var man := HumanBody.new()
	lab.add_child(man)
	man.global_transform = Transform3D(Basis(), b.to_global(Vector3(15.75, upper, 7.5)))
	await physics_frames(2)
	man.go_limp()
	for rb: Variant in man.parts.values():
		(rb as RigidBody3D).linear_velocity = Vector3(-0.8, 0, 0)
	await physics_frames(40)
	var broke := rails.filter(func(m: StructureMember) -> bool: return m.broken).size()
	check(broke == 0, "a man leaning on it is held (%d spans broke)" % broke)
	check((man.parts[&"chest"] as RigidBody3D).global_position.y > b.to_global(Vector3(0, upper - 0.3, 0)).y, "he's still on the gallery")
	man.queue_free()
	await physics_frames(2)
	# Thrown.
	var thrown := HumanBody.new()
	lab.add_child(thrown)
	thrown.global_transform = Transform3D(Basis(), b.to_global(Vector3(15.95, upper, 10.3)))
	await physics_frames(2)
	thrown.go_limp()
	for rb: Variant in thrown.parts.values():
		(rb as RigidBody3D).linear_velocity = Vector3(-5.5, 0.3, 0)
	await physics_frames(150)
	broke = rails.filter(func(m: StructureMember) -> bool: return m.broken).size()
	var chest := b.to_local((thrown.parts[&"chest"] as RigidBody3D).global_position) as Vector3
	print("  thrown: %d spans broke; he lies at %s; fall %s" % [broke, chest.snappedf(0.01), thrown.last_fall])
	check(broke >= 1, "a man thrown into it breaks the span he hits (%d)" % broke)
	check(chest.y < float(b._lv.ground) + 1.2 and chest.x < 15.2, "and goes over, down to the bar room (%s)" % chest.snappedf(0.01))
	check(not thrown.last_fall.is_empty(), "a fall from height (#759): %s" % [thrown.last_fall])
	thrown.queue_free()


## Every stair is climbed: a walker stands on its ramp the whole way from the lower floor to the
## upper (Layers.STAND), its foot and head within a step of their floors.
func test_saloon_bs_stairs_are_climbed() -> void:
	var b = lab.building
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var ramps: Array = b.find_children("Ramp_*", "StaticBody3D", false, false)
	check(ramps.size() == 5, "five stairs: the hall's, the outside stair, the cellar's, two back steps (%d)" % ramps.size())
	for ramp: StaticBody3D in ramps:
		var box := (ramp.get_child(0) as CollisionShape3D).shape as BoxShape3D
		var on := 0
		for i in 30:
			var along := (float(i) + 0.5) / 30.0 - 0.5
			var top: Vector3 = ramp.global_transform * Vector3(along * box.size.x, 0.0, 0.0) + Vector3.UP * 0.6
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 1.2, Layers.STAND))
			if not hit.is_empty() and hit.collider == ramp:
				on += 1
		check(on >= 24, "%s: a walker is on its ramp all the way (%d of 30)" % [ramp.get_meta(&"stair"), on])
		var lo: Vector3 = b.to_local(ramp.global_transform * Vector3(-box.size.x * 0.5, 0, 0))
		var hi: Vector3 = b.to_local(ramp.global_transform * Vector3(box.size.x * 0.5, 0, 0))
		if lo.y > hi.y:
			var t := lo
			lo = hi
			hi = t
		var floors: Array = [0.0, float(b._lv.cellar) + 0.08, float(b._lv.ground), float(b._lv.upper)]
		var near := func(y: float) -> bool: return floors.any(func(f: float) -> bool: return absf(f - y) < 0.3)
		check(near.call(lo.y) and near.call(hi.y), "%s runs floor to floor (%.2f to %.2f)" % [ramp.get_meta(&"stair"), lo.y, hi.y])


## The corner entrance (Sean's answers 1 and 7): the corner cut off, one iron column under the
## upper floor, glazed double doors with a transom in the diagonal wall, and a man walks through.
func test_the_corner_entrance_is_open_glazed_and_on_one_column() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var col: StructureMember = b.get_member(StringName(sid + "corner/column"))
	check(col != null and col.wood == &"iron", "one iron column at the corner")
	var glass := 0
	for m: StructureMember in b.get_members():
		if String(m.member_id).begins_with(sid + "corner/") and m.kind == &"glass":
			glass += 1
	check(glass == 3, "two glazed leaves and the transom's light (%d panes)" % glass)
	check(b.find_children("*batwing*", "", true, false).is_empty() and b.get_member(StringName(sid + "front/batwing0")) == null, "no batwings")
	# A man through the doors: 0.6 wide, 1.9 tall, along the way in.
	var c: Dictionary = b._corner_frame()
	var mid: Vector3 = (c.origin as Vector3) + (c.along as Vector3) * (float(c.length) * 0.5)
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	for d: float in [0.5, 0.0, -0.3, -0.8]:
		var box := BoxShape3D.new()
		box.size = Vector3(0.6, 1.9, 0.3)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = box
		q.transform = Transform3D(c.basis as Basis, b.to_global(mid + (c.out as Vector3) * d + Vector3.UP * (float(b._lv.ground) + 0.97)))
		q.collision_mask = Layers.WORLD
		var hits := space.intersect_shape(q, 4)
		check(hits.is_empty(), "the doorway is clear %.1f m out (%s)" % [d, hits.map(func(h: Dictionary) -> String: return String((h.collider as Node).get("member_id")))])
	# The corner knocked out (the Balcony Ambush's key post): the upper corner and the balcony's
	# corner bays lose their path or go over.
	for r: Dictionary in Checks.knockouts(b, [col.member_id]):
		print("  the column gone: %d fall, %d over %s" % [r.falls, r.over, r.over_first])
		check(int(r.falls) + int(r.over) > 0, "the column carries the corner")


## #824's rule: every room people use has a lamp of its own; RoomLight gets every outer opening.
func test_saloon_bs_rooms_have_their_own_light() -> void:
	var b = lab.building
	var spec: Dictionary = lab.spec
	var lit := {}
	for lamp: OilLamp in b.lamps:
		var at: Vector3 = b.to_local(lamp.global_position)
		for r: Dictionary in spec.rooms:
			var rc: Array = r.rect
			var y := float(b._lv[r.level])
			if at.x > float(rc[0]) - 0.25 and at.x < float(rc[2]) + 0.25 and at.z > float(rc[1]) - 0.25 and at.z < float(rc[3]) + 0.25 \
					and at.y > y and at.y < y + 5.2:
				lit[r.id] = true
	for r: Dictionary in spec.rooms:
		if r.id != "cellar":
			check(lit.has(r.id), "the %s has a lamp" % r.id)
	var n := 1  # the corner's doors
	for w: Dictionary in spec.walls:
		if not w.get("partition", false):
			for o: Dictionary in w.get("openings", []):
				if o.type != "void":
					n += 1
	check(b.light_openings().size() == n, "RoomLight gets every outer opening (%d of %d)" % [b.light_openings().size(), n])
	for w: Dictionary in spec.walls:
		for o: Dictionary in w.get("openings", []):
			if o.type == "window":
				check(o.has("lights"), "%s's window at %s is a sash" % [w.id, o.at])
