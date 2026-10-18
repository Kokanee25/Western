extends SceneTree
## What a man costs a frame by his body model, alone (the street's bench is noisier than the
## difference): N men of each model standing on a floor, idle, headless; the frame's wall clock
## with them less without them, per man, at 3.25 GHz as the perf bench scales it (clock_scale).
##   godot --headless --fixed-fps 60 -s res://tools/people_cost.gd -- [--ids=outlaw,bold_made] [--n=10]
## Untyped on purpose: -s scripts compile before autoloads exist.

func _initialize() -> void:
	_run.call_deferred()


func _avg(frames: int) -> float:
	var t0 := Time.get_ticks_usec()
	for i in frames:
		await physics_frame
	return (Time.get_ticks_usec() - t0) / 1000.0 / frames


func _run() -> void:
	var ids := ["outlaw", "bold_made"]
	var n := 10
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
		elif a.begins_with("--n="):
			n = int(a.substr(4))
	var scale: float = load("res://config/frame_budget.tres").clock_scale
	var w := Node3D.new()
	root.add_child(w)
	var floor := StaticBody3D.new()
	var fs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	fs.shape = box
	floor.add_child(fs)
	w.add_child(floor)
	floor.position = Vector3(0, -0.5, 0)
	await _avg(30)
	var empty := minf(await _avg(300), await _avg(300))
	print("people_cost: empty frame %.3f ms" % empty)
	var body_script = load("res://src/bodies/human_body.gd")
	for id in ids:
		var men := []
		for i in n:
			var m = body_script.new()
			m.body_model = StringName(id)
			m.person_id = StringName("%s_%d" % [id, i])
			m.rng_seed = 11 + i
			w.add_child(m)
			m.global_position = Vector3((i % 5) * 1.2 - 2.4, 0.0, (i / 5) * 1.5)
			men.append(m)
		await _avg(60)
		var t := minf(await _avg(300), await _avg(300))
		print("people_cost: %s: %.3f ms a man a frame (%.3f at 3.25 GHz), %d men" % [id, (t - empty) / n, (t - empty) / n * scale, n])
		for m in men:
			m.free()
		await _avg(30)
	quit()
