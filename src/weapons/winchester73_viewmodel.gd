class_name Winchester73Viewmodel
extends WeaponViewmodel
## The Winchester 1873 rifle in your hands (#734, #777). Reads the controls, runs the mechanism
## (Winchester73State), works the parts the rig drives (Winchester73Model: the lever with the bolt,
## carrier and hammer, the trigger, the gate, the dust cover, the rounds) and both hands, and fires
## a .44-40 ball through Ballistics with smoke, flash, brass and a rifle's report. Sits under the
## camera beside the revolver and the coach gun; slung on your back when it's put away.
##
## Controls: fire (LMB / RT) squeezes the trigger (only at full cock, the lever home); cock (Q,
## wheel down, RB) works the lever (one stroke: open and home), or thumbs the hammer back from half
## cock with a round in; held with a round in and the hammer back, it eases the hammer down to half
## cock (the safety); aim (RMB / LT) shoulders it, your eye down the buckhorn to the blade; reload
## (R / X) pushes a round through the gate into the tube (hold to keep going; any time the lever's
## home); holster (H / LB) slings it.

## The usual first-person carry (the lab's low ready, #776's sheets): the wrist low on the right out
## front, the muzzle in towards the middle. Turned to load: the gate's side to you. Euler degrees.
const HIP_ROT := Vector3(-6.0, 6.0, -6.0)
const HIP_WRIST := Vector3(0.17, -0.17, -0.33)
const LOAD_ROT := Vector3(8.0, 62.0, 10.0)
const LOAD_AT := Vector3(0.02, -0.12, -0.36)
## Shouldered: the cheek on the comb puts your eye this far behind the rear notch (m), on the
## line from the notch's bottom to the blade's top (the lab's fp_aim: ~15").
const EYE_RELIEF := 0.38
## Slung: up and back over your right shoulder, muzzle up, out of the view.
const PUT_AWAY_POS := Vector3(0.3, -0.45, 0.32)
const PUT_AWAY_ROT := Vector3(70.0, -10.0, 20.0)
## Up against a wall: port arms, the muzzle up and across.
const TUCK_POS := Vector3(0.1, -0.22, -0.06)
const TUCK_ROT := Vector3(62.0, 14.0, -10.0)

## The right hand round the wrist, its fingers through the lever's loop, the index on the trigger
## (the lab's fp hands, design inches); it rides the lever's pivot while the lever's worked. The left
## under the forend.
const R_HAND := Vector3(-5.2, -1.8, 0.62)
const R_WRIST_DIR := Vector3(0.5, 0.12, 0.86)
const R_PALM_DIR := Vector3(-1.0, -0.2, 0.0)
const R_FOREARM := Vector3(0.55, -0.35, 0.75)
const R_GRIP := {"middle": 82.0, "ring": 78.0, "little": 72.0}
const R_INDEX_REST := 12.0
const R_INDEX_PULL := 24.0
const R_INDEX_SPREAD := 28.0
## The hand follows this share of the lever's turn (the palm comes off the wrist, the fingers stay
## in the loop).
const R_LEVER_SHARE := 0.85
const R_THUMB_REST := [Vector3(-24.0, -36.0, 24.0), 45.0, 40.0]
const R_THUMB_COCK := [Vector3(48.0, 36.0, 60.0), 45.0, 40.0]
const L_HAND := Vector3(8.2, -1.50, 0.0)
const L_WRIST_DIR := Vector3(-0.7, -0.35, 0.6)
const L_PALM_DIR := Vector3(0.3, 1.0, 0.0)
const L_FOREARM := Vector3(-0.7, -0.5, 0.6)
const L_GRIP := {"index": 12.0, "middle": 50.0, "ring": 56.0, "little": 64.0}
const L_THUMB := [Vector3(-36.0, 60.0, 48.0), 45.0, 40.0]
## Your shoulders in the camera's space, and which way each elbow goes. From the hip as the coach
## gun's. Shouldered (#776: "both arms come in over the action"): the butt in the right shoulder's
## pocket just behind and below your cheek, the right elbow up and out to the side; the left
## shoulder forward under the forend, its elbow down beneath the gun.
const HIP_SHOULDER_R := Vector3(0.19, -0.2, 0.07)
const HIP_SHOULDER_L := Vector3(-0.19, -0.2, 0.07)
const HIP_POLE_R := Vector3(0.5, -1.0, 0.2)
const HIP_POLE_L := Vector3(-0.5, -1.0, 0.2)
const AIM_SHOULDER_R := Vector3(0.1, -0.2, 0.18)
const AIM_SHOULDER_L := Vector3(-0.17, -0.22, 0.06)
const AIM_POLE_R := Vector3(0.6, -0.8, 0.0)
const AIM_POLE_L := Vector3(-0.15, -1.0, -0.1)
const HAMMER_LEVEL := {Winchester73State.Hammer.DOWN: 0.0, Winchester73State.Hammer.HALF_COCK: 1.0,
		Winchester73State.Hammer.FULL_COCK: 2.0}

@export var tuning: Winchester73Tuning

var state: Winchester73State
var model: Winchester73Model
var hand: HeldHand
var left_hand: HeldHand

## 0 at the hip, 1 at the shoulder (moves at 1 / shoulder_time).
var shoulder := 0.0
## The lever's throw shown (0 home, 1 open).
var lever_shown := 0.0

var _r_pivot: Node3D
var _aim_rot := Vector3.ZERO
var _aim_pos := Vector3.ZERO
var _hip_pos := Vector3.ZERO
var _load_pos := Vector3.ZERO
var _hammer := 0.0
var _trigger := 0.0
var _thumb := 0.0
var _gate := 0.0
var _cover := 0.0
var _reload_held := 0.0
var _cock_held := 0.0
## The lever key went down with a round in and the hammer back: let go it works the lever, held it
## eases the hammer to half cock.
var _cock_pending := false


func _ready() -> void:
	add_to_group(&"winchester")
	if tuning == null:
		tuning = load("res://config/winchester73.tres")
	state = Winchester73State.new(tuning, hash(get_path()) + 73)
	_rng.seed = 73
	model = Winchester73Model.new()
	model.name = "Winchester"
	add_child(model)
	model.build()
	_place_poses()
	_build_hands()
	_pose_pos = _hip_pos
	_pose_rot = HIP_ROT
	_setup_common()
	for id in [&"gunshot", &"cock", &"dry_fire", &"break_open", &"close", &"insert", &"eject", &"gate"]:
		_add_sound(id, id == &"gunshot")
	state.lever_opened.connect(_on_lever_opened)
	state.lever_closed.connect(func() -> void: _play(&"close"))
	state.ejected.connect(_on_ejected)
	state.fired.connect(_on_fired)
	state.clicked.connect(func() -> void: _play(&"dry_fire"); _hammer = 0.0)
	state.misfired.connect(func() -> void: _play(&"dry_fire"); _hammer = 0.0)
	state.hammer_changed.connect(_on_hammer)
	state.gate_loaded.connect(func() -> void: _play(&"insert"); _gate = 1.0)
	state.cover_changed.connect(func(_o: bool) -> void: _play(&"gate"))
	_apply_pose(_draw)
	_muzzle_local = model.marker("Muzzle")


## The poses from the gun's own markers: aimed, the line from the notch to the blade along your
## view, the notch EYE_RELIEF in front of your eye; at the hip and turned to load, the wrist (the
## right hand's place) where the lab's sheets had it.
func _place_poses() -> void:
	var rear := model.marker("SightRear")
	var front := model.marker("SightFront")
	var b := Basis.looking_at(front - rear, Vector3.UP).inverse()
	_aim_rot = b.get_euler(EULER_ORDER_YXZ) * (180.0 / PI)
	_aim_pos = Vector3(0.0, 0.0, -EYE_RELIEF) - b * rear
	var wrist := Winchester73Model.design(-4.6, -1.8)
	_hip_pos = HIP_WRIST - Basis.from_euler(HIP_ROT * (PI / 180.0), EULER_ORDER_YXZ) * wrist
	_load_pos = LOAD_AT - Basis.from_euler(LOAD_ROT * (PI / 180.0), EULER_ORDER_YXZ) * Winchester73Model.design(-1.2, -0.9)


## Where the sights put your eye (camera space), for tests and the bridge.
func aim_pose() -> Array:
	return [_aim_pos, _aim_rot]


func _build_hands() -> void:
	_r_pivot = Node3D.new()
	_r_pivot.name = "RightHandLever"
	_r_pivot.position = model.lever_pivot
	model.add_child(_r_pivot)
	hand = _held_along(true, _r_pivot, Winchester73Model.design(R_HAND.x, R_HAND.y, R_HAND.z) - model.lever_pivot,
			R_WRIST_DIR, R_PALM_DIR, R_FOREARM)
	for f: String in R_GRIP:
		hand.grasp(f, R_GRIP[f])
	hand.grasp("index", R_INDEX_REST, R_INDEX_SPREAD)
	left_hand = _held_along(false, model, Winchester73Model.design(L_HAND.x, L_HAND.y, L_HAND.z),
			L_WRIST_DIR, L_PALM_DIR, L_FOREARM)
	for f: String in L_GRIP:
		left_hand.grasp(f, L_GRIP[f])
	left_hand.thumb_pose(L_THUMB[0], L_THUMB[1], L_THUMB[2])
	_set_shoulders(0.0)


## A hand at `pos` in `parent`'s space laid along `wrist_dir` (from its knuckles back towards its
## wrist) with its palm towards `palm_dir`, its forearm aimed `forearm` (the coach gun's way).
static func _held_along(is_right: bool, parent: Node3D, pos: Vector3, wrist_dir: Vector3, palm_dir: Vector3, forearm: Vector3) -> HeldHand:
	var h := HeldHand.new(is_right)
	h.name = "Hand" if is_right else "LeftHand"
	h.position = pos
	var z := wrist_dir.normalized()
	var x := (palm_dir - z * palm_dir.dot(z)).normalized() * (-1.0 if is_right else 1.0)
	h.basis = Basis(x, z.cross(x), z)
	parent.add_child(h)
	h.build()
	h.aim_forearm(forearm)
	return h


func _set_shoulders(s: float) -> void:
	hand.shoulder = HIP_SHOULDER_R.lerp(AIM_SHOULDER_R, s)
	hand.elbow_pole = HIP_POLE_R.lerp(AIM_POLE_R, s)
	left_hand.shoulder = HIP_SHOULDER_L.lerp(AIM_SHOULDER_L, s)
	left_hand.elbow_pole = HIP_POLE_L.lerp(AIM_POLE_L, s)


func _process(delta: float) -> void:
	state.tick(delta)
	if _can_act():
		_read_controls(delta)
	elif not drawn:
		aiming = false
	# On your back and not coming out: nothing to pose (the hands' arm solve stops with it).
	var away := not drawn and _draw <= 0.0
	if away and not visible:
		_set_hands_posing(false)
		return
	_set_hands_posing(true)
	_animate(delta)


func _set_hands_posing(on: bool) -> void:
	if hand and hand.is_processing() != on:
		hand.set_process(on)
		left_hand.set_process(on)


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
		_cock_pending = false
		return
	var want_aim := Input.is_action_pressed(&"aim") and _action_ok(&"aim")
	if want_aim and state.loading:
		state.stop_loading()
	_want_shoulder = want_aim and not state.loading
	if Input.is_action_just_pressed(&"reload"):
		_reload_held = 0.0
		reload_press()
	elif Input.is_action_pressed(&"reload"):
		_reload_held += delta
		if _reload_held > 0.3 and state.ready() and state.loading:
			reload_press()
	if Input.is_action_just_pressed(&"cock"):
		_cock_held = 0.0
		if _hold_decides():
			_cock_pending = true
		else:
			cock_press()
	elif _cock_pending:
		_cock_held += delta
		if not Input.is_action_pressed(&"cock"):
			_cock_pending = false
			cock_press()
		elif _cock_held >= tuning.half_cock_hold:
			_cock_pending = false
			state.half_cock()
	if Input.is_action_just_pressed(&"fire") and _action_ok(&"fire"):
		pull_trigger()
	if Settings.auto_cock and state.ready() and not state.lever_open and state.chamber != Winchester73State.Round.LOADED \
			and state.tube > 0 and state.hammer == Winchester73State.Hammer.DOWN:
		state.work_lever()


var _want_shoulder := false


## With a round in and the hammer back, the lever key waits to see if it's held (half cock) or let go
## (the lever: out with the live round).
func _hold_decides() -> bool:
	return state.hammer == Winchester73State.Hammer.FULL_COCK and state.chamber == Winchester73State.Round.LOADED \
			and not state.lever_open


## The lever key's tap: thumb the hammer back if a live round's in and it isn't cocked, else work
## the lever.
func cock_press() -> void:
	if state.lever_open:
		return
	if state.chamber == Winchester73State.Round.LOADED and state.hammer != Winchester73State.Hammer.FULL_COCK:
		state.thumb_cock()
	else:
		work_lever()


func work_lever() -> bool:
	return state.work_lever()


func half_cock() -> bool:
	return state.half_cock()


## One press of the reload key: a round through the gate; with nothing to load, the gun comes back
## round.
func reload_press() -> void:
	if not state.load_round():
		state.stop_loading()


func pull_trigger() -> Winchester73State.Shot:
	_trigger = 1.0
	return state.pull_trigger()


func toggle_cover() -> void:
	state.set_cover(not state.cover_open)


func toggle_holster() -> void:
	drawn = not drawn
	if not drawn:
		aiming = false
		_want_shoulder = false
		state.stop_loading()
		# Before it goes on your back: the lever home, the hammer eased to half cock over a live
		# round (or left down), the dust cover slid shut.
		if state.lever_open:
			state.busy = 0.0
			state.close_lever()
		if state.hammer == Winchester73State.Hammer.FULL_COCK and state.chamber == Winchester73State.Round.LOADED:
			state.hammer = Winchester73State.Hammer.HALF_COCK
		elif state.hammer == Winchester73State.Hammer.FULL_COCK:
			state.hammer = Winchester73State.Hammer.DOWN
		state.set_cover(false)
		state.busy = 0.0


func put_away() -> void:
	aiming = false
	if drawn:
		toggle_holster()


func take_out() -> void:
	if not drawn:
		toggle_holster()


## Shouldered and steady on the sights (the sway and the spread are the aimed ones).
func is_shouldered() -> bool:
	return aiming


func _why_not(action: StringName) -> String:
	if state == null:
		return ""
	match action:
		&"fire":
			if state.lever_open:
				return ""
			if state.hammer == Winchester73State.Hammer.HALF_COCK:
				return "it's on half cock: Q to cock it"
			if state.chamber != Winchester73State.Round.LOADED:
				if state.rounds_loaded() > 0:
					return "work the lever (Q)"
				return "it's empty: load it through the gate (R)" if state.cartridges() > 0 else "you're out of cartridges"
		&"reload":
			if state.tube >= tuning.magazine:
				return "the tube's full (%d)" % tuning.magazine
			if state.cartridges() <= 0:
				return "you've no cartridges left to load (%d in the gun)" % state.rounds_loaded()
		&"cock":
			if state.rounds_loaded() == 0 and state.chamber == Winchester73State.Round.EMPTY:
				return "it's empty: load it through the gate (R)" if state.cartridges() > 0 else "you're out of cartridges"
	return ""


func _on_lever_opened() -> void:
	_play(&"break_open")
	_unsettle()


func _on_hammer(h: int) -> void:
	if h != Winchester73State.Hammer.DOWN and not state.lever_open:
		_play(&"cock")
		_thumb = 1.0


func _on_fired() -> void:
	_hammer = 0.0
	_in_tick(_fire)


func _fire() -> void:
	var line := _shot_line((model.markers["Muzzle"] as Marker3D).global_position)
	var origin: Vector3 = line[0]
	var dir: Vector3 = line[1]
	var exclude: Array[RID] = line[2]
	var spread := lerpf(tuning.spread_hip_degrees, tuning.spread_aim_degrees, _sighted()) + _wobble()
	if _player:
		spread += _player.get_horizontal_speed() * 0.5
	dir = _cone(dir, deg_to_rad(spread))
	var ballistics := _ballistics()
	var bullet := ballistics.fire(origin, dir, tuning.muzzle_velocity, tuning.bullet_mass, tuning.bullet_diameter, exclude)
	bullet.form = tuning.form_factor
	bullet.shooter = _player
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir, 1.4)
	ImpactEffects.muzzle_flash(world, origin)
	if GameAudio.enabled():
		GameAudio.gunshot(self, origin, false, true)
	else:
		_play(&"gunshot")
	Events.shot_fired.emit(origin, dir, _player)
	_kick_shot(tuning)
	_unsettle()


## How much the shot is a sighted one: 0 from the hip, 1 with your eye down the sights.
func _sighted() -> float:
	return smoothstep(0.5, 1.0, shoulder) if _want_shoulder or aiming else 0.0


func _load() -> Dictionary:
	return {"speed": tuning.muzzle_velocity, "mass": tuning.bullet_mass, "diameter": tuning.bullet_diameter,
			"form": tuning.form_factor, "zero": tuning.zero_distance}


## What the extractor pulled is thrown up and out of the port to the right, as the bolt comes back.
func _on_ejected(round_state: int) -> void:
	_play(&"eject")
	var at := (model.markers["Port"] as Marker3D).global_position
	var b := model.global_transform.basis
	var push := b.y * 1.6 + b.x * 0.7 + b.z * 0.4
	var live := round_state == Winchester73State.Round.LOADED or round_state == Winchester73State.Round.DUD
	var world := _ballistics().get_parent()
	get_tree().create_timer(tuning.lever_open_time * 0.6).timeout.connect(func() -> void:
		if is_instance_valid(world):
			var c := ImpactEffects.spent_case(world, at, push, 0.0067, 0.0404 if live else 0.0331, 0.0165 if live else 0.006)
			c.name = "LiveRound" if live else "SpentCase")


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / tuning.draw_time)
	visible = _draw > 0.02
	var want := _want_shoulder and drawn and _draw >= 0.9
	shoulder = move_toward(shoulder, 1.0 if want else 0.0, delta / maxf(tuning.shoulder_time, 0.01))
	aiming = want and shoulder >= 0.85
	sway_factor = lerpf(tuning.sway_hip, tuning.sway_aimed, smoothstep(0.0, 1.0, shoulder))
	shake_factor = lerpf(1.0, tuning.tremor_aimed, smoothstep(0.0, 1.0, shoulder))
	var s := smoothstep(0.0, 1.0, shoulder)
	var target_pos := _hip_pos.lerp(_aim_pos, s)
	var target_rot := HIP_ROT.lerp(_aim_rot, s)
	if state.loading:
		target_pos = _load_pos
		target_rot = LOAD_ROT
	var k := 1.0 - exp(-delta * 14.0)
	_pose_pos = _pose_pos.lerp(target_pos, k)
	_pose_rot = _pose_rot.lerp(target_rot, k)
	kick.step(delta)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * (16.0 if _tuck_target > tuck else 8.0)))
	_update_sway(delta)
	_set_shoulders(s)

	# The lever: out over lever_open_time, home over lever_close_time; the bolt, carrier and the
	# hand with it.
	var opening := state.lever_open
	lever_shown = move_toward(lever_shown, 1.0 if opening else 0.0,
			delta / maxf(tuning.lever_open_time if opening else tuning.lever_close_time, 0.01))
	model.lever(lever_shown, not opening)
	_r_pivot.basis = Basis(Vector3.RIGHT, deg_to_rad(model.lever_deg(lever_shown) * R_LEVER_SHARE))
	# The hammer: pushed back by the bolt as the lever opens; thumbed or eased to its notch; falling
	# in an instant.
	var target: float = [0.0, model.hammer_half, model.hammer_full][int(HAMMER_LEVEL[state.hammer])]
	if opening:
		_hammer = maxf(_hammer, model.cocked_by(lever_shown))
	else:
		var rate := model.hammer_full / maxf(tuning.half_cock_time if target < _hammer else tuning.thumb_cock_time, 0.01)
		_hammer = move_toward(_hammer, target, delta * rate)
	model.set_hammer(_hammer)
	_trigger = move_toward(_trigger, 0.0, delta * 5.0)
	model.trigger(_trigger)
	hand.grasp("index", lerpf(R_INDEX_REST, R_INDEX_PULL, _trigger), R_INDEX_SPREAD)
	_thumb = move_toward(_thumb, 0.0, delta * 3.0)
	hand.thumb_pose((R_THUMB_REST[0] as Vector3).lerp(R_THUMB_COCK[0], _thumb), lerpf(R_THUMB_REST[1], R_THUMB_COCK[1], _thumb),
			lerpf(R_THUMB_REST[2], R_THUMB_COCK[2], _thumb))
	_cover = move_toward(_cover, 1.0 if state.cover_open else 0.0, delta / maxf(tuning.lever_open_time, 0.01))
	model.cover(_cover)
	_gate = move_toward(_gate, 0.0, delta / maxf(tuning.gate_round_time * 0.5, 0.01))
	model.gate(_gate)
	model.show_rounds(state.chamber, state.carrier, state.tube > 0)
	_apply_pose(_draw)
	_animate_camera(delta, tuning.aim_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var d := smoothstep(0.0, 1.0, drawn_amount)
	# Working the lever the gun dips a little in your hands (off the cheek less than at the hip).
	var dip := Vector3(-lerpf(6.0, 2.5, shoulder) * sin(PI * lever_shown), 0.0, 0.0)
	var pos := PUT_AWAY_POS.lerp(_pose_pos.lerp(TUCK_POS, t), d) + Vector3(0.0, kick.back * 0.2, kick.back) \
			+ _body_pos() * drawn_amount
	var rot := PUT_AWAY_ROT.lerp(_pose_rot.lerp(TUCK_ROT, t) + dip, d) \
			+ Vector3(kick.pitch, -kick.yaw, -kick.roll) * (1.0 - t) \
			+ _sway_rotation() * (1.0 - t) * (0.0 if state.loading else 1.0)
	position = pos
	rotation_degrees = rot
