extends SceneTree
## The train lab's headless runs (issue #543): every scenario on the 1D train, a CSV each and a
## summary, for graphs.py.
##   godot --headless -s res://experiments/train_lab/run.gd -- --out=build/train_lab [--tuning=res://config/train.tres]

const SC := preload("res://experiments/train_lab/scenarios.gd")


func _init() -> void:
	var out := "build/train_lab"
	var tuning_path := "res://config/train.tres"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--tuning="):
			tuning_path = a.substr(9)
	DirAccess.make_dir_recursive_absolute(out)
	var t: TrainTuning = load(tuning_path)
	var summary := {}
	var runs := {"start": SC.start(t), "stop30": SC.stop30(t), "climb": SC.climb(t),
		"descent": SC.descent(t), "whole_run": SC.whole_run(t)}
	for sc_name in runs:
		var r: Dictionary = runs[sc_name]
		_csv(out.path_join(sc_name + ".csv"), r.rows)
		summary[sc_name] = r.summary
	summary.top_speed_level_kmh = SC.top_speed(t)
	var sim := TrainSim.new(t, null)
	summary.consist = {"mass_t": sim.mass / 1000.0, "length_m": sim.length, "cars": sim.cars.size()}
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
