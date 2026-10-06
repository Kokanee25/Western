extends TestCase
## Boardwalks up on steps (Sean: "up on steps", as in the street picture): a walk 0.6 m up with a
## flight of steps; you and a townsman go up the steps, and the edge elsewhere is a step too high.

var world: Node3D
var walk: Boardwalk


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	walk = Boardwalk.new()
	walk.structure_id = &"walk"
	walk.length = 12.0
	walk.top = 0.6
	walk.steps = [Vector2(3.0, 2.0)]
	world.add_child(walk)
	walk.position = Vector3(-6, 0, 3)  # the street edge at z = 3 - 2.4 = 0.6, the street to -Z
	await physics_frames(3)


func after_each() -> void:
	Input.action_release(&"move_forward")
	world.queue_free()
	await physics_frames(2)


func _player(x: float) -> Player:
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3(x, 0, -4)
	player.rotation = Vector3.ZERO
	player.rotate_y(PI)  # face +Z, toward the walk
	await physics_frames(10)
	return player


func test_the_steps_are_there() -> void:
	var steps := walk.members.values().filter(func(m: StructureMember) -> bool: return String(m.member_id).begins_with("walk/step/"))
	check_eq(steps.size(), 2, "two steps below the walk (three rises of 0.2 m)")


func test_you_walk_up_the_steps() -> void:
	var player := await _player(walk.position.x + 3.0)
	Input.action_press(&"move_forward")
	var up := await wait_until(func() -> bool: return player.global_position.z > 1.6, 60 * 6)
	Input.action_release(&"move_forward")
	check(up, "walked up onto the walk (at %s)" % player.global_position)
	check_near(player.global_position.y, 0.6, 0.08, "standing on it")


func test_the_edge_elsewhere_is_too_high() -> void:
	var player := await _player(walk.position.x + 9.0)
	Input.action_press(&"move_forward")
	await physics_frames(60 * 3)
	Input.action_release(&"move_forward")
	check(player.global_position.z < 0.7, "stopped at the edge (at %s)" % player.global_position)
	check(player.global_position.y < 0.1, "still in the street")


func test_a_townsman_walks_up_by_the_steps() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	var foot := walk.to_global(walk.step_foot(0))
	man.global_position = foot + Vector3(0, 0, -3)
	await physics_frames(3)
	var top := walk.to_global(Vector3(3.0, 0.6, -1.2))
	var path: Array[Vector3] = [foot, top]
	var arrived := await wait_until(func() -> bool:
		if path.is_empty():
			return true
		if man.walk_to(path[0], 1.4, get_physics_process_delta_time()):
			path.pop_front()
		return path.is_empty(), 60 * 10)
	check(arrived, "he got there (at %s)" % man.global_position)
	check_near(man.global_position.y, 0.6, 0.08, "up on the walk")


func test_steps_at_the_end_join_a_lower_walk() -> void:
	# A walk 0.4 m higher beside this one (the saloon's beside the store's), steps down at its
	# west end: you walk along the low walk, up them and on along the high one, and back down.
	var high := Boardwalk.new()
	high.structure_id = &"high"
	high.length = 8.0
	high.top = 1.0
	high.end_steps = [Vector2(0, 0.6)]
	world.add_child(high)
	high.position = walk.position + Vector3(walk.length, 0, 0)
	await physics_frames(3)
	var treads := high.members.values().filter(func(m: StructureMember) -> bool: return String(m.member_id).begins_with("high/end_step/"))
	check_eq(treads.size(), 2, "two treads, the first level with the low walk")
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = walk.position + Vector3(walk.length - 2.0, 0.6, -1.2)
	player.rotation = Vector3(0, -PI * 0.5, 0)  # face +X, along the walks
	await physics_frames(10)
	Input.action_press(&"move_forward")
	var up := await wait_until(func() -> bool: return player.global_position.x > high.position.x + 2.0, 60 * 6)
	Input.action_release(&"move_forward")
	check(up, "walked up the steps onto the high walk (at %s)" % player.global_position)
	check_near(player.global_position.y, 1.0, 0.08, "standing on it")
	player.rotation = Vector3(0, PI * 0.5, 0)  # back the other way
	Input.action_press(&"move_forward")
	var down := await wait_until(func() -> bool: return player.global_position.x < high.position.x - 1.5, 60 * 6)
	Input.action_release(&"move_forward")
	check(down, "walked back down onto the low walk (at %s)" % player.global_position)
	check_near(player.global_position.y, 0.6, 0.08, "standing on it")
