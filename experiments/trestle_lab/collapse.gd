extends Node
## The trestle lab's collapse runs (#623): a charge on a bent's posts (or the posts cut outright),
## with or without the train coming on, and what happens: what falls by the support graph, whether
## the deck holds empty, whether the engine's weight finishes it, whether the train goes over, and
## what every drawn frame cost from the charge on against #492's gate (one hitch under ~100 ms at
## Sean's, back over 50 fps within half a second; here x0.65 for his clock, as step 5's derail runs).
##
## `run(spec)` (bridge `trestle_collapse k=v ...`), spec:
##   bent    which bent (its index along the bridge, 1..), or "mid" (the tallest)        mid
##   bents   how many side by side from it (1: one, 2: it and the next)                  1
##   story   which story, from the top (0) or "bottom"                                    bottom
##   posts   all | inner | outer | left | N (the N leftmost)                              all
##   how     stick (charges planted on the posts) | cut (the posts cut outright) | none   stick
##   sticks  sticks of dynamite at each post (a bundle; BlastTuning.tnt_per_stick each)   2
##   at      where up the post the charge sits, m above its foot                          0.6
##   train   none | cross (the train comes on)                                            none
##   when    before (the charge, `wait` s, then the train) | under (the charge as the engine's front
##           comes `lead` m short of the bent)                                            before
##   wait    s between the charge and the train coming on (when=before)                   6
##   lead    m (when=under)                                                               0
##   kmh     the train's speed (held; nobody watches: it's the trap)                     30
##   run_up  m back from the bridge's start it starts                                     250
##   riders  passengers in the coach                                                      0
##   secs    s watched after the charge (and after the train's off the rails)            10
##   out     the summary's file (JSON)
##   fresh   1: on a viaduct built afresh (0: as it stands)                              1
##   board   you on this car's front platform as it comes on (-1: not; 6 the coach)       -1
##   stagger physics ticks between one charge and the next (0: all on one tick). The game sets
##           no two off on one tick (each planted stick is lit as it's let go); a tick is the
##           least two hand-lit fuses could differ                                       1

var lab: Node
var frames: PackedFloat64Array = []  # each drawn frame's wall time (ms)
var frame_t: PackedFloat64Array = []  # its time since the run began (s)
var _last_us := 0
var _on := false
var _t0_us := 0
## The frames over 40 ms: {t, ms, top (their biggest systems), rubble, awake}.
var slow: Array = []
var _tr: Trestle


func _alive() -> int:
	if _tr == null or not is_instance_valid(_tr):
		return 0
	var n := 0
	for rb in _tr.rubble:
		if is_instance_valid(rb):
			n += 1
	return n


func RubbleSleep_awake() -> int:
	if _tr == null or not is_instance_valid(_tr):
		return 0
	var n := 0
	for rb in _tr.rubble:
		if is_instance_valid(rb) and not rb.sleeping and not rb.freeze:
			n += 1
	return n


func _process(_delta: float) -> void:
	if not _on:
		return
	var now := Time.get_ticks_usec()
	Prof.frame(1 << 30, 1e9)  # (this frame's systems, for the slow ones; never rolled)
	if _last_us > 0:
		var ms := float(now - _last_us) / 1000.0
		frames.append(ms)
		frame_t.append(float(now - _t0_us) / 1e6)
		if ms > 40.0:
			var top := {}
			for i in Prof.TOP:
				if Prof.frame_top_names[i] != &"":
					top[String(Prof.frame_top_names[i])] = snappedf(Prof.frame_top_ms[i], 0.1)
			slow.append({"t": snappedf(float(now - _t0_us) / 1e6, 0.01), "ms": snappedf(ms, 0.1), "top": top,
				"physics_ms": snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.1),
				"process_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.1),
				"rubble": _alive(), "awake": RubbleSleep_awake()})
	_last_us = now


func _now() -> float:
	return float(Time.get_ticks_usec() - _t0_us) / 1e6


static func parse(a: Array) -> Dictionary:
	var spec := {"bent": "mid", "bents": 1, "story": "bottom", "posts": "all", "how": "stick", "sticks": 2, "at": 0.6,
		"train": "none", "when": "before", "wait": 6.0, "lead": 0.0, "kmh": 30.0, "run_up": 250.0, "riders": 0,
		"secs": 10.0, "out": "", "fresh": 1, "stagger": 1, "board": -1}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() != 2:
			continue
		var v: Variant = kv[1]
		if spec.has(kv[0]) and (spec[kv[0]] is float or spec[kv[0]] is int):
			v = float(kv[1]) if spec[kv[0]] is float else int(kv[1])
		spec[kv[0]] = v
	return spec


## The bents (their dictionaries) a spec names.
static func pick_bents(tr: Trestle, spec: Dictionary) -> Array:
	var i0 := 0
	if str(spec.bent) == "mid":
		var tallest := -1.0
		for i in tr.bents.size():
			if float(tr.bents[i].height) > tallest:
				tallest = float(tr.bents[i].height)
				i0 = i
	else:
		i0 = clampi(int(spec.bent) - 1, 0, tr.bents.size() - 1)
	var out := []
	for k in maxi(1, int(spec.bents)):
		if i0 + k < tr.bents.size():
			out.append(tr.bents[i0 + k])
	return out


## The posts a spec names in a bent.
static func pick_posts(bent: Dictionary, spec: Dictionary) -> Array[StructureMember]:
	var stories: Array = bent.stories
	var out: Array[StructureMember] = []
	if stories.is_empty():
		return out
	var k := stories.size() - 1 if str(spec.story) == "bottom" else clampi(int(spec.story), 0, stories.size() - 1)
	var posts: Array = stories[k].posts
	var n := posts.size()
	var w := str(spec.posts)
	for i in n:
		var keep := false
		match w:
			"all":
				keep = true
			"outer":
				keep = i == 0 or i == n - 1
			"inner":
				keep = i == n / 2 - 1 or i == n / 2
			"left":
				keep = i < n / 2
			_:
				keep = i < int(w)
		if keep:
			out.append(posts[i])
	return out


## Set the charges off (or cut the posts), `stagger` ticks apart. Returns what was done.
func fire(tr: Trestle, spec: Dictionary) -> Dictionary:
	var posts: Array[StructureMember] = []
	for b: Dictionary in pick_bents(tr, spec):
		posts.append_array(pick_posts(b, spec))
	var how := str(spec.how)
	var stick := Blast.t().tnt_per_stick
	var kg := stick * float(spec.sticks)
	var world := tr.get_parent() as Node3D
	var u := Time.get_ticks_usec()
	if how == "cut":
		var pushes: Array[Vector3] = []
		for p in posts:
			pushes.append(Vector3.ZERO)
		tr.break_members(posts, pushes)
	elif how == "stick":
		var spots: Array[Vector3] = []
		for p in posts:
			var foot := p.global_transform * Vector3(0.0, 0.0, -p.size.z * 0.5)
			var up := (p.global_transform.basis.z).normalized()
			# On the post's face toward the line's start (where a man planting it would stand).
			var face := p.global_transform.basis.y.normalized() * (p.size.y * 0.5 + 0.05)
			spots.append(foot + up * float(spec.at) + face)
		var worst := 0.0
		for i in spots.size():
			var u1 := Time.get_ticks_usec()
			Blast.detonate(world, spots[i], kg)
			worst = maxf(worst, float(Time.get_ticks_usec() - u1) / 1000.0)
			if int(spec.stagger) > 0 and i < spots.size() - 1:
				for k in int(spec.stagger):
					await tr.get_tree().physics_frame
		return {"posts": posts.size(), "kg_each": kg, "how": how, "ms": float(Time.get_ticks_usec() - u) / 1000.0,
			"worst_one_ms": snappedf(worst, 0.1), "stagger_ticks": int(spec.stagger)}
	return {"posts": posts.size(), "kg_each": 0.0, "how": how, "ms": float(Time.get_ticks_usec() - u) / 1000.0}


func run(spec: Dictionary) -> Dictionary:
	if int(spec.fresh) == 1 and lab.line and is_instance_valid(lab.line):
		lab.line.free()
		lab.line = null
		lab.driver = &""
	var line: TrackLine = lab.ensure_built()
	await settled(lab.trestle())
	var tr: Trestle = lab.trestle()
	var train: Train = lab.train
	var tree := lab.get_tree()
	var clock := tree.root.find_child("DayCycle", true, false) as DayCycle
	if clock:
		clock.set_time(17.5)
		clock.set_time_scale(0.0)
	Prof.on = true
	Prof._sum.clear()
	var bents := pick_bents(tr, spec)
	var bent_s := float(bents[0].s) if not bents.is_empty() else (tr.from_s + tr.to_s) * 0.5
	var crossing := str(spec.train) == "cross"
	if crossing:
		train.place(maxf(tr.from_s - float(spec.run_up), train.sim.length + 5.0), 0.0)
		train.sim.set_speed(float(spec.kmh) / 3.6)
		if int(spec.riders) > 0:
			lab.seat_passengers(int(spec.riders))
		if int(spec.board) >= 0:
			await tree.physics_frame
			lab.board(int(spec.board), "front")
			lab.set_view(&"player")
	lab.driver = &"hold" if crossing else &""
	lab.hold_kmh = float(spec.kmh)
	if not crossing:
		train.sim.set_speed(0.0)
	frames.clear()
	frame_t.clear()
	slow.clear()
	_tr = tr
	_last_us = 0
	_t0_us = Time.get_ticks_usec()
	_on = true
	var fired := {}
	var t_fire := -1.0
	var broken_before := _broken(tr)
	var hold_until := -1.0
	if str(spec.when) == "before" or not crossing:
		# The charge first; the train held back while it settles (it's coming on at `wait`).
		if crossing:
			lab.driver = &""
			train.sim.throttle = 0.0
			train.sim.brake_lever = 1.0
		await tree.physics_frame
		t_fire = _now()
		fired = await fire(tr, spec)
		hold_until = t_fire + float(spec.wait)
	var t_off := -1.0
	var empty_report := {}
	while true:
		await tree.physics_frame
		var now := _now()
		if crossing and hold_until > 0.0 and now >= hold_until and lab.driver != &"hold":
			empty_report = _state(tr, broken_before)
			lab.driver = &"hold"
			train.sim.brake_lever = 0.0
		if t_fire < 0.0 and train.sim.s >= bent_s - float(spec.lead):
			t_fire = now
			fired = await fire(tr, spec)
		if t_off < 0.0 and not train.derail.is_empty():
			t_off = now
		var last := maxf(t_fire, t_off)
		if not crossing and t_fire >= 0.0 and now - t_fire > float(spec.secs):
			break
		if crossing and t_off >= 0.0 and now - t_off > float(spec.secs):
			break
		if crossing and t_off < 0.0 and train.sim.s > tr.to_s + train.sim.length + 20.0 and now - last > 2.0:
			break  # it crossed
		if now > 240.0:
			break
	_on = false
	return summary(spec, tr, train, t_fire, t_off, fired, broken_before, empty_report)


## Till its first look (or a settle) is done.
func settled(tr: Trestle) -> void:
	var fire := FireSystem.find(tr.get_tree())
	for k in 900:
		await tr.get_tree().physics_frame
		if (fire == null or not fire.settling(tr)) and tr._analysis_valid and (tr.last_analysis == null or tr.last_analysis.left() == 0):
			break
	for k in 30:
		await tr.get_tree().physics_frame


func _broken(tr: Trestle) -> int:
	var n := 0
	for m in tr.get_members():
		if m.broken:
			n += 1
	return n


## What's broken and standing now.
func _state(tr: Trestle, before: int) -> Dictionary:
	var by_kind := {}
	for m in tr.get_members():
		if m.broken:
			by_kind[String(m.kind)] = int(by_kind.get(String(m.kind), 0)) + 1
	var caps := 0
	for b in tr.bents:
		if (b.cap as StructureMember).broken:
			caps += 1
	var rails := 0
	for r: Dictionary in tr.rails:
		if (r.member as StructureMember).broken:
			rails += 1
	return {"broken": _broken(tr) - before, "by_kind": by_kind, "bents_down": caps, "rails_gone": rails,
		"deck_damage": tr.line.state.damage().filter(func(d: Dictionary) -> bool: return float(d.from_s) >= tr.from_s and float(d.to_s) <= tr.to_s).size()}


func summary(spec: Dictionary, tr: Trestle, train: Train, t_fire: float, t_off: float, fired: Dictionary, before: int, empty: Dictionary) -> Dictionary:
	var out := {"spec": spec, "fired": fired, "t_fire": t_fire, "t_off": t_off, "derail": train.derail.duplicate()}
	out["after"] = _state(tr, before)
	if not empty.is_empty():
		out["empty"] = empty
	out["outcome"] = "fell" if not train.derail.is_empty() else ("crossed" if str(spec.train) == "cross" else "no train")
	var rubble := 0
	var awake := 0
	for rb in tr.rubble:
		if is_instance_valid(rb):
			rubble += 1
			if not rb.sleeping and not rb.freeze:
				awake += 1
	out["rubble"] = {"pieces": rubble, "awake_at_end": awake}
	if train.wreck:
		var fell := 0
		var deck_y := tr.line.point_at((tr.from_s + tr.to_s) * 0.5).y
		var fastest := 0.0
		for bi in train.wreck.bodies.size():
			var rb := train.wreck.body(bi)
			if rb == null:
				continue
			var local := tr.line.global_transform.affine_inverse() * rb.global_position
			if local.y < deck_y - 10.0:
				fell += 1
			fastest = maxf(fastest, rb.linear_velocity.length())
		var where := []
		for bi in train.wreck.bodies.size():
			var rb := train.wreck.body(bi)
			if rb == null:
				continue
			var l := tr.line.global_transform.affine_inverse() * rb.global_position
			var ss := tr.line.curve.get_closest_offset(l)
			where.append("%s/%s s%.1f dy%.1f v%.1f%s" % [train.wreck.bodies[bi].car, train.wreck.bodies[bi].part, ss, l.y - tr.line.point_at(ss).y, rb.linear_velocity.length(), " F" if rb.freeze else ""])
		var gaps := []
		for st: Dictionary in tr.line.state.damage():
			if float(st.from_s) >= tr.from_s and float(st.to_s) <= tr.to_s:
				gaps.append("%s %.1f-%.1f" % [st.kind, float(st.from_s), float(st.to_s)])
		out["wreck"] = {"bodies": train.wreck.bodies.size(), "fell_into_gorge": fell, "events": train.wreck.events.duplicate(), "where": where, "gaps": gaps,
			"bents_s": pick_bents(tr, spec).map(func(b: Dictionary) -> float: return snappedf(float(b.s), 0.1))}
	out["load_cost"] = tr.load_cost.duplicate()
	var from := t_fire if t_fire >= 0.0 else 0.0
	out["frames"] = frame_report(from)
	var t2 := t_off if t_off >= 0.0 else -1.0
	if t2 >= 0.0:
		out["frames_fall"] = frame_report(t2)
	out["prof_ms_a_frame"] = _prof(frames.size())
	out["slow_frames"] = slow.duplicate()
	return out


func _prof(n: int) -> Dictionary:
	var out := {}
	for k: StringName in Prof._sum:
		var ms := float(Prof._sum[k]) / 1000.0 / maxf(n, 1)
		if ms > 0.05 and not String(k).begins_with("q_") and not String(k).begins_with("n_"):
			out[String(k)] = snappedf(ms, 0.01)
	return out


## The frames from `from_t` on: the worst, the second worst, how many over 50 and 100 ms, the
## longest slow spell (frames under 50 fps at Sean's, gaps under 0.1 s joined), the gate.
func frame_report(from_t: float) -> Dictionary:
	var worst := 0.0
	var second := 0.0
	var over50 := 0
	var over100 := 0
	var spell := 0.0
	var spell_from := -1.0
	var spell_to := -1.0
	var last_slow := -1.0
	var n := 0
	var sum := 0.0
	var before := 0.0
	var nb := 0
	var worst_t := 0.0
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
			worst_t = t - from_t
		elif ms > second:
			second = ms
		if ms > 50.0:
			over50 += 1
		if ms > 100.0:
			over100 += 1
		if ms * 0.65 > 20.0:
			last_slow = t - from_t
			if spell_to < 0.0 or t - spell_to > 0.1:
				spell_from = t - ms / 1000.0
			spell_to = t
			spell = maxf(spell, spell_to - spell_from)
	var k := 0.65
	return {"frames": n, "mean_ms": snappedf(sum / maxf(n, 1), 0.01), "before_mean_ms": snappedf(before / maxf(nb, 1), 0.01),
		"worst_ms": snappedf(worst, 0.1), "worst_at_s": snappedf(worst_t, 0.01), "second_ms": snappedf(second, 0.1),
		"over_50": over50, "over_100": over100, "last_under_50fps_s": snappedf(last_slow, 0.01),
		"sean_worst_ms": snappedf(worst * k, 0.1), "slow_spell_s": snappedf(spell, 0.01),
		"gate": "pass" if worst * k < 100.0 and spell < 0.5 else "fail"}
