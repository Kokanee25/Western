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


## Put a roof over the player (the smoke takes it for indoors: no breeze).
func _roof() -> StaticBody3D:
	var roof := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 0.2, 30)
	cs.shape = box
	roof.add_child(cs)
	street.add_child(roof)
	roof.global_position = player.global_position + Vector3(0, 3.2, 0)
	await physics_frames(2)
	return roof


## How much of a man `metres` ahead shows through your own smoke: the light that gets from your
## eye to his chest, sampled after one aimed shot at `seconds` (an array) after it.
func _see_through(which: String, metres: float, seconds: Array, shots := 1, gap := 1.0) -> Array[float]:
	for c in street.find_children("*", "GunSmoke", true, false):
		c.free()
	var w := await _gun(which)
	w.steady_hands = true
	Input.action_press(&"aim")
	await physics_frames(40)
	var eye := player.camera.global_position
	var target := eye - player.camera.global_transform.basis.z * metres
	for k in shots:
		if w is RevolverViewmodel:
			var r := (w as RevolverViewmodel).state
			if r.rounds_loaded() == 0:
				r.chambers.fill(RevolverState.Chamber.LOADED)
			r.busy = 0.0
			r.cock()
			r.busy = 0.0
			(w as RevolverViewmodel).pull_trigger()
		else:
			var sg := (w as ShotgunViewmodel).state
			sg.busy = 0.0
			sg.cock()
			sg.busy = 0.0
			(w as ShotgunViewmodel).pull_trigger()
		if k < shots - 1:
			await process_frames(int(gap * 60.0))
	var out: Array[float] = []
	var elapsed := 0
	for s: float in seconds:
		await process_frames(maxi(0, int(round(s * 60.0)) - elapsed))
		elapsed = int(round(s * 60.0))
		out.append(GunSmoke.transmittance(eye, target))
	Input.action_release(&"aim")
	w.steady_hands = false
	return out


## Sean, 2026-10-18: "I want to be able to actually see the bad guy react to being shot." The shot
## still throws a dense puff at the muzzle (black powder), but it thins and moves off your line
## within half a second; indoors it hangs longer and builds over a fight, never to a wall.
func test_smoke_lets_you_see_him() -> void:
	var times := [0.05, 0.25, 0.5, 1.0, 2.0]
	var out := await _see_through("revolver", 12.0, times)
	print("    revolver, outdoors, a man at 12 m: seen %s at %s s" % [str(out.map(func(v): return snappedf(v, 0.01))), str(times)])
	var sg := await _see_through("shotgun", 12.0, times)
	print("    shotgun, outdoors, 12 m: seen %s" % str(sg.map(func(v): return snappedf(v, 0.01))))
	var roof := await _roof()
	var inside := await _see_through("revolver", 8.0, times)
	print("    revolver, indoors, 8 m: seen %s" % str(inside.map(func(v): return snappedf(v, 0.01))))
	var fight := await _see_through("revolver", 8.0, [1.0], 6, 1.2)
	print("    revolver, indoors, 8 m, a second after the sixth shot in seven: seen %.2f" % fight[0])
	roof.queue_free()
	Feel.within(self, "smoke_puff_at_the_shot", out[0])
	Feel.within(self, "smoke_see_him_half_second", out[2])
	Feel.within(self, "smoke_see_him_one_second", out[3])
	Feel.within(self, "smoke_see_him_shotgun_one_second", sg[3])
	Feel.within(self, "smoke_see_him_indoors_one_second", inside[3])
	Feel.within(self, "smoke_see_him_indoors_after_six", fight[0])
