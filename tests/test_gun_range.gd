extends TestCase
## The revolver in the player's hand on the real test street: controls drive the mechanism,
## shots leave holes in the target boards and stop in the backstop, smoke hangs in the air,
## reloading drops real brass, the holster shows the gun on the hip.

const GUN_ACTIONS := [&"fire", &"aim", &"cock", &"reload", &"holster"]

var street: Node3D
var player: Player
var gun: RevolverViewmodel
var hits: Array[Dictionary] = []


func before_each() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	player = street.get_node(^"Player")
	gun = player.get_node(^"Head/Camera3D/Gun")
	gun.needs_captured_mouse = false
	# You walk about holstered; these tests start with it drawn.
	gun.take_out()
	await wait_until(func() -> bool: return gun.is_ready_in_hand(), 60)
	hits.clear()
	Events.bullet_hit.connect(_on_hit)
	# Stand at the range line facing the target board, 16 m east, and line up on the black square.
	player.global_position = Vector3(14, 0, -8.4)
	player.rotation = Vector3(0, deg_to_rad(-90), 0)
	player.velocity = Vector3.ZERO
	await physics_frames(5)
	var eye := player.camera.global_position
	player.add_look(Vector2(0, rad_to_deg(atan2(1.22 - eye.y, 30.0 - eye.x)) - player.get_pitch_degrees()))


func after_each() -> void:
	for a in GUN_ACTIONS:
		Input.action_release(a)
	Events.bullet_hit.disconnect(_on_hit)
	street.queue_free()
	await physics_frames(2)


func _on_hit(info: Dictionary) -> void:
	hits.append(info)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await process_frames(2)
	Input.action_release(action)
	await process_frames(1)


func _wait_ready() -> void:
	await wait_until(func() -> bool: return gun.state.ready(), 120)


func test_starts_in_hand_with_five_rounds() -> void:
	check(gun.drawn and gun.visible, "gun in hand")
	check_eq(gun.state.rounds_loaded(), 5, "five loaded")
	check(gun.model.muzzle != null and gun.hand.fingers.size() == 5, "a gun and a hand with five fingers")
	check_eq(gun.hand.fingers["index"].size(), 3, "three bones in a finger")


func test_trigger_alone_does_nothing() -> void:
	await _tap(&"fire")
	await physics_frames(20)
	check(hits.is_empty(), "single action: no shot without cocking")


func test_cock_and_fire_holes_the_target() -> void:
	Input.action_press(&"aim")
	await process_frames(30)
	await _tap(&"cock")
	await _wait_ready()
	check_eq(gun.state.hammer, RevolverState.Hammer.FULL_COCK, "hammer back")
	await _tap(&"fire")
	await wait_until(func() -> bool: return hits.size() >= 2, 90)
	check(hits.size() >= 1, "the shot hit something")
	var through := hits.filter(func(h: Dictionary) -> bool:
		return String(h.member_id).begins_with("target_board/board") or String(h.member_id) == "target_board/bull")
	check(not through.is_empty(), "hit the target (%s)" % [hits.map(func(h: Dictionary) -> String: return String(h.member_id))])
	if not through.is_empty():
		check(through[0].penetrated, "went through the board")
		var board := street.get_node(^"TargetBoard").get_member(through[0].member_id) as StructureMember
		check(board.holes.size() == 1 and board.holes[0].through, "and left a hole you can see through")
	var stopped := hits.filter(func(h: Dictionary) -> bool: return String(h.member_id).begins_with("target_board/stop"))
	check(not stopped.is_empty() and not stopped[0].penetrated, "stopped in the backstop timbers")
	check(get_tree().get_nodes_in_group(&"revolver").size() == 1, "one revolver")
	var smoke := street.find_children("*", "GunSmoke", true, false)
	check(smoke.size() == 1, "a cloud of black-powder smoke hangs in the air")


func test_empty_then_reload_drops_brass() -> void:
	for i in 6:
		await _tap(&"cock")
		await _wait_ready()
		await _tap(&"fire")
		await _wait_ready()
	check_eq(gun.state.rounds_loaded(), 0, "five fired, then a click")
	Input.action_press(&"reload")
	await wait_until(func() -> bool: return gun.state.rounds_loaded() == 6, 60 * 12)
	Input.action_release(&"reload")
	check_eq(gun.state.rounds_loaded(), 6, "held reload fills all six")
	await process_frames(20)
	check_eq(get_tree().get_nodes_in_group(&"spent_cases").size(), 5, "five spent cases on the ground")
	await _wait_ready()
	await _tap(&"reload")
	await _wait_ready()
	check(not gun.state.gate_open, "one more press closes the gate")


func test_holster() -> void:
	await _tap(&"holster")
	await process_frames(40)
	check(not gun.drawn and not gun.visible, "holstered")
	check(player.body._holstered_grip.visible, "the grip shows in the holster")
	await _tap(&"cock")
	check_eq(gun.state.hammer, RevolverState.Hammer.DOWN, "can't cock a holstered gun")
	await _tap(&"holster")
	await process_frames(40)
	check(gun.drawn and gun.visible, "drawn again")


func test_shoot_a_can_off_the_rail() -> void:
	var cans := get_tree().get_nodes_in_group(&"cans")
	var can := cans[2] as RigidBody3D
	var eye := player.camera.global_position
	var to := can.global_position - eye
	player.rotation = Vector3(0, atan2(-to.x, -to.z), 0)
	player.add_look(Vector2(0, rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length())) - player.get_pitch_degrees()))
	Input.action_press(&"aim")
	await process_frames(30)
	var start := can.global_position
	await _tap(&"cock")
	await _wait_ready()
	await _tap(&"fire")
	await physics_frames(40)
	var moved := cans.filter(func(c: RigidBody3D) -> bool: return c.linear_velocity.length() > 0.5 or c.global_position.distance_to(start) > 0.05)
	check(not moved.is_empty(), "a can went flying")


func test_shooting_a_store_window_breaks_it() -> void:
	var store: FalseFrontBuilding = street.get_node(^"Store")
	var panes := store.members_of_kind(&"glass")
	var pane: StructureMember = panes.filter(func(m: StructureMember) -> bool: return String(m.member_id).begins_with("store/front"))[0]
	# Stand on the boardwalk in front of the window and aim at its middle.
	player.global_position = store.to_global(Vector3(pane.position.x, 0.38, -2.0))
	player.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	await physics_frames(3)
	var eye := player.camera.global_position
	var to := pane.global_position - eye
	player.rotation = Vector3(0, atan2(-to.x, -to.z), 0)
	player.add_look(Vector2(0, rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length())) - player.get_pitch_degrees()))
	Input.action_press(&"aim")
	await process_frames(30)
	await _tap(&"cock")
	await _wait_ready()
	await _tap(&"fire")
	await physics_frames(30)
	check(pane.broken, "the window broke (hits: %s)" % [hits.map(func(h: Dictionary) -> String: return String(h.member_id))])
	check(not (pane.get_child(0) as MeshInstance3D).visible, "the pane is gone")
	check(get_tree().get_nodes_in_group(&"glass_shards").size() >= 8, "shards on the ground")


func test_reloading_does_not_move_the_player() -> void:
	for i in 5:
		await _tap(&"cock")
		await _wait_ready()
		await _tap(&"fire")
		await _wait_ready()
	await physics_frames(30)
	var start := player.global_position
	Input.action_press(&"reload")
	await wait_until(func() -> bool: return gun.state.rounds_loaded() == 6, 60 * 12)
	Input.action_release(&"reload")
	await physics_frames(60)
	var drift := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
	check(get_tree().get_nodes_in_group(&"spent_cases").size() >= 5, "brass fell")
	check(drift < 0.005, "standing still while reloading (moved %.3f m)" % drift)


## Face a solid wall from this close (eye to wall, metres) with the gun up.
func _face_wall_inside_store(gap: float) -> Dictionary:
	var spawn := street.get_node(^"DebugSpawns/StoreInside") as Node3D
	player.global_position = spawn.global_position
	player.velocity = Vector3.ZERO
	player.add_look(Vector2(0, -player.get_pitch_degrees()))
	await physics_frames(3)
	var space := player.get_world_3d().direct_space_state
	for i in 8:
		var yaw := TAU * i / 8.0
		player.rotation = Vector3(0, yaw, 0)
		await physics_frames(1)
		var eye := player.camera.global_position
		var fwd := -player.camera.global_transform.basis.z
		var q := PhysicsRayQueryParameters3D.create(eye, eye + fwd * 6.0, Layers.WORLD)
		q.exclude = [player.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty() or not hit.collider is StructureMember:
			continue
		var m := hit.collider as StructureMember
		if m.kind == &"glass" or eye.distance_to(hit.position) < 1.0 or absf(hit.normal.dot(fwd)) < 0.9:
			continue
		var flat := Vector3(fwd.x, 0, fwd.z).normalized()
		player.global_position += flat * (eye.distance_to(hit.position) - gap)
		player.velocity = Vector3.ZERO
		await physics_frames(2)
		return {member = m, normal = hit.normal as Vector3}
	return {}


func test_gun_pulls_back_from_a_wall() -> void:
	var wall := await _face_wall_inside_store(0.36)
	if not check(not wall.is_empty(), "found a wall to face"):
		return
	await process_frames(40)
	var eye := player.camera.global_position
	var q := PhysicsRayQueryParameters3D.create(eye, gun.model.muzzle.global_position, Layers.WORLD)
	q.exclude = [player.get_rid()]
	check(player.get_world_3d().direct_space_state.intersect_ray(q).is_empty(), "the muzzle stays this side of the wall")
	check(gun.tuck > 0.5, "gun tucked back (%.2f)" % gun.tuck)
	# Backing off lets the gun come up again.
	player.global_position -= -player.global_transform.basis.z * 1.2
	await physics_frames(2)
	await process_frames(40)
	check(gun.tuck < 0.05, "gun back up away from the wall (%.2f)" % gun.tuck)


func test_shot_against_a_wall_hits_that_wall() -> void:
	var wall := await _face_wall_inside_store(0.36)
	if not check(not wall.is_empty(), "found a wall to face"):
		return
	Input.action_press(&"aim")
	await process_frames(40)
	await _tap(&"cock")
	await _wait_ready()
	await _tap(&"fire")
	await wait_until(func() -> bool: return not hits.is_empty(), 30)
	check(not hits.is_empty(), "the shot hit something")
	if not hits.is_empty():
		check_eq(hits[0].member_id, (wall.member as StructureMember).member_id, "first thing hit is the wall in front")
