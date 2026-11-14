extends TestCase
## The valley town's greybox (docs/briefs/valley-plan.md §3, §12 G5, #724): the boardwalks along the
## lots' fronts from the game's Boardwalk part, the lanes, the 1.2 m gameplay alleys, the yards and
## the vacant lot open through to Back Street and the rear lane, the undertaker's alley blocked by
## junk you climb, and the town's places and links (ValleyTown.add_ways): `walk` from the crossroads
## to every lot's front door, and through every passage to the back.

const TEST_PORT := 18748

var holder: Node
var valley: ValleyWorld
var bridge: DevBridge


## The valley built once for the file (it's freed with the case, after its last test).
func before_each() -> void:
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(3)


func after_each() -> void:
	pass


func _town() -> ValleyTown:
	return valley.markers.town


func _bridge() -> DevBridge:
	if bridge == null:
		bridge = DevBridge.new()
		bridge.main = holder
		bridge.port = TEST_PORT
		holder.add_child(bridge)
		await process_frames(2)
	return bridge


func _player() -> Player:
	return valley.get_node(^"Player") as Player


func test_a_boardwalk_along_every_building_s_front() -> void:
	var t := _town()
	var lay := ValleyLayout.main()
	var with_walk := lay.town_buildings().filter(func(l: Dictionary) -> bool: return not (l.get("walk", {}) as Dictionary).get("none", false))
	check_eq(t.walks.size(), with_walk.size(), "a walk for each building lot but the livery's yard")
	check(_walk("livery").is_empty(), "no walk before the livery's dirt yard")
	var space := World.space(valley)
	for w: Dictionary in t.walks:
		var bw := w.node as Boardwalk
		check(bw != null and bw.get_members().size() > 50, "%s's walk built (%d members)" % [w.id, bw.get_members().size() if bw else 0])
		var l := lay.lot(String(w.id))
		# (A lot whose walk has a `span` keeps it to its building: the doctor's side yard is open, #765;
		# saloon B's runs on west past its corner to the side street's walk, #848.)
		var span: Array = (l.get("walk", {}) as Dictionary).get("span", [])
		check_near(float(w.x0), float(l.x0) if span.is_empty() else float(span[0]), 0.01, "%s's walk starts at its lot" % w.id)
		if span.is_empty():
			check(float(w.x1) >= float(l.x1) - 0.01, "%s's walk runs its frontage" % w.id)
		else:
			check_near(float(w.x1), float(span[1]), 0.01, "%s's walk runs its building's front" % w.id)
		# At its owner's height (G7, #737): the lot's walk.h over the ground at its street edge.
		var sgn := ValleyTown.sign_of(String(w.side))
		var edge := t.ground((float(w.x0) + float(w.x1)) * 0.5, sgn * (t.front - t.walk_depth))
		check_near(float(w.top) - edge, float((l.walk as Dictionary).h), 0.01, "%s's walk at its height" % w.id)
		# Its planks there, at its top, the town's boardwalk depth out from the front.
		for d in [0.3, t.walk_depth - 0.3]:
			# (A foot's width of rays: one can fall between two planks.)
			var p := Vector3(float(w.door) + 2.0, float(w.top) + 1.0, sgn * (t.front - d))
			var h := Waypoints._foot_height(space, p, p.y, p.y - 3.0, [])
			check(absf(h - float(w.top)) < 0.03, "%s's planks %.1f m out (%.2f)" % [w.id, d, h - float(w.top)])
		# Up on steps: a walk's street edge is a step too high but at its flight (a shack's isn't).
		if float(w.h) > Waypoints.STEP_UP + 0.05:
			check(float(w.top) - t.ground(float(w.door), sgn * (t.front - t.walk_depth)) > Waypoints.STEP_UP,
					"%s's walk a step too high at its edge" % w.id)
		check_eq(bw.steps.size() + bw.ramps.size(), 1, "%s: a flight (or a ramp) before its door" % w.id)
		check_eq(bw.ramps.size(), 1 if (l.walk as Dictionary).get("door", "") == "ramp" else 0, "%s: a ramp where its lot says" % w.id)
		# No riser over the town's rule, at its door or its ends.
		var door_h := bw.top + bw.street_below
		check(door_h / bw._rises(door_h) <= t.riser_max + 0.001, "%s: its door's risers (%.2f m in %d)" % [w.id, door_h, bw._rises(door_h)])
		for e: Vector2 in bw.end_steps:
			check((bw.top - e.y) / bw._end_rises(e.y) <= t.riser_max + 0.001, "%s: its end's risers" % w.id)
		check(bw._end_rises(0.0) >= 1, "counted")
		# Posts, open underneath, from posts_at; a rail along it from rail_at; its awning.
		check_eq(bw.on_posts, float(w.h) >= t.posts_at - 0.001, "%s on posts by its height" % w.id)
		check_eq(bw.rail, float(w.h) >= t.rail_at - 0.001, "%s railed by its height" % w.id)
		var aw := 0
		var rails := 0
		for m: StructureMember in bw.get_members():
			aw += 1 if String(m.member_id).contains("/awning/") else 0
			rails += 1 if String(m.member_id).contains("/rail/") else 0
		check_eq(aw > 0, float((l.walk as Dictionary).get("awning", 0)) > 0.0, "%s's awning as its lot says" % w.id)
		check_eq(rails > 0, bw.rail, "%s's rail built" % w.id)
	# Shoulder to shoulder walks join, the higher carrying the flight down: the store two treads to
	# the hardware's, the butcher a barrow ramp to the bakery's.
	check_eq(String(_walk("hardware").joined_e), "general_store", "the hardware's walk meets the store's")
	check_eq(String(_walk("bakery").joined_e), "butcher", "the bakery's meets the butcher's")
	var store := _walk("general_store").node as Boardwalk
	check(store.end_steps.any(func(e: Vector2) -> bool: return absf(e.y - (float(_walk("hardware").top) - float(_walk("general_store").y))) < 0.01),
			"the store steps down to the hardware's walk")
	var butcher := _walk("butcher").node as Boardwalk
	check_eq(butcher.end_ramps.size(), 1, "the butcher ramps down to the bakery's walk")
	# The drops: no flight at the store's east end (into its alley) or the bank's.
	check_eq(store.end_steps.size() + store.end_ramps.size(), 1, "the store's alley end a drop")
	var bank := _walk("bank").node as Boardwalk
	check_eq(bank.end_steps.size() + bank.end_ramps.size(), 1, "the bank's east end a drop")
	check_eq((_walk("hardware").node as Boardwalk).end_steps.size(), 1, "the hardware's down to its lane")
	# Under the high walks: room to crawl (the player flat is crawl_height).
	var crawl := PlayerTuning.new().crawl_height
	for id in ["undertaker", "bank"]:
		var w := _walk(id)
		var sgn := ValleyTown.sign_of(String(w.side))
		var x := float(w.door) + 3.0
		var under := float(w.top) - Boardwalk.PLANK_T - Boardwalk.JOIST_D - t.ground(x, sgn * (t.front - t.walk_depth + 0.4))
		check(under > crawl + 0.1, "%s: %.2f m under its street edge to crawl in" % [id, under])


## The ways use the steps (#737): from one door to the next over a join, or down an end's flight
## into an alley or a lane and up the next, never straight off a walk's edge.
func test_the_ways_go_by_the_steps() -> void:
	var places := valley.places()
	var space := World.space(valley)
	for pair: Array in [["doctor", "barber", true], ["general_store", "hardware", false], ["hotel", "doctor", true]]:
		var r := places.route(space, places.at(StringName(pair[0])), StringName(pair[1]))
		check(r.size() >= 1, "%s to %s routed" % [pair[0], pair[1]])
		var low := INF
		for q: Vector3 in r:
			low = minf(low, q.y)
		var doors := minf(places.at(StringName(pair[0])).y, places.at(StringName(pair[1])).y)
		if pair[2]:
			check(low < doors - 0.5, "%s to %s: down the steps into the gap and up (lowest %.2f, doors %.2f)" % [pair[0], pair[1], low, doors])
		else:
			check(low > doors - 0.3, "%s to %s: along the joined walks (lowest %.2f)" % [pair[0], pair[1], low])
		var worst := 0.0
		for i in range(1, r.size()):
			worst = maxf(worst, absf(r[i].y - r[i - 1].y) / maxf(Vector2(r[i].x - r[i - 1].x, r[i].z - r[i - 1].z).length(), 0.05))
		check(worst < 1.0, "%s to %s: no leg steeper than a stair (%.2f)" % [pair[0], pair[1], worst])


func _walk(id: String) -> Dictionary:
	for w: Dictionary in _town().walks:
		if w.id == id:
			return w
	return {}


func test_the_passages_and_the_alleys_width() -> void:
	var t := _town()
	var lay := ValleyLayout.main()
	for side in ["north", "south"]:
		for l: Dictionary in lay.lots(side):
			if String(l.kind) in ["lane", "alley", "yard", "vacant", "houses"]:
				check(not t.passage(String(l.id)).is_empty(), "%s is a passage" % l.id)
	check(not t.passage("gap_south@56").is_empty(), "the gap between the bank and the land office (%s)" % [t.passages.map(func(p: Dictionary) -> String: return p.id)])
	var space := World.space(valley)
	for id in ["alley_n4", "alley_n7", "alley_n8"]:
		var p := t.passage(id)
		var x := float(p.x)
		# Its width between the blocks, measured: the plan's 1.2 m.
		var z := -(t.front + 4.0)
		var y := t.ground(x, z) + 1.0
		var west := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, y, z), Vector3(x - 3.0, y, z), Layers.WORLD))
		var east := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, y, z), Vector3(x + 3.0, y, z), Layers.WORLD))
		check(not west.is_empty() and not east.is_empty(), "%s: walls on both sides" % id)
		if west.is_empty() or east.is_empty():
			continue
		var width := (east.position as Vector3).x - (west.position as Vector3).x
		check_near(width, 1.2, 0.02, "%s is 1.2 m wide (%.2f)" % [id, width])
		# A man fits; two abreast don't: a man's width (Waypoints.WIDTH each side) swept in from the
		# street at chest height clears it, two men's doesn't.
		var a := Vector3(x, t.ground(x, -t.front + 1.5) + 1.3, -t.front + 1.5)
		var b := Vector3(x, a.y, -t.front - 5.0)
		check(_sweep(space, a, b, Waypoints.WIDTH), "%s: a man walks it" % id)
		check(not _sweep(space, a, b, Waypoints.WIDTH * 2.0 + 0.02), "%s: two abreast don't" % id)


func _sweep(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, r: float) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = r
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = Layers.WORLD
	q.transform = Transform3D(Basis.IDENTITY, a)
	q.motion = b - a
	return space.cast_motion(q)[0] >= 0.999


func test_the_undertaker_s_alley_is_climbed_not_walked() -> void:
	var t := _town()
	check_eq(t.junk.size(), 1, "one lot's junk")
	var j: Dictionary = t.junk[0]
	check_eq(String(j.id), "alley_n8", "in the undertaker's alley")
	var p := t.passage("alley_n8")
	check(p.junk, "its passage blocked")
	# No link through it, and not walkable straight.
	var places := valley.places()
	check(not (places.links.get(&"alley_n8", []) as Array).has(&"alley_n8_back"), "not linked through")
	var space := World.space(valley)
	check(not Waypoints._walkable(space, places.at(&"alley_n8"), places.at(&"alley_n8_back"), []), "not walkable through")
	# Each tier a jump up from the one before (the player's jump clears ~0.65 m).
	var x := float(p.x)
	var last := t.ground(x, -t.front - 5.0)
	var tops := []
	for b: Dictionary in j.boxes:
		var top := (b.centre as Vector3).y + (b.size as Vector3).y * 0.5
		tops.append(top)
	check(float(tops[0]) - last <= 0.58 and float(tops[1]) - float(tops[0]) <= 0.58, "two jumps up (%s from %.2f)" % [tops, last])
	check(float(tops[0]) - last > 0.4, "too high to walk up")
	# The player: walked into it, stopped; jumping, over it.
	var br: DevBridge = await _bridge()
	var player := _player()
	var start := Vector3(x, t.ground(x, -t.front - 3.0) + 0.1, -t.front - 3.0)
	player.global_position = start
	player.velocity = Vector3.ZERO
	br._set_view(0.0, 0.0)  # facing north, -Z
	await physics_frames(5)
	br._act(true, &"move_forward")
	await physics_frames(240)
	br._act(false, &"move_forward")
	var far_side := -t.front - 9.6
	check(player.global_position.z > far_side + 3.0, "walking, stopped at it (z %.1f)" % player.global_position.z)
	player.global_position = start
	player.velocity = Vector3.ZERO
	await physics_frames(5)
	br._act(true, &"move_forward")
	for i in 12:
		br._act(true, &"jump")
		await physics_frames(2)
		br._act(false, &"jump")
		await physics_frames(28)
		if player.global_position.z < far_side:
			break
	br._act(false, &"move_forward")
	check(player.global_position.z < far_side, "jumping, over it (z %.1f)" % player.global_position.z)


func test_every_town_link_is_walkable() -> void:
	var places := valley.places()
	var space := World.space(valley)
	var n := 0
	var bad := []
	for a: StringName in places.links:
		for b: StringName in places.links[a]:
			if String(a) > String(b):
				continue
			if String(a).begins_with("farm_") and String(b).begins_with("farm_"):
				continue  # (the farmhouse's own, G6: the old town's house, its stair and porch steps; test_farmhouse)
			n += 1
			if not Waypoints._walkable(space, places.at(a), places.at(b), []):
				bad.append("%s-%s" % [a, b])
	check(n > 100, "the town's links (%d)" % n)
	check(bad.is_empty(), "every link walkable (not: %s)" % [bad])


func test_the_viewpoints_on_their_walks() -> void:
	var places := valley.places()
	for pair: Array in [["vp_main_east", "undertaker"], ["vp_saloon_balcony", "saloon"]]:
		var w := _walk(String(pair[1]))
		var p := places.at(StringName(pair[0]))
		check_near(p.y, float(w.top) + 0.05, 0.01, "%s on %s's walk" % pair)
		check((places.links.get(StringName(pair[0]), []) as Array).has(StringName(pair[1])), "%s linked to its door" % pair[0])


## The gate (#724): from the crossroads to every lot's front door, and through every lane, alley,
## yard and gap to Back Street or the rear lane, walked by the dev bridge's `walk` (running).
func test_walk_to_every_door_and_through_every_passage() -> void:
	var br: DevBridge = await _bridge()
	var t := _town()
	var places := valley.places()
	var player := _player()
	var failed := []
	var targets: Array[Array] = []
	for w: Dictionary in t.walks:
		targets.append([String(w.id)])
	for p: Dictionary in t.passages:
		targets.append([String(p.id), "%s_back" % p.id] if not p.junk else [String(p.id)])
	for legs: Array in targets:
		await br._cmd_goto(["town"])
		for leg: String in legs:
			var out: Dictionary = await br._cmd_walk([leg, "run"])
			var off := player.global_position.distance_to(places.at(StringName(leg)))
			if not out.get("arrived", false) or off > 1.5:
				failed.append("%s (%s, %.1f m off at %s)" % [leg, out.get("error", "stuck"), off, player.global_position])
				break
	check(failed.is_empty(), "walked to every door and through every passage (not: %s)" % [failed])
