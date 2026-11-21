extends TestCase
## The chaos playtest's faults (#1116; docs/playtests/2026-11-20-chaos.md) and Sean's answers on #1114:
## Joe down at the hideout gets up with your first aid and limps in, the cabin waiting for him.

var holder: Node
var valley: ValleyWorld
var said: Array = []  # [speaker id, text]


func before_each() -> void:
	StoryState.clear()
	said.clear()
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)


func after_each() -> void:
	Input.action_release(&"shove")
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)
	StoryState.clear()
	var p := _player()
	if p:
		p.input_enabled = true
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _on_spoke(who: Node, text: String) -> void:
	said.append([String((who as HumanBody).person_id) if who is HumanBody else "?", text])


func _lines_of(id: String) -> Array:
	return said.filter(func(s: Array) -> bool: return s[0] == id).map(func(s: Array) -> String: return s[1])


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _put(at: Vector3, look_at := Vector3.INF) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	if look_at != Vector3.INF:
		var to := look_at - at
		p.rotation.y = atan2(-to.x, -to.z)


func _start_cabin(opts := {}) -> NoJusticeCabin:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var o := {"set_up": true, "pace": 0.25}
	o.merge(opts, true)
	var m := Moment.start_named(&"no_justice_cabin", valley, null, o) as NoJusticeCabin
	check(m != null and not m.done, "it starts (%s)" % (m.result() if m else {}))
	return m


## A .45 through his right thigh from the side, the femur broken: down, awake, can't stand.
func _down_joe(m: NoJusticeCabin) -> void:
	var joe := m.joe
	var t: RevolverTuning = load("res://config/revolver.tres")
	var thigh := joe.parts[&"thigh_r"] as Node3D
	var dir := -joe.global_basis.x
	joe.take_bullet(thigh, thigh.global_position - dir * 0.15, dir, 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity,
			t.bullet_diameter * 0.5, t.bullet_mass, 5.0)
	joe.physiology.broken[&"femur_r"] = true
	if not joe.limp:
		joe.go_limp()


func test_joe_down_gets_up_with_first_aid_and_the_cabin_waits() -> void:
	var m := await _start_cabin()
	if m == null:
		return
	var joe := m.joe
	_down_joe(m)
	await physics_frames(90)
	check(m.joe_down() and not joe.physiology.can_stand(), "Joe's down and can't stand (%s)" % joe.physiology.broken.keys())
	# The door in (three sound kicks' worth) and you in: Kett gives up; the knife waits for Joe.
	var door := Vector3(m.shack.door_rect.get_center().x, 0.9, 0.0)
	for i in 3:
		m._on_kick({"move": &"kick", "what": &"wall", "speed": _player().shove.tuning.kick_speed, "mass": 28.0,
				"at": m.shack.global_transform * door, "result": &"held"})
	_put(m._local([2.1, 1.3]), m.kett.global_position)
	await physics_frames(10)
	_put(m._local([3.5, 2.4]), m.kett.global_position)
	var gave := await wait_until(func() -> bool: return m.state == &"in", 60 * 5)
	check(gave, "Kett gives up (%s)" % m.result())
	await physics_frames(60 * 20)
	check_eq(m.state, &"in", "no knife and no ask while Joe's down out there (%s)" % m.result())
	check(m.knife == null, "no knife drawn")
	# A tap of E isn't it (it's the carry's); a held E by his wound is.
	_put(m._joe_wound_at() + m.shack.global_basis.x * 0.8, m._joe_wound_at())
	await physics_frames(30)
	check(_player().carry.claims_use(_player()) or m.claims_use(_player()), "E's for him here")
	Input.action_press(&"shove")
	var bound := await wait_until(func() -> bool: return m.aided, 60 * 10)
	Input.action_release(&"shove")
	check(bound, "a held E by his wound binds him (%s)" % [m.timeline.slice(-3)])
	check(not _player().carry.carrying(), "you didn't take him up (no carry: Sean)")
	check(_player().shove.move == &"", "and letting go of E didn't kick")
	var ph := joe.physiology
	check(ph.splinted.has("r") and ph.broken.has(&"femur_r"), "his leg splinted, the bone still broken (the wound stays)")
	check(ph.bleeds.all(func(b: Dictionary) -> bool: return b.get("kind", &"ooze") == &"internal" or b.get(&"bandaged", false)), "every outside bleed bound")
	check(ph.can_stand(), "he can stand on it")
	var up := await wait_until(func() -> bool: return not joe.limp and not joe.rising and not joe.prone, 60 * 15)
	check(up, "he gets up himself")
	check(_lines_of("joe").has("It's all right. I can walk."), "\"It's all right. I can walk.\" (%s)" % [_lines_of("joe")])
	check(ph.leg_power("r") <= Physiology.SPLINTED_LEG, "he limps on it (%.2f)" % ph.leg_power("r"))
	_put(m._local([3.5, 2.4]), m.kett.global_position)
	var asked := await wait_until(func() -> bool: return m.state == &"ask", 60 * 90)
	check(asked, "he limps in and asks (%s)" % m.result())
	check(m.hideout.in_shack(joe.global_position) or m._flat(joe.global_position, m.kett.global_position) < 3.0,
			"asked from inside, by Kett (%s)" % m.result())


## A ball from you at `man`'s `seg` (your shot heard as the bridge's is: shot_fired, then the ball).
func _your_ball(man: HumanBody, seg: StringName) -> void:
	var p := _player()
	var t: RevolverTuning = load("res://config/revolver.tres")
	var from := p.camera.global_position
	var to := (man.parts[seg] as Node3D).global_position
	Events.shot_fired.emit(from, (to - from).normalized(), p)
	var exclude: Array[RID] = [p.get_rid()]
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var b := ballistics.fire(from, (to - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, exclude)
	b.shooter = p
	await wait_until(func() -> bool: return not b.alive, 60)


## The chaos round's 1 (2 of 2): in No Justice's start Joe took two of your balls and stayed `calm`,
## the doctor stood. Held by the scene isn't deaf to a gun.
func test_joe_and_the_doctor_answer_your_shots() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var m := Moment.start_named(&"no_justice_camp", valley, null, {"set_up": true, "pace": 0.25}) as NoJusticeCamp
	check(m != null and not m.done, "it starts")
	if m == null or m.done or m.doctor == null:
		return
	var joe := m.joe
	var doctor := m.doctor
	_put(joe.global_position + (m._local([4.71, -1.2]) - joe.global_position).normalized() * 2.2, joe.global_position + Vector3.UP * 1.3)
	await physics_frames(20)
	check(m.hold != null and m.hold.on, "the office held as a scene")
	await _your_ball(joe, &"upper_arm_l")
	await physics_frames(5)
	check(not m.hold.on, "your shot breaks it (%s)" % m.hold.report())
	check(doctor.get_node_or_null(^"Brain") is CivilianBrain, "the doctor has a mind of his own again")
	var ducked := await wait_until(func() -> bool: return joe.pose == &"duck", 60)
	check(ducked, "Joe ducks (%s)" % joe.pose)
	check(_lines_of("joe").any(func(l: String) -> bool: return l in ["Harlan. That was me.", "Careful. I am on your side.", "Harlan! Stop!", "Stop. It is me."]),
			"and tells you (%s)" % [_lines_of("joe")])
	var cb := doctor.get_node(^"Brain") as CivilianBrain
	var reacts := await wait_until(func() -> bool: return cb.mood != CivilianBrain.Mood.CALM, 60 * 3)
	check(reacts, "the doctor takes it (%s)" % cb.describe())
	var talk := m._beat
	await physics_frames(60 * 4)
	check_eq(m._beat, talk, "no talk under fire")
	# Keep on: he's done telling you.
	await physics_frames(30)
	await _your_ball(joe, &"forearm_l")
	await physics_frames(30)
	await _your_ball(joe, &"thigh_l")
	await physics_frames(10)
	check(m.joe_brain.turned, "three of yours and Joe turns on you (%s)" % m.joe_brain.describe())
	check(_lines_of("joe").has("Then I stop you."), "\"Then I stop you.\"")
	check(m.joe_brain.target == _player(), "his fight's with you")


## Chaos round 2 (#1125): you shot Joe first, he shot you down, and in the black-out he'd gone; the
## mission ended with no word ("he's long gone", `joe state` "no Joe"). Now it ends on a card that
## says so, the story has it, and Enter would start the act again.
func test_joe_lost_to_you_ends_no_justice_on_a_card() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var m := Moment.start_named(&"no_justice_camp", valley, null, {"set_up": true, "pace": 0.25}) as NoJusticeCamp
	check(m != null and not m.done, "it starts")
	if m == null or m.done or m.joe == null:
		return
	var lost := m.get_node_or_null(^"JoeLost") as JoeLost
	check(lost != null, "watched")
	m.joe_brain._turn_on_you()
	await physics_frames(5)
	# You go down (out cold) and come round hours on: Joe has gone his way.
	var p := _player()
	p.set_meta(&"last_hit_by", m.joe)
	p.wounds.physiology.blood_ml = 2800.0
	var woke := await wait_until(func() -> bool: return p.wounds.physiology.is_conscious() and p.wounds.out_cold == 0.0 and m.done, 60 * 12)
	check(woke, "you came round and it's over (%s, %s)" % [m.state, m.done])
	check_eq(String(m.state), "joe_lost", "ended: Joe lost")
	check_eq(StoryState.get_fact("nojustice.ending"), "joe_lost", "the story has it")
	check(lost != null and lost.over and m.card_up(), "on a card")
	check(m._card_label != null and m._card_label.text.contains("No Justice is over"), "it says so (%s)" % (m._card_label.text if m._card_label else ""))
	check(lost != null and lost.what.contains("Joe turned on you"), "what happened: %s" % (lost.what if lost else ""))
