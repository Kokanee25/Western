extends TestCase
## Men sit in the prop kit's chairs (Seating): a man walks to a chair, faces out of it and sits back
## in it; an outlaw takes a seated drink and gets up when it's done (Sean, 2026-10-22).

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


func _chair(at: Vector3, yaw := 0.0) -> KitProp:
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	return chair


func test_he_walks_to_a_free_chair_and_sits_back_in_it() -> void:
	var chair := _chair(Vector3(0, 0, -3), 0.7)
	var man := HumanBody.new()
	world.add_child(man)
	await physics_frames(5)
	check(Seating.free_chair_near(get_tree(), man.global_position) == chair, "the chair is free and near")
	var sat := false
	for i in 600:
		sat = Seating.sit_step(man, chair, 1.0 / 60.0)
		if sat:
			break
		await physics_frames(1)
	check(sat and chair.seated == man, "he gets to it and sits")
	check(man.pose == &"sit_back", "sat back in it")
	var out := chair.global_basis.z
	var front := -(man.parts[&"chest"] as Node3D).global_basis.z
	check(Vector2(front.x, front.z).normalized().dot(Vector2(out.x, out.z).normalized()) > 0.8, "facing out of the chair")
	check(Seating.free_chair_near(get_tree(), man.global_position) == null, "and it isn't free now")


func test_an_outlaw_takes_a_seated_drink_and_gets_up_after() -> void:
	var chair := _chair(Vector3(1.5, 0, 0), PI)
	var man := HumanBody.new()
	var brain := OutlawBrain.new()
	brain.name = "Brain"
	brain.agenda = [{"do": &"drink", "seconds": 4.0, "sit": true}, {"do": &"wait", "seconds": 60.0}]
	man.add_child(brain)
	world.add_child(man)
	var sat := false
	for i in 240:
		await physics_frames(1)
		sat = sat or chair.seated == man
	check(sat, "he sits for his drink")
	for i in 240:
		await physics_frames(1)
		if chair.seated == null:
			break
	check(chair.seated == null and man.pose != &"sit_back", "and he's up when it's drunk")


## A chair drawn up to a table faces into it: up out of it, he steps aside of it, not onto the table's
## top (the Drifter stood up onto the card table, and it was flung by his feet when it went loose, #1077).
func test_up_from_a_chair_at_a_table_he_stands_beside_it() -> void:
	var chair := _chair(Vector3.ZERO)
	var spot := Seating.spot(chair)
	var table := StaticBody3D.new()
	table.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.75, 0.9)
	shape.shape = box
	table.add_child(shape)
	world.add_child(table)
	table.global_position = Vector3(spot.x, 0.375, spot.z + 0.6)
	var man := HumanBody.new()
	world.add_child(man)
	man.global_position = spot
	await physics_frames(5)
	check(Seating.sit_step(man, chair, 1.0 / 60.0) and chair.seated == man, "sat at the table")
	await physics_frames(30)
	Seating.stand_up(man, chair)
	await physics_frames(30)
	var p := man.global_position
	var over := absf(p.x - table.global_position.x) < 0.45 and absf(p.z - table.global_position.z) < 0.45
	check(not over, "not standing over the table (at %s)" % p)
	check(p.y < 0.2, "on the floor, not its top (y %.2f)" % p.y)
	check(chair.seated == null and man.pose == &"stand", "up out of the chair")
