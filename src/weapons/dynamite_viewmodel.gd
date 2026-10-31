class_name DynamiteViewmodel
extends WeaponViewmodel
## A stick of dynamite in your right hand, a match in your left. Sits under the camera beside the
## guns; the player switches to it (3).
##
## Controls: cock (Q) strikes a match and lights the fuse; fire (LMB) held winds up and throws on
## release (the longer the wind-up, the harder); aim (RMB) sets it down in front of you. Hold a lit
## stick too long and it goes off in your hand. A fresh stick comes out after each throw while
## you've any left.
##
## Planting (issue #506, the farmhouse breach): facing a wall within reach (or the floor at its
## foot), hold the use key (E, `shove`): you set a stick down at the wall's base, lying flat to the
## boards (`plant_time`), and its fuse is lit when you let go (`plant_fuse_seconds`). Let go before
## it's down and nothing's set. Lit, it's the wall's: there's no picking it back up. Away from a
## wall E is the shove and kick as before (PlayerShove asks `claims_use()`).

const HIP_POS := Vector3(0.16, -0.2, -0.3)
const HIP_ROT := Vector3(10.0, -20.0, 60.0)
const WINDUP_POS := Vector3(0.24, -0.08, -0.05)
const WINDUP_ROT := Vector3(-40.0, -10.0, 70.0)
const PUT_AWAY_POS := Vector3(0.25, -0.7, 0.0)
const LIGHT_TIME := 0.9
## The hand reaching down to the wall's foot as you set it.
const PLANT_POS := Vector3(0.05, -0.5, -0.4)
const PLANT_ROT := Vector3(-50.0, 0.0, 90.0)

signal thrown(stick: DynamiteStick)

var sticks := 6
var lit := false
var fuse_left := 0.0
## 0 = not winding up; counts up while fire is held.
var windup := 0.0
var lighting := 0.0
## Where a stick would go if you held E now (`plant_spot()`: {at, basis, wall}), worked out each
## tick while you've one in hand and free; empty with no wall in reach.
var plant_at := {}
## s E has been held setting one down (-1 not setting one).
var planting := -1.0
## The stick you've set and are still holding E over: lit when you let go.
var planted: DynamiteStick

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
	if not drawn or _draw < 0.9 or not has_stick() or planting >= 0.0 or planted != null:
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


func _physics_process(delta: float) -> void:
	super(delta)
	_plant_tick(delta)


## E (`shove`) is this hand's while it's setting a stick, holding one it set, or facing a wall it
## could set one at; PlayerShove leaves the key alone then.
func claims_use() -> bool:
	return selected and (planting >= 0.0 or planted != null or not plant_at.is_empty())


func _plant_tick(delta: float) -> void:
	if planted != null:
		# Set; lit as the key comes up (or if you're no longer at the controls).
		if not is_instance_valid(planted) or planted.lit:
			planted = null
		elif not Input.is_action_pressed(&"shove") or not _can_act():
			_light_planted()
		return
	var free := _can_act() and drawn and _draw >= 0.9 and has_stick() and not lit and lighting <= 0.0 \
			and windup <= 0.0 and not hands_busy and not arm_disabled
	if not free or _player == null or _player.camera == null:
		plant_at = {}
		planting = -1.0
		return
	var cam := _player.camera
	plant_at = plant_spot(World.space(self), cam.global_position, -cam.global_basis.z, _bt.plant_reach, [_player.get_rid()], _player.global_position.y)
	if planting >= 0.0:
		if plant_at.is_empty() or not Input.is_action_pressed(&"shove"):
			planting = -1.0  # let go too soon, or turned away: nothing set
			return
		planting += delta
		if planting >= _bt.plant_time:
			plant(plant_at)
	elif not plant_at.is_empty() and Input.is_action_just_pressed(&"shove"):
		planting = 0.0


## Where a stick goes for a wall seen from `eye` along `look` (within `reach`): on the floor at the
## wall's foot, lying along it flat to the boards. Looking at the wall or at the floor just in
## front of it both find it. Empty when there's no upright face in reach with a floor at its foot;
## with `feet` (your feet's height), the floor you're standing on (within FLOOR_OFF), not a ledge
## or a window's sill.
## {at: the stick's centre, basis: its long axis (Z) along the wall, wall: the face's outward
## normal, collider: the wall}.
static func plant_spot(space: PhysicsDirectSpaceState3D, eye: Vector3, look: Vector3, reach: float, exclude: Array = [], feet := NAN) -> Dictionary:
	if space == null:
		return {}
	var hit := _ray(space, eye, eye + look.normalized() * reach, exclude)
	if hit.is_empty():
		return {}
	var n: Vector3 = hit.normal
	var floor_at: Vector3
	var flat := Vector3(look.x, 0.0, look.z)
	if flat.length() < 0.05:
		return {}
	flat = flat.normalized()
	if n.y > 0.7:
		# The floor: is there a wall just ahead along it?
		floor_at = hit.position
		var ahead := _ray(space, floor_at + Vector3.UP * 0.08, floor_at + Vector3.UP * 0.08 + flat * 0.7, exclude)
		if ahead.is_empty() or absf((ahead.normal as Vector3).y) > 0.4:
			return {}
		n = ahead.normal
	elif absf(n.y) < 0.4:
		# The wall: the floor under where you're looking, a hand-span out from it (from knee height
		# over your feet, so a ledge or a window sill isn't taken for it).
		var nf := Vector3(n.x, 0.0, n.z).normalized()
		var from := (hit.position as Vector3) + nf * 0.12
		if not is_nan(feet):
			from.y = minf(from.y, feet + FLOOR_OFF)
		var down := _ray(space, from, from + Vector3.DOWN * 2.5, exclude)
		if down.is_empty() or (down.normal as Vector3).y < 0.7:
			return {}
		floor_at = down.position
	else:
		return {}
	if not is_nan(feet) and absf(floor_at.y - feet) > FLOOR_OFF:
		return {}
	var out := Vector3(n.x, 0.0, n.z).normalized()
	# The face where it meets the floor (a window or a ledge higher up isn't where it lies).
	# (A few heights: a ray along a board's bottom edge meets its underside.)
	var base := {}
	for h: float in [0.05, 0.09, 0.03, 0.14]:
		var low := floor_at + Vector3.UP * h
		base = _ray(space, low + out * 0.45, low - out * 0.4, exclude)
		if not base.is_empty() and absf((base.normal as Vector3).y) < 0.4:
			break
		base = {}
	if base.is_empty():
		return {}
	out = Vector3((base.normal as Vector3).x, 0.0, (base.normal as Vector3).z).normalized()
	var at := Vector3((base.position as Vector3).x, floor_at.y, (base.position as Vector3).z) \
			+ out * (DynamiteStick.RADIUS + 0.004) + Vector3.UP * (DynamiteStick.RADIUS + 0.002)
	var along := out.cross(Vector3.UP).normalized()
	return {"at": at, "basis": Basis(out, Vector3.UP, along).orthonormalized(), "wall": out, "collider": base.collider}


## How far the floor at the wall may be from your feet (m).
const FLOOR_OFF := 0.25


static func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	q.exclude = exclude
	return space.intersect_ray(q)


## Set a stick down at `spot` (`plant_spot()`), unlit: it's lit when E comes up. Returns it.
func plant(spot: Dictionary) -> DynamiteStick:
	planting = -1.0
	if spot.is_empty() or sticks <= 0:
		return null
	var s := DynamiteStick.make(_ballistics().get_parent(), spot.at, Vector3.ZERO, _bt.plant_fuse_seconds)
	s.owner_node = _player
	s.planted = true
	s.global_basis = spot.basis
	sticks -= 1
	_next_stick = 0.6
	planted = s
	return s


func _light_planted() -> void:
	planted.fuse_left = _bt.plant_fuse_seconds
	planted.light()
	_play(&"match")
	planted = null


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
		var hit := World.space(self).intersect_ray(q)
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
	var at := stick_node.global_position
	_in_tick(func() -> void: Blast.detonate(world, at, _bt.tnt_per_stick, _player))  # (the fuse burns in _process)


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
	var setting := clampf(planting / maxf(_bt.plant_time, 0.01), 0.0, 1.0) if planting >= 0.0 else (1.0 if planted != null else 0.0)
	_pose_pos = _pose_pos.lerp(HIP_POS.lerp(WINDUP_POS, winding).lerp(PLANT_POS, setting), k)
	_pose_rot = _pose_rot.lerp(HIP_ROT.lerp(WINDUP_ROT, winding).lerp(PLANT_ROT, setting), k)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * 10.0))
	_apply_pose(_draw)
	match_node.visible = lighting > 0.0
	_match_light.light_energy = 1.2 if lighting > 0.0 and lighting < LIGHT_TIME - 0.12 else 0.0
	DynamiteStick.show_fuse(_fuse, _sparks, fuse_left if lit else _bt.fuse_seconds, _bt.fuse_seconds, lit and stick_node.visible)
	_animate_camera(delta, _base_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	position = PUT_AWAY_POS.lerp(_pose_pos.lerp(Vector3(0.15, -0.3, -0.12), t), drawn_amount) + _body_pos() * drawn_amount
	rotation_degrees = _pose_rot + _body_rotation() * drawn_amount
