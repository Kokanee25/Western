extends TestCase
## No Justice step 3 (#934; NoJusticeHideout, config/moments/no_justice_hideout.json): from the Ute
## camp's trail, the ride's card to the slope above the gang's line shack; Joe's closeness, warning,
## count and ask; the crew about their fire; the alarm (your shot first is `opened`); Kett breaking
## for the shack, yelled after and called by Joe, the door shut and barred; a win with Joe in it; Joe
## down but not dead; Kett shot outside ("That was mine to take."); the last man's quitting line.

var holder: Node
var valley: ValleyWorld
var said: Array = []  # [speaker id, text]


func before_each() -> void:
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


func _all_lines() -> Array:
	return said.map(func(s: Array) -> String: return s[1])


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _put(at: Vector3) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO


## The valley, the act started (`arrive`: on the slope above the hideout, the ride done).
func _start(opts := {}) -> NoJusticeHideout:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var o := {"set_up": true, "pace": 0.25, "no_next": true}
	o.merge(opts, true)
	var m := Moment.start_named(&"no_justice_hideout", valley, null, o) as NoJusticeHideout
	check(m != null and not m.done, "it starts (%s)" % (m.result() if m else {}))
	return m


## A ball from `from` at `to`, fired by `shooter`.
func _shoot(from: Vector3, to: Vector3, shooter: Node) -> void:
	var bal := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var t: RevolverTuning = load("res://config/revolver.tres")
	var exclude: Array[RID] = []
	if shooter is CollisionObject3D:
		exclude.append((shooter as CollisionObject3D).get_rid())
	Events.shot_fired.emit(from, (to - from).normalized(), shooter)
	var b := bal.fire(from, (to - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, exclude)
	b.shooter = shooter
	await wait_until(func() -> bool: return not b.alive, 60)


## You 30 m off their fire on the slope, a shot of yours into the dirt by it: the alarm, opened by you.
func _open_fire(m: NoJusticeHideout) -> void:
	_put(m.spot([-26.0, -6.0]))
	await physics_frames(20)
	var p := _player()
	await _shoot(p.global_position + Vector3.UP * 1.5, m.spot([-4.0, -3.0]), p)
	var on := await wait_until(func() -> bool: return m.alarm_t >= 0.0, 60 * 3)
	check(on, "the alarm (%s)" % m.result())
	# Back up the slope out of their range (five men on you in the open put you down: it's Joe's fight
	# and Kett's run these tests are about).
	_put(m.spot([-120.0, -45.0]))


func _kill_crew(m: NoJusticeHideout, leave := 0) -> void:
	var k := 0
	for g: Dictionary in m.crew:
		if k >= m.crew.size() - leave:
			break
		var man := g.man as HumanBody
		if is_instance_valid(man) and man.physiology.alive:
			man.physiology._die(&"heart")
		k += 1


func test_from_the_camps_trail_the_ride_to_the_slope_above_the_hideout() -> void:
	var m := await _start()
	if m == null:
		return
	check_eq(m.state, &"trail", "on the trail from the camp")
	check(m.joe_brain.costume and not m.joe_brain.held, "Joe with you, in the cowboy's hat")
	var p := _player()
	var place := ValleyLayout.main().place_at("ute_community")
	check(Vector2(p.global_position.x, p.global_position.z).distance_to(place) < 60.0, "you start at the Ute camp")
	var c := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	var was := c.time_of_day if c else 0.0
	var to := (m.centre - p.global_position)
	to.y = 0.0
	# Not the other way (the playtest: any walk took you there).
	_put(p.global_position - to.normalized() * 26.0)
	m.joe.global_position = p.global_position + Vector3(1.5, 0.0, 0.0)
	await physics_frames(30)
	check_eq(m.state, &"trail", "walking away from their trail isn't following it")
	_put(m._trail_from + to.normalized() * 26.0)
	m.joe.global_position = p.global_position + Vector3(1.5, 0.0, 0.0)
	var rode := await wait_until(func() -> bool: return m.state == &"ride", 60 * 3)
	check(rode, "on along it, the ride's card (%s)" % m.result())
	check(m.ride_s > 400.0 and m.ride_s < 2400.0, "the ride takes 7-40 minutes (%.0f s)" % m.ride_s)
	var there := await wait_until(func() -> bool: return m.state in [&"approach", &"watch"], 60 * 6)
	check(there, "come in (%s)" % m.result())
	check(p.input_enabled, "your hands back after the card")
	check(Vector2(p.global_position.x, p.global_position.z).distance_to(Vector2(m.centre.x, m.centre.z)) < 120.0, "on the slope above the hideout")
	check(p.global_position.y > m.centre.y + 2.0, "above it (%.1f m over the pad)" % (p.global_position.y - m.centre.y))
	if c:
		check(c.time_of_day > was + 0.1, "the clock on by the ride (%.2f -> %.2f h)" % [was, c.time_of_day])
	check(m.shack != null and m.props.size() >= 8 and m.crew.size() == 5 and m.kett != null, "the shack, the props, five men and Kett (%s)" % m.result())
	check(not m.kett.has_gun, "Kett carries no gun")
	await wait_until(func() -> bool: return _lines_of("joe").has("When I find him, you will not like what I do. Better you know it now."), 60 * 6)
	check(_lines_of("joe").has("Fresh. We are close."), "Joe: close (%s)" % [_lines_of("joe")])
	check(_lines_of("joe").has("When I find him, you will not like what I do. Better you know it now."), "Joe's warning")


func test_on_the_slope_joe_counts_them_and_asks_how() -> void:
	var m := await _start({"arrive": true})
	if m == null:
		return
	await physics_frames(10)
	_put(m.spot(m.data.watch))
	var asked := await wait_until(func() -> bool: return _lines_of("joe").has("How do you want it? Quiet, or now?") or m.alarm_t >= 0.0, 60 * 12)
	check(asked, "to the ask (%s)" % m.result())
	check(_lines_of("joe").has("Five. Six. There. By the fire. The red shirt."), "he counts them (%s)" % [_lines_of("joe")])
	if m.alarm_t < 0.0:
		check(_lines_of("joe").has("How do you want it? Quiet, or now?"), "and asks how you want it")
		check(m.crew.all(func(g: Dictionary) -> bool: return (g.brain as OutlawBrain).mood == OutlawBrain.Mood.CALM), "they're easy at their camp")


func test_you_open_fire_and_the_red_shirt_bars_himself_in() -> void:
	var m := await _start({"arrive": true})
	if m == null:
		return
	await physics_frames(10)
	await _open_fire(m)
	check_eq(StoryState.get_fact("nojustice.started"), "opened", "you started it")
	check(_all_lines().has("We got company!") or _all_lines().has("Riders! On the hill!"), "the alarm called (%s)" % [_all_lines()])
	var ran := await wait_until(func() -> bool: return m.kett_state != "", 60 * 3)
	check(ran, "Kett breaks (%s)" % m.result())
	check(_all_lines().has("Red! Where you going? Red, you yellow son of a bitch!"), "yelled after")
	check(_lines_of("joe").has("The red shirt. He runs."), "Joe calls it")
	var holed := await wait_until(func() -> bool: return m.kett_state == NoJusticeHideout.HOLED_UP, 60 * 20)
	check(holed, "in the shack (%s)" % m.result())
	check(m.in_shack(m.kett.global_position), "inside its walls")
	check(m.shack.door_shut, "the door shut")
	check(m.shack.get_member(&"hideout_shack/front/door_bar") != null, "and barred")
	check(m.shack.get_member(&"hideout_shack/front/door") == null, "the open leaf gone")
	check_eq(StoryState.get_fact("nojustice.kett"), "holed_up", "nojustice.kett")


func test_a_win_with_joe() -> void:
	var m := await _start({"arrive": true})
	if m == null:
		return
	await physics_frames(10)
	# Joe told to wait on the brow, 25 m off their fire (G): he holds there and fights while you're back.
	m.joe.global_position = m.spot([-24.0, -4.0], 0.05)
	check_eq(m.joe_brain.told(_player()), "\"Wait here.\"", "Joe waits")
	await _open_fire(m)
	# The fight a while, then the crew down.
	await wait_until(func() -> bool: return m.kett_state == NoJusticeHideout.HOLED_UP, 60 * 20)
	await physics_frames(60 * 6)
	check(is_instance_valid(m.joe_brain) and (m.joe_brain._fight_on or m.shots.joe > 0), "Joe's in it (%s)" % m.result())
	_kill_crew(m)
	var over := await wait_until(func() -> bool: return m.done, 60 * 20)
	check(over, "it ends (%s)" % m.result())
	check_eq(StoryState.get_fact("nojustice.hideout"), "fought", "nojustice.hideout")
	check_eq(StoryState.get_fact("nojustice.kett"), "holed_up", "Kett in the shack for step 4")
	var crew: Variant = StoryState.get_fact("nojustice.crew")
	check(crew is Dictionary and int(crew.dead) == 5, "the crew's tally (%s)" % [crew])
	check_eq(StoryState.get_fact("nojustice.seen"), false, "nobody got away")
	check(m.joe.physiology.alive, "Joe alive")


func test_joe_down_but_not_dead() -> void:
	var m := await _start({"arrive": true})
	if m == null:
		return
	await physics_frames(10)
	await _open_fire(m)
	var jp := m.joe.physiology
	jp._die(&"brain")  # a killing wound: down, spared
	check(jp.alive and not jp.is_conscious(), "Joe down, not dead (%s)" % jp.cause_of_death)
	await wait_until(func() -> bool: return m.kett_state == NoJusticeHideout.HOLED_UP, 60 * 20)
	_kill_crew(m)
	var over := await wait_until(func() -> bool: return m.done, 60 * 20)
	check(over, "it ends (%s)" % m.result())
	check(jp.alive, "Joe alive at the end")
	check_eq(StoryState.get_fact("nojustice.joe"), "down", "nojustice.joe")
	var up := await wait_until(func() -> bool: return is_instance_valid(m.joe) and jp.is_conscious() and not m.joe.limp, 60 * 30)
	check(up, "he comes to and gets up after it")


func test_the_red_shirt_shot_outside_is_joes_to_take() -> void:
	var m := await _start({"arrive": true})
	if m == null:
		return
	await physics_frames(10)
	await _open_fire(m)
	await wait_until(func() -> bool: return m.kett_state == "running", 60 * 3)
	var p := _player()
	var head := (m.kett.parts[&"head"] as Node3D).global_position
	await _shoot(head + (p.global_position - head).normalized() * 3.0, head, p)
	if m.kett.physiology.alive:
		m.kett_killer = p
		m.kett.physiology._die(&"brain")  # the ball found no brain: the test's killing wound
	var dead := await wait_until(func() -> bool: return m.kett_state == NoJusticeHideout.DEAD_OUTSIDE, 60 * 2)
	check(dead, "dead outside (%s)" % m.result())
	check(_lines_of("joe").has("That was mine to take."), "Joe: mine to take (%s)" % [_lines_of("joe")])
	check_eq(StoryState.get_fact("nojustice.kett"), "dead_outside", "nojustice.kett")


func test_the_last_mans_nerve_breaks_in_the_scripts_words() -> void:
	var m := await _start({"arrive": true})
	if m == null:
		return
	await physics_frames(10)
	await _open_fire(m)
	_kill_crew(m, 1)
	await physics_frames(30)
	var last: Dictionary = m.crew[m.crew.size() - 1]
	var b := last.brain as OutlawBrain
	if b.mood != OutlawBrain.Mood.SURRENDERED:
		b._said_at = -INF
		b._surrender()
	check(_lines_of(String(last.id)).has("I'm done! Don't shoot!"), "the last man quits in the script's words (%s)" % [_lines_of(String(last.id))])
	var others := m.crew.slice(0, m.crew.size() - 1)
	check(not others.any(func(g: Dictionary) -> bool: return _lines_of(String(g.id)).has("I'm done! Don't shoot!")), "and only he")


## Shot down in the fight (#979's playtest: a dead end): you come round at the doctor's free to walk
## off (not boxed in on the bedside chair), and the way to try it again is put to you.
func test_down_in_the_fight_you_come_round_free_and_can_try_again() -> void:
	var m := await _start({"arrive": true})
	if m == null:
		return
	await physics_frames(10)
	await _open_fire(m)
	var p := _player()
	var shown: Array = []
	p.wounds.shown.connect(func(text: String) -> void: shown.append(text))
	p.set_meta(&"last_hit_by", (m.crew[0] as Dictionary).man)
	p.wounds.physiology._die(&"heart")
	var down := await wait_until(func() -> bool: return m.done, 60 * 3)
	check(down and m.state == &"you_down", "the act's lost (%s)" % m.result())
	var up := await wait_until(func() -> bool: return p.wounds.physiology.is_conscious(), 60 * 10)
	check(up, "you come round")
	await physics_frames(10)
	var doc: Node3D = valley.buildings.get("doctor")
	check(doc != null and Vector2(p.global_position.x - doc.global_position.x, p.global_position.z - doc.global_position.z).length() < 15.0, "at the doctor's (%s)" % p.global_position)
	check(p.can_stand(), "room to stand")
	# Out across the floor (the chair's legs, the wall and the cot boxed you in): two ways of the four
	# compass ones, a metre or more (the sick room's small, its door shut).
	var start := p.global_position
	var free := 0
	for act: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right"]:
		p.global_position = start
		p.velocity = Vector3.ZERO
		p.rotation.y = 0.0
		await physics_frames(2)
		var ev := InputEventAction.new()
		ev.action = act
		ev.pressed = true
		ev.strength = 1.0
		Input.parse_input_event(ev)
		await physics_frames(60)
		var off := InputEventAction.new()
		off.action = act
		off.pressed = false
		Input.parse_input_event(off)
		await physics_frames(2)
		if p.global_position.distance_to(start) > 1.0:
			free += 1
	check(free >= 2, "you walk off two ways of four (%d)" % free)
	var told := await wait_until(func() -> bool: return shown.has(String(m.data.prompts.retry)), 60 * 25)
	check(told, "the retry put to you (%s)" % [shown])
	check(not NoJusticeHideout.retry_on_load, "not till you press it")


## The retry's reload: the valley starts the hideout again on the slope above it, whatever mission
## the game was started on, and only once.
func test_the_retry_starts_it_again_on_the_slope() -> void:
	NoJusticeHideout.retry_on_load = true
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(12)
	check(not NoJusticeHideout.retry_on_load, "the flag's spent")
	var ms := get_tree().get_nodes_in_group(&"moment").filter(func(n: Node) -> bool: return n is NoJusticeHideout)
	check(ms.size() == 1, "one hideout act (%d)" % ms.size())
	if ms.size() == 1:
		var m := ms[0] as NoJusticeHideout
		check(m.state in [&"approach", &"watch"], "on the slope above it (%s)" % m.result())
		check(m.crew.size() == 5 and m.kett != null and m.joe != null, "the crew, Kett and Joe")
		m.opts["no_next"] = true
