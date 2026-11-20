extends TestCase
## Playtest run 3's cabin faults (#1111, NoJusticeCabin): the barred door's kicks are a set count
## (three sound standing kicks, two on the run, a hurt leg's counting less by the same amount every
## time; the door takes the kick, not your foot); a kick on the shack's wall says where the door is;
## Joe walking round you isn't you stepping between them; saying nothing lets him (MISSIONS.md beat 33).

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


## A kick's report as PlayerShove gives it, landing on the shack at its own point `l`.
func _kick_at(m: NoJusticeCabin, l: Vector3, speed: float) -> void:
	m._on_kick({"move": &"kick", "what": &"wall", "speed": speed, "mass": 28.0, "at": m.shack.global_transform * l,
			"result": &"held"})


func _notes(m: NoJusticeCabin, has: String) -> bool:
	return m.timeline.any(func(e: Array) -> bool: return String(e[1]).contains(has))


func test_the_door_takes_a_set_count_of_kicks() -> void:
	var m := await _start()
	if m == null:
		return
	var sound := _player().shove.tuning.kick_speed
	var door := Vector3(m.shack.door_rect.get_center().x, 0.9, 0.0)
	check(m._in_doorway(m.shack.global_transform * door), "the door's middle is in its doorway")
	# Standing: three.
	_kick_at(m, door, sound)
	_kick_at(m, door, sound)
	check(not m.door_open(), "two sound standing kicks don't do it (%s)" % m.result())
	_kick_at(m, door, sound)
	check(m.door_open() and not m.barred(), "the third does (%s)" % m.result())
	check_eq(m.kicks, 3, "three kicks")
	m.reset()
	await physics_frames(5)
	holder.queue_free()
	await physics_frames(3)
	# On the run: two.
	m = await _start()
	_kick_at(m, door, sound + 4.0)
	check(not m.door_open(), "one running kick doesn't")
	_kick_at(m, door, sound + 4.0)
	check(m.door_open(), "two on the run do (%s)" % m.result())
	m.reset()
	await physics_frames(5)
	holder.queue_free()
	await physics_frames(3)
	# A leg at 0.8 of its strength: 0.64 of a kick each, so five, every time.
	m = await _start()
	for i in 4:
		_kick_at(m, door, sound * 0.8)
	check(not m.door_open(), "four kicks on a hurt leg don't (%s)" % m.result())
	_kick_at(m, door, sound * 0.8)
	check(m.door_open(), "the fifth does (%s)" % m.result())


func test_a_real_kick_on_the_door_spares_your_foot() -> void:
	var m := await _start()
	if m == null:
		return
	var p := _player()
	var door := m.hideout._shack_door(0.0)
	_put(m.hideout._shack_door(0.75), door + Vector3.UP * 0.8)
	p.add_look(Vector2(0.0, -8.0 - p.get_pitch_degrees()))
	await physics_frames(2)
	var leg := p.wounds.physiology.muscle_strength("leg", "r")
	p.shove.wants = &"kick"
	check(await wait_until(func() -> bool: return p.shove.move == &"kick", 60), "the kick goes out")
	await wait_until(func() -> bool: return p.shove.move == &"", 120)
	await physics_frames(5)
	check_eq(m.kicks, 1, "the kick counted on the door (%s, %s)" % [m.result(), p.shove.last])
	check_eq(p.shove.last.get("result"), &"gave", "the door gave a little")
	check(not p.shove.last.has("harm"), "nothing to your foot (%s)" % p.shove.last)
	check_eq(p.wounds.physiology.muscle_strength("leg", "r"), leg, "the kicking leg as it was")
	check(m.takes_kick(p, door + Vector3.UP * 0.9, {}), "the door takes kicks while it's barred")


func test_a_kick_on_the_wall_says_where_the_door_is() -> void:
	var m := await _start()
	if m == null:
		return
	var sound := _player().shove.tuning.kick_speed
	var front := m.hideout._shack_door(0.75) - m.shack.global_basis.x * 1.4
	_put(front, front + m.shack.global_basis.z * 2.0)
	await physics_frames(2)
	# On the front wall, well left of the door (the shack's own x 0.5); then its side wall.
	_kick_at(m, Vector3(0.5, 1.0, 0.0), sound)
	check_eq(m.kicks, 0, "not counted on the door")
	check(_notes(m, "That's the wall. The door's to your"), "told it's the wall and which side (%s)" % [m.timeline])
	check(not m.takes_kick(_player(), m.shack.global_transform * Vector3(0.5, 1.0, 0.0), {}), "the wall doesn't give")
	_kick_at(m, Vector3(0.0, 1.0, 2.5), sound)
	check(_notes(m, "The door's round the front."), "the side wall: round the front (%s)" % [m.timeline])
	check_eq(m.kicks, 0, "still none on the door")


## In through the door to the ask (the door kicked by reports, then walked through).
func _to_the_ask(m: NoJusticeCabin) -> bool:
	var door := Vector3(m.shack.door_rect.get_center().x, 0.9, 0.0)
	for i in 3:
		_kick_at(m, door, _player().shove.tuning.kick_speed)
	check(m.door_open(), "the door's in (%s)" % m.result())
	_put(m._local([2.1, 1.3]), m.kett.global_position)
	await physics_frames(10)
	_put(m._local([3.5, 2.4]), m.kett.global_position)
	var asked := await wait_until(func() -> bool: return m.state == &"ask", 60 * 40)
	check(asked, "to the ask (%s)" % m.result())
	_put(m._local([3.5, 2.4]), m.joe.global_position + Vector3.UP * 1.5)
	await physics_frames(5)
	return asked


func test_joe_round_you_isnt_between_and_silence_lets_him() -> void:
	var m := await _start()
	if m == null or not await _to_the_ask(m):
		return
	var p := _player()
	# Joe comes round so you're on his line to Kett, you standing still.
	var me := p.global_position
	var away := Vector3(me.x - m.kett.global_position.x, 0.0, me.z - m.kett.global_position.z).normalized()
	m.joe.global_position = Vector3(me.x, m.joe.global_position.y, me.z) + away * 1.0
	await physics_frames(5)
	check(m._between(Vector2(p.global_position.x, p.global_position.z)), "you're between them now (%s)" % m.result())
	await physics_frames(60)
	check_eq(m.answer, "", "not an answer: you didn't step in (%s)" % m.result())
	check(not _lines_of("joe").has("Then take him. Take him to your law. We will see what it does."), "no 'Then take him'")
	# And nothing more from you: he does it.
	var waited := await wait_until(func() -> bool: return m.answer != "", 60 * 12)
	check(waited, "he stops waiting (%s)" % m.result())
	check_eq(m.answer, "none", "silence")
	check_eq(m.state, &"revenge", "silence lets him (MISSIONS.md beat 33)")
	check_eq(StoryState.get_fact("nojustice.answer"), "none", "nojustice.answer")
