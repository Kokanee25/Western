class_name RevolverViewmodel
extends Node3D
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
## Clearance kept between the muzzle and the wall, and over how much extra closeness the gun goes
## from fully out to fully tucked (metres).
const TUCK_MARGIN := 0.06
const TUCK_RANGE := 0.22
## What the gun can't pass through: the world and living people (not debris, not the player).
const TUCK_MASK := Layers.WORLD | Layers.PEOPLE
const HAMMER_ANGLES := {RevolverState.Hammer.DOWN: 0.0, RevolverState.Hammer.HALF_COCK: 22.0, RevolverState.Hammer.FULL_COCK: 44.0}

@export var tuning: RevolverTuning

var state: RevolverState
var drawn := true
var aiming := false
## Wounds: hands busy pressing on a wound, or the gun arm can't hold it (PlayerWounds sets these).
var hands_busy := false
var arm_disabled := false
## Extra wobble from pain, shock and a wounded arm, degrees.
var extra_spread := 0.0
## Tests and scripted scenes drive the gun without a captured mouse.
var needs_captured_mouse := true

var model: RevolverModel
var hand: HandModel

var _player: Player
var _rng := RandomNumberGenerator.new()
var _pose_pos := POSES[Pose.HIP][0] as Vector3
var _pose_rot := POSES[Pose.HIP][1] as Vector3
var _draw := 1.0
var _hammer := 0.0
var _cyl := 0.0
var _gate := 0.0
var _trigger := 0.0
var _thumb := 0.0
var _recoil := 0.0
var _view_kick := 0.0
var _ejector := 0.0
var _reload_held := 0.0
var _base_fov := 75.0
var _sounds := {}
## 0 = gun out in its pose, 1 = pulled right back against a wall. Smoothed; see _probe_wall().
var tuck := 0.0
var _tuck_target := 0.0
var _muzzle_local := Vector3.ZERO
var _probe_shape := SphereShape3D.new()
## Where the last bullet started (tests check it can't start beyond a wall).
var last_shot_origin := Vector3.ZERO


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
	_player = _find_player()
	var cam := get_parent() as Camera3D
	if cam:
		_base_fov = cam.fov
	for id in [&"gunshot", &"cock", &"dry_fire", &"ratchet", &"gate", &"insert", &"eject"]:
		var p := AudioStreamPlayer3D.new()
		p.name = "Sound_" + id
		p.stream = SynthSounds.get_sound(id)
		p.unit_size = 25.0 if id == &"gunshot" else 2.0
		p.max_db = 6.0 if id == &"gunshot" else 0.0
		p.volume_db = 0.0 if id == &"gunshot" else -6.0
		add_child(p)
		_sounds[id] = p
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
	_probe_shape.radius = 0.03
	_warm_up.call_deferred()


func _warm_up() -> void:
	var cam := get_parent() as Camera3D
	if cam and is_inside_tree() and DisplayServer.get_name() != "headless":
		GunSmoke.warm_up(_ballistics().get_parent() as Node3D, cam)


func _find_player() -> Player:
	var n := get_parent()
	while n and not n is Player:
		n = n.get_parent()
	return n as Player


func _process(delta: float) -> void:
	state.tick(delta)
	if _can_act():
		_read_controls(delta)
	_animate(delta)


func _physics_process(_delta: float) -> void:
	_tuck_target = _probe_wall()


## How far the gun must pull back so the muzzle, in the pose it's heading for, stops short of
## whatever is in front: a small sphere swept from the eye to where the muzzle would be.
func _probe_wall() -> float:
	var cam := get_parent() as Node3D
	if cam == null or not is_inside_tree() or _draw < 0.5:
		return 0.0
	var pose_basis := Basis.from_euler(_pose_rot * (PI / 180.0), EULER_ORDER_YXZ)
	var muzzle_cam := Transform3D(pose_basis, _pose_pos) * _muzzle_local
	var reach := muzzle_cam.length()
	if reach < 0.01:
		return 0.0
	var from := cam.global_position
	var to := cam.global_transform * (muzzle_cam * ((reach + TUCK_MARGIN) / reach))
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _probe_shape
	q.transform = Transform3D(Basis.IDENTITY, from)
	q.motion = to - from
	q.collision_mask = TUCK_MASK
	if _player:
		q.exclude = [_player.get_rid()]
	var fractions := get_world_3d().direct_space_state.cast_motion(q)
	var free := fractions[0] * (reach + TUCK_MARGIN)
	return clampf((reach + TUCK_MARGIN - free) / TUCK_RANGE, 0.0, 1.0)


func _can_act() -> bool:
	return not (_player and not _player.input_enabled)


## Mouse buttons only count once the game has the mouse (the click that grabs it shouldn't fire).
## Keys, pads and touch always work.
func _mouse_ready() -> bool:
	if not needs_captured_mouse or DisplayServer.get_name() == "headless" or DisplayServer.is_touchscreen_available():
		return true
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func _pressed_by_mouse_only(action: StringName) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventMouseButton and Input.is_mouse_button_pressed((ev as InputEventMouseButton).button_index):
			return true
	return false


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
	aiming = Input.is_action_pressed(&"aim") and not state.gate_open and (_mouse_ready() or not _pressed_by_mouse_only(&"aim"))
	if Input.is_action_just_pressed(&"reload"):
		_reload_held = 0.0
		reload_press()
	elif Input.is_action_pressed(&"reload"):
		_reload_held += delta
		if _reload_held > 0.3 and state.ready():
			reload_press()
	if Input.is_action_just_pressed(&"cock"):
		cock_press()
	if Input.is_action_just_pressed(&"fire") and (_mouse_ready() or not _pressed_by_mouse_only(&"fire")):
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


func _on_fired() -> void:
	var cam := get_viewport().get_camera_3d() if get_viewport() else null
	var origin := model.muzzle.global_position
	var aim_dir := -global_transform.basis.z
	var aim_point := origin + aim_dir * 60.0
	var exclude: Array[RID] = []
	if _player:
		exclude.append(_player.get_rid())
	if cam:
		# Never start the bullet beyond a wall: if something lies between the eye and the muzzle,
		# the ball leaves from just this side of it (and hits it).
		var q0 := PhysicsRayQueryParameters3D.create(cam.global_position, origin, Layers.BULLETS)
		q0.exclude = exclude
		var blocked := get_world_3d().direct_space_state.intersect_ray(q0)
		if not blocked.is_empty():
			origin = blocked.position + (cam.global_position - blocked.position).normalized() * 0.01
	if cam:
		aim_dir = -cam.global_transform.basis.z
		aim_point = cam.global_position + aim_dir * 80.0
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, aim_point, Layers.BULLETS)
		q.exclude = exclude
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and cam.global_position.distance_to(hit.position) > 0.6:
			aim_point = hit.position
	var dir := (aim_point - origin).normalized()
	last_shot_origin = origin
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


func _ballistics() -> Ballistics:
	var b := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if b == null:
		b = Ballistics.new()
		b.name = "Ballistics"
		var host: Node = _player.get_parent() if _player else get_tree().current_scene
		host.add_child(b)
	return b


func _cone(dir: Vector3, half_angle: float) -> Vector3:
	if half_angle <= 0.0:
		return dir
	var axis := dir.cross(Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT).normalized()
	var off := dir.rotated(axis, _rng.randf() * half_angle)
	return off.rotated(dir, _rng.randf() * TAU).normalized()


func _play(id: StringName) -> void:
	var p: AudioStreamPlayer3D = _sounds.get(id)
	if p:
		p.play()


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

	var cam := get_parent() as Camera3D
	if cam:
		_view_kick = move_toward(_view_kick, 0.0, delta * (4.0 + _view_kick * 6.0))
		cam.rotation.x = deg_to_rad(_view_kick)
		cam.fov = lerpf(cam.fov, tuning.aim_fov if aiming else _base_fov, 1.0 - exp(-delta * 10.0))


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var pos := HOLSTER_POS.lerp(_pose_pos.lerp(TUCK_POS, t), drawn_amount) + Vector3(0.0, 0.012, 0.06) * _recoil
	var rot := _pose_rot.lerp(TUCK_ROT, t) + Vector3(24.0 * _recoil * (1.0 - t), 0.0, 0.0)
	position = pos
	rotation_degrees = rot
