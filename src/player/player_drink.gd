class_name PlayerDrink
extends Node
## A drink in Harlan's hand and what it does to him (#1292; numbers in config/drink.json, PlayerPurse.data()).
##
## - **At a bar** (BarService, group `bars`: a barkeep at his counter within `serve_m` over it): E asks him,
##   a tap for a whiskey, held past `hold_beer_s` a beer, past `hold_bottle_s` the bottle (the prompt says
##   which as you hold); G (PlayerWounds' shout) stands the house a round. He answers, pours, takes the coin.
## - **The glass** he sets before you (a real kit glass, meta `served_to` you): E picks it up into your left
##   hand (`take`), first person, under the camera on the held layer; fire with no gun out raises it and
##   drinks (`sip`: a sip, a shot in one, a swig from a bottle) and lowers it; E sets it down on what's in
##   front of you (the bar, a table: `set_down`), else lets it fall (`drop`: it breaks by its own glass's
##   rules); a gun drawn drops it. You hold it as long as you like, standing at the bar and listening.
## - **The dial**: what you drink goes into the blood (`gut` -> `units`) and leaves by the clock. It never
##   hides what's real (no blur, no tint): the gun sways more and settles slower (PlayerComposure,
##   WeaponViewmodel), your nerve's a little steadier round one drink, and past `body_from` your body
##   sways (the view drifts slowly) and your walk weaves (`weave`, from Player).
## In the group `claims_use` (E here isn't a shove).

signal drank(vessel: GlassProp, litres: float, units: float)
## Your glass set down (`dropped` false) or let go of (true).
signal let_go(vessel: GlassProp, dropped: bool)

var player: Player
var d: Dictionary = {}
## The glass or bottle in your hand, or null.
var vessel: GlassProp
## Alcohol in the blood and still in the stomach (drinks of ~14 g).
var units := 0.0
var gut := 0.0
## Drunk today (sips taken), and the last thing done here (&"took", &"drank", &"set", &"dropped",
## &"ordered", &"refused", &""): for the bridge and the tests.
var sips := 0
var last := &""
var last_order := {}
var _hold: Node3D
var _hand: HeldHand
var _host: Node
var _raise := 0.0
var _sip_t := -1.0  # into the current sip (s); -1 none
var _sipped := false
var _e_t := -1.0  # E held (s), -1 not
var _e_for := &""  # what the press is for: &"bar", &"glass", &"hand"
var _told_bar := false
var _clock_was := -1.0
var _t := 0.0
var _drift := Vector2.ZERO
var _day_cycle: DayCycle


func _ready() -> void:
	add_to_group(&"claims_use")
	d = PlayerPurse.data()
	Events.hours_passed.connect(_on_hours_passed)


func _n(k: String, dflt: float) -> float:
	return float(d.get(k, dflt))


func holding() -> bool:
	return vessel != null and is_instance_valid(vessel) and vessel.held and not vessel.broken


## The bar you could order at now (a barkeep at his counter over it), or null.
func bar_here() -> Node:
	if player == null or not player.is_inside_tree():
		return null
	for b in player.get_tree().get_nodes_in_group(&"bars"):
		if b.call(&"at_bar", player):
			return b
	return null


## A glass or bottle served to you (meta `served_to`), standing or knocked over, within `reach` and near the
## middle of your view: the one E would pick up.
func vessel_here() -> GlassProp:
	if player == null or not player.is_inside_tree() or holding():
		return null
	var eye := player.camera.global_position
	var fwd := -player.camera.global_basis.z
	var best: GlassProp = null
	var best_ang := _n("view_deg", 28.0)
	for n in player.get_tree().get_nodes_in_group(&"glass_props"):
		var g := n as GlassProp
		if g == null or g.broken or g.held or not g.has_meta(&"served_to") or g.get_meta(&"served_to") != player:
			continue
		var at := (g.body.global_position if g.loose else g.global_position) + Vector3.UP * 0.05
		if at.distance_to(eye) > _n("reach", 1.1) + 0.4 or Vector2(at.x - eye.x, at.z - eye.z).length() > _n("reach", 1.1):
			continue
		var ang := rad_to_deg(fwd.angle_to(at - eye))
		if ang < best_ang:
			best_ang = ang
			best = g
	return best


## E is for this: a glass in hand, one of yours to pick up, or a barkeep to ask.
func claims_use(p: Player) -> bool:
	if p != player:
		return false
	if holding():
		return true
	if player.carry != null and (player.carry.carrying() or player.carry.near_man() != null):
		return false
	return vessel_here() != null or bar_here() != null


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	_dial_step(delta)
	_body_sway(delta)
	if vessel != null and not holding():
		_lost_vessel()
	if holding() and gun_out():
		drop()  # a gun drawn: the glass goes (the left hand to the gun, or just out of it)
	_e_input(delta)
	if holding() and player.input_enabled and Input.is_action_just_pressed(&"fire") and not gun_out():
		sip()
	_sip_step(delta)
	_pose()
	_tell_bar()


## A gun of yours out in your hand (one you carry, drawn, not on its way back into the holster).
func gun_out() -> bool:
	var w := player.weapon
	return w != null and w.selected and w.drawn and player.carries(w) and not w.is_put_away()


# --- E -------------------------------------------------------------------------------------------------

func _e_input(delta: float) -> void:
	if not player.input_enabled or (player.seat != null and player.seat.seated()):
		_e_t = -1.0
		return
	if Input.is_action_just_pressed(&"shove"):
		_e_t = 0.0
		_e_for = &"hand" if holding() else (&"glass" if vessel_here() != null else (&"bar" if bar_here() != null else &""))
		if _e_for != &"hand" and player.carry != null and (player.carry.carrying() or player.carry.man_here() != null):
			_e_for = &""  # a man down by you has E first (PlayerCarry)
	elif _e_t >= 0.0 and Input.is_action_pressed(&"shove"):
		var was := _e_t
		_e_t += delta
		if _e_for == &"bar":
			for k: Array in [[_n("hold_beer_s", 0.45), "a beer"], [_n("hold_bottle_s", 1.3), "the bottle"]]:
				if was < float(k[0]) and _e_t >= float(k[0]):
					_say("E: %s (%s)" % [k[1], PlayerPurse.money(_price(&"beer" if k[1] == "a beer" else &"bottle"))], 1.0)
	elif _e_t >= 0.0:
		var held := _e_t
		_e_t = -1.0
		match _e_for:
			&"hand":
				if not give_away():
					set_down()
			&"glass":
				var v := vessel_here()
				if v != null:
					take(v)
			&"bar":
				order(&"bottle" if held >= _n("hold_bottle_s", 1.3) else (&"beer" if held >= _n("hold_beer_s", 0.45) else &"whiskey"))


func _price(kind: StringName) -> int:
	return int(((d.get("drinks", {}) as Dictionary).get(String(kind), {}) as Dictionary).get("cents", 0))


## Ask the barkeep you're at for `kind` (whiskey, beer, bottle, round): his answer ({ok, why, ...}).
func order(kind: StringName) -> Dictionary:
	var b := bar_here()
	if b == null:
		last_order = {"ok": false, "why": "no barkeep here"}
	else:
		last_order = b.call(&"order", player, kind)
	last = &"ordered" if last_order.get("ok", false) else &"refused"
	return last_order


func _tell_bar() -> void:
	var here := not holding() and bar_here() != null and player.input_enabled
	if here and not _told_bar:
		_say("E: a whiskey (%s) · hold E: beer, the bottle · G: a round" % PlayerPurse.money(_price(&"whiskey")), 3.0)
	_told_bar = here


func _say(text: String, seconds: float) -> void:
	if player.wounds:
		player.wounds.say(text, seconds)


# --- The glass in your hand ----------------------------------------------------------------------------

## Take `v` up into your left hand (a gun out goes away first).
func take(v: GlassProp) -> bool:
	if v == null or v.broken or holding():
		return false
	if player.weapon != null and player.weapon.drawn:
		player.weapon.put_away()
	if _hold == null:
		_build_hold()
	_host = v.get_parent() if v.get_parent() != null else player.get_parent()
	if v.loose:
		_host = player.get_parent()
	v.take_up(_hold, Transform3D.IDENTITY)
	vessel = v
	_raise = 0.0
	_sip_t = -1.0
	_hand.visible = true
	_fit_hand()
	last = &"took"
	if v.litres_in() <= 0.001:
		_say("It's empty", 1.5)
	return true


## A sip (a shot glass's shot in one, a swig from a bottle): raised, drunk at the top, lowered.
func sip() -> bool:
	if not holding() or _sip_t >= 0.0:
		return false
	if vessel.litres_in() <= 0.001:
		_say("It's empty", 1.5)
		return false
	_sip_t = 0.0
	_sipped = false
	return true


func _sip_step(delta: float) -> void:
	var up := maxf(_n("raise_s", 0.55), 0.05)
	if _sip_t < 0.0:
		_raise = move_toward(_raise, 0.0, delta / up)
		return
	_sip_t += delta
	_raise = move_toward(_raise, 1.0, delta / up)
	if _raise >= 1.0 and not _sipped:
		_sipped = true
		_drink_now()
	if _sipped and _sip_t > up + 0.45:
		_sip_t = -1.0


## What goes down at the top of a sip.
func _drink_now() -> void:
	if not holding():
		return
	var have := vessel.litres_in()
	var bottle := vessel.kit_id in [&"liquor_quart", &"liquor_quart_flint", &"whiskey_bottle", &"beer_bottle"]
	var take_l := _n("swig_l", 0.05) if bottle else (have if have <= _n("shot_l", 0.06) else _n("sip_l", 0.06))
	take_l = minf(take_l, have)
	vessel.set_litres(have - take_l)
	var u := take_l * units_per_l(vessel)
	gut += u
	sips += 1
	last = &"drank"
	drank.emit(vessel, take_l, u)


## Drinks of alcohol in a litre of what's in `v` (config/drink.json's `units_per_l` by its liquid).
func units_per_l(v: GlassProp) -> float:
	var liquid := String((v.definition.get("contents", {}) as Dictionary).get("liquid", ""))
	if liquid == "beer":
		return float((d.drinks.beer as Dictionary).get("units_per_l", 2.3))
	if liquid == "whiskey":
		return float((d.drinks.whiskey as Dictionary).get("units_per_l", 25.0))
	return 0.0


## E with a glass in hand: on what's in front of you, within `set_reach` and above your knees (the bar,
## a table), set down there; else let go.
func set_down() -> bool:
	if not holding():
		return false
	var at := _surface_ahead()
	if at == Vector3.INF:
		drop()
		return false
	var v := vessel
	_release()
	v.put_down(_host if _host != null and is_instance_valid(_host) else player.get_parent(), Transform3D(Basis(Vector3.UP, player.rotation.y), at + Vector3.UP * 0.003))
	last = &"set"
	let_go.emit(v, false)
	return true


## Hand the glass to the town drunk by you (#1312, TownDrunk.takes_glass): a drink stood him. True if he took it.
func give_away() -> bool:
	var f := get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk if is_inside_tree() else null
	if not holding() or f == null or f.drunk == null or not f.drunk.takes_glass(player):
		return false
	var v := vessel
	_release()
	last = &"given"
	let_go.emit(v, false)
	v.queue_free()  # it's off you and down him before you've let go of it
	f.drunk.answer(&"drink")
	return true


## Let go of it in the air: it falls from your hand with your way on it.
func drop() -> void:
	if not holding():
		return
	var v := vessel
	_release()
	v.let_fall(player.get_parent(), player.velocity * 0.8 + Vector3.DOWN * 0.3)
	last = &"dropped"
	let_go.emit(v, true)


func _release() -> void:
	vessel = null
	_sip_t = -1.0
	_raise = 0.0
	if _hand:
		_hand.visible = false


## Taken from you some other way (shot out of your hand, freed): the hand's empty.
func _lost_vessel() -> void:
	vessel = null
	if _hand:
		_hand.visible = false


## The top of what's in front of you within `set_reach`, above your knees (INF: nothing there).
func _surface_ahead() -> Vector3:
	var fwd := -player.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var eye := player.camera.global_position
	var feet := player.global_position.y
	for k in [0.6, 0.45, 0.8, 0.3]:
		var over := player.global_position + fwd * _n("set_reach", 0.85) * float(k)
		var q := PhysicsRayQueryParameters3D.create(Vector3(over.x, eye.y + 0.1, over.z), Vector3(over.x, feet + 0.3, over.z), Layers.WORLD)
		q.exclude = [player.get_rid()]
		var hit := World.space(player).intersect_ray(q)
		if hit.is_empty() or (hit.normal as Vector3).y < 0.8:
			continue
		var p: Vector3 = hit.position
		if p.y > feet + 0.45 and p.y < eye.y - 0.15:
			return p
	return Vector3.INF


func _build_hold() -> void:
	_hold = Node3D.new()
	_hold.name = "DrinkHold"
	player.camera.add_child(_hold)
	_hand = HeldHand.new(false)
	_hand.name = "DrinkHand"
	_hold.add_child(_hand)
	_hand.shoulder = ShotgunViewmodel.SHOULDER_L
	_hand.elbow_pole = ShotgunViewmodel.ELBOW_POLE_L
	for mi in _hand.find_children("*", "MeshInstance3D", true, false):
		Layers.hold(mi as MeshInstance3D)
	_hand.visible = false
	_hold.position = _vec("rest", Vector3(-0.17, -0.25, -0.36))


## The hand round the glass: palm to it from its left, fingers forward and wrapped round, thumb up.
func _fit_hand() -> void:
	var size := PropKit.vec(vessel.definition.get("size", [0.06, 0.1, 0.06]))
	var r := maxf(size.x, size.z) * 0.5
	_hand.position = Vector3(-r - 0.012, minf(size.y * 0.4, 0.09), 0.025)
	_hand.basis = Basis.IDENTITY
	for f: String in HeldHand.FINGERS:
		_hand.wrap(f, r + 0.005)
	_hand.thumb_pose(Vector3(0.0, 0.0, 0.0), 20.0, 15.0)
	for mi in _hand.find_children("*", "MeshInstance3D", true, false):
		Layers.hold(mi as MeshInstance3D)


func _vec(k: String, dflt: Vector3) -> Vector3:
	var a: Array = d.get(k, [])
	return Vector3(float(a[0]), float(a[1]), float(a[2])) if a.size() == 3 else dflt


## The glass where your hand has it: low at your left, or raised and tipped at your mouth; your body's
## steps ride it as they do the gun (PlayerMotion's hand_pos).
func _pose() -> void:
	if _hold == null:
		return
	var k := smoothstep(0.0, 1.0, _raise)
	var ride := player.motion.hand_pos if player.motion else Vector3.ZERO
	_hold.position = _vec("rest", Vector3(-0.17, -0.25, -0.36)).lerp(_vec("mouth", Vector3(-0.03, -0.07, -0.13)), k) + ride
	var tip := 75.0 if holding() and vessel.kit_id == &"shot_glass" else (85.0 if holding() and vessel.kit_id != &"schooner" else 55.0)
	# Tipped more as it empties (the last of a bottle goes up high).
	if holding() and vessel.full_litres() > 0.0:
		tip += 25.0 * (1.0 - clampf(vessel.litres_in() / vessel.full_litres(), 0.0, 1.0))
	_hold.rotation_degrees = Vector3(tip * k, 8.0 * k, -6.0 * k)


# --- The dial -----------------------------------------------------------------------------------------

func _hours(delta: float) -> float:
	if _day_cycle == null and player.is_inside_tree():
		_day_cycle = player.get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if _day_cycle == null or not is_instance_valid(_day_cycle) or _day_cycle.held:
		_clock_was = -1.0
		return delta / maxf(_n("held_hour_s", 112.5), 0.01)
	var now := float(_day_cycle.day) * 24.0 + float(_day_cycle.time_of_day)
	var h := now - _clock_was if _clock_was >= 0.0 else 0.0
	_clock_was = now
	return h if h > 0.0 and h < 0.25 else 0.0  # (a jump of the clock comes by hours_passed)


func _dial_step(delta: float) -> void:
	pass_hours(_hours(delta))


## `h` game hours of drink going into the blood and out of it.
func pass_hours(h: float) -> void:
	if h <= 0.0 or (gut <= 0.0 and units <= 0.0):
		return
	var moved := gut * (1.0 - pow(0.5, h / maxf(_n("absorb_h", 0.35), 0.001)))
	gut -= moved
	units += moved
	if gut < 0.0005:
		units += gut
		gut = 0.0
	units = maxf(units - _n("burn_per_h", 1.0) * h, 0.0)


func _on_hours_passed(hours: float, _why: StringName) -> void:
	# A sleep or a black-out: it's all in and burnt off by the hour.
	units += gut
	gut = 0.0
	units = maxf(units - _n("burn_per_h", 1.0) * hours, 0.0)
	_clock_was = -1.0


func drunk() -> bool:
	return units >= _n("drunk_at", 4.0)


## How many times as much the gun wanders (PlayerComposure.sway_scale).
func sway_scale() -> float:
	return 1.0 + _n("sway_per", 0.06) * units + _n("sway_more", 0.18) * maxf(units - _n("sway_from", 2.5), 0.0)


## How many times as long the aim takes to settle (WeaponViewmodel).
func settle_scale() -> float:
	return 1.0 + _n("settle_per", 0.12) * units


## The nerve: rattled and a flinch's jolt times this (under 1 round one drink).
func nerve_scale() -> float:
	var at := _n("courage_at", 1.0)
	var to := _n("courage_to", 3.0)
	var k := clampf(units / maxf(at, 0.01), 0.0, 1.0) if units <= at else clampf(1.0 - (units - at) / maxf(to - at, 0.01), 0.0, 1.0)
	return lerpf(1.0, _n("courage", 0.75), k)


## How far past `body_from` (units over it, 0 under).
func _over_body() -> float:
	return maxf(units - _n("body_from", 3.0), 0.0)


## Your body swaying: the view drifts, slowly (a turn of the head you'd make yourself, not a shake).
func _body_sway(_delta: float) -> void:
	var over := _over_body()
	var f := _n("body_hz", 0.13) * TAU
	var amp := _n("body_deg", 0.9) * over
	var now := Vector2(sin(_t * f) + 0.5 * sin(_t * f * 1.7 + 1.3), 0.5 * sin(_t * f * 0.8 + 2.1)) * amp
	if player.input_enabled and (over > 0.0 or _drift != Vector2.ZERO):
		player.add_look(now - _drift, false)
	_drift = now if player.input_enabled else _drift


## The way you push, turned a little (your walk weaving), from Player's movement.
func weave(wish: Vector3) -> Vector3:
	var over := _over_body()
	if over <= 0.0 or wish.length() < 0.05:
		return wish
	var ang := deg_to_rad(_n("weave_deg", 4.0) * over) * sin(_t * 0.9 + 0.4 * sin(_t * 2.3))
	return wish.rotated(Vector3.UP, ang)


func describe() -> String:
	return "%.2f units (%.2f to come)%s%s" % [units, gut, ", drunk" if drunk() else "", ", holding " + String(vessel.kit_id) if holding() else ""]


func report() -> Dictionary:
	return {"units": snappedf(units, 0.001), "gut": snappedf(gut, 0.001), "drunk": drunk(), "sips": sips, "last": String(last),
			"holding": String(vessel.kit_id) if holding() else "", "litres": snappedf(vessel.litres_in(), 0.001) if holding() else 0.0,
			"raise": snappedf(_raise, 0.01), "sway": snappedf(sway_scale(), 0.001), "settle": snappedf(settle_scale(), 0.001),
			"nerve": snappedf(nerve_scale(), 0.001), "order": last_order}


func save_dict() -> Dictionary:
	return {"units": units, "gut": gut}


func load_dict(sd: Dictionary) -> void:
	units = float(sd.get("units", 0.0))
	gut = float(sd.get("gut", 0.0))
	_clock_was = -1.0
