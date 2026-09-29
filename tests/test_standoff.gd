extends TestCase
## Nobody is an enemy by default. The outlaw minds his own business until someone does something;
## what he does then climbs a ladder you can read and answer (notice, wary, a warning, covering
## you) and steps back down when you do; it only comes to a fight when someone makes it one, and
## then with whoever that was.

var world: Node3D
var ballistics: Ballistics
var player: Player
var outlaw: HumanBody
var brain: OutlawBrain
var lines: Array[String] = []
var shots_by_outlaw := 0


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO  # facing -Z, towards him
	outlaw = _man(Vector3(0, 0, -5), &"outlaw")
	brain = outlaw.get_node(^"Brain")
	brain.nerve = 99.0
	lines.clear()
	shots_by_outlaw = 0
	Events.spoke.connect(_on_spoke)
	Events.shot_fired.connect(_on_shot)
	await physics_frames(3)


func after_each() -> void:
	Events.spoke.disconnect(_on_spoke)
	Events.shot_fired.disconnect(_on_shot)
	world.queue_free()
	await physics_frames(2)


func _on_spoke(who: Node, text: String) -> void:
	if who == outlaw:
		lines.append(text)


func _on_shot(_o: Vector3, _d: Vector3, who: Node) -> void:
	if who == outlaw:
		shots_by_outlaw += 1


func _man(at: Vector3, id: StringName) -> HumanBody:
	var m := HumanBody.new()
	m.person_id = id
	var b := OutlawBrain.new()
	b.name = "Brain"
	m.add_child(b)
	world.add_child(m)
	m.global_position = at
	m.rotation_degrees.y = 180.0  # facing +Z
	return m


func _draw() -> void:
	var gun := player.revolver()
	gun.needs_captured_mouse = false
	gun.take_out()
	await wait_until(func() -> bool: return gun.is_ready_in_hand(), 60)


func _stance() -> Relations.Stance:
	return brain.relations.stance(player)


func test_a_man_at_the_bar_minds_his_own_business() -> void:
	await physics_frames(60 * 5)
	check(_stance() <= Relations.Stance.NOTICE, "no more than a look (%s)" % Relations.Stance.keys()[_stance()])
	check_eq(brain.mood, OutlawBrain.Mood.CALM, "calm")
	check(outlaw.gun_holstered, "gun in its holster")
	check_eq(shots_by_outlaw, 0, "and nobody's shooting")


func test_draw_near_him_and_he_gets_wary() -> void:
	player.rotation_degrees.y = 90.0  # gun out, but pointing away from him
	await physics_frames(3)
	await _draw()
	var wary := await wait_until(func() -> bool: return _stance() >= Relations.Stance.WARY, 60 * 4)
	check(wary, "a drawn gun near him makes him wary")
	check(_stance() < Relations.Stance.THREAT, "but he doesn't draw on you for it (%s)" % Relations.Stance.keys()[_stance()])
	await physics_frames(20)
	check_eq(outlaw.pose, &"wary", "squares up, hand by the holster")


func test_point_it_at_him_and_he_covers_you_then_eases_off() -> void:
	await _draw()
	var covering := await wait_until(func() -> bool: return _stance() == Relations.Stance.THREAT, 60 * 6)
	check(covering, "a gun on him and he draws and covers you (%s)" % Relations.Stance.keys()[_stance()])
	await physics_frames(30)
	check(not outlaw.gun_holstered, "his gun's out")
	check_eq(outlaw.pose, &"aim", "on you")
	check_eq(shots_by_outlaw, 0, "but he hasn't fired")
	check(lines.size() >= 2, "and he's said so: %s" % str(lines))
	# Put it away.
	player.revolver().toggle_holster()
	var eased := await wait_until(func() -> bool: return _stance() <= Relations.Stance.WARY, 60 * 15)
	check(eased, "you holster, he steps back down (%s)" % Relations.Stance.keys()[_stance()])
	check_eq(shots_by_outlaw, 0, "no shots fired")
	var holstered := await wait_until(func() -> bool: return outlaw.gun_holstered, 60 * 20)
	check(holstered, "and in the end his goes back in its holster")


func test_keep_it_on_him_and_it_comes_to_shooting() -> void:
	await _draw()
	var shot := await wait_until(func() -> bool: return shots_by_outlaw > 0, 60 * 20)
	check(shot, "a gun held on him long enough, he'll shoot first")
	check_eq(brain.target, player, "at you")


func test_he_cant_react_to_what_he_cant_see() -> void:
	outlaw.rotation_degrees.y = 0.0  # his back to you
	await _draw()
	await physics_frames(60 * 4)
	check(_stance() <= Relations.Stance.NOTICE, "a gun at his back that he doesn't know about (%s)" % Relations.Stance.keys()[_stance()])


func test_a_hothead_minds_you_crowding_him_a_cool_man_doesnt() -> void:
	brain.temper = 1.0
	brain.relations.temper = 1.0
	player.global_position = Vector3(0, 0, -4.1)
	await physics_frames(60 * 5)
	var hot := _stance()
	check(hot >= Relations.Stance.WARNING, "the hothead warns you off (%s)" % Relations.Stance.keys()[hot])
	var cool_man := _man(Vector3(6, 0, -5), &"cool")
	var cool: OutlawBrain = cool_man.get_node(^"Brain")
	cool.temper = 0.0
	await physics_frames(3)
	cool.relations.temper = 0.0
	player.global_position = Vector3(6, 0, -4.1)
	await physics_frames(60 * 5)
	check(cool.relations.stance(player) <= Relations.Stance.WARY, "the professional lets it go (%s)" % Relations.Stance.keys()[cool.relations.stance(player)])


func test_someone_else_shoots_him_and_he_fights_them_not_you() -> void:
	var other := _man(Vector3(4, 0, -9), &"blacksmith")
	var ob: OutlawBrain = other.get_node(^"Brain")
	ob.nerve = 99.0
	other.rotation_degrees.y = 135.0  # facing him
	await physics_frames(10)
	# The blacksmith opens up on him.
	ob._provoked(outlaw)
	var fought := await wait_until(func() -> bool: return brain.target == other, 60 * 6)
	check(fought, "he turns on the man shooting at him (%s)" % str(brain.target))
	check(_stance() < Relations.Stance.THREAT, "not on you (%s)" % Relations.Stance.keys()[_stance()])
