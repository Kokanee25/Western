class_name Blast
## A charge going off: a shock wave whose pressure and impulse fall with scaled distance
## (Z = R / kg^(1/3), Kinney-Graham fits for a free-air TNT burst), and everything round it
## answering by its own rules:
## - timber breaks when the kick it's given (impulse² / 2m) passes what it can soak up bending,
##   and the pieces fly; splinters off it are flown as projectiles;
## - panes crack from a few kPa, much further out;
## - dry wood in the fireball may catch;
## - loose things are pushed; other sticks close by go off with it;
## - people take it through `take_blast(at, kg)` (ears, lungs, head, thrown down, torn open, limbs).
## Tuning in config/blast.tres (BlastTuning).

const P_ATM := 101.325  # kPa

static var tuning: BlastTuning
static var _rng := RandomNumberGenerator.new()


static func t() -> BlastTuning:
	if tuning == null:
		tuning = load("res://config/blast.tres")
	return tuning


## Peak side-on overpressure (kPa) `r` metres from `kg` of TNT.
static func overpressure_kpa(kg: float, r: float) -> float:
	var z := maxf(r, 0.02) / pow(maxf(kg, 1e-4), 1.0 / 3.0)
	var num := 808.0 * (1.0 + pow(z / 4.5, 2.0))
	var den := sqrt((1.0 + pow(z / 0.048, 2.0)) * (1.0 + pow(z / 0.32, 2.0)) * (1.0 + pow(z / 1.35, 2.0)))
	return P_ATM * num / den


## Positive-phase impulse per area (Pa·s) `r` metres from `kg` of TNT.
static func impulse(kg: float, r: float) -> float:
	var w3 := pow(maxf(kg, 1e-4), 1.0 / 3.0)
	var z := maxf(r, 0.02) / w3
	var scaled := 0.067 * sqrt(1.0 + pow(z / 0.23, 4.0)) / (z * z * pow(1.0 + pow(z / 1.55, 3.0), 1.0 / 3.0))
	return scaled * w3 * 100.0  # bar·ms -> Pa·s


static func reach(kg: float) -> float:
	return t().reach_per_cbrt_kg * pow(kg, 1.0 / 3.0)


static func fireball_radius(kg: float) -> float:
	return t().fireball_per_cbrt_kg * pow(kg, 1.0 / 3.0)


## How much of the blast gets from `from` to `to`: a standing wall between takes most of it.
static func shielding(world: Node3D, from: Vector3, to: Vector3, exclude: Array[RID] = []) -> float:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	q.exclude = exclude
	var hit := world.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return 1.0
	var c: Object = hit.collider
	if c is StructureMember and not (c as StructureMember).broken and (c as StructureMember).kind != &"glass":
		return 0.35
	return 1.0 if not c is StaticBody3D else 0.35


## Set it off. Returns what happened: {broken: [member ids], people: [nodes], splinters: n}.
static func detonate(world: Node3D, at: Vector3, kg: float, held_by: Node = null) -> Dictionary:
	var tn := t()
	# Seeded by where it went off (to the millimetre): the same blast throws the same way.
	_rng.seed = hash(Vector3i((at * 1000.0).round()))
	var report := {"broken": [], "people": [], "splinters": 0}
	var r_max := reach(kg)
	var space := world.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = r_max
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY, at)
	q.collision_mask = Layers.WORLD | Layers.DEBRIS | Layers.BODY_PARTS
	var found := space.intersect_shape(q, 1024)
	var by_structure := {}  # Structure -> [[member, push]]
	var pushes := []  # [RigidBody3D, impulse vector]
	var sticks: Array[DynamiteStick] = []
	var fire := FireSystem.find(world.get_tree())
	var fireball := fireball_radius(kg)
	for f: Dictionary in found:
		var c: Object = f.collider
		if c is StructureMember:
			var m := c as StructureMember
			if m.broken or m.consumed:
				continue
			var s := m.get_parent() as Structure
			var hitres := _member_response(m, at, kg, s)
			if hitres.break:
				by_structure.get_or_add(s, []).append([m, hitres.push])
			elif fire and fire.flammable(m) and hitres.distance < fireball and _rng.randf() < tn.ignite_chance:
				fire.ignite(m)
		elif c is DynamiteStick:
			sticks.append(c as DynamiteStick)
		elif c is RigidBody3D:
			var rb := c as RigidBody3D
			var r := maxf(rb.global_position.distance_to(at), 0.05)
			var area := pow(maxf(rb.mass / 500.0, 1e-5), 2.0 / 3.0)
			var dir := (rb.global_position - at).normalized()
			pushes.append([rb, (dir + Vector3.UP * 0.3).normalized() * impulse(kg, r) * area])
	# Break what breaks, one settle per building.
	var splinters := 0
	var ballistics := world.get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var passed := {}
	for s: Structure in by_structure:
		var list: Array[StructureMember] = []
		var ps: Array[Vector3] = []
		for pair: Array in by_structure[s]:
			list.append(pair[0])
			ps.append(pair[1])
		# Splinters fly off the boards it breaks (before they're rubble).
		for i in list.size():
			var m := list[i]
			if m.kind == &"glass" or ballistics == null or splinters >= tn.max_splinters:
				continue
			var from := _nearest_on(m, at)
			var speed := minf(ps[i].length() * tn.splinter_speed_factor, 220.0)
			if speed < 20.0:
				continue
			for k in tn.splinters_per_member:
				var dir := (from - at).normalized()
				dir = (dir + Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.2, 0.4), _rng.randf_range(-0.4, 0.4))).normalized()
				var b := ballistics.fire(from + dir * 0.05, dir, speed * _rng.randf_range(0.5, 1.0), tn.splinter_mass, tn.splinter_diameter)
				b.kind = &"splinter"
				b.blast = 0.0
				b.passed = passed
				splinters += 1
		report.broken.append_array(s.break_members(list, ps))
		if fire:
			for m in list:
				if fire.flammable(m) and m.global_position.distance_to(at) < fireball and _rng.randf() < tn.ignite_chance:
					fire.ignite(m)
	# Gravel and grit off the ground, if it went off on (or near) it.
	if ballistics:
		var down := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.05, at + Vector3.DOWN * 0.4, Layers.WORLD)
		if not space.intersect_ray(down).is_empty():
			var ground_at := at + Vector3.UP * 0.05
			for k in tn.ejecta_count:
				var az := _rng.randf() * TAU
				var el := deg_to_rad(_rng.randf_range(2.0, tn.ejecta_elevation))
				var dir := Vector3(cos(az) * cos(el), sin(el), sin(az) * cos(el))
				var b := ballistics.fire(ground_at + dir * 0.1, dir, _rng.randf_range(tn.ejecta_speed.x, tn.ejecta_speed.y), tn.ejecta_mass, tn.ejecta_diameter)
				b.kind = &"gravel"
				b.blast = 0.0
				b.passed = passed
				splinters += 1
	report.splinters = splinters
	for pair: Array in pushes:
		var rb: RigidBody3D = pair[0]
		if is_instance_valid(rb):
			var v: Vector3 = pair[1] / maxf(rb.mass, 0.01)
			if v.length() > tn.max_throw:
				v = v.normalized() * tn.max_throw
			rb.sleeping = false
			rb.linear_velocity += v
	# People.
	for p: Node in world.get_tree().get_nodes_in_group(&"people") + world.get_tree().get_nodes_in_group(&"player"):
		if not p is Node3D or (p as Node3D).global_position.distance_to(at) > r_max + 1.0:
			continue
		var target: Node = p
		if p is Player:
			target = (p as Player).wounds
		if target and target.has_method(&"take_blast"):
			target.call(&"take_blast", at, kg, p == held_by)
			report.people.append(p)
	# Other sticks close by.
	for st in sticks:
		if is_instance_valid(st) and overpressure_kpa(kg, st.global_position.distance_to(at)) > tn.sympathetic_kpa:
			st.detonate.call_deferred()
	BlastEffects.spawn(world, at, kg)
	Events.exploded.emit(at, kg)
	return report


## How a member answers: {break, push, distance}. Glass by pressure; timber by the energy the
## blast puts into it against what it can absorb bending.
static func _member_response(m: StructureMember, at: Vector3, kg: float, s: Structure) -> Dictionary:
	var tn := t()
	var near := _nearest_on(m, at)
	var dist := maxf(near.distance_to(at), 0.03)
	var dir := (m.global_position - at).normalized()
	if m.kind == &"glass":
		var kpa := overpressure_kpa(kg, dist) * tn.reflection
		return {"break": kpa > tn.glass_kpa, "push": dir * minf(kpa * 0.2, 15.0), "distance": dist}
	var length := m.length()
	var cs := m.cross_section()
	var total := face_impulse(m, at, kg) * tn.reflection
	var timber: TimberTuning = s.tuning if s and s.tuning else load("res://config/timber.tres")
	var mass := maxf(m.weight(timber) / 9.81, 0.05)
	var kick := total * total / (2.0 * mass)
	var wood: Dictionary = timber.woods.get(m.wood, timber.default_wood)
	var fb: float = wood.bending
	var e: float = wood.stiffness
	var sound := cs.x * cs.y * length
	var capacity := fb * fb / (2.0 * e) * sound * tn.absorb_factor
	# Close in, it breaks where it's hit before the whole length feels it: the same test over the
	# hand-span of it nearest the charge.
	var span := minf(tn.local_span, length)
	var near_j := face_impulse(m, at, kg, span) * tn.reflection
	var share := span / maxf(length, 1e-4)
	var near_kick := near_j * near_j / (2.0 * mass * share)
	var broke := kick > capacity or near_kick > capacity * share
	var speed := minf(maxf(total / mass, near_j / (mass * share) * 0.5), tn.max_throw)
	if broke:
		m.set_meta(&"blast_t", clampf((at - m.global_position).dot(m.axis()), -length * 0.5, length * 0.5))
	return {"break": broke, "push": (dir + Vector3.UP * 0.25).normalized() * speed, "distance": dist}


## The blast's push on a member (N·s): impulse per area summed over the face turned to it. The
## samples bunch up round the point nearest the charge, where nearly all of it lands (a stick lying
## on a floorboard hits the bit under it far harder than the rest of the board).
static func face_impulse(m: StructureMember, at: Vector3, kg: float, window := INF) -> float:
	var length := m.length()
	var cs := m.cross_section()
	var width := maxf(cs.x, cs.y)
	var axis := m.axis()
	var half := length * 0.5
	var t0 := clampf((at - m.global_position).dot(axis), -half, half)
	# How far the charge is off the face at its nearest.
	var perp := _nearest_on(m, at).distance_to(at)
	var offsets := [0.0]
	for d in [0.03, 0.08, 0.15, 0.3, 0.6, 1.2, 2.4, 4.8]:
		offsets.append(d)
		offsets.append(-d)
	var ts: Array[float] = []
	for o: float in offsets:
		var t := clampf(t0 + o, -half, half)
		if not ts.has(t):
			ts.append(t)
	ts.sort()
	var total := 0.0
	for i in ts.size():
		var lo := -half if i == 0 else (ts[i - 1] + ts[i]) * 0.5
		var hi := half if i == ts.size() - 1 else (ts[i] + ts[i + 1]) * 0.5
		if window < INF:
			lo = maxf(lo, t0 - window * 0.5)
			hi = minf(hi, t0 + window * 0.5)
		var seg := hi - lo
		if seg <= 0.0:
			continue
		var along := ts[i] - t0
		var r := maxf(sqrt(perp * perp + along * along), 0.02)
		# Across the width, the part near the charge takes more: average over the strip.
		var mean := 0.0
		for k in 3:
			var off := width * (k - 1) / 3.0
			mean += impulse(kg, sqrt(r * r + off * off))
		total += mean / 3.0 * seg * width
	return total


## The point of a member nearest `at`.
static func _nearest_on(m: StructureMember, at: Vector3) -> Vector3:
	var local := m.global_transform.affine_inverse() * at
	var half := m.size * 0.5
	var c := Vector3(clampf(local.x, -half.x, half.x), clampf(local.y, -half.y, half.y), clampf(local.z, -half.z, half.z))
	return m.global_transform * c
