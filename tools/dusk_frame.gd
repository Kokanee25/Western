extends SceneTree
## The dusk stall (#491): the game's street loaded as the game loads it, the clock put at dusk,
## then each frame timed for a while (the game's light re-blends as the sun goes down); prints the
## frames over LIMIT_MS and the worst, here and at Sean's clock (FrameBudget.clock_scale), and the
## time of one LightLooks.blend with what each kind of dial costs in it. Exits 1 if the light's own
## share of a frame (Prof `light_looks`) is ever over LIGHT_MS at Sean's; slow frames from other
## systems are printed with their timers but don't fail it. The clock runs at --speed (x30: the blend steps at each of its checks, four
## times a second; at x1 it steps every ~2.4 s, as in Sean's reports); an over frame names its
## biggest Prof timers.
##
##   godot --headless --fixed-fps 60 -s res://tools/dusk_frame.gd -- [--hour=17.6] [--seconds=20] [--speed=30] [--spec]
## --spec: the building lab's saloon built (as F5's stop and the gunfight lab build it) and the
## player put in its hall, where Sean's F12 reports were taken (18:00, x1).
## Untyped on purpose: -s scripts compile before autoloads exist.

const LIMIT_MS := 20.0  # at Sean's clock
const LIGHT_MS := 8.0  # the light looks' share of one frame, at Sean's


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var hour := 17.6
	var seconds := 20.0
	var speed := 30.0
	var spec := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hour="):
			hour = float(a.substr(7))
		elif a.begins_with("--seconds="):
			seconds = float(a.substr(10))
		elif a.begins_with("--speed="):
			speed = float(a.substr(8))
		elif a == "--spec":
			spec = true
	root.get_node(^"Settings").autosave = false
	var scale: float = load("res://config/frame_budget.tres").clock_scale
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 30:
		await process_frame
	if spec:
		var town = main.find_child("TownLife", true, false)
		var spec_saloon = load("res://experiments/gunfight_lab/spec_saloon.gd")
		spec_saloon.ensure(town.get_parent(), town.places)
		for i in 30:
			await physics_frame
		var player = main.find_child("Player", true, false)
		if player:
			player.global_position = spec_saloon.at(Vector3(6.0, 1.0, 6.0))
			player.velocity = Vector3.ZERO
	var clock = main.find_child("DayCycle", true, false)
	clock.set_time(hour)
	for i in 30:
		await process_frame
	var looks = load("res://src/render/light_looks.gd")
	var preset = load("res://src/debug/look_preset.gd")
	print("nodes: %d; night share at %.2f h: %.3f" % [_count(root), clock.time_of_day, looks.night_share(self)])
	# One blend, whole, a few times (each a little further into the night: a fresh grade step too).
	var t0: float = looks.night_share(self)
	for k in 4:
		var a := Time.get_ticks_usec()
		looks.blend(self, clampf(t0 + 0.03 * (k + 1), 0.0, 1.0))
		var ms := (Time.get_ticks_usec() - a) / 1000.0
		print("blend %d: %.1f ms here, %.1f at Sean's" % [k, ms, ms * scale])
	looks.blend(self, t0)
	# What each kind of dial costs: its read and its set, the value it has now.
	var game: Dictionary = preset.load_file(looks.GAME)
	var all := {}
	for f in [game.day, game.night]:
		all.merge(preset.load_file(f).get("values", {}))
	all.merge(game.get("night_values", {}))
	all.merge(game.get("day_values", {}))
	var by := {}
	for addr: String in all:
		var a := Time.get_ticks_usec()
		var v = preset.get_value(self, addr)
		var b := Time.get_ticks_usec()
		if v != null:
			preset.set_value(self, addr, v)
		var c := Time.get_ticks_usec()
		var g := addr.get_slice(".", 0)
		var row: Array = by.get(g, [0, 0.0, 0.0])
		by[g] = [row[0] + 1, row[1] + (b - a) / 1000.0, row[2] + (c - b) / 1000.0]
	for g in by:
		print("  %-9s %2d dials: read %.1f ms, set %.1f ms (here)" % [g, by[g][0], by[g][1], by[g][2]])
	# The frames, the clock running.
	var prof = load("res://src/debug/prof.gd")
	prof.on = true
	clock.set_time_scale(speed)
	var h0: float = clock.time_of_day
	var s0: float = looks.night_share(self)
	prof.frame()
	var worst := 0.0
	var over := 0
	var light_worst := 0.0
	var frames := int(seconds * 60.0)
	var last := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		prof.frame()
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		if ms * scale > LIMIT_MS:
			over += 1
			var top := []
			for k in prof.TOP:
				if prof.frame_top_names[k] != &"":
					top.append("%s %.1f" % [prof.frame_top_names[k], prof.frame_top_ms[k]])
			print("frame %d (%.2f h): %.1f ms here, %.1f at Sean's; its biggest (ms here): %s" % [i,
					clock.time_of_day, ms, ms * scale, ", ".join(top)])
		worst = maxf(worst, ms)
		light_worst = maxf(light_worst, prof.frame_ms.get(&"light_looks", 0.0))
	print("the clock %.2f -> %.2f h, the night share %.3f -> %.3f" % [h0, clock.time_of_day, s0, looks.night_share(self)])
	print("dusk_frame: %d frames, worst %.1f ms here (%.1f at Sean's), %d over %.0f ms at Sean's" % [frames, worst,
			worst * scale, over, LIMIT_MS])
	print("the light looks' worst frame: %.1f ms here, %.1f at Sean's (the line %.0f)" % [light_worst,
			light_worst * scale, LIGHT_MS])
	quit(1 if light_worst * scale > LIGHT_MS else 0)


func _count(n: Node) -> int:
	var c := 1
	for k in n.get_children():
		c += _count(k)
	return c
