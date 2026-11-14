extends SceneTree
## The three movement presets measured on a flat floor (tests/test_movement.gd's `measure()`), as a
## table for Sean against the old movement (worked out from its numbers: it had no presets).
##   godot --headless --fixed-fps 60 -s res://experiments/movement_feel/measure.gd -- --out=FILE.md

const ROWS := [
	["to_walk", "to a walk (95%), s", 0.09],
	["to_run", "standstill to a full run (95%), s", 0.19],
	["stop_walk", "stop from a walk, s", 0.13],
	["carry_walk", "... and carried on, m", 0.18],
	["stop_run", "stop from a run, s", 0.27],
	["carry_run", "... and carried on, m", 0.82],
	["steps_walk", "steps a second walking", 3.7],
	["steps_run", "steps a second running", 8.0],
	["bob_walk_cm", "head travel walking (top to bottom), cm", 4.4],
	["bob_run_cm", "head travel running, cm", 7.0],
	["footfalls_at_low", "footfalls with the head at its low (share; old: not tied)", NAN],
	["strafe_lean", "lean into a walking strafe, degrees", 0.0],
	["land_dip_cm", "dip landing a jump, cm", 0.0],
	["crouch", "crouch, 90% of the way down, s", 0.13],
	["crouch_sink_cm", "... sinking past it, cm", 0.0],
	["stand", "stand up, 90% of the way, s", 0.13],
	["player_ms", "the player's physics frame walking, ms (headless)", NAN],
	["motion_us", "the body's motion alone, µs", 0.0],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "experiments/movement_feel/results.md"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
	var bench: Node = load("res://tests/test_movement.gd").new()
	root.add_child(bench)
	var got := {}
	for preset: StringName in [&"light", &"middle", &"heavy"]:
		await bench.before_each()
		bench.player.set_movement(preset)
		await bench._settle_still()
		got[preset] = await bench.measure()
		await bench.after_each()
	var md := "# Movement presets, measured\n\nFlat floor, 60 Hz physics, `experiments/movement_feel/measure.gd` (%s).\n" % Time.get_date_string_from_system()
	md += "The old movement's column is worked out from its numbers (acceleration 30, deceleration 22, bob\n"
	md += "0.022 m at 0.7 a metre, a footstep every 0.75 m, the eyes sliding 3.5 m/s to a crouch).\n\n"
	md += "| | old | light | middle | heavy |\n|---|---|---|---|---|\n"
	for r in ROWS:
		var old: float = r[2]
		md += "| %s | %s | %s | %s | %s |\n" % [r[1], "–" if is_nan(old) else _n(old), _n(got[&"light"][r[0]]),
				_n(got[&"middle"][r[0]]), _n(got[&"heavy"][r[0]])]
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(md)
	f.close()
	print(md)
	quit(0)


func _n(v: float) -> String:
	return "%.2f" % v if absf(v) < 100.0 else "%.0f" % v
