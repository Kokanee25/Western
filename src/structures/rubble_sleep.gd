class_name RubbleSleep
extends Node
## The restless pieces that keep a pile of rubble awake, held still so the pile can sleep (#585).
##
## Jolt puts a body to sleep only with everything it touches: a pile is one island, and the island
## sleeps when every body in it has kept within ~1.5 cm (its sleep velocity, 0.03 m/s, over its sleep
## time, 0.5 s) for that long. After dynamite on Main Street the piles are hundreds of pieces, and
## one restless body keeps all of them awake: a piece spinning where it's wedged (~3 rad/s for
## minutes), a fallen fitting that jitters, a board rocking on another. The street's three sticks
## left ~700 pieces awake a minute on in most runs and none in others (#459's 0 vs 537), all but one
## or two of them moving under 1 cm/s, and Jolt stepped every one: ~30 ms a frame here for as long
## as they lay (experiments/blast_freeze/results/2026-11-02_rubble_sleep/).
##
## Putting the pile to sleep from here doesn't hold: the contact monitor reports four contacts a
## body, so the piles seen from here are pieces of Jolt's islands, and the awake rest woke them on
## the next step (~17,000 piles put to sleep in 20 s, nearly all woken again). So it takes out what
## keeps the island awake instead. Every EVERY s it looks at the awake rubble, fallen fittings and
## debris (GROUPS, and a glass prop's body knocked loose): a piece whose middle has stayed within
## STILL_M of where it was for STILL_S, with nothing given way within QUIET_M of it for QUIET_S
## (`disturbed`: Structure's wakes after a break; a blast, within BLAST_M), and still moving faster
## than RESTLESS at some point of it (spinning or jiggling in place: going nowhere), is frozen
## where it lies (static: it holds what's on it). Jolt then sleeps the rest of its pile itself. And
## (#647) a quiet piece still awake QUIET_AWAKE_S past its still spell is held too: something its
## pile touches that isn't looked at here keeps it awake (a dead man's ragdoll, bone chips, a hat).
## A frozen piece is let go (its own body again, awake) the moment anything happens to it or near
## it: struck, shot, blasted, shoved (`let_go`, from RubbleRest.let_go), its member touched
## (RubbleRest.touch), rubble landing on it, the ground dug under it, or something within its wake
## radius gives way (`disturbed`); one let go so lets go what's held lying on it (`_lying_on`).
##
## It only touches pieces after they've stopped mattering: nothing whose middle is moving, nothing
## near a break or within a blast's reach for QUIET_S, so what breaks next is decided as before
## (the broken counts in the results).

## How often (s of game time) the awake rubble is looked at.
const EVERY := 0.5
## Still: its middle within this (m) of where it was ...
const STILL_M := 0.03
## ... for this long (s of game time).
const STILL_S := 1.5
## Restless: some point of it (its middle's speed + its spin x its reach) faster than this (m/s);
## Jolt's sleep line is 0.03.
const RESTLESS := 0.01
## Quiet (under RESTLESS) yet still awake this long (s) past its still spell: something else in its
## pile keeps Jolt from sleeping it (Jolt sleeps a quiet island in 0.5 s, its sleep time), so it's
## held too (#647:
## after a bundle on Main Street ~2,100 still pieces lay awake round a dead man's ragdoll and the
## bone chips by him for 6 s to the end of the run, ~35 ms of the physics' step a frame).
const QUIET_AWAKE_S := 0.5
## Pieces held lie in cells this big (m), so what's held near a spot is found without a walk of all.
const CELL := 1.0
## Nothing gave way within this (m, plus the wake's own radius) of it for this long (s).
const QUIET_M := 2.0
const QUIET_S := 2.0
## A blast's reach for that (m, for a kilogram; by the cube root, never under it).
const BLAST_M := 20.0
## The groups looked at: rubble (Structure's, the kit props'), fittings fallen (Fittings.drop), and
## the debris that lies in the piles (a blasted man's bone fragments spun ~10 rad/s on the boards
## for 10 s and more; panes' shards, chips, spent cases).
const GROUPS: Array[StringName] = [&"rubble", &"fallen", &"bone_fragments", &"glass_shards", &"wood_chips", &"spent_cases"]

## Off (`-- --no-rubble-sleep`): the before, Jolt's sleep alone.
static var enabled := not "--no-rubble-sleep" in OS.get_cmdline_user_args()

## RigidBody3D -> [its middle when the still spell began, game time it began].
var _still := {}
## Where things gave way lately: a 4 m cell -> [at, radius, game time] (a blast's dozens of wakes
## kept as a few spheres).
var _disturbed := {}
## The pieces frozen here (instance id -> body).
var _frozen := {}
## The held pieces by CELL: Vector3i -> {instance id: body}.
var _cells := {}
var _next := 0.0
## The look under way: the bodies still to be looked at, how many a tick, the spells seen so far.
var _queue: Array = []  # (untyped: a body may be freed in it)
var _per_tick := 0
var _seen := {}
## Counts for the labs and tests: held still, let go (and why).
var counts := {}


## The one in `n`'s world (made the first time it's asked; null when off).
static func for_node(n: Node) -> RubbleSleep:
	if not enabled or n == null or not n.is_inside_tree():
		return null
	var top: Node = n
	while top.get_parent() is Node3D:
		top = top.get_parent()
	var r := top.get_node_or_null(^"RubbleSleep") as RubbleSleep
	if r == null:
		r = RubbleSleep.new()
		r.name = "RubbleSleep"
		top.add_child(r)
	return r


## Something gave way at `at`: what's held still within `radius` is let go, and the rubble within
## `radius` + QUIET_M is left to Jolt for QUIET_S.
static func disturbed(n: Node, at: Vector3, radius: float) -> void:
	var r := for_node(n)
	if r == null:
		return
	var key := Vector3i((at / 4.0).floor())
	var d: Variant = r._disturbed.get(key)
	var reach := radius + QUIET_M
	if d != null:
		reach = maxf(reach, float(d[1]) + at.distance_to(d[0]))
	r._disturbed[key] = [at, reach, _time()]
	for b: RigidBody3D in r._held_within(at, radius):
		r._release(b, "let go: gave way near")


## A body about to be moved (struck, shot, blasted, shoved, its member touched): if it's held still
## here, its own again, awake.
static func let_go(body: Object, tag := "") -> void:
	if body is RigidBody3D and (body as Node).has_meta(&"held_still"):
		var r: Variant = (body as Node).get_meta(&"held_still")
		if is_instance_valid(r):
			(r as RubbleSleep)._release(body as RigidBody3D, "let go: moved", 3, "let go: moved" + tag)


func _ready() -> void:
	Events.exploded.connect(_on_exploded)


## A blast: nothing within its reach is held for QUIET_S (pieces lying between one stick and the
## next still matter: what they shield and what they fall on), and what's held there is let go.
func _on_exploded(at: Vector3, kg: float) -> void:
	disturbed(self, at, maxf(BLAST_M, BLAST_M * pow(maxf(kg, 0.0), 1.0 / 3.0)))


static func _time() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)


func _physics_process(_delta: float) -> void:
	var now := _time()
	if _queue.is_empty():
		if now < _next:
			return
		_next = now + EVERY
		var t0 := Prof.start()
		_begin(now)
		Prof.stop(&"rubble_sleep", t0)
	# A look is spread over the ticks till the next (all of it on one tick was ~9 ms at the
	# farmhouse's ~2,000 pieces).
	var t := Prof.start()
	for i in mini(_per_tick, _queue.size()):
		_look_at(_queue.pop_back(), now)
	if _queue.is_empty():
		_still = _seen
		_seen = {}
	Prof.stop(&"rubble_sleep", t)


## One whole look at the awake rubble, fallen fittings and debris at once (the tests, with their
## own clock).
func look(now: float) -> void:
	_begin(now)
	while not _queue.is_empty():
		_look_at(_queue.pop_back(), now)
	_still = _seen
	_seen = {}


## A look begins: the old breaks forgotten, what's to be looked at gathered.
func _begin(now: float) -> void:
	for key: Vector3i in _disturbed.keys():
		if now - float(_disturbed[key][2]) >= QUIET_S:
			_disturbed.erase(key)
	_queue.clear()
	_seen = {}
	for g: StringName in GROUPS:
		_queue.append_array(get_tree().get_nodes_in_group(g))  # (asleep or not: _look_at's, spread)
	# A glass prop knocked loose (a lamp, a bottle) stays a body of its own: one jiggled on a pile.
	for g: Node in get_tree().get_nodes_in_group(&"glass_props"):
		var b: Variant = g.get(&"body")
		if b is RigidBody3D and bool(g.get(&"loose")) and not bool(g.get(&"broken")) and not (b as RigidBody3D).sleeping:
			_queue.append(b)
	_per_tick = ceili(_queue.size() / maxf(EVERY * Engine.physics_ticks_per_second, 1.0))


func _look_at(o: Variant, now: float) -> void:
	if not is_instance_valid(o) or not o is RigidBody3D:
		return
	var rb := o as RigidBody3D
	if rb.sleeping and _still.has(rb):
		# Asleep, it's been still all along: its spell kept, so woken again (the pile beside a piece
		# held wakes with it) and still restless, it's held at the next look, not a spell later.
		_seen[rb] = _still[rb]
		return
	if rb.sleeping or rb.freeze or rb.has_meta(&"held_still") or not rb.is_inside_tree():
		return
	var at := rb.global_position
	var s: Variant = _still.get(rb)
	if s == null or at.distance_to(s[0]) > STILL_M:
		s = [at, now]
	_seen[rb] = s
	if now - float(s[1]) < STILL_S or _near_disturbed(at):
		return
	if rb.linear_velocity.length() + rb.angular_velocity.length() * _reach(rb) < RESTLESS:
		if now - float(s[1]) < STILL_S + QUIET_AWAKE_S:
			return  # (quiet: Jolt puts it to sleep with its pile, if nothing in it keeps it awake)
		_hold(rb, "held still: quiet")
		return
	_hold(rb)


## Frozen where it lies (static), until something happens to it or near it. (Damping it to a stop
## instead, its type unchanged, kept its pile awake: tried, `results/2026-11-02_rubble_sleep/`.)
func _hold(rb: RigidBody3D, why := "held still") -> void:
	rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	rb.freeze = true
	rb.set_meta(&"held_still", self)
	var id := rb.get_instance_id()
	_frozen[id] = rb
	var key := _cell(rb.global_position)
	rb.set_meta(&"held_cell", key)
	(_cells.get_or_add(key, {}) as Dictionary)[id] = rb
	_count(why)


## Let go: its own body again, awake. Moved (struck, shot, pushed, landed on), what's held lying on
## it or against it is let go with it, and what lies on those (up to `depth` deep): a pile held
## whole doesn't hang in the air round a piece knocked out of it.
func _release(rb: RigidBody3D, why: String, depth := 3, counted := "") -> void:
	var id := rb.get_instance_id() if is_instance_valid(rb) else 0
	var b: Variant = _frozen.get(id)
	_frozen.erase(id)
	if not is_instance_valid(rb):
		return
	var key: Variant = rb.get_meta(&"held_cell", null)
	if key != null and _cells.has(key):
		(_cells[key] as Dictionary).erase(id)
		if (_cells[key] as Dictionary).is_empty():
			_cells.erase(key)
	rb.remove_meta(&"held_cell")
	rb.remove_meta(&"held_still")
	if rb.collision_layer == 0 or rb.is_queued_for_deletion():
		return  # (gone meanwhile: a glass prop smashed holds its own body frozen, out of the world)
	rb.freeze = false
	rb.sleeping = false
	_count(counted if counted != "" else why)
	if why == "let go: moved" and depth > 0 and b != null and not _frozen.is_empty():
		for o: RigidBody3D in _lying_on(rb):
			if _frozen.has(o.get_instance_id()):
				_release(o, "let go: moved", depth - 1, "let go: with one moved")


## What's held touching `rb` (within a couple of cm of its shapes) whose middle isn't below its own:
## what lies on it or leans on it. (What it lay on still holds, static.)
func _lying_on(rb: RigidBody3D) -> Array[RigidBody3D]:
	var out: Array[RigidBody3D] = []
	if not rb.is_inside_tree():
		return out
	var space := rb.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	q.collision_mask = Layers.WORLD | Layers.DEBRIS
	q.margin = 0.02
	q.exclude = [rb.get_rid()]
	for owner_id: int in rb.get_shape_owners():
		if rb.is_shape_owner_disabled(owner_id):
			continue
		var xf := rb.global_transform * rb.shape_owner_get_transform(owner_id)
		for k in rb.shape_owner_get_shape_count(owner_id):
			q.shape = rb.shape_owner_get_shape(owner_id, k)
			q.transform = xf
			for hit: Dictionary in space.intersect_shape(q, 32):
				var o: Variant = hit.collider
				if o is RigidBody3D and (o as Node).has_meta(&"held_still") and not out.has(o) \
						and (o as Node3D).global_position.y > rb.global_position.y - 0.05:
					out.append(o as RigidBody3D)
	return out


static func _cell(p: Vector3) -> Vector3i:
	return Vector3i((p / CELL).floor())


## What's held within `radius` of `at` (by its middle), freed ones forgotten.
func _held_within(at: Vector3, radius: float) -> Array[RigidBody3D]:
	var out: Array[RigidBody3D] = []
	if _frozen.is_empty():
		return out
	var lo := _cell(at - Vector3.ONE * radius)
	var hi := _cell(at + Vector3.ONE * radius)
	var span := hi - lo + Vector3i.ONE
	if span.x * span.y * span.z > _cells.size():
		for key: Vector3i in _cells.keys():
			_gather(key, at, radius, out)
	else:
		for x in range(lo.x, hi.x + 1):
			for y in range(lo.y, hi.y + 1):
				for z in range(lo.z, hi.z + 1):
					_gather(Vector3i(x, y, z), at, radius, out)
	return out


func _gather(key: Vector3i, at: Vector3, radius: float, out: Array[RigidBody3D]) -> void:
	var c: Variant = _cells.get(key)
	if c == null:
		return
	for id: int in (c as Dictionary).keys():
		var b: Variant = (c as Dictionary)[id]
		if not is_instance_valid(b):
			(c as Dictionary).erase(id)
			_frozen.erase(id)
		elif (b as Node3D).global_position.distance_to(at) < radius:
			out.append(b as RigidBody3D)
	if (c as Dictionary).is_empty():
		_cells.erase(key)


## Is it held still here (tests, the lab)?
func held(rb: RigidBody3D) -> bool:
	return is_instance_valid(rb) and _frozen.has(rb.get_instance_id())


func held_count() -> int:
	return _frozen.size()


## How far its farthest point is from its middle: RubbleRest's (from its meshes), else from its box
## shapes, else half a metre.
static func _reach(rb: RigidBody3D) -> float:
	if rb.has_meta(&"rest_reach"):
		return rb.get_meta(&"rest_reach")
	var r := 0.0
	for c: Node in rb.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
			var cs := c as CollisionShape3D
			var half := ((cs.shape as BoxShape3D).size * 0.5).length()
			r = maxf(r, cs.position.length() + half)
	if r <= 0.0:
		r = 0.5
	rb.set_meta(&"rest_reach", r)
	return r


func _near_disturbed(p: Vector3) -> bool:
	for d: Array in _disturbed.values():
		if p.distance_to(d[0]) < float(d[1]):
			return true
	return false


func _count(what: String) -> void:
	counts[what] = int(counts.get(what, 0)) + 1
