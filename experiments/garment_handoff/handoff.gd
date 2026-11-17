extends GloveAct
## The garment handoff's lab (#895 the lab, #917 on the game's part, #949 its clipping): the game's
## GloveAct (src/bodies/glove_act.gd: a long glove worn as part of his skinned mesh, drawn off as real
## cloth, flicked away, lying where it lands) with a chair by him to flick it toward, and the
## measures (`rec`): ticks and cost a phase, the pop, cloth under his skin, stretch, flung, below
## the floor, where it ended.

var chair: Node3D
## Count the cloth under his skin each tick (CPU-skins his arm: ~10 ms here; off for the cost runs).
var measure_skin := true
## Measure at all (off for the cost runs: only the handoff's own work).
var measure := true

## What's measured: ticks a phase, cloth through the arm each tick (from take), the worst point
## speed, the pop at the handoff, the cost a tick by phase (ms, this machine).
var rec := {"ticks": {}, "through": [], "through_max": 0, "through_ticks": 0, "through_total": 0,
		"pop_mm": -1.0, "flung": 0, "below_floor": 0, "lost": 0, "phase_at": {}, "us": {},
		"glove": {}, "rest_at": -1.0, "where": []}


## His glove made and put on (worn); flicked toward the chair's seat if there's one.
func dress(who: HumanBody, on_chair: Node3D) -> Dictionary:
	chair = on_chair
	if chair:
		toss_to = chair.global_position + Vector3.UP * 0.5
	var r := wear_on(who)
	if r.get("glove") is Dictionary:
		rec.glove = r.glove
	return r


func _physics_process(delta: float) -> void:
	if not started or done:
		return
	var t0 := Time.get_ticks_usec()
	super(delta)
	rec.phase_at = phase_at
	rec.rest_at = rest_at
	rec.ticks[phase] = int(rec.ticks.get(phase, 0)) + 1
	if part and part.collider and part.state != GarmentHandoff.State.WORN:
		var c: Dictionary = rec.get_or_add("part_us", {})
		var e: Array = c.get_or_add(phase, [0, 0, 0, 0])
		e[0] += part.tick_us
		e[1] += part.collider.rebuild_us if part.collider.active else 0
		e[2] += part.collider.last_tris if part.collider.active else 0
		e[3] += 1
		if part.ours():
			# Our cloth's own step (ms, summed) and its contacts with itself (the most at once).
			var core = (part.cloth as SolverCloth).core
			var sm: Dictionary = rec.get_or_add("solver_ms", {})
			sm[phase] = float(sm.get(phase, 0.0)) + core.millis()
			if core.has_method("body_vert_pushes"):
				rec.vert_pushes = maxi(int(rec.get("vert_pushes", 0)), core.body_vert_pushes())
				var vl: Dictionary = rec.get_or_add("vert_listed", {})
				vl[phase] = int(vl.get(phase, 0)) + core.body_vert_listed()
				var vu: Dictionary = rec.get_or_add("vert_us", {})
				var u: Vector2 = core.body_vert_us()
				var e2: Array = vu.get_or_add(phase, [0.0, 0.0])
				e2[0] += u.x
				e2[1] += u.y
				var vp: Dictionary = rec.get_or_add("vert_pairs", {})
				vp[phase] = int(vp.get(phase, 0)) + core.body_vert_pairs()
			if core.has_method("self_contacts"):
				rec.self_max = maxi(int(rec.get("self_max", 0)), core.self_contacts())
				var sp: Dictionary = rec.get_or_add("self_pairs", {})
				sp[phase] = int(sp.get(phase, 0)) + core.self_pairs()
				var sl: Dictionary = rec.get_or_add("self_lists", {})
				sl[phase] = int(sl.get(phase, 0)) + core.self_lists()
				if core.has_method("self_lookups"):
					var su: Dictionary = rec.get_or_add("self_us", {})
					var e3: Array = su.get_or_add(phase, [0.0, 0.0, 0, 0])
					e3[0] += core.self_list_us()
					e3[1] += core.self_meet_us()
					e3[2] += core.self_lookups()
					e3[3] += core.self_met()
	var us := Time.get_ticks_usec() - t0
	rec.us[phase] = float(rec.us.get(phase, 0.0)) + us


func _finish() -> void:
	if cloth:
		rec.where = _where()
		rec.last_fastest = snappedf(cloth.last_mean_speed, 0.001)
	super()


## Each tick the cloth is out: how far the points moved on the first ticks (the pop), points
## through the arm, flung, under the floor, lost.
func _measure() -> void:
	if cloth == null or cloth.resting or not measure:
		return
	var pts: PackedVector3Array = cloth.points_now()
	rec.pop_mm = part.pop_mm
	rec.skin_us_max = maxi(int(rec.get("skin_us_max", 0)), part.collider.rebuild_us)
	rec.skin_tris_max = maxi(int(rec.get("skin_tris_max", 0)), part.collider.last_tris)
	rec.fine_points = part.collider.fine_count()
	if part.released_all_at >= 0.0:
		rec.released_all_at = snappedf(part.released_all_at, 0.001)
	var sx: float = cloth.stretch(pts)
	if part.on_arm() > 0:
		# The points still held on him against where his skin carries the worn glove now (mm).
		var drawn: PackedVector3Array = glove.posed()
		var off := 0.0
		for i: int in part._on_arm:
			off = maxf(off, pts[i].distance_to(drawn[i]))
		rec.held_off_mm = maxf(float(rec.get("held_off_mm", 0.0)), snappedf(off * 1000.0, 0.1))
	rec.stretch_max = maxf(float(rec.get("stretch_max", 1.0)), sx)
	if measure_skin:
		# The same count of the glove as worn (skinned with him), this tick: what the measure finds
		# on a glove that can't be through him (his skin's own folds and normals).
		var base: int = glove.under_skin(glove.posed())
		rec.worn_under_max = maxi(int(rec.get("worn_under_max", 0)), base)
	var n: int = glove.under_skin(pts) if measure_skin else 0
	# His hand's skin through the glove (#1008): what the eye sees of his fingers through it.
	if measure_skin and part.collider and part.collider.active:
		if not rec.has("worn_out_max"):
			rec.worn_out_max = glove.skin_out(glove.posed())
		var so: int = glove.skin_out(pts)
		var bo: Dictionary = rec.get_or_add("skin_out_by_phase", {})
		bo[phase] = maxi(int(bo.get(phase, 0)), so)
		if so > int(rec.get("skin_out_max", -1)):
			rec.skin_out_max = so
			rec.skin_out_at = snappedf(t, 0.01)
		rec.skin_out_total = int(rec.get("skin_out_total", 0)) + so
		# His forearm's (Sean's specks at 3.4 s); the count leaves last_out as the hand's below.
		var fo: int = glove.skin_out(pts, 0.001, true)
		rec.arm_out_max = maxi(int(rec.get("arm_out_max", 0)), fo)
		rec.arm_out_total = int(rec.get("arm_out_total", 0)) + fo
		so = glove.skin_out(pts)
		if int(rec.ticks.get(phase, 0)) % 6 == 0:
			var hist := [0, 0, 0, 0]
			for h: float in glove.last_out_h:
				hist[0 if h < 0.003 else (1 if h < 0.006 else (2 if h < 0.01 else 3))] += 1
			(rec.get_or_add("skin_out_series", []) as Array).append([snappedf(t, 0.01), so, hist])

	var deep5 := 0
	var deep10 := 0
	for d: float in glove.last_depths:
		if d > 0.005:
			deep5 += 1
		if d > 0.01:
			deep10 += 1
	rec.under_5mm_max = maxi(int(rec.get("under_5mm_max", 0)), deep5)
	rec.under_10mm_max = maxi(int(rec.get("under_10mm_max", 0)), deep10)
	var bp: Dictionary = rec.get_or_add("by_phase", {})
	var b: Dictionary = bp.get_or_add(phase, {"stretch": 1.0, "through": 0, "on_arm": 0})
	b.stretch = snappedf(maxf(float(b.stretch), sx), 0.001)
	b.through = maxi(int(b.through), n)
	b.on_arm = maxi(int(b.on_arm), part.on_arm())
	rec.through.append(n)
	if n > int(rec.through_max):
		# Where they were, the worst tick: each point's bone and how deep (mm).
		var where := {}
		for k in glove.last_under.size():
			var i: int = glove.last_under[k]
			var key := "%s%s" % [man.skeleton.get_bone_name(glove.main_bone[i]), " (held)" if part.on_arm() > 0 and part._on_arm.has(i) else ""]
			(where.get_or_add(key, []) as Array).append(snappedf(glove.last_depths[k] * 1000.0, 0.1))
		rec.through_worst = {"t": snappedf(t, 0.01), "phase": phase, "where": where}
	rec.through_max = maxi(int(rec.through_max), n)
	rec.through_total = int(rec.through_total) + n
	if n > 0:
		rec.through_ticks = int(rec.through_ticks) + 1
	var floor_y: float = man.global_position.y
	for i in pts.size():
		var p := pts[i]
		if not p.is_finite():
			rec.lost = int(rec.lost) + 1
			continue
		if p.y < floor_y - 0.01:
			rec.below_floor = int(rec.below_floor) + 1
		if _last.size() == pts.size() and p.distance_to(_last[i]) * 60.0 > 20.0:
			rec.flung = int(rec.flung) + 1
			if not rec.has("flung_at"):
				rec.flung_at = [snappedf(t, 0.01), phase, i]
	_last = pts


var _last := PackedVector3Array()


## Where it ended: its middle, lowest and highest point, and whether it's on the chair.
func _where() -> Dictionary:
	var pts: PackedVector3Array = cloth.points_now()
	var c := Vector3.ZERO
	var lo := INF
	var hi := -INF
	for p in pts:
		c += p
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
	c /= pts.size()
	var on_chair := false
	if chair:
		var d := c - chair.global_position
		on_chair = Vector2(d.x, d.z).length() < 0.4 and hi > 0.3
	return {"centre": [snappedf(c.x, 0.001), snappedf(c.y, 0.001), snappedf(c.z, 0.001)],
			"low": snappedf(lo, 0.001), "high": snappedf(hi, 0.001), "on_chair": on_chair}
