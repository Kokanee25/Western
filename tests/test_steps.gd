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
