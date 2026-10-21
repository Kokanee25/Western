extends SceneTree
## The ragdoll lab's command line (docs/prompts/01_Testing_Lab.md; README.md beside this file).
##
##   godot --headless --fixed-fps 60 -s res://experiments/physics_lab/lab.gd -- --scenario=all --out=build/physics_lab/base
##   xvfb-run -a godot --rendering-driver vulkan --fixed-fps 60 -s res://experiments/physics_lab/lab.gd -- \
##       --scenario=A_stand_shot_front --render --out=build/physics_lab/shots
##
## --scenario=NAME[,NAME...] | all | group:A[,F] | list. --seconds=S (override each one's length).
## --seed=N (HumanBody.rng_seed). --model=ID (the body: outlaw, the MakeHuman man, by default).
## --repeat=K (each scenario K times in this one process, compared tick by tick with the first).
## --perf (1, 5 and 10 men going limp on the same tick; frame times).
## --render --views=front,side,three,top --size=480x360 --every=2 (a frame every N ticks).
## Untyped on purpose: -s scripts compile before autoloads exist.

var args := {}
var out_root := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_run.call_deferred()


func _scenarios() -> Array:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/physics_lab/scenarios.json"))
	return data.scenarios


func _pick(all: Array) -> Array:
	var want: String = args.get("scenario", "all")
	if want == "all":
		return all
	var out := []
	if want.begins_with("group:"):
		var groups := want.substr(6).split(",")
		for s in all:
			if s.group in groups:
				out.append(s)
		return out
	for name in want.split(","):
		for s in all:
			if s.name == name:
				out.append(s)
	return out


func _sha() -> String:
	var o := []
	OS.execute("git", ["rev-parse", "HEAD"], o)
	return (o[0] as String).strip_edges() if o.size() > 0 else "unknown"


func _run() -> void:
	var all := _scenarios()
	if args.get("scenario", "") == "list":
		for s in all:
			print("%-24s %s  %s" % [s.name, s.group, s.fixture])
		quit(0)
		return
	var sha := _sha()
	out_root = args.get("out", "build/physics_lab/%s" % sha.substr(0, 8))
	if not out_root.is_absolute_path():
		out_root = ProjectSettings.globalize_path("res://").path_join(out_root)
	DirAccess.make_dir_recursive_absolute(out_root)
	# Thousands of frames: keep Godot from importing them (as tools/tour.gd does).
	if not FileAccess.file_exists(out_root.path_join(".gdignore")):
		FileAccess.open(out_root.path_join(".gdignore"), FileAccess.WRITE).close()
	var picked := _pick(all)
	if picked.is_empty() and not args.has("perf"):
		push_error("lab: no scenario %s (--scenario=list)" % args.get("scenario", ""))
		quit(1)
		return
	if args.has("in-process") == false and picked.size() > 1:
		push_warning("lab: %d scenarios in one process; each after the first may fall differently from a run on its own (README, Determinism). run.py runs one a process." % picked.size())
	if args.has("perf"):
		picked = []
		for n in [1, 5, 10]:
			var s: Dictionary = all[1].duplicate(true)  # A_stand_shot_front
			s.name = "perf_%02d_men" % n
			s.seconds = 10.0
			s.pre = {"do": "stand", "seconds": 2.0}
			s["men"] = n
			s["light"] = true
			picked.append(s)
	var manifest := {
		"source_sha": sha, "godot": Engine.get_version_info(),
		"physics_engine": ProjectSettings.get_setting("physics/3d/physics_engine"),
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"physics_settings": {
			"run_on_separate_thread": ProjectSettings.get_setting("physics/3d/run_on_separate_thread"),
			"jolt": _jolt_settings(),
		},
		"fixed_fps_arg": "--fixed-fps 60" in " ".join(OS.get_cmdline_args()),
		"hardware": {"cpu": OS.get_processor_name(), "threads": OS.get_processor_count(), "os": OS.get_name(),
				"video": RenderingServer.get_video_adapter_name() if not DisplayServer.get_name() == "headless" else "headless"},
		"command": " ".join(OS.get_cmdline_args()), "user_args": OS.get_cmdline_user_args(),
		"note_determinism": "Same machine and build: repeat runs are compared tick by tick (--repeat). Across machines, OSes or builds rigid-body results are not expected to match bit for bit.",
		"scenarios": [],
	}
	var summaries := []
	var repeat := int(args.get("repeat", "1"))
	for s: Dictionary in picked:
		if args.has("seconds"):
			s.seconds = float(args.seconds)
		if args.has("seed"):
			s.seed = int(args.seed)
		var first_dir := ""
		for k in repeat:
			var dir := out_root.path_join(s.name) if k == 0 else out_root.path_join("%s_repeat%d" % [s.name, k])
			var runner_script: GDScript = load("res://experiments/physics_lab/lab_runner.gd")
			var body_script: GDScript = load("res://src/bodies/human_body.gd")
			if runner_script == null or not runner_script.can_instantiate() or body_script == null or not body_script.can_instantiate():
				# A script that doesn't parse would leave Godot waiting for ever (run.py waits 2 h).
				push_error("lab: lab_runner.gd or human_body.gd doesn't load")
				quit(1)
				return
			var runner = runner_script.new()
			runner.scenario = s
			runner.out_dir = dir
			runner.count = int(s.get("men", 1))
			runner.render = args.has("render")
			runner.light = bool(s.get("light", false))
			if args.has("views"):
				runner.views = Array(args.views.split(","))
			if args.has("size"):
				var wh: PackedStringArray = args.size.split("x")
				runner.view_size = Vector2i(int(wh[0]), int(wh[1]))
			if args.has("every"):
				runner.every = int(args.every)
			if args.has("old-flinch"):
				runner.old_flinch = true
			if args.has("mocap"):
				runner.mocap = true
			if args.has("follow"):
				runner.follow = true
			if args.has("cam-dist"):
				runner.cam_distance = float(args["cam-dist"])
			if args.has("model"):
				runner.model = StringName(args.model)
			root.add_child(runner)
			while not runner.done:
				await physics_frame
			var sm: Dictionary = runner.summary
			if k == 0:
				first_dir = dir
				summaries.append(sm)
				var entry := {"name": s.name, "definition": s, "seed": int(s.get("seed", 1)),
						"start": sm.get("start"), "dir": dir}
				manifest.scenarios.append(entry)
				var own := manifest.duplicate()
				own.scenarios = [entry]
				own["in_process_index"] = summaries.size() - 1
				var mf := FileAccess.open(dir.path_join("manifest.json"), FileAccess.WRITE)
				mf.store_string(JSON.stringify(own, "  "))
				mf.close()
				print("%-24s settle %s  flags %s  peak speed %.1f  pen %.3f" % [s.name,
						"%.2fs" % sm.settle_s if sm.settle_s != null else "never", ",".join(sm.raw_flags.keys()),
						sm.peak.speed, sm.peak.penetration])
				if s.has("men"):
					var st: Dictionary = sm.frame_ms_standing
					var co: Dictionary = sm.frame_ms_collapse_3s
					var af: Dictionary = sm.frame_ms_after_5s
					print("   %d men: frame ms standing %.2f (p99 %.2f) | collapse %.2f (p99 %.2f, max %.2f) | after 5 s %.2f (p99 %.2f); %d bodies, %d shapes, %d joints; asleep each second %s" % [
							s.men, st.mean, st.p99, co.mean, co.p99, co.max, af.mean, af.p99, sm.bodies, sm.shapes, sm.joints, sm.asleep_by_second])
			else:
				var d := _compare(first_dir, dir)
				print("   repeat %d: max position difference %.6f m (tick %d, %s)" % [k, d.max, d.tick, d.segment])
				summaries[-1]["repeat_%d" % k] = d
			runner.queue_free()
			for i in 3:
				await physics_frame
	manifest["summaries"] = summaries
	var f := FileAccess.open(out_root.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "  "))
	f.close()
	print("lab: %d scenario(s) into %s" % [picked.size(), out_root])
	quit(0)


func _jolt_settings() -> Dictionary:
	var out := {}
	for p in ProjectSettings.get_property_list():
		var n: String = p.name
		if n.begins_with("physics/jolt_physics_3d/"):
			out[n.substr(24)] = ProjectSettings.get_setting(n)
	return out


## Tick by tick, how far apart two runs' parts are (the run-to-run tolerance).
func _compare(a_dir: String, b_dir: String) -> Dictionary:
	var a := FileAccess.open(a_dir.path_join("segments.csv"), FileAccess.READ)
	var b := FileAccess.open(b_dir.path_join("segments.csv"), FileAccess.READ)
	var worst := {"max": 0.0, "tick": -1, "segment": ""}
	if a == null or b == null:
		return worst
	a.get_line()
	b.get_line()
	while not a.eof_reached() and not b.eof_reached():
		var la := a.get_line().split(",")
		var lb := b.get_line().split(",")
		if la.size() < 6 or lb.size() < 6:
			continue
		var pa := Vector3(float(la[3]), float(la[4]), float(la[5]))
		var pb := Vector3(float(lb[3]), float(lb[4]), float(lb[5]))
		var d := pa.distance_to(pb)
		if d > worst.max:
			worst = {"max": d, "tick": int(la[0]), "segment": la[2]}
	return worst
