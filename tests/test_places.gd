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


## Bounded and nearest-first asks give the same ways (#1119): `routes_from` with a `reach` is the
## unbounded one's ways no longer than it (the cover search's town ways), and `route_to_point`
## asking nearest first is the old ask-each-nearer-than-the-best, from a grid over the street.
func test_bounded_routes_and_route_to_point_keep_their_ways() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	for n in get_tree().get_nodes_in_group(&"people"):
		n.queue_free()
	await physics_frames(2)
	var w := Waypoints.test_street()
	var space := street.get_world_3d().direct_space_state
	var ex: Array[RID] = [(street.get_node(^"Player") as Player).get_rid()]
	var reach := 20.0
	var asked := 0
	var kept := 0
	var differ: Array[String] = []
	for x in range(-34, 31, 8):
		for z in range(-14, 9, 4):
			var top := Vector3(x, 6.0, z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 8.0, Layers.STAND, ex))
			if hit.is_empty():
				continue
			var from: Vector3 = hit.position
			asked += 1
			var all := w.routes_from(space, from, ex)
			var near := w.routes_from(space, from, ex, reach)
			for n: StringName in all:
				var way: Array = all[n]
				var length := 0.0
				var at := from
				for p: Vector3 in way:
					length += at.distance_to(p)
					at = p
				# A way from the fallback start (nothing walkable straight, level with him) isn't kept bounded.
				if length <= reach and absf(from.y - (way[0] as Vector3).y) < 0.6 and Waypoints._walkable(space, from, way[0], ex):
					kept += 1
					if not near.has(n) or near[n] != way:
						differ.append("routes %s -> %s" % [str(from.snapped(Vector3.ONE * 0.1)), n])
			for n: StringName in near:
				if not all.has(n) or all[n] != near[n]:
					differ.append("routes %s -> %s: not the unbounded way" % [str(from.snapped(Vector3.ONE * 0.1)), n])
			for to: Vector3 in [w.at(&"bar_1") + Vector3(0.8, 0.0, 0.3), w.at(&"west_edge") + Vector3(0.0, 0.0, 2.0)]:
				if w.route_to_point(space, from, to, ex) != _route_to_point_was(w, space, from, to, ex):
					differ.append("route_to_point %s -> %s" % [str(from.snapped(Vector3.ONE * 0.1)), str(to)])
	check(asked > 20 and kept > 50, "%d spots, %d ways in reach compared" % [asked, kept])
	check(differ.is_empty(), "the same ways: %s" % str(differ))
	street.queue_free()


## Waypoints.route_to_point before #1119: every place nearer than the best so far asked.
func _route_to_point_was(w: Waypoints, space: PhysicsDirectSpaceState3D, from: Vector3, point: Vector3, ex: Array[RID]) -> Array[Vector3]:
	var straight: Array[Vector3] = [point]
	if Waypoints._walkable(space, from, point, ex) and absf(from.y - point.y) < 0.6:
		return straight
	var best := &""
	var best_d := INF
	for n: StringName in w.points:
		var d := w.at(n).distance_to(point)
		if d < best_d and Waypoints._walkable(space, w.at(n), point, ex):
			best_d = d
			best = n
	if best == &"":
		return straight
	var path := w.route(space, from, best, ex)
	path.append(point)
	return path


## A cover search spread thin (one piece a step: a chunk's lines, one spot scored, one routed;
## #1123) finds what one chunk a step found: the same spot, score and way, by the town's ways and
## by the way there (`by_way`) and with his own cover (`own`), from a grid over the street's west
## end against a man up the street.
func test_a_spread_cover_search_finds_the_same_spot() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	for n in get_tree().get_nodes_in_group(&"people"):
		n.queue_free()
	await physics_frames(2)
	var w := Waypoints.test_street()
	var space := street.get_world_3d().direct_space_state
	var ex: Array[RID] = [(street.get_node(^"Player") as Player).get_rid()]
	var eye := Vector3(10.0, 1.6, -3.0)
	var compared := 0
	var found := 0
	var spread_steps := 0
	var chunk_steps := 0
	var differ: Array[String] = []
	for x in range(-30, 1, 6):
		for z in [-12, -8, -4]:
			var top := Vector3(x, 6.0, z)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 8.0, Layers.STAND, ex))
			if hit.is_empty():
				continue
			var from: Vector3 = hit.position
			for v: StringName in [&"", &"by_way", &"own"]:
				var got: Array[Dictionary] = []
				for spread: bool in [false, true]:
					var rng := RandomNumberGenerator.new()
					rng.seed = 1123
					var s := Cover.search(street, from, eye, ex, rng, Vector3.INF, 11.0, 3.0, w)
					if v != &"":
						s._ctx[v] = true
					var steps := 0
					while true:
						steps += 1
						# The whole search in one step (a budget it can't spend), or a piece a step.
						var b := WorkBudget.new(0.0, 0) if spread else WorkBudget.new(1e9, 1 << 40)
						if s.step(40, b) or steps > 5000:
							break
					if spread:
						spread_steps += steps
					else:
						chunk_steps += steps
					got.append(s.result)
				compared += 1
				var a: Dictionary = got[0]
				var b2: Dictionary = got[1]
				if not a.is_empty():
					found += 1
				if a.is_empty() != b2.is_empty() or (not a.is_empty() and (a.at != b2.at or a.score != b2.score or a.route != b2.route)):
					differ.append("%s %s" % [str(from.snapped(Vector3.ONE * 0.1)), v])
	check(compared > 30 and found > 10, "%d searches compared, %d found a spot" % [compared, found])
	check(spread_steps > chunk_steps * 5, "spread over many more steps (%d against %d)" % [spread_steps, chunk_steps])
	check(differ.is_empty(), "the same spots: %s" % str(differ))
	street.queue_free()
