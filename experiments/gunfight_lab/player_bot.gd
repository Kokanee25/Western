extends RefCounted
## The gunfight lab's scripted player (README.md "The scripted player"): plays you through the
## keys, as the dev bridge does (aim, cock, fire, reload, crouch, move), so the gun's own sway,
## kick and the ball along the barrel decide where his shots go. Seeded: the same seed, the same
## fight. Three styles:
##   hold  - holds his spot: crouched behind it, up to shoot when he can't see over it.
##   cover - moves cover to cover: after a couple of shots, when hit, pinned or flanked, he runs
##           for the next spot (found by `Cover.find`, the gang's own cover finder) and shoots
##           from its peek.
##   push  - pushes hard: walks at the nearest man he knows of, shooting as he goes, and reloads
##           where he stands.
##   careful - cover as a careful person plays it (Experiment, 2026-10-24: a scripted player more
##           like a person, so a fight's length isn't one quick shot's): to cover first when it
##           starts; up for a shot or two (CAREFUL_UP s at most) then down again for a moment;
##           down a while when he's hit, pressing on a wound that bleeds once it's quiet; topping
##           up his rounds while he's down; hurried (a wider aim, less settling) with balls
##           cracking past; his aim CAREFUL_AIM times the cover style's.
## He sees by the gang's rules (Senses: range by daylight, sharp ahead and dim to the side,
## nothing behind, a clear line to head, chest or pelvis, awareness built over a moment, harder
## to pick out a man crouched and still) and hears their shots roughly where they came from.
## His hand is a person's, not an aimbot's: he turns onto a man with a lag and an error that
## settles, aims where he takes the man to be (off by `aim_sd`, drawn again each shot), waits to
## settle before the shot, and never fires faster than he could cock.

const TICK := 0.12  # Senses.TICK

var player: Player
var gang: Array = []  # HumanBody
var style := "hold"
var rng := RandomNumberGenerator.new()
var weapon_kind := "revolver"
## Before the first shot of an ambush he's walking down the street, gun away (`walking`), until
## he's shot at, hears a shot or picks a man out.
var walking := false
var walk_dir := Vector3.RIGHT
var contact_at := -1.0  # fight time he knew he was in a fight
## He opens it (opening=shoot): his gun away, he draws on men going about their drink and fires
## the first shot (as Sean did), before any of them has turned on him.
var opens := false
var _opened := false  # his first shot's gone off
var reaction := 0.3

var know := {}  # man -> {aw, seen, last_pos, last_time, heard_pos, heard_time}
var target = null  # HumanBody; untyped: a man who rides out of town is freed under it
var held := {}  # action -> true while held
var _taps: Array = []  # [action, frames left before it's let go]
var _look_t := 0.0
var now := 0.0

# The hand.
var _aim_err := Vector2.ZERO  # degrees (yaw, pitch) the view is off the man, settling
## Where he thinks the man is, off where he is (degrees): a person's aim, drawn again each shot,
## its spread side to side (`aim=` on gf_fight; up and down three quarters of it).
var _bias := Vector2.ZERO
var aim_sd := Vector2(1.0, 0.75)
var _on_target := 0.0  # seconds aimed at this man
var _since_shot := 99.0
var _cock_in := -1.0
var _settle := 0.4

# Where he is and what he's doing.
var spot := Vector3.INF  # where he holds (hold/cover)
var peek := Vector3.INF  # where he shoots from (cover: a wall's edge)
var low_cover := true
var moving_to := Vector3.INF
var _move_started := 0.0
var _last_pos := Vector3.ZERO
var _stuck := 0.0
var _shots_here := 0
var _shots_before_move := 2
var _pinned_until := 0.0
var _near_recent: Array = []  # times of near misses on him
var _hit_recent := -99.0
var _flanked := 0.0
var _idle_here := 0.0
var _reloading := false
var _reload_t := 0.0
var _sidestep := 0.0
var _side := 1.0
## Down behind cover with nobody in sight: every few seconds he comes up (or out to the edge) to look.
var _look_out := 0.0
var _look_out_in := 3.0

## What he did, for the record.
# careful: down (not shooting, head down) till this fight time; up this long; to cover at the start.
const CAREFUL_UP := 1.6
const CAREFUL_DOWN := Vector2(1.2, 2.8)
const CAREFUL_HIT_DOWN := 3.0
const CAREFUL_AIM := 1.6
var careful := false
var _down_until := -1.0
var _up := 0.0
var _peek_shots := 0
var _took_cover := false
var _tending := 0.0
var _tended_at := -99.0
var _route: Array = []  # careful: the way to his next cover, by the building's ways
var _dbg := 0.0

var stats := {"shots": 0, "cover_moves": 0, "reloads": 0, "stuck": 0, "drew_at": -1.0, "first_aimed_at": -1.0, "arm_out_at": -1.0, "look_outs": 0}


func setup(p: Player, men: Array, how: String, seed_value: int, kind: String, aim_degrees := 1.0) -> void:
	player = p
	aim_sd = Vector2(aim_degrees, aim_degrees * 0.75)
	gang = men
	style = how
	careful = how == "careful"
	if careful:
		style = "cover"
		aim_sd *= CAREFUL_AIM
	weapon_kind = kind
	rng.seed = seed_value * 7919 + 17
	reaction = rng.randf_range(0.25, 0.45)
	_shots_before_move = 2 + rng.randi() % 2
	_side = 1.0 if rng.randf() < 0.5 else -1.0
	spot = p.global_position
	_last_pos = p.global_position
	Events.shot_fired.connect(_on_shot)
	Events.near_miss.connect(_on_near_miss)
	Events.body_hit.connect(_on_body_hit)


func teardown() -> void:
	for sig: Signal in [Events.shot_fired, Events.near_miss, Events.body_hit]:
		for c: Dictionary in sig.get_connections():
			if c.callable.get_object() == self:
				sig.disconnect(c.callable)
	release_all()


## He knows where they all are (a standoff: everyone's in plain sight when it starts).
func know_all() -> void:
	for man: HumanBody in _live():
		var k := _k(man)
		k.aw = 1.0
		k.seen = true
		k.last_pos = man.global_position
		k.last_time = 0.0
	contact_at = 0.0


# -- Each tick ------------------------------------------------------------------------------------

func tick(delta: float, fight_t: float) -> void:
	now = fight_t
	_since_shot += delta
	if target != null and not is_instance_valid(target):
		target = null
	_run_taps()
	if not player.wounds.physiology.is_conscious():
		release_all()
		return
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = TICK
		_look(TICK)
	if walking:
		_walk_in(delta)
		return
	if now - contact_at < reaction:
		return  # the moment it takes to take in that it's started
	var armed := _gun_out()
	if not armed:
		# Drawing (or, with his gun arm shot, unable to hold it: the gun puts itself away).
		_draw()
		if _gun().arm_disabled and stats.arm_out_at < 0.0:
			stats.arm_out_at = now
	_pick_target()
	_look_out = maxf(_look_out - delta, 0.0)
	if target == null and not _reloading and moving_to == Vector3.INF:
		_look_out_in -= delta
		if _look_out_in <= 0.0:
			_look_out = rng.randf_range(1.2, 2.0)
			_look_out_in = rng.randf_range(2.5, 4.5) + _look_out
			stats.look_outs += 1
	if armed:
		_handle_gun(delta)
	match style:
		"hold":
			_hold(delta)
		"cover":
			_cover(delta)
		"push":
			_push(delta)
	if careful:
		_careful_step(delta)
	if target != null and armed and not (careful and now < _down_until):
		_aim(delta)
	elif moving_to == Vector3.INF and not held.has(&"move_forward"):
		_search_look(delta)


# -- Eyes and ears (Senses' rules) ----------------------------------------------------------------

func _k(man: Node) -> Dictionary:
	if not know.has(man):
		know[man] = {"aw": 0.0, "seen": false, "last_pos": Vector3.INF, "last_time": -INF, "heard_pos": Vector3.INF, "heard_time": -INF}
	return know[man]


func _daylight() -> float:
	var day := player.get_tree().get_first_node_in_group(&"day_cycle")
	return clampf(day.call(&"get_daylight"), 0.0, 1.0) if day else 1.0


func _look(dt: float) -> void:
	var cam := player.camera
	var from := cam.global_position
	var fwd := -cam.global_basis.z
	var range_m := SightLight.sight_range(SightLight.sky_lux(_daylight()))  # the open sky's reach (the men's own now goes by the light on whom they look at)
	var space := player.get_world_3d().direct_space_state
	for man: HumanBody in _live():
		if not is_instance_valid(man):
			continue
		var k := _k(man)
		var vis := _visibility(man, from, fwd, range_m, space)
		if vis > 0.0:
			k.aw = minf(float(k.aw) + vis * Senses.NOTICE_RATE * dt, 1.0)
		else:
			k.aw = maxf(float(k.aw) - dt * 0.05, 0.0)
		k.seen = vis > 0.0 and k.aw >= 1.0
		if k.seen:
			k.last_pos = man.global_position
			k.last_time = now
			if walking:
				_contact()


func _visibility(man: HumanBody, from: Vector3, fwd: Vector3, range_m: float, space: PhysicsDirectSpaceState3D) -> float:
	var best := 0.0
	for sid: StringName in [&"head", &"chest", &"pelvis"]:
		var part := man.parts.get(sid) as Node3D
		if part == null:
			continue
		var p := part.global_position
		var to := p - from
		var d := to.length()
		if d > range_m or d < 0.01:
			continue
		var ang := rad_to_deg(fwd.angle_to(to))
		if ang > Senses.PERIPHERAL:
			continue
		if not clear(from, p, space):
			continue
		var cone := 1.0 if ang <= Senses.FOVEA else lerpf(0.35, 0.05, (ang - Senses.FOVEA) / (Senses.PERIPHERAL - Senses.FOVEA))
		var dist := clampf(1.0 - d / range_m, 0.0, 1.0)
		dist = dist * dist * 0.8 + 0.2 * float(d < range_m * 0.5)
		best = maxf(best, cone * dist)
	if best <= 0.0:
		return 0.0
	best *= 0.6 + minf(man.move_speed / 3.0, 1.0) * 0.8
	if man.prone or man.limp or man.pose in [&"crouch", &"duck", &"lie", &"crouch_aim", &"tend"]:
		best *= 0.55
	return clampf(best, 0.0, 1.5)


func clear(from: Vector3, to: Vector3, space: PhysicsDirectSpaceState3D = null) -> bool:
	if space == null:
		space = player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	q.exclude = [player.get_rid()]
	var hit := space.intersect_ray(q)
	return hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15


func _on_shot(origin: Vector3, _dir: Vector3, shooter: Node) -> void:
	if shooter == player:
		_opened = true
	if not shooter in gang:
		return
	var k := _k(shooter)
	var d := origin.distance_to(player.global_position)
	var err := 0.1 * d
	k.heard_pos = origin + Vector3(rng.randf_range(-err, err), 0.0, rng.randf_range(-err, err))
	k.heard_time = now
	if walking:
		_contact()


func _on_near_miss(person: Node, _shooter: Node, _d: float, _at: Vector3, _s: float, _t: bool) -> void:
	if person != player:
		return
	_near_recent.append(now)
	if walking:
		_contact()


func _on_body_hit(info: Dictionary) -> void:
	if info.get("person") == player:
		_hit_recent = now
		if careful:
			_down_until = maxf(_down_until, now + CAREFUL_HIT_DOWN)
		if walking:
			_contact()


func _contact() -> void:
	walking = false
	contact_at = now
	_act(false, &"move_forward")
	held.erase(&"move_forward")


func _live() -> Array:
	return gang.filter(func(n: Variant) -> bool: return is_instance_valid(n))


func _alive_in_fight(man: HumanBody) -> bool:
	if not is_instance_valid(man) or not man.physiology.alive or man.limp:
		return false
	var brain := man.get_node_or_null(^"Brain") as OutlawBrain
	if opens and not _opened and brain != null and brain.mood == OutlawBrain.Mood.CALM:
		return true  # he shoots first (opening=shoot): at men who aren't in it yet
	return brain != null and brain.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING, OutlawBrain.Mood.TENDING]


## The man he'd shoot: one he can see now (the nearest); else none.
func _pick_target() -> void:
	var best: HumanBody = null
	var best_d := INF
	var opening: bool = opens and not _opened  # drawing on men in plain sight: he knows where each is
	for man: HumanBody in _live():
		if not _alive_in_fight(man) or not (_k(man).seen or (opening and clear(player.camera.global_position, (man.parts[&"chest"] as Node3D).global_position))):
			continue
		var d := man.global_position.distance_to(player.global_position)
		if man == target:
			d -= 2.0  # keeps to the man he's on
		if d < best_d:
			best_d = d
			best = man
	if best != target:
		target = best
		_on_target = 0.0
		_settle = rng.randf_range(0.3, 0.6)
		_aim_err = Vector2(rng.randfn(0.0, 2.5), rng.randfn(0.0, 1.5))
		_bias = Vector2(rng.randfn(0.0, aim_sd.x), rng.randfn(0.0, aim_sd.y))


## Where he last knew the nearest man still in it to be (seen or heard), INF if nowhere.
func _threat() -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for man: HumanBody in _live():
		if not _alive_in_fight(man):
			continue
		var k := _k(man)
		var at: Vector3 = k.last_pos if float(k.last_time) >= float(k.heard_time) else k.heard_pos
		if at == Vector3.INF or now - maxf(k.last_time, k.heard_time) > 20.0:
			continue
		var d := at.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = at
	return best


# -- The gun -------------------------------------------------------------------------------------

func _gun() -> WeaponViewmodel:
	return player.revolver() if weapon_kind == "revolver" else player.shotgun()


func _gun_out() -> bool:
	var w := _gun()
	return player.weapon == w and w.drawn


func _draw() -> void:
	var w := _gun()
	if player.weapon != w or not w.selected:
		player.select_weapon(w)
	elif not w.drawn and _taps.is_empty():
		_tap(&"holster")
	if stats.drew_at < 0.0:
		stats.drew_at = now


func loaded() -> int:
	var w := _gun()
	if w is RevolverViewmodel:
		return (w as RevolverViewmodel).state.rounds_loaded()
	var st := (w as ShotgunViewmodel).state.to_dict()
	return (st.barrels as Array).count(1)


func _cocked() -> bool:
	var w := _gun()
	if w is RevolverViewmodel:
		return (w as RevolverViewmodel).state.hammer == RevolverState.Hammer.FULL_COCK
	return (w as ShotgunViewmodel).state.cocked_hammers.has(true)


func _gate_open() -> bool:
	var w := _gun()
	if w is RevolverViewmodel:
		return (w as RevolverViewmodel).state.gate_open
	return (w as ShotgunViewmodel).state.open


func _ready_gun() -> bool:
	var w := _gun()
	return (w as RevolverViewmodel).state.ready() if w is RevolverViewmodel else (w as ShotgunViewmodel).state.ready()


func _full() -> int:
	return 5 if weapon_kind == "revolver" else 2


func _handle_gun(delta: float) -> void:
	if _reloading:
		_reload_t += delta
		_hold_action(&"aim", false)
		# Held down, the gun does each step as it's ready (opens, ejects, loads, turns); it closes
		# itself when there's nothing left to do.
		_hold_action(&"reload", true)
		if (loaded() >= _full() and not _gate_open()) or _reload_t > 20.0:
			_hold_action(&"reload", false)
			_reloading = false
			if _gate_open():
				_tap(&"cock")  # shuts the gate / closes the action
		return
	var seen_target: bool = target != null and _k(target).seen
	var want_reload: bool = loaded() == 0 or (loaded() < _full() and not seen_target and style != "push" \
			and (target == null or now - float(_k(target).last_time) > 2.5) and _since_shot > 1.5) \
			or (careful and now < _down_until and loaded() <= 2 and _since_shot > 0.5)
	if want_reload and not _cocked():
		_reloading = true
		_reload_t = 0.0
		stats.reloads += 1
		return
	# Thumb the hammer back after each shot (single action; the coach gun's hammers too).
	if not _cocked() and loaded() > 0 and _ready_gun() and _since_shot > 0.15 and _taps.is_empty():
		_tap(&"cock")
	_hold_action(&"aim", target != null and moving_to == Vector3.INF)


func _aim(delta: float) -> void:
	var cam := player.camera
	var man := target as HumanBody
	var chest := man.parts.get(&"chest") as Node3D
	var aim_at := chest.global_position if chest else man.global_position + Vector3.UP * 1.3
	if not _k(target).seen:
		return
	var to := aim_at - cam.global_position
	var want_yaw := atan2(-to.x, -to.z)
	var want_pitch := rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length()))
	# His error settles over a fraction of a second; his hand lags a moving man.
	_aim_err = _aim_err * exp(-delta / 0.35) + Vector2(rng.randfn(0.0, 0.25), rng.randfn(0.0, 0.18)) * sqrt(delta * 10.0)
	want_yaw += deg_to_rad(_aim_err.x + _bias.x)
	want_pitch += _aim_err.y + _bias.y
	var yaw := player.rotation.y
	var dyaw := wrapf(want_yaw - yaw, -PI, PI)
	var k := 1.0 - exp(-delta / 0.08)
	var step := clampf(dyaw * k, -deg_to_rad(720.0) * delta, deg_to_rad(720.0) * delta)
	player.rotation.y = yaw + step
	var dp := (want_pitch - player.get_pitch_degrees()) * k
	var was := player.input_enabled
	player.input_enabled = true
	player.add_look(Vector2(0.0, dp))
	player.input_enabled = was
	# How far off he thinks he is (he takes the man to be where his bias puts him).
	var off := rad_to_deg(absf(wrapf(want_yaw - deg_to_rad(_aim_err.x) - player.rotation.y, -PI, PI)))
	var dist := to.length()
	var tol := maxf(rad_to_deg(atan2(0.18, dist)), 0.5)
	if off < tol * 2.0:
		_on_target += delta
		if stats.first_aimed_at < 0.0:
			stats.first_aimed_at = now
	else:
		_on_target = 0.0
	if _reloading or not _cocked() or _since_shot < 0.45 or not _gun_out():
		return
	if moving_to != Vector3.INF and style != "push":
		return
	if _on_target >= _settle and off < tol and _taps.is_empty():
		_tap(&"fire")
		_since_shot = 0.0
		_shots_here += 1
		stats.shots += 1
		_settle = rng.randf_range(0.2, 0.45)
		var hurry := 1.5 if careful and _near_recent.any(func(t: float) -> bool: return now - t < 1.0) else 1.0
		if hurry > 1.0:
			_settle *= 0.6
		_bias = Vector2(rng.randfn(0.0, aim_sd.x * hurry), rng.randfn(0.0, aim_sd.y * hurry))
		_peek_shots += 1


## No man in sight: he looks where he last saw or heard one, his eyes going a little either side.
func _search_look(delta: float) -> void:
	var at := _threat()
	if at == Vector3.INF:
		return
	var cam := player.camera
	var to := at + Vector3.UP * 1.3 - cam.global_position
	var want_yaw := atan2(-to.x, -to.z) + deg_to_rad(20.0) * sin(now * 1.3)
	var k := 1.0 - exp(-delta / 0.15)
	player.rotation.y += wrapf(want_yaw - player.rotation.y, -PI, PI) * k
	var want_pitch := rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length()))
	var was := player.input_enabled
	player.input_enabled = true
	player.add_look(Vector2(0.0, (want_pitch - player.get_pitch_degrees()) * k))
	player.input_enabled = was


## The building's ways, as the gang knows them (careful: his cover's found and reached by them).
func _places() -> Waypoints:
	for man: HumanBody in _live():
		var b := man.get_node_or_null(^"Brain") as OutlawBrain
		if b and b.places:
			return b.places
	return null


## careful: how long he's been up shooting; down again after a shot or two; a wound pressed on.
func _careful_step(delta: float) -> void:
	_dbg -= delta
	if _dbg <= 0.0 and OS.has_environment("BOT_DEBUG"):
		_dbg = 0.5
		print("BOT t=%.1f down=%.1f up=%.1f target=%s seen=%s moving=%s spot=%s low=%s crouch=%s reload=%s tend=%.1f shots=%d onT=%.2f" % [now, _down_until - now, _up, target.name if target else "-", _k(target).seen if target else false, moving_to != Vector3.INF, spot, low_cover, held.has(&"crouch"), _reloading, _tending, stats.shots, _on_target])
	# Up (or out to the edge) whenever he's not down: to look, and to shoot if there's a man there.
	var up := now >= _down_until and moving_to == Vector3.INF and not _reloading and _threat() != Vector3.INF
	_up = _up + delta if up else 0.0
	if not up:
		_peek_shots = 0
	if up and (_up > CAREFUL_UP + (0.8 if target != null and _peek_shots == 0 else 0.0) or (_peek_shots >= 1 + rng.randi() % 2 and _since_shot > 0.3)):
		_down_until = now + rng.randf_range(CAREFUL_DOWN.x, CAREFUL_DOWN.y)
		_up = 0.0
		_peek_shots = 0
	# A wound that's bleeding, and nothing coming in for a moment: down, pressing on it.
	var ph := player.wounds.physiology
	var quiet := _near_recent.filter(func(t: float) -> bool: return now - t < 3.0).is_empty() and now - _hit_recent > 3.0
	if _tending > 0.0:
		_tending -= delta
		_down_until = maxf(_down_until, now + 0.2)
		if _tending <= 0.0 or ph.total_bleed_rate() < 0.3:
			_tending = 0.0
			_hold_action(&"tend_wounds", false)
	elif ph.total_bleed_rate() > 0.8 and quiet and not _reloading and moving_to == Vector3.INF and now - _tended_at > 10.0:
		_tending = 6.0
		_tended_at = now
		_hold_action(&"tend_wounds", true)


# -- Styles ---------------------------------------------------------------------------------------

## Crouched behind it unless he must stand to see the man he's after.
func _hold(delta: float) -> void:
	if player.global_position.distance_to(spot) > 0.8:
		_go(spot, delta, false)
		return
	_stop_moving()
	_crouch_or_stand()


func _crouch_or_stand() -> void:
	if careful and not (opens and not _opened):
		_hold_action(&"crouch", _reloading or now < _down_until or _threat() == Vector3.INF)
		return
	if opens and not _opened:
		_hold_action(&"crouch", false)  # standing as he draws on them
		return
	if _reloading or target == null:
		var known := _threat()
		var down := _reloading or ((known != Vector3.INF or now - _hit_recent < 2.0) and _look_out <= 0.0)
		_hold_action(&"crouch", down)
		return
	var chest := ((target as HumanBody).parts.get(&"chest") as Node3D).global_position
	var low_eye := player.global_position + Vector3.UP * player.tuning.crouch_eye_height
	_hold_action(&"crouch", clear(low_eye, chest))


func _cover(delta: float) -> void:
	if moving_to != Vector3.INF:
		while _route.size() > 1 and player.global_position.distance_to(_route[0]) < 0.5:
			_route.pop_front()
		var leg: Vector3 = _route[0] if not _route.is_empty() else moving_to
		if _go(leg, delta, true) and (_route.size() <= 1):
			_stop_moving()
			spot = player.global_position
			_shots_here = 0
			_idle_here = 0.0
			stats.cover_moves += 1
		return
	if player.global_position.distance_to(spot) > 1.2 and peek == Vector3.INF:
		spot = player.global_position
	# Time to go: a couple of shots from here, a hit, rounds cracking past, a man round the side.
	_near_recent = _near_recent.filter(func(t: float) -> bool: return now - t < 4.0)
	var threat := _threat()
	var flanked := false
	if threat != Vector3.INF:
		var low_eye := player.global_position + Vector3.UP * 0.9
		for man: HumanBody in _live():
			if _alive_in_fight(man) and _k(man).seen and not _reloading:
				var eye := (man.parts[&"head"] as Node3D).global_position
				if clear(eye, low_eye):
					flanked = true
	_flanked = _flanked + delta if flanked and player.is_crouching else 0.0
	_idle_here = _idle_here + delta if target == null else 0.0
	var go := _shots_here >= _shots_before_move or now - _hit_recent < 0.3 or _near_recent.size() >= 3 \
			or _flanked > 1.5 or _idle_here > 12.0 or (careful and not _took_cover and contact_at >= 0.0 and not (opens and not _opened))
	if careful and go:
		_took_cover = true
	if go and not _reloading and threat != Vector3.INF and _since_shot > 0.3:
		var exclude: Array[RID] = [player.get_rid()]
		for man: HumanBody in _live():
			if is_instance_valid(man):
				for sid: StringName in man.parts:
					exclude.append((man.parts[sid] as CollisionObject3D).get_rid())
		var found := Cover.find(player.get_parent() as Node3D, player.global_position, threat + Vector3.UP * 1.6, exclude, rng, spot, 11.0,
				_places() if careful else null)
		_near_recent.clear()
		_shots_here = 0
		_idle_here = 0.0
		_flanked = 0.0
		_shots_before_move = 2 + rng.randi() % 2
		if not found.is_empty() and (found.at as Vector3).distance_to(player.global_position) > 1.0:
			moving_to = found.at
			_route = (found.get("route", []) as Array).duplicate() if careful else []
			peek = found.peek
			low_cover = found.low
			_move_started = now
			_hold_action(&"crouch", false)
			return
	# At his spot: down behind it; up (or out to its edge) to shoot, or to look.
	if careful and now < _down_until:
		if not low_cover and peek != Vector3.INF and player.global_position.distance_to(spot) > 0.3:
			_go(spot, delta, false)
			return
		_stop_moving()
		_hold_action(&"crouch", true)
		return
	if not low_cover and peek != Vector3.INF and (target != null or _look_out > 0.0 or careful) and not _reloading:
		if player.global_position.distance_to(peek) > 0.3:
			_go(peek, delta, false)
		else:
			_stop_moving()
		_hold_action(&"crouch", false)
		return
	if not low_cover and peek != Vector3.INF and player.global_position.distance_to(spot) > 0.3:
		_go(spot, delta, false)
		return
	_stop_moving()
	_crouch_or_stand()


func _push(delta: float) -> void:
	_hold_action(&"crouch", _reloading)
	if _reloading:
		_stop_moving()
		return
	var goal := _threat()
	if target != null:
		goal = (target as HumanBody).global_position
	if goal == Vector3.INF:
		_stop_moving()
		return
	if goal.distance_to(player.global_position) < 4.0:
		_stop_moving()
		return
	_go(goal, delta, target == null)


## Toward `to` by the keys (the way he's facing doesn't change unless `face`): true once there.
func _go(to: Vector3, delta: float, run: bool) -> bool:
	var flat := Vector3(to.x - player.global_position.x, 0.0, to.z - player.global_position.z)
	if flat.length() < 0.35:
		return true
	if run or target == null:
		player.rotation.y = atan2(-flat.x, -flat.z)
	# Stuck on something: a step aside, then on.
	if player.global_position.distance_to(_last_pos) < 0.6 * delta:
		_stuck += delta
	else:
		_stuck = maxf(_stuck - delta, 0.0)
	_last_pos = player.global_position
	if _stuck > 0.8:
		_sidestep = 0.6
		_stuck = 0.0
		stats.stuck += 1
		_side = -_side
	if moving_to != Vector3.INF and now - _move_started > 8.0:
		moving_to = Vector3.INF  # couldn't get there: stay where he is
		spot = player.global_position
		return false
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
	var f := dir.dot(fwd)
	var r := dir.dot(right)
	_hold_action(&"move_forward", f > 0.38)
	_hold_action(&"move_back", f < -0.38)
	_hold_action(&"move_right", r > 0.38)
	_hold_action(&"move_left", r < -0.38)
	_hold_action(&"run", run)
	return false


func _stop_moving() -> void:
	moving_to = Vector3.INF
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right", &"run"]:
		_hold_action(a, false)


## Down the street, gun away, till something happens.
func _walk_in(_delta: float) -> void:
	player.rotation.y = atan2(-walk_dir.x, -walk_dir.z)
	_hold_action(&"move_forward", true)


# -- Keys -----------------------------------------------------------------------------------------

## Press or let go as a key would (InputEventAction, as the dev bridge does): the guns read their
## keys in _process.
func _act(down: bool, action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _hold_action(action: StringName, down: bool) -> void:
	if down == held.has(action):
		return
	_act(down, action)
	if down:
		held[action] = true
	else:
		held.erase(action)


## Down for three ticks, then up (a press the guns see as "just pressed").
func _tap(action: StringName) -> void:
	_act(true, action)
	_taps.append([action, 3])


func _run_taps() -> void:
	for t: Array in _taps.duplicate():
		t[1] -= 1
		if t[1] <= 0:
			_act(false, t[0])
			_taps.erase(t)


func release_all() -> void:
	for a: StringName in held.keys():
		_act(false, a)
	held.clear()
	for t: Array in _taps:
		_act(false, t[0])
	_taps.clear()
