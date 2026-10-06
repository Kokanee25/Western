class_name BucketLine
extends Node3D
## A bucket brigade (DESIGN.md §8 fire: bucket lines from the trough). The townsfolk fighting a
## fire from one water source stand in a line along the way from the water to the fire; the man
## at the water fills a bucket, it's handed up the line man to man (where the gap's wider than a
## man can reach across, he walks it to the next and comes back), the man at the fire throws it,
## and the empty comes back down the line the same way. A full bucket going up and an empty
## coming down meet and the two men swap them. The buckets are things in their hands: drawn,
## carried, passed, slopping water when full.
##
## One line a water source. A CivilianBrain fighting a fire joins the line for the nearest water
## (BucketLine.join), and the line drives his body from then on: where he stands, what he holds,
## what he does with it. He leaves when he's scorched, hurt past standing, or it's out; with nobody
## left the line is gone and its buckets are set down where they were.
##
## Alone, a man is his own line: he carries the bucket to the fire, throws it and walks back.

## A bucket handed across this far (m, hand to hand); further, it's walked.
const PASS_REACH := 1.4
## Seconds to hand it over, to fill it at the water, to throw it.
const PASS_TIME := 0.45
const FILL_TIME := 1.5
const THROW_TIME := 0.6
const LITRES := 10.0
## The closest men stand (m): more than fit, the rest wait off the end of the line.
const MIN_SPACING := 0.9
## A man at the fire throws at what's burning within this of him.
const THROW_REACH := 3.7
## A man who can't get to his place in this long (s: caught on something, the way round too long)
## drops out, and the line closes up.
const GIVE_UP := 30.0
## Near enough his place to be in it (m).
const IN_PLACE := 0.9
## Where the man at the fire stands, off the nearest burning (m).
const THROW_STAND := 2.2
## A man stands no higher than this (m: a walk or a floor, not a porch roof the fire's climbed to),
## and a spot up on a walk counts this much further from the water (m) than one in the street (the
## way up is by its steps, often round).
const STAND_HIGHEST := 1.0
const RAISED_COST := 3.0
## The fire's nearest burning is looked for this far from the water (m); none: it's out.
const WATER_REACH := 40.0
## How often the line looks again at where the fire is (s): it's laid out again only when the man at
## the fire can't reach any of it from where he stands.
const RELAY_EVERY := 3.0
const WALK_SPEED := 1.6
const RUN_SPEED := 3.2
## One bucket a this many men (the man at the water starts with them).
const MEN_A_BUCKET := 2

var water: Node3D
var fire: FireSystem
## Where the man at the water stands, and where the man at the fire does.
var water_spot := Vector3.INF
var throw_spot := Vector3.INF
var links: Array[CivilianBrain] = []
## Where each man stands (one per man, from the water to the fire).
var slots: Array[Vector3] = []
## Per man: the bucket he holds (its index in `buckets`, -1 none), what he's doing and how long
## it's left (&"" nothing, &"fill", &"throw", &"pass"), and his way to his place.
var holding: Array[int] = []
var action: Array[StringName] = []
var action_left: Array[float] = []
var _ways: Array = []
var _stuck: Array[float] = []
## Seconds each man's been on his way to his place; past GIVE_UP he drops out.
var _late: Array[float] = []
## Empty buckets lying by the water, for the man there.
var pile: Array[int] = []
var _last: Array[Vector3] = []
## Each bucket: {node, full, passing: [from link, to link, t] or []}.
var buckets: Array[Dictionary] = []
var _relay := 0.0
var thrown := 0  ## buckets thrown on the fire
var passed := 0  ## hand-overs (a swap counts two)


## The line for the water nearest a fire (a new one if there's none), with `brain` in it.
static func join(brain: CivilianBrain, water_source: Node3D, fire_system: FireSystem, fire_at: Vector3) -> BucketLine:
	var tree := brain.get_tree()
	var line: BucketLine = null
	for l: Node in tree.get_nodes_in_group(&"bucket_lines"):
		if (l as BucketLine).water == water_source:
			line = l
			break
	if line == null:
		line = BucketLine.new()
		line.name = "BucketLine"
		line.water = water_source
		line.fire = fire_system
		var street := fire_system.get_parent() if fire_system.get_parent() else tree.current_scene
		street.add_child(line)
		line._lay_out(fire_at)
	line._add(brain)
	return line


func _ready() -> void:
	add_to_group(&"bucket_lines")


## Room for him: a line can't be crowded closer than MIN_SPACING.
func has_room() -> bool:
	return links.size() < maxi(int(_length() / MIN_SPACING) + 1, 2)


func _add(brain: CivilianBrain) -> void:
	# A man joining goes in next to the man at the water (the water end's where buckets start),
	# the rest moving up a place.
	var at := 1 if links.size() >= 1 else 0
	_shift_passes(at, 1)
	links.insert(at, brain)
	holding.insert(at, -1)
	action.insert(at, &"")
	action_left.insert(at, 0.0)
	_ways.insert(at, [])
	_stuck.insert(at, 0.0)
	_last.insert(at, Vector3.INF)
	_late.insert(at, 0.0)
	# New buckets with the new hands: a pile of them by the water, the man there taking the next.
	while buckets.size() < maxi(1, ceili(float(links.size()) / MEN_A_BUCKET)):
		buckets.append({"node": _bucket_node(), "full": false, "passing": []})
		pile.append(buckets.size() - 1)
	_place_slots()
	_draw_pile()


## He leaves the line (scorched, hurt, called off): what he held is set down where he is.
func leave(brain: CivilianBrain) -> void:
	var i := links.find(brain)
	if i < 0:
		return
	if holding[i] >= 0:
		_set_down(holding[i])
	# A bucket on its way to or from him lands with him.
	for b in buckets.size():
		var p: Array = buckets[b].passing
		if not p.is_empty() and (p[0] == i or p[1] == i):
			buckets[b].passing = []
			if p[1] == i:
				_set_down(b)
	_shift_passes(i + 1, -1)
	links.remove_at(i)
	holding.remove_at(i)
	action.remove_at(i)
	action_left.remove_at(i)
	_ways.remove_at(i)
	_stuck.remove_at(i)
	_late.remove_at(i)
	_last.remove_at(i)
	if links.is_empty():
		disband()
		return
	_place_slots()


## Men from `from` on move `by` places (one joining or leaving): buckets on their way between
## them follow.
func _shift_passes(from: int, by: int) -> void:
	for b in buckets.size():
		var p: Array = buckets[b].passing
		if p.is_empty():
			continue
		for k in 2:
			if int(p[k]) >= from:
				p[k] = int(p[k]) + by


## Nobody left, or it's out: the buckets are set down and the line's gone.
func disband() -> void:
	for brain in links.duplicate():
		if is_instance_valid(brain):
			brain.left_line()
	links.clear()
	for b in buckets.size():
		_set_down(b)
	queue_free()


func _set_down(b: int) -> void:
	var node: Node3D = buckets[b].node
	if node == null or not is_instance_valid(node):
		return
	var at := node.global_position
	at.y = 0.0
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			node.global_position + Vector3.UP * 0.2, node.global_position + Vector3.DOWN * 3.0, Layers.WORLD))
	if not hit.is_empty():
		at = hit.position
	node.global_transform = Transform3D(Basis(), at)
	_show_water(b, false)
	buckets[b].full = false
	for i in holding.size():
		if holding[i] == b:
			holding[i] = -1
	pile.erase(b)
	buckets[b]["down"] = true


# --- Laying it out -----------------------------------------------------------------------------

## The water end beside the water on the fire's side; the fire end a couple of paces off the
## nearest burning, on the water's side; the way between them by the town's places.
func _lay_out(fire_at: Vector3) -> void:
	water_spot = CivilianBrain.water_side(water, fire_at)
	throw_spot = _stand_by(fire_at)
	_place_slots()


## Where a man can stand a couple of paces off a burning point to throw at it: of eight spots round
## it, those he can stand on (the street, a walk, a floor: found by a ray down from head height, so
## never a roof the fire has climbed to) and not inside anything, the one nearest the water, the
## street before a walk.
func _stand_by(fire_at: Vector3) -> Vector3:
	var away := water_spot - fire_at
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	var fallback := Vector3(fire_at.x, water_spot.y, fire_at.z) + away * THROW_STAND
	if not is_inside_tree():
		return fallback
	var space := get_world_3d().direct_space_state
	var best := fallback
	var best_d := INF
	var probe := SphereShape3D.new()
	probe.radius = 0.25
	for k in 8:
		var dir := Vector3(cos(TAU * k / 8.0), 0.0, sin(TAU * k / 8.0))
		var p := Vector3(fire_at.x, 0.0, fire_at.z) + dir * THROW_STAND
		var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, STAND_HIGHEST + 0.8, p.z), Vector3(p.x, -1.0, p.z), Layers.WORLD))
		if down.is_empty() or (down.normal as Vector3).y < 0.7:
			continue
		var stand: Vector3 = down.position
		if stand.y > STAND_HIGHEST:
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = probe
		q.collision_mask = Layers.WORLD
		q.transform = Transform3D(Basis(), stand + Vector3.UP * 0.9)
		if not space.intersect_shape(q, 1).is_empty():
			continue  # inside a wall
		var d := stand.distance_to(water_spot) + (RAISED_COST if stand.y > 0.15 else 0.0)
		if d < best_d:
			best_d = d
			best = stand
	return best


var _path: Array[Vector3] = []


func _place_slots() -> void:
	if water_spot == Vector3.INF:
		return
	_path = [water_spot]
	var town := get_tree().get_first_node_in_group(&"town_life") if is_inside_tree() else null
	var places: Waypoints = town.get(&"places") if town else null
	if places and is_inside_tree():
		_path.append_array(places.route_to_point(get_world_3d().direct_space_state, water_spot, throw_spot))
	else:
		_path.append(throw_spot)
	slots.clear()
	var n := links.size()
	if n <= 1:
		slots.append(water_spot)
	else:
		var length := _length()
		var gap := length / (n - 1)
		for i in n:
			slots.append(_along(minf(gap * i, length)))


func _length() -> float:
	var total := 0.0
	for k in range(1, _path.size()):
		total += _path[k - 1].distance_to(_path[k])
	return total


func _along(d: float) -> Vector3:
	for k in range(1, _path.size()):
		var seg := _path[k - 1].distance_to(_path[k])
		if d <= seg or k == _path.size() - 1:
			return _path[k - 1].lerp(_path[k], clampf(d / maxf(seg, 0.001), 0.0, 1.0))
		d -= seg
	return _path[-1] if not _path.is_empty() else water_spot


# --- Working it ----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if fire == null or not is_instance_valid(fire) or water == null or not is_instance_valid(water):
		disband()
		return
	# Anyone who can't go on leaves.
	for brain in links.duplicate():
		if not is_instance_valid(brain) or brain.body == null or not brain.body.physiology.can_stand():
			leave(brain)
			if not is_inside_tree() or links.is_empty():
				return
	_relay -= delta
	if _relay <= 0.0:
		_relay = RELAY_EVERY
		var near := fire.fire_near(water_spot, WATER_REACH)
		if near.count == 0:
			if not links.is_empty():
				links[links.size() - 1].say(&"out")
			disband()
			return
		if throw_spot == Vector3.INF or fire.fire_near(throw_spot, THROW_REACH).count == 0:
			_lay_out(near.at)
	_move_buckets(delta)
	var i := 0
	while i < links.size():
		var who := links[i]
		_work(i, delta)
		if not is_inside_tree() or links.is_empty():
			return
		if i < links.size() and links[i] == who:
			i += 1  # (a man who dropped out: the next is in his place now)
	_draw_buckets()


## A bucket's going up the line (full) or down it (empty).
func _heading(b: int) -> int:
	return 1 if buckets[b].full else -1


func _work(i: int, delta: float) -> void:
	var brain := links[i]
	var body := brain.body
	var n := links.size()
	if action[i] != &"":
		action_left[i] -= delta
		_pose_for(i)
		if action_left[i] > 0.0:
			return
		_finish(i)
		return
	var b := holding[i]
	if n == 1:
		# Alone: carry it to the fire, throw, back to the water.
		if b < 0:
			if not pile.is_empty() and (_at_water(i) or _go(i, water_spot, WALK_SPEED, delta)):
				holding[i] = pile.pop_back()
				_draw_pile()
			return
		if buckets[b].full:
			if _go(i, throw_spot, WALK_SPEED, delta):
				_start(i, &"throw", THROW_TIME)
		elif _at_water(i) or _go(i, water_spot, WALK_SPEED, delta):
			_start(i, &"fill", FILL_TIME)
		return
	var placed := _in_place(i)
	if not placed and b < 0:
		_late[i] += delta
		if _late[i] > GIVE_UP:
			var gone := links[i]
			leave(gone)
			gone.left_line(60.0)
			return
		_go(i, slots[i], WALK_SPEED, delta)
		return
	_late[i] = 0.0
	if b < 0:
		# The man at the water takes the next bucket off the pile.
		if i == 0 and not pile.is_empty():
			holding[i] = pile.pop_back()
			_draw_pile()
			return
		_go(i, slots[i], WALK_SPEED, delta)
		_face_along(i, -1 if i > 0 else 1)
		return
	var full: bool = buckets[b].full
	if not full and i == 0:
		if _at_water(i) or _go(i, slots[0], WALK_SPEED, delta):
			_start(i, &"fill", FILL_TIME)
		return
	if full and i == n - 1:
		if _go(i, slots[i], WALK_SPEED, delta):
			_start(i, &"throw", THROW_TIME)
		return
	var j := i + _heading(b)
	if j < 0 or j >= n:
		return
	if not _in_place(j) or not _can_take(j, i):
		# He waits at his place, facing the way it's going.
		_go(i, slots[i], WALK_SPEED, delta)
		_face_along(i, _heading(b))
		return
	if body.global_position.distance_to(links[j].body.global_position) <= PASS_REACH:
		_hand(i, j)
	else:
		# Too far to hand across: he walks it to him (to his place: the man there stays put).
		var toward := slots[j] - slots[i]
		toward.y = 0.0
		var meet := slots[j] - toward.normalized() * PASS_REACH * 0.7 if toward.length() > 0.01 else slots[j]
		_go(i, meet, WALK_SPEED, delta, 0.3)


func _in_place(i: int) -> bool:
	var p := links[i].body.global_position
	return Vector2(p.x - slots[i].x, p.z - slots[i].z).length() <= IN_PLACE


## The buckets in the pile, set down by the water.
func _draw_pile() -> void:
	for k in pile.size():
		var node: Node3D = buckets[pile[k]].node
		if node and is_instance_valid(node):
			var off := Vector3((k % 3) * 0.32 - 0.32, 0.0, (k / 3) * 0.32)
			node.global_transform = Transform3D(Basis(), water_spot + off)


## Can man j take a bucket from man i now: hands free, or his own bucket's going i's way (a swap).
func _can_take(j: int, i: int) -> bool:
	if action[j] != &"":
		return false
	var b := holding[j]
	if b < 0:
		return true
	return j + _heading(b) == i


func _hand(i: int, j: int) -> void:
	var b := holding[i]
	buckets[b].passing = [i, j, 0.0]
	holding[i] = -1
	_start(i, &"pass", PASS_TIME)
	if holding[j] >= 0:
		var c := holding[j]
		buckets[c].passing = [j, i, 0.0]
		holding[j] = -1
		passed += 1
	_start(j, &"pass", PASS_TIME)
	passed += 1


func _start(i: int, what: StringName, seconds: float) -> void:
	action[i] = what
	action_left[i] = seconds
	_pose_for(i)


func _finish(i: int) -> void:
	var what := action[i]
	action[i] = &""
	var brain := links[i]
	match what:
		&"fill":
			var b := holding[i]
			if b >= 0:
				buckets[b].full = true
				_show_water(b, true)
				Events.noise.emit(brain.body.global_position, 6.0, &"fill", brain.body)
		&"throw":
			var b := holding[i]
			if b >= 0:
				var near := fire.fire_near(brain.body.global_position, THROW_REACH)
				if near.count > 0:
					fire.douse(near.at, 0.6, LITRES)
				thrown += 1
				buckets[b].full = false
				_show_water(b, false)
				Events.noise.emit(brain.body.global_position, 10.0, &"splash", brain.body)
	brain.body.set_pose(&"stand")


func _move_buckets(delta: float) -> void:
	for b in buckets.size():
		var p: Array = buckets[b].passing
		if p.is_empty():
			continue
		p[2] = float(p[2]) + delta / PASS_TIME
		if p[2] >= 1.0:
			buckets[b].passing = []
			var to: int = p[1]
			if to < holding.size() and holding[to] == -1:
				holding[to] = b
			else:
				_set_down(b)


## Each bucket in its holder's right hand, or on its way between two hands.
func _draw_buckets() -> void:
	for b in buckets.size():
		var node: Node3D = buckets[b].node
		if node == null or not is_instance_valid(node) or buckets[b].get("down", false) or b in pile:
			continue
		var p: Array = buckets[b].passing
		var at := Vector3.INF
		if not p.is_empty() and p[0] < links.size() and p[1] < links.size():
			var t := smoothstep(0.0, 1.0, float(p[2]))
			at = _hand_of(p[0]).lerp(_hand_of(p[1]), t) + Vector3.UP * sin(t * PI) * 0.12
		else:
			for i in holding.size():
				if holding[i] == b:
					at = _hand_of(i)
		if at != Vector3.INF:
			node.global_transform = Transform3D(Basis(), at - Vector3.UP * 0.32)


func _hand_of(i: int) -> Vector3:
	var body := links[i].body
	var hand: Node3D = body.parts.get(&"hand_r")
	return hand.global_position if hand else body.global_position + Vector3.UP * 0.8


func _pose_for(i: int) -> void:
	var body := links[i].body
	match action[i]:
		&"fill":
			body.set_pose(&"crouch")
			body.face(water.global_position)
		&"throw":
			body.set_pose(&"shove")
			var near := fire.fire_near(body.global_position, THROW_REACH + 2.0)
			if near.count > 0:
				body.face(near.at)
		&"pass":
			body.set_pose(&"shove")
		_:
			body.set_pose(&"stand")


## Walks him toward a point (round things, by the town's places when it's far); true there.
func _go(i: int, to: Vector3, speed: float, delta: float, within := 0.35) -> bool:
	var body := links[i].body
	var flat := Vector3(to.x - body.global_position.x, 0.0, to.z - body.global_position.z)
	if flat.length() <= within:
		return true
	var way: Array = _ways[i]
	if way.is_empty() or (way[-1] as Vector3).distance_to(to) > 0.5:
		way = FireFlight.route(links[i]._places(), body, to) if flat.length() > 3.0 else [to]
		_ways[i] = way
	body.set_pose(&"stand")
	# Caught on something low (the trough, a rail): a sidestep round it, one way then the other.
	if body.global_position.distance_to(_last[i]) < 0.2 * speed * delta:
		_stuck[i] += delta
	else:
		_stuck[i] = maxf(_stuck[i] - delta, 0.0)
	_last[i] = body.global_position
	if _stuck[i] > 0.8:
		_stuck[i] = 0.0
		var ahead: Vector3 = (way[0] as Vector3) - body.global_position
		ahead.y = 0.0
		# One way or the other, by where he is (the same each run).
		var flip := 1.0 if posmod(int(body.global_position.x * 10.0) + i, 2) == 0 else -1.0
		var side := Vector3(-ahead.z, 0.0, ahead.x).normalized() * flip
		way.push_front(body.global_position + side * 1.2 + ahead.normalized() * 0.3)
	if body.walk_to(way[0], speed, delta):
		way.pop_front()
		if way.is_empty():
			return Vector3(to.x - body.global_position.x, 0.0, to.z - body.global_position.z).length() <= within + 0.2
	return false


## Near enough the water to dip a bucket in it (either side of a trough, round a well).
func _at_water(i: int) -> bool:
	var w := water.get_node_or_null(^"Water") as Node3D
	var centre := w.global_position if w else water.global_position
	var length := float(water.get(&"length")) if water.get(&"length") != null else 2.0
	var width := float(water.get(&"trough_width")) if water.get(&"trough_width") != null else 0.65
	var local := water.global_transform.affine_inverse() * links[i].body.global_position
	var wl := water.global_transform.affine_inverse() * centre
	var dx := maxf(absf(local.x - wl.x) - length * 0.5, 0.0)
	var dz := maxf(absf(local.z - wl.z) - width * 0.5, 0.0)
	return Vector2(dx, dz).length() <= 0.9


## Facing up the line (+1) or down it (-1) from his place.
func _face_along(i: int, way: int) -> void:
	var j := clampi(i + way, 0, links.size() - 1)
	if j != i:
		links[i].body.face(links[j].body.global_position + Vector3.UP * 1.2)


# --- The bucket ----------------------------------------------------------------------------------

## A wooden bucket: staves, two iron hoops, a bail, and water in it when it's full.
func _bucket_node() -> Node3D:
	var root := Node3D.new()
	root.name = "Bucket"
	add_child(root)
	var staves := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.12
	cyl.height = 0.3
	cyl.radial_segments = 10
	cyl.rings = 1
	staves.mesh = cyl
	staves.position.y = 0.15
	staves.material_override = WoodMaterials.get_material(&"framing", 1)
	root.add_child(staves)
	for k in 2:
		var hoop := MeshInstance3D.new()
		var band := CylinderMesh.new()
		band.top_radius = (0.123 + 0.027 * (0.25 + k * 0.5)) + 0.006
		band.bottom_radius = band.top_radius - 0.003
		band.height = 0.025
		band.radial_segments = 10
		band.rings = 1
		hoop.mesh = band
		hoop.position.y = 0.3 * (0.25 + k * 0.5)
		hoop.material_override = WoodMaterials.get_material(&"iron", 0)
		root.add_child(hoop)
	var bail := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.14
	ring.outer_radius = 0.155
	ring.rings = 12
	ring.ring_segments = 4
	bail.mesh = ring
	bail.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	bail.position.y = 0.3
	bail.material_override = WoodMaterials.get_material(&"iron", 0)
	root.add_child(bail)
	var surface := MeshInstance3D.new()
	surface.name = "Water"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.135
	disc.bottom_radius = 0.135
	disc.height = 0.01
	disc.radial_segments = 10
	disc.rings = 1
	surface.mesh = disc
	surface.position.y = 0.26
	surface.material_override = WoodMaterials.water()
	surface.visible = false
	root.add_child(surface)
	return root


func _show_water(b: int, full: bool) -> void:
	var node: Node3D = buckets[b].node
	if node and is_instance_valid(node):
		var w := node.get_node_or_null(^"Water") as Node3D
		if w:
			w.visible = full
