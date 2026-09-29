class_name ShotgunViewmodel
extends WeaponViewmodel
## The coach gun in your hands. Reads the controls, runs the mechanism (ShotgunState), animates
## the barrels, hammers, triggers, lever and both hands, and fires a charge of buckshot through
## Ballistics: every pellet is its own projectile, spreading as it flies. Sits under the camera
## beside the revolver; the player switches between them.
##
## Controls: fire (LMB / RT) pulls the trigger of the next cocked barrel; cock (Q, wheel down, RB)
## thumbs back the next hammer; aim (RMB / LT) shoulders it; reload (R / X) breaks it open, pulls
## the empties, thumbs in fresh shells (hold to keep going; press again, or cock, to close it);
## holster (H / LB) lowers it.

enum Pose { HIP, AIM, LOADING }

const POSES := {
	Pose.HIP: [Vector3(0.11, -0.2, -0.22), Vector3(3.0, 4.0, 0.0)],
	Pose.AIM: [Vector3(0.0, -0.056, -0.32), Vector3(0.6, 0.0, 0.0)],
	Pose.LOADING: [Vector3(0.04, -0.12, -0.3), Vector3(-8.0, 14.0, 6.0)],
}
const PUT_AWAY_POS := Vector3(0.25, -0.8, 0.05)
## Up against a wall the barrels come up and back (port arms) instead of pushing through.
const TUCK_POS := Vector3(0.1, -0.24, -0.02)
const TUCK_ROT := Vector3(62.0, 12.0, -8.0)
## How far the barrels drop when it's broken open (degrees).
const OPEN_ANGLE := -32.0
const HAMMER_BACK := 40.0

@export var tuning: ShotgunTuning

var state: ShotgunState
var model: ShotgunModel
## The right hand round the wrist of the stock (index finger on the triggers, thumb for the
## hammers) and the left under the forend; finger by finger, like the revolver's hand.
var hand: Node3D
var left_hand: Node3D
var _index: Node3D
var _thumb_pivot: Node3D

var _open := 0.0
var _hammers := [0.0, 0.0]
var _triggers := [0.0, 0.0]
var _thumb := 0.0
var _recoil := 0.0
var _reload_held := 0.0


func _ready() -> void:
	add_to_group(&"shotgun")
	if tuning == null:
		tuning = load("res://config/shotgun.tres")
	state = ShotgunState.new(tuning, hash(get_path()) + 7)
	_rng.seed = 12
	model = ShotgunModel.new()
	model.name = "Shotgun"
	add_child(model)
	_build_hands()
	_pose_pos = POSES[Pose.HIP][0]
	_pose_rot = POSES[Pose.HIP][1]
	_setup_common()
	for id in [&"shotgun", &"cock", &"dry_fire", &"break_open", &"close", &"insert", &"eject"]:
		_add_sound(id, id == &"shotgun")
	state.cocked.connect(func(_i: int) -> void: _play(&"cock"); _thumb = 1.0)
	state.fired.connect(_on_fired)
	state.clicked.connect(func(_i: int) -> void: _play(&"dry_fire"))
	state.misfired.connect(func(_i: int) -> void: _play(&"dry_fire"))
	state.opened.connect(func(o: bool) -> void: _play(&"break_open" if o else &"close"))
	state.extracted.connect(_on_extracted)
	state.loaded.connect(func(_i: int) -> void: _play(&"insert"))
	_apply_pose(_draw)
	_muzzle_local = model.transform * (ShotgunModel.HINGE + model.muzzles[0].position)


func _build_hands() -> void:
	var skin := GunParts.skin()
	var sleeve := GunParts.cloth("shirt", Color(0.74, 0.67, 0.54))
	var cuff := GunParts.cloth("cuff", Color(0.68, 0.61, 0.49))
	# Right hand: the back of it on the right of the wrist, fingers curled under, forearm running
	# back and down to the right, out of the sight line.
	hand = GunParts.pivot(model, "Hand", Vector3(0.0, 0.0, 0.035))
	GunParts.box(hand, "Back", Vector3(0.022, 0.045, 0.075), Vector3(0.024, -0.012, 0.0), skin)
	for i in 3:
		GunParts.box(hand, "Finger%d" % i, Vector3(0.05, 0.016, 0.017), Vector3(0.0, -0.028, -0.004 + i * 0.019), skin)
	_index = GunParts.pivot(hand, "Index", Vector3(0.014, -0.02, -0.04))
	GunParts.box(_index, "Bone", Vector3(0.016, 0.016, 0.03), Vector3(-0.008, 0.0, -0.013), skin, Vector3(0, 25, 0))
	_thumb_pivot = GunParts.pivot(hand, "Thumb", Vector3(0.014, 0.02, -0.02))
	GunParts.box(_thumb_pivot, "Bone", Vector3(0.016, 0.016, 0.04), Vector3(-0.006, 0.004, -0.018), skin, Vector3(0, 20, 0))
	var arm := GunParts.pivot(hand, "Forearm", Vector3(0.03, -0.02, 0.035))
	arm.rotation_degrees = Vector3(38.0, 24.0, 0.0)
	GunParts.box(arm, "Wrist", Vector3(0.05, 0.05, 0.05), Vector3(0, 0, 0.02), skin)
	GunParts.box(arm, "Cuff", Vector3(0.066, 0.064, 0.04), Vector3(0, 0, 0.065), cuff)
	GunParts.box(arm, "Sleeve", Vector3(0.072, 0.07, 0.24), Vector3(0, 0, 0.2), sleeve)
	# Left hand: the forend lies across the palm, fingers up the right side, thumb up the left;
	# the forearm goes back and down to the left. It rides the barrels when the gun breaks open.
	var y := ShotgunModel.BARREL_Y - 0.026
	left_hand = GunParts.pivot(model.barrels, "LeftHand", Vector3(0.0, y, -0.07))
	GunParts.box(left_hand, "Palm", Vector3(0.05, 0.02, 0.075), Vector3(-0.004, -0.021, 0.0), skin)
	for i in 4:
		GunParts.box(left_hand, "Finger%d" % i, Vector3(0.016, 0.032, 0.016), Vector3(0.026, -0.004, -0.028 + i * 0.018), skin, Vector3(0, 0, -8))
	GunParts.box(left_hand, "Thumb", Vector3(0.015, 0.028, 0.04), Vector3(-0.026, -0.002, -0.01), skin, Vector3(0, 0, 10))
	var larm := GunParts.pivot(left_hand, "Forearm", Vector3(-0.01, -0.03, 0.03))
	larm.rotation_degrees = Vector3(40.0, -18.0, 0.0)
	GunParts.box(larm, "Wrist", Vector3(0.05, 0.05, 0.05), Vector3(0, 0, 0.02), skin)
	GunParts.box(larm, "Cuff", Vector3(0.066, 0.064, 0.04), Vector3(0, 0, 0.065), cuff)
	GunParts.box(larm, "Sleeve", Vector3(0.072, 0.07, 0.3), Vector3(0, 0, 0.23), sleeve)


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
	aiming = Input.is_action_pressed(&"aim") and not state.open and _action_ok(&"aim")
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
	if Settings.auto_cock and not state.open and state.ready() and not state.cocked_hammers.has(true):
		state.cock()


func cock_press() -> void:
	if state.open:
		state.close_action()
	else:
		state.cock()


func reload_press() -> void:
	if not state.reload_step():
		state.close_action()


func pull_trigger() -> ShotgunState.Shot:
	var shot := state.pull_trigger()
	if state.last_barrel >= 0:
		_triggers[state.last_barrel] = 1.0
	return shot


func toggle_holster() -> void:
	drawn = not drawn
	if not drawn:
		aiming = false
		if state.open:
			state.open = false
		state.cocked_hammers = [false, false]


func put_away() -> void:
	aiming = false
	if drawn:
		toggle_holster()


func take_out() -> void:
	if not drawn:
		toggle_holster()


func _on_fired(barrel: int) -> void:
	var line := _shot_line(model.muzzles[barrel].global_position)
	var origin: Vector3 = line[0]
	var dir: Vector3 = line[1]
	var exclude: Array[RID] = line[2]
	var wobble := (tuning.spread_aim_degrees if aiming else tuning.spread_hip_degrees) + extra_spread
	if _player:
		wobble += _player.get_horizontal_speed() * 0.5
	dir = _cone(dir, deg_to_rad(wobble))
	var ballistics := _ballistics()
	var pellets := ballistics.fire_charge(origin, dir, tuning.pellets, deg_to_rad(tuning.pattern_degrees),
			tuning.muzzle_velocity, tuning.pellet_mass, tuning.pellet_diameter, exclude, _rng, tuning.blast_joules, tuning.blast_reach)
	for p in pellets:
		p.shooter = _player
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir, 1.8)
	ImpactEffects.muzzle_flash(world, origin)
	_play(&"shotgun")
	Events.shot_fired.emit(origin, dir, _player)
	_recoil = 1.0
	if _player:
		_player.add_look(Vector2(_rng.randf_range(-0.8, 0.8), tuning.recoil_degrees * (1.0 - tuning.recoil_recovery)))
	_view_kick += tuning.recoil_degrees * tuning.recoil_recovery


func _on_extracted(barrel: int, _barrel_state: int) -> void:
	_play(&"eject")
	var at := model.chamber_points[barrel].global_position
	# Plucked out and flicked away over the right shoulder.
	var push := model.global_transform.basis.z * 1.1 + model.global_transform.basis.x * 0.6 + Vector3.UP * 0.8
	var world := _ballistics().get_parent()
	get_tree().create_timer(0.1).timeout.connect(func() -> void:
		if is_instance_valid(world):
			var hull := ImpactEffects.spent_case(world, at, push, 0.0105, 0.064, 0.025)
			hull.name = "SpentShell")


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / tuning.draw_time)
	visible = _draw > 0.02
	var pose := Pose.LOADING if state.open else (Pose.AIM if aiming else Pose.HIP)
	var k := 1.0 - exp(-delta * 10.0)
	_pose_pos = _pose_pos.lerp(POSES[pose][0], k)
	_pose_rot = _pose_rot.lerp(POSES[pose][1], k)
	_recoil = move_toward(_recoil, 0.0, delta * 3.5)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * (16.0 if _tuck_target > tuck else 8.0)))
	_apply_pose(_draw)

	_open = move_toward(_open, OPEN_ANGLE if state.open else 0.0, delta * absf(OPEN_ANGLE) / 0.2)
	model.barrels.rotation_degrees.x = _open
	model.lever.rotation_degrees.y = -35.0 * clampf(_open / OPEN_ANGLE, 0.0, 1.0)
	for i in 2:
		var target := HAMMER_BACK if state.cocked_hammers[i] else 0.0
		_hammers[i] = target if target < _hammers[i] else move_toward(_hammers[i], target, delta * HAMMER_BACK / maxf(tuning.cock_time, 0.01))
		model.hammers[i].rotation_degrees.x = _hammers[i]
		_triggers[i] = move_toward(_triggers[i], 0.0, delta * 5.0)
		model.triggers[i].rotation_degrees.x = -18.0 * _triggers[i]
	_index.rotation_degrees.x = -30.0 - 25.0 * maxf(_triggers[0], _triggers[1])
	_thumb = move_toward(_thumb, 0.0, delta * 3.0)
	_thumb_pivot.rotation_degrees = Vector3(-10.0 + 35.0 * _thumb, 0.0, 0.0)
	model.show_barrels(state.barrels)
	model.butt.visible = not (selected and _pose_pos.distance_to(POSES[Pose.AIM][0]) < 0.06 and tuck < 0.3)
	_animate_camera(delta, tuning.aim_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var pos := PUT_AWAY_POS.lerp(_pose_pos.lerp(TUCK_POS, t), drawn_amount) + Vector3(0.0, 0.01, 0.07) * _recoil
	var rot := _pose_rot.lerp(TUCK_ROT, t) + Vector3(14.0 * _recoil * (1.0 - t), 0.0, 0.0)
	position = pos
	rotation_degrees = rot
