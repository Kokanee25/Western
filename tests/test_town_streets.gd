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
