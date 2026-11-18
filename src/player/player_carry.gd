class_name PlayerCarry
extends Node
## Taking a downed man with you (#1057, No Law: Harlan gets Earl up the street to the doctor's): E
## by a man down (limp or lying, alive, wounded or dead; his collar within PlayerTuning.carry_reach
## and within carry_view_deg of your view) takes him by the collar, and he comes along behind you,
## dragged: his own body (the ragdoll, HumanBody.drag_toward, as OutlawBrain's rescue drags a
## friend), his wounds still bleeding where they are, the floor smeared and dripped on by them
## (WoundSigns), and what's on his collar comes off on your hands and cuffs (`blood_on_you`).
## Dragging, not a fireman's carry: what reads best for its cost (a ragdoll on your shoulder in
## first person would sit in your view and fight your capsule), and honest: it's how one man moves
## a dead weight up a street.
##
## While you have him: a walk at carry_speed (no run, no jump), no gun (PlayerWounds holds your
## hands: busy_why), and E lets go (or bangs on a door you're at: PlayerKnock has it then). He's let
## go if you're hit, go down, sit, take a ladder, if he comes up (not down any more), or if he's
## caught on something and comes loose (carry_tear_m from your hands). In the group `claims_use`,
## so E here isn't a shove.
## Reusable: any act asks `carrying(man)`; `took` and `let_go` say when.

signal took(man: HumanBody)
signal let_go(man: HumanBody, why: StringName)

var player: Player
## The man you have by the collar, or null.
var him: HumanBody
## How much of his blood is on your hands and cuffs (WoundSigns prints, 0 to PRINTS_PER_HAND): the
## most it's come to while you had him. Stays (it doesn't wash off by itself).
var blood_on_you := 0.0
## Metres you've dragged him (flat), this time and all told.
var dragged_m := 0.0
var dragged_total_m := 0.0
## The last thing E did here (&"took", &"let_go", &"") and why he was last let go.
var last := &""
var last_why := &""
var _from := Vector3.ZERO
var _told_for: HumanBody
var _told_ago := INF
var _wounds_n := 0
const TOLD_GAP := 6.0
const LOOK_EVERY := 0.25
var _look_t := 0.0
var _near: HumanBody


## The man down by you as last looked for (a few times a second): for what asks every tick.
func near_man() -> HumanBody:
	return _near if _near != null and is_instance_valid(_near) else null


func _ready() -> void:
	add_to_group(&"claims_use")


func carrying(man: HumanBody = null) -> bool:
	if him == null or not is_instance_valid(him):
		return false
	return man == null or man == him


## A man down by you that E would take (his collar in reach, him in front of you), or null.
func man_here() -> HumanBody:
	if player == null or not player.is_inside_tree() or player.is_crawling or player.ladder != null:
		return null
	if player.seat != null and player.seat.seated():
		return null
	var t := player.tuning
	var fwd := player.get_forward()
	fwd.y = 0.0
	fwd = fwd.normalized()
	var best: HumanBody = null
	var best_d := INF
	for n: Node in player.get_tree().get_nodes_in_group(&"people"):
		var m := n as HumanBody
		if m == null or not is_down(m) or (m.dragged_by != null and m.dragged_by != player):
			continue
		var at := collar(m)
		var to := at - player.global_position
		if absf(to.y) > 1.6:
			continue
		to.y = 0.0
		var d := to.length()
		if d > t.carry_reach or d >= best_d:
			continue
		if d > 0.5 and rad_to_deg(fwd.angle_to(to / d)) > t.carry_view_deg:
			continue
		best = m
		best_d = d
	return best


## Down: on the floor (the ragdoll, or lying posed), not getting up, not a man standing.
static func is_down(m: HumanBody) -> bool:
	return m != null and is_instance_valid(m) and m.is_inside_tree() and (m.limp or m.prone) and not m.rising


## Where you take hold of him: his neck (his chest if he has none left).
static func collar(m: HumanBody) -> Vector3:
	for sid: StringName in [&"neck", &"chest"]:
		var n := m.parts.get(sid) as Node3D
		if n != null:
			return n.global_position
	return m.global_position


## E is for this: you have a man (to let him go), or one's down by you.
func claims_use(p: Player) -> bool:
	return p == player and (carrying() or man_here() != null)


## How fast you go with him, a share of your walk (1 without him).
func pace(wish := Vector3.ZERO) -> float:
	if not carrying() or player == null:
		return 1.0
	var base := clampf(player.tuning.carry_speed / maxf(player.tuning.walk_speed, 0.1), 0.05, 1.0)
	# He's a load: caught (a chair over his legs, a step's edge) and lagging, he holds you; you don't
	# walk away from him, you stand and haul till he comes (#1057: the card table's broken chair on
	# Earl's legs; CI's run caught him on the walk's steps and tore him loose). Toward him you go free.
	var to := collar(him) - player.global_position
	to.y = 0.0
	var away := wish.length() < 0.01 or to.length() < 0.01 or wish.normalized().dot(to.normalized()) < 0.2
	if not away:
		return base
	return base * clampf(1.0 - (_lag - LAG_FREE) / LAG_SPAN, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_told_ago += delta
	if carrying():
		_hold(delta)
	elif him != null:
		_drop(&"gone")
	if player.input_enabled and Input.is_action_just_pressed(&"shove"):
		use()
		_look_t = 0.0
		return
	# Looked for a few times a second, not every tick (it's a pass over everyone).
	_look_t -= delta
	if _look_t > 0.0:
		return
	_look_t = LOOK_EVERY
	_near = null if carrying() else man_here()
	var here := _near
	if here != _told_for:
		_told_for = here
		if here != null and _told_ago > TOLD_GAP and player.wounds:
			_told_ago = 0.0
			player.wounds.say("E: take him by the collar", 1.5)


## What E does here: let him go (unless you're at a door: PlayerKnock bangs on it), or take the man
## down by you.
func use() -> StringName:
	if carrying():
		if player.knock != null and not player.knock.door_here().is_empty():
			return &""
		_drop(&"you")
		return last
	var m := man_here()
	if m != null:
		take(m)
		return last
	return &""


## Take `m` by the collar (true if you have him).
func take(m: HumanBody) -> bool:
	if m == null or not is_down(m) or (m.dragged_by != null and m.dragged_by != player):
		return false
	if carrying():
		_drop(&"another")
	him = m
	him.dragged_by = player
	_tear_t = 0.0
	_lag = 0.0
	dragged_m = 0.0
	_from = player.global_position
	_wounds_n = _wound_count()
	if player.weapon:
		player.weapon.put_away()
	last = &"took"
	if player.wounds:
		player.wounds.say("E: let him go", 1.5)
	Events.deed.emit(player, &"carry", m, collar(m))
	took.emit(m)
	return true


## Let him go (`why`: you, hit, down, ...).
func drop(why := &"you") -> void:
	if carrying():
		_drop(why)


func _drop(why: StringName) -> void:
	var m := him
	him = null
	if m != null and is_instance_valid(m) and m.dragged_by == player:
		m.dragged_by = null
	last = &"let_go"
	last_why = why
	if m != null and is_instance_valid(m):
		let_go.emit(m, why)


## Each tick with him: why you'd lose him, then him hauled after your hands, his blood on them.
func _hold(delta: float) -> void:
	var why := _lose_why()
	if why != &"":
		_drop(why)
		return
	him.wake()  # full ticks while you have him (PeopleTick's bands)
	him.dragged_by = player
	var fwd := player.get_forward()
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	# Your hands behind you at your hip, his collar in them.
	var hands := player.global_position - fwd * player.tuning.carry_hold_back + Vector3.UP * player.tuning.carry_hold_up
	him.drag_toward(hands, delta)
	_lift(delta)
	_lag = collar(him).distance_to(hands)
	var step := Vector2(player.global_position.x - _from.x, player.global_position.z - _from.z).length()
	dragged_m += step
	dragged_total_m += step
	_from = player.global_position
	var signs := him.signs_now()
	if signs != null:
		blood_on_you = maxf(blood_on_you, signs.blood_on_me(collar(him), WoundSigns.ON_COLLAR))


## Up a step or onto a walk: what of him is below the floor you stand on is drawn up to it (hauled
## by the collar his hips come up over a riser's edge; HumanBody.drag_toward moves his hips flat
## and they caught on the doctor's steps, #1057).
func _lift(delta: float) -> void:
	if not him.limp:
		return
	# His legs come after his hips: hauled by the collar a man's heels drag, they don't hold (with only
	# his trunk towed, Earl's feet under the card table held him there, #1057).
	var pelvis := him.parts.get(&"pelvis") as RigidBody3D
	if pelvis != null:
		var flat := Vector3(pelvis.linear_velocity.x, 0.0, pelvis.linear_velocity.z)
		for sid: StringName in LEGS:
			var rb := him.parts.get(sid) as RigidBody3D
			if rb == null:
				continue
			var v := rb.linear_velocity
			rb.linear_velocity = v.lerp(Vector3(flat.x, v.y, flat.z), clampf(delta * 8.0, 0.0, 1.0))
			rb.sleeping = false
	var floor_y := player.global_position.y
	for sid: StringName in LIFTED:
		var rb := him.parts.get(sid) as RigidBody3D
		if rb == null:
			continue
		var under := floor_y + 0.05 - rb.global_position.y
		if under <= 0.0:
			continue
		var v := rb.linear_velocity
		v.y = maxf(v.y, minf(under * 6.0, 1.6))
		rb.linear_velocity = rb.linear_velocity.lerp(v, clampf(delta * 12.0, 0.0, 1.0))
		rb.sleeping = false


## His collar this far from your hands (m) and he's no load; LAG_SPAN more and you're at a crawl.
const LAG_FREE := 1.1
const LAG_SPAN := 1.2
var _lag := 0.0
const LIFTED: Array[StringName] = [&"chest", &"abdomen", &"pelvis", &"thigh_l", &"thigh_r", &"shin_l", &"shin_r", &"foot_l", &"foot_r"]
const LEGS: Array[StringName] = [&"thigh_l", &"thigh_r", &"shin_l", &"shin_r", &"foot_l", &"foot_r"]
## He comes loose only after he's been past carry_tear_m this long (s): a jolt on a step isn't it.
const TEAR_S := 6.0
var _tear_t := 0.0


func _lose_why() -> StringName:
	if not is_down(him):
		return &"up"
	if player.seat != null and player.seat.seated():
		return &"sat"
	if player.ladder != null:
		return &"ladder"
	var w := player.wounds
	if w != null and w.physiology != null:
		if not w.physiology.is_conscious():
			return &"down"
		if _wound_count() > _wounds_n:
			return &"hit"
	var hands := player.global_position + Vector3.UP * player.tuning.carry_hold_up
	if collar(him).distance_to(hands) > player.tuning.carry_tear_m:
		_tear_t += get_physics_process_delta_time()
		if _tear_t > TEAR_S:
			return &"tore"
	else:
		_tear_t = 0.0
	return &""


func _wound_count() -> int:
	var w := player.wounds
	if w == null or w.physiology == null:
		return 0
	return int(w.physiology.wounds)


func report() -> Dictionary:
	var here := man_here()
	return {"carrying": String(him.person_id) if carrying() else "", "dragged_m": snappedf(dragged_m, 0.1),
			"blood_on_you": snappedf(blood_on_you, 0.01), "last": String(last), "why": String(last_why),
			"by_man": String(here.person_id) if here else ""}
