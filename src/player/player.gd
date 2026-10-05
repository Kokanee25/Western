class_name Player
extends CharacterBody3D
## First-person player: walk, run, crouch, jump and look, on keyboard + mouse or controller.
## Actions are polled, so the player works wherever it sits in the viewport tree. Mouse and touch
## look arrive through Events.look_input; the right stick is read here.

@export var tuning: PlayerTuning

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
var _step_left := 0.75
## What you do that people notice (drawing, aiming at them, crowding them...).
var deeds: PlayerDeeds

var _crouch_toggled := false
var _run_latched := false
var _eye_height := 0.0
var _bob_phase := 0.0
var _pitch := 0.0
var _capsule: CapsuleShape3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var body: PlayerBody = $Body


func _ready() -> void:
	add_to_group(&"player")
	collision_mask |= Layers.PEOPLE
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
	head.position.y = _eye_height
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(46.0)
	Events.look_input.connect(add_look)
	_arm()


## Footfalls people can hear: running carries, walking a little, creeping crouched hardly at all.
func _footsteps(delta: float) -> void:
	var speed := get_horizontal_speed()
	if speed < 0.3 or not is_on_floor():
		return
	_step_left -= speed * delta
	if _step_left > 0.0:
		return
	_step_left = 0.75
	var loud := 2.0 if is_crouching else (13.0 if is_running else 6.0)
	Events.noise.emit(global_position, loud, &"footsteps", self)


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


## Turn and pitch the view. x turns right, y pitches up, both in degrees.
func add_look(delta_degrees: Vector2) -> void:
	if not input_enabled:
		return
	rotate_y(deg_to_rad(-delta_degrees.x))
	_pitch = clampf(_pitch + delta_degrees.y, -tuning.max_pitch_degrees, tuning.max_pitch_degrees)
	head.rotation.x = deg_to_rad(_pitch)


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
		speed = tuning.run_speed
	speed *= move_factor
	var wish := global_transform.basis * Vector3(move.x, 0.0, move.y)
	wish.y = 0.0
	var target := Vector2(wish.x, wish.z) * speed

	var on_floor := is_on_floor()
	var accel := tuning.ground_accel if on_floor else tuning.air_accel
	if on_floor and target.length() < 0.01:
		accel = tuning.ground_decel
	var horizontal := Vector2(velocity.x, velocity.z).move_toward(target, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	if on_floor:
		if wants_jump:
			velocity.y = tuning.jump_velocity
	else:
		velocity.y -= tuning.gravity * delta
	move_and_slide()
	_footsteps(delta)
	_update_head(delta)


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


func _update_head(delta: float) -> void:
	var target_eye := tuning.crouch_eye_height if is_crouching else tuning.stand_eye_height
	_eye_height = move_toward(_eye_height, target_eye, tuning.crouch_transition_speed * delta)
	var speed := get_horizontal_speed()
	var grounded := is_on_floor()
	if grounded and speed > 0.2:
		_bob_phase += speed * delta * tuning.bob_cycles_per_meter
	var bob_strength := clampf(speed / tuning.walk_speed, 0.0, 1.6) if grounded else 0.0
	head.position.y = _eye_height + sin(_bob_phase * TAU) * tuning.bob_amplitude * bob_strength
	var crouch_amount := inverse_lerp(tuning.stand_eye_height, tuning.crouch_eye_height, _eye_height)
	body.update_pose(delta, speed, clampf(crouch_amount, 0.0, 1.0), grounded, _bob_phase, _pitch)
