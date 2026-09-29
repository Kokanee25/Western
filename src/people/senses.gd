class_name Senses
extends Node
## What a person knows about the people round him, from what he can see and hear. Not a radar:
## eyes that look where he's facing (sharp ahead, dim at the edges, nothing behind), need a clear
## line and enough light, and pick a man out faster when he's close, moving and standing tall;
## ears that hear gunfire across town, footsteps close by and speech, muffled through walls and
## only roughly where. What he's seen stays as where and when he last saw you.
## Child of a HumanBody. Ticks a few times a second.
##
## Other systems ask: `sees(node)`, `knows(node)`, `last_known(node)`, `aware_of(node)` (0..1).

signal spotted(who: Node3D)
signal heard(at: Vector3, kind: StringName, who: Node)
signal lost(who: Node3D)

const TICK := 0.12
## Sight: range in full daylight (m), and at the darkest night.
const SIGHT_DAY := 60.0
const SIGHT_NIGHT := 14.0
## Half-angles of the view (degrees): sharp ahead, peripheral out to the side.
const FOVEA := 35.0
const PERIPHERAL := 100.0
## How fast awareness of a man in plain view builds (per second, close up, straight ahead).
const NOTICE_RATE := 3.0

## Knowledge per person: {seen (bool now), awareness 0..1, last_pos, last_time (s, game clock),
## heard_pos, heard_time}.
var known := {}
var body: HumanBody
## How much light there is to see by (0 dark .. 1 day). Set by the day cycle, or tests.
var light := -1.0

var _t := 0.0
var _clock := 0.0
var _rng := RandomNumberGenerator.new()
var _day: Node


func _ready() -> void:
	body = get_parent() as HumanBody
	_rng.seed = (body.rng_seed if body else 1) * 13 + 5
	_t = _rng.randf() * TICK  # stagger people's ticks
	Events.noise.connect(_on_noise)


func _physics_process(delta: float) -> void:
	_clock += delta
	_t -= delta
	if _t > 0.0:
		return
	var dt := TICK - _t
	_t = TICK
	if body == null or not is_instance_valid(body) or not body.physiology.is_conscious():
		for who in known:
			known[who].seen = false
		return
	_look(dt)


## The time on his own clock (seconds since he came into the world).
func now() -> float:
	return _clock


func sees(who: Node) -> bool:
	return known.has(who) and known[who].seen


func aware_of(who: Node) -> float:
	return known[who].awareness if known.has(who) else 0.0


## Does he know about this man at all (has he seen or heard him)?
func knows(who: Node) -> bool:
	return known.has(who) and (known[who].awareness >= 1.0 or known[who].heard_time > -INF)


## Where he thinks the man is: where he is if he can see him, else where he last saw or heard him.
func last_known(who: Node) -> Vector3:
	if not known.has(who):
		return Vector3.INF
	var k: Dictionary = known[who]
	if k.seen:
		return (who as Node3D).global_position
	if k.last_time >= k.heard_time:
		return k.last_pos
	return k.heard_pos


## Roughly where someone is without seeing him (a shot came from over there): noted as heard.
func note(who: Node, at: Vector3, error := 1.5) -> void:
	if who == null or who == body:
		return
	var k := _entry(who)
	k.heard_pos = at + Vector3(_rng.randf_range(-error, error), 0.0, _rng.randf_range(-error, error))
	k.heard_time = _clock


## Seconds since he last saw or heard him (INF if never).
func since_known(who: Node) -> float:
	if not known.has(who):
		return INF
	var k: Dictionary = known[who]
	if k.seen:
		return 0.0
	return _clock - maxf(k.last_time, k.heard_time)


## Seconds since he last saw him (INF if never).
func since_seen(who: Node) -> float:
	if not known.has(who) or known[who].last_time == -INF:
		return INF
	return 0.0 if known[who].seen else _clock - known[who].last_time


func _entry(who: Node) -> Dictionary:
	if not known.has(who):
		known[who] = {"seen": false, "awareness": 0.0, "last_pos": Vector3.INF, "last_time": -INF,
				"heard_pos": Vector3.INF, "heard_time": -INF}
	return known[who]


## His eye, in the world.
func eye() -> Vector3:
	var head := body.parts.get(&"head") as Node3D
	return head.global_position + Vector3.UP * 0.04 if head else body.global_position + Vector3.UP * 1.62


func facing() -> Vector3:
	var head := body.parts.get(&"head") as Node3D
	var f := -(head.global_basis.z if head else body.global_basis.z)
	return f.normalized()


func _light() -> float:
	if light >= 0.0:
		return light
	if _day == null or not is_instance_valid(_day):
		_day = get_tree().get_first_node_in_group(&"day_cycle")
	return clampf(_day.call(&"get_daylight"), 0.0, 1.0) if _day else 1.0


## Look round: for everyone who could be seen, how plainly, and awareness building or fading.
func _look(dt: float) -> void:
	var from := eye()
	var fwd := facing()
	var rng_m := lerpf(SIGHT_NIGHT, SIGHT_DAY, _light())
	var space := body.get_world_3d().direct_space_state
	for who: Node in _people():
		var k := _entry(who)
		var was := k.seen as bool
		var vis := _visibility(who as Node3D, from, fwd, rng_m, space)
		if vis > 0.0:
			k.awareness = minf(float(k.awareness) + vis * NOTICE_RATE * dt, 1.0)
		else:
			k.awareness = maxf(float(k.awareness) - dt * 0.05, 0.0)
		k.seen = vis > 0.0 and k.awareness >= 1.0
		if k.seen:
			k.last_pos = (who as Node3D).global_position
			k.last_time = _clock
			if not was:
				spotted.emit(who)
		elif was:
			lost.emit(who)


## 0 (can't see him) .. 1 (plain as day, close, ahead of him). Needs a clear line to his head or
## chest; less for being off to the side, far, in the dark, still, or down low.
func _visibility(who: Node3D, from: Vector3, fwd: Vector3, range_m: float, space: PhysicsDirectSpaceState3D) -> float:
	var targets := _points_on(who)
	var best := 0.0
	for p: Vector3 in targets:
		var to := p - from
		var d := to.length()
		if d > range_m or d < 0.01:
			continue
		var ang := rad_to_deg(fwd.angle_to(to))
		if ang > PERIPHERAL:
			continue
		if not _clear(from, p, who, space):
			continue
		var cone := 1.0 if ang <= FOVEA else lerpf(0.35, 0.05, (ang - FOVEA) / (PERIPHERAL - FOVEA))
		var dist := clampf(1.0 - d / range_m, 0.0, 1.0)
		dist = dist * dist * 0.8 + 0.2 * float(d < range_m * 0.5)
		var v := cone * dist
		best = maxf(best, v)
	if best <= 0.0:
		return 0.0
	# Movement catches the eye; a man crouched or lying still is easy to miss.
	var speed := _speed_of(who)
	best *= 0.6 + minf(speed / 3.0, 1.0) * 0.8
	if _low(who):
		best *= 0.55
	return clampf(best, 0.0, 1.5)


func _points_on(who: Node3D) -> Array[Vector3]:
	if who is Player:
		var cam := (who as Player).camera
		return [cam.global_position, who.global_position + Vector3.UP * (0.9 if (who as Player).is_crouching else 1.2)]
	if who is HumanBody:
		var h := who as HumanBody
		var out: Array[Vector3] = []
		for sid: StringName in [&"head", &"chest", &"pelvis"]:
			var part := h.parts.get(sid) as Node3D
			if part:
				out.append(part.global_position)
		return out
	return [who.global_position + Vector3.UP * 1.2]


func _clear(from: Vector3, to: Vector3, who: Node3D, space: PhysicsDirectSpaceState3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	var ex: Array[RID] = []
	if who is CollisionObject3D:
		ex.append((who as CollisionObject3D).get_rid())
	q.exclude = ex
	var hit := space.intersect_ray(q)
	return hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15


func _speed_of(who: Node3D) -> float:
	if who is CharacterBody3D:
		return Vector2((who as CharacterBody3D).velocity.x, (who as CharacterBody3D).velocity.z).length()
	if who is HumanBody:
		return (who as HumanBody).move_speed
	return 0.0


func _low(who: Node3D) -> bool:
	if who is Player:
		return (who as Player).is_crouching
	if who is HumanBody:
		var h := who as HumanBody
		return h.prone or h.limp or h.pose in [&"crouch", &"duck", &"lie", &"crouch_aim", &"tend"]
	return false


func _people() -> Array[Node]:
	var out: Array[Node] = []
	for n in get_tree().get_nodes_in_group(&"people") + get_tree().get_nodes_in_group(&"player"):
		if n != body and n is Node3D and is_instance_valid(n):
			out.append(n)
	return out


## A noise somewhere: heard if it's loud enough for the distance (less through walls), placed only
## roughly (the further, the rougher).
func _on_noise(at: Vector3, loudness: float, kind: StringName, source: Node) -> void:
	if body == null or not is_instance_valid(body) or source == body or not body.physiology.is_conscious():
		return
	var from := eye()
	var d := from.distance_to(at)
	var reach := loudness
	# Walls in between muffle it.
	var q := PhysicsRayQueryParameters3D.create(from, at, Layers.WORLD)
	var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and (hit.position as Vector3).distance_to(at) > 0.3:
		reach *= 0.5
	if body.physiology.deaf_ears() > 0:
		reach *= 1.0 - 0.35 * body.physiology.deaf_ears()
	if d > reach:
		return
	var err := d * 0.12
	var guess := at + Vector3(_rng.randf_range(-err, err), 0.0, _rng.randf_range(-err, err))
	if source is Node3D and (source is Player or source is HumanBody):
		var k := _entry(source)
		k.heard_pos = guess
		k.heard_time = _clock
	heard.emit(guess, kind, source)
