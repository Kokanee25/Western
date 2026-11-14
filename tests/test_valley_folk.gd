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
	ValleyFolk.murder_auto = false  # No Law's murder (#773) has its own tests
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


## The night's folk in the world (the saloon yard's; the day folk on the walks, #796, aside).
func _night_in() -> Array:
	return _folk().people.keys().filter(func(id: StringName) -> bool: return not _folk()._person(id).has("says"))


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
	check_eq(_night_in().size(), 0, "none of the night's folk in town at noon")
	for p: Dictionary in f.data.people:
		if not p.has("says"):
			check_eq(String(f.state[StringName(p.id)]), "out", "%s out" % p.id)
	# By day the day folk at their posts on the walks (No Law's morning after, #796).
	for id: StringName in [&"townsman", &"loudmouth", &"undertaker"]:
		check(f.state.get(id) in [&"in", &"coming"], "%s in town by day (%s)" % [id, f.state.get(id)])
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
	check_eq(_night_in().size(), 5, "all five in at nine (%s)" % f.report())
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
	check_eq(_night_in().size(), 1, "only the barkeep in before seven (%s)" % _folk().report())
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
	check_eq(_night_in().size(), 0, "none of the night's folk left in the morning (%s)" % _folk().report())


func test_hours_past_midnight() -> void:
	check(ValleyFolk.in_hours(23.0, [19.0, 2.0]) and ValleyFolk.in_hours(1.0, [19.0, 2.0]), "in after midnight")
	check(not ValleyFolk.in_hours(2.0, [19.0, 2.0]) and not ValleyFolk.in_hours(12.0, [19.0, 2.0]), "out by day")
	check(ValleyFolk.in_hours(10.0, [8.0, 17.0]) and not ValleyFolk.in_hours(17.5, [8.0, 17.0]), "a day's hours")
	check_near(ValleyFolk.since(0.5, 23.0), 1.5, 0.001, "hours since, over midnight")


## The valley's frame bench (#865): the load timed by part, and its townsfolk on Main Street's walks,
## half near the spot and half far down the street, standing on something (not in the air or under it).
func test_the_bench_s_load_parts_and_townsfolk() -> void:
	await _empty()
	for part in ["ground", "markers", "buildings", "folk"]:
		check(valley.load_ms.has(StringName(part)), "the load's %s timed (%s)" % [part, valley.load_ms])
	var at := Vector3(40.0, 0.0, 2.0)
	var made: Array = load("res://tools/valley/valley_townsfolk.gd").lay(valley, 6, at)
	await physics_frames(10)
	check_eq(made.size(), 6, "six townsfolk")
	var near := 0
	var far := 0
	var ground := valley.get_node(^"Ground")
	for man: HumanBody in made:
		var p := man.global_position
		var d := Vector2(p.x - at.x, p.z - at.z).length()
		if d <= 25.0:
			near += 1
		elif d >= 60.0:
			far += 1
		check(absf(p.z) > 9.0, "%s on a walk, not in the street (%s)" % [man.name, p])
		var under: float = ground.height_at(p.x, p.z)
		check(p.y > under - 0.3 and p.y < under + 2.0, "%s stands on the walk (%.2f over the ground)" % [man.name, p.y - under])
		check(man.physiology.alive and not man.is_queued_for_deletion(), "%s alive" % man.name)
	check_eq(near, 3, "half near")
	check_eq(far, 3, "half far")
	for man: HumanBody in made:
		man.queue_free()
	await physics_frames(2)


# --- The day and the book (townsfolk step 2, #870) ----------------------------------------------

## Every day man where his day says at `h` (placed: the walk's window shut for the check): at his
## spot in the world, or on the book in his block's place doing its doing. Returns what was wrong.
func _where_wrong(h: float) -> Array:
	var f := _folk()
	var wrong := []
	for p: Dictionary in f.data.people:
		if not p.has("day"):
			continue
		var id := StringName(p.id)
		var b := f.block_now(p, h)
		if b.has("at"):
			if f.state.get(id) != &"in" or _off_post(id) > 0.6:
				wrong.append("%.2f %s: %s (%s), %.1f m off his spot" % [h, id, f.state.get(id), ValleyFolk.block_key(b), _off_post(id)])
		else:
			var r := f.book.row(id)
			if f.people.has(id) or r.is_empty() or String(r.in) != String(b.in) or String(r.do) != String(b.do):
				wrong.append("%.2f %s: in the world %s, book %s, wants %s" % [h, id, f.people.has(id), r, ValleyFolk.block_key(b)])
	return wrong


func test_the_day_every_hour_bands_on_and_off() -> void:
	await _empty()
	var f := _folk()
	var walk_h: Variant = f.data.walk_in_h
	f.data.walk_in_h = 0.0  # every hour a jump: placed, not walking
	var bands := Settings.people_bands
	for on in [true, false]:
		Settings.people_bands = on
		var wrong := []
		var most := 0
		for i in 24:
			var h := float(i) + 0.01
			await _at(h)
			await physics_frames(3)
			wrong.append_array(_where_wrong(h))
			most = maxi(most, f.people.size())
			# The book and the street agree: a window lit where someone's in at a lamp's doing after
			# dark, smoke where someone's cooking.
			for place: StringName in f.lights.shows:
				var shows: Dictionary = f.lights.report()[String(place)]
				if shows.lit != f.book.lit(place, h) or shows.smoke != f.book.smoke(place):
					wrong.append("%.2f %s shows %s, the book %s" % [h, place, shows, f.book.inside(place)])
		check(wrong.is_empty(), "bands %s: everyone where his day says, every hour (%s)" % [on, wrong.slice(0, 6)])
		check(most <= 24, "never more than 24 bodies in the world (%d)" % most)
	Settings.people_bands = bands
	f.data.walk_in_h = walk_h


func test_the_book_shows_lit_windows_and_smoke() -> void:
	await _empty()
	var f := _folk()
	var shows := func() -> Dictionary: return f.report()["_day"]["shows"]
	check(f.lights.shows.has(&"hotel") and f.lights.shows.has(&"saloon") and f.lights.shows.has(&"undertaker"),
			"a window and a chimney for each building the day takes them into (%s)" % f.lights.shows.keys())
	check(not f.lights.shows.has(&"back@0"), "none for a way out of town")
	# Nine at night: the townsman at home in the hotel, the undertaker over his shop, the loudmouth in
	# the saloon's back: lamps lit; nobody cooking.
	await _at(21.0)
	var s: Dictionary = shows.call()
	check(s.hotel.lit and s.undertaker.lit and s.saloon.lit, "lit windows at nine (%s)" % s)
	check(not s.hotel.smoke and not s.undertaker.smoke, "no smoke at nine (%s)" % s)
	check(f.book.inside(&"hotel").has(&"townsman") and not f.people.has(&"townsman"), "the townsman on the book, in the hotel")
	# Half past eleven: all abed but the saloon's (out in the yard): dark.
	await _at(23.5)
	s = shows.call()
	check(not s.hotel.lit and not s.undertaker.lit and not s.saloon.lit, "dark at half past eleven (%s; %s)" % [s, f.book.report()])
	# Breakfast: smoke from the hotel's and the undertaker's chimneys, daylight (no lamp).
	await _at(6.5)
	s = shows.call()
	check(s.hotel.smoke and s.undertaker.smoke, "breakfast smoke (%s)" % s)
	check(not s.hotel.lit, "no lamp by day")
	# Supper, after dark: the undertaker's lit and smoking; the hotel's smoke (the miner at supper).
	await _at(18.5)
	s = shows.call()
	check(s.undertaker.lit and s.undertaker.smoke and s.hotel.smoke, "supper (%s)" % s)
	await _at(12.0)
	s = shows.call()
	check(not s.hotel.smoke and not s.undertaker.smoke, "nothing cooking at noon (%s)" % s)


## The player stood across Main Street from the hotel's door, looking at it (or away).
func _watch_hotel(looking: bool) -> void:
	var f := _folk()
	var player := valley.get_node(^"Player") as Player
	var door: Vector3 = f.places.at(&"hotel")
	var at := Vector3(door.x, f.ground(door.x, 6.0) + 0.1, 6.0)
	player.velocity = Vector3.ZERO
	player.global_position = at
	var to := door - at
	player.rotation.y = atan2(-to.x, -to.z) + (0.0 if looking else PI)
	await physics_frames(2)


## The clock run on by `step` hours a look from `from` to `to` (as it runs while you watch).
func _run_clock(from: float, to: float, step := 0.02) -> void:
	var h := from
	while ValleyFolk.since(to, h) > 0.0001 and ValleyFolk.since(to, h) < 12.0:
		h = fposmod(h + step, 24.0)
		await _at(h)


func test_nobody_appears_or_vanishes_in_view() -> void:
	await _empty()
	var f := _folk()
	await _at(18.9)
	await _watch_hotel(true)
	var door: Vector3 = f.places.at(&"hotel")
	check(f.seen_man_at(door), "you can see the hotel's door from across the street")
	var log_from := f.view_log.size()
	# The miner's to come out of the hotel at seven: with you watching its door he waits behind it.
	await _run_clock(18.9, 19.1)
	check_eq(String(f.state[&"miner"]), "out", "the miner not out while you watch the door (%s)" % f.report().get("miner"))
	check(f.book.inside(&"hotel").has(&"miner"), "still on the book, in the hotel")
	# Look away and he comes out.
	await _watch_hotel(false)
	await _at(19.12)
	check_eq(String(f.state[&"miner"]), "coming", "out and walking once you look away (%s)" % f.report().get("miner"))
	var arrived := await wait_until(func() -> bool: return _off_post(&"miner") < 0.6, 60 * 70)
	check(arrived, "at the bar")
	# Half past one he goes back: you watch the hotel's door, he waits at it, in once you look away.
	await _at(1.4)
	await _watch_hotel(true)
	await _run_clock(1.4, 1.52)
	check_eq(String(f.state[&"miner"]), "going", "the miner on his way in")
	var at_door := await wait_until(func() -> bool:
		var m := _man(&"miner")
		return m != null and Vector2(m.global_position.x - door.x, m.global_position.z - door.z).length() < ValleyFolk.GONE_AT, 60 * 70)
	check(at_door, "at the hotel's door (%s)" % f.report().get("miner"))
	await physics_frames(60)
	check_eq(String(f.state[&"miner"]), "going", "not gone in while you watch (%s)" % f.report().get("miner"))
	await _watch_hotel(false)
	await physics_frames(10)
	check_eq(String(f.state[&"miner"]), "out", "in once you look away")
	check(f.book.inside(&"hotel").has(&"miner"), "on the book in the hotel")
	var seen := f.view_log.slice(log_from).filter(func(e: Array) -> bool: return e[3] and not e[4])
	check(seen.is_empty(), "nobody came or went in view (%s)" % [seen])
	check(f.view_log.size() - log_from >= 2, "the probe logged the miner's coming and going (%s)" % [f.view_log.slice(log_from)])


func test_day_kinds_sunday_and_payday() -> void:
	await _empty()
	var f := _folk()
	var c := _clock()
	check_eq(String(f.day_kind(1)), "ordinary", "day 1 a working day")
	check_eq(String(f.day_kind(7)), "sunday", "day 7 a Sunday")
	check_eq(String(f.day_kind(13)), "payday", "day 13 a payday (the second Saturday)")
	c.day = 7
	await _at(12.0)
	check(f.book.row(&"undertaker").get("in") == &"undertaker" and not f.people.has(&"undertaker"),
			"the undertaker's shut on a Sunday (%s)" % f.report().get("undertaker"))
	check(f.book.row(&"townsman").is_empty() and f.people.has(&"townsman"), "the townsman out on the hotel's walk")
	await _at(8.5)
	check_eq(String(f.book.row(&"townsman").get("do", "")), "breakfast", "a Sunday's late breakfast")
	# A night past midnight is still Sunday's.
	c.day = 8
	await _at(3.0)
	check_eq(String(f.report()["_day"]["kind"]), "sunday", "three in the morning still Sunday's night")
	c.day = 13
	await _at(18.5)
	check(f.people.has(&"miner"), "payday: the miner at the bar early (%s)" % f.report().get("miner"))
	c.day = 1
	await _empty()
