class_name CardGame
extends Node3D
## The card game at a kit card table (#766, No Law step 2; data config/card_game.json; rules Poker):
## five-card draw among whoever is sat at the table, the player dealt in from the hand after he sits
## in a free chair there (PlayerSeat). A scene, not a minigame: the men shuffle, ante, deal, bet,
## draw and show by the data's rules, a line now and then (Events.spoke: their mouths, subtitles),
## their hands to the deck and the pot (HumanBody.reach_to), their eyes on the table; the cards
## and chips lie on the table (stand-ins: boxes and discs, the faces as text). On your turn a nod
## calls or checks and a shake folds (HeadGesture), and waited on you check, or fold to a bet.
##
## It runs till something stops it: a shot or a blast near, a man in the hand out of his chair
## (kicked, up and running), or an act's `interrupt` (No Law's next step: the red shirt walks up).
## Stopped, the cards stay where they lie and the pot rides; it deals again once it's been calm
## `resume_after_s` with two or more sat, unless an act `hold`s it.

signal interrupted(reason: StringName)
signal hand_done(winner: String, pot: int, hand: String)

const DATA := "res://config/card_game.json"
const YOU := "you"
const CARD_SIZE := Vector3(0.063, 0.0012, 0.088)
const CHIP_R := 0.019
const CHIP_H := 0.0035
const CHIP_COLOURS := [Color(0.62, 0.12, 0.1), Color(0.86, 0.84, 0.78), Color(0.14, 0.2, 0.45)]
const BACK := Color(0.42, 0.1, 0.08)
const FACE := Color(0.93, 0.91, 0.85)
const STACK_MAX := 20
## Past this (m) the cards and chips aren't drawn.
const SEEN_FROM := 40.0

var data: Dictionary
var table: KitProp
## The chairs round the table in the order the cards go round.
var chairs: Array[KitProp] = []
var rng := RandomNumberGenerator.new()
## Game seconds a second (tests, the bench).
var speed := 1.0
## &"idle" (not two sat), &"shuffle", &"ante", &"deal", &"bet", &"draw", &"showdown", &"between",
## &"stopped".
var state := &"idle"
var stop_reason := &""
## Whoever's keeping it stopped (an act): reason -> true.
var holds := {}
var hands := 0
var wins := {}
var cheated := 0
var stacks := {}
## This hand's players, in the order the cards go: {id, who, chair, cards, in, put, cards_at}.
var seats: Array[Dictionary] = []
var deck: Array[int] = []
var pot := 0
var dealer_id := ""
var betting_round := 0
var last_winner := ""
var last_hand := ""
## What each did last: id -> "check", "bet", "call", "raise", "fold", "draw 2"...
var last_move := {}

var _t := 0.0
var _calm := 0.0
var _clock := 0.0
var _turn := -1
var _round_bet := 0
var _raises := 0
var _acted := {}
var _deal_q: Array = []
var _draw_i := -1
var _said := {}
var _gesture := HeadGesture.new()
var _you_turn := false
var _you_told := false
var _reach := {}  # id -> [side, point, until]
var _you_seated := false
var _broke_told := false
var _mucked := 0

# What's drawn: every card on the table, the chips, the flights.
var _cards: Array[Dictionary] = []  # {c, from, to, t, up, label}
var _chip_flights: Array[Dictionary] = []  # {from, to, t, colour}
var _pot_flying := 0
var _card_mm: MultiMeshInstance3D
var _chip_mm: MultiMeshInstance3D
var _dirty := true
var _letters := false
var _centre := Vector3.ZERO
var _centre_at := -1.0
var _top := -1.0


func _init() -> void:
	name = "CardGame"


func _ready() -> void:
	add_to_group(&"card_game")
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	_letters = not ThemeDB.fallback_font.has_char(0x2665)
	_card_mm = _multimesh("Cards", _box_mesh())
	_chip_mm = _multimesh("Chips", _chip_mesh())
	Events.shot_fired.connect(_on_shot)
	Events.exploded.connect(_on_blast)


func _exit_tree() -> void:
	if Events.shot_fired.is_connected(_on_shot):
		Events.shot_fired.disconnect(_on_shot)
	if Events.exploded.is_connected(_on_blast):
		Events.exploded.disconnect(_on_blast)


func _beat(k: String) -> float:
	return float((data.get("beats", {}) as Dictionary).get(k, 1.0))


func _play(k: String) -> float:
	return float((data.get("play", {}) as Dictionary).get(k, 0.5))


func _place(k: String) -> float:
	return float((data.get("place", {}) as Dictionary).get(k, 0.3))


# --- Who's at the table --------------------------------------------------------------------------

## Who's in `chair` and fit to play: a conscious man on his feet's worth, or the player.
func _sitter(chair: KitProp) -> Node3D:
	if chair == null or not is_instance_valid(chair) or chair.loose:
		return null
	var who := chair.seated
	if who == null or not is_instance_valid(who):
		return null
	if who is HumanBody:
		var man := who as HumanBody
		return man if not man.limp and man.physiology.alive and man.physiology.is_conscious() else null
	return who if who.is_in_group(&"player") else null


static func id_of(who: Node3D) -> String:
	return String((who as HumanBody).person_id) if who is HumanBody else YOU


## Everyone sat and fit, in the chairs' order: [[chair, who], ...].
func sat() -> Array:
	var out := []
	for c in chairs:
		var who := _sitter(c)
		if who != null:
			out.append([c, who])
	return out


func _seat(id: String) -> Dictionary:
	for s in seats:
		if s.id == id:
			return s
	return {}


func _in_hand() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in seats:
		if s.in:
			out.append(s)
	return out


func you_in() -> bool:
	var s := _seat(YOU)
	return not s.is_empty() and s.in


# --- Where things lie ------------------------------------------------------------------------------

## The middle of the table's top (read again every second: a kicked table moves).
func centre() -> Vector3:
	if _centre_at < 0.0 or _clock - _centre_at > 1.0 or _clock < _centre_at:
		_centre_at = _clock
		if _top < 0.0 and table:
			_top = PropKit.bounds(table.definition).end.y
		_centre = table.global_transform * Vector3(0.0, _top, 0.0) if table else global_position
	return _centre


## Flat from the table's middle toward his chair.
func _dir(chair: KitProp) -> Vector3:
	var d := chair.global_position - centre()
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD


func _card_at(chair: KitProp, slot: int, layer := 0) -> Transform3D:
	var d := _dir(chair)
	var across := d.cross(Vector3.UP)
	var at := centre() + d * _place("cards_in") + across * (float(slot) - 2.0) * _place("card_gap") + Vector3.UP * (0.0008 + layer * 0.0013)
	return Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), at)


func _deck_at() -> Transform3D:
	var s := _seat(dealer_id)
	var chair: KitProp = s.chair if not s.is_empty() else (chairs[0] if not chairs.is_empty() else null)
	var d := _dir(chair) if chair else Vector3.FORWARD
	var at := centre() + d * _place("deck_in") + d.cross(Vector3.UP) * -0.12 + Vector3.UP * 0.006
	return Transform3D(Basis(Vector3.UP, atan2(d.x, d.z) + 0.3), at)


func _muck_at(n: int) -> Transform3D:
	var at := centre() + Vector3(-0.1, 0.0008 + n * 0.0013, 0.08)
	return Transform3D(Basis(Vector3.UP, 0.7 + n * 0.37), at)


func _chips_at(chair: KitProp) -> Vector3:
	var d := _dir(chair)
	return centre() + d * _place("chips_in") + d.cross(Vector3.UP) * _place("chips_side")


func _pot_at() -> Vector3:
	var off: Array = (data.get("place", {}) as Dictionary).get("pot_off", [0.0, 0.0])
	return centre() + Vector3(float(off[0]), 0.0, float(off[1]))


# --- The game ----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if table == null or not is_instance_valid(table):
		return
	var t := Prof.start()
	var dt := delta * speed
	step(dt)
	_animate(dt)
	_act()
	Prof.stop(&"card_game", t)


## Stop the hand where it is (an act: a man walks up; `hold` too to keep it stopped).
func interrupt(reason: StringName, hold_it := false) -> void:
	if hold_it:
		holds[reason] = true
	if state == &"stopped":
		return
	stop_reason = reason
	state = &"stopped"
	_calm = 0.0
	_you_turn = false
	_reach.clear()
	interrupted.emit(reason)


func hold(reason: StringName) -> void:
	holds[reason] = true


func let_go(reason: StringName) -> void:
	holds.erase(reason)


## Deal again now (an act's, or the tests'): the old hand gathered, the pot riding.
func resume() -> void:
	holds.clear()
	if state == &"stopped" or state == &"idle":
		_clear_table()
		_start_hand()


func _on_shot(origin: Vector3, _dir_v: Vector3, _shooter: Node) -> void:
	if state not in [&"idle", &"stopped"] and table and origin.distance_to(centre()) <= float(data.stop_on.shot_m):
		interrupt(&"shot")
	_calm = 0.0


func _on_blast(at: Vector3, _kg: float) -> void:
	if state not in [&"idle", &"stopped"] and table and at.distance_to(centre()) <= float(data.stop_on.blast_m):
		interrupt(&"blast")
	_calm = 0.0


func step(dt: float) -> void:
	_clock += dt
	_watch_you()
	if state == &"stopped" or state == &"idle":
		_calm += dt
		var wait := float(data.get("resume_after_s", 25.0)) if state == &"stopped" else 1.0
		if holds.is_empty() and _calm >= wait and sat().size() >= 2:
			_clear_table()
			_start_hand()
		return
	# A man of the hand gone from the world (out of town at the end of his hours): it's over, and
	# he's no longer at the table.
	if seats.any(func(x: Dictionary) -> bool: return not is_instance_valid(x.who)):
		seats = seats.filter(func(x: Dictionary) -> bool: return is_instance_valid(x.who))
		_turn = -1
		interrupt(&"up")
		return
	# A man in the hand out of his chair (kicked from under him, up and off): the hand's over. You
	# standing up only folds you.
	for s in seats:
		if s.id != YOU and s.chair.seated != s.who:
			interrupt(&"up")
			return
		if s.id == YOU and s.in and _sitter(s.chair) != s.who:
			_fold(s, false)
	_t -= dt
	match state:
		&"shuffle":
			if _t <= 0.0:
				_ante()
		&"ante":
			if _t <= 0.0:
				_begin_deal()
		&"deal":
			_deal_step()
		&"bet":
			_bet_step(dt)
		&"draw":
			_draw_step()
		&"showdown":
			if _t <= 0.0:
				state = &"between"
				_t = _beat("between_s")
		&"between":
			if _t <= 0.0:
				_clear_table()
				_start_hand()


## You sat down or got up at this table: what to tell you.
func _watch_you() -> void:
	var now := false
	for c in chairs:
		if c and is_instance_valid(c) and c.seated != null and c.seated.is_in_group(&"player"):
			now = true
	if now and not _you_seated and state not in [&"idle", &"stopped", &"between", &"shuffle"]:
		_prompt(String(data.you.next_hand), 2.5)
	_you_seated = now


func _start_hand() -> void:
	var who := sat()
	seats.clear()
	last_move.clear()
	if who.size() < 2:
		state = &"idle"
		_calm = 0.0
		return
	var ante := int(data.get("ante", 1))
	for x in who:
		var id := id_of(x[1])
		if not stacks.has(id):
			stacks[id] = int(data.stack.you if id == YOU else data.stack.men)
		if id != YOU and int(stacks[id]) < int(data.get("rebuy_below", 3)):
			stacks[id] = int(stacks[id]) + int(data.stack.men)
			_say(x[1], "rebuy")
		if id == YOU and int(stacks[id]) < ante:
			if not _broke_told:
				_broke_told = true
				_prompt(String(data.you.broke), 3.0)
			continue
		seats.append({"id": id, "who": x[1], "chair": x[0], "cards": [], "in": true, "put": 0})
	if seats.size() < 2 or seats.filter(func(s: Dictionary) -> bool: return s.id != YOU).is_empty():
		seats.clear()
		state = &"idle"
		_calm = 0.0
		return
	# The deal goes round the men (you're dealt to, you don't deal).
	var men := seats.filter(func(s: Dictionary) -> bool: return s.id != YOU)
	var at := -1
	for i in men.size():
		if men[i].id == dealer_id:
			at = i
	dealer_id = men[(at + 1) % men.size()].id
	deck = Poker.deck(rng)
	state = &"shuffle"
	_t = _beat("shuffle_s")
	_say(_seat(dealer_id).who, "shuffle", {}, true)
	_reach_for(dealer_id, "r", _deck_at().origin, _t)
	_reach_for(dealer_id, "l", _deck_at().origin + Vector3.UP * 0.02, _t)
	_dirty = true


func _ante() -> void:
	var ante := int(data.get("ante", 1))
	for s in seats:
		_put(s, ante)
	state = &"ante"
	_t = _beat("ante_s")


## Seats from the dealer's left round to the dealer.
func _from_dealer() -> Array[Dictionary]:
	var d := 0
	for i in seats.size():
		if seats[i].id == dealer_id:
			d = i
	var out: Array[Dictionary] = []
	for k in seats.size():
		out.append(seats[(d + 1 + k) % seats.size()])
	return out


func _begin_deal() -> void:
	_deal_q.clear()
	for k in 5:
		for s in _from_dealer():
			_deal_q.append([s, k])
	state = &"deal"
	_t = 0.0


func _deal_step() -> void:
	if _t > 0.0:
		return
	if _deal_q.is_empty():
		var you := _seat(YOU)
		if not you.is_empty():
			_prompt(String(data.you.dealt).replace("{hand}", Poker.name(you.cards)), 3.0)
		_begin_round(0)
		return
	var job: Array = _deal_q.pop_front()
	var s: Dictionary = job[0]
	var c: int = deck.pop_back()
	# The cheat dealing himself his last card: from the bottom, one that pairs his best (No Law: the
	# card player the red shirt believes has been cheating).
	var cheat: Dictionary = data.get("cheat", {})
	if int(job[1]) == 4 and s.id == dealer_id and s.id == String(cheat.get("who", "")) and rng.randf() < float(cheat.get("odds", 0.0)):
		var best := -1
		for x: int in s.cards:
			best = maxi(best, Poker.rank(x))
		for i in deck.size():
			if Poker.rank(deck[i]) == best:
				deck.push_back(c)
				c = deck[i]
				deck.remove_at(i)
				cheated += 1
				break
	s.cards.append(c)
	_add_card(c, _deck_at(), _card_at(s.chair, int(job[1])), s.id == YOU)
	_reach_for(dealer_id, "r", _card_at(s.chair, int(job[1])).origin.lerp(_deck_at().origin, 0.5), _beat("deal_every_s") * 1.5)
	_t = _beat("deal_every_s")


func _begin_round(n: int) -> void:
	betting_round = n
	_round_bet = 0
	_raises = 0
	_acted.clear()
	for s in seats:
		s.put = 0
	state = &"bet"
	_turn = -1
	_next_turn()


## The next man in the hand who's still to act (round from the dealer's left), or end the round.
func _next_turn() -> void:
	var order := _from_dealer()
	if _in_hand().size() <= 1:
		_showdown()
		return
	var start := 0
	if _turn >= 0:
		for i in order.size():
			if order[i].id == seats[_turn].id:
				start = i + 1
	for k in order.size():
		var s: Dictionary = order[(start + k) % order.size()]
		if s.in and (not _acted.has(s.id) or int(s.put) < _round_bet) and int(stacks[s.id]) > 0:
			_turn = seats.find(s)
			_t = rng.randf_range(float(data.beats.think_s[0]), float(data.beats.think_s[1]))
			if s.id == YOU:
				_you_turn = true
				_you_told = false
				_gesture = HeadGesture.new()
				_t = _beat("you_wait_s")
			return
	# Everyone's acted and level.
	_turn = -1
	if betting_round == 0:
		state = &"draw"
		_draw_i = -1
		_t = 0.0
	else:
		_showdown()


func _bet_step(dt: float) -> void:
	if _turn < 0 or _turn >= seats.size():
		_next_turn()
		return
	var s: Dictionary = seats[_turn]
	var to_call := _round_bet - int(s.put)
	if s.id == YOU:
		if not _you_told:
			_you_told = true
			# What it costs and what you've got: the playtest couldn't tell the stakes.
			var t := String(data.you.turn if to_call > 0 else data.you.turn_check).replace("{call}", str(to_call))
			_prompt(t + String(data.you.stakes).replace("{pot}", str(pot)).replace("{stack}", str(stacks.get(YOU, 0))), _beat("you_wait_s"))
			var asker := _seat(dealer_id)
			if not asker.is_empty() and asker.id != YOU:
				_say(asker.who, "your_turn")
		var p := s.who as Player
		var g := _gesture.feed(rad_to_deg(p.rotation.y), p.get_pitch_degrees(), dt) if p else &""
		if g == &"shake":
			_you_turn = false
			_fold(s, true)
			_prompt(String(data.you.you_fold), 1.5)
		elif g == &"nod" or (_t <= 0.0 and to_call <= 0):
			_you_turn = false
			_call(s)
			_prompt(String(data.you.you_call if to_call > 0 else data.you.you_check), 1.5)
		elif _t <= 0.0:
			# Waited on with a bet to you: you're out of it (it doesn't spend your money for you).
			_you_turn = false
			_fold(s, false)
			_prompt(String(data.you.you_fold), 1.5)
		else:
			return
		_next_turn()
		return
	if _t > 0.0:
		return
	var st := Poker.strength(s.cards)
	var bet := int((data.get("bets", [1, 2]) as Array)[mini(betting_round, 1)])
	if to_call <= 0:
		if st >= _play("open_at") and rng.randf() < _play("open_chance") and _raises < int(data.get("max_raises", 2)):
			_round_bet += bet
			_raises += 1
			_put(s, _round_bet - int(s.put))
			_did(s, "bet")
		else:
			_did(s, "check")
	elif st >= _play("raise_at") and rng.randf() < _play("raise_chance") and _raises < int(data.get("max_raises", 2)):
		_round_bet += bet
		_raises += 1
		_put(s, _round_bet - int(s.put))
		_did(s, "raise")
	elif st >= _play("call_at") or rng.randf() < _play("bluff_call"):
		_call(s)
		_did(s, "call")
	else:
		_fold(s, true)
		_did(s, "fold")
	_next_turn()


func _did(s: Dictionary, move: String) -> void:
	_acted[s.id] = true
	last_move[s.id] = move
	if move in ["bet", "raise"] and you_in():
		_prompt(String(data.you.they_bet).replace("{who}", String((s.who as Node).name)).replace("{n}", str(_round_bet)), 2.0)
	if move in ["bet", "raise", "call"]:
		_reach_for(s.id, "r", _pot_at() + Vector3.UP * 0.03, _beat("chip_fly_s") * 2.5)
	_say(s.who, move)


func _call(s: Dictionary) -> void:
	_acted[s.id] = true
	last_move[s.id] = "call" if _round_bet > int(s.put) else "check"
	_put(s, _round_bet - int(s.put))


func _fold(s: Dictionary, said: bool) -> void:
	s.in = false
	_acted[s.id] = true
	last_move[s.id] = "fold"
	# His cards pushed in, face down.
	for card in _cards:
		if card.get("owner", "") == s.id:
			_fly(card, _muck_at(_mucked), false)
			card.owner = ""
			_mucked += 1
	if s.id == YOU and said:
		for o in _in_hand():
			_say(o.who, "you_fold")
			break


## `n` chips from his stack to the pot (what he has, at most).
func _put(s: Dictionary, n: int) -> void:
	n = clampi(n, 0, int(stacks.get(s.id, 0)))
	if n <= 0:
		return
	stacks[s.id] = int(stacks[s.id]) - n
	s.put = int(s.put) + n
	pot += n
	for i in mini(n, 3):
		_chip_flights.append({"from": _chips_at(s.chair) + Vector3.UP * CHIP_H * 2.0, "to": _pot_at(), "t": -0.08 * i, "colour": i % CHIP_COLOURS.size()})
		_pot_flying += 1
	_dirty = true


func _draw_step() -> void:
	if _t > 0.0:
		return
	var order := _from_dealer()
	_draw_i += 1
	while _draw_i < order.size() and not order[_draw_i].in:
		_draw_i += 1
	if _draw_i >= order.size():
		_begin_round(1)
		return
	var s: Dictionary = order[_draw_i]
	var out := Poker.discards(s.cards)
	# Thrown in face down, and as many dealt him.
	for k in out:
		for card in _cards:
			if card.get("owner", "") == s.id and card.get("slot", -1) == k:
				_fly(card, _muck_at(_mucked), false)
				card.owner = ""
				_mucked += 1
		var c: int = deck.pop_back()
		s.cards[k] = c
		_add_card(c, _deck_at(), _card_at(s.chair, k, 1), s.id == YOU, 0.25 + 0.12 * out.find(k), s.id, k)
	last_move[s.id] = "draw %d" % out.size()
	if s.id == YOU:
		_prompt(String(data.you.you_draw).replace("{n}", str(out.size())) if not out.is_empty() else String(data.you.you_stand_pat), 1.6)
	else:
		_say(s.who, "draw_%d" % mini(out.size(), 3))
	_reach_for(dealer_id, "r", _card_at(s.chair, 2).origin.lerp(_deck_at().origin, 0.5), _beat("draw_s") * 0.7)
	_t = _beat("draw_s")


func _showdown() -> void:
	var live := _in_hand()
	_turn = -1
	_you_turn = false
	var best: Array[Dictionary] = []
	for s in live:
		if best.is_empty() or Poker.compare(s.cards, best[0].cards) > 0:
			best = [s]
		elif Poker.compare(s.cards, best[0].cards) == 0:
			best.append(s)
	var shown := live.size() > 1
	if shown:
		for card in _cards:
			for s in live:
				if card.get("owner", "") == s.id:
					card.up = true
					_show_face(card)
	var share := pot / maxi(best.size(), 1)
	var won := pot
	for w in best:
		stacks[w.id] = int(stacks[w.id]) + share
		wins[w.id] = int(wins.get(w.id, 0)) + 1
		for i in mini(share, 4):
			_chip_flights.append({"from": _pot_at() + Vector3.UP * CHIP_H * 3.0, "to": _chips_at(w.chair), "t": -0.1 * i - 0.4, "colour": i % CHIP_COLOURS.size()})
		_reach_for(w.id, "r", _pot_at() + Vector3.UP * 0.02, 1.4)
	pot -= share * best.size()
	var w0: Dictionary = best[0] if not best.is_empty() else {}
	last_winner = String(w0.get("id", ""))
	last_hand = Poker.name(w0.cards) if not w0.is_empty() else ""
	if not w0.is_empty():
		if w0.id == YOU:
			_prompt(String(data.you.you_win).replace("{hand}", last_hand) if shown else String(data.you.you_win).replace(" with {hand}", ""), 3.0)
			for o in seats:
				if o.id != YOU:
					_say(o.who, "you_win")
					break
		else:
			_say(w0.who, "win" if shown else "win_quiet", {"hand": last_hand[0].to_upper() + last_hand.substr(1)}, true)
			for o in live:
				if o.id != w0.id and o.id != YOU:
					_say(o.who, "lose")
					break
	hands += 1
	hand_done.emit(last_winner, won, last_hand)
	state = &"showdown"
	_t = _beat("showdown_s")
	_dirty = true


# --- Saying and doing ----------------------------------------------------------------------------

func _lines(who: Node3D, kind: String) -> Array:
	var lines: Dictionary = data.get("lines", {})
	var own: Dictionary = (lines.get("by", {}) as Dictionary).get(id_of(who), {})
	return own.get(kind, lines.get(kind, []))


## A line of `kind` from him (sometimes: say_chance, a man at most every say_gap_s; `always`).
func _say(who: Variant, kind: String, fill := {}, always := false) -> void:
	if who == null or not is_instance_valid(who) or not who is HumanBody:
		return
	var id := id_of(who)
	if not always and (_clock - float(_said.get(id, -INF)) < float(data.get("say_gap_s", 2.5)) or rng.randf() > float(data.get("say_chance", 0.5))):
		return
	var pick := _lines(who, kind)
	if pick.is_empty():
		return
	var text := String(pick[rng.randi() % pick.size()])
	for k: String in fill:
		text = text.replace("{%s}" % k, String(fill[k]))
	_said[id] = _clock
	Events.spoke.emit(who, text)


func _prompt(text: String, seconds: float) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player if is_inside_tree() else null
	if p and p.wounds and p.seat and p.seat.seated() and chairs.has(p.seat.chair):
		p.wounds.say(text, seconds)


func _reach_for(id: String, side: String, at: Vector3, seconds: float) -> void:
	if id == YOU or id == "":
		return
	_reach[id + side] = [id, side, at, _clock + seconds, _clock]


## Each tick: the men's hands where the game has them, their eyes on the table.
func _act() -> void:
	if state in [&"idle", &"stopped"]:
		return
	var c := centre()
	for s in seats:
		if not is_instance_valid(s.who):
			continue
		var man := s.who as HumanBody
		if man == null or man.limp or s.chair.seated != man:
			continue
		var life := man.get_node_or_null(^"FaceLife") as FaceLife
		if life:
			var look := c
			if _turn >= 0 and _turn < seats.size() and seats[_turn].id != s.id:
				var other: Node3D = seats[_turn].who if is_instance_valid(seats[_turn].who) else null
				if other == null:
					continue
				look = other.global_position + Vector3.UP * 1.15 if other is HumanBody else (other as Player).camera.global_position
			life.attend_to(look)
	for k: String in _reach.keys():
		var r: Array = _reach[k]
		var who: Variant = _seat(r[0]).get("who")
		var man := who as HumanBody if is_instance_valid(who) else null
		if man == null or _clock > float(r[3]) or man.limp:
			_reach.erase(k)
			continue
		# Out to it and back: eased in and out over a quarter second each way.
		var ease := minf(clampf((_clock - float(r[4])) * 4.0, 0.0, 1.0), clampf((float(r[3]) - _clock) * 4.0, 0.0, 1.0))
		man.reach_to(String(r[1]), r[2], Vector3.UP, ease)


# --- Cards and chips on the table -------------------------------------------------------------------

func _add_card(c: int, from: Transform3D, to: Transform3D, up: bool, delay := 0.0, owner := "", slot := -1) -> void:
	if owner == "":
		# Dealt: whose it is, its slot (its place in his row).
		for x in seats:
			if x.cards.has(c):
				owner = x.id
				slot = x.cards.find(c)
	var card := {"c": c, "from": from, "to": to, "t": -delay, "up": up, "owner": owner, "slot": slot}
	_cards.append(card)
	if up:
		_show_face(card)
	_dirty = true


func _fly(card: Dictionary, to: Transform3D, up: bool) -> void:
	card.from = _card_xform(card)
	card.to = to
	card.t = 0.0
	card.up = up
	if not up and card.get("label"):
		(card.label as Label3D).queue_free()
		card.erase("label")
	_dirty = true


func _show_face(card: Dictionary) -> void:
	if card.get("label"):
		return
	var l := Label3D.new()
	l.text = Poker.label(int(card.c), _letters)
	l.pixel_size = 0.0006
	l.font_size = 40
	l.outline_size = 0
	l.modulate = Color(0.62, 0.06, 0.05) if Poker.red(int(card.c)) else Color(0.05, 0.05, 0.05)
	l.shaded = false
	l.double_sided = true
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	l.visibility_range_end = SEEN_FROM
	add_child(l)
	card.label = l
	_place_label(card)


func _place_label(card: Dictionary) -> void:
	var l: Label3D = card.get("label")
	if l == null:
		return
	var x := _card_xform(card)
	l.global_transform = Transform3D(x.basis * Basis(Vector3.RIGHT, -PI * 0.5), x.origin + x.basis.y * 0.0015)


func _card_xform(card: Dictionary) -> Transform3D:
	var k := clampf(float(card.t) / _beat("card_fly_s"), 0.0, 1.0)
	var a: Transform3D = card.from
	var b: Transform3D = card.to
	var x := a.interpolate_with(b, k)
	x.origin.y += sin(k * PI) * 0.05
	return x


func _clear_table() -> void:
	for card in _cards:
		if card.get("label"):
			(card.label as Label3D).queue_free()
	_cards.clear()
	_mucked = 0
	_chip_flights.clear()
	_pot_flying = 0
	_reach.clear()
	_dirty = true


func _animate(dt: float) -> void:
	var fly := _beat("card_fly_s")
	for card in _cards:
		if float(card.t) < fly:
			card.t = float(card.t) + dt
			_place_label(card)
			_dirty = true
	var cf := _beat("chip_fly_s")
	for i in range(_chip_flights.size() - 1, -1, -1):
		var f: Dictionary = _chip_flights[i]
		f.t = float(f.t) + dt
		_dirty = true
		if float(f.t) >= cf:
			if (f.to as Vector3).is_equal_approx(_pot_at()):
				_pot_flying = maxi(_pot_flying - 1, 0)
			_chip_flights.remove_at(i)
	if _dirty:
		_dirty = false
		_draw_cards()
		_draw_chips()


func _draw_cards() -> void:
	var mm := _card_mm.multimesh
	var shown := _cards.filter(func(c: Dictionary) -> bool: return float(c.t) >= 0.0)
	var deck_n := mini(deck.size(), 12) if state not in [&"idle", &"between"] and not seats.is_empty() else 0
	mm.instance_count = shown.size() + deck_n
	var i := 0
	for card in shown:
		mm.set_instance_transform(i, _card_xform(card))
		mm.set_instance_color(i, FACE if card.up else BACK)
		i += 1
	var d := _deck_at()
	for k in deck_n:
		mm.set_instance_transform(i, Transform3D(d.basis, d.origin + Vector3.UP * (k * 0.0012 - 0.005)))
		mm.set_instance_color(i, BACK)
		i += 1


func _draw_chips() -> void:
	var xs: Array[Transform3D] = []
	var cs: Array[Color] = []
	for s in seats:
		_stack(xs, cs, _chips_at(s.chair), int(stacks.get(s.id, 0)))
	_stack(xs, cs, _pot_at(), pot - _pot_flying, true)
	var cf := _beat("chip_fly_s")
	for f in _chip_flights:
		if float(f.t) < 0.0:
			continue
		var k := clampf(float(f.t) / cf, 0.0, 1.0)
		var p: Vector3 = (f.from as Vector3).lerp(f.to, k) + Vector3.UP * sin(k * PI) * 0.04
		xs.append(Transform3D(Basis(), p))
		cs.append(CHIP_COLOURS[int(f.colour)])
	var mm := _chip_mm.multimesh
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
		mm.set_instance_color(i, cs[i])


## `n` chips as stacks of three colours at `at` (a pile, `spread`, for the pot).
func _stack(xs: Array[Transform3D], cs: Array[Color], at: Vector3, n: int, spread := false) -> void:
	n = mini(n, STACK_MAX * 3)
	for i in n:
		var col := i % 3 if spread else mini(i / STACK_MAX, 2)
		var h := i / 3 if spread else i % STACK_MAX
		var off := Vector3(float(col) * CHIP_R * 2.2, 0.0, 0.0) if not spread else Vector3(cos(col * 2.1) * 0.035, 0.0, sin(col * 2.1) * 0.035)
		xs.append(Transform3D(Basis(Vector3.UP, i * 0.7), at + off + Vector3.UP * (CHIP_H * 0.5 + h * CHIP_H)))
		cs.append(CHIP_COLOURS[col])


func _multimesh(n: String, mesh: Mesh) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = n
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = SEEN_FROM
	# The instances are in world space, it at the origin; its box the table and round it.
	mmi.top_level = true
	add_child(mmi)
	mmi.global_transform = Transform3D()
	var c := centre()
	mmi.custom_aabb = AABB(c - Vector3(1.5, 1.0, 1.5), Vector3(3.0, 2.0, 3.0))
	return mmi


static func _box_mesh() -> Mesh:
	var m := BoxMesh.new()
	m.size = CARD_SIZE
	m.material = _vertex_material(0.75)
	return m


static func _chip_mesh() -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = CHIP_R
	m.bottom_radius = CHIP_R
	m.height = CHIP_H
	m.radial_segments = 10
	m.rings = 1
	m.material = _vertex_material(0.55)
	return m


static func _vertex_material(rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = rough
	return mat


## What it's doing, for the bridge and the tests.
func report() -> Dictionary:
	var ss := []
	for s in seats:
		ss.append({"id": s.id, "stack": int(stacks.get(s.id, 0)), "in": s.in, "put": int(s.put),
				"cards": (s.cards as Array).map(func(c: int) -> String: return Poker.label(c, true)),
				"hand": Poker.name(s.cards) if (s.cards as Array).size() == 5 else "", "last": String(last_move.get(s.id, ""))})
	return {"state": String(state), "stopped_by": String(stop_reason), "hands": hands, "dealer": dealer_id,
			"round": betting_round, "turn": String(seats[_turn].id) if _turn >= 0 and _turn < seats.size() else "",
			"pot": pot, "seats": ss, "wins": wins.duplicate(), "cheated": cheated, "you_in": you_in(),
			"last_winner": last_winner, "last_hand": last_hand, "cards_on_table": _cards.size(), "held": holds.keys()}
