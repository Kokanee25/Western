class_name TrackState
extends RefCounted
## What's wrong with a line (train step 5, #616): the stretches a train can't run over.
##
##   broken   a rail gone (torn loose, cut), or a run of `ties_gone_break` ties gone under the rails;
##   bent     a rail bowed out more than `bent_passable` (a train over it faster than
##            `bent_pass_speed` leaves the rails);
##   blocked  something on the line: a crate, a wagon, rubble, a body (found by looking along it:
##            `scan`, a box over the rails every CELL metres, from just over the rail tops up).
##
## The members' damage comes from the TrackChunks (worked out again when one of theirs breaks or
## bends: `Events.member_broken`); the blocks from the scan, which whoever drives looks ahead with
## (`scan_ahead`, a few cells a tick). Every stretch carries its place on the route (`key`:
## section id and the distance along it, TrackLine.key_of), never a world position: the save keeps
## those (`to_dict`), and `from_dict` puts them back on a line built from any route that has the
## same sections (a re-laid route, #542 "The route can move").

## The blocks' scan: a box this long along the line a cell, m.
const CELL := 4.0
## What the scan doesn't count as a block: a loose thing lighter than this, kg (splinters, gravel, a hat).
const BLOCK_MIN_KG := 8.0
## A block found this long ago is still taken to be there, s (cells are looked at again round-robin).
const BLOCK_KEEP := 2.0

var line: TrackLine
var tuning: TrainTuning
## Broken and bent stretches from the members: {kind, from_s, to_s, side, what, amount, key, length}.
var stretches: Array[Dictionary] = []
## Blocks by cell index: {kind "blocked", from_s, to_s, what, kg, seen (scan time), key, length}.
var blocks := {}
## Bumped each time the stretches are worked out again (for whoever caches what's ahead).
var version := 0
var _dirty := true
var _cursor := 0
var _time := 0.0
var _box: BoxShape3D


func _init(on_line: TrackLine) -> void:
	line = on_line
	tuning = on_line.tuning if on_line.tuning else TrainTuning.new()
	Events.member_broken.connect(_on_member_broken)


func line_built() -> void:
	_dirty = true
	blocks.clear()


func _on_member_broken(id: StringName) -> void:
	if String(id).begins_with("track"):
		_dirty = true


## Every stretch (broken, bent, blocked), in order along the line.
func damage() -> Array[Dictionary]:
	if _dirty:
		_recompute()
	var out: Array[Dictionary] = stretches.duplicate()
	for k in blocks:
		var b: Dictionary = blocks[k]
		if _time - float(b.seen) <= BLOCK_KEEP:
			out.append(b)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.from_s) < float(b.from_s))
	return out


## The first stretch a train going `dir` (+1 toward the line's end) meets from `s` on, within
## `reach` m, or {}.
func first_ahead(s: float, dir: int, reach := INF) -> Dictionary:
	var best := {}
	var best_d := INF
	for st: Dictionary in damage():
		var d := (float(st.from_s) - s) if dir > 0 else (s - float(st.to_s))
		if float(st.from_s) <= s and float(st.to_s) >= s:
			d = 0.0
		if d < 0.0 or d > reach:
			continue
		if d < best_d:
			best_d = d
			best = st
	return best


## The stretch over `s`, or {} (what the wheels on `s` are on).
func at(s: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for st: Dictionary in damage():
		if float(st.from_s) <= s and float(st.to_s) >= s:
			out.append(st)
	return out


func _stretch(kind: StringName, a: float, b: float, side: int, what: String, amount := 0.0) -> Dictionary:
	return {"kind": kind, "from_s": a, "to_s": b, "side": side, "what": what, "amount": amount,
		"key": line.key_of(a), "length": b - a}


func _recompute() -> void:
	_dirty = false
	version += 1
	stretches.clear()
	var gone_ties := PackedFloat32Array()
	for c: TrackChunk in line.chunks:
		if not is_instance_valid(c):
			continue
		var d := c.damage()
		for r: Dictionary in d.rails:
			stretches.append(_stretch(&"broken", float(r.a), float(r.b), int(r.side), "rail gone"))
		for r: Dictionary in d.bent:
			if float(r.amount) >= tuning.bent_passable:
				stretches.append(_stretch(&"bent", float(r.a), float(r.b), int(r.side), "rail bent", float(r.amount)))
		for s: float in d.ties:
			gone_ties.append(s)
	gone_ties.sort()
	# Runs of ties gone (next to each other: a spacing apart).
	var i := 0
	while i < gone_ties.size():
		var j := i
		while j + 1 < gone_ties.size() and gone_ties[j + 1] - gone_ties[j] < tuning.tie_spacing * 1.5:
			j += 1
		if j - i + 1 >= tuning.ties_gone_break:
			var half := tuning.tie_spacing * 0.5
			stretches.append(_stretch(&"broken", gone_ties[i] - half, gone_ties[j] + half, 0, "%d ties gone" % (j - i + 1)))
		i = j + 1


## Look along the line for blocks: `cells` boxes of CELL m between `a` and `b` (round-robin over
## calls, so a long look ahead costs a few boxes a tick), at time `now` (s). `exclude`: the train's
## own bodies. Returns the blocks found this call.
func scan(world: World3D, a: float, b: float, cells: int, now: float, exclude: Array[RID] = []) -> Array[Dictionary]:
	_time = now
	var found: Array[Dictionary] = []
	if world == null:
		return found
	var space := world.direct_space_state
	var lo := int(floor(maxf(a, 0.0) / CELL))
	var hi := int(floor(minf(b, line.length) / CELL))
	if hi < lo:
		return found
	if _box == null:
		_box = BoxShape3D.new()
	var t := tuning
	var low := 0.04  # just over the rail tops: the ties, rails and ballast aren't blocks
	var high := 2.4
	_box.size = Vector3(t.car_width - 0.3, high - low, CELL)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _box
	q.collision_mask = Layers.WORLD | Layers.DEBRIS | Layers.RAGDOLL | Layers.BODY_PARTS | Layers.PEOPLE
	q.collide_with_areas = false
	q.exclude = exclude
	var n := hi - lo + 1
	for k in mini(cells, n):
		_cursor = (_cursor + 1) % n
		var cell := lo + _cursor
		var s := (cell + 0.5) * CELL
		var f := line.global_transform * line.transform_at(s)
		q.transform = Transform3D(f.basis, f.origin + f.basis.y * (low + (high - low) * 0.5))
		var hits := space.intersect_shape(q, 16)
		var what := ""
		var kg := 0.0
		for h: Dictionary in hits:
			var c: Object = h.collider
			if c == null or not is_instance_valid(c):
				continue
			var w := _what(c)
			if w.is_empty():
				continue
			if float(w.kg) > kg:
				kg = float(w.kg)
				what = String(w.what)
		if what != "":
			var st := _stretch(&"blocked", cell * CELL, (cell + 1) * CELL, 0, what)
			st.kg = kg
			st.seen = now
			blocks[cell] = st
			found.append(st)
		else:
			blocks.erase(cell)
	return found


## Scan the line ahead of a train: from `s` `reach` m in its direction.
func scan_ahead(world: World3D, s: float, dir: int, reach: float, cells: int, now: float, exclude: Array[RID] = []) -> Array[Dictionary]:
	return scan(world, s, s + reach, cells, now, exclude) if dir > 0 else scan(world, s - reach, s, cells, now, exclude)


## What a body on the line is, as a block: {what, kg}, or {} for what isn't one (the track, its bed,
## the train, the ground, light debris).
func _what(c: Object) -> Dictionary:
	if c.has_meta(&"train_car"):
		return {}
	if c is StructureMember:
		var host := (c as Node).get_parent()
		if host is TrackChunk or host == null:
			return {}
		var m := c as StructureMember
		return {"what": String(host.name), "kg": m.weight(load("res://config/timber.tres")) / 9.81}
	if Ground.is_ground(c):
		return {}
	if c is RigidBody3D:
		var rb := c as RigidBody3D
		var hb := _person_of(rb)
		if hb:
			return {"what": String(hb.person_id), "kg": 75.0}
		if rb.mass < BLOCK_MIN_KG:
			return {}
		var host := rb.get_parent()
		return {"what": "%s %s" % [String(host.name) if host else "", String(rb.name)], "kg": rb.mass}
	if c is CharacterBody3D:
		var hb := _person_of(c as Node)
		return {"what": String(hb.person_id) if hb else String((c as Node).name), "kg": 75.0}
	if c is StaticBody3D:
		var n := c as Node
		# The line's own bed and anything else of the track's.
		if n.get_parent() and n.get_parent().get_parent() == line:
			return {}
		var hb := _person_of(n)
		if hb:
			return {"what": String(hb.person_id), "kg": 75.0}
		return {}
	return {}


static func _person_of(n: Node) -> HumanBody:
	var p := n
	for i in 6:
		if p == null:
			return null
		if p is HumanBody:
			return p as HumanBody
		p = p.get_parent()
	return null


## The damage as the route's places, for the save: what's broken on the members (each rail gone,
## each rail bent, each tie gone) by section and distance, and the rubble's pieces placed in the
## line's frame at their section and distance.
func to_dict() -> Dictionary:
	var rails := []
	var bowed := []
	var ties := []
	for c: TrackChunk in line.chunks:
		var d := c.damage()
		for r: Dictionary in d.rails:
			rails.append({"key": line.key_of((float(r.a) + float(r.b)) * 0.5), "side": int(r.side)})
		for r: Dictionary in d.bent:
			bowed.append({"key": line.key_of((float(r.a) + float(r.b)) * 0.5), "side": int(r.side), "amount": float(r.amount)})
		for s: float in d.ties:
			ties.append({"key": line.key_of(s)})
	return {"rails": rails, "bent": bowed, "ties": ties}


## Put saved damage back on this line (built from the same route, or a re-laid one with the same
## sections): each tie and rail at its section and distance broken again where it lies (no blast,
## nothing thrown: the rubble is the wreck's to place). Returns how many it couldn't place (their
## section isn't on this route).
func from_dict(d: Dictionary) -> int:
	var missed := 0
	for r: Dictionary in d.get("rails", []):
		var s := line.s_of(r.key)
		var c := line.chunk_at(s) if not is_nan(s) else null
		var m := c.rail_at(int(r.side), s) if c else null
		if m == null:
			missed += 1
			continue
		c.lie_loose(m)
	for r: Dictionary in d.get("bent", []):
		var s := line.s_of(r.key)
		var c := line.chunk_at(s) if not is_nan(s) else null
		var m := c.rail_at(int(r.side), s) if c else null
		if m == null:
			missed += 1
			continue
		c.bend(m, float(r.amount))
	for r: Dictionary in d.get("ties", []):
		var s := line.s_of(r.key)
		var c := line.chunk_at(s) if not is_nan(s) else null
		var m := c.tie_near(s) if c else null
		if m == null:
			missed += 1
			continue
		c.lie_loose(m)
	_dirty = true
	return missed
