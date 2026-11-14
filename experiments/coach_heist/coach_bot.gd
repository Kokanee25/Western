extends RefCounted
## The coach heist's scripted player (#815's measures): at the high spot over the cut, he shoots the
## ram's pin as the coach comes (or the pin goes by itself: `auto`), fights the guards from there by
## the gunfight lab's scripted player (its eyes, its hand, the `hold` style: player_bot.gd), then
## goes down to the wreck, hauls the strongbox out (E held at the door), shoots its padlock, opens
## it and takes the papers (`take=papers`; `take=box`: shoulders it shut), and walks out by the South
## Road and up the rimrock trail. Seeded: the same seed, the same hand.

const Bot := preload("res://experiments/gunfight_lab/player_bot.gd")

var bot
var player: Player
var cut: CoachCut
var fight: CoachFight
var phase := "pin"
var take := "papers"
var auto_pin := false
var rng := RandomNumberGenerator.new()
var stats := {"pin_shots": 0, "padlock_shots": 0, "phase_at": {}, "stuck": 0.0}
var _t := 0.0
var _on := 0.0
var _since := 9.0
var _quiet := 0.0
var _route: Array[Vector3] = []
var _last := Vector3.ZERO
var _stuck := 0.0
var _side := 1.0
var _sidestep := 0.0
var _wait := 0.0
var _duck := 0.0


func setup(p: Player, c: CoachCut, seed_value: int, aim_degrees := 1.0, how := "papers", auto := false) -> void:
	player = p
	cut = c
	fight = c.fight
	take = how
	auto_pin = auto
	rng.seed = seed_value * 104729 + 7
	bot = Bot.new()
	var men: Array = []
	men.append_array(c.riders)
	bot.setup(p, men, "hold", seed_value, "revolver", aim_degrees)
	if auto_pin:
		phase = "fight"


func teardown() -> void:
	bot.teardown()


func _phase(p: String) -> void:
	phase = p
	stats.phase_at[p] = snappedf(_t, 0.01)


func tick(delta: float, t: float) -> void:
	_t = t
	_since += delta
	if not player.wounds.physiology.is_conscious():
		bot.release_all()
		return
	match phase:
		"pin":
			_pin(delta)
		"fight":
			_fight(delta)
		"down":
			if _shooting(delta):
				_stop()
			elif _follow(_route, delta):
				_phase("haul")
		"haul":
			if _shooting(delta):
				bot._hold_action(&"shove", false)
				return
			_stop()
			if fight.box_state != &"in":
				bot._hold_action(&"shove", false)
				_wait = 0.0
				_phase("padlock" if take == "papers" else "shoulder")
				return
			if not fight.claims_use(player):
				_follow([fight.hatch_top], delta)
				return
			bot._hold_action(&"shove", true)
		"padlock":
			_padlock(delta)
		"open":
			_use_until(delta, func() -> bool: return fight.box_state == &"taken", "out")
		"shoulder":
			_use_until(delta, func() -> bool: return fight.box_state == &"carried", "out")
		"out":
			if _shooting(delta) and fight.box_state != &"carried":
				_stop()
			elif _follow(_route, delta):
				_phase("clear")
		"clear":
			_stop()


## The pin, as the coach comes: aimed at it, the hammer back, fired when the coach's middle is a
## swing's walk short of the ram's line (1.28 s at 1.4 m/s) and a touch.
func _pin(delta: float) -> void:
	if cut.ram == null or not cut.ram.is_held() or (cut.drive and cut.drive.loose):
		_phase("fight")
		return
	bot._run_taps()
	if not bot._gun_out():
		bot._draw()
		return
	if bot.loaded() == 0 and not bot._reloading:
		bot._reloading = true
		bot._reload_t = 0.0
	if bot._reloading:
		bot._handle_gun(delta)
		return
	if not bot._cocked() and bot._taps.is_empty() and bot._ready_gun():
		bot._tap(&"cock")
	bot._hold_action(&"aim", true)
	_look_at(cut.ram.pin_position())
	_on += delta
	if cut.coach == null:
		return
	var short := (cut.ram.global_position - cut.coach.global_position).dot(cut.road_dir)
	if short <= 1.4 * 1.28 + 0.15 and _on > 0.8 and bot._cocked() and bot._taps.is_empty() and _since > 0.6:
		bot._tap(&"fire")
		_since = 0.0
		stats.pin_shots += 1


## From the high spot by the gunfight lab's hold, till they're all out of it, or nobody's been seen
## for 25 s once they're up (then down to the box, shooting at any he sees on the way).
func _fight(delta: float) -> void:
	bot.tick(delta, _t)
	var seen := false
	for man: HumanBody in cut.riders:
		if is_instance_valid(man) and bot._k(man).seen and bot._alive_in_fight(man):
			seen = true
	_quiet = 0.0 if seen else _quiet + delta
	var up := fight.settled_t >= 0.0 and fight.t - fight.settled_t > 10.0
	# (Or two minutes on, a standoff: men behind the wreck he can't hit from up here. He goes down.)
	if fight.settled_t >= 0.0 and (fight.men_out() >= fight.men.size() or (up and _quiet > 25.0) or fight.t - fight.settled_t > 120.0):
		bot._hold_action(&"crouch", false)
		bot._hold_action(&"aim", false)
		_route = _way_down()
		_phase("down")


## Shooting at a man he sees (the bot's eyes and hand, standing where he is). True while he is.
func _shooting(delta: float) -> bool:
	bot.now = _t
	bot._since_shot += delta
	bot._run_taps()
	bot._look_t -= delta
	if bot._look_t <= 0.0:
		bot._look_t = Bot.TICK
		bot._look(Bot.TICK)
	if fight.box_state == &"carried":
		return false
	bot._pick_target()
	var armed: bool = bot._gun_out()
	if armed:
		bot._handle_gun(delta)
	elif bot.target != null:
		bot._draw()
	var on: bool = bot.target != null and armed and bot._k(bot.target).seen
	if on:
		bot._aim(delta)
	return on


## Down off the high spot, round the wreck's back (its wheels and gear are on your side) to its
## roof side, by the door on top.
func _way_down() -> Array[Vector3]:
	var door := fight.hatch_top
	# Round its back (+x: the boot; the pole and the traces stick out past its front).
	var along := fight.coach_basis() * Vector3.RIGHT
	along.y = 0.0
	along = along.normalized()
	var pts: Array[Vector3] = [door + along * 3.6 - fight.lee_dir * 2.8, door + along * 3.6 + fight.lee_dir * 2.0,
			door + fight.lee_dir * 1.3]
	for i in pts.size():
		pts[i].y = float(cut.height_at.call(pts[i].x, pts[i].z))
	return pts


## The padlock shot off from 2 m (crouched before it, the gun on it), then the lid.
func _padlock(delta: float) -> void:
	_wait += delta
	if _wait > 45.0:
		stats.padlock_gave_up = true
		_wait = 0.0
		_phase("shoulder")  # (can't get a shot at it: he takes the box shut)
		return
	var box := fight.box
	if box == null or not is_instance_valid(box):
		_phase("open")
		return
	if not box.is_locked("lid"):
		bot._hold_action(&"aim", false)
		_phase("open")
		return
	bot._run_taps()
	if not bot._gun_out():
		bot._draw()
		return
	var lock := box.get_member(StringName("%s/padlock" % box.structure_id))
	var at := lock.global_position if lock else box.global_position + Vector3.UP * 0.3
	var d := Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length()
	stats.pad_d = snappedf(d, 0.01)
	if d < 1.6 or d > 2.6:
		# Back off (or in) to about 2 m in front of it.
		# (The box is set down with its padlock away from the wreck: there, 2 m off it.)
		var away := at - fight.hatch_top
		away.y = 0.0
		var stand := at + away.normalized() * 2.0
		_follow([stand], delta)
		return
	_stop()
	if bot.loaded() == 0 and not bot._reloading:
		bot._reloading = true
		bot._reload_t = 0.0
	if bot._reloading:
		bot._handle_gun(delta)  # (the gate, the rounds, the gate shut)
		return
	if not bot._cocked() and bot._taps.is_empty() and bot._ready_gun():
		bot._tap(&"cock")
	bot._hold_action(&"aim", true)
	_look_at(at)
	_on += delta
	if _on > 1.0 and bot._cocked() and bot._taps.is_empty() and _since > 0.8:
		bot._tap(&"fire")
		_since = 0.0
		_on = 0.0
		stats.padlock_shots += 1
		if stats.padlock_shots > 12:
			_phase("shoulder")


## E held by the box till `done`, then on to `next` (the way out).
func _use_until(delta: float, done: Callable, next: String) -> void:
	bot._run_taps()
	bot._hold_action(&"aim", false)
	if done.call():
		bot._hold_action(&"shove", false)
		_route = _way_out()
		_phase(next)
		return
	var box := fight.box
	if not fight.claims_use(player) and box and is_instance_valid(box):
		bot._hold_action(&"shove", false)
		_follow([box.global_position], delta)
		return
	_stop()
	_wait += delta
	# Let go and press again between each step (open, then take).
	bot._hold_action(&"shove", fmod(_wait, 2.0) < 1.7)


## East along the South Road to where the rimrock trail leaves it, and up it.
func _way_out() -> Array[Vector3]:
	var line := cut.layout.road_line("rimrock_trail")
	var a := Vector3(line[0].x, 0.0, line[0].y)
	var b := Vector3(line[1].x, 0.0, line[1].y)
	var up := a + (b - a).normalized() * (fight.tuning.trail_along + 8.0)
	return [cut.middle + cut.road_dir * 20.0, a, up] as Array[Vector3]


func _follow(way_pts: Array[Vector3], delta: float, run := false) -> bool:
	while not way_pts.is_empty() and _flat(way_pts[0]).length() < 0.6:
		way_pts.pop_front()
	if way_pts.is_empty():
		_stop()
		return true
	var flat := _flat(way_pts[0])
	if bot.target == null or not bot._gun_out() or phase in ["out", "padlock", "open", "shoulder", "haul"]:
		player.rotation.y = atan2(-flat.x, -flat.z)
	if player.global_position.distance_to(_last) < 0.5 * delta:
		_stuck += delta
		stats.stuck += delta
	else:
		_stuck = maxf(_stuck - delta, 0.0)
	_last = player.global_position
	if _stuck > 0.5 and _stuck - delta <= 0.5:
		bot._tap(&"jump")
		_duck = 2.5  # (and ducked: the ram's log hangs over the road at head height after the hit)
	_duck = maxf(_duck - delta, 0.0)
	bot._hold_action(&"crouch", _duck > 0.0)
	if _stuck > 1.2:
		_sidestep = 0.6
		_stuck = 0.0
		_side = -_side
	var dir := flat.normalized()
	if _sidestep > 0.0:
		_sidestep -= delta
		dir = dir.cross(Vector3.UP) * _side
	var fwd := -player.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := player.global_basis.x
	right.y = 0.0
	right = right.normalized()
	bot._hold_action(&"move_forward", dir.dot(fwd) > 0.38)
	bot._hold_action(&"move_back", dir.dot(fwd) < -0.38)
	bot._hold_action(&"move_right", dir.dot(right) > 0.38)
	bot._hold_action(&"move_left", dir.dot(right) < -0.38)
	bot._hold_action(&"run", run)
	return false


func _flat(to: Vector3) -> Vector3:
	return Vector3(to.x - player.global_position.x, 0.0, to.z - player.global_position.z)


func _stop() -> void:
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right", &"run"]:
		bot._hold_action(a, false)


func _look_at(p: Vector3) -> void:
	var to := p - player.camera.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var pitch := rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length()))
	var was := player.input_enabled
	player.input_enabled = true
	player.add_look(Vector2(0.0, pitch - player.get_pitch_degrees()), false)
	player.input_enabled = was
