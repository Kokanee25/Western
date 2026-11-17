class_name WallClock
extends Node3D
## A wall or shelf clock's going parts (#789, #1030): the clock is how the player tells the time (there's
## no clock on screen), so its hands show the town's own time, DayCycle's (local time by the sun: no
## standard time zones till November 1883). Made by KitProp for a kit file with "clock" (the
## regulator `wall_clock`, the first; the bank's, depot's, store's and the homes' shelf clocks are the
## same part with their own model and numbers).
##
## - **The hands** (its model's "Hour", "Minute" (with its "Collet") and "Seconds" parts, each made
##   pointing at XII) turn about the dial's middle, read from DayCycle each frame it's drawn. The
##   seconds bit steps with the pendulum's beat (real seconds: the pendulum is a thing in the room).
## - **The pendulum** (every "Pendulum*" part) swings `swing` degrees each way about its `pivot`, a
##   beat each half `period` (2 pi sqrt(L/g) from its length), drawn by sums, no body.
## - **The tick:** each beat a quiet placed sound (GameAudio: delay, the room, walls between), only
##   with the ears within `tick.hear_within`; GameAudio's voice limit gives it way to anything
##   louder, so it's heard in a quiet room and lost under a busy night.
## - **It stops** (and keeps that time: a clue, #789) when a ball goes through its works (`works`, a
##   box in the prop's space), when the member its works are on breaks, or when it falls off the wall.
##
## Cheap: the hands and pendulum move only while it's on screen within `near` metres; the tick is
## worked out only within earshot; a stopped clock does nothing.

signal stopped(hour: float)

var spec: Dictionary
var is_stopped := false
## The hour it stopped at (DayCycle's time then), or -1.
var stopped_hour := -1.0
## Real seconds the pendulum has swung (its phase; a beat each half period).
var swing_time := 0.0

var _prop: Node3D
var _clock: DayCycle
var _hour: Node3D
var _minute: Node3D
var _seconds: Node3D
var _pendulum: Node3D
var _notifier: VisibleOnScreenNotifier3D
var _beat := 0
var _period := 1.4
var _shown_hour := -100.0


func _ready() -> void:
	_prop = get_parent() as Node3D
	var def: Dictionary = _prop.get(&"definition") if _prop else {}
	spec = def.get("clock", {})
	_period = maxf(0.2, float(spec.get("period", 1.4)))
	# Each clock its own phase (two side by side don't tick together).
	swing_time = float(posmod(hash(String(_prop.name) if _prop else "c"), 1000)) / 1000.0 * _period
	_build()
	if _prop and _prop.has_signal(&"went_loose"):
		_prop.connect(&"went_loose", _on_loose)
	Events.bullet_hit.connect(_on_bullet_hit)
	Events.member_broken.connect(_on_member_broken)
	_clock = get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	show_time(current_hour())


func _build() -> void:
	var model := String(spec.get("model", ""))
	var mat := PropKit.material(String(spec.get("look", "pbr:" + model)), 0)
	var centre := PropKit.vec(spec.get("centre", [0, 0, 0]))
	var sec_centre := PropKit.vec(spec.get("seconds_centre", spec.get("centre", [0, 0, 0])))
	var pivot := PropKit.vec(spec.get("pivot", [0, 0, 0]))
	_hour = _pivot("Hour", centre, model, ["Hour"], mat)
	_minute = _pivot("Minute", centre, model, ["Minute", "Collet"], mat)
	_seconds = _pivot("Seconds", sec_centre, model, ["Seconds"], mat)
	_pendulum = _pivot("Pendulum", pivot, model, ["PendulumRod", "PendulumSpring", "PendulumBob", "PendulumNut"], mat)
	# Seen: the case's box (a little over).
	_notifier = VisibleOnScreenNotifier3D.new()
	_notifier.aabb = AABB(Vector3(-0.3, 0.0, -0.05), Vector3(0.6, 1.1, 0.25))
	add_child(_notifier)


## A pivot at `at` (the prop's space) carrying the model's `parts`, laid so they turn about it.
func _pivot(node_name: String, at: Vector3, model: String, parts: Array, mat: Material) -> Node3D:
	var p := Node3D.new()
	p.name = node_name
	p.position = at
	add_child(p)
	for part: String in parts:
		var mesh := PropKit.model_part(model, part)
		if mesh == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = part
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = -at
		# Hands a few mm over a dial: their shadow is the dial's own business.
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if node_name != "Pendulum" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		p.add_child(mi)
	return p


## The town's time now (hours since midnight), or the time it stopped at.
func current_hour() -> float:
	if is_stopped:
		return stopped_hour
	return _clock.time_of_day if _clock else 12.0


## The hands' angles for `hour`: x the hour hand's, y the minute hand's, in degrees clockwise from
## XII as you face the clock.
static func hand_angles(hour: float) -> Vector2:
	var h := fposmod(hour, 12.0)
	return Vector2(h / 12.0 * 360.0, fposmod(hour * 60.0, 60.0) / 60.0 * 360.0)


## The hands as they stand now (degrees clockwise from XII, as hand_angles).
func shown_angles() -> Vector2:
	return Vector2(-rad_to_deg(_hour.rotation.z), -rad_to_deg(_minute.rotation.z))


## Set the hands to `hour` (a turn clockwise as you face it is about the prop's -z).
func show_time(hour: float) -> void:
	var a := hand_angles(hour)
	_hour.rotation.z = -deg_to_rad(a.x)
	_minute.rotation.z = -deg_to_rad(a.y)
	_shown_hour = hour


## The pendulum's angle now (degrees, + toward the clock's right).
func pendulum_angle() -> float:
	if is_stopped:
		return 0.0
	return float(spec.get("swing", 3.0)) * sin(TAU * swing_time / _period)


## The swing and the tick on the physics tick (GameAudio's placing asks the physics where the walls are).
func _physics_process(delta: float) -> void:
	if is_stopped:
		set_physics_process(false)
		return
	swing_time += delta
	var beat := int(floor(swing_time / (_period * 0.5)))
	if beat != _beat:
		_beat = beat
		var ears := GameAudio.ears_of(self)
		_tick(ears.global_position.distance_to(global_position) if ears else 0.0)


## Drawn only on screen and near.
func _process(_delta: float) -> void:
	if is_stopped:
		set_process(false)
		return
	if not _notifier.is_on_screen():
		return
	var ears := GameAudio.ears_of(self)
	if ears and ears.global_position.distance_to(global_position) > float(spec.get("near", 14.0)):
		return
	update_now()


## Draw it as it stands now: the pendulum, the hands at the town's time, the seconds bit a beat at
## a time (done each frame it's seen; a test or the bridge may call it).
func update_now() -> void:
	_pendulum.rotation.z = deg_to_rad(pendulum_angle())
	var hour := current_hour()
	if absf(hour - _shown_hour) > 0.0002:
		show_time(hour)
	var beat_s: float = floor(swing_time / (_period * 0.5)) * _period * 0.5
	_seconds.rotation.z = -deg_to_rad(fposmod(beat_s, 60.0) * 6.0)


func _tick(d: float) -> void:
	var tick: Dictionary = spec.get("tick", {})
	if tick.is_empty() or d > float(tick.get("hear_within", 9.0)) or not GameAudio.enabled():
		return
	# Tick and tock: the escapement's two pallets aren't quite alike.
	GameAudio.play(self, &"clock_tick", _pendulum.global_position, {
		"unit_size": float(tick.get("unit_size", 0.35)), "volume_db": float(tick.get("volume_db", -6.0)),
		"max_db": -6.0, "pitch": 1.0 if _beat % 2 == 0 else 0.93, "limit": 2, "delay": false})


## Stopped: the hands keep the time it stopped at.
func stop() -> void:
	if is_stopped:
		return
	stopped_hour = current_hour()
	is_stopped = true
	show_time(stopped_hour)
	_pendulum.rotation.z = 0.0
	stopped.emit(stopped_hour)


func _on_bullet_hit(info: Dictionary) -> void:
	if is_stopped or not spec.has("works") or not info.has("position"):
		return
	var at: Vector3 = info.position
	if at.distance_squared_to(global_position) > 4.0:
		return
	var w: Dictionary = spec.works
	var box := AABB(PropKit.vec(w.at) - PropKit.vec(w.size) * 0.5, PropKit.vec(w.size)).grow(0.01)
	if box.has_point(_prop.to_local(at)):
		stop()


func _on_member_broken(id: StringName) -> void:
	if is_stopped or _prop == null:
		return
	var sid := String(_prop.get(&"structure_id"))
	for m: String in spec.get("members", []):
		if String(id) == sid + "/" + m:
			stop()
			# Its dial's gone to pieces: the hands with it.
			_hour.visible = false
			_minute.visible = false
			_seconds.visible = false
			return


## Off the wall: it stops, and its going parts fall with the piece its dial is on.
func _on_loose() -> void:
	stop()
	var dial := global_transform * PropKit.vec(spec.get("centre", [0, 0, 0]))
	var best: RigidBody3D = null
	var best_d := INF
	for rb: Variant in _prop.get(&"rubble"):
		if is_instance_valid(rb) and (rb as RigidBody3D).global_position.distance_to(dial) < best_d:
			best = rb
			best_d = (rb as RigidBody3D).global_position.distance_to(dial)
	if best == null:
		visible = false
		return
	for p: Node3D in [_hour, _minute, _seconds, _pendulum]:
		p.reparent(best, true)
