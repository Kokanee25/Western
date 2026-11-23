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

## Where the gun hangs under the camera ([metres, degrees]): at the hip, low in the right of the view
## with its line into the screen's centre; turned up to the gate to load. Aimed is `_aim_pose()`.
const POSES := {
	Pose.HIP: [Vector3(0.12, -0.12, -0.38), Vector3(3.0, 3.0, -8.0)],
	Pose.LOADING: [Vector3(0.06, -0.11, -0.43), Vector3(20.0, 16.0, 58.0)],
}
## How far ahead of the eye the rear sight sits, aimed (metres).
const AIM_RELIEF := 0.55
## The aimed gun's cant about the line of sight (degrees; positive tops it to the left).
const AIM_CANT := 0.0
## The aimed gun turned about its front sight ([yaw, pitch] degrees; positive yaw swings the rear to the
## left, positive pitch drops it): the gun's side and top in view, the front blade still centred.
const AIM_TURN := Vector2.ZERO
## Harlan's cut-off forearm aimed (HeldHand.elbow_drop, from the shoulder in the camera's space): the
## arm out, so the sleeve drops steeply out of the view's bottom instead of running back into the lens.
const AIM_ELBOW := Vector3(0.0, -0.35, -0.3)
const HOLSTER_POS := Vector3(0.22, -0.55, -0.12)
## Up close to a wall (or a person) the gun comes back to the chest, muzzle up, instead of
## pushing through: a compressed high ready.
const TUCK_POS := Vector3(0.15, -0.26, -0.14)
const TUCK_ROT := Vector3(55.0, 22.0, -25.0)
## The viewmodel's own field of view (WeaponViewmodel.view_fov): the gun drawn as a 54 degree camera
## would draw it, bigger and with less stretch than the world's 75.
const VIEW_FOV := 54.0
## Loading (#1031): the left hand brings a round to the open gate between its thumb and index finger
## and pushes it in. Its place: where the thumb's and index's tips meet, from the round's base (the
## gun's space), the wrist's line from the hand and the palm's facing (`colt.l_load` in
## config/fp_holds.json for Harlan's hands).
const L_LOAD := [Vector3(0.004, 0.0, 0.002), Vector3(0.2, -0.2, 1.0), Vector3(-1.0, 0.0, 0.0)]
const L_LOAD_GRIP := {"index": 40.0, "middle": 75.0, "ring": 85.0, "little": 88.0}
const L_LOAD_THUMB := [Vector3(-20.0, 40.0, 30.0), 25.0, 20.0]
## The left forearm from its wrist (the gun's space): back, down and out to the left, under the gun.
const L_LOAD_FOREARM := Vector3(-0.3, -0.6, 0.75)
## The cut-off left forearm's end (HeldHand.elbow_drop, from the left shoulder, camera space): out to
## the left and forward, so its sleeve leaves by the view's lower left, not across the middle.
const L_ELBOW_LOAD := Vector3(0.0, -0.45, 0.0)
## How far behind the gate the round's base sits before it's pushed in (m), and the push's time (s).
const ROUND_BACK := 0.03
const PUSH_TIME := 0.18

@export var tuning: RevolverTuning

var state: RevolverState

## The approved Colt (#693, #1014): the gun lab's script-built SAA (ColtModel).
var model: ColtModel
var hand: HandModel
## The left hand, there only while the gate's open (#1031), and the round in its fingers.
var left_hand: HeldHand
var _load_pivot: Node3D
var _round: Node3D
var _load_k := 0.0
var _push := 0.0

var _hammer := 0.0
var _cyl := 0.0
var _gate := 0.0
var _trigger := 0.0
var _thumb := 0.0
var _ejector := 0.0
var _reload_held := 0.0
var _finger_off := 1.0
var _aim_k := 0.0
var _aim_elbow := AIM_ELBOW
## The poses for the hands you have: `POSES`, or Harlan's first-person hands' own (HeldHand.hold:
## `colt.hip`, `colt.aim`, `colt.loading` in config/fp_holds.json).
var _poses := POSES


## The flash at the muzzle as you see it (#1019).
var flash: MuzzleFlash


func _ready() -> void:
	add_to_group(&"revolver")
	if tuning == null:
		tuning = load("res://config/revolver.tres")
	state = RevolverState.new(tuning, hash(get_path()))
	_rng.seed = 45
	view_fov = VIEW_FOV
	model = ColtModel.new()
	model.held = true
	model.name = "Revolver"
	add_child(model)
	flash = MuzzleFlash.new(1.0)
	model.muzzle.add_child(flash)
	hand = HandModel.new()
	hand.name = "Hand"
	add_child(hand)
	_build_loading_hand()
	_poses = {Pose.HIP: HeldHand.hold("colt.hip", POSES[Pose.HIP]), Pose.AIM: _aim_pose(),
			Pose.LOADING: HeldHand.hold("colt.loading", POSES[Pose.LOADING])}
	_aim_elbow = HeldHand.hold("colt.elbow_aim", AIM_ELBOW)
	_pose_pos = _poses[Pose.HIP][0]
	_pose_rot = _poses[Pose.HIP][1]
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
	state.inserted.connect(func() -> void: _play(&"insert"); _push = 1.0)
	_apply_pose(1.0)
	_muzzle_local = model.transform * model.to_local(model.muzzle.global_position) if model.is_inside_tree() else Vector3(0, 0.02, -0.3)
	_warm_up.call_deferred()


## The left hand and its round at the gate (#1031): under a pivot that rides in with the round.
func _build_loading_hand() -> void:
	_load_pivot = Node3D.new()
	_load_pivot.name = "LoadPivot"
	_load_pivot.position = model.gate_point.position
	model.add_child(_load_pivot)
	var case_len := 0.033
	_round = Node3D.new()
	_round.name = "HeldRound"
	_load_pivot.add_child(_round)
	GunParts.tube(_round, "Case", 0.0058, case_len, Vector3(0, 0, -case_len * 0.5), GunParts.brass(), 10).set_meta(&"own_paint", true)
	GunParts.tube(_round, "Bullet", 0.0053, 0.012, Vector3(0, 0, -case_len - 0.005), GunParts.lead(), 10).set_meta(&"own_paint", true)
	var place: Array = HeldHand.hold("colt.l_load", L_LOAD)
	left_hand = HeldHand.new(false)
	left_hand.name = "LeftHand"
	Winchester73Viewmodel._place(left_hand, Vector3.ZERO, place[1], place[2], false)
	_load_pivot.add_child(left_hand)
	left_hand.build()
	left_hand.aim_forearm(L_LOAD_FOREARM)
	left_hand.shoulder = ShotgunViewmodel.SHOULDER_L
	left_hand.elbow_pole = ShotgunViewmodel.ELBOW_POLE_L
	left_hand.elbow_drop = HeldHand.hold("colt.l_elbow_load", L_ELBOW_LOAD)
	var grip: Dictionary = HeldHand.hold("colt.l_load_grip", L_LOAD_GRIP)
	for f: String in grip:
		left_hand.grasp(f, grip[f])
	var th: Array = HeldHand.hold("colt.l_load_thumb", L_LOAD_THUMB)
	left_hand.thumb_pose(th[0], th[1], th[2])
	# The hand put where its pinch (between the thumb's and the index's tips) holds the round.
	left_hand.position = (place[0] as Vector3) - left_hand.basis * _pinch(left_hand)
	left_hand.visible = false
	_round.visible = false


## Where a hand's thumb and index tips meet (their midpoint), in the hand's own space.
static func _pinch(h: HeldHand) -> Vector3:
	var inv := h.global_transform.affine_inverse()
	var tips := Vector3.ZERO
	for f: String in ["index", "thumb"]:
		var bones: Array = h.fingers.get(f, [])
		if bones.is_empty():
			return Vector3(0.0, 0.0, -0.09)
		var b := bones[-1] as Node3D
		tips += inv * (b.global_transform * (h.tip_dir(b) * float(h.lengths[f][-1])))
	return tips * 0.5


## Down the sights, from the Colt's own markers (as the Winchester's): the rear notch and the front
## blade on your line of sight, the notch `AIM_RELIEF` ahead of the eye (an arm out, the elbow a
## little bent: one-handed, the gun is held well out).
func _aim_pose() -> Array:
	var rear := model.marker("SightRear")
	var front := model.marker("SightFront")
	var b := Basis.looking_at((front - rear).normalized(), Vector3.UP).inverse()
	var relief: float = HeldHand.hold("colt.eye_relief", AIM_RELIEF)
	# Canted a little about the line of sight (the sights stay on it): the cylinder's side to the eye.
	var cant := Basis(Vector3.BACK, deg_to_rad(float(HeldHand.hold("colt.aim_cant", AIM_CANT))))
	var pos := cant * (-(b * rear) + Vector3(0.0, 0.0, -relief))
	var t := Transform3D(cant * b, pos)
	# Turned and dropped about the front sight (#1031): the front blade stays on the screen's centre and
	# the rear comes off the line of sight, so you look a little down the gun's side and top, as a
	# first-person shooter frames an aimed gun, not dead end-on (`colt.aim_turn`: [yaw, pitch] degrees).
	var turn: Vector2 = HeldHand.hold("colt.aim_turn", AIM_TURN)
	var f := t * front
	var r := Basis.from_euler(Vector3(deg_to_rad(turn.y), deg_to_rad(turn.x), 0.0))
	t = Transform3D(r, f - r * f) * t
	return [t.origin, t.basis.get_euler() * (180.0 / PI)]


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
		# Held, it keeps working round the cylinder and shuts the gate when it's done, but never
		# opens it again: a held key used to shut and reopen the gate over and over, and a let-go
		# left the hammer at half cock (the D+ playtest).
		if _reload_held > 0.3 and state.ready() and state.gate_open:
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


## Empty (a shot that's a click: reload), or out of cartridges: none on the belt, and none left in
## the cylinder (or some, but none to load).
func _why_not(action: StringName) -> String:
	if state == null:
		return ""
	var loaded := state.chambers.count(RevolverState.Chamber.LOADED)
	if state.belt > 0:
		return "it's empty: reload" if loaded == 0 and action in [&"fire", &"cock"] else ""
	if loaded == 0 and action in [&"fire", &"reload", &"cock"]:
		return "you're out of cartridges"
	if action == &"reload" and not state.chambers.has(RevolverState.Chamber.SPENT) and not state.chambers.has(RevolverState.Chamber.DUD):
		return "you've no cartridges left to load (%d in the gun)" % loaded
	return ""


func pull_trigger() -> RevolverState.Shot:
	_trigger = 1.0
	return state.pull_trigger()


func toggle_holster() -> void:
	drawn = not drawn
	if not drawn and state.gate_open:
		state.line_up()
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
	_in_tick(_fire)


func _fire() -> void:
	var line := _shot_line(model.muzzle.global_position)
	var origin: Vector3 = line[0]
	var dir: Vector3 = line[1]
	var exclude: Array[RID] = line[2]
	var spread := (tuning.spread_aim_degrees if aiming else tuning.spread_hip_degrees) + _wobble()
	if _player:
		spread += _player.get_horizontal_speed() * 0.5
	dir = _cone(dir, deg_to_rad(spread))
	var ballistics := _ballistics()
	var bullet := ballistics.fire(origin, dir, tuning.muzzle_velocity, tuning.bullet_mass, tuning.bullet_diameter, exclude)
	bullet.form = tuning.form_factor
	bullet.shooter = _player
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir, 1.0, true)  # your own shot (#1048)
	# Your own gun: its light up and out from the muzzle (on it, it burned the barrel white) and no
	# world puff over the held flash (#1031).
	ImpactEffects.muzzle_flash(world, origin + dir * 0.15 + Vector3.UP * 0.1, false)
	flash.fire()
	if GameAudio.enabled():
		GameAudio.gunshot(self, origin)
	else:
		_play(&"gunshot")
	Events.shot_fired.emit(origin, dir, _player)
	_kick_shot(tuning)
	_unsettle()


func _load() -> Dictionary:
	return {"speed": tuning.muzzle_velocity, "mass": tuning.bullet_mass, "diameter": tuning.bullet_diameter,
			"form": tuning.form_factor, "zero": tuning.zero_distance}


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
	_pose_pos = _pose_pos.lerp(_poses[pose][0], k)
	_pose_rot = _pose_rot.lerp(_poses[pose][1], k)
	kick.step(delta)
	flash.step(delta)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * (18.0 if _tuck_target > tuck else 9.0)))
	_update_sway(delta)
	_apply_pose(_draw)

	var hammer_target: float = _hammer_angle(state.hammer)
	_hammer = hammer_target if hammer_target < _hammer else move_toward(_hammer, hammer_target, delta * model.notch("full") / maxf(tuning.cock_time, 0.01))
	_trigger = move_toward(_trigger, 0.0, delta * 5.0)
	model.hammer(_hammer, _trigger)
	# Chamber k under the hammer is the cylinder turned -60k; with the gate open, the chamber worked
	# on sits behind the gate instead.
	var cyl_target := model.gate_turn(state.under_hammer) if state.gate_open else -60.0 * state.under_hammer
	_cyl = rad_to_deg(lerp_angle(deg_to_rad(_cyl), deg_to_rad(cyl_target), 1.0 - exp(-delta * 18.0)))
	model.cylinder(_cyl)
	_gate = move_toward(_gate, 1.0 if state.gate_open else 0.0, delta * 5.0)
	model.gate(_gate)
	# The trigger finger lies along the frame until you aim or fire (#1014).
	_finger_off = move_toward(_finger_off, 0.0 if aiming or _trigger > 0.0 else 1.0, delta * 6.0)
	hand.set_trigger(_trigger, _finger_off)
	_aim_k = move_toward(_aim_k, 1.0 if pose == Pose.AIM else 0.0, delta * 6.0)
	hand.held.elbow_drop = HeldHand.FP_ELBOW_DROP.lerp(_aim_elbow, smoothstep(0.0, 1.0, _aim_k))
	_thumb = move_toward(_thumb, 0.0, delta * 3.5)
	hand.set_thumb(_thumb)
	_ejector = move_toward(_ejector, 0.0, delta * 3.0)
	model.ejector(_ejector)
	model.show_chambers(state.chambers)
	_animate_loading(delta)

	_animate_camera(delta, tuning.aim_fov)


## The left hand comes up from below to the open gate, a round in its fingers; each round pressed in
## (`inserted`) pushes it home, and the next one's brought back behind the gate.
func _animate_loading(delta: float) -> void:
	_load_k = move_toward(_load_k, 1.0 if state.gate_open else 0.0, delta / 0.3)
	_push = move_toward(_push, 0.0, delta / PUSH_TIME)
	var shown := _load_k > 0.01
	left_hand.visible = shown
	left_hand.set_process(shown)
	var k := smoothstep(0.0, 1.0, _load_k)
	# From below and behind as it comes in; the push carries hand and round forward into the gate.
	var push := sin(_push * PI) if _push > 0.0 else 0.0
	_load_pivot.position = model.gate_point.position + Vector3(0.0, -0.1, 0.08) * (1.0 - k) \
			+ Vector3(0.0, 0.0, ROUND_BACK * (1.0 - push))
	var any := state.belt > 0 and (state.chambers.has(RevolverState.Chamber.SPENT) \
			or state.chambers.has(RevolverState.Chamber.EMPTY) or state.chambers.has(RevolverState.Chamber.DUD))
	_round.visible = shown and any


func _hammer_angle(h: int) -> float:
	match h:
		RevolverState.Hammer.HALF_COCK:
			return model.notch("half")
		RevolverState.Hammer.FULL_COCK:
			return model.notch("full")
	return 0.0


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	var pos := HOLSTER_POS.lerp(_pose_pos.lerp(TUCK_POS, t), drawn_amount) + Vector3(0.0, kick.back * 0.2, kick.back) \
			+ _body_pos() * drawn_amount
	var rot := _pose_rot.lerp(TUCK_ROT, t) + Vector3(kick.pitch, -kick.yaw, -kick.roll) * (1.0 - t) \
			+ _sway_rotation() * (1.0 - t) * (0.0 if state.gate_open else 1.0)
	_set_view(pos, rot)
