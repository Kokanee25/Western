extends TestCase
## #1091's must (#1250): in the line shack, the front door kicked in, Joe walks from the door down the
## west lane, through the back storeroom's door (shut by Kett; Joe lifts its latch) to Kett, ten runs
## with the door's pieces wherever they land (each run kicked from a different spot along the door,
## the shack's own dice seeded anew). He gets there on his own feet every time: never stuck on the
## sill or the pieces (the cabin's step-over fallbacks, "Joe over the ...", never fire).

var holder: Node
var valley: Node


func after_each() -> void:
	StoryState.clear()
	var p := _player()
	if p:
		p.input_enabled = true
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _put(at: Vector3, look_at := Vector3.INF) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	if look_at != Vector3.INF:
		var to := look_at - at
		p.rotation.y = atan2(-to.x, -to.z)


func _start() -> NoJusticeCabin:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	return Moment.start_named(&"no_justice_cabin", valley, null, {"set_up": true, "pace": 0.25}) as NoJusticeCabin


func _kick_in(m: NoJusticeCabin, side: float) -> void:
	var p := _player()
	var along := m.shack.global_basis.x * side
	var door := m.hideout._shack_door(0.0) + along
	for i in 6:
		if m.door_open():
			break
		_put(m.hideout._shack_door(0.75) + along, door + Vector3.UP * 0.8)
		p.add_look(Vector2(0.0, -8.0 - p.get_pitch_degrees()))
		await physics_frames(2)
		var was := m.kicks
		p.shove.wants = &"kick"
		await wait_until(func() -> bool: return m.kicks > was or p.shove.move == &"", 90)
		await wait_until(func() -> bool: return p.shove.move == &"", 120)
		await physics_frames(20)


func test_joe_walks_from_the_door_to_kett_ten_times() -> void:
	var reached := 0
	var sides := [0.0, 0.3, -0.3, 0.15, -0.15, 0.4, -0.4, 0.05, -0.25, 0.25]
	for run in 10:
		var m := await _start()
		check(m != null and not m.done, "run %d starts" % run)
		if m == null:
			return
		(m.shack.get(&"_rng") as RandomNumberGenerator).seed = 7000 + run * 31
		check(m.hideout.in_storeroom(m.kett.global_position), "run %d: Kett hides in the storeroom" % run)
		check(m.store_shut(), "run %d: he's pulled its door to" % run)
		await _kick_in(m, sides[run])
		check(m.door_open(), "run %d: the door's in (%s)" % [run, m.result()])
		await physics_frames(60)  # (the pieces down)
		# In (he gives up), then aside by the east wall, out of the lane.
		_put(m._local([2.1, 1.3]), m.kett.global_position)
		await physics_frames(10)
		_put(m._local([3.0, 1.0]), m.kett.global_position)
		var got := await wait_until(func() -> bool: return m.state == &"ask" or m.done, 60 * 45)
		var d := NoJusticeCabin._flat(m.joe.global_position, m.kett.global_position)
		var hops := m.timeline.filter(func(e: Array) -> bool: return String(e[1]).begins_with("Joe over the"))
		# (he asks from his place 0.8 m short of Kett, within 0.5 of it: NoJusticeCabin's knife step; in the
		# storeroom's doorway) Then the shake: he goes on to Kett with the knife (in reach: 0.95 m).
		var asked_d := d
		if got and m.state == &"ask":
			var p := _player()
			for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
				p.add_look(Vector2(12.0 * k, 0.0))
				await physics_frames(3)
			got = await wait_until(func() -> bool: return m.stabs > 0 or m.done, 60 * 30)
			d = NoJusticeCabin._flat(m.joe.global_position, m.kett.global_position)
			hops = m.timeline.filter(func(e: Array) -> bool: return String(e[1]).begins_with("Joe over the"))
		var ok := got and m.stabs > 0 and d < 0.95 and hops.is_empty() and not m.store_shut()
		print("  run %d (kicked at %+.2f): %s, asked %.2f m from Kett, at the knife %.2f m (in the storeroom %s), its door shut %s, step-overs %d" % [
				run, sides[run], m.state, asked_d, d, m.hideout.in_storeroom(m.joe.global_position), m.store_shut(), hops.size()])
		check(ok, "run %d: Joe walked to Kett (%s; %.2f m; %s)" % [run, m.state, d, hops])
		if ok:
			reached += 1
		await after_each()
	print("  Joe reached Kett %d of 10" % reached)
	check(reached == 10, "every run (%d of 10)" % reached)
