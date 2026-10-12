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
	sway_factor = 0.75  # shouldered: steadier than a revolver at arm's length
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
	var sleeve := GunParts.held_cloth("coat", Color(0.36, 0.25, 0.16))
	var cuff := GunParts.held_cloth("cuff", Color(0.82, 0.76, 0.62))
	var r := HandModel.FINGER_R
	# Right hand round the wrist of the stock: the palm on its right side, the fingers wrapped
	# under it to the left, the index forward through the guard onto the front trigger, the thumb
	# along the tang towards the hammers. Built in the gun's own space.
	hand = GunParts.pivot(model, "Hand", Vector3.ZERO)
	var wrist := func(z: float) -> Vector3: return Vector3(0.0, -0.006 - 0.15 * maxf(z + 0.01, 0.0), z)
	var names := ["middle", "ring", "little"]
	var zs := [0.018, 0.0375, 0.0555]
	var reach := [0.098, 0.093, 0.08]
	for i in 3:
		var c: Vector3 = wrist.call(zs[i])
		var path := PackedVector3Array()
		for k in 25:
			var phi := lerpf(112.0, -128.0, k / 24.0)
			var lift := 0.01 * smoothstep(60.0, 112.0, phi)
			path.append(HandModel.oval_point(c, 0.0148, 0.0182, phi, r + 0.0012 + lift))
		HandModel.chain(hand, names[i], HandModel.cut(path, reach[i]), [0.46, 0.3, 0.24], r * (1.0 - 0.05 * i), skin)
	var index := HandModel.chain(hand, "index", HandModel.cut(HandModel.smooth([Vector3(0.022, -0.006, 0.0),
			Vector3(0.017, -0.016, -0.022), Vector3(0.008, -0.03, -0.04), Vector3(-0.001, -0.043, -0.05),
			Vector3(-0.01, -0.047, -0.044)], 4), 0.094), [0.46, 0.3, 0.24], r * 0.97, skin)
	_index = index[1]
	var thumb := HandModel.chain(hand, "thumb", HandModel.cut(HandModel.smooth([Vector3(0.006, 0.002, 0.062),
			Vector3(0.017, 0.009, 0.04), Vector3(0.023, 0.013, 0.018), Vector3(0.026, 0.015, 0.0)], 4), 0.064),
			[0.55, 0.45], 0.0116, skin)
	_thumb_pivot = thumb[0]
	var rings := []
	for z in [-0.006, 0.004, 0.02, 0.038, 0.056, 0.068, 0.076]:
		var c: Vector3 = wrist.call(z)
		var end := smoothstep(0.06, 0.078, z) + (1.0 - smoothstep(-0.008, 0.008, z))
		var inner := HandModel.round_oval(c, 0.0148, 0.0182, 92.0, 206.0, 0.0012, 10)
		var outer := PackedVector3Array()
		for k in 11:
			var phi := lerpf(92.0, 206.0, k / 10.0)
			var t := 0.008 + 0.014 * clampf(1.0 - absf(phi - 118.0) / 70.0, 0.0, 1.0) - 0.004 * end
			outer.append(HandModel.oval_point(c, 0.0148, 0.0182, phi, 0.0012 + t))
		rings.append(HandModel.shell_ring(inner, outer))
	GunParts.lofted(hand, "Palm", rings, skin)
	var start := Vector3(0.014, -0.03, 0.068)
	var dir := Basis.from_euler(Vector3(deg_to_rad(38.0), deg_to_rad(24.0), 0.0), EULER_ORDER_YXZ) * Vector3.BACK
	GunParts.lofted(hand, "Wrist", HandModel.tube(start, dir, [[-0.01, 0.017, 0.026], [0.03, 0.02, 0.028],
			[0.075, 0.0225, 0.031]]), skin)
	GunParts.lofted(hand, "Cuff", HandModel.tube(start, dir, [[0.068, 0.028, 0.035], [0.072, 0.031, 0.037],
			[0.098, 0.032, 0.038], [0.104, 0.030, 0.036]]), cuff)
	GunParts.lofted(hand, "Sleeve", HandModel.tube(start, dir, [[0.094, 0.034, 0.040], [0.1, 0.039, 0.044],
			[0.2, 0.042, 0.047], [0.34, 0.045, 0.05]]), sleeve)

	# Left hand: the forend lies in the palm, the fingers curl up its right side, the thumb lies
	# along its left; the forearm goes back and down to the left. It rides the barrels when the
	# gun breaks open. Built in the barrels' space.
	left_hand = GunParts.pivot(model.barrels, "LeftHand", Vector3.ZERO)
	var fc := Vector3(0.0, ShotgunModel.BARREL_Y - 0.021, 0.0)
	var lnames := ["l_index", "l_middle", "l_ring", "l_little"]
	var lz := [-0.036, -0.0555, -0.075, -0.093]
	for i in 4:
		var c := fc + Vector3(0.0, 0.0, lz[i])
		var path := HandModel.round_oval(c, 0.019, 0.014, -40.0, 100.0, r + 0.0012, 20)
		HandModel.chain(left_hand, lnames[i], HandModel.cut(path, [0.076, 0.081, 0.078, 0.066][i]), [0.46, 0.3, 0.24],
				r * [0.97, 1.0, 0.97, 0.88][i], skin)
	HandModel.chain(left_hand, "l_thumb", HandModel.cut(HandModel.smooth([Vector3(-0.02, -0.016, -0.02),
			Vector3(-0.03, -0.006, -0.045), Vector3(-0.03, 0.004, -0.07), Vector3(-0.027, 0.01, -0.09)], 4), 0.064),
			[0.55, 0.45], 0.0116, skin)
	var lrings := []
	for z in [-0.016, -0.026, -0.045, -0.065, -0.085, -0.1, -0.106]:
		var c := fc + Vector3(0.0, 0.0, z)
		var inner := HandModel.round_oval(c, 0.019, 0.014, -112.0, -30.0, 0.0012, 8)
		var outer := PackedVector3Array()
		for k in 9:
			var phi := lerpf(-112.0, -30.0, k / 8.0)
			var t := 0.012 + 0.01 * clampf(1.0 - absf(phi + 50.0) / 60.0, 0.0, 1.0)
			outer.append(HandModel.oval_point(c, 0.019, 0.014, phi, 0.0012 + t))
		lrings.append(HandModel.shell_ring(inner, outer))
	GunParts.lofted(left_hand, "Palm", lrings, skin)
	var lstart := fc + Vector3(-0.022, -0.026, -0.03)
	var ldir := Basis.from_euler(Vector3(deg_to_rad(40.0), deg_to_rad(-18.0), 0.0), EULER_ORDER_YXZ) * Vector3.BACK
	GunParts.lofted(left_hand, "Wrist", HandModel.tube(lstart, ldir, [[-0.01, 0.026, 0.018], [0.03, 0.028, 0.02],
			[0.075, 0.031, 0.0225]]), skin)
	GunParts.lofted(left_hand, "Cuff", HandModel.tube(lstart, ldir, [[0.068, 0.035, 0.028], [0.072, 0.037, 0.031],
			[0.098, 0.038, 0.032], [0.104, 0.036, 0.030]]), cuff)
	GunParts.lofted(left_hand, "Sleeve", HandModel.tube(lstart, ldir, [[0.094, 0.040, 0.034], [0.1, 0.044, 0.039],
			[0.2, 0.047, 0.042], [0.4, 0.05, 0.045]]), sleeve)


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
	var wobble := (tuning.spread_aim_degrees if aiming else tuning.spread_hip_degrees) + _wobble()
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
	_unsettle()
	if _player:
		_player.add_look(Vector2(_rng.randf_range(-0.8, 0.8), tuning.recoil_degrees * (1.0 - tuning.recoil_recovery)))
	_view_kick += tuning.recoil_degrees * tuning.recoil_recovery


func _load() -> Dictionary:
	return {"speed": tuning.muzzle_velocity, "mass": tuning.pellet_mass, "diameter": tuning.pellet_diameter,
			"form": 0.0, "zero": tuning.zero_distance}


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
	_update_sway(delta)
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
	_index.rotation_degrees.x = -14.0 * maxf(_triggers[0], _triggers[1])
	_thumb = move_toward(_thumb, 0.0, delta * 3.0)
	_thumb_pivot.rotation_degrees = Vector3(30.0 * _thumb, 0.0, 0.0)
	model.show_barrels(state.barrels)
	model.butt.visible = not (selected and _pose_pos.distance_to(POSES[Pose.AIM][0]) < 0.06 and tuck < 0.3)
	_animate_camera(delta, tuning.aim_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var pos := PUT_AWAY_POS.lerp(_pose_pos.lerp(TUCK_POS, t), drawn_amount) + Vector3(0.0, 0.01, 0.07) * _recoil
	var rot := _pose_rot.lerp(TUCK_ROT, t) + Vector3(14.0 * _recoil * (1.0 - t), 0.0, 0.0) \
			+ _sway_rotation() * (1.0 - t) * (0.0 if state.open else 1.0)
	position = pos
	rotation_degrees = rot
