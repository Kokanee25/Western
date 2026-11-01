extends BridgeLab
## The train lab's dev bridge commands (issue #543; README). The line is built by `train_lab`
## (or the first command that needs it), out on the flat south of town.

const LAB := preload("res://experiments/train_lab/lab.gd")

const HELP := {
	"train_lab": "train_lab -> build the test line and its train (at mark A), the line's numbers",
	"train": "train -> the train now: s, km/h, levers, regulator, steam, brake, what limits it",
	"throttle": "throttle X -> the engineer's hand on the regulator, 0..1",
	"brake": "brake X -> the brake handle, 0..1",
	"reverser": "reverser 1|-1 -> forward (toward B) or back",
	"train_place": "train_place S|A|B [KMH] -> the train's front at S (or a mark), at a speed (default standing)",
	"train_drive": "train_drive off|hold [KMH]|whole [KMH] -> a scripted driver: hold a speed, or run to B and stop",
	"train_cam": "train_cam cab|chase|curve|side_a|side S|player -> watch from the cab, chasing, lineside, or back to you",
	"train_log": "train_log on|off|PATH -> log every drawn frame (on clears it); PATH writes it as CSV (graphs.py --frames)",
	"train_cost": "train_cost [S] -> over S seconds (default 10): the train's tick and its drawing, ms a tick / a frame, and the frame's",
	"train_record": "train_record on|off|PATH -> the train's tick rows (on clears them); PATH writes them as CSV",
}


func _lab() -> Node:
	var lab := main.get_node_or_null(^"TrainLab")
	if lab == null:
		lab = LAB.new()
		lab.name = "TrainLab"
		main.add_child(lab)
	lab.street = street
	lab.player = player
	return lab


func _cmd_train_lab(_a: Array) -> Dictionary:
	var lab := _lab()
	var line: TrackLine = lab.ensure_built()
	return {"length": line.length, "marks": line.marks, "origin": arr(line.global_position),
		"mark_a": arr(line.to_global(line.point_at(float(line.marks.A)))), "mass_t": lab.train.sim.mass / 1000.0,
		"train_length": lab.train.sim.length}


func _cmd_train(_a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var sim: TrainSim = lab.train.sim
	var d := sim.to_dict()
	d.kmh = sim.v * 3.6
	d.limit = String(sim.limit)
	d.grade = lab.line.grade_at(sim.s - sim.length * 0.5)
	d.at = arr(lab.train.view.bodies[0].global_position)
	d.driver = String(lab.driver)
	return d


func _cmd_throttle(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	lab.train.sim.throttle = clampf(float(a[0]) if a.size() > 0 else 0.0, 0.0, 1.0)
	return {"throttle": lab.train.sim.throttle}


func _cmd_brake(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	lab.train.sim.brake_lever = clampf(float(a[0]) if a.size() > 0 else 0.0, 0.0, 1.0)
	return {"brake": lab.train.sim.brake_lever}


func _cmd_reverser(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	lab.train.sim.reverser = -1 if a.size() > 0 and int(a[0]) < 0 else 1
	return {"reverser": lab.train.sim.reverser}


func _cmd_train_place(a: Array) -> Dictionary:
	var lab := _lab()
	var line: TrackLine = lab.ensure_built()
	if a.is_empty():
		return {"ok": false, "error": HELP.train_place}
	var s := float(line.marks[a[0]]) if line.marks.has(a[0]) else float(a[0])
	lab.train.place(s)
	var kmh := float(a[1]) if a.size() > 1 else 0.0
	if kmh > 0.0:
		var sim: TrainSim = lab.train.sim
		sim.v = kmh / 3.6
		sim.throttle = 0.0
		sim.brake_lever = 0.0
		sim.brake = 0.0
	return {"s": lab.train.sim.s, "kmh": kmh}


func _cmd_train_drive(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var mode: String = a[0] if a.size() > 0 else "off"
	lab.driver = &"" if mode == "off" else StringName(mode)
	if a.size() > 1:
		lab.hold_kmh = float(a[1])
	return {"driver": String(lab.driver), "kmh": lab.hold_kmh}


func _cmd_train_cam(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var v: String = a[0] if a.size() > 0 else "chase"
	if v == "side":
		lab.set_view(&"side_a")
		lab.side_at = float(a[1]) if a.size() > 1 else 150.0
	else:
		lab.set_view(StringName(v))
	return {"view": String(lab.view), "side_at": lab.side_at}


func _cmd_train_log(a: Array) -> Dictionary:
	var lab := _lab()
	var w: String = a[0] if a.size() > 0 else "on"
	if w == "on":
		lab.frames.clear()
		lab.logging = true
		return {"logging": true}
	if w == "off":
		lab.logging = false
		return {"logging": false, "frames": lab.frames.size()}
	return {"wrote": lab.write_frames(w), "path": w}


func _cmd_train_record(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var w: String = a[0] if a.size() > 0 else "on"
	var train: Train = lab.train
	if w == "on":
		train.rows.clear()
		train.record = true
		return {"recording": true}
	if w == "off":
		train.record = false
		return {"recording": false, "rows": train.rows.size()}
	var f := FileAccess.open(w, FileAccess.WRITE)
	if f == null or train.rows.is_empty():
		return {"ok": false, "error": "nothing recorded, or can't write " + w}
	var keys: Array = train.rows[0].keys()
	f.store_line(",".join(keys))
	for r in train.rows:
		var vals := PackedStringArray()
		for k in keys:
			vals.append(str(r[k]))
		f.store_line(",".join(vals))
	f.close()
	return {"wrote": train.rows.size(), "path": w}


func _cmd_train_cost(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var train: Train = lab.train
	train.cost_reset()
	var f0 := Engine.get_process_frames()
	var u0 := Time.get_ticks_usec()
	await seconds(float(a[0]) if a.size() > 0 else 10.0)
	var c := train.cost
	var frames := Engine.get_process_frames() - f0
	return {"tick_ms": float(c.get("tick_us", 0)) / maxf(1.0, c.get("ticks", 0)) / 1000.0,
		"draw_ms": float(c.get("draw_us", 0)) / maxf(1.0, c.get("draws", 0)) / 1000.0,
		"ticks": c.get("ticks", 0), "frames": frames,
		"wall_ms_a_frame": float(Time.get_ticks_usec() - u0) / maxf(1.0, frames) / 1000.0,
		"kmh": train.sim.v * 3.6}
