class_name Dents
extends RefCounted
## Dents in iron plate and steel (issue #770, Sean's "dents OK" on #784): a member marked to dent
## (a kit member's `"plate": true`, the Baron's coach's 28 plates; or any member given the meta
## `dents`, the train's steel later) is pushed in by the energy a blow puts into it, its mesh rebuilt
## dense from the member's own box and pushed into a smooth dish or a trough along what struck it.
## Each dent is kept on the member (`dents` meta, member space: where, along what, how wide, how
## deep), saved (`state`/`restore`), and past `tear_depth` the plate tears off its rivets.
##
## The rule (DentTuning, config/dents.tres): depth = sqrt(E / (pi x yield x thickness)); dents in
## the same place add their energies (sqrt of the sum of squares of their depths). What finds the
## blows and their energy is Dents.Watch (contacts on watched bodies) and the ball's hook
## (`bullet_hit`, its spent energy times `ball_share`).

static var tuning: DentTuning


static func t() -> DentTuning:
	if tuning == null:
		tuning = load("res://config/dents.tres")
	return tuning


## How deep (m) `joules` into a plate `thickness` thick dents it.
static func depth_for(joules: float, thickness: float, dt: DentTuning = null) -> float:
	dt = dt if dt else t()
	return sqrt(maxf(joules, 0.0) / (PI * dt.yield_pa * maxf(thickness, 1e-4)))


## The energy (J) a dent `depth` deep took.
static func joules_for(depth: float, thickness: float, dt: DentTuning = null) -> float:
	dt = dt if dt else t()
	return PI * dt.yield_pa * thickness * depth * depth


## Whether a member takes dents.
static func can_dent(m: StructureMember) -> bool:
	if m == null or not is_instance_valid(m):
		return false
	if m.has_meta(&"dents_marked"):
		return true
	var spec: Dictionary = m.get_meta(&"kit", {})
	return bool(spec.get("plate", false)) or bool(spec.get("dents", false))


## Mark any member to take dents (the train's steel: a tender's side, the cab).
static func mark(m: StructureMember) -> void:
	m.set_meta(&"dents_marked", true)


## A plate's thickness: its thinnest side.
static func thickness(m: StructureMember) -> float:
	return minf(m.size.x, minf(m.size.y, m.size.z))


static func _thin_axis(size: Vector3) -> int:
	return 0 if size.x <= size.y and size.x <= size.z else (1 if size.y <= size.z else 2)


## The dents on a member (member space).
static func on(m: StructureMember) -> Array:
	return m.get_meta(&"dents", [])


## The deepest dent on it (m).
static func deepest(m: StructureMember) -> float:
	var d := 0.0
	for r: Dictionary in on(m):
		d = maxf(d, float(r.d))
	return d


## Dent `m` with `joules` (already its share: what goes into the plate) at `at` (world), the blow
## going `push` (world, into the plate), `radius` wide (m), along `along` (world; a log's line) for
## `length` m (0: a round dish). Returns {"depth": its depth after, "torn": bool, "dent": record} or
## {} if too light to show.
static func dent(m: StructureMember, at: Vector3, joules: float, push: Vector3, radius := -1.0,
		along := Vector3.ZERO, length := 0.0) -> Dictionary:
	if not can_dent(m) or m.has_meta(&"dent_torn"):
		return {}
	var dt := t()
	var mi := mesh_of(m)
	var frame := mi.global_transform if mi else m.global_transform
	var inv := frame.affine_inverse()
	var k := _thin_axis(m.size)
	var local_at := inv * at
	local_at[k] = 0.0
	# Inside the plate (a contact a hair off its edge counts at the edge).
	local_at = local_at.clamp(-m.size * 0.5, m.size * 0.5)
	var local_push := inv.basis * push
	var sgn := -1.0 if local_push[k] < 0.0 else 1.0
	var ax := Vector3.ZERO
	if length > 0.0 and along.length() > 1e-4:
		ax = inv.basis * along
		ax[k] = 0.0
		ax = ax.normalized() if ax.length() > 1e-4 else Vector3.ZERO
	var r := radius if radius > 0.0 else dt.default_radius
	var t_m := thickness(m)
	var d := depth_for(joules, t_m, dt)
	var list: Array = on(m).duplicate(true)
	# Near one already there on the same side, its energy adds to that one.
	var merged := false
	var record := {}
	for rec: Dictionary in list:
		if int(rec.s) != int(sgn):
			continue
		var c := _v(rec.c)
		if c.distance_to(local_at) <= dt.merge_within * maxf(float(rec.r), r) + float(rec.len) * 0.5:
			var e_old := joules_for(float(rec.d), t_m, dt)
			var e_sum := e_old + joules
			rec.c = _a(c.lerp(local_at, joules / maxf(e_sum, 1e-6)))
			rec.d = depth_for(e_sum, t_m, dt)
			rec.r = maxf(float(rec.r), r)
			if float(rec.len) < length and ax != Vector3.ZERO:
				rec.len = length
				rec.ax = _a(ax)
			merged = true
			record = rec
			break
	if not merged:
		if d < dt.least_depth:
			return {}
		record = {"c": _a(local_at), "ax": _a(ax), "len": length if ax != Vector3.ZERO else 0.0, "r": r, "d": d, "s": int(sgn)}
		list.append(record)
	m.set_meta(&"dents", list)
	var deepest_now := float(record.d)
	var torn := deepest_now >= dt.tear_depth
	rebuild(m)
	if torn:
		tear(m, push)
	return {"depth": deepest_now, "torn": torn, "dent": record}


## The plate comes off its rivets: standing, its structure breaks it out; loose (in a rubble body),
## its piece leaves the body as one of its own.
static func tear(m: StructureMember, push := Vector3.ZERO) -> void:
	if m.has_meta(&"dent_torn"):
		return
	m.set_meta(&"dent_torn", true)
	var s := m.get_parent() as Structure
	if not m.broken and s:
		s.break_member(m, push.normalized() * 2.0 if push.length() > 1e-4 else Vector3.ZERO)
		return
	var rb := _body_of(m)
	if rb == null:
		return
	var parts: Array[Node3D] = []
	for c in rb.get_children():
		if c.get_meta(&"member", &"") == m.member_id and (c is MeshInstance3D or c is CollisionShape3D):
			parts.append(c as Node3D)
	if parts.is_empty():
		return
	var piece := RigidBody3D.new()
	piece.name = "TornPlate"
	piece.collision_layer = rb.collision_layer
	piece.collision_mask = rb.collision_mask
	piece.mass = maxf(m.size.x * m.size.y * m.size.z * 7600.0, 0.5)
	rb.get_parent().add_child(piece)
	piece.global_transform = rb.global_transform
	for c in parts:
		c.reparent(piece, true)
	rb.mass = maxf(rb.mass - piece.mass, 1.0)
	piece.linear_velocity = rb.linear_velocity + (push.normalized() * 1.5 if push.length() > 1e-4 else Vector3.ZERO)
	piece.angular_velocity = rb.angular_velocity
	piece.add_to_group(&"rubble")
	if s:
		s.rubble.append(piece)


## Its mesh node, wherever it is: standing, its own (out of its structure's batch); loose, the one
## carried in its rubble body (tagged with its id, Structure._drop).
static func mesh_of(m: StructureMember) -> MeshInstance3D:
	if not m.broken:
		var s := m.get_parent() as Structure
		if s:
			s.unbatch(m)
		return m.drawn_node()
	var rb := _body_of(m)
	if rb:
		for c in rb.get_children():
			if c is MeshInstance3D and c.get_meta(&"member", &"") == m.member_id:
				return c
	return null


static func _body_of(m: StructureMember) -> RigidBody3D:
	var s := m.get_parent() as Structure
	if s == null:
		return null
	for rb in s.rubble:
		if is_instance_valid(rb) and m.member_id in (rb.get_meta(&"members", []) as Array):
			return rb
	return null


## The member of `s` whose shape is `shape_index` of `rb` (a rubble body), if it's one that dents.
static func member_of_shape(s: Structure, rb: RigidBody3D, shape_index: int) -> StructureMember:
	var owner := rb.shape_find_owner(shape_index)
	var node := rb.shape_owner_get_owner(owner) as Node
	if node == null:
		return null
	var id: StringName = node.get_meta(&"member", &"")
	return s.members.get(id) if id != &"" else null


## Its mesh rebuilt from its box with every dent pushed in: both faces in squares of `cell`, its
## edges between them; the material it had kept.
static func rebuild(m: StructureMember) -> void:
	var mi := mesh_of(m)
	if mi == null:
		return
	mi.mesh = dented_mesh(m.size, on(m), t().cell)


## The plate's box (centred, member space) in squares of `cell`, its faces pushed along the thin
## axis by the dents. UVs in metres along its two long sides.
static func dented_mesh(size: Vector3, dents: Array, cell := 0.025) -> ArrayMesh:
	var k := _thin_axis(size)
	var a := (k + 1) % 3
	var b := (k + 2) % 3
	if size[a] < size[b]:
		var sw := a
		a = b
		b = sw
	var na := clampi(ceili(size[a] / cell), 1, 96)
	var nb := clampi(ceili(size[b] / cell), 1, 96)
	var push := PackedFloat32Array()
	push.resize((na + 1) * (nb + 1))
	var dl := t().tear_depth
	for j in nb + 1:
		for i in na + 1:
			var p := Vector3.ZERO
			p[a] = -size[a] * 0.5 + size[a] * i / na
			p[b] = -size[b] * 0.5 + size[b] * j / nb
			push[j * (na + 1) + i] = clampf(_push_at(p, k, dents), -dl, dl)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid := func(i: int, j: int, side: float) -> Vector3:
		var p := Vector3.ZERO
		p[a] = -size[a] * 0.5 + size[a] * i / na
		p[b] = -size[b] * 0.5 + size[b] * j / nb
		p[k] = side * size[k] * 0.5 + push[j * (na + 1) + i]
		return p
	var uv := func(p: Vector3) -> Vector2:
		return Vector2(p[a], p[b])
	st.set_smooth_group(0)
	for side in [1.0, -1.0]:
		var n := Vector3.ZERO
		n[k] = side
		for j in nb:
			for i in na:
				var p00: Vector3 = grid.call(i, j, side)
				var p10: Vector3 = grid.call(i + 1, j, side)
				var p01: Vector3 = grid.call(i, j + 1, side)
				var p11: Vector3 = grid.call(i + 1, j + 1, side)
				_tri(st, p00, p10, p11, n, uv)
				_tri(st, p00, p11, p01, n, uv)
	# The edges: flat strips between the two faces.
	st.set_smooth_group(0xFFFFFFFF)
	for edge in 4:
		var count := na if edge < 2 else nb
		var n := Vector3.ZERO
		if edge < 2:
			n[b] = -1.0 if edge == 0 else 1.0
		else:
			n[a] = -1.0 if edge == 2 else 1.0
		for s in count:
			var i0: int
			var j0: int
			var i1: int
			var j1: int
			if edge < 2:
				j0 = 0 if edge == 0 else nb
				j1 = j0
				i0 = s
				i1 = s + 1
			else:
				i0 = 0 if edge == 2 else na
				i1 = i0
				j0 = s
				j1 = s + 1
			var t0: Vector3 = grid.call(i0, j0, 1.0)
			var t1: Vector3 = grid.call(i1, j1, 1.0)
			var b0: Vector3 = grid.call(i0, j0, -1.0)
			var b1: Vector3 = grid.call(i1, j1, -1.0)
			_tri(st, t0, t1, b1, n, uv)
			_tri(st, t0, b1, b0, n, uv)
	st.index()
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


## How far (m, along the thin axis, signed) the dents push a point of the plate's middle plane.
static func _push_at(p: Vector3, k: int, dents: Array) -> float:
	var out := 0.0
	for rec: Dictionary in dents:
		var c := _v(rec.c)
		var ax := _v(rec.ax)
		var half := float(rec.len) * 0.5
		var q := p - c
		q[k] = 0.0
		if ax != Vector3.ZERO and half > 0.0:
			var along := clampf(q.dot(ax), -half, half)
			q -= ax * along
		var s := q.length()
		var r := float(rec.r)
		if s < r:
			out += float(rec.s) * float(rec.d) * 0.5 * (1.0 + cos(PI * s / r))
	return out


static func _tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, want: Vector3, uv: Callable) -> void:
	var n := (p1 - p0).cross(p2 - p0)
	var order := [p0, p1, p2]
	# Godot's front faces wind clockwise seen from outside: the cross product points in.
	if n.dot(want) > 0.0:
		order = [p0, p2, p1]
	for p: Vector3 in order:
		st.set_uv(uv.call(p))
		st.add_vertex(p)


# --- Saved ---------------------------------------------------------------------------------------

## Every dent and torn plate of a structure, by member id.
static func state(s: Structure) -> Dictionary:
	var out := {}
	for id: StringName in s.members:
		var m: StructureMember = s.members[id]
		if m.has_meta(&"dents") or m.has_meta(&"dent_torn"):
			out[String(id)] = {"dents": on(m).duplicate(true), "torn": m.has_meta(&"dent_torn")}
	return out


## Put back what `state` saved (the structure built as authored: its torn plates break out again).
static func restore(s: Structure, d: Dictionary) -> void:
	for id: String in d:
		var m: StructureMember = s.members.get(StringName(id))
		if m == null:
			continue
		var rec: Dictionary = d[id]
		m.set_meta(&"dents", (rec.get("dents", []) as Array).duplicate(true))
		rebuild(m)
		if bool(rec.get("torn", false)):
			tear(m)


static func _a(v: Vector3) -> Array:
	return [snappedf(v.x, 1e-4), snappedf(v.y, 1e-4), snappedf(v.z, 1e-4)]


static func _v(a: Variant) -> Vector3:
	return Vector3(a[0], a[1], a[2]) if a is Array else (a as Vector3)
