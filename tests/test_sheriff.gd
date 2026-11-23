extends TestCase
## The sheriff on the road (#746, docs/missions/the-sheriff.md): `sheriff.care`'s rules (good / poor /
## left him), his wound by the numbers (hours, not minutes; how well you did shows in his blood
## loss), the nod and the shake (HeadGesture), the story's facts (StoryState), and the scene played
## in the valley each way through (SheriffOnRoad, config/moments/the_sheriff.json).

const DATA := "res://config/moments/the_sheriff.json"

var holder: Node
var valley: ValleyWorld


func after_each() -> void:
	StoryState.clear()
	Input.action_release(&"shove")
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


func _body() -> Physiology:
	var p := Physiology.new()
	p.roll_rng.seed = 746
	SheriffOnRoad.shape_wound(p, _data().wound)
	return p


## His blood loss at the doctor's after: `arrive_s` to reach him, your hand on it `press_s` (packed
## past pack_s), then the walk in (the trip's own seconds as the scene works them out from ~470 m).
func _loss(arrive_s: float, press_s: float) -> float:
	var d := _data()
	var p := _body()
	SheriffOnRoad.run_body(p, arrive_s)
	if press_s > 0.0:
		p.bleeds[0].hand = true
		SheriffOnRoad.run_body(p, press_s)
		p.bleeds[0].hand = false
		if press_s >= float(d.care.pack_s):
			p.apply_pressure(&"abdomen", true)
	SheriffOnRoad.run_body(p, float(d.trip.load_s) + 470.0 / float(d.trip.lead_mps))
	return p.blood_loss()


func test_care_by_the_rules() -> void:
	check_eq(SheriffOnRoad.care_for(false, true, 0.1, 0.3), "left him", "not taken in: left him, however you'd tended him")
	check_eq(SheriffOnRoad.care_for(true, true, 0.25, 0.3), "good", "packed, and not bled too much by the doctor's")
	check_eq(SheriffOnRoad.care_for(true, true, 0.35, 0.3), "poor", "packed, but too late: he'd bled too much")
	check_eq(SheriffOnRoad.care_for(true, false, 0.2, 0.3), "poor", "taken in without the wound packed")


func test_a_gut_shot_has_hours_not_minutes() -> void:
	var p := _body()
	check(p.is_conscious(), "conscious when you find him")
	check_eq(Act.band_for_loss(p.blood_loss(), _data().bands), "clear", "and clear-spoken at first")
	SheriffOnRoad.run_body(p, 2000.0)
	check(p.alive, "left 2,000 s (18 game hours) untended, he's still alive (%s)" % p.cause_of_death)
	check(not p.is_conscious(), "but he's passed out (%.2f lost)" % p.blood_loss())
	check(p.blood_loss() < p.tuning.death_at_loss, "short of bleeding to death")
	# The gut itself does for him, about 30 game hours after the shot (gut_death_game_hours): on
	# day 2, as the story has it.
	SheriffOnRoad.run_body(p, 1500.0)
	check(not p.alive and p.cause_of_death == &"gut_wound", "the gut does for him on day 2 (%s)" % p.cause_of_death)


func test_how_well_you_did_shows_in_his_blood_loss() -> void:
	var good_max := float(_data().care.good_max_loss)
	var walked_packed := _loss(240.0, 7.0)
	var ran_packed := _loss(80.0, 7.0)
	var walked_unpacked := _loss(240.0, 0.0)
	var dawdled_packed := _loss(240.0 + 420.0, 7.0)
	check(walked_packed <= good_max, "walked down, packed it: good (%.3f)" % walked_packed)
	check(ran_packed < walked_packed, "ran down: less lost (%.3f)" % ran_packed)
	check(walked_unpacked > good_max + 0.04, "walked down, never packed it: well past good (%.3f)" % walked_unpacked)
	check(dawdled_packed > good_max, "seven minutes dawdling first: poor even packed (%.3f)" % dawdled_packed)
	check(_loss(240.0, 3.0) > walked_packed, "your hand on it a few seconds, not packed: worse than packed")


func test_the_bands_of_his_words() -> void:
	var bands: Dictionary = _data().bands
	check_eq(Act.band_for_loss(0.1, bands), "clear", "a tenth lost: clear")
	check_eq(Act.band_for_loss(0.25, bands), "weak", "a quarter: weak")
	check_eq(Act.band_for_loss(0.36, bands), "fading", "over a third: fading")


func _feed(g: HeadGesture, path: Array, axis: Vector2, step_s: float) -> StringName:
	var got := &""
	for k: float in path:
		var r := g.feed(axis.x * k, axis.y * k, step_s)
		if r != &"":
			got = r
	return got


func test_a_nod_and_a_shake() -> void:
	var swing := [0.0, 5.0, 10.0, 5.0, 0.0, -5.0, -10.0, -5.0, 0.0, 5.0, 10.0, 5.0, 0.0]
	check_eq(_feed(HeadGesture.new(), swing, Vector2(0, 1), 0.05), &"nod", "the view down, up, down: a nod")
	check_eq(_feed(HeadGesture.new(), swing, Vector2(1, 0), 0.05), &"shake", "left, right, left: a shake")
	check_eq(_feed(HeadGesture.new(), swing, Vector2(1, 0), 0.4), &"", "the same swings slowly: looking round, not a shake")
	check_eq(_feed(HeadGesture.new(), [0.0, 3.0, 0.0, -3.0, 0.0, 3.0, 0.0], Vector2(1, 0), 0.05), &"", "small wobbles: nothing")
	check_eq(_feed(HeadGesture.new(), swing, Vector2(1, 1), 0.05), &"", "round and round on both: neither")
	# Looking round first doesn't stop a nod after.
	var g := HeadGesture.new()
	_feed(g, [0.0, 20.0, 40.0, 60.0, 80.0], Vector2(1, 0), 0.2)
	check_eq(_feed(g, swing, Vector2(0, 1), 0.05), &"nod", "a nod after turning to face him")
	# The yaw wraps at +-180.
	var w := HeadGesture.new()
	var wrap: Array = [170.0, 175.0, 180.0, 185.0, 190.0, 185.0, 180.0, 175.0, 170.0, 175.0, 180.0, 185.0, 190.0]
	var got := &""
	for y: float in wrap:
		var r := w.feed(wrapf(y, -180.0, 180.0), 0.0, 0.05)
		if r != &"":
			got = r
	check_eq(got, &"shake", "a shake across the wrap")


func test_story_state() -> void:
	StoryState.set_fact("sheriff.care", "poor", 1, 6.5)
	check_eq(StoryState.get_fact("sheriff.care"), "poor", "kept")
	check_eq(StoryState.to_dict().when["sheriff.care"], [1, 6.5], "with when")
	StoryState.set_fact("other.thing", true)
	StoryState.clear("sheriff.")
	check(not StoryState.has_fact("sheriff.care"), "a mission's own facts cleared")
	check(StoryState.has_fact("other.thing"), "others kept")


# --- The scene in the valley -------------------------------------------------------------------------

func _start() -> SheriffOnRoad:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var m := Moment.start_named(&"the_sheriff", valley, null, {"pace": 0.1}) as SheriffOnRoad
	await physics_frames(10)
	return m


func _put(p: Player, at: Vector3) -> void:
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO


func _nod(m: SheriffOnRoad, p: Player) -> void:
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(0.0, -12.0 * k - p.get_pitch_degrees()))
		await physics_frames(3)


func test_dawn_at_harlan_s_and_the_sheriff_on_the_road() -> void:
	var m := await _start()
	check(m != null, "the scene starts in the valley")
	if m == null:
		return
	var p := m.player()
	var home := ValleyLayout.main().place_at("harlan_homestead")
	check(Vector2(p.global_position.x, p.global_position.z).distance_to(home) < 15.0, "you start at Harlan's place")
	check_near(m.clock().time_of_day, float(_data().hour), 0.05, "at dawn")
	check_eq(String(m.state), "road", "he's on the road")
	check(m.sheriff.limp and m.phys.is_conscious(), "down, and with it")
	var site := ValleyLayout.main().place_at("opening_site")
	check(Vector2(m.site.x, m.site.z).distance_to(site) < 3.0, "at the opening site")
	check(m.horse != null and m.horse.global_position.distance_to(m.site) < 12.0, "his horse stands by")
	check(m.phys.total_bleed_rate() > 1.0, "bleeding (%.2f ml/s)" % m.phys.total_bleed_rate())


func test_help_him_well() -> void:
	var m := await _start()
	var p := m.player()
	_put(p, m._sheriff_at() + Vector3(1.0, 0, 0.6))
	check(await wait_until(func() -> bool: return m.asked, 60 * 5), "he hails you, then asks")
	await _nod(m, p)
	check_eq(m.answer, "nod", "you nod")
	_put(p, m.sheriff.parts[&"abdomen"].global_position + Vector3(0.8, 0, 0))
	Input.action_press(&"shove")
	var ok := await wait_until(func() -> bool: return m.packed, 60 * 8)
	check(ok, "held on the wound long enough: packed and bound (%.1f s)" % m.pressed_s)
	check(m.phys.bleeds[0].pressure, "the dressing holds it")
	Input.action_release(&"shove")
	await physics_frames(2)
	_put(p, m.horse.global_position + Vector3(1.5, 0, 0))
	await physics_frames(2)
	Input.action_press(&"shove")
	await physics_frames(3)
	Input.action_release(&"shove")
	check(m.taken, "E by his horse: taken in")
	check(m.trip_m > 350.0 and m.trip_m < 700.0, "about 480 m into town (%.0f)" % m.trip_m)
	var over := await wait_until(func() -> bool: return m.done, 60 * 6)
	check(over, "the doctor takes him (%s)" % m.state)
	check_eq(m.care, "good", "care good (lost %.3f)" % m.loss_at_doctor)
	check_eq(StoryState.get_fact("sheriff.care"), "good", "the story knows")
	check(m.doctor != null and is_instance_valid(m.doctor), "the doctor's there")
	var walk_in := m.clock().time_of_day - float(_data().hour)
	check(walk_in > 0.5 and walk_in < 2.0, "about an hour on the clock, not the morning (#1082: %.2f h)" % walk_in)
	check_eq(m.clock().time_scale, 1.0, "the day's rate again once it's over")


func test_help_him_poorly() -> void:
	var m := await _start()
	var p := m.player()
	_put(p, m._sheriff_at() + Vector3(1.0, 0, 0.6))
	await wait_until(func() -> bool: return m.asked, 60 * 5)
	await _nod(m, p)
	# Straight to his horse, the wound not tended.
	_put(p, m.horse.global_position + Vector3(1.5, 0, 0))
	await physics_frames(2)
	Input.action_press(&"shove")
	await physics_frames(3)
	Input.action_release(&"shove")
	var over := await wait_until(func() -> bool: return m.done, 60 * 6)
	check(over, "done")
	check_eq(m.care, "poor", "care poor (lost %.3f)" % m.loss_at_doctor)
	check_eq(StoryState.get_fact("sheriff.care"), "poor", "the story knows")


func test_leave_him() -> void:
	var m := await _start()
	var p := m.player()
	_put(p, m._sheriff_at() + Vector3(1.0, 0, 0.6))
	await wait_until(func() -> bool: return m.asked, 60 * 5)
	var was := 0.0
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(12.0 * k - was, 0.0))
		was = 12.0 * k
		await physics_frames(3)
	check_eq(m.answer, "shake", "you shake your head")
	_put(p, m.site + Vector3(0, 0, 60.0))
	var over := await wait_until(func() -> bool: return m.done, 60 * 4)
	check(over, "done once you've walked off")
	check_eq(m.care, "left him", "care: left him")
	check_eq(StoryState.get_fact("sheriff.care"), "left him", "the story knows")
	check(m.phys.alive, "a freighter finds him alive")


# --- The playtest's faults (#1081) ----------------------------------------------------------------

## A slow, deliberate nod (the view down, up, down a second apart: the playtester's turns) answers.
func test_a_slow_nod_answers() -> void:
	var m := await _start()
	var p := m.player()
	_put(p, m._sheriff_at() + Vector3(1.0, 0, 0.6))
	check(await wait_until(func() -> bool: return m.asked, 60 * 5), "he asks")
	for k: float in [-1.0, 1.0, -1.0, 0.0]:
		p.add_look(Vector2(0.0, 12.0 * k - p.get_pitch_degrees()))
		await physics_frames(60)
	check_eq(m.answer, "nod", "a slow nod's a yes")


## The town's doctor (ValleyFolk's) and the doctor's door's point, its front (out of the building).
func _door() -> Array:
	var f := valley.folk
	var door := f.places.at(&"doctor")
	var bldg := (valley.buildings as Dictionary).get("doctor") as Node3D
	var front := bldg.global_basis.z
	front.y = 0.0
	return [door, front.normalized()]


## Carried to the doctor's at noon (the playtest's way in, not the horse's card) and a knock: the
## doctor answers by day, comes out to him and takes him in. Your hands on him don't pack his wound,
## and the horse's caption isn't shown once you've carried him.
func test_carried_to_the_doctors_door_by_day_the_doctor_answers() -> void:
	var m := await _start()
	var p := m.player()
	var shown: Array[String] = []
	p.wounds.shown.connect(func(text: String) -> void: shown.append(text))
	_put(p, m._sheriff_at() + Vector3(1.0, 0, 0.6))
	check(await wait_until(func() -> bool: return m.asked, 60 * 5), "he asks")
	await _nod(m, p)
	check_eq(m.answer, "nod", "you nod")
	m.clock().set_time(12.0)
	valley.folk._look = 0.0
	await physics_frames(60)
	check(valley.folk.book.inside(&"doctor").has(&"doctor"), "noon: the doctor's in (%s)" % [valley.folk.book.inside(&"doctor")])
	# Him lying at the foot of the doctor's door (moved whole: the 480 m is No Law's carry test's).
	var d := _door()
	var door: Vector3 = d[0]
	var out: Vector3 = -d[1]
	var lie := door + out * 1.9
	lie.y = valley.folk.ground(lie.x, lie.z)
	var stand := door + out * 0.9
	stand.y = valley.folk.ground(stand.x, stand.z) + 0.05
	# (You and he moved on the same frame: apart, the scene would have you walked off.)
	p.global_position = stand
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-out.x, -out.z)  # facing out, at him
	ValleyFolk.move_body(m.sheriff, lie)
	await physics_frames(30)
	var took := shown.size()
	Input.action_press(&"shove")
	await physics_frames(1)
	Input.action_release(&"shove")
	await physics_frames(3)
	check(p.carry.carrying(m.sheriff), "you have him over your shoulder (%s)" % p.carry.report())
	# E held a while with him over your shoulder: your hands are on him, not his wound.
	p.rotation.y = atan2(out.x, out.z)  # facing the door
	await physics_frames(3)
	check(p.knock.door_here().get("place", &"") == &"doctor", "at the doctor's door (%s)" % p.knock.report())
	var pressed := m.pressed_s
	Input.action_press(&"shove")
	await physics_frames(60)
	Input.action_release(&"shove")
	await physics_frames(3)
	check(m.pressed_s == pressed and not m.packed, "carrying him, E doesn't press his wound (%.2f s)" % m.pressed_s)
	check(m.knocks >= 1, "E at the door bangs on it (%s)" % p.knock.report())
	check(m.state in [&"knocked", &"doctor"] or m.done, "the knock's the beat (%s)" % m.state)
	check(shown.any(func(x: String) -> bool: return x.begins_with("Doctor, inside")), "a voice through the door (%s)" % [shown])
	var over := await wait_until(func() -> bool: return m.done, 60 * 30)
	check(over, "the doctor comes out and takes him (%s; %s)" % [m.state, m.timeline.slice(-6)])
	check(m.carried_in and m.taken, "taken in, carried")
	check(m.doctor != null and is_instance_valid(m.doctor) and m.doctor == valley.folk.folk_man(&"doctor"), "the town's doctor, out of his door")
	check(not p.carry.carrying(), "you've let go of him")
	check_eq(m.care, "poor", "unpacked: care poor (lost %.3f)" % m.loss_at_doctor)
	check_eq(StoryState.get_fact("sheriff.care"), "poor", "the story knows")
	var after: Array = shown.slice(took)
	check(not after.any(func(x: String) -> bool: return x.contains("E by his horse")), "no horse caption once you've carried him (%s)" % [after])


## Out on his rounds by the book: a knock gets nobody, and says where he is.
func test_the_doctor_out_says_where() -> void:
	var m := await _start()
	var p := m.player()
	var shown: Array[String] = []
	p.wounds.shown.connect(func(text: String) -> void: shown.append(text))
	var d := _door()
	var door: Vector3 = d[0]
	var out: Vector3 = -d[1]
	var lie := door + out * 1.9
	lie.y = valley.folk.ground(lie.x, lie.z)
	ValleyFolk.move_body(m.sheriff, lie)
	await physics_frames(10)
	valley.folk.book.rows[&"doctor"]["in"] = "general_store"
	var heard := valley.folk.knock(&"doctor", p, door + Vector3.UP * 1.3)
	check(not heard.has(&"doctor"), "nobody in")
	await physics_frames(2)
	check(m.state == &"road" and m.knocks == 1, "the scene waits (%s)" % m.state)
	check(shown.any(func(x: String) -> bool: return x.begins_with("Nobody answers") and x.contains("general store")), "told where he is (%s)" % [shown])


## Carried (Sean, 2026-11-18: not dragged): taken up over your shoulder, clear of the ground, no blood
## left on it while you carry him; and the clock at the prologue's rate (clock_scale of the day's, #1082).
func test_carried_off_the_ground_no_trail_and_the_clock_at_its_rate() -> void:
	var m := await _start()
	var p := m.player()
	_put(p, m._sheriff_at() + Vector3(1.0, 0, 0.6))
	await wait_until(func() -> bool: return m.asked, 60 * 5)
	await _nod(m, p)
	var c := PlayerCarry.collar(m.sheriff)
	var at := c + Vector3(0.9, 0.0, 0.0)
	at.y = m._ground(at.x, at.z) + 0.05
	p.global_position = at
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(0.9, 0.0)  # facing back along -x: at his collar
	await physics_frames(2)
	await physics_frames(60 * 5)  # (his pool started where he lies; the nod's lines said)
	var said: Array[String] = []
	var heard := func(who: Node, text: String) -> void:
		if who == m.sheriff:
			said.append(text)
	Events.spoke.connect(heard)
	Input.action_press(&"shove")
	await physics_frames(1)
	Input.action_release(&"shove")
	await physics_frames(3)
	check(p.carry.carrying(m.sheriff) and m.sheriff.carried, "a tap of E: you take him up (%s)" % p.carry.report())
	await physics_frames(60)  # (lifted)
	var marks := get_tree().get_nodes_in_group(&"blood_marks").size()
	var bleed := m.phys.total_bleed_rate()
	var h0 := m.clock().time_of_day
	p.rotation.y = atan2(-1.0, 0.0)
	Input.action_press(&"move_forward")
	var low := INF
	for i in 10:
		await physics_frames(60)
		var ground := m._ground(p.global_position.x, p.global_position.z)
		for v: Variant in m.sheriff.parts.values():
			low = minf(low, (v as Node3D).global_position.y - ground)
	Input.action_release(&"move_forward")
	var hours := m.clock().time_of_day - h0
	var rate := 10.0 / m.phys.tuning.game_hour_seconds * float(_data().clock_scale)
	check(absf(hours - rate) < rate * 0.1, "10 s carrying him: %.4f game hours (the prologue's rate %.4f, #1082)" % [hours, rate])
	check(p.carry.dragged_m > 6.0, "carried him (%.1f m)" % p.carry.dragged_m)
	check(low > 0.15, "clear of the ground all the way (his lowest part %.2f m up)" % low)
	check(bleed > 0.5 and get_tree().get_nodes_in_group(&"blood_marks").size() == marks,
			"bleeding (%.2f ml/s) but no blood left on the ground (%d marks, %d before)" % [bleed, get_tree().get_nodes_in_group(&"blood_marks").size(), marks])
	if OS.has_environment("CARRY_DEBUG"):
		var f := p.get_forward()
		f.y = 0.0
		f = f.normalized()
		var r := f.cross(Vector3.UP)
		for sid: Variant in m.sheriff.parts:
			var d := (m.sheriff.parts[sid] as Node3D).global_position - p.global_position
			print("      %s fwd %.2f right %.2f up %.2f" % [sid, d.dot(f), d.dot(r), d.y])
	var head := (m.sheriff.parts[&"head"] as Node3D).global_position - p.global_position
	var fwd := p.get_forward()
	check(head.dot(fwd) < 0.0, "his head down your back (%.2f along your view)" % head.dot(fwd))
	check(p.carry.blood_on_you > 0.0, "his blood on you (%s)" % p.carry.report())
	Events.spoke.disconnect(heard)
	check(said.count("Don't let me lie here.") == 1 and said.size() == 1,
			"over your shoulder: his word once as you take him up, then quiet a while (%s)" % [said])
	# Laid down: in front of you, on the ground; his blood pools there again.
	Input.action_press(&"shove")
	await physics_frames(1)
	Input.action_release(&"shove")
	await physics_frames(60)
	check(not p.carry.carrying() and not m.sheriff.carried, "a tap again: laid down (%s)" % p.carry.report())
	var laid := ValleyFolk._body_at(m.sheriff)
	check(laid.y - m._ground(laid.x, laid.z) < 0.45, "on the ground (%.2f m up)" % (laid.y - m._ground(laid.x, laid.z)))
	check((laid - p.global_position).dot(p.get_forward()) > 0.2, "in front of you (%.2f m along your view)" % (laid - p.global_position).dot(p.get_forward()))


## Enter after (or held): the scene starts again from dawn with the story as it stood when it
## began (#864): an earlier fact kept, what the try set gone.
func test_a_restart_starts_it_from_the_story_as_it_began() -> void:
	StoryState.clear()
	StoryState.set_fact("earlier.thing", true)
	var m := await _start()
	check(m != null, "started")
	if m == null:
		return
	StoryState.set_fact("sheriff.care", "left him")
	StoryState.set_fact("during.try", true)
	var pl := get_tree().get_first_node_in_group(&"player") as Player
	if pl and pl.carry:
		pl.carry.dragged_m = 488.3
		pl.carry.blood_on_you = 6.0
	var again := m.restart() as SheriffOnRoad
	await physics_frames(10)
	check(again != null and not again.done, "started again")
	if pl and pl.carry:
		check(pl.carry.dragged_m == 0.0 and pl.carry.blood_on_you == 0.0,
				"the last run's carry gone (#1116: %.1f m, %.1f blood)" % [pl.carry.dragged_m, pl.carry.blood_on_you])
	check(StoryState.has_fact("earlier.thing"), "the earlier fact kept")
	check(not StoryState.has_fact("during.try"), "the try's fact gone")
	check(not StoryState.has_fact("sheriff.care"), "no care yet")
