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

## From the hip, the usual first-person carry: the stock under your arm, the gun at the lower right
## with the barrels running in towards the middle, both hands on it. Aimed, down the sights (Sean,
## 2026-10-23): your eye over the comb, looking between the hammers along the rib to the bead on
## the middle of the view.
const POSES := {
	Pose.HIP: [Vector3(0.18, -0.14, -0.34), Vector3(1.0, -1.5, -4.0)],
	Pose.AIM: [Vector3(0.0, -0.053, -0.3), Vector3(2.5, 0.0, 0.0)],
	Pose.LOADING: [Vector3(0.04, -0.12, -0.3), Vector3(-8.0, 14.0, 6.0)],
}
const PUT_AWAY_POS := Vector3(0.25, -0.8, 0.05)
## Up against a wall the barrels come up and back (port arms) instead of pushing through.
const TUCK_POS := Vector3(0.1, -0.24, -0.02)
const TUCK_ROT := Vector3(62.0, 12.0, -8.0)
## How far the barrels drop when it's broken open (degrees).
const OPEN_ANGLE := -32.0
const HAMMER_BACK := 40.0

## The hands (the gun lab's `views.gd --fit`: the fingers closed on the wood, every bone 0-3 mm
## off it, the index's pad on the front trigger, the thumbs clear of the steel).
## The right: its index knuckle on the right of the stock's wrist by the guard, the knuckles'
## line run back along the wrist, rolled so the heel of the hand is beside the stock (clear of the
## rib when aimed), the forearm back, down and out to the right.
const R_HAND_POS := Vector3(0.026, -0.024, 0.016)
const R_HAND_TILT := -45.0
const R_HAND_ROLL := -40.0
const R_FOREARM := Vector3(0.8, -0.58, 0.15)
const R_GRIP := {"middle": [49.0, 73.0, 24.0], "ring": [70.0, 52.0, 27.0], "little": [77.0, 28.0, 37.0]}
## The index swung forward from its knuckle onto the front trigger (a plain curl can't reach it),
## and squeezed back.
const R_INDEX_REST := [Vector3(24.0, 24.0, 12.0), 0.0, 0.0]
const R_INDEX_PULL := [Vector3(12.0, 24.0, 12.0), 0.0, 0.0]
const R_THUMB_REST := [Vector3(-48.0, -60.0, 36.0), 0.0, 0.0]
const R_THUMB_COCK := [Vector3(12.0, 60.0, 36.0), 45.0, 40.0]
## The left, in the barrels' space: the forend across its palm, its fingers up the right side and
## its thumb up the left, the forearm back, down and out to the left.
const L_HAND_POS := Vector3(0.012, -0.026, -0.1)
const L_HAND_TILT := -90.0
const L_HAND_ROLL := 90.0
const L_FOREARM := Vector3(-0.3, -0.55, 0.78)
const L_GRIP := {"index": [13.0, 79.0, 4.0], "middle": [50.0, 77.0, 52.0], "ring": [29.0, 79.0, 32.0], "little": [2.0, 80.0, 0.0]}
const L_THUMB := [Vector3(60.0, 60.0, -60.0), 45.0, 40.0]

@export var tuning: ShotgunTuning

var state: ShotgunState
var model: ShotgunModel
## The right hand round the wrist of the stock (index finger on the front trigger, thumb over the
## top for the hammers) and the left under the forend, riding the barrels: HeldHands, the same
## painted Studio hands as the revolver's.
var hand: HeldHand
var left_hand: HeldHand

var _open := 0.0
var _hammers := [0.0, 0.0]
var _triggers := [0.0, 0.0]
var _thumb := 0.0
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
	hand = _held(true, model, R_HAND_POS, R_HAND_TILT, R_HAND_ROLL, R_FOREARM)
	for f: String in R_GRIP:
		hand.curl(f, R_GRIP[f])
	left_hand = _held(false, model.barrels, L_HAND_POS, L_HAND_TILT, L_HAND_ROLL, L_FOREARM)
	for f: String in L_GRIP:
		left_hand.curl(f, L_GRIP[f])
	left_hand.thumb_pose(L_THUMB[0], L_THUMB[1], L_THUMB[2])


## A hand at `pos` in `parent`'s space: turned `tilt` about X (degrees; the knuckles' line from
## pointing up to along the wood) then `roll` about the gun's length, its forearm aimed `forearm`
## (a direction in the gun's space, back towards that shoulder).
func _held(is_right: bool, parent: Node3D, pos: Vector3, tilt: float, roll: float, forearm: Vector3) -> HeldHand:
	var h := HeldHand.new(is_right)
	h.name = "Hand" if is_right else "LeftHand"
	h.position = pos
	h.basis = Basis(Vector3.BACK, deg_to_rad(roll)) * Basis(Vector3.RIGHT, deg_to_rad(tilt))
	parent.add_child(h)
	h.build()
	h.aim_forearm(forearm)
	return h


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
	if GameAudio.enabled():
		GameAudio.gunshot(self, origin, true)
	else:
		_play(&"shotgun")
	Events.shot_fired.emit(origin, dir, _player)
	_kick_shot(tuning)
	_unsettle()


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
	kick.step(delta)
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
	var pull := maxf(_triggers[0], _triggers[1])
	hand.pose_finger("index", (R_INDEX_REST[0] as Vector3).lerp(R_INDEX_PULL[0], pull), lerpf(R_INDEX_REST[1], R_INDEX_PULL[1], pull),
			lerpf(R_INDEX_REST[2], R_INDEX_PULL[2], pull))
	_thumb = move_toward(_thumb, 0.0, delta * 3.0)
	hand.thumb_pose((R_THUMB_REST[0] as Vector3).lerp(R_THUMB_COCK[0], _thumb), lerpf(R_THUMB_REST[1], R_THUMB_COCK[1], _thumb),
			lerpf(R_THUMB_REST[2], R_THUMB_COCK[2], _thumb))
	model.show_barrels(state.barrels)
	model.butt.visible = true
	_animate_camera(delta, tuning.aim_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var pos := PUT_AWAY_POS.lerp(_pose_pos.lerp(TUCK_POS, t), drawn_amount) + Vector3(0.0, kick.back * 0.2, kick.back) \
			+ _body_pos() * drawn_amount
	var rot := _pose_rot.lerp(TUCK_ROT, t) + Vector3(kick.pitch, -kick.yaw, -kick.roll) * (1.0 - t) \
			+ _sway_rotation() * (1.0 - t) * (0.0 if state.open else 1.0)
	position = pos
	rotation_degrees = rot
