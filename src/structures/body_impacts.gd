class_name BodyImpacts
extends RefCounted
## A limp man thrown into timber breaks it as falling timber does (Structure._on_rubble_hit): when
## the energy spent stopping him against a member passes what it can take (TimberTuning
## impact_toughness, J per m³ of it). A shove into a railing, a body pitched into a balustrade at a
## run (Sean, 2026-10-21: "a hard push or shove into that 1 meter railing, make the railing break
## and the body fall").
##
## The energy is the work of the contact's impulse over the closing speed it takes away, summed
## over every part of him on that member while he's on it (the stop takes a few ticks). Only the
## level part counts: a railing gives way to a body thrown into it from the side, where a floor or
## a tread, struck from above, bears on its joists and posts (a man dropped onto boards doesn't go
## through them).

## A member's tally is forgotten this long after his last touch on it (s).
const FORGET_AFTER := 0.3
## Parts slower than this (m/s) can't break anything: no contacts read (most ticks of a fall).
const QUIET_SPEED := 0.6

var _tally := {}  ## StructureMember -> [joules, seconds since a touch]
var _last_v := {}  ## RigidBody3D -> its velocity last tick


## Once a tick while he's limp: `parts` his RigidBody3Ds. Returns the members it broke.
func step(parts: Dictionary, delta: float) -> Array[StructureMember]:
	var broke: Array[StructureMember] = []
	for m: StructureMember in _tally.keys():
		var e: Array = _tally[m]
		e[1] += delta
		if e[1] > FORGET_AFTER or not is_instance_valid(m) or m.broken:
			_tally.erase(m)
	for rb_v: Variant in parts.values():
		var rb := rb_v as RigidBody3D
		if rb == null or not is_instance_valid(rb) or not rb.is_inside_tree():
			continue
		var before: Vector3 = _last_v.get(rb, rb.linear_velocity)
		var now := rb.linear_velocity
		_last_v[rb] = now
		if rb.sleeping or Vector2(before.x, before.z).length() < QUIET_SPEED:
			continue
		var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
		if st == null:
			continue
		for i in st.get_contact_count():
			var m := st.get_contact_collider_object(i) as StructureMember
			if m == null or m.broken:
				continue
			var j := st.get_contact_impulse(i)
			var n := st.get_contact_local_normal(i)
			var nl := Vector3(n.x, 0.0, n.z)
			if nl.length() < 0.2:
				continue  # struck from above or below: it bears on its supports
			nl = nl.normalized()
			# The level speed into it it took away this tick, at the mean of before and after.
			var closing := (absf(before.dot(nl)) + absf(now.dot(nl))) * 0.5
			var work := absf(j.dot(nl)) * closing
			var e: Array = _tally.get(m, [0.0, 0.0])
			e[0] += work
			e[1] = 0.0
			_tally[m] = e
			var s := m.get_parent() as Structure
			if s and s.tuning and e[0] > s.tuning.impact_toughness * m.volume():
				broke.append(m)
				_tally.erase(m)
				s.break_member.call_deferred(m, before * 0.3)
	return broke
