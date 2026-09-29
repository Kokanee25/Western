extends TestCase
## The outlaw fights like a man who wants to live: he finds cover (anything solid between him and
## you), runs to it, keeps his head down while rounds crack past, rises or leans out to shoot,
## moves to new angles; broken, he runs; hurt and left alone, he tends his wound; legs gone, he's
## down on his belly, crawling and still shooting. And he doesn't walk through walls.

var world: Node3D
var ballistics: Ballistics
var player: Player
var outlaw: HumanBody
var brain: OutlawBrain
var shots_by_outlaw := 0


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, 0), Vector3(80, 1, 80))  # the ground
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO  # facing -Z
	shots_by_outlaw = 0
	Events.shot_fired.connect(_on_shot)
	await physics_frames(2)


func after_each() -> void:
	Events.shot_fired.disconnect(_on_shot)
	world.queue_free()
	await physics_frames(2)


func _on_shot(_o: Vector3, _d: Vector3, shooter: Node) -> void:
	if shooter == outlaw:
		shots_by_outlaw += 1


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


## Crates stacked chest high to a crouching man (1.2 m): he can duck behind them.
func _crates() -> void:
	_box(Vector3(2.2, 0.6, -11.0), Vector3(1.0, 1.2, 1.0))


func _outlaw(at: Vector3) -> void:
	outlaw = HumanBody.new()
	brain = OutlawBrain.new()
	brain.name = "Brain"
	outlaw.add_child(brain)
	world.add_child(outlaw)
	outlaw.global_position = at
	outlaw.rotation_degrees.y = 180.0
	await physics_frames(3)


func _seeded() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = 11
	return r


func _eye() -> Vector3:
	return player.camera.global_position


func _provoke() -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var ex: Array[RID] = [player.get_rid()]
	var head := outlaw.global_position + Vector3.UP * 1.6
	var from := _eye() + Vector3(0, 0, -0.5)
	var b := ballistics.fire(from, (head + Vector3(0.9, 0.1, 0) - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, ex)
	b.shooter = player
	await wait_until(func() -> bool: return not b.alive, 90)


func _exclude() -> Array[RID]:
	var out: Array[RID] = [player.get_rid()]
	for sid: StringName in outlaw.parts:
		out.append((outlaw.parts[sid] as CollisionObject3D).get_rid())
	return out


# --- Finding cover -----------------------------------------------------------------------------------

func test_finds_the_crate() -> void:
	await _outlaw(Vector3(0, 0, -12))
	_crates()
	await physics_frames(2)
	var spot := Cover.find(world, outlaw.global_position, _eye(), _exclude(), _seeded())
	check(not spot.is_empty(), "found somewhere")
	if spot.is_empty():
		return
	var space := world.get_world_3d().direct_space_state
	check(spot.low, "the crates only cover him down low")
	check(not spot.lie, "he can duck behind them")
	check(Cover.hidden_at(space, spot.at, _eye(), Cover.HIDE_HEAD, _exclude()), "hidden behind it, ducked")
	check((spot.at as Vector3).distance_to(Vector3(2.2, 0, -11.0)) < 1.6, "right behind the crate (%s)" % str(spot.at))


func test_behind_a_low_crate_he_lies_flat() -> void:
	await _outlaw(Vector3(0, 0, -12))
	_box(Vector3(2.2, 0.45, -11.0), Vector3(1.0, 0.9, 1.0))
	brain.nerve = 99.0
	await physics_frames(2)
	await _provoke()
	await wait_until(func() -> bool: return brain.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 6)
	await physics_frames(40)
	check(brain.cover.get("lie", false), "a crate that low from that far only hides a man lying down")
	check_eq(outlaw.pose, &"lie", "flat behind it")
	var space := world.get_world_3d().direct_space_state
	check(Cover.hidden_at(space, outlaw.global_position, _eye(), Cover.LIE_HEAD, _exclude()), "and out of sight")


func test_a_wall_is_full_cover_with_somewhere_to_lean_out() -> void:
	await _outlaw(Vector3(0, 0, -12))
	_box(Vector3(-2.5, 1.25, -10.5), Vector3(1.6, 2.5, 0.3))
	await physics_frames(2)
	var spot := Cover.find(world, outlaw.global_position, _eye(), _exclude(), _seeded())
	check(not spot.is_empty() and not spot.low, "full cover behind the wall")
	if spot.is_empty():
		return
	var space := world.get_world_3d().direct_space_state
	check(Cover._sees(space, (spot.peek as Vector3) + Vector3.UP * Cover.GUN_HEIGHT, _eye(), _exclude()), "and a spot to lean out and shoot")


func test_nothing_to_hide_behind_in_the_open() -> void:
	await _outlaw(Vector3(0, 0, -12))
	var spot := Cover.find(world, outlaw.global_position, _eye(), _exclude(), _seeded())
	check(spot.is_empty(), "no cover on bare ground")


# --- Using it ---------------------------------------------------------------------------------------------

func test_he_runs_for_cover_when_shot_at() -> void:
	await _outlaw(Vector3(0, 0, -12))
	_crates()
	brain.nerve = 99.0
	await physics_frames(2)
	var start := outlaw.global_position
	await _provoke()
	var got_there := await wait_until(func() -> bool: return brain.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 6)
	await physics_frames(20)
	check(got_there, "behind cover within a few seconds (%s)" % brain.describe().substr(0, 50))
	check(outlaw.global_position.distance_to(start) > 0.8, "he moved to get there (%.1f m)" % outlaw.global_position.distance_to(start))
	var space := world.get_world_3d().direct_space_state
	var h := Cover.LIE_HEAD if brain.cover.get("lie", false) else Cover.HIDE_HEAD
	check(Cover.hidden_at(space, outlaw.global_position, _eye(), h, _exclude()), "and you can't see him there (%s, %.2f m off the spot %s)" % [outlaw.pose, outlaw.global_position.distance_to(brain.cover.at), brain.cover])
	check(outlaw.pose in [&"crouch", &"duck", &"lie"], "down behind it (%s)" % outlaw.pose)


func test_he_shoots_from_cover_and_ducks_back() -> void:
	await _outlaw(Vector3(0, 0, -12))
	_crates()
	brain.nerve = 99.0
	await physics_frames(2)
	await _provoke()
	var hidden := 0.0
	var peeking := 0.0
	for i in 60 * 14:
		await physics_frames(1)
		if brain.tactic == OutlawBrain.Tactic.HIDDEN:
			hidden += 1.0 / 60.0
		elif brain.tactic == OutlawBrain.Tactic.PEEKING:
			peeking += 1.0 / 60.0
	check(shots_by_outlaw >= 2, "shoots back from there (%d shots)" % shots_by_outlaw)
	check(hidden > 3.0, "spends most of it hidden (%.1f s hidden, %.1f s up)" % [hidden, peeking])
	check(peeking > 0.5, "and comes up to shoot (%.1f s)" % peeking)


func test_rounds_cracking_past_keep_his_head_down() -> void:
	await _outlaw(Vector3(0, 0, -12))
	_crates()
	brain.nerve = 99.0
	await physics_frames(2)
	await _provoke()
	await wait_until(func() -> bool: return brain.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 6)
	shots_by_outlaw = 0
	for k in 8:
		Events.near_miss.emit(outlaw, player, 0.6)
		await physics_frames(20)
	check(brain.suppressed > 0.0, "pinned down")
	check_eq(shots_by_outlaw, 0, "no shooting back while they crack past him")
	check_eq(outlaw.pose, &"duck", "head right down")


# --- Breaking, tending, crawling ---------------------------------------------------------------------------

func test_broken_he_runs_for_it() -> void:
	await _outlaw(Vector3(0, 0, -12))
	brain.flee_chance = 1.0
	await _provoke()
	var d0 := outlaw.global_position.distance_to(player.global_position)
	brain.fear = brain.nerve + 0.5
	await physics_frames(2)
	check_eq(brain.mood, OutlawBrain.Mood.FLEEING, "runs rather than gives up")
	await physics_frames(60 * 4)
	var d1 := outlaw.global_position.distance_to(player.global_position)
	check(d1 > d0 + 8.0, "well away (%.1f m -> %.1f m)" % [d0, d1])
	check(outlaw.held_gun != null, "keeps his gun")


func test_covered_up_close_he_gives_up_instead() -> void:
	await _outlaw(Vector3(0, 0, -4))
	brain.flee_chance = 1.0
	await _provoke()
	brain.fear = brain.nerve + 0.5
	await physics_frames(2)
	check_eq(brain.mood, OutlawBrain.Mood.SURRENDERED, "too close to run: hands up")


func test_left_alone_he_tends_his_wound() -> void:
	await _outlaw(Vector3(0, 0, -12))
	_crates()
	brain.nerve = 99.0
	await physics_frames(2)
	await _provoke()
	await wait_until(func() -> bool: return brain.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 6)
	# A cut artery in his left forearm, pumping.
	outlaw.physiology._add_bleed(&"radial_l", &"forearm_l", 6.0, &"artery")
	brain._quiet = 10.0
	var tended := await wait_until(func() -> bool: return brain.mood == OutlawBrain.Mood.TENDING, 60 * 4)
	check(tended, "he stops to see to it")
	var belt := await wait_until(func() -> bool:
		for b: Dictionary in outlaw.physiology.bleeds:
			if b.tourniquet:
				return true
		return false, 60 * 8)
	check(belt, "and cinches a belt round the arm")
	check(outlaw.pose == &"tend" or brain.mood == OutlawBrain.Mood.FIGHTING, "hands on it (%s)" % outlaw.pose)


func test_legs_gone_he_crawls_and_fights_on() -> void:
	await _outlaw(Vector3(0, 0, -12))
	brain.nerve = 99.0
	await _provoke()
	outlaw.physiology.broken[&"femur_r"] = true
	await physics_frames(10)
	check(outlaw.prone, "down on his belly")
	check(not outlaw.limp, "not a ragdoll: still moving")
	check(outlaw.physiology.is_conscious(), "and with it")
	await physics_frames(60 * 5)
	check(shots_by_outlaw >= 1, "still shooting from the ground (%d)" % shots_by_outlaw)
	var start := outlaw.global_position
	for i in 60:
		outlaw.walk_to(start + Vector3(3, 0, 0), 3.8, 1.0 / 60.0)
		await physics_frames(1)
	var crawled := outlaw.global_position.distance_to(start)
	check(crawled > 0.1 and crawled < 0.45, "crawls, slowly (%.2f m in a second)" % crawled)
	check_eq(outlaw.gait, &"crawl", "crawling")


# --- Moving ------------------------------------------------------------------------------------------------

func test_he_does_not_walk_through_walls() -> void:
	await _outlaw(Vector3(0, 0, -12))
	brain.set_physics_process(false)
	_box(Vector3(0, 1.25, -14.0), Vector3(4.0, 2.5, 0.3))
	await physics_frames(2)
	for i in 60 * 3:
		outlaw.walk_to(Vector3(0, 0, -17), 3.8, 1.0 / 60.0)
		await physics_frames(1)
	check(outlaw.global_position.z > -14.0, "stopped at the wall (z %.2f)" % outlaw.global_position.z)


func test_a_bad_leg_makes_him_limp() -> void:
	await _outlaw(Vector3(0, 0, -12))
	brain.set_physics_process(false)
	outlaw.physiology.muscle_damage[&"quadriceps_r"] = 0.9
	outlaw.physiology.muscle_damage[&"hamstrings_r"] = 0.9
	var start := outlaw.global_position
	for i in 60:
		outlaw.walk_to(start + Vector3(10, 0, 0), 3.8, 1.0 / 60.0)
		await physics_frames(1)
	var went := outlaw.global_position.distance_to(start)
	check_eq(outlaw.gait, &"limp", "limping")
	check(went < 2.0, "slow (%.1f m in a second)" % went)


# --- On the real range ---------------------------------------------------------------------------------

func test_on_the_range_he_uses_the_cover_there() -> void:
	player.queue_free()  # only the street's player here
	await physics_frames(1)
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	var p: Player = street.get_node(^"Player")
	p.global_position = Vector3(14.0, 0.0, -8.4)
	p.rotation = Vector3(0, deg_to_rad(-90), 0)
	var man: HumanBody = street.find_child("OutlawSpawn", true, false).spawn()
	await physics_frames(5)
	var b: OutlawBrain = man.get_node(^"Brain")
	b.nerve = 99.0
	var shots := [0]
	var count := func(_o: Vector3, _d: Vector3, who: Node) -> void: if who == man: shots[0] += 1
	Events.shot_fired.connect(count)
	var bl := street.find_child("Ballistics", true, false) as Ballistics
	var t: RevolverTuning = load("res://config/revolver.tres")
	var ex: Array[RID] = [p.get_rid()]
	var from := p.camera.global_position
	var near := man.global_position + Vector3(0.0, 1.6, 1.0)
	var bullet := bl.fire(from, (near - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, ex)
	bullet.shooter = p
	var hid := await wait_until(func() -> bool: return b.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 8)
	check(hid, "gets behind something (%s)" % b.describe().substr(0, 60))
	await physics_frames(60 * 10)
	Events.shot_fired.disconnect(count)
	check(shots[0] >= 2, "and shoots from it (%d shots)" % shots[0])
	print("  on the range he took cover at %s (%s)" % [str(b.cover.get("at", "-")), "lying" if b.cover.get("lie", false) else ("low" if b.cover.get("low", false) else "a wall")])
	street.queue_free()
