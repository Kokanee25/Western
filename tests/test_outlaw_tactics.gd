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
		Events.near_miss.emit(outlaw, player, 0.6, outlaw.global_position + Vector3(0.6, 1.5, 0), 240.0, false)
		await physics_frames(20)
	check(brain.suppressed > 0.0, "pinned down")
	check_eq(shots_by_outlaw, 0, "no shooting back while they crack past him")
	check_eq(outlaw.pose, &"duck", "head right down")


# --- Shaken, not broken (variant C) --------------------------------------------------------------------------

## Past his nerve behind cover he goes to ground rather than give up: head right down, not
## shooting. Let be, it passes and he's back in it.
func test_shaken_behind_cover_he_gets_his_nerve_back() -> void:
	await _outlaw(Vector3(0, 0, -12))
	brain.variant = OutlawBrain.Variant.C  # the gunfight lab's C: shaken first
	_crates()
	brain.nerve = 99.0
	await physics_frames(2)
	await _provoke()
	await wait_until(func() -> bool: return brain.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 6)
	brain.nerve = 0.75
	brain.fear = brain.nerve + 0.1
	shots_by_outlaw = 0
	await physics_frames(60)
	check(brain.mood == OutlawBrain.Mood.FIGHTING and brain._shaken >= 0.0, "gone to ground, not given up (%s)" % brain.describe().substr(0, 70))
	check(outlaw.pose in [&"duck", &"lie"], "head right down (%s)" % outlaw.pose)
	var back := await wait_until(func() -> bool: return brain._shaken < 0.0, 60 * 6)
	check(back and brain.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING], "it passes and he's back in it (%s)" % brain.describe().substr(0, 70))
	check(brain.fear <= brain.nerve, "his fear's settled (%.2f)" % brain.fear)


## Kept at it while he's down there, it doesn't pass: he breaks after all. Far past his nerve he
## breaks at once, cover or no.
func test_shaken_and_kept_at_it_he_breaks() -> void:
	await _outlaw(Vector3(0, 0, -12))
	brain.variant = OutlawBrain.Variant.C  # the gunfight lab's C: shaken first
	_crates()
	brain.nerve = 99.0
	brain.flee_chance = 0.0
	await physics_frames(2)
	await _provoke()
	await wait_until(func() -> bool: return brain.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 6)
	brain.nerve = 0.75
	brain.fear = brain.nerve + 0.05
	var k := 0
	while k < 60 * 9 and brain.mood != OutlawBrain.Mood.SURRENDERED:
		if k % 45 == 0:
			Events.near_miss.emit(outlaw, player, 2.2, outlaw.global_position + Vector3(2.2, 1.5, 0), 240.0, false)
		await physics_frames(1)
		k += 1
	check_eq(brain.mood, OutlawBrain.Mood.SURRENDERED, "gives up in the end")
	check(k > 60 * 2, "but not on the spot (%.1f s)" % (k / 60.0))


func test_far_past_his_nerve_cover_doesnt_hold_him() -> void:
	await _outlaw(Vector3(0, 0, -12))
	brain.variant = OutlawBrain.Variant.C  # the gunfight lab's C: shaken first
	_crates()
	brain.nerve = 99.0
	brain.flee_chance = 0.0
	await physics_frames(2)
	await _provoke()
	await wait_until(func() -> bool: return brain.tactic == OutlawBrain.Tactic.HIDDEN, 60 * 6)
	brain.nerve = 0.75
	brain.fear = brain.nerve + brain.shaken_margin + 0.05
	await physics_frames(2)
	check_eq(brain.mood, OutlawBrain.Mood.SURRENDERED, "gives up there and then")


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
	# At the range line (where the range stands now: config/town.json).
	p.global_position = (street.get_node(^"RangeCover") as Node3D).global_transform * Vector3(14.0, 0.0, -8.4)
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


# --- Holding his cover (variant D's hold_cover, #294) ------------------------------------------------

## A wall between you and him: he can hear you, not see you.
func _wall_between() -> void:
	_box(Vector3(0, 1.5, -6.0), Vector3(10.0, 3.0, 0.4))


func test_a_shot_he_hears_puts_you_at_your_feet_not_over_your_gun() -> void:
	_wall_between()
	await _outlaw(Vector3(0, 0, -12))
	brain.variant = OutlawBrain.Variant.D  # the game's (an earlier file may leave default_variant at A)
	brain.target = player
	brain.senses.note(player, Vector3(0.5, 0.0, 0.0), 0.0)
	await physics_frames(2)
	check(not brain.senses.sees(player), "he can't see you through the wall")
	brain._on_heard(Vector3(0.6, 1.4, 0.2), &"gunshot", null)
	var lk := brain.senses.last_known(player)
	check(Vector2(lk.x - 0.6, lk.z - 0.2).length() < 0.01, "he takes the shot for you (%s)" % lk)
	check(absf(lk.y) < 0.05, "at your feet, not up at your gun (%.2f m up)" % lk.y)
	check(absf(brain._eye_of(player).y - 1.6) < 0.05, "so your eyes a man's height up (%.2f)" % brain._eye_of(player).y)


func test_behind_cover_he_holds_it_against_what_he_knows_not_a_guess() -> void:
	_wall_between()
	await _outlaw(Vector3(0, 0, -12))
	brain.variant = OutlawBrain.Variant.D  # the game's (an earlier file may leave default_variant at A)
	brain.target = player
	brain.senses.note(player, Vector3(0.5, 0.0, 0.0), 0.0)
	await physics_frames(2)
	var chosen := Vector3(0.5, 1.6, 0.0)
	brain.cover = {"at": outlaw.global_position, "eye": chosen, "low": false}
	brain._sure = false
	check(brain._held_eye(Vector3(4.0, 1.6, 2.0)) == chosen, "a new guess at where you are doesn't move it")
	brain._on_near_miss(outlaw, player, 1.0, outlaw.global_position, 300.0, false)
	check(brain._held_eye(Vector3(4.0, 1.6, 2.0)) == Vector3(4.0, 1.6, 2.0), "a ball past him does")
	check(brain._held_eye(Vector3(-3.0, 1.6, 1.0)) == Vector3(4.0, 1.6, 2.0), "and holds there till the next thing he's sure of")
	OutlawBrain.d_fixes.erase(&"hold_cover")
	check(brain._held_eye(Vector3(-3.0, 1.6, 1.0)) == Vector3(-3.0, 1.6, 1.0), "without the fix, his guess as before")
	OutlawBrain.d_fixes = OutlawBrain.D_FIXES.duplicate()


# --- Watching the spot (variant D's watch_spot, #477) ----------------------------------------------

## As if he last saw or heard you `ago` seconds back, at `at`.
func _known_ago(at: Vector3, ago: float) -> void:
	brain.senses.note(player, at, 0.0)
	var k: Dictionary = brain.senses.known[player]
	k.seen = false
	k.heard_time = brain.senses._clock - ago
	k.last_time = minf(float(k.last_time), k.heard_time)


func test_behind_cover_he_watches_where_you_were_rather_than_go_looking() -> void:
	_wall_between()
	await _outlaw(Vector3(0, 0, -12))
	brain.variant = OutlawBrain.Variant.D  # the game's (an earlier file may leave default_variant at A)
	brain.target = player
	await physics_frames(2)
	check(not brain.senses.sees(player), "he can't see you through the wall")
	_known_ago(Vector3(0.5, 0.0, 0.0), 6.0)
	check(not brain._lost_you(player), "6 s quiet, 12 m off: he watches the spot")
	_known_ago(Vector3(0.5, 0.0, 0.0), OutlawBrain.WATCH_ALONE + 1.0)
	check(brain._lost_you(player), "on his own, past WATCH_ALONE he goes to look")
	_known_ago(Vector3(0.5, 0.0, 0.0), OutlawBrain.WATCH_ALONE - 1.0)
	check(not brain._lost_you(player), "short of it he still watches")
	_known_ago(Vector3(0.0, 0.0, 8.0), 6.0)
	check(brain._lost_you(player), "his idea of you 20 m off: he's lost you")
	brain.senses.known.erase(player)
	check(brain._lost_you(player), "no idea of you at all: he's lost you")
	_known_ago(Vector3(0.5, 0.0, 0.0), 6.0)
	OutlawBrain.d_fixes.erase(&"watch_spot")
	check(brain._lost_you(player), "without the fix, 4 s and he goes, as before")
	OutlawBrain.d_fixes = OutlawBrain.D_FIXES.duplicate()


func test_watching_he_stays_behind_his_cover_in_the_fight() -> void:
	_wall_between()
	await _outlaw(Vector3(0, 0, -6.8))  # right behind the wall
	brain.variant = OutlawBrain.Variant.D  # the game's (an earlier file may leave default_variant at A)
	brain.target = player
	await physics_frames(2)
	brain._set_mood(OutlawBrain.Mood.FIGHTING)
	brain.cover = {"at": outlaw.global_position, "eye": Vector3(0.5, 1.6, 0.0), "low": false, "peek": outlaw.global_position}
	brain.tactic = OutlawBrain.Tactic.HIDDEN
	brain._tactic_time = 5.0
	brain._flank_after = 99.0
	brain._in_cover = 0.0
	_known_ago(Vector3(0.5, 0.0, 0.0), 6.0)
	brain._combat(0.1)
	check(brain.tactic == OutlawBrain.Tactic.HIDDEN, "6 s quiet: still behind his cover (%s)" % OutlawBrain.Tactic.keys()[brain.tactic])
	OutlawBrain.d_fixes.erase(&"watch_spot")
	brain._combat(0.1)
	check(brain.tactic == OutlawBrain.Tactic.SEARCHING, "without the fix he goes to look (%s)" % OutlawBrain.Tactic.keys()[brain.tactic])
	OutlawBrain.d_fixes = OutlawBrain.D_FIXES.duplicate()


## A planted stick's fuse hissing a few metres off (#506): he hears it, it frightens him and turns
## his head; one round the corner out of earshot he doesn't.
func test_he_hears_a_planted_fuse() -> void:
	await _outlaw(Vector3(0, 0, -10))
	# 2 m off: a hiss carries 3 m from the stick to his ears (issue #537), his eyes 1.6 m up.
	var near := DynamiteStick.make(world, Vector3(2.0, 0.02, -10.0), Vector3.ZERO, 60.0)
	near.planted = true
	near.light()
	await physics_frames(70)
	var heard := float(brain.fear_from.get(&"a fuse hissing", 0.0))
	check(heard > 0.0, "a fuse 2 m off frightens him (%.2f)" % heard)
	near.queue_free()
	brain.fear_from.erase(&"a fuse hissing")
	var far := DynamiteStick.make(world, Vector3(30.0, 0.02, -10.0), Vector3.ZERO, 60.0)
	far.planted = true
	far.light()
	await physics_frames(70)
	check_eq(float(brain.fear_from.get(&"a fuse hissing", 0.0)), 0.0, "one 30 m off he doesn't hear")
	far.queue_free()
