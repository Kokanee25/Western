class_name Ballistics
extends Node
## Flies bullets through the world on the physics tick: real travel time and drop, and
## penetration by material and thickness. Through thin boards they go on (slower) and leave a hole
## you can see through; in thick timber they stop. Loose objects get knocked about. Striking
## something at a shallow angle a ball can glance off (a ricochet): flatter, slower, flattened and
## tumbling, whining away, and it can still hurt someone.
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
	## It's glanced off something: flattened and tumbling (it whizzes past rather than snaps).
	var tumbling := false
	var ricochets := 0
	## Its shape for drag: 0 a round ball (buckshot, fragments), else a conical bullet's form
	## factor against the G1 standard (the .45's blunt 255-grain bullet ~1.27).
	var form := 0.0

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
var _rng := RandomNumberGenerator.new()
var _flights := {}
## Every path flown, for the F8 debug traces.
signal bullet_finished(bullet: Bullet)


func _ready() -> void:
	add_to_group(&"ballistics")
	_rng.seed = 1873
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
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"ballistics", t)


func _physics_step(delta: float) -> void:
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
		var heading := b.velocity.normalized()
		remaining = _impact(b, hit, remaining)
		# The blast spends itself on the first thing it meets.
		b.blast = 0.0
		if b.alive and b.velocity.normalized().dot(heading) < 0.9999:
			# It glanced off: its flight bends here, so near misses are judged leg by leg.
			_near_misses(b, start, hit.position)
			start = hit.position
	b.velocity.y -= tuning.gravity * delta
	# Air drag: speed falls off exponentially with distance, faster for light, fat projectiles.
	if b.alive and b.mass > 0.0:
		var v := b.velocity.length()
		b.velocity *= exp(-_drag_k(b.diameter, b.mass, b.form, v) * v * delta)
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
	elif collider != null and collider.has_meta(&"hat_of"):
		# A worn hat: through the felt, the hat's off his head, and on it goes (into his head, if
		# it was low enough).
		var wearer: HumanBody = collider.get_meta(&"hat_of")
		b.exclude.append((collider as CollisionObject3D).get_rid())
		_set_energy(b, wearer.take_hat_shot(hit.position, dir, e_before, b.shooter, b.mass))
		info.person = wearer
		info.hat = true
		info.penetrated = true
		info.energy_after = b.energy()
		b.hits.append(info)
		Events.bullet_hit.emit(info)
		return remaining
	elif collider is StructureMember:
		var member := collider as StructureMember
		info.member_id = member.member_id
		if member.kind != &"glass" and _ricochet(b, hit, surface_of(member, hit.normal), info):
			member.add_hole(hit.position, null, b.diameter * 0.5)  # a gouge where it glanced
			return remaining * b.velocity.length() / maxf(sqrt(2.0 * e_before / maxf(b.mass, 1e-6)), 1e-3)
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
		# The solid it meets going through (the whole box, until it's been carved: then only what's
		# left, and a line through a hole already shot meets nothing). Each stretch costs its
		# thickness; what it spends there (and the muzzle blast, at contact) is carved out.
		var runs := member.solid_runs(hit.position, dir)
		var resistance: float = tuning.resistance_by_wood.get(member.wood, tuning.default_resistance)
		var radius := b.diameter * 0.5
		var travelled: float = b.path[0].distance_to(hit.position) if not b.path.is_empty() else 99.0
		var blast := b.blast_at(travelled)
		var e := e_before
		var out_at := 0.0
		if runs.is_empty():
			out_at = member.exit_distance(hit.position, dir)
			if blast > 0.0:
				# Down a hole already blown (a charge at contact: the pellets follow the first),
				# the blast still tears its edges wider.
				member.carve_hit(hit.position, hit.position + dir * out_at, true, dir, radius, 0.0, blast)
		for i in range(0, runs.size(), 2):
			var cost := (runs[i + 1] - runs[i]) * 100.0 * resistance
			var entry: Vector3 = hit.position + dir * runs[i]
			if e > cost + 1.0:
				member.carve_hit(entry, hit.position + dir * runs[i + 1], true, dir, radius, cost, blast)
				e -= cost
				out_at = runs[i + 1]
			else:
				member.carve_hit(entry, entry + dir * (e / (100.0 * resistance)), false, dir, radius, e, blast)
				b.alive = false
				break
			blast = 0.0
		if b.alive:
			_set_energy(b, e)
			b.position = hit.position + dir * (out_at + 0.002)
			b.path.append(b.position)
			info.penetrated = true
			info.energy_after = b.energy()
			b.hits.append(info)
			Events.bullet_hit.emit(info)
			return maxf(remaining - out_at, 0.0)
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
	elif _ricochet(b, hit, surface_of(collider, hit.normal), info):
		return remaining * b.velocity.length() / maxf(sqrt(2.0 * e_before / maxf(b.mass, 1e-6)), 1e-3)
	else:
		b.alive = false
	b.hits.append(info)
	Events.bullet_hit.emit(info)
	return remaining if b.alive else 0.0


## Air drag per metre of flight per unit speed, at `speed`: 0.5·ρ·Cd·A/m.
func _drag_k(diameter: float, mass: float, form: float, speed: float) -> float:
	var area := PI * diameter * diameter * 0.25
	return 0.5 * tuning.air_density() * tuning.drag_cd(speed, form) * area / maxf(mass, 1e-6)


## Where a projectile fired level will be after `distance` metres: how far it's fallen below the
## line it left on (m), how long it took (s) and how fast it's going (m/s). Flown with the same
## steps, gravity and drag as the real thing, so sights and shooters that allow for it get exactly
## the drop that happens. Remembered per load.
func flight(distance: float, speed: float, mass: float, diameter: float, form := 0.0) -> Dictionary:
	var key := "%.3f/%.1f/%.5f/%.5f/%.3f/%.0f/%.1f" % [distance, speed, mass, diameter, form, tuning.elevation_m, tuning.air_temperature_c]
	if _flights.has(key):
		return _flights[key]
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var pos := Vector2.ZERO  # x along, y up
	var vel := Vector2(speed, 0.0)
	var t := 0.0
	while pos.x < distance and t < tuning.max_age:
		var step := vel * dt
		if pos.x + step.x >= distance:
			var f := (distance - pos.x) / maxf(step.x, 1e-9)
			pos += step * f
			t += dt * f
			break
		pos += step
		t += dt
		vel.y -= tuning.gravity * dt
		var v := vel.length()
		vel *= exp(-_drag_k(diameter, mass, form, v) * v * dt)
	var out := {"drop": -pos.y, "time": t, "speed": vel.length()}
	_flights[key] = out
	return out


## The angle (radians) to raise a shot by so a ball fired at `speed` comes down onto a point
## `distance` away: how a gun's sights are regulated for one range, and how a man who knows his
## gun holds over for another.
func holdover(distance: float, speed: float, mass: float, diameter: float, form := 0.0) -> float:
	if distance < 0.5:
		return 0.0
	return atan(float(flight(distance, speed, mass, diameter, form).drop) / distance)


## What a surface is, for glancing off it: its `surface` meta (&"ground", &"stone", &"metal",
## &"wood"); a stone member is stone and any other member wood (glass: nothing); anything else
## level is the ground and upright is wood. &"" = it never glances.
static func surface_of(collider: Object, normal: Vector3) -> StringName:
	if collider == null:
		return &""
	if collider.has_meta(&"surface"):
		return collider.get_meta(&"surface")
	if collider is StructureMember:
		var m := collider as StructureMember
		return &"" if m.kind == &"glass" else (&"stone" if m.wood == &"stone" else &"wood")
	if collider is StaticBody3D:
		return &"ground" if normal.y > 0.7 else &"wood"
	return &""


## Glancing off: struck shallow enough for this surface, it skips (near the limit it's a toss-up,
## a graze nearly always). It leaves flatter than it came in and a little to one side, slower,
## flattened and tumbling. True if it did (the hit is announced, with `ricochet`).
func _ricochet(b: Bullet, hit: Dictionary, surface: StringName, info: Dictionary) -> bool:
	var limit: float = tuning.ricochet_angle.get(surface, 0.0)
	if limit <= 0.0 or b.ricochets >= tuning.max_ricochets:
		return false
	var dir := b.velocity.normalized()
	var n: Vector3 = hit.normal
	var into := -dir.dot(n)  # sine of the angle it strikes at
	if into <= 0.0:
		return false
	var angle := rad_to_deg(asin(clampf(into, 0.0, 1.0)))
	if angle >= limit:
		return false
	var t := angle / limit
	if _rng.randf() > 1.0 - t * t:
		return false
	var along := (dir + n * into).normalized()
	var out_angle := deg_to_rad(angle * tuning.ricochet_exit_share + _rng.randf_range(0.5, 2.0))
	var out := (along * cos(out_angle) + n * sin(out_angle)).normalized()
	out = out.rotated(n, deg_to_rad(_rng.randf_range(-1.0, 1.0) * tuning.ricochet_scatter))
	var speed := b.velocity.length() * lerpf(tuning.ricochet_keep_speed.x, tuning.ricochet_keep_speed.y, t)
	b.velocity = out * speed
	b.position = (hit.position as Vector3) + n * 0.003
	b.path.append(b.position)
	if not b.tumbling:
		b.diameter *= tuning.ricochet_flatten
	b.tumbling = true
	b.ricochets += 1
	b.blast = 0.0
	info.ricochet = true
	info.surface = surface
	info.energy_after = b.energy()
	b.hits.append(info)
	Events.bullet_hit.emit(info)
	return true


## Announce a bullet cracking past someone's head (within `tuning.near_miss_distance`), at its
## closest: while it's still coming nearer (the nearest point of this tick's flight is its end)
## it waits for the next tick.
func _near_misses(b: Bullet, from: Vector3, to: Vector3) -> void:
	var people := get_tree().get_nodes_in_group(&"people") + get_tree().get_nodes_in_group(&"player")
	for p: Node in people:
		if p == b.shooter or b.passed.has(p) or not p is Node3D:
			continue
		var head := (p as Node3D).global_position + Vector3.UP * 1.5
		var closest := Geometry3D.get_closest_point_to_segment(head, from, to)
		var d := closest.distance_to(head)
		if b.alive and closest.distance_squared_to(to) < 1e-8 and from.distance_squared_to(to) > 1e-8:
			continue  # still closing on him
		if d < tuning.near_miss_distance:
			b.passed[p] = true
			Events.near_miss.emit(p, b.shooter, d, closest, b.velocity.length(), b.tumbling)


func _set_energy(b: Bullet, joules: float) -> void:
	var speed := sqrt(maxf(2.0 * joules / b.mass, 0.0))
	b.velocity = b.velocity.normalized() * speed
