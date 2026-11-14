class_name SheriffDies
extends Act
## No Law, beat 5: the sheriff's last day (#796; data config/moments/sheriff_dies.json, its _doc has
## the whole scene). The morning after the murder: the doctor's runner finds you in town, the doctor
## at his door leads you to the sick room, the sheriff on the cot and his wife sat by him. His lines
## by how you cared for him on the road (sheriff.care: good, he's clear; else fading), the oath (your
## nod or shake, HeadGesture; a shake or no answer: "That's not the way this works, son."), his
## revolver given you (Player.give), and he dies of his gut (Physiology's own death). Then the
## doctor, the acting law, keeps you on as his deputy.
##
## The men are ValleyFolk's act men (`act: sheriff_dies`: built while the valley loads); the cot
## and the wife's chair are kit props put in the sick room for the scene (the doctor's own cot and chair, if
## the props lane has furnished his sick room, is used instead). Lines wait while you're out of
## earshot (`hear_m`); the beats are timed by their length (`cps`).

const GOOD := "good"
const POOR := "poor"
const LEFT := "left"

var folk: ValleyFolk
var building: Node3D
var care := LEFT
## The sheriff's voice: clear (care good) or fading.
var voice := "fading"
var sheriff: HumanBody
var doctor: HumanBody
var wife: HumanBody
var runner: HumanBody
var cot: KitProp
var chair: KitProp
var answer := ""
var held_him := false
var gesture := HeadGesture.new()
var _made: Array[Node] = []
var _lead: Array[Vector3] = []
var _runner_back := -1.0
var _beats: Array = []
var _beat := 0
var _next_t := 0.0
var _wait := &""
var _wait_t := 0.0
var _hold_s := 0.0
var _gave := false
var _followed := false
## From the oath on, a nod or shake counts before its prompt (`_early`, taken when the wait starts).
var _early_from := false
var _early := ""
var state_t := 0.0


func begin() -> void:
	folk = street.get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk if street else null
	var bs: Variant = street.get(&"buildings") if street else null
	building = (bs as Dictionary).get(String(data.get("building", "doctor"))) if bs is Dictionary else null
	if folk == null or building == null:
		_note("no folk or no doctor's building")
		_finish(&"no_town")
		return
	care = String(opts.get("care", StoryState.get_fact("sheriff.care", LEFT)))
	if care not in [GOOD, POOR, LEFT]:
		care = LEFT
	voice = "clear" if care == GOOD else "fading"
	folk.sheriff_scene = self
	if opts.get("set_up", false):
		_set_up_morning()
	StoryState.mark_checkpoint()  # the night before it, set up or played (#864)
	fact("nolaw.sheriff", "dying")
	_make_room()
	_make_men()
	add_to_group(&"claims_use")
	_go(&"send")


func _go(s: StringName) -> void:
	state = s
	state_t = 0.0
	_note("-> %s" % s)


# --- Where (the doctor's building's own space) -------------------------------------------------

## A point of the building [x, z] on its ground floor.
func _local(xz: Array, up := 0.0) -> Vector3:
	return building.global_transform * Vector3(float(xz[0]), _floor_y() + up, float(xz[1]))


func _floor_y() -> float:
	return 0.95


func _use_point(n: String) -> Node3D:
	return building.find_child(n, true, false) as Node3D


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- Setting it up ------------------------------------------------------------------------------

## `-- --mission=sheriff_dies` / the bridge's set_up: the night's done (Earl to the undertaker's),
## the morning, you on Main Street toward the doctor's, unarmed.
func _set_up_morning() -> void:
	var c := clock()
	if c:
		c.set_time(float(opts.get("hour", data.get("hour", 8.5))))
	var morning := {"nolaw.murder": "done", "nolaw.morning": true, "nolaw.seen_from": "table", "nolaw.earl": "undertaker"}
	for k: String in morning:
		if not StoryState.has_fact(k):
			fact(k, morning[k])
	if not StoryState.has_fact("sheriff.care"):
		fact("sheriff.care", care)
	var p := player()
	if p:
		var start: Array = (data.get("you_start", {}) as Dictionary).get("off", [-14.0, 5.0])
		var door := _local(data.get("door_out", [4.71, -1.2]))
		var at := door + Vector3(float(start[0]), 0.0, float(start[1]))
		at.y = folk.ground(at.x, at.z) + 0.1
		p.global_position = at
		p.velocity = Vector3.ZERO
		var to := door - at
		p.rotation.y = atan2(-to.x, -to.z)
		if not StoryState.has_fact("nolaw.revolver"):
			p.lack(&"revolver")


## The cot (the room's own if it has one, else one put there) and the chair by it.
func _make_room() -> void:
	var cp := _use_point(String(data.get("cot", "cot_1")))
	var bp := _use_point(String(data.get("bedside", "bedside")))
	var basis := building.global_basis
	var cot_at := cp.global_position if cp else _local([0.6, 9.8])
	for s: Node in get_tree().get_nodes_in_group(&"structures"):
		var kp := s as KitProp
		if kp and kp.definition.get("id", "") == "iron_cot" and kp.global_position.distance_to(cot_at) < 1.2:
			cot = kp
			break
	if cot == null:
		cot = PropKit.make(&"iron_cot")
		cot.name = "SheriffsCot"
		# The cot's head at its -z; the building's +z runs back: its head toward the room's front.
		cot.transform = Transform3D(basis, Vector3(cot_at.x, cot_at.y - 0.02, cot_at.z))
		street.add_child(cot)
		_made.append(cot)
	var chair_at := bp.global_position if bp else _local([2.0, 10.5])
	# The room's own chair by the bed if it has one (#844: the doctor's dressing puts his bentwood at
	# the bedside point), as the cot.
	for s: Node in get_tree().get_nodes_in_group(&"structures"):
		var kp := s as KitProp
		if kp and kp != cot and kp.definition.has("seat") and kp.global_position.distance_to(chair_at) < 0.6:
			chair = kp
			break
	if chair == null:
		chair = PropKit.make(&"chair")
		chair.name = "BedsideChair"
		var to := cot.global_position - chair_at
		to.y = 0.0
		# A chair faces its +z.
		chair.transform = Transform3D(Basis(Vector3.UP, atan2(to.x, to.z)), Vector3(chair_at.x, chair_at.y - 0.02, chair_at.z))
		street.add_child(chair)
		_made.append(chair)


## The tick's top and the cot's length (its own space): where he lies.
func _cot_bed() -> Array:
	var b := PropKit.bounds(cot.definition)
	var seat: Dictionary = cot.definition.get("seat", {})
	var top := float((seat.get("at", [0, 0.55, 0]) as Array)[1])
	return [top, b.position.z, b.end.z]


func _make_men() -> void:
	var door := _local(data.get("door_out", [4.71, -1.2]))
	var into := _local((data.get("lead", [[4.71, 0.6]]) as Array)[0])
	doctor = folk.take(&"doc", door, into - (into - door) * 3.0)
	wife = folk.take(&"wife", chair.global_position + chair.global_basis.z * 0.8, cot.global_position)
	if wife:
		wife.global_position = Seating.spot(chair)
		Seating.sit_step(wife, chair, 0.0)
	# The sheriff on his back, his feet at the cot's foot (+z), his head on the pillow (-z).
	var bed := _cot_bed()
	var foot := cot.global_transform * Vector3(0.0, float(bed[0]), float(bed[2]) - 0.12)
	var head := cot.global_transform * Vector3(0.0, float(bed[0]), float(bed[1]))
	sheriff = folk.take(&"dying_sheriff", foot, head)
	if sheriff:
		# Facing his head's way the rig lies head toward his +z: turn him to face his feet.
		sheriff.global_transform = Transform3D(Basis(Vector3.UP, atan2(-(foot - head).x, -(foot - head).z)), foot)
		sheriff.set_pose(&"on_back")
		_shape_body()
	for m: HumanBody in [doctor, wife, sheriff]:
		if m == null:
			_note("a man's missing")
	_note("set: the cot, the wife, the doctor at his door; care %s" % care)


## His body: the road's wound (not bleeding now, the doctor's work), what he'd lost by care, the
## gut's clock held till he goes.
func _shape_body() -> void:
	var road: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/moments/the_sheriff.json"))
	var phys := sheriff.physiology
	SheriffOnRoad.shape_wound(phys, (road as Dictionary).get("wound", {}) if road is Dictionary else {})
	var w: Dictionary = data.get("wound", {})
	phys.bleeds.clear()
	phys.blood_ml = phys.tuning.blood_ml * (1.0 - float((w.get("loss", {}) as Dictionary).get(care, 0.36)))
	phys.wound_pain = float(w.get("pain", 0.7))
	phys.pain = phys.wound_pain
	phys.gut_seconds = -1.0  # held: he goes when the scene says
	# (No ball through him here: a hit knocks a man limp. The wound's dressed, under the blanket.)
	sheriff.set_pose(&"on_back")


# --- The tick ----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	t += delta
	state_t += delta
	card_step(delta)
	if done:
		_runner_step(delta)
		return
	for m: HumanBody in [doctor, wife, sheriff, runner]:
		if m != null and is_instance_valid(m):
			m.wake()
	_hold_poses(delta)
	_runner_step(delta)
	var p := player()
	if p == null:
		return
	match state:
		&"send":
			_send_step(p)
		&"go":
			if _flat(p.global_position, doctor.global_position) < float(data.get("door_m", 5.0)):
				doctor.face(p.global_position + Vector3.UP * 1.5)
				_say(doctor, line("door", care))
				for ab: Array in data.get("lead", []):
					_lead.append(_local(ab))
				_lead.append(_local(data.get("doctor_spot", [3.3, 10.9])))
				_go(&"lead")
		&"lead":
			_lead_step(p, delta)
		&"room":
			_room_step(p, delta)


func _hold_poses(delta: float) -> void:
	if wife and is_instance_valid(wife) and chair.seated != wife:
		Seating.sit_step(wife, chair, delta)
	elif wife and is_instance_valid(wife):
		wife.set_pose(&"sit_back")
	if sheriff and is_instance_valid(sheriff) and not sheriff.limp:
		sheriff.set_pose(&"on_back")


## The runner from the doctor's door to you, once you're in town; his line; back he goes.
func _send_step(p: Player) -> void:
	var rd: Dictionary = data.get("runner", {})
	var door := _local(data.get("door_out", [4.71, -1.2]))
	if _flat(p.global_position, door) < float(data.get("door_m", 5.0)) + 4.0:
		_go(&"go")  # you came by yourself
		return
	if runner == null:
		if _flat(p.global_position, door) > float(rd.get("in_town_m", 90.0)):
			return  # out of town: he finds you when you're back
		runner = folk.take(StringName(rd.get("id", "runner")), door, p.global_position)
		if runner == null:
			_go(&"go")
			return
		state_t = 0.0
		_note("the runner comes for you")
	var d := _flat(runner.global_position, p.global_position)
	if d > float(rd.get("say_m", 3.0)) and state_t < float(rd.get("give_up_s", 50.0)):
		runner.set_pose(&"stand")
		runner.walk_to(p.global_position, float(rd.get("walk_speed", 2.6)), get_physics_process_delta_time())
		return
	runner.face(p.global_position + Vector3.UP * 1.5)
	_say(runner, line("sent_for"))
	prompt(String((data.get("prompts", {}) as Dictionary).get("go", "")), 5.0)
	_runner_back = 0.0
	_go(&"go")


## Back toward the doctor's door and out of the world once you can't see him (or a minute on).
func _runner_step(delta: float) -> void:
	if _runner_back < 0.0 or runner == null or not is_instance_valid(runner):
		return
	_runner_back += delta
	if _runner_back < 2.0:
		return
	var door := _local(data.get("door_out", [4.71, -1.2]))
	var p := player()
	var far := p == null or _flat(p.global_position, runner.global_position) > 25.0
	if (far and not folk._you_see(runner.global_position, 40.0)) or _runner_back > 60.0 or _flat(runner.global_position, door) < 0.6:
		folk.release(StringName((data.get("runner", {}) as Dictionary).get("id", "runner")))
		runner = null
		_runner_back = -1.0
		return
	runner.set_pose(&"stand")
	runner.walk_to(door, 1.3, delta)


## The doctor ahead of you to the sick room; the room's beats once you're by the cot.
func _lead_step(p: Player, delta: float) -> void:
	if state_t > float(data.get("lead_after_s", 2.5)):
		if state_t < float(data.get("lead_timeout_s", 40.0)):
			while not _lead.is_empty() and _flat(doctor.global_position, _lead[0]) < 0.3:
				_lead.pop_front()
			if not _lead.is_empty():
				doctor.set_pose(&"stand")
				doctor.walk_to(_lead[0], float(data.get("doctor_walk", 1.1)), delta)
		elif not _lead.is_empty():
			doctor.global_position = _lead[_lead.size() - 1]  # stuck on his way: he's there
			_lead.clear()
		if _lead.is_empty():
			doctor.set_pose(&"stand")
			doctor.face(sheriff.global_position + Vector3.UP * 0.6 if sheriff else cot.global_position)
		if state_t > float(data.get("lead_after_s", 2.5)) + 0.5 and not _followed:
			_followed = true
			prompt(String((data.get("prompts", {}) as Dictionary).get("follow", "")), 3.0)
	if _flat(p.global_position, cot.global_position) < float(data.get("bed_m", 3.2)) and absf(p.global_position.y - cot.global_position.y) < 1.5:
		if not _lead.is_empty():
			doctor.global_position = _lead[_lead.size() - 1]
			_lead.clear()
		_beats = _beat_list()
		_beat = 0
		_next_t = t + 0.8
		_go(&"room")


# --- The room's beats ---------------------------------------------------------------------------

## [who, beat, band] in order, by how you cared for him; `wait` beats are yours (`hold`, `answer`).
func _beat_list() -> Array:
	var b: Array = [["wife", "with_him", "any"]]
	b.append(["wife", "obliged", care] if care != LEFT else ["wife", "freighter", care])
	b.append(["sheriff", "red_shirt", voice])
	b.append(["sheriff", "ditch", voice])
	if care != GOOD:
		b.append(["doctor", "where", care])
		b.append(["wait", "hold", ""])
	b.append(["sheriff", "oath", voice])
	b.append(["wait", "answer", ""])
	b.append(["sheriff", "answer", voice])
	b.append(["do", "badge", ""])
	b.append(["sheriff", "pistol", voice])
	b.append(["do", "give", ""])
	b.append(["sheriff", "last", voice])
	b.append(["do", "die", ""])
	b.append(["doctor", "gone", "any"])
	b.append(["wife", "sit", "any"])
	b.append(["doctor", "acting", "any"])
	b.append(["do", "end", ""])
	return b


func _room_step(p: Player, delta: float) -> void:
	var near := _flat(p.global_position, cot.global_position) < float(data.get("hear_m", 7.0))
	if _wait != &"":
		_wait_t += delta
		_wait_step(p, delta, near)
		return
	if _early_from and near and _early == "":
		# The oath's said: a nod or shake from then on counts, before the prompt's up.
		var g := gesture.feed(rad_to_deg(p.rotation.y), p.get_pitch_degrees(), delta)
		if g != &"":
			_early = String(g)
	if t < _next_t or not near or _beat >= _beats.size():
		return
	var b: Array = _beats[_beat]
	_beat += 1
	match String(b[0]):
		"wait":
			_wait = StringName(b[1])
			_wait_t = 0.0
			if _wait == &"answer" and _early != "":
				_answered(_early)
				return
			if _wait != &"answer" or gesture == null:
				gesture = HeadGesture.new()
			var pr: Dictionary = data.get("prompts", {})
			prompt(String(pr.get(String(b[1]), "")), 12.0 if b[1] == "answer" else float(data.get("hold_wait_s", 12.0)))
		"do":
			_do(String(b[1]))
		_:
			var who: HumanBody = {"wife": wife, "doctor": doctor, "sheriff": sheriff}[String(b[0])]
			var beat := String(b[1])
			if beat == "answer":
				beat = "nod" if answer == "nod" else "shake"
			var text := line(beat, String(b[2]))
			_say(who, text)
			if beat == "oath":
				_early_from = true
				gesture = HeadGesture.new()
			_next_t = t + maxf(float(data.get("gap_min_s", 2.6)), float(text.length()) / float(data.get("cps", 13.0)) + 0.8) * _pace()


## Your part: hold him (E by the cot, `hold_s`), or the nod or shake (no answer in `answer_s`: he
## takes it as a shake).
func _wait_step(p: Player, delta: float, near: bool) -> void:
	match _wait:
		&"hold":
			if Input.is_action_pressed(&"shove") and claims_use(p):
				_hold_s += delta
			if _hold_s >= float(data.get("hold_s", 2.0)) or _wait_t > float(data.get("hold_wait_s", 12.0)):
				held_him = _hold_s >= float(data.get("hold_s", 2.0))
				fact("nolaw.held_him", held_him)
				_wait = &""
				_next_t = t + 0.6
		&"answer":
			var g := gesture.feed(rad_to_deg(p.rotation.y), p.get_pitch_degrees(), delta) if near else &""
			if g != &"":
				_answered(String(g))
			elif _wait_t > float(data.get("answer_s", 25.0)):
				_answered("none")


func _answered(g: String) -> void:
	_early_from = false
	answer = g
	_note("answer: " + g)
	fact("nolaw.accepted", g)
	_wait = &""
	_next_t = t + 0.5


## E here: by the cot while he's held down (the bridge's `use` and PlayerShove ask).
func claims_use(p: Player) -> bool:
	return not done and _wait == &"hold" and p != null and cot != null and _flat(p.global_position, cot.global_position) < 2.2


## The things done between the lines: the badge, the revolver, his death, the end.
func _do(what: String) -> void:
	var pr: Dictionary = data.get("prompts", {})
	match what:
		"badge":
			fact("nolaw.deputy", true)
			prompt(String(pr.get("badge", "")), 3.5)
			_next_t = t + 2.0
		"give":
			var p := player()
			if p:
				p.give(&"revolver")
			_gave = true
			fact("nolaw.revolver", "given")
			prompt(String(pr.get("pistol", "")), 4.0)
			_next_t = t + 2.5
		"die":
			var phys := sheriff.physiology if sheriff else null
			if phys:
				# His gut's clock run out: the body's own death (Physiology: gut_wound).
				phys.gut_seconds = phys.tuning.gut_death_game_hours * phys.tuning.game_hour_seconds
				phys.step(0.05)
			fact("nolaw.sheriff", "dead")
			fact("death.sheriff", String(data.get("sheriff_death", "The sheriff.")))
			_note("the sheriff dies (%s)" % (String(phys.cause_of_death) if phys else "?"))
			_next_t = t + 3.0
		"end":
			fact("nolaw.acting", "doctor")
			_finish(&"done")


## The beats' gaps scaled (`pace` option: the tests run it quicker).
func _pace() -> float:
	return clampf(float(opts.get("pace", 1.0)), 0.05, 4.0)


func _say(man: HumanBody, text: String) -> void:
	if text == "" or man == null or not is_instance_valid(man):
		return
	speak(man, text)
	_note("%s: %s" % [man.person_id, text])


func result() -> Dictionary:
	var r := {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done,
			"care": care, "voice": voice, "answer": answer, "held_him": held_him, "gave": _gave,
			"beat": _beat, "waiting": String(_wait)}
	var p := player()
	if p and cot:
		r["you_to_cot_m"] = snappedf(_flat(p.global_position, cot.global_position), 0.1)
	if p and doctor and is_instance_valid(doctor):
		r["you_to_doctor_m"] = snappedf(_flat(p.global_position, doctor.global_position), 0.1)
	if sheriff and is_instance_valid(sheriff):
		r["sheriff"] = {"alive": sheriff.physiology.alive, "conscious": sheriff.physiology.is_conscious(),
				"loss": snappedf(sheriff.physiology.blood_loss(), 0.001), "pose": String(sheriff.pose), "limp": sheriff.limp,
				"at": [snappedf(sheriff.global_position.x, 0.01), snappedf(sheriff.global_position.y, 0.01), snappedf(sheriff.global_position.z, 0.01)]}
	r["story"] = StoryState.to_dict().facts
	r["timeline"] = timeline.slice(-14)
	return r


## Take back its men and props (the bridge, the tests).
func reset() -> void:
	if folk and is_instance_valid(folk):
		for id: StringName in [&"doc", &"wife", &"dying_sheriff", &"runner"]:
			if folk.state.get(id) == &"act":
				if id == &"wife" and wife and is_instance_valid(wife) and chair and is_instance_valid(chair):
					Seating.stand_up(wife, chair)
				folk.release(id)
		if folk.sheriff_scene == self:
			folk.sheriff_scene = null
	for n: Node in _made:
		if is_instance_valid(n):
			n.queue_free()
	queue_free()
