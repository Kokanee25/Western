extends TestCase
## Saloon B, the corner saloon (#848 step 1: the spec and the frame): built from its spec
## (config/buildings/saloon_b.json) it is destructible through and through, stands,
## is built right, fits a man at every door, stair and use point, and every room has its people's
## places and its own lamp. It writes every member to build/saloon_b_members.json for the X-ray
## sheet (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://config/buildings/saloon_b.json"

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
	check(int(r.cloths) == 2, "the stage's curtain and drop are its only cloths (%d)" % r.cloths)
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
		# bar room's floor the timbers land on (its boards, and since #867 a joist under them).
		elif not (id.begins_with("beam/east/2") or id.begins_with("gallery/") or id.begins_with("floor/ground/")):
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
	# The stage (#902) stands clear of the panel, and it and what stands on it stay up.
	var stage_n := 0
	var stage_down := []
	for m: StructureMember in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		if id.begins_with("stage/") or id.begins_with("stair/stage/") or id.begins_with("stair/wing/") or id.begins_with("wing/"):
			stage_n += 1
			if m.broken:
				stage_down.append(id)
	check(stage_n > 100 and stage_down.is_empty(), "the stage, its steps and the wing stand when the panel falls (%d of %d down: %s)" % [stage_down.size(), stage_n, stage_down.slice(0, 6)])
	check(b.curtain != null and b.curtain.is_inside_tree() and b.backdrop != null and b.backdrop.is_inside_tree(), "the curtain and the drop still hang")
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
	# The hanging lamps on the panel's joists come down with them (#950: its dressing); the rest hang on.
	var lamps: Dictionary = b.dressed.get("S1", {})
	for id: String in ["hanging_lamp_1", "hanging_lamp_5"]:
		check(lamps.has(id) and lamps[id].loose, "%s, hung from the panel's joists, falls with them" % id)
	for id: String in ["hanging_lamp_0", "hanging_lamp_3"]:
		check(lamps.has(id) and not lamps[id].loose, "%s, off the panel, still hangs" % id)


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
	check(ramps.size() == 7, "seven stairs: the hall's, the outside stair, the cellar's, two back steps, the stage's two (%d)" % ramps.size())
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
		var floors: Array = [0.0, float(b._lv.cellar) + 0.08, float(b._lv.ground), float(b._lv.upper), float(b._lv.upper) + float(lab.spec.stage.height)]
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


## Step 2 (#867): the look's parts are built and take their finishes by name: the bar room's
## wainscot (oak, clear of every window), the bracketed cornice on both streets (the trim's
## paint), the dressed timber over the bar, and the dust under the dance floor.
func test_saloon_b_has_its_finishes_cornices_and_dust() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var count := {"wainscot": 0, "front_brackets": 0, "side_brackets": 0, "side_cornice": 0}
	var want := {"/wainscot": "oak", "/picture_rail": "oak", "front/cornice_bracket": "trim", "side/cornice": "trim",
			"floor/dance/joist": "timber", "beam/east": "timber", "gallery/rail": "oak", "stair/hall/tread": "oak",
			"street/post": "trim", "/siding/": "exterior", "floor/dance/board": "floor"}
	var seen := {}
	for m: StructureMember in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		if id.contains("/wainscot"):
			count.wainscot += 1
		elif id.begins_with("front/cornice_bracket/"):
			count.front_brackets += 1
		elif id.begins_with("side/cornice_bracket/"):
			count.side_brackets += 1
		elif id.begins_with("side/cornice/"):
			count.side_cornice += 1
		for k: String in want:
			if id.contains(k) and not seen.has(k):
				seen[k] = true
				check(b._finish_of(m) == want[k], "%s takes the %s finish (%s)" % [id, want[k], b._finish_of(m)])
				var f: Dictionary = b.finish(want[k])
				var e: Dictionary = MaterialLibrary.entry(String(f.get("entry", "")))
				check(not e.is_empty(), "%s names a library entry (%s)" % [want[k], f])
	for k: String in want:
		check(seen.has(k), "a member for %s" % k)
	print("  %s" % [count])
	check(int(count.wainscot) > 100, "the bar room is wainscoted (%d pieces)" % count.wainscot)
	check(int(count.front_brackets) >= 30 and int(count.side_brackets) >= 40, "brackets under the cornice on both streets: %s" % [count])
	check(int(count.side_cornice) >= 4, "the side street's eave has its cornice")
	# The outside paint is one the judge passed at the age it's drawn at.
	var ext: Dictionary = b.finish("exterior")
	check((MaterialLibrary.entry(String(ext.entry)).get("approved", []) as Array).has(String(ext.age)), "the outside paint is passed at its age: %s" % [ext])
	var dust := b.get_node_or_null(^"FloorDust") as FloorDust
	check(dust != null, "dust under the dance floor")
	if dust:
		check(dust.rect.size.x > 9.0 and dust.top > 4.7 and dust.bottom < 1.0, "it falls from the dance floor's boards to the bar room's floor (%s, %.2f to %.2f)" % [dust.rect, dust.top, dust.bottom])
		dust.stir(Vector3(3.0, 0.0, 6.0))
		var falling := 0
		for c in dust.get_children():
			if c is CPUParticles3D and (c as CPUParticles3D).one_shot and (c as CPUParticles3D).emitting:
				falling += 1
		check(falling == 1, "a step above shakes one fall down (%d)" % falling)


## The stage (#902; Sean, 2026-11-13: 16 x 8 ft, a wing and a dressing room, a curtain that opens on
## a painted drop; the band plays there on Payday Night): against the dance hall's back partition,
## 30 in high, of members, clear of the sawn girder's panel; the wing boarded off with its own door
## across the hall from the dressing room's; room_6 the dressing room.
func test_saloon_bs_stage_stands_clear_of_the_panel_with_its_wing_and_dressing_room() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var spec: Dictionary = lab.spec
	var girder: StructureMember = b.get_member(StringName(sid + String(spec.sabotage.girder)))
	var gz1 := girder.position.z + girder.size.z * 0.5
	var top := float(b._lv.upper) + float(spec.stage.height)
	var counts := {"leg": 0, "bearer": 0, "joist": 0, "board": 0, "skirt": 0, "proscenium": 0}
	var nearest := INF
	var highest := -INF
	for m: StructureMember in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		if not (id.begins_with("stage/") or id.begins_with("stair/stage/") or id.begins_with("stair/wing/")):
			continue
		var box: AABB = m.structure_aabb()
		nearest = minf(nearest, box.position.z)
		for k: String in counts:
			if id.begins_with("stage/%s/" % k):
				counts[k] += 1
		if id.begins_with("stage/board/"):
			highest = maxf(highest, box.end.y)
	print("  stage: %s; its nearest edge z %.2f (the panel ends at %.2f); its top %.3f" % [counts, nearest, gz1, highest])
	check(int(counts.board) >= 15 and int(counts.joist) >= 12 and int(counts.leg) >= 12 and int(counts.skirt) >= 8, "the stage is built as a floor: %s" % [counts])
	check(nearest > gz1 + 0.2, "it and its steps stand clear of the sawn girder's panel (%.2f past %.2f)" % [nearest, gz1])
	check(absf(highest - top) < 0.005 and absf(highest - float(b._lv.upper) - 0.762) < 0.01, "30 in over the dance floor (%.3f)" % (highest - float(b._lv.upper)))
	check(int(counts.proscenium) == 4, "two posts, a header and the rod (%d)" % counts.proscenium)
	# The wing's door and the hall's: one at 1.58 across from room_6's, the public one at 8.43, none behind the stage.
	var doors := []
	for w: Dictionary in spec.walls:
		if w.id == "dance_back":
			for o: Dictionary in w.openings:
				doors.append(float(o.at))
		if w.id == "rooms_front":
			check(absf(float(w.openings[0].at) - 1.58) < 0.01, "room_6's door at 1.58")
	check(doors == [1.58, 8.43], "the dance hall's doors: the wing's across from the dressing room's, the public one (%s)" % [doors])
	var leaves := 0
	for m: StructureMember in b.get_members():
		if String(m.member_id).begins_with(sid + "dance_back/door_"):
			leaves += 1
	check(leaves == 2, "both its doors have their leaves (%d)" % leaves)
	var wing_boards := 0
	for m: StructureMember in b.get_members():
		if String(m.member_id).begins_with(sid + "wing/"):
			wing_boards += 1
	check(wing_boards > 20, "the wing is boarded off from the dance floor (%d members)" % wing_boards)
	var room_6: Dictionary = (spec.rooms as Array).filter(func(r: Dictionary) -> bool: return r.id == "room_6")[0]
	check(String(room_6.use).begins_with("the dressing room"), "room_6 is the dressing room")
	var let := (spec.rooms as Array).filter(func(r: Dictionary) -> bool: return String(r.use) == "let by the night").size()
	check(let == 3, "three rooms let (%d)" % let)
	var dressed: Dictionary = b.dressed.get("stage", {})
	for k: String in ["dress_table", "dress_chair", "dress_lamp", "foot_0", "foot_4"]:
		check(dressed.has(k), "%s is placed" % k)
	if dressed.has("dress_table"):
		var at: Vector3 = b.to_local((dressed.dress_table as Node3D).global_position)
		check(at.x < 2.85 and at.z > 15.29 and absf(at.y - float(b._lv.upper)) < 0.05, "the dressing table in room_6, on its floor (%s)" % at.snappedf(0.01))
	if dressed.has("foot_0"):
		var at: Vector3 = b.to_local((dressed.foot_0 as Node3D).global_position)
		check(absf(at.y - top) < 0.02, "the footlights on the stage's boards (%.2f)" % at.y)
	# The band's places on the stage, behind the curtain's line.
	var band := 0
	for u: Dictionary in spec.use_points:
		if u.has("at") and absf(float(u.at[1]) - top) < 0.01:
			band += 1
	check(band >= 4, "the band and the act have their places on the stage (%d)" % band)


## A man can go the way Payday Night's acts do: up the outside stair's landing into the upper hall,
## into the dressing room, back across to the wing's door, through the wing and up its steps, across
## the stage behind the curtain and down its steps to the dance floor. Each stretch walked as the
## town's people walk (Waypoints._walkable), a step at a time over whatever floor is there.
func test_a_man_walks_from_the_yard_stair_through_the_dressing_room_and_wing_onto_the_stage() -> void:
	var b = lab.building
	var space: PhysicsDirectSpaceState3D = b.get_world_3d().direct_space_state
	var u := float(b._lv.upper)
	var route: Array = [Vector2(-0.6, 14.43), Vector2(0.6, 14.43), Vector2(1.68, 14.45), Vector2(1.68, 16.3), Vector2(1.68, 14.45),
			Vector2(1.68, 12.75), Vector2(1.0, 12.45), Vector2(1.0, 11.9), Vector2(1.3, 11.9), Vector2(2.9, 11.9), Vector2(4.0, 11.75), Vector2(7.2, 11.75),
			Vector2(8.9, 11.75), Vector2(8.9, 8.0)]
	var names := ["landing", "yard door", "hall", "dressing room", "hall", "wing door", "the wing's back", "wing", "wing steps' foot", "stage", "behind the curtain",
			"stage's side", "steps' foot", "dance floor"]
	var feet := func(p: Vector2) -> Vector3:
		# What's under his feet (past a board's gap, as the walkers look).
		var at: Vector3 = b.to_global(Vector3(p.x, u, p.y))
		var y := Waypoints._foot_height(space, at, at.y + 1.2, at.y - 0.4, [])
		return Vector3(at.x, y, at.z)
	var bad := []
	for i in route.size() - 1:
		var a: Vector2 = route[i]
		var c: Vector2 = route[i + 1]
		var n := maxi(1, ceili(a.distance_to(c) / 0.4))
		var prev: Vector3 = feet.call(a)
		for k in range(1, n + 1):
			var here: Vector3 = feet.call(a.lerp(c, float(k) / n))
			if prev.y == -INF or here.y == -INF or not Waypoints._walkable(space, prev, here, []):
				bad.append("%s -> %s at %d/%d (%s to %s)" % [names[i], names[i + 1], k, n, b.to_local(prev).snappedf(0.01), b.to_local(here).snappedf(0.01)])
				break
			prev = here
	var on_stage: Vector3 = b.to_local(feet.call(route[10]))
	check(absf(on_stage.y - u - float(lab.spec.stage.height)) < 0.02, "the walk is up on the stage behind the curtain (%.2f)" % on_stage.y)
	check(bad.is_empty(), "walked every stretch: %s" % [bad])


## The curtain (#902; DrawCurtain): hung shut on the rod between the proscenium's posts; drawn open
## its halves pack at the sides, drawn shut they meet past the middle; its state saves and loads.
func test_the_stage_curtain_opens_closes_and_saves() -> void:
	var b = lab.building
	var c: DrawCurtain = b.curtain
	check(c != null, "the stage has its curtain")
	if c == null:
		return
	var post_gap := 4.9 - 2.0 * 0.12
	check(absf(c.width - post_gap) < 0.01 and c.height > 1.9, "it fills the opening between the posts (%.2f x %.2f)" % [c.width, c.height])
	check(not c.is_open() and c.half_width() > c.width * 0.5, "it hangs shut, its halves past the middle (%.2f of %.2f)" % [c.half_width(), c.width * 0.5])
	var shut_box := _drawn(c)
	b.open_curtain()
	check(c.moving(), "drawing it takes time")
	var done := []
	c.finished.connect(func(open: bool) -> void: done.append(open))
	await wait_until(func() -> bool: return not c.moving(), int((c.travel + 2.0) * 60.0))
	check(c.is_open() and is_equal_approx(c.amount, 1.0) and done == [true], "drawn open (%.2f, %s)" % [c.amount, done])
	check(c.half_width() < c.width * 0.12, "its halves packed at the sides (%.2f each)" % c.half_width())
	var open_box := _drawn(c)
	check(open_box.x < shut_box.x * 0.3, "open, the middle of the stage is clear (cloth across %.2f of the middle's %.2f)" % [open_box.x, shut_box.x])
	check(open_box.y > shut_box.y, "and its folds deepen as it gathers (%.3f, shut %.3f)" % [open_box.y, shut_box.y])
	var saved := c.to_dict()
	b.close_curtain()
	await wait_until(func() -> bool: return not c.moving(), int((c.travel + 2.0) * 60.0))
	check(not c.is_open() and c.half_width() > c.width * 0.5, "drawn shut again")
	c.from_dict(saved)
	check(c.is_open() and not c.moving() and is_equal_approx(c.amount, 1.0), "a saved open curtain loads open, where it was")
	var fresh := DrawCurtain.new()
	add_child(fresh)
	fresh.from_dict({"open": false})
	check(not fresh.is_open() and fresh.to_dict() == {"open": false}, "and a shut one shut")
	fresh.queue_free()
	check(b.backdrop != null and b.backdrop.painted() and absf(b.backdrop.width - 4.6) < 0.01, "the drop hangs, painted (Salt Creek as the Baron promises it, #960)")
	var cloth := b.backdrop.get_node(^"Cloth") as MeshInstance3D
	check(cloth != null and (cloth.material_override as StandardMaterial3D).albedo_texture != null, "its painting on the canvas")


## The cloth a curtain draws across the stage's middle metre (x) and its folds' depth (y), from its meshes.
func _drawn(c: DrawCurtain) -> Vector2:
	var across := 0.0
	var depth := 0.0
	for mi: MeshInstance3D in c.find_children("*", "MeshInstance3D", false, false):
		var verts: PackedVector3Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var lo := INF
		var hi := -INF
		for v in verts:
			depth = maxf(depth, absf(v.z))
			if absf(v.x) < 0.5:
				lo = minf(lo, v.x)
				hi = maxf(hi, v.x)
		if hi > lo:
			across += hi - lo
	return Vector2(across, depth)


## #886 (Sean's yes on #885; the name his, 2026-11-13): THE NEW OCCIDENTAL painted on the false front's board (the factory's
## letters, laid on a board cut to them in the dark walnut), and the walks lit: four reflector lamps
## on the outside walls under the balcony, two a street, lit from dusk, one casting shadows.
func test_saloon_bs_sign_is_lettered_and_its_walks_lit() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	var sign: StructureMember = b.get_member(StringName(sid + "front/sign"))
	check(sign != null, "the false front has its sign board")
	check(SignArt.letters("THE NEW OCCIDENTAL") != null, "THE NEW OCCIDENTAL's letters are painted (letters_the_new_occidental)")
	var painted := sign.find_children("PaintedLetters", "MeshInstance3D", true, false)
	check(painted.size() == 1, "the letters are laid on the board (%d)" % painted.size())
	if painted.size() == 1:
		var q := (painted[0] as MeshInstance3D).mesh as QuadMesh
		var at: Vector3 = b.to_local((painted[0] as Node3D).global_position)
		check(q.size.x < sign.size.x and q.size.y < sign.size.y, "inside the board (%s on %s)" % [q.size, Vector2(sign.size.x, sign.size.y)])
		check(q.size.x > sign.size.x * 0.75, "the board cut to them (%.2f of %.2f m)" % [q.size.x, sign.size.x])
		check(absf(at.x - b.width * 0.5) < 0.05 and at.z < -0.05, "centred on the front, on the board's face (%s)" % at)
		check(q.size.x > 4.0 and q.size.x < 4.95, "big enough to read down the street, kept to 4.9 m (%.2f m)" % q.size.x)
		check(q.size.y > 1.0, "letters tall enough to read down the street (%.2f m)" % q.size.y)
	check(b._finish_of(sign) == "oak", "the board in the dark walnut (%s)" % b._finish_of(sign))
	var ground := float(b._lv.ground)
	var walks := {"front": 0, "side": 0}
	var shadows := 0
	for lamp: OilLamp in b.lamps:
		var p: Vector3 = b.to_local(lamp.global_position)
		var on_front := p.z < 0.0
		var on_side: bool = p.x > float(b.width)
		if not (on_front or on_side):
			continue
		walks["front" if on_front else "side"] += 1
		check(p.y > ground + 1.8 and p.y < ground + 2.6, "a walk's lamp is hung over a man's head (%.2f over the walk)" % (p.y - ground))
		check((on_front and p.z > -2.36) or (on_side and p.x < 18.82 and p.z < 13.33), "and under the balcony (%s)" % p)
		check(lamp.lit_from_hour == 17 and lamp.lit_until_hour == 4, "lit from dusk to 4 (%d-%d)" % [lamp.lit_from_hour, lamp.lit_until_hour])
		if lamp.casts_shadows:
			shadows += 1
	check(walks.front == 2 and walks.side == 2, "two lamps on each street's walk (%s)" % walks)
	check(shadows == 1, "only one of them casts shadows (%d)" % shadows)
