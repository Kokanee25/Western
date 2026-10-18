extends TestCase
## How the guns feel, as numbers (config/feel_ranges.json): the kick (how far the muzzle and your
## view climb, how fast, how long till they've settled, how much stays), the rhythm of shots, the
## reload, how much the sights wander held still. Measured on the real test street with the
## player's own guns, frame by frame at 60 fps.

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


## Fire once (cocking first) and follow the muzzle and the view for `seconds`. Returns
## {muzzle: [deg above where it was], view: [...]} a sample a frame.
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
	var muzzle0 := _elev(-w.global_transform.basis.z)
	var view0 := _elev(-player.camera.global_transform.basis.z)
	Input.action_press(&"fire")
	var muzzle: Array[float] = []
	var view: Array[float] = []
	for i in int(seconds * 60.0):
		await process_frames(1)
		if i == 1:
			Input.action_release(&"fire")
		muzzle.append(_elev(-w.global_transform.basis.z) - muzzle0)
		view.append(_elev(-player.camera.global_transform.basis.z) - view0)
	Input.action_release(&"aim")
	w.steady_hands = false
	return {"muzzle": muzzle, "view": view}


## Peak (deg), frames to the peak, frames from the peak till it's back within 10% of the peak
## of where it ends, and what's left at the end (deg).
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
	return {"peak": peak, "rise_ms": at * 1000.0 / 60.0, "settle_ms": (settle - at) * 1000.0 / 60.0, "rest": rest}


func test_kick_measured() -> void:
	for which in ["revolver", "shotgun"]:
		for aim in [false, true]:
			var w := await _gun(which)
			var k := await _kick(w, aim)
			var m := _shape(k.muzzle)
			var v := _shape(k.view)
			print("    %s %s: muzzle peak %.1f° at %d ms, settles %d ms, stays %.2f° | view peak %.1f° at %d ms, settles %d ms, stays %.2f°" % [
					which, "aimed" if aim else "hip", m.peak, m.rise_ms, m.settle_ms, m.rest, v.peak, v.rise_ms, v.settle_ms, v.rest])
			var line := ""
			for i in mini(24, k.muzzle.size()):
				line += "%.1f " % k.muzzle[i]
			print("      muzzle by frame: ", line)
			check(m.peak > 0.0, "%s kicks" % which)


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
