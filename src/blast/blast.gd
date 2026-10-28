class_name Blast
## A charge going off: a shock wave whose pressure and impulse fall with scaled distance
## (Z = R / kg^(1/3), Kinney-Graham fits for a free-air TNT burst), and everything round it
## answering by its own rules:
## - timber breaks when the kick it's given (impulse² / 2m) passes what it can soak up bending,
##   and the pieces fly; splinters off it are flown as projectiles;
## - panes crack from a few kPa, much further out;
## - it lights nothing itself (Sean, 2026-10-28: `ignite_chance` 0); a lit lamp it smashes or
##   knocks down spills burning oil (GlassProp, OilLamp.smash), and that lights the floor;
## - loose things are pushed; other sticks close by go off with it;
## - people take it through `take_blast(at, kg)` (ears, lungs, head, thrown down, torn open, limbs),
##   the side of each part facing it taking the reflected pressure (`reflected_kpa`);
## - on (or near) the ground it hits as 1.8 times its TNT (`effective_kg`).
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


## How much harder a shock hits a face square to it than it passes by (the reflection
## coefficient): 2 for a weak shock, rising toward 8 for a strong one, as the gas piles up against
## the face (normal reflection of an ideal-gas shock, Rankine-Hugoniot with gamma 1.4:
## Pr/Ps = 2 + 6 Ps / (Ps + 7 P0); Glasstone & Dolan, "The Effects of Nuclear Weapons", 1977, §3.78).
## A stick by a wall hits it three or four times as hard as a flat x2 had it.
static func reflection(kpa: float) -> float:
	var strong := t().reflection_strong
	return 2.0 + (strong - 2.0) * kpa / (kpa + 7.0 * P_ATM)


## What a charge `at` hits as (kg TNT): one lying on (or just over) the ground blasts a hemisphere,
## not a sphere, the ground turning back the half that would have gone down, so it counts as about
## `ground_factor` times its TNT (2 for a perfect reflector, about 1.8 for earth, which soaks some
## up and digs a crater: the usual surface-burst allowance, as in Baker et al., "Explosion Hazards
## and Evaluation", 1983, ch. 2, and UFC 3-340-02, "Structures to Resist the Effects of Accidental
## Explosions", 2008, §2-13). Any floor counts as ground. Fading to free air by `ground_height`
## per cube root of kg up (a stick held at the chest is in free air). Sean picked this, with
## everything facing the blast taking the reflected pressure, for everything (issue #220).
static func effective_kg(world: Node3D, at: Vector3, kg: float) -> float:
	var h := _height_over_ground(World.space(world), at, kg)
	return kg * ground_share(kg, h)


## The ground's allowance (x kg) for a charge `height` m over it (INF: none under it).
static func ground_share(kg: float, height: float) -> float:
	var tn := t()
	var top := tn.ground_height * pow(maxf(kg, 1e-4), 1.0 / 3.0)
	return 1.0 + (tn.ground_factor - 1.0) * clampf(1.0 - maxf(height, 0.0) / maxf(top, 1e-4), 0.0, 1.0)


## How high `at` is over what's under it (m; INF if nothing within the ground's reach).
static func _height_over_ground(space: PhysicsDirectSpaceState3D, at: Vector3, kg: float) -> float:
	var top := t().ground_height * pow(maxf(kg, 1e-4), 1.0 / 3.0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.05, at + Vector3.DOWN * top, Layers.WORLD))
	return INF if hit.is_empty() else maxf(at.y - (hit.position as Vector3).y, 0.0)


## The pressure (kPa) a face turned to the charge takes: the side-on `side` reflected off it.
static func reflected_kpa(side: float) -> float:
	return side * reflection(side)


static func reach(kg: float) -> float:
	return t().reach_per_cbrt_kg * pow(kg, 1.0 / 3.0)


static func fireball_radius(kg: float) -> float:
	return t().fireball_per_cbrt_kg * pow(kg, 1.0 / 3.0)


## How much of the blast gets from `from` to `to`: a standing wall between takes most of it.
static func shielding(world: Node3D, from: Vector3, to: Vector3, exclude: Array[RID] = []) -> float:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	q.exclude = exclude
	var hit := World.space(world).intersect_ray(q)
	if hit.is_empty():
		return 1.0
	var c: Object = hit.collider
	if c is StructureMember and not (c as StructureMember).broken and (c as StructureMember).kind != &"glass":
		return 0.35
	return 1.0 if not c is StaticBody3D else 0.35


## Set it off. Returns what happened: {broken: [member ids], people: [nodes], splinters: n,
## kg: what it hit as, the ground counted (effective_kg)}. `charge` is its TNT; everything it acts
## on takes it as `kg`, but the crater (Kinney and Graham's fit is for charges on the ground already)
## and the look.
static func detonate(world: Node3D, at: Vector3, charge: float, held_by: Node = null) -> Dictionary:
	var tn := t()
	# Seeded by where it went off (to the millimetre): the same blast throws the same way.
	_rng.seed = hash(Vector3i((at * 1000.0).round()))
	var space := World.space(world)
	var kg := charge * ground_share(charge, _height_over_ground(space, at, charge))
	var report := {"broken": [], "people": [], "splinters": 0, "kg": kg}
	var r_max := reach(kg)
	var by_structure := {}  # Structure -> [[member, push]]
	var pushes := []  # [RigidBody3D, impulse vector]
	var sticks: Array[DynamiteStick] = []
	var fire := FireSystem.find(world.get_tree())
	var fireball := fireball_radius(kg)
	var t_gather := Prof.start()
	var found := gather(world, at, kg)
	Prof.stop(&"blast_gather", t_gather)
	var t_resp := Prof.start()
	for c: Object in found:
		if c is StructureMember:
			var m := c as StructureMember
			if m.broken or m.consumed:
				continue
			var s := m.get_parent() as Structure
			var hitres := _member_response(m, at, kg, s)
			if hitres.break and not _bedded(m):
				var cut: Variant = null
				if m.kind in CUT_KINDS:
					cut = torn_stretch(m, at, kg, s.tuning if s and s.tuning else load("res://config/timber.tres"))
				by_structure.get_or_add(s, []).append([m, hitres.push, hitres.distance, cut])
			elif fire and fire.flammable(m) and hitres.distance < fireball and _rng.randf() < tn.ignite_chance:
				fire.ignite_after(m, _rng.randf_range(tn.ignite_delay.x, tn.ignite_delay.y))
		elif c is DynamiteStick:
			sticks.append(c as DynamiteStick)
		elif c is RigidBody3D:
			var rb := c as RigidBody3D
			var r := maxf(rb.global_position.distance_to(at), 0.05)
			var area := pow(maxf(rb.mass / 500.0, 1e-5), 2.0 / 3.0)
			var dir := (rb.global_position - at).normalized()
			pushes.append([rb, (dir + Vector3.UP * 0.3).normalized() * impulse(kg, r) * area])
	Prof.stop(&"blast_response", t_resp)
	# Break what breaks, one settle per building.
	var t_break := Prof.start()
	var splinters := 0
	var ballistics := world.get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var passed := {}
	for s: Structure in by_structure:
		var list: Array[StructureMember] = []
		var ps: Array[Vector3] = []
		var near: Array[float] = []
		var cuts := []
		for pair: Array in by_structure[s]:
			list.append(pair[0])
			ps.append(pair[1])
			near.append(pair[2])
			cuts.append(pair[3])
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
		report.broken.append_array(s.break_members(list, ps, cuts))
		if fire:
			# By how near the fireball came to it, as for what it didn't break (a tall board's middle
			# can be well outside it while its foot is in it). A board it holed: the ends left.
			for i in list.size():
				var catching: Array = list[i].get_meta(&"cut_pieces", [list[i]])
				for m: StructureMember in catching:
					if is_instance_valid(m) and fire.flammable(m) and near[i] < fireball and _rng.randf() < tn.ignite_chance:
						fire.ignite_after(m, _rng.randf_range(tn.ignite_delay.x, tn.ignite_delay.y))
	Prof.stop(&"blast_break", t_break)
	# A crater, if it went off on (or just over) the dirt.
	var t_crater := Prof.start()
	var under := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.05, at + Vector3.DOWN * 0.4, Layers.WORLD))
	if not under.is_empty() and Ground.is_ground(under.collider):
		report["crater"] = crater(world, at, charge, at.y - (under.position as Vector3).y)
	Prof.stop(&"blast_crater", t_crater)
	# The clods and the gravel are thrown together, not at each other.
	var clods: Array[RID] = []
	for c: RID in report.get("crater", {}).get("clods", []):
		clods.append(c)
	# Gravel and grit off the ground, if it went off on (or near) it.
	if ballistics:
		if not under.is_empty():
			var ground_at := at + Vector3.UP * 0.05
			for k in tn.ejecta_count:
				var az := _rng.randf() * TAU
				var el := deg_to_rad(_rng.randf_range(2.0, tn.ejecta_elevation))
				var dir := Vector3(cos(az) * cos(el), sin(el), sin(az) * cos(el))
				var b := ballistics.fire(ground_at + dir * 0.1, dir, _rng.randf_range(tn.ejecta_speed.x, tn.ejecta_speed.y), tn.ejecta_mass, tn.ejecta_diameter, clods.duplicate())
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
	var t_fx := Prof.start()
	BlastEffects.spawn(world, at, charge)
	Prof.stop(&"blast_fx", t_fx)
	Events.exploded.emit(at, kg)
	return report


## A crater's diameter and depth (m) for `kg` of TNT gone off `height` m over the dirt.
static func crater_size(kg: float, height: float) -> Vector2:
	var tn := t()
	var c := pow(maxf(kg, 0.0), 1.0 / 3.0)
	var d := tn.crater_k * c * clampf(1.0 - maxf(height, 0.0) / maxf(tn.crater_height * c, 1e-4), 0.0, 1.0)
	return Vector2(d, d * tn.crater_depth_ratio)


## The dirt under a charge: the bowl taken out (Ground.take), a share packed down, the rest laid as
## the lip and thrown as clods (Clod) that lie down as loose earth where they land. Seeded by the
## blast. Its diameter, depth, and the earth (bank m³) taken and thrown.
static func crater(world: Node3D, at: Vector3, kg: float, height: float) -> Dictionary:
	var ground := Ground.of(world.get_tree())
	var size := crater_size(kg, height)
	if ground == null or size.x < ground.tuning.cell * 3.0:
		return {}
	var tn := t()
	var r := size.x * 0.5
	var floor_at := Vector3(at.x, at.y - height, at.z)
	var bank := ground.take(floor_at, r, size.y)
	var thrown := bank * (1.0 - tn.crater_packed)
	var flying := thrown * tn.clod_share if tn.clods > 0 else 0.0
	ground.put(floor_at, thrown - flying, r * tn.lip_out, r, r * tn.lip_peak)
	var thrown_rids: Array[RID] = []
	for k in (tn.clods if flying > 0.0 else 0):
		var az := _rng.randf() * TAU
		var el := deg_to_rad(_rng.randf_range(25.0, 65.0))
		var dir := Vector3(cos(az) * cos(el), sin(el), sin(az) * cos(el))
		var start := floor_at + Vector3(cos(az), 0.0, sin(az)) * r * _rng.randf_range(0.2, 0.8)
		# On the crater's wall, not in it (Jolt would throw it out of the earth).
		start.y = ground.height_at(start.x, start.z) + pow(flying / tn.clods, 1.0 / 3.0) + 0.02
		var c := Clod.throw(world, ground, start, dir * _rng.randf_range(tn.clod_speed.x, tn.clod_speed.y), flying / tn.clods, tn.earth_density)
		thrown_rids.append(c.get_rid())
	return {"diameter_m": size.x, "depth_m": size.y, "taken_m3": bank, "thrown_m3": thrown, "clods": thrown_rids}


## Everything a charge at `at` acts on, each once: every member and loose body where timber can
## break (`break_reach`, its own query, so a crowded street can't crowd out what's beside the
## charge), and out to `reach` the debris, ragdolls and sticks, every pane of glass, and the loose
## rubble and fallen fittings. (One query of everything to `reach`, capped, came back in the
## physics engine's order: on Main Street it left out every member within a metre of a stick by
## the store; the breakage lab, 2026-10-21.)
static func gather(world: Node3D, at: Vector3, kg: float) -> Array[Object]:
	var space := World.space(world)
	var r_max := reach(kg)
	var out: Array[Object] = []
	var seen := {}
	var add := func(c: Object) -> void:
		if c != null and not seen.has(c.get_instance_id()):
			seen[c.get_instance_id()] = true
			out.append(c)
	for f: Dictionary in _sphere(space, at, break_reach(kg), Layers.WORLD | Layers.DEBRIS | Layers.BODY_PARTS):
		add.call(f.collider)
	for f: Dictionary in _sphere(space, at, r_max, Layers.DEBRIS | Layers.BODY_PARTS):
		add.call(f.collider)
	for s: Node in world.get_tree().get_nodes_in_group(&"structures"):
		for m: StructureMember in (s as Structure).panes():
			if not m.broken and _nearest_on(m, at).distance_to(at) <= r_max:
				add.call(m)
	for g: StringName in [&"rubble", &"fallen"]:
		for rb: Node in world.get_tree().get_nodes_in_group(g):
			if rb is RigidBody3D and (rb as Node3D).global_position.distance_to(at) <= r_max:
				add.call(rb)
	return out


## Where timber can break (m) round `kg` of TNT.
static func break_reach(kg: float) -> float:
	return t().break_reach_per_cbrt_kg * pow(kg, 1.0 / 3.0)


## A sphere query that won't run out: asked again with room to spare if it came back full.
static func _sphere(space: PhysicsDirectSpaceState3D, at: Vector3, radius: float, mask: int) -> Array[Dictionary]:
	var shape := SphereShape3D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY, at)
	q.collision_mask = mask
	var cap := 2048
	var found := space.intersect_shape(q, cap)
	while found.size() >= cap:
		cap *= 4
		found = space.intersect_shape(q, cap)
	return found


## How a member answers: {break, push, distance}. Glass by pressure; timber by the energy the
## blast puts into it against what it can absorb bending.
static func _member_response(m: StructureMember, at: Vector3, kg: float, s: Structure) -> Dictionary:
	var tn := t()
	var near := _nearest_on(m, at)
	var dist := maxf(near.distance_to(at), 0.03)
	var dir := (m.global_position - at).normalized()
	if m.kind == &"glass":
		var kpa := reflected_kpa(overpressure_kpa(kg, dist))
		return {"break": kpa > tn.glass_kpa, "push": dir * minf(kpa * 0.2, 15.0), "distance": dist}
	var length := m.length()
	var cs := m.cross_section()
	var timber: TimberTuning = s.tuning if s and s.tuning else load("res://config/timber.tres")
	var mass := maxf(m.weight(timber) / 9.81, 0.05)
	var wood: Dictionary = timber.woods.get(m.wood, timber.default_wood)
	var fb: float = wood.bending
	var e: float = wood.stiffness
	var sound := cs.x * cs.y * length
	var capacity := fb * fb / (2.0 * e) * sound * tn.absorb_factor
	var span := minf(tn.local_span, length)
	var share := span / maxf(length, 1e-4)
	# Most of what a charge reaches it can't break: the most the face could take, were every
	# bit of it as near and as square to the charge as its nearest point, falls short of what
	# it soaks up, so the samples aren't walked (a stick in the spec saloon reaches thousands).
	var width := maxf(cs.x, cs.y)
	var r0 := maxf(near.distance_to(at), 0.02)  # the samples' own floor, not dist's
	var most := impulse(kg, r0) * reflection(overpressure_kpa(kg, r0)) * width
	if pow(most * length, 2.0) / (2.0 * mass) < capacity and pow(most * span, 2.0) / (2.0 * mass * share) < capacity * share:
		return {"break": false, "push": Vector3.ZERO, "distance": dist}
	var total := face_impulse(m, at, kg)
	var kick := total * total / (2.0 * mass)
	# Close in, it breaks where it's hit before the whole length feels it: the same test over the
	# hand-span of it nearest the charge.
	var near_j := face_impulse(m, at, kg, span)
	var near_kick := near_j * near_j / (2.0 * mass * share)
	var broke := kick > capacity or near_kick > capacity * share
	var speed := minf(maxf(total / mass, near_j / (mass * share) * 0.5), tn.max_throw)
	if broke:
		m.set_meta(&"blast_t", clampf((at - m.global_position).dot(m.axis()), -length * 0.5, length * 0.5))
	return {"break": broke, "push": (dir + Vector3.UP * 0.25).normalized() * speed, "distance": dist}


## The blast's push on a member (N·s): reflected impulse per area summed over the face turned to it. The
## samples bunch up round the point nearest the charge, where nearly all of it lands (a stick lying
## on a floorboard hits the bit under it far harder than the rest of the board).
static func face_impulse(m: StructureMember, at: Vector3, kg: float, window := INF, center := NAN) -> float:
	var length := m.length()
	var cs := m.cross_section()
	var width := maxf(cs.x, cs.y)
	var axis := m.axis()
	var half := length * 0.5
	var t0 := clampf((at - m.global_position).dot(axis), -half, half)
	# The window is about the point nearest the charge, or about `center` (along it, from its middle).
	var tc := t0 if is_nan(center) else clampf(center, -half, half)
	# How far the charge is off the face at its nearest, and how far out from the face it sees (the
	# side of the cross-section it's furthest beyond): a shock striking a face square on is
	# reflected in full, one running along it hardly at all.
	var perp := _nearest_on(m, at).distance_to(at)
	var out := _out_from_face(m, at)
	var offsets := [0.0]
	for d in [0.03, 0.08, 0.15, 0.3, 0.6, 1.2, 2.4, 4.8]:
		offsets.append(d)
		offsets.append(-d)
	var ts: Array[float] = []
	for o: float in offsets:
		var t := clampf(t0 + o, -half, half)
		if not ts.has(t):
			ts.append(t)
	if tc != t0 and window < INF:
		for o: float in [0.0, -0.4, -0.15, 0.15, 0.4]:
			var t := clampf(tc + o * window, -half, half)
			if not ts.has(t):
				ts.append(t)
	ts.sort()
	var total := 0.0
	for i in ts.size():
		var lo := -half if i == 0 else (ts[i - 1] + ts[i]) * 0.5
		var hi := half if i == ts.size() - 1 else (ts[i] + ts[i + 1]) * 0.5
		if window < INF:
			lo = maxf(lo, tc - window * 0.5)
			hi = minf(hi, tc + window * 0.5)
		var seg := hi - lo
		if seg <= 0.0:
			continue
		var along := ts[i] - t0
		var r := maxf(sqrt(perp * perp + along * along), 0.02)
		# Across the width, the part near the charge takes more: average over the strip.
		var mean := 0.0
		for k in 3:
			var off := width * (k - 1) / 3.0
			var rk := sqrt(r * r + off * off)
			var square_on := clampf(out / rk, 0.0, 1.0)
			mean += impulse(kg, rk) * (1.0 + (reflection(overpressure_kpa(kg, rk)) - 1.0) * square_on)
		total += mean / 3.0 * seg * width
	return total


## Boards, floor boards and roof boards: what a charge overcomes is torn out of them, not the whole
## length (a floor board is the room's width). Framing still snaps where it's hit.
const CUT_KINDS: Array[StringName] = [&"board", &"floor_board", &"roof_board"]
## How finely the torn stretch's ends are found along a board (m).
const CUT_STEP := 0.05


## The stretch of a board a charge tears out (Vector2(t0, t1), along it from its middle): where the
## kick over a hand-span (`local_span`) about each point beats what that span soaks up bending, as
## `_member_response` tests at the point nearest the charge, walked out from there both ways. A
## board broken by the whole-length test alone loses one span about that point.
static func torn_stretch(m: StructureMember, at: Vector3, kg: float, timber: TimberTuning) -> Vector2:
	var tn := t()
	var length := m.length()
	var half := length * 0.5
	var span := minf(tn.local_span, length)
	var share := span / maxf(length, 1e-4)
	var mass := maxf(m.weight(timber) / 9.81, 0.05)
	var cs := m.cross_section()
	var wood: Dictionary = timber.woods.get(m.wood, timber.default_wood)
	var fb: float = wood.bending
	var capacity := fb * fb / (2.0 * float(wood.stiffness)) * cs.x * cs.y * length * tn.absorb_factor * share
	var near := clampf((at - m.global_position).dot(m.axis()), -half, half)
	var over := func(tc: float) -> bool:
		var j := face_impulse(m, at, kg, span, tc)
		return j * j / (2.0 * mass * share) > capacity
	var lo := near
	var hi := near
	if over.call(near):
		# The kick falls off away from the charge: each end is found by halving (to CUT_STEP), not
		# by stepping along (a long board's walk was ~70 windows; this is ~12).
		var reach := break_reach(kg)
		lo = _last_over(over, near, maxf(near - reach, -half))
		hi = _last_over(over, near, minf(near + reach, half))
	return Vector2(clampf(lo - span * 0.5, -half, half), clampf(hi + span * 0.5, -half, half))


## From `inside` (where `over` holds) toward `outside`: the furthest point it still holds, to CUT_STEP.
static func _last_over(over: Callable, inside: float, outside: float) -> float:
	if over.call(outside):
		return outside
	while absf(outside - inside) > CUT_STEP:
		var mid := (inside + outside) * 0.5
		if over.call(mid):
			inside = mid
		else:
			outside = mid
	return inside


## A timber lying on the ground (a sill on its footing): a charge on it cuts it, but both halves
## still lie where they were and carry what stood on them, so it stays in the wall. (Snapped, the
## whole length would fall as rubble and take the wall and roof with it.)
static func _bedded(m: StructureMember) -> bool:
	return m.grounded and absf(m.axis().y) < 0.5


## How far `at` stands out from the long face of a member it's beyond (m; at least 2 cm, nothing
## if it's off the member's end, in line with it).
static func _out_from_face(m: StructureMember, at: Vector3) -> float:
	var local := m.global_transform.affine_inverse() * at
	var half := m.size * 0.5
	var long := m.axis_index()
	var out := -INF
	for i in 3:
		if i != long:
			out = maxf(out, absf(local[i]) - half[i])
	return maxf(out, 0.02) if out > -0.005 else 0.0


## The point of a member nearest `at`.
static func _nearest_on(m: StructureMember, at: Vector3) -> Vector3:
	var local := m.global_transform.affine_inverse() * at
	var half := m.size * 0.5
	var c := Vector3(clampf(local.x, -half.x, half.x), clampf(local.y, -half.y, half.y), clampf(local.z, -half.z, half.z))
	return m.global_transform * c
