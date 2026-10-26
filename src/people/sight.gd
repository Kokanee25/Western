class_name Sight
## The sight service (docs/briefs/more-cores.md step 3, "The design" A): what a man can see, what
## hides him, which lamp reaches him, asked of `SightWorld` in the native plugin instead of Jolt.
## SightWorld keeps a copy of every body on the sight layers (the world and the walking ramps) as
## the physics server holds it, and answers a batch of lines in one call, across its threads.
## Balls, feet, falling bodies and a man's room to stand still ask Jolt, the truth for what
## touches what.
##
## It's fed by the tree: a body on the sight layers that enters it is taken at the next question,
## one that leaves it is let go, and one whose shapes are added, taken away or moved round it
## (a member gone to rubble, a carved one at rest again) is taken again. What moves without the
## tree knowing tells it (`changed`): the physics' own movers (rubble, the player) are placed
## again once a physics frame; a kit prop set down, the horse's shapes on his bones, a pane gone,
## the ground dug say so. A carved member keeps its box until something takes it again, so a line
## through a carved hole is the one place it can differ from Jolt (`tests/test_sight_world.gd`
## counts them).
##
## Without the plugin (the web export), or with `--jolt-sight` (the before, for the labs), every
## question goes to Jolt as before: the same answers, the old cost.

## What the game says a body is, for what a line met (`kind`).
const KIND_OTHER := 0
const KIND_MEMBER := 1
const KIND_GROUND := 2
## The player's capsule (Senses and Cover see through the shooter himself).
const KIND_CHARACTER := 3
## Rubble, a loose prop: moved by the physics.
const KIND_RIGID := 4

## The layers it holds.
const LAYERS := Layers.WORLD | Layers.WALK

static var enabled: bool = ClassDB.class_exists(&"SightWorld") and not "--jolt-sight" in OS.get_cmdline_user_args()

## One SightWorld a physics space (the game's world; a preview's, if one ever asks).
static var _worlds := {}
## ... and by its direct space state's instance id (Cover asks by the state).
static var _by_state := {}
static var _hooked := false
## Bodies to take (again) at the next question, and those to take at the first question of the
## next physics frame (after the frame's deferred calls and moves have reached the server).
static var _now: Array = []
static var _next: Array = []
## The kinds of hit kept from the last `ray` and `lines`.
static var _last_kind := PackedInt32Array()
static var _last_ids := PackedInt64Array()
static var _last_normals := PackedVector3Array()


class _World:
	extends RefCounted
	var native: Object
	var space: RID
	## body id -> the body, for what a line met.
	var bodies := {}
	var frame := -1


# --- Asking -------------------------------------------------------------------------------------

## The first thing on `mask` along `from`..`to` (`exclude`: bodies to see past), as Jolt's
## `intersect_ray` gives it: {} for nothing, else {position, normal, rid, kind}. `world`: any node
## in the world asked about, or its space (`World.space(node)`, as Cover passes it).
static func ray(world: Object, from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
	var t := cast(world, from, to, mask, exclude)
	if t >= 1.0:
		return {}
	return {"position": from + (to - from) * t, "normal": hit_normal(), "rid": hit_body(), "kind": hit_kind()}


## The fraction along `from`..`to` where it first meets something on `mask` (1.0 for nothing);
## what it met in `hit_kind()`, `hit_normal()`, `hit_body()`. The cheap way to ask one line.
static func cast(world: Object, from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> float:
	var w: _World = _world_of(world) if enabled else null
	if w == null:
		_one_w = null
		var hit := _jolt_ray(world, from, to, mask, exclude)
		if hit.is_empty():
			return 1.0
		_one_kind = hit.kind
		_one_normal = hit.normal
		_one_rid = hit.rid
		var d := from.distance_to(to)
		return from.distance_to(hit.position) / d if d > 0.0 else 0.0
	_one_w = w
	return w.native.cast_one(from, to, mask, exclude)


## What the last `cast` met (asked of the plugin only when wanted).
static func hit_kind() -> int:
	return _one_w.native.one_kind() if _one_w else _one_kind


static func hit_normal() -> Vector3:
	return _one_w.native.one_normal() if _one_w else _one_normal


static func hit_body() -> RID:
	return rid_from_int64(_one_w.native.one_id()) if _one_w else _one_rid


static var _one_w: _World
static var _one_kind := KIND_OTHER
static var _one_normal := Vector3.ZERO
static var _one_rid := RID()


## Nothing on the world's layer between `from` and `to` (the bodies in `exclude` aside), or what's
## there is within `near` of `to` (the thing looked at itself).
static func clear(world: Object, from: Vector3, to: Vector3, exclude: Array[RID] = [], near := 0.15) -> bool:
	var w: _World = _world_of(world) if enabled else null
	if w == null:
		var hit := _jolt_ray(world, from, to, Layers.WORLD, exclude)
		return hit.is_empty() or (hit.position as Vector3).distance_to(to) < near
	return w.native.clear(from, to, Layers.WORLD, exclude, near)


## A batch: the fraction along each line `from[i]`..`to[i]` where it first meets something on
## `mask` (1.0 for nothing). `kinds()`, `normals()` and `hit_rid(i)` have the rest of each hit.
static func lines(world: Object, from: PackedVector3Array, to: PackedVector3Array, mask: int, exclude: Array[RID] = []) -> PackedFloat32Array:
	var w: _World = _world_of(world) if enabled else null
	if w == null:
		return _jolt_lines(world, from, to, mask, exclude)
	var out: PackedFloat32Array = w.native.cast(from, to, mask, exclude)
	_last_kind = w.native.hit_kinds()
	_last_ids = w.native.hit_ids()
	_last_normals = w.native.hit_normals()
	return out


## The last batch's hits: each line's body kind, surface normal and body.
static func kinds() -> PackedInt32Array:
	return _last_kind


static func normals() -> PackedVector3Array:
	return _last_normals


static func hit_rid(i: int) -> RID:
	return rid_from_int64(_last_ids[i])


# --- Without the plugin: Jolt -------------------------------------------------------------------

static func _jolt_ray(world: Object, from: Vector3, to: Vector3, mask: int, exclude: Array[RID]) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	q.exclude = exclude
	var hit := _space(world).intersect_ray(q)
	if hit.is_empty():
		return hit
	hit.kind = _kind_of(hit.collider as Node)
	return hit


static func _jolt_lines(world: Object, from: PackedVector3Array, to: PackedVector3Array, mask: int, exclude: Array[RID]) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	_last_kind = PackedInt32Array()
	_last_ids = PackedInt64Array()
	_last_normals = PackedVector3Array()
	var space := _space(world)
	var q := PhysicsRayQueryParameters3D.new()
	q.collision_mask = mask
	q.exclude = exclude
	for i in mini(from.size(), to.size()):
		q.from = from[i]
		q.to = to[i]
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			out.append(1.0)
			_last_kind.append(KIND_OTHER)
			_last_ids.append(0)
			_last_normals.append(Vector3.ZERO)
			continue
		var d := from[i].distance_to(to[i])
		out.append(from[i].distance_to(hit.position) / d if d > 0.0 else 0.0)
		_last_kind.append(_kind_of(hit.collider as Node))
		_last_ids.append((hit.rid as RID).get_id())
		_last_normals.append(hit.normal)
	return out


# --- Keeping it up to date ----------------------------------------------------------------------

## Something about `node`'s bodies (it, or any body under it) changed that the tree doesn't show:
## its shapes resized or moved, or it moved by script. `next_frame`: the change reaches the
## physics server only at the end of this frame (a deferred call, a transform notification).
static func changed(node: Node, next_frame := false) -> void:
	if not enabled or node == null or _worlds.is_empty():
		return
	if next_frame:
		_next.append([node, Engine.get_physics_frames()])
	else:
		_now.append(node)


static func _space(world: Object) -> PhysicsDirectSpaceState3D:
	return world as PhysicsDirectSpaceState3D if world is PhysicsDirectSpaceState3D else World.space(world as Node)


## A body's shapes moved on it, the same shapes (the horse's, following his bones): only their places
## are read again, at the first question of the next physics frame (a shape node's move reaches
## the server at the frame's end).
static func shapes_moved(co: CollisionObject3D) -> void:
	if not enabled or co == null or _worlds.is_empty():
		return
	_moves.append([co, Engine.get_physics_frames()])


static var _moves: Array = []


## A body the physics moves (`co`) moved by script this tick (the player's own step): placed again
## now, for the lines asked after it this tick (the rest are placed once a physics frame).
static func moved(co: CollisionObject3D) -> void:
	if not enabled or _worlds.is_empty() or not co.is_inside_tree():
		return
	var w: _World = _worlds.get(co.get_world_3d().space.get_id())
	if w != null and w.frame == Engine.get_physics_frames():
		w.native.refresh_body(co.get_rid().get_id())


static func _world_of(world: Object) -> _World:
	# The same asker as last time, this frame, nothing waiting to be taken: as it was.
	if _fast_w != null and _now.is_empty() and world != null and world.get_instance_id() == _fast_id \
			and _fast_w.frame == Engine.get_physics_frames():
		return _fast_w
	var w: _World
	if world is PhysicsDirectSpaceState3D:
		w = _by_state.get(world.get_instance_id())
		if w == null:
			# Not asked by a node yet: the game's world, if it's this one.
			var tree := Engine.get_main_loop() as SceneTree
			var w3d := tree.root.find_world_3d() if tree else null
			if w3d == null or w3d.direct_space_state != world:
				return null
			w = _worlds.get(w3d.space.get_id())
			if w == null:
				w = _start(tree.root, w3d)
	else:
		var node := world as Node
		var w3d: World3D = (node as Node3D).get_world_3d() if node is Node3D else (node.get_viewport().find_world_3d() if node and node.get_viewport() else null)
		if w3d == null:
			return null
		w = _worlds.get(w3d.space.get_id())
		if w == null:
			w = _start(node, w3d)
	var frame := Engine.get_physics_frames()
	# Keeping it up to date: `sight_sync` in the lab's perf.
	var t_sync := Prof.start()
	if w.frame != frame:
		w.frame = frame
		if not _next.is_empty():
			var later: Array = []
			for e: Array in _next:
				if frame > int(e[1]):
					_now.append(e[0])
				else:
					later.append(e)
			_next = later
		_take_pending()
		_move_pending(frame)
		w.native.refresh_moving()
	elif not _now.is_empty():
		_take_pending()
	Prof.stop(&"sight_sync", t_sync)
	_fast_id = world.get_instance_id()
	_fast_w = w
	return w


static var _fast_id := 0
static var _fast_w: _World


static func _start(world: Node, w3d: World3D) -> _World:
	var w := _World.new()
	w.native = ClassDB.instantiate(&"SightWorld")
	w.space = w3d.space
	w.native.set_space(w3d.space)
	_worlds[w3d.space.get_id()] = w
	_by_state[w3d.direct_space_state.get_instance_id()] = w
	var tree := world.get_tree()
	if not _hooked:
		_hooked = true
		tree.node_added.connect(_on_added)
		tree.node_removed.connect(_on_removed)
		Events.ground_changed.connect(_on_ground_changed)
	var found: Array = []
	_gather(tree.root, found)
	_take(found)
	return w


static func _gather(n: Node, out: Array) -> void:
	if n is CollisionObject3D and not n is Area3D:
		out.append(n)
	for c in n.get_children(true):
		_gather(c, out)


static func _on_added(n: Node) -> void:
	if n is CollisionObject3D:
		if not n is Area3D:
			_now.append(n)
	elif n is CollisionShape3D:
		var p := n.get_parent()
		if p is CollisionObject3D:
			_now.append(p)


static func _on_removed(n: Node) -> void:
	if n is CollisionObject3D:
		var id := (n as CollisionObject3D).get_rid().get_id()
		for w: _World in _worlds.values():
			if w.bodies.erase(id):
				w.native.remove_bodies(PackedInt64Array([id]))
	elif n is CollisionShape3D:
		var p := n.get_parent()
		if p is CollisionObject3D and not p.is_queued_for_deletion():
			_now.append(p)


static func _on_ground_changed(_area: Rect2) -> void:
	for w: _World in _worlds.values():
		for b: Variant in w.bodies.values():
			if is_instance_valid(b) and (b is Ground or b is GroundTile):
				_now.append(b)


static func _move_pending(frame: int) -> void:
	if _moves.is_empty():
		return
	var later: Array = []
	var by := {}
	for e: Array in _moves:
		if frame <= int(e[1]):
			later.append(e)
			continue
		var co: Variant = e[0]
		if not is_instance_valid(co) or not (co as Node).is_inside_tree():
			continue
		var w: _World = _worlds.get((co as CollisionObject3D).get_world_3d().space.get_id())
		if w == null:
			continue
		if not by.has(w):
			by[w] = []
		(by[w] as Array).append((co as CollisionObject3D).get_rid().get_id())
	_moves = later
	for w: _World in by:
		w.native.move_shapes(PackedInt64Array(by[w]))


static func _take_pending() -> void:
	var list := _now
	_now = []
	var bodies: Array = []
	for n: Variant in list:
		if not is_instance_valid(n):
			continue
		if n is CollisionObject3D:
			bodies.append(n)
		else:
			_gather(n as Node, bodies)
	_take(bodies)


## Each body (once, in the order given) read from the physics server into its space's SightWorld:
## one call a world.
static func _take(bodies: Array) -> void:
	var by := {}
	var seen := {}
	for b: Variant in bodies:
		if not is_instance_valid(b):
			continue
		var co := b as CollisionObject3D
		var id := co.get_rid().get_id()
		if seen.has(id):
			continue
		seen[id] = true
		if not co.is_inside_tree():
			continue
		var w3d := co.get_world_3d()
		var w: _World = _worlds.get(w3d.space.get_id()) if w3d else null
		if w == null:
			continue
		if (co.collision_layer & LAYERS) == 0:
			if w.bodies.erase(id):
				w.native.remove_bodies(PackedInt64Array([id]))
			continue
		var pack: Array = by.get(w, [])
		if pack.is_empty():
			pack = [[], [], []]
			by[w] = pack
		(pack[0] as Array).append(id)
		(pack[1] as Array).append(_kind_of(co))
		(pack[2] as Array).append(_disabled(co))
		w.bodies[id] = co
	for w: _World in by:
		var pack: Array = by[w]
		w.native.add_bodies(PackedInt64Array(pack[0]), PackedInt32Array(pack[1]), PackedInt64Array(pack[2]))


## A bit for each of the body's shapes that's switched off (a shattered pane's).
static func _disabled(co: CollisionObject3D) -> int:
	var bits := 0
	for owner in co.get_shape_owners():
		if co.is_shape_owner_disabled(owner):
			for j in co.shape_owner_get_shape_count(owner):
				var idx := co.shape_owner_get_shape_index(owner, j)
				if idx < 64:
					bits |= 1 << idx
	return bits


static func _kind_of(n: Node) -> int:
	if n is StructureMember:
		return KIND_MEMBER
	if n is Ground or n is GroundTile:
		return KIND_GROUND
	if n is CharacterBody3D:
		return KIND_CHARACTER
	if n is RigidBody3D:
		return KIND_RIGID
	return KIND_OTHER


## What it holds, for the tests and the labs: the native stats, or {} with no plugin.
static func stats(world: Object) -> Dictionary:
	var w: _World = _world_of(world) if enabled else null
	return w.native.stats() if w else {}


## Forget every world (a test's fresh scene; the next question takes the tree again).
static func reset() -> void:
	_one_w = null
	_moves.clear()
	_fast_w = null
	_fast_id = 0
	_worlds.clear()
	_by_state.clear()
	_now.clear()
	_next.clear()
