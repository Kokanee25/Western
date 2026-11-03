extends Node
## The train lab's derail runs (train step 5, #616), breakage-lab style: one break on the line, the
## train coming on at a speed, by day or night, and what happens: does the engineer see it in time
## and stop short, or does it leave the rails, and where; what the derail costs the frames it
## happens on and the seconds after (against #492's gate: one hitch under ~100 ms at Sean's, back
## over 50 fps within half a second).
##
## `run(spec)` (bridge `train_derail k=v ...`), spec:
##   kmh     the speed it's coming on at (held till he sees it)       20
##   at      where the break is, m along the line                      380
##   how     rail (the left rail torn out) | stick (three sticks on the ties) | bent (a rail bowed 12 cm)
##           | crate (a heavy crate on the line) | wagon (a 2 t block)  rail
##   hour    the clock (12 noon, 23 night)                             12
##   driver  engineer (he watches and brakes) | none (nobody looks)    engineer
##   run_up  how far back it starts, m                                 300
##   riders  passengers in the coach                                   6
##   secs    how long it's watched after it stops or derails, s       8
##   seed    the engineer's reaction's dice                            616
##   out     write the summary here (JSON)

var lab: Node
var frames: PackedFloat64Array = []  # each drawn frame's wall time (ms)
var frame_t: PackedFloat64Array = []  # its sim time (s)
var _last_us := 0
var _on := false


func _process(_delta: float) -> void:
	if not _on:
		return
	var now := Time.get_ticks_usec()
	if _last_us > 0:
		frames.append(float(now - _last_us) / 1000.0)
		frame_t.append(_now())
	_last_us = now


## The train's clock, running on in the wreck's once it's off the rails (the 1D train stops there).
func _now() -> float:
	var t: Train = lab.train
	if t == null or not is_instance_valid(t):
		return 0.0
	return float(t.derail.t) + t.wreck.time if t.wreck else t.sim.time


static func parse(a: Array) -> Dictionary:
	var spec := {"kmh": 20.0, "at": 380.0, "how": "rail", "hour": 12.0, "driver": "engineer", "run_up": 300.0,
		"riders": 6, "secs": 8.0, "seed": 616, "out": ""}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() != 2:
			continue
		var v: Variant = kv[1]
		if spec.has(kv[0]) and (spec[kv[0]] is float or spec[kv[0]] is int):
			v = float(kv[1]) if spec[kv[0]] is float else int(kv[1])
		spec[kv[0]] = v
	return spec


func make_break(line: TrackLine, at: float, how: String) -> void:
	var c := line.chunk_at(at)
	var f := line.global_transform * line.transform_at(at)
	match how:
		"rail":
			c.tear_loose(c.rail_at(-1, at + 0.5), f.basis.x * -2.0 + Vector3.UP)
		"bent":
			c.bend(c.rail_at(-1, at + 0.5), 0.12)
		"stick":
			for k in 3:
				Blast.detonate(lab.street, f.origin + f.basis.x * -0.3 + f.basis.y * -0.06 + f.basis.z * (0.6 * (k - 1)), 0.2)
				await lab.get_tree().physics_frame
		"crate":
			lab.place_crate(at, 0.0)
		"wagon":
			var rb := RigidBody3D.new()
			rb.name = "Block"
			rb.mass = 2000.0
			var cs := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(1.8, 1.2, 3.0)
			cs.shape = box
			rb.add_child(cs)
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = box.size
			mi.mesh = bm
			rb.add_child(mi)
			lab.street.add_child(rb)
			rb.global_transform = Transform3D(f.basis, f.origin + f.basis.y * 0.7)
			lab.placed.append(rb)


func run(spec: Dictionary) -> Dictionary:
	var line: TrackLine = lab.ensure_built()
	var train: Train = lab.train
	var clock := lab.get_tree().root.find_child("DayCycle", true, false) as DayCycle
	if clock:
		clock.set_time(float(spec.hour))
		clock.set_time_scale(0.0)
	var at := float(spec.at)
	await make_break(line, at, String(spec.how))
	await lab.get_tree().physics_frame
	var s0 := maxf(at - float(spec.run_up), train.sim.length + 5.0)
	train.place(s0, 0.0)
	train.sim.set_speed(float(spec.kmh) / 3.6)
	train.lookout.reset(int(spec.seed))
	if int(spec.riders) > 0:
		lab.seat_passengers(int(spec.riders))
	if String(spec.driver) == "engineer":
		lab.engineer = TrainEngineer.new(train.sim, line)
		lab.engineer.go_to(line.length - 3.0, float(spec.kmh))
		lab._put_engineer_in_cab()
		lab.engineer.body = lab.engineer_body
		lab.engineer.lookout = train.lookout
		lab.driver = &"engineer"
	else:
		lab.driver = &"hold"
		lab.hold_kmh = float(spec.kmh)
	frames.clear()
	frame_t.clear()
	_last_us = 0
	_on = true
	var t0 := train.sim.time
	var tree := lab.get_tree()
	# Till it's off the rails, or stopped after he's seen it, or well past the break.
	while true:
		await tree.physics_frame
		if not train.derail.is_empty():
			break
		if train.lookout.alarmed() and absf(train.sim.v) < 0.02:
			break
		if train.sim.s > at + 120.0 or train.sim.time - t0 > 240.0:
			break
	var end_t := train.sim.time
	for k in int(float(spec.secs) * Engine.physics_ticks_per_second):
		await tree.physics_frame
	_on = false
	return summary(spec, line, train, end_t)


func summary(spec: Dictionary, line: TrackLine, train: Train, end_t: float) -> Dictionary:
	var at := float(spec.at)
	var out := {"spec": spec, "seen": train.lookout.log.duplicate(), "derail": train.derail.duplicate()}
	out["outcome"] = "derailed" if not train.derail.is_empty() else ("stopped" if train.lookout.alarmed() else "ran on")
	if train.derail.is_empty():
		out["stopped_at"] = train.sim.s
		out["short_by"] = at - train.sim.s
	if train.wreck:
		var off := 0.0
		var far := 0.0
		var tipped := 0
		for b: Dictionary in train.wreck.bodies:
			var rb := b.body as RigidBody3D
			if not is_instance_valid(rb):
				continue
			var local := line.global_transform.affine_inverse() * rb.global_position
			var s := line.curve.get_closest_offset(local)
			off = maxf(off, local.distance_to(line.point_at(s)))
			far = maxf(far, s - at)
			if rad_to_deg(rb.global_basis.y.angle_to(Vector3.UP)) > 30.0:
				tipped += 1
		var e0 := train.wreck.bodies[0].body as RigidBody3D
		var el := line.global_transform.affine_inverse() * e0.global_position
		var es := line.curve.get_closest_offset(el)
		var c0: Dictionary = train.sim.cars[0]
		out["engine"] = {"front_past_break_m": es + (c0.trucks.x + c0.trucks.y) * 0.5 - at, "off_m": el.distance_to(line.point_at(es)),
			"tilt_deg": rad_to_deg(e0.global_basis.y.angle_to(Vector3.UP))}
		out["wreck"] = {"bodies": train.wreck.bodies.size(), "most_off_m": off, "furthest_past_m": far, "tipped": tipped,
			"events": train.wreck.events.duplicate(), "asleep": _asleep(train.wreck)}
	var thrown := 0
	if train.wreck:
		for e: Dictionary in train.wreck.events:
			if e.what == "thrown":
				thrown += 1
	out["thrown"] = thrown
	out["frames"] = frame_report(float(train.derail.get("t", end_t)))
	return out


func _asleep(w: TrainWreck) -> int:
	var n := 0
	for b: Dictionary in w.bodies:
		var rb := b.body as RigidBody3D
		if is_instance_valid(rb) and (rb.sleeping or rb.freeze):
			n += 1
	return n


## The frames from the derail (or the stop) on: the worst, the second worst, how many over 50 ms
## and 100 ms, and when after it they were last slower than 50 fps at Sean's (here x0.65 over 20 ms).
func frame_report(from_t: float) -> Dictionary:
	var worst := 0.0
	var second := 0.0
	var over50 := 0
	var over100 := 0
	var last_slow := -1.0
	var n := 0
	var sum := 0.0
	var before := 0.0
	var nb := 0
	for i in frames.size():
		var ms := frames[i]
		var t := frame_t[i]
		if t < from_t - 0.05:
			before += ms
			nb += 1
			continue
		n += 1
		sum += ms
		if ms > worst:
			second = worst
			worst = ms
		elif ms > second:
			second = ms
		if ms > 50.0:
			over50 += 1
		if ms > 100.0:
			over100 += 1
		if ms * 0.65 > 20.0:  # under 50 fps at Sean's
			last_slow = t - from_t
	var k := 0.65
	return {"frames": n, "mean_ms": sum / maxf(n, 1), "before_mean_ms": before / maxf(nb, 1), "worst_ms": worst, "second_ms": second,
		"over_50": over50, "over_100": over100, "last_under_50fps_s": last_slow,
		"sean_worst_ms": worst * k,
		"gate": "pass" if worst * k < 100.0 and last_slow < 0.5 else "fail"}
