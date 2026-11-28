extends TestCase
## The real card game (#1294; CardGame, Poker, PlayingCards, PlayerCards, config/card_game.json): the
## draw's rule (three, four keeping an ace), the men's honest odds (Poker.equity: only their own cards)
## and their bets by their odds and nature (seeded), a whole hand played from your chair with your own
## raise and your own draw, your cards face down till the showdown and in your hand when lifted, the
## tells, and the table's cost with four men at it.

var holder: Node
var valley: ValleyWorld


## A card: rank 0 the two .. 12 the ace; suit 0 spades, 1 hearts, 2 diamonds, 3 clubs.
func _c(r: int, s: int) -> int:
	return s * 13 + r


func test_the_draw_rule() -> void:
	var ace_junk := [_c(12, 0), _c(7, 1), _c(5, 2), _c(3, 3), _c(1, 0)]
	var king_junk := [_c(11, 0), _c(7, 1), _c(5, 2), _c(3, 3), _c(1, 0)]
	check(Poker.can_throw(ace_junk, [1, 2, 3]), "three, any three")
	check(Poker.can_throw(ace_junk, [1, 2, 3, 4]), "four, keeping the ace")
	check(not Poker.can_throw(ace_junk, [0, 2, 3, 4]), "not four throwing the ace")
	check(not Poker.can_throw(king_junk, [1, 2, 3, 4]), "not four keeping a king")
	check(not Poker.can_throw(ace_junk, [0, 1, 2, 3, 4]), "never five")
	check(not Poker.can_throw(ace_junk, [1, 1]), "a card once")
	check(not Poker.can_throw(ace_junk, [1, 2, 3, 4], 3, false), "four only where the house allows it")
	check(Poker.can_throw(ace_junk, []), "standing pat")
	check_eq(Poker.discards(ace_junk, true), [1, 2, 3, 4], "a man with an ace and nothing draws four to it")
	check_eq(Poker.discards(ace_junk, false).size(), 3, "three where the house doesn't")
	check_eq(Poker.discards(king_junk, true).size(), 3, "a king alone isn't an ace")


func test_honest_odds_from_his_own_cards() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1294
	var aces := [_c(12, 0), _c(12, 1), _c(7, 2), _c(4, 3), _c(1, 0)]
	var trips := [_c(10, 0), _c(10, 1), _c(10, 2), _c(4, 3), _c(1, 0)]
	var junk := [_c(0, 0), _c(2, 1), _c(5, 2), _c(7, 3), _c(9, 0)]
	var royal := [_c(8, 1), _c(9, 1), _c(10, 1), _c(11, 1), _c(12, 1)]
	var e_aces := Poker.equity(aces, 1, rng, 400)
	var e_trips := Poker.equity(trips, 1, rng, 400)
	var e_junk := Poker.equity(junk, 1, rng, 400)
	check(e_aces > 0.6, "a pair of aces beats one man more often than not (%.2f)" % e_aces)
	check(e_trips > e_aces, "three queens better still (%.2f)" % e_trips)
	check(e_junk < 0.45, "a jack-high nothing less than even (%.2f)" % e_junk)
	check(Poker.equity(royal, 3, rng, 100, false) > 0.99, "a royal flush, drawn, wins")
	check(Poker.equity(aces, 3, rng, 400) < e_aces, "against three it's worth less than against one")
	# The same seed, the same odds: nothing he can't see (the others' cards) goes in.
	var a := RandomNumberGenerator.new()
	a.seed = 7
	var b := RandomNumberGenerator.new()
	b.seed = 7
	check_eq(Poker.equity(aces, 2, a, 50), Poker.equity(aces, 2, b, 50), "seeded: the same deals")
	check(Poker.unseen(aces).size() == 47 and not Poker.unseen(aces).has(aces[0]), "he deals from the 47 he can't see")


## What `nature` does in `n` tries with `share` against one man, `to_call` into `pot`.
func _moves(nature: Dictionary, share: float, to_call: int, pot: int, n := 400) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1294
	var out := {}
	for i in n:
		var d := CardGame.decide(nature, share, 1, to_call, pot, true, 4, rng)
		out[d.move] = int(out.get(d.move, 0)) + 1
		check(int(d.n) >= 0 and int(d.n) <= 4, "within the limit")
		out["size"] = int(out.get("size", 0)) + int(d.n)
		if bool(d.bluff):
			out["bluff"] = int(out.get("bluff", 0)) + 1
	return out


func test_the_men_bet_by_their_hands_and_natures() -> void:
	var data: Dictionary = CardGame.data_file()
	var nat: Dictionary = data.natures
	var careful: Dictionary = nat.careful
	var reckless: Dictionary = nat.reckless
	var bluffer: Dictionary = nat.bluffer
	# Strong: they bet it. Weak: the careful man checks.
	var strong := _moves(careful, 0.85, 0, 4)
	var weak := _moves(careful, 0.3, 0, 4)
	check(int(strong.get("bet", 0)) > 250, "a careful man bets a strong hand (%s)" % strong)
	check(int(weak.get("bet", 0)) < 30, "and checks a weak one (%s)" % weak)
	# Facing a bet on a weak hand: careful folds, reckless stays in more.
	var c_weak := _moves(careful, 0.2, 2, 4)
	var r_weak := _moves(reckless, 0.2, 2, 4)
	check(int(c_weak.get("fold", 0)) > int(r_weak.get("fold", 0)) + 60, "the careful man folds more to a bet (%s vs %s)" % [c_weak, r_weak])
	# A bluffer bets nothing far more often than a careful man.
	var b_bluff := _moves(bluffer, 0.25, 0, 4)
	var c_bluff := _moves(careful, 0.25, 0, 4)
	check(int(b_bluff.get("bluff", 0)) > int(c_bluff.get("bluff", 0)) * 4 and int(b_bluff.get("bluff", 0)) > 60,
			"the bluffer bluffs (%s vs %s)" % [b_bluff, c_bluff])
	# The stronger, the bigger: a monster bets more a time than a fair-plus hand.
	var big := _moves(reckless, 0.95, 0, 4)
	var mid := _moves(reckless, 0.6, 0, 4)
	check(float(big.size) / maxf(big.get("bet", 1), 1) > float(mid.size) / maxf(mid.get("bet", 1), 1),
			"stronger bets bigger (%s vs %s)" % [big, mid])
	# Priced in: a cheap call on a fair hand is called; the same hand folds to a big price, careful.
	check(int(_moves(careful, 0.45, 1, 10).get("call", 0)) > 350, "a cheap call is called")
	check(int(_moves(careful, 0.3, 4, 2).get("fold", 0)) > 300, "a dear one on a poor hand is folded")


# --- At the table ------------------------------------------------------------------------------------

func _valley() -> void:
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


## Nine at night, everyone in, the game sped up, you sat at the south chair.
func _sat(speed := 4.0) -> void:
	await _valley()
	var clock := valley.get_node(^"DayCycle") as DayCycle
	if clock.time_of_day < 20.0:
		clock.set_time(21.0)
		await physics_frames(1)
		valley.folk._look = 0.0
		await physics_frames(60)
	_game().speed = speed
	var p := _player()
	if p.seat.seated():
		return
	var ch := valley.folk.props["chair_s"] as KitProp
	p.global_position = Seating.spot(ch) - ch.global_basis.z * 0.5
	p.velocity = Vector3.ZERO
	var to := ch.global_basis.z
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(2)
	p.seat.use()
	await physics_frames(30)


func test_a_hand_played_from_your_chair() -> void:
	await _sat()
	var g := _game()
	var p := _player()
	check(p.seat.seated(), "sat at the table")
	var dealt := await wait_until(func() -> bool: return g.you_in() and g.your_cards().size() == 5 and g.state == &"bet", 60 * 60)
	check(dealt, "dealt in (%s)" % g.report())
	# Your cards lie face down: on the table, not turned up.
	var yours := g._cards.filter(func(c: Dictionary) -> bool: return c.get("owner", "") == CardGame.YOU)
	check(yours.size() == 5 and yours.all(func(c: Dictionary) -> bool: return not c.up), "your five lie face down")
	# Lifted: in your hand, first person, the faces yours.
	p.cards.force_lift = true
	await physics_frames(40)
	check(g.lifted, "lifted off the table")
	var held := p.camera.get_node_or_null(^"CardHold") as Node3D
	check(held != null and held.visible, "in your hand, before you")
	check(g._card_mm.multimesh.instance_count < 5 * g.seats.size() + 12, "not on the table while you hold them")
	p.cards.force_lift = false
	# Your bet: raise by two (the limit's within reach); else, if the raises are spent, call.
	var turned := await wait_until(func() -> bool: return g.your_turn() or g.state == &"showdown", 60 * 60)
	check(turned and g.your_turn(), "your turn comes (%s)" % g.report())
	var chips := 0
	for s: Dictionary in g.report().seats:
		chips += int(s.stack)
	chips += g.pot
	var bet_before := g._round_bet
	if not g.you_raise(2):
		g.you_call()
	else:
		check_eq(g._round_bet, bet_before + 2, "your raise added two")
		check_eq(g.last_move.get(CardGame.YOU), "raise", "you raised")
	# Your draw: the hand lifts itself; throw the two lowest cards you hold.
	var drawing := await wait_until(func() -> bool: return g.you_drawing or not g.you_in() or g.state == &"showdown", 60 * 60)
	if g.you_in() and g.you_drawing:
		await physics_frames(20)
		check(held.visible, "your draw brings them up")
		var before := g.your_cards()
		var order := [0, 1, 2, 3, 4]
		order.sort_custom(func(a: int, b: int) -> bool: return Poker.rank(before[a]) < Poker.rank(before[b]))
		check(g.you_mark(order[0]) and g.you_mark(order[1]), "two marked")
		check(not g.you_draw([0, 1, 2, 3, 4]), "five's refused")
		check(g.you_drawing, "and you choose again")
		check(g.you_draw(), "the two drawn")
		var after := g.your_cards()
		var kept := 0
		for i in 5:
			if before[i] == after[i]:
				kept += 1
		check_eq(kept, 3, "three kept, two new (%s -> %s)" % [before, after])
		check(after[order[0]] != before[order[0]] and after[order[1]] != before[order[1]], "the two you marked")
		check_eq(g.last_move.get(CardGame.YOU), "draw 2", "you drew two")
	else:
		check(drawing, "out before the draw (%s)" % g.report())
	# Played out: a man's odds were his own (each has his share), the pot goes, no chip made or lost.
	var start := g.hands
	while g.you_in() and g.hands == start and g.state != &"stopped":
		if g.your_turn():
			g.you_call()
		await physics_frames(1)
	var done := await wait_until(func() -> bool: return g.hands > start, 60 * 60)
	check(done, "the hand played out (%s)" % g.report())
	var r := g.report()
	var now := 0
	for s: Dictionary in r.seats:
		now += int(s.stack)
		if s.id != CardGame.YOU:
			check(float(s.odds) >= 0.0 and String(s.nature) != "", "%s bet by his odds and nature (%s)" % [s.id, s])
	check_eq(now + int(r.pot), chips, "no chip made or lost")
	# Shown down (you in to the end and someone else too): your cards turned up for all.
	if g.you_in() and g._in_hand().size() > 1:
		yours = g._cards.filter(func(c: Dictionary) -> bool: return c.get("owner", "") == CardGame.YOU)
		check(yours.all(func(c: Dictionary) -> bool: return c.up), "shown at the showdown")


func test_the_tells() -> void:
	await _sat()
	var g := _game()
	var ok := await wait_until(func() -> bool: return g.state == &"bet" and g._in_hand().any(func(s: Dictionary) -> bool: return s.id == "drifter" and s.in), 60 * 90)
	check(ok, "the drifter in a hand (%s)" % g.report())
	if not ok:
		return
	var s := g._seat("drifter")
	check_eq(g.nature_of("drifter").tell, "chips", "the drifter's tell is his chips")
	# Strong: his hand goes to his chips when another's acting.
	g.odds["drifter"] = {"share": 0.95, "opp": 1, "round": g.betting_round}
	var before := g.tells_shown
	var turn := g._turn
	g._turn = -1  # (another man's turn: a man shows his tell while he waits, not on his own)
	for i in 20:
		g._tell_at.erase("drifter")
		g._tell(s)
	check(g.tells_shown > before, "strong, he touches his chips (%d)" % (g.tells_shown - before))
	check(g._reach.has("drifterl"), "his left hand to them")
	# Weak: never.
	g.odds["drifter"] = {"share": 0.1, "opp": 1, "round": g.betting_round}
	before = g.tells_shown
	for i in 20:
		g._tell_at.erase("drifter")
		g._tell(s)
	g._turn = turn
	check_eq(g.tells_shown, before, "weak, his hands stay still")
	check_eq(g.nature_of("earl").name, "bluffer", "Earl bluffs")
	check_eq(g.nature_of("earl").tell, "stare", "and stares you down when he does")


## Four men at the table (Earl, the drifter and two more sat in the free chairs), the game at its own
## pace: its cost a frame (Prof `card_game`, the men's odds included) inside a small share of the
## people's budget, and its frames under 1 ms (the 99th) (what a man says is timed apart, `card_say`: its
## listeners are the faces', subtitles' and news's, as anywhere a man speaks).
func test_four_men_at_the_table_within_the_budget() -> void:
	await _valley()
	var clock := valley.get_node(^"DayCycle") as DayCycle
	if clock.time_of_day < 20.0:
		clock.set_time(21.0)
		await physics_frames(1)
		valley.folk._look = 0.0
		await physics_frames(60)
	var g := _game()
	var p := _player()
	if p.seat.seated():
		p.seat.use()
		await physics_frames(10)
	var men: Array[HumanBody] = []
	for c: KitProp in g.chairs:
		if c.seated == null:
			var man := HumanBody.new()
			man.person_id = &"guest_%d" % men.size()
			valley.add_child(man)
			man.global_position = Seating.spot(c) - c.global_basis.z * 0.4
			men.append(man)
			var sat := false
			for i in 400:
				sat = Seating.sit_step(man, c, 1.0 / 60.0)
				if sat:
					break
				await physics_frames(1)
	var ok := await wait_until(func() -> bool: return g.sat().size() == 4 and g.seats.size() == 4 and g.state == &"bet", 60 * 60)
	check(ok, "four men in a hand (%s; chairs %s)" % [g.report(), g.chairs.map(func(c: KitProp) -> String: return str(c.seated.name) if c.seated else "-")])
	g.speed = 1.0
	var fb: FrameBudget = load("res://config/frame_budget.tres")
	Prof.on = true
	# The same four sat, the game held still: the people's part without the play.
	g.interrupt(&"bench", true)
	_people_at = Prof._sum.duplicate()
	_people_frames = 0
	for i in 300:
		_people_frames += 1
		await physics_frames(1)
	var still := _people_ms(fb)
	g.let_go(&"bench")
	g.resume()
	ok = await wait_until(func() -> bool: return g.seats.size() == 4 and g.state == &"bet", 60 * 30)
	check(ok, "dealt again, four in")
	var worst := 0.0
	var total := 0.0
	var frames := 600
	var each: Array[float] = []
	var was := int(Prof._sum.get(&"card_game", 0)) - int(Prof._sum.get(&"card_say", 0))
	_people_at = Prof._sum.duplicate()
	_people_frames = 0
	for i in frames:
		_people_frames += 1
		await physics_frames(1)
		var now := int(Prof._sum.get(&"card_game", 0)) - int(Prof._sum.get(&"card_say", 0))
		worst = maxf(worst, float(now - was) / 1000.0)
		each.append(float(now - was) / 1000.0)
		total += float(now - was) / 1000.0
		was = now
	var people := _people_ms(fb)
	Prof.on = false
	var per := total / frames * fb.clock_scale
	each.sort()
	var p99 := each[int(frames * 0.99)] * fb.clock_scale
	print("    card_game with four men: %.3f ms a frame, 99th %.3f, worst %.3f ms (Sean's core), hands %d; people %.2f ms playing, %.2f held still (this workspace's core, scaled by clock_scale)" % [
			per, p99, worst * fb.clock_scale, g.hands, people, still])
	check(per <= 0.25, "the game a frame within a sixteenth of the people's 4 ms (%.3f ms)" % per)
	# (One frame in a hundred may be the machine's: a wall clock on a shared core.)
	check(p99 <= 1.0, "the game's frames under 1 ms, its odds spread out (99th %.3f ms, worst %.3f)" % [p99, worst * fb.clock_scale])
	check(people - still <= 0.5, "four men playing add at most 0.5 ms to the people's part (%.2f -> %.2f)" % [still, people])
	for m in men:
		m.queue_free()


var _people_at := {}
var _people_frames := 0


## The people's part a frame since `_people_at` (Sean's core): its timers summed (FrameBudget.parts).
func _people_ms(fb: FrameBudget) -> float:
	var us := 0
	for k: StringName in fb.parts.people:
		us += int(Prof._sum.get(k, 0)) - int(_people_at.get(k, 0))
	return float(us) / 1000.0 / maxf(_people_frames, 1) * fb.clock_scale
