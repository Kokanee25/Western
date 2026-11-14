extends TestCase
## The places on the test street and the links between them: every link can be walked in a
## straight line (nothing in the way at knee to chest height), and every place has floor under it.

func test_every_link_can_be_walked() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	# No outlaw in the way.
	for n in get_tree().get_nodes_in_group(&"people"):
		n.queue_free()
	await physics_frames(2)
	var w := Waypoints.test_street()
	var space := street.get_world_3d().direct_space_state
	var ex: Array[RID] = [(street.get_node(^"Player") as Player).get_rid()]
	var bad: Array[String] = []
	for a: StringName in w.links:
		for b: StringName in w.links[a]:
			# A stair's link is climbed by its ramp (Waypoints.mark_stair), not walked level.
			if String(a) < String(b) and not w.is_stair(a, b) and not Cover.path_clear(space, w.at(a), w.at(b), ex):
				bad.append("%s-%s" % [a, b])
	check(bad.is_empty(), "blocked links: %s" % str(bad))
	var floorless: Array[String] = []
	for n: StringName in w.points:
		if Cover._ground(space, w.at(n), ex) == null:
			floorless.append(String(n))
	check(floorless.is_empty(), "no floor under: %s" % str(floorless))
	var way := w.route(space, w.at(&"west_edge"), &"bar_1", ex)
	check(way.size() >= 4, "a way from the edge of town to the bar (%d legs)" % way.size())
	street.queue_free()


## The way found asking only the places it needs (#510) is the way found asking every place first
## (the old `route`, below: each place's straight walk by the sweep and the steps), from a grid of
## spots over the street, inside and out, to places across the town.
func test_a_route_is_the_one_asking_every_place_gives() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	for n in get_tree().get_nodes_in_group(&"people"):
		n.queue_free()
	await physics_frames(2)
	var w := Waypoints.test_street()
	var space := street.get_world_3d().direct_space_state
	var ex: Array[RID] = [(street.get_node(^"Player") as Player).get_rid()]
	var goals: Array[StringName] = [&"bar_0", &"bar_2", &"store_counter", &"west_edge"]
	var asked := 0
	var differ: Array[String] = []
	for x in range(-34, 31, 8):
		for z in range(-14, 9, 4):
			var top := Vector3(x, 6.0, z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 8.0, Layers.STAND, ex))
			if hit.is_empty():
				continue
			var from: Vector3 = hit.position
			for to in goals:
				asked += 1
				var now := w.route(space, from, to, ex)
				var then := _route_asking_all(w, space, from, to, ex)
				if now != then:
					differ.append("%s -> %s: %d legs, was %d" % [str(from.snapped(Vector3.ONE * 0.1)), to, now.size(), then.size()])
	check(asked > 100, "%d routes compared" % asked)
	check(differ.is_empty(), "the same ways: %s" % str(differ))
	street.queue_free()


## Waypoints.route before #510: every place asked first (the sweep, then the steps), then the
## shortest way along the links from those he can walk to.
func _route_asking_all(w: Waypoints, space: PhysicsDirectSpaceState3D, from: Vector3, to: StringName, ex: Array[RID]) -> Array[Vector3]:
	var walk := func(a: Vector3, b: Vector3) -> bool:
		var low := minf(a.y, b.y)
		return Cover.path_clear(space, Vector3(a.x, low, a.z), Vector3(b.x, low, b.z), ex, Waypoints.WIDTH) \
				and Waypoints._no_step_up(space, a, b, ex)
	var goal := w.at(to)
	if walk.call(from, goal) and absf(from.y - goal.y) < 0.6:
		return [goal]
	var starts: Array[StringName] = []
	for n: StringName in w.points:
		if walk.call(from, w.at(n)):
			starts.append(n)
	if starts.is_empty():
		var best := &""
		var best_d := INF
		for n: StringName in w.points:
			if from.distance_to(w.at(n)) < best_d:
				best_d = from.distance_to(w.at(n))
				best = n
		starts.append(best)
	var dist := {}
	var prev := {}
	var open: Array[StringName] = []
	for n in starts:
		dist[n] = from.distance_to(w.at(n))
		open.append(n)
	while not open.is_empty():
		var cur: StringName = open[0]
		for n in open:
			if dist[n] < dist[cur]:
				cur = n
		open.erase(cur)
		if cur == to:
			break
		for nb: StringName in w.links.get(cur, []):
			var d: float = dist[cur] + w.at(cur).distance_to(w.at(nb))
			if d < dist.get(nb, INF):
				dist[nb] = d
				prev[nb] = cur
				if not open.has(nb):
					open.append(nb)
	if not dist.has(to):
		return []
	var path: Array[Vector3] = []
	var n := to
	while true:
		path.push_front(w.at(n))
		if not prev.has(n):
			break
		n = prev[n]
	return path
