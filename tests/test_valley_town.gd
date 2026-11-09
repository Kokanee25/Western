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
	check_eq(t.walks.size(), lay.town_buildings().size(), "a walk for each building lot")
	var space := World.space(valley)
	for w: Dictionary in t.walks:
		var bw := w.node as Boardwalk
		check(bw != null and bw.get_members().size() > 50, "%s's walk built (%d members)" % [w.id, bw.get_members().size() if bw else 0])
		var l := lay.lot(String(w.id))
		check_near(float(w.x0), float(l.x0), 0.01, "%s's walk starts at its lot" % w.id)
		check(float(w.x1) >= float(l.x1) - 0.01, "%s's walk runs its frontage" % w.id)
		# Its planks there, at its top, the town's boardwalk depth out from the front.
		var sgn := ValleyTown.sign_of(String(w.side))
		for d in [0.3, t.walk_depth - 0.3]:
			# (A foot's width of rays: one can fall between two planks.)
			var p := Vector3(float(w.door) + 2.0, float(w.top) + 1.0, sgn * (t.front - d))
			var h := Waypoints._foot_height(space, p, p.y, p.y - 3.0, [])
			check(absf(h - float(w.top)) < 0.03, "%s's planks %.1f m out (%.2f)" % [w.id, d, h - float(w.top)])
		# Up on steps: the walk's street edge is a step too high but at its flight.
		check(float(w.top) - t.ground(float(w.door), sgn * (t.front - t.walk_depth)) > Waypoints.STEP_UP,
				"%s's walk a step too high at its edge" % w.id)
		check_eq(bw.steps.size(), 1, "%s: a flight before its door" % w.id)
	# Shoulder to shoulder walks join (the hardware and the store; the bakery and the butcher).
	for pair: Array in [["hardware", "general_store"], ["bakery", "butcher"]]:
		var a := _walk(String(pair[0]))
		check_eq(String(a.joined_e), String(pair[1]), "%s's walk meets %s's" % pair)
		check(absf(float(a.top) - float(_walk(String(pair[1])).top)) < Waypoints.STEP_UP, "a step between them, not a climb")
	# Every other end steps down to the ground.
	check_eq((_walk("butcher").node as Boardwalk).end_steps.size(), 1, "the butcher's walk steps down to the North-South Street")
	check_eq((_walk("hardware").node as Boardwalk).end_steps.size(), 1, "the hardware's down to its lane")


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
