class_name FaceGaze
extends Node
## A talking man's eyes and head on a target (a node, or a point): his eye shapes (look_left,
## look_right, look_up, look_down: tools/faces/talking_face.py) carry the first eye_range degrees,
## measured from where his head really points this frame, so the eyes stay on the target while the
## head catches up; his head (HumanBody.pose_offsets) takes the rest of a big turn. Blinks now and
## then, and on a big jump. Its numbers are GazeTuning's (config/gaze.tres).
##
## Add as a child of a HumanBody built from a talking model: `var g := FaceGaze.new(); g.body = man;
## g.target = player_camera; man.add_child(g)`. With `auto` off, call step(delta) yourself (the face
## lab does, a fixed step a frame). Who a man looks at is his brain's call; this only looks.

const SHAPES := [&"look_left", &"look_right", &"look_up", &"look_down", &"blink_l", &"blink_r"]

var body: HumanBody
## The node looked at (its position; a Camera3D's is the player's eyes), or `target_point` if none.
var target: Node3D
var target_point := Vector3.ZERO
var tuning: GazeTuning
## Drive the blinks too (off when something else does, a take for one).
var blinks := true
## Stepped from _process; off: call step() yourself.
var auto := true
## Off: his eyes ahead, his head his pose's (the shapes and pose_offsets let go).
var active := true
var rng_seed := 0

var _faces: Array[MeshInstance3D] = []
var _index := []         # per face, per SHAPES entry: its blend shape (-1: none)
var _eye_local := Vector3.ZERO   # his eyes' midpoint in his head part's space
var _eye := Vector2.ZERO          # degrees: left (+) / up (+), in his head's frame, as drawn
var _head := Vector2.ZERO         # degrees: left (+) / up (+), his head's offset over his pose
var _last_goal := Vector2.ZERO
var _micro := Vector2.ZERO
var _micro_in := 0.0
var _blink_in := 0.0
var _blink_t := -1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if tuning == null:
		tuning = load("res://config/gaze.tres")
	_rng.seed = rng_seed
	_blink_in = _rng.randf_range(tuning.blink_every.x, tuning.blink_every.y)
	_micro_in = _rng.randf_range(tuning.micro_every.x, tuning.micro_every.y)
	if body == null and get_parent() is HumanBody:
		body = get_parent()
	_find_faces()


func _process(delta: float) -> void:
	if auto:
		step(delta)


## The shapes found on his head: false if he has no look shapes (not a talking model).
func has_face() -> bool:
	return not _faces.is_empty()


func _find_faces() -> void:
	_faces.clear()
	_index.clear()
	if body == null:
		return
	for c in body.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		var am := mi.mesh as ArrayMesh
		if am == null or am.get_blend_shape_count() == 0:
			continue
		var ids := []
		for s: StringName in SHAPES:
			ids.append(mi.find_blend_shape_by_name(s))
		if ids[0] >= 0:
			_faces.append(mi)
			_index.append(ids)
	# His own eyes (his talking model's report: its eyeballs' middle), else the anatomy's.
	var rig: Dictionary = PeopleBodies.report(body.body_model).get("facerig", {})
	var mid := Vector3.ZERO
	if rig.has("eye_centre"):
		var c: Array = rig.eye_centre
		mid = Vector3(c[0], c[1], c[2])
	else:
		var r: Dictionary = body.anatomy.structure(&"eye_r")
		var l: Dictionary = body.anatomy.structure(&"eye_l")
		if not r.is_empty() and not l.is_empty():
			mid = 0.5 * ((r.a as Vector3) + (l.a as Vector3))
	_eye_local = mid - body.anatomy.segment_center(&"head")


func step(delta: float) -> void:
	if body == null or not body.parts.has(&"head") or _faces.is_empty():
		return
	var head := body.parts[&"head"] as Node3D
	var goal_eye := Vector2.ZERO
	var goal_head := Vector2.ZERO
	if active:
		var at := target.global_position if target != null else target_point
		var eye := head.global_transform * _eye_local
		# The target in his body's frame (where he faces), for how far his head should go ...
		goal_head = _angles(body.global_transform.basis.inverse() * (at - eye))
		var big := maxf(absf(goal_head.x), absf(goal_head.y))
		var k := smoothstep(tuning.eye_comfort * 0.5, tuning.eye_comfort, big)
		goal_head = Vector2(clampf(goal_head.x * tuning.head_share * k, -tuning.head_yaw_max, tuning.head_yaw_max),
				clampf(goal_head.y * tuning.head_share * k, -tuning.head_pitch_max, tuning.head_pitch_max))
		# ... and in his head's frame as it is now, for his eyes (they cover what it hasn't yet).
		goal_eye = _angles(head.global_transform.basis.inverse() * (at - eye))
		if blinks and (goal_eye - _last_goal).length() > tuning.blink_on_shift and _blink_t < 0.0 \
				and _rng.randf() < tuning.blink_shift_chance:
			_blink_t = 0.0
		_last_goal = goal_eye
	_head = _head.lerp(goal_head, 1.0 - exp(-delta / tuning.head_time))
	_micro_in -= delta
	if _micro_in <= 0.0:
		_micro_in = _rng.randf_range(tuning.micro_every.x, tuning.micro_every.y)
		_micro = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * tuning.micro
	_eye = _eye.lerp(goal_eye + (_micro if active else Vector2.ZERO), 1.0 - exp(-delta / tuning.eye_time))
	# His head over his pose: HumanBody's pose axes (degrees; x tips his head up, y turns it to his
	# left: checked in the face lab, --mode=gaze --check).
	if active or not _head.is_zero_approx():
		body.pose_offsets[&"head"] = Vector3(_head.y, _head.x, 0.0)
	var blink := 0.0
	if blinks:
		_blink_in -= delta
		if _blink_in <= 0.0 and _blink_t < 0.0:
			_blink_t = 0.0
		if _blink_t >= 0.0:
			_blink_t += delta
			var u := _blink_t / tuning.blink_time
			blink = clampf(1.0 - absf(2.0 * u - 1.0), 0.0, 1.0)
			if u >= 1.0:
				_blink_t = -1.0
				_blink_in = _rng.randf_range(tuning.blink_every.x, tuning.blink_every.y)
	var e := _eye / tuning.eye_range
	var w := [maxf(e.x, 0.0), maxf(-e.x, 0.0), maxf(e.y, 0.0), maxf(-e.y, 0.0), blink, blink]
	for f in _faces.size():
		var ids: Array = _index[f]
		for k in SHAPES.size():
			if ids[k] >= 0 and (k < 4 or blinks):
				_faces[f].set_blend_shape_value(ids[k], clampf(w[k], 0.0, 1.0))


## Degrees (left +, up +) of a direction in a frame where he faces -Z and his left is -X.
static func _angles(d: Vector3) -> Vector2:
	if d.length_squared() < 1e-8:
		return Vector2.ZERO
	return Vector2(rad_to_deg(atan2(-d.x, -d.z)), rad_to_deg(atan2(d.y, Vector2(d.x, d.z).length())))


## Where he's looking now, degrees (left +, up +) from his body's facing: head and eyes together.
func looking() -> Vector2:
	return _head + _eye
