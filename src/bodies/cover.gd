class_name Cover
## Finding cover the way a man does: look round for somewhere close that puts something solid
## between you and the man shooting at you, that you can get to, and that you can shoot back from.
## Works on any geometry (a trough, a barrel, a corner of the store, the boardwalk's edge): it
## samples spots in rings round him and tests each against the threat with rays.
##
## A spot is {at, low (bool: only covers him down low), crouch_ok (he can crouch there, not just
## duck), peek (where he shoots from), score}.

const DIRECTIONS := 20
const RADII := [1.2, 2.2, 3.5, 5.0, 7.0, 10.0]
## Heights (m) that matter, from HumanBody's poses: the top of his head ducked right down, and
## crouched on his heels; his chest ducked; the top of his head standing; his gun aimed standing
## and crouched.
const HIDE_HEAD := 0.97
const CROUCH_HEAD := 1.23
const CHEST := 0.64
const STAND_HEAD := 1.75
const GUN_HEIGHT := 1.46
const CROUCH_GUN := 0.9
## Lying flat behind it.
const LIE_HEAD := 0.42
const LIE_CHEST := 0.28
## How near the thing that blocks the shot must be, to count as his cover (not a far-off hill):
## within this, or (`far`, a man who knows the town) this share of the way to the threat, if it's
## wide (a building's corner a few metres off is cover from a man across the street; a crate there
## or the trough by the shooter's own knees is not).
const HUGGING := 1.6
const HUGGING_SHARE := 0.35
## A pace to the side (m): further-off cover has to hide him from there too.
const PACE := 0.8


## The best spot from `from` against a threat whose eye is at `threat_eye`. `exclude`: his own
## body. `bias_from`: a spot he's been using (flanking: prefer a new angle). {} if none.
static func find(world: Node3D, from: Vector3, threat_eye: Vector3, exclude: Array[RID], rng: RandomNumberGenerator,
		bias_from := Vector3.INF, max_travel := 11.0, places: Waypoints = null) -> Dictionary:
	var space := World.space(world)
	var best := {}
	var threat_flat := Vector3(threat_eye.x, from.y, threat_eye.z)
	var start_angle := rng.randf() * TAU
	var candidates: Array[Vector3] = []
	for r: float in RADII:
		if r > max_travel:
			break
		for i in DIRECTIONS:
			var ang := start_angle + TAU * i / DIRECTIONS
			candidates.append(from + Vector3(cos(ang), 0.0, sin(ang)) * r)
	candidates.append_array(_shadows(space, from, threat_eye, exclude, max_travel))
	candidates = _dedupe(candidates)
	return _best(space, candidates, from, threat_eye, threat_flat, exclude, rng, bias_from, 3.0, places)


## A search spread over several frames (the cover hunt is a few thousand rays): `step()` each
## physics tick until it returns true, then read `result`.
class Search:
	extends RefCounted
	var result := {}
	var _space: PhysicsDirectSpaceState3D
	var _cands: Array[Vector3] = []
	var _from: Vector3
	var _eye: Vector3
	var _flat: Vector3
	var _exclude: Array[RID]
	var _rng: RandomNumberGenerator
	var _bias: Vector3
	var _angle := 3.0
	var _places: Waypoints
	var _ctx := {}
	var _i := 0

	func step(per_tick := 120) -> bool:
		var chunk := _cands.slice(_i, _i + per_tick)
		_i += per_tick
		var best := Cover._best(_space, chunk, _from, _eye, _flat, _exclude, _rng, _bias, _angle, _places, _ctx)
		if not best.is_empty() and (result.is_empty() or best.score > result.score):
			result = best
		return _i >= _cands.size()


## `new_angle`: how much a spot at a new angle on the threat from `bias_from` counts (a man going
## round on him with friends keeping him busy wants it far more). `places`: the town's ways (a
## man who knows them goes up and down steps and in at doors: spots on another level, or inside,
## count, reached by them).
static func search(world: Node3D, from: Vector3, threat_eye: Vector3, exclude: Array[RID], rng: RandomNumberGenerator,
		bias_from := Vector3.INF, max_travel := 11.0, new_angle := 3.0, places: Waypoints = null) -> Search:
	var s := Search.new()
	s._space = World.space(world)
	s._from = from
	s._eye = threat_eye
	s._flat = Vector3(threat_eye.x, from.y, threat_eye.z)
	s._exclude = exclude
	s._rng = rng
	s._bias = bias_from
	s._angle = new_angle
	s._places = places
	var start_angle := rng.randf() * TAU
	for r: float in RADII:
		if r > max_travel:
			break
		for i in DIRECTIONS:
			var ang := start_angle + TAU * i / DIRECTIONS
			s._cands.append(from + Vector3(cos(ang), 0.0, sin(ang)) * r)
	s._cands.append_array(_shadows(s._space, from, threat_eye, exclude, max_travel))
	s._cands = _dedupe(s._cands)
	return s


static func _dedupe(points: Array[Vector3]) -> Array[Vector3]:
	var seen := {}
	var out: Array[Vector3] = []
	for p in points:
		var key := Vector2i(roundi(p.x / 0.2), roundi(p.z / 0.2))
		if not seen.has(key):
			seen[key] = true
			out.append(p)
	return out


static func _best(space: PhysicsDirectSpaceState3D, candidates: Array[Vector3], from: Vector3, threat_eye: Vector3,
		threat_flat: Vector3, exclude: Array[RID], rng: RandomNumberGenerator, bias_from: Vector3, new_angle := 3.0,
		places: Waypoints = null, ctx := {}) -> Dictionary:
	if places != null:
		return _best_in_town(space, candidates, from, threat_eye, threat_flat, exclude, rng, bias_from, new_angle, places, ctx)
	var best := {}
	for p in candidates:
		var r := Vector2(p.x - from.x, p.z - from.z).length()
		var spot := evaluate(space, p, threat_eye, exclude)
		if spot.is_empty():
			continue
		var way := route(space, from, spot.at, exclude)
		if way.is_empty():
			continue
		spot.route = way
		var d_threat: float = (spot.at as Vector3).distance_to(threat_flat)
		var spot_to := (spot.at as Vector3) - from
		# Not right under his gun, and not charging at him to get there.
		if d_threat < 5.0 or spot_to.dot((threat_flat - from).normalized()) > 3.0:
			continue
		var score := _score(spot, r, d_threat, from, threat_flat, rng, bias_from, new_angle)
		spot.score = score
		if best.is_empty() or score > best.score:
			best = spot
	return best


## As `_best`, for a man who knows the town's ways: each spot dropped onto the floor under it (up
## on the porch or down in the street), something wide a few metres off counted as cover, and the
## way there found best spot first (straight, round one thing, or by the town's places), so only
## the few best are routed.
static func _best_in_town(space: PhysicsDirectSpaceState3D, candidates: Array[Vector3], from: Vector3, threat_eye: Vector3,
		threat_flat: Vector3, exclude: Array[RID], rng: RandomNumberGenerator, bias_from: Vector3, new_angle: float,
		places: Waypoints, ctx: Dictionary) -> Dictionary:
	var scored: Array[Dictionary] = []
	for p0 in candidates:
		var floor_at: Variant = _floor_under(space, p0, exclude)
		if floor_at == null:
			continue
		var p: Vector3 = floor_at
		var spot := evaluate(space, p, threat_eye, exclude, true)
		if spot.is_empty():
			continue
		var r := Vector2(p.x - from.x, p.z - from.z).length()
		var d_threat: float = (spot.at as Vector3).distance_to(threat_flat)
		if d_threat < 5.0 or ((spot.at as Vector3) - from).dot((threat_flat - from).normalized()) > 3.0:
			continue
		spot.score = _score(spot, r, d_threat, from, threat_flat, rng, bias_from, new_angle)
		spot.r = r
		scored.append(spot)
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	# By the way there (OutlawBrain's variant D `way_cost`, Experiment B): the best few spots he can
	# get to, each scored on the way he'd run (round the end of the bar is 10 m for a spot 2 m off),
	# not the straight line.
	var by_way: bool = ctx.get("by_way", false)
	var best := {}
	var tries := 0
	for spot in scored:
		var way := route(space, from, spot.at, exclude)
		if way.is_empty():
			way = _town_way(space, from, spot.at, exclude, places, spot.r, ctx)
		if way.is_empty():
			continue
		spot.route = way
		if not by_way:
			spot.erase("r")
			return spot
		var run := _run_length(from, way)
		spot.way_m = run
		spot.score -= maxf(run - float(spot.r), 0.0) * WAY_COST
		spot.erase("r")
		if best.is_empty() or spot.score > best.score:
			best = spot
		tries += 1
		if tries >= WAY_TRIES:
			break
	return best


## With `by_way`: each metre the way there is longer than the straight line costs this much of a
## spot's score (as each metre of the straight line does, `_score`: -0.35), over the best this many
## spots he can reach.
const WAY_COST := 0.35
const WAY_TRIES := 8


static func _run_length(from: Vector3, way: Array) -> float:
	var length := 0.0
	var at := from
	for w: Vector3 in way:
		length += Vector2(w.x - at.x, w.z - at.z).length()
		at = w
	return length


static func _score(spot: Dictionary, r: float, d_threat: float, from: Vector3, threat_flat: Vector3, rng: RandomNumberGenerator,
		bias_from: Vector3, new_angle: float) -> float:
	var score := -r * 0.35 - absf(d_threat - 12.0) * 0.12 + rng.randf() * 0.6
	if not spot.low:
		score += 0.5  # a wall is better than a trough
	if spot.lie:
		score -= 0.4  # flat in the dirt is the worst of it
	if d_threat < 4.0:
		score -= 3.0  # not right on top of him
	# Don't run towards the gun to get there.
	var spot_at: Vector3 = spot.at
	var toward := (spot_at - from).normalized().dot((threat_flat - from).normalized())
	score -= maxf(toward, 0.0) * r * 0.25
	if bias_from != Vector3.INF:
		# Flanking: a new angle on him counts for a lot.
		var a0 := (bias_from - threat_flat).normalized()
		var a1 := (spot_at - threat_flat).normalized()
		score += clampf(1.0 - a0.dot(a1), 0.0, 1.0) * new_angle - (2.0 if (spot.at as Vector3).distance_to(bias_from) < 1.5 else 0.0)
	return score


## Spots just behind whatever stands between the threat and the ground round him: follow the
## threat's sight lines low past him and step in behind what they hit.
static func _shadows(space: PhysicsDirectSpaceState3D, from: Vector3, threat_eye: Vector3, exclude: Array[RID], max_travel: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for r: float in [1.5, 2.5, 3.5, 5.0, 7.0]:
		if r > max_travel + 1.0:
			break
		for i in 32:
			var ang := TAU * i / 32.0
			var target := from + Vector3(cos(ang), 0.0, sin(ang)) * r + Vector3.UP * 0.5
			var q := PhysicsRayQueryParameters3D.create(threat_eye, target + (target - threat_eye).normalized() * 3.0, Layers.WORLD)
			q.exclude = exclude
			Prof.count(&"q_cover")
			var hit := space.intersect_ray(q)
			if hit.is_empty() or hit.collider is CharacterBody3D:
				continue
			var at: Vector3 = hit.position
			if Vector2(at.x - from.x, at.z - from.z).length() > max_travel:
				continue
			var along := (at - threat_eye)
			along.y = 0.0
			along = along.normalized()
			# Through to its far side (a woodpile's a metre deep): a ray back from beyond it.
			var q2 := PhysicsRayQueryParameters3D.create(at + along * 4.0, at, Layers.WORLD)
			q2.exclude = exclude
			Prof.count(&"q_cover")
			var back_hit := space.intersect_ray(q2)
			if not back_hit.is_empty():
				at = back_hit.position
			var side := along.cross(Vector3.UP)
			for back: float in [0.35, 0.55]:
				for lateral: float in [0.0, 0.25, -0.25]:
					out.append(Vector3(at.x, from.y, at.z) + along * back + side * lateral)
	return out


## Is a spot any good? {} if not; else {at, low, crouch_ok, lie, peek}. `far`: something wide a few
## metres off counts as his cover too (a man who knows the town: OutlawBrain with its `places`).
static func evaluate(space: PhysicsDirectSpaceState3D, p: Vector3, threat_eye: Vector3, exclude: Array[RID], far := false) -> Dictionary:
	var ground: Variant = _ground(space, p, exclude)
	if ground == null:
		return {}
	var at: Vector3 = ground
	if absf(at.y - p.y) > 0.5:
		return {}
	# Cheapest first: one ray at his chest lying down; if that's seen, nothing here hides him.
	if not _blocked(space, at, threat_eye, LIE_CHEST, exclude, far):
		return {}
	if not _room(space, at, exclude):
		return {}
	var lie := false
	if not hidden_at(space, at, threat_eye, HIDE_HEAD, exclude, far) or not hidden_at(space, at, threat_eye, CHEST, exclude, far):
		# Too low to duck behind: flat on the ground, then.
		if not hidden_at(space, at, threat_eye, LIE_HEAD, exclude, far) or not hidden_at(space, at, threat_eye, LIE_CHEST, exclude, far):
			return {}
		lie = true
	var low := not hidden_at(space, at, threat_eye, STAND_HEAD, exclude, far)
	var crouch_ok := hidden_at(space, at, threat_eye, CROUCH_HEAD, exclude, far)
	var peek := Vector3.INF
	if low:
		# Rise up and shoot over it.
		if _sees(space, at + Vector3.UP * GUN_HEIGHT, threat_eye, exclude):
			peek = at
	else:
		# Step out past the edge of it.
		var to := threat_eye - at
		to.y = 0.0
		var side := to.normalized().cross(Vector3.UP)
		for k in [0.6, -0.6, 0.9, -0.9, 1.3, -1.3, 1.8, -1.8]:
			var q: Vector3 = at + side * float(k)
			var g: Variant = _ground(space, q, exclude)
			if g != null and _room(space, g, exclude) and _sees(space, (g as Vector3) + Vector3.UP * GUN_HEIGHT, threat_eye, exclude) \
					and path_clear(space, at, g, exclude):
				peek = g
				break
	if peek == Vector3.INF:
		return {}
	return {"at": at, "low": low, "peek": peek, "crouch_ok": crouch_ok, "lie": lie}


## Is a man at `at` hidden from the threat at this height, all of him (his shoulders either side,
## not just a line down his middle)? The shot has to be stopped close to him.
static func hidden_at(space: PhysicsDirectSpaceState3D, at: Vector3, threat_eye: Vector3, height: float, exclude: Array[RID], far := false) -> bool:
	var to := threat_eye - at
	to.y = 0.0
	var side := to.normalized().cross(Vector3.UP) if to.length() > 0.01 else Vector3.RIGHT
	for off in [0.0, SHOULDERS, -SHOULDERS]:
		if not _blocked(space, at + side * float(off), threat_eye, height, exclude, far):
			return false
	return true


## Half the width of a man, crouched.
const SHOULDERS := 0.18


static func _blocked(space: PhysicsDirectSpaceState3D, at: Vector3, threat_eye: Vector3, height: float, exclude: Array[RID], far := false) -> bool:
	var target := at + Vector3.UP * height
	var q := PhysicsRayQueryParameters3D.create(threat_eye, target, Layers.WORLD)
	q.exclude = exclude
	Prof.count(&"q_cover")
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return false
	var c: Object = hit.collider
	if c is CharacterBody3D:
		return false  # the shooter himself
	var d := (hit.position as Vector3).distance_to(target)
	if d < HUGGING:
		return true
	var reach := threat_eye.distance_to(target) * HUGGING_SHARE if far else 0.0
	if d >= reach:
		return false
	# Further off than arm's length: only something wide (a wall, a building's corner, not a crate
	# across the street), that still hides him from a pace either side of where the threat stands.
	var side := (target - threat_eye).cross(Vector3.UP)
	if side.length() < 0.01:
		return true
	side = side.normalized() * PACE
	for s: Vector3 in [side, -side]:
		var q2 := PhysicsRayQueryParameters3D.create(threat_eye + s, target, Layers.WORLD)
		q2.exclude = exclude
		Prof.count(&"q_cover")
		var h2 := space.intersect_ray(q2)
		if h2.is_empty() or h2.collider is CharacterBody3D or (h2.position as Vector3).distance_to(target) >= reach:
			return false
	return true


static func _sees(space: PhysicsDirectSpaceState3D, from: Vector3, threat_eye: Vector3, exclude: Array[RID]) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, threat_eye, Layers.WORLD)
	q.exclude = exclude
	Prof.count(&"q_cover")
	var hit := space.intersect_ray(q)
	return hit.is_empty() or hit.collider is CharacterBody3D or (hit.position as Vector3).distance_to(threat_eye) < 0.5


## Ground under a point (the floor, the boardwalk), or null.
static func _ground(space: PhysicsDirectSpaceState3D, p: Vector3, exclude: Array[RID]) -> Variant:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.6, p + Vector3.DOWN * 0.6, Layers.WORLD)
	q.exclude = exclude
	Prof.count(&"q_cover")
	var hit := space.intersect_ray(q)
	if hit.is_empty() or (hit.normal as Vector3).y < 0.7:
		return null
	return hit.position


## Room for a man there (nothing solid in his way from the knee to the chest).
static func _room(space: PhysicsDirectSpaceState3D, at: Vector3, exclude: Array[RID]) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = 0.22
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = Layers.WORLD
	q.exclude = exclude
	for h in [0.45, 0.95]:
		q.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * h)
		Prof.count(&"q_cover")
		if not space.intersect_shape(q, 1).is_empty():
			return false
	return true


## The floor under a point, a step up to a porch's height above it or below it (null if none).
static func _floor_under(space: PhysicsDirectSpaceState3D, p: Vector3, exclude: Array[RID]) -> Variant:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * LEVELS, p + Vector3.DOWN * LEVELS, Layers.STAND)
	q.exclude = exclude
	Prof.count(&"q_cover")
	var hit := space.intersect_ray(q)
	if hit.is_empty() or (hit.normal as Vector3).y < 0.7:
		return null
	return hit.position


## How far up or down (m) a spot may be from him when he knows the town's ways (a porch is 0.78).
const LEVELS := 1.0
## A way round by the town's ways may be this many times as long as the straight line, plus this.
const WAY_LONGER := 1.6
const WAY_EXTRA := 6.0
## ... or this much more for a man who'll run the long way round to it (OutlawBrain's variant D:
## round the end of a long bar to get behind it; Search's `ctx.way_extra`).
const WAY_EXTRA_FAR := 12.0
## The places nearest a spot he'll try reaching it from.
const TOWN_NEAREST := 4


## The way there by the town's places (in at the door, down the steps), if there's one not much
## longer than the straight line `r`; [] if not.
static func _town_way(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID], places: Waypoints,
		r: float, ctx: Dictionary) -> Array[Vector3]:
	# His ways to every place, worked out once a search (`ctx`).
	if not ctx.has("routes"):
		ctx.routes = places.routes_from(space, from, exclude)
	var routes: Dictionary = ctx.routes
	var near: Array = routes.keys()
	near.sort_custom(func(a: StringName, b: StringName) -> bool:
		return (places.points[a] as Vector3).distance_squared_to(to) < (places.points[b] as Vector3).distance_squared_to(to))
	var way: Array[Vector3] = []
	for n: StringName in near.slice(0, TOWN_NEAREST):
		var at_place: Vector3 = places.points[n]
		if absf(at_place.y - to.y) < 0.6 and Waypoints._walkable(space, at_place, to, exclude):
			way.assign(routes[n])
			way.append(to)
			break
	if way.is_empty():
		return []
	var length := 0.0
	var at := from
	for w in way:
		length += Vector2(w.x - at.x, w.z - at.z).length()
		at = w
	if length > r * WAY_LONGER + float(ctx.get("way_extra", WAY_EXTRA)):
		return []
	return way


## How to get there on foot: straight if he can, else round the thing in the way by one point
## off to the side. The points to walk through, ending at `to`; [] if there's no way.
static func route(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID]) -> Array[Vector3]:
	if path_clear(space, from, to, exclude):
		return [to]
	var flat := (to - from) * Vector3(1, 0, 1)
	var side := flat.normalized().cross(Vector3.UP)
	var mid := from + flat * 0.5
	for off: float in [1.2, -1.2, 2.0, -2.0, 3.0, -3.0]:
		var wp := mid + side * off
		var g: Variant = _ground(space, wp, exclude)
		if g == null:
			continue
		wp = g
		if path_clear(space, from, wp, exclude) and path_clear(space, wp, to, exclude):
			return [wp, to]
	return []


## Can he get from one spot to the other on foot, in a straight line?
static func path_clear(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID], radius := 0.22) -> bool:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = Layers.WORLD
	q.exclude = exclude
	q.transform = Transform3D(Basis.IDENTITY, from + Vector3.UP * 0.75)
	q.motion = (to - from) * Vector3(1, 0, 1)
	Prof.count(&"q_cover")
	var frac := space.cast_motion(q)
	return frac[0] >= 0.98
