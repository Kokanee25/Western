extends TestCase
## Knocked off his feet unhurt (his chair gone, a shove), a man lies a moment and gets up again;
## one who simply goes limp stays down (HumanBody.get_up; Sean, 2026-10-22).

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


func _wait_up(man: HumanBody, frames: int) -> void:
	for i in frames:
		if not man.limp and not man.rising:
			return
		await physics_frames(1)


func test_kicked_over_in_his_chair_he_gets_up_again() -> void:
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var sp := chair.seat_position()
	chair.global_position -= Vector3(sp.x, 0.0, sp.z)
	var man := HumanBody.new()
	world.add_child(man)
	man.set_pose(&"sit_back")
	await physics_frames(50)
	chair.sit(man)
	await physics_frames(10)
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken:
			chair.take_blow(m, Vector3(m.global_position.x, 0.12, m.global_position.z), Vector3(0, 0, -48), 8.0)
	await physics_frames(30)
	check(man.limp, "he goes over with the chair")
	await _wait_up(man, 600)
	check(not man.limp and not man.rising, "and is up again within 10 s")
	await physics_frames(30)
	var head := (man.parts[&"head"] as Node3D).global_position.y
	check(head > 1.4, "standing: his head at %.2f m" % head)


func test_shoved_down_he_gets_up_again() -> void:
	var man := HumanBody.new()
	world.add_child(man)
	await physics_frames(10)
	man.take_blow(null, 400.0, (man.parts[&"chest"] as Node3D).global_position, Vector3(0, 0, -1), 250.0)
	check(man.limp, "the shove puts him down")
	await _wait_up(man, 600)
	check(not man.limp and not man.rising, "and he's up again within 10 s")


func test_gone_limp_he_stays_down() -> void:
	var man := HumanBody.new()
	world.add_child(man)
	await physics_frames(10)
	man.go_limp()
	await physics_frames(360)
	check(man.limp, "a man who simply goes limp (a faint, a wound) doesn't get up by himself")


func test_he_comes_up_clear_of_his_chair() -> void:
	# His legs over the chair he went down with, he rolls off it and comes up the other way, not
	# kneeling in it (2026-10-24: 2.9 s of it before).
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var sp := chair.seat_position()
	chair.global_position -= Vector3(sp.x, 0.0, sp.z)
	var man := HumanBody.new()
	world.add_child(man)
	man.set_pose(&"sit_back")
	await physics_frames(50)
	chair.sit(man)
	await physics_frames(10)
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken:
			chair.take_blow(m, Vector3(m.global_position.x, 0.12, m.global_position.z), Vector3(0, 0, -48), 8.0)
	await physics_frames(30)
	check(man.limp, "he goes over with the chair")
	var wreck := 0
	for i in 700:
		if not man.limp and not man.rising:
			break
		if man.rising and _in_wreck(man, chair) > 0.05:
			wreck += 1
		await physics_frames(1)
	check(not man.limp and not man.rising, "he's up")
	check(wreck < 72, "his legs in the wreck for %.2f s as he rose (2.9 s before)" % (wreck / 60.0))


func test_a_hat_knocked_off_goes_back_on() -> void:
	# HumanBody.wear_hat (he picks it up as he gets up, if it's lying near).
	var man := HumanBody.new()
	world.add_child(man)
	await physics_frames(5)
	if man.hat_body == null:
		return  # this body wears none
	var hat := man.knock_hat_off(Vector3(1, 0, 0))
	await physics_frames(30)
	check(man.hat_off and man.hat_body == null, "it's off")
	check(man.wear_hat(hat), "he puts it back on")
	await physics_frames(2)
	check(not man.hat_off and man.hat_body != null, "it's on, its hitbox back")
	check(not is_instance_valid(hat) or hat.is_queued_for_deletion(), "the loose one's gone")


## How deep his legs are in the chair's pieces (m), as the ragdoll lab measures it.
func _in_wreck(man: HumanBody, chair: KitProp) -> float:
	var pieces := {}
	for rb in chair.rubble:
		if is_instance_valid(rb):
			pieces[(rb as RigidBody3D).get_rid()] = true
	var space := man.get_world_3d().direct_space_state
	var deepest := 0.0
	for sid: StringName in [&"thigh_l", &"thigh_r", &"shin_l", &"shin_r", &"foot_l", &"foot_r"]:
		for c in (man.parts[sid] as Node).get_children():
			var cs := c as CollisionShape3D
			if cs == null or cs.shape == null:
				continue
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = cs.shape
			q.transform = cs.global_transform
			q.collision_mask = Layers.WORLD
			var others: Array[RID] = []
			var any := false
			for hit: Dictionary in space.intersect_shape(q, 8):
				if pieces.has(hit.rid):
					any = true
				else:
					others.append(hit.rid)
			if not any:
				continue
			q.exclude = others
			var pts := space.collide_shape(q, 8)
			for k in range(0, pts.size() - 1, 2):
				deepest = maxf(deepest, (pts[k] as Vector3).distance_to(pts[k + 1]))
	return deepest
