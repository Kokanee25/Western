extends TestCase
## The town's news in the valley (townsfolk step 7, #1051): ValleyFolk's TownNews and its dead.
## - a townsman shot dead on the walk by Harlan at noon: the record, the versions of those who sensed
##   it; the undertaker comes for him (seen: within `dead.seen_h`), and he's taken to the
##   undertaker's once you're off him (a recorded death, the town's word on who did it);
## - he isn't taken while you stand over him;
## - the day after is `uneasy` (the storekeeper keeps in), and the town has a word on Harlan.

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	ValleyFolk.murder_auto = false  # No Law's murder and morning have their own tests
	StoryState.clear()
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _clock() -> DayCycle:
	return valley.get_node(^"DayCycle") as DayCycle


func _at(day: int, h: float, frames := 10) -> void:
	_clock().day = day
	_clock().set_time(h)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(frames)


func _put(at: Vector3, toward := Vector3.INF) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	if toward != Vector3.INF:
		p.rotation.y = atan2(-(toward.x - at.x), -(toward.z - at.z))


## A day man in the world now, out on the walks, with others near enough to see it.
func _victim() -> HumanBody:
	var f := valley.folk
	var best: HumanBody = null
	var best_n := -1
	for id: StringName in f.people:
		var p := f._person(id)
		var man := f.folk_man(id)
		if man == null or p.has("act") or not p.has("day") or id in [&"undertaker", &"doctor"] or f.state.get(id) != &"in":
			continue
		var n := 0
		for o: StringName in f.people:
			var om := f.folk_man(o)
			if om != null and om != man and om.global_position.distance_to(man.global_position) < 25.0:
				n += 1
		if n > best_n:
			best_n = n
			best = man
	return best


func test_a_man_shot_dead_is_taken_away_and_the_next_day_is_uneasy() -> void:
	await _at(2, 12.0, 60 * 3)
	var f := valley.folk
	var man := _victim()
	check(man != null, "a townsman out on the walks at noon (%s)" % [f.people.keys()])
	if man == null:
		return
	var id := man.person_id
	var p := _player()
	var at := man.global_position
	_put(at + Vector3(0.0, 0.0, 6.0), at)
	# A witness: another of the day folk by him, looking his way (the noon street is thin, #1040's
	# playtest).
	var wit: HumanBody = null
	for o: StringName in f.people:
		var om := f.folk_man(o)
		if om != null and om != man and o != &"undertaker" and not f._person(o).has("act") and f.state.get(o) == &"in":
			wit = om
			break
	check(wit != null, "someone else on the street")
	if wit == null:
		return
	var wb := wit.get_node(^"Brain") as CivilianBrain
	var wat := at + Vector3(5.0, 0.0, 3.0)
	wat.y = f.ground(wat.x, wat.z)
	wit.global_position = wat
	wb.post = wat
	wb.faces = at + Vector3.UP * 1.2
	wit.face(at + Vector3.UP * 1.2)
	var sees := await wait_until(func() -> bool: return wb.senses.sees(man), 60 * 4)
	check(sees, "the witness sees him")
	# Harlan's shot, and the man killed by it (the deed and death as DeedWatch tells them).
	Events.noise.emit(p.global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", p)
	Events.deed.emit(p, &"hit", man, at + Vector3.UP)
	man.physiology._die(&"shot")
	await physics_frames(60 * 4)
	var rep := f.news.report()
	print("  the news: %s" % [rep])
	check(rep.records.size() >= 1, "a record of it")
	check_eq(String(f.state.get(id)), "dead", "he's dead in the folk's book")
	check(not rep.versions.has(String(id)), "the dead man holds nothing")
	var holders := 0
	for pid: String in rep.versions:
		var v: Dictionary = rep.versions[pid].get("1", {})
		if v.is_empty():
			continue
		holders += 1
		if v.how != "told" and v.who != "":
			check_eq(v.how, "saw", "%s names a shooter only having seen him fire" % pid)
	print("  %d hold a version of it" % holders)
	# Stood over him an hour on: the undertaker's come, but he isn't taken in your sight.
	f.data["dead"]["walk_at_most_s"] = 3.0
	await _at(2, 13.0, 60 * 5)
	check(f.dead_out.has(id) or holders == 0, "he's due to be taken (%s)" % [f.dead_out])
	check(not f.gone_for_good.has(id), "not taken while you stand over him")
	# Off him (far up the street, facing away): he's taken to the undertaker's.
	_put(at + Vector3(0.0, 0.0, 80.0), at + Vector3(0.0, 0.0, 200.0))
	await _at(3, 7.0, 60 * 5)
	check(f.gone_for_good.has(id), "taken to the undertaker's by morning (%s)" % [f.state.get(id)])
	check(StoryState.has_fact("death." + String(id)), "a recorded death (%s)" % [StoryState.get_fact("death." + String(id))])
	print("  death: %s" % [StoryState.get_fact("death." + String(id), "")])
	if holders > 0:
		check_eq(String(StoryState.get_fact("news.yesterday", "")), "killing", "the town's yesterday: a killing")
		check_eq(String(f.day_kind(f.town_day())), "uneasy", "the day after's uneasy")
		check_eq(String(StoryState.get_fact("news.harlan", "")), "shot_a_man", "the town: he shot a man")
		var sk := f._person(&"storekeeper")
		check(not f.block_now(sk, 6.5).has("at"), "no sweeping the walk the morning after (%s)" % [f.block_now(sk, 6.5)])
