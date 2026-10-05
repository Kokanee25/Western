extends TestCase
## Rubble that can't land (found by the first nightly soak, 2026-10-05): a member burnt away and
## then snapped, and a falling clump with no working collision shape (shattered glass, burnt-away
## members), which fell through the ground for ever.

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
	s.add_member("post", &"post", &"framing", Vector3(0.1, 2.0, 0.1), Vector3(0, 1.0, 0))
	s.add_member("pane", &"glass", &"glass", Vector3(0.6, 0.5, 0.004), Vector3(0, 2.3, 0))
	s.infer_supports()
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_a_member_burnt_away_then_snapped_is_just_broken() -> void:
	var post := s.get_member(&"rig/post")
	post.consumed = true
	for c in post.get_children():
		c.free()
	var before := s.rubble.size()
	s._snap(post, 0.0)
	check(post.broken, "it's broken")
	check_eq(s.rubble.size(), before, "and nothing falls: there's nothing left of it")


func test_a_clump_with_nothing_solid_isnt_rubble() -> void:
	var pane := s.get_member(&"rig/pane")
	for c in pane.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true  # as a shattered pane's is
	var before := s.rubble.size()
	var ids: Array[StringName] = [&"rig/pane"]
	s._drop(ids)
	check_eq(s.rubble.size(), before, "a falling pane of nothing solid isn't kept as a body that falls for ever")
	check(pane.broken, "the pane's down all the same")


func test_rubble_lost_under_the_ground_is_removed() -> void:
	var before := s.rubble.size()
	var rb := s._new_rubble([&"rig/post"])
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1, 0.1, 0.1)
	cs.shape = box
	rb.add_child(cs)
	rb.collision_mask = 0  # nothing to land on, and nothing lands on it
	rb.collision_layer = 0
	rb.global_position = Vector3(0, -4.0, 0)
	var y := [0.0]
	for i in 60:
		await physics_frames(1)
		if is_instance_valid(rb) and not rb.is_queued_for_deletion():
			y[0] = rb.global_position.y
	print("    last seen at y %.1f, sleeping %s" % [y[0], rb.sleeping if is_instance_valid(rb) else "gone"])
	check(not is_instance_valid(rb) or rb.is_queued_for_deletion(), "a piece that's gone through the ground is taken away")
	check_eq(s.rubble.size(), before, "and isn't counted as rubble")
