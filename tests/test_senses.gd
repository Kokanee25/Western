extends TestCase
## Senses: eyes that look where he's facing, need a clear line and light, and pick out a moving man
## faster than a still, crouched one; ears for gunfire across town and footsteps close by, muffled
## by walls; and where he last saw you.

var world: Node3D
var player: Player
var man: HumanBody
var senses: Senses


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, 0), Vector3(120, 1, 120))
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	man = HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	man.global_position = Vector3(0, 0, -10)
	man.rotation_degrees.y = 180.0  # facing +Z, towards you
	senses = Senses.new()
	man.add_child(senses)
	senses.light = 1.0
	await physics_frames(3)


func after_each() -> void:
	Input.action_release(&"crouch")
	world.queue_free()
	await physics_frames(2)


func _box(center: Vector3, size: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = center
	world.add_child(b)
	return b


func test_sees_you_in_front_of_him() -> void:
	var spotted := await wait_until(func() -> bool: return senses.sees(player), 90)
	check(spotted, "picks you out at 10 m in daylight within a second and a half")
	check(senses.last_known(player).distance_to(player.global_position) < 0.1, "and knows where you are")


func test_not_behind_him() -> void:
	man.rotation_degrees.y = 0.0  # his back to you
	await physics_frames(120)
	check(not senses.sees(player), "eyes in the front of his head only")


func test_not_through_a_wall() -> void:
	_box(Vector3(0, 1.5, -5), Vector3(4, 3, 0.2))
	await physics_frames(120)
	check(not senses.sees(player), "a wall between you")


func test_night_shortens_his_sight() -> void:
	senses.light = 0.0
	player.global_position = Vector3(0, 0, 10)  # 20 m off
	await physics_frames(150)
	check(not senses.sees(player), "can't make you out at 20 m in the dark")
	player.global_position = Vector3(0, 0, -4)  # 6 m
	var spotted := await wait_until(func() -> bool: return senses.sees(player), 180)
	check(spotted, "but does close up")


func test_crouched_and_still_is_harder_to_spot() -> void:
	senses.light = 0.3
	player.global_position = Vector3(0, 0, 4)  # 14 m
	Input.action_press(&"crouch")
	await physics_frames(60)
	senses.known.clear()
	var frames := 0
	while not senses.sees(player) and frames < 600:
		await physics_frames(1)
		frames += 1
	var crouched := frames
	check(player.is_crouching, "(you were crouched)")
	Input.action_release(&"crouch")
	await physics_frames(60)
	senses.known.clear()
	frames = 0
	while not senses.sees(player) and frames < 600:
		await physics_frames(1)
		frames += 1
	print("  frames to spot you at 14 m, dusk: crouched %d, standing %d" % [crouched, frames])
	check(crouched > frames, "crouched takes longer to spot")


func test_hears_a_shot_behind_him_roughly_where() -> void:
	man.rotation_degrees.y = 0.0
	player.global_position = Vector3(0, 0, 20)  # 30 m behind him
	await physics_frames(2)
	Events.noise.emit(player.global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", player)
	check(senses.knows(player), "heard it")
	check(not senses.sees(player), "without seeing you")
	var guess := senses.last_known(player)
	check(guess.distance_to(player.global_position) < 5.0, "and roughly where (%.1f m off)" % guess.distance_to(player.global_position))


func test_footsteps() -> void:
	man.rotation_degrees.y = 0.0
	player.global_position = Vector3(0, 0, -2)  # 8 m behind him
	await physics_frames(2)
	Events.noise.emit(player.global_position, 13.0, &"footsteps", player)
	check(senses.knows(player), "hears you running at 8 m")
	senses.known.clear()
	Events.noise.emit(player.global_position, 2.0, &"footsteps", player)
	check(not senses.knows(player), "not creeping crouched")
