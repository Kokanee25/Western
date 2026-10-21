extends TestCase
## The railing part (Railing): balusters on whatever floor is under them, the rail on them in spans,
## each its own member, so a man thrown into it breaks the span he hits and the rest stands. The
## saloon's balcony and stair rails are built of it.

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
	await physics_frames(1)


## A level railing 2.4 m long on a sill on the ground, along x at z = -0.5.
func _level() -> Structure:
	var s := Structure.new()
	s.structure_id = &"rail_test"
	world.add_child(s)
	s.add_member("deck", &"sill", &"floor", Vector3(4.0, 0.05, 2.0), Vector3(0, 0.025, 0.45))
	Railing.build(s, "rail", Vector3(-1.2, 0.05, -0.5), Vector3(1.2, 0.05, -0.5), {"height": 1.0})
	s.infer_supports()
	return s


func _kinds(s: Structure) -> Dictionary:
	var out := {}
	for m in s.get_members():
		out[m.kind] = int(out.get(m.kind, 0)) + 1
	return out


func test_a_level_railing_stands_in_spans() -> void:
	var s := _level()
	check(s.members_without_load_path().is_empty(), "it stands: %s" % [s.members_without_load_path()])
	var kinds := _kinds(s)
	check_eq(int(kinds.get(&"trim", 0)), 2, "a 2.4 m rail in two spans")
	check(int(kinds.get(&"baluster", 0)) >= 16, "balusters every 0.15 (%d)" % int(kinds.get(&"baluster", 0)))
	# Each baluster reaches up to the rail: the rail rests on them.
	var span := s.get_member(&"rail_test/rail/rail/00")
	check(span.supported_by.size() >= 5, "a span rests on its balusters (%d)" % span.supported_by.size())


func test_a_stair_railing_stands_on_its_treads() -> void:
	var s := Structure.new()
	s.structure_id = &"stair_test"
	world.add_child(s)
	# Ten treads rising 0.19 on 0.25 along x, and a newel at the foot.
	var posts: Array = []
	for i in 10:
		var top := 0.19 * (i + 1)
		s.add_member("tread/%02d" % i, &"furniture_top", &"floor", Vector3(0.27, 0.035, 0.9),
				Vector3(0.25 * i, top - 0.0175, 0.0))
		# Each tread on a block down to the ground (a stair's strings, simply).
		s.add_member("string/%02d" % i, &"post", &"framing", Vector3(0.05, top - 0.035, 0.05), Vector3(0.25 * i, (top - 0.035) * 0.5, 0.0))
		posts.append(Vector3(0.25 * i, top, 0.4))
	s.add_member("newel", &"post", &"dark_trim", Vector3(0.09, 1.05, 0.09), Vector3(-0.2, 0.525, 0.4))
	Railing.build(s, "rail", Vector3(-0.2, 1.05, 0.4), Vector3(2.25, 1.9 + 0.95, 0.4),
			{"height": 0.025, "posts": posts, "overhang": 0.0})
	s.infer_supports()
	var spans := 0
	for m in s.get_members():
		if m.kind == &"trim":
			spans += 1
	check(spans >= 3, "a 3.4 m sloped rail in spans (%d)" % spans)
	check(s.members_without_load_path().is_empty(), "every span rests on the balusters under it: %s" % [s.members_without_load_path()])


func test_the_saloons_balcony_and_stair_rails_are_railings() -> void:
	var saloon := SaloonBuilding.new()
	saloon.structure_id = &"saloon"
	add_child(saloon)
	await physics_frames(1)
	for id: StringName in [&"saloon/balcony/rail_z/rail/00", &"saloon/stair/rail/00", &"saloon/stair/baluster/05"]:
		check(saloon.get_member(id) != null, "%s is the railing part's" % id)
	check(saloon.members_without_load_path().is_empty(), "the saloon stands: %s" % [saloon.members_without_load_path().slice(0, 6)])
	saloon.queue_free()


func test_a_man_thrown_into_it_breaks_the_span_he_hits_and_goes_through() -> void:
	var s := _level()
	var man := HumanBody.new()
	world.add_child(man)
	man.global_transform = Transform3D(Basis(), Vector3(0.6, 0.05, 0.6))
	await physics_frames(2)
	man.go_limp()
	for rb: Variant in man.parts.values():
		(rb as RigidBody3D).linear_velocity = Vector3(0, 0, -3.5)
	await physics_frames(24)
	var chest := man.parts[&"chest"] as RigidBody3D
	var hit := s.get_member(&"rail_test/rail/rail/01")
	var other := s.get_member(&"rail_test/rail/rail/00")
	check(hit.broken, "the span he hit broke")
	check(not other.broken, "the other span stands")
	check(chest.linear_velocity.z < -0.5, "he goes on through, not stopped at it (%.2f m/s)" % chest.linear_velocity.z)
