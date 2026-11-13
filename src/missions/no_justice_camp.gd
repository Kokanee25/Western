class_name NoJusticeCamp
extends Act
## No Justice, step 2 (#843's plan, #859; data config/moments/no_justice_camp.json, its _doc has the
## whole scene; lines from docs/scripts/no_justice.json's doctor, camp and ride). The day the sheriff
## died: Joe in the doctor's front office, the doctor and the bold cowboy; the doctor's warning and the
## cowboy's (S11); Joe asks once, and you nod or shake (HeadGesture), or follow him out anyway. The
## ride out is a card (riding isn't built, #478). At the Southern Ute camp: the raid's damage (kit
## props charred, with real bullet holes), Joe to the survivors and back with what they said (the red
## shirt, S1; the way they went, S10), the cowboy's hat and neckerchief (S12), and the trail read
## toward the hideout. Then he walks with you (CompanionBrain, no longer `held`) for step 3.
##
## Joe is a CompanionBrain from the start, `held` while it's quiet (the scene walks him); in a fight he
## fights. The doctor is ValleyFolk's act man `doc` (SheriffDies'), the cowboy its `cowboy`.

const NOD := "nod"
const FOLLOWED := "followed"
const DECLINED := "declined"

var folk: ValleyFolk
var building: Node3D
var joe: HumanBody
var joe_brain: CompanionBrain
var doctor: HumanBody
var cowboy: HumanBody
var answer := ""
var met := ""
var gesture := HeadGesture.new()
var props: Array[Node3D] = []
## The camp's frame: where you come in, the way on along the trail (flat, unit), across it.
var camp_at := Vector3.ZERO
var camp_on := Vector3.FORWARD
var camp_across := Vector3.RIGHT
var ride_s := 0.0
var holes := 0
var state_t := 0.0
var _made: Array[Node] = []
var _beats: Array = []
var _beat := 0
var _next_t := 0.0
var _waiting := false
var _walk: Array[Vector3] = []
var _looked := 0.0
var _said_nobody := false
var _trail_to := Vector3.ZERO
var _told := false  # the survivors' prompt up
var _to_shoot: Array = []  # [kit prop, its damage entry]


func begin() -> void:
	folk = street.get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk if street else null
	var bs: Variant = street.get(&"buildings") if street else null
	building = (bs as Dictionary).get(String(data.get("building", "doctor"))) if bs is Dictionary else null
	if folk == null or building == null:
		_note("no folk or no doctor's building")
		_finish(&"no_town")
		return
	if opts.get("set_up", false):
		_set_up_day()
	if opts.get("at_camp", false):
		_start_at_camp()
		return
	_make_men()
	_go(&"walk_in")


## Straight to the camp (`at_camp`: the bench's spot, a playtest's or the bridge's start): you came
## with him (`met`, a nod unless said), the ride done.
func _start_at_camp() -> void:
	met = String(opts.get("met", NOD))
	answer = met
	fact("nojustice.met", met)
	_camp_frame()
	joe = CompanionBrain.make_joe(street, _camp_point(2.2, 0.6), 0.0, player(), folk.places, CompanionBrain.STAND_IN, true)
	joe_brain = joe.get_node(^"Brain") as CompanionBrain
	_made.append(joe)
	_make_damage()
	_at_camp_start()


func _go(s: StringName) -> void:
	state = s
	state_t = 0.0
	_note("-> %s" % s)


# --- Where --------------------------------------------------------------------------------------

## A point of the doctor's building [x, z] on its ground floor.
func _local(xz: Array, up := 0.0) -> Vector3:
	return building.global_transform * Vector3(float(xz[0]), 0.95 + up, float(xz[1]))


## Its own space's [x, z] of a world point.
func _in_building(at: Vector3) -> Vector2:
	var l := building.global_transform.affine_inverse() * at
	return Vector2(l.x, l.z)


func _in_front_office(at: Vector3) -> bool:
	var r: Array = data.get("front_office", [0.1, 0.1, 8.43, 3.76])
	var l := _in_building(at)
	return l.x > float(r[0]) and l.x < float(r[2]) and l.y > float(r[1]) and l.y < float(r[3]) \
			and absf(at.y - _local([0, 0]).y) < 1.5


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _ground(x: float, z: float) -> float:
	return ValleyTerrain.main().height(x, z)


# --- Setting it up ------------------------------------------------------------------------------

## `-- --mission=no_justice` / the bridge's set_up: No Law done to the sheriff's death (you his deputy,
## his revolver yours), the late morning, you on Main Street by the doctor's.
func _set_up_day() -> void:
	var c := clock()
	if c:
		c.set_time(float(opts.get("hour", data.get("hour", 10.5))))
	var before := {"nolaw.murder": "done", "nolaw.morning": true, "nolaw.earl": "undertaker", "nolaw.sheriff": "dead",
			"nolaw.deputy": true, "nolaw.revolver": "given", "nolaw.acting": "doctor"}
	for k: String in before:
		if not StoryState.has_fact(k):
			fact(k, before[k])
	if opts.has("followed"):
		fact("nolaw.followed", bool(opts.followed))
	var p := player()
	if p:
		var start: Array = (data.get("you_start", {}) as Dictionary).get("off", [-12.0, 5.0])
		var door := _local(data.get("door_out", [4.71, -1.2]))
		var at := door + Vector3(float(start[0]), 0.0, float(start[1]))
		at.y = folk.ground(at.x, at.z) + 0.1
		p.global_position = at
		p.velocity = Vector3.ZERO
		var to := door - at
		p.rotation.y = atan2(-to.x, -to.z)
		p.give(&"revolver")


## The doctor's men (taken from ValleyFolk, or moved if SheriffDies still has him) and Joe.
func _make_men() -> void:
	var joe_at := _local(data.get("joe_spot", [3.0, 2.3]))
	var door := _local(data.get("door_out", [4.71, -1.2]))
	doctor = _man(&"doc", _local(data.get("doctor_spot", [1.5, 2.6])), joe_at)
	cowboy = _man(&"cowboy", _local(data.get("cowboy_spot", [7.7, 0.75])), _local(data.get("cowboy_faces", [5.0, 2.0])))
	joe = CompanionBrain.make_joe(street, joe_at, HumanBody.yaw_toward(joe_at, door), player(), folk.places,
			CompanionBrain.STAND_IN, true)
	joe_brain = joe.get_node(^"Brain") as CompanionBrain
	_made.append(joe)
	_note("set: Joe, the doctor and the cowboy in the front office")


func _man(id: StringName, at: Vector3, faces: Vector3) -> HumanBody:
	var here: HumanBody = folk.people.get(id)
	if here != null and is_instance_valid(here):
		here.global_position = at
		here.rotation.y = HumanBody.yaw_toward(at, faces)
		return here
	var m := folk.take(id, at, faces)
	if m == null:
		_note("no %s" % id)
	return m


# --- The tick ----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	t += delta
	state_t += delta
	card_step(delta)
	if done:
		return
	for m: HumanBody in [doctor, cowboy, joe]:
		if m != null and is_instance_valid(m):
			m.wake()
	var p := player()
	if p == null or joe == null or not is_instance_valid(joe):
		return
	_hold_poses()
	match state:
		&"walk_in":
			if state_t < 0.2:
				prompt(String(_prompts().get("go", "")), 5.0)
			if _in_front_office(p.global_position) or (_flat(p.global_position, joe.global_position) < 3.0):
				_beats = [["doctor", "who"], ["joe", "joe_wants"], ["joe", "badge"], ["doctor", "warning"],
						["cowboy", "cowboy"], ["joe", "ask"], ["wait", "answer"]]
				_beat = 0
				_next_t = t + 0.6
				_go(&"office")
		&"office":
			_office_step(p, delta)
		&"out":
			_out_step(p, delta)
		&"ride":
			if not card_up():
				p.input_enabled = true
				_at_camp_start()
		&"camp":
			_camp_step(p, delta)


func _prompts() -> Dictionary:
	return data.get("prompts", {})


## The men stand and face the room; Joe's held (the brain's quiet) until the trail.
func _hold_poses() -> void:
	for m: HumanBody in [doctor, cowboy]:
		if m != null and is_instance_valid(m) and not m.limp:
			m.set_pose(&"stand")


func _office_step(p: Player, delta: float) -> void:
	var near := _flat(p.global_position, joe.global_position) < float(data.get("hear_m", 8.0))
	if _waiting:
		var g := gesture.feed(rad_to_deg(p.rotation.y), p.get_pitch_degrees(), delta) if near else &""
		if g != &"":
			_answered(String(g))
		elif state_t > float(data.get("answer_s", 25.0)):
			_answered("none")
		return
	if t < _next_t or not near:
		return
	if _beat >= _beats.size():
		return
	var b: Array = _beats[_beat]
	_beat += 1
	if b[0] == "wait":
		_waiting = true
		gesture = HeadGesture.new()
		state_t = 0.0
		prompt(String(_prompts().get("answer", "")), 12.0)
		return
	var who: HumanBody = {"doctor": doctor, "joe": joe, "cowboy": cowboy}[String(b[0])]
	if who != null and is_instance_valid(who):
		if b[0] == "cowboy":
			who.face(joe.global_position + Vector3.UP * 1.0)  # (not looking up from his smoke)
		else:
			who.face(p.global_position + Vector3.UP * 1.5)
	var text := line(String(b[1]))
	_say(who, text)
	_next_t = t + _gap(text)


func _gap(text: String) -> float:
	return maxf(float(data.get("gap_min_s", 2.4)), float(text.length()) / float(data.get("cps", 13.0)) + 0.8) * _pace()


func _answered(g: String) -> void:
	_waiting = false
	answer = g
	_note("answer: " + g)
	_say(joe, line("yes" if g == NOD else "no"))
	if g == NOD:
		met = NOD
		fact("nojustice.met", NOD)
	_walk.clear()
	for xz: Array in data.get("joe_out", []):
		_walk.append(_local(xz))
	prompt(String(_prompts().get("follow", "")), 3.0)
	_go(&"out")


## Joe out the door to the horses; you after him (or not: a shake you stay by, and he goes alone).
func _out_step(p: Player, delta: float) -> void:
	if state_t > 1.2:
		_walk_joe(_joe_walk(), delta)
	var outside := not _in_front_office(p.global_position) and _in_building(p.global_position).y < 0.0
	var by_him := _flat(p.global_position, joe.global_position) < float(data.get("follow_m", 6.0))
	if met == NOD and (by_him and outside or state_t > float(data.get("follow_s", 60.0)) * _pace()):
		_ride()
	elif met != NOD and outside and by_him and _walk.size() <= 1:
		met = FOLLOWED
		fact("nojustice.met", FOLLOWED)
		_note("you followed him out: you're coming")
		_ride()
	elif met != NOD and state_t > float(data.get("follow_s", 60.0)) * _pace():
		met = DECLINED
		fact("nojustice.met", DECLINED)
		card(String((data.get("cards", {}) as Dictionary).get("alone", "Joe rides out alone.")), 4.0 * _pace())
		_finish(&"declined")


## Joe along `_walk` (true once there).
func _walk_joe(speed: float, delta: float) -> bool:
	while not _walk.is_empty() and _flat(joe.global_position, _walk[0]) < 0.35:
		_walk.pop_front()
	if _walk.is_empty():
		joe.set_pose(&"stand")
		return true
	joe.set_pose(&"stand")
	joe.walk_to(_walk[0], speed, delta)
	return false


# --- The ride (the card) -----------------------------------------------------------------------

## The trail's length from the doctor's: town to its start, then the trail (valley.json), at a walk.
func ride_metres() -> float:
	var rd: Dictionary = data.get("ride", {})
	var l := ValleyLayout.main()
	var line_xz := l.road_line(String(rd.get("trail", "ute_trail")))
	if line_xz.size() < 2:
		return 1900.0
	var m := 0.0
	for i in range(1, line_xz.size()):
		m += line_xz[i - 1].distance_to(line_xz[i])
	var door := _local(data.get("door_out", [4.71, -1.2]))
	return m + Vector2(door.x, door.z).distance_to(line_xz[0])


func _ride() -> void:
	var rd: Dictionary = data.get("ride", {})
	var metres := ride_metres()
	ride_s = metres / float(rd.get("mps", 1.8))
	_note("the ride: %.0f m, %.0f s" % [metres, ride_s])
	card(String((data.get("cards", {}) as Dictionary).get("ride", "You ride out with Joe.")).replace("%d", str(roundi(ride_s / 60.0))), 5.0 * _pace())
	var c := clock()
	if c and joe:
		c.set_time(c.time_of_day + ride_s / joe.physiology.tuning.game_hour_seconds)
	var p := player()
	if p:
		p.input_enabled = false
	# The camp made while the card's up (its holes shot 1.9 km off: nobody here hears them).
	_camp_frame()
	_make_damage()
	_go(&"ride")


# --- The camp ----------------------------------------------------------------------------------

## The camp's frame from the trail's last leg into the place: you in at `arrive_back_m` short of it.
func _camp_frame() -> void:
	var cd: Dictionary = data.get("camp", {})
	var l := ValleyLayout.main()
	var at2 := l.place_at(String(cd.get("place", "ute_community")))
	var line_xz := l.road_line(String((data.get("ride", {}) as Dictionary).get("trail", "ute_trail")))
	var on2 := Vector2(0.0, -1.0)
	if line_xz.size() >= 2:
		on2 = (at2 - line_xz[line_xz.size() - 2]).normalized()
	var you2 := at2 - on2 * float(cd.get("arrive_back_m", 34.0))
	camp_on = Vector3(on2.x, 0.0, on2.y)
	camp_across = Vector3.UP.cross(-camp_on).normalized()  # (your right, facing on)
	camp_at = Vector3(you2.x, _ground(you2.x, you2.y), you2.y)


## A point of the camp's frame (x across, z on) on the ground.
func _camp_point(x: float, z: float) -> Vector3:
	var v := camp_at + camp_across * x + camp_on * z
	v.y = _ground(v.x, v.z)
	return v


func _at_camp_start() -> void:
	var p := player()
	var cd: Dictionary = data.get("camp", {})
	p.global_position = camp_at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-camp_on.x, -camp_on.z)
	var jat := _camp_point(float(cd.get("joe_side_m", 2.2)), 0.6)
	joe.global_position = jat + Vector3.UP * 0.05
	joe.rotation.y = HumanBody.yaw_toward(jat, jat + camp_on)
	# The doctor and the cowboy back to their day (ValleyFolk); the scene's at the camp now.
	for id: StringName in [&"cowboy"]:
		if folk.state.get(id) == &"act":
			folk.release(id)
	cowboy = null
	_beats = [["joe", "wait"], ["do", "to_them"], ["do", "back"], ["joe", "what"], ["joe", "shirt"], ["do", "point"],
			["joe", "way"]]
	if StoryState.get_fact("nolaw.followed", false) == true:
		_beats.append(["joe", "you_knew"])
	_beats.append_array([["do", "costume"], ["joe", "disguise"], ["do", "trail"], ["do", "end"]])
	_beat = 0
	_next_t = t + 1.0
	fact("nojustice.camp", "came")
	_go(&"camp")


## The raid's damage: kit props tipped and charred about the camp, and real balls put through some.
func _make_damage() -> void:
	var dd: Dictionary = data.get("damage", {})
	for d: Dictionary in dd.get("props", []):
		if not PropKit.has(StringName(d.id)):
			continue
		var kp := PropKit.make(StringName(d.id))
		var at := _camp_point(float(d.at[0]), float(d.at[1]))
		var yaw := atan2(camp_on.x, camp_on.z) + deg_to_rad(float(d.get("yaw", 0.0)))
		var b := Basis(Vector3.UP, yaw)
		if d.get("tipped", false):
			b = b * Basis(Vector3.FORWARD, PI * 0.5)
			at.y += 0.25
		kp.name = "Raid_%s" % d.id
		kp.transform = Transform3D(b, at)
		street.add_child(kp)
		_made.append(kp)
		props.append(kp)
		if int(d.get("holes", 0)) > 0:
			_to_shoot.append([kp, d])
		var ch := float(d.get("char", 0.0))
		if ch > 0.0 and kp is Structure:
			for m: StructureMember in (kp as Structure).members.values():
				(kp as Structure).show_fire(m, ch, 0.0)
	_shoot_holes.call_deferred()


## The bullet holes: balls fired through the props from where the raiders stood (a few frames on,
## once their shapes are in the world). A .44 ball's numbers.
func _shoot_holes() -> void:
	for i in 3:
		await get_tree().physics_frame
	var bal := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if bal == null:
		_note("no ballistics: no holes")
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 859
	for pair: Array in _to_shoot:
		var kp := pair[0] as Node3D
		var d: Dictionary = pair[1]
		if not is_instance_valid(kp):
			continue
		var n := int(d.get("holes", 0))
		var f: Array = d.get("from", [5.0, 1.2, -5.0])
		var from := kp.global_position + camp_across * float(f[0]) + camp_on * float(f[2]) + Vector3.UP * float(f[1])
		for k in n:
			var aim := kp.global_position + Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.3, 0.9), rng.randf_range(-0.3, 0.3))
			bal.fire(from, (aim - from).normalized(), 260.0, 0.0145, 0.0114, [])
			holes += 1
	_note("%d balls through the camp's things" % holes)


func _camp_step(p: Player, delta: float) -> void:
	if not _walk.is_empty():
		_walk_joe(_joe_walk(), delta)
	_look_at_joe(p, delta)
	if _waiting:
		_camp_wait(p, delta)
		return
	if t < _next_t or _beat >= _beats.size():
		return
	var near := _flat(p.global_position, joe.global_position) < float(data.get("hear_m", 8.0)) + 4.0
	var b: Array = _beats[_beat]
	if b[0] == "joe" and not near:
		return  # (he waits for you to come up)
	_beat += 1
	if b[0] == "do":
		_do(String(b[1]))
		return
	if b[1] != "way":
		joe.face(p.global_position + Vector3.UP * 1.5)
	var text := line(String(b[1]))
	_say(joe, text)
	_next_t = t + _gap(text)
	if b[1] == "you_knew":
		fact("nojustice.knew_the_way", true)


## The beats that are things done: to the survivors and back, pointing, the costume, the trail.
func _do(what: String) -> void:
	var cd: Dictionary = data.get("camp", {})
	match what:
		"to_them":
			_walk = [_camp_point(0.0, float(cd.get("arrive_back_m", 34.0)) + float(cd.get("survivors_on_m", 22.0)))]
			_waiting = true
			state_t = 0.0
		"back":
			_walk = [_camp_point(float(cd.get("joe_side_m", 2.2)) * 0.8, 1.6)]
			_waiting = true
			state_t = 0.0
		"point":
			joe.face(_trail_dir_point(20.0) + Vector3.UP * 1.4)
			_next_t = t + 0.6
		"costume":
			joe_brain.costume = true
			fact("nojustice.costume", true)
			prompt(String(_prompts().get("costume", "")), 4.0)
			_next_t = t + 3.0 * _pace()
		"trail":
			_trail_to = _trail_dir_point(float(cd.get("trail_m", 14.0)))
			_walk = [_trail_to]
			_waiting = true
			state_t = 0.0
		"end":
			joe.set_pose(&"stand")
			fact("nojustice.trail", "hideout")
			if not StoryState.has_fact("nojustice.knew_the_way"):
				fact("nojustice.knew_the_way", StoryState.get_fact("nolaw.followed", false) == true)
			prompt(String(_prompts().get("trail", "")), 6.0)
			joe_brain.held = false  # with you again
			_finish(&"done")


## Toward the hideout from Joe, this far (on the ground).
func _trail_dir_point(m: float) -> Vector3:
	var cd: Dictionary = data.get("camp", {})
	var h := ValleyLayout.main().place_at(String(cd.get("trail_toward", "hideout")))
	var dir := (Vector3(h.x, 0.0, h.y) - Vector3(joe.global_position.x, 0.0, joe.global_position.z)).normalized()
	var v := joe.global_position + dir * m
	v.y = _ground(v.x, v.z)
	return v


## The walks' waits: Joe gone to the survivors and talking, back to you, or out to read the ground.
func _camp_wait(p: Player, _delta: float) -> void:
	var cd: Dictionary = data.get("camp", {})
	var there := _walk.is_empty()
	match _beat_name(_beat - 1):
		"to_them":
			if there:
				joe.set_pose(&"stand")
				if not _told:
					_told = true
					prompt(String(_prompts().get("survivors", "")), 5.0)
					state_t = 0.0
				elif state_t > float(cd.get("talk_s", 16.0)) * _pace():
					_waiting = false
					_next_t = t + 0.2
			elif state_t > 90.0:
				joe.global_position = _walk[_walk.size() - 1]
				_walk.clear()
		"back":
			# Back to you, wherever you've gone.
			var to := p.global_position + (joe.global_position - p.global_position).normalized() * 2.0
			if not _walk.is_empty():
				_walk[0] = to
			if there or _flat(joe.global_position, p.global_position) < 2.6:
				_walk.clear()
				joe.set_pose(&"stand")
				_waiting = false
				_next_t = t + 0.4
		"trail":
			if there:
				if joe.pose != &"kneel":
					joe.set_pose(&"kneel")
					joe.face(_trail_to + (_trail_to - p.global_position).normalized() * 6.0)
					state_t = 0.0
				elif state_t > float(cd.get("kneel_s", 3.5)) * _pace():
					# Half to himself, as he gets up: however far back you've stayed.
					joe.set_pose(&"stand")
					var text := line("trail")
					_say(joe, text)
					_waiting = false
					_next_t = t + _gap(text)
			elif state_t > 40.0:
				_walk.clear()


func _beat_name(i: int) -> String:
	return String(_beats[i][1]) if i >= 0 and i < _beats.size() else ""


## A while looking at him in the hat (S37): the dry line, once.
func _look_at_joe(p: Player, delta: float) -> void:
	if _said_nobody or not joe_brain.costume or _waiting:
		return
	var cd: Dictionary = data.get("camp", {})
	if not StoryState.has_fact("nojustice.costume"):
		return
	var cam := p.camera
	var to := joe.global_position + Vector3.UP * 1.5 - cam.global_position
	var looking := to.length() < 7.0 and rad_to_deg((-cam.global_transform.basis.z).angle_to(to)) < 10.0
	_looked = _looked + delta if looking else 0.0
	if _looked > float(cd.get("look_s", 2.5)) and t > _next_t:
		_said_nobody = true
		var text := line("nobody")
		_say(joe, text)
		_next_t = maxf(_next_t, t + _gap(text))


func _joe_walk() -> float:
	return float(opts.get("joe_walk", data.get("joe_walk", 1.3)))


func _pace() -> float:
	return clampf(float(opts.get("pace", 1.0)), 0.05, 4.0)


func _say(man: HumanBody, text: String) -> void:
	if text == "" or man == null or not is_instance_valid(man):
		return
	speak(man, text)
	_note("%s: %s" % [man.person_id, text])


func result() -> Dictionary:
	var r := {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done,
			"answer": answer, "met": met, "beat": _beat, "waiting": _waiting, "ride_s": snappedf(ride_s, 1.0),
			"holes": holes, "props": props.size()}
	var p := player()
	if p and joe and is_instance_valid(joe):
		r["you_to_joe_m"] = snappedf(_flat(p.global_position, joe.global_position), 0.1)
		r["joe"] = {"held": joe_brain.held, "costume": joe_brain.costume, "pose": String(joe.pose),
				"at": [snappedf(joe.global_position.x, 0.1), snappedf(joe.global_position.y, 0.1), snappedf(joe.global_position.z, 0.1)]}
	r["story"] = StoryState.to_dict().facts
	r["timeline"] = timeline.slice(-14)
	return r


## Take back its men and props (the bridge, the tests).
func reset() -> void:
	if folk and is_instance_valid(folk):
		for id: StringName in [&"doc", &"cowboy"]:
			if folk.state.get(id) == &"act":
				folk.release(id)
	for n: Node in _made:
		if is_instance_valid(n):
			n.queue_free()
	var p := player()
	if p:
		p.input_enabled = true
	queue_free()
