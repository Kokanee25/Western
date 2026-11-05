class_name TrackChunk
extends Structure
## A stretch of the railroad's track as members (train step 5, #616; docs/briefs/train.md): its
## wooden ties and iron rails, about TrackLine.CHUNK long and always a whole number of rails, so
## its ends are rail joints. Any building's rules: a ball carves a tie, a charge splinters it, a
## fire (where the fire reaches) burns it. The rails are iron: they never snap or shatter. A blast
## that would break one tears it loose whole off its spikes (`tear_loose`: it flies as one piece of
## rubble), and one too weak for that may still bend it (`bend`: drawn bowed, the line bent there).
## A rail whose ties are gone under it hangs on its joints (the track's state calls a long enough
## run of them broken).
##
## At rest as a building's members are (Structure.rest_batched): its ties and rails drawn in a
## batch a material, each member its body alone, nothing ticking. The links are known from the
## line (a rail rests on the ties under it), so the support graph isn't searched for (a chunk's
## ~190 members by pairs were ~36,000 box tests).
##
## Space: the TrackLine's (the chunk sits at its origin). `from_s`, `to_s`: the stretch of the line.

var line: TrackLine
var train_tuning: TrainTuning
var index := 0
var from_s := 0.0
var to_s := 0.0
## The ties along it: [member, s].
var ties: Array = []
## The rails: [{member, side (-1 left, +1 right, looking toward the line's end), a, b (s)}].
var rails: Array = []
## Rail id -> how far it's bowed out (m), for the drawn rail and the track's state.
var bent := {}

const TIE_WOOD := &"framing"
## Iron (the box's iron weighs about twice a 35 lb/yd rail's: what its spikes and joint bars add
## to tearing it out is in that).
const RAIL_WOOD := &"iron"
## Rails meet with this gap at a joint (m).
const JOINT_GAP := 0.006


func setup(on_line: TrackLine, t: TrainTuning, n: int, a: float, b: float) -> void:
	line = on_line
	train_tuning = t
	index = n
	from_s = a
	to_s = b
	structure_id = StringName("track%02d" % n)
	name = "Track%02d" % n
	build_seed = 616 + n


func _ready() -> void:
	super._ready()
	Events.exploded.connect(_on_exploded)


## The ballast holds the ties, not the ground under it (a crater dug beside the line isn't under them).
func _on_ground_changed(_area: Rect2) -> void:
	pass


func build() -> void:
	ties.clear()
	rails.clear()
	bent.clear()
	if line == null:
		return
	var t := train_tuning
	var rh := t.rail_size.y
	# Ties at whole multiples of the spacing along the line (their ids by it, so a tie is the same
	# tie whichever chunk builds it).
	var k := int(ceil(from_s / t.tie_spacing - 1e-6))
	while k * t.tie_spacing < to_s - 1e-6 and k * t.tie_spacing <= line.length:
		var s := k * t.tie_spacing
		var f := line.transform_at(s)
		var centre := f.origin + f.basis.y * (-rh - t.tie_size.y * 0.5)
		var m := add_member("tie/%05d" % k, &"tie", TIE_WOOD, t.tie_size, centre, f.basis)
		ties.append([m, s])
		k += 1
	# Rails: each side from the chunk's start, a rail length each (the last may be short).
	var a := from_s
	var j := 0
	while a < to_s - 0.05:
		var b := minf(a + t.rail_length, to_s)
		for side in [-1, 1]:
			var x: float = side * (t.gauge * 0.5 + t.rail_size.x * 0.5)
			var m := _add_rail("rail/%s/%02d" % ["l" if side < 0 else "r", j], x, a, b)
			rails.append({"member": m, "side": side, "a": a, "b": b})
		a = b
		j += 1


func _rail_point(x: float, s: float) -> Vector3:
	return line.transform_at(s) * Vector3(x, -train_tuning.rail_size.y * 0.5, 0.0)


func _add_rail(id_path: String, x: float, a: float, b: float) -> StructureMember:
	var t := train_tuning
	var p0 := _rail_point(x, a + JOINT_GAP * 0.5)
	var p1 := _rail_point(x, b - JOINT_GAP * 0.5)
	var up := (line.transform_at(a).basis.y + line.transform_at(b).basis.y).normalized()
	var basis := Basis.looking_at(p1 - p0, up)
	var size := Vector3(t.rail_size.x, t.rail_size.y, p0.distance_to(p1))
	var m := add_member(id_path, &"rail", RAIL_WOOD, size, (p0 + p1) * 0.5, basis)
	m.set_meta(&"rail_x", x)
	m.set_meta(&"rail_s", Vector2(a, b))
	# Drawn along the curve (the box is its chord: 9 cm off at the middle on a 120 m bend).
	(m.get_child(0) as MeshInstance3D).mesh = _rail_mesh(m, 0.0)
	return m


## A rail's mesh in its own space: swept along the line between its ends, bowed `bow` m out to
## its own side at the middle (a bent rail).
func _rail_mesh(m: StructureMember, bow: float) -> ArrayMesh:
	var t := train_tuning
	var x: float = m.get_meta(&"rail_x")
	var ab: Vector2 = m.get_meta(&"rail_s")
	var a := ab.x + JOINT_GAP * 0.5
	var b := ab.y - JOINT_GAP * 0.5
	var hw := t.rail_size.x * 0.5
	var rh := t.rail_size.y
	var prof := [Vector2(-hw, -rh), Vector2(-hw, 0.0), Vector2(hw, 0.0), Vector2(hw, -rh), Vector2(-hw, -rh)]
	var inv := m.transform.affine_inverse()
	var steps := maxi(2, int(ceil((b - a) / 1.0)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := []
	for i in steps + 1:
		var u := float(i) / steps
		var s := lerpf(a, b, u)
		var f := line.transform_at(s)
		var off := x + signf(x) * bow * sin(PI * u)
		var ring := []
		for p: Vector2 in prof:
			ring.append(inv * (f * Vector3(off + p.x, p.y, 0.0)))
		rings.append(ring)
	for i in steps:
		var v0 := float(i) / steps * (b - a)
		var v1 := float(i + 1) / steps * (b - a)
		for e in prof.size() - 1:
			var q0: Vector3 = rings[i][e]
			var q1: Vector3 = rings[i][e + 1]
			var q2: Vector3 = rings[i + 1][e + 1]
			var q3: Vector3 = rings[i + 1][e]
			var u0 := float(e) * 0.07
			var u1 := float(e + 1) * 0.07
			for pv in [[q0, Vector2(u0, v0)], [q2, Vector2(u1, v1)], [q1, Vector2(u1, v0)], [q0, Vector2(u0, v0)], [q3, Vector2(u0, v1)], [q2, Vector2(u1, v1)]]:
				st.set_uv(pv[1])
				st.add_vertex(pv[0])
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


## The links are the line's: every tie on the bed, each rail on the ties under it, a rail touching
## the next at its joint (its joint bars). No search by pairs.
func infer_supports() -> void:
	invalidate_analysis()
	_by_stack.clear()
	for m in _order:
		m.supported_by.clear()
		m.dependents.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
	var t := train_tuning
	for pair: Array in ties:
		var tie: StructureMember = pair[0]
		tie.grounded = true
		tie.stack_key = tie.position.y
	var by_side := {-1: [], 1: []}
	var ti := 0
	for r: Dictionary in rails:
		var m: StructureMember = r.member
		m.grounded = false
		m.stack_key = 100.0 + m.position.y
		(by_side[r.side] as Array).append(m)
		# The ties under it: they're in order along the line.
		while ti > 0 and float(ties[ti][1]) > float(r.a):
			ti -= 1
		for i in range(ti, ties.size()):
			var ts: float = ties[i][1]
			if ts < float(r.a) - 0.001:
				continue
			if ts > float(r.b) + 0.001:
				break
			var tie: StructureMember = ties[i][0]
			var at := line.transform_at(ts) * Vector3(float(r.side) * (t.gauge * 0.5 + t.rail_size.x * 0.5), -t.rail_size.y, 0.0)
			var half := Vector3(t.rail_size.x * 0.5, 0.01, t.tie_size.z * 0.5)
			m.supported_by.append(tie.member_id)
			tie.dependents.append(m.member_id)
			m.support_points[tie.member_id] = at
			m.support_boxes[tie.member_id] = AABB(at - half, half * 2.0)
			m.touching.append(tie.member_id)
			tie.touching.append(m.member_id)
	for side in by_side:
		var list: Array = by_side[side]
		for i in list.size() - 1:
			(list[i] as StructureMember).touching.append((list[i + 1] as StructureMember).member_id)
			(list[i + 1] as StructureMember).touching.append((list[i] as StructureMember).member_id)


## Rails don't snap: a blast (or anything) that would break one tears it loose whole; the rest
## break as any timber does.
func break_members(list: Array[StructureMember], pushes: Array[Vector3], cuts: Array = [], budget: WorkBudget = null) -> Array[StringName]:
	var keep: Array[StructureMember] = []
	var keep_push: Array[Vector3] = []
	var keep_cut := []
	var out: Array[StringName] = []
	for i in list.size():
		var m := list[i]
		var push: Vector3 = pushes[i] if i < pushes.size() else Vector3.ZERO
		if m != null and is_instance_valid(m) and m.kind == &"rail":
			out.append_array(tear_loose(m, push))
		else:
			keep.append(m)
			keep_push.append(push)
			keep_cut.append(cuts[i] if i < cuts.size() else null)
	if not keep.is_empty():
		out.append_array(super.break_members(keep, keep_push, keep_cut, budget))
	return out


func break_member(m: StructureMember, push := Vector3.ZERO) -> Array[StringName]:
	if m != null and is_instance_valid(m) and m.kind == &"rail":
		return tear_loose(m, push)
	return super.break_member(m, push)


## A rail off its spikes and out of its joint bars whole, thrown by `push` (m/s): one piece of
## rubble, bowed as it was.
func tear_loose(m: StructureMember, push := Vector3.ZERO) -> Array[StringName]:
	if m == null or not is_instance_valid(m) or m.broken or not collapses:
		return []
	var before := rubble.size()
	var ids: Array[StringName] = [m.member_id]
	var out := _drop(ids)
	if rubble.size() > before:
		var rb := rubble.back() as RigidBody3D
		if is_instance_valid(rb):
			rb.linear_velocity = push
			rb.angular_velocity = Vector3(push.z, 0.0, -push.x) * 0.15
	bent.erase(m.member_id)
	out.append_array(settle(SETTLE_FRAME_MS))
	return out


## A member as a save left it (TrackState.from_dict): a tie gone (its splinters long since lost in
## the ballast), a rail lying off the line on its own side, asleep. Nothing's thrown or heard.
func lie_loose(m: StructureMember) -> void:
	if m == null or not is_instance_valid(m) or m.broken:
		return
	var before := rubble.size()
	var ids: Array[StringName] = [m.member_id]
	var x: float = m.get_meta(&"rail_x", 0.0)
	_drop(ids)
	if rubble.size() > before:
		var rb := rubble.back() as RigidBody3D
		if m.kind == &"tie":
			rubble.erase(rb)
			rb.queue_free()
		else:
			rb.global_position += global_basis * (m.basis.x * signf(x) * 1.6 + Vector3.DOWN * 0.2)
			rb.sleeping = true
	bent.erase(m.member_id)
	settle_soon()


## Bow a standing rail `amount` m out to its side at its middle (kept if it's bowed more already).
func bend(m: StructureMember, amount: float) -> void:
	if m == null or m.broken or m.kind != &"rail":
		return
	amount = minf(amount, train_tuning.rail_bend_max)
	if amount <= float(bent.get(m.member_id, 0.0)) + 0.005:
		return
	bent[m.member_id] = amount
	unbatch(m)
	m.realise()
	(m.get_child(0) as MeshInstance3D).mesh = _rail_mesh(m, amount)
	Events.member_broken.emit(m.member_id)  # (the track's state hears it: a bent stretch)


## A charge near the line: a rail it didn't tear loose may still be bent, by how much of what
## would tear it loose the blast put into it (`rail_bend_share` of it bends it at all).
func _on_exploded(at: Vector3, kg: float) -> void:
	if not is_inside_tree() or rails.is_empty():
		return
	var local := global_transform.affine_inverse() * at
	if bounds_distance(local) > Blast.reach(kg):
		return
	var t := train_tuning
	for r: Dictionary in rails:
		var m: StructureMember = r.member
		if m.broken or not is_instance_valid(m):
			continue
		var share := Blast.rail_share(m, at, kg, tuning)
		if share > t.rail_bend_share:
			bend(m, t.rail_bend_max * clampf((share - t.rail_bend_share) / (1.0 - t.rail_bend_share), 0.0, 1.0))


## Damage as numbers by the line (for the track's state and the save): ties gone, rails gone, rails
## bent, each with its s and side.
func damage() -> Dictionary:
	var gone_ties := []
	for pair: Array in ties:
		var tie: StructureMember = pair[0]
		if not is_instance_valid(tie) or tie.broken or tie.consumed:
			gone_ties.append(float(pair[1]))
	var gone_rails := []
	var bowed := []
	for r: Dictionary in rails:
		var m: StructureMember = r.member
		if not is_instance_valid(m) or m.broken:
			gone_rails.append({"side": r.side, "a": r.a, "b": r.b})
		elif bent.has(m.member_id):
			bowed.append({"side": r.side, "a": r.a, "b": r.b, "amount": bent[m.member_id]})
	return {"ties": gone_ties, "rails": gone_rails, "bent": bowed}


## The rail on `side` over s, or null.
func rail_at(side: int, s: float) -> StructureMember:
	for r: Dictionary in rails:
		if int(r.side) == side and s >= float(r.a) and s < float(r.b) + 0.001:
			return r.member
	return null


## The tie nearest s, or null.
func tie_near(s: float) -> StructureMember:
	var best: StructureMember = null
	var d := INF
	for pair: Array in ties:
		var dd := absf(float(pair[1]) - s)
		if dd < d:
			d = dd
			best = pair[0]
	return best
