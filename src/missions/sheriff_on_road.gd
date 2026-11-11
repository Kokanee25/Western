class_name SheriffOnRoad
extends Act
## The sheriff on the road (docs/missions/the-sheriff.md; issue #746): the first mission, rough, in
## the valley. Dawn at Harlan's homestead; the ford path down to the East Road; the sheriff gut-shot
## at `opening_site`, conscious, frightened, his horse standing off the road with its reins down.
## Help him or leave him by a nod or a shake of the head (HeadGesture on your view); press on the
## wound (E held: your hand slows his bleed while it's there; pack_s of it and the wound's packed and
## bound, Physiology.apply_pressure); E by his horse and you take him in: a typed card (leading a
## horse isn't built) with the walk's minutes run on his body; a stand-in doctor takes him at his
## greybox. Or walk off and leave him: a typed card, a freighter finds him later. Either way the
## first story fact: `sheriff.care` (good / poor / left him), with his blood loss
## (`sheriff.blood_loss`) for day 2's last words (no-law). Data: config/moments/the_sheriff.json.
## Stand-ins: the men (the Studio's sean_s3 as the sheriff, doctor_s2), typed lines, the card for
## the walk in, no rifle on his saddle.

## What `sheriff.care` can be (docs/missions/DECISIONS.md).
const GOOD := "good"
const POOR := "poor"
const LEFT := "left him"

var valley: ValleyWorld
var sheriff: HumanBody
var doctor: HumanBody
var horse: Horse
## His body (kept across the card: the same Physiology runs on through the walk in).
var phys: Physiology
var site := Vector3.ZERO
var gesture := HeadGesture.new()

## What you've done.
var found := false  ## been within found_m of him
var hailed := false
var asked := false
var answer := ""  ## "", "nod" or "shake" (the last one)
var pressed_s := 0.0  ## seconds of your hand on the wound, all told
var pressing := false
var packed := false
var taken := false  ## up on his horse and into town
var left_him := false
var care := ""
var loss_at_doctor := -1.0
var trip_s := 0.0
var trip_m := 0.0

var _wound_beat := -1.0  # when the nod's line was said (the red shirt follows)
var _said_shot_by := false
var _say_t := 0.0  # when he last said anything
var _ask_t := 0.0
var _retry_hold := 0.0
var _closer_t := -9.0
var _hail_t := -9.0
var _wounds_seen: Array = []  # his wounds as they were on the road (drawn again at the doctor's)
var _end_t := -1.0
## Cards and the doctor's beats this many times as long (opts `pace`: the tests run them quicker).
var pace := 1.0


func begin() -> void:
	valley = street as ValleyWorld
	pace = float(opts.get("pace", 1.0))
	set_hour()
	if clock() and bool(data.get("clock_runs", true)):
		clock().set_time_scale(1.0)  # the morning goes on while you're at it (the game holds it at noon)
	StoryState.clear("sheriff.")
	_place_player()
	site = _site_point()
	sheriff = _man(data.sheriff, site, site + _road_dir() * 3.0)
	phys = sheriff.physiology
	horse = _horse()
	_horse_place()
	state = &"wounding"
	add_to_group(&"claims_use")
	_note("begin")


## The valley's places (ValleyMarkers), not the old town's.
func places() -> Waypoints:
	return valley.places() if valley else super()


func _layout() -> ValleyLayout:
	return valley.layout if valley and valley.layout else ValleyLayout.main()


## The ground (the greybox's walks where there are some) at x, z.
func _ground(x: float, z: float) -> float:
	if valley and valley.markers:
		return valley.markers.surface(x, z)
	return ValleyTerrain.main().height(x, z)


func _on_ground(c: Vector2) -> Vector3:
	return Vector3(c.x, _ground(c.x, c.y), c.y)


# --- Setting it up --------------------------------------------------------------------------------

## You at Harlan's place at dawn, facing down his ford path.
func _place_player() -> void:
	var p := player()
	if p == null:
		return
	var l := _layout()
	var home := l.place_at(String(data.get("start", "harlan_homestead")))
	var path := l.road_line(String(data.get("start_toward", "harlan_ford_path")))
	var to := path[1] if path.size() > 1 else home + Vector2(0, -10)
	var dir := (to - home).normalized()
	var at := home + dir * 6.0
	var heading := rad_to_deg(atan2(dir.x, -dir.y))
	p.global_transform = Transform3D(Basis(Vector3.UP, ValleyWorld.yaw_of(heading)), _on_ground(at) + Vector3.UP * 0.05)
	p.velocity = Vector3.ZERO
	p.add_look(Vector2(0.0, -p.get_pitch_degrees()), false)  # level (a restart kept the last look)
	prompt(String(data.get("dawn_line", "")), 7.0)


## The East Road's way at the site (unit, in x/z as a Vector3).
func _road_dir() -> Vector3:
	var line := _layout().road_line("east_road")
	var c := _layout().place_at(String(data.get("site", "opening_site")))
	var best := 0
	var bd := INF
	for i in line.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(c, line[i], line[i + 1])
		if q.distance_to(c) < bd:
			bd = q.distance_to(c)
			best = i
	var d := (line[best + 1] - line[best]).normalized() if line.size() > 1 else Vector2(1, 0)
	return Vector3(d.x, 0.0, d.y)


## Where he lies: the site, a little off the road's middle on the far side from the ford path.
func _site_point() -> Vector3:
	var c := _layout().place_at(String(data.get("site", "opening_site")))
	var along := _road_dir()
	var side := Vector3(-along.z, 0.0, along.x)  # the road's right
	if side.z > 0.0:
		side = -side  # the north side: the ford path comes up from the south
	var p := Vector2(c.x, c.y) + Vector2(side.x, side.z) * float((data.sheriff as Dictionary).get("off_road_m", 1.5))
	return _on_ground(p)


func _man(d: Dictionary, at: Vector3, faces: Vector3) -> HumanBody:
	var m := HumanBody.new()
	m.body_model = StringName(d.get("model", "outlaw"))
	m.person_id = StringName(d.get("id", "man"))
	m.name = String(d.get("name", String(m.person_id)))
	m.rng_seed = int(d.get("seed", 1))
	m.has_gun = false
	m.enter(street, at, HumanBody.yaw_toward(at, faces))
	return m


## His horse, standing off the road with its reins down (on the ground before him).
func _horse() -> Horse:
	if not Horse.available():
		return null
	var hd: Dictionary = data.get("horse", {})
	var along := _road_dir()
	var side := Vector3(-along.z, 0.0, along.x)
	if side.z > 0.0:
		side = -side
	var at := site + side * float(hd.get("off_m", 8.0)) + along * float(hd.get("along_m", 4.0))
	at = _on_ground(Vector2(at.x, at.z))
	var h := Horse.new()
	h.name = "SheriffsHorse"
	street.add_child(h)
	_stand_horse(h, at, -along)
	return h


## His horse as a place (`sheriffs_horse`, beside him on the road's side, joined to the site), so
## the bridge's `walk` finds him.
func _horse_place() -> void:
	if horse == null or valley == null or valley.markers == null:
		return
	var w := places()
	var by := horse.global_position + (site - horse.global_position).normalized() * 1.6
	w.add(&"sheriffs_horse", _on_ground(Vector2(by.x, by.z)) + Vector3.UP * 0.05)
	var from := StringName(data.get("site", "opening_site"))
	if w.has(from):
		valley.markers.join(from, &"sheriffs_horse")


## A horse at `at` with his head toward `facing`, his reins hanging to the ground before him.
func _stand_horse(h: Horse, at: Vector3, facing: Vector3) -> void:
	# Model space: his head at -X.
	h.global_transform = Transform3D(Basis(Vector3.UP, atan2(facing.z, -facing.x)), at)
	var nose := at + facing.normalized() * 1.6
	h.tie_to(Vector3(nose.x, _ground(nose.x, nose.z) + 0.02, nose.z))


## The ball in his belly (for the hole, the blood on his shirt), then his body as the data has it:
## the gut holed, what he's lost lying there, the wall's weeping bleed and the slow one inside.
## Down where he is, conscious.
func _wound_him() -> void:
	var w: Dictionary = data.get("wound", {})
	var part := sheriff.parts.get(&"abdomen") as Node3D
	if part:
		var dir := (part.global_basis * Vector3.BACK).normalized()
		var at := part.global_transform * Vector3(0.07, -0.03, -0.3)
		sheriff.take_bullet(part, at, dir, 160.0, 0.0057, 0.0165, 4.0)
	sheriff.go_limp()
	shape_wound(phys, w)
	if not sheriff.wounds.is_empty():
		(sheriff.wounds[-1] as Dictionary).bleeds = [0]


## His body as the data's wound has it (whatever the ball did): pure, for the tests.
static func shape_wound(p: Physiology, w: Dictionary) -> void:
	p.bleeds.clear()
	p.cut.clear()
	p.broken.clear()
	p.torn.clear()
	p.muscle_damage.clear()
	p.lung_damage.clear()
	p.airway_blood = false
	p.brain_dead = false
	p.torn[&"small_intestine"] = true
	p.gut_seconds = float(w.get("shot_ago_s", 225.0))
	var outer: Dictionary = w.get("outer", {})
	var inner: Dictionary = w.get("inner", {})
	p.bleeds.append({"id": 0, "source": &"flesh", "kind": &"vein", "segment": &"abdomen",
			"rate": float(outer.get("rate", 2.4)), "clots": false, "clot": 1.0, "pressure": false,
			"tourniquet": false, "lost": 0.0, "limit": float(outer.get("limit_ml", 1350.0))})
	p.bleeds.append({"id": 1, "source": &"small_intestine", "kind": &"internal", "segment": &"abdomen",
			"rate": float(inner.get("rate", 0.2)), "clots": false, "clot": 1.0, "pressure": false,
			"tourniquet": false, "lost": 0.0, "limit": float(inner.get("limit_ml", 300.0))})
	p.blood_ml = p.tuning.blood_ml - float(w.get("lost_before_ml", 450.0))
	p.wound_pain = float(w.get("pain", 0.9))
	p.pain = p.wound_pain
	p.adrenaline = 0.15
	p.alive = true


# --- The care, as a rule ---------------------------------------------------------------------------

## `sheriff.care` from what you did: left him if you didn't take him in; good if you packed it and
## he'd lost no more than `good_max` of his blood by the doctor's; poor otherwise.
static func care_for(took_him_in: bool, was_packed: bool, loss: float, good_max: float) -> String:
	if not took_him_in:
		return LEFT
	return GOOD if was_packed and loss <= good_max else POOR


# --- The tick --------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	t += delta
	card_step(delta)
	_retry_step(delta)
	if done:
		return
	match state:
		&"wounding":
			if t > 0.1:
				_wound_him()
				state = &"road"
		&"road":
			_road_step(delta)
		&"trip":
			if not card_up():
				_at_doctor()
		&"doctor":
			_doctor_step()
		&"left":
			if not card_up():
				_end(LEFT)


func _sheriff_at() -> Vector3:
	if sheriff == null or not is_instance_valid(sheriff):
		return site
	var pelvis := sheriff.parts.get(&"pelvis") as Node3D
	return pelvis.global_position if sheriff.limp and pelvis else sheriff.global_position


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _road_step(delta: float) -> void:
	var p := player()
	if p == null or sheriff == null or not is_instance_valid(sheriff):
		return
	if not phys.alive:
		_note("he died on the road")
		_leave(true)
		return
	var dist := _flat(p.global_position, _sheriff_at())
	var dd: Dictionary = data.get("distances", {})
	var band := band_of(phys)
	if not found and dist < float(dd.get("found_m", 15.0)):
		found = true
		_note("found him")
	if not hailed and dist < float(dd.get("hail_m", 25.0)):
		hailed = true
		_hail_t = t
		_say(line("hail", band))
	var near := dist < float(dd.get("ask_m", 3.5))
	if near and not asked and band != "out" and t - _hail_t > 2.5:
		asked = true
		_ask_t = t
		_say(line("ask", band))
		prompt("Nod to help him, shake your head to leave him (move your view)", 5.0)
	# Your answer: the view's nod or shake, while you're with him.
	if found and dist < float(dd.get("hail_m", 25.0)):
		var g := gesture.feed(rad_to_deg(p.rotation.y), p.get_pitch_degrees(), delta)
		# Only a change of answer counts (turning away to leave reads as more shaking).
		if g != &"" and asked and String(g) != answer:
			_answer(String(g), band)
	if asked and answer == "" and near and t - _ask_t > float(data.get("say_gap_s", 14.0)):
		_ask_t = t
		_say(line("ask_again", band))
	if answer == "nod" and not _said_shot_by and t - _wound_beat > 4.0:
		_said_shot_by = true
		_say(line("shot_by", band))
	# Your hand on the wound.
	_press_step(p, delta, band)
	if taken:
		return
	# Walked off: from found_m out past leave_m.
	if found and dist > float(dd.get("leave_m", 45.0)):
		_say(line("walked_off", band))
		_leave(false)
		return
	if found and dist < 10.0 and t - _say_t > float(data.get("say_gap_s", 14.0)) * 1.4 and band != "out":
		_say(line("idle", band))


func _answer(g: String, band: String) -> void:
	answer = g
	_note("answer: " + g)
	if g == "nod":
		_wound_beat = t
		_said_shot_by = false
		_say(line("nod", band))
		prompt("Hold E on the wound to press it. E by his horse to take him in", 5.0)
	else:
		_say(line("shake", band))


func _say(text: String) -> void:
	if text == "" or text == "...":
		return
	_say_t = t
	speak(sheriff, text)
	_note("sheriff: " + text)


## E for this scene: by him (your hand on his wound) or by his horse (taking him in).
func claims_use(p: Player) -> bool:
	if done or state != &"road" or p == null:
		return false
	return _by_wound(p) or _by_horse(p)


func _by_wound(p: Player) -> bool:
	if sheriff == null or not is_instance_valid(sheriff):
		return false
	var belly := sheriff.parts.get(&"abdomen") as Node3D
	var at := belly.global_position if belly else _sheriff_at()
	var reach := float((data.get("care", {}) as Dictionary).get("press_reach_m", 2.0))
	return _flat(p.global_position, at) <= reach and absf(p.global_position.y - at.y) < 2.0


func _by_horse(p: Player) -> bool:
	if horse == null or not is_instance_valid(horse):
		return false
	var reach := float((data.get("care", {}) as Dictionary).get("horse_reach_m", 3.0))
	return _flat(p.global_position, horse.global_position) <= reach


func _press_step(p: Player, delta: float, band: String) -> void:
	var e := Input.is_action_pressed(&"shove")
	var now := e and _by_wound(p)
	if now != pressing:
		pressing = now
		if not phys.bleeds.is_empty():
			phys.bleeds[0].hand = now
		if now and pressed_s == 0.0:
			_say(line("press", band))
		if now and answer != "nod":
			answer = "nod"  # your hands on his wound are a yes
			_note("answer: nod (pressed the wound)")
	if pressing:
		pressed_s += delta
		if not packed and pressed_s >= float((data.get("care", {}) as Dictionary).get("pack_s", 6.0)):
			packed = true
			phys.apply_pressure(&"abdomen", true)
			_note("packed and bound")
			_say(line("packed", band))
			prompt("Packed and bound. E by his horse to take him in", 4.0)
	if e and not pressing and _by_horse(p):
		_take_him_in()
	elif e and not pressing and _flat(p.global_position, _sheriff_at()) < 5.0 and t - _closer_t > 2.0:
		_closer_t = t
		prompt("Closer: kneel by his wound", 1.5)


# --- Taking him in (the stand-in card) -------------------------------------------------------------

## The road from here to the doctor's (m): the roads' shortest way.
func trip_metres() -> float:
	var doc := _layout()
	var from := Vector2(site.x, site.z)
	var to := _doctor_front()
	var j := ValleyRoads.make(doc).journey(from, Vector2(to.x, to.z))
	return float(j.get("length", from.distance_to(Vector2(to.x, to.z))))


## In front of the doctor's: on Main Street, off his lot's front by `street_off_m`.
func _doctor_front() -> Vector3:
	var l := _layout()
	var lot := String(data.get("doctor_lot", "doctor"))
	var x := 0.0
	var side := "north"
	for s: String in ["north", "south"]:
		for d: Dictionary in l.lots(s):
			if String(d.id) == lot:
				x = float((d.get("walk", {}) as Dictionary).get("door_x", (float(d.x0) + float(d.x1)) * 0.5))
				side = s
	var front := float((l.town().get("main_street", {}) as Dictionary).get("width_between_fronts", 20.1)) * 0.5
	var deep := float((l.town().get("main_street", {}) as Dictionary).get("boardwalk_depth", 2.4))
	var z := (front - deep - float(data.get("street_off_m", 4.0)) + 1.5) * (-1.0 if side == "north" else 1.0)
	return _on_ground(Vector2(x, z))


func _take_him_in() -> void:
	if taken:
		return
	taken = true
	pressing = false
	if not phys.bleeds.is_empty():
		phys.bleeds[0].hand = false
	trip_m = trip_metres()
	var tr: Dictionary = data.get("trip", {})
	trip_s = float(tr.get("load_s", 60.0)) + trip_m / float(tr.get("lead_mps", 1.3))
	_note("taken in: %.0f m, %.0f s" % [trip_m, trip_s])
	card(String((data.get("cards", {}) as Dictionary).get("trip", "You take him into town.")).replace("%d", str(roundi(trip_s / 60.0))), 5.0 * pace)
	# The walk in, on his body (your hand's on the reins now, not the wound) and the clock.
	run_body(phys, trip_s)
	_forward_clock(trip_s)
	if is_instance_valid(sheriff):
		_wounds_seen = sheriff.wounds.duplicate(true)
		sheriff.queue_free()
	sheriff = null
	var p := player()
	if p:
		p.input_enabled = false  # on the road with him till the card's done
	state = &"trip"


## His body run on through `seconds` (the walk in, the wait to be found): a second a step.
static func run_body(p: Physiology, seconds: float) -> void:
	var left := seconds
	while left > 0.0 and p.alive:
		var dt := minf(left, 1.0)
		p.step(dt)
		left -= dt


func _forward_clock(seconds: float) -> void:
	var c := clock()
	if c:
		c.set_time(c.time_of_day + seconds / phys.tuning.game_hour_seconds)


## At the doctor's: you, him (laid in the street before the steps), his horse to the livery, the
## doctor come out to him.
func _at_doctor() -> void:
	var front := _doctor_front()
	var to_lot := Vector3(0.0, 0.0, signf(front.z) if front.z != 0.0 else -1.0)
	sheriff = _man(data.sheriff, front, front + Vector3(1, 0, 0))
	sheriff.physiology.from_dict(phys.to_dict())
	phys = sheriff.physiology
	var d := band_of(phys)
	doctor = _man(data.doctor, front + to_lot * 1.4 + Vector3(0.6, 0, 0), front)
	var p := player()
	if p:
		var at := front - to_lot * 1.8 + Vector3(-0.5, 0, 0)
		p.global_transform = Transform3D(Basis(Vector3.UP, atan2(-(front - at).x, -(front - at).z)), at + Vector3.UP * 0.05)
		p.velocity = Vector3.ZERO
		p.input_enabled = true
	if horse and is_instance_valid(horse):
		var lv := _lot_front(String(data.get("livery_lot", "livery")))
		_stand_horse(horse, lv, Vector3(0, 0, signf(lv.z) if lv.z != 0.0 else 1.0))
	loss_at_doctor = phys.blood_loss()
	care = care_for(true, packed, loss_at_doctor, float((data.get("care", {}) as Dictionary).get("good_max_loss", 0.3)))
	_record()
	_doc_band = d
	_doc_t = t
	state = &"doctor"


var _doc_band := ""
var _doc_t := 0.0
var _doc_said := 0


func _doctor_step() -> void:
	var dt := (t - _doc_t) / pace
	if _doc_said == 0 and t - _doc_t > 0.2:
		# His body laid down where they set him: the hole and the blood as on the road, the bandage.
		for w: Dictionary in _wounds_seen:
			sheriff.wounds.append(w)
			sheriff._paint_wound(w)
		if packed:
			phys.treated.emit(&"pressure", &"abdomen")
		sheriff.go_limp()
		_doc_said = 1
	elif _doc_said == 1 and dt > 1.5:
		_doc_said = 2
		speak(doctor, line("doctor", _doc_band))
		_note("doctor: " + _doc_band)
	elif _doc_said == 2 and dt > 7.5:
		_doc_said = 3
		speak(doctor, line("doctor_after", care))
	elif _doc_said == 3 and dt > 12.0:
		_doc_said = 4
		card(String((data.get("cards", {}) as Dictionary).get("end", "%s")).replace("%s", care), 6.0 * pace)
		_end(care)


## A lot's middle on Main Street's ground, just off its front.
func _lot_front(id: String) -> Vector3:
	var l := _layout()
	var front := float((l.town().get("main_street", {}) as Dictionary).get("width_between_fronts", 20.1)) * 0.5
	for s: String in ["north", "south"]:
		for d: Dictionary in l.lots(s):
			if String(d.id) == id:
				var z := (front - 3.0) * (-1.0 if s == "north" else 1.0)
				return _on_ground(Vector2((float(d.x0) + float(d.x1)) * 0.5, z))
	return _on_ground(Vector2.ZERO)


# --- Leaving him -------------------------------------------------------------------------------------

func _leave(died: bool) -> void:
	if left_him:
		return
	left_him = true
	pressing = false
	if not phys.bleeds.is_empty():
		phys.bleeds[0].hand = false
	_note("left him" + (" (dead)" if died else ""))
	var found_after := float((data.get("left", {}) as Dictionary).get("found_after_s", 1500.0))
	run_body(phys, found_after)
	loss_at_doctor = phys.blood_loss()
	care = LEFT
	_record()
	card(String((data.get("cards", {}) as Dictionary).get("left", "You leave him.")), 6.0 * pace)
	state = &"left"


func _record() -> void:
	fact("sheriff.care", care)
	fact("sheriff.blood_loss", snappedf(loss_at_doctor, 0.001))
	fact("sheriff.packed", packed)
	fact("sheriff.answer", answer if answer != "" else "none")


func _end(final_care: String) -> void:
	_end_t = t
	if final_care == LEFT and is_instance_valid(sheriff):
		sheriff.queue_free()  # carried off by the freighter
		sheriff = null
	if final_care == LEFT:
		card(String((data.get("cards", {}) as Dictionary).get("end_left", "left him")), 5.0 * pace)
	_finish(&"done")


## Enter afterwards (or held 1.5 s any time): start again from dawn.
func _retry_step(delta: float) -> void:
	if not InputMap.has_action(&"mission_retry"):
		return
	if Input.is_action_pressed(&"mission_retry"):
		_retry_hold += delta
		if (done and t - _end_t > 1.0) or _retry_hold >= 1.5:
			_retry_hold = -INF
			restart()
	else:
		_retry_hold = 0.0


## Take it all back and start again (the same scene, from dawn).
func restart() -> Moment:
	var at := street
	var opts_now := opts
	reset()
	return Moment.start_named(&"the_sheriff", at, null, opts_now)


func result() -> Dictionary:
	var r := super()
	r["care"] = care
	r["found"] = found
	r["asked"] = asked
	r["answer"] = answer
	r["pressing"] = pressing
	r["pressed_s"] = snappedf(pressed_s, 0.01)
	r["packed"] = packed
	r["taken"] = taken
	r["left"] = left_him
	r["blood_loss"] = snappedf(phys.blood_loss(), 0.001) if phys else -1.0
	r["band"] = band_of(phys) if phys else ""
	r["conscious"] = phys.is_conscious() if phys else false
	r["bleed_ml_s"] = snappedf(phys.total_bleed_rate(), 0.01) if phys else 0.0
	r["loss_at_doctor"] = snappedf(loss_at_doctor, 0.001)
	r["trip_m"] = roundf(trip_m)
	r["trip_s"] = roundf(trip_s)
	var p := player()
	if p:
		r["you_to_him_m"] = snappedf(_flat(p.global_position, _sheriff_at()), 0.1)
		r["you_to_horse_m"] = snappedf(_flat(p.global_position, horse.global_position), 0.1) if horse and is_instance_valid(horse) else -1.0
		r["by_wound"] = _by_wound(p) if state == &"road" else false
		r["by_horse"] = _by_horse(p) if state == &"road" else false
	if horse and is_instance_valid(horse):
		r["horse_at"] = [snappedf(horse.global_position.x, 0.1), snappedf(horse.global_position.z, 0.1)]
	r["sheriff_at"] = [snappedf(_sheriff_at().x, 0.1), snappedf(_sheriff_at().y, 0.1), snappedf(_sheriff_at().z, 0.1)]
	r["story"] = StoryState.to_dict().facts
	r["timeline"] = timeline.slice(-12)
	return r


func reset() -> void:
	for n in [sheriff, doctor, horse]:
		if is_instance_valid(n):
			(n as Node).queue_free()
	var p := player()
	if p:
		p.input_enabled = true
	sheriff = null
	doctor = null
	horse = null
	queue_free()
