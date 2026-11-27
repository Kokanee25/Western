extends TestCase
## No Law, beat 3 (#773; NoLawMurder, config/moments/no_law_murder.json): at night at the saloon
## yard's card table, a stranger sits in the free chair, Cody walks in shouting at Earl, the game
## stops and you're held in your seat, the stranger tells you not to move, Cody kicks Earl's chair
## out, shoots him where he lies (down through his collarbone since #1057: down and bleeding), says there's no law to save him and walks out; the
## room quiet till the barman's "Jesus, Cody, my chair!". After: you're let go, Earl's body stays,
## the drifter and the miner leave, StoryState has what you saw. Not at the table, it happens all
## the same. And the townsfolk after a shot (the cards playtest): cries by turns, not all at once.

var holder: Node
var valley: ValleyWorld
var said: Array = []  # [physics frame, speaker id, text, the act's t, msec]


## A fresh valley for each test (Earl's only murdered once).
func before_each() -> void:
	ValleyFolk.murder_auto = true
	StoryState.clear("nolaw.")
	await _new_valley()


## The valley built again (the scene's reload, as after Backspace).
func _new_valley() -> void:
	if holder != null:
		holder.queue_free()
		await physics_frames(3)
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	said.clear()
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)
	await physics_frames(5)


func after_each() -> void:
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)


func _on_spoke(who: Node, text: String) -> void:
	var id := String((who as HumanBody).person_id) if who is HumanBody else "?"
	said.append([Engine.get_physics_frames(), id, text, _folk().murder.t if _folk() and _folk().murder and is_instance_valid(_folk().murder) else -1.0,
			Engine.get_physics_frames() * 1000 / Engine.physics_ticks_per_second])


func _folk() -> ValleyFolk:
	return valley.folk if valley and is_instance_valid(valley) else null


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _clock() -> DayCycle:
	return valley.get_node(^"DayCycle") as DayCycle


func _chair(c: String) -> KitProp:
	return _folk().props["chair_" + c] as KitProp


## The clock to `h` and everyone at their posts.
func _at(h: float) -> void:
	_clock().set_time(h)
	await physics_frames(1)
	_folk()._look = 0.0
	await physics_frames(60)


## Sat in chair `c` (E, behind it, facing it).
func _sit(c: String) -> void:
	var p := _player()
	var ch := _chair(c)
	p.global_position = Seating.spot(ch) - ch.global_basis.z * 0.5
	p.velocity = Vector3.ZERO
	var to := ch.global_basis.z
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(2)
	p.seat.use()
	await physics_frames(10)


func _lines_of(id: String) -> Array:
	return said.filter(func(s: Array) -> bool: return s[1] == id).map(func(s: Array) -> String: return s[2])


func test_the_murder_with_you_sat_at_the_table() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var p := _player()
	# The south chair (the playtest's): the stranger's way to the north one goes round the table.
	await _sit("s")
	check(p.seat.seated() and _chair("s").seated == p, "sat in the south chair (%s)" % p.seat.report())
	var earl := f.folk_man(&"earl")
	check(earl != null and _chair("w").seated == earl, "Earl at the table")
	# The clock at its hour on the first night: it starts.
	ValleyFolk.murder_auto = true
	await _at(22.0)
	var m := f.murder as NoLawMurder
	check(m != null, "it starts at 22:00 (%s)" % f.report())
	if m == null:
		return
	var sat := await wait_until(func() -> bool: return m._str_state == &"sat", 60 * 30)
	check(sat and _chair("n").seated == m.stranger, "the stranger sits in the free (north) chair (%s)" % m.result())
	check(m.events.any(func(e: Array) -> bool: return String(e[1]).begins_with("the stranger sits")) and m.state == &"stranger", "sat before Cody comes in (%s)" % [m.events])
	check_eq(_lines_of("stranger"), ["Evening. Mind if I sit in a while?"], "his first line first")
	var stopped := await wait_until(func() -> bool: return m.state not in [&"stranger", &"come"], 60 * 40)
	check(stopped, "Cody comes up to Earl (%s)" % m.result())
	check(f.cards.state == &"stopped" and f.cards.stop_reason == &"cody" and f.cards.holds.has(&"cody"), "the game stopped and held (%s)" % f.cards.state)
	# He shouts at Earl as he walks into the yard (Sean, 2026-11-12), before he's up at the table:
	# the accusation before the game stops, and the stranger's warning after it.
	var ev: Array = m.events.map(func(e: Array) -> String: return String(e[1]))
	var acc := ev.find("Cody accuses Earl")
	var stop := -1
	for i in ev.size():
		if ev[i].begins_with("the game stops"):
			stop = i
	check(acc >= 0 and acc == ev.find("Cody comes in") + 1 and acc < stop, "Cody shouts as he comes in, before he's at the table (%s)" % [ev])
	check_eq(_lines_of("cody").slice(0, 1), ["Earl, you cheating son of a bitch!"], "his shout")
	var shout_i := -1
	var warn_i := -1
	for i in said.size():
		if said[i][2] == "Earl, you cheating son of a bitch!" and shout_i < 0:
			shout_i = i
		if String(said[i][2]).begins_with("Don't move") and warn_i < 0:
			warn_i = i
	check(shout_i >= 0 and warn_i > shout_i, "the stranger's warning after the shout (%d, %d)" % [shout_i, warn_i])
	check(m.you_held and p.seat.held(), "you're held in your seat")
	check_eq(p.seat.use(), &"held", "E doesn't stand you")
	check(_lines_of("stranger").any(func(l: String) -> bool: return l.begins_with("Don't move")), "the stranger tells you not to move (%s)" % [_lines_of("stranger")])
	var shot := await wait_until(func() -> bool: return m.shots > 0, 60 * 20)
	check(shot, "Cody shoots (%s)" % m.result())
	var r := m.result()
	check(r.chair_loose and r.earl_fell, "Earl's chair kicked out from under him (%s)" % r)
	# #1248 (the blind playtest, 2026-11-25): the card table went over with Earl's chair, and in saloon B
	# it lay on the way out. The table stands, and the other chairs (the stranger's, yours) with it.
	var table := f.props.table as KitProp
	check(table != null and not table.loose, "the card table still standing after the kick (%s)" % (table.global_position if table else Vector3.INF))
	if table != null:
		var feet := 0
		for i in 4:
			if table._has_footing(table.get_member(StringName("%s/foot%d" % [table.structure_id, i]))):
				feet += 1
		check_eq(feet, 4, "on its four feet")
		check(int(f.cards.report().cards_on_table) > 0, "the cards still on it (%s)" % f.cards.report())
	# His fall off the chair bruised him, no more (#1248: logged as four "hits" before the shot).
	check(earl.physiology.injuries() <= 1, "no injury but Cody's ball (%d wounds, %d bruises)" % [earl.physiology.wounds, earl.physiology.bruises])
	# Down and bleeding, not shot dead (Sean, 2026-11-17, #1057): the ball through his collarbone,
	# what it does the body's.
	await physics_frames(20)
	check(not earl.wounds.is_empty() and (earl.physiology.total_bleed_rate() > 1.0 or not earl.physiology.alive),
			"Earl shot and bleeding (%s)" % earl.physiology.describe())
	check(m.shots == 1, "one shot (%d)" % m.shots)
	check(p.seat.seated(), "you're still sat")
	var over := await wait_until(func() -> bool: return m.done, 60 * 60)
	r = m.result()
	check(over and r.end == "done", "it plays out (%s)" % r)
	check(_lines_of("cody").any(func(l: String) -> bool: return "no law" in l), "no law to save him (%s)" % [_lines_of("cody")])
	check(_lines_of("barkeep").has("Jesus, Cody, my chair!"), "the barman's first words")
	check(m.events.any(func(e: Array) -> bool: return e[1] == "the barkeep by Earl"), "the barkeep comes round to Earl (%s)" % [m.events.slice(-6)])
	check_eq(int(f.cards.report().cards_on_table), 0, "and gathers the cards")
	# A gun on the stranger as he goes: he has his word.
	if m.stranger != null and is_instance_valid(m.stranger):
		var n := _lines_of("stranger").size()
		Events.deed.emit(p, &"aim_at", m.stranger, p.global_position)
		await physics_frames(2)
		check(_lines_of("stranger").size() == n + 1, "the stranger answers a gun on him (%s)" % [_lines_of("stranger")])
	# The room quiet from the shot to the barman's line: nobody else says a word.
	var shot_t := -1.0
	for e: Array in m.events:
		if String(e[1]).begins_with("Cody shoots"):
			shot_t = float(e[0])
			break
	var chair_t := INF
	for s: Array in said:
		if s[2] == "Jesus, Cody, my chair!":
			chair_t = float(s[3])
	var talk := said.filter(func(s: Array) -> bool: return float(s[3]) > shot_t and float(s[3]) < chair_t and s[1] != "cody")
	check(talk.is_empty(), "the room quiet till the barman (%s)" % [talk])
	check(_lines_of("barkeep").size() <= 1 or _lines_of("barkeep")[0] == "Jesus, Cody, my chair!", "the barman's first words are those (%s)" % [_lines_of("barkeep")])
	# After: let go, Earl stays, the men leave, the facts.
	check(not p.seat.held(), "let go")
	check(f.folk_man(&"earl") == earl and earl.is_inside_tree(), "Earl's body stays")
	# Down and breathing when it's over (#1057): the carry's, and he dies by his own clock.
	check(String(f.state[&"earl"]) == "dead" or earl.physiology.alive, "Earl breathing, or dead to the folk (%s)" % f.state[&"earl"])
	var gone := await wait_until(func() -> bool: return not f.people.has(&"cody") and not f.people.has(&"stranger"), 60 * 90)
	var touching := []
	if not gone and m.stranger != null and is_instance_valid(m.stranger):
		var q := PhysicsShapeQueryParameters3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.3
		cap.height = 1.6
		q.shape = cap
		q.transform = Transform3D(Basis(), m.stranger.global_position + Vector3.UP * 0.9)
		q.collision_mask = Layers.WORLD
		for hit: Dictionary in valley.get_world_3d().direct_space_state.intersect_shape(q, 12):
			touching.append(str((hit.collider as Node).get_path()).get_slice("/Valley/", 1))
	check(gone, "Cody and the stranger walk off down the street and are gone (%s; the stranger %s at %s by %s, his way left %s)" % [m.result().events.slice(-3), m._str_state,
			m.stranger.global_position if m.stranger != null and is_instance_valid(m.stranger) else "gone", touching, m._str_route])
	check(String(f.state[&"drifter"]) in ["going", "out"] and f.kept_out.has(&"drifter"), "the drifter leaves (%s)" % f.state[&"drifter"])
	check_eq(StoryState.get_fact("nolaw.murder"), "done", "nolaw.murder")
	check_eq(StoryState.get_fact("nolaw.seen_from"), "table", "seen from the table")
	check_eq(StoryState.get_fact("nolaw.witnessed"), true, "you witnessed it")
	check(StoryState.get_fact("nolaw.earl") in ["alive", "dead"], "nolaw.earl (%s)" % StoryState.get_fact("nolaw.earl"))
	p.seat.use()
	await physics_frames(10)
	check(not p.seat.seated(), "E stands you up now")
	# Once only: not again this run.
	await _at(23.0)
	check(f.murder == m, "not started again")


func test_away_from_the_table_it_happens_all_the_same() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var p := _player()
	# Out on the street, 40 m east of the yard's table.
	p.global_position = f.cards.centre() + Vector3(40.0, 0.0, 12.0)
	p.global_position.y = f.ground(p.global_position.x, p.global_position.z) + 0.1
	await physics_frames(10)
	var m := f.start_murder() as NoLawMurder
	check(m != null, "started")
	var over := await wait_until(func() -> bool: return m.done, 60 * 120)
	var r := m.result()
	check(over and r.end == "done", "it plays out (%s)" % r)
	check(not m.you_held, "nobody held you")
	check(not m.cheater.wounds.is_empty(), "Earl shot (%s)" % r.get("earl", ""))
	check_eq(StoryState.get_fact("nolaw.seen_from"), "heard", "heard it")
	check_eq(StoryState.get_fact("nolaw.witnessed"), false, "not a witness")


## What lies between Cody's muzzle and where he aims doesn't save Earl (#925; since #1057 his
## collarbone, not his head): a piece of his chair held on the line as Cody stands over him. Before, the ball stopped in whatever lay on its line
## (a chair leg, Earl's own neck or arm): of 16 murders in fresh valleys 2 left him alive after all
## three shots, by how his ragdoll happened to lie.
func test_a_chair_leg_over_his_face_doesnt_save_him() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var p := _player()
	p.global_position = f.cards.centre() + Vector3(40.0, 0.0, 12.0)
	p.global_position.y = f.ground(p.global_position.x, p.global_position.z) + 0.1
	await physics_frames(10)
	var m := f.start_murder() as NoLawMurder
	check(m != null, "started")
	var over_him := await wait_until(func() -> bool: return m.state == &"stand_over" or m.done, 60 * 60)
	check(over_him and not m.done, "Cody stands over Earl (%s)" % m.state)
	if m.done:
		return
	# A loose bar (a chair's leg, lying still) across the line from his gun to Earl's head, a hand
	# from the head, kept there till he fires.
	var leg := RigidBody3D.new()
	leg.collision_layer = Layers.WORLD
	leg.freeze = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3, 0.3, 0.06)
	shape.shape = box
	leg.add_child(shape)
	valley.add_child(leg)
	var gun := m.victim.held_gun as RevolverModel
	var across := 0
	while m.shots == 0 and not m.done and across < 60 * 10:
		var head := m._aim_point()
		var from := gun.muzzle.global_position if gun != null else m.victim.global_position + Vector3.UP * 1.2
		var dir := (from - head).normalized()
		leg.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT), head + dir * 0.22)
		across += 1
		await physics_frames(1)
	check(m.shots > 0, "he fires (%s)" % m.result())
	await physics_frames(10)
	check(not m.cheater.wounds.is_empty(), "the ball's in Earl, the leg in the way or not (%s; shots %d)" % [m.cheater.physiology.describe(), m.shots])
	check(m.shots == 1, "the first shot (%d)" % m.shots)
	leg.queue_free()


func test_after_a_shot_they_cry_out_by_turns() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var at := f.cards.centre() + Vector3(0.0, 1.2, 3.0)
	said.clear()
	Events.noise.emit(at, 1.0, &"gunshot", _player())
	Events.shot_fired.emit(at, Vector3.UP, _player())
	await physics_frames(60 * 4)
	var cries := said.filter(func(s: Array) -> bool: return s[1] != "?")
	check(cries.size() >= 1, "someone cries out (%s)" % [cries])
	var ticks := {}
	var texts := {}
	for c: Array in cries:
		ticks[c[0]] = true
		check(not texts.has(c[2]) or int(c[4]) - int(texts[c[2]]) > CivilianBrain.SAME_LINE_MS, "nobody says the same line in the same breath (%s)" % c[2])
		texts[c[2]] = c[4]
	check(cries.size() < 2 or ticks.size() > 1, "not all in the same instant (%s)" % [cries])
	var by := {}
	for c: Array in cries:
		by[c[1]] = int(by.get(c[1], 0)) + 1
	for id: String in by:
		check(by[id] <= 2, "%s says at most two lines in 4 s (%d)" % [id, by[id]])


func test_a_gun_drawn_by_the_table_is_noticed() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var p := _player()
	# Stood by the table, between the bar and it, a while, so they've seen you.
	p.global_position = f.cards.centre() + Vector3(-1.8, 0.0, 0.0)
	# On the bar room's floor (#1304: the street's ground under it put you in the floor, pushed out up or down by luck).
	p.global_position.y = f.floor_under(p.global_position.x, p.global_position.z, f.cards.centre().y) + 0.1
	await physics_frames(60 * 2)
	said.clear()
	Events.deed.emit(p, &"draw", null, p.global_position)
	await physics_frames(20)
	var lines := said.filter(func(s: Array) -> bool: return s[2] in CivilianBrain.LINES[&"gun_out"])
	check(not lines.is_empty(), "someone minds the gun (%s)" % [said])



# --- A reset (#864, review A5) -----------------------------------------------------------------

## The murder's places are the valley folk's: none dropped for a misspelt name.
func test_the_murders_places_are_all_the_folks() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/moments/no_law_murder.json"))
	var names: Array = d.cody.get("in", []) + d.cody.get("out", []) + d.stranger.get("in", [])
	check(names.size() >= 4, "it names its ways (%s)" % [names])
	for n: String in names:
		check(_folk().places.has(StringName(n)), "%s is a place" % n)


## After the murder, Backspace (a fresh start) and the night again: it plays again.
func test_after_a_reset_the_murder_plays_again() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	# What the murder leaves the story (test_the_murder_with_you_sat_at_the_table plays it).
	StoryState.set_fact("nolaw.murder", "done")
	StoryState.set_fact("nolaw.earl", "dead")
	ValleyFolk.murder_auto = true
	await _at(22.0)
	check(_folk().murder == null, "not again in the same game (%s)" % _folk().report())
	GameReset.clear_statics()  # Backspace's, before the reload
	await _new_valley()
	ValleyFolk.murder_auto = false
	await _at(21.0)
	ValleyFolk.murder_auto = true
	await _at(22.0)
	var m := _folk().murder as NoLawMurder
	check(m != null and not m.done, "it plays again (%s)" % _folk().report())
	if m != null:
		m.reset()


## Over before Cody came in (no Earl at the table): nothing written, and it comes again.
func test_a_murder_over_before_it_played_writes_nothing_and_comes_again() -> void:
	ValleyFolk.murder_auto = false
	await _at(12.0)
	var first := _folk().start_murder() as NoLawMurder
	check(first != null and first.done and not first.played, "over before it began (%s)" % (first.result() if first else {}))
	check(not StoryState.has_fact("nolaw.murder"), "nothing in the story")
	var first_id := first.get_instance_id() if first else 0
	ValleyFolk.murder_auto = true
	await _at(21.0)  # its hours yet to come: the spent one's let go
	_folk()._murder_again = 0  # (not a minute's wait)
	await _at(22.0)
	var m := _folk().murder as NoLawMurder
	check(m != null and m.get_instance_id() != first_id and not m.done, "a new one at its hour (%s)" % _folk().report())
	if m != null:
		m.reset()


# --- The hold (SceneHold, #1050) ---------------------------------------------------------------

## An armed man by the table, spoiling for it: while the scene holds, he never takes Cody on (Sean's
## No Law case on #1050: the shooter downed by a townsman before you'd done anything), and the murder
## plays out.
func test_an_armed_townsman_leaves_cody_be_while_its_held() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var p := _player()
	p.global_position = f.cards.centre() + Vector3(30.0, 0.0, 10.0)
	p.global_position.y = f.ground(p.global_position.x, p.global_position.z) + 0.1
	var guard := HumanBody.new()
	guard.person_id = &"guard"
	guard.name = "Guard"
	guard.rng_seed = 1050
	guard.has_gun = true
	var ob := OutlawBrain.new()
	ob.name = "Brain"
	ob.temper = 1.0
	ob.nerve = 99.0
	guard.add_child(ob)
	var at := f.cards.centre() + Vector3(-3.0, 0.0, 1.5)
	at.y = f.ground(at.x, at.z) + 0.05
	valley.add_child(guard)
	guard.global_position = at
	await physics_frames(5)
	var m := f.start_murder() as NoLawMurder
	check(m != null and m.scene_hold != null and m.scene_hold.on, "started, held (%s)" % (m.scene_hold.report() if m and m.scene_hold else {}))
	var on_cody := []
	var watch := func(actor: Node, kind: StringName, target: Node, _w: Vector3) -> void:
		if m.victim != null and target == m.victim and actor != m.victim and kind in [&"shoot_at", &"hit", &"kill"]:
			on_cody.append([String(actor.name), String(kind)])
	Events.deed.connect(watch)
	var cody_in := await wait_until(func() -> bool: return m.victim != null, 60 * 90)
	check(cody_in, "Cody comes in (%s)" % m.result())
	if cody_in:
		ob.relations.provoke(m.victim)  # he's for taking Cody on: the hold keeps him off it
	var over := await wait_until(func() -> bool: return m.done, 60 * 120)
	Events.deed.disconnect(watch)
	var r := m.result()
	check(over and r.end == "done", "it plays out (%s)" % r)
	check(on_cody.is_empty(), "nobody shot at or hit Cody (%s)" % [on_cody])
	check(r.broken == "", "nothing of yours broke it")
	check(StoryState.get_fact("nolaw.murder") == "done" and not m.cheater.wounds.is_empty(), "Earl murdered (%s)" % StoryState.get_fact("nolaw.murder"))
	guard.queue_free()


## Your shot as Cody stands over Earl: it lets go on that frame, the beats stop, Cody's his own man
## (an outlaw's brain) and fights you.
func test_your_shot_breaks_it_and_cody_fights_you() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var p := _player()
	p.global_position = f.cards.centre() + Vector3(6.0, 0.0, 4.0)
	p.global_position.y = f.ground(p.global_position.x, p.global_position.z) + 0.1
	await physics_frames(5)
	var m := f.start_murder() as NoLawMurder
	check(m != null, "started")
	var up := await wait_until(func() -> bool: return m.state in [&"kick", &"after_kick", &"draw", &"approach"], 60 * 120)
	check(up, "Cody's at Earl (%s)" % m.result())
	var hold := m.scene_hold
	var f0 := Engine.get_physics_frames()
	var from := p.global_position + Vector3.UP * 1.5
	Events.noise.emit(from, 1.0, &"gunshot", p)
	Events.shot_fired.emit(from, Vector3.UP, p)
	check(not hold.on and hold.ended_frame == f0 and m.broken_by == &"shot", "let go on the shot's frame (%s)" % hold.report())
	check(m.state == &"after" and m.end_reason == &"broken", "the beats stop (%s)" % m.result())
	var cb := m.victim.get_node_or_null(^"Brain") as OutlawBrain if m.victim else null
	check(cb != null, "Cody has a brain of his own")
	if cb != null:
		var fights := await wait_until(func() -> bool: return cb.mood == OutlawBrain.Mood.FIGHTING and cb.target == p, 60 * 4)
		check(fights, "and fights you (mood %s, target %s)" % [cb.mood, cb.target])
	check(not p.seat.held(), "you're nobody's")
	m.reset()


## Your gun drawn as Cody's at Earl (the playtest's 2026-11-17: he then stood over Earl 40 s doing
## nothing): it lets go, and with nobody to fight he walks out the way he came.
func test_your_drawn_gun_breaks_it_and_cody_walks_out() -> void:
	ValleyFolk.murder_auto = false
	await _at(21.0)
	var f := _folk()
	var p := _player()
	p.global_position = f.cards.centre() + Vector3(6.0, 0.0, 4.0)
	p.global_position.y = f.ground(p.global_position.x, p.global_position.z) + 0.1
	await physics_frames(5)
	var m := f.start_murder() as NoLawMurder
	var up := await wait_until(func() -> bool: return m.state in [&"kick", &"after_kick", &"draw", &"approach"], 60 * 120)
	check(up, "Cody's at Earl (%s)" % m.result())
	Events.deed.emit(p, &"draw", null, p.global_position)
	check(m.broken_by == &"draw" and not m.scene_hold.on, "your gun let it go (%s)" % m.scene_hold.report())
	var cody := m.victim
	var from := cody.global_position
	var went := await wait_until(func() -> bool: return m.events.any(func(e: Array) -> bool: return e[1] == "Cody, let be, walks out"), 60 * 20)
	check(went, "he walks out (%s)" % [m.events.slice(-4)])
	await physics_frames(60 * 6)
	check(not is_instance_valid(cody) or cody.global_position.distance_to(from) > 4.0, "and gets on his way")
	m.reset()


## `-- --mission=no_law` (#1125): it started nothing (no such flag; the bridge's town has no folk).
## Its set-up puts the clock before the murder's hour and you in the yard by the table; the clock
## alone then brings Cody in, as on any first night.
func test_the_mission_flag_sets_up_the_night_and_the_clock_brings_the_murder() -> void:
	var f := _folk()
	f.set_up_no_law(ValleyWorld.NO_LAW_HOUR)
	await physics_frames(1)
	f._look = 0.0
	await physics_frames(60)
	check(absf(_clock().time_of_day - ValleyWorld.NO_LAW_HOUR) < 0.05, "the clock at the start (%.2f)" % _clock().time_of_day)
	check(_player().global_position.distance_to(f.cards.centre()) < 12.0, "you in the yard by the table (%.1f m)" % _player().global_position.distance_to(f.cards.centre()))
	check(f.murder == null, "not yet")
	var earl := f.folk_man(&"earl")
	var sat := await wait_until(func() -> bool: return _chair("w").seated == earl, 60 * 60)
	check(sat, "Earl at the table")
	_clock().set_time(22.0)  # the test clock is held: the hour itself
	var came := await wait_until(func() -> bool: return f.murder != null, 60 * 30)
	check(came, "the clock brought the murder")
	if came:
		var m := f.murder as NoLawMurder
		# The bridge's run of it: the start put you on the stranger's way in, and the scene's hold
		# broke on its first frame ("mark"): it never played.
		var shot := await wait_until(func() -> bool: return m.done or m.shots > 0, 60 * 120)
		check(shot and m.shots > 0, "it plays to Cody's shot (%s)" % m.result())
		check_eq(String(m.broken_by), "", "nothing broke the hold")
