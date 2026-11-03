extends TestCase
## Your gun arm broken, the revolver goes back in its holster and won't come out: you're told why,
## when it goes and when you try it (#595: the second D+ playtest's gun was "put away" after two
## balls broke its upper arm, and draw, shoot and reload did nothing, without a word).

var world: Node3D
var player: Player
var shown: Array[String] = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	shown.clear()
	await physics_frames(3)
	player.wounds.shown.connect(func(t: String) -> void: shown.append(t))


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_a_broken_gun_arm_says_why_the_gun_is_gone() -> void:
	var gun := player.revolver()
	gun.needs_captured_mouse = false
	player.select_weapon(gun)
	gun.take_out()
	var out := await wait_until(func() -> bool: return gun.is_ready_in_hand(), 90)
	check(out, "gun in hand")
	check_eq(gun.why_not_usable(), "", "nothing wrong with it yet")
	player.wounds.physiology.broken[&"humerus_r"] = true
	var away := await wait_until(func() -> bool: return not gun.drawn, 30)
	check(away, "the gun goes back in its holster")
	check(gun.why_not_usable().contains("broken upper arm"), "and why: %s" % gun.why_not_usable())
	var told := shown.filter(func(t: String) -> bool: return t.contains("You can't hold the gun: a broken upper arm"))
	check_eq(told.size(), 1, "said on the screen once: %s" % str(shown))
	await physics_frames(60 * 3)
	check_eq(shown.size(), told.size(), "and not again on its own")
	Input.action_press(&"holster")
	await physics_frames(2)
	Input.action_release(&"holster")
	await physics_frames(2)
	told = shown.filter(func(t: String) -> bool: return t.contains("You can't hold the gun"))
	check_eq(told.size(), 2, "trying to draw it, you're told again")
	check(not gun.drawn, "and it stays put away")


func test_the_hand_isnt_why_you_cant_hold_it() -> void:
	var p := player.wounds.physiology
	check_eq(p.why_cant_hold("r"), "", "a sound arm")
	p.broken[&"radius_r"] = true
	check_eq(p.why_cant_hold("r"), "a broken forearm", "the forearm")
	check_eq(p.why_cant_hold("l"), "", "the other's fine")
