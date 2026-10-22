extends TestCase
## FaceLife: a talking man's look and his face answering what happens to him (src/bodies/
## face_life.gd). Each test steps him by hand, a fixed step at a time.

const MAN := &"bold_cowboy_talking"
const DT := 1.0 / 60.0


## A brain's few fields FaceLife reads (fear, senses, target), without a brain's behaviour.
class FakeBrain extends Node:
	var fear := 0.0
	var senses: Senses
	var target: Node3D


func _man(id: StringName, at := Vector3.ZERO, model := MAN) -> HumanBody:
	var him := HumanBody.new()
	him.body_model = model
	him.person_id = id
	add_child(him)
	him.global_position = at
	return him


## Him with a FakeBrain and Senses his life reads, its own stepping off.
func _alive(id: StringName) -> Array:
	var him := _man(id)
	var brain := FakeBrain.new()
	brain.name = "Brain"
	var senses := Senses.new()
	senses.body = him
	senses.process_mode = Node.PROCESS_MODE_DISABLED   # what he sees is set by hand here
	brain.senses = senses
	him.add_child(brain)
	him.add_child(senses)
	await physics_frames(2)
	var life := him.get_node(^"FaceLife") as FaceLife
	life.auto = false
	return [him, life, brain]


func _steps(life: FaceLife, seconds: float) -> void:
	for i in int(seconds / DT):
		life.step(DT)


func _shape(him: HumanBody, s: StringName) -> float:
	var head := him.skin_meshes.get("head/head") as MeshInstance3D
	return head.get_blend_shape_value(head.find_blend_shape_by_name(s))


func _sees(senses: Senses, who: Node3D) -> void:
	senses.known[who] = {"seen": true, "awareness": 1.0, "last_pos": who.global_position, "last_time": 0.0,
			"heard_pos": Vector3.INF, "heard_time": -INF}


func test_a_talking_man_comes_alive_and_a_plain_one_doesnt() -> void:
	var him := _man(&"life_talking")
	var plain := _man(&"life_plain", Vector3(3, 0, 0), &"outlaw")
	await physics_frames(2)
	var life := him.get_node_or_null(^"FaceLife") as FaceLife
	check(life != null and life.has_face(), "the talking man has a FaceLife on his face")
	check(plain.get_node_or_null(^"FaceLife") == null, "the plain man has none")
	him.queue_free()
	plain.queue_free()


func test_he_looks_at_the_man_he_sees() -> void:
	var r: Array = await _alive(&"life_looker")
	var him: HumanBody = r[0]
	var life: FaceLife = r[1]
	var other := _man(&"life_other", Vector3(-2.0, 0, -2.5), &"outlaw")   # ahead, to his left (he faces -Z)
	await physics_frames(2)
	_sees((r[2] as FakeBrain).senses, other)
	_steps(life, 0.6)
	check(life.looking_at() == other.parts[&"head"], "he looks at the man he sees, at his head (%s)" % life.looking_at())
	check(_shape(him, &"look_left") > 0.2 or (him.pose_offsets.get(&"head", Vector3.ZERO) as Vector3).y > 5.0,
			"his eyes or head turn to his left (look_left %.2f, head %s)" % [_shape(him, &"look_left"), him.pose_offsets.get(&"head")])
	# He doesn't stare for ever: in 20 seconds he looks away at least once.
	var away := false
	for i in int(20.0 / DT):
		life.step(DT)
		away = away or life.looking_at() != other.parts[&"head"]
	check(away, "he looks away now and then")
	other.queue_free()
	him.queue_free()


func test_a_shot_starts_him_and_he_looks_to_it() -> void:
	var r: Array = await _alive(&"life_startle")
	var him: HumanBody = r[0]
	var life: FaceLife = r[1]
	_steps(life, 0.5)
	var at := him.global_position + Vector3(8, 0, 0)   # to his right
	(r[2] as FakeBrain).senses.heard.emit(at, &"gunshot", null)
	_steps(life, 0.15)
	var e := life.expression()
	check(e.brows_up > 0.4, "his brows go up (%.2f)" % e.brows_up)
	check(life.looking_at() == null and life.looking_at_point().distance_to(at) < 1.5, "he looks to the shot")
	check(_shape(him, &"look_right") > 0.2 or (him.pose_offsets[&"head"] as Vector3).y < -3.0, "to his right")
	_steps(life, 3.0)
	check(life.expression().brows_up < 0.1, "and his start passes (%.2f)" % life.expression().brows_up)
	him.queue_free()


func test_a_ball_past_his_head_turns_him_to_the_shooter() -> void:
	var r: Array = await _alive(&"life_near_miss")
	var him: HumanBody = r[0]
	var life: FaceLife = r[1]
	var shooter := _man(&"life_shooter", Vector3(4, 0, -6), &"outlaw")
	await physics_frames(2)
	Events.near_miss.emit(him, shooter, 0.3, him.global_position + Vector3(0, 1.7, 0), 250.0, false)
	_steps(life, 0.1)
	check(life.looking_at() == shooter.parts[&"head"], "he looks at the man who shot past him")
	check(life.expression().brows_up > 0.3, "with a start")
	shooter.queue_free()
	him.queue_free()


func test_his_pain_shows_on_his_face() -> void:
	var r: Array = await _alive(&"life_pain")
	var him: HumanBody = r[0]
	var life: FaceLife = r[1]
	_steps(life, 0.5)
	check(life.expression().scowl < 0.05, "no grimace unhurt")
	him.physiology.pain = 1.2
	him.physiology.adrenaline = 0.0
	_steps(life, 1.0)
	var e := life.expression()
	check(e.scowl > 0.3 and e.brows_down > 0.3 and e.squint > 0.2, "a grimace (%s)" % e)
	check(_shape(him, &"scowl") > 0.3, "drawn on his face")
	him.queue_free()


func test_afraid_his_eyes_go_wide_and_he_blinks_more() -> void:
	var r: Array = await _alive(&"life_fear")
	var life: FaceLife = r[1]
	(r[2] as FakeBrain).fear = 1.0
	_steps(life, 0.5)
	check_near(life.expression().brows_up, life.tuning.fear_brows, 0.05, "his brows up with fear")
	check_near(life.gaze.blink_rate, life.tuning.fear_blink, 0.01, "he blinks more often")
	(r[0] as HumanBody).queue_free()


func test_dead_his_lids_settle_part_shut_and_his_eyes_still() -> void:
	var r: Array = await _alive(&"life_dead")
	var him: HumanBody = r[0]
	var life: FaceLife = r[1]
	_steps(life, 0.5)
	him.physiology.alive = false
	_steps(life, 1.5)
	var lid := _shape(him, &"blink_l")
	check_near(lid, life.tuning.dead_lids, 0.05, "his lids part shut (%.2f)" % lid)
	var lo := 1.0
	var hi := 0.0
	for i in int(6.0 / DT):
		life.step(DT)
		lo = minf(lo, _shape(him, &"blink_l"))
		hi = maxf(hi, _shape(him, &"blink_l"))
	check(hi - lo < 0.01, "and he doesn't blink (%.2f..%.2f)" % [lo, hi])
	check(_shape(him, &"look_left") < 0.05 and _shape(him, &"look_right") < 0.05, "his eyes still, ahead")
	him.queue_free()


func test_far_from_the_camera_his_face_rests() -> void:
	var r: Array = await _alive(&"life_far")
	var him: HumanBody = r[0]
	var life: FaceLife = r[1]
	var cam := Node3D.new()
	add_child(cam)
	cam.global_position = him.global_position + Vector3(0, 1.6, life.tuning.near_camera + 10.0)
	life.camera = cam
	var other := _man(&"life_far_other", Vector3(-2.0, 0, -2.5), &"outlaw")
	await physics_frames(2)
	_sees((r[2] as FakeBrain).senses, other)
	var before := _shape(him, &"look_left")
	_steps(life, 1.0)
	check(life.looking_at() == null, "he picks nobody to look at out there")
	check(_shape(him, &"look_left") == before, "and his eyes aren't driven")
	cam.queue_free()
	other.queue_free()
	him.queue_free()


func test_a_man_he_saw_who_is_gone_doesnt_trouble_him() -> void:
	# (test_dynamite: a man freed while still in his Senses' knowledge.)
	var r: Array = await _alive(&"life_gone")
	var him: HumanBody = r[0]
	var life: FaceLife = r[1]
	var other := _man(&"life_gone_other", Vector3(-2.0, 0, -2.5), &"outlaw")
	await physics_frames(2)
	_sees((r[2] as FakeBrain).senses, other)
	_steps(life, 1.0)
	other.free()
	_steps(life, 5.0)
	check(life.looking_at() == null or is_instance_valid(life.looking_at()), "he looks at nobody who's gone")
	him.queue_free()
