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
## What each member handed down last time, id -> [[support id, where (structure space), N], ...],
## and the same the other way up, support id -> {contributor id -> [[where, N], ...]}: the loads a
## member gets from above, kept between runs for the members `begin_update` doesn't work out again.
var _delivered := {}
var _received := {}


func _init(t: TimberTuning = null) -> void:
	tuning = t if t != null else load_tuning()


static func load_tuning() -> TimberTuning:
	return load("res://config/timber.tres")


func analyse(structure: Structure, extra_broken := {}) -> StructuralAnalysis:
	begin(structure, extra_broken)
	advance(_sorted.size())
	return self


# The members' records (LoadRecord), one for each of `_sorted`, copied a slice at a time on the main
# thread (`prepare`), so `advance` reads no Node and can run on a worker (`run_async`, more-cores
# step 8): an analysis's numbers are the records', worked out by the members' own methods.
var _recs: Array = []
var _prepared := 0
## The worker's task while it's working the rest out (-1: none).
var _task := -1


## Copy the next `count` members' records (the structure's, taken again where they've changed).
## True when every one is ready.
func prepare(count: int) -> bool:
	_structure.wait_analysis()  # (another analysis of it on a worker reads the records)
	var to := mini(_prepared + count, _sorted.size())
	if _recs.size() != _sorted.size():
		_recs.resize(_sorted.size())
	for i in range(_prepared, to):
		var m := _sorted[i]
		_recs[i] = _structure.load_record(m) if is_instance_valid(m) else null
	_prepared = to
	return _prepared >= _sorted.size()


## How many members' records are still to copy.
func unprepared() -> int:
	return _sorted.size() - _prepared


## The rest of the analysis on a worker (every record prepared first). Its numbers are read only
## after `wait()`; the structure waits for it before anything else touches this analysis or its
## records (Structure.wait_analysis).
func run_async() -> void:
	assert(_prepared >= _sorted.size() and _task < 0)
	# High priority (issue #392: a low-priority task queued at quit can hang the game).
	_task = WorkerThreadPool.add_task(_run_rest, true, "structural analysis")


func _run_rest() -> void:
	_advance(_recs.size() - _next)


## Done with the worker (blocks till it is).
func wait() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func busy() -> bool:
	return _task >= 0


# An analysis can also be done a slice at a time (`begin`, then `advance` until it says it's
# done: FireSystem checks burning buildings that way, so a big one isn't one long frame).
var _structure: Structure
var _gone := {}
var _sorted: Array[StructureMember] = []
var _next := 0
## The last begin_update's seeds and the members it works (for the labs).
var last_seeds := 0
var last_set := 0


## Set up: what's broken and what's fallen, the members top-down, nothing worked out yet.
func begin(structure: Structure, extra_broken := {}) -> void:
	structure.wait_analysis()
	_structure = structure
	var broken := extra_broken.duplicate()
	for m in structure.get_members():
		if m.broken:
			broken[m.member_id] = true
	falling = structure.members_without_load_path(broken)
	_gone = broken.duplicate()
	for id in falling:
		_gone[id] = true
	# Top-down: the structure's stack order (sorted once) the other way round.
	_sorted.clear()
	var up := structure.by_stack()
	for i in range(up.size() - 1, -1, -1):
		if not _gone.has(up[i].member_id):
			_sorted.append(up[i])
	load.clear()
	utilisation.clear()
	mode.clear()
	critical_t.clear()
	_delivered.clear()
	_received.clear()
	ground_load = 0.0
	_next = 0
	_recs.clear()
	_prepared = 0
	structure.records_all_stale()  # from the top: every member's record taken again


## The analysis brought up to date after a change, instead of done again from the top (`advance`
## finishes it, as after `begin`): only the members whose loads can have changed are worked out
## again. `dirty` (id -> true) is what changed since the last run: a member broken (snapped,
## dropped, cut, burnt away, shattered), one whose weight or strength changed (char, a hole, a man
## sitting on it), one that lost the ground under it, or one newly added (a cut's ends). A member's
## load comes only from what rests on it, so a change spreads downward through the supports, and
## what has lost its last support falls, and what rested on that with it, upward. Everything else
## keeps last time's loads. (A blast in the spec saloon settled in 64 rounds of all 5,150 members,
## 10 s on one frame, 2026-10-25; a round of this is the few dozen near the damage.) False when it
## can't: no run of this structure yet, or a dirty member has been freed.
func begin_update(structure: Structure, dirty: Dictionary) -> bool:
	if _structure != structure or _structure == null:
		return false
	var t_seeds := Prof.start()
	var seeds := {}
	var newly_gone: Array[StringName] = []
	# A run left unfinished (a slice a frame, then something gave way): its remainder is done again.
	for i in range(_next, _sorted.size()):
		var m := _sorted[i]
		if is_instance_valid(m) and not _gone.has(m.member_id):
			seeds[m.member_id] = true
	for id: StringName in dirty:
		var m := structure.get_member(id)
		if m == null:
			return false
		if m.broken:
			if _gone.has(id):
				falling.erase(id)  # dropped since it was found falling
			else:
				_gone[id] = true
				newly_gone.append(id)
			seeds.erase(id)
			for n in m.touching:
				if not _gone.has(n):
					seeds[n] = true
		else:
			seeds[id] = true
	# What has lost its last support falls, and what rested on it with it, upward: the dirty
	# members themselves (the ground dug from under one) and what rested on the newly gone.
	var queue: Array[StringName] = newly_gone.duplicate()
	for id: StringName in seeds.keys():
		var m := structure.get_member(id)
		if m != null and not m.grounded and not _held(m):
			_fall(structure, id, seeds, queue)
	while not queue.is_empty():
		var g: StringName = queue.pop_back()
		var gm := structure.get_member(g)
		if gm == null:
			continue
		for d: StringName in gm.dependents:
			if _gone.has(d):
				continue
			var dm := structure.get_member(d)
			if dm == null:
				continue
			if dm.broken:
				_gone[d] = true  # broken behind the structure's back: gone all the same
				continue
			if not dm.grounded and not _held(dm):
				_fall(structure, d, seeds, queue)
	Prof.stop(&"bu_seeds", t_seeds)
	var t_closure := Prof.start()
	# Down through the supports: everything the seeds hand their load to.
	var set := {}
	var stack: Array = seeds.keys()
	while not stack.is_empty():
		var id: StringName = stack.pop_back()
		if set.has(id) or _gone.has(id):
			continue
		var m := structure.get_member(id)
		if m == null or m.broken:
			continue
		set[id] = true
		for sup in m.supported_by:
			if not _gone.has(sup) and not set.has(sup):
				stack.append(sup)
	Prof.stop(&"bu_closure", t_closure)
	var t_forget := Prof.start()
	# Those gone take their numbers (and what they handed down) with them; those to do again start
	# clean, their loads from above kept but for what the set itself hands down, worked out afresh.
	for id: StringName in newly_gone:
		_forget(id, structure.get_member(id))
		_received.erase(id)
	for id: StringName in falling:
		_forget(id, structure.get_member(id))
		_received.erase(id)
	# Top-down, as the whole is (a member's supports always come lower in the stack).
	_sorted.clear()
	for id: StringName in set:
		var m := structure.get_member(id)
		_sorted.append(m)
		_forget(id, m)
	Prof.stop(&"bu_forget", t_forget)
	_sorted.sort_custom(func(a: StructureMember, b: StructureMember) -> bool: return a.stack_key > b.stack_key)
	last_set = set.size()
	last_seeds = seeds.size()
	_next = 0
	_recs.clear()
	_prepared = 0
	return true


## Has `m` a support still standing?
func _held(m: StructureMember) -> bool:
	for s in m.supported_by:
		if not _gone.has(s):
			return true
	return false


func _fall(structure: Structure, id: StringName, seeds: Dictionary, queue: Array[StringName]) -> void:
	_gone[id] = true
	falling.append(id)
	queue.append(id)
	seeds.erase(id)
	var m := structure.get_member(id)
	if m == null:
		return
	for n in m.touching:
		if not _gone.has(n):
			seeds[n] = true


## A member's numbers out of the tables (gone, or about to be worked out again), and what it
## handed down out of its supports' loads.
## (What it handed down comes off its supports as it's worked out again, in `advance`: a gone
## member's supports are gone with it or worked out again themselves, and a support worked out
## again reads only the live members' loads.)
func _forget(id: StringName, m: StructureMember) -> void:
	if m != null and m.grounded:
		ground_load -= float(load.get(id, 0.0))
	load.erase(id)
	utilisation.erase(id)
	mode.erase(id)
	critical_t.erase(id)
	_delivered.erase(id)


## Work out the next `count` members (top-down), their records copied first. True when they're
## all done. (Main thread; the worker's is `_advance`.)
func advance(count: int) -> bool:
	var to := mini(_next + count, _sorted.size())
	if _prepared < to:
		prepare(to - _prepared)
	return _advance(count)


## The next `count` members worked out from their records: no Node read.
func _advance(count: int) -> bool:
	var gone := _gone
	var to := mini(_next + count, _recs.size())
	for i in range(_next, to):
		var m: LoadRecord = _recs[i]
		if m == null:
			continue  # freed
		var loads: Array = []
		var from_above: Variant = _received.get(m.member_id)
		if from_above != null:
			for c: StringName in from_above:
				if not gone.has(c):  # a gone member's last loads are still listed; they don't count
					loads.append_array((from_above as Dictionary)[c])
		var total := m.weight + m.extra_load
		for pl: Array in loads:
			total += float(pl[1])
		load[m.member_id] = total
		var supports: Array[StringName] = []
		for s in m.supported_by:
			if not gone.has(s):
				supports.append(s)
				# Last pass's loads from this member off the support, before this pass's go on.
				var onto: Variant = _received.get(s)
				if onto != null:
					(onto as Dictionary).erase(m.member_id)
		if m.grounded:
			ground_load += total
			if m.compression and m.upright:
				_check_compression(m, total)
			continue
		if supports.is_empty():
			continue  # can't happen: it would be falling
		if m.upright:
			if m.compression:
				_check_compression(m, total)
			var share := total / supports.size()
			for s in supports:
				_deliver(m, s, m.support_points.get(s, m.origin), share)
		else:
			_bend(m, loads, supports, gone)
	_next = to
	return _next >= _recs.size()


## How many members are still to do (0 when it's done).
func left() -> int:
	return _sorted.size() - _next


## `m` hands `newtons` down onto its support `s` at `at` (structure space): onto s's loads from
## above (by contributor, so `begin_update` can take m's back), and on m's own list of what it gave.
func _deliver(m: LoadRecord, s: StringName, at: Vector3, newtons: float) -> void:
	var onto: Variant = _received.get(s)
	if onto == null:
		_received[s] = {m.member_id: [[at, newtons]]}
	else:
		var mine: Variant = (onto as Dictionary).get(m.member_id)
		if mine == null:
			(onto as Dictionary)[m.member_id] = [[at, newtons]]
		else:
			(mine as Array).append([at, newtons])
	var list: Variant = _delivered.get(m.member_id)
	if list == null:
		_delivered[m.member_id] = [[s, at, newtons]]
	else:
		(list as Array).append([s, at, newtons])


## Is anything overloaded? Returns the ids over capacity, worst first (two worked as hard, to a
## part in a billion, by their ids: the same one first whichever way the loads were summed).
func overloaded() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in utilisation:
		if utilisation[id] > 1.0:
			out.append(id)
	out.sort_custom(func(a: StringName, b: StringName) -> bool:
		var ua := roundi(float(utilisation[a]) * 1e9)
		var ub := roundi(float(utilisation[b]) * 1e9)
		return ua > ub if ua != ub else String(a) < String(b))
	return out


## (Its capacity, crushing or buckling, worked out with its record: LoadRecord.take.)
func _check_compression(m: LoadRecord, force: float) -> void:
	utilisation[m.member_id] = force / maxf(m.c_capacity, 1.0)
	mode[m.member_id] = m.c_mode
	critical_t[m.member_id] = m.weakest()


## A lying member: loads along it, supports under it, bending over each span.
## What doesn't change while a member stands, worked out once and kept on it (an analysis runs
## every second on a burning building): its axis and length, where along it it bears on each
## support, and for a rafter the rafters it meets at the ridge. Redone if it's moved or resized;
## Structure.infer_supports() clears it.
static func geometry_of(m: StructureMember, structure: Structure) -> Dictionary:
	var c: Dictionary = m.analysis_cache
	if not c.is_empty() and c.transform == m.transform and c.size == m.size:
		return c
	var length := m.length()
	var half := length * 0.5
	var axis := m.axis()
	var origin := m.transform.origin
	var support_t := {}
	for s in m.supported_by:
		# Where along the member it bears on this support: a point, or both ends of a long
		# contact (lying along a beam, a plank on a sleeper it crosses at an angle...).
		var ts_here: Array[float] = []
		var box: Variant = m.support_boxes.get(s)
		if box is AABB:
			var lo := INF
			var hi := -INF
			for k in 8:
				var t := ((box as AABB).get_endpoint(k) - origin).dot(axis)
				lo = minf(lo, t)
				hi = maxf(hi, t)
			lo = clampf(lo, -half, half)
			hi = clampf(hi, -half, half)
			ts_here.append((lo + hi) * 0.5)
			if hi - lo > 0.1:
				ts_here = [lo, hi]
		else:
			ts_here.append(clampf(((m.support_points.get(s, origin) as Vector3) - origin).dot(axis), -half, half))
		support_t[s] = ts_here
	var partners: Array[StringName] = []
	if m.kind == &"rafter":
		for id in m.touching:
			var o := structure.get_member(id)
			if o != null and o.kind == &"rafter" and not o.axis().is_equal_approx(axis):
				partners.append(id)
	c = {"transform": m.transform, "size": m.size, "length": length, "half": half, "axis": axis,
			"origin": origin, "support_t": support_t, "partners": partners}
	m.analysis_cache = c
	return c


func _bend(m: LoadRecord, loads: Array, supports: Array[StringName], gone: Dictionary) -> void:
	var geo := m.geo
	var length: float = geo.length
	var half: float = geo.half
	var axis: Vector3 = geo.axis
	var origin: Vector3 = geo.origin
	var w_self := (m.weight) / maxf(length, 0.01)
	var points: Array = []  # [t, newtons]
	for pl: Array in loads:
		points.append([clampf(((pl[0] as Vector3) - origin).dot(axis), -half, half), float(pl[1])])
	if m.extra_load > 0.0:
		points.append([0.0, m.extra_load])
	# Supports grouped by where they are along the member: the same every time while none has
	# gone (kept with its geometry), worked out afresh when one has.
	var groups: Array
	if supports.size() == m.supported_by.size():
		if not geo.has("groups"):
			geo.groups = _group(supports, geo.support_t)
		groups = geo.groups
	else:
		groups = _group(supports, geo.support_t)
	var ts: Array[float] = []
	for g: Array in groups:
		ts.append(g[0])
	# A rafter meeting its partner at the ridge is held up there too (the pair is a truss); its
	# load still comes down at the wall.
	var virtual_top := false
	for id: StringName in geo.partners:
		if not gone.has(id):
			virtual_top = true
			break
	var top_t := 0.0
	if virtual_top:
		top_t = half if (axis.y >= 0.0) else -half
		ts.append(top_t)
		ts.sort()
	var result := beam(length, w_self, points, ts)
	var reactions: Array = result.reactions
	# Both in order along the member, and groups are at least SAME_SUPPORT apart, so at most one
	# matches each t: walk them together.
	var j := 0
	for i in ts.size():
		var r: float = reactions[i]
		while j < groups.size() and float(groups[j][0]) < ts[i] - 0.0001:
			j += 1
		var gi := j if j < groups.size() and absf(float(groups[j][0]) - ts[i]) < 0.0001 else -1
		if gi < 0:
			# The virtual ridge support: its share comes down through the nearest real support.
			gi = 0 if absf(float(groups[0][0]) - ts[i]) < absf(float(groups[-1][0]) - ts[i]) else groups.size() - 1
		var ids: Array = groups[gi][1]
		var each := r / ids.size()
		for s: StringName in ids:
			_deliver(m, s, m.support_points.get(s, origin), each)
	if not m.bending:
		return
	var capacity: float = m.b_capacity
	var one_support := ts.size() == 1
	if one_support:
		capacity = minf(capacity, tuning.joint_moment)
	utilisation[m.member_id] = float(result.moment) / maxf(capacity, 0.01)
	mode[m.member_id] = &"joint" if one_support else &"bending"
	var lift := float(result.uplift) / tuning.joint_uplift
	if lift > utilisation[m.member_id]:
		utilisation[m.member_id] = lift
		mode[m.member_id] = &"joint"
	critical_t[m.member_id] = m.weakest(result.at)


## Supports (in order) grouped by where they bear along the member, within SAME_SUPPORT of the
## first in each group; sorted along it. [[t, [ids]], ...]: read-only once made (it's kept).
static func _group(supports: Array[StringName], support_t: Dictionary) -> Array:
	var groups: Array = []
	for s in supports:
		for t: float in support_t[s]:
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
	return groups


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
		# A point load belongs to the span it's in (the last span takes its end support too).
		var last := i == n - 2
		if l < 1e-6:
			for p: Array in points:
				var t: float = p[0]
				if t >= a and (t < b or (last and t <= b)):
					reactions[i] += float(p[1])
			continue
		var m := w * l * l / 8.0
		reactions[i] += w * l * 0.5
		reactions[i + 1] += w * l * 0.5
		for p: Array in points:
			var t: float = p[0]
			if t >= a and (t < b or (last and t <= b)):
				var pn: float = p[1]
				m += pn * (t - a) * (b - t) / l
				reactions[i] += pn * (b - t) / l
				reactions[i + 1] += pn * (t - a) / l
		if m > worst:
			worst = m
			at = (a + b) * 0.5
	return {"reactions": reactions, "moment": worst, "at": at, "uplift": uplift}
