class_name PlayerCarry
extends Node
## Taking a downed man with you (#1057, No Law: Harlan gets Earl up the street to the doctor's; the
## prologue's sheriff, #1081): a tap of E by a man down (limp or lying, alive, wounded or dead; his
## collar within PlayerTuning.carry_reach and within carry_view_deg of your view) takes him up over
## your right shoulder, a fireman's carry: his belly on your shoulder (that part of his ragdoll held
## there, eased up over carry_lift_s), the rest of him hanging off it on his joints, head and arms down
## your back, legs down your front, clear of the ground. Carried, not dragged (Sean, 2026-11-18): he
## leaves no trail; what he bleeds goes into your coat (`blood_on_you`), not on the street
## (HumanBody.carried: no pool, no smear). While you have him his parts touch only each other, not
## you or the world (a door frame doesn't catch his boots). A tap again lays him down in front of you.
##
## While you have him: a walk at carry_speed (no run, no jump), no gun (PlayerWounds holds your
## hands: busy_why), and E lays him down (or bangs on a door you're at: PlayerKnock has it then). He's
## put down if you're hit, go down, sit, take a ladder, or if he comes up (not down any more). In the
## group `claims_use`, so E here isn't a shove. Held E isn't this (a scene may want it: the sheriff's
## wound).
## Reusable: any act asks `carrying(man)`; `took` and `let_go` say when.

signal took(man: HumanBody)
signal let_go(man: HumanBody, why: StringName)

var player: Player
## The man you have by the collar, or null.
var him: HumanBody
## How much of his blood is on your hands and cuffs (WoundSigns prints, 0 to PRINTS_PER_HAND): the
## most it's come to while you had him. Stays (it doesn't wash off by itself).
var blood_on_you := 0.0
## Metres you've carried him (flat), this time and all told.
var dragged_m := 0.0
var dragged_total_m := 0.0
var _e_held := 0.0  # how long E's been down this press (a tap takes him up or lays him down)
var _lift_t := 0.0  # how far into lifting him (s)
var _lift_from := Transform3D()  # his belly where you took him up from
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


## A mission started again in place (#1116: the sheriff's "start again" kept the last run's
## metres and the blood on your coat): put down whoever you had, and none of it carried over.
func start_over() -> void:
	if carrying():
		_drop(&"start_over")
	blood_on_you = 0.0
	dragged_m = 0.0
	dragged_total_m = 0.0
	last = &""
	last_why = &""
	_e_held = 0.0
	_lift_t = 0.0
	_told_for = null
	_near = null


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
	if player.drink != null and player.drink.holding():
		return null  # a glass in your hand: E's for it (#1292)
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
func pace(_wish := Vector3.ZERO) -> float:
	if not carrying() or player == null:
		return 1.0
	return clampf(player.tuning.carry_speed / maxf(player.tuning.walk_speed, 0.1), 0.05, 1.0)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_told_ago += delta
	if carrying():
		_hold(delta)
	elif him != null:
		_drop(&"gone")
	# A tap (let go within carry_tap_s): held, E's for something else (a scene's: his wound). Down
	# and up between two ticks (a tap in one slow frame, #1117) it's never seen down: a tap too.
	var tapped := player.input_enabled and _e_held <= 0.0 and Input.is_action_just_pressed(&"shove") \
			and Input.is_action_just_released(&"shove")
	if player.input_enabled and Input.is_action_pressed(&"shove"):
		_e_held += delta
	elif _e_held > 0.0 or tapped:
		var tap := _e_held <= player.tuning.carry_tap_s
		_e_held = 0.0
		if tap and player.input_enabled:
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
			player.wounds.say("E: take him up", 1.5)


## What E does here: lay him down (unless you're at a door: PlayerKnock bangs on it), or take the man
## down by you up.
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


## Take `m` up over your shoulder (true if you have him).
func take(m: HumanBody) -> bool:
	if m == null or not is_down(m) or (m.dragged_by != null and m.dragged_by != player):
		return false
	if carrying():
		_drop(&"another")
	him = m
	him.dragged_by = player
	_tear_t = 0.0
	_shoulder(m, true)
	dragged_m = 0.0
	_from = player.global_position
	_wounds_n = _wound_count()
	if player.weapon:
		player.weapon.put_away()
	last = &"took"
	if player.wounds:
		player.wounds.say("E: put him down", 1.5)
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
	if m != null and is_instance_valid(m):
		_shoulder(m, false)
		if m.dragged_by == player:
			m.dragged_by = null
	last = &"let_go"
	last_why = why
	if m != null and is_instance_valid(m):
		let_go.emit(m, why)


## Each tick with him: why you'd lose him, then his belly held over your shoulder, his blood on you.
func _hold(delta: float) -> void:
	var why := _lose_why()
	if why != &"":
		_drop(why)
		return
	him.wake()  # full ticks while you have him (PeopleTick's bands)
	him.dragged_by = player
	var belly := him.parts.get(&"abdomen") as RigidBody3D
	if belly != null and him.limp:
		_lift_t = minf(_lift_t + delta, player.tuning.carry_lift_s)
		var k := _lift_t / maxf(player.tuning.carry_lift_s, 0.01)
		k = k * k * (3.0 - 2.0 * k)
		var to := shoulder_xform()
		belly.global_transform = Transform3D(_lift_from.basis.slerp(to.basis, k).orthonormalized(), _lift_from.origin.lerp(to.origin, k))
		for rb: Variant in him.parts.values():
			if rb is RigidBody3D:
				(rb as RigidBody3D).sleeping = false
	var step := Vector2(player.global_position.x - _from.x, player.global_position.z - _from.z).length()
	dragged_m += step
	dragged_total_m += step
	_from = player.global_position
	var signs := him.signs_now()
	if signs != null:
		# His collar in your hand, his belly on your shoulder: what's on them comes off on you.
		blood_on_you = maxf(blood_on_you, signs.blood_on_me(collar(him), WoundSigns.ON_COLLAR))
		if belly != null:
			blood_on_you = maxf(blood_on_you, signs.blood_on_me(belly.global_position, WoundSigns.ON_COLLAR))


## Where his belly lies over your right shoulder: his head down your back, his front down on you.
func shoulder_xform() -> Transform3D:
	var fwd := player.get_forward()
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var right := fwd.cross(Vector3.UP).normalized()
	var t := player.tuning
	var at := player.global_position + Vector3.UP * t.carry_shoulder_up + right * t.carry_shoulder_side + fwd * t.carry_shoulder_fwd
	# His +Y (toward his head) behind you, his front (-Z) down: +Z up.
	var y := -fwd
	var z := Vector3.UP
	return Transform3D(Basis(y.cross(z), y, z), at)


## On (taken up) or off (laid down) your shoulder: his belly held (kinematic) or let go, his parts
## out of the world and off you while you have him, his blood kept off the ground (HumanBody.carried).
func _shoulder(m: HumanBody, on: bool) -> void:
	if on and not m.limp:
		m.go_limp()  # lying posed (prone): the ragdoll, to hang off your shoulder
	m.carried = on
	var belly := m.parts.get(&"abdomen") as RigidBody3D
	if on:
		_lift_t = 0.0
		_lift_from = belly.global_transform if belly else Transform3D()
	for v: Variant in m.parts.values():
		var rb := v as RigidBody3D
		if rb == null:
			continue
		rb.collision_mask = Layers.RAGDOLL if on else Layers.WORLD | Layers.RAGDOLL
		# (Kept on as he's laid down: a limp man never collides with you, HumanBody._through_the_player.)
		player.add_collision_exception_with(rb)
		rb.linear_velocity = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO
		rb.sleeping = false
	if belly != null:
		belly.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		belly.freeze = on
	if not on and m.limp and belly != null and player.is_inside_tree():
		# Laid down in front of you: the whole of him lowered there by the same step, to settle.
		var fwd := player.get_forward()
		fwd.y = 0.0
		fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
		# Clear of you, all of him: his body hangs down your back as he comes off the shoulder, and
		# with nothing of you to push him (a limp man goes through you, HumanBody._through_the_player)
		# a pelvis set 0.7 m out left his chest inside you, to fold back through you (#1092).
		# Lowered, not dropped on end: over the shoulder he hangs folded at the hips (head down your
		# back, legs down your front), and set down as he hung he stood on his head and feet and
		# toppled for a second or more (#1116: CI's lay 0.48 m up a second on). A quarter turn about
		# the fold's fore-and-aft line lays the fold flat, on his side; he settles from there.
		var pivot := belly.global_position
		var turn := Basis(fwd, deg_to_rad(LAY_TURN_DEG))
		for v: Variant in m.parts.values():
			var n := v as Node3D
			if n != null:
				var xf := n.global_transform
				n.global_transform = Transform3D(turn * xf.basis, pivot + turn * (xf.origin - pivot))
		var from := ValleyFolk._body_at(m)
		var back := 0.0
		for v: Variant in m.parts.values():
			back = minf(back, ((v as Node3D).global_position - from).dot(fwd))
		var to := player.global_position + fwd * maxf(0.7, player.tuning.radius + LAY_CLEAR_M - back)
		ValleyFolk.move_body(m, Vector3(to.x, player.global_position.y, to.z))


## Laid down, his nearest part this far (m) past your capsule.
const LAY_CLEAR_M := 0.15
## Laid down: the hang's fold turned this far onto his side (degrees about your forward).
const LAY_TURN_DEG := 90.0


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
