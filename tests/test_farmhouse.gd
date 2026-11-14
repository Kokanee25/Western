extends TestCase
## The farmhouse out east (issue #520; experiments/building_lab/farmhouse.json, src/missions/
## farmhouse.gd), built from its spec by the building lab's builder: it stands under its own weight
## and with a crowd on its floors, people fit its doors, stairs and places, everything in it is a
## member, a kit prop or a fitting (destructible through and through), and its marks have causes.

const Checks := preload("res://experiments/building_lab/checks.gd")

var world: Node3D
var house: Farmhouse


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	house = Farmhouse.new()
	world.add_child(house)
	await physics_frames(3)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_it_stands() -> void:
	var r := Checks.stands(house.building)
	print("  dead load: %s; with a crowd on the floors: %s" % [r.dead, r.crowd])
	check(int(r.dead.falling) == 0, "every member has a load path (%d don't)" % r.dead.falling)
	check(int(r.dead.over) == 0, "none over its limit under its own weight: %s" % [r.dead.worst])
	check(int(r.crowd.over) == 0, "nor with a crowd on the floor and the loft (40 lb/ft2): %s" % [r.crowd.worst])


func test_everything_in_it_is_destructible() -> void:
	var b: Structure = house.building
	var r := Checks.destructible(b, b)
	print("  %d members, %d kit props (%d members), %d lamps, allowed %s" % [r.members, r.kit_props, r.kit_members, r.lamps, r.allowed])
	check((r.bad as Array).is_empty(), "nothing but members, kit props and fittings: %s" % [(r.bad as Array).slice(0, 8)])
	check((r.rigs as Array).is_empty(), "no structure that holds still whatever happens: %s" % [r.rigs])
	for k: StringName in r.allowed:
		check(Checks.EXCEPTIONS.has(k), "%s is a listed exception" % k)
	check(int(r.members) > 1000, "the house is members (%d)" % r.members)
	check(int(r.kit_props) >= 15, "its furniture is kit props (%d)" % r.kit_props)
	check(int(r.lamps) == 2, "its two lamps are OilLamps (%d)" % r.lamps)
	# The porch's deck is a Boardwalk: members too.
	check(house.porch.get_members().size() > 20, "the porch's deck is members (%d)" % house.porch.get_members().size())


func test_people_fit() -> void:
	var fit := Checks.people_fit(house.building, house.building.spec)
	print("  %d doors, %d stairs, %d use points" % [fit.doors, fit.stairs, fit.use_points])
	# The yard's watch point is out on the hill, which isn't here (no street): nothing under it.
	var failures := (fit.failures as Array).filter(func(f: String) -> bool: return not f.begins_with("yard:"))
	check(failures.is_empty(), "doors, the stairs and its places clear a man: %s" % [failures.slice(0, 10)])
	check(int(fit.doors) >= 4, "its doors (%d)" % fit.doors)


func test_its_marks_have_causes() -> void:
	const Marks := preload("res://experiments/building_lab/marks.gd")
	var m: Dictionary = house.building.marks
	check((m.unresolved as Array).is_empty(), "every past mark finds its member: %s" % [m.unresolved])
	for ev: Dictionary in house.building.spec.past:
		check(int(m.by_cause.get(ev.id, 0)) > 0, "%s marks something" % ev.id)
	for p: Dictionary in house.building.spec.use.paths:
		check(int(m.by_cause.get(p.id, 0)) > 0, "%s wears its floor" % p.id)
	for k: String in m.by_kind:
		check(Marks.KINDS.has(StringName(k)), "%s is a mark the shader knows" % k)


func test_its_places_join_the_town() -> void:
	var w := Waypoints.test_street()
	for p: StringName in [&"road_east", &"road_farm", &"farm_lane", &"farm_door", &"farm_bedroom", &"farm_kitchen", &"farm_back_door", &"farm_loft"]:
		check(w.has(p), "%s is a place" % p)
	check(w.at(&"farm_door").distance_to(Farmhouse.at(Vector3(2.8, Farmhouse.FLOOR, 0.45))) < 0.01, "its door where the spec has it")
	var bedroom := Farmhouse.at(Vector3(7.3, Farmhouse.FLOOR, 2.5))
	check(Vector2(bedroom.x, bedroom.z).distance_to(Vector2(98.0, -49.0)) < 6.0, "out on its knoll (%s)" % bedroom)
