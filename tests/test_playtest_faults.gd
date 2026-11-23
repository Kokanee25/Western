extends TestCase
## The blind playtest's faults (#1095; docs/playtests/2026-11-19-slice-run2.md): one doctor, who answers
## his door to any hurt man brought him and takes him in; the knock's prompt only at a door worth
## banging on, from outside it; Earl at the undertaker's stays there (not back at the cards); what
## broke said as what it was; when you go down, what hit you; the sheriff's mutters over your
## shoulder spread out. Each sets its own state (no physics luck).

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear("nolaw.")
	StoryState.clear("sheriff.")
	StoryState.clear("death.")
	if holder != null:
		holder.queue_free()
		await physics_frames(3)
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	ValleyFolk.murder_auto = true
	Input.action_release(&"shove")


func _folk() -> ValleyFolk:
	return valley.folk


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _at(h: float) -> void:
	(valley.get_node(^"DayCycle") as DayCycle).set_time(h)
	await physics_frames(1)
	_folk()._look = 0.0
	await physics_frames(60)


## Into the building from the doctor's door point (its +z), `m` metres.
func _doctor_in(m: float) -> Vector3:
	var f := _folk()
	var door := f.places.at(&"doctor")
	var into := ((valley.buildings as Dictionary).get("doctor") as Node3D).global_basis.z
	into.y = 0.0
	var at := door + into.normalized() * m
	at.y = door.y + 0.05
	return at


## You at the doctor's door, outside it, facing it.
func _at_door() -> void:
	var p := _player()
	var at := _doctor_in(-0.9)
	var door := _folk().places.at(&"doctor")
	p.global_position = at
	p.velocity = Vector3.ZERO
	var to := door - at
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(3)


## A townsman out of his day (no brain), stood by the doctor's door and bleeding slowly from a vein
## in his forearm: the hurt man brought.
func _hurt_man_by_door(id: StringName) -> HumanBody:
	var f := _folk()
	var door := f.places.at(&"doctor")
	var side := ((valley.buildings as Dictionary).get("doctor") as Node3D).global_basis.x
	side.y = 0.0
	var at := door + (door - _doctor_in(1.0)) + side.normalized() * 1.6
	at.y = f.ground(at.x, at.z)
	var man := f.seize(id, at, door)
	if man != null:
		man.physiology._add_bleed(&"radial_l", &"forearm_l", 0.6, &"vein")
	return man


func test_one_doctor() -> void:
	var f := _folk()
	check(f._person(&"doc").is_empty(), "no second doctor (`doc`) in the folk")
	check_eq(FetchHelp.DOCTORS, [FetchHelp.DOCTOR] as Array[StringName], "FetchHelp's one doctor")
	await _at(10.0)
	var man := f.take(&"doctor", _doctor_in(3.0), _doctor_in(5.0))
	check(man != null and man == f.folk_man(&"doctor"), "an act takes the town's doctor off his day")
	check(f.state.get(&"doctor") == &"act" and not f.book.inside(&"doctor").has(&"doctor"), "his day waits (%s)" % f.state.get(&"doctor"))
	# (His morning is a round of calls since #1167: held on its leg in at his own door for this.)
	f._legs[&"doctor"] = {"base": 7.0, "i": 0, "until": 1.0e9, "since": f._ran, "n": 0}
	f.release(&"doctor")
	check(f.state.get(&"doctor") == &"out", "given back to his day, not freed (%s)" % f.state.get(&"doctor"))
	f._look = 0.0
	await physics_frames(30)
	check(f.book.inside(&"doctor").has(&"doctor"), "back on the book in his building (%s)" % [f.book.inside(&"doctor")])


func test_the_doctor_answers_his_door_to_any_hurt_man() -> void:
	await _at(22.5)
	var f := _folk()
	check(f.book.inside(&"doctor").has(&"doctor"), "the doctor's in")
	var man := _hurt_man_by_door(&"miner")
	check(man != null, "the miner by the door, bleeding")
	if man == null:
		return
	await _at_door()
	var p := _player()
	check(not p.knock.door_here().is_empty(), "a door to bang on (%s)" % p.knock.report())
	var shown: Array[String] = []
	p.wounds.shown.connect(func(text: String) -> void: shown.append(text))
	p.knock.bang()
	check(shown.any(func(x: String) -> bool: return x.contains("doctor's coming")), "told he's coming (%s)" % [shown])
	var took := await wait_until(func() -> bool: return f.taken_in.has("miner"), 60 * 40)
	check(took, "the doctor takes him in (%s; calls %s)" % [f.fetch.report().get("log"), f.fetch.report().get("calls")])
	check(f.past_door(&"doctor", ValleyFolk._body_at(man)), "he's inside, past the door (%s)" % ValleyFolk._body_at(man))
	check(man.physiology.alive, "alive (treating him is #1093)")
	check(f.fetch.calls.is_empty(), "the doctor's call over")


func test_the_doctor_comes_back_from_a_call_to_the_man_you_brought() -> void:
	await _at(22.5)
	var f := _folk()
	var man := _hurt_man_by_door(&"miner")
	if man == null:
		check(false, "no miner")
		return
	# Called to him where he fell (the saloon's yard): out of his door and walking there.
	var yard := f.places.at(&"saloon") if f.places.has(&"saloon") else man.global_position + Vector3(40, 0, 0)
	man.global_position = Vector3(yard.x, f.ground(yard.x, yard.z), yard.z)
	f.fetch._call_doctor(man)
	var out := await wait_until(func() -> bool: return f.fetch.calls.size() == 1 and f.fetch.calls[0].stage == &"walk", 60 * 10)
	check(out, "the doctor's out on the call (%s)" % [f.fetch.report()])
	await physics_frames(60)
	# You've brought him to the door meanwhile.
	var door := f.places.at(&"doctor")
	var at := door + (door - _doctor_in(1.0)) * 1.5
	at.y = f.ground(at.x, at.z)
	man.global_position = at
	await _at_door()
	_player().knock.bang()
	check(f.fetch.calls.size() == 1 and f.fetch.calls[0].get("door", false), "the call's now to the door (%s)" % [f.fetch.report()])
	var took := await wait_until(func() -> bool: return f.taken_in.has("miner"), 60 * 90)
	check(took, "he comes back and takes him in (%s)" % [f.fetch.report().get("log")])


func test_nobody_answers_with_no_doctor() -> void:
	await _at(22.5)
	var f := _folk()
	var doc := f.take(&"doctor", _doctor_in(3.0), _doctor_in(5.0))  # an act has him
	check(doc != null, "the doctor taken by an act")
	var man := _hurt_man_by_door(&"miner")
	await _at_door()
	var shown: Array[String] = []
	_player().wounds.shown.connect(func(text: String) -> void: shown.append(text))
	_player().knock.bang()
	check(shown.has("Nobody answers."), "nobody answers (%s)" % [shown])
	check(f.fetch.calls.is_empty(), "no call")


func test_the_knock_prompt_only_at_a_door_worth_banging_on() -> void:
	await _at(22.5)
	var f := _folk()
	var p := _player()
	await _at_door()
	check(p.knock.door_here().get("place", &"") == &"doctor", "outside his door, the doctor in: a door (%s)" % p.knock.report())
	# In past the doorway: no door.
	p.global_position = _doctor_in(1.6)
	await physics_frames(3)
	check(p.knock.door_here().is_empty(), "inside the doorway: no door to bang on (%s)" % p.knock.report())
	# Nobody in on the book and nobody by the collar: nothing to bang for.
	f.take(&"doctor", _doctor_in(3.0), _doctor_in(5.0))
	await _at_door()
	check(p.knock.door_here().is_empty(), "nobody in: no prompt (%s)" % p.knock.report())
	# The saloon has no door to bang on.
	check(f.no_knock(&"saloon") and f.no_knock(&"saloon_annex"), "the saloon's in no_knock")
	for pn: StringName in [&"saloon", &"saloon_annex"]:
		if f.places.has(pn):
			var at := f.places.at(pn)
			check(not f.door_near(at, Vector3.FORWARD, 3.0).get("place", &"") in [&"saloon", &"saloon_annex"], "no door at %s" % pn)


func test_earl_at_the_undertakers_stays_there() -> void:
	StoryState.set_fact("nolaw.earl", "undertaker")
	await _at(21.0)
	var f := _folk()
	check(f.gone_for_good.has(&"earl"), "Earl's gone for good")
	check(f.folk_man(&"earl") == null, "not at the cards")
	await _at(21.5)
	check(f.folk_man(&"earl") == null, "not later either")


func test_what_broke_is_said_as_it_was() -> void:
	check_eq(DevBridge._broke_text({"Raid_barrel" + DevBridge.LOOSE: 20}), "Raid_barrel went loose (fell whole)", "a prop gone loose")
	check_eq(DevBridge._broke_text({"Building_doctor": 2}), "Building_doctor: 2 members broke", "a building's members")


func test_down_says_what_hit_you() -> void:
	await _at(21.0)
	var p := _player()
	var f := _folk()
	var shooter := f.folk_man(&"barkeep")
	check(shooter != null, "the barkeep in the yard")
	check_eq(p.wounds.down_line(), "", "nothing yet")
	var chest := p.global_position + Vector3.UP * 1.3
	var dir := -p.global_basis.z
	p.wounds.take_bullet(null, chest - dir * 0.3, dir, 400.0, 0.0057)
	Events.deed.emit(shooter, &"hit", p, chest)
	var line := p.wounds.down_line()
	check(line.begins_with("The barkeep's ball.") and line.contains("Hit in the"), "where and by whom (%s)" % line)


func test_the_sheriffs_mutters_are_spread_out() -> void:
	var m := SheriffOnRoad.new()
	m.set_physics_process(false)
	m.set_process(false)
	add_child(m)
	m.data = JSON.parse_string(FileAccess.get_file_as_string("res://config/moments/the_sheriff.json"))
	var cd: Dictionary = m.data.get("carried", {})
	var all: Array = (m.data.lines.carried as Dictionary).get("clear", [])
	var got: Array[String] = []
	for i in all.size() + 3:
		var text := m._next_carried_line("clear", cd)
		if text != "":
			got.append(text)
	var unique := {}
	for g in got:
		unique[g] = true
	check(unique.size() == got.size(), "no line twice (%s)" % [got])
	check(not got.has("How far?"), "\"How far?\" only once he's been carried a way (%s)" % [got])
	check(got.size() == all.size() - 1, "each of the rest once, then silence (%s)" % [got])
	check(float(cd.get("grow", 0.0)) > 0.0, "the gaps grow")
	m.free()


## #1106 (playtest run 3): the No Justice start, as a player has it: the camp scene holds the doctor in
## his front office with Joe and the cowboy (`act`). A townsman hurt and brought to the door, a knock:
## the doctor still answers (he's lent back to the town, out of the scene), comes and takes him in.
## #1100's test had the plain valley, where nobody held him.
func test_the_doctor_answers_in_the_no_justice_start() -> void:
	StoryState.clear()
	var f := _folk()
	var m := Moment.start_named(&"no_justice_camp", valley, null, {"set_up": true}) as NoJusticeCamp
	check(m != null and not m.done and m.doctor != null, "the scene holds the doctor (%s)" % (m.result() if m else {}))
	if m == null or m.doctor == null:
		return
	await _at(10.5)
	check_eq(f.state.get(&"doctor"), &"act", "the scene has him")
	var man := _hurt_man_by_door(&"miner")
	check(man != null, "the miner by the door, bleeding")
	if man == null:
		return
	await _at_door()
	var p := _player()
	check(not p.knock.door_here().is_empty(), "a door to bang on (%s)" % p.knock.report())
	var shown: Array[String] = []
	p.wounds.shown.connect(func(text: String) -> void: shown.append(text))
	p.knock.bang()
	check(shown.any(func(x: String) -> bool: return x.contains("doctor's coming")), "told he's coming (%s)" % [shown])
	check(m.doctor == null, "the scene's let him go")
	var took := await wait_until(func() -> bool: return f.taken_in.has("miner"), 60 * 40)
	check(took, "the doctor takes him in (%s; calls %s)" % [f.fetch.report().get("log"), f.fetch.report().get("calls")])
	m.reset()

