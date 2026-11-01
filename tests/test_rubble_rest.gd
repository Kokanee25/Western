extends TestCase
## Rubble at rest drawn in its cell (#459): a piece lying still a while is its body alone, its mesh
## in the cell's and its shape held as an owner; it's still there to hit; waking it, or the fire
## touching it, makes it its own again where it lies.

var world: Node3D
var s: Structure


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = WorldBoundaryShape3D.new()
	ground.add_child(cs)
	world.add_child(ground)
	s = Structure.new()
	s.structure_id = &"rig"
	world.add_child(s)
	s.add_member("stud", &"post", &"framing", Vector3(0.1, 0.1, 1.2), Vector3(5, 0.3, 5))
	s.add_member("plank", &"post", &"framing", Vector3(0.1, 0.1, 1.2), Vector3(8, 0.3, 5))
	s.infer_supports()
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _rest() -> RubbleRest:
	return world.get_node_or_null(^"RubbleRest") as RubbleRest


## Drop the members and wait till they've lain still long enough to join.
func _lying(ids: Array[StringName]) -> Array:
	s._drop(ids)
	var bodies := s.rubble.duplicate()
	for i in 360:
		await physics_frames(1)
		if _rest() and _rest().piece_count() >= bodies.size():
			break
	return bodies


func test_rubble_lying_still_joins_its_cell() -> void:
	var bodies := await _lying([&"rig/stud", &"rig/plank"] as Array[StringName])
	check(_rest() != null, "a rest for the world")
	if _rest() == null:
		return
	check_eq(_rest().piece_count(), 2, "both pieces at rest")
	await physics_frames(int(RubbleRest.BUILD_GAP * 60) + 2)
	var mats := {}
	for rb: RigidBody3D in bodies:
		var e: Dictionary = _rest()._rest.get(rb.get_instance_id(), {})
		for p: Array in e.get("parts", []):
			mats[p[0]] = true
	var meshes := _rest().mesh_count()
	check(meshes >= mats.size() and meshes <= mats.size() * RubbleRest.MAX_CHUNKS,
			"drawn as a mesh a material in each of the cell's chunks (%d meshes, %d materials)" % [meshes, mats.size()])
	for rb: RigidBody3D in bodies:
		check_eq(rb.get_child_count(), 0, "its mesh and shape out of the tree")
		check(rb.sleeping, "still asleep")
		check(RubbleRest.resting(rb), "resting")
	# Still solid: a ray down finds the body.
	var rb: RigidBody3D = bodies[0]
	var q := PhysicsRayQueryParameters3D.create(rb.global_position + Vector3.UP, rb.global_position + Vector3.DOWN)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(q)
	check(not hit.is_empty() and hit.collider == rb, "and still there to hit")


func test_a_piece_woken_is_its_own_again_where_it_lay() -> void:
	var bodies := await _lying([&"rig/stud", &"rig/plank"] as Array[StringName])
	if _rest() == null or _rest().piece_count() < 2:
		check(false, "the pieces didn't come to rest")
		return
	await physics_frames(int(RubbleRest.BUILD_GAP * 60) + 2)
	var rb: RigidBody3D = bodies[0]
	var at := rb.global_position
	rb.apply_impulse(Vector3(0, 6.0, 0))
	await physics_frames(RubbleRest.STIR_TICKS + 3)
	check(not RubbleRest.resting(rb), "moving, it's left the cell")
	check_eq(rb.get_children().filter(func(c: Node) -> bool: return c is MeshInstance3D).size(), 1, "its mesh back on it")
	check_eq(rb.get_children().filter(func(c: Node) -> bool: return c is CollisionShape3D).size(), 1, "its shape back on it")
	check(rb.global_position.distance_to(at) < 0.3, "where it lay")
	check_eq(_rest().piece_count(), 1, "the other still at rest")
	for i in 240:
		await physics_frames(1)
		if RubbleRest.resting(rb):
			break
	check(RubbleRest.resting(rb), "asleep again, it joins again")


## A collapse nearby wakes everything lying near (Structure._wake_near): what doesn't stir stays.
func test_a_piece_woken_that_doesnt_stir_stays_in_its_cell() -> void:
	var bodies := await _lying([&"rig/stud"] as Array[StringName])
	var rb: RigidBody3D = bodies[0]
	check(RubbleRest.resting(rb), "at rest")
	rb.sleeping = false
	await physics_frames(60)
	check(RubbleRest.resting(rb), "woken and asleep again where it lay: still in its cell")
	check_eq(rb.get_child_count(), 0, "its nodes still aside")


func test_the_fire_on_a_piece_lets_it_go() -> void:
	var bodies := await _lying([&"rig/stud"] as Array[StringName])
	var rb: RigidBody3D = bodies[0]
	check(RubbleRest.resting(rb), "at rest")
	var stud := s.get_member(&"rig/stud")
	s.show_fire(stud, 0.5, 0.6)
	check(not RubbleRest.resting(rb), "the fire on it: its own again")
	var mi := rb.get_children().filter(func(c: Node) -> bool: return c is MeshInstance3D)
	check(not mi.is_empty() and (mi[0] as MeshInstance3D).material_overlay != null, "drawn charred")
	check(rb.sleeping, "and still lying asleep")
	await physics_frames(int((RubbleRest.REST_AFTER + 1.0) * 60))
	check(not RubbleRest.resting(rb), "glowing, it doesn't join again")


func test_a_piece_freed_at_rest_takes_its_nodes() -> void:
	var bodies := await _lying([&"rig/stud"] as Array[StringName])
	var rb: RigidBody3D = bodies[0]
	check(RubbleRest.resting(rb), "at rest")
	var e: Dictionary = _rest()._rest.get(rb.get_instance_id(), {})
	var nodes: Array = (e.get("nodes", []) as Array).map(func(n: Array) -> Node: return n[0])
	check_eq(nodes.size(), 2, "its mesh and shape kept aside")
	rb.queue_free()
	await physics_frames(3)
	check_eq(_rest().piece_count(), 0, "gone from the rest")
	for n: Variant in nodes:
		check(not is_instance_valid(n), "its kept nodes freed with it")
	check_eq(_rest().mesh_count(), 0, "and nothing drawn for it")


func test_window_shards_lying_still_join() -> void:
	var pane := s.add_member("pane", &"glass", &"glass", Vector3(0.6, 0.5, 0.004), Vector3(0, 2.3, 0))
	await physics_frames(2)
	pane.shatter(pane.global_position, Vector3.FORWARD, 1)
	var shards := get_tree().get_nodes_in_group(&"glass_shards").filter(func(n: Node) -> bool: return world.is_ancestor_of(n))
	check(shards.size() >= 8, "the pane in shards (%d)" % shards.size())
	for i in 600:
		await physics_frames(1)
		if _rest() and _rest().piece_count() >= shards.size() * 0.8:
			break
	check(_rest() != null and _rest().piece_count() >= shards.size() * 0.8,
			"most lie still and join (%d of %d)" % [_rest().piece_count() if _rest() else 0, shards.size()])


## Between joining and its cell drawing it, a piece draws itself: it never vanishes.
func test_a_joining_piece_is_drawn_all_the_while() -> void:
	s._drop([&"rig/stud", &"rig/plank"] as Array[StringName])
	var bodies := s.rubble.duplicate()
	var unseen := 0
	for i in 360:
		await physics_frames(1)
		var r := _rest()
		for rb: RigidBody3D in bodies:
			var own := rb.get_children().any(func(c: Node) -> bool: return c is MeshInstance3D and (c as MeshInstance3D).visible)
			if not own and not (r and r.drawn_by_cell(rb)):
				unseen += 1
		if r and r.piece_count() == bodies.size() and r._jobs.is_empty() and r._pending.is_empty():
			break
	check_eq(unseen, 0, "drawn by itself or by its cell every frame")
	check(_rest() != null and _rest().piece_count() == bodies.size(), "and both joined")


## A chunk's meshes made a few a tick (here one): every piece still gets drawn by its cell (the
## bench found a cell whose part-made chunk never finished, its pieces waiting for good).
func test_a_chunk_made_over_many_ticks_is_finished() -> void:
	var ids: Array[StringName] = []
	for i in 8:
		var m := s.add_member("bit%d" % i, &"post", &"framing", Vector3(0.1, 0.1, 0.6), Vector3(4.0 + 0.4 * i, 0.3, 8.0))
		ids.append(m.member_id)
	await physics_frames(2)
	var was := RubbleRest.mesh_ms
	RubbleRest.mesh_ms = 0.0
	s._drop(ids)
	var bodies := s.rubble.duplicate()
	var done := false
	for i in 600:
		await physics_frames(1)
		var r := _rest()
		if r and r.piece_count() == bodies.size() and r._jobs.is_empty() and r._pending.is_empty():
			done = true
			break
	RubbleRest.mesh_ms = was
	check(done, "every piece joined and no job left (%s)" % (str(_rest().state()) if _rest() else "no rest"))
	var drawn := 0
	for rb: RigidBody3D in bodies:
		if _rest() and _rest().drawn_by_cell(rb):
			drawn += 1
	check_eq(drawn, bodies.size(), "all of them drawn by their cell")
