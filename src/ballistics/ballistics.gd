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
	var shooter: Node
	## People it has already cracked past (near misses are announced once each). The pellets of
	## one shotgun charge share this, so a charge cracks past a man once, not nine times.
	var passed := {}
	## Muzzle blast (and a shotgun's wad) this projectile carries into the first thing it touches,
	## joules at contact, gone by `blast_reach` metres. A revolver's is 300 J.
	var blast := 300.0
	var blast_reach := 1.5
	## Its share of a shotgun charge (1 for a single ball).
	var pellets := 1
	## What it is, when it isn't a ball or a pellet (&"splinter" off a blast); the wound says so.
	var kind := &""

	## The blast still with it after flying `travelled` metres: all of it right at the muzzle,
	## then fading out.
	func blast_at(travelled: float) -> float:
		if travelled < 0.3:
			return blast
		return blast * 0.48 * maxf(blast_reach - travelled, 0.0) / maxf(blast_reach - 0.3, 0.01)

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


## A shotgun charge: `count` pellets leaving together along `direction`, each thrown off the line
## by a normal spread of `pattern` radians (one standard deviation, capped at 2.5), each flown as
## its own projectile. The muzzle blast is split between them. Returns the pellets.
func fire_charge(origin: Vector3, direction: Vector3, count: int, pattern: float, speed: float, mass: float,
		diameter: float, exclude: Array[RID], rng: RandomNumberGenerator, blast := 0.0, blast_reach := 1.5) -> Array[Bullet]:
	var d := direction.normalized()
	var side := d.cross(Vector3.UP if absf(d.y) < 0.99 else Vector3.RIGHT).normalized()
	var up := side.cross(d).normalized()
	var passed := {}
	var out: Array[Bullet] = []
	for i in count:
		var off := Vector2(rng.randfn(0.0, 1.0), rng.randfn(0.0, 1.0))
		if off.length() > 2.5:
			off = off.normalized() * 2.5
		var dir := (d + (side * off.x + up * off.y) * tan(pattern)).normalized()
		var b := fire(origin, dir, speed * rng.randf_range(0.97, 1.03), mass, diameter, exclude.duplicate())
		b.passed = passed
		b.blast = blast / maxf(count, 1)
		b.blast_reach = blast_reach
		b.pellets = count
		out.append(b)
	return out


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
	var start := b.position
	var guard := 0
	while remaining > 0.0001 and b.alive and guard < 12:
		guard += 1
		var dir := b.velocity.normalized()
		var to := b.position + dir * remaining
		var q := PhysicsRayQueryParameters3D.create(b.position, to, Layers.BULLETS)
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
		# The blast spends itself on the first thing it meets.
		b.blast = 0.0
	b.velocity.y -= tuning.gravity * delta
	# Air drag: speed falls off exponentially with distance, faster for light, fat projectiles.
	if b.alive and b.mass > 0.0:
		var area := PI * b.diameter * b.diameter * 0.25
		var k := 0.5 * tuning.air_density * tuning.drag_coefficient * area / b.mass
		b.velocity *= exp(-k * b.velocity.length() * delta)
	_near_misses(b, start, b.position)
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
	if collider != null and collider.has_meta(&"human_body"):
		var person: Node = collider.get_meta(&"human_body")  # HumanBody, or the player's PlayerWounds
		var travelled: float = b.path[0].distance_to(hit.position) if not b.path.is_empty() else 99.0
		var res: Dictionary = person.call(&"take_bullet", collider as Node3D, hit.position, dir, e_before, b.diameter * 0.5, b.mass, travelled, b.blast_at(travelled), b.kind)
		b.blast = 0.0
		b.exclude.append((collider as CollisionObject3D).get_rid())
		if res.segment == &"":
			return remaining  # through the space round him without touching him
		info.person = person
		info.segment = res.segment
		info.shooter = b.shooter
		var victim: Node = person.get(&"player") if person is PlayerWounds else person
		if b.shooter and victim:
			victim.set_meta(&"last_hit_by", b.shooter)
			Events.deed.emit(b.shooter, &"hit", victim, hit.position)
		if res.exit != null:
			var exit_point: Vector3 = res.exit
			var through: float = (hit.position as Vector3).distance_to(exit_point)
			_set_energy(b, res.energy_out)
			b.position = exit_point + dir * 0.002
			b.path.append(b.position)
			info.penetrated = true
			info.energy_after = b.energy()
			b.hits.append(info)
			Events.bullet_hit.emit(info)
			return maxf(remaining - through, 0.0)
		b.alive = false
	elif collider is StructureMember:
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
	elif collider is DynamiteStick:
		var stick := collider as DynamiteStick
		b.exclude.append(stick.get_rid())
		_set_energy(b, maxf(e_before - 20.0, 0.0))
		info.penetrated = true
		info.energy_after = b.energy()
		b.hits.append(info)
		Events.bullet_hit.emit(info)
		stick.shot(dir * b.mass * sqrt(2.0 * e_before / maxf(b.mass, 1e-4)))
		return remaining
	elif collider != null and collider.has_meta(&"oil_lamp"):
		(collider.get_meta(&"oil_lamp") as OilLamp).smash(dir)
		b.exclude.append((collider as CollisionObject3D).get_rid())
		_set_energy(b, maxf(e_before - 15.0, 0.0))
		info.penetrated = true
		info.energy_after = b.energy()
		b.hits.append(info)
		Events.bullet_hit.emit(info)
		return remaining
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


## Announce a bullet cracking past someone's head (within `tuning.near_miss_distance`).
func _near_misses(b: Bullet, from: Vector3, to: Vector3) -> void:
	var people := get_tree().get_nodes_in_group(&"people") + get_tree().get_nodes_in_group(&"player")
	for p: Node in people:
		if p == b.shooter or b.passed.has(p) or not p is Node3D:
			continue
		var head := (p as Node3D).global_position + Vector3.UP * 1.5
		var closest := Geometry3D.get_closest_point_to_segment(head, from, to)
		var d := closest.distance_to(head)
		if d < tuning.near_miss_distance:
			b.passed[p] = true
			Events.near_miss.emit(p, b.shooter, d)


func _set_energy(b: Bullet, joules: float) -> void:
	var speed := sqrt(maxf(2.0 * joules / b.mass, 0.0))
	b.velocity = b.velocity.normalized() * speed
