class_name RevolverViewmodel
extends WeaponViewmodel
## The revolver in your hand. Reads the controls, runs the mechanism (RevolverState), animates
## every moving part and the hand, and fires real bullets through Ballistics with smoke, flash,
## spent brass and sound. Sits under the player's camera.
##
## Controls: fire (LMB / RT) squeezes the trigger; cock (Q, mouse wheel down, RB) thumbs the hammer;
## aim (RMB / LT) raises the sights; reload (R / X) opens the gate and works round the cylinder
## (hold to keep going; press again when full to close); holster (H / LB).

enum Pose { HIP, AIM, LOADING }

const POSES := {
	Pose.HIP: [Vector3(0.14, -0.16, -0.34), Vector3(1.5, 4.0, 0.0)],
	Pose.AIM: [Vector3(0.0, -0.073, -0.3), Vector3(4.0, 0.0, 0.0)],
	Pose.LOADING: [Vector3(0.03, -0.12, -0.29), Vector3(20.0, 24.0, 58.0)],
}
const HOLSTER_POS := Vector3(0.22, -0.55, -0.12)
## Up close to a wall (or a person) the gun comes back to the chest, muzzle up, instead of
## pushing through: a compressed high ready.
const TUCK_POS := Vector3(0.15, -0.26, -0.14)
const TUCK_ROT := Vector3(55.0, 22.0, -25.0)
const HAMMER_ANGLES := {RevolverState.Hammer.DOWN: 0.0, RevolverState.Hammer.HALF_COCK: 22.0, RevolverState.Hammer.FULL_COCK: 44.0}

@export var tuning: RevolverTuning

var state: RevolverState

var model: RevolverModel
var hand: HandModel

var _hammer := 0.0
var _cyl := 0.0
var _gate := 0.0
var _trigger := 0.0
var _thumb := 0.0
var _recoil := 0.0
var _ejector := 0.0
var _reload_held := 0.0


func _ready() -> void:
	add_to_group(&"revolver")
	if tuning == null:
		tuning = load("res://config/revolver.tres")
	state = RevolverState.new(tuning, hash(get_path()))
	_rng.seed = 45
	model = RevolverModel.new()
	model.name = "Revolver"
	add_child(model)
	hand = HandModel.new()
	hand.name = "Hand"
	add_child(hand)
	_pose_pos = POSES[Pose.HIP][0]
	_pose_rot = POSES[Pose.HIP][1]
	_setup_common()
	for id in [&"gunshot", &"cock", &"dry_fire", &"ratchet", &"gate", &"insert", &"eject"]:
		_add_sound(id, id == &"gunshot")
	state.cocked.connect(func() -> void: _play(&"cock"); _thumb = 1.0)
	state.fired.connect(_on_fired)
	state.clicked.connect(func() -> void: _play(&"dry_fire"))
	state.misfired.connect(func() -> void: _play(&"dry_fire"))
	state.gate_changed.connect(func(_open: bool) -> void: _play(&"gate"))
	state.cylinder_turned.connect(func() -> void: if state.gate_open: _play(&"ratchet"))
	state.ejected.connect(_on_ejected)
	state.inserted.connect(func() -> void: _play(&"insert"))
	_apply_pose(1.0)
	_muzzle_local = model.transform * model.to_local(model.muzzle.global_position) if model.is_inside_tree() else Vector3(0, 0.02, -0.3)
	_warm_up.call_deferred()


func _warm_up() -> void:
	var cam := get_parent() as Camera3D
	if cam and is_inside_tree() and DisplayServer.get_name() != "headless":
		GunSmoke.warm_up(_ballistics().get_parent() as Node3D, cam)


func _process(delta: float) -> void:
	state.tick(delta)
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
	aiming = Input.is_action_pressed(&"aim") and not state.gate_open and _action_ok(&"aim")
	if Input.is_action_just_pressed(&"reload"):
		_reload_held = 0.0
		reload_press()
	elif Input.is_action_pressed(&"reload"):
		_reload_held += delta
		if _reload_held > 0.3 and state.ready():
			reload_press()
	if Input.is_action_just_pressed(&"cock"):
		cock_press()
	if Input.is_action_just_pressed(&"fire") and _action_ok(&"fire"):
		pull_trigger()
	if Settings.auto_cock and state.hammer == RevolverState.Hammer.DOWN and not state.gate_open and state.ready():
		state.cock()


func cock_press() -> void:
	if state.gate_open:
		state.close_gate()
	else:
		state.cock()


func reload_press() -> void:
	if not state.reload_step():
		state.close_gate()


func pull_trigger() -> RevolverState.Shot:
	_trigger = 1.0
	return state.pull_trigger()


func toggle_holster() -> void:
	drawn = not drawn
	if not drawn and state.gate_open:
		state.gate_open = false
		state.hammer = RevolverState.Hammer.DOWN
	if _player and _player.body:
		_player.body.set_gun_holstered(not drawn)


func put_away() -> void:
	aiming = false
	if drawn:
		toggle_holster()


func take_out() -> void:
	if not drawn:
		toggle_holster()


func _on_fired() -> void:
	var line := _shot_line(model.muzzle.global_position)
	var origin: Vector3 = line[0]
	var dir: Vector3 = line[1]
	var exclude: Array[RID] = line[2]
	var spread := (tuning.spread_aim_degrees if aiming else tuning.spread_hip_degrees) + extra_spread
	if _player:
		spread += _player.get_horizontal_speed() * 0.5
	dir = _cone(dir, deg_to_rad(spread))
	var ballistics := _ballistics()
	var bullet := ballistics.fire(origin, dir, tuning.muzzle_velocity, tuning.bullet_mass, tuning.bullet_diameter, exclude)
	bullet.shooter = _player
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir)
	ImpactEffects.muzzle_flash(world, origin)
	_play(&"gunshot")
	Events.shot_fired.emit(origin, dir, _player)
	_recoil = 1.0
	if _player:
		_player.add_look(Vector2(_rng.randf_range(-0.4, 0.4), tuning.recoil_degrees * (1.0 - tuning.recoil_recovery)))
	_view_kick += tuning.recoil_degrees * tuning.recoil_recovery


func _on_ejected(_chamber_state: int) -> void:
	_play(&"eject")
	_ejector = 1.0
	var at := model.gate_point.global_position
	var push := model.global_transform.basis.x * 0.9 + Vector3(0, -0.4, 0)
	var world := _ballistics().get_parent()
	get_tree().create_timer(0.12).timeout.connect(func() -> void:
		if is_instance_valid(world):
			ImpactEffects.spent_case(world, at, push))


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / tuning.draw_time)
	visible = _draw > 0.02
	var pose := Pose.LOADING if state.gate_open else (Pose.AIM if aiming else Pose.HIP)
	var k := 1.0 - exp(-delta * 12.0)
	_pose_pos = _pose_pos.lerp(POSES[pose][0], k)
	_pose_rot = _pose_rot.lerp(POSES[pose][1], k)
	_recoil = move_toward(_recoil, 0.0, delta * 4.5)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * (18.0 if _tuck_target > tuck else 9.0)))
	_apply_pose(_draw)

	var hammer_target: float = HAMMER_ANGLES[state.hammer]
	_hammer = hammer_target if hammer_target < _hammer else move_toward(_hammer, hammer_target, delta * 44.0 / maxf(tuning.cock_time, 0.01))
	model.hammer.rotation_degrees.x = _hammer
	var cyl_target := state.under_hammer * 60.0 - (60.0 if state.gate_open else 0.0)
	_cyl = rad_to_deg(lerp_angle(deg_to_rad(_cyl), deg_to_rad(cyl_target), 1.0 - exp(-delta * 18.0)))
	model.cylinder.rotation_degrees.z = _cyl
	_gate = move_toward(_gate, -80.0 if state.gate_open else 0.0, delta * 400.0)
	model.gate.rotation_degrees.z = _gate
	_trigger = move_toward(_trigger, 0.0, delta * 5.0)
	model.trigger.rotation_degrees.x = -18.0 * _trigger
	hand.set_trigger(_trigger)
	_thumb = move_toward(_thumb, 0.0, delta * 3.5)
	hand.set_thumb(_thumb)
	_ejector = move_toward(_ejector, 0.0, delta * 3.0)
	model.ejector.position.z = -0.21 + 0.035 * _ejector
	model.show_chambers(state.chambers)

	_animate_camera(delta, tuning.aim_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var pos := HOLSTER_POS.lerp(_pose_pos.lerp(TUCK_POS, t), drawn_amount) + Vector3(0.0, 0.012, 0.06) * _recoil
	var rot := _pose_rot.lerp(TUCK_ROT, t) + Vector3(24.0 * _recoil * (1.0 - t), 0.0, 0.0)
	position = pos
	rotation_degrees = rot
