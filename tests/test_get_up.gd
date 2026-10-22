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
