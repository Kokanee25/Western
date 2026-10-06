extends TestCase
## Main Street's step 3 (docs/briefs/main-street.md): the telegraph office, the doctor's and the
## bank, furnished inside; the well and windpump behind the jail (water for buckets); the corral
## behind the livery. Each stands as built, the bank's safe stops a ball, the well fills a bucket.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _building(kind: StringName, w: float, d: float) -> FalseFrontBuilding:
	var b := FalseFrontBuilding.new()
	b.structure_id = kind
	b.interior = kind
	b.width = w
	b.depth = d
	world.add_child(b)
	return b


func test_each_stands_as_built() -> void:
	var made: Array[Structure] = [_building(&"telegraph", 6.0, 8.0), _building(&"doctor", 7.0, 10.0), _building(&"bank", 8.0, 10.0)]
	for s: Structure in [Well.new(), Windpump.new(), Corral.new()]:
		world.add_child(s)
		made.append(s)
	for s in made:
		var a := StructuralAnalysis.new().analyse(s)
		check(a.overloaded().is_empty(), "%s: nothing overloaded as built: %s" % [s.structure_id, a.overloaded().slice(0, 5)])
		check(a.falling.is_empty(), "%s: nothing unsupported: %s" % [s.structure_id, a.falling.slice(0, 5)])


func test_each_is_furnished_for_its_trade() -> void:
	var telegraph := _building(&"telegraph", 6.0, 8.0)
	check(telegraph.get_member(&"telegraph/desk/key") != null, "the telegraph's key on the operator's desk")
	check(telegraph.get_member(&"telegraph/batteries/jar0") != null, "and its battery jars")
	var doctor := _building(&"doctor", 7.0, 10.0)
	check(doctor.get_member(&"doctor/table/top") != null, "the doctor's operating table")
	check(doctor.get_member(&"doctor/cot/top") != null, "and a cot")
	var bank := _building(&"bank", 8.0, 10.0)
	check(bank.get_member(&"bank/safe/door") != null, "the bank's safe")
	check(bank.get_member(&"bank/cage/rail") != null, "and the teller's cage")
	for b: FalseFrontBuilding in [telegraph, doctor, bank]:
		check(b.find_children("*", "OilLamp", true, false).size() >= 2, "%s has its lamps" % b.structure_id)


func test_a_ball_flattens_on_the_safe() -> void:
	var bank := _building(&"bank", 8.0, 10.0)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(2)
	var door := bank.get_member(&"bank/safe/door")
	var target := door.global_position
	var from := target + bank.global_basis * Vector3(0.0, 0.0, -2.5)  # in front of it
	var hits: Array = []
	var on_hit := func(info: Dictionary) -> void: hits.append(info)
	Events.bullet_hit.connect(on_hit)
	ballistics.fire(from, target - from, 274.0, 0.0165, 0.0115)
	await physics_frames(20)
	Events.bullet_hit.disconnect(on_hit)
	var on_safe := hits.filter(func(h: Dictionary) -> bool: return h.get("collider") == door)
	check(not on_safe.is_empty(), "it struck the safe's door")
	check_eq(Ballistics.surface_of(door, Vector3.FORWARD), &"metal", "iron is a metal surface (balls glance off it)")
	var back := bank.get_member(&"bank/safe/back")
	check(not hits.any(func(h: Dictionary) -> bool: return h.get("collider") == back), "and never reached the back plate")
	check(not door.broken, "the door holds (broken %s)" % door.broken)
	check(door.voxels == null, "not carved (voxels %s)" % door.voxels)


func test_the_well_fills_a_bucket() -> void:
	var well := Well.new()
	world.add_child(well)
	await physics_frames(2)
	check(well.is_in_group(&"water_source"), "a water source")
	var water := well.get_node(^"Water") as Node3D
	check(water != null and water.global_position.y > 0.3 and water.global_position.y < well.ring_height,
			"its water within reach over the ring")


func test_in_the_street_you_come_round_at_the_doctors() -> void:
	world.queue_free()
	await physics_frames(1)
	world = load("res://scenes/test_street.tscn").instantiate()
	add_child(world)
	await physics_frames(5)
	var player: Player = world.get_node(^"Player")
	var doctor := world.get_node(^"Doctor") as FalseFrontBuilding
	player.wounds.physiology.blood_ml = 2800.0
	await physics_frames(10)
	check(player.wounds.out_cold > 0.0, "out cold")
	await wait_until(func() -> bool: return player.wounds.physiology.is_conscious(), 60 * 8)
	var local := doctor.to_local(player.global_position)
	check(local.x > 0.0 and local.x < doctor.width and local.z > 0.0 and local.z < doctor.depth,
			"inside the doctor's (%s)" % local)
