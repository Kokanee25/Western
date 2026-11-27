extends TestCase
## The town registers Harlan (the town gate's fault 1, #1167): in the valley, the gate's three deeds
## each move the regard of the men who saw them, where before every number stayed at 0.0:
## - a shot in the air by a townsman who sees him fire (TownNews' version, Harlan firing, nobody down);
## - a shove (Events.deed, as PlayerShove sends it): the man shoved more than the one who saw it;
## - a won pot at the card table (CardGame.hand_done): respect from the men at the table;
## and what they saw is kept in the town's save.

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


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _at(day: int, h: float, frames := 10) -> void:
	var c := valley.get_node(^"DayCycle") as DayCycle
	c.day = day
	c.set_time(h)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(frames)


func _put(at: Vector3, toward: Vector3) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-(toward.x - at.x), -(toward.z - at.z))


## Two day men out in the world (not No Law's set men), the first stood facing `p`'s spot.
func _two_men() -> Array[HumanBody]:
	var f := valley.folk
	var out: Array[HumanBody] = []
	for id: StringName in f.people:
		var man := f.folk_man(id)
		if man != null and not f._person(id).has("act") and f._person(id).has("day") and f.state.get(id) == &"in" \
				and not f.spot_of(f._person(id)).has("hall"):  # out of doors (#1213: the barkeep's inside by day)
			out.append(man)
		if out.size() == 2:
			break
	return out


## `man` stood at `at`, facing `look`, and kept there (his post).
func _stand(man: HumanBody, at: Vector3, look: Vector3) -> CivilianBrain:
	var b := man.get_node(^"Brain") as CivilianBrain
	at.y = valley.folk.ground(at.x, at.z)
	man.global_position = at
	b.post = at
	b.faces = look + Vector3.UP * 1.5
	man.face(look + Vector3.UP * 1.5)
	return b


func _numbers_moved(o: Dictionary) -> bool:
	return absf(o.trust) + absf(o.liking) + absf(o.respect) + absf(o.fear) > 0.01


func test_a_shot_and_a_shove_move_the_men_who_saw_them() -> void:
	await _at(2, 12.0, 60 * 2)
	var f := valley.folk
	var men := _two_men()
	check_eq(men.size(), 2, "two townsmen out at noon")
	if men.size() < 2:
		return
	var a := men[0]
	var w := men[1]
	var p := _player()
	# The street's middle by the crossroads, clear of its dressing (#1304: where a man happened to be, a
	# wagon or a tied horse could stand between them).
	var here := Vector3(4.0, 0.0, 1.0)
	here.y = f.ground(here.x, here.z)
	var at_a := here - Vector3(0.0, 0.0, 4.0)
	_put(here, at_a)
	var ab := _stand(a, at_a, here)
	var wb := _stand(w, here + Vector3(6.0, 0.0, 0.0), here)
	var seen := await wait_until(func() -> bool: return ab.senses.sees(p) and wb.senses.sees(p), 60 * 4)
	check(seen, "both see Harlan")
	for id: StringName in [a.person_id, w.person_id]:
		check(not _numbers_moved(f.regard.opinions(id)), "%s starts at nothing" % id)
	# A shot in the air (the revolver's noise as DeedWatch sends it; nobody hit).
	Events.noise.emit(p.global_position + Vector3.UP * 1.5, DeedWatch.GUNSHOT, &"gunshot", p)
	await physics_frames(10)
	var oa := f.regard.opinions(a.person_id)
	print("  after the shot: %s %s" % [a.person_id, oa])
	check(oa.fear > 0.05 and oa.trust < 0.0, "a shot in town: he fears and trusts Harlan less (%s)" % [oa])
	# A shove: `a` is shoved; `w` sees it.
	var before_w := f.regard.opinions(w.person_id)
	Events.deed.emit(p, &"shove", a, a.global_position + Vector3.UP)
	await physics_frames(2)
	var oa2 := f.regard.opinions(a.person_id)
	var ow := f.regard.opinions(w.person_id)
	print("  after the shove: %s %s / %s %s" % [a.person_id, oa2, w.person_id, ow])
	check(oa2.liking < oa.liking - 0.1, "the man shoved likes him less")
	check(ow.liking < before_w.liking, "the man who saw it likes him less")
	check(oa2.liking - oa.liking < ow.liking - before_w.liking, "the man shoved minds more than the one who saw")
	# Kept in the town's save.
	var d := f.save_dict()
	f.regard.deeds = {}
	f.regard.load_dict(d.regard)
	check_eq(f.regard.opinions(a.person_id).liking, oa2.liking, "what he saw is kept in the save")


func test_a_won_pot_earns_the_table_s_respect() -> void:
	await _at(2, 21.0, 60 * 3)
	var f := valley.folk
	var p := _player()
	var pot := f.cards._pot_at()
	var seen_by: Array[HumanBody] = []
	for id: StringName in f.people:
		var man := f.folk_man(id)
		if man != null and not f._person(id).has("act") and man.global_position.distance_to(pot) < 4.0:
			seen_by.append(man)
	check(seen_by.size() >= 1, "men at the card table at nine")
	if seen_by.is_empty():
		return
	var here := pot + Vector3(0.0, 0.0, 1.2)
	here.y = f.ground(here.x, here.z)
	_put(here, pot)
	for man: HumanBody in seen_by:
		_stand(man, man.global_position, here)
	var sees := await wait_until(func() -> bool:
		return seen_by.any(func(m: HumanBody) -> bool: return (m.get_node(^"Brain") as CivilianBrain).senses.sees(p)), 60 * 4)
	check(sees, "a man at the table sees Harlan")
	# (#1279: the table's deeds come from CardGame.you_did; no men listed, so only those who see it keep it)
	f.cards.you_did.emit(&"won_pot", {"men": [], "pot": 30, "shown": true})
	await physics_frames(2)
	var moved := 0
	for man: HumanBody in seen_by:
		var o := f.regard.opinions(man.person_id)
		if o.respect > 0.05:
			moved += 1
	print("  after the pot: %s" % [f.regard.deeds])
	check(moved >= 1, "a won pot: respect from the table (%s)" % [f.regard.deeds])
