extends TestCase
## The seated player and the card game (#766, No Law step 2; PlayerSeat, CardGame, Poker,
## config/card_game.json): E by a free chair at the saloon yard's card table sits you down, where you
## look round but can't walk or draw; the men there deal you in and play five-card draw by its
## rules; E stands you up (unless an act holds you); the chair kicked out from under you drops you
## on the floor; a shot, a man out of his chair or an act stops the game where it lies.

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	ValleyFolk.murder_auto = false  # No Law's murder (#773) has its own tests
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func _game() -> CardGame:
	return valley.folk.cards


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _chair(c: String) -> KitProp:
	return valley.folk.props["chair_" + c] as KitProp


## Nine at night, everyone in, the game at four times its pace.
func _night() -> void:
	var clock := valley.get_node(^"DayCycle") as DayCycle
	if clock.time_of_day < 20.0:
		clock.set_time(21.0)
		await physics_frames(1)
		valley.folk._look = 0.0
		await physics_frames(60)
	_game().speed = 4.0


## Stood behind chair `c`, facing the table over it.
func _behind(c: String) -> void:
	var p := _player()
	if p.seat.seated():
		p.seat.stand()
	var ch := _chair(c)
	p.global_position = Seating.spot(ch) - ch.global_basis.z * 0.5
	p.velocity = Vector3.ZERO
	var to := ch.global_basis.z
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(2)


func test_five_card_draw_s_hands() -> void:
	# 0 two .. 12 ace; suits spades, hearts, diamonds, clubs (13 each).
	var c := func(r: int, s: int) -> int: return s * 13 + r
	var pair_9 := [c.call(7, 0), c.call(7, 1), c.call(12, 2), c.call(3, 3), c.call(0, 0)]
	var two_pair := [c.call(11, 0), c.call(11, 1), c.call(2, 2), c.call(2, 3), c.call(5, 0)]
	var wheel := [c.call(12, 0), c.call(0, 1), c.call(1, 2), c.call(2, 3), c.call(3, 0)]
	var flush := [c.call(1, 1), c.call(4, 1), c.call(6, 1), c.call(9, 1), c.call(11, 1)]
	var boat := [c.call(8, 0), c.call(8, 1), c.call(8, 2), c.call(0, 3), c.call(0, 0)]
	var ace_high := [c.call(12, 0), c.call(10, 1), c.call(6, 2), c.call(3, 3), c.call(1, 0)]
	check_eq(Poker.name(pair_9), "a pair of nines", "a pair")
	check_eq(Poker.name(two_pair), "two pair, kings and fours", "two pair")
	check_eq(Poker.name(wheel), "a straight, five high", "the wheel")
	check_eq(Poker.name(flush), "a flush", "a flush")
	check_eq(Poker.name(boat), "a full house, tens over twos", "a full house")
	check_eq(Poker.name(ace_high), "ace high", "nothing")
	check(Poker.compare(two_pair, pair_9) > 0 and Poker.compare(flush, wheel) > 0 and Poker.compare(boat, flush) > 0, "the order of hands")
	check(Poker.compare(pair_9, ace_high) > 0 and Poker.compare(ace_high, ace_high) == 0, "a pair beats ace high; a split")
	check_eq(Poker.discards(pair_9), [2, 3, 4], "a pair keeps the pair")
	check_eq(Poker.discards(two_pair), [4], "two pair throws the odd one")
	check_eq(Poker.discards(boat), [], "a made hand stands pat")
	check_eq(Poker.discards(ace_high).size(), 3, "three at most")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var d := Poker.deck(rng)
	var seen := {}
	for x in d:
		seen[x] = true
	check(d.size() == 52 and seen.size() == 52, "a whole deck")


func test_sat_at_the_table_at_night_dealt_in() -> void:
	await _night()
	var p := _player()
	var g := _game()
	check(g != null and g.chairs.size() == 4, "the game at the yard's table, its four chairs")
	await _behind("n")
	check(p.seat.chair_here() == _chair("n"), "the north chair's the one E would sit you in (%s)" % p.seat.report())
	# E, as the key: you sit.
	Input.action_press(&"shove")
	await physics_frames(2)
	Input.action_release(&"shove")
	await physics_frames(30)
	check(p.seat.seated(), "E sat you down (%s)" % p.seat.report())
	check(_chair("n").seated == p, "your weight's on its seat")
	check_eq(p.shove.move, &"", "E wasn't a shove")
	check(p.get_eye_height() < 1.35 and p.get_eye_height() > 1.0, "eyes at a sitting height (%.2f)" % p.get_eye_height())
	# Can't walk.
	var at := p.global_position
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	await physics_frames(40)
	Input.action_release(&"move_forward")
	Input.action_release(&"run")
	check(p.global_position.distance_to(at) < 0.02, "can't walk (moved %.3f m)" % p.global_position.distance_to(at))
	# Look round, but only so far: the view kept within the chair's turn.
	var face := atan2(-_chair("n").global_basis.z.x, -_chair("n").global_basis.z.z)
	p.add_look(Vector2(60.0, 0.0))
	check(absf(angle_difference(p.rotation.y, face)) > deg_to_rad(50.0), "you can look round")
	p.add_look(Vector2(150.0, -30.0))
	check(absf(angle_difference(p.rotation.y, face)) <= deg_to_rad(p.tuning.seat_turn_deg) + 0.01, "not right round (%.0f deg)" % rad_to_deg(angle_difference(p.rotation.y, face)))
	p.rotation.y = face
	p.add_look(Vector2(0.0, 30.0))
	# No gun.
	p.select_weapon(p.revolver())
	await physics_frames(40)
	check(not p.revolver().drawn, "the gun stays put away")
	check_eq(p.revolver().why_not(&"fire"), "you're sat at the table", "and says why")
	# Dealt in: five cards each, you among them, played to a showdown.
	var dealt := await wait_until(func() -> bool:
		return g.you_in() and (g._seat(CardGame.YOU).cards as Array).size() == 5, 60 * 40)
	check(dealt, "dealt in within 40 s (%s)" % g.report())
	var start := g.hands
	var played := await wait_until(func() -> bool: return g.hands > start, 60 * 90)  # you waited on 10 s a turn (you_wait_s)
	var r := g.report()
	check(played, "a hand played out with you in it (%s)" % r)
	check_eq(r.seats.size(), 3, "you, Earl and the drifter")
	check(r.cards_on_table >= 15, "the cards on the table (%d)" % r.cards_on_table)
	check(r.last_winner != "" and r.last_hand != "", "someone took the pot (%s with %s)" % [r.last_winner, r.last_hand])
	var chips := 0
	for s: Dictionary in r.seats:
		chips += int(s.stack)
	check_eq(chips + int(r.pot), 20 + 40 + 40, "no chip made or lost")
	# E: up, a step clear of the chair, and the game goes on without you.
	p.seat.use()
	await physics_frames(10)
	check(not p.seat.seated() and _chair("n").seated == null, "E stood you up")
	check(Vector2(p.global_position.x - Seating.spot(_chair("n")).x, p.global_position.z - Seating.spot(_chair("n")).z).length() > 0.4, "clear of the chair")
	await physics_frames(60)
	check(g.state != &"stopped", "the game goes on without you (%s)" % g.state)
	check(not g.you_in(), "you're out of the hand")


func test_an_act_holds_you_in_your_seat() -> void:
	await _night()
	var p := _player()
	await _behind("s")
	check(p.seat.use() == &"sat", "sat in the south chair")
	p.seat.hold(&"act", "Sit still.")
	check_eq(p.seat.use(), &"held", "E doesn't stand you while it holds you")
	await physics_frames(5)
	check(p.seat.seated(), "still sat")
	# The crouch key pressed while sat does nothing, and leaves nothing for when you stand (the
	# playtest stood up into a crawl).
	Input.action_press(&"crouch_toggle")
	await physics_frames(2)
	Input.action_release(&"crouch_toggle")
	await physics_frames(5)
	p.seat.let_go(&"act")
	p.seat.use()
	await physics_frames(20)
	check(not p.seat.seated(), "let go, E stands you")
	check(not p.is_crawling and not p.is_crouching, "on your feet, not crawling (crouching %s, crawling %s)" % [p.is_crouching, p.is_crawling])


func test_a_man_out_of_his_chair_stops_the_hand() -> void:
	await _night()
	var g := _game()
	await wait_until(func() -> bool: return g.state in [&"bet", &"draw", &"deal"], 60 * 30)
	var earl: HumanBody = valley.folk.people[&"earl"]
	var chore: SitChore = null
	for c: RefCounted in (earl.get_node(^"Brain") as CivilianBrain).chores:
		if c is SitChore:
			chore = c
	# Up out of his chair (as he'd be sent off, or getting up to go).
	chore.wanted = false
	await physics_frames(3)
	check_eq(g.state, &"stopped", "Earl up: the hand's over")
	check_eq(g.stop_reason, &"up", "because a man's out of his chair")
	# His chore sits him back down; dealt again.
	chore.wanted = true
	var sat := await wait_until(func() -> bool: return _chair("w").seated == earl, 60 * 10)
	check(sat, "Earl sat back down")
	g.resume()
	check(g.state != &"stopped", "dealt again")


func test_a_shot_stops_the_game_and_it_deals_again() -> void:
	await _night()
	var g := _game()
	var going := await wait_until(func() -> bool: return g.state in [&"bet", &"draw", &"deal"], 60 * 30)
	check(going, "a hand going (%s)" % g.state)
	var why: Array = []
	g.interrupted.connect(func(r: StringName) -> void: why.append(r), CONNECT_ONE_SHOT)
	var cards: int = g.report().cards_on_table
	Events.shot_fired.emit(g.centre() + Vector3(8, 1, 0), Vector3.LEFT, null)
	await physics_frames(2)
	check_eq(g.state, &"stopped", "a shot near stops it")
	check_eq(why, [&"shot"], "and says why")
	check_eq(g.report().cards_on_table, cards, "the cards left where they lie")
	await physics_frames(30)
	check_eq(g.state, &"stopped", "and it stays stopped a while")
	# An act's hold keeps it stopped however calm it gets.
	g.interrupt(&"red_shirt", true)
	g._calm = 999.0
	await physics_frames(5)
	check_eq(g.state, &"stopped", "held by an act")
	g.let_go(&"red_shirt")
	# The shot had the men up out of their chairs (townsfolk: trouble); calm, they sit back down
	# and the cards go round again.
	var again := await wait_until(func() -> bool: return g.state != &"stopped", 60 * 120)
	check(again, "let go, it deals again once they're sat (%s; holds %s, sat %d)" % [g.state, g.holds, g.sat().size()])


func test_the_chair_kicked_out_from_under_you() -> void:
	await _night()
	var p := _player()
	await _behind("s")
	check(p.seat.use() == &"sat", "sat in the south chair")
	await physics_frames(10)
	var dumped: Array = []
	p.seat.dumped.connect(func(c: KitProp) -> void: dumped.append(c), CONNECT_ONE_SHOT)
	# A boot into its back legs (as a kick does, #204): the chair goes from under you.
	var ch := _chair("s")
	ch.go_loose(Vector3.ZERO, -ch.global_basis.z * 60.0)
	await physics_frames(3)
	check_eq(dumped.size(), 1, "the seat told you")
	check(not p.seat.seated(), "you're not in it")
	check(p.is_crawling, "down on the floor")
	check(p.seat.down_t > 0.0, "and still a moment")
	await physics_frames(20)
	check(p.get_eye_height() < 0.8, "eyes down by the floor (%.2f)" % p.get_eye_height())
	# Pressing on doesn't crawl you anywhere till you've come to: your own speed stays nil (where you
	# lie the chair's pieces may shift under you: that's theirs, not a crawl).
	var most := 0.0
	Input.action_press(&"move_forward")
	for i in 15:
		await physics_frames(1)
		most = maxf(most, Vector2(p.velocity.x, p.velocity.z).length())
	Input.action_release(&"move_forward")
	check(most < 0.05, "not crawling off yet (your speed at most %.3f m/s)" % most)
	check(p.seat.down_t > 0.0, "still down")
	await wait_until(func() -> bool: return p.seat.down_t <= 0.0, 120)
	var at := p.global_position
	Input.action_press(&"move_forward")
	await physics_frames(45)
	Input.action_release(&"move_forward")
	check(p.global_position.distance_to(at) > 0.08, "then you can crawl off (%.3f m)" % p.global_position.distance_to(at))


func test_his_chair_broken_he_takes_a_free_one() -> void:
	await _night()
	var p := _player()
	if p.seat.seated():
		p.seat.stand()
		await physics_frames(3)
	var earl: HumanBody = valley.folk.people[&"earl"]
	var ch := _chair("w")
	check(ch.seated == earl, "Earl in the west chair")
	ch.go_loose(Vector3.ZERO, ch.global_basis.z * -80.0)
	# Down with it, up again, and into the free north chair (the south one's broken above).
	var brain := earl.get_node(^"Brain") as CivilianBrain
	var tl: Array = []
	var on_hit := func(info: Dictionary) -> void:
		tl.append("blow %s %.0fJ %s" % [info.get("segment", "?"), float(info.get("joules", 0.0)), info.get("harm", [])])
	earl.hit.connect(on_hit)
	var last := ""
	var sat := false
	for k in 60 * 90:
		await physics_frames(1)
		var st := "limp %s rising %s pose %s mood %d ok %s" % [earl.limp, earl.rising, earl.pose, brain.mood, earl.rise_ok]
		if st != last:
			last = st
			tl.append("%d %s fear %.2f at %s" % [k, st, brain.fear, earl.global_position.snappedf(0.01)])
		if _chair("n").seated == earl:
			sat = true
			break
	earl.hit.disconnect(on_hit)
	var chore_chair := ""
	for c: RefCounted in brain.chores:
		if c is SitChore:
			chore_chair = "%s wanted %s" % [(c as SitChore).chair.name if (c as SitChore).chair and is_instance_valid((c as SitChore).chair) else "none", (c as SitChore).wanted]
	check(sat, "Earl sat in the free north chair within 90 s (at %s, limp %s; '%s' can_stand %s conscious %s shock %.2f down_t %.1f still_t %.1f; n.seated %s n.loose %s; chore %s; player %s; timeline %s)" % [earl.global_position, earl.limp,
			earl.physiology.describe(), earl.physiology.can_stand(), earl.physiology.is_conscious(), earl.physiology.shock(), earl._down_t, earl._still_t, _chair("n").seated, _chair("n").loose, chore_chair, p.global_position.snappedf(0.01), tl.slice(0, 60)])
