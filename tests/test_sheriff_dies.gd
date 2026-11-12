extends TestCase
## No Law's morning after and the sheriff's last day (#796; ValleyFolk's `morning` and `talk`,
## SheriffDies, config/moments/sheriff_dies.json): the story's facts read for the day folk's lines;
## the murder done and the clock round to the day, Earl's body to the undertaker's (a recorded
## death) and the folk telling it by what you saw; the sheriff dying on the doctor's cot, his wife by
## him, each answer (a nod; a shake, which comes to the same), his revolver yours, and he dies.

var holder: Node
var valley: ValleyWorld
var said: Array = []  # [speaker id, text]


func before_each() -> void:
	ValleyFolk.murder_auto = true
	StoryState.clear()
	said.clear()
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)


func after_each() -> void:
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)
	Input.action_release(&"shove")
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _on_spoke(who: Node, text: String) -> void:
	said.append([String((who as HumanBody).person_id) if who is HumanBody else "?", text])


func _lines_of(id: String) -> Array:
	return said.filter(func(s: Array) -> bool: return s[0] == id).map(func(s: Array) -> String: return s[1])


func _valley() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _clock() -> DayCycle:
	return valley.get_node(^"DayCycle") as DayCycle


func _at(h: float, frames := 60) -> void:
	_clock().set_time(h)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(frames)


func _put(at: Vector3) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO


func _nod(p: Player) -> void:
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(0.0, -12.0 * k - p.get_pitch_degrees()))
		await physics_frames(3)


func _shake(p: Player) -> void:
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(12.0 * k, 0.0))
		await physics_frames(3)


func test_the_story_s_facts_choose_the_lines() -> void:
	StoryState.set_fact("nolaw.morning", true)
	StoryState.set_fact("nolaw.seen_from", "yard")
	check(ValleyFolk.story_holds({"nolaw.morning": true}), "a fact's value")
	check(not ValleyFolk.story_holds({"nolaw.seen_from": "table"}), "another value")
	check(ValleyFolk.story_holds({"nolaw.seen_from": ["table", "yard"]}), "one of a list")
	check(ValleyFolk.story_holds({"nolaw.seen_from": "*"}), "set at all")
	check(not ValleyFolk.story_holds({"!nolaw.morning": true}), "not set")
	check(ValleyFolk.story_holds({"!nolaw.sheriff": true}), "not set: holds")
	check(not ValleyFolk.story_holds({"sheriff.care": "*"}), "unset fact")


func test_the_morning_after() -> void:
	ValleyFolk.murder_auto = false
	await _valley()
	var f := valley.folk
	# The night: Earl at the table, shot dead (the murder's own test plays it; here his end only).
	await _at(21.0)
	var earl := f.folk_man(&"earl")
	check(earl != null, "Earl at the table")
	earl.physiology._die(&"blood_loss")
	earl.go_limp()
	await physics_frames(2)
	f._look = 0.0
	await physics_frames(2)
	check_eq(String(f.state[&"earl"]), "dead", "Earl dead to the folk")
	StoryState.set_fact("nolaw.murder", "done")
	StoryState.set_fact("nolaw.seen_from", "table")
	StoryState.set_fact("nolaw.earl", "dead")
	ValleyFolk.murder_auto = true
	# You stood over him as the clock runs on: he isn't taken from under your eyes.
	_put(ValleyFolk._body_at(earl) + Vector3(-3.0, 0.0, 0.0))
	_player().rotation.y = atan2(-1.0, 0.0)  # facing +x, toward him
	await _at(6.0, 10)
	check_eq(StoryState.get_fact("nolaw.morning"), true, "the morning after")
	check(f.folk_man(&"earl") == earl and is_instance_valid(earl), "his body's still there while you look at it")
	# Off down the street: he's taken to the undertaker's.
	var hotel := f.lot_point("hotel", 4.0, -1.0)
	_put(hotel + Vector3(2.0, 0.0, 12.0))  # out in the street, off them both
	await _at(7.0, 10)
	check(f.folk_man(&"earl") == null and f.gone_for_good.has(&"earl"), "Earl gone to the undertaker's (%s)" % f.state.get(&"earl"))
	check_eq(StoryState.get_fact("nolaw.earl"), "undertaker", "a recorded death")
	check(String(StoryState.get_fact("death.earl", "")).contains("Cody"), "his record names Cody")
	# The townsman at the hotel tells you what you saw, then the town's version.
	# (Come in with the clock: he walks to his post on the hotel's walk.)
	await wait_until(func() -> bool: return f.state.get(&"townsman") == &"in" and f.state.get(&"undertaker") == &"in", 60 * 30)
	var tm := f.folk_man(&"townsman")
	check(tm != null and f.state[&"townsman"] == &"in", "the townsman at his post by day (%s)" % f.report().get("townsman"))
	if tm == null:
		return
	_put(tm.global_position + Vector3(1.5, 0.0, 1.0))
	f._spoke_at.clear()
	f._look = 0.0
	await physics_frames(4)
	check_eq(_lines_of("townsman"), ["You were sat right there at the table, they say. And you never moved."], "you were at the table")
	f._spoke_at.clear()
	f._look = 0.0
	await physics_frames(4)
	check(_lines_of("townsman").size() == 2 and _lines_of("townsman")[1].begins_with("Cody shot Earl dead"), "then the town's version (%s)" % [_lines_of("townsman")])
	# Not again straight away.
	f._look = 0.0
	await physics_frames(4)
	check_eq(_lines_of("townsman").size(), 2, "a gap between lines")
	# The undertaker has Earl laid out; nobody arrests Cody.
	var ut := f.folk_man(&"undertaker")
	if ut:
		_put(ut.global_position + Vector3(1.5, 0.0, 1.0))
		f._look = 0.0
		await physics_frames(4)
		check(_lines_of("undertaker").any(func(l: String) -> bool: return l.begins_with("Earl. Shot through the head")), "the undertaker's line (%s)" % [_lines_of("undertaker")])
	check(not StoryState.has_fact("nolaw.cody_arrested"), "nobody arrests Cody")
	# Its hour: the sheriff's last day starts.
	await _at(8.0, 10)
	check(f.sheriff_scene != null and StoryState.get_fact("nolaw.sheriff") == "dying", "the sheriff's last day starts (%s)" % StoryState.get_fact("nolaw.sheriff"))


## The scene from its start (the bridge's way: the morning set up), you walked to the doctor's door,
## led in, by the cot; returns the act.
func _to_the_room(care: String) -> SheriffDies:
	await _valley()
	var f := valley.folk
	var m := f.start_sheriff_dies({"set_up": true, "care": care, "pace": 0.25}) as SheriffDies
	check(m != null and not m.done, "it starts (%s)" % (m.result() if m else {}))
	if m == null or m.done:
		return null
	var p := _player()
	check(not p.carries(p.revolver()), "Harlan's unarmed")
	await physics_frames(5)
	# The runner comes to you on Main Street.
	var came := await wait_until(func() -> bool: return m.state == &"go", 60 * 40)
	check(came and _lines_of("runner").size() == 1, "the doctor's runner finds you (%s, %s)" % [m.state, said])
	# To the doctor at his door: his line by care; he leads you in.
	_put(m.doctor.global_position + (m._local([4.71, -4.0]) - m.doctor.global_position).normalized() * 2.0)
	var led := await wait_until(func() -> bool: return m.state == &"lead", 60 * 3)
	check(led and _lines_of("doc").size() == 1, "the doctor at his door (%s)" % [_lines_of("doc")])
	# You follow him in (put by the cot's side: walking the hall is the playtest's).
	await physics_frames(60 * 4)
	_put(m._local(m.data.you_spot))
	var cot := m.cot
	var in_room := await wait_until(func() -> bool: return m.state == &"room", 60 * 3)
	check(in_room, "by the cot (%s)" % m.result())
	check(m.sheriff != null and m.sheriff.pose == &"on_back" and not m.sheriff.limp, "on his back on the cot (%s)" % m.result().get("sheriff"))
	var top := cot.global_transform * Vector3(0.0, 0.55, 0.0)
	check(absf(m.sheriff.global_position.y - top.y) < 0.1 and m.sheriff.global_position.distance_to(cot.global_position) < 1.3, "on the cot, not the floor")
	check(m.chair.seated == m.wife, "his wife sat by him")
	check(m.sheriff.physiology.is_conscious(), "awake")
	return m


func _answer_and_end(m: SheriffDies, how: String) -> void:
	var p := _player()
	var asked := await wait_until(func() -> bool: return m._wait == &"answer" or m._wait == &"hold", 60 * 60)
	check(asked, "to your part (%s)" % m.result())
	if m._wait == &"hold":
		Input.action_press(&"shove")
		var held := await wait_until(func() -> bool: return m._wait != &"hold", 60 * 6)
		Input.action_release(&"shove")
		check(held and m.held_him, "E: you hold him while Doc works")
		asked = await wait_until(func() -> bool: return m._wait == &"answer", 60 * 30)
		check(asked, "to the oath")
	check(not p.carries(p.revolver()), "no gun yet")
	if how == "nod":
		await _nod(p)
	elif how == "shake":
		await _shake(p)
	var over := await wait_until(func() -> bool: return m.done, 60 * 120)
	check(over, "it plays out (%s)" % m.result())


func test_he_dies_and_you_nod() -> void:
	var m := await _to_the_room("good")
	if m == null:
		return
	await _answer_and_end(m, "nod")
	check_eq(m.answer, "nod", "you nod")
	var sl := _lines_of("dying_sheriff")
	check(sl.has("Faded red shirt. I'd know him again. You find him, Harlan."), "clear: the red shirt (%s)" % [sl])
	check(sl.has("Good. You're my deputy. Doc, you heard him."), "the nod's line")
	check(not sl.has("That's not the way this works, son. ... Doc. Pin it on him."), "not the shake's")
	check(sl.has("Sun's up. Ain't that something."), "his last words")
	check(_lines_of("wife").has("He said it was you that brought him. I'm obliged to you, Mr. Harlan."), "his wife's thanks")
	check(not _lines_of("doc").any(func(l: String) -> bool: return l.begins_with("Hold him")), "packed well: no holding him")
	_after(m)


func test_shake_your_head_and_you_get_it_anyway() -> void:
	var m := await _to_the_room("poor")
	if m == null:
		return
	await _answer_and_end(m, "shake")
	check_eq(m.answer, "shake", "you shake your head")
	var sl := _lines_of("dying_sheriff")
	check(sl.has("...not how it works... son."), "fading: that's not how it works (%s)" % [sl])
	check(sl.has("...boot."), "his last word")
	check(_lines_of("doc").any(func(l: String) -> bool: return l.begins_with("Hold him")), "Doc has you hold him")
	_after(m)


## Either way: deputy, the revolver yours, he's dead of his wound on the cot, the facts.
func _after(m: SheriffDies) -> void:
	var p := _player()
	check(p.carries(p.revolver()), "the revolver's yours")
	check_eq(StoryState.get_fact("nolaw.revolver"), "given", "nolaw.revolver")
	check_eq(StoryState.get_fact("nolaw.accepted"), m.answer, "nolaw.accepted")
	check_eq(StoryState.get_fact("nolaw.deputy"), true, "deputy either way")
	check_eq(StoryState.get_fact("nolaw.sheriff"), "dead", "nolaw.sheriff")
	check_eq(StoryState.get_fact("nolaw.acting"), "doctor", "Doc's the law")
	var s := m.sheriff
	check(s != null and not s.physiology.alive and s.physiology.cause_of_death == &"gut_wound", "he dies of his wound (%s)" % (s.physiology.cause_of_death if s else &""))
	check(s != null and not s.limp and s.pose == &"on_back", "where he lay (%s)" % m.result().get("sheriff"))
	check(_lines_of("doc").has("He's gone, ma'am."), "Doc: he's gone")
	check(_lines_of("wife").has("I'll sit with him now. Go on, the both of you."), "his wife stays with him")
