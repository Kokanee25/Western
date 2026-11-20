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
