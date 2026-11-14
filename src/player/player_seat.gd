class_name PlayerSeat
extends Node
## Sitting in a kit chair (#766, No Law step 2: Harlan sat at the saloon yard's card table, unarmed,
## "sitting at a table and has no gun yet so he can't do anything at all", Sean 2026-11-09).
##
## E by a free kit chair (its seat within PlayerTuning.seat_reach, flat, and within seat_view_deg of
## your view) sits you in it: your weight on its seat (KitProp.sit, as a man's: a kick has it to
## slide out from under you), your eyes down to seat_eye_height, facing the way the chair faces.
## Sat, you look round (at most seat_turn_deg either way of the chair) but don't walk, crouch or
## jump, and no gun comes out (PlayerWounds holds your hands, `why_not` says why). E again stands
## you up, a step clear of the chair, unless something holds you there (`hold`: an act; E then
## says its reason). The chair going from under you (kicked, shot to pieces, a blast) drops you
## to the floor: down flat (the crawl) and still for seat_fall_s, then up as from a crawl.
## The player isn't a HumanBody: KitProp.sit takes any Node3D (80 kg when it has no `total_mass`),
## and its `went_loose` is what tells us the chair's gone (its `_unseat` only fells a HumanBody).
## In the group `claims_use`, so E here isn't a shove (PlayerShove._planting).

signal sat(chair: KitProp)
signal stood(chair: KitProp)
## The chair went from under you (kicked, broken, blown away): you're on the floor.
signal dumped(chair: KitProp)

var player: Player
## The chair you're in, or null.
var chair: KitProp
## Who's holding you in it (reason -> why, in plain words): E won't stand you while any is set.
var holds := {}
## On the floor after the chair went (s left before you can move).
var down_t := 0.0
## The last thing E did here (&"sat", &"stood", &"held", &""): for the bridge and the tests.
var last := &""
var _told := false  # "E: sit" said for the chair you're by
var _told_ago := INF  # since "E: sit" was last said (s): not again within SIT_TOLD_GAP
## "E: sit down" no oftener than this (s) (#773's playtest: it flashed five times walking past the chairs).
const SIT_TOLD_GAP := 6.0
var _near: KitProp
var _stand_soon := false


func _ready() -> void:
	add_to_group(&"claims_use")


func seated() -> bool:
	return chair != null and is_instance_valid(chair) and chair.seated == player


## Hold him in his seat (an act: the card game's last hand, a man with a gun on you): E says `why`.
func hold(reason: StringName, why := "") -> void:
	holds[reason] = why


func let_go(reason: StringName) -> void:
	holds.erase(reason)


func held() -> bool:
	return not holds.is_empty()


## The free kit chair you'd sit in now (by it and looking its way), or null.
func chair_here() -> KitProp:
	if player == null or not player.is_inside_tree() or player.is_crawling or player.ladder != null:
		return null
	var t := player.tuning
	var c := Seating.free_chair_near(player.get_tree(), player.global_position + Vector3.UP * 0.47, t.seat_reach + 0.5)
	if c == null:
		return null
	var to := c.seat_position() - player.global_position
	to.y = 0.0
	if to.length() > t.seat_reach or absf(c.seat_position().y - 0.47 - player.global_position.y) > 0.6:
		return null
	var fwd := player.get_forward()
	fwd.y = 0.0
	if to.length() > 0.3 and rad_to_deg(fwd.angle_to(to)) > t.seat_view_deg:
		return null
	return c


## E is for this: by a free chair, or sat (to stand, or to be told you can't).
func claims_use(p: Player) -> bool:
	return p == player and (seated() or down_t > 0.0 or chair_here() != null)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	down_t = maxf(down_t - delta, 0.0)
	if _stand_soon and seated():
		stand()
	if chair != null and not seated():
		_lost_chair()
	var here := null if seated() else chair_here()
	if here != _near:
		_near = here
		_told = false
	_told_ago += delta
	if here != null and not _told and player.wounds and player.input_enabled:
		_told = true
		if _told_ago > SIT_TOLD_GAP:
			_told_ago = 0.0
			player.wounds.say("E: sit down", 1.5)
	if player.input_enabled and Input.is_action_just_pressed(&"shove"):
		use()


## What E does here: sit in the chair you're by, or stand up out of yours.
func use() -> StringName:
	if seated():
		if held():
			for why: String in holds.values():
				if why != "" and player.wounds:
					player.wounds.say(why, 2.0)
					break
			last = &"held"
			return last
		stand()
		return last
	var c := chair_here()
	if c != null and sit(c):
		return last
	return &""


## Into `c` (true if you're in it now): your weight on its seat, facing the way it faces.
func sit(c: KitProp) -> bool:
	if c == null or not is_instance_valid(c) or c.loose or (c.seated != null and c.seated != player):
		return false
	if not c.sit(player):
		return false
	chair = c
	if not c.went_loose.is_connected(_on_chair_went):
		c.went_loose.connect(_on_chair_went.bind(c))
	player.velocity = Vector3.ZERO
	player.global_position = Seating.spot(c)
	var out := c.global_basis.z
	out.y = 0.0
	if out.length() > 0.01:
		# Facing out of the chair (its +z): the player looks down his -z.
		player.rotation.y = atan2(-out.x, -out.z)
	player.sit_down()
	if player.weapon:
		player.weapon.put_away()
	last = &"sat"
	sat.emit(c)
	if player.wounds:
		player.wounds.say("E: stand up", 1.5)
	return true


## Up out of it, a step clear (behind it, or to a side with room). Asked outside the physics tick
## (the bridge, a tool) it's done on the next (where the room's looked for is a physics query).
func stand() -> void:
	if not Engine.is_in_physics_frame():
		_stand_soon = true
		return
	_stand_soon = false
	var c := chair
	if c != null and is_instance_valid(c):
		if c.went_loose.is_connected(_on_chair_went):
			c.went_loose.disconnect(_on_chair_went)
		if c.seated == player:
			c.leave()
		player.global_position = _clear_spot(c)
	chair = null
	player.stand_up_from_seat()
	last = &"stood"
	stood.emit(c)


## Where to stand clear of the chair: behind it, else to either side, else where you are.
func _clear_spot(c: KitProp) -> Vector3:
	var at := Seating.spot(c)
	var out := c.global_basis.z
	out.y = 0.0
	out = out.normalized()
	var side := out.cross(Vector3.UP)
	for off: Vector3 in [-out * 0.6, side * 0.6, -side * 0.6, -out * 0.9]:
		var p := at + off
		if _room_at(p):
			return p
	return at


func _room_at(at: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = player.tuning.radius * 0.9
	shape.height = player.tuning.stand_height - 0.2
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), at + Vector3.UP * (shape.height * 0.5 + 0.1))
	q.exclude = [player.get_rid()]
	q.collision_mask = player.collision_mask
	return World.space(player).intersect_shape(q, 1).is_empty()


func _on_chair_went(c: KitProp) -> void:
	if chair == c:
		_lost_chair()


## The chair's gone from under you: down on the floor where you sat.
func _lost_chair() -> void:
	var c := chair
	if c != null and is_instance_valid(c) and c.went_loose.is_connected(_on_chair_went):
		c.went_loose.disconnect(_on_chair_went)
	chair = null
	holds.clear()
	down_t = player.tuning.seat_fall_s
	player.dumped_from_seat()
	last = &"dumped"
	dumped.emit(c)


## Each tick sat: where the chair is (it may have slid), the view kept within the turn of it.
## True while you're in it (the walk is skipped).
func step(_delta: float) -> bool:
	if not seated():
		return false
	player.velocity = Vector3.ZERO
	player.global_position = Seating.spot(chair)
	clamp_turn()
	return true


## The view kept within seat_turn_deg of the way the chair faces (the Player calls it on each look).
func clamp_turn() -> void:
	if not seated():
		return
	var out := chair.global_basis.z
	out.y = 0.0
	if out.length() < 0.01:
		return
	var face := atan2(-out.x, -out.z)
	var off := wrapf(player.rotation.y - face, -PI, PI)
	var most := deg_to_rad(player.tuning.seat_turn_deg)
	if absf(off) > most:
		player.rotation.y = face + clampf(off, -most, most)


func report() -> Dictionary:
	return {"seated": seated(), "chair": String(chair.name) if seated() else "", "held": holds.keys().map(func(k: StringName) -> String: return String(k)),
			"down_s": snappedf(down_t, 0.01), "last": String(last), "by_chair": String(chair_here().name) if chair_here() else ""}
