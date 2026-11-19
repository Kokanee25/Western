class_name NoLawCarry
extends Act
## No Law, the night after the murder (#1057; data config/moments/no_law_carry.json, its _doc has the
## whole beat). Earl down and bleeding in the saloon's yard (Cody's ball, the body's own wound); the
## barkeep sends you to Doc's with him; you carry him there over your shoulder (PlayerCarry), bang on the
## doctor's door (PlayerKnock, ValleyFolk.knocked: the doctor inside hears it), the doctor answers
## (out of his door: ValleyFolk.call_out) and says he wants burying; Earl's laid in the front room
## under a sheet (ValleyFolk.lay_out) and is there in the morning. Earl dies by his own wound's
## clock wherever he is: nothing here kills him or keeps him alive.
##
## Beats: ask (the barkeep's lines; nobody else steps up) -> carry (you have him; his lines while he
## can talk) -> knocked (a voice through the door) -> door (the doctor out, his lines) -> lay (into
## the front room: by you, or by the doctor once you've gone and he's dead) -> done. Won't carry him:
## he dies on the floor where he lies (`left`), the morning as before (the undertaker's).

var folk: ValleyFolk
var building: Node3D
var earl: HumanBody
var barkeep: HumanBody
var doctor: HumanBody
## Lines said: [t, speaker, line id, text].
var said: Array = []
var carried := false
var knocked_n := 0
var earl_died := ""
var _state_t := 0.0
var _asked := 0
var _lifted := false
var _earl_said := 0
var _earl_next := 0.0
var _beats: Array = []
var _next_t := 0.0
var _laid_by := ""
var _told_lay := false


func begin() -> void:
	folk = street.get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk if street else null
	var bs: Variant = street.get(&"buildings") if street else null
	building = (bs as Dictionary).get(String(data.get("building", "doctor"))) if bs is Dictionary else null
	if folk == null or building == null:
		_note("no folk or no doctor's building")
		_finish(&"no_town")
		return
	earl = folk.folk_man(StringName(data.get("earl", "earl")))
	barkeep = folk.folk_man(StringName(data.get("barkeep", "barkeep")))
	if earl == null or not earl.physiology.alive:
		_note("no Earl, or dead already")
		_finish(&"no_earl")
		return
	folk.carry_act = self
	folk.knocked.connect(_on_knocked)
	_go(&"ask")


func _go(s: StringName) -> void:
	state = s
	_state_t = 0.0
	_note("-> %s" % s)


func _local(xz: Array) -> Vector3:
	return building.global_transform * Vector3(float(xz[0]), 0.95, float(xz[1]))


func door_point() -> Vector3:
	return _local(data.get("door_out", [4.71, -1.2]))


func laid_spot() -> Vector3:
	return _local(data.get("laid", [6.7, 1.9]))


## In the front room: inside its rect, on its floor (a storey's height).
func in_front_room(at: Vector3) -> bool:
	var r: Array = data.get("front_room", [0.3, 0.2, 8.3, 3.7])
	var l := building.global_transform.affine_inverse() * at
	return l.x > float(r[0]) and l.x < float(r[2]) and l.z > float(r[1]) and l.z < float(r[3]) and absf(l.y - 0.95) < 1.2


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _say(man: HumanBody, id: String) -> String:
	var text := line(id)
	if text == "":
		return ""
	said.append([snappedf(t, 0.01), String(man.person_id) if man else "doctor_inside", id, text])
	if man != null:
		speak(man, text)
	else:
		# Through the door: a voice, no body to see (the doctor's still inside).
		prompt("Doctor, inside: \"%s\"" % text, FaceSpeech.subtitle_seconds(text))
	_note("%s: %s" % [id, text])
	return text


func _length_s(text: String) -> float:
	return float(text.length()) / float(data.get("cps", 13.0)) + float(data.get("gap_s", 1.2))


func _earl_ok() -> bool:
	return earl != null and is_instance_valid(earl)


func _physics_process(delta: float) -> void:
	if done:
		return
	t += delta
	_state_t += delta
	var p := player()
	if p == null or not _earl_ok():
		_end(&"no_earl")
		return
	if earl_died == "" and not earl.physiology.alive:
		earl_died = _where_earl()
		fact("nolaw.earl_died", earl_died)
	if p.carry != null and p.carry.carrying(earl) and not carried:
		carried = true
		fact("nolaw.carried_earl", "yes")
		_earl_next = t + float(data.get("earl_first_s", 4.0))
		if state == &"ask":
			_go(&"carry")
	if carried:
		_earl_talks()
	match state:
		&"ask":
			_ask_step()
		&"carry":
			_carry_step(p)
		&"knocked":
			if _state_t > float(data.get("answer_s", 7.0)):
				_open_door()
		&"door":
			_door_step(delta)
		&"lay":
			_lay_step(p)


## Where Earl is now, in the story's words: the yard, the street, the doctor's door, the front room.
func _where_earl() -> String:
	var at := ValleyFolk._body_at(earl)
	if in_front_room(at):
		return "front_room"
	if _flat(at, door_point()) < float(data.get("door_body_m", 4.5)):
		return "door"
	return "street" if carried else "yard"


## The barkeep's lines (nobody to fetch, so he turns to you); Earl dying where he lies, uncarried.
func _ask_step() -> void:
	if not earl.physiology.alive:
		fact("nolaw.carried_earl", "no")
		_end(&"left")
		return
	var help_at := float(data.get("help_after_s", 4.0))
	if _asked == 0 and _state_t > help_at:
		_asked = 1
		if barkeep != null and is_instance_valid(barkeep) and barkeep.physiology.is_conscious():
			if barkeep.physiology.alive:
				barkeep.face(ValleyFolk._body_at(earl))
			_say(barkeep, "after.help")
		prompt(String((data.get("prompts", {}) as Dictionary).get("take", "")), 3.0)
	elif _asked == 1 and _state_t > help_at + float(data.get("nag_s", 25.0)):
		_asked = 2
		if barkeep != null and is_instance_valid(barkeep) and barkeep.physiology.is_conscious():
			_say(barkeep, "after.help")


## Out with him: the barkeep's word once he's off the floor; at the door, the prompt to bang.
func _carry_step(p: Player) -> void:
	if not earl.physiology.alive and not p.carry.carrying(earl) \
			and _flat(p.global_position, ValleyFolk._body_at(earl)) > float(data.get("unseen_m", 30.0)):
		_end(&"left_on_way")  # let go of on the way and left: he lies where he died (the undertaker's)
		return
	if not _lifted and p.carry.carrying(earl) and p.carry.dragged_m > float(data.get("lifted_m", 3.0)):
		_lifted = true
		if barkeep != null and is_instance_valid(barkeep) and barkeep.physiology.is_conscious() \
				and _flat(barkeep.global_position, p.global_position) < 15.0:
			_say(barkeep, "after.lifted")
		prompt(String((data.get("prompts", {}) as Dictionary).get("door", "")), 4.0)


## His lines on the way, a while apart, while he can talk; then nothing.
func _earl_talks() -> void:
	if t < _earl_next or _earl_said >= ((data.get("lines", {}) as Dictionary).get("carry.earl", {}) as Dictionary).get("any", []).size():
		return
	var band := band_of(earl.physiology)
	if band in ["dead", "out"] or not earl.physiology.can_speak():
		return
	_earl_said += 1
	_earl_next = t + float(data.get("earl_gap_s", 9.0))
	_say(earl, "carry.earl")


## A bang on a door (ValleyFolk.knocked): the doctor's, with Earl by it, is the beat.
func _on_knocked(place: StringName, inside: Array, by: Node, _at: Vector3) -> void:
	if done or place != StringName(String(data.get("building", "doctor"))) or not by is Player:
		return
	if not _earl_ok():
		return
	if _flat(ValleyFolk._body_at(earl), door_point()) > float(data.get("door_body_m", 4.5)):
		_note("a knock at the doctor's without Earl by it")
		return
	folk.claim_knock()  # Earl's: the town doesn't answer it as well (#1095)
	if state not in [&"ask", &"carry", &"knocked"]:
		return
	knocked_n += 1
	var doc_in := inside.has(StringName(String(data.get("doctor", "doctor"))))
	_note("knocked (%d): inside %s" % [knocked_n, inside])
	if knocked_n == 1:
		fact("nolaw.knocked", true)
		_go(&"knocked")
	if doc_in and knocked_n <= 2:
		_say(null, "carry.door_wait")


## He opens it: out of his door (his body, ValleyFolk.call_out), to Earl.
func _open_door() -> void:
	doctor = folk.call_out(StringName(String(data.get("doctor", "doctor"))))
	if doctor == null:
		_note("no doctor to open it")
		_go(&"lay")
		return
	var brain := doctor.get_node_or_null(^"Brain") as CivilianBrain
	var to := ValleyFolk._body_at(earl)
	if brain:
		if brain.reaction:
			brain.reaction.forget()
		brain.chores = []
		brain.chore = null
		brain.walk_speed = float(data.get("doctor_walk", 1.3))
		var from := doctor.global_position - to
		from.y = 0.0
		brain.go_to(to + (from.normalized() if from.length() > 0.1 else Vector3.BACK) * float(data.get("doctor_at_m", 1.1)), to)
	_beats = ["carry.door"]
	var care := String(StoryState.get_fact("sheriff.care", ""))
	if care in ["good", "poor"]:
		_beats.append("carry.two")
	elif care == "left":
		_beats.append("carry.this_one")
	_beats.append_array(["carry.lay", "carry.lay"])
	_next_t = -1.0
	_go(&"door")


## The doctor at Earl: he looks, says it, and the rest in turn.
func _door_step(_delta: float) -> void:
	if doctor == null or not is_instance_valid(doctor) or not doctor.physiology.is_conscious():
		_go(&"lay")
		return
	var at := ValleyFolk._body_at(earl)
	var near := _flat(doctor.global_position, at) < float(data.get("doctor_at_m", 1.1)) + 0.6
	if _next_t < 0.0:
		if not near and _state_t < float(data.get("doctor_wait_s", 8.0)):
			return
		_next_t = t
	if t < _next_t:
		return
	if _beats.is_empty():
		_go(&"lay")
		return
	doctor.face(at + Vector3.UP * 0.2)
	var text := _say(doctor, String(_beats.pop_front()))
	_next_t = t + _length_s(text)


## Into the front room: let go there by you, or the doctor has him in once he's dead and you've gone
## (out of your sight); then the sheet, and the doctor back in.
func _lay_step(p: Player) -> void:
	if not _told_lay:
		_told_lay = true
		prompt(String((data.get("prompts", {}) as Dictionary).get("lay", "")), 4.0)
		_send_doctor_in()
	var at := ValleyFolk._body_at(earl)
	var held := p.carry != null and p.carry.carrying(earl)
	if not held and in_front_room(at) and not earl.physiology.alive:
		_laid("you")
		return
	if not earl.physiology.alive and not held:
		var gone := _flat(p.global_position, door_point()) > float(data.get("leave_m", 14.0))
		var unseen := not folk._you_see(at, float(data.get("unseen_m", 30.0)))
		if (gone or _state_t > float(data.get("lay_timeout_s", 90.0))) and unseen:
			ValleyFolk.move_body(earl, laid_spot())
			_laid("doctor")


func _send_doctor_in() -> void:
	if doctor == null or not is_instance_valid(doctor):
		return
	var brain := doctor.get_node_or_null(^"Brain") as CivilianBrain
	if brain:
		brain.walk_speed = CivilianBrain.WALK
	folk.call_over(doctor.person_id)


func _laid(by: String) -> void:
	_laid_by = by
	folk.lay_out(earl.person_id, StringName(String(data.get("building", "doctor"))))
	fact("nolaw.earl", "doctor's")
	_end(&"laid")


func _end(s: StringName) -> void:
	var p := player()
	if p != null and p.carry != null:
		if p.carry.blood_on_you >= float(data.get("blood_on_you", 0.5)):
			fact("nolaw.blood_on_you", true)
		if s == &"laid" and p.carry.carrying(earl):
			p.carry.drop(&"laid")
	if folk != null and is_instance_valid(folk) and folk.knocked.is_connected(_on_knocked):
		folk.knocked.disconnect(_on_knocked)
	_note("ends: %s" % s)
	_finish(s)


func result() -> Dictionary:
	var p := player()
	return {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done,
			"carried": carried, "knocked": knocked_n, "earl_died": earl_died, "laid_by": _laid_by,
			"earl_alive": _earl_ok() and earl.physiology.alive, "said": said.map(func(s: Array) -> String: return "%s %s" % [s[1], s[2]]),
			"blood_on_you": snappedf(p.carry.blood_on_you, 0.01) if p and p.carry else 0.0,
			"earl": earl.physiology.describe() if _earl_ok() else "", "events": timeline.duplicate()}


func reset() -> void:
	if folk != null and is_instance_valid(folk):
		if folk.knocked.is_connected(_on_knocked):
			folk.knocked.disconnect(_on_knocked)
		if folk.carry_act == self:
			folk.carry_act = null
	queue_free()
