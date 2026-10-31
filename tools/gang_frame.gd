extends SceneTree
## The gang's ride-in frame (#488): the game's street loaded as the game loads it, then its first
## two minutes (the gang rides in at 45 s), each frame's `town_life` time (Prof) taken; prints the
## frames over the line and the worst, here and at Sean's clock (FrameBudget.clock_scale). Exits 1
## if a `town_life` frame is over 5 ms at Sean's (the issue's gate).
##
##   godot --headless --fixed-fps 60 -s res://tools/gang_frame.gd -- [--seconds=120] [--arrive=45]
## Untyped on purpose: -s scripts compile before autoloads exist.

const LIMIT_MS := 5.0  # at Sean's clock


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var seconds := 120.0
	var arrive := -1.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.substr(10))
		elif a.begins_with("--arrive="):
			arrive = float(a.substr(9))
	root.get_node(^"Settings").autosave = false
	var scale: float = load("res://config/frame_budget.tres").clock_scale
	var prof = load("res://src/debug/prof.gd")
	prof.on = true
	var t0 := Time.get_ticks_usec()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	print("load: %.0f ms (the first frame in)" % ((Time.get_ticks_usec() - t0) / 1000.0))
	var town = main.find_child("TownLife", true, false)
	if arrive >= 0.0:
		town.gang_arrives = arrive
	prof.frame()  # (the load's own sums out of the way)
	var worst := 0.0
	var worst_frame := -1
	var arrived_at := -1
	var frames := int(seconds * 60.0)
	for i in frames:
		var a := Time.get_ticks_usec()
		var before: bool = town._arrived
		await process_frame
		prof.frame()
		var ms: float = prof.frame_ms.get(&"town_life", 0.0)
		var wall := (Time.get_ticks_usec() - a) / 1000.0
		if ms * scale > LIMIT_MS or before != town._arrived:
			print("frame %d (%.1f s): town_life %.2f ms here, %.2f at Sean's; the frame %.1f ms%s" % [i, i / 60.0,
					ms, ms * scale, wall, " (the gang rode in)" if before != town._arrived else ""])
		if before != town._arrived:
			arrived_at = i
		if arrived_at >= 0 and i - arrived_at < 4:
			var top := []
			for k in prof.TOP:
				if prof.frame_top_names[k] != &"":
					top.append("%s %.1f" % [prof.frame_top_names[k], prof.frame_top_ms[k]])
			print("   frame %d, %.1f ms; its biggest (ms here): %s" % [i, wall, ", ".join(top)])
		if ms > worst:
			worst = ms
			worst_frame = i
	var gang: int = town.gang.filter(func(g): return is_instance_valid(g) and g.is_inside_tree()).size()
	print("worst town_life %.2f ms here, %.2f at Sean's (frame %d); the gang in: %d" % [worst, worst * scale, worst_frame, gang])
	var ok: bool = worst * scale <= LIMIT_MS and gang == 3
	print("PASS" if ok else "FAIL")
	main.free()
	quit(0 if ok else 1)
