extends "res://experiments/physics_lab/lab.gd"
## The body lab's command line (README.md beside this file). One process runs one scenario on one
## man (run.py runs them all, one process each, as the ragdoll lab does):
##
##   godot --headless --fixed-fps 60 -s res://experiments/body_lab/lab.gd -- --scenario=revolver_05m_thigh --model=old_rancher_s1 --out=DIR
##   godot --headless -s res://experiments/body_lab/lab.gd -- --scenario=list
##   godot --headless -s res://experiments/body_lab/lab.gd -- --vessels --out=DIR     (every artery, vein and organ cut alone)
##   godot --headless --fixed-fps 60 -s res://experiments/body_lab/lab.gd -- --perf --model=mixed --out=DIR
##   xvfb-run -a godot --rendering-driver vulkan --fixed-fps 60 -s res://experiments/body_lab/lab.gd -- --scenario=check --render --model=... --out=DIR
##
## --model=ID (assets/people/<id>.glb; the lab's own choice, never the game's default; `mixed` in
## --perf cycles the three studio men). --seed=N. --render (pictures into DIR/frames/). --size=WxH.
## Extends the ragdoll lab's lab.gd for its arguments and manifest. Untyped where it must be: -s
## scripts compile before autoloads exist.

const BENCH := "res://experiments/body_lab/wound_bench.gd"


func _run() -> void:
	var bench = load(BENCH)
	var all: Array = bench.scenarios()
	if args.get("scenario", "") == "list":
		for s in all:
			print("%-26s %s" % [s.name, s.group])
		quit(0)
		return
	var sha := _sha()
	out_root = args.get("out", "build/body_lab/%s" % sha.substr(0, 8))
	if not out_root.is_absolute_path():
		out_root = ProjectSettings.globalize_path("res://").path_join(out_root)
	DirAccess.make_dir_recursive_absolute(out_root)
	if not FileAccess.file_exists(out_root.path_join(".gdignore")):
		FileAccess.open(out_root.path_join(".gdignore"), FileAccess.WRITE).close()
	var manifest := {"source_sha": sha, "godot": Engine.get_version_info(),
			"physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine"),
			"physics_ticks_per_second": Engine.physics_ticks_per_second,
			"hardware": {"cpu": OS.get_processor_name(), "threads": OS.get_processor_count(), "os": OS.get_name()},
			"command": " ".join(OS.get_cmdline_args()), "user_args": OS.get_cmdline_user_args(),
			"seed": int(args.get("seed", str(bench.data().seed)))}
	if args.has("vessels"):
		var rows := []
		for st: Dictionary in Anatomy.shared().structures:
			if st.kind in [&"artery", &"vein", &"organ"]:
				rows.append(bench.vessel(st.id))
		manifest["vessels"] = rows
		_save(out_root.path_join("vessels.json"), manifest)
		print("lab: %d vessels and organs into %s" % [rows.size(), out_root])
		quit(0)
		return
	var picked := []
	if args.has("perf"):
		picked = [{"name": "perf", "group": "perf", "kind": "perf"}]
	else:
		for name in String(args.get("scenario", "")).split(","):
			for s in all:
				if s.name == name or ("group:" + s.group) == name:
					picked.append(s)
	if picked.is_empty():
		push_error("lab: no scenario %s (--scenario=list)" % args.get("scenario", ""))
		quit(1)
		return
	var models: Array = String(args.get("model", "outlaw")).split(",")
	# A man whose model won't load would quietly be the default body (PeopleBodies falls back to
	# BodyMesh): refuse instead. (After a fresh checkout, `godot --headless --import` first.)
	for m: String in models:
		if m != "mixed" and not ResourceLoader.exists("res://assets/people/%s.glb" % m):
			push_error("lab: no model %s (assets/people/%s.glb not there or not imported)" % [m, m])
			quit(1)
			return
	for s: Dictionary in picked:
		for m: String in models:
			var dir := out_root.path_join(m).path_join(s.name)
			var script = load("res://experiments/body_lab/lab_runner.gd")
			if script == null or not script.can_instantiate():
				push_error("lab: lab_runner.gd doesn't load")
				quit(1)
				return
			var runner = script.new()
			runner.scenario = s
			runner.out_dir = dir
			runner.render = args.has("render")
			runner.seed_value = int(manifest.seed)
			runner.brains = args.has("brains")
			runner.grab_on = not args.has("no-grab")
			if args.has("size"):
				var wh: PackedStringArray = args.size.split("x")
				runner.view_size = Vector2i(int(wh[0]), int(wh[1]))
			# `mixed`: the three studio men in turn (the perf run's ten).
			runner.model = StringName("bold_cowboy_s0" if m == "mixed" else m)
			if m == "mixed":
				runner.set_meta(&"mixed", ["bold_cowboy_s0", "old_rancher_s1", "young_drifter_s1"])
			root.add_child(runner)
			while not runner.done:
				await physics_frame
			var own := manifest.duplicate()
			own["scenario"] = s
			own["model"] = m
			_save(dir.path_join("manifest.json"), own)
			print("%-26s %-18s %s" % [s.name, m, _line(runner.summary)])
			runner.queue_free()
			for i in 3:
				await physics_frame
	quit(0)


func _line(sm: Dictionary) -> String:
	if sm.has("grab"):
		var g: Dictionary = sm.grab
		return "hand %s, there in %s s, palm %s cm from the hole at 1 s, %s at the end%s" % [g.hand, g.reached_s, g.palm_to_hole_cm_at_1s,
				g.palm_to_hole_cm_end, " (down)" if g.down else ""]
	if sm.has("same_tick"):
		return ", ".join(sm.same_tick.map(func(c): return "%s: %d wound(s)" % [c.case, c.wounds]))
	if sm.has("check"):
		var c: Dictionary = sm.check
		return "wound open %s, hat shot off %s, stumps %s" % [c.wound.open, c.hat.shot_off,
				", ".join(c.stumps.map(func(s): return "%s %s" % [s.segment, s.stump_open_edges]))]
	if sm.has("frame_ms_after"):
		return "people %.2f ms (Sean's %.2f) of %.1f; frame %.2f; %d down" % [sm.people_ms_after.mean, sm.people_ms_after_at_seans,
				sm.budget_ms, sm.frame_ms_after.mean, sm.down]
	var o: Dictionary = sm.get("outcomes", {}).get("none", {})
	return "crossed %s | dead %s (%s)" % [",".join(sm.get("crossed", {}).keys()), o.get("dead_s"), o.get("cause", "")]


func _save(path: String, d: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))
	f.close()
