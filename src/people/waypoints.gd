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


## A man (a little wider than he is, to clear door jambs) can walk it in a straight line.
static func _walkable(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, exclude: Array[RID]) -> bool:
	return Cover.path_clear(space, a, b, exclude, WIDTH)


## Half the width a man needs to get through somewhere without catching his shoulder.
const WIDTH := 0.3


## The places on the test street: the saloon (its bar and the room behind it), the store (the
## counter, and behind it), their doors and porches, the street itself and the road out west.
static func test_street() -> Waypoints:
	var w := Waypoints.new()
	# The street, east to west down the middle.
	w.add(&"west_edge", Vector3(-38, 0, -9))
	w.add(&"street_west", Vector3(-14, 0, -9), [&"west_edge"])
	w.add(&"street_mid", Vector3(3, 0, -9), [&"street_west"])
	w.add(&"street_east", Vector3(15, 0, -9), [&"street_mid"])
	# The store (at the origin, front to -Z, the door at x 3).
	w.add(&"store_porch", Vector3(3, 0.38, -1.2), [&"street_mid"])
	w.add(&"store_door", Vector3(3, 0.38, 0.9), [&"store_porch"])
	w.add(&"store_counter", Vector3(4.15, 0.38, 3.7), [&"store_door"])
	w.add(&"store_aisle", Vector3(3.0, 0.38, 6.3), [&"store_door", &"store_counter"])
	w.add(&"store_behind_counter", Vector3(5.65, 0.38, 6.0), [&"store_aisle"])
	w.add(&"store_keeper", Vector3(5.65, 0.38, 3.7), [&"store_behind_counter"])
	# The saloon (turned to face the street, the door at x 7).
	w.add(&"saloon_porch", Vector3(7, 0.38, -15.3), [&"street_mid", &"street_east"])
	w.add(&"saloon_door", Vector3(7, 0.38, -17.7), [&"saloon_porch"])
	w.add(&"saloon_floor", Vector3(6.0, 0.38, -20.3), [&"saloon_door"])
	# Along the bar: a line in front of the stools, and a place at the bar between each pair.
	for i in 3:
		var z := -21.25 - i * 1.3
		w.add(StringName("bar_front_%d" % i), Vector3(5.8, 0.38, z), [&"saloon_floor"] if i == 0 else [StringName("bar_front_%d" % (i - 1))])
		w.add(StringName("bar_%d" % i), Vector3(4.95, 0.38, z), [StringName("bar_front_%d" % i)])
	# Round the near end of the bar to the barkeep's side.
	w.add(&"bar_end", Vector3(5.3, 0.38, -19.1), [&"saloon_floor"])
	w.add(&"bar_end_inside", Vector3(3.2, 0.38, -19.1), [&"bar_end"])
	w.add(&"behind_bar", Vector3(3.2, 0.38, -22.6), [&"bar_end_inside"])
	return w
