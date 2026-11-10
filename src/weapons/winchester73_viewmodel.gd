class_name Winchester73Viewmodel
extends WeaponViewmodel
## The Winchester 1873 in your hands (#734 step 2). Reads the controls, runs the mechanism
## (Winchester73State), drives the model's parts (Winchester73Model: the lever, bolt, carrier,
## hammer, trigger, dust cover, gate, the rounds) and both hands, and fires a .44-40 bullet through
## Ballistics with smoke, flash, the case flying out of the port and a rifle's report. Sits under the
## camera beside the revolver and the coach gun; carried on a sling.
##
## Controls: fire (LMB / RT) squeezes the trigger (only at full cock, the lever shut); cock (Q, wheel
## down, RB) works the lever: a tap is the whole stroke, held it stays open till you let go; hammer
## (middle mouse, Alt) eases a cocked hammer down to half cock (the safety: the trigger's dead there)
## or thumbs it back to full; aim (RMB / LT) shoulders it, down the buckhorn to the blade; reload
## (R / X) thumbs one round through the gate into the tube (hold to keep going; topped up any time);
## holster (H / LB) slings it or takes it off the sling. Its key is 6. The rounds are the Colt's.

enum Pose { HIP, AIM, LOADING }

## The low ready (the gun lab's fp view, `win73_views.gd --only=fp`): the wrist low on the right out
## front, the muzzle down and in toward the middle of the view. Turned for the gate: the action up
## and round so its right side faces you.
const HIP_ROT := Vector3(-7.0, 14.0, -8.0)
const HIP_AT := Vector3(0.17, -0.17, -0.33)
const LOADING_ROT := Vector3(8.0, 62.0, 10.0)
const LOADING_AT := Vector3(0.02, -0.12, -0.36)
## Shouldered: on the line from the rear notch to the blade's top. The cheek on the comb puts a real
## eye ~15" (38 cm) behind the notch, the thumb a few inches in front of it; held there in first
## person the right wrist and forearm run back past the camera and fill the view (the lab's fp views,
## and the game's first render), so the view sits back along the line as first-person games do.
const EYE_RELIEF := 0.5
## Slung on the right shoulder, muzzle up behind you (out of view), and up against a wall: port arms.
const PUT_AWAY_POS := Vector3(0.32, -0.75, 0.2)
const PUT_AWAY_ROT := Vector3(75.0, -10.0, 0.0)
const TUCK_POS := Vector3(0.12, -0.26, -0.05)
const TUCK_ROT := Vector3(68.0, 14.0, -10.0)

## The hands (the lab's fit, design inches f/u/l). The right round the wrist of the stock, its
## fingers through the lever's loop and the index on the trigger; it rides the loop down when the
## lever's thrown (its pivot turns on the lever's pin by `HAND_RIDES` of the lever's angle). The
## left under the forend, as under the coach gun's.
const R_HAND_FUL := Vector3(-5.2, -1.5, 0.7)
const R_WRIST_DIR := Vector3(0.3, 0.12, 0.95)
const R_PALM_DIR := Vector3(-1.0, -0.25, 0.0)
const R_FOREARM := Vector3(0.45, -0.55, 0.70)
const R_GRIP := {"middle": 72.0, "ring": 66.0, "little": 60.0}
const R_INDEX_SPREAD := 28.0
const R_INDEX_REST := 12.0
const R_INDEX_PULL := 24.0
## The thumb over the top of the wrist (the coach gun's), laid low so it stays under the sights.
const R_THUMB := [Vector3(-24.0, -36.0, 24.0), 55.0, 45.0]
const HAND_RIDES := 0.8
## At the gate (loading): the right hand off the wrist, a round between thumb and fingers against
## the gate (f/u/l, its knuckles forward along the receiver's side).
const R_GATE_FUL := Vector3(-1.4, -1.4, 1.9)
const R_GATE_WRIST := Vector3(0.6, -0.4, 0.7)
const R_GATE_PALM := Vector3(-1.0, 0.2, -0.2)
const L_HAND_FUL := Vector3(8.2, -2.3, 0.25)
const L_WRIST_DIR := Vector3(-0.55, -0.25, 0.8)
const L_PALM_DIR := Vector3(0.3, 1.0, 0.0)
const L_FOREARM := Vector3(-0.7, -0.5, 0.6)
const L_GRIP := {"index": 40.0, "middle": 62.0, "ring": 66.0, "little": 70.0}
const L_THUMB := [Vector3(-36.0, 60.0, 48.0), 45.0, 40.0]

## Your shoulders in the camera's space: at the low ready the coach gun's; shouldered, the right
## comes in behind the butt (the stock in its pocket, the elbow out to the side) and the left forward
## and in under the forend (the elbow under the gun), so neither arm crosses the action (the lab's
## first-person views: with the coach gun's both came in over it).
const SHOULDER_R_AIM := Vector3(0.14, -0.2, 0.12)
const SHOULDER_L_AIM := Vector3(-0.14, -0.22, -0.05)
const ELBOW_POLE_R_AIM := Vector3(1.0, -0.35, 0.1)
const ELBOW_POLE_L_AIM := Vector3(-0.15, -1.0, 0.1)

@export var tuning: Winchester73Tuning

var state: Winchester73State
var model: Winchester73Model
var hand: HeldHand
var left_hand: HeldHand
## 0 at the low ready, 1 shouldered (the cheek on the comb, the blade in the notch).
var shoulder := 0.0

var _hip_pos := Vector3.ZERO
var _aim_pos := Vector3.ZERO
var _aim_rot := Vector3.ZERO
var _loading_pos := Vector3.ZERO
var _lever := 0.0
var _lever_closing := false
var _lever_held := 0.0
var _hammer := 0.0
var _trigger := 0.0
var _gate := 0.0
var _at_gate := 0.0
var _reload_held := 0.0
var _hand_pivot: Node3D
var _held_round: Node3D
var _loading_until := 0.0
var _clock := 0.0
var _close_when_ready := false
var _fire_until := 0.0
## A squeeze that comes while the lever's still finishing its stroke fires as it shuts, this long after
## at most (s): a hand already on the trigger.
const TRIGGER_BUFFER := 0.2


func _ready() -> void:
	add_to_group(&"rifle")
	if tuning == null:
		tuning = load("res://config/winchester73.tres")
	sway_factor = tuning.sway_hip
	state = Winchester73State.new(tuning, hash(get_path()) + 73)
	_rng.seed = 73
	model = Winchester73Model.new()
	model.name = "Winchester"
	add_child(model)
	_poses()
	_build_hands()
	_pose_pos = _hip_pos
	_pose_rot = HIP_ROT
	_setup_common()
	for id in [&"rifle", &"cock", &"dry_fire", &"break_open", &"close", &"insert", &"eject", &"gate"]:
		_add_sound(id, id == &"rifle")
	state.lever_moved.connect(func(o: bool) -> void:
		_play(&"break_open" if o else &"close")
		_lever_closing = not o)
	state.ejected.connect(_on_ejected)
	state.fired.connect(_on_fired)
	state.clicked.connect(func() -> void: _play(&"dry_fire"))
	state.misfired.connect(func() -> void: _play(&"dry_fire"))
	state.hammer_moved.connect(func(h: int) -> void:
		if h != Winchester73State.Hammer.DOWN and not state.lever_open:
			_play(&"cock"))
	state.gate_loaded.connect(func() -> void: _play(&"insert"); _gate = 1.0)
	_apply_pose(_draw)
	_muzzle_local = _pose_local(model.marker("Muzzle"))
	_share_ammo.call_deferred()


## The .44-40 is the Colt's: one belt for both (the revolver keeps it).
func _share_ammo() -> void:
	var colt := _player.revolver() if _player else null
	if colt and colt.state:
		state.shares = colt.state


func _pose_local(p: Vector3) -> Vector3:
	return model.transform * p


## The poses from the model's markers (the lab's first-person holds).
func _poses() -> void:
	var d := func(v: Vector3) -> Vector3: return Winchester73Model.design(v.x, v.y, v.z)
	var bl := Basis.from_euler(HIP_ROT * (PI / 180.0))
	_hip_pos = HIP_AT - bl * d.call(Vector3(-4.6, -1.8, 0.0))
	var bi := Basis.from_euler(LOADING_ROT * (PI / 180.0))
	_loading_pos = LOADING_AT - bi * d.call(Vector3(-1.2, -0.9, 0.0))
	var rear := model.marker("SightRear")
	var front := model.marker("SightFront")
	var b := Basis.looking_at((front - rear).normalized(), Vector3.UP).inverse()
	_aim_rot = b.get_euler() * (180.0 / PI)
	_aim_pos = -(b * rear) + Vector3(0.0, 0.0, -EYE_RELIEF)


func _build_hands() -> void:
	var d := func(v: Vector3) -> Vector3: return Winchester73Model.design(v.x, v.y, v.z)
	var lever_pin: Array = model.rig["moving"]["Lever"]["pivot"]
	_hand_pivot = Node3D.new()
	_hand_pivot.name = "RightHandPivot"
	_hand_pivot.position = Vector3(lever_pin[0], lever_pin[1], lever_pin[2])
	model.add_child(_hand_pivot)
	hand = _held(true, _hand_pivot, d.call(R_HAND_FUL) - _hand_pivot.position, R_WRIST_DIR, R_PALM_DIR, R_FOREARM)
	for f: String in R_GRIP:
		hand.grasp(f, R_GRIP[f])
	hand.grasp("index", R_INDEX_REST, R_INDEX_SPREAD)
	hand.thumb_pose(R_THUMB[0], R_THUMB[1], R_THUMB[2])
	left_hand = _held(false, model, d.call(L_HAND_FUL), L_WRIST_DIR, L_PALM_DIR, L_FOREARM)
	for f: String in L_GRIP:
		left_hand.grasp(f, L_GRIP[f])
	left_hand.thumb_pose(L_THUMB[0], L_THUMB[1], L_THUMB[2])
	hand.shoulder = ShotgunViewmodel.SHOULDER_R
	hand.elbow_pole = ShotgunViewmodel.ELBOW_POLE_R
	left_hand.shoulder = ShotgunViewmodel.SHOULDER_L
	left_hand.elbow_pole = ShotgunViewmodel.ELBOW_POLE_L
	# The round in the fingers, on its way into the gate (brass, its lead nose forward).
	_held_round = Node3D.new()
	_held_round.name = "HeldRound"
	model.add_child(_held_round)
	var case_len := 1.305 * 0.0254
	GunParts.tube(_held_round, "Case", 0.0059, case_len, Vector3(0, 0, -case_len * 0.5), GunParts.brass(), 10).set_meta(&"own_paint", true)
	GunParts.tube(_held_round, "Bullet", 0.0054, 0.012, Vector3(0, 0, -case_len - 0.005), GunParts.lead(), 10).set_meta(&"own_paint", true)
	_held_round.visible = false


## A hand at `pos` in `parent`'s space laid along `wrist_dir` (from its knuckles back towards its
## wrist) with its palm towards `palm_dir`, its forearm aimed `forearm` (in the gun's space).
func _held(is_right: bool, parent: Node3D, pos: Vector3, wrist_dir: Vector3, palm_dir: Vector3, forearm: Vector3) -> HeldHand:
	var h := HeldHand.new(is_right)
	h.name = "Hand" if is_right else "LeftHand"
	_place(h, pos, wrist_dir, palm_dir, is_right)
	parent.add_child(h)
	h.build()
	h.aim_forearm(forearm)
	return h


static func _place(h: Node3D, pos: Vector3, wrist_dir: Vector3, palm_dir: Vector3, is_right: bool) -> void:
	h.position = pos
	var z := wrist_dir.normalized()
	var x := (palm_dir - z * palm_dir.dot(z)).normalized() * (-1.0 if is_right else 1.0)
	h.basis = Basis(x, z.cross(x), z)


func _process(delta: float) -> void:
	_clock += delta
	state.tick(delta)
	if _close_when_ready and state.ready():
		_close_when_ready = false
		if state.lever_open:
			state.close_lever()
	if _can_act():
		_read_controls(delta)
	_animate(delta)


func _read_controls(delta: float) -> void:
	if hands_busy or arm_disabled:
		if drawn:
			toggle_holster()
		aiming = false
		return
	if Input.is_action_just_pressed(&"holster"):
		toggle_holster()
	if not drawn or _draw < 0.9:
		aiming = false
		return
	aiming = Input.is_action_pressed(&"aim") and _action_ok(&"aim") and not _loading()
	if Input.is_action_just_pressed(&"reload"):
		_reload_held = 0.0
		reload_press()
	elif Input.is_action_pressed(&"reload"):
		_reload_held += delta
		if _reload_held > 0.3 and state.ready():
			reload_press()
	# The lever: open on the press, shut when it's let go (a tap is the whole stroke).
	if Input.is_action_just_pressed(&"cock"):
		lever_open()
	if state.lever_open:
		_lever_held += delta
		if not Input.is_action_pressed(&"cock") and _lever_held >= tuning.lever_min_open:
			lever_close()
	if InputMap.has_action(&"hammer") and Input.is_action_just_pressed(&"hammer") and _action_ok(&"hammer"):
		hammer_press()
	if Input.is_action_just_pressed(&"fire") and _action_ok(&"fire"):
		if state.ready() and not state.lever_open:
			pull_trigger()
		else:
			_fire_until = _clock + TRIGGER_BUFFER  # the lever still going home: the squeeze comes as it shuts
	if _fire_until > _clock and state.ready() and not state.lever_open:
		_fire_until = 0.0
		pull_trigger()
	if Settings.auto_cock and state.ready() and not state.lever_open and state.hammer == Winchester73State.Hammer.DOWN \
			and state.rounds_ready() > 0:
		lever_open()


## Throw the lever (the cock key): opens it now; it shuts on `lever_close` (or let go of the key).
func lever_open() -> bool:
	_lever_held = 0.0
	return state.open_lever()


func lever_close() -> bool:
	return state.close_lever()


## The whole stroke, out and back (tools and tests: what a tap of Q does): open now, shut on the
## first frame the hands are free after.
func work_lever() -> void:
	if state.lever_open:
		lever_close()
		return
	_close_when_ready = lever_open()


## The cock key's place on the bridge and in the tests (the revolver's and shotgun's name).
func cock_press() -> void:
	work_lever()


func hammer_press() -> bool:
	return state.hammer_press()


func reload_press() -> void:
	if state.reload_step():
		_loading_until = _clock + tuning.gate_load_time + 0.5


func _loading() -> bool:
	return _clock < _loading_until and not state.lever_open


## Thumbing rounds in at the gate (the gang presses you then, as on the revolver's gate).
func is_loading() -> bool:
	return _loading()


func pull_trigger() -> Winchester73State.Shot:
	if state.lever_open:
		return Winchester73State.Shot.NONE
	_trigger = 1.0
	return state.pull_trigger()


func _why_not(action: StringName) -> String:
	if state == null:
		return ""
	if action == &"fire":
		if state.lever_open:
			return "the lever's open"
		if state.hammer == Winchester73State.Hammer.HALF_COCK:
			return "it's at half cock: thumb the hammer back"
		if state.hammer == Winchester73State.Hammer.DOWN:
			return "work the lever" if state.rounds_ready() > 0 else ("it's empty: load it" if state.belt() > 0 else "you're out of cartridges")
	if action == &"reload":
		if state.tube >= tuning.tube_capacity:
			return "the tube's full"
		if state.belt() <= 0:
			return "you're out of cartridges"
	if action == &"cock" and state.rounds_ready() == 0 and state.chamber == Winchester73State.Round.EMPTY:
		return "it's empty: load it" if state.belt() > 0 else "you're out of cartridges"
	return ""


func toggle_holster() -> void:
	drawn = not drawn
	if not drawn:
		aiming = false
		if state.lever_open:
			state.busy = 0.0
			state.close_lever()
		state.close_cover()


func put_away() -> void:
	aiming = false
	if drawn:
		toggle_holster()


func take_out() -> void:
	if not drawn:
		toggle_holster()


func _on_fired() -> void:
	_in_tick(_fire)


func _fire() -> void:
	var line := _shot_line(model.muzzle.global_position)
	var origin: Vector3 = line[0]
	var dir: Vector3 = line[1]
	var exclude: Array[RID] = line[2]
	# Not yet in the shoulder the barrel's still coming up to your eye: the shot goes as from the hip.
	var spread := lerpf(tuning.spread_hip_degrees, tuning.spread_aim_degrees, shoulder if aiming else 0.0) + _wobble()
	if _player:
		spread += _player.get_horizontal_speed() * 0.5
	dir = _cone(dir, deg_to_rad(spread))
	var ballistics := _ballistics()
	var bullet := ballistics.fire(origin, dir, tuning.muzzle_velocity, tuning.bullet_mass, tuning.bullet_diameter, exclude)
	bullet.form = tuning.form_factor
	bullet.shooter = _player
	bullet.blast = tuning.blast_joules
	bullet.blast_reach = tuning.blast_reach
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir, 1.2)
	ImpactEffects.muzzle_flash(world, origin)
	if GameAudio.enabled():
		GameAudio.gunshot(self, origin, false, &"report_rifle", &"rolling_rifle")
	else:
		_play(&"rifle")
	Events.shot_fired.emit(origin, dir, _player)
	_kick_shot(tuning)
	_unsettle()


func _load() -> Dictionary:
	return {"speed": tuning.muzzle_velocity, "mass": tuning.bullet_mass, "diameter": tuning.bullet_diameter,
			"form": tuning.form_factor, "zero": tuning.zero_distance}


## Out of the port, up and to the right, end over end (the 1873's ejector throws them high).
func _on_ejected(round_state: int) -> void:
	_play(&"eject")
	var at := model.global_transform * model.marker("Port")
	var b := model.global_transform.basis
	var push := b.y * 1.6 + b.x * 0.9 + b.z * 0.3
	var live := round_state == Winchester73State.Round.LOADED
	var world := _ballistics().get_parent()
	get_tree().create_timer(0.06).timeout.connect(func() -> void:
		if is_instance_valid(world):
			var c := ImpactEffects.spent_case(world, at, push, 0.0067, 0.04 if live else 0.033, 0.0145 if live else 0.006)
			c.name = "LiveRound" if live else "SpentCase")


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / tuning.draw_time)
	visible = _draw > 0.02
	var loading := _loading()
	var pose := Pose.LOADING if loading else (Pose.AIM if aiming else Pose.HIP)
	var target_pos: Vector3 = [_hip_pos, _aim_pos, _loading_pos][pose]
	var target_rot: Vector3 = [HIP_ROT, _aim_rot, LOADING_ROT][pose]
	var k := 1.0 - exp(-delta * 3.0 / maxf(tuning.shoulder_time, 0.05))
	_pose_pos = _pose_pos.lerp(target_pos, k)
	_pose_rot = _pose_rot.lerp(target_rot, k)
	# How far into the shoulder: the gun's way along from the low ready to the aimed pose.
	var span := _hip_pos.distance_to(_aim_pos)
	shoulder = clampf(1.0 - _pose_pos.distance_to(_aim_pos) / maxf(span, 0.01), 0.0, 1.0) if aiming else 0.0
	if aiming and shoulder < 0.95:
		_unsettle()  # the sights aren't settled before the cheek is on the comb
	sway_factor = lerpf(tuning.sway_hip, tuning.sway_aimed, shoulder)
	shake_factor = lerpf(1.0, tuning.shake_aimed, shoulder)
	kick.step(delta)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * (16.0 if _tuck_target > tuck else 8.0)))
	_update_sway(delta)
	_apply_pose(_draw)
	_animate_camera(delta, tuning.aim_fov)
	# Slung and out of sight: nothing of it to draw or pose (its hands stop posing too).
	var shown := visible
	if hand.is_processing() != shown:
		hand.set_process(shown)
		left_hand.set_process(shown)
	if not shown:
		return
	_animate_parts(delta, loading)
	_animate_hands(delta, loading)


func _animate_parts(delta: float, loading: bool) -> void:
	var opening := state.lever_open
	_lever = move_toward(_lever, 1.0 if opening else 0.0, delta / maxf(tuning.lever_open_time if opening else tuning.lever_close_time, 0.01))
	model.lever(_lever, _lever_closing)
	var target: float
	match state.hammer:
		Winchester73State.Hammer.FULL_COCK:
			target = model.notch("full")
		Winchester73State.Hammer.HALF_COCK:
			target = model.notch("half")
		_:
			target = model.notch("rest")
	if target < _hammer:
		# Falling (the trigger) is instant; eased down to half cock it's slow.
		_hammer = target if state.hammer == Winchester73State.Hammer.DOWN else move_toward(_hammer, target, delta * 40.0 / maxf(tuning.half_cock_time, 0.01))
	else:
		_hammer = move_toward(_hammer, target, delta * 60.0 / maxf(tuning.hammer_time, 0.01))
	model.hammer(maxf(_hammer, model.bolt_hammer(_lever) if opening else 0.0))
	_trigger = move_toward(_trigger, 0.0, delta * 5.0)
	model.trigger(_trigger)
	model.cover(1.0 if state.cover_open else 0.0)
	_gate = move_toward(_gate, 0.0, delta / maxf(tuning.gate_load_time * 0.4, 0.05))
	model.gate(_gate)
	model.chamber(Winchester73Model.shown(state.chamber))
	model.carrier_round(Winchester73Model.shown(state.carrier))
	model.tube_round("loaded" if state.tube > 0 else "empty")
	model.sling.visible = true
	# A round in the fingers from the pocket to the gate, then pushed in as the gate goes in.
	_held_round.visible = loading and _gate < 0.9 and state.belt() > 0 and state.tube < tuning.tube_capacity
	var gate_at := model.marker("GatePoint")
	_held_round.position = gate_at + Vector3(0.012, 0.0, 0.03 + 0.03 * (1.0 - _at_gate))
	_held_round.rotation_degrees = Vector3(0.0, -8.0, 0.0)


func _animate_hands(delta: float, loading: bool) -> void:
	var lever_deg: float = model.rig["moving"]["Lever"]["throw_deg"]
	_hand_pivot.rotation_degrees.x = lever_deg * _lever * HAND_RIDES
	_at_gate = move_toward(_at_gate, 1.0 if loading else 0.0, delta / 0.25)
	var d := func(v: Vector3) -> Vector3: return Winchester73Model.design(v.x, v.y, v.z)
	var grip_pos: Vector3 = d.call(R_HAND_FUL) - _hand_pivot.position
	var gate_pos: Vector3 = d.call(R_GATE_FUL) - _hand_pivot.position
	var a := smoothstep(0.0, 1.0, _at_gate)
	_place(hand, grip_pos.lerp(gate_pos, a), R_WRIST_DIR.lerp(R_GATE_WRIST, a), R_PALM_DIR.lerp(R_GATE_PALM, a), true)
	hand.aim_forearm(R_FOREARM)
	for f: String in R_GRIP:
		hand.grasp(f, lerpf(R_GRIP[f], 20.0, a))
	hand.grasp("index", lerpf(lerpf(R_INDEX_REST, R_INDEX_PULL, _trigger), 25.0, a), R_INDEX_SPREAD * (1.0 - a))
	var s := smoothstep(0.0, 1.0, shoulder)
	hand.shoulder = ShotgunViewmodel.SHOULDER_R.lerp(SHOULDER_R_AIM, s)
	hand.elbow_pole = ShotgunViewmodel.ELBOW_POLE_R.lerp(ELBOW_POLE_R_AIM, s)
	left_hand.shoulder = ShotgunViewmodel.SHOULDER_L.lerp(SHOULDER_L_AIM, s)
	left_hand.elbow_pole = ShotgunViewmodel.ELBOW_POLE_L.lerp(ELBOW_POLE_L_AIM, s)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var away := smoothstep(0.0, 1.0, drawn_amount)
	var pos := PUT_AWAY_POS.lerp(_pose_pos.lerp(TUCK_POS, t), away) + Vector3(0.0, kick.back * 0.2, kick.back) \
			+ _body_pos() * drawn_amount
	var rot := PUT_AWAY_ROT.lerp(_pose_rot.lerp(TUCK_ROT, t), away) + Vector3(kick.pitch, -kick.yaw, -kick.roll) * (1.0 - t) \
			+ _sway_rotation() * (1.0 - t) * (0.3 if _loading() else 1.0)
	position = pos
	rotation_degrees = rot
