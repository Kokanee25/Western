class_name Ballistics
extends Node
## Flies bullets through the world on the physics tick: real travel time and drop, and
## penetration by material and thickness. Through thin boards they go on (slower) and leave a hole
## you can see through; in thick timber they stop. Loose objects get knocked about.
## Everything that happens is announced on Events.bullet_hit.

class Bullet:
	extends RefCounted
	var position: Vector3
	var velocity: Vector3
	var mass: float
	var diameter: float
	var age := 0.0
	var alive := true
	var exclude: Array[RID] = []
	var path := PackedVector3Array()
	var hits: Array[Dictionary] = []

	func energy() -> float:
		return 0.5 * mass * velocity.length_squared()


@export var tuning: BallisticsTuning

var bullets: Array[Bullet] = []
## Every path flown, for the F8 debug traces.
signal bullet_finished(bullet: Bullet)


func _ready() -> void:
	add_to_group(&"ballistics")
	if tuning == null:
		tuning = load("res://config/ballistics.tres")


func fire(origin: Vector3, direction: Vector3, speed: float, mass: float, diameter: float, exclude: Array[RID] = []) -> Bullet:
	var b := Bullet.new()
	b.position = origin
	b.velocity = direction.normalized() * speed
	b.mass = mass
	b.diameter = diameter
	b.exclude = exclude
	b.path.append(origin)
	bullets.append(b)
	return b


func _physics_process(delta: float) -> void:
	for b in bullets:
		step(b, delta)
	var done := bullets.filter(func(b: Bullet) -> bool: return not b.alive)
	for b in done:
		bullets.erase(b)
		bullet_finished.emit(b)


func step(b: Bullet, delta: float) -> void:
	if not b.alive:
		return
	b.age += delta
	var space := get_viewport().find_world_3d().direct_space_state if get_viewport() else null
	if space == null:
		return
	var remaining := b.velocity.length() * delta
	var guard := 0
	while remaining > 0.0001 and b.alive and guard < 12:
		guard += 1
		var dir := b.velocity.normalized()
		var to := b.position + dir * remaining
		var q := PhysicsRayQueryParameters3D.create(b.position, to)
		q.exclude = b.exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			b.position = to
			remaining = 0.0
			break
		var travelled := b.position.distance_to(hit.position)
		remaining -= travelled
		b.position = hit.position
		b.path.append(hit.position)
		remaining = _impact(b, hit, remaining)
	b.velocity.y -= tuning.gravity * delta
	if b.alive:
		b.path.append(b.position)
	if b.age > tuning.max_age or b.velocity.length() < tuning.min_speed or b.position.y < -50.0:
		b.alive = false


## Handle one impact. Returns the distance left to fly this tick.
func _impact(b: Bullet, hit: Dictionary, remaining: float) -> float:
	var dir := b.velocity.normalized()
	var collider: Object = hit.collider
	var e_before := b.energy()
	var info := {"position": hit.position, "normal": hit.normal, "direction": dir, "collider": collider,
			"member_id": &"", "penetrated": false, "energy_before": e_before, "energy_after": 0.0}
	if collider is StructureMember:
		var member := collider as StructureMember
		info.member_id = member.member_id
		if member.kind == &"glass":
			var glass_cost := member.exit_distance(hit.position, dir) * 100.0 * float(tuning.resistance_by_wood.get(&"glass", 8.0))
			member.shatter(hit.position, dir)
			_set_energy(b, maxf(e_before - glass_cost, 0.0))
			b.exclude.append(member.get_rid())
			info.penetrated = true
			info.energy_after = b.energy()
			b.hits.append(info)
			Events.bullet_hit.emit(info)
			return remaining
		var thickness := member.exit_distance(hit.position, dir)
		var resistance: float = tuning.resistance_by_wood.get(member.wood, tuning.default_resistance)
		var cost := thickness * 100.0 * resistance
		var radius := b.diameter * 0.5
		if e_before > cost + 1.0:
			var exit_point: Vector3 = hit.position + dir * thickness
			member.add_hole(hit.position, exit_point, radius)
			_set_energy(b, e_before - cost)
			b.position = exit_point + dir * 0.002
			b.path.append(b.position)
			info.penetrated = true
			info.energy_after = b.energy()
			b.hits.append(info)
			Events.bullet_hit.emit(info)
			return maxf(remaining - thickness, 0.0)
		member.add_hole(hit.position, null, radius)
		b.alive = false
	elif collider is RigidBody3D:
		var body := collider as RigidBody3D
		body.apply_impulse(dir * b.mass * b.velocity.length() * tuning.impulse_transfer, hit.position - body.global_position)
		var thin: float = body.get_meta(&"ballistic_thickness", -1.0)
		if thin >= 0.0:
			_set_energy(b, maxf(e_before - thin * 100.0 * tuning.default_resistance, 0.0))
			b.exclude.append(body.get_rid())
			info.penetrated = b.energy() > 1.0
			info.energy_after = b.energy()
			b.alive = info.penetrated
		else:
			b.alive = false
	else:
		b.alive = false
	b.hits.append(info)
	Events.bullet_hit.emit(info)
	return remaining if b.alive else 0.0


func _set_energy(b: Bullet, joules: float) -> void:
	var speed := sqrt(maxf(2.0 * joules / b.mass, 0.0))
	b.velocity = b.velocity.normalized() * speed
