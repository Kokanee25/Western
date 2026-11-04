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
## Planting (issue #506, the farmhouse breach): aim at any piece of a building within reach (a
## wall, a stud, a post, a beam, the floor) or the ground and hold the use key (E, `shove`): the
## stick is fixed right where you aim, flat to it (`plant_time`), and its fuse is lit when you let
## go (`plant_fuse_seconds`). Let go before it's set and nothing is. Lit, there's no picking it back
## up. Aiming at a man (or at nothing in reach), E is the shove and kick as before (PlayerShove asks
## `claims_use()`).
##
## Bundles (#647, brief docs/briefs/dynamite-bundles.md; Sean on #648: prep them first, ~10-15 s of
## holding a key, and no fuss wiring them): R held `make_time` ties `bundle_sticks` of your loose
## sticks into a bundle (let go early and the work's kept); R tapped puts a stick or a bundle in
## your hand. A bundle is one charge of all their kg and one fuse: lit, thrown (shorter: it's
## heavier) or set down like a stick; planted with E it's capped and wired to your plunger box
## (PlungerViewmodel, 5) and waits unlit, at most `max_bundles` at once; a match aimed at it (Q)
## lights its fuse instead.

const HIP_POS := Vector3(0.16, -0.2, -0.3)
const HIP_ROT := Vector3(10.0, -20.0, 60.0)
const WINDUP_POS := Vector3(0.24, -0.08, -0.05)
const WINDUP_ROT := Vector3(-40.0, -10.0, 70.0)
const PUT_AWAY_POS := Vector3(0.25, -0.7, 0.0)
const LIGHT_TIME := 0.9
## The hand reaching down to the wall's foot as you set it.
const PLANT_POS := Vector3(0.05, -0.5, -0.4)
const PLANT_ROT := Vector3(-50.0, 0.0, 90.0)
## Both hands in front of you, tying a bundle.
const TIE_POS := Vector3(0.06, -0.24, -0.3)
const TIE_ROT := Vector3(-10.0, -60.0, 20.0)

signal thrown(stick: DynamiteStick)

## Loose sticks carried.
var sticks := 12
## Bundles made and carried (each `bundle_sticks`).
var bundles := 0
## A bundle in your hand (else a stick), while you've one.
var hold_bundle := false
## s of work on the next bundle (kept when you let go of R); 0 none started.
var making := 0.0
## s R has been held this press (-1 not held).
var r_held := -1.0
## The planted bundle the match you're striking is for (null: the one in your hand).
var lighting_planted: DynamiteStick
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
var _shown_bundle := 1


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
	if drawn and _draw >= 0.9 and planting < 0.0 and planted == null and not lit and lighting <= 0.0 \
			and Input.is_action_just_pressed(&"cock"):
		# A match to a bundle you set (aimed at, in reach) before the one in your hand.
		var aimed := aimed_charge()
		if aimed:
			light_planted(aimed)
			return
	if not drawn or _draw < 0.9 or not has_stick() or planting >= 0.0 or planted != null:
		windup = 0.0
		r_held = -1.0
		return
	_read_r(delta)
	if is_making():
		windup = 0.0
		return  # both hands at the cord
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
			and windup <= 0.0 and not is_making() and not hands_busy and not arm_disabled and not at_cap()
	if not free or _player == null or _player.camera == null:
		plant_at = {}
		planting = -1.0
		return
	var cam := _player.camera
	plant_at = plant_spot(World.space(self), cam.global_position, -cam.global_basis.z, _bt.plant_reach, [_player.get_rid()], DynamiteStick.radius_of(in_hand()))
	if planting >= 0.0:
		if plant_at.is_empty() or not Input.is_action_pressed(&"shove"):
			planting = -1.0  # let go too soon, or turned away: nothing set
			return
		planting += delta
		if planting >= _bt.plant_time:
			plant(plant_at)
	elif not plant_at.is_empty() and Input.is_action_just_pressed(&"shove"):
		planting = 0.0


## Where a stick goes for what you're aiming at from `eye` along `look` (within `reach`): right
## where the line meets it, on any structure's piece (a wall's board, a stud, a post, a beam, a
## floor, a sill) or the ground, lying flat to that face. Along the piece's own length where that
## lies across the face (up a post, along a board or a beam), else level across a wall, else along
## your look on a floor. Empty with nothing in reach, a man in the way (E is the shove then), or a
## loose thing (a rigid body) in front. Where you put it is your affair (Sean, 2026-10-31: "if you
## fuck up the placement in game that's the player's fault").
## {at: the stick's centre, basis: its long axis (Z) along the face, X out of it, wall: the face's
## normal, collider: what it's on}.
static func plant_spot(space: PhysicsDirectSpaceState3D, eye: Vector3, look: Vector3, reach: float, exclude: Array = [], radius := DynamiteStick.RADIUS) -> Dictionary:
	if space == null or look.length() < 0.01:
		return {}
	var dir := look.normalized()
	var q := PhysicsRayQueryParameters3D.create(eye, eye + dir * reach, Layers.WORLD | Layers.PEOPLE)
	q.exclude = exclude
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return {}
	var c: Object = hit.collider
	if c is RigidBody3D or c is CharacterBody3D or (c is CollisionObject3D and ((c as CollisionObject3D).collision_layer & Layers.WORLD) == 0):
		return {}
	var n: Vector3 = (hit.normal as Vector3).normalized()
	var along := Vector3.ZERO
	if c is StructureMember:
		var ax := (c as StructureMember).axis()
		ax = ax - n * ax.dot(n)
		if ax.length() > 0.5:
			along = ax.normalized()
	if along == Vector3.ZERO:
		along = n.cross(Vector3.UP)
		if along.length() < 0.3:
			# A floor, a ceiling, a beam's top: along your look.
			along = dir - n * dir.dot(n)
			if along.length() < 0.05:
				along = n.cross(Vector3.RIGHT)
		along = along.normalized()
	var at: Vector3 = (hit.position as Vector3) + n * (radius + 0.003)
	return {"at": at, "basis": Basis(n, along.cross(n), along).orthonormalized(), "wall": n, "collider": c}


## Set a stick (or the bundle) down at `spot` (`plant_spot()`), unlit: a stick's lit when E comes
## up, a bundle's left waiting. Returns it.
func plant(spot: Dictionary) -> DynamiteStick:
	planting = -1.0
	if spot.is_empty() or (sticks <= 0 and bundles <= 0) or (in_hand() > 1 and at_cap()):
		return null
	var s := DynamiteStick.make(_ballistics().get_parent(), spot.at, Vector3.ZERO, _bt.plant_fuse_seconds, in_hand())
	s.owner_node = _player
	s.global_basis = spot.basis
	s.stick_to(spot.collider)
	if s.is_bundle():
		s.wire()  # to your plunger box: no more to it than planting it (Sean, #648)
	_used()
	planted = s
	return s


func _light_planted() -> void:
	if planted.is_bundle():
		planted = null  # waits for a match (Q aimed at it)
		return
	planted.fuse_left = _bt.plant_fuse_seconds
	planted.light()
	_play(&"match")
	planted = null


## As many bundles set and waiting as you may have (`max_bundles`): no more till one's gone off.
func at_cap() -> bool:
	return in_hand() > 1 and is_inside_tree() and DynamiteStick.bundles_set(get_tree()).size() >= _bt.max_bundles


## The planted bundle, unlit, you're aiming at within reach (`light_reach`; within `light_aim` of
## your eye line), nearest first; null with none.
func aimed_charge() -> DynamiteStick:
	if _player == null or _player.camera == null or not is_inside_tree():
		return null
	var eye := _player.camera.global_position
	var look := -_player.camera.global_basis.z
	var best: DynamiteStick = null
	var best_along := INF
	for s in DynamiteStick.bundles_set(get_tree()):
		if s.lit:
			continue
		var along := (s.global_position - eye).dot(look)
		if along < 0.0 or along > _bt.light_reach:
			continue
		var off := (s.global_position - (eye + look * along)).length()
		if off <= _bt.light_aim + DynamiteStick.radius_of(s.sticks) and along < best_along:
			best = s
			best_along = along
	return best


## Strike a match and put it to a planted bundle's fuse (it gets `plant_fuse_seconds`).
func light_planted(s: DynamiteStick) -> void:
	if s == null or s.lit or lighting > 0.0:
		return
	lighting_planted = s
	lighting = LIGHT_TIME
	_play(&"match")


## Sticks in what's in your hand: a bundle's or 1.
func in_hand() -> int:
	return _bt.bundle_sticks if hold_bundle and bundles > 0 else 1


## Enough loose sticks for a bundle, and nothing else in your hands.
func can_make() -> bool:
	return sticks >= _bt.bundle_sticks and not lit and lighting <= 0.0 and windup <= 0.0 \
			and planting < 0.0 and planted == null


## Tying a bundle right now (R held past a tap).
func is_making() -> bool:
	return r_held >= _bt.r_tap and can_make()


## R: held, work on the next bundle (it's made at `make_time`, and the work's kept when you let go);
## tapped, a stick or a bundle in your hand.
func _read_r(delta: float) -> void:
	if Input.is_action_pressed(&"reload"):
		r_held = maxf(r_held, 0.0) + delta
		if is_making():
			work_on_bundle(delta)
	elif r_held >= 0.0:
		if r_held < _bt.r_tap:
			switch_in_hand()
		r_held = -1.0


## `dt` s more on the bundle you're tying; done at `make_time`: `bundle_sticks` loose sticks are a
## bundle, and it's in your hand.
func work_on_bundle(dt: float) -> void:
	if not can_make():
		return
	making += dt
	if making >= _bt.make_time:
		making = 0.0
		sticks -= _bt.bundle_sticks
		bundles += 1
		hold_bundle = true


## A stick in your hand if it was a bundle, a bundle if it was a stick (with one of each).
func switch_in_hand() -> void:
	if lit or lighting > 0.0:
		return
	hold_bundle = bundles > 0 and (not hold_bundle or sticks <= 0)


## The stick or bundle in your hand is gone (thrown, set, gone off): off what you carry.
func _used() -> void:
	if in_hand() > 1:
		bundles -= 1
	else:
		sticks = maxi(sticks - 1, 0)
	hold_bundle = bundles > 0 and (hold_bundle or sticks <= 0)
	_next_stick = 0.6


func has_stick() -> bool:
	return (sticks > 0 or bundles > 0) and _next_stick <= 0.0


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
		if lighting <= 0.0 and lighting_planted != null:
			if is_instance_valid(lighting_planted) and not lighting_planted.lit:
				lighting_planted.fuse_left = _bt.plant_fuse_seconds
				lighting_planted.light()
			lighting_planted = null
		elif lighting <= 0.0:
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
	# A bundle's heavier: thrown shorter (as the square root of its weight, the arm's work the same).
	var speed := lerpf(_bt.throw_speed_min, _bt.throw_speed_max, k) * clampf(1.0 / sqrt(float(in_hand())), 0.4, 1.0)
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
	var s := DynamiteStick.make(world, at, velocity, fuse_left if lit else _bt.fuse_seconds, in_hand())
	s.owner_node = _player
	s.global_basis = global_basis
	s.angular_velocity = Vector3(_rng.randf_range(-6, 6), _rng.randf_range(-3, 3), _rng.randf_range(-6, 6))
	if lit:
		s.light()
	lit = false
	lighting = 0.0
	_hiss.stop()
	_used()
	thrown.emit(s)
	return s


## Held it too long.
func _goes_off_in_hand() -> void:
	lit = false
	_hiss.stop()
	var kg := _bt.tnt_per_stick * in_hand()
	_used()
	var world := _ballistics().get_parent() as Node3D
	var at := stick_node.global_position
	_in_tick(func() -> void: Blast.detonate(world, at, kg, _player))  # (the fuse burns in _process)


func put_away() -> void:
	if lit:
		place()
	drawn = false


func take_out() -> void:
	drawn = true


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / 0.4)
	visible = _draw > 0.02
	stick_node.visible = has_stick() or is_making()
	hand.visible = true
	var winding := clampf(windup / _bt.throw_windup, 0.0, 1.0)
	var k := 1.0 - exp(-delta * 12.0)
	var setting := clampf(planting / maxf(_bt.plant_time, 0.01), 0.0, 1.0) if planting >= 0.0 else (1.0 if planted != null else 0.0)
	var tie_k := 1.0 if is_making() else 0.0
	_pose_pos = _pose_pos.lerp(HIP_POS.lerp(WINDUP_POS, winding).lerp(PLANT_POS, setting).lerp(TIE_POS, tie_k), k)
	_pose_rot = _pose_rot.lerp(HIP_ROT.lerp(WINDUP_ROT, winding).lerp(PLANT_ROT, setting).lerp(TIE_ROT, tie_k), k)
	# Tying: the sticks gathered into the hand as the work goes on (all of them at the last, the cord
	# going round).
	var shown := in_hand()
	if making > 0.0 and is_making():
		shown = clampi(1 + int(making / _bt.make_time * float(_bt.bundle_sticks)), 1, _bt.bundle_sticks)
	if shown != _shown_bundle:
		_show_bundle(shown)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * 10.0))
	_apply_pose(_draw)
	match_node.visible = lighting > 0.0
	_match_light.light_energy = 1.2 if lighting > 0.0 and lighting < LIGHT_TIME - 0.12 else 0.0
	DynamiteStick.show_fuse(_fuse, _sparks, fuse_left if lit else _bt.fuse_seconds, _bt.fuse_seconds, lit and stick_node.visible)
	_animate_camera(delta, _base_fov)


## The stick in your hand drawn as a bundle of `n`.
func _show_bundle(n: int) -> void:
	_shown_bundle = n
	for c in stick_node.get_children():
		stick_node.remove_child(c)
		c.queue_free()
	var parts := DynamiteStick.build_model(stick_node, 0.15, n)
	_fuse = parts.fuse
	_sparks = parts.sparks


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	position = PUT_AWAY_POS.lerp(_pose_pos.lerp(Vector3(0.15, -0.3, -0.12), t), drawn_amount) + _body_pos() * drawn_amount
	rotation_degrees = _pose_rot + _body_rotation() * drawn_amount
