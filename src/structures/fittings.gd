class_name Fittings
extends Node
## What's fixed to or resting on a building's members comes down when they go (Sean: "lamps and
## stuff floating in the air after the wall they were attached to burns down"): lamps, sconces and
## lanterns, painted signs and hung boards, pictures and the stag, the bottle wall, the bottles on a
## shelf, a lamp on a table, barrels on a boardwalk. Shortly after load it finds, for each thing in
## a building or in the street's dressing, the members it touches (and the other fittings it rests
## on); when every one of them is gone (burnt away, broken, fallen) it becomes a body and falls, and
## whatever rested on it follows. A lamp that lands hard breaks, and a lit one spills its burning
## oil where it lands (OilLamp.smash): a burning building's lamps spread its fire.
##
## Things standing on the ground (horses, wagons, poles, the water tower) touch no member and are
## left alone. Dressing drawn by StaticBatch is handed back before it falls.

## How often the supports are looked at (seconds), and how many fittings a frame at most.
const CHECK_EVERY := 0.25
const CHECK_PER_FRAME := 120
## How far round a thing's box a member still counts as holding it (m).
const TOUCH := 0.04
## A thing whose biggest side is under this falls among the small debris (you walk through it).
const SMALL := 0.6
## Landing faster than this (m/s) breaks a lamp.
const BREAKS_AT := 1.5
## A thing whose bottom is lower than this stands on the ground (m).
const GROUND := 0.08
## Physics frames after load before looking (the buildings, the dressing and the batch settled).
const SETTLE_FRAMES := 4

var items: Array[Dictionary] = []
var fallen: Array[RigidBody3D] = []
var _by_body := {}
var _next := 0
var _since := 0.0
var _frames := 0
var _ready_to_watch := false


func _physics_process(delta: float) -> void:
	if not _ready_to_watch:
		_frames += 1
		if _frames >= SETTLE_FRAMES:
			collect()
			_ready_to_watch = true
		return
	_since += delta
	if _since < CHECK_EVERY and _next == 0:
		return
	_since = 0.0
	var n := mini(CHECK_PER_FRAME, items.size() - _next)
	for i in n:
		var item := items[_next + i]
		if not item.down and _unheld(item):
			drop(item)
	_next += n
	if _next >= items.size():
		_next = 0


## Finds the fittings and what holds each (also callable again, from a test, once things change).
func collect() -> void:
	items.clear()
	_by_body.clear()
	var street := get_parent()
	var nodes: Array[Node3D] = []
	for s: Node in get_tree().get_nodes_in_group(&"structures"):
		if street.is_ancestor_of(s):
			_candidates(s, nodes)
	var dressing := street.get_node_or_null(^"StreetDressing")
	if dressing:
		_candidates(dressing, nodes)
	var space := (street as Node3D).get_world_3d().direct_space_state if street is Node3D else null
	if space == null:
		return
	for node in nodes:
		var box := _box_of(node)
		if box.size == Vector3.ZERO or box.position.y < GROUND:
			continue  # nothing drawn, or it stands on the ground
		var item := {"node": node, "box": box, "members": [], "on": [], "down": false, "bodies": _bodies_in(node)}
		items.append(item)
		for b in item.bodies:
			_by_body[b] = item
	for item in items:
		_find_supports(space, item)
	items = items.filter(func(it: Dictionary) -> bool: return not (it.members as Array).is_empty() or not (it.on as Array).is_empty())


## The things under `root` that are fittings: props (static bodies), lamps, and nodes drawing
## meshes of their own; plain containers are looked into; members, batches and the people aren't.
func _candidates(root: Node, out: Array[Node3D]) -> void:
	for c in root.get_children():
		if c is StructureMember or c is HumanBody or c is Backdrop or c is DryGrass or c is Structure or c is RigidBody3D:
			continue  # (a loose body falls by itself)
		if not (c is Node3D) or (c is MeshInstance3D and String(c.name).begins_with("Batch")):
			continue
		var n := c as Node3D
		if n is StaticBody3D or n is OilLamp or n is MeshInstance3D or _draws_itself(n):
			out.append(n)
		else:
			_candidates(n, out)


## A node drawing a mesh of its own is one thing (a lantern and its post); one holding only props
## or lamps is a container (a building's Props), looked into.
func _draws_itself(n: Node3D) -> bool:
	for c in n.get_children():
		if c is MeshInstance3D:
			return true
	return false


func _bodies_in(node: Node3D) -> Array[CollisionObject3D]:
	var out: Array[CollisionObject3D] = []
	if node is CollisionObject3D:
		out.append(node)
	for c in node.find_children("*", "CollisionObject3D", true, false):
		out.append(c)
	return out


## The world box of what it draws (its meshes, and the hitbox for a lamp drawing nothing); an
## invisible thing (a stair's ramp) has none and isn't a fitting.
func _box_of(node: Node3D) -> AABB:
	var box := AABB()
	var any := false
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for mi: MeshInstance3D in meshes:
		if mi.mesh == null:
			continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if not any else box.merge(b)
		any = true
	if not any and node is OilLamp:
		for cs: CollisionShape3D in node.find_children("*", "CollisionShape3D", true, false):
			if cs.shape is BoxShape3D:
				var half := (cs.shape as BoxShape3D).size * 0.5
				var b := cs.global_transform * AABB(-half, half * 2.0)
				box = b if not any else box.merge(b)
				any = true
	return box if any else AABB()


func _find_supports(space: PhysicsDirectSpaceState3D, item: Dictionary) -> void:
	var box: AABB = item.box
	var shape := BoxShape3D.new()
	shape.size = box.size + Vector3.ONE * TOUCH * 2.0
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), box.get_center())
	q.collision_mask = Layers.WORLD
	var exclude: Array[RID] = []
	for b: CollisionObject3D in item.bodies:
		exclude.append(b.get_rid())
	q.exclude = exclude
	for hit in space.intersect_shape(q, 48):
		var other: Object = hit.collider
		if other is StructureMember:
			var m := other as StructureMember
			if not m.broken and not m.consumed:
				item.members.append([m, m.global_position])
		elif _by_body.has(other) and _by_body[other] != item:
			if not (item.on as Array).has(_by_body[other]):
				item.on.append(_by_body[other])


## Nothing it touched holds it any more.
func _unheld(item: Dictionary) -> bool:
	for entry: Array in item.members:
		var m = entry[0]
		if is_instance_valid(m) and not m.broken and not m.consumed and (m as Node3D).global_position.distance_to(entry[1]) < 0.05:
			return false
	for other: Dictionary in item.on:
		if not other.down:
			return false
	return true


## It falls: a body of its own (small things among the debris, big ones like rubble), keeping
## where it was; a lamp in it breaks when it lands.
func drop(item: Dictionary) -> void:
	item.down = true
	var node: Node3D = item.node
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	StaticBatch.release_in(get_tree(), node)
	var box: AABB = item.box
	var rb := RigidBody3D.new()
	rb.name = "Fallen%s" % node.name
	var big := maxf(box.size.x, maxf(box.size.y, box.size.z)) >= SMALL
	rb.collision_layer = Layers.WORLD if big else Layers.DEBRIS
	rb.collision_mask = (Layers.WORLD | Layers.PEOPLE | Layers.BODY_PARTS) if big else Layers.DEBRIS_MASK
	rb.mass = clampf(box.size.x * box.size.y * box.size.z * 250.0, 0.3, 150.0)
	rb.contact_monitor = true
	rb.max_contacts_reported = 2
	rb.continuous_cd = true
	rb.add_to_group(&"fallen")
	get_parent().add_child(rb)
	rb.global_transform = Transform3D(Basis(), box.get_center())
	if node is StaticBody3D:
		# A prop: its pieces (and its light) into the falling body, the static one gone.
		for c in node.get_children():
			c.reparent(rb, true)
		node.queue_free()
	else:
		node.reparent(rb, true)
	var shapes := rb.find_children("*", "CollisionShape3D", false, false)
	if shapes.is_empty():
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box.size.max(Vector3.ONE * 0.05)
		cs.shape = shape
		rb.add_child(cs)
	for b in rb.find_children("*", "CollisionObject3D", true, false):
		rb.add_collision_exception_with(b as CollisionObject3D)
	rb.body_entered.connect(_landed.bind(rb))
	fallen.append(rb)


func _landed(_other: Node, rb: RigidBody3D) -> void:
	if not is_instance_valid(rb) or rb.linear_velocity.length() < BREAKS_AT and rb.get_meta(&"v", 0.0) < BREAKS_AT:
		return
	for lamp: OilLamp in rb.find_children("*", "OilLamp", true, false):
		lamp.smash(rb.linear_velocity.normalized() if rb.linear_velocity.length() > 0.01 else Vector3.DOWN)


func _process(_delta: float) -> void:
	# The speed it was falling at before the contact slowed it (for _landed).
	for rb in fallen:
		if is_instance_valid(rb) and not rb.sleeping:
			rb.set_meta(&"v", rb.linear_velocity.length())
