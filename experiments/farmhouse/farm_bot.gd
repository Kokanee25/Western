extends RefCounted
## The farmhouse's scripted player (issue #520's measures): goes in one way, fights by the gunfight
## lab's scripted player (its eyes by the gang's rules, its hand, the keys: player_bot.gd, used for
## those alone, not its styles), cuts the rancher loose (E held by him) and takes him out the way
## he came. Seeded: the same seed, the same run.
##
## Ways in:
##   front  - up the lane, onto the porch, in at the front door, through the front room to the
##            bedroom's door.
##   breach - round the yard to the house's west wall (the front room's; as built: the world's
##            east), a stick planted chest high, back off, in through the hole when it's gone.
##   back   - wide round the knoll to the back, crouched (quiet), in at the lean-to's back door,
##            through the kitchen and the front room to the bedroom.

const Bot := preload("res://experiments/gunfight_lab/player_bot.gd")
const TICK := 0.12

var bot
var player: Player
var mission: FarmhouseMission
var way := "front"
var rng := RandomNumberGenerator.new()
var phase := "in"
var route: Array[Vector3] = []
var out_route: Array[Vector3] = []
var stats := {"phase_at": {}, "planted": -1.0, "blast": -1.0, "freed": -1.0}

var _t := 0.0
var _look_t := 0.0
var _hold_e := 0.0
var _wait := 0.0
var _crouch := false
var _stuck := 0.0
var _last := Vector3.ZERO
var _side := 1.0
var _sidestep := 0.0
var _went_off := false
var _sticks0 := 0


func setup(p: Player, m: FarmhouseMission, how: String, seed_value: int, aim_degrees := 1.0) -> void:
	player = p
	mission = m
	way = how
	rng.seed = seed_value * 104729 + 3
	bot = Bot.new()
	var men: Array = []  # untyped: the gunfight lab's bot asks `in` it of anyone who fires
	men.append_array(m.men)
	bot.setup(p, men, "hold", seed_value, "revolver", aim_degrees)
	Events.exploded.connect(func(_at: Vector3, _kg: float) -> void: _went_off = true)
	route = _route_in()
	out_route = _route_out()
	_crouch = way == "back" or way == "breach"


func teardown() -> void:
	bot.teardown()


func _p(local: Vector3) -> Vector3:
	return Farmhouse.at(local)


func _g(x: float, z: float) -> Vector3:
	return Farmhouse.on_ground(x, z)


func _place(name: StringName) -> Vector3:
	return mission._town().places.at(name)


## The way in, as points (the house's own space; FORMAT.md).
func _route_in() -> Array[Vector3]:
	var f := Farmhouse.FLOOR
	var r: Array[Vector3] = []
	match way:
		"front":
			r = [_place(&"farm_lane"), _place(&"farm_steps"), _place(&"farm_porch"), _place(&"farm_door"), _place(&"farm_room"),
					_place(&"farm_room_e"), _place(&"farm_bedroom_door_w"), _place(&"farm_bedroom_door"), _place(&"farm_bedroom")]
		"breach":
			# Up the draw west of the knoll (the house's east as built), out of the porch's sight, round
			# behind, to the kitchen's back wall (the lean-to's), west of its window.
			r = _the_draw()
			r.append_array([_g(4.0, 13.0), _g(2.9, 8.5)])
		"back":
			r = _the_draw()
			r.append_array([_g(4.4, 12.0), _place(&"farm_back"), _place(&"farm_back_steps"),
					_place(&"farm_back_door"), _place(&"farm_kitchen_e"), _place(&"farm_kitchen"), _place(&"farm_kitchen_door"),
					_place(&"farm_room_back"), _place(&"farm_room_back_e"), _place(&"farm_room_e"), _place(&"farm_bedroom_door_w"),
					_place(&"farm_bedroom_door"), _place(&"farm_bedroom")])
	return r


## The quiet way round: off the road short of the range's targets, north wide of the house past the
## low rise, along behind it (the porch faces the road: behind its man) and down on the back.
func _the_draw() -> Array[Vector3]:
	var r: Array[Vector3] = [_w(50.0, -14.0), _w(52.0, -72.0), _w(88.0, -72.0), _w(94.0, -64.0)]
	return r


func _w(x: float, z: float) -> Vector3:
	return Vector3(x, TownLayout.ground_height(x, z), z)


## After the breach: in through the hole in the kitchen's back wall, to the bedroom.
func _route_through_hole() -> Array[Vector3]:
	var f := Farmhouse.FLOOR
	return [_p(Vector3(2.9, f, 7.2)), _place(&"farm_kitchen"), _place(&"farm_kitchen_door"), _place(&"farm_room_back"),
			_place(&"farm_room_back_e"), _place(&"farm_room_e"), _place(&"farm_bedroom_door_w"), _place(&"farm_bedroom_door"),
			_place(&"farm_bedroom")]


## Out: back the way he came, to the lane and on down to the road.
func _route_out() -> Array[Vector3]:
	match way:
		"back":
			return [_place(&"farm_bedroom_door"), _place(&"farm_room_e"), _place(&"farm_room_back_e"), _place(&"farm_room_back"),
					_place(&"farm_kitchen_door"), _place(&"farm_kitchen"), _place(&"farm_kitchen_e"), _place(&"farm_back_door"),
					_place(&"farm_back_steps"), _place(&"farm_back"), _g(4.4, 16.0), _g(4.4, 30.0), _g(-10.0, 48.0)]
		"breach":
			var f := Farmhouse.FLOOR
			return [_place(&"farm_bedroom_door"), _place(&"farm_room_e"), _place(&"farm_room_back_e"), _place(&"farm_room_back"),
					_place(&"farm_kitchen_door"), _place(&"farm_kitchen"), _p(Vector3(2.9, f, 7.2)), _g(2.9, 10.0), _g(4.4, 16.0), _g(4.4, 30.0), _g(-10.0, 48.0)]
	return [_place(&"farm_bedroom_door"), _place(&"farm_room_e"), _place(&"farm_room"), _place(&"farm_door"), _place(&"farm_porch"),
			_place(&"farm_steps"), _place(&"farm_lane"), _place(&"road_farm")]


func _phase(p: String) -> void:
	phase = p
	stats.phase_at[p] = snappedf(_t, 0.01)


func tick(delta: float, t: float) -> void:
	_t = t
	if not player.wounds.physiology.is_conscious():
		bot.release_all()
		return
	# The gunfight lab's eyes and hand (not its styles: he moves himself here).
	bot.now = t
	bot._since_shot += delta
	bot._run_taps()
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = TICK
		bot._look(TICK)
	var dyn := phase in ["plant", "lit"]
	# His gun out once he's near the house or it's started (not walking out of town with it drawn).
	var near := player.global_position.distance_to(Farmhouse.at(Vector3(4.5, 0.0, 3.8))) < 40.0 or mission.alarm_t >= 0.0
	if not dyn and near and not bot._gun_out():
		bot._draw()
	bot._pick_target()
	# The guard with his gun on the rancher: him first, if he can be seen (the pause he gives you).
	var g := mission.guard
	if g != null and is_instance_valid(g) and g.menace != null and is_instance_valid(g.body) and g.body.physiology.alive \
			and bot._k(g.body).seen and bot.target != g.body:
		bot.target = g.body
		bot._on_target = 0.0
		bot._settle = rng.randf_range(0.2, 0.4)
	var armed: bool = not dyn and bot._gun_out()
	if armed:
		bot._handle_gun(delta)
	var shooting: bool = bot.target != null and armed and bot._k(bot.target).seen
	if shooting:
		bot._aim(delta)
	match phase:
		"in":
			if shooting and not bot._reloading:
				_stop()
			elif _follow(route, delta):
				if way == "breach":
					_phase("plant")
				else:
					_phase("rescue")
		"plant":
			_plant(delta)
		"lit":
			_lit(delta)
		"through":
			if shooting and not bot._reloading:
				_stop()
			elif _follow(route, delta):
				_phase("rescue")
		"rescue":
			_rescue(delta, shooting)
		"out":
			if shooting and not bot._reloading and player.global_position.distance_to(mission.hostage.global_position) < 6.0:
				_stop()
			elif _follow(out_route, delta):
				_phase("clear")
				_stop()
		"clear":
			_stop()
	# Crouched (quiet, low) once he's within 35 m of the house on a quiet way in.
	var close := player.global_position.distance_to(Farmhouse.at(Vector3(4.5, 0.0, 3.8))) < 45.0
	bot._hold_action(&"crouch", _crouch and close and not shooting and not phase in ["lit", "out", "clear"])


## The stick out, aimed chest high at the wall in front, E held till it's set, let go to light it,
## then back off.
func _plant(delta: float) -> void:
	_stop()
	var d := player.dynamite()
	if player.weapon != d:
		player.select_weapon(d)
		return
	if not d.drawn:
		return
	var wall := _p(Vector3(2.9, 0.0, 7.6))
	wall.y = player.global_position.y + 1.2
	_look_at(wall)
	if _hold_e <= 0.0 and d.plant_at.is_empty():
		return  # not ready in hand yet, or nothing in reach: E would be a shove
	if _hold_e <= 0.0:
		_sticks0 = d.sticks
	_hold_e += delta
	bot._hold_action(&"shove", _hold_e < 1.2)
	if _hold_e > 1.3:
		if d.sticks < _sticks0 or d.planted != null:
			stats.planted = snappedf(_t, 0.01)
			_phase("lit")
			route = [_g(2.9, 12.0), _g(6.0, 17.0)]
		else:
			_hold_e = 0.0  # it didn't take: again


func _lit(delta: float) -> void:
	if not _went_off:
		_follow(route, delta, true)
		return
	if stats.blast < 0.0:
		stats.blast = snappedf(_t, 0.01)
		_wait = 1.5  # the dust, a breath
		_stop()
	_wait -= delta
	if _wait <= 0.0:
		player.select_weapon(player.revolver())
		route = _route_through_hole()
		_phase("through")


func _rescue(delta: float, shooting: bool) -> void:
	var h := mission.hostage
	if h == null or not is_instance_valid(h):
		return
	if not mission.hostage_brain.tied:
		stats.freed = snappedf(_t, 0.01)
		bot._hold_action(&"shove", false)
		_phase("out")
		return
	if shooting and not bot._reloading:
		_stop()
		bot._hold_action(&"shove", false)
		return
	var to := h.global_position - player.global_position
	to.y = 0.0
	if to.length() > mission.tuning.free_reach - 0.3:
		_follow([h.global_position], delta)
		return
	_stop()
	bot._hold_action(&"shove", true)


## Along `way` by the movement keys, facing where he goes (unless he's shooting); true at its end.
func _follow(way_pts: Array[Vector3], delta: float, run := false) -> bool:
	while not way_pts.is_empty() and _flat(way_pts[0]).length() < 0.45:
		way_pts.pop_front()
	if way_pts.is_empty():
		_stop()
		return true
	var flat := _flat(way_pts[0])
	if bot.target == null or not bot._gun_out():
		player.rotation.y = atan2(-flat.x, -flat.z)
	if player.global_position.distance_to(_last) < 0.5 * delta:
		_stuck += delta
	else:
		_stuck = maxf(_stuck - delta, 0.0)
	_last = player.global_position
	if _stuck > 0.5 and _stuck - delta <= 0.5:
		bot._tap(&"jump")  # a step up into a hole's sill, a broken board
	if _stuck > 1.2:
		_sidestep = 0.5
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
	player.add_look(Vector2(0.0, pitch - player.get_pitch_degrees()), false)
