extends TestCase
## Joe, the companion (CompanionBrain, No Justice step 1, #843): he walks with you and waits when
## told; your deeds are never against him; your fights are his and theirs are his; he leaves your man
## to you and steps out of your line; and a wound that would kill him puts him down till it's over.

var world: Node3D
var ballistics: Ballistics
var player: Player
var joe: HumanBody
var brain: CompanionBrain


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(160, 1, 160)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO  # facing -Z
	joe = _joe(Vector3(2.0, 0.0, 2.5))
	brain = joe.get_node(^"Brain") as CompanionBrain
	await physics_frames(3)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _joe(at: Vector3) -> HumanBody:
	var man := HumanBody.new()
	man.name = "Joe"
	man.person_id = &"joe"
	var b := CompanionBrain.new()
	b.name = "Brain"
	b.follow_man(player)
	man.add_child(b)
	world.add_child(man)
	man.global_position = at
	return man


func _outlaw(at: Vector3) -> HumanBody:
	var man := HumanBody.new()
	man.name = "Kett"
	man.person_id = &"kett"
	var b := OutlawBrain.new()
	b.name = "Brain"
	b.nerve = 99.0
	man.add_child(b)
	world.add_child(man)
	man.global_position = at
	man.rotation_degrees.y = 180.0
	return man


func _draw() -> void:
	player.select_weapon(player.revolver())
	await wait_until(func() -> bool: return player.revolver().drawn, 120)


func _shoot(from: Vector3, to: Vector3, shooter: Node) -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var exclude: Array[RID] = []
	if shooter == player:
		exclude.append(player.get_rid())
	var b := ballistics.fire(from, (to - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, exclude)
	b.shooter = shooter
	await wait_until(func() -> bool: return not b.alive, 60)


func test_spared_means_down_not_dead() -> void:
	var p := Physiology.new()
	p.spared = true
	p.brain_dead = true
	p._die(&"brain")
	check(p.alive, "a brain shot doesn't kill a spared man")
	check(not p.is_conscious(), "it puts him out")
	check_eq(p.spared_times, 1, "counted")
	p.blood_ml = 100.0
	p.step(0.1)
	check(p.alive, "nor does bleeding out (%d ml)" % int(p.blood_ml))
	check(p.blood_loss() < p.tuning.death_at_loss, "his blood is kept short of the loss that kills")
	for i in 60 * 30:
		p.step(1.0 / 60.0)
	check(p.is_conscious(), "and he comes to (%.2f lost)" % p.blood_loss())
	p.spared = false  # the rope
	p.brain_dead = true
	p._die(&"brain")
	check(not p.alive, "not spared, he dies like anyone")


func test_he_walks_with_you_and_waits_when_told() -> void:
	player.global_position = Vector3(0, 0, -25)
	var came := await wait_until(func() -> bool:
		return CompanionBrain._flat(joe.global_position, player.global_position) < float(brain.tune.follow_far) + 0.5, 60 * 15)
	check(came, "he comes after you (%.1f m off)" % CompanionBrain._flat(joe.global_position, player.global_position))
	await physics_frames(60 * 2)
	var d := CompanionBrain._flat(joe.global_position, player.global_position)
	check(d > 1.5, "not on top of you (%.1f m)" % d)
	check(not brain.in_your_line(), "nor in front of you")
	# "Wait here."
	var said := brain.told(player)
	check_eq(said, "\"Wait here.\"", "you tell him to wait")
	var at := joe.global_position
	player.global_position = Vector3(0, 0, -50)
	await physics_frames(60 * 6)
	check(CompanionBrain._flat(joe.global_position, at) < 1.5, "he waits where he was (%.1f m)" % CompanionBrain._flat(joe.global_position, at))
	player.look_at(joe.global_position + Vector3.UP * 1.2)
	check(CompanionBrain.in_view(player) == brain, "looked at from %.0f m, your word is for him (the playtest: past 10 m it wasn't)" % CompanionBrain._flat(joe.global_position, player.global_position))
	check_eq(brain.told(player), "\"Come on.\"", "then to come")
	var again := await wait_until(func() -> bool:
		return CompanionBrain._flat(joe.global_position, player.global_position) < float(brain.tune.follow_far) + 0.5, 60 * 15)
	check(again, "and he comes")


func test_your_deeds_are_never_against_him() -> void:
	await _draw()
	player.look_at(joe.global_position + Vector3.UP * 1.2)
	for i in 20:
		Events.deed.emit(player, &"aim_at", joe, player.camera.global_position)
		await physics_frames(6)
	Events.shouted.emit(player, &"drop_it")
	await _shoot(Vector3(0, 1.5, 0), joe.global_position + Vector3(0.6, 1.6, 0), player)
	await physics_frames(60)
	check_eq(brain.relations.stance(player), Relations.Stance.IGNORE, "your gun on him is nothing to him")
	check_eq(brain.mood, OutlawBrain.Mood.CALM, "he doesn't turn on you")
	check(joe.held_gun == null or joe.gun_holstered or brain.target == null, "nor cover you")


func test_your_fight_is_his_and_theirs_is_his() -> void:
	var kett := _outlaw(Vector3(0, 0, -14))
	var kb := kett.get_node(^"Brain") as OutlawBrain
	await physics_frames(30)
	kb.turn_on(player)  # he goes for you
	var joined := await wait_until(func() -> bool: return brain.target == kett, 60 * 6)
	check(joined, "Joe fights the man who's after you (%s)" % brain.describe().substr(0, 60))
	check_eq(kb.relations.stance(joe), Relations.Stance.FIGHT, "and that man fights Joe too")


func test_he_starts_when_you_do() -> void:
	var kett := _outlaw(Vector3(0, 0, -14))
	await physics_frames(30)
	Events.deed.emit(player, &"shoot_at", kett, player.camera.global_position)
	await physics_frames(10)
	check_eq(brain.relations.stance(kett), Relations.Stance.FIGHT, "you shoot at a man: he's Joe's fight")


func test_he_leaves_your_man_to_you() -> void:
	var kett := _outlaw(Vector3(0, 0, -14))
	await _draw()
	player.look_at(kett.global_position + Vector3.UP * 1.2)
	await physics_frames(5)
	check(brain.in_your_sights(kett), "the man in your sights ...")
	check(not brain.yours(kett), "... is fair game while he's whole")
	kett.physiology.wounds = 1
	check(brain.yours(kett), "hurt, he's yours to finish")
	brain.relations.side_with(kett)
	brain._start_fight(kett)
	check(not brain._can_shoot_at(kett), "Joe holds his fire on him")
	(kett.get_node(^"Brain") as OutlawBrain).target = joe
	check(brain._on_me(kett), "once that man's on Joe ...")
	var held := int(brain.stats.held_fire)
	brain._can_shoot_at(kett)
	check_eq(int(brain.stats.held_fire), held, "... Joe doesn't hold off him")
	(kett.get_node(^"Brain") as OutlawBrain).target = null
	player.look_at(Vector3(30, 1.2, 0))
	await physics_frames(5)
	check(not brain.yours(kett), "look away and he isn't")
	Events.bullet_hit.emit({"person": kett, "shooter": player})
	check(brain.yours(kett), "a man you've just hit is yours")
	var other := _outlaw(Vector3(6, 0, -14))
	await physics_frames(3)
	check(not brain.yours(other), "another man isn't")
	Events.deed.emit(player, &"shoot_at", other, player.camera.global_position)
	check(not brain.yours(other), "firing at him alone doesn't make him yours: Joe keeps his head down too (#859)")
	(other.get_node(^"Brain") as OutlawBrain).target = player
	check(brain._on_you(other), "a man whose fight is with you is on you: Joe would rather fight him (#859)")


func test_he_steps_out_of_your_line() -> void:
	await _draw()
	joe.global_position = Vector3(0.2, 0, -5)
	player.rotation = Vector3.ZERO
	await physics_frames(5)
	check(brain.in_your_line(), "stood in front of your gun")
	var out := await wait_until(func() -> bool: return not brain.in_your_line(), 60 * 3)
	check(out, "he's out of it within 3 s (%.1f m off the line)" % absf(brain.line_offset()))
	check(brain.stats.line_steps >= 1, "by stepping aside")


func test_a_killing_wound_puts_him_down_till_its_over() -> void:
	var kett := _outlaw(Vector3(0, 0, -14))
	var kb := kett.get_node(^"Brain") as OutlawBrain
	await physics_frames(30)
	kb.turn_on(player)
	await wait_until(func() -> bool: return brain.target == kett, 60 * 6)
	# A ball through his head.
	var head := (joe.parts[&"head"] as Node3D).global_position
	await _shoot(head + Vector3(0, 0, -3), head, kett)
	var p := joe.physiology
	check(p.alive, "alive (%s)" % p.cause_of_death)
	if not p.is_conscious():
		check(p.spared_times >= 1 or p.concussion > 0.0, "out, a near thing")
	else:
		p._die(&"brain")  # the ball found no brain: the test's killing wound
	check(not p.is_conscious(), "down")
	await physics_frames(60 * 12)
	check(not p.is_conscious(), "and he stays down while the fight's on (%.1f s out)" % brain.stats.out_cold_s)
	kett.queue_free()  # it's over
	var up := await wait_until(func() -> bool: return p.is_conscious() and not joe.limp, 60 * 25)
	check(up, "he comes to and gets up after it (conscious %s, limp %s)" % [p.is_conscious(), joe.limp])
	check(p.alive, "alive")
