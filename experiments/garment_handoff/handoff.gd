extends Node3D
## The garment handoff (#895; lab only): a long glove worn as part of his skinned mesh, drawn off
## down his fingers and forearm by his other hand as real cloth, tossed, and left lying where it
## lands. Driven a tick at a time; measured as it goes (`rec`).
##
## Phases (s from `begin`): present (his left hand out in front, palm down, fingers open), reach
## (his right hand to its fingertips), take (the worn glove becomes cloth, its fingertips pinned to
## his right hand where they are), draw (the right hand draws it off along the left hand's line,
## two tugs, the left arm drawing back), toss (a swing toward the chair, let go), lie (it falls
## and drapes; at rest its soft body is taken out).

const Glove := preload("res://experiments/garment_handoff/glove.gd")
const GloveCloth := preload("res://experiments/garment_handoff/glove_cloth.gd")
const ArmColliders := preload("res://experiments/garment_handoff/arm_colliders.gd")

## The handoff's timing and reach (s, m).
var tune := {
	"present": 0.9, "reach_at": 1.0, "reach": 0.9, "take_at": 2.1, "draw_at": 2.25, "draw": 2.6,
	"draw_len": 0.62, "left_back": 0.12, "tug": 0.035, "toss_swing": 0.38, "toss_flight": 0.45,
	"seat": 0.5, "end_after_rest": 1.0, "max_seconds": 12.0, "bare_rest_after": 4.5,
	# The arm lets go of a point (friction gives) once an edge from it to cloth already pulled free is
	# stretched past `give` of its length; the finger ends (`release_lead` m from the tips) at once.
	"release_lead": 0.035, "give": 1.05, "front_step": 0.01,
}
var man: HumanBody
var chair: Node3D
var glove: RefCounted
var worn: MeshInstance3D
var cloth: Node3D
var arm: Node3D
var phase := "worn"
var t := 0.0
var started := false
var done := false
var debug_shapes := false
## Without the glove (the cost runs' baseline): the same hands, nothing on them.
var with_glove := true
## Count the cloth under his skin each tick (CPU-skins his arm: ~10 ms here; off for the cost runs).
var measure_skin := true
## Measure at all (off for the cost runs: only the handoff's own work).
var measure := true
## The cloth meets his skin itself (arm_colliders.use_skin), not the fitted shapes.
var skin_collider := true
## (Debug: present and reach only, the glove left worn.)
var no_take := false
## The glove's look (glove.gd's black kid).
var look: Material

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


## His glove made and put on (worn, part of his skinned mesh), the arm's shapes fitted.
func dress(who: HumanBody, on_chair: Node3D) -> Dictionary:
	man = who
	chair = on_chair
	if not with_glove:
		return {"ok": true, "glove": "none"}
	glove = Glove.new()
	if not glove.build(man, "l"):
		return {"ok": false, "error": "no Skin_whole on " + String(man.body_model)}
	look = Glove.material()
	worn = glove.worn(look)
	arm = ArmColliders.new()
	arm.name = "GloveArm"
	get_parent().add_child(arm)
	arm.fit(man, glove.skin_mi, glove.cuff_t, "l")
	arm.follow()
	arm.show_shapes(debug_shapes)
	arm.set_physics_process(false)  # (worn, nothing meets it: the arm's shapes wait for the take)
	rec.glove = glove.report.duplicate()
	rec.glove.shapes = arm.shapes.size()
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
			_let_go_by_tension()
			_measure()
			if u >= 1.0:
				_let_go_of_arm(INF)
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
				if cloth:
					cloth.let_go(vel - moving)
				man.curl_hand("r", 0.1)
				_enter("lie")
				_off_t = 0.25
			elif cloth:
				_centre_was = cloth.centre()
		"lie":
			if _off_t > 0.0:
				_off_t -= delta
				if _off_t <= 0.0 and arm:
					arm.off()  # it's clear of him: his arm's shapes (and their cost) gone
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
					rec.last_fastest = snappedf(cloth.last_fastest, 0.001)
				done = true
		"rest":
			if t - _rest_t >= float(T.end_after_rest):
				if cloth:
					rec.where = _where()
					rec.last_fastest = snappedf(cloth.last_fastest, 0.001)
				done = true


func _enter(p: String) -> void:
	phase = p
	rec.phase_at[p] = snappedf(t, 0.001)


func _tips_now() -> Vector3:
	if glove == null:
		var sk: Skeleton3D = man.skeleton
		return sk.global_transform * sk.get_bone_global_pose(sk.find_bone("finger_middle_l_2")).origin
	var pts: PackedVector3Array = glove.posed(worn)
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


## The handoff: the worn glove out, the cloth in where it was drawn, its fingertips in his right hand.
func _take() -> void:
	if glove == null:
		_draw_dir = (_finger_dir() + man.global_basis.x * 0.35).normalized()
		_enter("take")
		return
	var pts: PackedVector3Array = glove.posed(worn)
	cloth = GloveCloth.new()
	cloth.name = "Glove"
	cloth.setup(pts, glove.indices, glove.uvs, look)
	get_parent().add_child(cloth)
	worn.visible = false
	arm.set_physics_process(true)
	arm.follow()
	if skin_collider:
		arm.use_skin(glove)
	var tips: Array[int] = []
	for i: int in glove.tips:
		tips.append(i)
	cloth.pin_to(tips, man.parts[&"hand_r"], man, "r")
	# The rest held on his arm as worn, each to its bone.
	var rest: Array[int] = []
	var is_tip := {}
	for i in tips:
		is_tip[i] = true
	for i in pts.size():
		if not is_tip.has(i):
			rest.append(i)
	cloth.hold_on(rest, func(i: int) -> Node3D: return arm.carrier(glove.main_bone[i]))
	_on_arm = {}
	for i in rest:
		_on_arm[i] = true
	_let_go_of_arm(0.0)
	_draw_dir = _finger_dir()
	_draw_dir = (_draw_dir + man.global_basis.x * 0.35).normalized()  # out toward his right
	_enter("take")
	_first = pts
	_pop_ticks = 3
	if OS.has_environment("GH_DEBUG"):
		var sk: Skeleton3D = man.skeleton
		var hand := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
		var far := 0
		for i in pts.size():
			if pts[i].distance_to(hand) > 0.75:
				far += 1
				if far < 6:
					var bw := []
					for k in 4:
						bw.append("%s:%.2f" % [glove.skin.get_bind_name(glove.bones[i * 4 + k]), glove.weights[i * 4 + k]])
					print("far point ", i, " at ", pts[i], " ", bw)
		print("far points ", far, " of ", pts.size())
		var w: Dictionary = arm.inside_which(pts)
		var hist := {}
		for i: int in w:
			var key := "%s in %s (own %s)" % [glove.finger_of[i], w[i], man.skeleton.get_bone_name(glove.main_bone[i])]
			hist[key] = hist.get(key, 0) + 1
		print("inside at take: ", hist)


var _on_arm := {}
var _off_t := 0.0
var _centre_was := Vector3.ZERO


## The finger ends at the take (`drawn` 0), or all of it (INF): those let go of his arm.
func _let_go_of_arm(drawn: float) -> void:
	if cloth == null:
		return
	var reach := float(tune.release_lead) + drawn
	var go := {}
	for i: int in _on_arm:
		if glove.along[i] <= reach:
			go[i] = true
	_release(go)


## Friction giving way: while the cloth already pulled free is stretched past its give, the points
## still on his arm nearest his fingertips let go, the front moving up the arm at most `front_step`
## m a tick. (The free cloth as a whole, not the edges at the front: with the solver's few
## iterations the stretch gathers in the middle of the free cloth, away from the pins.)
func _let_go_by_tension() -> void:
	if cloth == null or _on_arm.is_empty():
		return
	if _nbr.is_empty():
		_nbr.resize(glove.verts.size())
		for i in _nbr.size():
			_nbr[i] = []
		for k in range(0, glove.indices.size(), 3):
			for e in 3:
				var a: int = glove.indices[k + e]
				var b: int = glove.indices[k + (e + 1) % 3]
				(_nbr[a] as Array).append([b, cloth.start[a].distance_to(cloth.start[b])])
				(_nbr[b] as Array).append([a, cloth.start[a].distance_to(cloth.start[b])])
	var pts: PackedVector3Array = cloth.points_now()
	var now := 0.0
	var rest := 0.0
	for i in pts.size():
		if _on_arm.has(i):
			continue
		for nb: Array in _nbr[i]:
			var j: int = nb[0]
			if j > i and not _on_arm.has(j):
				now += pts[i].distance_to(pts[j])
				rest += float(nb[1])
	_free_stretch = now / maxf(rest, 1e-6)
	if OS.has_environment("GH_DEBUG") and int(t * 60) % 15 == 0:
		print("t ", snappedf(t, 0.01), " free stretch ", snappedf(_free_stretch, 0.001), " on arm ", _on_arm.size(), " all ", snappedf(cloth.stretch(), 0.001))
	if _free_stretch <= float(tune.give):
		return
	var front := INF
	for i: int in _on_arm:
		front = minf(front, glove.along[i])
	var go := {}
	for i: int in _on_arm:
		if glove.along[i] <= front + float(tune.front_step):
			go[i] = true
	_release(go)


var _free_stretch := 1.0
var _nbr: Array = []


func _release(go: Dictionary) -> void:
	if go.is_empty():
		return
	for i: int in go:
		_on_arm.erase(i)
	cloth.release(go)
	rec.released_at = rec.get("released_at", {})
	if _on_arm.is_empty():
		rec.released_at.all = snappedf(t, 0.001)


var _first := PackedVector3Array()
var _pop_ticks := 0
var _last := PackedVector3Array()


## Each tick the cloth is out: how far the points moved on the first ticks (the pop), points
## through the arm, flung, under the floor, lost.
func _measure() -> void:
	if cloth == null or cloth.resting or not measure:
		return
	var pts: PackedVector3Array = cloth.points_now()
	if _pop_ticks > 0:
		_pop_ticks -= 1
		var worst := 0.0
		_first = glove.posed(worn)  # where the worn glove would be drawn this tick
		for i in pts.size():
			worst = maxf(worst, pts[i].distance_to(_first[i]))
		rec.pop_mm = maxf(float(rec.pop_mm), worst * 1000.0)
		if OS.has_environment("GH_DEBUG"):
			var hist := {}
			for i in pts.size():
				var d := pts[i].distance_to(_first[i]) * 1000.0
				if d > 5.0:
					var key: String = "%s/%s" % [glove.finger_of[i], "tip" if glove.tips.has(i) else ""]
					hist[key] = hist.get(key, 0) + 1
			var mean := Vector3.ZERO
			for i in pts.size():
				mean += pts[i] - _first[i]
			var sk: Skeleton3D = man.skeleton
			print("pop tick ", _pop_ticks, " worst ", worst * 1000.0, " >5mm ", hist, " mean ", mean / pts.size() * 1000.0,
					" posed-now vs first ", (glove.posed(worn)[0] - _first[0]) * 1000.0, " man ", man.global_position)
	if arm._skin_on:
		rec.rebuild_us_max = maxi(int(rec.get("rebuild_us_max", 0)), arm.rebuild_us)
	var sx: float = cloth.stretch()
	rec.stretch_max = maxf(float(rec.get("stretch_max", 1.0)), sx)
	var n: int = glove.under_skin(pts) if measure_skin else 0
	if OS.has_environment("GH_DEBUG") and n > 0 and int(t * 60) % 6 == 0:
		var hist := {}
		for i: int in glove.last_under:
			var key := "%s along %.2f" % [man.skeleton.get_bone_name(glove.main_bone[i]), snappedf(glove.along[i], 0.05)]
			hist[key] = hist.get(key, 0) + 1
		print("t ", snappedf(t, 0.01), " ", phase, " under skin ", n, " on arm ", _on_arm.size(), " ", hist)
	var deep5 := 0
	var deep10 := 0
	for d: float in glove.last_depths:
		if d > 0.005:
			deep5 += 1
		if d > 0.01:
			deep10 += 1
	rec.under_5mm_max = maxi(int(rec.get("under_5mm_max", 0)), deep5)
	rec.under_10mm_max = maxi(int(rec.get("under_10mm_max", 0)), deep10)
	var in_shapes: int = arm.through(pts)
	rec.in_shapes_max = maxi(int(rec.get("in_shapes_max", 0)), in_shapes)
	var bp: Dictionary = rec.get_or_add("by_phase", {})
	var b: Dictionary = bp.get_or_add(phase, {"stretch": 1.0, "through": 0, "on_arm": 0})
	b.stretch = snappedf(maxf(float(b.stretch), sx), 0.001)
	b.through = maxi(int(b.through), n)
	b.in_shapes = maxi(int(b.get("in_shapes", 0)), in_shapes)
	b.on_arm = maxi(int(b.on_arm), _on_arm.size())
	rec.through.append(n)
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
