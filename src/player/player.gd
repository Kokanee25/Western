class_name Player
extends CharacterBody3D
## First-person player: walk, run, crouch, jump and look, on keyboard + mouse or controller.
## Actions are polled, so the player works wherever it sits in the viewport tree. Mouse and touch
## look arrive through Events.look_input; the right stick is read here. How the body carries the
## eyes and the gun (steps, lean, dips, momentum's feel) is PlayerMotion; three ways of moving
## (light, middle, heavy) are presets of its dials, switched on F (`set_movement`).

signal movement_changed(preset: StringName)

## The movement presets (config/movement/): only the movement dials are taken from them.
const MOVEMENT_PRESETS := {&"light": "res://config/movement/light.tres",
		&"middle": "res://config/movement/middle.tres", &"heavy": "res://config/movement/heavy.tres"}

@export var tuning: PlayerTuning
## Which preset the movement dials came from (the game's own tuning is middle).
var movement := &"middle"
var motion := PlayerMotion.new()

var input_enabled := true
## Set by wounds (PlayerWounds): slower, no running or jumping, down on the ground.
var move_factor := 1.0
var can_sprint := true
var can_jump := true
var force_crouch := false
var is_crouching := false
var is_running := false
var wounds: PlayerWounds
var composure: PlayerComposure
## The guns under the camera (the revolver, the shotgun), and the one in your hands.
var weapons: Array[WeaponViewmodel] = []
var weapon: WeaponViewmodel
var _switch_to: WeaponViewmodel
## What you do that people notice (drawing, aiming at them, crowding them...).
var deeds: PlayerDeeds

var _crouch_toggled := false
var _run_latched := false
var _eye_height := 0.0
var _pitch := 0.0
## The lean's pitch now on the head (degrees), on top of your own.
var _tilt := 0.0
var _capsule: CapsuleShape3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var body: PlayerBody = $Body


func _ready() -> void:
	add_to_group(&"player")
	collision_mask |= Layers.PEOPLE | Layers.WALK
	wounds = PlayerWounds.new()
	wounds.name = "Wounds"
	add_child(wounds)
	if tuning == null:
		tuning = PlayerTuning.new()
	composure = PlayerComposure.new()
	composure.name = "Composure"
	add_child(composure)
	_capsule = CapsuleShape3D.new()
	_capsule.radius = tuning.radius
	collision.shape = _capsule
	_set_collision_height(tuning.stand_height)
	_eye_height = tuning.stand_eye_height
	motion.reset(_eye_height)
	head.position.y = _eye_height
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(46.0)
	Events.look_input.connect(add_look)
	_arm()


var _step_n := 0


## Footfalls people can hear: running carries, walking a little, creeping crouched hardly at all.
## One on each step the body takes (PlayerMotion), so the sound lands with the head's low.
func _footsteps() -> void:
	if not motion.footfall:
		return
	var loud := 2.0 if is_crouching else (13.0 if is_running else 6.0)
	Events.noise.emit(global_position, loud, &"footsteps", self)
	if GameAudio.enabled():
		# The sound lab: on boards (any timber underfoot) a hollow knock, on the street's dirt a crunch.
		var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.2, global_position + Vector3.DOWN * 0.4, Layers.STAND)
		q.exclude = [get_rid()]
		var under := get_world_3d().direct_space_state.intersect_ray(q)
		var boards: bool = not under.is_empty() and (under.collider is StructureMember or under.collider is KitProp)
		_step_n += 1
		var id := StringName("step_%s_%d" % ["boards" if boards else "dirt", _step_n % 4])
		GameAudio.play(self, id, global_position, {"unit_size": 1.5, "max_db": 0.0, "walls": false, "delay": false,
				"volume_db": -14.0 if is_crouching else (-4.0 if is_running else -9.0)})


## The revolver comes from the scene (Head/Camera3D/Gun); the shotgun, the dynamite and a water
## bucket are added beside it, put away.
func _arm() -> void:
	var revolver := camera.get_node_or_null(^"Gun") as WeaponViewmodel
	if revolver:
		weapons.append(revolver)
	var shotgun := ShotgunViewmodel.new()
	shotgun.name = "Shotgun"
	shotgun.selected = false
	shotgun.drawn = false
	shotgun._draw = 0.0
	camera.add_child(shotgun)
	weapons.append(shotgun)
	var dynamite := DynamiteViewmodel.new()
	dynamite.name = "Dynamite"
	dynamite.selected = false
	dynamite.drawn = false
	dynamite._draw = 0.0
	camera.add_child(dynamite)
	weapons.append(dynamite)
	var bucket := BucketViewmodel.new()
	bucket.name = "Bucket"
	bucket.selected = false
	bucket.drawn = false
	bucket._draw = 0.0
	camera.add_child(bucket)
	weapons.append(bucket)
	weapon = weapons[0]
	# You walk about with the gun in its holster; drawing it is something people notice (H).
	if revolver:
		revolver.drawn = false
		revolver._draw = 0.0
		revolver.visible = false
	if body:
		body.set_gun_holstered.call_deferred(true)
	deeds = PlayerDeeds.new()
	deeds.name = "Deeds"
	add_child(deeds)


func revolver() -> RevolverViewmodel:
	return camera.get_node_or_null(^"Gun") as RevolverViewmodel


func shotgun() -> ShotgunViewmodel:
	return camera.get_node_or_null(^"Shotgun") as ShotgunViewmodel


func dynamite() -> DynamiteViewmodel:
	return camera.get_node_or_null(^"Dynamite") as DynamiteViewmodel


func bucket() -> BucketViewmodel:
	return camera.get_node_or_null(^"Bucket") as BucketViewmodel


## Put the gun in your hands away and bring out another once it is.
func select_weapon(w: WeaponViewmodel) -> void:
	if w == null:
		return
	if w == weapon and _switch_to == null:
		w.take_out()
		return
	if weapon:
		weapon.put_away()
		weapon.selected = false
	_switch_to = w


func _update_weapon_switch() -> void:
	if input_enabled:
		if Input.is_action_just_pressed(&"weapon_revolver"):
			select_weapon(revolver())
		elif Input.is_action_just_pressed(&"weapon_shotgun"):
			select_weapon(shotgun())
		elif Input.is_action_just_pressed(&"weapon_dynamite"):
			select_weapon(dynamite())
		elif Input.is_action_just_pressed(&"weapon_bucket"):
			select_weapon(bucket())
		elif Input.is_action_just_pressed(&"weapon_next") and weapons.size() > 1:
			var current := _switch_to if _switch_to else weapon
			select_weapon(weapons[(weapons.find(current) + 1) % weapons.size()])
	if _switch_to and (weapon == null or weapon.is_put_away()):
		weapon = _switch_to
		_switch_to = null
		weapon.selected = true
		weapon.take_out()


## Turn and pitch the view. x turns right, y pitches up, both in degrees. `lags`: the gun in
## your hands lags the turn (not when the gun itself is what turned you: its kick's climb).
func add_look(delta_degrees: Vector2, lags := true) -> void:
	if not input_enabled:
		return
	rotate_y(deg_to_rad(-delta_degrees.x))
	var was := _pitch
	_pitch = clampf(_pitch + delta_degrees.y, -tuning.max_pitch_degrees, tuning.max_pitch_degrees)
	head.rotation.x = deg_to_rad(_pitch + _tilt)
	if lags:
		motion.looked(Vector2(delta_degrees.x, _pitch - was))


## Move like this preset (light, middle or heavy): its movement dials, not the gun's.
func set_movement(preset: StringName) -> void:
	if not MOVEMENT_PRESETS.has(preset):
		return
	if tuning.resource_path != "":
		tuning = tuning.duplicate()  # don't change the shared config for every scene after
	tuning.take_movement(load(MOVEMENT_PRESETS[preset]) as PlayerTuning)
	movement = preset
	movement_changed.emit(preset)


func next_movement() -> void:
	var names: Array = MOVEMENT_PRESETS.keys()
	set_movement(names[(names.find(movement) + 1) % names.size()])


func get_pitch_degrees() -> float:
	return _pitch


func get_eye_height() -> float:
	return _eye_height


func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## The direction the player faces on the ground plane.
func get_forward() -> Vector3:
	return -global_transform.basis.z


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"player", t)


func _physics_step(delta: float) -> void:
	_update_weapon_switch()
	if input_enabled and Input.is_action_just_pressed(&"movement_preset"):
		next_movement()
	var move := Vector2.ZERO
	var wants_jump := false
	var wants_run := false
	var wants_crouch := false
	if input_enabled:
		move = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		_stick_look(delta)
		if Input.is_action_just_pressed(&"crouch_toggle"):
			_crouch_toggled = not _crouch_toggled
		if Input.is_action_just_pressed(&"run_toggle"):
			_run_latched = true
		if move.length() < 0.1:
			_run_latched = false
		wants_run = Input.is_action_pressed(&"run") or _run_latched
		if wants_run and move.length() > 0.1:
			_crouch_toggled = false
		wants_crouch = _crouch_toggled or Input.is_action_pressed(&"crouch")
		wants_jump = Input.is_action_just_pressed(&"jump") and can_jump
	wants_run = wants_run and can_sprint
	wants_crouch = wants_crouch or force_crouch

	_update_crouch(wants_crouch)
	is_running = wants_run and not is_crouching and move.length() > 0.1

	var speed := tuning.walk_speed
	if is_crouching:
		speed = tuning.crouch_speed
	elif is_running:
		# Blown from running, the run sags.
		var blown := clampf((composure.winded - 0.5) * 2.0, 0.0, 1.0) if composure else 0.0
		speed = tuning.run_speed * (1.0 - tuning.winded_slow * blown)
	speed *= move_factor
	var wish := global_transform.basis * Vector3(move.x, 0.0, move.y)
	wish.y = 0.0
	var target := Vector2(wish.x, wish.z) * speed

	var on_floor := is_on_floor()
	var horizontal := Vector2(velocity.x, velocity.z)
	if not on_floor:
		horizontal = horizontal.move_toward(target, tuning.air_accel * delta)
	else:
		horizontal = _momentum(horizontal, target, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if on_floor:
		if wants_jump:
			velocity.y = tuning.jump_velocity
	else:
		velocity.y -= tuning.gravity * delta
	var falling := -velocity.y
	if on_floor:
		_step_up(delta)
	move_and_slide()
	_update_head(delta, falling)
	_footsteps()


## Steps and stairs: blocked low down (a riser, a tread's nosing, a porch step), try the same move
## lifted by up to `step_height`; if it lands on floor you can stand on, go up onto it. The eyes
## ease over the lift (PlayerMotion.stepped) so a stair is a climb, not a jolt.
func _step_up(delta: float) -> void:
	var move := Vector3(velocity.x, 0.0, velocity.z) * delta
	if move.length() < 0.0005:
		return
	var hit := KinematicCollision3D.new()
	if not test_move(global_transform, move, hit) or hit.get_normal().y > 0.7:
		return
	# Feel for the step half a body's width on (only lifted there, not moved: the slide does that),
	# so a rounded heel doesn't come down on the very edge of the tread.
	var reach := move.normalized() * maxf(move.length(), tuning.radius * 0.5)
	var lifted := global_transform
	var rise := Vector3.UP * tuning.step_height
	if test_move(lifted, rise):
		return  # no headroom
	lifted.origin += rise
	if test_move(lifted, reach):
		return  # still blocked up there: a wall, not a step
	lifted.origin += reach
	var down := KinematicCollision3D.new()
	if not test_move(lifted, -rise, down) or down.get_normal().y < cos(floor_max_angle):
		return
	var gained := lifted.origin.y + down.get_travel().y - global_position.y
	if gained < 0.01 or gained > tuning.step_height:
		return
	global_position.y += gained
	motion.stepped(gained)


## Speed on the ground with weight: along the way you want to go it builds (quick to a walk,
## slower on to a full run) and sheds (letting go, or pushing back against it); across it, your
## boots grip and take it off, so a turn at a run carries you wide a little.
func _momentum(horizontal: Vector2, target: Vector2, delta: float) -> Vector2:
	var t := tuning
	if target.length() < 0.01:
		return horizontal.move_toward(Vector2.ZERO, t.ground_decel * delta)
	var dir := target.normalized()
	var along := horizontal.dot(dir)
	var across := horizontal - dir * along
	var goal := target.length()
	var rate := t.run_build
	if along < 0.0:
		rate = t.reverse_decel
	elif along > goal:
		rate = t.ground_decel
	elif along < t.walk_speed * move_factor:
		rate = t.ground_accel
	along = move_toward(along, goal, rate * delta)
	across = across.move_toward(Vector2.ZERO, t.turn_grip * delta)
	return dir * along + across


func _stick_look(delta: float) -> void:
	var stick := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if stick == Vector2.ZERO:
		return
	stick *= stick.length()  # gentle near the centre, fast at the edge
	var y_sign := 1.0 if Settings.invert_y else -1.0
	add_look(Vector2(stick.x, stick.y * y_sign) * Settings.stick_look_speed * delta)


func _update_crouch(wants_crouch: bool) -> void:
	if wants_crouch and not is_crouching:
		is_crouching = true
		_set_collision_height(tuning.crouch_height)
	elif not wants_crouch and is_crouching and can_stand():
		is_crouching = false
		_set_collision_height(tuning.stand_height)


## True when there is headroom to stand up from a crouch.
func can_stand() -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = tuning.radius * 0.9
	shape.height = tuning.stand_height - 0.12
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), global_position + Vector3.UP * (tuning.stand_height * 0.5 + 0.08))
	params.exclude = [get_rid()]
	params.collision_mask = collision_mask
	return get_world_3d().direct_space_state.intersect_shape(params, 1).is_empty()


func _set_collision_height(height: float) -> void:
	_capsule.height = height
	collision.position = Vector3(0.0, height * 0.5, 0.0)


## The eyes where the body carries them (PlayerMotion): steps, lean, dips, the crouch's spring.
## `falling` is how fast you were coming down before this frame's move (m/s).
func _update_head(delta: float, falling: float) -> void:
	var speed := get_horizontal_speed()
	var grounded := is_on_floor()
	var aiming := weapon != null and weapon.aiming
	var winded := composure.winded if composure else 0.0
	motion.step(tuning, delta, global_basis.inverse() * velocity, grounded, is_crouching, aiming, winded, falling)
	_eye_height = motion.eye_height
	head.position = Vector3(motion.head_pos.x, _eye_height + motion.head_pos.y, 0.0)
	# The lean's pitch goes on top of yours by its change, so whoever else turns the head keeps it.
	head.rotation.x += deg_to_rad(motion.head_turn.x - _tilt)
	_tilt = motion.head_turn.x
	head.rotation.z = deg_to_rad(motion.head_turn.z)
	var crouch_amount := inverse_lerp(tuning.stand_eye_height, tuning.crouch_eye_height, _eye_height)
	# The legs: widest apart as each foot comes down.
	body.update_pose(delta, speed, clampf(crouch_amount, 0.0, 1.0), grounded, motion.steps + 0.5, _pitch)
