extends TestCase
## The valley town's people (#756, No Law step 1; ValleyFolk, config/valley_folk.json): built while
## the valley loads and out of the world by day; at night the barkeep behind the saloon yard's bar,
## two men drinking at it and two at the card table, sat in its chairs (two left free), the lamps
## lit; with the clock running into their hours they walk in from their way in by the town's ways
## (the folk's own Waypoints: the town's and the set's, not the valley's thousand), and out again
## at the end of them.

var holder: Node
var valley: ValleyWorld


## The valley built once for the file (it's freed with the case, after its last test).
func before_each() -> void:
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	pass


func _folk() -> ValleyFolk:
	return valley.folk


func _clock() -> DayCycle:
	return valley.get_node(^"DayCycle") as DayCycle


## The clock to `h`, held there, and the folk's look at it.
func _at(h: float) -> void:
	_clock().set_time(h)
	await physics_frames(1)
	_folk()._look = 0.0
	await physics_frames(2)


func _man(id: StringName) -> HumanBody:
	return _folk().people.get(id)


## How far he is from his post across the ground (m).
func _off_post(id: StringName) -> float:
	var f := _folk()
	var post: Vector3 = f.post_of(f._person(id))[0]
	var m := _man(id)
	return Vector2(m.global_position.x - post.x, m.global_position.z - post.z).length() if m else INF


## Leaves them all out of town (the clock at noon, a jump: gone at once).
func _empty() -> void:
	await _at(12.0)
	await physics_frames(2)


func test_by_day_nobody_s_there_but_they_re_built() -> void:
	await _empty()
	var f := _folk()
	check(f != null, "the valley has its folk")
	check_eq(f.people.size(), 0, "nobody in town at noon")
	for p: Dictionary in f.data.people:
		check_eq(String(f.state[StringName(p.id)]), "out", "%s out" % p.id)
	check(f.build_ms.has("men"), "built while the valley loaded (%s)" % f.build_ms)
	# The set stands in the saloon's yard (Sean's B on #755: the saloon a grey block for now).
	var yard := ValleyLayout.main().lot("saloon_annex")
	for k in ["bar", "table", "chair_n", "chair_e", "chair_s", "chair_w"]:
		var p: Node3D = f.props[k]
		check(p.global_position.x > float(yard.x0) and p.global_position.x < float(yard.x1) and p.global_position.z < -10.0,
				"the %s in the saloon's yard (%s)" % [k, p.global_position])


func test_at_night_the_barkeep_the_drinkers_and_the_card_table() -> void:
	await _empty()
	await _at(21.0)
	await physics_frames(90)
	var f := _folk()
	check_eq(f.people.size(), 5, "all five in at nine (%s)" % f.report())
	for id: StringName in [&"barkeep", &"miner", &"rancher", &"earl", &"drifter"]:
		check(_man(id) != null and _man(id).is_inside_tree(), "%s in the world" % id)
		check(_off_post(id) < 0.6, "%s at his post (%.2f m off)" % [id, _off_post(id)])
		check(not _man(id).limp and _man(id).physiology.alive, "%s on his feet or in his seat, alive" % id)
	# The barkeep behind the bar (on the far side from its customers), the drinkers before it.
	var bar: Node3D = f.props.bar
	var side := func(id: StringName) -> float: return (_man(id).global_position - bar.global_position).dot(bar.global_basis.z)
	check(side.call(&"barkeep") < -0.3, "the barkeep behind the bar (%.2f)" % side.call(&"barkeep"))
	check(side.call(&"miner") > 0.3 and side.call(&"rancher") > 0.3, "the drinkers on its customers' side")
	# The card players sat in their chairs (their weight on the seats: a kick takes them down, #204),
	# the other two chairs free for the next step's seated player.
	check((f.props.chair_w as KitProp).seated == _man(&"earl"), "Earl sat in the west chair")
	check((f.props.chair_e as KitProp).seated == _man(&"drifter"), "the drifter sat in the east chair")
	check((f.props.chair_n as KitProp).seated == null and (f.props.chair_s as KitProp).seated == null, "two chairs free")
	check_eq(_man(&"earl").pose, &"sit_back", "Earl sat back")
	# The lamps lit at night.
	for k in ["lamp_0", "lamp_1"]:
		check((f.props[k] as OilLamp).lit, "%s lit" % k)
	# Each faces his way: the barkeep his customers, the drinkers the bar.
	var fwd := func(id: StringName) -> Vector3: return -_man(id).global_basis.z
	check(fwd.call(&"barkeep").dot(bar.global_basis.z) > 0.7, "the barkeep facing his customers")
	check(fwd.call(&"miner").dot(bar.global_basis.z) < -0.7, "the miner facing the bar")


func test_they_walk_in_by_the_town_s_ways() -> void:
	await _empty()
	await _at(18.95)
	check_eq(_folk().people.size(), 1, "only the barkeep in before seven (%s)" % _folk().report())
	await _at(19.02)
	var f := _folk()
	var miner := _man(&"miner")
	check(miner != null, "the miner comes in at seven")
	if miner == null:
		return
	check_eq(String(f.state[&"miner"]), "coming", "walking in")
	var start := miner.global_position
	check(start.distance_to(f.places.at(&"hotel")) < 0.5, "from the hotel's door (%s)" % start)
	# He goes round by the town's ways: out along the walks, into the saloon's yard by its mouth,
	# up to the bar.
	var u := Time.get_ticks_usec()
	var arrived := await wait_until(func() -> bool: return _off_post(&"miner") < 0.5, 60 * 70)
	check(arrived, "the miner at the bar within 70 s (%.1f m off; at %s)" % [_off_post(&"miner"), miner.global_position])
	check(f.places.points.size() < 800, "the folk's own places, not the valley's (%d)" % f.places.points.size())
	print("  the miner's walk in: %.1f s of wall clock" % ((Time.get_ticks_usec() - u) / 1e6))


func test_each_finds_his_way_in() -> void:
	# The barkeep out of the saloon's door and down its walk's steps; the rancher from Back Street
	# down the North-South Street; Earl from Back Street up the yard; the drifter from the hotel.
	await _empty()
	await _at(16.9)
	await _at(17.01)
	check_eq(String(_folk().state[&"barkeep"]), "coming", "the barkeep walking in at five")
	await _at(19.61)
	var f := _folk()
	for id: StringName in [&"rancher", &"earl", &"drifter"]:
		check_eq(String(f.state[id]), "coming", "%s walking in" % id)
	var ids: Array[StringName] = [&"barkeep", &"rancher", &"earl", &"drifter"]
	var there := await wait_until(func() -> bool:
		return ids.all(func(id: StringName) -> bool: return _off_post(id) < 0.6), 60 * 90)
	for id in ids:
		check(_off_post(id) < 0.6, "%s at his post within 90 s (%.1f m off, at %s)" % [id, _off_post(id), _man(id).global_position])
	check(there, "all four in")
	await physics_frames(30)
	check((f.props.chair_w as KitProp).seated == _man(&"earl") and (f.props.chair_e as KitProp).seated == _man(&"drifter"),
			"the card players sat down once there")


func test_and_out_at_the_end_of_their_hours() -> void:
	await _empty()
	await _at(1.3)
	var f := _folk()
	check(_man(&"miner") != null and _man(&"earl") != null, "the miner and Earl in at 1.30")
	await physics_frames(60)
	check((f.props.chair_w as KitProp).seated == _man(&"earl"), "Earl sat")
	# Earl's hours end at 2: the clock running past it, he gets up and walks out the back of the yard.
	await _at(2.05)
	check_eq(String(f.state[&"earl"]), "going", "Earl going (%s)" % f.report())
	await physics_frames(30)
	check((f.props.chair_w as KitProp).seated == null, "up out of his chair")
	var gone := await wait_until(func() -> bool: return f.state[&"earl"] == &"out", 60 * 60)
	check(gone, "out of town by Back Street within 60 s (%s)" % f.report().get("earl"))
	check(not f.people.has(&"earl"), "and gone from the world")
	# The clock jumped well past (a night slept through): the rest gone at once.
	await _at(9.0)
	check_eq(f.people.size(), 0, "nobody left in the morning")


func test_hours_past_midnight() -> void:
	check(ValleyFolk.in_hours(23.0, [19.0, 2.0]) and ValleyFolk.in_hours(1.0, [19.0, 2.0]), "in after midnight")
	check(not ValleyFolk.in_hours(2.0, [19.0, 2.0]) and not ValleyFolk.in_hours(12.0, [19.0, 2.0]), "out by day")
	check(ValleyFolk.in_hours(10.0, [8.0, 17.0]) and not ValleyFolk.in_hours(17.5, [8.0, 17.0]), "a day's hours")
	check_near(ValleyFolk.since(0.5, 23.0), 1.5, 0.001, "hours since, over midnight")
