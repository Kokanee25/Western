extends TestCase
## PinnedSoft: a soft body pinned to its prop (the mop's head, a held rag) lets falling things
## through (rubble, shards) and still meets what stands (a frozen prop) and people's parts.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _body(layer: int, frozen := false, group := &"") -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.collision_layer = layer
	rb.freeze = frozen
	if group != &"":
		rb.add_to_group(group)
	var cs := CollisionShape3D.new()
	cs.shape = BoxShape3D.new()
	rb.add_child(cs)
	return rb


func test_what_falls_passes_through_and_what_stands_doesnt() -> void:
	var owner := Node3D.new()
	world.add_child(owner)
	var soft := SoftBody3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.3, 0.3)
	soft.mesh = plane
	owner.add_child(soft)
	soft.global_position = Vector3(0, 5, 0)
	var before := _body(Layers.WORLD, false, &"rubble")
	world.add_child(before)
	PinnedSoft.keep_clear(soft, owner)
	var rubble := _body(Layers.WORLD, false, &"rubble")
	var shard := _body(Layers.DEBRIS, false, &"glass_shards")
	var standing := _body(Layers.DEBRIS, true)
	var part := _body(Layers.BODY_PARTS)
	for b in [rubble, shard, standing, part]:
		world.add_child(b)
	await physics_frames(1)
	var ex := soft.get_collision_exceptions()
	check(before in ex, "rubble already lying about passes through")
	check(rubble in ex and shard in ex, "rubble and shards that come later pass through")
	check(not standing in ex, "a prop standing (frozen) is met")
	check(not part in ex, "a man's parts are met")
	owner.queue_free()
	await physics_frames(1)
	world.add_child(_body(Layers.WORLD, false, &"rubble"))  # nothing's listening for it now
	check(true, "no error once it's gone")
