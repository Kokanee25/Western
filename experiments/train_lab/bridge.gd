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
	"train_place": "train_place S|MARK [KMH] -> the train's front at S (or a named mark: depot, mine; A and B as step 1's), at a speed (default standing)",
	"train_drive": "train_drive off|hold [KMH]|whole [KMH] -> a scripted driver: hold a speed, or run to B and stop",
	"train_cam": "train_cam cab|chase|curve|side_a|side S|player -> watch from the cab, chasing, lineside, or back to you",
	"train_log": "train_log on|off|PATH -> log every drawn frame (on clears it); PATH writes it as CSV (graphs.py --frames)",
	"train_cost": "train_cost [S] -> over S seconds (default 10): the train's tick and its drawing, ms a tick / a frame, and the frame's",
	"train_record": "train_record on|off|PATH -> the train's tick rows (on clears them); PATH writes them as CSV",
	"train_route": "train_route test_line|relaid|FILE -> rebuild the line on another route file (the route-moves test)",
	"train_goto": "train_goto MARK|S [KMH] -> the engineer (in the cab) runs to a mark at KMH and stops on it, from wherever the train is",
	"train_watch": "train_watch CAR [ALONG] [SIDE] [UP] [BACK] [follow] -> a lineside camera where a car is now, SIDE m off the line, looking at the car's point ALONG m behind its front (BACK m further back); follow: it rides alongside the car",
	"train_slowmo": "train_slowmo X -> the game's time at X (0.05..1: slow motion for films; 1 back to normal)",
	"train_run": "train_run [LATE_S] -> the engineer in the cab runs the timetable from the depot (LATE_S late)",
	"train_engineer": "train_engineer -> the engineer now: state, bound for, cruise, delay, his stops (error on the mark)",
	"train_board": "train_board CAR [back|front|mid|M] -> you standing on a car (index or name: coach, express1...)",
	"train_cross": "train_cross [run] [nojump] [S] -> you walk the train forward to the cab (up to S s): which cars you were on",
	"train_jump_off": "train_jump_off [left|right] -> you jump off the side",
	"train_rider": "train_rider -> the car you stand on (-1 none), where you are, your speed",
	"train_crate": "train_crate S [SIDE] [KIND] -> a kit crate standing on the line at S (SIDE m right of the middle)",
	"train_man": "train_man S [SIDE] -> a man standing on the line at S",
	"train_struck": "train_struck -> men and props the train has struck",
	"train_hits": "train_hits -> the balls that have struck a car (which, its surface, where)",
	"train_placed": "train_placed -> the crates and men put on the line: where they are now, how far off the line",
	"train_events": "train_events [N] -> the last N couplers' slack-outs and bunches",
	"train_models": "train_models on|off -> the cars drawn as step 3's models or step 2's boxes (rebuilt; passengers go)",
	"train_passengers": "train_passengers N -> N passengers seated in the coach (window seats first)",
	"train_where": "train_where CAR [ALONG] [UP] -> a point on a car (for look/shoot): ALONG m behind its front",
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


var _events: Array = []


func _built() -> Node:
	var lab := _lab()
	lab.ensure_built()
	var train: Train = lab.train
	if not train.coupler.is_connected(_on_coupler):
		train.coupler.connect(_on_coupler)
	return lab


func _on_coupler(e: Dictionary) -> void:
	_events.append(e)
	if _events.size() > 2000:
		_events = _events.slice(1000)


func _car_index(lab: Node, w: String) -> int:
	if w.is_valid_int():
		return int(w)
	var cars: Array = lab.train.sim.cars
	for i in cars.size():
		if String(cars[i].name) == w or String(cars[i].kind) == w:
			return i
	return -1


func _cmd_train_lab(_a: Array) -> Dictionary:
	var lab := _lab()
	var line: TrackLine = lab.ensure_built()
	return {"length": line.length, "marks": line.marks, "origin": arr(line.global_position),
		"depot": arr(line.to_global(line.point_at(line.mark_s("depot")))), "mass_t": lab.train.sim.mass / 1000.0,
		"train_length": lab.train.sim.length, "cars": lab.train.sim.cars.map(func(c: Dictionary) -> String: return String(c.name))}


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
	var mark: String = {"A": "depot", "B": "mine"}.get(a[0], a[0])
	var s := line.mark_s(mark) if line.marks.has(mark) else float(a[0])
	lab.train.place(s)
	var kmh := float(a[1]) if a.size() > 1 else 0.0
	if kmh > 0.0:
		var sim: TrainSim = lab.train.sim
		sim.set_speed(kmh / 3.6)
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
		"engineer_ms": float(c.get("engineer_us", 0)) / maxf(1.0, c.get("ticks", 0)) / 1000.0,
		"sim_ms": float(c.get("sim_us", 0)) / maxf(1.0, c.get("ticks", 0)) / 1000.0,
		"solids_ms": float(c.get("solids_us", 0)) / maxf(1.0, c.get("ticks", 0)) / 1000.0,
		"strike_ms": float(c.get("strike_us", 0)) / maxf(1.0, c.get("ticks", 0)) / 1000.0,
		"draw_ms": float(c.get("draw_us", 0)) / maxf(1.0, c.get("draws", 0)) / 1000.0,
		"ticks": c.get("ticks", 0), "frames": frames,
		"wall_ms_a_frame": float(Time.get_ticks_usec() - u0) / maxf(1.0, frames) / 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"kmh": train.sim.v * 3.6}


func _cmd_train_route(a: Array) -> Dictionary:
	var lab := _lab()
	var w: String = a[0] if a.size() > 0 else "test_line"
	var file := w if w.begins_with("res://") else "res://experiments/train_lab/routes/%s.json" % w
	var line: TrackLine = lab.set_route(file)
	_built()
	return {"route": file, "length": line.length, "marks": line.marks}


func _cmd_train_run(a: Array) -> Dictionary:
	var lab := _built()
	var e: TrainEngineer = lab.start_engineer(float(a[0]) if a.size() > 0 else 0.0)
	await seconds(0.2)
	return {"timetable": lab.timetable.describe(), "late": e.late_until}


func _cmd_train_engineer(_a: Array) -> Dictionary:
	var lab := _built()
	var e: TrainEngineer = lab.engineer
	if e == null:
		return {"ok": false, "error": "no engineer: train_run first"}
	return {"state": ["wait", "run", "done"][e.state], "stop": e.stop, "target": e.target, "cruise_kmh": e.cruise * 3.6,
		"delay": e.delay(), "time": lab.train.sim.time, "kmh": lab.train.sim.v * 3.6, "alive": e._alive(),
		"stops": e.stop_log}


func _cmd_train_models(a: Array) -> Dictionary:
	var lab := _built()
	var view: TrainView = lab.train.view
	view.models = a.is_empty() or a[0] != "off"
	view.setup(view.track, view.sim)
	view.place()
	view.place_solids()
	return {"models": view.models}


func _cmd_train_passengers(a: Array) -> Dictionary:
	var lab := _built()
	var n: int = lab.seat_passengers(int(a[0]) if a.size() > 0 else 12)
	await seconds(1.0)
	var where := []
	for p: HumanBody in lab.passengers:
		where.append(arr(p.global_position))
	return {"seated": n, "at": where}


func _cmd_train_board(a: Array) -> Dictionary:
	var lab := _built()
	var i := _car_index(lab, a[0] if a.size() > 0 else "coach")
	if i < 0:
		return {"ok": false, "error": HELP.train_board}
	var r: Dictionary = lab.board(i, a[1] if a.size() > 1 else "back")
	await seconds(0.3)
	r.on = lab.train.car_under(player)
	r.at = arr(r.at)
	return r


func _cmd_train_cross(a: Array) -> Dictionary:
	var lab := _built()
	var limit := 120.0
	for w in a:
		if String(w).is_valid_float():
			limit = float(w)
	lab.cross("run" in a, not "nojump" in a)
	var t0: float = lab.train.sim.time
	while lab.crossing and lab.train.sim.time - t0 < limit:
		await seconds(0.25)
	if lab.crossing:
		lab._cross_end()
	# The cars he was on, in order, and any time he was on none (in a gap, or off the train).
	var order := []
	var off_ticks := 0
	var lowest := INF
	for r: Array in lab.cross_log:
		if r[1] >= 0 and (order.is_empty() or order[order.size() - 1] != r[1]):
			order.append(r[1])
		if r[1] < 0:
			off_ticks += 1
		lowest = minf(lowest, r[2])
	var on: int = lab.train.car_under(player)
	return {"cars_in_order": order, "reached_cab": on == 0, "now_on": on, "ticks": lab.cross_log.size(),
		"ticks_on_no_car": off_ticks, "lowest_y": lowest, "time": lab.train.sim.time - t0, "kmh": lab.train.sim.v * 3.6}


func _cmd_train_jump_off(a: Array) -> Dictionary:
	var lab := _built()
	lab.jump_off(a[0] if a.size() > 0 else "right")
	await seconds(2.0)
	return {"on": lab.train.car_under(player), "at": arr(player.global_position), "on_floor": player.is_on_floor(),
		"speed": Vector3(player.velocity.x, 0, player.velocity.z).length()}


func _cmd_train_rider(_a: Array) -> Dictionary:
	var lab := _built()
	var on: int = lab.train.car_under(player)
	var r := {"on": on, "at": arr(player.global_position), "on_floor": player.is_on_floor(),
		"speed": player.velocity.length(), "train_kmh": lab.train.sim.v * 3.6, "riding": lab.train.riding}
	if on >= 0:
		# Where he is on the car: m behind its front, m right of its middle, m above the rail.
		var c: Dictionary = lab.train.sim.cars[on]
		var local: Vector3 = lab.train.view.solids[on].global_transform.affine_inverse() * player.global_position
		r.on_car = [snappedf(local.z + (c.trucks.x + c.trucks.y) * 0.5, 0.01), snappedf(local.x, 0.01), snappedf(local.y, 0.01)]
	return r


func _cmd_train_crate(a: Array) -> Dictionary:
	var lab := _built()
	var s := float(a[0]) if a.size() > 0 else 300.0
	var prop: KitProp = lab.place_crate(s, float(a[1]) if a.size() > 1 else 0.0, StringName(a[2]) if a.size() > 2 else &"crate")
	await seconds(0.5)
	return {"prop": String(prop.name), "at": arr(prop.global_position)}


func _cmd_train_man(a: Array) -> Dictionary:
	var lab := _built()
	var man: HumanBody = lab.place_man(float(a[0]) if a.size() > 0 else 300.0, float(a[1]) if a.size() > 1 else 0.0)
	await seconds(0.5)
	return {"person": String(man.person_id), "at": arr(man.global_position)}


func _cmd_train_struck(_a: Array) -> Dictionary:
	var lab := _built()
	return {"struck": lab.train.struck}


func _cmd_train_events(a: Array) -> Dictionary:
	_built()
	var n := int(a[0]) if a.size() > 0 else 20
	return {"count": _events.size(), "last": _events.slice(maxi(0, _events.size() - n))}


func _cmd_train_where(a: Array) -> Dictionary:
	var lab := _built()
	var i := _car_index(lab, a[0] if a.size() > 0 else "coach")
	if i < 0:
		return {"ok": false, "error": HELP.train_where}
	var c: Dictionary = lab.train.sim.cars[i]
	var p: Vector3 = lab.car_point(i, float(a[1]) if a.size() > 1 else float(c.length) * 0.5, float(a[2]) if a.size() > 2 else 2.0)
	return {"car": String(c.name), "at": arr(p), "xyz": "%.2f %.2f %.2f" % [p.x, p.y, p.z]}


func _cmd_train_placed(_a: Array) -> Dictionary:
	var lab := _built()
	return {"placed": lab.placed_report()}


func _cmd_train_hits(_a: Array) -> Dictionary:
	var lab := _built()
	var out := []
	for h: Dictionary in lab.hits:
		out.append({"car": h.car, "surface": h.surface, "at": arr(h.at), "ricochet": h.ricochet})
	return {"hits": out}


func _cmd_train_goto(a: Array) -> Dictionary:
	var lab := _built()
	var line: TrackLine = lab.line
	var w: String = a[0] if a.size() > 0 else "mine"
	var at := line.mark_s(w) if line.marks.has(w) else float(w)
	var e := TrainEngineer.new(lab.train.sim, line)
	e.go_to(at, float(a[1]) if a.size() > 1 else 22.0)
	lab.engineer = e
	if lab.engineer_body == null or not is_instance_valid(lab.engineer_body):
		lab._put_engineer_in_cab()
	e.body = lab.engineer_body
	lab.timetable = null
	lab.driver = &"engineer"
	return {"to": at, "kmh": e._plain_kmh}


func _cmd_train_watch(a: Array) -> Dictionary:
	var lab := _built()
	var i := _car_index(lab, a[0] if a.size() > 0 else "box")
	if i < 0:
		return {"ok": false, "error": HELP.train_watch}
	var c: Dictionary = lab.train.sim.cars[i]
	var along := float(a[1]) if a.size() > 1 else float(c.length)
	var side := float(a[2]) if a.size() > 2 else -5.0
	var up := float(a[3]) if a.size() > 3 else 1.6
	var target: Vector3 = lab.car_point(i, along, 1.3)
	var eye: Vector3 = lab.car_point(i, along, up, side)
	if a.size() > 4:
		eye = lab.car_point(i, along + float(a[4]), up, side)
	if "follow" in a:
		var back := float(a[4]) if a.size() > 4 and String(a[4]).is_valid_float() else 0.0
		lab.watch = {"car": i, "eye": Vector3(side, up, along + back), "target": Vector3(0.0, 1.3, along)}
		lab.set_view(&"follow")
		return {"follow": String(c.name)}
	lab.set_view(&"fixed")
	lab.camera.global_position = eye
	lab.camera.look_at(target, Vector3.UP)
	return {"eye": arr(eye), "target": arr(target)}


func _cmd_train_slowmo(a: Array) -> Dictionary:
	Engine.time_scale = clampf(float(a[0]) if a.size() > 0 else 1.0, 0.05, 1.0)
	return {"time_scale": Engine.time_scale}
