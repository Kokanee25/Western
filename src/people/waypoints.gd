class_name Waypoints
extends RefCounted
## Named places people go to (the bar, the store counter, the saloon door, the street) joined into a
## graph, so a man can walk from anywhere to any of them: straight to the nearest point he can reach,
## then along the links (in the door, not through the wall). A stand-in for proper route-finding
## until the town has a navigation mesh.

var points := {}  ## name -> Vector3
var links := {}  ## name -> Array[StringName]


func add(name: StringName, at: Vector3, linked: Array = []) -> void:
	points[name] = at
	links.get_or_add(name, [])
	for other: StringName in linked:
		link(name, other)


func link(a: StringName, b: StringName) -> void:
	if not (links.get_or_add(a, []) as Array).has(b):
		links[a].append(b)
	if not (links.get_or_add(b, []) as Array).has(a):
		links[b].append(a)


func has(name: StringName) -> bool:
	return points.has(name)


func at(name: StringName) -> Vector3:
	return points.get(name, Vector3.INF)


## The points to walk through from `from` to the place `to`, ending there. [] if it can't be done.
func route(space: PhysicsDirectSpaceState3D, from: Vector3, to: StringName, exclude: Array[RID] = []) -> Array[Vector3]:
	if not points.has(to):
		return []
	var goal: Vector3 = points[to]
	if _walkable(space, from, goal, exclude) and absf(from.y - goal.y) < 0.6:
		return [goal]
	# Nearest points he can walk straight to, then the shortest way along the links.
	var starts: Array[StringName] = []
	for n: StringName in points:
		if _walkable(space, from, points[n], exclude):
			starts.append(n)
	if starts.is_empty():
		# Nothing in a straight line: head for the nearest anyway.
		var best := &""
		var best_d := INF
		for n: StringName in points:
			var d := from.distance_to(points[n])
			if d < best_d:
				best_d = d
				best = n
		starts.append(best)
	var dist := {}
	var prev := {}
	var open: Array[StringName] = []
	for n in starts:
		dist[n] = from.distance_to(points[n])
		open.append(n)
	while not open.is_empty():
		var cur: StringName = open[0]
		for n in open:
			if dist[n] < dist[cur]:
				cur = n
		open.erase(cur)
		if cur == to:
			break
		for nb: StringName in links.get(cur, []):
			var d: float = dist[cur] + (points[cur] as Vector3).distance_to(points[nb])
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
		path.push_front(points[n])
		if not prev.has(n):
			break
		n = prev[n]
	return path


## The ways from `from` to every place he can get to: {name: points to walk through, ending there},
## worked out together (one search, a sweep per place to find where he can start), for choosing
## among many places at once.
func routes_from(space: PhysicsDirectSpaceState3D, from: Vector3, exclude: Array[RID] = []) -> Dictionary:
	var dist := {}
	var prev := {}
	var open: Array[StringName] = []
	for n: StringName in points:
		if _walkable(space, from, points[n], exclude) and absf(from.y - (points[n] as Vector3).y) < 0.6:
			dist[n] = from.distance_to(points[n])
			open.append(n)
	if open.is_empty() and not points.is_empty():
		# Nothing in a straight line: head for the nearest anyway (as `route` does).
		var near: StringName = points.keys()[0]
		for n: StringName in points:
			if from.distance_to(points[n]) < from.distance_to(points[near]):
				near = n
		dist[near] = from.distance_to(points[near])
		open.append(near)
	while not open.is_empty():
		var cur: StringName = open[0]
		for n in open:
			if dist[n] < dist[cur]:
				cur = n
		open.erase(cur)
		for nb: StringName in links.get(cur, []):
			var d: float = dist[cur] + (points[cur] as Vector3).distance_to(points[nb])
			if d < dist.get(nb, INF):
				dist[nb] = d
				prev[nb] = cur
				if not open.has(nb):
					open.append(nb)
	var out := {}
	for to: StringName in dist:
		var path: Array[Vector3] = []
		var n := to
		while true:
			path.push_front(points[n])
			if not prev.has(n):
				break
			n = prev[n]
		out[to] = path
	return out


## The way to any point: straight there if he can, else to the place nearest it that he can walk
## on from, and on.
func route_to_point(space: PhysicsDirectSpaceState3D, from: Vector3, point: Vector3, exclude: Array[RID] = []) -> Array[Vector3]:
	var straight: Array[Vector3] = [point]
	if _walkable(space, from, point, exclude) and absf(from.y - point.y) < 0.6:
		return straight
	var best := &""
	var best_d := INF
	for n: StringName in points:
		var d := (points[n] as Vector3).distance_to(point)
		if d < best_d and _walkable(space, points[n], point, exclude):
			best_d = d
			best = n
	if best == &"":
		return straight
	var path := route(space, from, best, exclude)
	path.append(point)
	return path


## A man (a little wider than he is, to clear door jambs) can walk it in a straight line. Swept at
## the lower end's height: from a porch down into the street, a sweep at porch height passes over a
## hitching rail he'd walk into.
static func _walkable(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, exclude: Array[RID]) -> bool:
	var low := minf(a.y, b.y)
	return Cover.path_clear(space, Vector3(a.x, low, a.z), Vector3(b.x, low, b.z), exclude, WIDTH) and _no_step_up(space, a, b, exclude)


## The tallest rise a way may have from one footfall to the next: the steps' rise and the slope over
## them pass; a boardwalk's edge (up on steps since Sean's map) or a crate doesn't.
const STEP_UP := 0.25


## No sudden rise or drop in the ground along the way from `a` to `b` (looked at every 0.3 m).
static func _no_step_up(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, exclude: Array[RID]) -> bool:
	var n := maxi(1, ceili(Vector2(b.x - a.x, b.z - a.z).length() / 0.3))
	var top := maxf(a.y, b.y) + 0.6
	var bottom := minf(a.y, b.y) - 0.5
	var prev := a.y
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, top, p.z), Vector3(p.x, bottom, p.z), Layers.WORLD, exclude)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var h := (hit.position as Vector3).y
		if absf(h - prev) > STEP_UP:
			return false
		prev = h
	return true


## Half the width a man needs to get through somewhere without catching his shoulder.
const WIDTH := 0.3


## The places on the test street: the saloon (its bar and the room behind it), the store (the
## counter, and behind it), their doors and porches, the street itself and the road out west.
static func test_street() -> Waypoints:
	var w := Waypoints.new()
	# Main Street, east to west down the middle (config/town.json: Freight Street at the east end,
	# Market Street at the west, the road out west beyond it).
	w.add(&"west_edge", Vector3(-50, 0, -9))
	w.add(&"street_west", Vector3(-20, 0, -9), [&"west_edge"])
	w.add(&"street_mid", Vector3(0, 0, -9), [&"street_west"])
	w.add(&"street_east", Vector3(20, 0, -9), [&"street_mid"])
	var floor_top := float(TownLayout.data().get("floor", 0.38))
	# The store (its door in the middle of its front, the front to -Z), up the steps at its west end.
	var store := func(x: float, y: float, z: float) -> Vector3: return TownLayout.point(&"Store", Vector3(x, y, z))
	var store_set: Dictionary = TownLayout.entry(&"Store").get("set", {})
	var sw := float(store_set.get("width", 6.0))
	var store_steps: Array = (TownLayout.entry(&"Boardwalk").get("set", {}) as Dictionary).get("steps", [[sw * 0.5, 2.0]])
	var sx := float(store_steps[0][0])
	w.add(&"store_front", store.call(sx, 0, -7.0), [&"street_mid", &"street_west"])
	w.add(&"store_steps", store.call(sx, 0, -3.4), [&"store_front"])
	w.add(&"store_landing", store.call(sx, floor_top, -1.2), [&"store_steps"])
	w.add(&"store_porch", store.call(sw * 0.5, floor_top, -1.5), [&"store_landing"])
	w.add(&"store_door", store.call(sw * 0.5, floor_top, 0.9), [&"store_porch"])
	w.add(&"store_counter", store.call(sw - 1.85, floor_top, 3.7), [&"store_door"])
	w.add(&"store_aisle", store.call(sw * 0.5, floor_top, 6.3), [&"store_door", &"store_counter"])
	# A man walking behind the counter needs his shoulder clear of the wall's studs and his hip clear
	# of the counter (to w - 0.73) the whole way from the keeper's place.
	w.add(&"store_behind_counter", store.call(sw - 0.5, floor_top, 6.0), [&"store_aisle"])
	w.add(&"store_keeper", store.call(sw - 0.35, floor_top, 3.7), [&"store_behind_counter"])
	# The saloon (its door at x 5 in its own space, the front to -Z), up the steps at its east end.
	# Its floor and walk stand higher than the store's (config/town.json's Saloon), the two walks
	# joined by steps at the saloon walk's west end.
	var saloon := func(x: float, y: float, z: float) -> Vector3: return TownLayout.point(&"Saloon", Vector3(x, y, z))
	var saloon_top := float((TownLayout.entry(&"Saloon").get("set", {}) as Dictionary).get("floor_top", floor_top))
	var saloon_steps: Array = (TownLayout.entry(&"SouthBoardwalk").get("set", {}) as Dictionary).get("steps", [[5.0, 2.0]])
	var lx := float(saloon_steps[0][0])
	w.add(&"saloon_front", saloon.call(lx, 0, -7.0), [&"street_mid", &"street_east"])
	w.add(&"saloon_steps", saloon.call(lx, 0, -3.4), [&"saloon_front"])
	w.add(&"saloon_landing", saloon.call(lx, saloon_top, -1.2), [&"saloon_steps"])
	# Along the walk from the store's door to the saloon's (they stand side by side), up the steps
	# between the two walks.
	w.add(&"store_walk_east", store.call(sw - 0.5, floor_top, -1.3), [&"store_porch"])
	w.add(&"saloon_walk_west", saloon.call(1.3, saloon_top, -1.3), [&"store_walk_east"])
	w.add(&"saloon_porch", saloon.call(5, saloon_top, -1.5), [&"saloon_landing", &"saloon_walk_west"])
	w.add(&"saloon_door", saloon.call(5, saloon_top, 0.9), [&"saloon_porch"])
	w.add(&"saloon_floor", saloon.call(6.0, saloon_top, 3.5), [&"saloon_door"])
	# Along the bar: a line in front of the stools, and a place at the bar between each pair.
	for i in 3:
		var z := 4.45 + i * 1.3
		w.add(StringName("bar_front_%d" % i), saloon.call(6.2, saloon_top, z), [&"saloon_floor"] if i == 0 else [StringName("bar_front_%d" % (i - 1))])
		w.add(StringName("bar_%d" % i), saloon.call(7.05, saloon_top, z), [StringName("bar_front_%d" % i)])
	# Round the near end of the bar to the barkeep's side.
	w.add(&"bar_end", saloon.call(6.7, saloon_top, 2.3), [&"saloon_floor"])
	w.add(&"bar_end_inside", saloon.call(8.8, saloon_top, 2.3), [&"bar_end"])
	w.add(&"behind_bar", saloon.call(8.8, saloon_top, 5.8), [&"bar_end_inside"])
	return w
