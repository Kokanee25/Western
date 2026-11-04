class_name MasonryStructure
extends Structure
## A masonry structure: its elements (stones, blocks, adobes, brick clumps, footings) as members,
## built from a masonry structure file's expanded form (config/destruction/structures/FORMAT.md;
## MasonryExpander), and the mortar joints between them as data (MasonryWall). The masonry lab's
## step 2 (docs/briefs/masonry-lab.md): a charge breaks joints (MasonryBlast, from Blast.detonate),
## not stones; what it frees flies; what's left stands or falls by StructuralAnalysis's masonry
## check (spec section 6, S1 bearing and S2 bond; the arch rule is step 3's).
##
## A member's `wood` is its material id; it's drawn in the game's stone (`look`). Its supports come
## from the file's `rests_on` (no `infer_supports`: n² for ~300 stones), its `touching` from its
## joints. Members still bonded fall together; a broken joint lets them part.

## The file it's built from (set before it enters the tree), and that file's joints' state.
var spec: Dictionary = {}
var wall: MasonryWall
## How each element is drawn (`look`): the game's stone.
var drawn_as := &"stone"
var _members: Array[StructureMember] = []  # by element index
var _index_of := {}  # member id -> element index
## Per element: its bed on each support (member id -> Vector2(t0, t1) along it from its middle).
var _beds: Array[Dictionary] = []
var _blast_rng := RandomNumberGenerator.new()


static func from_file(path: String, id := &"") -> MasonryStructure:
	var s := MasonryStructure.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	s.spec = parsed if parsed is Dictionary else {}
	s.structure_id = id if id != &"" else StringName(s.spec.get("id", "masonry"))
	s.name = String(s.structure_id)
	return s


func _ready() -> void:
	add_to_group(&"masonry")
	super()


func build() -> void:
	wall = MasonryWall.from_spec(spec)
	_members.clear()
	_index_of.clear()
	var joint := 0.03
	for i in wall.count():
		var mat := MasonryMaterials.material(wall.materials[i])
		joint = float(mat.get("joint_thickness", 0.03))
		var basis := Basis(Vector3.UP, deg_to_rad(wall.turn[i]))
		var m := add_member(String(wall.ids[i]), wall.kinds[i], wall.materials[i], wall.size[i], wall.at[i], basis)
		m.look = drawn_as
		var mi := m.drawn_node()
		if mi != null and wall.kinds[i] != &"footing":
			mi.mesh = stone_mesh(wall.size[i], joint, hash(wall.ids[i]))
		_members.append(m)
		_index_of[m.member_id] = i


## The supports from the file (`rests_on`), not from geometry; `touching` from the joints.
func infer_supports() -> void:
	invalidate_analysis()
	_by_stack.clear()
	_beds.clear()
	for m in _members:
		m.supported_by.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.dependents.clear()
		m.analysis_cache = {}
	for i in wall.count():
		var m := _members[i]
		var beds := {}
		m.grounded = false
		m.stack_key = float(wall.course[i]) * 10.0 + wall.at[i].y
		var box := m.structure_aabb()
		for s: int in wall.rests_on[i]:
			if s < 0:
				m.grounded = true
				continue
			var o := _members[s]
			var contact := box.grow(CONTACT_EPSILON).intersection(o.structure_aabb())
			m.supported_by.append(o.member_id)
			o.dependents.append(m.member_id)
			m.support_points[o.member_id] = contact.get_center()
			m.support_boxes[o.member_id] = contact
			# Its bed on that support, along it (from its middle): what bearing it has there.
			var axis := m.transform.basis.x.normalized()
			var t0 := INF
			var t1 := -INF
			for k in 8:
				var t := (contact.get_endpoint(k) - m.transform.origin).dot(axis)
				t0 = minf(t0, t)
				t1 = maxf(t1, t)
			var half := wall.size[i].x * 0.5
			beds[o.member_id] = Vector2(clampf(t0, -half, half), clampf(t1, -half, half))
		_beds.append(beds)
	for j in wall.ja.size():
		var a := _members[wall.ja[j]]
		var b := _members[wall.jb[j]]
		a.touching.append(b.member_id)
		b.touching.append(a.member_id)


## What StructuralAnalysis reads of a masonry member (LoadRecord.take): its axis along the wall,
## its half-length, its bed on each support, and each bonded bed and head joint's moment (S2:
## tension x b x d² / 6, b the joint's width through the wall, d its length in the bending's
## direction) with the element on its other side.
func masonry_record(m: StructureMember, r: LoadRecord) -> void:
	var i: int = _index_of.get(m.member_id, -1)
	if i < 0:
		return
	r.masonry = true
	r.axis = m.transform.basis.x.normalized()
	r.half = wall.size[i].x * 0.5
	r.beds = _beds[i].duplicate()
	r.min_share = MasonryMaterials.dial("min_bearing_share", 0.25)
	var bond: Array = []
	for j in wall.of[i]:
		if wall.bonded[j] == 0 or wall.jtype[j] == MasonryWall.Joint.COLLAR:
			continue
		var o := wall.other(j, i)
		var area := wall.jarea[j]
		var depth := minf(wall.size[i].z, wall.size[o].z)
		var d := area / maxf(depth, 0.01)  # the joint's length (along for a bed, high for a head)
		bond.append([_members[o].member_id, wall.jtension[j] * depth * d * d / 6.0])
	r.bond = bond


## Overloaded masonry gives way all at once (a round of the settle): each loses its joints and
## falls on its own, not snapped as timber is.
func _gives_way(over: Array[StringName], changed: Array[StringName]) -> bool:
	var drop: Array[StringName] = []
	for id in over:
		if _index_of.has(id):
			drop.append(id)
			if drop.size() >= DROP_PER_ROUND:
				break
	if drop.is_empty():
		return false
	for id in drop:
		_unbond(_index_of[id])
	changed.append_array(_drop(drop, DROP_PER_ROUND))
	return true


## What falls with it: what it's still mortared to (a clump), not everything it touches.
func _clump_with(id: StringName) -> Array[StringName]:
	var i: int = _index_of.get(id, -1)
	if i < 0:
		return super(id)
	var out: Array[StringName] = []
	for j in wall.of[i]:
		if wall.bonded[j] == 1:
			out.append(_members[wall.other(j, i)].member_id)
	return out


## Its joints all broken (it's leaving the wall): what it was bonded to is worked out again.
func _unbond(i: int) -> void:
	for j in wall.of[i]:
		if wall.bonded[j] == 1:
			wall.bonded[j] = 0
			mark_dirty(_members[wall.other(j, i)].member_id)
	mark_dirty(_members[i].member_id)


## A charge `at` (world) of `kg` (TNT, the ground counted): MasonryBlast's rules, then what it
## frees thrown (a cracked unit in two), the joints it broke broken, and the rest settled. The ids
## of what it freed.
func take_blast(at: Vector3, kg: float) -> Array[StringName]:
	var out: Array[StringName] = []
	if not collapses or wall == null:
		return out
	var t_s := Prof.start()
	var local := global_transform.affine_inverse() * at
	var standing := {}
	for i in wall.count():
		if not _members[i].broken:
			standing[i] = true
	var res := MasonryBlast.strike(wall, local, kg, standing, Blast.t().max_throw)
	last_blast = res
	for j: int in res.broke:
		wall.bonded[j] = 0
		mark_dirty(_members[wall.ja[j]].member_id)
		mark_dirty(_members[wall.jb[j]].member_id)
	_blast_rng.seed = hash(Vector3i((at * 1000.0).round())) ^ hash(structure_id)
	var cracked := {}
	for i in res.cracked:
		cracked[i] = true
	var freed: Array = res.freed.keys()
	freed.sort()
	_wakes = []
	for i: int in freed:
		var m := _members[i]
		if m.broken:
			continue
		_unbond(i)
		_fling(m, global_basis * (res.freed[i] as Vector3), cracked.has(i))
		out.append(m.member_id)
	_wake_near_all(_wakes)
	_wakes = null
	Prof.stop(&"masonry_blast", t_s)
	if not res.broke.is_empty() or not out.is_empty():
		var t_set := Prof.start()
		out.append_array(settle(SETTLE_FRAME_MS, true))
		Prof.stop(&"blast_settle", t_set)
	return out


## The last blast's result (MasonryBlast.strike's), for the lab.
var last_blast := {}


## A freed element thrown at `v` (world), spinning; `split`: cracked, in two halves along it.
func _fling(m: StructureMember, v: Vector3, split: bool) -> void:
	unbatch(m, false, true)
	m.broken = true
	mark_dirty(m.member_id)
	var at_m := m.global_transform
	var mass := m.weight(tuning) / 9.81
	var parts := m.take_parts()
	var bodies: Array[RigidBody3D] = []
	if not split:
		var rb := _new_rubble([m.member_id], false)
		rb.transform = _rubble_host_space(at_m)
		for c in parts:
			rb.add_child(c)  # (their places on the member are their places on the body)
		rb.mass = maxf(mass, 0.3)
		bodies.append(rb)
	else:
		for c in parts:
			c.queue_free()
		for side in 2:
			var half := m.size
			half.x *= 0.5
			var off := Vector3((side - 0.5) * half.x, 0.0, 0.0)
			var rb := _new_rubble([m.member_id], false)
			rb.transform = _rubble_host_space(at_m * Transform3D(Basis(), off))
			var mi := MeshInstance3D.new()
			mi.mesh = stone_mesh(half, 0.03, hash(m.member_id) + side)
			mi.material_override = WoodMaterials.get_material(m.drawn_wood(), hash(m.member_id))
			rb.add_child(mi)
			var cs := CollisionShape3D.new()
			cs.shape = _box_shape(half)
			rb.add_child(cs)
			rb.mass = maxf(mass * 0.5, 0.2)
			bodies.append(rb)
	for rb in bodies:
		_enter_rubble(rb)
		var spread := Vector3(_blast_rng.randf_range(-1, 1), _blast_rng.randf_range(-0.5, 1), _blast_rng.randf_range(-1, 1)) * 0.15
		rb.linear_velocity = v * (1.0 + spread.y * 0.3) + spread * v.length()
		rb.angular_velocity = Vector3(_blast_rng.randf_range(-1, 1), _blast_rng.randf_range(-1, 1), _blast_rng.randf_range(-1, 1)) * minf(v.length(), 12.0)
	if _wakes is Array:
		_wakes.append([m.global_position, 1.0])
	else:
		_wake_near(m.global_position, 1.0)
	Events.member_broken.emit(m.member_id)


func _rubble_host_space(xf: Transform3D) -> Transform3D:
	var host := _rubble_host() as Node3D
	return host.global_transform.affine_inverse() * xf if host else xf


## A rough stone: its box with both faces' edges chamfered by about half a joint (the mortar's
## groove between stones, so a wall reads as stones without a mortar mesh behind), the faces'
## corners nudged a little by `seed`. Drawn as MemberMesh's boxes are (UVs in metres, face sizes in
## UV2), so it batches and carves the same.
static func stone_mesh(size: Vector3, joint: float, seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var h := size * 0.5
	var c := minf(joint * 0.6, minf(h.x, minf(h.y, h.z)) * 0.4)
	# Rings at each face (z = ±h.z, inset by c) and where the chamfer meets the sides (z = ±(h.z - c)).
	var ring := func(z: float, inset: float, nudge: float) -> Array[Vector3]:
		var r: Array[Vector3] = []
		for k in 4:
			var sx := -1.0 if k == 0 or k == 3 else 1.0
			var sy := -1.0 if k < 2 else 1.0
			var dx := rng.randf_range(-nudge, nudge)
			var dy := rng.randf_range(-nudge, nudge)
			r.append(Vector3(sx * (h.x - inset) + dx, sy * (h.y - inset) + dy, z))
		return r
	var nudge := c * 0.5
	var f_in: Array[Vector3] = ring.call(-h.z, c, nudge)
	var f_out: Array[Vector3] = ring.call(-h.z + c, 0.0, 0.0)
	var b_in: Array[Vector3] = ring.call(h.z, c, nudge)
	var b_out: Array[Vector3] = ring.call(h.z - c, 0.0, 0.0)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var idx := PackedInt32Array()
	var quad := func(q: Array[Vector3]) -> void:
		# Its normal out from the middle (the stone's convex: its centre is inside), and its
		# triangles wound clockwise seen from outside (Godot's front face).
		var g := (q[1] - q[0]).cross(q[2] - q[0])
		var mid := (q[0] + q[1] + q[2] + q[3]) * 0.25
		if g.dot(mid) > 0.0:
			q = [q[0], q[3], q[2], q[1]] as Array[Vector3]
			g = -g
		var n := -g.normalized()
		var an := n.abs()
		var u_axis := 0 if an.x < 0.5 else 2
		var v_axis := 1 if an.y < 0.5 else 2
		var base := verts.size()
		for p in q:
			verts.append(p)
			normals.append(n)
			uvs.append(Vector2(p[u_axis] + h[u_axis], p[v_axis] + h[v_axis]))
			uv2.append(Vector2(size[u_axis], size[v_axis]))
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	quad.call([f_in[0], f_in[3], f_in[2], f_in[1]] as Array[Vector3])  # the face toward -z
	quad.call([b_in[0], b_in[1], b_in[2], b_in[3]] as Array[Vector3])  # +z
	for k in 4:
		var k1 := (k + 1) % 4
		quad.call([f_in[k], f_in[k1], f_out[k1], f_out[k]] as Array[Vector3])  # front chamfers
		quad.call([f_out[k], f_out[k1], b_out[k1], b_out[k]] as Array[Vector3])  # the sides
		quad.call([b_out[k], b_out[k1], b_in[k1], b_in[k]] as Array[Vector3])  # back chamfers
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_INDEX] = idx
	return MemberMesh.made(arrays)


## The wall as it stands, for the lab: elements standing, fallen, joints broken.
func report() -> Dictionary:
	var standing := 0
	for m in _members:
		if not m.broken:
			standing += 1
	var broken_j := 0
	for b in wall.bonded:
		if b == 0:
			broken_j += 1
	return {"elements": wall.count(), "standing": standing, "fallen": wall.count() - standing,
		"joints": wall.ja.size(), "joints_broken": broken_j, "rubble": rubble.size()}


func element(i: int) -> StructureMember:
	return _members[i]


func index_of(id: StringName) -> int:
	return _index_of.get(id, -1)
