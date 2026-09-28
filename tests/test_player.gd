extends TestCase
## The first-person controller on a flat test floor: walk, run, strafe, look (mouse and stick),
## crouch (and not standing up under a low ceiling), jump and gravity.

const ACTIONS := [&"move_forward", &"move_back", &"move_left", &"move_right", &"run", &"run_toggle",
		&"crouch", &"crouch_toggle", &"jump", &"look_left", &"look_right", &"look_up", &"look_down"]

var arena: Node3D
var player: Player


func before_each() -> void:
	arena = Node3D.new()
	arena.name = "Arena"
	get_tree().root.add_child(arena)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	arena.add_child(floor_body)
	player = load("res://scenes/player.tscn").instantiate()
	arena.add_child(player)
	await physics_frames(10)


func after_each() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	arena.queue_free()
	await physics_frames(2)


func _hold(action: StringName, frames: int, strength := 1.0) -> void:
	Input.action_press(action, strength)
	await physics_frames(frames)
	Input.action_release(action)


func test_starts_on_the_floor() -> void:
	check(player.is_on_floor(), "standing on the floor")
	check_near(player.global_position.y, 0.0, 0.05, "feet at floor height")


func test_walks_forward() -> void:
	var start := player.global_position
	Input.action_press(&"move_forward")
	await physics_frames(60)
	var speed := player.get_horizontal_speed()
	Input.action_release(&"move_forward")
	var moved := player.global_position - start
	check_near(speed, player.tuning.walk_speed, 0.05, "walk speed")
	check(moved.z < -2.0, "moved forward (-Z) %s" % moved)
	check_near(moved.x, 0.0, 0.01, "no sideways drift")


func test_runs_faster_than_walking() -> void:
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	await physics_frames(60)
	check(player.is_running, "running")
	check_near(player.get_horizontal_speed(), player.tuning.run_speed, 0.05, "run speed")


func test_controller_run_toggle_latches_until_stopping() -> void:
	Input.action_press(&"move_forward")
	await physics_frames(2)
	Input.action_press(&"run_toggle")
	await physics_frames(1)
	Input.action_release(&"run_toggle")
	await physics_frames(45)
	check(player.is_running, "still running after letting go of the stick click")
	Input.action_release(&"move_forward")
	await physics_frames(30)
	Input.action_press(&"move_forward")
	await physics_frames(45)
	check(not player.is_running, "stopping cancels the run")


func test_strafes() -> void:
	var start := player.global_position
	await _hold(&"move_right", 40)
	check(player.global_position.x - start.x > 1.0, "moved right (+X)")


func test_stops_when_input_released() -> void:
	await _hold(&"move_forward", 40)
	await physics_frames(30)
	check_near(player.get_horizontal_speed(), 0.0, 0.01, "comes to rest")


func test_mouse_look_turns_and_clamps_pitch() -> void:
	Events.look_input.emit(Vector2(90.0, 0.0))
	var f := player.get_forward()
	check(f.x > 0.99, "turning right 90 degrees faces +X (got %s)" % f)
	Events.look_input.emit(Vector2(0.0, 200.0))
	check_near(player.get_pitch_degrees(), player.tuning.max_pitch_degrees, 0.001, "pitch clamps looking up")
	Events.look_input.emit(Vector2(0.0, -400.0))
	check_near(player.get_pitch_degrees(), -player.tuning.max_pitch_degrees, 0.001, "pitch clamps looking down")
	# Walking follows the view.
	var start := player.global_position
	await _hold(&"move_forward", 40)
	check(player.global_position.x - start.x > 1.0, "walks where it looks")


func test_stick_look() -> void:
	var yaw0 := player.rotation.y
	await _hold(&"look_right", 30)
	var turned := rad_to_deg(yaw0 - player.rotation.y)
	check_near(turned, Settings.stick_look_speed * 0.5, 8.0, "right stick turns at the configured speed")
	await _hold(&"look_up", 10)
	check(player.get_pitch_degrees() > 5.0, "right stick pitches up")


func test_crouch_lowers_view_and_slows() -> void:
	Input.action_press(&"crouch")
	Input.action_press(&"move_forward")
	await physics_frames(60)
	check(player.is_crouching, "crouching")
	check_near(player.get_eye_height(), player.tuning.crouch_eye_height, 0.01, "eyes lowered")
	check_near(player.get_horizontal_speed(), player.tuning.crouch_speed, 0.05, "crouch speed")
	Input.action_release(&"crouch")
	await physics_frames(60)
	check(not player.is_crouching, "stands up again")
	check_near(player.get_eye_height(), player.tuning.stand_eye_height, 0.01, "eyes back up")


func test_crouch_toggle() -> void:
	await _hold(&"crouch_toggle", 1)
	await physics_frames(10)
	check(player.is_crouching, "toggle crouches")
	await _hold(&"crouch_toggle", 1)
	await physics_frames(10)
	check(not player.is_crouching, "toggle again stands")


func test_cannot_stand_under_low_ceiling() -> void:
	Input.action_press(&"crouch")
	await physics_frames(10)
	var ceiling := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 0.2, 4)
	shape.shape = box
	ceiling.add_child(shape)
	ceiling.position = player.global_position + Vector3(0, 1.5, 0)
	arena.add_child(ceiling)
	await physics_frames(2)
	Input.action_release(&"crouch")
	await physics_frames(20)
	check(player.is_crouching, "stays crouched under a 1.4 m ceiling")
	ceiling.queue_free()
	await physics_frames(20)
	check(not player.is_crouching, "stands once there is headroom")


func test_jump_and_land() -> void:
	Input.action_press(&"jump")
	await physics_frames(2)
	Input.action_release(&"jump")
	var peak := 0.0
	var left_floor := false
	for i in 90:
		await get_tree().physics_frame
		peak = maxf(peak, player.global_position.y)
		if not player.is_on_floor():
			left_floor = true
	var expected := pow(player.tuning.jump_velocity, 2) / (2.0 * player.tuning.gravity)
	check(left_floor, "left the floor")
	check_near(peak, expected, 0.08, "jump height")
	check(player.is_on_floor(), "landed again")


func test_falls_under_gravity() -> void:
	player.global_position = Vector3(3, 3, 3)
	player.velocity = Vector3.ZERO
	await physics_frames(2)
	check(not player.is_on_floor(), "in the air")
	var landed := await wait_until(func() -> bool: return player.is_on_floor() and player.global_position.y < 0.1, 120)
	check(landed, "falls and lands")
	check_near(player.global_position.y, 0.0, 0.05, "lands on the floor")


func test_body_is_visible_looking_down() -> void:
	var boots := 0
	for n in player.body.find_children("Boot", "MeshInstance3D", true, false):
		if (n as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			boots += 1
	check_eq(boots, 2, "two visible boots")
	# Look straight down and check the boots are in front of the camera.
	Events.look_input.emit(Vector2(0.0, -90.0))
	await physics_frames(2)
	var cam := player.camera
	for n in player.body.find_children("Boot", "MeshInstance3D", true, false):
		var p := (n as Node3D).global_position
		check(not cam.is_position_behind(p), "boot is in view looking down")
		var local := cam.global_transform.affine_inverse() * p
		var angle := rad_to_deg(atan(Vector2(local.x, local.y).length() / -local.z))
		check(angle < cam.fov * 0.5, "boot inside the field of view (%.0f°)" % angle)
