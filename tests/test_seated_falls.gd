extends TestCase
## A man sat back in the prop kit's chair (pose sit_back) whose back legs are kicked out goes over
## backwards with it and ends on his back (Sean, 2026-10-21; the ragdoll lab's group U).

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.WORLD
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


func test_back_legs_kicked_out_he_goes_over_backwards_onto_his_back() -> void:
	# The chair faces -z as he does, its seat point over his origin (as the lab's kit_chair).
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var sp := chair.seat_position()
	chair.global_position -= Vector3(sp.x, 0.0, sp.z)
	var man := HumanBody.new()
	world.add_child(man)
	man.set_pose(&"sit_back")
	await physics_frames(50)
	check(chair.sit(man), "he sits")
	await physics_frames(10)
	var start := (man.parts[&"chest"] as Node3D).global_position
	# A kick at the foot of each back leg from behind (48 N·s, a kicking leg's 8 kg).
	var did: Array[StringName] = []
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken:
			did.append(chair.take_blow(m, Vector3(m.global_position.x, 0.12, m.global_position.z), Vector3(0, 0, -48), 8.0))
	check(did.has(&"broke"), "the kick breaks a back leg under him (%s)" % [did])
	# The chair goes over on its own balance (KitProp._check_balance, a tick or two on).
	for i in 30:
		if man.limp:
			break
		await physics_frames(1)
	check(chair.loose, "the chair goes over")
	check(man.limp, "he goes down with it")
	if not man.limp:
		return
	# His front in his ragdoll chest's own frame, as he goes over (he faced -z).
	var chest := man.parts[&"chest"] as Node3D
	var front_local := chest.global_basis.orthonormalized().inverse() * Vector3.FORWARD
	await physics_frames(240)
	var up := (chest.global_basis.orthonormalized() * front_local).normalized().dot(Vector3.UP)
	check(up > 0.5, "he ends on his back (his chest's front %.2f up)" % up)
	check(chest.global_position.z > start.z + 0.2, "behind where he sat (%.2f m)" % (chest.global_position.z - start.z))
