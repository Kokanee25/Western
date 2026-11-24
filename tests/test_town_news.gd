extends TestCase
## The town's news (townsfolk step 7, #1051; docs/briefs/townsfolk.md §5 "The town's news", §8's news
## row): TownNews.
## - a shooting: one record, and each man's version only what he sensed (the witness who saw it has
##   who and whom; the man facing away heard shots and no more; the man out of earshot nothing);
## - two calm men within 3 m pass the biggest piece in 6-10 s; a man further off doesn't get it;
## - overnight the big news reaches everyone as told, 20-40 % of versions wrong in a slot, the small
##   told news fades, what nobody sensed stays unknown; the next day's kind (`uneasy`) from it, a
##   story act's killing not counted;
## - what the town makes of Harlan by the versions (stopped a killer, or shot a man), and the line a
##   man says of his own version.

var world: Node3D
var news: TownNews


class Stepper:
	extends Node
	var news: TownNews

	func _physics_process(delta: float) -> void:
		news.step(delta)


func before_each() -> void:
	StoryState.clear("news.")
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1200, 1, 1200)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	news = TownNews.new()
	var st := Stepper.new()
	st.news = news
	world.add_child(st)


func after_each() -> void:
	StoryState.clear("news.")
	world.queue_free()
	await physics_frames(2)


func _man(id: String, seed_value: int, at: Vector3, faces: Vector3, dials := {"nerve": 0.9, "nosy": 0.2, "duty": 0.3}) -> CivilianBrain:
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
	man.add_child(brain)
	world.add_child(man)
	man.global_position = at
	man.face(faces)
	news.join(brain)
	return brain


## A record and a full version of it held by `pid` (as he'd have it had he seen it all).
func _seen(pid: StringName, what: StringName, who: StringName, whom: StringName, first: StringName, shots: int, dead: bool) -> int:
	var r := news._new_record(what, Vector3.ZERO)
	r.who = who
	r.whom = whom
	r.first = first
	r.shots = shots
	var v := news._version(pid, r, &"saw")
	v.who = who
	v.whom = whom
	v.first = first
	v.shots = shots
	v.down = whom != &""
	v.dead = dead
	v.where = "the store"
	return int(r.id)


func test_a_shooting_each_holds_only_what_he_sensed() -> void:
	var gunman := _man("gunman", 11, Vector3(0.0, 0.0, -3.0), Vector3(0.0, 1.5, 0.0))
	var victim := _man("victim", 12, Vector3.ZERO, Vector3(0.0, 1.5, -3.0))
	var witness := _man("witness", 13, Vector3(5.0, 0.0, 6.0), Vector3(0.0, 1.5, -1.5))
	var away := _man("away", 14, Vector3(-6.0, 0.0, 9.0), Vector3(-6.0, 1.5, 40.0))
	var far := _man("far", 15, Vector3(500.0, 0.0, 0.0), Vector3(520.0, 1.5, 0.0))
	var ok := await wait_until(func() -> bool: return witness.senses.sees(gunman.body) and witness.senses.sees(victim.body), 60 * 4)
	check(ok, "the witness sees them both")
	check(not away.senses.sees(gunman.body), "the other faces away")
	Events.noise.emit(gunman.body.global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", gunman.body)
	Events.deed.emit(gunman.body, &"hit", victim.body, victim.body.global_position + Vector3.UP)
	Events.person_fell.emit(victim.body, false)
	await physics_frames(3)
	var a1 := news.version_of(&"away", 1)
	check_eq(String(a1.get("how", "")), "heard", "the man facing away heard the first shot (%s)" % [a1])
	check_eq(String(a1.get("who", "x")), "", "no shooter: he didn't see him fire")
	await physics_frames(30)
	Events.noise.emit(gunman.body.global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", gunman.body)
	await physics_frames(60)
	check_eq(news.records.size(), 1, "one record (%s)" % [news.report().records])
	if news.records.is_empty():
		return
	var r: Dictionary = news.records[0]
	check_eq(String(r.what), "shooting", "a shooting")
	check_eq(String(r.who), "gunman", "the truth: who")
	check_eq(String(r.whom), "victim", "the truth: whom")
	check_eq(int(r.shots), 2, "two shots")
	var w := news.version_of(&"witness", 1)
	check_eq(String(w.get("how", "")), "saw", "the witness saw it")
	check_eq(String(w.get("who", "")), "gunman", "he has who")
	check_eq(String(w.get("whom", "")), "victim", "and whom")
	check_eq(String(w.get("first", "")), "gunman", "and who fired first")
	var a := news.version_of(&"away", 1)
	# He turned to the first shot: the second he may have seen fired (that he sensed), the first not.
	check_eq(String(a.get("first", "x")), "", "he didn't see who fired first (%s)" % [a])
	check(a.get("who", &"") == &"" or a.get("how", &"") == &"saw", "a shooter only if he saw one fire")
	check_eq(String(a.get("whom", "x")), "", "no man down: he never saw him fall")
	check_eq(int(a.get("shots", 0)), 2, "he heard two shots")
	check(news.version_of(&"far", 1).is_empty(), "out of earshot, nothing")
	check(news.version_of(&"gunman", 1).get("who", &"") != &"gunman" or news.version_of(&"gunman", 1).is_empty(), "the shooter's own isn't by sight of himself")
	far.body.queue_free()
	away.body.queue_free()


func test_two_calm_men_pass_it_on_and_a_third_further_off_doesnt() -> void:
	var a := _man("teller", 21, Vector3(0.0, 0.0, 0.0), Vector3(2.0, 1.5, 0.0))
	var b := _man("hearer", 22, Vector3(2.0, 0.0, 0.0), Vector3(0.0, 1.5, 0.0))
	var c := _man("apart", 23, Vector3(0.0, 0.0, 12.0), Vector3(0.0, 1.5, 20.0))
	await physics_frames(10)
	var rid := _seen(&"teller", &"killing", &"gunman", &"victim", &"gunman", 2, true)
	var t0 := Engine.get_physics_frames()
	var got := await wait_until(func() -> bool: return not news.version_of(&"hearer", rid).is_empty(), 60 * 14)
	var took := float(Engine.get_physics_frames() - t0) / 60.0
	check(got, "the hearer has it (%s)" % [news.report()])
	check(took >= TownNews.TALK_S.x and took <= TownNews.TALK_S.y + TownNews.LOOK_EVERY + 0.2, "it took a talk's time (%.1f s)" % took)
	var v := news.version_of(&"hearer", rid)
	check_eq(String(v.get("how", "")), "told", "told")
	check_eq(String(v.get("by", "")), "teller", "by the teller")
	check(news.version_of(&"apart", rid).is_empty(), "the man 12 m off hasn't got it")
	check(news.trail.any(func(l: Array) -> bool: return l[1] == "talk"), "they talked")
	c.body.queue_free()
	a.body.queue_free()
	b.body.queue_free()


func test_overnight_the_big_news_reaches_everyone_a_bit_wrong_and_the_day_is_uneasy() -> void:
	for i in 200:
		news.town.append(StringName("folk_%d" % i))
	var big := _seen(&"folk_0", &"killing", TownNews.HARLAN, &"earl_like", &"earl_like", 2, true)
	# A small thing, only told on: it fades. And something nobody sensed: it stays unknown.
	var small := _seen(&"folk_1", &"shots", &"", &"", &"", 1, false)
	news._told(&"folk_1", &"folk_2", small)
	var unseen := news._new_record(&"killing", Vector3(80.0, 0.0, 0.0))
	unseen.who = TownNews.HARLAN
	unseen.whom = &"nobody_saw"
	news.overnight()
	var holders := 0
	var wrong := 0
	for i in 200:
		var v := news.version_of(StringName("folk_%d" % i), big)
		if v.is_empty():
			continue
		holders += 1
		if i > 0 and (v.who != TownNews.HARLAN or v.first != &"earl_like" or int(v.shots) != 2 or v.where == ""):
			wrong += 1
	check_eq(holders, 200, "all hold the killing by morning")
	var share := float(wrong) / 199.0
	print("  overnight: %d of 199 told versions differ from the truth in a slot (%.0f %%)" % [wrong, share * 100.0])
	check(share >= 0.2 and share <= 0.4, "20-40 %% of versions differ (%.0f %%)" % [share * 100.0])
	check(news.version_of(&"folk_2", small).is_empty(), "the small told news faded")
	check(not news.version_of(&"folk_1", small).is_empty(), "the man who heard it himself still has it")
	for pid: StringName in news.versions:
		check(news.version_of(pid, int(unseen.id)).is_empty(), "nobody holds what nobody sensed (%s)" % pid)
	check_eq(String(StoryState.get_fact("news.yesterday", "")), "killing", "the town's yesterday: a killing")
	var vf := ValleyFolk.new()
	vf.data = JSON.parse_string(FileAccess.get_file_as_string(ValleyFolk.DATA))
	check_eq(String(vf.day_kind(2)), "uneasy", "the next day's kind: uneasy")
	StoryState.clear("news.")
	check_eq(String(vf.day_kind(2)), "ordinary", "without it, ordinary")
	vf.free()


func test_a_story_act_s_killing_doesnt_make_the_day() -> void:
	news.town = [&"a", &"b"]
	news.story_men = [&"cody"]
	var rid := _seen(&"a", &"killing", &"cody", &"earl", &"cody", 2, true)
	news.records[rid - 1].story = true
	news.overnight()
	check(not news.version_of(&"b", rid).is_empty(), "it travels")
	check(not StoryState.has_fact("news.yesterday"), "but the story's day is the story's")
	check_eq(news.to_say(&"a"), 0, "and its lines are the script's")


func test_what_the_town_makes_of_harlan() -> void:
	# Three saw him shoot a man who'd fired first; one saw only Harlan's shot.
	var rid := _seen(&"p1", &"killing", TownNews.HARLAN, &"badman", &"badman", 3, true)
	for pid: StringName in [&"p2", &"p3"]:
		var v: Dictionary = news.version_of(&"p1", rid).duplicate()
		(news.versions.get_or_add(pid, {}) as Dictionary)[rid] = v
	var v4: Dictionary = news.version_of(&"p1", rid).duplicate()
	v4.first = TownNews.HARLAN
	(news.versions.get_or_add(&"p4", {}) as Dictionary)[rid] = v4
	check_eq(String(news.view_of_harlan(&"p1")), "stopped_a_killer", "the man who saw the other draw first")
	check_eq(String(news.view_of_harlan(&"p4")), "shot_a_man", "the man who saw only Harlan fire")
	check_eq(String(news.town_view_of_harlan()), "stopped_a_killer", "the town: three to one")
	check_eq(String(news.said_did_it(&"badman")), "harlan", "the town says Harlan did it")
	var line := news.line_of(&"p1", rid, TownNews.HARLAN)
	check(line.begins_with("You shot"), "to his face (%s)" % line)
	check(line.contains("drew first"), "and that the other drew first (%s)" % line)
	news.overnight()
	check_eq(String(StoryState.get_fact("news.harlan", "")), "stopped_a_killer", "the next day's word on him")


## #1213 (gate 4, run 4): a shot in the air in the saloon, nobody hit. A man who saw who fired says so ("you"
## to his face), not "whoever it was"; a man who only heard it says shooting, as before; saw_fire holds who
## he saw, for his relief.
func test_shots_nobody_hit_who_fired_if_he_saw() -> void:
	var rid := _seen(&"p1", &"shots", TownNews.HARLAN, &"", &"", 1, false)
	var to_him := news.line_of(&"p1", rid, TownNews.HARLAN)
	check(to_him.begins_with("You") or to_him.begins_with("That was you"), "to his face: you (%s)" % to_him)
	var to_other := news.line_of(&"p1", rid, &"p2")
	check(to_other.to_lower().contains("the new man") and not to_other.to_lower().contains("whoever"), "of him: the new man (%s)" % to_other)
	StoryState.set_fact("nolaw.deputy", true, 1, 12.0)
	var dep := news.line_of(&"p1", rid, &"p2")
	check(dep.to_lower().contains("the deputy"), "once he's the deputy (%s)" % dep)
	StoryState.clear("nolaw.")
	check_eq(String(news.saw_fire(&"p1")), "harlan", "he saw Harlan fire")
	# Heard only: no who.
	var r2 := news._new_record(&"shots", Vector3(200, 0, 0))
	r2.shots = 1
	var v := news._version(&"p3", r2, &"heard")
	v.shots = 1
	v.where = "the saloon"
	var heard := news.line_of(&"p3", int(r2.id), &"p2")
	check(heard.to_lower().contains("shooting") or heard.to_lower().contains("somebody"), "heard only: shooting (%s)" % heard)
	check_eq(String(news.saw_fire(&"p3")), "", "heard, not seen")
