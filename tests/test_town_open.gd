extends TestCase
## The saloon and the store open by day (the town gate's fault 3, #1167):
## - at two in the afternoon the saloon's room is open, the barkeep behind his bar, and the day's
##   rounds bring a drinker or two to it within a few minutes (the gate found it shut and empty);
## - a knock at the store's door in its hours brings the storekeeper out to it, facing you, with a
##   line; he goes back in once you've walked off. At night (shut) nobody comes.

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
