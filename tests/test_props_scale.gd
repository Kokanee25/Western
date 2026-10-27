extends TestCase
## Props that scale (docs/briefs/props-scale.md): a member at rest in its structure's batch is its
## body alone (its mesh and shape nodes out of the tree, the shape held on the body), made real as
## built the moment anything touches it; kit props at rest are drawn with their neighbours
## (PropBatch) and leave the moment anything happens to them.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _place(id: StringName, at := Vector3.ZERO) -> KitProp:
	var p := PropKit.spawn(id)
	p.position = at
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	await process_frames(1)
	return p


func _batch() -> PropBatch:
	return world.get_node_or_null(^"PropBatch") as PropBatch


func test_a_member_at_rest_is_its_body_alone_and_still_solid() -> void:
	var p: KitProp = await _place(&"crate")
	var resting := p.get_members().filter(func(m: StructureMember) -> bool: return m.resting())
	check(resting.size() == p.member_count(), "every member at rest (%d of %d)" % [resting.size(), p.member_count()])
	var m: StructureMember = resting[0]
	check(m.find_children("*", "MeshInstance3D", false, false).is_empty() and m.find_children("*", "CollisionShape3D", false, false).is_empty(),
			"no mesh or shape node in the tree")
	check_eq(m.get_shape_owners().size(), 1, "its shape on its body")
	check(m.drawn_node() != null and m.drawn_node().mesh != null, "its mesh kept for the batch")
	# A ray at it finds the member itself (what ballistics, blows and footings ask for).
	await physics_frames(1)  # queries in the physics frame (World.space)
	var c := m.global_transform.origin
	var space := world.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(c + Vector3(3, 0, 0), c, Layers.WORLD))
	check(not hit.is_empty() and hit.collider is StructureMember and (hit.collider as StructureMember).get_parent() == p, "a ray stops on one of its members")


func test_touched_it_is_made_real_as_built() -> void:
	var p: KitProp = await _place(&"crate")
	var m: StructureMember = p.get_members()[0]
	var size := m.size
	p.unbatch(m)  # what a hole, heat or a break does first
	await process_frames(2)
	check(not m.resting(), "made real")
	check(m.get_child(0) is MeshInstance3D and m.get_child(1) is CollisionShape3D, "its mesh child 0, its shape child 1, as built")
	check_eq(m.get_shape_owners().size(), 1, "one shape: its own node's")
	check((m.get_child(0) as MeshInstance3D).visible, "drawn on its own")
	var cs := m.get_child(1) as CollisionShape3D
	check(cs.shape is BoxShape3D and (cs.shape as BoxShape3D).size.is_equal_approx(size) or cs.shape is ConcavePolygonShape3D, "its shape as it was (or carved)")
	# The others are still at rest.
	check(p.get_members().slice(1).all(func(o: StructureMember) -> bool: return o.resting()), "the rest still at rest")


func test_props_at_rest_are_drawn_together_and_leave_when_touched() -> void:
	var a: KitProp = await _place(&"crate", Vector3(0, 0, 0))
	var b: KitProp = await _place(&"crate", Vector3(1.0, 0, 0))
	var c: KitProp = await _place(&"barrel", Vector3(-1.0, 0, 0))
	await process_frames(1)
	var pb := _batch()
	check(pb != null, "a PropBatch in the world")
	if pb == null:
		return
	check(pb.has(a) and pb.has(b) and pb.has(c), "all three in it")
	var joined := func(mi: MeshInstance3D) -> bool:
		return mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY or PropBatch.joins(mi.material_override, mi.mesh)
	check(a.batch_nodes().all(func(mi: MeshInstance3D) -> bool: return not joined.call(mi) or not mi.visible), "its own batches hidden")
	var own := a.batch_nodes().size() + b.batch_nodes().size() + c.batch_nodes().size()
	check(pb.mesh_count() < own, "fewer meshes together (%d) than their own (%d)" % [pb.mesh_count(), own])
	# A ball through one: it draws itself again, the others stay in.
	var m: StructureMember = a.get_members()[0]
	var at := m.global_transform.origin
	m.add_hole(at + Vector3(0, 0, 0.3), at - Vector3(0, 0, 0.3), 0.006)
	await process_frames(2)
	check(not pb.has(a), "the shot one left")
	check(pb.has(b) and pb.has(c), "the others still in")
	check(a.batch_nodes().any(func(mi: MeshInstance3D) -> bool: return mi.visible), "its own batches drawn again")
	# Moved by hand, it leaves too.
	b.global_position += Vector3(0, 0, 2.0)
	await process_frames(1)
	check(not pb.has(b), "a moved one left")
	# Freed, it goes; the last one gone, the cells are gone.
	c.queue_free()
	await process_frames(2)
	check_eq(pb.prop_count(), 0, "a freed one left")
	check_eq(pb.mesh_count(), 0, "nothing left to draw")


func test_a_kicked_prop_leaves_and_its_rubble_draws_itself() -> void:
	var p: KitProp = await _place(&"crate")
	var pb := _batch()
	check(pb != null and pb.has(p), "in")
	var bodies := p.go_loose(Vector3(1.5, 0, 0))
	await physics_frames(2)
	check(pb == null or not pb.has(p), "gone loose, it left")
	var drawn := 0
	for rb in bodies:
		for mi: MeshInstance3D in rb.find_children("*", "MeshInstance3D", false, false):
			if mi.is_visible_in_tree():
				drawn += 1
	check(drawn >= p.member_count() - 2, "its members drawn in their rubble (%d)" % drawn)
