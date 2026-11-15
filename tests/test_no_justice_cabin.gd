extends TestCase
## No Justice step 4 (#966; NoJusticeCabin, config/moments/no_justice_cabin.json): from the hideout's
## end, Kett barred in the shack; his bluff; kicks adding up against the bar till the door gives; his
## surrender in the corner, Joe in behind you, the knife (in his hand only), the bargain and the ask.
## The nod and the arrest (G, his walk bound to the jail's door); the shake and the revenge on the
## wound system; a small nod's "Is that a yes?"; stepping between them; shooting the man who'd given
## up (the murder); Kett dead before it (outside); the hideout handing over to it.

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


func _nod(p: Player, size := 12.0, frames := 3) -> void:
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(0.0, -size * k - p.get_pitch_degrees()))
		await physics_frames(frames)


func _shake(p: Player) -> void:
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(12.0 * k, 0.0))
		await physics_frames(3)


## The valley, the cabin set up (the hideout fought and over, Kett barred in).
func _start(opts := {}) -> NoJusticeCabin:
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


## Kicks at the door from just outside it till it gives (at most `most`); `side` m along the front
## from its middle (0.55: at its jamb, as the bridge's playtest kicked).
func _kick_in(m: NoJusticeCabin, most := 6, side := 0.0) -> void:
	var p := _player()
	var along := m.shack.global_basis.x * side
	var door := m.hideout._shack_door(0.0) + along
	for i in most:
		if m.door_open():
			break
		_put(m.hideout._shack_door(0.75) + along, door + Vector3.UP * 0.8)
		p.add_look(Vector2(0.0, -8.0 - p.get_pitch_degrees()))
		await physics_frames(2)
		var was := m.kicks
		p.shove.wants = &"kick"
		await wait_until(func() -> bool: return m.kicks > was or p.shove.move == &"", 90)
		await wait_until(func() -> bool: return p.shove.move == &"", 120)
		await physics_frames(20)


## In through the door to the ask: returns true once Joe's asked.
func _to_the_ask(m: NoJusticeCabin) -> bool:
	await _kick_in(m)
	check(m.door_open(), "the door's in (%s)" % m.result())
	var inside := m._local([2.1, 1.3])
	_put(inside, m.kett.global_position)
	await physics_frames(10)
	# In and aside, out of the doorway.
	_put(m._local([3.5, 2.4]), m.kett.global_position)
	var asked := await wait_until(func() -> bool: return m.state == &"ask", 60 * 40)
	check(asked, "to the ask (%s)" % m.result())
	# Facing Joe (and nowhere near between them, or on them with a gun).
	_put(m._local([3.5, 2.4]), m.joe.global_position + Vector3.UP * 1.5)
	await physics_frames(5)
	return asked


func test_the_barred_door_gives_to_kicks_and_he_surrenders_in_the_corner() -> void:
	var m := await _start()
	if m == null:
		return
	check_eq(m.state, &"barred", "Kett's barred in")
	check(m.barred() and not m.door_open(), "the door shut and barred")
	var p := _player()
	_put(m.hideout._shack_door(5.0))
	await physics_frames(10)
	check(_lines_of("kett").has("Stay out! I got a gun! I'll use it!"), "his bluff at the door (%s)" % [_lines_of("kett")])
	await _kick_in(m, 1, 0.55)
	check(m.kicks == 1, "a kick at its jamb counts on the door (%s)" % m.result())
	check(not m.door_open(), "the bar holds one standing kick (%.0f J)" % m.kicked_j)
	check(_lines_of("kett").has("First man through that door gets it!"), "his second bluff")
	await _kick_in(m)
	check(m.door_open() and not m.barred(), "it gives to more (%d kicks, %.0f J)" % [m.kicks, m.kicked_j])
	check(m.kicks >= 2 and m.kicks <= 4, "two to four kicks (%d)" % m.kicks)
	check_eq(m.forced_by, "kick", "forced by kicks")
	_put(m._local([2.1, 1.2]), m.kett.global_position)
	await physics_frames(10)
	_put(m._local([3.5, 2.4]), m.kett.global_position)
	var gave := await wait_until(func() -> bool: return _lines_of("kett").has("I'm done! I ain't heeled! You're law, ain't you? Then take me in!"), 60 * 4)
	check(gave, "his surrender (%s)" % m.result())
	var knife := await wait_until(func() -> bool: return m.knife != null, 60 * 40)
	check(knife, "Joe's knife out (%s)" % m.result())
	check(_lines_of("kett").has("It weren't only me. Ask them. It weren't only me."), "it weren't only me, with Joe in")
	check(m.hideout.in_shack(m.joe.global_position), "Joe's in the shack")
	check(m.joe.gun_holstered or m.joe.held_gun == null, "the knife in his hand only: his gun put up")
	check(_lines_of("joe").has("You know me. You were at my camp."), "Joe to him")
	var asked := await wait_until(func() -> bool: return m.state == &"ask", 60 * 20)
	check(asked, "to the ask (%s)" % m.result())
	check(_lines_of("kett").has("You'll want to hear who sent me, Deputy, before that Indian opens my throat."), "the bargain")
	check(_lines_of("joe").has("Are you going to stop me?"), "Joe asks")
	check(m.hideout.in_shack(m.kett.global_position) and m.kett.pose == &"hands_up", "Kett in there, hands up (%s)" % m.result())
	var c := m._local(m.data.corner)
	check(NoJusticeCabin._flat(m.kett.global_position, c) < 1.2, "backed into the corner (%.2f m off it)" % NoJusticeCabin._flat(m.kett.global_position, c))


func test_the_nod_and_the_arrest_to_the_jail() -> void:
	var m := await _start()
	if m == null or not await _to_the_ask(m):
		return
	var p := _player()
	await _nod(p)
	check_eq(m.answer, "nod", "you nodded (%s)" % m.result())
	check(_lines_of("joe").has("Then take him. Take him to your law. We will see what it does."), "Joe's bitter word")
	check(m.knife == null, "the knife put away")
	check(m.kett_brain != null and m.kett_brain.mood == OutlawBrain.Mood.SURRENDERED, "Kett's given up to the law (%s)" % m.result())
	var thanks := await wait_until(func() -> bool: return _lines_of("kett").has("Bless you, Deputy. You're a fair man. I'll come quiet."), 60 * 10)
	check(thanks, "his relief (%s)" % m.result())
	# G by him.
	_put(m.kett.global_position + (m.joe.global_position - m.kett.global_position).normalized() * 0.9, m.kett.global_position + Vector3.UP * 1.0)
	p.wounds._arrest(m.kett)
	await physics_frames(3)
	check(m.kett_brain.arrested_by == p, "bound (%s)" % m.result())
	var rode := await wait_until(func() -> bool: return m.state in [&"ride", &"jail"], 60 * 3)
	check(rode, "the ride back's card (%s)" % m.result())
	check_eq(StoryState.get_fact("nojustice.ending"), "arrest", "nojustice.ending")
	check_eq(StoryState.get_fact("nojustice.joe_trust"), "strained", "Joe's trust")
	check_eq(StoryState.get_fact("nojustice.camp_trust"), "waiting", "the camp's")
	var town := await wait_until(func() -> bool: return m.state == &"jail", 60 * 6)
	check(town, "in town (%s)" % m.result())
	var door := m._jail_local(m.data.jail.door)
	check(NoJusticeCabin._flat(p.global_position, door) < 9.0, "before the jail's door")
	# Walk to it, Kett along behind you.
	for i in 40:
		var to := door - p.global_position
		to.y = 0.0
		if to.length() < 1.6:
			break
		_put(p.global_position + to.normalized() * 0.25, door + Vector3.UP * 1.0)
		await physics_frames(6)
	var jailed := await wait_until(func() -> bool: return StoryState.has_fact("nojustice.jail"), 60 * 20)
	check(jailed, "Kett walked to the jail and locked up (%s)" % m.result())
	check(_lines_of("kett").has("They'll not keep me, Deputy. You know that, don't you?"), "his needling on the way (%s)" % [_lines_of("kett")])
	var over := await wait_until(func() -> bool: return m.done, 60 * 6)
	check(over, "it ends (%s)" % m.result())


func test_the_shake_and_the_revenge() -> void:
	var m := await _start()
	if m == null or not await _to_the_ask(m):
		return
	var p := _player()
	var cam_was := p.camera.global_position
	await _shake(p)
	check_eq(m.answer, "shake", "you shook your head (%s)" % m.result())
	var down := await wait_until(func() -> bool: return m.stabs > 0 and not m.kett.physiology.is_conscious(), 60 * 40)
	check(down, "Joe's knife puts him down (%s)" % m.result())
	check(m.kett.physiology.wounds > 0 and m.kett.wounds.any(func(w: Dictionary) -> bool: return w.kind in [&"stab", &"slash"]), "knife wounds on him")
	var done_said := await wait_until(func() -> bool: return _lines_of("joe").has("It is done."), 60 * 10)
	check(done_said, "it is done (%s)" % m.result())
	check_eq(StoryState.get_fact("nojustice.ending"), "revenge", "nojustice.ending")
	check_eq(StoryState.get_fact("nojustice.bodies"), "left", "the bodies left")
	check_eq(StoryState.get_fact("nojustice.joe_trust"), "kept", "Joe's trust")
	check(p.camera.global_position.distance_to(cam_was) < 0.3, "your view never moved in")
	check(not m.done or not m.kett.physiology.alive, "not over while he still lives")
	var over := await wait_until(func() -> bool: return m.done, 60 * 140)
	check(over, "it ends once he's gone (%s)" % m.result())
	check(not m.kett.physiology.alive, "dead of it")
	check(not m.joe_brain.held, "Joe his own man again")


func test_a_small_nod_is_that_a_yes() -> void:
	var m := await _start()
	if m == null or not await _to_the_ask(m):
		return
	var p := _player()
	await _nod(p, 3.0, 3)
	await physics_frames(60)
	check(_lines_of("joe").has("Is that a yes?"), "Is that a yes? (%s)" % [_lines_of("joe")])
	check_eq(m.answer, "", "not an answer yet")
	check_eq(m.state, &"ask", "he waits again")
	await _nod(p)
	check_eq(m.answer, "nod", "a plain nod answers it (%s)" % m.result())


func test_stepping_between_them_stops_him() -> void:
	var m := await _start()
	if m == null or not await _to_the_ask(m):
		return
	var mid := m.joe.global_position.lerp(m.kett.global_position, 0.5)
	_put(mid, m.joe.global_position + Vector3.UP * 1.5)
	var stopped := await wait_until(func() -> bool: return m.answer != "", 60 * 3)
	check(stopped, "an answer (%s)" % m.result())
	check_eq(m.answer, "between", "stepping between them")
	check(_lines_of("joe").has("Then take him. Take him to your law. We will see what it does."), "the nod's way")
	check(m.knife == null, "the knife put away")


func test_shooting_the_man_who_gave_up() -> void:
	var m := await _start()
	if m == null or not await _to_the_ask(m):
		return
	var p := _player()
	var head := (m.kett.parts[&"chest"] as Node3D).global_position
	var bal := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var tu: RevolverTuning = load("res://config/revolver.tres")
	var from := p.camera.global_position
	Events.shot_fired.emit(from, (head - from).normalized(), p)
	var b := bal.fire(from, (head - from).normalized(), tu.muzzle_velocity, tu.bullet_mass, tu.bullet_diameter, [p.get_rid()])
	b.shooter = p
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	check(m.shot_him, "your ball in him (%s)" % m.result())
	check(_lines_of("joe").has("He had his hands up."), "Joe saw it")
	if m.kett.physiology.alive:
		m.kett.physiology._die(&"heart")  # (the ball's killing wound, made sure of)
	var over := await wait_until(func() -> bool: return m.ending != "", 60 * 2)
	check(over, "an ending (%s)" % m.result())
	check_eq(StoryState.get_fact("nojustice.ending"), "murder", "nojustice.ending")
	check_eq(StoryState.get_fact("nojustice.joe_saw"), true, "Joe saw it")
	check_eq(StoryState.get_fact("nojustice.joe_trust"), "broken", "Joe's trust")


func test_dead_in_the_fight_is_outside() -> void:
	var m := await _start()
	if m == null:
		return
	m.kett.physiology._die(&"heart")
	var over := await wait_until(func() -> bool: return m.done, 60 * 2)
	check(over, "it ends (%s)" % m.result())
	check_eq(StoryState.get_fact("nojustice.ending"), "outside", "nojustice.ending")


func test_down_outside_plays_where_he_lies() -> void:
	var m := await _start({"kett": "down_outside"})
	if m == null:
		return
	check_eq(m.state, &"down", "Kett down outside (%s)" % m.result())
	_put(m.kett.global_position + Vector3(2.0, 0.0, 0.0), m.kett.global_position)
	var gave := await wait_until(func() -> bool: return _lines_of("kett").has("I'm done! I ain't heeled! You're law, ain't you? Then take me in!"), 60 * 4)
	check(gave, "his surrender where he lies (%s)" % m.result())
	var asked := await wait_until(func() -> bool: return m.state == &"ask", 60 * 40)
	check(asked, "Joe's ask (%s)" % m.result())


func test_the_hideout_hands_over_to_the_cabin() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var h := Moment.start_named(&"no_justice_hideout", valley, null, {"set_up": true, "arrive": true, "pace": 0.25}) as NoJusticeHideout
	for g: Dictionary in h.crew:
		(g.man as HumanBody).physiology._die(&"heart")
	h.kett.global_position = h.shack.global_transform * Vector3(h.shack.width * 0.5, h.shack.floor_top + 0.05, 2.2)
	h._holed_up()
	h._go(&"after")
	var over := await wait_until(func() -> bool: return h.done, 60 * 2)
	check(over, "the hideout's over (%s)" % h.result())
	check(h.next_act is NoJusticeCabin and not h.next_act.done, "the cabin starts from it (%s)" % (h.next_act.result() if h.next_act else {}))
	if h.next_act is NoJusticeCabin:
		check_eq((h.next_act as NoJusticeCabin).state, &"barred", "at the barred door")


func test_your_gun_on_joe_stops_him() -> void:
	var m := await _start()
	if m == null or not await _to_the_ask(m):
		return
	var p := _player()
	p.give(&"revolver")
	var w := p.revolver()
	p.select_weapon(w)
	await wait_until(func() -> bool: return p.weapon == w and w.drawn, 60 * 4)
	await physics_frames(30)
	var to := m.joe.global_position + Vector3.UP * 1.0 - p.camera.global_position
	p.rotation.y = atan2(-to.x, -to.z)
	p.add_look(Vector2(0.0, rad_to_deg(asin(to.normalized().y)) - p.get_pitch_degrees()))
	check(CompanionBrain._gun_out(p), "your gun out (%s)" % [w])
	check(m._sights_on(p, m.joe), "on Joe")
	var stopped := await wait_until(func() -> bool: return m.answer != "", 60 * 3)
	check(stopped, "an answer (%s)" % m.result())
	check_eq(m.answer, "drew_on_joe", "your gun on Joe")
	check(_lines_of("joe").has("Then take him. Take him to your law. We will see what it does."), "the nod's way")


func test_binding_him_before_the_ask_answers_it() -> void:
	var m := await _start()
	if m == null:
		return
	await _kick_in(m)
	_put(m._local([2.1, 1.2]), m.kett.global_position)
	await physics_frames(10)
	_put(m._local([3.5, 2.4]), m.kett.global_position)
	var knife := await wait_until(func() -> bool: return m.state in [&"knife", &"ask"], 60 * 40)
	check(knife, "the knife's out (%s)" % m.result())
	var p := _player()
	_put(m.kett.global_position + (p.global_position - m.kett.global_position).normalized() * 0.9, m.kett.global_position + Vector3.UP * 1.0)
	var given := p.wounds._given_up_in_reach()
	check(given == m.kett, "G by him finds a man who's given up, not a duel (%s)" % [given])
	if given:
		p.wounds._arrest(given)
	var answered := await wait_until(func() -> bool: return m.answer != "", 60 * 2)
	check(answered and m.answer == "tied", "binding him answers Joe (%s)" % m.result())
	var arrested := await wait_until(func() -> bool: return m.ending == "arrest", 60 * 20)
	check(arrested, "the arrest (%s)" % m.result())


## Standing, walked in by the keys: up the doorstep and through the doorway (#966's playtest stopped
## dead on the threshold: the shack's floor stood higher than a step).
func test_you_walk_in_through_the_door_standing() -> void:
	var m := await _start()
	if m == null:
		return
	await _kick_in(m)
	check(m.door_open(), "the door's in")
	await physics_frames(30)
	var p := _player()
	_put(m.hideout._shack_door(2.0), m.hideout._shack_door(-3.0) + Vector3.UP * 1.6)
	p.add_look(Vector2(0.0, -p.get_pitch_degrees()))
	var ev := InputEventAction.new()
	ev.action = &"move_forward"
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)
	var inside := await wait_until(func() -> bool: return m.hideout.in_shack(p.global_position), 60 * 6)
	var up := InputEventAction.new()
	up.action = &"move_forward"
	up.pressed = false
	Input.parse_input_event(up)
	check(inside, "in, standing (%s)" % [m.shack.global_transform.affine_inverse() * p.global_position])
	check(not p.is_crouching, "not crouched")
