extends BridgeLab
## The answers bench (#1272, DESIGN §2 pillar 6 "Everything you do gets an answer"): what the saloon's
## people did about one thing the player did. `ans_snap` is everyone the valley's folk has in play
## now (who sees you, his Reaction, mood, look, regard); `ans_watch S` watches S seconds of game time
## and says, for each man, when he first answered and how (a line, a Reaction stage, a look, a
## flinch, a mood). `run.py` drives a fresh game a verb and makes the table.

const HELP := {
	"ans_snap": "ans_snap -> each valley man in play: sees you, distance, Reaction stage/kind, mood, look shown, regard numbers and band",
	"ans_pot": "ans_pot MAX_S -> waits (at most MAX_S game s) till you win a hand at the valley's table; answers the hand",
	"ans_close": "ans_close PERSON D -> you put D m in front of PERSON, facing him",
	"ans_turn": "ans_turn [any|bet|weak|strong] MAX_S -> waits (at most MAX_S game s) till it's your turn at the valley's table (bet: with a bet open to you; weak/strong: your hand under or over the table's call_at; answers your hand",
	"ans_lose": "ans_lose MAX_S -> waits till a hand you played to the end is won by another man; answers the hand",
	"ans_watch": "ans_watch S -> S seconds watched: each man's first answer (said / reaction / look / flinch / mood) and when, the lines said",
}


func _folk() -> ValleyFolk:
	return get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk


func _men() -> Dictionary:
	var out := {}
	var vf := _folk()
	if vf == null:
		return out
	for pid: StringName in vf.people:
		var man: HumanBody = vf.people[pid]
		if man == null or not is_instance_valid(man) or not man.is_inside_tree():
			continue
		if man.global_position.distance_to(player.global_position) > 30.0:
			continue
		out[pid] = man
	return out


func _cmd_ans_snap(_a: Array) -> Dictionary:
	var vf := _folk()
	var out := {}
	for pid: StringName in _men():
		var man: HumanBody = _men()[pid]
		var b := man.get_node_or_null(^"Brain") as CivilianBrain
		var r := {"d": snappedf(man.global_position.distance_to(player.global_position), 0.01),
				"state": String(vf.state.get(pid, &"")), "alive": man.physiology.alive}
		if b != null:
			r["sees"] = b.senses != null and b.senses.sees(player)
			r["mood"] = String(CivilianBrain.Mood.keys()[b.mood]).to_lower()
			r["stage"] = String(Reaction.Stage.keys()[b.reaction.stage]).to_lower() if b.reaction else "none"
			r["kind"] = String(b.reaction.kind) if b.reaction else ""
			r["fear"] = snappedf(b.fear, 0.01)
			r["shown"] = String(b.last_shown)
		# At the card table (#1279): sat at it, the verbs there are done to his face.
		r["table"] = vf.cards != null and vf.cards.sat().any(func(x: Array) -> bool: return x[1] == man)
		if vf.regard != null and vf.regard.people().has(pid):
			var o := vf.regard.opinions(pid)
			for k: String in o:
				r[k] = snappedf(o[k], 0.001)
			r["band"] = String(vf.regard.band_of(o))
		out[String(pid)] = r
	return {"men": out, "barks": vf.barks.log.size() if vf.barks else 0}


func _cmd_ans_watch(a: Array) -> Dictionary:
	var s := float(a[0]) if a.size() > 0 else 3.0
	var men := _men()
	var first := {}
	var lines: Array = []
	var t0 := Time.get_ticks_msec()
	var game0 := bridge._game_seconds()
	var on_spoke := func(who: Node, text: String) -> void:
		var pid := _pid_of(who, men)
		var at := snappedf(bridge._game_seconds() - game0, 0.01)
		lines.append([pid, text, at])
		if pid != "" and not first.has(pid):
			first[pid] = {"how": "said", "s": at, "text": text}
	Events.spoke.connect(on_spoke)
	var base := {}
	for pid: StringName in men:
		var b := (men[pid] as HumanBody).get_node_or_null(^"Brain") as CivilianBrain
		if b != null:
			# Calm, no stage, no look: what a man at his drink is (ans_snap before says he was). A look or a
			# fright already on when the watch starts began in the verb's own frame: it counts.
			base[pid] = [CivilianBrain.Mood.CALM, Reaction.Stage.NONE, &""]
	while bridge._game_seconds() - game0 < s:
		await physics_frames(3)
		var at := snappedf(bridge._game_seconds() - game0, 0.01)
		for pid: StringName in base:
			if first.has(String(pid)):
				continue
			var b := (men[pid] as HumanBody).get_node_or_null(^"Brain") as CivilianBrain
			if b == null or not is_instance_valid(b):
				continue
			var how := ""
			if b.reaction and b.reaction.stage != Reaction.Stage.NONE and b.reaction.stage != base[pid][1]:
				how = "reaction:" + String(b.reaction.kind) + ":" + String(Reaction.Stage.keys()[b.reaction.stage]).to_lower()
			elif b.showing.get("what", &"") != &"" and b.showing.get("what", &"") != base[pid][2]:
				how = "look:" + String(b.showing.get("what"))
			elif b._flinch > 0.0:
				how = "flinch"
			elif b.mood != base[pid][0]:
				how = "mood:" + String(CivilianBrain.Mood.keys()[b.mood]).to_lower()
			if how != "":
				first[String(pid)] = {"how": how, "s": at}
	Events.spoke.disconnect(on_spoke)
	return {"first": first, "lines": lines, "real_ms": Time.get_ticks_msec() - t0}


func _pid_of(who: Node, men: Dictionary) -> String:
	for pid: StringName in men:
		if men[pid] == who:
			return String(pid)
	return String(who.get("person_id")) if who != null and who.get("person_id") != null else ""


func _cmd_ans_pot(a: Array) -> Dictionary:
	var g := get_tree().get_first_node_in_group(&"card_game") as CardGame
	if g == null:
		return {"ok": false, "error": "no card game"}
	var won := [false]
	var f := func(w: String, _p: int, _h: String) -> void:
		if w == CardGame.YOU:
			won[0] = true
	g.hand_done.connect(f)
	var game0 := bridge._game_seconds()
	while not won[0] and bridge._game_seconds() - game0 < (float(a[0]) if a.size() > 0 else 240.0):
		await physics_frames(1)
	g.hand_done.disconnect(f)
	return {"won": won[0], "after_s": snappedf(bridge._game_seconds() - game0, 0.1), "hands": g.hands}


func _cmd_ans_close(a: Array) -> Dictionary:
	var man := person(String(a[0])) if a.size() > 0 else null
	if man == null:
		return {"ok": false, "error": "ans_close PERSON D"}
	var d := float(a[1]) if a.size() > 1 else 0.6
	var to := player.global_position - man.global_position
	to.y = 0.0
	to = to.normalized() if to.length() > 0.01 else Vector3.FORWARD
	player.global_position = man.global_position + to * d
	player.velocity = Vector3.ZERO
	player.rotation.y = atan2(to.x, to.z)
	await physics_frames(2)
	return {"d": snappedf(player.global_position.distance_to(man.global_position), 0.01)}


func _cmd_ans_turn(a: Array) -> Dictionary:
	var g := get_tree().get_first_node_in_group(&"card_game") as CardGame
	if g == null:
		return {"ok": false, "error": "no card game"}
	var want := String(a[0]) if a.size() > 0 else "any"
	var game0 := bridge._game_seconds()
	var limit := float(a[1]) if a.size() > 1 else 240.0
	while bridge._game_seconds() - game0 < limit:
		await physics_frames(1)
		if not g._you_turn:
			continue
		var you := g._seat(CardGame.YOU)
		if you.is_empty():
			continue
		var st := Poker.strength(you.cards)
		var weak := st < g._play("call_at")
		var to_call := g._round_bet - int(you.put)
		if want == "any" or (want == "bet" and to_call > 0) or (want in ["weak", "strong"] and (want == "weak") == weak):
			return {"turn": true, "hand": Poker.name(you.cards), "strength": snappedf(st, 0.01), "weak": weak,
					"to_call": to_call, "pot": g.pot, "after_s": snappedf(bridge._game_seconds() - game0, 0.1)}
		# Not the turn wanted: waiting for a bet, check (a nod) and play on; else fold it (a shake) and wait
		# for the next hand.
		if want == "bet":
			await bridge._cmd_nod([])
		else:
			await bridge._cmd_shake([])
	return {"turn": false, "after_s": snappedf(bridge._game_seconds() - game0, 0.1)}


func _cmd_ans_lose(a: Array) -> Dictionary:
	var g := get_tree().get_first_node_in_group(&"card_game") as CardGame
	if g == null:
		return {"ok": false, "error": "no card game"}
	var lost := [false]
	var f := func(w: String, _p: int, _h: String) -> void:
		var you := g._seat(CardGame.YOU)
		if w != CardGame.YOU and not you.is_empty() and bool(you.in):
			lost[0] = true
	g.hand_done.connect(f)
	var game0 := bridge._game_seconds()
	while not lost[0] and bridge._game_seconds() - game0 < (float(a[0]) if a.size() > 0 else 240.0):
		await physics_frames(1)
		# Stay in every hand to the end: nod on your turn (a call).
		if g._you_turn:
			await bridge._cmd_nod([])
	g.hand_done.disconnect(f)
	return {"lost": lost[0], "after_s": snappedf(bridge._game_seconds() - game0, 0.1), "hands": g.hands}
