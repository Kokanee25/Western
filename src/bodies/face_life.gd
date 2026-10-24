class_name FaceLife
extends Node
## A talking man's face alive in the game (Sean, 2026-10-22: "make them look around and blink and
## react"): what he looks at, and how his face answers what happens to him. The looking (eyes first,
## the head after) and the blinks are his FaceGaze's; this chooses the target and sets his
## expression shapes (tools/faces/talking_face.py: brows_up, brows_down, squint, scowl).
##
## What he looks at: whoever his brain is fighting; else a sound he's just started at; else the
## people his Senses see, weighed by how near, the player, moving, just seen, and less the longer
## he's looked (he holds a look a while, then may glance off at nothing); with nobody about, his
## eyes wander ahead; a deed can have him watch his work (`attend_to`). His face: a start at a shot (brows up, a blink), his pain as a grimace as it
## arrives, wide eyes and quick blinks when afraid, his eyes narrowed aiming; out cold his lids
## close, dead they settle part shut and his eyes go still. Numbers in config/face_life.tres.
##
## HumanBody adds one to a man whose model has a talking face (its report's "facerig"); further
## from the camera than near_camera it rests (nobody can see his eyes there).

const EXPRESSIONS := [&"brows_up", &"brows_down", &"squint", &"scowl"]
## The noises that start him (Events.noise kinds); any other he hears only draws a look.
const STARTLING := [&"gunshot", &"glass", &"timber"]
## Off for a whole run: the fixed screenshot views hold every face at rest (their golden images).
static var enabled := true

var body: HumanBody
var tuning: FaceLifeTuning
var gaze: FaceGaze
## Stepped from _physics_process (a fixed step, so a run plays the same twice); off: call step().
var auto := true
## Where the camera is for the near_camera rest (null: the viewport's camera; none: always near).
var camera: Node3D

var _brain: Node
var _senses: Senses
var _faces: Array[MeshInstance3D] = []
var _index := []                 # per face, per EXPRESSIONS entry: its blend shape (-1: none)
var _w := [0.0, 0.0, 0.0, 0.0]    # the expressions' weights now
var _who: Node3D                  # whom he's looking at (null: a point)
var _point := Vector3.ZERO        # the point he's looking at when nobody
var _hold := 0.0                  # seconds left on this look
var _startled := 0.0              # seconds left looking at what started him
var _startle := 0.0               # 0..1, his start fading
var _pick_in := 0.0
var _looked := {}                 # who -> seconds looked at lately (boredom)
var _first := {}                  # who -> his clock when first seen
var _clock := 0.0
var _lids := 0.0
var _rng := RandomNumberGenerator.new()
## A point a deed has him watching (his work: the bar under the cloth he's wiping), renewed every
## tick it's wanted (`attend_to`); a start and a fight still take his eyes off it.
var _attend := Vector3.INF
var _attend_frame := -10
var _attend_over := false  ## ... even in a fight or a start (a man looking at his own wound)


func _ready() -> void:
	if tuning == null:
		tuning = load("res://config/face_life.tres")
	if body == null and get_parent() is HumanBody:
		body = get_parent()
	_rng.seed = hash(["face_life", body.rng_seed if body else 0])
	if gaze == null:
		gaze = FaceGaze.new()
		gaze.name = "Gaze"
		gaze.body = body
		gaze.auto = false
		gaze.rng_seed = hash(["gaze", body.rng_seed if body else 0])
		add_child(gaze)
	_find_faces()
	_pick_in = _rng.randf_range(0.0, tuning.pick_every)
	_point = _ahead(Vector2.ZERO)
	Events.exploded.connect(_on_exploded)
	Events.near_miss.connect(_on_near_miss)


func _physics_process(delta: float) -> void:
	if auto and enabled:
		step(delta)


## Does he have a face to drive (a talking model's look shapes)?
func has_face() -> bool:
	return gaze != null and gaze.has_face()


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
		for s: StringName in EXPRESSIONS:
			ids.append(mi.find_blend_shape_by_name(s))
		_faces.append(mi)
		_index.append(ids)


func step(delta: float) -> void:
	if body == null or not has_face() or not body.parts.has(&"head"):
		return
	_clock += delta
	var p := body.physiology
	if not p.alive or not p.is_conscious():
		# Dead, his lids settle part shut and his eyes stop; out cold, they close.
		gaze.active = false
		gaze.blink_rate = 0.0
		var lids := tuning.dead_lids if not p.alive else tuning.out_lids
		_lids = move_toward(_lids, lids, delta / maxf(tuning.lids_time, 0.01))
		gaze.lids = _lids
		_express([0.0, 0.0, 0.0, 0.0], delta)
		gaze.step(delta)
		return
	_lids = move_toward(_lids, 0.0, delta / maxf(tuning.lids_time, 0.01))
	gaze.lids = _lids
	gaze.active = true
	if not _near():
		return
	_hook_senses()
	var fear := clampf(float(_brain.get("fear")) if _brain != null and "fear" in _brain else 0.0, 0.0, 1.0)
	_hold -= delta
	_startled -= delta
	_startle = maxf(_startle - delta / maxf(tuning.startle_fade, 0.01), 0.0)
	if is_instance_valid(_who):
		_looked[_who] = float(_looked.get(_who, 0.0)) + delta
	for w: Variant in _looked.keys():
		if is_instance_valid(w) and w != _who:
			_looked[w] = maxf(float(_looked[w]) - delta * 0.5, 0.0)
	_pick_in -= delta
	if _pick_in <= 0.0:
		_pick_in = tuning.pick_every
		_pick(fear)
	if not is_instance_valid(_who):
		_who = null   # (gone: he looks at the point he had till his next pick)
	if attending() and (_attend_over or _startled <= 0.0 and not _fighting()):
		_who = null   # at his work: his eyes on it
		_point = _attend
	gaze.target = _who
	gaze.target_point = _point
	var aiming := body.pose == &"aim" or body.pose == &"crouch_aim" or body.pose == &"prone_aim"
	gaze.head = not aiming
	gaze.blink_rate = lerpf(1.0, tuning.fear_blink, fear)
	var hurt := clampf(p.felt_pain() / maxf(p.tuning.pain_faint, 0.01), 0.0, 1.0) * tuning.pain_grimace
	var up := maxf(tuning.startle_brows * _startle, tuning.fear_brows * fear) * (1.0 - hurt)
	_express([up, hurt, maxf(hurt * 0.7, tuning.aim_squint if aiming else 0.0), hurt], delta)
	gaze.step(delta)


func _express(goal: Array, delta: float) -> void:
	var k := 1.0 - exp(-delta / maxf(tuning.ease_time, 0.001))
	for i in _w.size():
		_w[i] = lerpf(_w[i], goal[i], k)
	for f in _faces.size():
		var ids: Array = _index[f]
		for i in ids.size():
			if ids[i] >= 0:
				_faces[f].set_blend_shape_value(ids[i], clampf(_w[i], 0.0, 1.0))


## The expressions' weights now (brows_up, brows_down, squint, scowl), for tests and the lab.
func expression() -> Dictionary:
	var out := {}
	for i in EXPRESSIONS.size():
		out[EXPRESSIONS[i]] = _w[i]
	return out


## His eyes on `point` this tick, for whatever he's doing (WipeBar: the cloth under his hand). Call
## it every tick he's to keep watching it; stop, and his eyes are his own again. `over_all`: even in
## a fight and just started (OutlawBrain's wince: his eyes on his wound).
func attend_to(point: Vector3, over_all := false) -> void:
	_attend = point
	_attend_frame = Engine.get_physics_frames()
	_attend_over = over_all


func attending() -> bool:
	return Engine.get_physics_frames() - _attend_frame <= 2


## Whom he's looking at (null: a point, `looking_at_point()`).
func looking_at() -> Node3D:
	return _who


func looking_at_point() -> Vector3:
	return _who.global_position if _who != null and is_instance_valid(_who) else _point


func _near() -> bool:
	var cam := camera
	if cam == null and is_inside_tree():
		cam = get_viewport().get_camera_3d()
	return cam == null or cam.global_position.distance_to(body.global_position) <= tuning.near_camera


func _hook_senses() -> void:
	if _brain == null:
		_brain = body.get_node_or_null(^"Brain")
	if _senses == null and _brain != null and _brain.get("senses") is Senses:
		_senses = _brain.get("senses")
		_senses.heard.connect(_on_heard)


func _pick(fear: float) -> void:
	# Fighting: on his man (the brain's target), whatever else.
	var foe: Variant = _brain.get("target") if _brain != null and "target" in _brain else null
	if is_instance_valid(foe) and foe is Node3D and _fighting():
		_who = _face_of(foe)
		_hold = 0.5
		return
	if _startled > 0.0 or _hold > 0.0:
		return
	for d: Dictionary in [_looked, _first]:
		for w: Variant in d.keys():
			if not is_instance_valid(w):
				d.erase(w)
	var best: Node3D = null
	var best_score := -INF
	if _senses != null:
		for who: Variant in _senses.known.keys():
			if not is_instance_valid(who) or not (who is Node3D) or who == body or not _senses.sees(who):
				continue
			var n := who as Node3D
			if n is HumanBody and not (n as HumanBody).physiology.alive:
				continue
			if not _first.has(n):
				_first[n] = _clock
			var d := n.global_position.distance_to(body.global_position)
			if d > tuning.interest_range:
				continue
			var score := (tuning.interest_range - d) / tuning.interest_range * 2.0
			if n.is_in_group(&"player"):
				score += tuning.player_bonus
			if _clock - float(_first[n]) < 2.0:
				score += tuning.new_bonus
			if _moving(n):
				score += tuning.moving_bonus
			score -= tuning.bored_per_second * float(_looked.get(n, 0.0))
			score += _rng.randf() * 0.5
			if score > best_score:
				best_score = score
				best = n
	var hold := _rng.randf_range(tuning.hold.x, tuning.hold.y) * lerpf(1.0, tuning.fear_hold, fear)
	# Nobody worth it now (he's looked his fill), or a glance off at nothing as a hold ends.
	var glancing := best != null and (best_score < tuning.nothing_score + _rng.randf() * 0.5
			or (_who != null and _rng.randf() < tuning.glance_away))
	if best == null or glancing:
		_who = null
		var spread := 1.0 + fear
		_point = _ahead(Vector2(_rng.randf_range(-1, 1) * tuning.wander_yaw * spread,
				_rng.randf_range(-1, 1) * tuning.wander_pitch))
		_hold = _rng.randf_range(tuning.glance.x, tuning.glance.y) if glancing \
				else _rng.randf_range(tuning.wander_every.x, tuning.wander_every.y) * lerpf(1.0, tuning.fear_hold, fear)
		return
	_who = _face_of(best)
	_hold = hold


func _fighting() -> bool:
	if _brain is OutlawBrain:
		var m: int = (_brain as OutlawBrain).mood
		return m == OutlawBrain.Mood.FIGHTING or m == OutlawBrain.Mood.RELOADING
	return false


func _moving(n: Node3D) -> bool:
	if n is CharacterBody3D:
		return (n as CharacterBody3D).velocity.length() > 0.5
	if n is HumanBody:
		return (n as HumanBody).pose == &"walk" or (n as HumanBody).pose == &"run"
	return false


## What to look at on someone: his head (a man's head part; the player's camera, his eyes).
func _face_of(n: Node3D) -> Node3D:
	if n is HumanBody and (n as HumanBody).parts.has(&"head"):
		return (n as HumanBody).parts[&"head"]
	if n is Player:
		return (n as Player).camera
	return n


## A point 5 m out from his eyes, `deg` (left +, up +) off where his body faces.
func _ahead(deg: Vector2) -> Vector3:
	if body == null:
		return Vector3.ZERO
	var y := deg_to_rad(deg.x)
	var x := deg_to_rad(deg.y)
	var d := Vector3(-sin(y) * cos(x), sin(x), -cos(y) * cos(x))
	var eye := body.global_position + Vector3.UP * 1.62
	if body.parts.has(&"head"):
		eye = (body.parts[&"head"] as Node3D).global_position
	return eye + body.global_transform.basis * d * 5.0


func _start(at: Vector3, who: Node) -> void:
	_startle = 1.0
	gaze.blink()
	if is_instance_valid(who) and who is Node3D and who != body:
		_who = _face_of(who)
	else:
		_who = null
		_point = at + Vector3.UP * 1.2
	_startled = _rng.randf_range(tuning.startle_look.x, tuning.startle_look.y)
	_hold = _startled


func _awake() -> bool:
	return enabled and body != null and is_instance_valid(body) and body.physiology.is_conscious()


func _on_heard(at: Vector3, kind: StringName, who: Node) -> void:
	if not _awake() or (_brain != null and _fighting()):
		return
	if kind in STARTLING and at.distance_to(body.global_position) <= tuning.startle_range:
		_start(at, who)
	elif _hold <= 0.0 and _startled <= 0.0:
		# A quieter sound: a look that way, no start.
		if is_instance_valid(who) and who is Node3D and who != body:
			_who = _face_of(who)
		else:
			_who = null
			_point = at + Vector3.UP * 1.0
		_hold = _rng.randf_range(tuning.glance.x, tuning.glance.y)


func _on_exploded(at: Vector3, _kg: float) -> void:
	if _awake() and at.distance_to(body.global_position) <= tuning.startle_range * 2.0:
		_start(at, null)


func _on_near_miss(person: Node, shooter: Node, _distance: float, at: Vector3, _speed: float, _tumbling: bool) -> void:
	if person == body and _awake():
		_start(at, shooter)
