extends "res://tools/perf_bench.gd"
## The load test for one man (docs/style_test/two-tests-2026-10-19): the performance bench's calm
## street (tools/perf_bench.gd, measured and held to config/frame_budget.tres as it is) with
## `--count` copies of one people.json man standing about in the street as well, so what he costs
## shows against the budget. Only a load test: the copies aren't new men in the game.
##   godot --headless --fixed-fps 60 -s res://tools/characters/men_bench.gd -- --men=bold_cowboy_whole \
##       [--count=10] [--seconds=20] [--out=file.json] (and perf_bench's own flags)
## --men=none: the street as it is, for the baseline.

var men_id := "bold_cowboy_whole"
var men_count := 10


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--men="):
			men_id = a.substr(6)
		elif a.begins_with("--count="):
			men_count = int(a.substr(8))
	only = "calm"
	ablate = false
	root.get_node(^"Settings").autosave = false
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(3)
	street = main.find_child("TestStreet", true, false)
	var player = street.get_node(^"Player")
	player.input_enabled = false
	var town = street.get_node(^"TownLife")
	town.bring_gang()
	player.global_position = Vector3(11.0, 0.0, -9.0)
	player.rotation = Vector3(0, deg_to_rad(121.0), 0)
	# The copies: in two rows down the street in front of the player, facing him, each idling.
	if men_id != "none":
		for i in men_count:
			var m = load("res://src/bodies/human_body.gd").new()
			m.name = "Copy%d" % i
			m.body_model = StringName(men_id)
			m.person_id = StringName("%s_copy%d" % [men_id, i])
			m.rng_seed = 300 + i
			street.add_child(m)
			m.global_position = Vector3(6.0 - (i / 2) * 2.5, 0.0, -10.5 + (i % 2) * 3.0)
			m.face(player.global_position)
			m.set_pose(&"stand")
	await _frames(120)
	var here := 0
	for n in street.get_children():
		if String(n.name).begins_with("Copy"):
			here += 1
	print("men_bench: %d copies of %s in the street" % [here, men_id])
	var frames := int(seconds * 60.0)
	var m: Dictionary = await _measure(frames)
	var entry := {"frames": m, "census": _census(), "men": {"id": men_id, "count": men_count if men_id != "none" else 0}}
	if budget_report:
		entry["budget"] = await _budget(m)
	report["calm"] = entry
	_print("calm", entry)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "  "))
	quit()
