extends TestCase
## Fights that commit (OutlawBrain's variant D; Sean's first play, issue #257: "the bad guys just
## kept quitting"): noise pins a man but doesn't break him; a hothead holds his first half minute;
## the man who leads them holds the rest while he's in it and calls a shaken one back; the Kid
## running barely shakes the others; a steady man takes the thump of a ball better than a green one.

var world: Node3D
var ballistics: Ballistics
var player: Player
var men := {}  ## id -> HumanBody
var calls: Array[Dictionary] = []


func before_each() -> void:
	OutlawBrain.d_fixes = OutlawBrain.D_FIXES.duplicate()
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(90, 1, 90)
	cs.shape = bs
	ground.add_child(cs)
	ground.position = Vector3(0, -0.5, 0)
	world.add_child(ground)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.remove_meta(&"human_body")  # their rounds stop on you without wounding
	men.clear()
	calls.clear()
	Events.callout.connect(_on_callout)
	await physics_frames(2)


func after_each() -> void:
	Events.callout.disconnect(_on_callout)
	world.queue_free()
	await physics_frames(2)


func _on_callout(speaker: Node, kind: StringName, about: Node, _at: Vector3) -> void:
	calls.append({"who": (speaker as HumanBody).person_id, "kind": kind, "about": about})


func _man(id: StringName, at: Vector3, nerve: float, temper: float, leads := false, variant := OutlawBrain.Variant.D) -> HumanBody:
	var m := HumanBody.new()
	m.name = String(id).capitalize()
	m.person_id = id
	m.rng_seed = 400 + men.size() * 7
	var b := OutlawBrain.new()
	b.name = "Brain"
	b.nerve = nerve
	b.temper = temper
	b.leads = leads
	b.variant = variant
	var friends: Array[StringName] = []
	for other: StringName in [&"brody", &"lyle", &"kid"]:
		if other != id:
			friends.append(other)
	b.friends = friends
	m.add_child(b)
	world.add_child(m)
	m.global_position = at
	m.rotation_degrees.y = 180.0
	men[id] = m
	return m


func _brain(id: StringName) -> OutlawBrain:
	return (men[id] as HumanBody).get_node(^"Brain") as OutlawBrain


## The three of them 12 m off, in a fight with you (as in the game: Brody leads).
func _gang(variant := OutlawBrain.Variant.D) -> void:
	_man(&"brody", Vector3(-3.0, 0, -12.0), 0.95, 0.2, true, variant)
	_man(&"lyle", Vector3(0.0, 0, -12.0), 0.7, 0.9, false, variant)
	_man(&"kid", Vector3(3.0, 0, -12.0), 0.3, 0.45, false, variant)
	await physics_frames(5)
	for id: StringName in men:
		_brain(id)._start_fight(player)
		_brain(id).fear = 0.0
	await physics_frames(45)  # each man's taken in who's with him (the leader looked for twice a second)


func _in_it(id: StringName) -> bool:
	return _brain(id).mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING]


func test_near_misses_pin_him_but_dont_break_him() -> void:
	await _gang()
	var kid := _brain(&"kid")
	for i in 12:
		kid._on_near_miss(men[&"kid"], player, 0.3, Vector3.ZERO, 300.0, false)
	check(kid.fright > 1.0, "a dozen balls cracking past frighten him (fright %.2f)" % kid.fright)
	check(kid.suppressed > 0.0, "and put his head down (%.1f s)" % kid.suppressed)
	check(kid.dread() <= kid.fear + OutlawBrain.FRIGHT_SHARE * kid.nerve + 0.001, "but count for at most a share of his nerve (%.2f)" % kid.dread())
	await physics_frames(10)
	check(_in_it(&"kid"), "the Kid's still in it (%s)" % kid.describe().substr(0, 60))


func test_near_misses_break_a_green_man_as_he_was() -> void:
	await _gang(OutlawBrain.Variant.C)
	var kid := _brain(&"kid")
	for i in 12:
		kid._on_near_miss(men[&"kid"], player, 0.3, Vector3.ZERO, 300.0, false)
	var broke := await wait_until(func() -> bool: return not _in_it(&"kid"), 30)
	check(broke, "in C the noise alone breaks the Kid (%s)" % kid.describe().substr(0, 60))


func test_the_hothead_holds_his_first_half_minute() -> void:
	await _gang()
	var lyle := _brain(&"lyle")
	lyle.fear = lyle.nerve + 0.3
	await physics_frames(20)
	check(_in_it(&"lyle"), "past his nerve early on, Lyle fights on (%.2f / %.2f)" % [lyle.dread(), lyle.nerve_now()])
	lyle._fight_from = lyle._now - OutlawBrain.HOT_EARLY - 1.0
	var broke := await wait_until(func() -> bool: return not _in_it(&"lyle"), 60)
	check(broke, "half a minute in, the same fear breaks him (%s)" % lyle.describe().substr(0, 60))


func test_the_leader_holds_the_rest_while_hes_in_it() -> void:
	await _gang()
	var kid := _brain(&"kid")
	kid.nerve = 0.5
	kid.fear = 0.6  # past his own nerve, inside it with Brody's
	await physics_frames(60)
	check(_in_it(&"kid"), "with Brody up and in it the Kid holds (%.2f / %.2f)" % [kid.dread(), kid.nerve_now()])
	(men[&"brody"] as HumanBody).go_limp()
	kid.fear = 0.6
	var broke := await wait_until(func() -> bool: return not _in_it(&"kid"), 90)
	check(broke, "Brody down, he breaks (%s)" % kid.describe().substr(0, 60))


func test_the_leader_calls_a_shaken_man_back() -> void:
	await _gang()
	var lyle := _brain(&"lyle")
	lyle._shaken = 0.5
	lyle.fear = 0.8
	Events.callout.emit(men[&"lyle"], &"shaken", player, Vector3.INF)
	await physics_frames(3)
	check(calls.any(func(c: Dictionary) -> bool: return c.who == &"brody" and c.kind == &"hold" and c.about == men[&"lyle"]),
			"Brody tells him to stay in it: %s" % str(calls.slice(-3)))
	check_near(lyle.fear, 0.8 - OutlawBrain.LEADER_HOLD, 0.05, "and it steadies him")


func test_the_kid_running_barely_shakes_the_others() -> void:
	await _gang()
	var brody := _brain(&"brody")
	var before := brody.fear
	brody._mate_out(men[&"kid"], &"fled", true)
	var kid_cost := brody.fear - before
	before = brody.fear
	brody._mate_out(men[&"lyle"], &"fled", true)
	var lyle_cost := brody.fear - before
	check(kid_cost < lyle_cost * 0.6, "the Kid running frightens Brody less than Lyle running (%.3f against %.3f)" % [kid_cost, lyle_cost])


func test_a_steady_man_takes_a_ball_better_than_a_green_one() -> void:
	await _gang()
	check(_brain(&"brody")._thump() < 0.55, "Brody feels half the thump (%.2f)" % _brain(&"brody")._thump())
	check(_brain(&"kid")._thump() > 0.8, "the Kid nearly all of it (%.2f)" % _brain(&"kid")._thump())


func test_one_comes_at_you_when_you_reload_and_the_rest_cover_him() -> void:
	await _gang()
	(player.revolver() as RevolverViewmodel).state.gate_open = true  # the gate open: reloading
	var went := await wait_until(func() -> bool:
		return men.keys().any(func(id: StringName) -> bool: return _brain(id)._press > 0.0), 60 * 3)
	check(went, "one of them comes at you (%s)" % " | ".join(men.keys().map(func(id: StringName) -> String: return _brain(id).decision)))
	await physics_frames(10)
	var pressing: Array = men.keys().filter(func(id: StringName) -> bool: return _brain(id)._press > 0.0)
	check_eq(pressing.size(), 1, "just the one (%s)" % str(pressing))
	check(calls.any(func(c: Dictionary) -> bool: return c.kind == &"press"), "and he calls it: %s" % str(calls.slice(-4)))
	(player.revolver() as RevolverViewmodel).state.gate_open = false


func test_in_the_open_under_fire_he_fights_from_a_knee() -> void:
	await _gang()
	await physics_frames(30)  # each man's taken it in and drawn
	var lyle := _brain(&"lyle")
	lyle.tactic = OutlawBrain.Tactic.OPEN
	lyle._stand_and_fight = true  # no running for cover in this one
	lyle._quiet = 0.0
	await physics_frames(2)
	check_eq((men[&"lyle"] as HumanBody).pose, &"crouch_aim", "down on a knee, fighting")
	lyle._quiet = OutlawBrain.GO_LOW_QUIET + 1.0
	await physics_frames(2)
	lyle._quiet = OutlawBrain.GO_LOW_QUIET + 1.0
	await physics_frames(1)
	check_eq((men[&"lyle"] as HumanBody).pose, &"aim", "up again once you've stopped shooting")


func test_a_friend_still_on_you_keeps_him_in_it() -> void:
	await _gang()
	await physics_frames(30)
	var on := _brain(&"kid")._mate_on(player)
	check(on != null, "the Kid knows a friend's still on you (%s)" % (on.body.name if on else "nobody"))
	for id: StringName in [&"brody", &"lyle"]:
		(men[id] as HumanBody).go_limp()
	await physics_frames(5)
	check(_brain(&"kid")._mate_on(player) == null, "with them down, nobody is")


## Variant D's `wince` (on trial: `fixes=all+wince`; Sean, 2026-10-23): a ball in the arm and he
## stops shooting, gets low out of your sight and looks at it; seen to be light, it frightens him
## less and he's back in it.
func _arm_hit(id: StringName) -> Dictionary:
	var m := men[id] as HumanBody
	var arm := m.parts[&"upper_arm_l"] as Node3D
	return {"person": m, "kind": &"bullet", "segment": &"upper_arm_l", "position": arm.global_position, "direction": Vector3.FORWARD,
			"severe": false, "deposited": 40.0, "hits": [], "shooter": player, "knocked_down": false}


func test_hit_he_winces_and_gets_out_of_sight_to_look_at_it() -> void:
	OutlawBrain.d_fixes.append(&"wince")
	await _gang()
	await physics_frames(30)
	var brody := _brain(&"brody")
	brody.tactic = OutlawBrain.Tactic.OPEN
	var rounds := brody.rounds
	var before := brody.fear
	brody._on_hit(_arm_hit(&"brody"))
	var scared := brody.fear - before
	check(brody._wince > 1.0, "he takes a moment over it (%.1f s)" % brody._wince)
	await physics_frames(20)
	check_eq(brody.rounds, rounds, "and doesn't shoot meanwhile")
	check((men[&"brody"] as HumanBody).pose in [&"duck", &"wince"] or brody.tactic == OutlawBrain.Tactic.MOVING,
			"low, hunched over it, or off to cover (%s, %s)" % [(men[&"brody"] as HumanBody).pose, brody.decision])
	var seen := await wait_until(func() -> bool: return brody._wince <= 0.0, 60 * 5)
	check(seen, "he's looked at it")
	check(brody.decision.begins_with("seen his wound: light"), "a light one (%s)" % brody.decision)
	check(brody.fear < before + scared - 0.01, "and it frightens him less than it did (%.2f, %.2f when it hit)" % [brody.fear, before + scared])


func test_without_wince_he_fights_on_through_it() -> void:
	await _gang()
	await physics_frames(30)
	var brody := _brain(&"brody")
	brody._on_hit(_arm_hit(&"brody"))
	check_eq(brody._wince, 0.0, "no wince without the fix")


## Variant D's `pain_fight` (on trial, Experiment A): past disabling, the pain takes him in bouts, and
## in between he fights hurt; as it was, it's a wall.
func _in_pain(id: StringName, felt: float) -> void:
	var p := (men[id] as HumanBody).physiology
	p.adrenaline = 0.0
	p.pain = felt


func test_past_disabling_pain_he_fights_between_bouts() -> void:
	OutlawBrain.d_fixes.append(&"pain_fight")
	await _gang()
	await physics_frames(30)
	var lyle := _brain(&"lyle")
	lyle.tactic = OutlawBrain.Tactic.OPEN
	lyle._stand_and_fight = true
	_in_pain(&"lyle", 1.3)
	await physics_frames(2)
	check(lyle._pain_locked(), "it takes him first (a bout of %.1f s)" % lyle._pain_bout)
	var rounds := lyle.rounds
	var fired := await wait_until(func() -> bool:
		_in_pain(&"lyle", 1.3)
		return lyle.rounds < rounds, 60 * 8)
	check(fired, "then he fights through it (%s)" % lyle.decision)


func test_without_pain_fight_the_pain_is_a_wall() -> void:
	await _gang()
	await physics_frames(30)
	var lyle := _brain(&"lyle")
	lyle.tactic = OutlawBrain.Tactic.OPEN
	lyle._stand_and_fight = true
	var rounds := lyle.rounds
	for i in 60 * 4:
		_in_pain(&"lyle", 1.3)
		await physics_frames(1)
	check(lyle._pain_locked(), "past disabling he can only hold it")
	check_eq(lyle.rounds, rounds, "and doesn't shoot")


## Variant D's `floor_fight` (on trial): down and still with it, gun in hand, he comes to on his
## belly and fights from the floor.
func test_shot_down_he_comes_to_and_fights_from_the_floor() -> void:
	OutlawBrain.d_fixes.append(&"floor_fight")
	await _gang()
	await physics_frames(30)
	for id: StringName in [&"brody", &"kid"]:  # (nobody to drag him off to cover)
		(men[id] as HumanBody).queue_free()
		men.erase(id)
	var m := men[&"lyle"] as HumanBody
	m.go_limp()
	var up := await wait_until(func() -> bool: return m.prone and not m.limp and not m.rising, 60 * 8)
	check(up, "on his belly (limp %s, prone %s, rising %s; %s)" % [m.limp, m.prone, m.rising, _brain(&"lyle").decision])
	await physics_frames(10)
	check(_in_it(&"lyle"), "and back in it (%s)" % _brain(&"lyle").describe().substr(0, 60))
	check(m.pose in HumanBody.PRONE_POSES, "fighting from where he lies (%s)" % m.pose)


func test_without_floor_fight_he_lies_there() -> void:
	await _gang()
	await physics_frames(30)
	var m := men[&"lyle"] as HumanBody
	m.go_limp()
	await physics_frames(60 * 4)
	check(m.limp, "he lies where he fell")


## Variant D's `odds` (on trial, spec 1C): past his nerve he weighs it. A fresh hit gives him a
## moment; a hothead cornered fights it out; a man who can't run but can stand backs off.
func test_a_hit_gives_him_a_moment_before_fear_breaks_him() -> void:
	OutlawBrain.d_fixes.append(&"odds")
	await _gang()
	await physics_frames(30)
	var brody := _brain(&"brody")
	brody._on_hit(_arm_hit(&"brody"))
	brody.fear = brody.nerve_now() + 0.1
	await physics_frames(20)
	check(_in_it(&"brody"), "just hit and past his nerve, he takes stock (%s)" % brody.decision)


func test_a_cornered_hothead_fights_it_out() -> void:
	OutlawBrain.d_fixes.append(&"odds")
	await _gang()
	await physics_frames(30)
	var lyle := _brain(&"lyle")
	lyle._fight_from = lyle._now - OutlawBrain.HOT_EARLY - 1.0
	lyle._aimed_at = 1.0
	(men[&"lyle"] as HumanBody).global_position = Vector3(0, 0, -4)  # your gun on him, close
	lyle.fear = lyle.nerve_now() + 0.2
	await physics_frames(5)
	check(lyle.decision.begins_with("fight it out"), "covered close, Lyle fights it out (%s)" % lyle.decision)
	check(lyle.rage > 0.0 and _in_it(&"lyle"), "in a rage, still in it")


func test_hurt_past_running_he_backs_off_at_a_walk() -> void:
	OutlawBrain.d_fixes.append(&"odds")
	await _gang()
	await physics_frames(30)
	var kid := _brain(&"kid")
	(men[&"kid"] as HumanBody).physiology.adrenaline = 0.0
	(men[&"kid"] as HumanBody).physiology.pain = 1.2  # past disabling: can't run
	kid._hid_once = true  # (he's lain low already)
	kid.fear = kid.nerve_now() + 0.1
	await physics_frames(5)
	check(kid.decision.begins_with("back off"), "he backs off (%s)" % kid.decision)
	check_eq(kid.mood, OutlawBrain.Mood.FLEEING, "going, not giving up")
