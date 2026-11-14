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
	var w: WeaponViewmodel = player.revolver() if which == "revolver" else player.shotgun()
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


# --- The Winchester (#734 step 2) ----------------------------------------------------------------

const RopeRange := preload("res://experiments/gun_lab/win73/rope_range.gd")


func _rifle() -> Winchester73Viewmodel:
	var w := player.rifle()
	w.needs_captured_mouse = false
	player.select_weapon(w)
	w.take_out()
	await wait_until(func() -> bool: return w.is_ready_in_hand(), 180)
	return w


## Work the lever as a tap of the key (open, let go: it shuts once it's all the way out).
func _tap_lever() -> void:
	Input.action_press(&"cock")
	await process_frames(1)
	Input.action_release(&"cock")


## Time from the sights coming up (aim pressed, the gun at the low ready, cocked) to the shot, for a
## hand that fires the moment the cheek is on the comb and the blade's in the notch.
func test_rifle_shoulder_to_first_shot() -> void:
	var w := await _rifle()
	w.state.own_belt = 0
	await _tap_lever()
	await wait_until(func() -> bool: return not w.state.lever_open and w.state.ready(), 120)
	await physics_frames(30)
	var fired := [false]
	w.state.fired.connect(func() -> void: fired[0] = true)
	Input.action_press(&"aim")
	var t := 0.0
	while not fired[0] and t < 3.0:
		await process_frames(1)
		t += 1.0 / 60.0
		if w.shoulder >= 0.95:
			w.pull_trigger()
	Input.action_release(&"aim")
	print("    rifle: shoulder to first shot %.2f s" % t)
	Feel.within(self, "rifle_shoulder_to_shot_seconds", t)


## As fast as the lever and trigger go (from the hip): seconds between shots.
func test_rifle_cycling_rate() -> void:
	var w := await _rifle()
	var times: Array[float] = []
	var clock := {"t": 0.0}
	w.state.fired.connect(func() -> void: times.append(clock.t))
	await _tap_lever()
	while times.size() < 6 and clock.t < 10.0:
		if w.state.ready() and not w.state.lever_open:
			if w.state.hammer == Winchester73State.Hammer.FULL_COCK:
				w.pull_trigger()
			else:
				await _tap_lever()
		await process_frames(1)
		clock.t += 1.0 / 60.0
	var gaps: Array[float] = []
	for i in range(1, times.size()):
		gaps.append(times[i] - times[i - 1])
	var mean := 0.0
	for g in gaps:
		mean += g
	mean /= maxf(gaps.size(), 1)
	print("    rifle: lever to next shot %s s (mean %.2f)" % [str(gaps.map(func(g): return snappedf(g, 0.01))), mean])
	check(gaps.size() >= 4, "it fired shot after shot")
	Feel.within(self, "rifle_cycle_seconds", mean)


## Seconds a round through the gate, R held (topping up from ten).
func test_rifle_reload_per_round() -> void:
	var w := await _rifle()
	w.state.tube = 10
	var loads: Array[float] = []
	var clock := {"t": 0.0}
	w.state.gate_loaded.connect(func() -> void: loads.append(clock.t))
	Input.action_press(&"reload")
	while loads.size() < 5 and clock.t < 15.0:
		await process_frames(1)
		clock.t += 1.0 / 60.0
	Input.action_release(&"reload")
	var per := (loads[-1] - loads[0]) / maxf(loads.size() - 1, 1) if loads.size() > 1 else 99.0
	print("    rifle: %d rounds through the gate, %.2f s a round" % [loads.size(), per])
	check_eq(w.state.tube, 15, "topped up to fifteen")
	Feel.within(self, "rifle_reload_seconds_per_round", per)


## Turn the view onto `target` (degrees off, then nothing): your own hand's aim, as a player's.
func _look_at(target: Vector3) -> void:
	for i in 6:
		var cam := player.camera
		var fwd := -cam.global_transform.basis.z
		var to := (target - cam.global_position).normalized()
		var yaw := rad_to_deg(atan2(fwd.x, -fwd.z) - atan2(to.x, -to.z))
		yaw = wrapf(yaw, -180.0, 180.0)
		var pitch := rad_to_deg(asin(clampf(to.y, -1.0, 1.0)) - asin(clampf(fwd.y, -1.0, 1.0)))
		if absf(yaw) < 0.002 and absf(pitch) < 0.002:
			return
		player.add_look(Vector2(-yaw, pitch), false)
		await process_frames(1)


## How far off the rope the barrel points across (degrees, + to its right): where your view is off
## it, the sway and the kick's left-over.
func _signed_across(w: Winchester73Viewmodel, target: Vector3) -> float:
	var cam := player.camera
	var fwd := -cam.global_transform.basis.z
	var to := (target - cam.global_position).normalized()
	var view := wrapf(rad_to_deg(atan2(fwd.x, -fwd.z) - atan2(to.x, -to.z)), -180.0, 180.0)
	return view + w.sway.x + w.kick.yaw


## A hand's reaction from seeing the sight picture to the trigger breaking (s), and how quickly the
## eye and hand pull the blade back onto the mark as it wanders (s).
const REACTION := 0.12
const STEER := 0.25


## A steady hand on the sights: the eye follows the slow wander (not the fine shake, smoothed over
## 0.08 s), the hand steers the blade back onto the rope as a player's mouse does (through the look,
## so the gun lags the turn as it does yours), and the squeeze starts when the blade's centred on it
## (to a sixteenth of the blade's ~0.2 degrees, 0.012) and holding there; the trigger breaks a
## reaction later. Gives up at 5 s and fires where it is.
func _steady_squeeze(w: Winchester73Viewmodel, target: Vector3) -> void:
	var dt := 1.0 / 60.0
	var waited := 0.0
	var seen := _signed_across(w, target)
	var was := seen
	while waited < 5.0:
		await process_frames(1)
		waited += dt
		was = seen
		seen = lerpf(seen, _signed_across(w, target), 1.0 - exp(-dt / 0.08))
		player.add_look(Vector2(-seen * (1.0 - exp(-dt / STEER)), 0.0))
		if waited > 0.3 and absf(seen) < 0.012 and absf(seen - was) / dt < 0.05:
			break
	await process_frames(int(REACTION * 60.0))


## The rope shot (#734: "a rope at 30-60 m must be hittable for a steady player, and hard but fair
## under pressure"), from the rope range's stand 3 m up. Steady: settled on the shoulder, then
## `_steady_squeeze`. Rushed: winded (after running up the stand's steps), the view on the rope, and
## fired the moment the stock's in the shoulder (no settling, no waiting on the drift). A hit is the ball
## touching the rope (cutting it through is the rope's: most hits through its middle part it).
func test_rifle_rope_shot() -> void:
	var range_root := RopeRange.build(street)
	await physics_frames(10)
	var g := TownLayout.ground_height(RopeRange.STAND.x, RopeRange.STAND.z)
	player.global_position = Vector3(RopeRange.STAND.x - 0.6, g + RopeRange.STAND_TOP + 0.05, RopeRange.STAND.z)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0, deg_to_rad(-90), 0)
	await physics_frames(20)
	var w := await _rifle()
	var ropes := RopeRange.ropes(range_root)
	const N := 16
	var rates := {}
	for i in ropes.size():
		var rope := ropes[i]
		rope.swings = false
		rope.mend_after = 0.0
		var d := int(RopeRange.RANGES[i])
		var target := rope.global_position + Vector3.DOWN * 1.1
		for steady in [true, false]:
			var hit := 0
			var parted := 0
			for n in N:
				w.state.tube = 15
				if w.state.hammer != Winchester73State.Hammer.FULL_COCK:
					await _tap_lever()
					await wait_until(func() -> bool: return not w.state.lever_open and w.state.ready(), 120)
				Input.action_release(&"aim")
				await physics_frames(25)
				await _look_at(target)
				var before := rope.hits
				var fired := [false]
				var on_fire := func() -> void: fired[0] = true
				w.state.fired.connect(on_fire)
				w.state.misfired.connect(on_fire)
				Input.action_press(&"aim")
				if steady:
					await wait_until(func() -> bool: return w.shoulder >= 0.95, 120)
					await physics_frames(int(60 * (player.tuning.settle_time + 0.5)))
					await _steady_squeeze(w, target)
				else:
					player.composure.winded = 0.7
					await wait_until(func() -> bool: return w.shoulder >= 0.98, 120)
				w.pull_trigger()
				await physics_frames(30)
				w.state.fired.disconnect(on_fire)
				w.state.misfired.disconnect(on_fire)
				if rope.hits > before:
					hit += 1
				if rope.is_parted:
					parted += 1
					rope.mend()
				check(fired[0], "the hammer fell (%s %d: %s)" % ["steady" if steady else "rushed", n, w.state.to_dict()])
			var key := "rifle_rope_%dm_%s" % [d, "steady" if steady else "rushed"]
			rates[key] = float(hit) / N
			print("    %s: %d of %d touched the rope, %d parted it" % [key, hit, N, parted])
	Input.action_release(&"aim")
	for k: String in rates:
		Feel.within(self, k, rates[k])
	check(rates["rifle_rope_30m_steady"] > rates["rifle_rope_30m_rushed"], "rushed is harder at 30 m")
	check(rates["rifle_rope_30m_steady"] >= rates["rifle_rope_60m_steady"], "60 m is harder than 30")
