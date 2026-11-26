extends TestCase
## The Railroad Saloon, THE SILVER SPIKE (#1285 the design, #1286 the build): built from its spec
## (config/buildings/railroad_saloon.json, written by experiments/building_lab/railroad_saloon/make_spec.py)
## it is destructible through and through, stands, is built right and fits a man at every door, stair
## and use point; its dance floor carries a payday crowd whole, and cut (Payday Night's sawn girder)
## drops the middle bay, and only it, onto the bar. It writes every member to
## build/railroad_saloon_members.json for the X-ray sheet (tools/buildings/xray.py).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")
const SPEC := "res://config/buildings/railroad_saloon.json"

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


func test_railroad_saloon_is_built_and_destructible() -> void:
	var b: Structure = lab.building
	var r := Checks.destructible(b, b)
	for k: StringName in r.allowed:
		print("  allowed: %d x %s" % [r.allowed[k], k])
	print("  %d members; not things: %d" % [r.members, r.not_things])
	check((r.bad as Array).is_empty(), "nothing but members and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 1200, "the building is members (%d)" % r.members)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var n := Checks.export_members(b, ProjectSettings.globalize_path("res://build/railroad_saloon_members.json"))
	print("  exported %d members to build/railroad_saloon_members.json" % n)
	print("  draws: %s" % [Checks.draw_calls(lab)])


func test_railroad_saloon_stands() -> void:
	var r := Checks.stands(lab.building)
	print("  dead load: %s; with a crowd: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't): %s" % [r.dead.falling, r.dead.get("falling_first", [])])
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on its floors: %s" % [r.crowd.worst])
	var gave: Array = lab.building.settle()
	check(gave.is_empty(), "the game's own settle finds nothing to give (%d: %s)" % [gave.size(), gave.slice(0, 4)])


func test_railroad_saloon_is_built_right() -> void:
	var r := Checks.built_right(lab.building, lab.spec)
	print("  %d openings, %d framed" % [r.openings, r.framed])
	for f: String in (r.failures as Array).slice(0, 40):
		print("    ", f)
	check(r.ok, "nothing across an opening, every opening framed and glazed (%d failures)" % (r.failures as Array).size())


func test_people_fit_the_railroad_saloon() -> void:
	var b: Structure = lab.building
	var fit := Checks.people_fit(b, lab.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	for f: String in (fit.failures as Array).slice(0, 40):
		print("    ", f)
	check(fit.ok, "doors, stairs and use points clear a man (%d failures)" % (fit.failures as Array).size())
	var used := Checks.used(b, lab.spec)
	check(used.ok, "every room has its people's places: %s" % [used.failures])



## Payday Night (#1285's plan, #772: the girder the Baron's men saw). Whole, the 6x12 carries the
## dance floor under a dancing crowd (70 lb/ft2, Hatfield) and nothing gives. Cut through
## (`sabotage`: beam/spine/1, the middle bay over the bar; SpecBuilding.saw_girder), the middle
## bay's floor comes down through its load paths, its joists hinging on the side walls' ribbons, and
## nothing else but what its timbers hit where they land: the front bay, the back bay with the piano
## and the band's corner, and the girder's other pieces stand.
func test_the_sawn_girder_drops_the_middle_bay_onto_the_bar() -> void:
	var b = lab.building
	var sid := String(b.structure_id) + "/"
	for m: StructureMember in b.get_members():
		if m.kind == &"floor_board" and String(m.member_id).contains("/floor/dance"):
			m.extra_load += 3352.0 * m.size.x * m.size.z
	b.invalidate_analysis()
	var gave: Array = b.settle()
	check(gave.is_empty(), "whole, the floor carries a dancing crowd (%d gave: %s)" % [gave.size(), gave.slice(0, 4)])
	var girder: StructureMember = b.get_member(StringName(sid + String(lab.spec.sabotage.girder)))
	var gz0 := girder.position.z - girder.size.z * 0.5
	var gz1 := girder.position.z + girder.size.z * 0.5
	var bars := 0
	for f: Dictionary in lab.spec.fixtures:
		if f.kit == "bar":
			check(float(f.at[0]) < girder.position.x and absf(float(f.at[1]) - girder.position.z) < 0.5, "the bar stands under the sawn bay (z %.2f, the bay %.2f-%.2f)" % [float(f.at[1]), gz0, gz1])
			bars += 1
	check(bars == 1, "there is a bar")
	var hit := {}
	var watch := func(n: Node) -> void:
		if n is RigidBody3D and n.is_in_group(&"rubble"):
			(n as RigidBody3D).body_entered.connect(func(o: Node) -> void:
				if o is StructureMember:
					hit[String((o as StructureMember).member_id).trim_prefix(sid)] = true)
	get_tree().node_added.connect(watch)
	var halves: Array = b.saw_girder()
	check(halves.size() == 2, "the saw leaves two halves (%d)" % halves.size())
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
		if id.begins_with("floor/dance_mid/joist/"):
			joists += 1
		elif id.begins_with("floor/dance_mid/board/"):
			boards += 1
		elif not (id.begins_with("beam/spine/1") or id.begins_with("floor/ground/")):
			outside.append(id)
	# Outside the bay a member may go only if a falling piece hit it, or what it was nailed to did.
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
	print("  cut: %d joists, %d boards down; outside the bay: %s (%d hit by what fell, %d members hit in all)" % [joists, boards, outside.slice(0, 6), landed.size(), hit.size()])
	check(joists >= 12, "the bay's joists come down, both sides of the girder (%d)" % joists)
	check(boards >= 25, "and the boards on them, under the crowd (%d)" % boards)
	check(unexplained.is_empty(), "nothing else gives but what the falling floor hit: %s" % [unexplained.slice(0, 8)])
	check(landed.size() <= 12, "and the falling floor breaks only a few members where it lands (%d: %s)" % [landed.size(), landed.keys().slice(0, 8)])
	var front_down := 0
	var back_down := 0
	for m: StructureMember in b.get_members():
		var id := String(m.member_id).trim_prefix(sid)
		if id.begins_with("floor/dance/") and m.broken:
			front_down += 1
		if id.begins_with("floor/dance_back/") and m.broken:
			back_down += 1
	check(front_down == 0 and back_down == 0, "the front and back bays stand (%d, %d down)" % [front_down, back_down])
	for id: String in ["beam/spine/0", "beam/spine/2", "post/00", "post/01"]:
		check(not (b.get_member(StringName(sid + id)) as StructureMember).broken, "%s stands" % id)
	# For real: the pieces fall, and over the bar's side.
	await physics_frames(360)
	var fell := 0
	var over_bar := 0
	var n := 0
	for rb: RigidBody3D in get_tree().get_nodes_in_group(&"rubble"):
		var ids: Array = rb.get_meta(&"members", [])
		if ids.is_empty() or not String(ids[0]).begins_with(sid + "floor/dance_mid/joist/") and not String(ids[0]).begins_with(sid + "beam/spine/1"):
			continue
		n += 1
		var p: Vector3 = b.to_local(rb.global_position)
		if p.y < float(b._lv.upper) - 1.0:
			fell += 1
			if p.x < girder.position.x + 0.5:
				over_bar += 1
	print("  %d pieces of the girder and its joists; %d fell a metre or more, %d of them on the bar's side" % [n, fell, over_bar])
	check(fell >= n * 0.6, "the girder's halves and its joists fall (%d of %d)" % [fell, n])
	check(over_bar >= 5, "and the bar's side gets its share (%d)" % over_bar)
