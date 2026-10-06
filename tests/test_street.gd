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
	# Up the store's steps (Sean: the boardwalks up on steps), along the walk and in at the door.
	var store: FalseFrontBuilding = street.get_node(^"Store")
	var walk: Boardwalk = street.get_node(^"Boardwalk")
	var door := store.door_rect
	var steps: Vector2 = walk.steps[0]
	player.global_position = store.to_global(Vector3(steps.x, 0.0, -8.0))
	player.rotation = Vector3.ZERO
	player.rotate_y(PI)  # face +Z, toward the store
	player.velocity = Vector3.ZERO
	await physics_frames(10)
	Input.action_press(&"move_forward")
	var up := await wait_until(func() -> bool: return store.to_local(player.global_position).z > -1.2, 60 * 8)
	check(up, "up the steps (at %s)" % store.to_local(player.global_position))
	check_near(store.to_local(player.global_position).y, walk.top, 0.06, "on the walk")
	player.rotation = Vector3.ZERO
	player.rotate_y(-PI * 0.5)  # face +X, along the walk to the door
	await wait_until(func() -> bool: return store.to_local(player.global_position).x > door.get_center().x, 60 * 8)
	player.rotation = Vector3.ZERO
	player.rotate_y(PI)
	var inside := await wait_until(func() -> bool: return store.to_local(player.global_position).z > 2.0, 60 * 8)
	Input.action_release(&"move_forward")
	var local := store.to_local(player.global_position)
	check(inside, "walked through the door (ended at %s)" % local)
	check_near(local.y, store.floor_top, 0.06, "standing on the store floor")


func test_outlaw_waits_at_the_range() -> void:
	var spawner: OutlawSpawner = street.get_node(^"OutlawSpawn")
	var man := spawner.outlaw
	check(man != null and man.is_inside_tree(), "an outlaw stands at the range")
	check(man.global_position.distance_to(spawner.global_position) < 0.01, "where the spawn is")
	check_eq(spawner.brain().mood, OutlawBrain.Mood.CALM, "minding his own business")
	man.physiology.blood_ml = 2000.0
	await physics_frames(3)
	check(man.limp, "shot to pieces, he's down")
	Input.action_press(&"debug_reset_outlaw")
	await process_frames(2)
	Input.action_release(&"debug_reset_outlaw")
	await physics_frames(3)
	check(spawner.outlaw != man and not spawner.outlaw.limp, "F9 brings a fresh one")
	var outlaws := get_tree().get_nodes_in_group(&"people").filter(func(n: Node) -> bool: return n.get_node_or_null(^"Brain") is OutlawBrain)
	check_eq(outlaws.size(), 1, "and clears the old one away (the townsfolk stay)")


func test_f11_breaks_the_post_you_look_at() -> void:
	var store: FalseFrontBuilding = street.get_node(^"Store")
	var post := store.get_member(&"store/porch/post0")
	# Stand in the street facing the post, eye level with it.
	var at := post.global_position
	player.global_position = at + Vector3(0, -at.y, -3.0)
	player.rotation = Vector3(0, PI, 0)  # face +Z
	player.velocity = Vector3.ZERO
	await physics_frames(3)
	player.add_look(Vector2(0, -player.get_pitch_degrees() - 5.0))
	var breaker: DebugBreaker = street.get_node(^"DebugBreaker")
	var m := breaker.break_looked_at()
	check(m == post, "broke the post (%s)" % [m.member_id if m else "nothing"])
	check(store.get_member(&"store/porch/beam").broken, "the beam can't carry the porch off one post")
	check(not store.get_member(&"store/roof/ridge").broken, "the store stands")
