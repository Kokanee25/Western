extends TestCase
## CI's parallel test jobs (#1015): run_tests.gd --shard=K/N splits the test files by
## config/test_times.json. Every file must run in exactly one shard, or a test silently never runs.

const Runner := preload("res://tests/run_tests.gd")


func _all_files() -> Array:
	var files := Array(DirAccess.get_files_at("res://tests")).filter(
			func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd")
	files.sort()
	return files


func test_every_file_in_exactly_one_shard() -> void:
	var files := _all_files()
	var times := Runner.load_times()
	for n in [1, 4, 6, 7]:
		var seen := {}
		for k in n:
			for f: String in Runner.shard_files(files, times, k, n):
				check(not seen.has(f), "%s in two of %d shards" % [f, n])
				seen[f] = true
		check_eq(seen.size(), files.size(), "all %d files across %d shards" % [files.size(), n])


func test_shards_balance_by_the_table() -> void:
	var times := {"test_a.gd": 100.0, "test_b.gd": 60.0, "test_c.gd": 50.0, "test_d.gd": 10.0}
	var files := ["test_a.gd", "test_b.gd", "test_c.gd", "test_d.gd", "test_new.gd"]
	# Longest first to the lightest: a -> 0; b -> 1; c -> 1 (110); new (30) -> 0 (130); d -> 1 (120).
	check_eq(Runner.shard_files(files, times, 0, 2), ["test_a.gd", "test_new.gd"], "shard 1 of 2")
	check_eq(Runner.shard_files(files, times, 1, 2), ["test_b.gd", "test_c.gd", "test_d.gd"], "shard 2 of 2")


func test_the_table_is_read() -> void:
	# A file missing from it counts as 30 s and one left over is ignored, so it never needs to be
	# exact; tools/test_times.py refreshes it from CI's logs when the shards drift.
	check(Runner.load_times().size() > 100, "config/test_times.json read")


# --- The leak check (#1326, tests/leak_check.gd): what a test file leaves behind is named. Each test
# takes its own picture, leaves one thing, asks, and puts it back itself. (Here, not a file of their own:
# a new file moves the shards' split.)

var lc: RefCounted


## A fresh picture for each leak test (#1326).
func _fresh() -> void:
	lc = (load("res://tests/leak_check.gd") as GDScript).new()
	await physics_frames(1)
	lc.call(&"take", get_tree().root)


func _leaks() -> PackedStringArray:
	await physics_frames(1)
	return lc.call(&"leaks", get_tree().root, self)


func _has(left: PackedStringArray, part: String) -> bool:
	for l in left:
		if l.contains(part):
			return true
	return false


func test_nothing_left_is_clean() -> void:
	await _fresh()
	var left: PackedStringArray = await _leaks()
	check(left.is_empty(), "a file that leaves nothing: clean (%s)" % [left])


func test_a_node_left_under_the_root_is_named() -> void:
	await _fresh()
	var n := Node3D.new()
	n.name = "LeftValley"
	get_tree().root.add_child(n)
	var left: PackedStringArray = await _leaks()
	check(_has(left, "LeftValley"), "the node's named (%s)" % [left])
	lc.call(&"free_leaks", get_tree().root, self)
	await process_frames(1)
	check(not is_instance_valid(n), "and taken away for the next file")


func test_the_files_own_node_is_not_a_leak() -> void:
	await _fresh()
	var kid := Node.new()
	add_child(kid)  # (under the test's own node: it goes with it)
	var left: PackedStringArray = await _leaks()
	check(left.is_empty(), "its own children go with it (%s)" % [left])
	kid.queue_free()


func test_a_node_left_under_an_autoload_is_counted() -> void:
	await _fresh()
	var n := Node.new()
	get_tree().root.get_node(^"Events").add_child(n)
	var left: PackedStringArray = await _leaks()
	check(_has(left, "under the Events autoload"), "counted under Events (%s)" % [left])
	n.free()


func test_a_body_made_by_rid_is_counted() -> void:
	await _fresh()
	var ps := PhysicsServer3D
	var shape := ps.box_shape_create()
	ps.shape_set_data(shape, Vector3.ONE)
	var body := ps.body_create()
	ps.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
	ps.body_add_shape(body, shape)
	ps.body_set_space(body, get_tree().root.find_world_3d().space)
	ps.body_set_state(body, PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(Basis.IDENTITY, Vector3(0, -500, 0)))
	await physics_frames(2)
	var left: PackedStringArray = await _leaks()
	check(_has(left, "physics: 1 more"), "the body's counted (%s)" % [left])
	ps.free_rid(body)
	ps.free_rid(shape)


func test_a_dial_left_set_is_named_and_put_back() -> void:
	await _fresh()
	var was := FireSystem.in_play
	FireSystem.in_play = not was
	var left: PackedStringArray = await _leaks()
	check(_has(left, "static FireSystem.in_play"), "the static's named (%s)" % [left])
	lc.call(&"free_leaks", get_tree().root, self)
	check(FireSystem.in_play == was, "and put back")
	FireSystem.in_play = was


func test_the_engine_left_slowed_is_named_and_put_back() -> void:
	await _fresh()
	Engine.time_scale = 0.5
	var left: PackedStringArray = await _leaks()
	check(_has(left, "Engine.time_scale"), "the time scale's named (%s)" % [left])
	lc.call(&"free_leaks", get_tree().root, self)
	check(Engine.time_scale == 1.0, "and put back")
	Engine.time_scale = 1.0


func test_a_listener_left_on_an_autoload_signal_is_named() -> void:
	await _fresh()
	var holder := Node.new()
	add_child(holder)
	var events := get_tree().root.get_node(^"Events")
	var sig: StringName = events.get_signal_list()[0].name
	# (a callable on a node taken out of the tree: as a test's node left listening when it's gone)
	var call := Callable(holder, &"queue_free")
	events.connect(sig, call)
	remove_child(holder)
	var left: PackedStringArray = await _leaks()
	check(_has(left, "Events.%s" % sig), "the dead listener's named (%s)" % [left])
	events.disconnect(sig, call)
	holder.free()


func test_a_running_tween_is_named() -> void:
	await _fresh()
	var tw := get_tree().create_tween()
	tw.tween_interval(10.0)
	var left: PackedStringArray = await _leaks()
	check(_has(left, "tweens: 1"), "the tween's named (%s)" % [left])
	tw.kill()


func test_shuffled_order_is_seeded() -> void:
	await _fresh()
	var runner := load("res://tests/run_tests.gd") as GDScript
	var files := []
	for i in 40:
		files.append("test_%02d.gd" % i)
	var a: Array = runner.call(&"shuffled", files, 7)
	var b: Array = runner.call(&"shuffled", files, 7)
	var c: Array = runner.call(&"shuffled", files, 8)
	check(a == b, "the same seed, the same order")
	check(a != c, "another seed, another order")
	check(a != files, "not the suite's order")
	var sa := a.duplicate()
	sa.sort()
	check(sa == files, "every file once")
