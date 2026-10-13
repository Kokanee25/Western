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


## A falling beam lands on you: you take the blow as anyone would (the soak, 2026-10-13: rubble
## passes the blow's momentum, which your wounds didn't take, so it errored and you felt nothing).
func test_a_beam_falling_on_you_hurts_you() -> void:
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3(3, 0, 0)
	await physics_frames(2)
	var hits := []
	var on_hit := func(info: Dictionary) -> void: hits.append(info)
	Events.body_hit.connect(on_hit)
	var rb := s._new_rubble([&"rig/post"])
	rb.set_meta(&"v", Vector3(0, -6.0, 0))
	s._on_rubble_hit(player, rb)
	await physics_frames(2)
	Events.body_hit.disconnect(on_hit)
	var blows := hits.filter(func(h: Dictionary) -> bool: return h.get("person") == player and h.get("kind") == &"blow")
	check_eq(blows.size(), 1, "the beam caught you once")


## A man coming into the street doesn't fling what's lying where his parent's origin is (the
## nightly soak, 2026-10-13: the gang, added and then moved to the edge of town, swept their limbs
## 50 m in one step and a fallen stud went off at 500 m/s).
func test_a_man_coming_into_town_leaves_the_rubble_lying() -> void:
	s.add_member("stud", &"post", &"framing", Vector3(0.1, 0.1, 2.0), Vector3(0.0, 0.05, 0.0))
	var ids: Array[StringName] = [&"rig/stud"]
	s._drop(ids)
	await physics_frames(60)
	var rb := s.rubble[-1] as RigidBody3D
	var at := rb.global_position
	var man := HumanBody.new()
	man.person_id = &"stranger"
	man.enter(world, Vector3(-50, 0, -9), -PI * 0.5)
	var top := 0.0
	for i in 30:
		await physics_frames(1)
		top = maxf(top, rb.linear_velocity.length())
	check(top < 1.0, "the stud lies still (top speed %.1f m/s)" % top)
	check(rb.global_position.distance_to(at) < 0.1, "where it was")
	check(man.global_position.distance_to(Vector3(-50, 0, -9)) < 0.01, "and he's where he was put")
	check(absf(wrapf(man.global_rotation.y + PI * 0.5, -PI, PI)) < 0.01, "facing east")


## A carved member (its shape the concave mesh of what's left) falling as rubble lands on its box:
## a moving body can't be concave, and one that was fell through the ground (a sign carved by a
## blast, then dropped with what held it: the nightly soak, 2026-10-13).
func test_a_carved_member_falls_on_its_box() -> void:
	var sign := s.add_member("sign", &"trim", &"sign", Vector3(1.6, 0.6, 0.03), Vector3(0, 3.0, 0))
	var cs: CollisionShape3D = null
	for c in sign.get_children():
		if c is CollisionShape3D:
			cs = c
	var carved := ConcavePolygonShape3D.new()
	carved.set_faces(BoxMesh.new().get_faces())
	cs.shape = carved
	var ids: Array[StringName] = [&"rig/sign"]
	s._drop(ids)
	check(cs.shape is BoxShape3D, "it falls on its box (%s)" % cs.shape.get_class())
	await physics_frames(120)
	var rb := s.rubble[-1] as RigidBody3D
	check(rb.global_position.y > -0.2, "and lies on the ground (y %.2f)" % rb.global_position.y)


## A piece of rubble burnt away as it lies goes with its body, whatever else hangs on it: a body
## with nothing solid left falls through the ground (the nightly soak, 2026-10-13).
func test_rubble_burnt_away_goes_whatever_hangs_on_it() -> void:
	var post := s.get_member(&"rig/post")
	var ids: Array[StringName] = [&"rig/post"]
	s._drop(ids)
	var rb := s.rubble[-1] as RigidBody3D
	rb.add_child(Node3D.new())  # something else on it (a sound, a mark)
	var fire := FireSystem.new()
	world.add_child(fire)
	fire._consume(post)
	await physics_frames(2)
	check(not is_instance_valid(rb), "the body's gone with what was left of it")


## A member going this frame (burnt away as its neighbours gave way) has nothing to land with:
## no rubble is kept for it.
func test_a_clump_whose_shape_is_going_isnt_rubble() -> void:
	var post := s.get_member(&"rig/post")
	for c in post.get_children():
		if c is CollisionShape3D:
			c.queue_free()
	var before := s.rubble.size()
	var ids: Array[StringName] = [&"rig/post"]
	s._drop(ids)
	check_eq(s.rubble.size(), before, "no body kept that would fall through the ground")
