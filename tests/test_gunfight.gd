extends TestCase
## The test gunfight: the outlaw is calm until shot at, then fights back with real bullets;
## fear breaks him (he drops the gun and puts his hands up); the player's own wounds act on the
## player, and pressing on them / a belt round the leg saves you.

var world: Node3D
var ballistics: Ballistics
var player: Player
var outlaw: HumanBody
var brain: OutlawBrain
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
	player.global_position = Vector3(0, 0, 0)
	player.rotation = Vector3.ZERO  # facing -Z, towards him
	outlaw = HumanBody.new()
	brain = OutlawBrain.new()
	brain.name = "Brain"
	outlaw.add_child(brain)
	world.add_child(outlaw)
	outlaw.global_position = Vector3(0, 0, -8)
	outlaw.rotation_degrees.y = 180.0  # facing +Z, towards the player
	shots_by_outlaw = 0
	Events.shot_fired.connect(_on_shot)
	await physics_frames(3)


func after_each() -> void:
	Input.action_release(&"tend_wounds")
	Events.shot_fired.disconnect(_on_shot)
	world.queue_free()
	await physics_frames(2)


func _on_shot(_origin: Vector3, _dir: Vector3, shooter: Node) -> void:
	if shooter == outlaw:
		shots_by_outlaw += 1


func _shoot(from: Vector3, to: Vector3, shooter: Node = null) -> Ballistics.Bullet:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var exclude: Array[RID] = []
	if shooter == player:
		exclude.append(player.get_rid())
	var b := ballistics.fire(from, (to - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, exclude)
	b.shooter = shooter
	await wait_until(func() -> bool: return not b.alive, 60)
	return b


func test_calm_until_shot_at() -> void:
	await physics_frames(60)
	check_eq(brain.mood, OutlawBrain.Mood.CALM, "stands easy")
	check_eq(shots_by_outlaw, 0, "doesn't shoot first")
	# A ball cracks past his ear.
	await _shoot(Vector3(0, 1.5, -1), Vector3(0.8, 1.6, -8), player)
	check_eq(brain.mood, OutlawBrain.Mood.FIGHTING, "then he fights")
	check(brain.fear > 0.0, "and it scared him a little (%.2f)" % brain.fear)


func test_he_shoots_back_and_hurts() -> void:
	brain.nerve = 99.0  # no quitting in this one
	var hits := [0]
	var count := func(info: Dictionary) -> void: if info.get("person") == player: hits[0] += 1
	Events.body_hit.connect(count)
	await _shoot(Vector3(0, 1.5, -1), Vector3(0.8, 1.6, -8), player)
	var down := func() -> bool: return not player.wounds.physiology.is_conscious()
	await wait_until(func() -> bool: return shots_by_outlaw >= 4 or down.call(), 60 * 9)
	Events.body_hit.disconnect(count)
	check(hits[0] >= 1, "he hits you at 8 m (%d hits)" % hits[0])
	if down.call():
		# A .45 in the chest can put a man down at once; then he stands down: you're out of it.
		await physics_frames(60 * 4)
		check(brain.target == null, "you're down: he's done with you (%s)" % brain.describe().substr(0, 50))
		return
	check(shots_by_outlaw >= 4, "fires again and again (%d shots)" % shots_by_outlaw)
	# (He has to draw first, and pick you out.)
	var done := func() -> bool: return brain.mood == OutlawBrain.Mood.RELOADING or shots_by_outlaw > 5 \
			or brain.rounds == brain.rounds_per_load and shots_by_outlaw >= 5 or down.call()
	await wait_until(done, 60 * 12)
	check(done.call(), "reloads after five (%d shots, %d rounds, %s)" % [shots_by_outlaw, brain.rounds, brain.describe().substr(0, 40)])


func test_broken_gun_arm_breaks_his_nerve() -> void:
	var at := (outlaw.parts[&"upper_arm_r"] as Node3D).global_position
	await _shoot(Vector3(at.x, at.y, 0), at, player)
	check(outlaw.physiology.broken.has(&"humerus_r"), "upper arm broken")
	await physics_frames(120)
	check(outlaw.held_gun == null, "gun's on the ground")
	check_eq(brain.mood, OutlawBrain.Mood.SURRENDERED, "hands up")
	check_eq(outlaw.pose, &"hands_up", "posed so")


func test_drop_it_when_hurt_and_covered() -> void:
	# A flesh wound in the thigh (no bone, no artery), then he's covered and told to drop it.
	await _shoot(Vector3(0.14, 0.72, -1), Vector3(0.14, 0.72, -8), player)
	check_eq(brain.mood, OutlawBrain.Mood.FIGHTING, "fighting after a flesh wound")
	brain._aimed_at = 3.0
	for i in 3:
		Events.shouted.emit(player, &"drop_it")
		brain._aimed_at = 3.0
		await physics_frames(10)
	check_eq(brain.mood, OutlawBrain.Mood.SURRENDERED, "gives up (fear %.2f)" % brain.fear)


func test_player_wounds_act() -> void:
	brain.nerve = 99.0
	outlaw.queue_free()
	await physics_frames(2)
	# Shot through the right thigh bone from the side.
	var leg := player.global_position + player.global_basis * Vector3(0.1, 0.7, 0.0)
	await _shoot(leg + player.global_basis.x * 5.0, leg)
	var p := player.wounds.physiology
	check(p.broken.has(&"femur_r"), "femur broken")
	await physics_frames(3)
	check(player.force_crouch, "down on the ground")
	check(player.move_factor < 0.5, "crawling (%.2f)" % player.move_factor)
	check(not player.can_sprint, "no running")


func test_tourniquet_on_your_own_leg() -> void:
	outlaw.queue_free()
	await physics_frames(2)
	var leg := player.global_position + player.global_basis * Vector3(0.07, 0.7, 0.0)
	await _shoot(leg - player.global_basis.z * 5.0, leg)
	var p := player.wounds.physiology
	check(p.cut.has(&"femoral_r"), "femoral cut")
	var bleeding := p.total_bleed_rate()
	Input.action_press(&"tend_wounds")
	await physics_frames(20)
	var gun := player.get_node(^"Head/Camera3D/Gun") as RevolverViewmodel
	check(gun.hands_busy, "hands busy on the wound")
	check(p.total_bleed_rate() < bleeding * 0.5, "pressure slows it")
	await physics_frames(60 * 5)
	Input.action_release(&"tend_wounds")
	await physics_frames(2)
	check(p.total_bleed_rate() < 1.0, "belt round the thigh stops it (%.2f ml/s)" % p.total_bleed_rate())
	check(not gun.hands_busy, "hands free again")


func test_blackout_and_come_round() -> void:
	outlaw.queue_free()
	await physics_frames(2)
	player.wounds.physiology.blood_ml = 2800.0
	await physics_frames(10)
	check(player.wounds.out_cold > 0.0, "out cold")
	await physics_frames(60 * 5)
	check(player.wounds.physiology.is_conscious(), "comes round")
	check_eq(player.wounds.physiology.wounds, 0, "patched up")


## How many body hits it takes to end the fight (down, dead or hands up), over many fresh outlaws
## shot at random points on the chest and belly from 8 m. The gunfight's main tuning number.
func test_body_hits_to_stop_him() -> void:
	outlaw.queue_free()
	await physics_frames(1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1882
	var counts: Array[int] = []
	for trial in 24:
		var man := HumanBody.new()
		man.rng_seed = trial + 1
		var b := OutlawBrain.new()
		b.name = "Brain"
		man.add_child(b)
		world.add_child(man)
		man.global_position = Vector3(0, 0, -8)
		man.rotation_degrees.y = 180.0
		await physics_frames(2)
		var hits := 0
		for shot in 8:
			var at := man.global_position + Vector3(rng.randf_range(-0.14, 0.14), rng.randf_range(1.0, 1.42), 0)
			var before := man.physiology.wounds
			await _shoot(Vector3(at.x, at.y, -1), at, player)
			if man.physiology.wounds > before:
				hits += 1
			await physics_frames(90)
			if b.mood >= OutlawBrain.Mood.SURRENDERED:
				break
		counts.append(hits)
		man.queue_free()
		await physics_frames(1)
	var total := 0
	for c in counts:
		total += c
	var average := float(total) / counts.size()
	print("  body hits to stop him: %s (average %.2f)" % [counts, average])
	check(average >= 1.2 and average <= 2.3, "one to two good hits end it (average %.2f)" % average)
	check(counts.count(1) > 0 and counts.max() >= 2, "sometimes one, sometimes more (%s)" % [counts])
