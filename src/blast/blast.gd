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
static var _count := 0


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
	_count += 1
	_rng.seed = hash(at) + _count
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
	var face := length * maxf(cs.x, cs.y)
	var n := 5
	var total := 0.0
	var axis := m.axis()
	for i in n:
		var p := m.global_position + axis * length * ((i + 0.5) / n - 0.5)
		total += impulse(kg, maxf(p.distance_to(at), 0.03)) * tn.reflection * face / n
	var timber: TimberTuning = s.tuning if s and s.tuning else load("res://config/timber.tres")
	var mass := maxf(m.weight(timber) / 9.81, 0.05)
	var kick := total * total / (2.0 * mass)
	var wood: Dictionary = timber.woods.get(m.wood, timber.default_wood)
	var fb: float = wood.bending
	var e: float = wood.stiffness
	var sound := cs.x * cs.y * length
	var capacity := fb * fb / (2.0 * e) * sound * tn.absorb_factor
	var speed := minf(total / mass, tn.max_throw)
	return {"break": kick > capacity, "push": (dir + Vector3.UP * 0.25).normalized() * speed, "distance": dist}


## The point of a member nearest `at`.
static func _nearest_on(m: StructureMember, at: Vector3) -> Vector3:
	var local := m.global_transform.affine_inverse() * at
	var half := m.size * 0.5
	var c := Vector3(clampf(local.x, -half.x, half.x), clampf(local.y, -half.y, half.y), clampf(local.z, -half.z, half.z))
	return m.global_transform * c
