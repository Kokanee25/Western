class_name FireFlight
extends RefCounted
## Getting clear of a fire: where to go and the way there, for anyone on foot (CivilianBrain,
## OutlawBrain). The places tried are the town's street places (by the town's ways) and points out
## in every direction he can walk straight to; a good one is clear of any fire by `clear` m and reached by a way that never passes within
## `PATH_GAP` m of the burning; the nearest such wins. If there's none, the way that stays clear of
## the burning and ends furthest from it; failing that, just the furthest. Worked out on the fire's
## map of where it's burning seen from above (`FireSystem.burning_map()`, 2 m squares), so a dozen
## people can do it in the same breath in a burning town.

## How near the burning a way may pass, and how often (m) along it that's checked.
const PATH_GAP := 3.0
const PATH_STEP := 2.0
## Straight-out points tried round him: this many directions, at these distances.
const DIRECTIONS := 8
const OUT := [9.0, 18.0]


## The way (points to walk through, the last the place) away from the fire.
static func way_out(fire: FireSystem, places: Waypoints, body: HumanBody, clear: float) -> Array[Vector3]:
	var map := fire.burning_map()
	var me := body.global_position
	var ways: Array = []  # [way, place]
	if body.is_inside_tree():
		var space := body.get_world_3d().direct_space_state
		if places:
			var routes := places.routes_from(space, me, exclude(body))
			for n: StringName in routes:
				var p: Vector3 = places.points[n]
				if p.y < 0.2:  # out on the street, not in a building or on a porch
					ways.append([routes[n], p])
		# Straight out across open ground, where nothing's in the way.
		for i in DIRECTIONS:
			var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU * i / DIRECTIONS)
			for d: float in OUT:
				var c := Vector3(me.x, 0.0, me.z) + dir * d
				if Waypoints._walkable(space, me, c, exclude(body)):
					ways.append([[c] as Array[Vector3], c])
	if ways.is_empty():
		var away := Vector3(me.x, 0.0, me.z) + Vector3.FORWARD.rotated(Vector3.UP, body.rng_seed * 2.4) * OUT[-1]
		return [away]
	var best: Array[Vector3] = []
	var best_len := INF
	var fallback: Array[Vector3] = []
	var fallback_far := -1.0
	var furthest: Array[Vector3] = []
	var furthest_far := -1.0
	for w: Array in ways:
		var way: Array[Vector3] = w[0]
		var far := distance(map, w[1], clear)
		var length := 0.0
		var near_fire := false
		var prev := me
		for pt in way:
			var seg := prev.distance_to(pt)
			length += seg
			var steps := maxi(1, ceili(seg / PATH_STEP))
			for k in range(1, steps + 1):
				if distance(map, prev.lerp(pt, float(k) / steps), PATH_GAP) < PATH_GAP:
					near_fire = true
					break
			if near_fire:
				break
			prev = pt
		if not near_fire and far >= clear:
			if length < best_len:
				best_len = length
				best = way
		elif not near_fire:
			if far > fallback_far:
				fallback_far = far
				fallback = way
		elif far > furthest_far:
			furthest_far = far
			furthest = way
	if not best.is_empty():
		return best
	return fallback if not fallback.is_empty() else furthest


## How far from `at` to the nearest burning square, up to `reach` (`reach` if none that near).
static func distance(map: Dictionary, at: Vector3, reach: float) -> float:
	if map.is_empty():
		return reach
	var cell := FireSystem.MAP_CELL
	var c := Vector2i(floori(at.x / cell), floori(at.z / cell))
	var r := ceili(reach / cell)
	var best := reach
	for x in range(c.x - r, c.x + r + 1):
		for z in range(c.y - r, c.y + r + 1):
			if map.has(Vector2i(x, z)):
				# To the nearest point of that square.
				var nx := clampf(at.x, x * cell, (x + 1) * cell)
				var nz := clampf(at.z, z * cell, (z + 1) * cell)
				best = minf(best, Vector2(at.x - nx, at.z - nz).length())
	return best


## The way to a point: along the town's places where he can't walk straight there.
static func route(places: Waypoints, body: HumanBody, point: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if places and body.is_inside_tree():
		out = places.route_to_point(body.get_world_3d().direct_space_state, body.global_position, point, exclude(body))
	if out.is_empty():
		out.append(point)
	return out


static func exclude(body: HumanBody) -> Array[RID]:
	var out: Array[RID] = []
	for sid: StringName in body.parts:
		out.append((body.parts[sid] as CollisionObject3D).get_rid())
	return out
