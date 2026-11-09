extends TestCase
## The farmhouse on the widow's pad in the valley (docs/briefs/valley-plan.md §6, §12 G6, #731): the
## old town's house (its spec unchanged) built by ValleyWorld on config/valley.json's
## `widow_homestead`, its middle on the place, facing the lane, on the ground under its low corner;
## the mission's hills carried from the old town into the bake; its places joined to the valley's by
## the East Road and the widow's lane; FarmhouseMission played there with no TownLife (its men made
## as the riders, finding their way by the farm's own places), started by walking up to it or by
## `farm_start`. The old town's farmhouse is held by test_farmhouse and test_farmhouse_mission.

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	holder.queue_free()
	await physics_frames(3)


func test_the_hills_are_the_old_town_s() -> void:
	# valley.json's widow_homestead hills: town.json's ground.hills, about the old house's middle.
	var place := ValleyLayout.main().place(Farmhouse.VALLEY_PLACE)
	var bumps: Array = (place.get("hills", {}) as Dictionary).get("bumps", [])
	var town: Array = (TownLayout.data().ground.hills as Dictionary).bumps
	check_eq(bumps.size(), town.size(), "every bump carried")
	var old := TownLayout.transform_of(&"Farmhouse")
	var mid := old * Farmhouse.MIDDLE
	var turn := deg_to_rad(float((place.get("farmhouse", {}) as Dictionary).get("facing", 180.0))) - old.basis.get_euler().y
	for i in mini(bumps.size(), town.size()):
		var t: Dictionary = town[i]
		var off := Vector2(float(t.at[0]) - mid.x, float(t.at[1]) - mid.z).rotated(-turn)
		var b: Dictionary = bumps[i]
		check(off.distance_to(Vector2(float(b.at[0]), float(b.at[1]))) < 0.6, "bump %d where it was about the house (%s, town %s)" % [i, b.at, off])
		check_eq(float(b.r), float(t.r), "bump %d's reach" % i)
		check_eq(float(b.h), float(t.h), "bump %d's height" % i)


func test_it_stands_on_the_widow_s_pad() -> void:
	var house := valley.get_node_or_null(^"Farmhouse") as Farmhouse
	check(house != null and house.building != null and house.building.get_members().size() > 1000, "the house built from its spec")
	check(Farmhouse.in_valley() and Farmhouse.of(get_tree()) == house, "the farmhouse in play is the valley's")
	var at := ValleyLayout.main().place_at(Farmhouse.VALLEY_PLACE)
	var mid := Farmhouse.at(Farmhouse.MIDDLE)
	check_near(Vector2(mid.x, mid.z).distance_to(at), 0.0, 0.01, "its middle on the place")
	check_eq_v(house.global_transform, Farmhouse.origin(), "where its helpers say it is")
	var front := Farmhouse.origin().basis * Vector3(0, 0, -1)
	check(front.dot(Vector3(0, 0, 1)) > 0.999, "its front to the lane, south (%s)" % front)
	# On the ground under its low corner (as TownLayout.footing in the old town).
	var o := Farmhouse.origin()
	var low := INF
	for c: Vector3 in [Vector3(0, 0, -2.4), Vector3(Farmhouse.WIDTH, 0, -2.4), Vector3(0, 0, Farmhouse.DEPTH), Vector3(Farmhouse.WIDTH, 0, Farmhouse.DEPTH)]:
		var q := o * c
		low = minf(low, valley.get_node(^"Ground").height_at(q.x, q.z))
	check_near(o.origin.y, low, 0.01, "on the ground under its low corner")
	# The ground round it as round the old town's, relative to it (the pad levelled, the knoll and
	# the rise carried): within 15 m of its middle to 0.2 m.
	var old := TownLayout.transform_of(&"Farmhouse")
	var worst := 0.0
	for x in range(-12, 22, 3):
		for z in range(-12, 20, 3):
			var v := o * Vector3(x, 0, z)
			var t := old * Vector3(x, 0, z)
			var dv := Farmhouse.ground_at(v.x, v.z) - o.origin.y
			var dt := TownLayout.ground_height(t.x, t.z) - old.origin.y
			worst = maxf(worst, absf(dv - dt))
	check(worst < 0.2, "the ground round it the old town's, relative to it (worst %.2f m)" % worst)


func test_its_places_join_the_valley_s() -> void:
	var w := valley.places()
	for n in [&"farm_lane", &"farm_porch", &"farm_door", &"farm_bedroom", &"farm_back", &"farm_outhouse", Farmhouse.VALLEY_START, Farmhouse.VALLEY_BELOW]:
		check(w.has(n), "%s among the valley's places" % n)
	var lane_end := valley.markers.way_end("widow_lane")
	check(lane_end != &"" and (w.links.get(&"farm_lane", []) as Array).has(lane_end), "the lane's foot joined to the widow's lane's end (%s)" % lane_end)
	check(Vector2(w.at(lane_end).x - w.at(&"farm_lane").x, w.at(lane_end).z - w.at(&"farm_lane").z).length() < 8.0, "beside it")
	# From the crossroads by the links: Main Street, the East Road, the widow's lane.
	var back: Array = w._ways_to(&"farm_porch")
	check((back[0] as Dictionary).has(&"main@0"), "the crossroads has a way to the porch")
	var n := &"main@0"
	var roads := {}
	var steps := 0
	while n != &"farm_porch" and steps < 5000:
		n = (back[1] as Dictionary)[n]
		roads[String(n).get_slice("@", 0).get_slice(">", 0)] = true
		steps += 1
	check(roads.has("east_road") and roads.has("widow_lane"), "by the East Road and the widow's lane (%s)" % [roads.keys().slice(0, 12)])
	check(float((back[0] as Dictionary)[&"main@0"]) < 3200.0, "about the plan's way (%.0f m)" % float((back[0] as Dictionary)[&"main@0"]))
	# Each link of the ways no steeper over its lower end than a man's sweep passes.
	for id: String in ValleyMarkers.WAY_ROADS:
		var names: Array = valley.markers.ways.get(id, [])
		check(names.size() > 2, "%s has its way" % id)
		for i in range(1, names.size()):
			var d := Vector2(w.at(names[i]).x - w.at(names[i - 1]).x, w.at(names[i]).z - w.at(names[i - 1]).z).length()
			if d > ValleyMarkers.WAY_LINK_MAX + 0.01:
				check(false, "%s's link %s-%s %.1f m" % [id, names[i - 1], names[i], d])
				break


func test_the_mission_plays_there() -> void:
	var m := valley.get_node(^"FarmhouseMission") as FarmhouseMission
	var player := valley.get_node(^"Player") as Player
	check_eq(m.state, FarmhouseMission.State.IDLE, "not on while you're in town")
	await physics_frames(20)
	check_eq(m.state, FarmhouseMission.State.IDLE, "still not, at the crossroads")
	check(m.places() != valley.places() and m.places().has(&"farm_bedroom") and not m.places().has(&"main@0"), "the men's places the farm's own")
	# Walk up within VALLEY_REACH: it's on (no blacksmith in the valley).
	var mid := Farmhouse.at(Farmhouse.MIDDLE)
	var far := mid + Vector3(120.0, 0.0, 320.0)
	far.y = Farmhouse.ground_at(far.x, far.z) + 0.1
	player.global_position = far
	await physics_frames(20)
	check_eq(m.state, FarmhouseMission.State.IDLE, "not on 340 m off")
	var near := mid + Vector3(60.0, 0.0, 200.0)
	near.y = Farmhouse.ground_at(near.x, near.z) + 0.1
	player.global_position = near
	await physics_frames(20)
	check_eq(m.state, FarmhouseMission.State.ON, "on once you're near the widow's")
	check_eq(m.brains.size(), 7, "five in the house and two in the yard")
	for b in m.brains:
		if not b in m.rovers:
			var post: Array = Farmhouse.use_point(String(m.specs[b.body.person_id].post))
			var d := Vector2(b.body.global_position.x - post[0].x, b.body.global_position.z - post[0].z).length()
			check(d < 1.0, "%s at his post (%.2f m off)" % [b.body.name, d])
		check(b.places == m.places(), "%s finds his way by the farm's places" % b.body.name)
	check(m.hostage != null and m.hostage_brain.tied or m.hostage.global_position.distance_to(Farmhouse.use_point("hostage")[0]) < 1.5, "the rancher in his chair")
	for b in m.brains:
		if String(b.body.person_id) in ["brody", "lyle", "kid"]:
			check_eq(b.body.rng_seed, 200 + ["brody", "lyle", "kid"].find(String(b.body.person_id)), "%s made as the town's rider" % b.body.name)


func test_farm_start_puts_you_before_the_house() -> void:
	var m := valley.get_node(^"FarmhouseMission") as FarmhouseMission
	var player := valley.get_node(^"Player") as Player
	m.begin(true)
	await physics_frames(5)
	check_eq(m.state, FarmhouseMission.State.ON, "on")
	var start := m.places().at(Farmhouse.VALLEY_START)
	check(Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length() < 0.5, "you at the start")
	# The old town's start carried: where it was from the house.
	var old := TownLayout.transform_of(&"Farmhouse").affine_inverse() * TownLayout.street_point(40.0, 3.0)
	var now := Farmhouse.origin().affine_inverse() * start
	check(Vector2(old.x - now.x, old.z - now.z).length() < 0.1, "as far from the house as the old town's (%s, %s)" % [old, now])


func test_the_old_town_s_again_once_it_s_gone() -> void:
	holder.queue_free()
	await physics_frames(3)
	check(not Farmhouse.in_valley(), "nothing in the valley")
	check_eq_v(Farmhouse.origin(), TownLayout.transform_of(&"Farmhouse"), "the helpers the old town's")
	check_eq(Farmhouse.start_place(), &"road_east", "the old town's start")
	holder = Node.new()
	add_child(holder)


func check_eq_v(a: Transform3D, b: Transform3D, what: String) -> void:
	check(a.is_equal_approx(b), "%s (%s vs %s)" % [what, a, b])
