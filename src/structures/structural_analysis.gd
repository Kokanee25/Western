class_name StructuralAnalysis
extends RefCounted
## How the weight of a structure comes down through its members to the ground, and how hard each
## member is working. Pure rules over a Structure's members (no physics), so they're tested
## headless.
##
## Loads flow top-down through the support graph (a member rests on lower tiers, or on the same kind
## stacked underneath it): each member
## carries its own weight, any `extra_load` on it, and the share of everything resting on it at the
## point where it rests. Then:
## - upright members (posts, studs) are checked in compression: crushing, or buckling for slender
##   ones (sheathed studs are braced by the boards nailed to them);
## - lying members (joists, beams, rafters, boards) are checked in bending over their spans between
##   supports, with overhangs as cantilevers; a member left hanging off one support is held only by
##   its nails (TimberTuning.joint_moment);
## - bullet holes weaken the section they pass through.
## Utilisation = demand / capacity; over 1 it breaks.

const BENDING_KINDS := [&"joist", &"floor_board", &"plate", &"beam", &"header", &"ledger", &"rafter",
		&"roof_board", &"ridge", &"furniture_top"]
const COMPRESSION_KINDS := [&"post", &"stud", &"cripple"]
const BRACED_KINDS := [&"stud", &"cripple"]
## Supports closer than this along a member count as one.
const SAME_SUPPORT := 0.03

var tuning: TimberTuning
## id -> newtons coming down through the member (its own weight and everything it carries)
var load := {}
## id -> demand / capacity, for checked members
var utilisation := {}
## id -> &"bending", &"compression", &"buckling" or &"joint": what's governing
var mode := {}
## id -> t along the member where it's working hardest (for where it snaps)
var critical_t := {}
## Members with no load path to the ground.
var falling: Array[StringName] = []
## Total load delivered to the ground (N): should equal the structure's weight.
var ground_load := 0.0


func _init(t: TimberTuning = null) -> void:
	tuning = t if t != null else load_tuning()


static func load_tuning() -> TimberTuning:
	return load("res://config/timber.tres")


func analyse(structure: Structure, extra_broken := {}) -> StructuralAnalysis:
	var broken := extra_broken.duplicate()
	for m in structure.get_members():
		if m.broken:
			broken[m.member_id] = true
	falling = structure.members_without_load_path(broken)
	var gone := broken.duplicate()
	for id in falling:
		gone[id] = true
	var sorted: Array[StructureMember] = []
	for m in structure.get_members():
		if not gone.has(m.member_id):
			sorted.append(m)
	sorted.sort_custom(func(a: StructureMember, b: StructureMember) -> bool: return a.stack_key > b.stack_key)
	var point_loads := {}  # id -> Array of [Vector3 (structure space), newtons]
	load.clear()
	utilisation.clear()
	mode.clear()
	critical_t.clear()
	ground_load = 0.0
	for m in sorted:
		var loads: Array = point_loads.get(m.member_id, [])
		var total := m.weight(tuning) + m.extra_load
		for pl: Array in loads:
			total += float(pl[1])
		load[m.member_id] = total
		var supports: Array[StringName] = []
		for s in m.supported_by:
			if not gone.has(s):
				supports.append(s)
		if m.grounded:
			ground_load += total
			if m.kind in COMPRESSION_KINDS and m.is_upright():
				_check_compression(m, total)
			continue
		if supports.is_empty():
			continue  # can't happen: it would be falling
		if m.is_upright():
			if m.kind in COMPRESSION_KINDS:
				_check_compression(m, total)
			var share := total / supports.size()
			for s in supports:
				point_loads.get_or_add(s, []).append([m.support_points.get(s, m.transform.origin), share])
		else:
			_bend(m, loads, supports, structure, gone, point_loads)
	return self


## Is anything overloaded? Returns the ids over capacity, worst first.
func overloaded() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in utilisation:
		if utilisation[id] > 1.0:
			out.append(id)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return utilisation[a] > utilisation[b])
	return out


func _check_compression(m: StructureMember, force: float) -> void:
	var w := tuning.wood(m.wood)
	var dims := m.cross_section()
	var b: float = minf(dims.x, dims.y)
	var h: float = maxf(dims.x, dims.y)
	var keep := m.section_left(tuning)
	var crush: float = w.compression * b * h * keep
	var k := tuning.braced_buckling_factor if m.kind in BRACED_KINDS else tuning.free_buckling_factor
	var length := m.length()
	var inertia := h * b * b * b / 12.0
	var euler: float = PI * PI * float(w.stiffness) * inertia * keep / pow(k * length, 2.0)
	var capacity := minf(crush, euler)
	utilisation[m.member_id] = force / maxf(capacity, 1.0)
	mode[m.member_id] = &"compression" if crush <= euler else &"buckling"
	critical_t[m.member_id] = m.weakest_t()


## A lying member: loads along it, supports under it, bending over each span.
func _bend(m: StructureMember, loads: Array, supports: Array[StringName], structure: Structure, gone: Dictionary, point_loads: Dictionary) -> void:
	var length := m.length()
	var half := length * 0.5
	var axis := m.axis()
	var origin := m.transform.origin
	var w_self := (m.weight(tuning)) / maxf(length, 0.01)
	var points: Array = []  # [t, newtons]
	for pl: Array in loads:
		points.append([clampf(((pl[0] as Vector3) - origin).dot(axis), -half, half), float(pl[1])])
	if m.extra_load > 0.0:
		points.append([0.0, m.extra_load])
	# Group supports by where they are along the member.
	var groups: Array = []  # [t, Array[StringName]]
	for s in supports:
		# Where along the member it bears on this support: a point, or both ends of a long
		# contact (lying along a beam, a plank on a sleeper it crosses at an angle...).
		var ts_here: Array[float] = []
		var box: Variant = m.support_boxes.get(s)
		if box is AABB:
			var lo := INF
			var hi := -INF
			for c in 8:
				var t := ((box as AABB).get_endpoint(c) - origin).dot(axis)
				lo = minf(lo, t)
				hi = maxf(hi, t)
			lo = clampf(lo, -half, half)
			hi = clampf(hi, -half, half)
			ts_here.append((lo + hi) * 0.5)
			if hi - lo > 0.1:
				ts_here = [lo, hi]
		else:
			ts_here.append(clampf(((m.support_points.get(s, origin) as Vector3) - origin).dot(axis), -half, half))
		for t in ts_here:
			var placed := false
			for g: Array in groups:
				if absf(float(g[0]) - t) < SAME_SUPPORT:
					if not (g[1] as Array).has(s):
						(g[1] as Array).append(s)
					placed = true
					break
			if not placed:
				groups.append([t, [s]])
	groups.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var ts: Array[float] = []
	for g: Array in groups:
		ts.append(g[0])
	# A rafter meeting its partner at the ridge is held up there too (the pair is a truss); its
	# load still comes down at the wall.
	var virtual_top := m.kind == &"rafter" and _has_partner(m, structure, gone)
	var top_t := 0.0
	if virtual_top:
		top_t = half if (axis.y >= 0.0) else -half
		ts.append(top_t)
		ts.sort()
	var result := beam(length, w_self, points, ts)
	var reactions: Array = result.reactions
	for i in ts.size():
		var r: float = reactions[i]
		var gi := -1
		for j in groups.size():
			if absf(float(groups[j][0]) - ts[i]) < 0.0001:
				gi = j
		if gi < 0:
			# The virtual ridge support: its share comes down through the nearest real support.
			gi = 0 if absf(float(groups[0][0]) - ts[i]) < absf(float(groups[-1][0]) - ts[i]) else groups.size() - 1
		var ids: Array = groups[gi][1]
		for s: StringName in ids:
			point_loads.get_or_add(s, []).append([m.support_points.get(s, origin), r / ids.size()])
	if not m.kind in BENDING_KINDS:
		return
	var w := tuning.wood(m.wood)
	var dims := m.cross_section()
	var capacity: float = float(w.bending) * dims.x * dims.y * dims.y / 6.0 * m.section_left(tuning)
	var one_support := ts.size() == 1
	if one_support:
		capacity = minf(capacity, tuning.joint_moment)
	utilisation[m.member_id] = float(result.moment) / maxf(capacity, 0.01)
	mode[m.member_id] = &"joint" if one_support else &"bending"
	var lift := float(result.uplift) / tuning.joint_uplift
	if lift > utilisation[m.member_id]:
		utilisation[m.member_id] = lift
		mode[m.member_id] = &"joint"
	critical_t[m.member_id] = m.weakest_t(result.at)


func _has_partner(m: StructureMember, structure: Structure, gone: Dictionary) -> bool:
	for id in m.touching:
		if gone.has(id):
			continue
		var o := structure.get_member(id)
		if o != null and o.kind == &"rafter" and not o.axis().is_equal_approx(m.axis()):
			return true
	return false


## A beam along t in [-length/2, length/2] with its own weight `w` (N/m), point loads
## [[t, N]...] and supports at `supports` (sorted t). Spans between supports are treated as simply
## supported, overhangs as cantilevers. Returns {reactions: Array[float] per support,
## moment: the largest bending moment (N·m), at: t where it is, uplift: the pull (N) a support
## needs to hold an overhang from tipping the member up off it}.
static func beam(length: float, w: float, points: Array, supports: Array[float]) -> Dictionary:
	var half := length * 0.5
	var n := supports.size()
	var reactions: Array[float] = []
	reactions.resize(n)
	reactions.fill(0.0)
	if n == 0:
		return {"reactions": reactions, "moment": 0.0, "at": 0.0, "uplift": 0.0}
	var total := w * length
	for p: Array in points:
		total += float(p[1])
	var s0: float = supports[0]
	var s1: float = supports[n - 1]
	# Overhangs: everything beyond the end supports hangs off them as a cantilever.
	var left := w * pow(s0 + half, 2.0) * 0.5
	var right := w * pow(half - s1, 2.0) * 0.5
	for p: Array in points:
		var t: float = p[0]
		if t < s0:
			left += float(p[1]) * (s0 - t)
		elif t > s1:
			right += float(p[1]) * (t - s1)
	var worst := maxf(left, right)
	var at := s0 if left >= right else s1
	if n == 1:
		reactions[0] = total
		return {"reactions": reactions, "moment": worst, "at": at, "uplift": 0.0}
	# An overhang tips the member about its end support; what's on the span behind holds it down,
	# and if that's not enough the next support has to hold it down by its nails.
	var uplift := 0.0
	for side in 2:
		var pivot: float = s0 if side == 0 else s1
		var back: float = supports[1] if side == 0 else supports[n - 2]
		var l := absf(back - pivot)
		if l < 1e-6:
			continue
		var over := left if side == 0 else right
		var counter := w * l * l * 0.5
		for p: Array in points:
			var t: float = p[0]
			if (side == 0 and t > pivot and t <= back) or (side == 1 and t < pivot and t >= back):
				counter += float(p[1]) * absf(t - pivot)
		uplift = maxf(uplift, (over - counter) / l)
	reactions[0] += w * (s0 + half)
	reactions[n - 1] += w * (half - s1)
	for p: Array in points:
		var t: float = p[0]
		if t < s0:
			reactions[0] += float(p[1])
		elif t > s1:
			reactions[n - 1] += float(p[1])
	# Spans between supports, each simply supported.
	for i in n - 1:
		var a: float = supports[i]
		var b: float = supports[i + 1]
		var l := b - a
		var in_span := func(t: float) -> bool: return t >= a and (t < b or (i == n - 2 and t <= b))
		if l < 1e-6:
			for p: Array in points:
				if in_span.call(float(p[0])):
					reactions[i] += float(p[1])
			continue
		var m := w * l * l / 8.0
		reactions[i] += w * l * 0.5
		reactions[i + 1] += w * l * 0.5
		for p: Array in points:
			var t: float = p[0]
			if in_span.call(t):
				var pn: float = p[1]
				m += pn * (t - a) * (b - t) / l
				reactions[i] += pn * (b - t) / l
				reactions[i + 1] += pn * (t - a) / l
		if m > worst:
			worst = m
			at = (a + b) * 0.5
	return {"reactions": reactions, "moment": worst, "at": at, "uplift": uplift}
