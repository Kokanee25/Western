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


## Seen by the light on him: at night, standing 20 m off under a lit lamp, he's picked out; the same
## lamp put out, he isn't; lit, but with a wall between it and him, he isn't either. The perception
## lab's baseline (2026-10-22): lamps lit nobody.
func test_a_lamp_lights_you_at_night() -> void:
	senses.light = 0.0
	player.global_position = Vector3(0, 0, 10)  # 20 m off: past his reach under the night sky
	var lamp := OilLamp.new()
	world.add_child(lamp)
	lamp.global_position = Vector3(1.2, 1.6, 10.5)
	await physics_frames(2)
	check(lamp.shines(), "(the lamp is lit)")
	var spotted := await wait_until(func() -> bool: return senses.sees(player), 480)
	check(spotted, "under a lit lamp at 20 m he picks you out (%.2f lux on you)" % senses.light_on(player))
	lamp.set_lit(false)
	senses.known.clear()
	await physics_frames(360)
	check(not senses.sees(player), "the lamp out, you're dark again (%.3f lux)" % senses.light_on(player))
	lamp.set_lit(true)
	_box(Vector3(0.6, 1.5, 10.25), Vector3(0.1, 3, 3))  # a wall between the lamp and you
	senses.known.clear()
	await physics_frames(360)
	check(not senses.sees(player), "a wall keeps its light off you (%.3f lux)" % senses.light_on(player))


## A shut room at night with no lamp is black, though the sky's the same outside it.
func test_a_dark_room_at_night() -> void:
	senses.light = 0.0
	player.global_position = Vector3(0, 0, -4)  # 6 m: seen under the open night sky
	var open_sky := senses.range_to(player)
	_box(Vector3(0, 3.1, -4), Vector3(4, 0.2, 4))  # a roof over you
	for side: Vector3 in [Vector3(2, 0, 0), Vector3(-2, 0, 0), Vector3(0, 0, 2), Vector3(0, 0, -2)]:
		_box(Vector3(0, 1.5, -4) + side, Vector3(0.1 if side.x != 0.0 else 4, 3, 0.1 if side.z != 0.0 else 4))
	await physics_frames(SightLight.tune().lines_frames + 5)  # its sky is looked for again
	check(open_sky > 6.0, "under the open sky he'd see you at 6 m (%.1f m)" % open_sky)
	check(senses.range_to(player) < 3.0, "in a shut room his eye reaches %.1f m of you" % senses.range_to(player))


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
	var shot := senses.last_sound([&"gunshot"])
	check(not shot.is_empty(), "heard it")
	check(not senses.sees(player), "without seeing you")
	check(not shot.is_empty() and (shot.at as Vector3).distance_to(player.global_position) < 5.0, "and roughly where")
	check(not senses.knows(player), "but not who fired: he didn't see you")


## A shot from a man he can see: he knows who fired. The perception lab's baseline (2026-10-22)
## found every listener knew, seen or not.
func test_knows_who_fired_only_if_he_sees_him() -> void:
	var who := [null]
	senses.heard.connect(func(_at: Vector3, _k: StringName, w: Node) -> void: who[0] = w)
	Events.noise.emit(player.global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", player)
	check(who[0] == player, "you, 10 m in front of him: he knows it was you")
	check(senses.knows(player), "and where you are")
	_box(Vector3(0, 1.5, -5), Vector3(6, 3, 0.3))  # a wall between
	await physics_frames(2)
	senses.known.clear()
	who[0] = null
	Events.noise.emit(player.global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", player)
	check(who[0] == null and not senses.knows(player), "the same shot behind a wall: a shot, not you")
	check(not senses.last_sound([&"gunshot"], 0.5).is_empty(), "heard all the same")


func test_footsteps() -> void:
	man.rotation_degrees.y = 0.0
	player.global_position = Vector3(0, 0, -2)  # 8 m behind him
	await physics_frames(2)
	Events.noise.emit(player.global_position, 13.0, &"footsteps", player)
	check(not senses.last_sound([&"footsteps"]).is_empty(), "hears you running at 8 m")
	check(not senses.knows(player), "steps behind him: somebody's, not yours")
	senses.sounds.clear()
	Events.noise.emit(player.global_position, 2.0, &"footsteps", player)
	check(senses.last_sound([&"footsteps"]).is_empty(), "not creeping crouched")


## People come and go (the gang rides out, is freed, rides in again, often where the last ones
## were in memory): he forgets the gone, and his look never walks round in a circle. The nightly
## soak froze for hours in the knocked-out man's loop over who he knew (2026-10-14): a Dictionary
## keyed by freed objects can loop for ever in Godot 4.7.
func test_forgets_people_who_are_gone() -> void:
	var others: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var me := senses.body
	for round in 40:
		for i in 3:
			var n := Node3D.new()
			others.append(n)
			senses._entry(n)
		while others.size() > 6:
			var k := rng.randi_range(0, others.size() - 1)
			(others[k] as Node).free()
			others.remove_at(k)
		# Knocked out (no body to look with): the loop that froze.
		senses.body = null
		senses._t = 0.0
		senses._physics_step(0.0)
		senses.body = me
	senses._t = 0.0
	senses._physics_step(0.0)
	var gone := senses.known.keys().filter(func(w: Variant) -> bool: return not is_instance_valid(w))
	check_eq(gone.size(), 0, "nobody gone is still known")
	check(senses.known.size() <= others.size() + 2, "only the living (and you) are (%d known)" % senses.known.size())
	for n: Node in others:
		n.free()


## A planted stick's hiss (issue #537, Sean): heard only really close (Blast.t().fuse_heard, 3 m)
## and only on its side of the wall it's set on, however thin: the wall-side noise is made a hand
## off the face the stick is on, and none of a fuse's hiss gets through a wall.
func test_a_fuse_is_heard_only_close_and_on_its_side_of_the_wall() -> void:
	var wall := _box(Vector3(0, 1.5, -8.0), Vector3(12, 3, 0.15))
	await physics_frames(2)
	var hissed := []
	senses.heard.connect(func(_at: Vector3, kind: StringName, _w: Node) -> void:
		if kind == &"fuse":
			hissed.append(kind))
	# [where on the wall's face, the face's way out, heard?, what]; he stands at (0, 0, -10).
	var cases := [[Vector3(0.3, 1.2, -7.92), Vector3(0, 0, 1), false, "the far side of the wall, 2 m from him"],
			[Vector3(0.3, 1.2, -8.08), Vector3(0, 0, -1), true, "his side of the wall, 2 m off"],
			[Vector3(4.4, 1.2, -8.08), Vector3(0, 0, -1), false, "his side, 4.5 m along it"]]
	for c: Array in cases:
		hissed.clear()
		var s := DynamiteStick.make(world, c[0], Vector3.ZERO, 30.0)
		var n: Vector3 = c[1]
		s.global_basis = Basis(n, Vector3.UP, n.cross(Vector3.UP))  # as planted: its x the face's normal
		s.stick_to(wall)
		s.light()
		await physics_frames(40)
		check_eq(not hissed.is_empty(), c[2], "%s: %s" % [c[3], "heard" if not hissed.is_empty() else "not heard"])
		s.queue_free()
		await physics_frames(2)
