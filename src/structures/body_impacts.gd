class_name BodyImpacts
extends RefCounted
## A limp man thrown into timber breaks it as falling timber does (Structure._on_rubble_hit): when
## the energy spent stopping him against a member passes what it can take (`capacity`: its wood's,
## TimberTuning impact_toughness J per m³; trim's nails first). What the engine took from him past
## that goes back to him (`_give_back`): he carries on through. A shove into a railing, a body pitched into a balustrade at a
## run (Sean, 2026-10-21: "a hard push or shove into that 1 meter railing, make the railing break
## and the body fall").
##
## The energy is the work of the contact's impulse over the closing speed it takes away, summed
## over every part of him on that member while he's on it (the stop takes a few ticks). From the
## side, against `capacity`: a railing gives way to a body thrown into it. From above (issue #759,
## a body falling onto it), only boards (`ABOVE_KINDS`) and a railing's members, and only parts
## coming down faster than TimberTuning.body_above_speed, against `capacity_above`: what a board
## takes is its breaking load where he lands on it, over its span between rafters or joists, times
## the give of his flesh (`body_stop`). The span between the supports either side of him drops
## out (Structure.cut_member) and the rest stays nailed. A man dropped onto a floor, lying or
## walking on a roof, never comes near it (roof boards go at ~3-3.5 m of fall, a porch roof's
## ~2.5-3, floors ~6 feet first: Sean's #762; experiments/falls_lab/); joists, rafters and beams are
## never broken by a body from above, so he mostly lodges in the hole he makes, between rafters
## 0.61 m apart, and goes through when he lands between them feet first or lying along them.
##
## And an upright member whose top nothing holds any more (a baluster whose cap rail he broke) is
## held at its foot only by its nails (`nailed_moment`; a post set in the ground isn't):
## it tears out when his push on it, times how high up it he bears, passes that, whichever way he
## bears on it. His weight leaning or lying on a freed balustrade is enough.

## A member's tally is forgotten this long after his last touch on it (s).
const FORGET_AFTER := 0.3
## Parts slower than this (m/s) break nothing by impact (only a freed member's nails, by his push).
const QUIET_SPEED := 0.6

var _tally := {}  ## StructureMember -> [joules, seconds since a touch]
var _rbs: Array[RigidBody3D] = []  ## his parts, as watched
var _last_v := PackedVector3Array()  ## each one's velocity last tick
## RigidBody3D -> how many members it's touching (body_entered/exited): only these are read, so a
## man lying in the street or on the ground costs nothing (reading all his parts every tick, ten
## men going down took a third again the frame, p99 5 -> 27 ms).
var _touching := {}
## Near timber at all (a sphere round his pelvis, every NEAR_EVERY ticks): out in the street his
## parts aren't read at all (their velocities, kept for a contact, were ~0.3 ms for ten men).
const NEAR_RADIUS := 1.6
const NEAR_EVERY := 10
var _near := false
var _ticks := 0
var _pelvis: RigidBody3D
var _probe: PhysicsShapeQueryParameters3D


## Each of his parts as he goes limp: its contacts with members are watched while he's near timber.
func watch(rb: RigidBody3D) -> void:
	if rb.get_meta(&"segment", &"") == &"pelvis":
		_pelvis = rb
	rb.set_meta(&"impact_index", _rbs.size())
	_rbs.append(rb)
	_last_v.append(Vector3.ZERO)


## Near timber, his parts' contacts are reported and listened to: not out in the street (Jolt's
## contact reports for ten men going down at once cost a frame of ~25 ms now and then, and their
## touches of each other and the ground come by the hundred).
func _listen(on: bool) -> void:
	_touching.clear()
	for rb in _rbs:
		if not is_instance_valid(rb):
			continue
		if on:
			rb.contact_monitor = true
			# Eight: a part pressed into a railing touches the floor, two or three balusters and the
			# rail at once; with four the rail's contact went unreported often enough that a man thrown
			# into it at 3.5 m/s left it standing 5 times in 24 (its work undercounted).
			rb.max_contacts_reported = maxi(rb.max_contacts_reported, 8)
			rb.body_entered.connect(_entered.bind(rb))
			rb.body_exited.connect(_exited.bind(rb))
			# Already against a member (he went down leaning on it): counted from now.
			for b: Node3D in rb.get_colliding_bodies():
				_entered(b, rb)
		elif rb.body_entered.is_connected(_entered.bind(rb)):
			rb.body_entered.disconnect(_entered.bind(rb))
			rb.body_exited.disconnect(_exited.bind(rb))


func _entered(other: Node, rb: RigidBody3D) -> void:
	if other is StructureMember:
		_touching[rb] = int(_touching.get(rb, 0)) + 1


func _exited(other: Node, rb: RigidBody3D) -> void:
	if other is StructureMember and _touching.has(rb):
		_touching[rb] -= 1
		if _touching[rb] <= 0:
			_touching.erase(rb)


## Once a tick while he's limp, after his parts are `watch`ed. Returns the members it broke.
func step(delta: float) -> Array[StructureMember]:
	var broke: Array[StructureMember] = []
	for m: StructureMember in _tally.keys():
		var e: Array = _tally[m]
		e[1] += delta
		if e[1] > FORGET_AFTER or not is_instance_valid(m) or m.broken:
			_tally.erase(m)
	# Falling fast he'd be through the near sphere between looks: it reaches as far as he'll go.
	var fast := 0.0
	if _pelvis != null and is_instance_valid(_pelvis):
		fast = _pelvis.linear_velocity.length()
		_drop_was = _drop_v
		_drop_v = maxf(-_pelvis.linear_velocity.y, 0.0)
	if _ticks % NEAR_EVERY == 0 or (fast > 6.0 and not _near):
		var was := _near
		_near = _timber_near(fast * float(NEAR_EVERY) / 60.0)
		if _near != was:
			_listen(_near)
		if _near and not was:
			for k in _rbs.size():
				if is_instance_valid(_rbs[k]):
					_last_v[k] = _rbs[k].linear_velocity
	_ticks += 1
	if not _near:
		return broke
	# Each part's velocity is kept from the tick before (what it brought into a contact); only those
	# touching a member are read.
	var before_all := _last_v.duplicate()
	for k in _rbs.size():
		var rb := _rbs[k]
		if is_instance_valid(rb) and not rb.sleeping:
			_last_v[k] = rb.linear_velocity
	var kit := {}  ## a kit prop he's hitting this tick -> what he brings it (`_kit_contact`)
	for rb: RigidBody3D in _touching.keys():
		if not is_instance_valid(rb) or rb.sleeping or not rb.is_inside_tree():
			continue
		var before: Vector3 = before_all[int(rb.get_meta(&"impact_index"))]
		var now: Vector3 = _last_v[int(rb.get_meta(&"impact_index"))]
		var moving := Vector2(before.x, before.z).length() >= QUIET_SPEED
		var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
		if st == null:
			continue
		for i in st.get_contact_count():
			var m := st.get_contact_collider_object(i) as StructureMember
			if m == null or m.broken:
				continue
			var j := st.get_contact_impulse(i)
			var n := st.get_contact_local_normal(i)
			var s := m.get_parent() as Structure
			if s == null or s.tuning == null:
				continue
			if s.has_method(&"take_blow"):
				_kit_contact(kit, s, m, rb, n, before, st.get_contact_collider_position(i))
				_kit_stop(s, m, rb, j, st.get_contact_collider_position(i))
				continue
			if m.is_upright() and not m.grounded and _top_free(s, m):
				# Free at the top it holds nothing up: leaning on it or lying across it, any way he
				# bears on it levers it off its nails.
				var push := j.length() / maxf(delta, 1e-4)
				var up := st.get_contact_collider_position(i).y - m.world_aabb().position.y
				var holds := nailed_moment(s.tuning, m)
				if push * up > holds:
					broke.append(m)
					_tally.erase(m)
					# It pushed back only as hard as its nails held, this one tick: the rest of what
					# the engine took from him goes back (as `_give_back`).
					var could := holds / maxf(up, 0.05) * delta
					var level := Vector3(j.x, 0.0, j.z)
					rb.apply_central_impulse(-level * clampf(1.0 - could / maxf(j.length(), 1e-6), 0.0, 1.0))
					var away := Vector3(-n.x, 0.0, -n.z)
					s.break_member.call_deferred(m, away.normalized() * maxf(before.length(), 0.3) if away.length() > 0.01 else before)
					continue
			var nl := Vector3(n.x, 0.0, n.z)
			# A board lying flat (a roof's, a floor's) is only ever landed on from above: a part on the
			# seam between two meets an edge at a slant, near level, and that's no blow from the side.
			var flat_board := m.kind in ABOVE_KINDS
			if nl.length() < 0.2 or flat_board:
				if (n.y > 0.8 or (flat_board and n.y > 0.0)) and (flat_board or m.kind == &"trim" or m.kind == &"baluster"):
					_from_above(s, m, rb, j, before, now, st.get_contact_collider_position(i), broke)
				continue  # struck from below, or a member a body never breaks from above
			nl = nl.normalized()
			if not moving:
				continue
			# The level speed into it it took away this tick, at the mean of before and after.
			var closing := (absf(before.dot(nl)) + absf(now.dot(nl))) * 0.5
			var work := absf(j.dot(nl)) * closing
			var e: Array = _tally.get(m, [0.0, 0.0, {}])
			e[0] += work
			e[1] = 0.0
			var given: Dictionary = e[2]
			given[rb] = (given.get(rb, Vector3.ZERO) as Vector3) + nl * j.dot(nl)
			_tally[m] = e
			var can_take := capacity(s, m)
			if e[0] > can_take:
				broke.append(m)
				_tally.erase(m)
				s.break_member.call_deferred(m, before * 0.3)
				_give_back(given, e[0], can_take)
	_kit_blows(kit, broke)
	return broke


## Boards a body landing from above can break (issue #759).
const ABOVE_KINDS := [&"roof_board", &"floor_board"]
## The labs' measure (issue #759): the most of TimberTuning.body_stop a board he landed on would
## have needed to hold him (m; it broke if that's over the dial).
var peak_need := 0.0
## The speed his middle is coming down at, this tick and the last (m/s).
var _drop_v := 0.0
var _drop_was := 0.0


## A part of him landing on `m` from above: its work tallied as the level case's, against
## `capacity_above` (a railing's members: their nails, `capacity`).
func _from_above(s: Structure, m: StructureMember, rb: RigidBody3D, j: Vector3, before: Vector3, now: Vector3,
		at: Vector3, broke: Array[StructureMember]) -> void:
	# What stops on it is all of him behind the part, through his joints over the next few ticks
	# (a foot stops at once, the leg and body come down on it after): each tick's push on it counts
	# at the speed it took away, the part's own or his middle's, whichever is more (the mean of this
	# tick's and the last). Lying still on it, his weight puts in nothing.
	var into := maxf(-before.y, _drop_was)
	if into < s.tuning.body_above_speed:
		return
	var closing := maxf((maxf(-before.y, 0.0) + maxf(-now.y, 0.0)) * 0.5, (_drop_was + _drop_v) * 0.5)
	var work := absf(j.y) * closing
	# Landing on his feet, his body comes down on that foot or shin (TimberTuning.body_feet_share of
	# it): his limp ragdoll's knees fold at once where a man's take some of his weight.
	var seg := String(rb.get_meta(&"segment", &""))
	if (seg.begins_with("foot") or seg.begins_with("shin")) and _pelvis != null and is_instance_valid(_pelvis) \
			and _pelvis.global_position.y > at.y + 0.6:
		work *= clampf(_mass() * s.tuning.body_feet_share / maxf(rb.mass, 0.5), 1.0, 50.0)
	var e: Array = _tally.get(m, [0.0, 0.0, {}])
	e[0] += work
	e[1] = 0.0
	var given: Dictionary = e[2]
	given[rb] = (given.get(rb, Vector3.ZERO) as Vector3) + Vector3.UP * j.y
	_tally[m] = e
	var can_take := capacity_above(s, m, at) if m.kind in ABOVE_KINDS else capacity(s, m)
	if m.kind in ABOVE_KINDS:
		peak_need = maxf(peak_need, e[0] / maxf(can_take / maxf(s.tuning.body_stop, 1e-6), 1e-6))
	if e[0] > can_take:
		broke.append(m)
		_tally.erase(m)
		# A board goes between the rafters or joists either side of him: that span drops out under
		# him and the rest stays nailed down (Structure.cut_member, as a charge's hole).
		var span := span_at(s, m, at) if m.kind in ABOVE_KINDS else Vector2.INF
		if span.x > -INF and span.y < INF:
			s.cut_member.call_deferred(m, span.x, span.y, Vector3(before.x * 0.3, minf(before.y, 0.0) * 0.5, before.z * 0.3))
		else:
			s.break_member.call_deferred(m, before * 0.3)
		_give_back(given, e[0], can_take)


## What a board takes from a body landing on it at `at` (world) before it breaks (J): the point
## load that breaks it there (simply supported between the supports either side: P = M L / (a b),
## M its bending strength times its section, as StructuralAnalysis has it; held at one end only,
## M over the reach), times TimberTuning.body_stop. A saloon roof board (1x8 weathered pine, rafters
## at 0.61 m) ~4.3 kN at mid-span, ~1,700 J at body_stop 0.4; a porch roof's (rafters 0.75) ~1,400;
## a floor board (1x6 on joists at 0.406) ~2,700. Nearer a support it takes more.
static func capacity_above(s: Structure, m: StructureMember, at: Vector3) -> float:
	if m.supported_by.is_empty():
		return INF  # on no timber: bedded on the ground (or whatever's solid) its whole length
	var w := s.tuning.wood(m.wood)
	var dims := m.cross_section()
	var moment := float(w.get("bending", 40e6)) * dims.x * dims.y * dims.y / 6.0 * m.section_left(s.tuning)
	var geo := StructuralAnalysis.geometry_of(m, s)
	var t := ((s.global_transform.affine_inverse() * at) - (geo.origin as Vector3)).dot(geo.axis as Vector3)
	var span := span_at(s, m, at)
	var left := span.x
	var right := span.y
	var load: float
	if left > -INF and right < INF and right - left > 0.05:
		var a := maxf(t - left, 0.05)
		var b := maxf(right - t, 0.05)
		load = moment * (a + b) / (a * b)
	else:
		load = moment / maxf(minf(absf(t - left), absf(right - t)), 0.05)
	return load * s.tuning.body_stop


## The supports either side of `at` (world) along a member: Vector2(t before, t after) from its
## middle along its axis (-INF / INF where there's none that side).
static func span_at(s: Structure, m: StructureMember, at: Vector3) -> Vector2:
	var geo := StructuralAnalysis.geometry_of(m, s)
	var t := ((s.global_transform.affine_inverse() * at) - (geo.origin as Vector3)).dot(geo.axis as Vector3)
	var left := -INF
	var right := INF
	for ts: Array in (geo.support_t as Dictionary).values():
		for x: float in ts:
			if x <= t:
				left = maxf(left, x)
			if x >= t:
				right = minf(right, x)
	return Vector2(left, right)


## A kit prop (KitProp: a chair, a table; the prop lab's) takes him as a blow on its own terms
## (`take_blow`: it breaks, slides or goes over by its wood, its weight and what's on it), not by the
## timber rule above. Each of his parts moving into it brings its momentum; together, once a tick,
## they're one blow from the weight of them (Sean, 2026-10-22: bodies breaking furniture). A prop
## he's just struck takes no more from him for KIT_AGAIN (he's on it, not hitting it).
const KIT_AGAIN := 0.25
var _kit_last := {}  ## KitProp -> seconds since he last struck it


func _kit_contact(kit: Dictionary, s: Structure, m: StructureMember, rb: RigidBody3D, n: Vector3, before: Vector3,
		at: Vector3) -> void:
	if s.get(&"loose") or float(_kit_last.get(s, INF)) < KIT_AGAIN:
		return
	# The contact's normal points out of the prop at him: his speed into it, from the tick before.
	var into := -before.dot(n)
	if into < QUIET_SPEED:
		return
	var e: Array = kit.get(s, [Vector3.ZERO, 0.0, {}, null, 0.0, Vector3.ZERO])
	var by: Dictionary = e[2]
	if by.has(rb):
		return
	by[rb] = true
	var p := -n * into * rb.mass
	e[0] += p
	e[1] += rb.mass
	if p.length() > float(e[4]):
		e[3] = m
		e[4] = p.length()
		e[5] = at
	kit[s] = e


func _kit_blows(kit: Dictionary, broke: Array[StructureMember]) -> void:
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	for s: Variant in _kit_last.keys():
		_kit_last[s] = float(_kit_last[s]) + dt
		if not is_instance_valid(s) or float(_kit_last[s]) > 2.0 * KIT_AGAIN:
			_kit_last.erase(s)
	for s: Variant in kit:
		if not is_instance_valid(s):
			continue
		var e: Array = kit[s]
		var m := e[3] as StructureMember
		if m == null or not is_instance_valid(m) or m.broken:
			continue
		_kit_last[s] = 0.0
		if s.call(&"take_blow", m, e[5], e[0], e[1]) == &"broke":
			broke.append(m)
		elif HumanBody.keep_stride and not s.get(&"loose"):
			# Held: what the engine takes from all of him against it over the next few ticks decides.
			_kit_held[s] = [Vector3.ZERO, 0.0, {}, m, e[5], 0.0]
	_kit_stops(broke)


## Issue #446 (with HumanBody.keep_stride): a kit prop held rigid until it decides stops all of him
## through the few parts that touch it, a hand or a shin: as a blow from those parts' weight alone,
## a man running into a card table left it standing ("that table doesn't move or flip", Sean,
## 2026-10-28). So once his parts' first touch has been taken as a blow and held, what the engine
## takes from him against it (the contacts' level impulses: his whole weight coming on behind those
## parts) is summed for KIT_HOLD and given to it each tick, a blow from his whole weight; when it goes,
## what a free prop wouldn't have taken from him (his share, M / (M + its weight)) goes back to the
## parts it stopped, and he carries on with it.
const KIT_HOLD := 0.2
var _kit_held := {}  ## KitProp -> [level impulse it took from him, seconds, {part: impulse on it}, member, where, weight of where]


func _kit_stop(s: Structure, m: StructureMember, rb: RigidBody3D, j: Vector3, at: Vector3) -> void:
	var e: Array = _kit_held.get(s, [])
	if e.is_empty() or s.get(&"loose"):
		return
	var level := Vector3(j.x, 0.0, j.z)
	var w := level.length()
	if w <= 0.0:
		return
	e[0] = (e[0] as Vector3) - level
	var given: Dictionary = e[2]
	given[rb] = (given.get(rb, Vector3.ZERO) as Vector3) + level
	# Where he bears on it: the contacts weighted by what each took (his chest on its top and his
	# shins on its foot push it over about the middle, not at whichever touched last).
	e[4] = ((e[4] as Vector3) * float(e[5]) + at * w) / (float(e[5]) + w)
	e[5] = float(e[5]) + w
	e[3] = m


func _kit_stops(broke: Array[StructureMember]) -> void:
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	for s: Variant in _kit_held.keys():
		var e: Array = _kit_held[s]
		e[1] = float(e[1]) + dt
		if not is_instance_valid(s) or s.get(&"loose") or float(e[1]) > KIT_HOLD:
			_kit_held.erase(s)
			continue
		var m := e[3] as StructureMember
		var took: Vector3 = e[0]
		if m == null or not is_instance_valid(m) or m.broken or took.length() < 1e-3:
			continue
		var him := _mass()
		var its := float(s.call(&"mass"))  # (before: gone loose, its members are rubble)
		var r: StringName = s.call(&"take_blow", m, e[4], took, him)
		if r == &"broke":
			broke.append(m)
		if s.get(&"loose"):
			var keep := him / (him + maxf(its, 0.1))
			var given: Dictionary = e[2]
			for rb: Variant in given:
				if is_instance_valid(rb):
					(rb as RigidBody3D).apply_central_impulse(-(given[rb] as Vector3) * keep)
			_kit_held.erase(s)


## His weight (the parts watched).
func _mass() -> float:
	var kg := 0.0
	for rb in _rbs:
		if is_instance_valid(rb):
			kg += rb.mass
	return maxf(kg, 1.0)


## A member breaks having taken no more than it could (`can_take`), but the engine held it rigid
## until it did, so it may have stopped him harder (`took`): for a stop, energy goes with the
## impulse squared, so the share of the impulse it really took is sqrt(can_take / took); the rest
## goes back to each part it pushed, the way it was going: he carries on through.
static func _give_back(given: Dictionary, took: float, can_take: float) -> void:
	var back := clampf(1.0 - sqrt(can_take / maxf(took, 1e-6)), 0.0, 1.0)
	if back <= 0.0:
		return
	for rb: RigidBody3D in given:
		if is_instance_valid(rb):
			rb.apply_central_impulse(-(given[rb] as Vector3) * back)


## Nothing holds its top: every member it touches, but what it stands on, is broken (or there's
## none).
static func _top_free(s: Structure, m: StructureMember) -> bool:
	for id: StringName in m.touching:
		if id in m.supported_by:
			continue
		var o := s.get_member(id)
		if o != null and not o.broken:
			return false
	return true


## What a member takes from a body thrown into it before it gives way (J): its wood's, as falling
## timber's (`impact_toughness` x its volume); but a railing's members (trim and balusters: finish
## carpentry, light nails) let go at their nails first. Each member it touches is a nailed joint that
## gives way after ~10 mm of slip at its nails, a turn of NAIL_TURN over its depth (load-slip of
## nailed joints, USDA Wood Handbook ch. 8: an assumption to judge by eye), half its
## `nailed_moment` x that turn. A 1.2 m oak cap on nine balusters and two newels ~51 J (its wood
## ~150), a baluster ~6.5.
const NAIL_TURN := 0.15


static func capacity(s: Structure, m: StructureMember) -> float:
	var wood := s.tuning.impact_toughness * m.volume()
	if m.kind != &"trim" and m.kind != &"baluster":
		return wood
	var joints := 0.0
	for id: StringName in m.touching:
		var o := s.get_member(id)
		if o != null and not o.broken:
			joints += 0.5 * minf(nailed_moment(s.tuning, m), nailed_moment(s.tuning, o)) * NAIL_TURN
	return minf(wood, joints)


## What a member's nailed foot takes before it tears out (N·m): TimberTuning.joint_moment is a
## framing member's (38 x 89, several nails); a smaller section takes fewer nails nearer together,
## so holds less, in proportion (a 35 mm baluster, toe-nailed with one or two: ~43).
const FRAMING_SECTION := 0.038 * 0.089


static func nailed_moment(tuning: TimberTuning, m: StructureMember) -> float:
	var cs := m.cross_section()
	return tuning.joint_moment * clampf(cs.x * cs.y / FRAMING_SECTION, 0.1, 3.0)


## Any member within NEAR_RADIUS of his pelvis (and `reach` more, falling fast).
func _timber_near(reach := 0.0) -> bool:
	if _pelvis == null or not is_instance_valid(_pelvis) or not _pelvis.is_inside_tree():
		return false
	if _probe == null:
		_probe = PhysicsShapeQueryParameters3D.new()
		_probe.shape = SphereShape3D.new()
		_probe.collision_mask = Layers.WORLD
	(_probe.shape as SphereShape3D).radius = NEAR_RADIUS + minf(reach, 6.0)
	_probe.transform = Transform3D(Basis(), _pelvis.global_position)
	for hit: Dictionary in World.space(_pelvis).intersect_shape(_probe, 24):
		if hit.collider is StructureMember:
			return true
	return false
