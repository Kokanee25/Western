extends TestCase
## CI's pull requests run the tests their changes need (#1234): tools/test_select.py reads
## config/test_map.json and passes its choice to run_tests.gd --files=. A test renamed or removed
## must not leave the map pointing at nothing (a rule whose tests all vanished would quietly run
## none), and --files must run exactly what it names. (The select job also runs
## `tools/test_select.py --check`, which checks the same in Python.)

const Runner := preload("res://tests/run_tests.gd")


func _all_files() -> Array:
	var files := Array(DirAccess.get_files_at("res://tests")).filter(
			func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd")
	files.sort()
	return files


func _map() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/test_map.json"))
	return parsed if parsed is Dictionary else {}


func _matches(pattern: String, files: Array) -> bool:
	for f: String in files:
		if f.match(pattern):
			return true
	return false


func test_the_map_reads_and_its_core_is_there() -> void:
	var m := _map()
	check(not m.is_empty(), "config/test_map.json reads")
	var files := _all_files()
	for name: String in m.get("core", []):
		check(files.has(name), "core test %s is a test file" % name)
	check(int(m.get("max_shards", 0)) >= 1 and int(m.get("all_shards", 0)) >= 1, "shard counts set")


func test_every_pattern_names_a_test() -> void:
	var m := _map()
	var files := _all_files()
	var groups: Dictionary = m.get("groups", {})
	var patterns: Array = []
	for g: String in groups:
		patterns.append_array(groups[g])
	for rule: Dictionary in m.get("rules", []):
		if rule["tests"] is Array:
			patterns.append_array(rule["tests"])
	for p: String in patterns:
		if p.begins_with("@"):
			check(groups.has(p.substr(1)), "group %s exists" % p)
		elif not p.contains("{"):
			check(_matches(p, files), "%s matches a test file" % p)


func test_files_picks_what_it_names_in_the_suites_order() -> void:
	var files := ["test_a.gd", "test_b.gd", "test_c.gd"]
	check_eq(Runner.pick_files(files, "test_c.gd,test_a.gd"), ["test_a.gd", "test_c.gd"], "two of three")
	check_eq(Runner.pick_files(files, ""), [], "none")
	# A chosen set is then split by --shard as the whole suite is.
	var chosen := Runner.pick_files(_all_files(), "test_project.gd,test_valley.gd,test_native.gd")
	var seen := 0
	for k in 2:
		seen += Runner.shard_files(chosen, Runner.load_times(), k, 2).size()
	check_eq(seen, 3, "the three across two shards")
