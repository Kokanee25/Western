extends TestCase
## Regard and the barks (townsfolk step 9, #1152; docs/briefs/townsfolk.md §5, §8's barks row):
## - every line the picker may say has an `if` it understands, a speaker some townsman's pools hold;
## - the most specific line that fits wins; news he doesn't hold is never his to say;
## - once a day a person, nobody says a line another said within the minute, one bark a group;
## - a 10-minute walk past the town: no id twice from one person, none without its news;
## - regard: each man's band from his own view of Harlan and the story's facts, the town's the average;
## - what you see by band (a man in a plain world): a nod, a look away, a turned shoulder, a step aside.

const ONS := ["pass", "react.shot_far", "react.flee", "react.ring", "react.doc", "react.gun", "react.back", "undertaker"]
const KNOWN := ["on", "once", "regard", "view", "fact", "day", "hour", "spot", "at", "whom", "who_you", "shaken", "opinion"]
const FACTS := ["news.", "nolaw.", "sheriff.", "nojustice.", "kett."]

var world: Node3D


func before_each() -> void:
	StoryState.clear()


func after_each() -> void:
	StoryState.clear()
	if world != null and is_instance_valid(world):
		world.queue_free()
		world = null
		await physics_frames(2)


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ValleyFolk.DATA))


func _ctx(pid: String, more := {}) -> Dictionary:
	var c := {"pid": pid, "pools": ["townsman"], "band": "wary", "view": "", "hour": 13.0, "day_kind": "ordinary",
			"spot": "stand", "at": [], "shaken": false, "opinion": {}}
	c.merge(more, true)
	return c


func test_every_picked_line_has_an_if_the_picker_knows() -> void:
	var pools := {}
	for id: String in (_data().barks.pools as Dictionary):
		for p: String in _data().barks.pools[id]:
			pools[p] = true
	var n := 0
	for id: String in TownScript.meta():
		var c: Dictionary = TownScript.meta()[id]["if"]
		if c.is_empty():
			continue
		n += 1
		check(String(c.get("on", "")) in ONS, "%s: a moment that asks for it (%s)" % [id, c.get("on")])
		for k: String in c:
			check(k in KNOWN, "%s: a condition the picker knows (%s)" % [id, k])
		for f: String in (c.get("fact", {}) as Dictionary):
			var any := false
			for pre: String in FACTS:
				any = any or f.trim_prefix("!").begins_with(pre)
			check(any, "%s: a story fact (%s)" % [id, f])
		check(pools.has(String(TownScript.meta()[id].speaker)), "%s: somebody's pool speaks it (%s)" % [id, TownScript.meta()[id].speaker])
		check(not TownScript.words(id).is_empty(), "%s has words" % id)
	check(n >= 40, "the barks are wired (%d lines with an if)" % n)


func test_the_most_specific_line_wins() -> void:
	StoryState.set_fact("nolaw.deputy", true)
	# A warm man before ten who holds that Harlan stopped a killer: his news first, then the badge's
	# warm word, then the morning's.
	var c := _ctx("a", {"band": "warm", "hour": 8.0, "view": "stopped_a_killer"})
	var ids := TownBarks.fitting("pass", c)
	check(ids.size() >= 3 and ids[0] == "harlan.killer.nod", "his news first (%s)" % [ids])
	check(ids.find("deputy.first") >= 0 and ids.find("deputy.first") < ids.find("day.morning"), "the badge first seen before plain morning (%s)" % [ids])
	var wf := TownBarks.fitting("pass", _ctx("w", {"pools": ["townswoman"], "band": "warm"}))
	check(not wf.is_empty() and wf[0] == "deputy.for", "a warm woman: glad somebody's wearing it (%s)" % [wf])
	# A woman's pool first: her own line over the shared one.
	var w := _ctx("w", {"pools": ["townswoman"], "view": "shot_a_man"})
	check(TownBarks.fitting("pass", w)[0] == "harlan.shot.woman", "the woman's own (%s)" % [TownBarks.fitting("pass", w)])


func test_nobody_says_news_he_does_not_hold() -> void:
	StoryState.set_fact("news.harlan", "split")
	for id: String in TownBarks.fitting("pass", _ctx("a")):
		check(not id.begins_with("harlan."), "no view of Harlan, no line of him (%s)" % id)
	check(TownBarks.fitting("pass", _ctx("a", {"view": "shot_a_man"})).has("harlan.split"), "holding it, the town's split is his to say")
	check(TownBarks.fitting("react.ring", _ctx("a", {"whom": false}))[0] == "react.who", "not knowing who: 'Who is it?'")
	check(TownBarks.fitting("react.ring", _ctx("a", {"whom": true}))[0] == "react.knows", "knowing: 'It's ...'")
	check(TownBarks.fitting("undertaker", _ctx("u", {"pools": ["undertaker"], "whom": true, "who_you": true}))[0] == "undertaker.yours", "the undertaker's 'Yours, Deputy?' with Harlan firing in his version")
	check(TownBarks.fitting("undertaker", _ctx("u", {"pools": ["undertaker"], "whom": false, "who_you": false}))[0] == "undertaker.stranger", "nobody knows him: the county pays")


func test_once_a_day_a_person_and_not_another_s_line_within_the_minute() -> void:
	var b := TownBarks.new({"same_line_s": 60.0})
	var c := _ctx("a", {"band": "warm", "hour": 8.0})
	var first := b.pick("pass", c, 2, 0.0)
	check(not first.is_empty() and first[0] == "day.morning", "a warm morning (%s)" % [first])
	var again := b.pick("pass", c, 2, 30.0)
	check(again.is_empty() or again[0] != "day.morning", "not twice in a day (%s)" % [again])
	var other := b.pick("pass", _ctx("b", {"band": "warm", "hour": 8.0}), 2, 40.0)
	check(other.is_empty() or other[0] != "day.morning", "nobody says it within the minute of another (%s)" % [other])
	var later := b.pick("pass", _ctx("c", {"band": "warm", "hour": 8.0}), 2, 70.0)
	check(not later.is_empty() and later[0] == "day.morning", "a minute on, another may (%s)" % [later])
	var next_day := b.pick("pass", c, 3, 9000.0)
	check(not next_day.is_empty() and next_day[0] == "day.morning", "the next day, his morning again (%s)" % [next_day])
	StoryState.set_fact("nolaw.deputy", true)
	check(not b.pick("pass", _ctx("d"), 3, 9100.0).is_empty(), "the badge first seen")
	check(b.said_ever.get("d", {}).has("deputy.first"), "'Deputy, is it' is once for good")
	check(not b.allowed("d", "deputy.first", 9, 99999.0), "never again")


func test_one_bark_a_group() -> void:
	var b := TownBarks.new({"group_m": 4.0, "group_clear_m": 10.0})
	b.block(Vector3(0, 0, 0))
	check(b.blocked(Vector3(2.5, 0, 1.0)), "the man beside him keeps quiet")
	check(not b.blocked(Vector3(6.0, 0, 0)), "the next group may")
	b.clear_far(Vector3(4.0, 0, 0))
	check(b.blocked(Vector3(1.0, 0, 0)), "you're still by them")
	b.clear_far(Vector3(20.0, 0, 0))
	check(not b.blocked(Vector3(1.0, 0, 0)), "you've gone on: next time they may")


## §8's barks row: a 10-minute walk past a dozen men, each passed every 20 s: no line id twice from
## one person; nobody says news he doesn't hold; the groups one bark each pass.
func test_a_ten_minute_walk() -> void:
	StoryState.set_fact("nolaw.deputy", true)
	StoryState.set_fact("nolaw.sheriff", "dead")
	StoryState.set_fact("sheriff.care", "good")
	StoryState.set_fact("news.harlan", "split")
	var b := TownBarks.new(_data().barks)
	var pools: Dictionary = _data().barks.pools
	var men := ["barkeep", "storekeeper", "store_wife", "landlady", "loudmouth", "undertaker", "smith", "liveryman",
			"miner", "rancher", "drifter", "saloon_girl"]
	var views := ["stopped_a_killer", "shot_a_man", "", ""]
	var bands := ["warm", "wary", "cold", "afraid"]
	var by := {}
	var t := 0.0
	var n := 0
	while t < 600.0:
		for i in men.size():
			var pid: String = men[i]
			var c := _ctx(pid, {"pools": pools.get(pid, pools._default), "view": views[i % 4], "band": bands[(i / 2) % 4],
					"hour": 9.5 + t / 3600.0, "at": ["saloon"] if i % 3 == 0 else ["store"]})
			var l := b.pick("pass", c, 2, t + i * 0.5)
			if l.is_empty():
				continue
			n += 1
			if not by.has(pid):
				by[pid] = []
			check(not (by[pid] as Array).has(l[0]), "%s: %s not twice in the walk" % [pid, l[0]])
			by[pid].append(l[0])
			if String(l[0]).begins_with("harlan."):
				check(views[i % 4] != "", "%s holds the news he speaks (%s)" % [pid, l[0]])
		t += 20.0
	check(n >= 12, "the town spoke (%d lines in ten minutes)" % n)
	check(n < men.size() * 6, "and not without end (%d)" % n)


func test_regard_bands_from_his_own_news_and_the_facts() -> void:
	var r := TownRegard.new(null, _data().regard)
	check(r.band(&"x") == &"wary", "a man who holds nothing of him: wary (the man from up the creek)")
	r.view_of[&"a"] = "stopped_a_killer"
	check(r.band(&"a") == &"warm", "he stopped a killer: warm (%s)" % [r.opinions(&"a")])
	r.view_of[&"b"] = "shot_a_man"
	check(r.band(&"b") == &"cold", "he shot a man: cold (%s)" % [r.opinions(&"b")])
	r.view_of[&"c"] = "shot_a_man"
	r.shots_of[&"c"] = 3
	check(r.band(&"c") == &"afraid", "three men he has Harlan shooting: afraid (%s)" % [r.opinions(&"c")])
	StoryState.set_fact("sheriff.care", "left him")
	check(r.band(&"x") == &"cold", "he rode by the sheriff: cold (%s)" % [r.opinions(&"x")])
	StoryState.clear("sheriff.")
	StoryState.set_fact("nojustice.ending", "murder")
	check(r.band(&"undertaker") == &"cold" and r.band(&"x") == &"wary", "the surrendered man shot: the undertaker works it out, the rest don't")
	StoryState.clear("nojustice.")
	var o := r.town()
	var sum := 0.0
	for pid: StringName in r.people():
		sum += float(r.opinions(pid).trust)
	check(absf(float(o.trust) - sum / r.people().size()) < 0.001, "the town's the plain average")


func _man(at: Vector3, faces: Vector3) -> CivilianBrain:
	var man := HumanBody.new()
	man.body_model = &"storekeeper_s1_talking"
	man.person_id = &"m"
	man.rng_seed = 5
	man.has_gun = false
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = at
	brain.faces = faces
	man.add_child(brain)
	world.add_child(man)
	man.global_position = at
	man.face(faces)
	return brain


func _world() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


## What you see changes with his band: Harlan 4 m off, walking by; each band's show from the same
## start (facing the street, Harlan to his left).
func test_what_you_see_by_band() -> void:
	_world()
	var seen := {}
	for band: StringName in [&"warm", &"wary", &"cold", &"afraid"]:
		var b := _man(Vector3.ZERO, Vector3(0, 1.5, -5))
		var harlan := Node3D.new()
		world.add_child(harlan)
		harlan.global_position = Vector3(-4, 0, 0)
		harlan.rotation.y = PI / 2.0  # heading -X... past him
		await physics_frames(20)
		check(b.can_show(), "%s: calm at his post, he may show it" % band)
		var what: StringName = TownRegard.SHOWS[band]
		b.show_regard(what, harlan)
		var head := 0.0
		var yaw0 := b.body.global_rotation.y
		for i in (110 if band == &"afraid" else 70):
			await physics_frames(1)
			var off: Vector3 = b.body.pose_offsets.get(&"head", Vector3.ZERO)
			head = minf(head, off.x)
		var to_h := (harlan.global_position - b.body.global_position)
		to_h.y = 0.0
		var fwd := -b.body.global_basis.z
		fwd.y = 0.0
		var facing := fwd.normalized().dot(to_h.normalized())
		var moved := Vector2(b.body.global_position.x, b.body.global_position.z).length()
		seen[band] = [facing, moved, head]
		match band:
			&"warm":
				check(facing > 0.8 and head < -5.0, "warm: he turns to you and nods (facing %.2f, head %.1f)" % [facing, head])
			&"wary":
				check(b.body.pose_offsets.get(&"head", Vector3.ZERO).y < -20.0 or b.showing.is_empty(), "wary: his look slides off")
				check(absf(yaw0 - b.body.global_rotation.y) > 0.3, "wary: he looked your way first")
			&"cold":
				check(facing < 0.4, "cold: a turned shoulder (facing %.2f)" % facing)
			&"afraid":
				check(moved > 1.0 and head < -8.0, "afraid: out of your way, eyes down (moved %.2f m, head %.1f)" % [moved, head])
		b.body.queue_free()
		harlan.queue_free()
		await physics_frames(2)
	check(seen.warm[0] > seen.cold[0] + 0.4, "warm and cold don't look the same (%s)" % [seen])
	check(seen.afraid[1] > seen.warm[1] + 0.8, "only the afraid one gets out of the way (%s)" % [seen])
