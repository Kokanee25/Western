extends TestCase
## Integration on the real test street: walk from the road, up onto the boardwalk and through
## the door into the store.

var street: Node3D
var player: Player


func before_each() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	player = street.get_node(^"Player")
	await physics_frames(5)


func after_each() -> void:
	Input.action_release(&"move_forward")
	street.queue_free()
	await physics_frames(2)


func test_walk_from_road_into_store() -> void:
	var store: FalseFrontBuilding = street.get_node(^"Store")
	var door := store.door_rect
	player.global_position = store.to_global(Vector3(door.get_center().x, 0.0, -8.0))
	player.rotation = Vector3.ZERO
	player.rotate_y(PI)  # face +Z, toward the store
	player.velocity = Vector3.ZERO
	await physics_frames(10)
	Input.action_press(&"move_forward")
	var inside := await wait_until(func() -> bool: return store.to_local(player.global_position).z > 2.0, 60 * 8)
	Input.action_release(&"move_forward")
	var local := store.to_local(player.global_position)
	check(inside, "walked through the door (ended at %s)" % local)
	check_near(local.y, store.floor_top, 0.06, "standing on the store floor")
