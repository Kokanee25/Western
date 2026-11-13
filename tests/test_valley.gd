extends TestCase
## The world switch and the new valley (docs/briefs/valley-plan.md §12, G1): ValleyLayout reads
## config/valley.json as written, the valley's scene is empty but for the sky, the baked ground (G2:
## tests/test_valley_ground.gd), the main line and its train (G3: tests/test_valley_railway.gd) and
## the player at the crossroads looking down Main Street, and the old town is what loads unless the
## valley is asked for.


func _valley() -> ValleyLayout:
	return ValleyLayout.main()


func test_the_file_reads() -> void:
	var v := _valley()
	check_eq(int(v.data.get("format", 0)), ValleyLayout.FORMAT, "format")
	var env := v.envelope()
	check_eq(env.position, Vector2(-2000, -1400), "the envelope's north-west corner")
	check_eq(env.end, Vector2(2400, 2200), "the envelope's south-east corner")
	check(env.has_point(Vector2.ZERO), "the crossroads inside it")
	check_eq(v.crossroads(), Vector3.ZERO, "the crossroads is the origin")
	check_eq(v.main_street_heading(), 270.0, "Main Street runs due west")
	check_eq(v.boundaries().size(), 4, "a rule for each side")
	check(float(v.speeds().get("player_walk", 0.0)) > 0.0, "the speeds")


func test_places_and_where_they_are() -> void:
	var v := _valley()
	var ids := v.place_ids()
	check(ids.size() >= 20, "the places (%d)" % ids.size())
	check_eq(v.place_at("town"), Vector2.ZERO, "the town at the crossroads")
	check_eq(v.place_at("depot"), Vector2(61, -63), "the depot north of town")
	check(not v.place_pad("depot").is_empty(), "the depot's pad")
	var seen := {}
	for id in ids:
		check(not seen.has(id), "%s once" % id)
		seen[id] = true
		check(v.envelope().has_point(v.place_at(id)) or v.place_at(id).x == v.envelope().end.x,
				"%s inside the envelope (%s)" % [id, v.place_at(id)])
		for road: String in v.place(id).get("access", []):
			check(not v.road(road).is_empty(), "%s's road %s is a road" % [id, road])
	for m: Dictionary in v.missions():
		for p: String in m.get("places", []):
			check(not v.entry(p).is_empty(), "mission %s's %s is a place, bridge or viewpoint" % [m.id, p])
	check(not v.viewpoint("vp_depot").is_empty(), "a viewpoint")
	check(not v.mission("opening").is_empty(), "a mission")
	check(v.place("nowhere").is_empty() and v.entry("nowhere").is_empty(), "nothing by an id that isn't there")


func test_roads_and_bridges() -> void:
	var v := _valley()
	check_eq(v.road_ids().size(), v.roads().size(), "every road has an id")
	for id in v.road_ids():
		var line := v.road_line(id)
		check(line.size() >= 2, "%s has a line" % id)
		check(v.road_length(id) > 10.0, "%s is a road's length (%.0f m)" % [id, v.road_length(id)])
	check_near(v.road_line("west_road")[0].x, -125.0, 0.001, "the West Road leaves Main Street's west end")
	check_near(ValleyLayout.line_length(PackedVector2Array([Vector2.ZERO, Vector2(3, 4), Vector2(3, 10)])), 11.0, 1e-5, "a line's length")
	var crossings := {}
	for c: Dictionary in v.route_dict().get("crossings", []):
		crossings[c.id] = true
	for b: Dictionary in v.bridges():
		if b.has("road"):
			check(not v.road(b.road).is_empty(), "%s carries a road (%s)" % [b.id, b.road])
		if b.has("route_crossing"):
			check(crossings.has(b.route_crossing), "%s is a crossing on the line (%s)" % [b.id, b.route_crossing])
		if b.has("route_mark"):
			check(v.route_mark(b.route_mark) >= 0.0, "%s at a mark on the line (%s)" % [b.id, b.route_mark])
	check_eq(int(v.bridge("bridge_c").get("length", 0)), 130, "the great trestle is 130 m (DECIDED)")


func test_the_water() -> void:
	var v := _valley()
	check(v.water("creek") == v.water("salt_creek"), "the creek by its key and its id")
	check(v.water_line("creek").size() >= 10, "the creek's line")
	check((v.water_rows("creek")[0] as Array).size() > 2, "the creek's rows carry its bed")
	check(v.water_line("arroyo").size() >= 2 and v.water_line("ditch").size() >= 2, "the arroyo and the ditch")
	check(not v.water("canyon").is_empty(), "the canyon")
	check(v.water("nowhere").is_empty() and v.water("_doc").is_empty(), "nothing for a key that isn't a course")
	check_eq(v.springs().size(), 2, "the springs")


func test_the_railway_is_a_train_route() -> void:
	var v := _valley()
	var r := v.route()
	check(r is TrainRoute, "a TrainRoute")
	var total := 0.0
	for s: Dictionary in r.segments():
		total += float(s.length)
	check_near(total, 4600.0, 0.01, "the main line's plan runs 4.6 km to its tunnel")
	check_eq(r.origin(), Vector3(2450, -2.5, -344), "it starts at the east entrance")
	var last := -1.0
	for m: String in r.marks():
		check(float(r.marks()[m]) > last, "%s after the mark before" % m)
		last = float(r.marks()[m])
	check_eq(v.route_mark("depot"), 2416.0, "the depot's mark")
	check_eq(v.route_mark("nowhere"), -1.0, "no mark by a name that isn't one")
	for s: Dictionary in v.stops():
		check(v.route_mark(s.mark) >= 0.0, "stop %s at a mark" % s.id)
	for t: Dictionary in v.tracks():
		if t.has("from_mark"):
			check(v.route_mark(t.from_mark) < v.route_mark(t.to_mark), "%s runs from mark to mark" % t.id)


func test_the_town_lots() -> void:
	var v := _valley()
	check_eq(v.main_street_x(), Vector2(-125, 130), "Main Street's 250 m")
	for side in ["north", "south"]:
		var lots := v.lots(side)
		check(lots.size() > 5, "the %s side's lots" % side)
		for i in lots.size():
			var l: Dictionary = lots[i]
			check(float(l.x0) < float(l.x1), "%s has a width" % l.id)
			if i > 0:
				check(float((lots[i - 1] as Dictionary).x1) <= float(l.x0) + 1e-4, "%s doesn't overlap the lot west of it" % l.id)
			# The North-South Street (15.2 m) between the lots either side of x 0.
			if float(l.x1) <= 0.0 and i + 1 < lots.size() and float((lots[i + 1] as Dictionary).x0) >= 0.0:
				check_near(float((lots[i + 1] as Dictionary).x0) - float(l.x1), float(v.town().ns_street.width), 0.01, "the cross street on the %s side" % side)
	check(not v.lot("second_saloon").is_empty(), "an extra by id")
	check(not v.lot("assay_office").is_empty(), "a lot by id")
	for b: Dictionary in v.town_buildings():
		check_eq(b.kind, "building", "%s is a building" % b.id)


func test_an_empty_layout_is_safe() -> void:
	var v := ValleyLayout.new({})
	check_eq(v.envelope(), Rect2(), "no envelope")
	check(v.place_ids().is_empty() and v.road_line("x").is_empty() and v.lots("north").is_empty(), "nothing in it")
	check_eq(v.route_mark("depot"), -1.0, "no marks")
	check_eq(ValleyLayout.xz([3, 4, 5]), Vector2(3, 4), "a point from the file")


func test_the_town_is_the_default_world() -> void:
	check_eq(Settings.world, &"town", "the old town unless asked")
	check(Settings.WORLDS.has(&"valley"), "the valley is one")
	check(not Settings.set_world(&"moon"), "no such world")
	check_eq(Settings.world, &"town", "unchanged by a bad name")
	check(Settings.set_world(&"valley") and Settings.world == &"valley", "set")
	Settings.set_world(&"town")


func test_the_valley_scene_is_empty() -> void:
	var valley: Node3D = load("res://scenes/valley.tscn").instantiate()
	add_child(valley)
	await physics_frames(3)
	check(valley is ValleyWorld, "the valley's own scene")
	var player := valley.get_node_or_null(^"Player") as Node3D
	check(player != null, "the player")
	if player:
		check(Vector2(player.global_position.x, player.global_position.z).length() < 0.5, "at the crossroads (%s)" % player.global_position)
		check(absf(player.global_position.y) < 0.3, "on the ground (%.2f)" % player.global_position.y)
		var facing := -player.global_transform.basis.z
		check(facing.dot(Vector3.LEFT) > 0.999, "looking down Main Street, west (%s)" % facing)
	# The ground (G2): the valley's own, a Ground over the bake, the crossroads at Y 0.
	var ground := valley.get_node_or_null(^"Ground") as Ground
	check(ground != null and ground.terrain != null, "the baked ground")
	check(valley.get_node_or_null(^"FlatGround") == null, "G1's flat placeholder gone")
	if ground:
		check_eq(Ground.of(get_tree()), ground, "it's the ground (Ground.of)")
		check_near(ground.height_at(0.0, 0.0), 0.0, 1e-4, "the crossroads at Y 0")
		check(ground.valley != null and ground.valley.bodies.size() > 0, "its chunks")
	for name in ["TownLife", "TownLayout", "StreetDressing", "FireSystem"]:
		check(valley.find_child(name, true, false) == null, "no %s in the valley" % name)
	# (G6: the farmhouse and its mission on the widow's pad; tests/test_valley_farmhouse.gd.)
	check(valley.get_node_or_null(^"Farmhouse") is Farmhouse and valley.get_node_or_null(^"FarmhouseMission") is FarmhouseMission, "the farmhouse and its mission (G6)")
	# Nobody but the train's engineer (G3) and, by day, the town's day folk on their walks (#796).
	var folk := (valley as ValleyWorld).folk
	var people := get_tree().get_nodes_in_group(&"people").filter(func(p: Node) -> bool: return folk == null or not folk.people.values().has(p))
	check(people.size() <= 1 and people.all(func(p: Node) -> bool: return p.name == "Engineer"), "nobody in it but the train's engineer (G3) (%s)" % [people.map(func(p: Node) -> String: return p.name)])
	var rail := valley.get_node_or_null(^"Railway") as ValleyRailway
	check(rail != null and rail.line != null and rail.train != null, "the main line and its train (G3: tests/test_valley_railway.gd)")
	# The sun sets due west, straight down Main Street (heading 270, -X).
	var day := valley.get_node(^"DayCycle") as DayCycle
	var low := day.get_sun_direction(18.0)
	var flat := Vector3(low.x, 0.0, low.z).normalized()
	check(flat.dot(Vector3.LEFT) > 0.99, "the evening sun's bearing down Main Street (%s)" % flat)
	valley.queue_free()
	await process_frames(2)


func test_main_loads_one_world() -> void:
	# The switch's job: the town's street unless the valley's asked for, and then only the valley.
	for w: StringName in [&"valley", &"town"]:
		Settings.set_world(w)
		var main: Node = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await process_frames(2)
		var street := main.find_child("TestStreet", true, false)
		var valley := main.find_child("Valley", true, false)
		if w == &"valley":
			check(street == null and valley != null, "the valley alone")
		else:
			check(street != null and valley == null, "the town alone")
		check_eq(World.root(main), street if street else valley, "World.root finds it")
		main.queue_free()
		await process_frames(3)
	Settings.set_world(&"town")
