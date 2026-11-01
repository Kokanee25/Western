extends BridgeLab
## The train lab's dev bridge commands (issues #543, #551; README). The line is built by
## `train_lab [ROUTE]` (or the first command that needs it), out on the flat round town.

const LAB := preload("res://experiments/train_lab/lab.gd")

const HELP := {
	"train_lab": "train_lab [ROUTE] -> build the line (routes/ROUTE.json, default test_line) and its train at its first stop, the line's numbers",
	"train": "train -> the train now: s, km/h, levers, regulator, steam, brake, what limits it",
	"throttle": "throttle X -> the engineer's hand on the regulator, 0..1",
	"brake": "brake X -> the brake handle, 0..1",
	"reverser": "reverser 1|-1 -> forward (toward B) or back",
	"train_place": "train_place S|MARK [KMH] -> the train's front at S (or a mark by name), at a speed (default standing)",
	"train_drive": "train_drive off|hold [KMH]|whole [KMH] -> a scripted driver: hold a speed, or run to the mine and stop",
	"train_engineer": "train_engineer on [LATE_S] [LEAD_S]|off|to MARK [KMH] -> the engineer drives to the route's timetable (LATE_S late off the first stop; the clock LEAD_S before it), or runs to one mark; off stops him",
	"train_engineer_log": "train_engineer_log [PATH] -> his state, arrivals and (PATH) his log a second as CSV",
	"train_events": "train_events [N] -> the last N coupler events (runs out / bunches)",
	"train_slack": "train_slack on|off -> the slack readout on the screen (gaps, each car's speed, clanks)",
	"train_crate": "train_crate S|MARK [ACROSS] -> a kit crate standing on the line at S (ACROSS m off its middle)",
	"train_struck": "train_struck -> what the train's leading end has struck (props, men) and the crates' positions",
	"train_ride": "train_ride CAR -> the player standing on a car (index or name: engine (the cab), tender, ore1, boxcar, coach...), facing ahead",
	"train_where": "train_where -> which car the player is on and where along it, on his feet or not",
	"train_cross": "train_cross on|off|wait [S] -> walk the player car to car to the cab, jumping each gap (wait: until he's there or S s), its log",
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


func _cmd_train_lab(a: Array) -> Dictionary:
	var lab := _lab()
	var line: TrackLine = lab.ensure_built(String(a[0]) if a.size() > 0 else "")
	var first: StringName = line.stops[0] if not line.stops.is_empty() else &""
	return {"route": String(line.route_name), "length": line.length, "marks": line.marks, "origin": arr(line.global_position),
		"first_stop": arr(line.to_global(line.point_at(line.mark(first)))) if first != &"" else [],
		"mass_t": lab.train.sim.mass / 1000.0, "train_length": lab.train.sim.length, "cars": lab.train.sim.cars.size()}


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
	var s := line.mark(StringName(a[0])) if line.marks.has(StringName(a[0])) else float(a[0])
	lab.train.place(s)
	var kmh := float(a[1]) if a.size() > 1 else 0.0
	if kmh > 0.0:
		var sim: TrainSim = lab.train.sim
		sim.v = kmh / 3.6
		sim.throttle = 0.0
		sim.brake_lever = 0.0
		for i in sim.brakes.size():
			sim.brakes[i] = 0.0
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


func _cmd_train_engineer(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var w: String = a[0] if a.size() > 0 else "on"
	if w == "off":
		lab.stop_engineer()
		return {"engineer": false}
	if w == "to":
		var line: TrackLine = lab.line
		var e := TrainEngineer.new(lab.train.sim, line, lab.tuning)
		var to := line.mark(StringName(a[1])) if a.size() > 1 and line.marks.has(StringName(a[1])) else float(a[1] if a.size() > 1 else 0.0)
		e.run_to(to, float(a[2]) if a.size() > 2 else lab.tuning.schedule_kmh)
		lab.train.engineer = e
		lab.driver = &""
		lab._place_engineer_man()
		return {"engineer": "to", "s": to}
	return lab.start_engineer(float(a[1]) if a.size() > 1 else 0.0, float(a[2]) if a.size() > 2 else 20.0)


func _cmd_train_engineer_log(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var e: TrainEngineer = lab.train.engineer
	if e == null:
		return {"ok": false, "error": "no engineer (train_engineer on)"}
	var out := {"state": String(e.state), "clock": Timetable.clock_text(e.clock), "delay": e.delay(), "to_go": e.to_go(),
		"cruise_kmh": e.cruise_kmh, "arrivals": e.arrivals, "run_m": e.run_m}
	if a.size() > 0 and not e.log.is_empty():
		var f := FileAccess.open(a[0], FileAccess.WRITE)
		var keys: Array = e.log[0].keys()
		f.store_line(",".join(keys))
		for r in e.log:
			var vals := PackedStringArray()
			for k in keys:
				vals.append(str(r[k]))
			f.store_line(",".join(vals))
		f.close()
		out.wrote = e.log.size()
	return out


func _cmd_train_events(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var ev: Array = lab.train.sim.events
	var n := int(a[0]) if a.size() > 0 else 12
	var out := []
	for e in ev.slice(maxi(0, ev.size() - n)):
		out.append({"t": snappedf(e.t, 0.01), "kind": String(e.kind), "between": "%s-%s" % e.between, "speed": snappedf(e.speed, 0.001)})
	return {"events": out, "count": lab.train.sim.event_count}


func _cmd_train_slack(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	lab.set_slack(a.is_empty() or a[0] != "off")
	return {"slack": lab.show_slack}


var _crates: Array[Node3D] = []


func _cmd_train_crate(a: Array) -> Dictionary:
	var lab := _lab()
	var line: TrackLine = lab.ensure_built()
	var s := line.mark(StringName(a[0])) if a.size() > 0 and line.marks.has(StringName(a[0])) else float(a[0] if a.size() > 0 else 300.0)
	var across := float(a[1]) if a.size() > 1 else 0.0
	var f := line.global_transform * line.transform_at(s)
	var crate := PropKit.spawn(&"crate")
	street.add_child(crate)
	# On the ballast between the rails (its top is a tie's half below the rail tops).
	var t: TrainTuning = lab.tuning
	crate.global_transform = Transform3D(f.basis, f.origin + f.basis.x * across - f.basis.y * (t.rail_size.y + t.tie_size.y * 0.5))
	_crates.append(crate)
	await physics_frames(3)
	return {"crate": String(crate.name), "at": arr(crate.global_position), "s": s}


func _cmd_train_struck(_a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var crates := []
	for c in _crates:
		if not is_instance_valid(c):
			continue
		var ps := []
		for rb in (c.rubble if c.get("rubble") != null else []):
			if is_instance_valid(rb):
				ps.append(arr(rb.global_position))
		crates.append({"name": String(c.name), "loose": c.get("loose"), "at": arr(c.global_position), "pieces": ps})
	return {"struck": lab.train.struck_log, "crates": crates}


func _cmd_train_ride(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var r: Dictionary = lab.ride(String(a[0]) if a.size() > 0 else "boxcar")
	await physics_frames(2)
	r.on = lab.player_on()
	return r


func _cmd_train_where(_a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var r: Dictionary = lab.player_on()
	r.player = arr(player.global_position)
	r.kmh = lab.train.sim.v * 3.6
	return r


func _cmd_train_cross(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var w: String = a[0] if a.size() > 0 else "on"
	if w == "off":
		lab.cross(false)
		return {"crossing": false, "log": lab.cross_log}
	if w == "wait":
		var limit := float(a[1]) if a.size() > 1 else 60.0
		var t := 0.0
		while lab.crossing and t < limit:
			await seconds(0.5)
			t += 0.5
		return {"crossing": lab.crossing, "log": lab.cross_log, "where": lab.player_on()}
	lab.cross(true)
	return {"crossing": true, "from": lab.player_on()}
