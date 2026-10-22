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
## over every part of him on that member while he's on it (the stop takes a few ticks). Only the
## level part counts: a railing gives way to a body thrown into it from the side, where a floor or
## a tread, struck from above, bears on its joists and posts (a man dropped onto boards doesn't go
## through them).
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
	if _ticks % NEAR_EVERY == 0:
		var was := _near
		_near = _timber_near()
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
			if nl.length() < 0.2:
				continue  # struck from above or below: it bears on its supports
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


## Any member within NEAR_RADIUS of his pelvis.
func _timber_near() -> bool:
	if _pelvis == null or not is_instance_valid(_pelvis) or not _pelvis.is_inside_tree():
		return false
	if _probe == null:
		_probe = PhysicsShapeQueryParameters3D.new()
		var ball := SphereShape3D.new()
		ball.radius = NEAR_RADIUS
		_probe.shape = ball
		_probe.collision_mask = Layers.WORLD
	_probe.transform = Transform3D(Basis(), _pelvis.global_position)
	for hit: Dictionary in _pelvis.get_world_3d().direct_space_state.intersect_shape(_probe, 24):
		if hit.collider is StructureMember:
			return true
	return false
