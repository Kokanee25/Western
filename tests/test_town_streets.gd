extends TestCase
## The day street lived in (the town gate's fault 2, #1167): at 07:00, 12:00, 14:00 and 17:30,
## with the clock held at the hour, the day folk out of doors and on the move: errand rounds
## (ValleyFolk `round` blocks) walk them leg to leg, so men go into the store and come out, stand a
## while on a walk, sit on the bench and move on. Measured: bodies out of doors (on the street's
## walks, not in the saloon's room) and how many of them moved more than a few metres in the window.
## The gate found 3 / 3 / 8 out at 07:00 / 12:00 / 17:30, none moving; the brief's day table has
## about ten out in the morning, two or three at noon (dinner), the work again in the afternoon.

const WINDOW_S := 150.0
## The brief's numbers, made floors: [hour, out of doors at least, of them moving at least].
const HOURS := [[7.0, 5, 3], [12.0, 3, 2], [14.0, 6, 4], [17.5, 6, 2]]

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


## Out of doors: a day man's body at a spot on a lot's walk (in front of the building), or walking.
func _outdoors(f: ValleyFolk) -> Dictionary:
	var out := {}
	for id: StringName in f.people:
		var man := f.folk_man(id)
		var p := f._person(id)
		if man == null or p.has("act") or not p.has("day") or not f.state.get(id) in [&"in", &"coming", &"going"]:
			continue
		var b := f.block_now(p, f.hour())
		var sp := f.spot(b.at) if b.has("at") else {}
		var walk: bool = sp.has("lot") and float((sp.at as Array)[1]) < 0.0
		if walk or f.state.get(id) != &"in":
			out[id] = man.global_position
	return out


func test_the_day_street_is_out_and_moving() -> void:
	var f := valley.folk
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 2  # an ordinary day
	var p := get_tree().get_first_node_in_group(&"player") as Player
	# Harlan up the street out of the way, looking at nothing in particular (doors hide nobody).
	p.global_position = Vector3(0.0, f.ground(0.0, 300.0) + 0.2, 300.0)
	var rows := []
	for row: Array in HOURS:
		clock.set_time(float(row[0]))
		clock.time_scale = 0.0
		await physics_frames(1)
		f._look = 0.0
		await physics_frames(60 * 5)
		var start := _outdoors(f)
		var seen := start.duplicate()
		var moved := {}
		var peak := 0
		var t := 0.0
		while t < WINDOW_S:
			await physics_frames(60 * 5)
			t += 5.0
			var now := _outdoors(f)
			peak = maxi(peak, now.size())
			for id: StringName in now:
				if not seen.has(id):
					seen[id] = now[id]
				elif (now[id] as Vector3).distance_to(seen[id]) > 3.0:
					moved[id] = true
		var mean_out := seen.size()
		rows.append([row[0], start.size(), peak, mean_out, moved.size()])
		print("  %05.2f: out at the start %d, at most %d, %d out at some time, %d moved (%s)" % [row[0], start.size(), peak, mean_out, moved.size(), moved.keys()])
		check(peak >= int(row[1]), "%.1f h: at least %d out of doors (%d)" % [row[0], row[1], peak])
		check(moved.size() >= int(row[2]), "%.1f h: at least %d of them on the move (%d)" % [row[0], row[2], moved.size()])
	clock.time_scale = 1.0


## Two runs, two towns (the gate's fault 4: the noon runs said the same at the same seconds): with
## another run seed the rounds start elsewhere and the barks come at other times; with the same, the same.
func test_another_run_another_town() -> void:
	var f := valley.folk
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 2
	clock.set_time(12.0)
	await physics_frames(1)
	f._look = 0.0
	await physics_frames(10)
	var first := {}
	for id: StringName in f.people:
		first[id] = [f._legs.get(id, {}).get("i", -1), snappedf(f._jit(id, "first"), 0.001)]
	check_eq(f.run_seed, 0, "the tests' town is run 0")
	var same := 0
	var other := 0
	for s: int in [0, 7]:
		f.run_seed = s
		f._legs.clear()
		for id: StringName in first:
			var p := f._person(id)
			if p.has("day"):
				f.block_now(p, 12.0)
			var now := [f._legs.get(id, {}).get("i", -1), snappedf(f._jit(id, "first"), 0.001)]
			if s == 0 and now == first[id]:
				same += 1
			elif s != 0 and now != first[id]:
				other += 1
	f.run_seed = 0
	check_eq(same, first.size(), "the same run seed: the same legs and times")
	check(other >= first.size() / 2, "another: most men's legs or first words elsewhere (%d of %d)" % [other, first.size()])


## #1184 (gate round 2: the loudmouth, the saloon girl, the liveryman, the storekeeper, the smith on
## one spot all run, `from_post` 0.0 every look): no man out of doors stands still for ten minutes.
## The data, every hour: a day block that has a man at a spot out of doors (on a lot's walk) either
## walks a round (no leg's stay ten minutes or more), or ends within ten minutes at the gate's clock.
const STILL_S := 600.0
## The gate's clock (the bridge's `clock 0.03`: 1 is 45 minutes a day): real seconds a game hour.
const GATE_HOUR_S := 45.0 * 60.0 / 0.03 / 24.0


func test_no_block_keeps_a_man_on_one_spot_outdoors() -> void:
	var f := valley.folk
	var bad := []
	for p: Dictionary in f.data.people:
		var day: Variant = p.get("day", null)
		if day == null:
			continue
		var kinds: Dictionary = day if day is Dictionary else {"ordinary": day}
		for kind: String in kinds:
			var bl: Variant = kinds[kind]
			if not bl is Array:
				continue
			for i in (bl as Array).size():
				var b: Dictionary = bl[i]
				if b.has("round"):
					for leg: Dictionary in b.round:
						if float((leg.get("stay", [60, 150]) as Array)[1]) >= STILL_S:
							bad.append("%s %s %.1f: a leg's stay of %s" % [p.id, kind, b.from, leg.stay])
					continue
				if not b.has("at") or not _out_of_doors(f, String(b.at)):
					continue
				var to: float = float(bl[i + 1].from) if i + 1 < bl.size() else 24.0 + float(bl[0].from)
				if (to - float(b.from)) * GATE_HOUR_S >= STILL_S:
					bad.append("%s %s %.1f-%.1f at %s" % [p.id, kind, b.from, to, b.at])
	check(bad.is_empty(), "every man out of doors moves within ten minutes (%s)" % [bad])


func _out_of_doors(f: ValleyFolk, name: String) -> bool:
	var sp := f.spot(name)
	return sp.has("lot") and float((sp.at as Array)[1]) < 0.0


## And played: 17:30 (the worst hour of round 2, four men still), the clock at the gate's rate, you on
## the walk by the store and the saloon: nobody out of doors stays within 1.5 m of one place ten minutes.
func test_nobody_out_of_doors_is_still_ten_minutes() -> void:
	var f := valley.folk
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 2
	var p := get_tree().get_first_node_in_group(&"player") as Player
	p.global_position = Vector3(0.0, f.ground(0.0, 300.0) + 0.2, 300.0)
	clock.set_time(17.5)
	clock.time_scale = 0.03
	await physics_frames(1)
	f._look = 0.0
	await physics_frames(60 * 5)
	var anchor := {}  # id -> [where, since (s)]
	var longest := {}
	var t := 0.0
	while t < STILL_S + 30.0:
		await physics_frames(60 * 5)
		t += 5.0
		var now := _outdoors(f)
		for id: StringName in anchor.keys():
			if not now.has(id):
				anchor.erase(id)
		for id: StringName in now:
			var at: Vector3 = now[id]
			if not anchor.has(id) or (at - (anchor[id][0] as Vector3)).length() > 1.5:
				anchor[id] = [at, t]
			longest[id] = maxf(float(longest.get(id, 0.0)), t - float(anchor[id][1]))
	print("  17:30, ten minutes: the longest each stood still out of doors %s" % [longest])
	check(not longest.is_empty(), "men out of doors at 17:30 (%d)" % longest.size())
	for id: StringName in longest:
		check(float(longest[id]) < STILL_S, "%s not still ten minutes out of doors (%.0f s)" % [id, longest[id]])
	clock.time_scale = 1.0
