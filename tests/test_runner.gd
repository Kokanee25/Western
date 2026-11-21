extends TestCase
## The runner (townsfolk step 6, #1040; docs/briefs/townsfolk.md §4 "Who runs, and to whom", §8's
## runner row): a man down, one of those who saw it runs for help.
## - one runner an event: the calm one with the most duty; the second who'd go sees him gone and
##   stays (kneels by the man);
## - he runs to the doctor and says it there; the doctor takes his bag and comes at a fast walk, then
##   tends him;
## - the runner row: from the shot to the doctor leaving his door, the run itself within 20 % of the
##   walk's length at a run (Reaction.RUN), the rest the fixed beats (his start and look, the shots
##   stopping, the bag);
## - a man dead is for the law: none on night 1 ("Ain't nobody left to fetch": nobody runs); with the
##   badge, Harlan if he was seen within the hour, else the doctor.

var world: Node3D
var fetch: FetchHelp
var news: TownNews
var said: Array = []


class Stepper:
	extends Node
	var fetch: FetchHelp
	var news: TownNews

	func _physics_process(delta: float) -> void:
		fetch.step(delta)
		news.step(delta)


func before_each() -> void:
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
	fetch = FetchHelp.new()
	news = TownNews.new()
	var st := Stepper.new()
	st.fetch = fetch
	st.news = news
	world.add_child(st)
	said.clear()
	Events.spoke.connect(_on_spoke)


func after_each() -> void:
	Events.spoke.disconnect(_on_spoke)
	world.queue_free()
	await physics_frames(2)


func _on_spoke(who: Node, text: String) -> void:
	said.append([String((who as HumanBody).person_id) if who is HumanBody else "", text])


func _man(id: String, seed_value: int, at: Vector3, faces: Vector3, dials := {}) -> CivilianBrain:
	var man := HumanBody.new()
	man.body_model = &"storekeeper_s1_talking"
	man.person_id = StringName(id)
	man.rng_seed = seed_value
	man.has_gun = false
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = at
	brain.faces = faces
	for k: String in dials:
		brain.dials[k] = dials[k]
	brain.fetch = fetch
	man.add_child(brain)
	news.join(brain)
	world.add_child(man)
	man.global_position = at
	man.face(faces)
	return brain


## The victim, two dutiful men who see him (the steadier the more dutiful), a nosy one, and the
## doctor far off (out of sight of it), facing away.
func _scene(doc_at := Vector3(36.0, 0.0, 0.0)) -> Dictionary:
	var victim := _man("victim", 71, Vector3.ZERO, Vector3(0.0, 1.5, 5.0))
	var first := _man("first", 81, Vector3(-4.0, 0.0, 9.0), Vector3(0.0, 1.5, 0.0), {"nerve": 0.95, "nosy": 0.2, "duty": 1.0})
	var second := _man("second", 82, Vector3(4.0, 0.0, 9.0), Vector3(0.0, 1.5, 0.0), {"nerve": 0.95, "nosy": 0.2, "duty": 0.8})
	var nosy := _man("nosy", 83, Vector3(-9.0, 0.0, -3.0), Vector3(0.0, 1.5, 0.0), {"nerve": 0.8, "nosy": 0.9, "duty": 0.3})
	# Indoors at his work: a runner goes to his door, and he comes out of it when he's told.
	fetch.doctor_door = doc_at
	fetch.bring = func() -> HumanBody:
		return _man("doctor", 901, doc_at, doc_at + Vector3(10.0, 1.5, 0.0), {"nerve": 0.9, "nosy": 0.3, "duty": 1.0}).body
	var ok := await wait_until(func() -> bool:
		for b in [first, second, nosy]:
			if not b.senses.sees(victim.body):
				return false
		return true, 60 * 4)
	check(ok, "they see him standing there")
	return {"victim": victim, "first": first, "second": second, "nosy": nosy}


func test_one_runner_for_the_doctor_and_he_comes_with_his_bag() -> void:
	fetch.law = false
	var s: Dictionary = await _scene()
	var victim: CivilianBrain = s.victim
	var first: CivilianBrain = s.first
	var second: CivilianBrain = s.second
	var f0 := Engine.get_physics_frames()
	Events.noise.emit(Vector3(0.0, 1.5, -4.0), DeedWatch.GUNSHOT, &"gunshot", null)
	victim.body.physiology.alive = true
	Events.person_fell.emit(victim.body, false)
	var left := await wait_until(func() -> bool: return fetch.trail.any(func(l: Array) -> bool: return l[1] == "doctor leaves"), 60 * 40)
	check(left, "the doctor comes (%s)" % [fetch.report()])
	var doc := fetch.doctor.get_node(^"Brain") as CivilianBrain if fetch.doctor else null
	if doc == null:
		return
	var rep := fetch.report()
	check_eq(rep.events.size(), 1, "one runner an event")
	if rep.events.is_empty():
		return
	var e: Dictionary = rep.events[0]
	check_eq(e.runner, "first", "the calm man with the most duty runs")
	check_eq(e.to, "doctor", "for the doctor")
	check_eq(second.reaction.choice, &"help", "the second saw him go and stayed: down by the man (%s)" % second.reaction.describe())
	check(not said.any(func(x: Array) -> bool: return x[0] == "doctor" or x[0] == "second" and String(x[1]).begins_with("Doc")), "only the runner tells the doctor")
	check(not s.nosy.reaction.choice == &"run", "the nosy man doesn't run")
	# The runner row: the run against the walk at a run; from the shot, the run and the fixed beats.
	var walk := float(e.route_m) / Reaction.RUN
	var run := float(e.told_frame - e.ran_frame) / 60.0
	var shot_to_left := float(e.left_frame - f0) / 60.0
	var beats := Reaction.START_SOONEST + Reaction.START_NERVE + Reaction.LOOK_FOR.y + Reaction.SHOOTER_GONE + FetchHelp.BAG_BEAT
	print("  the runner: %.1f m way, walk at a run %.1f s, ran %.1f s; shot to the doctor leaving %.1f s (beats at most %.1f s)" % [
			e.route_m, walk, run, shot_to_left, beats])
	check(absf(run - walk) <= walk * 0.2, "the run within 20%% of the walk (%.1f s against %.1f s)" % [run, walk])
	check(shot_to_left <= walk * 1.2 + beats + 0.5, "from the shot to the doctor leaving: the walk and the beats (%.1f s)" % shot_to_left)
	check(said.any(func(x: Array) -> bool: return x[0] == "first" and String(x[1]).begins_with("Doc")), "he tells the doctor (%s)" % [said])
	check(said.any(func(x: Array) -> bool: return x[0] == "first" and String(x[1]).contains("shot")), "a shot, as he heard it (%s)" % [said])
	# The news goes with him (TownNews, #1051): the doctor holds the runner's version, told by him.
	var dv := news.version_of(&"doctor", int(news._record_of(&"victim").get("id", 0)))
	check_eq(String(dv.get("by", "")), "first", "the doctor has it from the runner (%s)" % [news.report().versions.get("doctor", {})])
	check(bool(dv.get("down", false)), "a man down, as the runner saw him")
	# The doctor at a fast walk with his bag, then tends him.
	var bag := world.get_node_or_null(^"DoctorsBag") as Node3D
	check(bag != null, "his bag")
	var t0 := Engine.get_physics_frames()
	var p0 := doc.body.global_position
	await physics_frames(60 * 4)
	var pace := doc.body.global_position.distance_to(p0) / 4.0
	check(pace > Reaction.WALK + 0.2, "a fast walk (%.2f m/s)" % pace)
	if bag:
		check(bag.global_position.distance_to(doc.body.global_position) < 0.8, "the bag in his hand")
	var there := await wait_until(func() -> bool: return doc.body.pose == &"tend", 60 * 40)
	check(there, "he tends him (%.1f m off, %s)" % [doc.body.global_position.distance_to(victim.body.global_position), doc.describe()])
	check(doc.body.global_position.distance_to(victim.body.global_position) < 1.5, "beside him")
	if bag:
		check(bag.global_position.y < 0.3, "his bag set down")
	print("  the doctor: %.1f m/s, beside him %.1f s after he left" % [pace, float(Engine.get_physics_frames() - t0) / 60.0 + 0.0])


func test_a_man_dead_on_night_1_nobody_runs() -> void:
	fetch.law = false
	var s: Dictionary = await _scene()
	var victim: CivilianBrain = s.victim
	Events.noise.emit(Vector3(0.0, 1.5, -4.0), DeedWatch.GUNSHOT, &"gunshot", null)
	victim.body.physiology.alive = false
	Events.person_died.emit(victim.body, &"shot")
	await physics_frames(60 * 10)
	check(fetch.events.is_empty(), "ain't nobody left to fetch: nobody runs (%s)" % [fetch.report()])
	for b: CivilianBrain in [s.first, s.second, s.nosy]:
		check(b.reaction.choice != &"run", "%s stays (%s)" % [b.body.person_id, b.reaction.describe()])


func test_with_the_badge_a_man_dead_they_run_to_harlan_or_else_the_doctor() -> void:
	fetch.law = true
	var you := Node3D.new()
	you.add_to_group(&"player")
	world.add_child(you)
	you.global_position = Vector3(-30.0, 0.0, 20.0)
	var s: Dictionary = await _scene()
	fetch.harlan_at = you.global_position
	fetch.harlan_when = fetch._clock_s
	var victim: CivilianBrain = s.victim
	Events.noise.emit(Vector3(0.0, 1.5, -4.0), DeedWatch.GUNSHOT, &"gunshot", null)
	victim.body.physiology.alive = false
	Events.person_died.emit(victim.body, &"shot")
	var told := await wait_until(func() -> bool: return fetch.trail.any(func(l: Array) -> bool: return l[1] == "told harlan"), 60 * 30)
	check(told, "they run to Harlan, seen lately (%s)" % [fetch.report()])
	check(said.any(func(x: Array) -> bool: return String(x[1]).begins_with("Deputy!")), "Deputy! (%s)" % [said])
	check(fetch.calls.is_empty(), "nobody brings the doctor for a dead man when the law's been told")
	# Not seen within the hour: the doctor, the acting law.
	fetch.events.clear()
	fetch.harlan_when = fetch._clock_s - Reaction.SHAKEN_SECONDS * 2.0
	var e := fetch.errand_for(victim.body)
	check_eq(e.get("to"), &"doctor", "Harlan not seen within the hour: the doctor")
	you.queue_free()


func test_too_frightened_to_go_he_runs_once_he_comes_back_to_himself() -> void:
	fetch.law = false
	fetch.doctor_door = Vector3(30.0, 0.0, 20.0)
	fetch.bring = func() -> HumanBody:
		return _man("doctor", 901, Vector3(30.0, 0.0, 20.0), Vector3(40.0, 1.5, 20.0), {"nerve": 0.9, "nosy": 0.3, "duty": 1.0}).body
	var victim := _man("victim", 71, Vector3.ZERO, Vector3(0.0, 1.5, 5.0))
	var timid := _man("timid", 85, Vector3(-3.0, 0.0, 5.0), Vector3(0.0, 1.5, 0.0), {"nerve": 0.3, "nosy": 0.2, "duty": 0.9})
	await wait_until(func() -> bool: return timid.senses.sees(victim.body), 60 * 4)
	Events.noise.emit(Vector3(0.0, 1.5, -3.0), DeedWatch.GUNSHOT, &"gunshot", null)
	Events.person_fell.emit(victim.body, false)
	await physics_frames(60 * 4)
	check(timid.reaction.choice in [&"hide", &"flee"], "close to it, he gets down (%s)" % timid.reaction.describe())
	check(fetch.events.is_empty(), "nobody's gone yet")
	var calm := Reaction.CALM_HIDE + Reaction.CALM_HIDE_NERVE * 0.7 + Reaction.LOOK_ROUND.y
	var ran := await wait_until(func() -> bool: return timid.reaction.choice == &"run", int((calm + 4.0) * 60))
	check(ran, "come back to himself, he runs for the doctor (%s)" % timid.reaction.describe())
	var left := await wait_until(func() -> bool: return fetch.trail.any(func(l: Array) -> bool: return l[1] == "doctor leaves"), 60 * 30)
	check(left, "and the doctor comes (%s)" % [fetch.report()])
