extends TestCase
## GameAudio (the sound lab): a sound heard from where it happened. It comes late by the distance
## over the speed of sound, duller the further, rings inside a room, is muffled through a wall (not
## through a man), and outdoors slaps back off a front.

var world: Node3D
var ears: Camera3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, 0), Vector3(200, 1, 200))  # the ground
	ears = Camera3D.new()
	world.add_child(ears)
	ears.make_current()
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _box(at: Vector3, size: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	b.add_child(shape)
	world.add_child(b)
	b.global_position = at
	return b


func test_it_arrives_late_by_the_distance() -> void:
	ears.global_position = Vector3(0, 1.6, 0)
	var p := GameAudio.play(world, &"report", Vector3(34.3, 1.6, 0))
	check(p != null and not p.playing, "34 m off, it hasn't started yet")
	await physics_frames(int(0.08 * Engine.physics_ticks_per_second))
	check(not p.playing, "nor 0.08 s later")
	await physics_frames(int(0.04 * Engine.physics_ticks_per_second) + 2)
	check(p.playing, "it has by 0.1 s (34.3 m / 343 m/s)")
	var near := GameAudio.play(world, &"report", Vector3(0.5, 1.6, 0))
	check(near.playing, "half a metre off, at once")


func test_the_air_takes_the_highs() -> void:
	check_near(GameAudio.air_cutoff(0.0), 20000.0, 1.0, "nothing lost at the source")
	check(GameAudio.air_cutoff(80.0) < GameAudio.air_cutoff(20.0), "duller at 80 m than at 20")
	check(GameAudio.air_cutoff(20.0) < 15000.0, "and already a little at 20")


func test_inside_a_room_and_through_its_wall() -> void:
	# A room 8 x 8 x 4 with a roof, walls all round.
	_box(Vector3(0, 4.1, 0), Vector3(8.4, 0.2, 8.4))
	_box(Vector3(4.1, 2, 0), Vector3(0.2, 4, 8.4))
	_box(Vector3(-4.1, 2, 0), Vector3(0.2, 4, 8.4))
	_box(Vector3(0, 2, 4.1), Vector3(8.4, 4, 0.2))
	_box(Vector3(0, 2, -4.1), Vector3(8.4, 4, 0.2))
	await physics_frames(2)
	check(GameAudio.inside(world, Vector3(0, 1.5, 0)), "under its roof, walled every way: inside")
	check(not GameAudio.inside(world, Vector3(20, 1.5, 0)), "out in the open: not")
	check(GameAudio.walled(world, Vector3(10, 1.6, 0), Vector3(0, 1.5, 0)), "a wall between the street and the room")
	check(not GameAudio.walled(world, Vector3(2, 1.6, 0), Vector3(0, 1.5, 0)), "none inside it")
	ears.global_position = Vector3(10, 1.6, 0)
	var p := GameAudio.play(world, &"report", Vector3(0, 1.5, 0))
	check_eq(p.bus, &"RoomMuffled", "a shot in the room heard from the street: the room, through its wall")
	ears.global_position = Vector3(2, 1.6, 0)
	p = GameAudio.play(world, &"report", Vector3(0, 1.5, 0))
	check_eq(p.bus, &"Room", "heard inside: the room")


func test_a_man_is_not_a_wall() -> void:
	var man := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	shape.shape = cap
	man.add_child(shape)
	world.add_child(man)
	man.global_position = Vector3(5, 1, 0)
	await physics_frames(2)
	check(not GameAudio.walled(world, Vector3(10, 1.0, 0), Vector3(0, 1.0, 0)), "a man between is looked past")


func test_it_slaps_back_off_a_front() -> void:
	# A front 6 m high, 5 m south of the shot; the ears 10 m east of it.
	_box(Vector3(0, 3, 5.1), Vector3(40, 6, 0.2))
	await physics_frames(2)
	ears.global_position = Vector3(10, 1.6, 0)
	var s := GameAudio.slaps(world, Vector3(0, 1.5, 0))
	check_eq(s.size(), 1, "one front, one slap")
	if s.size() == 1:
		check((s[0].at as Vector3).distance_to(Vector3(0, 1.5, 10.0)) < 0.1, "from the shot mirrored in the front")
	# A post is not a front.
	world.get_child(world.get_child_count() - 1).queue_free()
	_box(Vector3(0, 0.5, 5.0), Vector3(0.2, 1.0, 0.2))
	await physics_frames(2)
	check(GameAudio.slaps(world, Vector3(0, 0.6, 0)).is_empty(), "a post a metre high throws nothing back")
