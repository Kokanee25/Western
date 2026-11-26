extends TestCase
## Every verb at the card table gets an answer (#1279, DESIGN §2 pillar 6; CardGame.you_did, ValleyFolk.
## _on_table_deed, TownRegard, TownNews.table): sitting down, raising, calling, folding, a pot won or lost,
## a bluff shown up, a cheat called true or false and getting up each get a line from the table at once
## in words that match what they saw, move the table's regard, and the bigger ones are news told later.
## The table starts things too: a man asks you to sit if you stand watching, and needles you after a big pot.

var holder: Node
var valley: ValleyWorld
var said: Array = []  # [who, text]
var did: Array = []  # [verb, info]


func before_each() -> void:
	ValleyFolk.murder_auto = false  # No Law's murder (#773) has its own tests
	said.clear()
	did.clear()
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	_game().you_did.connect(func(verb: StringName, info: Dictionary) -> void: did.append([verb, info]))


func after_each() -> void:
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)


func _on_spoke(who: Node, text: String) -> void:
	said.append([who, text])


func _game() -> CardGame:
	return valley.folk.cards


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _lines(kind: String, who: Node = null) -> Array:
	var g := _game()
	return g._lines(who as Node3D, kind) if who != null else (g.data.lines as Dictionary).get(kind, [])


## Said since `from` (an index into `said`), by anyone, a line of `kind` (its own or the table's).
func _said_kind(kind: String, from := 0) -> Array:
	var out := []
	for i in range(from, said.size()):
		var who: Node = said[i][0]
		var text: String = said[i][1]
		for l: String in _lines(kind, who) + _lines(kind):
			var stem := l.split("{")[0]
			if (stem != "" and text.begins_with(stem)) or (stem == "" and text.ends_with(l.split("}")[-1])):
				out.append(said[i])
				break
	return out


func _did(verb: StringName) -> Dictionary:
	for d: Array in did:
		if d[0] == verb:
			return d[1]
	return {}


## Nine at night, everyone in, the game at four times its pace, you sat at the south chair.
func _sat() -> void:
	var clock := valley.get_node(^"DayCycle") as DayCycle
	if clock.time_of_day < 20.0:
		clock.set_time(21.0)
		await physics_frames(1)
		valley.folk._look = 0.0
		await physics_frames(60)
	_game().speed = 4.0
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


func _man(id: StringName) -> HumanBody:
	return valley.folk.folk_man(id)


func _deeds(id: StringName) -> Dictionary:
	return valley.folk.regard.deeds.get(id, {})


func test_sat_down_greeted_and_kept_raise_answered_up_and_off_said_after() -> void:
	await _sat()
	var g := _game()
	var p := _player()
	check(p.seat.seated(), "sat at the table")
	check(not _said_kind("greet").is_empty(), "greeted as you sit (%s)" % [said])
	check(not _did(&"sit").is_empty(), "the table knows you sat")
	var men: Array = _did(&"sit").get("men", [])
	check(men.size() >= 2, "Earl and the drifter at the table (%d)" % men.size())
	for m: HumanBody in men:
		check(_deeds(m.person_id).has("sit"), "%s keeps your sitting down (%s)" % [m.person_id, _deeds(m.person_id)])
	# Your turn: fire raises (the input's own path, `you_raise`), and the next man answers it at once.
	var turn := await wait_until(func() -> bool: return g._you_turn, 60 * 90)
	check(turn, "your turn comes (%s)" % g.report())
	if turn:
		var before := g._round_bet
		var from := said.size()
		var ok := g.you_raise()
		check(ok, "you raise")
		check(g._round_bet > before, "the bet's up (%d -> %d)" % [before, g._round_bet])
		check(not _said_kind("you_raise", from).is_empty(), "the table answers your raise in its words (%s)" % [said.slice(from)])
		check(not _did(&"raise").is_empty(), "the raise is a deed the town keeps")
	# Up and off: a word after you.
	var from2 := said.size()
	p.seat.use()
	await physics_frames(10)
	check(not p.seat.seated(), "E stood you up")
	check(not (_said_kind("you_up", from2) + _said_kind("you_up_ahead", from2)).is_empty(), "a word as you go (%s)" % [said.slice(from2)])
	check(not _did(&"up").is_empty(), "getting up is a deed too")


## A raise on nothing shown down is a bluff called, in its own words, not an ordinary loss; a pot won is
## answered and told later; a big one brings a needle the next hand.
func test_a_bluff_shown_up_is_not_a_pot_lost_and_a_won_pot_is_told() -> void:
	await _sat()
	var g := _game()
	var dealt := await wait_until(func() -> bool: return g.you_in() and (g._seat(CardGame.YOU).cards as Array).size() == 5, 60 * 60)
	check(dealt, "dealt in (%s)" % g.report())
	if not dealt:
		return
	# Your hand nothing, a man's three of a kind; you raised on it, and it's shown down.
	var you := g._seat(CardGame.YOU)
	var other: Dictionary = g.seats.filter(func(s: Dictionary) -> bool: return s.id != CardGame.YOU)[0]
	for s: Dictionary in g.seats:
		s.in = s == you or s == other
	you.cards = [_c(2, 0), _c(5, 1), _c(7, 2), _c(9, 3), _c(11, 0)]
	other.cards = [_c(13, 0), _c(13, 1), _c(13, 2), _c(4, 3), _c(6, 0)]
	g._you_bluffing = true
	var from := said.size()
	g._showdown()
	check(not _said_kind("bluff_called", from).is_empty(), "your bluff shown up, said so (%s)" % [said.slice(from)])
	check(_said_kind("you_win", from).is_empty() and _said_kind("you_lose", from).is_empty(), "not a pot won, nor an ordinary loss")
	var info := _did(&"bluff_called")
	check(not info.is_empty() and _did(&"lost_pot").is_empty(), "a bluff called, the deed (%s)" % [did.map(func(d: Array) -> StringName: return d[0])])
	check(_deeds(other.who.person_id).has("bluff_called"), "the man who called it keeps it (%s)" % _deeds(other.who.person_id))
	# The same hand without the bluff: an ordinary loss.
	did.clear()
	g._you_bluffing = false
	for s: Dictionary in g.seats:
		s.in = s == you or s == other
	from = said.size()
	g._clock += 700.0  # (the table's own lines not said again within same_line_s)
	g._showdown()
	check(not _said_kind("you_lose", from).is_empty(), "a hand lost fair, said so (%s)" % [said.slice(from)])
	check(not _did(&"lost_pot").is_empty(), "a pot lost, the deed")
	# Yours the best: a pot won, answered, news for later, a needle next hand.
	did.clear()
	for s: Dictionary in g.seats:
		s.in = s == you or s == other
	you.cards = [_c(14, 0), _c(14, 1), _c(14, 2), _c(14, 3), _c(3, 0)]
	g.pot = 12
	from = said.size()
	g._clock += 700.0
	g._showdown()
	check(not _said_kind("you_win", from).is_empty(), "your pot answered (%s)" % [said.slice(from)])
	check(not _did(&"won_pot").is_empty(), "a pot won, the deed")
	var news := valley.folk.news
	var rec := news.records.filter(func(r: Dictionary) -> bool: return StringName(r.get("cards", &"")) == &"won_pot")
	check(not rec.is_empty(), "the pot is news (%s)" % [news.records.map(func(r: Dictionary) -> String: return String(r.what))])
	if not rec.is_empty():
		var rid := int(rec[-1].id)
		var pid: StringName = other.who.person_id
		var line := news.line_of(pid, rid, TownNews.HARLAN)
		check(line.to_lower().contains("pot") or line.to_lower().contains("clean"), "told to your face later, of the pot: \"%s\"" % line)
		check(news._too_soon(rid), "not told in the same breath")
	check(g._needle, "a big pot: the next hand needles you")
	from = said.size()
	g._start_hand()
	check(not _said_kind("needle", from).is_empty() or not g.you_in(), "the needle said as the next hand starts (%s)" % [said.slice(from)])


## A cheat called on Earl: true when he dealt himself from the bottom this hand or the last (caught, the
## drifter with you; respected), else a lie on an honest man (he takes it hard, the table cold). A shout
## sat at the table, facing him, is the call.
func test_a_cheat_called_true_and_false() -> void:
	await _sat()
	var g := _game()
	var earl := _man(&"earl")
	check(earl != null and g._men().has(earl), "Earl at the table")
	if earl == null:
		return
	# True: he's just dealt himself from the bottom. The shout, facing him.
	g._cheat_hand = g.hands
	var p := _player()
	var to := earl.global_position + Vector3.UP * 1.1 - p.camera.global_position
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(2)
	var from := said.size()
	Events.shouted.emit(p, &"cheat")
	await physics_frames(2)
	check(not _said_kind("caught", from).is_empty(), "Earl caught, says so (%s)" % [said.slice(from)])
	check(not _said_kind("cheat_seen", from).is_empty(), "the other man saw it too")
	check(not _did(&"cheat_true").is_empty(), "a cheat called true")
	check(g.state == &"stopped", "the hand stops (%s)" % g.state)
	check(_deeds(&"earl").has("caught_him"), "Earl's own regard: caught (%s)" % _deeds(&"earl"))
	check(not _deeds(&"earl").has("cheat_true"), "not the table's")
	var news := valley.folk.news
	var rec := news.records.filter(func(r: Dictionary) -> bool: return StringName(r.get("cards", &"")) == &"cheat_true")
	check(not rec.is_empty() and rec[-1].whom == &"earl", "news: you caught Earl")
	# False: a clean hand, later.
	did.clear()
	g._cheat_hand = -1
	g._clock += 60.0
	from = said.size()
	check_eq(g.accuse(earl), &"cheat_false", "a cheat called on a clean hand")
	check(not _said_kind("accused", from).is_empty(), "Earl takes it hard (%s)" % [said.slice(from)])
	check(not _said_kind("accused_seen", from).is_empty(), "and the table with him")
	check(_deeds(&"earl").has("accused_him"), "Earl's own regard: wrongly accused")
	# Not again at once.
	check_eq(g.accuse(earl), &"", "not called twice in a breath")


## Stood by the table watching, a chair free and a game on: a man asks you to sit.
func test_stood_watching_a_man_asks_you_to_sit() -> void:
	await _sat()
	var g := _game()
	var p := _player()
	p.seat.use()
	await physics_frames(10)
	var at := g.centre() + Vector3(0.0, 0.0, 1.8)
	at.y = p.global_position.y
	p.global_position = at
	p.velocity = Vector3.ZERO
	g._invited_at = -INF
	var from := said.size()
	var asked := await wait_until(func() -> bool: return not _said_kind("invite", from).is_empty(), 60 * 30)
	check(asked, "asked to sit within 30 s of standing there (%s, %s)" % [g.state, said.slice(from)])


## A card: face value 2..14 (the ace), suit 0..3 (Poker: rank `c % 13`, suit `c / 13`).
func _c(v: int, s: int) -> int:
	return s * 13 + (v - 2)
