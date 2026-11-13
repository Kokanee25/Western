extends TestCase
## No Law's funeral (#868; Funeral, config/moments/funeral.json, ValleyFolk's `_funeral_step`): the
## town says when it is; the day after the sheriff dies the mourners are at the grave; attended, you
## hear the prayer, the Baron's offer and her refusal, he has a word for you and she thanks you;
## missed, it's said without you and the town says so once; from the lane, it's `distance`; the
## clock past it unseen, the grave's filled. The night's men borrowed for it come to work after.

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


func _at(day: int, h: float, frames := 10) -> void:
	_clock().day = day
	_clock().set_time(h)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(frames)


func _put(at: Vector3, toward := Vector3.INF) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	if toward != Vector3.INF:
		p.rotation.y = atan2(-(toward.x - at.x), -(toward.z - at.z))


## The sheriff died on day 1 (the facts his last day leaves).
func _sheriff_dead() -> void:
	for k: String in ["nolaw.murder", "nolaw.morning", "nolaw.deputy"]:
		StoryState.set_fact(k, "done" if k == "nolaw.murder" else true, 1, 8.0)
	StoryState.set_fact("nolaw.sheriff", "dead", 1, 9.0)


func _grave() -> Vector3:
	var g: Array = valley.folk._funeral_data.grave
	return Vector3(float(g[0]), valley.folk.ground(float(g[0]), float(g[1])), float(g[1]))


func test_attended() -> void:
	await _valley()
	var f := valley.folk
	_sheriff_dead()
	# The day he died: the town knows when.
	await _at(1, 12.0, 70)
	check_eq(StoryState.get_fact("nolaw.funeral_due"), "tomorrow", "the day before")
	check_eq(String(f.line_for("townsman")[0]), "funeral.announce", "the townsman says when (%s)" % [f.line_for("townsman")])
	check(f.funeral == null, "not yet")
	await _at(2, 9.0)
	check_eq(StoryState.get_fact("nolaw.funeral_due"), "today", "that morning")
	# You're up at the grave at its hour.
	var g := _grave()
	_put(g + Vector3(0.0, 0.0, 4.0), g)
	await _at(2, 10.1)
	var m := f.funeral as Funeral
	check(m != null and m.state == &"gather", "the funeral starts by the clock (%s)" % (m.result() if m else {}))
	if m == null:
		return
	m.opts["pace"] = 0.3
	await physics_frames(90)
	# Everyone's there, heads bowed, the day folk and the night's men among them.
	var want := (m.data.mourners as Array).size()
	check_eq(m.men.size(), want, "all the mourners (%s)" % [m.men.keys()])
	var bowed := 0
	var at_spot := 0
	for md: Dictionary in m.data.mourners:
		var man := m.man(StringName(md.id))
		if man == null:
			continue
		if man.pose == &"mourn":
			bowed += 1
		if Funeral._flat(man.global_position, m.spot(md.spot)) < 0.6:
			at_spot += 1
		check(absf(man.global_position.y - g.y) < 0.4, "%s on the ground (%.2f, the grave %.2f)" % [md.id, man.global_position.y, g.y])
	check_eq(at_spot, want, "each at his place by the grave")
	check(bowed >= want - 2, "heads bowed (%d of %d)" % [bowed, want])
	check(m.coffin.visible and not m.filled.visible, "the box by the open grave")
	check(f.folk_man(&"dying_sheriff") == null, "his body isn't at the doctor's any more")
	var over := await wait_until(func() -> bool: return m.done, 60 * 150)
	check(over, "it plays out (%s)" % m.result())
	check_eq(StoryState.get_fact("nolaw.funeral"), "attended", "attended")
	check(_lines_of("preacher").size() == 3 and _lines_of("preacher")[0].begins_with("Man that is born of a woman") and _lines_of("preacher")[2] == "Amen.", "the burial words, the committal, Amen (%s)" % [_lines_of("preacher")])
	check(_lines_of("loudmouth").has("Fined me twice. Fair, both times.") and _lines_of("barkeep").has("He'd come in Saturdays. One drink. Never two."), "two of the town (%s)" % [said])
	check(_lines_of("baron").size() == 2 and _lines_of("baron")[0].begins_with("A hard day, ma'am."), "the Baron's offer (%s)" % [_lines_of("baron")])
	check_eq(_lines_of("baron")[-1] if not _lines_of("baron").is_empty() else "", "Mr. Harlan. A sad day for the county.", "his word to you")
	check_eq(_lines_of("wife"), ["Not today. Not any day.", "You came, Mr. Harlan. He'd have noticed that."], "her refusal, her thanks")
	check_eq(StoryState.get_fact("nolaw.offer_heard"), true, "you heard the offer")
	check_eq(StoryState.get_fact("baron.met"), true, "the Baron's met you")
	check(not m.coffin.visible, "the box is down")
	# The town walks back to work, one by one; the widow stays by the grave.
	await wait_until(func() -> bool: return m._go_at.is_empty(), 60 * 30)
	check(m.man(&"wife") != null and m.man(&"townsman") == null, "the widow stays, the town goes")
	check_eq(String(f.state[&"townsman"]), "coming", "the townsman's on his way back to his post")
	check(m._leaving.has(&"baron") or f.state[&"baron"] == &"out", "the Baron's leaving")
	# Nobody's taken out of the world while you're stood there looking, and the grave stays open.
	_put(m.spot([0.0, 14.0]), m.grave)
	await physics_frames(60 * 12)
	check(m.man(&"miner") != null and m.man(&"barkeep") != null, "they walk off; nobody's gone from near you (%s)" % m.result())
	check(not m.filled.visible, "the grave's open while you're there")
	# You go; they go; the grave's filled.
	_put(f.lot_point("hotel", 4.0, -12.0), f.lot_point("hotel", 4.0, -40.0))  # in the street, your back to the hill
	var gone := await wait_until(func() -> bool: return m.men.is_empty() and m.filled.visible, 60 * 30)
	check(gone, "the hill's empty and the grave filled (%s)" % m.result())
	check(f._waiting.has(&"barkeep") and f._waiting.has(&"wife") and f._waiting.has(&"baron"), "the borrowed and the act's men are back waiting, not freed")
	# That night the barkeep's behind his bar as ever.
	await _at(2, 21.0, 30)
	var bk := f.folk_man(&"barkeep")
	check(bk != null and f.state[&"barkeep"] == &"in" and bk.physiology.alive and bk.get_node_or_null(^"Brain") != null, "the barkeep's at work that night (%s)" % f.report().get("barkeep"))
	check(f.funeral == m and StoryState.get_fact("nolaw.funeral") == "attended", "once only")


func test_missed_and_from_a_distance() -> void:
	await _valley()
	var f := valley.folk
	_sheriff_dead()
	# In town at its hour, by the townsman: he says it's time and walks off up the hill.
	await _at(2, 9.5, 70)
	var tm := f.folk_man(&"townsman")
	check(tm != null, "the townsman's at his post")
	if tm == null:
		return
	f._said_n["funeral.announce_today"] = 1
	_put(tm.global_position + Vector3(2.0, 0.0, 6.0), tm.global_position)
	var m := f.start_funeral({"pace": 0.1}) as Funeral
	await physics_frames(5)
	check(_lines_of("townsman").has("It's time. They're burying him now, up the hill."), "it's time (%s)" % [said])
	check(m.man(&"townsman") == tm and Funeral._flat(tm.global_position, m.grave) > 100.0, "he walks: not gone from under your eyes")
	said.clear()
	var over := await wait_until(func() -> bool: return m.done, 60 * 90)
	check(over, "it's said without you (%s)" % m.result())
	check_eq(StoryState.get_fact("nolaw.funeral"), "missed", "missed")
	check_eq(said, [], "nothing heard from town")
	check_eq(StoryState.get_fact("nolaw.offer_heard"), false, "the offer not heard")
	check(not StoryState.has_fact("baron.met"), "the Baron hasn't met you")
	check_eq(String(f.line_for("townsman")[0]), "funeral.missed", "the town says so, once (%s)" % [f.line_for("townsman")])
	m.reset()
	await physics_frames(3)
	check(f.state[&"baron"] == &"out" and f._waiting.has(&"baron"), "taken back")
	# Again, watched from down the lane: seen, not near.
	StoryState.clear("nolaw.funeral")
	StoryState.clear("nolaw.offer")
	var g := _grave()
	_put(g + Vector3(6.0, 0.0, 30.0), g)
	m = f.start_funeral({"pace": 0.1}) as Funeral
	check(m._in_sight(_player().global_position), "the grave's in sight from the lane")
	over = await wait_until(func() -> bool: return m.done, 60 * 90)
	check(over and StoryState.get_fact("nolaw.funeral") == "distance", "from a distance (%s)" % m.result())
	check(_lines_of("baron").is_empty() and _lines_of("wife").is_empty(), "too far to hear the offer (%s)" % [said])
	check_eq(String(f.line_for("townsman")[0]), "funeral.distance", "the town saw you stand off (%s)" % [f.line_for("townsman")])


func test_the_clock_past_it() -> void:
	await _valley()
	var f := valley.folk
	_sheriff_dead()
	await _at(3, 8.0)
	var m := f.funeral as Funeral
	check(m != null and m.done and m.filled.visible and m.men.is_empty(), "buried without you (%s)" % (m.result() if m else {}))
	check_eq(StoryState.get_fact("nolaw.funeral"), "missed", "missed")
