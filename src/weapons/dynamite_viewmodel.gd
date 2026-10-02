class_name DynamiteViewmodel
extends WeaponViewmodel
## A stick of dynamite in your right hand, a match in your left. Sits under the camera beside the
## guns; the player switches to it (3).
##
## Controls: cock (Q) strikes a match and lights the fuse; fire (LMB) held winds up and throws on
## release (the longer the wind-up, the harder); aim (RMB) sets it down in front of you. Hold a lit
## stick too long and it goes off in your hand. A fresh stick comes out after each throw while
## you've any left.

const HIP_POS := Vector3(0.16, -0.2, -0.3)
const HIP_ROT := Vector3(10.0, -20.0, 60.0)
const WINDUP_POS := Vector3(0.24, -0.08, -0.05)
const WINDUP_ROT := Vector3(-40.0, -10.0, 70.0)
const PUT_AWAY_POS := Vector3(0.25, -0.7, 0.0)
const LIGHT_TIME := 0.9

signal thrown(stick: DynamiteStick)

var sticks := 6
var lit := false
var fuse_left := 0.0
## 0 = not winding up; counts up while fire is held.
var windup := 0.0
var lighting := 0.0

var stick_node: Node3D
var hand: Node3D
var match_node: Node3D
var _fuse: Node3D
var _sparks: GPUParticles3D
var _match_light: OmniLight3D
var _hiss: AudioStreamPlayer3D
var _next_stick := 0.0
var _bt: BlastTuning


func _ready() -> void:
	add_to_group(&"dynamite_hand")
	_bt = Blast.t()
	sticks = _bt.sticks_carried
	_build()
	_setup_common()
	_pose_pos = HIP_POS
	_pose_rot = HIP_ROT
	_muzzle_local = HIP_POS
	_add_sound(&"match")
	_hiss = AudioStreamPlayer3D.new()
	_hiss.stream = SynthSounds.get_sound(&"fuse")
	_hiss.unit_size = 2.0
	_hiss.volume_db = -10.0
	add_child(_hiss)
	_apply_pose(_draw)


func _build() -> void:
	var skin := GunParts.skin()
	var sleeve := GunParts.held_cloth("coat", Color(0.36, 0.25, 0.16))
	stick_node = GunParts.pivot(self, "Stick", Vector3.ZERO)
	# In the hand the sparks are right under your nose: small and close.
	var parts := DynamiteStick.build_model(stick_node, 0.15)
	_fuse = parts.fuse
	_sparks = parts.sparks
	# A fist round the middle of the stick, forearm going back and down.
	hand = GunParts.pivot(self, "Hand", Vector3(0, -0.005, 0.02))
	GunParts.box(hand, "Fist", Vector3(0.05, 0.045, 0.07), Vector3(0.012, -0.004, 0.0), skin)
	GunParts.box(hand, "Thumb", Vector3(0.016, 0.016, 0.04), Vector3(-0.016, 0.018, -0.01), skin)
	var arm := GunParts.pivot(hand, "Forearm", Vector3(0.02, -0.01, 0.04))
	arm.rotation_degrees = Vector3(30.0, 30.0, 0.0)
	GunParts.box(arm, "Sleeve", Vector3(0.07, 0.07, 0.28), Vector3(0, 0, 0.16), sleeve)
	# The match, in the left hand, only while lighting.
	match_node = GunParts.pivot(self, "Match", Vector3(-0.05, 0.0, -0.14))
	GunParts.box(match_node, "Stem", Vector3(0.003, 0.003, 0.05), Vector3.ZERO, GunParts.material("match_wood", PixelArt.skin("match_wood", Color(0.8, 0.7, 0.5), 137), 0.0, 1.0))
	GunParts.box(match_node, "LeftFingers", Vector3(0.05, 0.03, 0.05), Vector3(-0.02, -0.01, 0.03), skin)
	_match_light = OmniLight3D.new()
	_match_light.light_color = Color(1.0, 0.7, 0.35)
	_match_light.omni_range = 2.0
	_match_light.light_energy = 0.0
	match_node.add_child(_match_light)
	_match_light.position = Vector3(0, 0, -0.03)
	match_node.visible = false


func _process(delta: float) -> void:
	if _can_act():
		_read_controls(delta)
	_tick(delta)
	_animate(delta)


func _read_controls(delta: float) -> void:
	if hands_busy or arm_disabled:
		if lit:
			place()  # drop it and deal with the bleeding
		if drawn:
			drawn = false
		return
	if Input.is_action_just_pressed(&"holster") and not lit:
		drawn = not drawn
	if not drawn or _draw < 0.9 or not has_stick():
		windup = 0.0
		return
	if Input.is_action_just_pressed(&"cock"):
		strike_match()
	if Input.is_action_just_pressed(&"aim") and _action_ok(&"aim"):
		place()
	if Input.is_action_pressed(&"fire") and _action_ok(&"fire"):
		if not lit and lighting <= 0.0:
			strike_match()
		elif lit:
			windup += delta
	elif windup > 0.0:
		throw()


func has_stick() -> bool:
	return sticks > 0 and _next_stick <= 0.0


## Strike a match and put it to the fuse (takes a moment).
func strike_match() -> void:
	if lit or lighting > 0.0 or not has_stick():
		return
	lighting = LIGHT_TIME
	_play(&"match")


func _tick(delta: float) -> void:
	if _next_stick > 0.0:
		_next_stick -= delta
	if lighting > 0.0:
		lighting -= delta
		if lighting <= 0.0:
			lit = true
			fuse_left = _bt.fuse_seconds
			if is_inside_tree():
				_hiss.play()
	if lit:
		fuse_left -= delta
		if fuse_left <= 0.0:
			_goes_off_in_hand()


## Throw the lit stick (or an unlit one) where you're looking.
func throw() -> DynamiteStick:
	var k := clampf(windup / _bt.throw_windup, 0.0, 1.0)
	windup = 0.0
	var speed := lerpf(_bt.throw_speed_min, _bt.throw_speed_max, k)
	var cam := get_parent() as Node3D
	var fwd := -cam.global_transform.basis.z if cam else -global_transform.basis.z
	var v := fwd * speed + Vector3.UP * _bt.throw_lift
	if _player:
		v += _player.velocity
	return _release(v)


## Set it down just in front of you (by the wall you're facing, say).
func place() -> DynamiteStick:
	var cam := get_parent() as Node3D
	var fwd := -cam.global_transform.basis.z if cam else -global_transform.basis.z
	return _release(Vector3(fwd.x, -0.2, fwd.z).normalized() * 1.2)


func _release(velocity: Vector3) -> DynamiteStick:
	if sticks <= 0 or _next_stick > 0.0:
		return null
	var world := _ballistics().get_parent()
	var at := stick_node.global_position
	var cam := get_parent() as Node3D
	if cam and _player:
		# Out from in front of your face, never from inside a wall you're up against.
		var from := cam.global_position
		var want := from - cam.global_transform.basis.z * 0.45 + cam.global_transform.basis.x * 0.12 - cam.global_transform.basis.y * 0.1
		var q := PhysicsRayQueryParameters3D.create(from, want, Layers.WORLD)
		q.exclude = [_player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		at = want if hit.is_empty() else hit.position + (from - hit.position).normalized() * 0.05
	var s := DynamiteStick.make(world, at, velocity, fuse_left if lit else _bt.fuse_seconds)
	s.owner_node = _player
	s.global_basis = global_basis
	s.angular_velocity = Vector3(_rng.randf_range(-6, 6), _rng.randf_range(-3, 3), _rng.randf_range(-6, 6))
	if lit:
		s.light()
	lit = false
	lighting = 0.0
	_hiss.stop()
	sticks -= 1
	_next_stick = 0.6
	thrown.emit(s)
	return s


## Held it too long.
func _goes_off_in_hand() -> void:
	lit = false
	_hiss.stop()
	sticks -= 1
	_next_stick = 0.6
	var world := _ballistics().get_parent() as Node3D
	Blast.detonate(world, stick_node.global_position, _bt.tnt_per_stick, _player)


func put_away() -> void:
	if lit:
		place()
	drawn = false


func take_out() -> void:
	drawn = true


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / 0.4)
	visible = _draw > 0.02
	stick_node.visible = has_stick()
	hand.visible = true
	var winding := clampf(windup / _bt.throw_windup, 0.0, 1.0)
	var k := 1.0 - exp(-delta * 12.0)
	_pose_pos = _pose_pos.lerp(HIP_POS.lerp(WINDUP_POS, winding), k)
	_pose_rot = _pose_rot.lerp(HIP_ROT.lerp(WINDUP_ROT, winding), k)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * 10.0))
	_apply_pose(_draw)
	match_node.visible = lighting > 0.0
	_match_light.light_energy = 1.2 if lighting > 0.0 and lighting < LIGHT_TIME - 0.12 else 0.0
	DynamiteStick.show_fuse(_fuse, _sparks, fuse_left if lit else _bt.fuse_seconds, _bt.fuse_seconds, lit and stick_node.visible)
	_animate_camera(delta, _base_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	position = PUT_AWAY_POS.lerp(_pose_pos.lerp(Vector3(0.15, -0.3, -0.12), t), drawn_amount)
	rotation_degrees = _pose_rot
