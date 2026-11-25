extends TestCase
## The chaos playtest's townsfolk faults (#1116; docs/playtests/2026-11-20-chaos.md 3 and 5): a hurt
## townsman isn't held by a gun on him, he goes for a door; down and awake with an arm wound he gets up,
## and a man whose leg won't hold him calls for help. And who holds fire for a man in the line (Sean,
## 2026-11-20): an outlaw only for his mates, a careful man (Joe, lawmen, armed townsfolk) for anyone.

var world: Node3D
var said: Array = []  # [speaker id, text]


func before_each() -> void:
	said.clear()
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(260, 1, 260)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


func after_each() -> void:
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)
	world.queue_free()
	await physics_frames(2)


func _on_spoke(who: Node, text: String) -> void:
	said.append([String((who as HumanBody).person_id) if who is HumanBody else "?", text])


func _said(id: String, kind: StringName) -> bool:
	var lines: Array = CivilianBrain.LINES[kind]
	return said.any(func(s: Array) -> bool: return s[0] == id and s[1] in lines)


func _townsman(id: String, at: Vector3, faces: Vector3) -> CivilianBrain:
	var man := HumanBody.new()
	man.body_model = &"storekeeper_s1_talking"
	man.person_id = StringName(id)
	man.rng_seed = 77
	man.has_gun = false
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = at
	brain.faces = faces
	brain.dials = {"nerve": 0.3, "nosy": 0.3, "duty": 0.3}
	brain.refuges = [at + Vector3(14.0, 0.0, 0.0)]
	man.add_child(brain)
	world.add_child(man)
	man.global_position = at
	man.face(faces)
	return brain


## A .45 ball into `seg` across him, this tick, from `by` (a deed `hit` with it, as DeedWatch says).
func _ball(man: HumanBody, seg: StringName, by: Node3D) -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var part := man.parts[seg] as Node3D
	var dir := -man.global_basis.x
	man.take_bullet(part, part.global_position - dir * 0.15, dir, 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity,
			t.bullet_diameter * 0.5, t.bullet_mass, 5.0)
	Events.deed.emit(by, &"hit", man, part.global_position)


func test_a_hurt_man_isnt_held_by_a_gun_on_him() -> void:
	var gunman := HumanBody.new()
	gunman.person_id = &"gunman"
	gunman.rng_seed = 9
	world.add_child(gunman)
	gunman.global_position = Vector3(0.0, 0.0, 1.2)
	gunman.face(Vector3(0.0, 1.5, 0.0))
	var b := _townsman("bench", Vector3.ZERO, Vector3(0.0, 1.5, 2.0))
	var man := b.body
	await physics_frames(10)
	# A gun on him at arm's length: hands up.
	for i in 30:
		Events.deed.emit(gunman, &"aim_at", man, man.global_position)
		await physics_frames(2)
	check_eq(b.mood, CivilianBrain.Mood.HANDS_UP, "hands up with a gun on him")
	_ball(man, &"forearm_l", gunman)
	# The gun stays on him; hurt, he goes anyway.
	var start := man.global_position
	var went := false
	for i in 60 * 6:
		if i % 20 == 0:
			Events.deed.emit(gunman, &"aim_at", man, man.global_position)
		await physics_frames(1)
		if man.global_position.distance_to(start) > 2.0:
			went = true
			break
	check(b.hurt, "he knows he's hit (%s)" % b.describe())
	check(_said("bench", &"hurt") or _said("bench", &"hurt_arm"), "and cries out (%s)" % [said])  # (by where he's hit: #1125)
	check(went, "he goes for the door, the gun on him or not (%s)" % b.describe())
	check(b.mood != CivilianBrain.Mood.HANDS_UP, "not hands up")


func test_down_with_an_arm_wound_he_gets_up() -> void:
	var b := _townsman("arm", Vector3.ZERO, Vector3(0.0, 1.5, 2.0))
	var man := b.body
	await physics_frames(10)
	_ball(man, &"forearm_l", null)
	man.go_limp()
	await physics_frames(5)
	check(man.limp and man.physiology.is_conscious() and man.physiology.can_stand(), "down, awake, legs sound")
	var up := await wait_until(func() -> bool: return not man.limp and not man.rising, 60 * 20)
	check(up, "he gets up within 20 s, not minutes (%s)" % b.describe())


func test_down_and_his_leg_gone_he_calls_for_help() -> void:
	var b := _townsman("leg", Vector3.ZERO, Vector3(0.0, 1.5, 2.0))
	var man := b.body
	await physics_frames(10)
	_ball(man, &"thigh_r", null)
	man.physiology.broken[&"femur_r"] = true
	man.go_limp()
	var called := await wait_until(func() -> bool: return _said("leg", &"hurt_down"), 60 * 8)
	check(called, "he calls for help (%s)" % [said])
	check(man.limp, "and stays down: his leg won't hold him")


## Two men 10 m apart facing, a townsman between; is the line held?
func _line(careful: bool) -> bool:
	var shooter := HumanBody.new()
	shooter.person_id = &"shooter"
	shooter.rng_seed = 5
	var ob := OutlawBrain.new()
	ob.name = "Brain"
	ob.careful = careful
	shooter.add_child(ob)
	world.add_child(shooter)
	shooter.global_position = Vector3(0.0, 0.0, 0.0)
	var target := HumanBody.new()
	target.person_id = &"target"
	target.rng_seed = 6
	world.add_child(target)
	target.global_position = Vector3(0.0, 0.0, -10.0)
	var by := _townsman("between", Vector3(0.0, 0.0, -5.0), Vector3(3.0, 1.5, -5.0))
	await physics_frames(10)
	var from := shooter.global_position + Vector3(0.0, 1.4, 0.0)
	var to := target.global_position + Vector3(0.0, 1.3, 0.0)
	var held := ob._friend_on_line(from, to, target)
	check(not ob._friend_on_line(from + Vector3(3.0, 0.0, 0.0), to + Vector3(3.0, 0.0, 0.0), target) or not careful,
			"a clear line isn't held")
	shooter.queue_free()
	target.queue_free()
	by.body.queue_free()
	await physics_frames(2)
	return held


func test_an_outlaw_fires_past_a_townsman_and_a_careful_man_doesnt() -> void:
	check(not await _line(false), "an outlaw: a townsman in his line takes his chance (Sean, #1116)")
	check(await _line(true), "a careful man (Joe, lawmen, armed townsfolk) holds fire")


## #1248: Earl's fall off his kicked chair bruised him (a blow, no harm past a bruise), and that made
## him a hurt man: "I'm hit!" and off to a door, so he didn't take the free chair (main red, 5436). A
## bruise isn't a wound he's hurt by; a ball is.
func test_a_bruise_isnt_a_hurt() -> void:
	var b := _townsman("earl", Vector3.ZERO, Vector3(0.0, 1.5, 2.0))
	var man := b.body
	await physics_frames(10)
	var harm := man.physiology.blow(&"chest", 21.0, RandomNumberGenerator.new())
	check_eq(Array(harm), ["bruised"], "21 J on the chest: a bruise")
	check_eq(man.physiology.injuries(), 0, "no injury in it")
	await physics_frames(30)
	check(not b.hurt, "not a hurt man (%s)" % b.describe())
	check(not _said("earl", &"hurt"), "no cry of being hit (%s)" % [said])
	_ball(man, &"forearm_l", man)
	await physics_frames(5)
	check(b.hurt, "a ball in him is (%s)" % b.describe())
