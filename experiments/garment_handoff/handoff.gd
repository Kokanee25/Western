extends Node3D
## The garment handoff's choreography (#895 the lab, #917 on the game's part): a long glove worn as
## part of his skinned mesh, drawn off down his fingers and forearm by his other hand as real cloth,
## tossed, and left lying where it lands. The glove, the cloth, the release rule and his skin's
## shape are the game's GarmentHandoff (src/bodies/); this is only where his hands go and when, and
## the measures (`rec`).
##
## Phases (s from `begin`): present (his left hand out in front, palm down, fingers open), reach
## (his right hand to its fingertips), take (the worn glove becomes cloth, its fingertips pinned to
## his right hand where they are), draw (the right hand draws it off along the left hand's line,
## two tugs, the left arm drawing back), toss (a swing toward the chair, let go), lie (it falls
## and drapes; at rest its soft body is taken out).


## The handoff's timing and reach (s, m).
var tune := {
	"present": 0.9, "reach_at": 1.0, "reach": 0.9, "take_at": 2.1, "draw_at": 2.25, "draw": 2.6,
	"draw_len": 0.62, "left_back": 0.12, "tug": 0.035, "toss_swing": 0.38, "toss_flight": 0.45,
	"seat": 0.5, "end_after_rest": 1.0, "max_seconds": 12.0, "bare_rest_after": 4.5,
}
var man: HumanBody
var chair: Node3D
var part: GarmentHandoff
var glove: WornGarment
var cloth: GarmentCloth
var phase := "worn"
var t := 0.0
var started := false
var done := false
## Without the glove (the cost runs' baseline): the same hands, nothing on them.
var with_glove := true
## The glove's triangles (simplified to about).
var tris := 700
## Over the part's own tune (the bench's flags).
var part_tune := {}
## Count the cloth under his skin each tick (CPU-skins his arm: ~10 ms here; off for the cost runs).
var measure_skin := true
## Measure at all (off for the cost runs: only the handoff's own work).
var measure := true
## (Debug: present and reach only, the glove left worn.)
var no_take := false

# Where things go (set at present/take).
var _l_at := Vector3.ZERO
var _l_n := Vector3.UP
var _r_from := Vector3.ZERO
var _r_take := Vector3.ZERO
var _draw_dir := Vector3.ZERO
var _toss_from := Vector3.ZERO
var _toss_to := Vector3.ZERO
var _rest_t := -1.0

## What's measured: ticks a phase, cloth through the arm each tick (from take), the worst point
## speed, the pop at the handoff, the cost a tick by phase (ms, this machine).
var rec := {"ticks": {}, "through": [], "through_max": 0, "through_ticks": 0, "through_total": 0,
		"pop_mm": -1.0, "flung": 0, "below_floor": 0, "lost": 0, "phase_at": {}, "us": {},
		"glove": {}, "rest_at": -1.0, "where": []}


## His glove made and put on (worn, part of his skinned mesh).
func dress(who: HumanBody, on_chair: Node3D) -> Dictionary:
	man = who
	chair = on_chair
	if not with_glove:
		return {"ok": true, "glove": "none"}
	part = GarmentHandoff.glove_on(man, get_parent(), "l", null, tris)
	if part == null:
		return {"ok": false, "error": "no Skin_whole on " + String(man.body_model)}
	glove = part.garment
	part.tune.merge(part_tune, true)
	rec.glove = glove.report.duplicate()
	return {"ok": true, "glove": rec.glove}


func begin() -> void:
	started = true
	t = 0.0
	phase = "present"
	man.curl_hand("l", 0.0)
	var fwd := -man.global_basis.z
	var right := man.global_basis.x
	var sh := (man.pivots[&"upper_arm_l"] as Node3D).global_position
	# Out in front, a little across toward his right, a hand below the shoulder; palm down.
	_l_at = sh + fwd * 0.40 + right * 0.16 + Vector3.DOWN * 0.20
	_l_n = Vector3.UP
	_r_from = man.palm("r")


func _physics_process(delta: float) -> void:
	if not started or done:
		return
	var t0 := Time.get_ticks_usec()
	var pt := Prof.start()
	t += delta
	_step(delta)
	Prof.stop(&"glove_handoff", pt)
	rec.ticks[phase] = int(rec.ticks.get(phase, 0)) + 1
	if part and part.collider and part.state != GarmentHandoff.State.WORN:
		var c: Dictionary = rec.get_or_add("part_us", {})
		var e: Array = c.get_or_add(phase, [0, 0, 0, 0])
		e[0] += part.tick_us
		e[1] += part.collider.rebuild_us if part.collider.active else 0
		e[2] += part.collider.last_tris if part.collider.active else 0
		e[3] += 1
	var us := Time.get_ticks_usec() - t0
	rec.us[phase] = float(rec.us.get(phase, 0.0)) + us


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _step(delta: float) -> void:
	var T: Dictionary = tune
	var left_k := _ease(t / float(T.present))
	var l_at := _l_at
	if phase in ["draw", "toss", "lie", "rest"]:
		# The left arm draws back as the glove comes off it.
		var u := _ease((t - float(T.draw_at)) / float(T.draw))
		l_at = _l_at - _draw_dir * float(T.left_back) * u
	var down := phase in ["lie", "rest"]
	if not down or t - float(rec.phase_at.get("lie", t)) < 0.6:
		man.reach_to("l", l_at, _l_n, left_k if not down else 1.0 - _ease((t - float(rec.phase_at.lie)) / 0.6))
	match phase:
		"present":
			if t >= float(T.reach_at):
				_enter("reach")
		"reach":
			var tips: Vector3 = _tips_now()
			var dir := _finger_dir()
			_r_take = tips + dir * 0.025 + Vector3.UP * 0.012
			var k := _ease((t - float(T.reach_at)) / float(T.reach))
			man.reach_to("r", _r_take, Vector3.UP, k)
			man.curl_hand("r", 0.2 + 0.35 * k)
			if t >= float(T.take_at) and not no_take:
				_take()
		"take":
			man.reach_to("r", _r_take, Vector3.UP, 1.0)
			_measure()
			if t >= float(T.draw_at):
				_enter("draw")
		"draw":
			var u := (t - float(T.draw_at)) / float(T.draw)
			# Two tugs on the way (a pull and a little give), then one long draw.
			var tug := float(T.tug) * (sin(clampf(u, 0.0, 0.5) * TAU * 2.0)) * (1.0 - _ease(u * 2.0))
			var drawn := float(T.draw_len) * _ease(u) + tug
			var at := _r_take + _draw_dir * drawn
			man.reach_to("r", at, Vector3.UP, 1.0)
			_measure()
			if u >= 1.0:
				if part:
					part.let_go_of_arm()
				_toss_from = at
				var to_chair := (chair.global_position + Vector3.UP * 0.9) - at if chair else -man.global_basis.z
				to_chair.y = 0.0
				_toss_to = at + to_chair.normalized() * 0.25 + Vector3.UP * 0.12
				_enter("toss")
		"toss":
			var u := (t - float(rec.phase_at.toss)) / float(T.toss_swing)
			man.reach_to("r", _toss_from.lerp(_toss_to, _ease(u)), Vector3.UP, 1.0)
			_measure()
			if u >= 1.0:
				# Thrown to land on the chair's seat in `toss_flight` s (from where the glove's middle is).
				var from: Vector3 = cloth.centre() if cloth else man.palm("r")
				var aim := chair.global_position + Vector3.UP * float(T.seat) if chair else from + (_toss_to - _toss_from) * 4.0
				var fl := float(T.toss_flight)
				var vel := (aim - from) / fl + Vector3.UP * 0.5 * 9.8 * fl
				# (It's already moving with his hand: the throw adds what's still wanted.)
				var moving := (from - _centre_was) * 60.0
				rec.toss = {"from": [snappedf(from.x, 0.01), snappedf(from.y, 0.01), snappedf(from.z, 0.01)],
						"speed": snappedf(vel.length(), 0.01), "had": snappedf(moving.length(), 0.01)}
				if part:
					part.let_go(vel - moving)
				man.curl_hand("r", 0.1)
				_enter("lie")
			elif cloth:
				_centre_was = cloth.centre()
		"lie":
			if man.can_reach("r", _toss_to):
				man.reach_to("r", _toss_to, Vector3.UP, 1.0 - _ease((t - float(rec.phase_at.lie)) / 0.8))
			_measure()
			var at_rest: bool = cloth.resting if cloth else t - float(rec.phase_at.lie) >= float(T.bare_rest_after)
			if at_rest and _rest_t < 0.0:
				_rest_t = t
				rec.rest_at = t
				_enter("rest")
			elif t >= float(T.max_seconds):
				if cloth:
					rec.where = _where()
					rec.last_fastest = snappedf(cloth.last_mean_speed, 0.001)
				done = true
		"rest":
			if t - _rest_t >= float(T.end_after_rest):
				if cloth:
					rec.where = _where()
					rec.last_fastest = snappedf(cloth.last_mean_speed, 0.001)
				done = true


func _enter(p: String) -> void:
	phase = p
	rec.phase_at[p] = snappedf(t, 0.001)


func _tips_now() -> Vector3:
	if glove == null:
		var sk: Skeleton3D = man.skeleton
		return sk.global_transform * sk.get_bone_global_pose(sk.find_bone("finger_middle_l_2")).origin
	var pts: PackedVector3Array = glove.posed()
	var c := Vector3.ZERO
	for i: int in glove.tips:
		c += pts[i]
	return c / maxf(glove.tips.size(), 1)


## Along his left hand toward its fingertips (world).
func _finger_dir() -> Vector3:
	var sk: Skeleton3D = man.skeleton
	var wr := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
	var tip := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("finger_middle_l_2")).origin
	return (tip - wr).normalized()


## The handoff: the part's take (the worn glove out, the cloth in where it was drawn, its fingertips
## in his right hand, the rest held on his bones by friction).
func _take() -> void:
	_draw_dir = (_finger_dir() + man.global_basis.x * 0.35).normalized()  # out toward his right
	if part:
		part.take("r")
		cloth = part.cloth
	_enter("take")


var _centre_was := Vector3.ZERO


## Each tick the cloth is out: how far the points moved on the first ticks (the pop), points
## through the arm, flung, under the floor, lost.
func _measure() -> void:
	if cloth == null or cloth.resting or not measure:
		return
	var pts: PackedVector3Array = cloth.points_now()
	rec.pop_mm = part.pop_mm
	rec.skin_us_max = maxi(int(rec.get("skin_us_max", 0)), part.collider.rebuild_us)
	rec.skin_tris_max = maxi(int(rec.get("skin_tris_max", 0)), part.collider.last_tris)
	if part.released_all_at >= 0.0:
		rec.released_all_at = snappedf(part.released_all_at, 0.001)
	var sx: float = cloth.stretch(pts)
	rec.stretch_max = maxf(float(rec.get("stretch_max", 1.0)), sx)
	if measure_skin:
		# The same count of the glove as worn (skinned with him), this tick: what the measure finds
		# on a glove that can't be through him (his skin's own folds and normals).
		var base: int = glove.under_skin(glove.posed())
		rec.worn_under_max = maxi(int(rec.get("worn_under_max", 0)), base)
	var n: int = glove.under_skin(pts) if measure_skin else 0

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
