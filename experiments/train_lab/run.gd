extends SceneTree
## The train lab's headless runs (issues #543, #551): every scenario on the 1D train, a CSV each
## and a summary, for graphs.py.
##   godot --headless -s res://experiments/train_lab/run.gd -- --out=build/train_lab [--tuning=res://config/train.tres] [--only=a,b]

const SC := preload("res://experiments/train_lab/scenarios.gd")


func _init() -> void:
	var out := "build/train_lab"
	var tuning_path := "res://config/train.tres"
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--tuning="):
			tuning_path = a.substr(9)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
	DirAccess.make_dir_recursive_absolute(out)
	var t: TrainTuning = load(tuning_path)
	var summary := {}
	var runs := {
		"start": func() -> Dictionary: return SC.start(t),
		"stop30": func() -> Dictionary: return SC.stop30(t),
		"climb": func() -> Dictionary: return SC.climb(t),
		"descent": func() -> Dictionary: return SC.descent(t),
		"whole_run": func() -> Dictionary: return SC.whole_run(t),
		"step1_start": func() -> Dictionary: return SC.start(t, SC.STEP1),
		"step1_stop30": func() -> Dictionary: return SC.stop30(t, SC.STEP1),
		"slack_start": func() -> Dictionary: return SC.slack_start(t),
		"slack_stop": func() -> Dictionary: return SC.slack_stop(t),
		"marks": func() -> Dictionary: return SC.marks(t),
		"on_time": func() -> Dictionary: return SC.timetable(t, 0.0),
		"late_start": func() -> Dictionary: return SC.timetable(t, 180.0),
		"relaid": func() -> Dictionary: return SC.timetable(t, 0.0, "relaid"),
		"relaid_late": func() -> Dictionary: return SC.timetable(t, 120.0, "relaid"),
	}
	for sc_name in runs:
		if not only.is_empty() and not only.has(sc_name):
			continue
		var u := Time.get_ticks_msec()
		var r: Dictionary = runs[sc_name].call()
		if not r.rows.is_empty():
			_csv(out.path_join(sc_name + ".csv"), r.rows)
		summary[sc_name] = r.summary
		summary[sc_name].wall_ms = Time.get_ticks_msec() - u
	if only.is_empty() or only.has("top_speed"):
		summary.top_speed_level_kmh = SC.top_speed(t)
		summary.step1_top_speed_level_kmh = SC.top_speed(t, SC.STEP1)
	var sim := TrainSim.new(t, null)
	summary.consist = {"mass_t": sim.mass / 1000.0, "length_m": sim.length, "cars": sim.cars.size()}
	var s1 := TrainSim.new(t, null, SC.STEP1)
	summary.step1_consist = {"mass_t": s1.mass / 1000.0, "length_m": s1.length, "cars": s1.cars.size()}
	var f := FileAccess.open(out.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	f.close()
	print(JSON.stringify(summary))
	quit(0)


func _csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	var keys: Array = rows[0].keys()
	f.store_line(",".join(keys))
	for r in rows:
		var vals := PackedStringArray()
		for k in keys:
			vals.append(str(r[k]))
		f.store_line(",".join(vals))
	f.close()
