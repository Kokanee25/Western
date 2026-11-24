extends TestCase
## The saloon and the store open by day (the town gate's fault 3, #1167):
## - at two in the afternoon the saloon's room is open, the barkeep behind his bar, and the day's
##   rounds bring a drinker or two to it within a few minutes (the gate found it shut and empty);
## - a knock at the store's door in its hours brings the storekeeper out to it, facing you, with a
##   line; he goes back in once you've walked off. At night (shut) nobody comes.
## - (#1184) the knock's own line, and again if you stand there; a man in the doorway makes E a knock,
##   never a shove of him, and the keeper out on his walk answers it.

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear()
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	ValleyFolk.murder_auto = true
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _clock() -> DayCycle:
	return valley.get_node(^"DayCycle") as DayCycle


func _at(h: float, frames: int) -> void:
	_clock().day = 2
	_clock().set_time(h)
	_clock().time_scale = 0.0
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(frames)


func _put(at: Vector3, toward: Vector3) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-(toward.x - at.x), -(toward.z - at.z))


func test_the_saloon_is_open_by_day() -> void:
	var f := valley.folk
	_put(Vector3(0.0, f.ground(0.0, 300.0), 300.0), Vector3(0.0, 0.0, 400.0))
	await _at(14.0, 60 * 3)
	check(f.room.open(), "the saloon's open at two")
	check_eq(String(f.state.get(&"barkeep")), "in", "the barkeep's at his bar")
	var bar := f.folk_man(&"barkeep")
	check(bar != null and f.room.inside(bar.global_position), "behind it, in the room")
	var drank := {}
	for i in 60:  # five minutes
		await physics_frames(60 * 5)
		for id: StringName in f.people:
			var b := f.block_now(f._person(id), f.hour())
			if id != &"barkeep" and String(b.get("do", "")) == "drink" and f.state.get(id) == &"in":
				drank[id] = true
	print("  at the bar by day: %s; the room %s" % [drank.keys(), f.room.report().get("in", [])])
	check(drank.size() >= 1, "a drinker or two in by day (%s)" % [drank.keys()])
	_clock().time_scale = 1.0


func test_a_knock_at_the_store_in_its_hours() -> void:
	var f := valley.folk
	_put(Vector3(0.0, f.ground(0.0, 300.0), 300.0), Vector3(0.0, 0.0, 400.0))
	await _at(14.0, 60 * 2)
	# In at his store (his round's leg in, on the book): the clock held, he stays in.
	var keeper := &"storekeeper"
	f._legs[keeper] = {"base": 13.0, "i": 0, "until": 1.0e9, "since": f._ran, "n": 0}
	f._key.erase(keeper)
	f._look = 0.0
	await physics_frames(60 * 2)
	check(f.book.inside(&"general_store").has(keeper), "the storekeeper's in at his store (%s)" % [f.book.row(keeper)])
	check(f.shop_open(&"general_store"), "the store's open at two")
	var door := f.door(&"general_store")
	var stand := door + Vector3(0.0, 0.0, -2.5)
	stand.y = f.ground(stand.x, stand.z)
	_put(stand, door)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	var said := f.heard.size()
	f.knock(&"general_store", p, door)
	var out := await wait_until(func() -> bool:
		var m := f.folk_man(keeper)
		return m != null and m.global_position.distance_to(f.spot_point(f.spot("store_walk"))[0]) < 1.2, 60 * 30)
	check(out, "he comes out to his door")
	await physics_frames(60 * 2)
	print("  said: %s" % [f.heard.slice(said)])
	check(f.heard.size() > said and String(f.heard[-1][0]) == "storekeeper", "and says a line (%s)" % [f.heard.slice(said)])
	# The knock's own line, not his counter's (#1184: "There's others before you" with nobody there).
	var ids := f.heard.slice(said).map(func(x: Array) -> String: return String(x[1]))
	check(ids.has("day.store_open"), "the knock's answer: the store's open (%s)" % [ids])
	# You stand there and say nothing: he asks again.
	var asked := await wait_until(func() -> bool:
		return f.heard.slice(said).any(func(x: Array) -> bool: return String(x[1]).begins_with("knock.wait")), 60 * 25)
	check(asked, "stood at his door, he asks what you want (%s)" % [f.heard.slice(said)])
	# Off up the street: he goes back to his day.
	_put(stand + Vector3(0.0, 0.0, -30.0), stand + Vector3(0.0, 0.0, -60.0))
	var back := await wait_until(func() -> bool: return f.state.get(keeper) != &"called", 60 * 10)
	check(back, "back to his day once you've gone")
	# At night (shut): a knock brings nobody.
	f._legs.erase(keeper)
	await _at(23.0, 60 * 2)
	_put(stand, door)
	f.knock(&"general_store", p, door)
	await physics_frames(60 * 3)
	check(f.state.get(keeper) != &"called" and not f.answering.has(keeper), "shut at night: nobody comes")
	_clock().time_scale = 1.0


## #1184 (gate round 2, run 3): the storekeeper stood in his doorway, nobody in on the book, and E there
## shoved him in the chest. A man at the door: E is the door's, and the keeper on his walk answers.
func test_a_man_in_the_doorway_is_knocked_for_not_shoved() -> void:
	var f := valley.folk
	_put(Vector3(0.0, f.ground(0.0, 300.0), 300.0), Vector3(0.0, 0.0, 400.0))
	await _at(14.0, 60 * 2)
	var keeper := &"storekeeper"
	# On his walk (his afternoon round's second leg, store_walk), the clock held.
	f._legs[keeper] = {"base": 13.0, "i": 1, "until": 1.0e9, "since": f._ran, "n": 0}
	f._key.erase(keeper)
	f._look = 0.0
	var spot := f.spot_point(f.spot("store_walk"))[0] as Vector3
	var there := await wait_until(func() -> bool:
		var m := f.folk_man(keeper)
		return m != null and f.state.get(keeper) == &"in" and m.global_position.distance_to(spot) < 1.0, 60 * 40)
	check(there, "the storekeeper's out on his walk")
	var door := f.door(&"general_store")
	var man := f.folk_man(keeper)
	# Him right in the doorway, you at arm's length out on the walk facing it.
	var out := spot - door
	out.y = 0.0
	out = out.normalized() if out.length() > 0.1 else Vector3.BACK
	man.global_position = Vector3(door.x, man.global_position.y, door.z) + out * 0.5
	var stand := door + out * 1.5
	stand.y = f.ground(stand.x, stand.z)
	_put(stand, door)
	await physics_frames(2)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	check(not p.knock.door_here(true).is_empty(), "a man at the door: the door's yours to bang on")
	check(p.knock.claims_use(p), "E there is the door's, not a shove")
	var said := f.heard.size()
	p.knock.bang(p.knock.door_here(true))
	await physics_frames(60 * 4)
	check(f.answering.has(keeper) or f.heard.slice(said).any(func(x: Array) -> bool: return String(x[0]) == "storekeeper"),
			"the keeper on his walk answers the knock (%s)" % [f.heard.slice(said)])
	check(man.physiology.is_conscious() and not (man.get_node(^"Brain") as CivilianBrain).mood in [CivilianBrain.Mood.DOWN],
			"and nobody's knocked down")
	_clock().time_scale = 1.0


## #1213 (gate 4, run 2): at noon the barkeep stood behind the yard's bar, beyond saloon B's wall from its
## own bar and below its floor, where you couldn't reach him. By day he serves behind saloon B's bar: you
## at its customers' side are in the room, on his floor, across the bar from him.
func test_at_noon_the_barkeep_is_behind_saloon_b_s_bar() -> void:
	var f := valley.folk
	_put(Vector3(0.0, f.ground(0.0, 300.0), 300.0), Vector3(0.0, 0.0, 400.0))
	await _at(12.0, 60 * 3)
	var bar := f.folk_man(&"barkeep")
	check(bar != null and f.state.get(&"barkeep") == &"in", "the barkeep's at his post at noon")
	var serve := f.hall_use("saloon", "barman_a")
	check(not serve.is_empty(), "saloon B's bar has its barman's place")
	if bar == null or serve.is_empty():
		return
	check(bar.global_position.distance_to(serve[0]) < 1.0, "behind saloon B's bar (%s, its place %s)" % [bar.global_position, serve[0]])
	var drink := f.hall_use("saloon", "drinker_1")
	var stand: Vector3 = drink[0]
	_put(stand, bar.global_position)
	await physics_frames(30)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	check(absf(p.global_position.y - bar.global_position.y) < 0.3, "on his floor (you %.2f, him %.2f)" % [p.global_position.y, bar.global_position.y])
	var flat := Vector2(p.global_position.x - bar.global_position.x, p.global_position.z - bar.global_position.z).length()
	check(flat < 2.8, "across the bar from him (%.2f m)" % flat)
	check(f.room.inside(p.global_position) and f.room.inside(bar.global_position), "both in the room")
	# He walks out to the yard's bar for the night's room at five.
	check_eq(String(f.spot_of(f._person(&"barkeep")).get("behind", "")), "", "by day not the yard's bar")
	_clock().time_scale = 1.0


## The store's pane: its door's glass leaf (a StructureMember "…entry_leaf/pane").
func _store_pane() -> StructureMember:
	var b: Node3D = valley.get(&"buildings").get("general_store")
	for n: Node in b.find_children("*", "StructureMember", true, false):
		if String((n as StructureMember).member_id).ends_with("entry_leaf/pane"):
			return n as StructureMember
	return null


## #1213 (gate 4, run 3): stood at the store door's glass from 0.7 m, the knock wasn't offered (you were
## "past the door", 0.9 m in from its point out on the walk; the door's 1.2 m back in its recess), so E
## shoved and broke the glass, and nobody turned. Now E there is the door's; and glass broken in a shop
## is noticed: its keeper has his say, the men near look round.
func test_at_the_store_s_glass_e_knocks_and_broken_glass_is_noticed() -> void:
	var f := valley.folk
	_put(Vector3(0.0, f.ground(0.0, 300.0), 300.0), Vector3(0.0, 0.0, 400.0))
	await _at(14.0, 60 * 2)
	var pane := _store_pane()
	check(pane != null, "the store's door has its glass")
	if pane == null:
		return
	var door := f.door(&"general_store")
	var out := door - pane.global_position
	out.y = 0.0
	out = out.normalized()
	var stand := pane.global_position + out * 0.7
	stand.y = door.y - 0.1
	_put(stand, pane.global_position)
	await physics_frames(10)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	print("  at the glass: you %s, the pane %s, the door point %s" % [p.global_position, pane.global_position, door])
	check(not f.past_door(&"general_store", p.global_position), "at the glass isn't past the door")
	check(not p.knock.door_here(true).is_empty(), "the door's yours to bang on")
	check(p.knock.claims_use(p), "E there is the door's, not a shove")
	# In the doorway past the leaf: in at it, no knock.
	check(f.past_door(&"general_store", pane.global_position - out * 0.6), "past the leaf: in at it")
	# The glass broken (as a shove did it): the keeper out on his walk has his say, and men near look.
	var keeper := &"storekeeper"
	f._legs[keeper] = {"base": 13.0, "i": 1, "until": 1.0e9, "since": f._ran, "n": 0}
	f._key.erase(keeper)
	f._look = 0.0
	var there := await wait_until(func() -> bool:
		var m := f.folk_man(keeper)
		return m != null and f.state.get(keeper) == &"in" and m.global_position.distance_to(door) < 6.0, 60 * 40)
	check(there, "the storekeeper's out by his door")
	var said := f.heard.size()
	var lines := []
	var hook := func(by: Node, text: String) -> void:
		if by is HumanBody:
			lines.append([String((by as HumanBody).person_id), text])
	Events.spoke.connect(hook)
	(pane.get_parent() as Structure).break_member(pane, -out)
	Events.noise.emit(pane.global_position, 14.0, &"crash", p)
	Events.deed.emit(p, &"damage", null, pane.global_position)
	await physics_frames(60 * 2)
	Events.spoke.disconnect(hook)
	print("  said: %s; %s" % [lines, f.heard.slice(said)])
	check(f.damaged.any(func(x: Array) -> bool: return x[1] == &"general_store" and x[2] == keeper), "the keeper takes it as his")
	check(lines.any(func(x: Array) -> bool: return x[0] == "storekeeper" and CivilianBrain.LINES[&"damage_mine"].has(x[1])),
			"and says so (%s)" % [lines])
	check(not lines.any(func(x: Array) -> bool: return x[0] == "storekeeper" and not CivilianBrain.LINES[&"damage_mine"].has(x[1])),
			"and not straight back to his small talk (%s)" % [lines])
	var br := f.folk_man(keeper).get_node(^"Brain") as CivilianBrain
	check(not br.showing.is_empty() or br.fear > 0.0, "he turns to it")
	_clock().time_scale = 1.0


## #1213 (gate 4, run 4): after the shot three men were left 25-80 m from their posts for minutes, "in" and
## so never watched for being stuck. A man in at his spot, his fright over, left far off it and not getting
## nearer, is put back unseen; seen, sent again.
func test_a_man_left_far_off_after_a_fright_goes_back() -> void:
	var f := valley.folk
	_put(Vector3(0.0, f.ground(0.0, 300.0), 300.0), Vector3(0.0, 0.0, 400.0))
	await _at(14.0, 60 * 3)
	var id := &""
	for pid: StringName in f.people:
		var m := f.folk_man(pid)
		var b := m.get_node_or_null(^"Brain") as CivilianBrain if m else null
		if f.state.get(pid) == &"in" and b != null and b.post != Vector3.INF and not f._person(pid).has("act") \
				and b.mood == CivilianBrain.Mood.CALM and f.block_now(f._person(pid), f.hour()).has("at") \
				and not b.held and not f.answering.has(pid) and not m.limp and m.dragged_by == null \
				and (b.reaction == null or b.reaction.stage == Reaction.Stage.NONE):
			id = pid
			break
	check(id != &"", "a man in at his spot")
	if id == &"":
		return
	var man := f.folk_man(id)
	var brain := man.get_node(^"Brain") as CivilianBrain
	var post := brain.post
	# Left 30 m off, his reaction over, not nearer for longer than a stuck walk's wait, you far off.
	f._away_from[id] = [30.0, f._ran - ValleyFolk.WALK_STUCK_S - 1.0]
	var away := post + Vector3(30.0, 0.0, 0.0)
	away.y = f.ground(away.x, away.z)
	man.global_position = away
	if brain.chore != null and brain.chore.has_method(&"stop"):
		brain.chore.call(&"stop")  # (as the fright stopped it: up from his work, his body his own)
	f._away_step(id, man, f._person(id))
	check(f.away_fixed.any(func(x: Array) -> bool: return x[1] == id), "taken in hand (%s)" % [f.away_fixed])
	await physics_frames(30)
	var back := f.folk_man(id)
	check(back != null and Vector2(back.global_position.x - post.x, back.global_position.z - post.z).length() < 2.0,
			"unseen: back at his spot (%s, his post %s)" % [back.global_position if back else Vector3.INF, post])
	# Seen: sent back by a fresh route, not put there.
	back = f.folk_man(id)
	brain = back.get_node(^"Brain") as CivilianBrain
	var far := brain.post + Vector3(20.0, 0.0, 0.0)
	far.y = f.ground(far.x, far.z)
	back.global_position = far
	if brain.chore != null and brain.chore.has_method(&"stop"):
		brain.chore.call(&"stop")
	_put(far + Vector3(0.0, 0.0, 4.0), far)
	await physics_frames(5)
	f._away_from[id] = [20.0, f._ran - ValleyFolk.WALK_STUCK_S - 1.0]
	f._away_step(id, back, f._person(id))
	check(back.global_position.distance_to(far) < 1.0 and brain.returning, "seen: sent back on his feet")
	_clock().time_scale = 1.0
