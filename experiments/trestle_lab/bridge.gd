extends BridgeLab
## The trestle lab's dev bridge commands (#623; README). `trestle_lab` builds the gorge line, its
## viaduct, the gorge and a train 2.6 km east of town, as the train lab's lab (node "TrainLab"):
## every `train_*` command (cameras, the engineer, passengers, the walk) works on it after.

const LAB := preload("res://experiments/trestle_lab/lab.gd")
const COLLAPSE := preload("res://experiments/trestle_lab/collapse.gd")

const HELP := {
	"trestle_lab": "trestle_lab -> build the gorge line, the viaduct and the train (as the train lab's lab): the viaduct's numbers, nodes, the build's ms",
	"trestle": "trestle -> the viaduct now: members by kind, bents, what's broken, its rubble, the train's loads' cost",
	"trestle_cost": "trestle_cost [S] [train=KMH] -> over S s (default 10): ms a frame, the systems (Prof), nodes, draws; train=KMH: the train crossing at KMH from before the bridge",
	"trestle_collapse": "trestle_collapse bent=mid|N bents=1 story=bottom|K posts=all|inner|outer|left|N how=stick|cut|none sticks=4 at=0.6 train=none|cross when=before|under wait=6 lead=0 kmh=30 run_up=250 riders=0 secs=10 out=PATH -> a charge on a bent's posts (with or without the train): what falls, the train, every frame against #492's gate",
	"trestle_cam": "trestle_cam floor|rim [SIDE]|deck [S]|under -> a camera on the gorge's floor looking up at the middle, on the far rim SIDE m along the gorge (90), on the deck (S along), or under the deck",
	"trestle_matrix": "trestle_matrix [out=PATH] [only=A,B] -> each cut of the matrix on a fresh viaduct (posts cut outright, no train), then the engine standing over it: holds empty? fails under the engine? what fell",
	"trestle_where": "trestle_where BENT [STORY] [post|cap] -> a point on the viaduct (for look/shoot/plant): bent N's story K post foot, or its cap",
}


func _lab() -> Node:
	var lab := main.get_node_or_null(^"TrainLab")
	if lab != null and not lab.has_method(&"trestle"):
		lab.free()  # the train lab's own: this one's on the gorge line
		lab = null
	if lab == null:
		lab = LAB.new()
		lab.name = "TrainLab"
		main.add_child(lab)
	lab.street = street
	lab.player = player
	return lab


func _cmd_trestle_lab(_a: Array) -> Dictionary:
	var lab := _lab()
	var n0 := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var u := Time.get_ticks_usec()
	var line: TrackLine = lab.ensure_built()
	var ms := float(Time.get_ticks_usec() - u) / 1000.0
	await seconds(0.5)
	var tr: Trestle = lab.trestle()
	var rep := tr.report()
	rep["build_ms"] = snappedf(ms, 0.1)
	rep["nodes_added"] = Performance.get_monitor(Performance.OBJECT_NODE_COUNT) - n0
	rep["nodes"] = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	rep["trestle_nodes"] = _count(tr)
	rep["line_length"] = line.length
	rep["marks"] = line.marks
	rep["middle"] = arr(line.to_global(line.point_at(line.mark_s("middle"))))
	return rep


func _count(n: Node) -> int:
	var c := 1
	for k in n.get_children():
		c += _count(k)
	return c


func _cmd_trestle(_a: Array) -> Dictionary:
	var lab := _lab()
	var tr: Trestle = lab.trestle()
	var broken := {}
	for m in tr.get_members():
		if m.broken:
			broken[String(m.kind)] = int(broken.get(String(m.kind), 0)) + 1
	var alive := 0
	for rb in tr.rubble:
		if is_instance_valid(rb):
			alive += 1
	var rep := tr.report()
	rep["broken"] = broken
	rep["rubble"] = alive
	rep["load_cost"] = tr.load_cost
	rep["train"] = {"s": lab.train.sim.s, "kmh": lab.train.sim.v * 3.6, "derail": lab.train.derail}
	return rep


func _cmd_trestle_cost(a: Array) -> Dictionary:
	if "bare" in a:
		return await _cost_bare(float(a[0]) if a.size() > 1 and String(a[0]).is_valid_float() else 10.0)
	var lab := _lab()
	lab.ensure_built()
	var secs := 10.0
	var kmh := -1.0
	for w: String in a:
		if w.begins_with("train="):
			kmh = float(w.trim_prefix("train="))
		elif w.is_valid_float():
			secs = float(w)
	var train: Train = lab.train
	var tr: Trestle = lab.trestle()
	if kmh > 0.0:
		# From far enough back that it's on the bridge for the whole measure.
		train.place(tr.from_s + train.sim.length + 5.0, 0.0)
		train.sim.set_speed(kmh / 3.6)
		lab.driver = &"hold"
		lab.hold_kmh = kmh
	else:
		lab.driver = &""
		train.sim.set_speed(0.0)
	await seconds(0.5)
	tr.load_cost = {"us": 0, "updates": 0, "settles": 0}
	Prof.on = true
	Prof._sum.clear()
	var f0 := Engine.get_process_frames()
	var p0 := Engine.get_physics_frames()
	var u0 := Time.get_ticks_usec()
	await seconds(secs)
	var frames := maxi(1, Engine.get_process_frames() - f0)
	var ticks := maxi(1, Engine.get_physics_frames() - p0)
	var systems := {}
	for k: StringName in Prof._sum:
		var ms := float(Prof._sum[k]) / 1000.0 / frames
		if ms > 0.01 and not String(k).begins_with("q_") and not String(k).begins_with("n_"):
			systems[String(k)] = snappedf(ms, 0.001)
	Prof.on = false
	lab.driver = &""
	return {"secs": secs, "frames": frames, "ticks": ticks,
		"wall_ms_a_frame": snappedf(float(Time.get_ticks_usec() - u0) / frames / 1000.0, 0.01),
		"systems_ms_a_frame": systems,
		"bridge_load_ms_a_tick": snappedf(float(tr.load_cost.us) / ticks / 1000.0, 0.001),
		"load_updates": tr.load_cost.updates, "load_settles": tr.load_cost.settles, "load_set": tr.load_cost.get("set", 0), "load_seeds": tr.load_cost.get("seeds", 0),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"train_kmh": snappedf(train.sim.v * 3.6, 0.1), "train_s": snappedf(train.sim.s, 0.1)}


## The same measure with nothing built (the before).
func _cost_bare(secs: float) -> Dictionary:
	Prof.on = true
	Prof._sum.clear()
	var f0 := Engine.get_process_frames()
	var u0 := Time.get_ticks_usec()
	await seconds(secs)
	var frames := maxi(1, Engine.get_process_frames() - f0)
	var systems := {}
	for k: StringName in Prof._sum:
		var ms := float(Prof._sum[k]) / 1000.0 / frames
		if ms > 0.01 and not String(k).begins_with("q_") and not String(k).begins_with("n_"):
			systems[String(k)] = snappedf(ms, 0.001)
	Prof.on = false
	return {"secs": secs, "frames": frames, "wall_ms_a_frame": snappedf(float(Time.get_ticks_usec() - u0) / frames / 1000.0, 0.01),
		"systems_ms_a_frame": systems, "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}


func _cmd_trestle_collapse(a: Array) -> Dictionary:
	var lab := _lab()
	lab.ensure_built()
	var c: Node = lab.get_node_or_null(^"Collapse")
	if c == null:
		c = COLLAPSE.new()
		c.name = "Collapse"
		c.lab = lab
		lab.add_child(c)
	var spec: Dictionary = c.parse(a)
	var out: Dictionary = await c.run(spec)
	if String(spec.out) != "":
		DirAccess.make_dir_recursive_absolute(String(spec.out).get_base_dir())
		var f := FileAccess.open(String(spec.out), FileAccess.WRITE)
		f.store_string(JSON.stringify(out, "  "))
	return {"outcome": out.outcome, "fired": out.fired, "after": out.after, "empty": out.get("empty", {}),
		"wreck": out.get("wreck", {}), "frames": out.frames, "frames_fall": out.get("frames_fall", {}), "rubble": out.rubble}


## The cuts the matrix tries: name -> collapse.gd's spec keys (how=cut).
const MATRIX := {
	"A_one_bent_bottom": {"bents": 1, "story": "bottom", "posts": "all"},
	"B_one_bent_top": {"bents": 1, "story": "0", "posts": "all"},
	"C_two_bents_bottom": {"bents": 2, "story": "bottom", "posts": "all"},
	"D_bottom_inner": {"bents": 1, "story": "bottom", "posts": "inner"},
	"E_bottom_left_half": {"bents": 1, "story": "bottom", "posts": "left"},
	"F_bottom_outer": {"bents": 1, "story": "bottom", "posts": "outer"},
	"G_top_inner": {"bents": 1, "story": "0", "posts": "inner"},
	"H_two_bents_top": {"bents": 2, "story": "0", "posts": "all"},
}


func _settled(tr: Trestle) -> void:
	var fire := FireSystem.find(tr.get_tree())
	for k in 600:
		await tr.get_tree().physics_frame
		if (fire == null or not fire.settling(tr)) and tr._analysis_valid and (tr.last_analysis == null or tr.last_analysis.left() == 0):
			break
	await seconds(0.5)


func _cmd_trestle_matrix(a: Array) -> Dictionary:
	var out_path := ""
	var only := []
	for w: String in a:
		if w.begins_with("out="):
			out_path = w.trim_prefix("out=")
		elif w.begins_with("only="):
			only = Array(w.trim_prefix("only=").split(","))
	var lab := _lab()
	var results := {}
	for name: String in MATRIX:
		if not only.is_empty() and not name.substr(0, 1) in only:
			continue
		if lab.line and is_instance_valid(lab.line):
			lab.line.free()
		lab.line = null
		lab.ensure_built()
		var tr: Trestle = lab.trestle()
		var train: Train = lab.train
		train.sim.set_speed(0.0)
		lab.driver = &""
		await _settled(tr)
		var spec: Dictionary = COLLAPSE.parse(["how=cut"])
		for k in MATRIX[name]:
			spec[k] = MATRIX[name][k]
		var c: Node = COLLAPSE.new()
		var bents: Array = c.pick_bents(tr, spec)
		var fired: Dictionary = await c.fire(tr, spec)
		await _settled(tr)
		var empty: Dictionary = c._state(tr, 0)
		# The engine standing over the (first) cut bent, then a car length either side.
		var under := []
		var c0: Dictionary = train.sim.cars[0]
		var mid_e := (float(c0.trucks.x) + float(c0.trucks.y)) * 0.5
		for off in [-6.0, -3.0, 0.0, 3.0, 6.0]:
			if not train.derail.is_empty():
				break
			train.place(float(bents[0].s) + float(off) + mid_e, 0.0)
			for k in tr.tt.load_every * 2:
				await tr.get_tree().physics_frame
			await _settled(tr)
			var st: Dictionary = c._state(tr, 0)
			var worst := 0.0
			if tr.last_analysis:
				for d: Dictionary in tr.stringers:
					worst = maxf(worst, float(tr.last_analysis.utilisation.get((d.member as StructureMember).member_id, 0.0)))
			st["engine_at"] = off
			st["stringers_worst"] = snappedf(worst, 0.01)
			under.append(st)
		var holds_empty: bool = int(empty.rails_gone) == 0 and int(empty.deck_damage) == 0
		var last: Dictionary = under.back() if not under.is_empty() else {}
		var fails: bool = not train.derail.is_empty() or int(last.get("rails_gone", 0)) > 0 or int(last.get("deck_damage", 0)) > 0
		results[name] = {"cut": fired, "empty": empty, "holds_empty": holds_empty, "under_engine": under,
			"fails_under_engine": fails if holds_empty else null, "bent_heights": bents.map(func(b: Dictionary) -> float: return snappedf(float(b.height), 0.1))}
		c.free()
	if out_path != "":
		DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(results, "  "))
	var brief := {}
	for k in results:
		brief[k] = {"holds_empty": results[k].holds_empty, "fails_under_engine": results[k].fails_under_engine,
			"empty_broken": results[k].empty.broken, "stringers_worst": (results[k].under_engine as Array).map(func(u: Dictionary) -> float: return u.stringers_worst)}
	return brief


func _cmd_trestle_where(a: Array) -> Dictionary:
	var lab := _lab()
	var tr: Trestle = lab.trestle()
	var i := clampi(int(a[0]) - 1 if a.size() > 0 else tr.bents.size() / 2, 0, tr.bents.size() - 1)
	var b: Dictionary = tr.bents[i]
	var stories: Array = b.stories
	var k := clampi(int(a[1]) if a.size() > 1 else stories.size() - 1, 0, maxi(0, stories.size() - 1))
	if a.size() > 2 and a[2] == "cap" or stories.is_empty():
		return {"bent": i + 1, "at": arr((b.cap as StructureMember).global_position)}
	var p: StructureMember = stories[k].posts[0]
	return {"bent": i + 1, "story": k, "height": b.height, "foot": arr(p.global_transform * Vector3(0, 0, -p.size.z * 0.5)), "post": String(p.member_id)}


func _cmd_trestle_cam(a: Array) -> Dictionary:
	var lab := _lab()
	var line: TrackLine = lab.ensure_built()
	var tr: Trestle = lab.trestle()
	var where: String = a[0] if a.size() > 0 else "floor"
	var mid := (tr.from_s + tr.to_s) * 0.5
	var f := line.global_transform * line.transform_at(mid)
	var g = line.get_meta(&"gorge")
	var deck := f.origin
	var eye := deck
	var look := deck
	match where:
		"floor":
			# On the gorge floor (the river's bank) 35 m downstream, looking up at the deck's middle.
			eye = deck + f.basis.x * 35.0 + (-f.basis.z) * 12.0
			eye.y = line.global_position.y - float(g.depth) + 1.7
			look = deck + Vector3.DOWN * 8.0
		"rim":
			# On the far rim (past the crossing's end, on the flat), 260 m along the gorge, looking
			# back across at the whole span.
			var half := (tr.to_s - tr.from_s) * 0.5
			var side := float(a[1]) if a.size() > 1 else 90.0
			eye = deck + f.basis.x * side + (-f.basis.z) * (half + 6.0)
			eye.y = line.global_position.y + 6.0  # (on a rock at the edge, looking down across)
			look = deck + Vector3.DOWN * 10.0
		"deck":
			var s := float(a[1]) if a.size() > 1 else tr.from_s + 20.0
			var fs := line.global_transform * line.transform_at(s)
			eye = fs.origin + Vector3.UP * 1.7 + fs.basis.x * 0.6
			look = fs * Vector3(0.0, 1.0, -40.0)
		"under":
			eye = deck + Vector3.DOWN * 8.0 + f.basis.x * 14.0 + f.basis.z * 30.0
			look = deck + Vector3.DOWN * 30.0
	lab.set_view(&"fixed")
	lab.camera.global_position = eye
	lab.camera.look_at(look, Vector3.UP)
	lab.camera.far = 2000.0
	return {"view": where, "eye": arr(eye), "look": arr(look)}
