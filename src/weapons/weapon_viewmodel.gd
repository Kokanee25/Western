class_name WeaponViewmodel
extends Node3D
## What every gun in the player's hands shares: whether it's out, the wound limits on it, pulling
## back from walls (the tuck), where a shot starts and which way it goes, sounds. Each gun sits
## under the player's camera; only the `selected` one reads the controls and moves the camera.
## Subclasses set `_pose_pos`/`_pose_rot` (where the gun is heading) and `_muzzle_local`.

## Up close to a wall (or a person) the gun comes back to the chest instead of pushing through.
## Clearance kept between the muzzle and the wall, and over how much extra closeness the gun goes
## from fully out to fully tucked (metres).
const TUCK_MARGIN := 0.06
const TUCK_RANGE := 0.22
## What the gun can't pass through: the world and living people (not debris, not the player).
const TUCK_MASK := Layers.WORLD | Layers.PEOPLE

## The gun in your hands (the others are put away). The player switches them.
var selected := true
var drawn := true
var aiming := false
## Wounds: hands busy pressing on a wound, or the gun arm can't hold it (PlayerWounds sets these).
var hands_busy := false
var arm_disabled := false
## Extra wobble from pain, shock and a wounded arm, degrees.
var extra_spread := 0.0
## Tests and scripted scenes drive the gun without a captured mouse.
var needs_captured_mouse := true
## 0 = gun out in its pose, 1 = pulled right back against a wall. Smoothed; see _probe_wall().
var tuck := 0.0
## Where the last shot started (tests check it can't start beyond a wall).
var last_shot_origin := Vector3.ZERO

var _player: Player
var _rng := RandomNumberGenerator.new()
var _pose_pos := Vector3.ZERO
var _pose_rot := Vector3.ZERO
## 0 = put away, 1 = in the hands.
var _draw := 1.0
var _tuck_target := 0.0
var _muzzle_local := Vector3(0, 0.02, -0.3)
var _probe_shape := SphereShape3D.new()
var _sounds := {}
var _base_fov := 75.0
var _view_kick := 0.0


func _setup_common() -> void:
	_player = _find_player()
	var cam := get_parent() as Camera3D
	if cam:
		_base_fov = cam.fov
	_probe_shape.radius = 0.03


func _find_player() -> Player:
	var n := get_parent()
	while n and not n is Player:
		n = n.get_parent()
	return n as Player


func _add_sound(id: StringName, loud := false) -> void:
	var p := AudioStreamPlayer3D.new()
	p.name = "Sound_" + id
	p.stream = SynthSounds.get_sound(id)
	p.unit_size = 25.0 if loud else 2.0
	p.max_db = 6.0 if loud else 0.0
	p.volume_db = 0.0 if loud else -6.0
	add_child(p)
	_sounds[id] = p


func _play(id: StringName) -> void:
	var p: AudioStreamPlayer3D = _sounds.get(id)
	if p:
		p.play()


## Put it away (holstered, slung) or bring it out; each gun does its own.
func put_away() -> void:
	drawn = false
	aiming = false


func take_out() -> void:
	drawn = true


## Fully in the hands and ready to use.
func is_ready_in_hand() -> bool:
	return selected and drawn and _draw >= 0.9


## Fully put away (switching guns waits for this).
func is_put_away() -> bool:
	return _draw <= 0.02


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
	return selected and not (_player and not _player.input_enabled)


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


func _action_ok(action: StringName) -> bool:
	return _mouse_ready() or not _pressed_by_mouse_only(action)


## Where a shot from `muzzle` starts and which way it goes: towards whatever the crosshair is on
## (so the sights are true), but never starting beyond a wall between the eye and the muzzle.
## Returns [origin, direction, exclude].
func _shot_line(muzzle: Vector3) -> Array:
	var cam := get_viewport().get_camera_3d() if get_viewport() else null
	var origin := muzzle
	var aim_dir := -global_transform.basis.z
	var aim_point := origin + aim_dir * 60.0
	var exclude: Array[RID] = []
	if _player:
		exclude.append(_player.get_rid())
	if cam:
		var q0 := PhysicsRayQueryParameters3D.create(cam.global_position, origin, Layers.BULLETS)
		q0.exclude = exclude
		var blocked := get_world_3d().direct_space_state.intersect_ray(q0)
		if not blocked.is_empty():
			origin = blocked.position + (cam.global_position - blocked.position).normalized() * 0.01
		aim_dir = -cam.global_transform.basis.z
		aim_point = cam.global_position + aim_dir * 80.0
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, aim_point, Layers.BULLETS)
		q.exclude = exclude
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and cam.global_position.distance_to(hit.position) > 0.6:
			aim_point = hit.position
	last_shot_origin = origin
	return [origin, (aim_point - origin).normalized(), exclude]


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


## The camera's kick and zoom; only the gun in your hands moves the camera.
func _animate_camera(delta: float, aim_fov: float) -> void:
	var cam := get_parent() as Camera3D
	if cam == null or not selected:
		return
	_view_kick = move_toward(_view_kick, 0.0, delta * (4.0 + _view_kick * 6.0))
	cam.rotation.x = deg_to_rad(_view_kick)
	cam.fov = lerpf(cam.fov, aim_fov if aiming else _base_fov, 1.0 - exp(-delta * 10.0))
