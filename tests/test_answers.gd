extends TestCase
## Every verb gets an answer, step 1 (#1272, DESIGN §2 pillar 6): in the valley's saloon on an
## ordinary evening, Harlan's shove gets
## - an answer at once from the man shoved, even shoved from behind (he felt it), who turns to see who;
## - a look from everyone who saw it, and words about it from the nearest (TownBarks `react.shove`);
## - a mark: the regard of those who saw it, more for the man shoved, turns cold and shows as you pass;
## - a mention later: a TownNews record (`rough`) each witness holds, tells on, and says to your face,
##   after a calm while (`ROUGH_TELL_S`), not all at once in the same breath.
## And the shot's words fit where the man is: "Get in and shut it" only out of doors (`indoors`).
## The bench that measured it: experiments/answers/ (README, results/).

var holder: Node
var valley: ValleyWorld
var said: Array = []


func before_each() -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear()
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	said = []
	Events.spoke.connect(_on_spoke)
	await physics_frames(5)


func after_each() -> void:
	Events.spoke.disconnect(_on_spoke)
	ValleyFolk.murder_auto = true
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _on_spoke(who: Node, text: String) -> void:
	said.append([who, text])


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## The evening in the saloon, everyone at his spot.
func _evening() -> void:
	var c := valley.get_node(^"DayCycle") as DayCycle
	c.day = 2
	c.set_time(20.6)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(60 * 4)


func _brain(id: StringName) -> CivilianBrain:
	var man := valley.folk.folk_man(id)
	return man.get_node(^"Brain") as CivilianBrain if man != null else null


## Harlan stood `d` m behind `man` (his back to him), facing him.
func _behind(man: HumanBody, d: float) -> void:
	var p := _player()
	var back := man.global_basis.z  # (a body faces -Z)
	back.y = 0.0
	p.global_position = man.global_position + back.normalized() * d + Vector3.UP * 0.05
	p.velocity = Vector3.ZERO
	var to := man.global_position - p.global_position
	p.rotation.y = atan2(-to.x, -to.z)


## The day men in play within `m` of `at` who see Harlan now, but `not_id`.
func _who_see(at: Vector3, m: float, not_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var f := valley.folk
	for id: StringName in f.people:
		var man := f.folk_man(id)
		var b := _brain(id)
		if man == null or b == null or id == not_id or f._person(id).has("act") or f.state.get(id) != &"in":
			continue
		if man.global_position.distance_to(at) < m and b.senses.sees(_player()) and b.mood == CivilianBrain.Mood.CALM:
			out.append(id)
	return out


func _shove_rancher() -> Dictionary:
	await _evening()
	var f := valley.folk
	var rancher := f.folk_man(&"rancher")
	check(rancher != null and f.state.get(&"rancher") == &"in", "the rancher's at the bar at half past eight")
	if rancher == null:
		return {}
	_behind(rancher, 0.6)
	var rb := _brain(&"rancher")
	await wait_until(func() -> bool: return _who_see(rancher.global_position, 15.0, &"rancher").size() >= 2, 60 * 6)
	var saw := _who_see(rancher.global_position, 15.0, &"rancher")
	check(saw.size() >= 2, "two or more in the room see Harlan behind the rancher (%s)" % [saw])
	check(not rb.senses.sees(_player()), "the rancher, his back to Harlan, doesn't see him")
	said = []
	var before := {}
	for id: StringName in saw + [&"rancher"]:
		before[id] = f.regard.opinions(id)
	Events.deed.emit(_player(), &"shove", rancher, rancher.global_position + Vector3.UP)
	return {"rancher": rancher, "saw": saw, "before": before}


func _lines_of(id: StringName) -> Array:
	return said.filter(func(x: Array) -> bool: return is_instance_valid(x[0]) and x[0] is HumanBody and (x[0] as HumanBody).person_id == id)


func test_the_man_shoved_from_behind_answers_and_everyone_who_saw_it_does() -> void:
	var s := await _shove_rancher()
	if s.is_empty():
		return
	var looked := {}
	for i in 60 * 3:
		await physics_frames(1)
		for id: StringName in s.saw + [&"rancher"]:
			var b := _brain(id)
			if b != null and (b.showing.get("what", &"") == &"look" or b.reaction.active() or b.mood != CivilianBrain.Mood.CALM):
				looked[id] = true
	print("  said: %s" % [said.map(func(x: Array) -> String: return "%s: %s" % [(x[0] as HumanBody).person_id, x[1]])])
	check(not _lines_of(&"rancher").is_empty(), "the man shoved says something, shoved from behind")
	check(looked.has(&"rancher"), "and turns to see who did it")
	for id: StringName in s.saw:
		check(looked.has(id), "%s, who saw it, looks" % id)
	var shove_lines: Array = valley.folk.barks.log.filter(func(l: Array) -> bool: return String(l[1]).begins_with("react.shove"))
	check(shove_lines.size() >= 1, "someone who saw it says so (%s)" % [shove_lines])
	check(shove_lines.size() <= CivilianBrain.ROUGH_SPEAK, "the nearest few, not the whole room")
	for l: Array in shove_lines:
		check(not "{" in String(l[2]), "the line's slots are filled: %s" % l[2])


func test_one_shove_seen_turns_them_cold_and_it_shows_as_you_pass() -> void:
	var s := await _shove_rancher()
	if s.is_empty():
		return
	await physics_frames(2)
	var f := valley.folk
	var ro := f.regard.opinions(&"rancher")
	check_eq(f.regard.band_of(ro), &"cold", "the man shoved is cold to him (%s)" % [ro])
	for id: StringName in s.saw:
		var o := f.regard.opinions(id)
		check(TownRegard.warmth(o) < TownRegard.warmth(s.before[id]) - 0.1, "%s thinks less of him" % id)
		check(TownRegard.warmth(ro) < TownRegard.warmth(o), "the rancher minds more than %s" % id)
		check_eq(f.regard.band_of(o), &"cold", "%s, who saw it, is cold" % id)
	# The next time you pass: off and back, and the calm ones turn a shoulder.
	var p := _player()
	var back := p.global_position
	p.global_position = back + Vector3(0.0, 0.0, 40.0)
	await physics_frames(30)
	f.regard.log.clear()
	p.global_position = back
	await wait_until(func() -> bool: return f.regard.log.any(func(l: Array) -> bool: return s.saw.has(StringName(l[0]))), 60 * 30)
	print("  shown: %s" % [f.regard.log])
	var shown: Array = f.regard.log.filter(func(l: Array) -> bool: return s.saw.has(StringName(l[0])))
	check(not shown.is_empty(), "a man who saw it shows you as you pass")
	for l: Array in shown:
		check_eq(String(l[2]), "turn", "%s turns a shoulder (cold)" % l[0])


func test_the_shove_is_news_he_tells_on_and_says_to_your_face() -> void:
	var s := await _shove_rancher()
	if s.is_empty():
		return
	await physics_frames(2)
	var news := valley.folk.news
	var rough: Array = news.records.filter(func(r: Dictionary) -> bool: return r.get("rough", false))
	check_eq(rough.size(), 1, "one record of the shove")
	if rough.is_empty():
		return
	var rid := int(rough[0].id)
	check_eq(rough[0].whom, &"rancher", "of the rancher")
	for id: StringName in s.saw + [&"rancher"]:
		var v := news.version_of(id, rid)
		check(not v.is_empty() and v.who == TownNews.HARLAN, "%s holds it, Harlan doing it" % id)
		check_eq(news.to_say(id), 0, "%s doesn't talk of it in the same breath" % id)
		check_eq(news._piece(id, &"miner") if news.version_of(&"miner", rid).is_empty() else 0, 0, "nor tell it on at once")
	# Half a minute on (the record aged rather than waited for):
	rough[0].last_frame = int(rough[0].last_frame) - int(TownNews.ROUGH_TELL_S + 1.0) * Engine.physics_ticks_per_second
	for id: StringName in s.saw + [&"rancher"]:
		check_eq(news.to_say(id), rid, "%s has it to say, a while after" % id)
	var w: StringName = s.saw[0]
	var to_you := news.line_of(w, rid, TownNews.HARLAN)
	print("  %s to Harlan: %s" % [w, to_you])
	check(to_you.contains("rancher") and (to_you.begins_with("You") or to_you.begins_with("That was you")), "to your face: you, and whom")
	var his := news.line_of(&"rancher", rid, TownNews.HARLAN)
	print("  the rancher to Harlan: %s" % his)
	check(his.contains(" me"), "the man shoved says 'me'")
	# Told on: a man who wasn't there has it from one who was, small news (it fades overnight if only told).
	var other := &""
	for id: StringName in valley.folk.people:
		if id != &"rancher" and not s.saw.has(id) and not valley.folk._person(id).has("act") and news.version_of(id, rid).is_empty():
			other = id
			break
	check(news._told(w, other, rid), "%s tells %s" % [w, other])
	check_eq(TownNews.kind_of(news.version_of(other, rid)), &"rough", "told, it's still a shove")
	print("  %s, told: %s" % [other, news.line_of(other, rid)])
	# A shove isn't a shot: no "fired" in his regard, and a shot after it is a record of its own.
	check_eq(valley.folk.regard._harlan_fired(w), 0, "a shove isn't Harlan firing")
	Events.noise.emit(_player().global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", _player())
	await physics_frames(5)
	check(news.records.size() >= 2 and not news.records[-1].get("rough", false), "a shot after it is its own record")


func test_get_in_is_said_out_of_doors_only() -> void:
	await _evening()
	var f := valley.folk
	var girl := f.folk_man(&"saloon_girl")
	check(girl != null and f.state.get(&"saloon_girl") == &"in", "the saloon girl's in the saloon")
	if girl == null:
		return
	var ctx := f.bark_ctx(&"saloon_girl", girl)
	check(bool(ctx.get("indoors", false)), "in the saloon she's indoors")
	check(not TownBarks.fitting("react.flee", ctx).has("react.inside"), "no 'Get in and shut it' from inside")
	ctx["indoors"] = false
	check(TownBarks.fitting("react.flee", ctx).has("react.inside"), "out of doors she says it")
