extends TestCase
## "Ride there" (#1120, RideThere, config/ride_there.json): E at a tied horse lists the places you know;
## one chosen, a fade, the clock on by the ride (the distance at a trot and a little), and you're stood
## by your horse at that place's rail. Riding to each place, the clock's jump, each refusal (a man over
## your shoulder, bleeding hard, a man after you, an act running, the farmhouse's fight), what's known,
## what comes due on the way (the funeral's hour), and the bridge's `ride`.

const TEST_PORT := 8794
var holder: Node
var valley: ValleyWorld
var ride: RideThere
var made: Array[Node] = []


func before_each() -> void:
	StoryState.wipe()
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(12)
	ride = valley.ride
	# Quick fades for the tests (the look is the data's).
	ride.data["fade_s"] = 0.05
	ride.data["card_s"] = 0.05


func after_each() -> void:
	for n in made:
		if is_instance_valid(n):
			n.queue_free()
	made.clear()
	StoryState.wipe()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _player() -> Player:
	return valley.get_node(^"Player") as Player


func _clock() -> DayCycle:
	return valley.find_child("DayCycle", true, false) as DayCycle


func _hours() -> float:
	var c := _clock()
	return float(c.day) * 24.0 + c.time_of_day


## You by your horse at `id`'s rail, facing him.
func _by_horse(id: StringName) -> void:
	ride.stand_horse(id)
	var p := _player()
	p.global_position = (ride.spots[id].stand as Vector3) + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	var to := ride.horse.global_position - p.global_position
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(3)


func _ride(id: StringName) -> String:
	var why := ride.ride(id)
	if why != "":
		return why
	await wait_until(func() -> bool: return ride.state == &"idle", 600)
	await physics_frames(2)
	return ""


func test_your_horse_is_at_the_rail_nearest_you() -> void:
	check(ride != null, "the valley has RideThere")
	check(Horse.available(), "the horse model is built")
	check(ride.horse != null and ride.horse.tied, "your horse, tied")
	check_eq(ride.horse_at, &"town", "in town, where you start")
	check(ride.spots.size() >= 8, "a hitch at each place (%d)" % ride.spots.size())
	check(ride.spots.has(&"harlan_homestead"), "Harlan's homestead is one (it's in valley.json's places)")
	for id: StringName in ride.order:
		check(valley.places().has(StringName("horse_%s" % id)), "goto horse_%s" % id)
		# The hitch on ground you can stand on: not on a cliff.
		var s: Dictionary = ride.spots[id]
		var h: Vector3 = s.horse
		var rise := 0.0
		for d: Vector3 in [Vector3(1.5, 0, 0), Vector3(-1.5, 0, 0), Vector3(0, 0, 1.5), Vector3(0, 0, -1.5)]:
			rise = maxf(rise, absf(ride.ground(h.x + d.x, h.z + d.z) - h.y))
		check(rise < 1.0, "%s's hitch on fair ground (%.2f m in 1.5 m)" % [id, rise])
	await _by_horse(&"town")
	check(ride.horse_here() != null, "the horse by you")
	check(ride.claims_use(_player()), "E is the ride, not a shove")


func test_riding_to_each_place() -> void:
	# The widow's place starts the farmhouse rescue as you come (as on foot): not in this test.
	if valley.mission:
		valley.mission.process_mode = Node.PROCESS_MODE_DISABLED
	for id: StringName in ride.order:
		StoryState.set_fact("known.%s" % id, true)
	await _by_horse(&"town")
	var p := _player()
	var from := &"town"
	for id: StringName in ride.order:
		if id == from:
			continue
		var before := _hours()
		var want := ride.ride_of(p.global_position, id)
		var why := await _ride(id)
		check_eq(why, "", "rode to %s" % id)
		if why != "":
			continue
		var s: Dictionary = ride.spots[id]
		check(RideThere._flat(p.global_position, s.stand) < 2.6, "%s: stood by the rail (%.1f m off)" % [id, RideThere._flat(p.global_position, s.stand)])
		check(RideThere._flat(ride.horse.global_position, s.horse) < 0.05 and ride.horse.tied, "%s: your horse tied there with you" % id)
		check_eq(ride.horse_at, id, "%s: the horse's spot" % id)
		var gone := _hours() - before
		check_near(gone, float(want.seconds) / 3600.0, 0.01, "%s: the clock on by the ride (%.0f m, %.1f min)" % [id, want.metres, gone * 60.0])
		check(p.input_enabled, "%s: you have your legs back" % id)
		await physics_frames(30)
		var g := ride.ground(p.global_position.x, p.global_position.z)
		check(absf(p.global_position.y - g) < 1.2, "%s: on the ground, not falling (%.2f over it)" % [id, p.global_position.y - g])
		from = id
	check_eq(ride.rides, ride.order.size() - 1, "every ride")


func test_the_clock_jumps_by_the_ride_at_a_trot() -> void:
	await _by_horse(&"town")
	var p := _player()
	var d := RideThere._flat(p.global_position, ride.spots[&"harlan_homestead"].stand)
	var r := ride.ride_of(p.global_position, &"harlan_homestead")
	var trot := float(ValleyLayout.main().speeds().horse_trot)
	check_near(float(r.seconds), d * 1.3 / trot + 45.0, 0.5, "the distance (%.0f m, winding) at a trot, plus a little" % d)
	check(float(r.seconds) > 120.0 and float(r.seconds) < 600.0, "a few minutes (%.0f s)" % r.seconds)
	var was := _hours()
	var hurt := []
	var on_hours := func(h: float, why: StringName) -> void: hurt.append([h, why])
	Events.hours_passed.connect(on_hours)
	check_eq(await _ride(&"harlan_homestead"), "", "rode home")
	Events.hours_passed.disconnect(on_hours)
	check_near(_hours() - was, float(r.seconds) / 3600.0, 0.005, "the clock on")
	check(hurt.size() == 1 and hurt[0][1] == &"rode", "the world told the hours went by (%s)" % [hurt])
	check(StoryState.get_fact("known.harlan_homestead", false) == true, "known now")
	check((ride.last.to as String) == "harlan_homestead" and ride.last.to_clock != "", "the ride's record (%s)" % ride.last)


func test_only_places_you_know() -> void:
	await _by_horse(&"town")
	var offered := ride.offered()
	check(&"harlan_homestead" in offered and &"widow_homestead" in offered, "home and the widow's (%s)" % [offered])
	check(not &"town" in offered, "not where you are")
	check(not &"hideout" in offered and not &"mine" in offered, "not the hideout or the mine, unseen")
	check(ride.ride(&"hideout") != "", "can't ride where you don't know")
	StoryState.set_fact("nojustice.trail", "hideout")
	check(&"hideout" in ride.offered(), "the hideout once No Justice sent you there")
	# Been near a place: known.
	var p := _player()
	var mine: Vector3 = ride.spots[&"mine"].look
	p.global_position = Vector3(mine.x, ride.ground(mine.x, mine.z) + 0.2, mine.z)
	await physics_frames(70)
	check(ride.knows(&"mine"), "the mine, once you've been there")


func test_each_refusal() -> void:
	await _by_horse(&"town")
	var p := _player()
	check_eq(ride.refusal(), "", "free to ride")
	# A man over your shoulder.
	var man := HumanBody.new()
	man.person_id = &"earl"
	valley.add_child(man)
	made.append(man)
	man.global_position = p.global_position + Vector3(4, 0, 0)
	await physics_frames(2)
	p.carry.him = man
	check(ride.refusal().contains("shoulder"), "not carrying (%s)" % ride.refusal())
	var at := p.global_position
	check(ride.ride(&"harlan_homestead") != "" and ride.state == &"idle", "no ride")
	check(p.global_position.distance_to(at) < 0.5, "you stay")
	p.carry.him = null
	# Bleeding hard.
	var ph := p.wounds.physiology
	ph._add_bleed(&"femoral_artery_r", &"thigh_r", 20.0, &"artery")
	check(ph.total_bleed_rate() > 2.0, "bleeding (%.1f ml/s)" % ph.total_bleed_rate())
	check(ride.refusal().contains("bleeding"), "not bleeding hard (%s)" % ride.refusal())
	ph.bleeds.clear()
	check_eq(ride.refusal(), "", "free again")
	# A man after you who knows where you are.
	var foe := HumanBody.new()
	foe.person_id = &"cody"
	var b := OutlawBrain.new()
	b.name = "Brain"
	foe.add_child(b)
	valley.add_child(foe)
	made.append(foe)
	foe.global_position = p.global_position + Vector3(0, 0, 20)
	await physics_frames(3)
	b.target = p
	check(ride.refusal().contains("Cody"), "not in a fight (%s)" % ride.refusal())
	foe.global_position = p.global_position + Vector3(0, 0, 400)
	await physics_frames(2)
	check_eq(ride.refusal(), "", "free when he's far off")
	foe.queue_free()
	# A running act says no (its `ride_no`); one whose data says ride ok lets you go.
	var act := Act.new()
	act.data = {"ride_no": "Not now: Joe's waiting on you."}
	act.add_to_group(&"moment")
	valley.add_child(act)
	made.append(act)
	check_eq(ride.refusal(), "Not now: Joe's waiting on you.", "a mission that says no")
	act.data = {"ride": "ok"}
	check_eq(ride.refusal(), "", "or one that doesn't")
	act.done = true
	# The farmhouse with the gang in it.
	if valley.mission:
		var was := valley.mission.state
		valley.mission.state = FarmhouseMission.State.ON
		check(ride.refusal().contains("farmhouse"), "not with the farmhouse on (%s)" % ride.refusal())
		valley.mission.state = was
	check_eq(ride.refusal(), "", "free at the end")
	# The why's said on screen.
	var said: Array = []
	var on_shown := func(t: String) -> void: said.append(t)
	p.wounds.shown.connect(on_shown)
	p.carry.him = man
	ride.open_menu()
	p.carry.him = null
	p.wounds.shown.disconnect(on_shown)
	check(said.any(func(t: String) -> bool: return t.contains("shoulder")), "said why (%s)" % [said])
	check_eq(ride.state, &"idle", "no list")


func test_the_list_opens_and_rides() -> void:
	await _by_horse(&"town")
	var p := _player()
	check(ride.open_menu(), "E at the horse: the list")
	check_eq(ride.state, &"menu", "the list up")
	check(not p.input_enabled, "you stand while you choose")
	check(ride._menu_label.text.contains("Your place"), "Harlan's homestead on it (%s)" % ride._menu_label.text)
	ride.close_menu()
	check(p.input_enabled and ride.state == &"idle", "Esc: stay")


func test_the_funeral_due_on_the_way_happens() -> void:
	var folk := valley.folk
	check(folk != null, "the valley's folk")
	if folk == null:
		return
	# The sheriff died yesterday; the funeral's at 10:00 today; you set off from home just before.
	var c := _clock()
	c.day = 2
	c.set_time(9.95)
	StoryState.set_fact("nolaw.murder", "done", 1, 22.0)
	StoryState.set_fact("nolaw.sheriff", "dead", 1, 12.0)
	await _by_horse(&"harlan_homestead")
	var beats := ride.beats_on_way(0.2)
	check(beats.any(func(b: Dictionary) -> bool: return b.what == "nolaw.funeral"), "the funeral comes due on the way (%s)" % [beats])
	var said: Array = []
	var on_shown := func(t: String) -> void: said.append(t)
	var p := _player()
	p.wounds.shown.connect(on_shown)
	check_eq(await _ride(&"town"), "", "rode to town")
	p.wounds.shown.disconnect(on_shown)
	check(said.any(func(t: String) -> bool: return t.contains("funeral began at 10:00")), "told on arrival (%s)" % [said])
	var began := await wait_until(func() -> bool: return folk.funeral != null and is_instance_valid(folk.funeral), 120)
	check(began, "and the funeral goes on, not skipped")


func test_the_bridge_rides() -> void:
	var bridge := DevBridge.new()
	bridge.main = holder
	bridge.port = TEST_PORT
	holder.add_child(bridge)
	await process_frames(2)
	var out: Dictionary = await bridge._cmd_goto(["horse_town"])
	check(not out.has("error"), "goto horse_town (%s)" % out)
	var listed: Dictionary = await bridge._cmd_ride([])
	check((listed.offered as Array).size() >= 2, "ride alone lists (%s)" % listed)
	var was := _hours()
	out = await bridge._cmd_ride(["widow_homestead"])
	check(not out.has("error") and String(out.get("refused", "")) == "", "ride widow_homestead (%s)" % out)
	check(_hours() - was > 0.1, "the clock on (%.2f h)" % (_hours() - was))
	check_eq(ride.horse_at, &"widow_homestead", "the horse there")
	out = await bridge._cmd_ride(["nowhere"])
	check(out.has("refused"), "a place it doesn't know (%s)" % out)
