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
