extends TestCase
## How the guns feel, as numbers (config/feel_ranges.json): the kick (how far the muzzle and your
## view climb, how fast, how long till they've settled, how much stays), the rhythm of shots, the
## reload, how much the sights wander held still. Measured on the real test street with the
## player's own guns, frame by frame at 60 fps.

const Feel := preload("res://tests/feel.gd")
const GUN_ACTIONS := [&"fire", &"aim", &"cock", &"reload", &"holster"]

var street: Node3D
var player: Player


func before_each() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	player = street.get_node(^"Player")
	player.global_position = street.get_node(^"TargetBoard").global_position + Vector3(-16.0, 0.0, 0.0)
	player.rotation = Vector3(0, deg_to_rad(-90), 0)
	player.velocity = Vector3.ZERO
	await physics_frames(5)


func after_each() -> void:
	for a in GUN_ACTIONS:
		Input.action_release(a)
	street.queue_free()
	await physics_frames(2)


func _gun(which: String) -> WeaponViewmodel:
	var w: WeaponViewmodel = player.revolver() if which == "revolver" else player.winchester() if which == "rifle" else player.shotgun()
	w.needs_captured_mouse = false
	player.select_weapon(w)
	w.take_out()
	await wait_until(func() -> bool: return w.is_ready_in_hand(), 120)
	return w


## Degrees up from level of a direction.
static func _elev(dir: Vector3) -> float:
	return rad_to_deg(asin(clampf(dir.normalized().y, -1.0, 1.0)))


func _ready_to_fire(w: WeaponViewmodel) -> bool:
	if w is RevolverViewmodel:
		return (w as RevolverViewmodel).state.hammer == RevolverState.Hammer.FULL_COCK
	return (w as ShotgunViewmodel).state.cocked_hammers.has(true)


## Fire once (cocking first) and follow the gun and the view for `seconds`. Returns, a sample a
## frame (the first a frame after the trigger), in degrees above where each was: `gun` how far the
## gun's turned on screen (against your view), `view` your line of sight.
func _kick(w: WeaponViewmodel, aim: bool, seconds := 1.0) -> Dictionary:
	w.steady_hands = true
	if aim:
		Input.action_press(&"aim")
	await physics_frames(40)
	Input.action_press(&"cock")
	await process_frames(2)
	Input.action_release(&"cock")
	await wait_until(func() -> bool: return _ready_to_fire(w), 60)
	await process_frames(20)
	var gun0 := _elev(-w.global_transform.basis.z) - _elev(-player.camera.global_transform.basis.z)
	var view0 := _elev(-player.camera.global_transform.basis.z)
	Input.action_press(&"fire")
	var gun: Array[float] = []
	var view: Array[float] = []
	for i in int(seconds * 60.0):
		await process_frames(1)
		if i == 1:
			Input.action_release(&"fire")
		var v := _elev(-player.camera.global_transform.basis.z)
		gun.append(_elev(-w.global_transform.basis.z) - v - gun0)
		view.append(v - view0)
	Input.action_release(&"aim")
	w.steady_hands = false
	await physics_frames(30)
	return {"gun": gun, "view": view}


## Peak (deg), ms from the shot to the peak, ms from the shot till it's back within a tenth of
## the peak of where it ends, and what's left at the end (deg).
static func _shape(curve: Array[float]) -> Dictionary:
	var peak := 0.0
	var at := 0
	for i in curve.size():
		if curve[i] > peak:
			peak = curve[i]
			at = i
	var rest := curve[-1]
	var settle := curve.size()
	for i in range(curve.size() - 1, at - 1, -1):
		if absf(curve[i] - rest) > 0.1 * (peak - rest):
			settle = i + 1
			break
	return {"peak": peak, "rise_ms": (at + 1) * 1000.0 / 60.0, "settle_ms": (settle + 1) * 1000.0 / 60.0, "rest": rest}


## Sean: "too snappy", "should push, not flip" (DESIGN.md §7 "Recoil"). The gun climbs over a few
## frames, not in one; comes back in a few tenths; your view takes some of it and keeps a little.
func test_kick_pushes() -> void:
	var shapes := {}
	for which in ["revolver", "shotgun"]:
		for aim in [false, true]:
			var w := await _gun(which)
			var k := await _kick(w, aim)
			var g := _shape(k.gun)
			var v := _shape(k.view)
			shapes["%s_%s" % [which, "aimed" if aim else "hip"]] = [g, v]
			print("    %s %s: gun on screen %.1f° at %d ms, settled %d ms | view %.1f° at %d ms, settled %d ms, keeps %.2f°" % [
					which, "aimed" if aim else "hip", g.peak, g.rise_ms, g.settle_ms, v.peak, v.rise_ms, v.settle_ms, v.rest])
			var line := ""
			for i in 24:
				line += "%.1f " % k.gun[i]
			print("      gun by frame: ", line)
	var rh: Array = shapes.revolver_hip
	Feel.within(self, "revolver_kick_degrees", rh[0].peak)
	Feel.within(self, "revolver_kick_rise_ms", rh[0].rise_ms)
	Feel.within(self, "revolver_kick_settle_ms", rh[0].settle_ms)
	Feel.within(self, "revolver_view_climb_degrees", (shapes.revolver_aimed[1] as Dictionary).rest)
	Feel.within(self, "shotgun_shouldered_view_kick_degrees", (shapes.shotgun_aimed[1] as Dictionary).peak)
	Feel.within(self, "shotgun_view_climb_degrees", (shapes.shotgun_aimed[1] as Dictionary).rest)
	# Shouldered, the barrels stay with your eye and you take the shove; from the hip it's the
	# other way round.
	check((shapes.shotgun_aimed[0] as Dictionary).peak < (shapes.shotgun_hip[0] as Dictionary).peak * 0.6,
			"shouldered, the barrels climb less on screen than from the hip")
	check((shapes.shotgun_aimed[1] as Dictionary).peak > (shapes.shotgun_hip[1] as Dictionary).peak * 1.4,
			"shouldered, your view takes more of the shove than from the hip")


## No two shots kick quite the same.
func test_kick_varies_shot_to_shot() -> void:
	var w := await _gun("revolver")
	var peaks: Array[float] = []
	for i in 6:
		var k := await _kick(w, false, 0.4)
		peaks.append(_shape(k.gun).peak)
		var r := (w as RevolverViewmodel).state
		if r.rounds_loaded() == 0:
			r.chambers.fill(RevolverState.Chamber.LOADED)
	var mean := 0.0
	for p in peaks:
		mean += p
	mean /= peaks.size()
	var sd := 0.0
	for p in peaks:
		sd += (p - mean) * (p - mean)
	sd = sqrt(sd / peaks.size())
	print("    revolver kick shot to shot: %s" % str(peaks.map(func(p): return snappedf(p, 0.1))))
	Feel.within(self, "kick_shot_to_shot", sd / mean)


func test_rhythm_measured() -> void:
	var w := await _gun("revolver") as RevolverViewmodel
	# As fast as a hand can cock and fire: press cock, fire the moment it's cocked.
	var times: Array[float] = []
	var clock := {"t": 0.0}
	w.state.fired.connect(func() -> void: times.append(clock.t))
	while times.size() < 5 and clock.t < 10.0:
		if w.state.hammer != RevolverState.Hammer.FULL_COCK:
			w.cock_press()
		else:
			w.pull_trigger()
		await process_frames(1)
		clock.t += 1.0 / 60.0
	var gaps: Array[float] = []
	for i in range(1, times.size()):
		gaps.append(times[i] - times[i - 1])
	print("    revolver: fastest aimed-or-not cadence %s s between shots" % str(gaps))
	# A full reload from empty: open, eject and load six, close.
	var r := w.state
	r.chambers.fill(RevolverState.Chamber.SPENT)
	var start := 0.0
	var tt := 0.0
	while tt < 30.0:
		if r.ready():
			if not r.reload_step():
				r.close_gate()
				break
		await process_frames(1)
		tt += 1.0 / 60.0
	print("    revolver: full reload from six spent %.2f s" % (tt - start))
	check(not times.is_empty(), "fired")


func test_sway_measured() -> void:
	for which in ["revolver", "shotgun"]:
		var w := await _gun(which)
		Input.action_press(&"aim")
		await physics_frames(120)
		var xs: Array[float] = []
		var ys: Array[float] = []
		for i in 180:
			await process_frames(1)
			xs.append(w.sway.x)
			ys.append(w.sway.y)
		Input.action_release(&"aim")
		var mx := 0.0
		for i in xs.size():
			mx = maxf(mx, Vector2(xs[i], ys[i]).length())
		var rms := 0.0
		for i in xs.size():
			rms += xs[i] * xs[i] + ys[i] * ys[i]
		rms = sqrt(rms / xs.size())
		print("    %s aimed and settled: sway rms %.2f°, widest %.2f° (= %.0f cm at 15 m)" % [which, rms, mx, tan(deg_to_rad(mx)) * 1500.0])
		check(rms > 0.0, "it wanders")


# --- The Winchester 1873 (#777; every range proposed until Sean plays it) ------------------------

## The rifle in hand, a round chambered, the hammer back, the hands free.
func _rifle() -> Winchester73Viewmodel:
	var w := await _gun("rifle") as Winchester73Viewmodel
	w.state.tuning.misfire_chance = 0.0
	if not w.state.ready_to_fire():
		w.work_lever()
	await wait_until(func() -> bool: return w.state.ready_to_fire() and w.state.ready(), 60)
	return w


## From the hip to the first shot down the sights (pressed the moment it's at your shoulder); the
## lever as fast as a hand works it, shot to shot; a round through the gate.
func test_winchester_handling() -> void:
	var w := await _rifle()
	var shots: Array[float] = []
	var clock := {"t": 0.0}
	var on_shot := func(_o: Vector3, _d: Vector3, _s: Node) -> void: shots.append(clock.t)
	Events.shot_fired.connect(on_shot)
	Input.action_press(&"aim")
	var fired := false
	while shots.is_empty() and clock.t < 3.0:
		if not fired and w.is_shouldered():
			fired = w.pull_trigger() == Winchester73State.Shot.FIRED
		await process_frames(1)
		clock.t += 1.0 / 60.0
	Feel.within(self, "winchester_shoulder_to_shot_s", shots[0] if not shots.is_empty() else 9.0)
	# The lever and the trigger as fast as they'll go, still shouldered: five more.
	while shots.size() < 6 and clock.t < 10.0:
		if w.state.ready():
			if w.state.ready_to_fire():
				w.pull_trigger()
			elif not w.state.lever_open:
				w.cock_press()
		await process_frames(1)
		clock.t += 1.0 / 60.0
	Input.action_release(&"aim")
	Events.shot_fired.disconnect(on_shot)
	var gaps: Array[float] = []
	for i in range(1, shots.size()):
		gaps.append(snappedf(shots[i] - shots[i - 1], 0.001))
	print("    winchester: shot to shot with the lever %s s" % str(gaps))
	var mean := 0.0
	for g in gaps:
		mean += g / gaps.size()
	Feel.within(self, "winchester_lever_to_shot_s", mean if not gaps.is_empty() else 9.0)
	# Five rounds through the gate (the turn to it once).
	await wait_until(func() -> bool: return w.state.ready(), 60)
	w.state.tube = 5
	var t0: float = clock.t
	Input.action_press(&"reload")
	while w.state.tube < 10 and clock.t - t0 < 15.0:
		await process_frames(1)
		clock.t += 1.0 / 60.0
	Input.action_release(&"reload")
	# The fifth round's push done.
	while not w.state.ready() and clock.t - t0 < 15.0:
		await process_frames(1)
		clock.t += 1.0 / 60.0
	Feel.within(self, "winchester_gate_round_s", (clock.t - t0) / 5.0)


## The rope shot (#734: the hanging; Sean, #777): a hanging rope (3/4", a man's weight on it) shot
## at from a roof, 30 and 60 m off and some 2.5 m below your eye. Steady: shouldered, settled, the
## trigger squeezed as the blade sits on the rope. Rushed: winded from a run, fired as the blade
## first crosses the rope once it's up. Each shot its own seed (the wander and the ball's cone);
## a hit is the ball touching the rope (one through its middle parts it; a graze frays it, and a
## second at the same place parts it: HangingRope).
func test_winchester_rope_shot() -> void:
	var w := await _rifle()
	Events.shot_fired.connect(func(o: Vector3, d: Vector3, _s: Node) -> void: _last_line = [o, d])
	var roof := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 1.0, 6.0)
	shape.shape = box
	roof.add_child(shape)
	street.add_child(roof)
	var feet := player.global_position + Vector3(0.0, 30.0, 0.0)
	roof.global_position = feet + Vector3.DOWN * 0.5
	player.global_position = feet
	player.velocity = Vector3.ZERO
	await physics_frames(10)
	var ahead := -player.global_transform.basis.z
	ahead.y = 0.0
	ahead = ahead.normalized()
	var rates := {}
	for dist in [30.0, 60.0]:
		var rope := HangingRope.new()
		rope.load_kg = 80.0
		rope.length = 2.0
		street.add_child(rope)
		var eye := player.camera.global_position
		rope.global_position = Vector3(eye.x, eye.y - 1.5, eye.z) + ahead * dist
		var mark := rope.global_position + Vector3.DOWN * 1.0
		await physics_frames(2)
		for how in ["steady", "rushed"]:
			var hit := 0
			var cut := 0
			var n := 10
			_misses.clear()
			for i in n:
				# The same hands at both distances (paired seeds): only the range differs.
				var seed := 1873 + i * 31 + (0 if how == "steady" else 997)
				w.sway_model = Sway.new(seed)
				w._rng.seed = seed
				w._kick_rng.seed = seed + 1
				rope.mend()
				var touched := await _rope_shot(w, mark, rope, dist, how == "rushed")
				hit += int(touched > 0)
				cut += int(rope.is_parted)
			var key := "winchester_rope_%dm_%s" % [int(dist), how]
			rates[key] = float(hit) / n
			print("    rope %d m %s: %d of %d touched it, %d cut it through; misses (cm) %s" % [int(dist), how, hit, n, cut, str(_misses)])
		rope.queue_free()
	for key: String in rates:
		Feel.within(self, key, rates[key])
	check(rates.winchester_rope_30m_steady >= rates.winchester_rope_60m_steady, "nearer is easier")
	check(rates.winchester_rope_30m_steady > rates.winchester_rope_30m_rushed, "steady beats rushed")


## Look at `mark`, then one shot as a man would take it; returns how many balls touched the rope.
func _rope_shot(w: Winchester73Viewmodel, mark: Vector3, rope: HangingRope, dist: float, rushed: bool) -> int:
	Input.action_release(&"aim")
	await wait_until(func() -> bool: return w.shoulder <= 0.0, 60)
	w.state.tube = w.tuning.magazine  # topped up: forty shots
	if not w.state.ready_to_fire():
		w.work_lever()
	await wait_until(func() -> bool: return w.state.ready_to_fire() and w.state.ready(), 60)
	_last_line = []
	for k in 3:
		var cam := player.camera.global_transform
		var to := (mark - cam.origin).normalized()
		var fwd := -cam.basis.z
		var yaw := rad_to_deg(atan2(-to.x, -to.z) - atan2(-fwd.x, -fwd.z))
		var pitch := rad_to_deg(asin(to.y) - asin(fwd.y))
		player.add_look(Vector2(-wrapf(yaw, -180.0, 180.0), pitch), false)
		await physics_frames(1)
	player.composure.winded = 0.8 if rushed else 0.0
	player.composure.rattled = 0.0
	Input.action_press(&"aim")
	await wait_until(func() -> bool: return w.is_shouldered(), 60)
	# The rope's half-width as you see it (degrees): the blade's "on it".
	var window := rad_to_deg(atan((rope.diameter * 0.5) / dist))
	var settle := 0.0 if rushed else 1.5
	var t := 0.0
	var before := rope.hits
	while t < settle + 4.0:
		await process_frames(1)
		t += 1.0 / 60.0
		if rushed:
			player.composure.winded = maxf(player.composure.winded, 0.7)
		if t < settle:
			continue
		var off := w.sway.x + w.kick.yaw
		if absf(off) <= window or t >= settle + 3.9:
			# The squeeze: the shot breaks a moment after you decide (the gun keeps moving).
			await process_frames(6)
			w.pull_trigger()
			break
	await physics_frames(int(dist / 400.0 * 60.0) + 8)
	Input.action_release(&"aim")
	if _last_line.size() == 2:
		var o: Vector3 = _last_line[0]
		var d: Vector3 = _last_line[1]
		var p := rope.global_position - o
		var flat := Vector2(d.x, d.z).normalized()
		var miss := Vector2(p.x, p.z).x * flat.y - Vector2(p.x, p.z).y * flat.x
		_misses.append(snappedf(miss * 100.0, 0.1))
	return rope.hits - before


## The last shot's line (origin, way), and each shot's miss sideways of the rope's middle (cm).
var _last_line: Array = []
var _misses: Array[float] = []
