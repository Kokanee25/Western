class_name Structure
extends Node3D
## A building (or boardwalk, trough, rail) made of individual members. Subclasses describe what to
## build in build(); the structure then works out what rests on what (the support graph) from the
## members' positions and kinds.
##
## It stands or falls by StructuralAnalysis: when a member is damaged or broken, the loads are
## worked out again; anything overloaded snaps (in two, where it was weakest) and anything left
## without a load path falls. Members still nailed together fall together as one piece and break
## up when they land hard; falling timber breaks what it lands on. Rubble stays where it ends up.

## Members whose bottom is within this of y = 0 (structure space) rest on the ground.
const GROUND_EPSILON := 0.02
## Members closer than this are in contact (nailed, resting, bolted).
const CONTACT_EPSILON := 0.012

@export var structure_id: StringName = &"structure"
## Seed for any variation in the build (board gaps, tints), so rebuilding is identical.
@export var build_seed := 1
## False for fixtures that hold still whatever happens (test rigs): holes, but no breaking.
@export var collapses := true
## Draw untouched members together: one mesh per material for the whole structure (a building is
## hundreds of boards, and a draw call each, times every shadow pass, was too many for a street
## of them). A member leaves the batch for good the moment anything happens to it (a hole, heat,
## breaking): its own mesh shows again and the batch is rebuilt without it.
@export var batch_meshes := true

## StringName -> StructureMember
var members := {}

var _order: Array[StructureMember] = []
## Fallen pieces (RigidBody3D), still in the world.
var rubble: Array[RigidBody3D] = []
var tuning: TimberTuning
## The last settle's analysis, for debugging (F3 / tests).
var last_analysis: StructuralAnalysis
var _settle_pending := false
var _sound_cooldown := 0.0
var _rng := RandomNumberGenerator.new()
var _shape_cache := {}
## Material -> MeshInstance3D drawing the batched members of that material.
var _batches := {}
## StructureMember -> the Material of the batch it's drawn in.
var _batched := {}
var _batch_dirty := {}
var _by_stack: Array[StructureMember] = []  # see by_stack()
var _show_after := {}  # members unbatched `soon`: shown when their batch is rebuilt
var _rebuild_queued := false
var _rebuild_timed := false
var _last_rebuild := -INF
## The fire takes members out of a burning building's batches one at a time; rebuilding a batch
## (every member of that material in the building) each time it did was a long frame.
const BATCH_REBUILD_GAP := 0.5


func _ready() -> void:
	add_to_group(&"structures")
	tuning = StructuralAnalysis.load_tuning()
	rebuild()


func rebuild() -> void:
	_clear_batches()
	for m in _order:
		m.free()
	members.clear()
	_order.clear()
	_rng.seed = build_seed
	build()
	infer_supports()
	_batch_all()


## Override: add members with add_member().
func build() -> void:
	pass


func member_count() -> int:
	return _order.size()


func get_member(id: StringName) -> StructureMember:
	return members.get(id)


func get_members() -> Array[StructureMember]:
	return _order


func members_of_kind(kind: StringName) -> Array[StructureMember]:
	return _order.filter(func(m: StructureMember) -> bool: return m.kind == kind)


## Add one member: an axis-aligned box of `size` centred at `center` (structure space),
## optionally rotated by `basis`. `id_path` is local to this structure, e.g. "front/stud/03".
func add_member(id_path: String, kind: StringName, wood: StringName, size: Vector3, center: Vector3, basis := Basis()) -> StructureMember:
	var id := StringName("%s/%s" % [structure_id, id_path])
	assert(not members.has(id), "Duplicate member id %s" % id)
	var m := StructureMember.new()
	m.name = id_path.validate_node_name().replace("/", "_")
	m.member_id = id
	m.kind = kind
	m.wood = wood
	m.size = size
	m.transform = Transform3D(basis, center)

	var mi := MeshInstance3D.new()
	mi.mesh = _box_mesh(size)
	mi.material_override = WoodMaterials.get_material(wood, hash(id))
	m.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.shape = _box_shape(size)
	m.add_child(cs)

	add_child(m)
	m.pieces = [[mi, cs]]
	m.damaged.connect(unbatch.bind(m))
	m.damaged.connect(_on_member_damaged)
	members[id] = m
	_order.append(m)
	return m


## Work out supports from geometry: a member rests on every lower-tier member it touches.
func infer_supports() -> void:
	_by_stack.clear()
	var boxes := {}
	for m in _order:
		boxes[m] = m.structure_aabb()
	for m in _order:
		m.supported_by.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
		var box: AABB = boxes[m]
		var tier := StructureMember.tier_of(m.kind)
		m.grounded = tier <= 1 and box.position.y <= GROUND_EPSILON
		m.stack_key = tier * 100.0 + box.position.y
		var grown := box.grow(CONTACT_EPSILON)
		for other in _order:
			if other == m or not grown.intersects(boxes[other]):
				continue
			m.touching.append(other.member_id)
			var other_tier := StructureMember.tier_of(other.kind)
			var other_box: AABB = boxes[other]
			# Lower tiers hold up higher ones; the same kind stacked (timbers in a pile) rests on
			# what's underneath it.
			var beneath := other_tier == tier and other_box.end.y <= box.position.y + CONTACT_EPSILON \
					and other_box.position.y < box.position.y - CONTACT_EPSILON
			if other_tier < tier or beneath:
				m.supported_by.append(other.member_id)
				var contact := grown.intersection(boxes[other])
				m.support_points[other.member_id] = contact.get_center()
				m.support_boxes[other.member_id] = contact


## True if a chain of supports leads from this member down to the ground.
func has_load_path(id: StringName, broken := {}) -> bool:
	return not id in members_without_load_path(broken)


## Every member that would fall if the members in `broken` (id -> true) were gone. Supports
## always come earlier in stack order (lower tier, or the same kind lower down), so one pass
## settles it.
func members_without_load_path(broken := {}) -> Array[StringName]:
	var sorted := by_stack()
	var held := {}
	var falling: Array[StringName] = []
	for m: StructureMember in sorted:
		if broken.has(m.member_id):
			continue
		var ok := m.grounded
		if not ok:
			for s in m.supported_by:
				if held.has(s):
					ok = true
					break
		if ok:
			held[m.member_id] = true
		else:
			falling.append(m.member_id)
	return falling


## The members bottom-up (stack order, which never changes once built): sorted once, kept.
func by_stack() -> Array[StructureMember]:
	if _by_stack.size() != _order.size():
		_by_stack = _order.duplicate()
		_by_stack.sort_custom(func(a: StructureMember, b: StructureMember) -> bool: return a.stack_key < b.stack_key)
	return _by_stack


# --- Drawing members together ---------------------------------------------------------------------

func _batch_all() -> void:
	_clear_batches()
	if not batch_meshes:
		return
	var groups := {}
	for m in _order:
		var mi := m.get_child(0) as MeshInstance3D
		# Glass stays its own (see-through, no shadow); so does anything already hidden (a sign
		# member under its painted board) or drawn its own way.
		if mi == null or not mi.visible or m.kind == &"glass" or mi.material_override == null \
				or mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON or mi.material_overlay != null:
			continue
		var mat := mi.material_override
		if not groups.has(mat):
			groups[mat] = []
		(groups[mat] as Array).append(m)
		_batched[m] = mat
		mi.visible = false
	for mat in groups:
		_build_batch(mat)


func _build_batch(mat: Material) -> void:
	var old: MeshInstance3D = _batches.get(mat)
	var st := SurfaceTool.new()
	var any := false
	for m: StructureMember in _batched:
		if _batched[m] != mat:
			continue
		var mi := m.get_child(0) as MeshInstance3D
		st.append_from(mi.mesh, 0, m.transform * mi.transform)
		any = true
	if not any:
		if old:
			old.queue_free()
		_batches.erase(mat)
		return
	var mesh := st.commit()
	if old == null:
		old = MeshInstance3D.new()
		old.name = "Batch"
		old.material_override = mat
		add_child(old, false, Node.INTERNAL_MODE_BACK)
		_batches[mat] = old
	old.mesh = mesh


## Draw this member on its own from now on (something's happened to it). `soon` (the fire's
## heating, a member at a time all over a burning building): its batch is rebuilt without it at
## most every BATCH_REBUILD_GAP, and it's shown then, not drawn twice meanwhile.
func unbatch(m: StructureMember, soon := false) -> void:
	if not _batched.has(m):
		return
	var mat: Material = _batched[m]
	_batched.erase(m)
	_batch_dirty[mat] = true
	var mi := m.get_child(0) as MeshInstance3D
	if soon:
		_show_after[m] = true
		if not _rebuild_timed and not _rebuild_queued and is_inside_tree():
			_rebuild_timed = true
			var wait := maxf(_last_rebuild + BATCH_REBUILD_GAP - Time.get_ticks_msec() / 1000.0, 0.0)
			get_tree().create_timer(wait, true, true).timeout.connect(_rebuild_dirty_batches)
		return
	if mi:
		mi.visible = true
	if not _rebuild_queued:
		_rebuild_queued = true
		_rebuild_dirty_batches.call_deferred()


func _rebuild_dirty_batches() -> void:
	_rebuild_queued = false
	_rebuild_timed = false
	if not is_inside_tree() and _batch_dirty.is_empty():
		return
	for mat in _batch_dirty:
		_build_batch(mat)
	_batch_dirty.clear()
	for m: Variant in _show_after:
		if is_instance_valid(m) and (m as StructureMember).get_child_count() > 0:
			var mi := (m as StructureMember).get_child(0) as MeshInstance3D
			if mi and not (m as StructureMember).consumed:
				mi.visible = true
	_show_after.clear()
	_last_rebuild = Time.get_ticks_msec() / 1000.0


func _clear_batches() -> void:
	for mat in _batches:
		var mi: MeshInstance3D = _batches[mat]
		if is_instance_valid(mi):
			mi.free()
	_batches.clear()
	_batched.clear()
	_batch_dirty.clear()
	_show_after.clear()


## How many draw calls its intact members take (tests, F3).
func batch_count() -> int:
	return _batches.size()


# --- Standing and falling -----------------------------------------------------------------------

func _on_member_damaged() -> void:
	settle_soon()


## Settle soon, once however many times it's asked: in a world with a FireSystem it works
## through it a slice of the building a frame (a big collapse was seconds on one frame); else at
## the end of this frame.
func settle_soon() -> void:
	var fire := FireSystem.find(get_tree()) if is_inside_tree() else null
	if fire and fire.queue_settle(self):
		return
	if not _settle_pending:
		_settle_pending = true
		settle.call_deferred()


## Work out the loads again and let whatever can't stand break or fall, until it's stable.
## Returns the ids that broke or fell.
func settle() -> Array[StringName]:
	_settle_pending = false
	var changed: Array[StringName] = []
	if not collapses or not is_inside_tree():
		return changed
	for round_ in 64:
		var a := StructuralAnalysis.new(tuning).analyse(self)
		if not apply_round(a, changed):
			break
	return changed


## One round of settling from an analysis of it as it stands: the worst overloaded member snaps,
## else what has no load path falls. True if something did (another round is due). FireSystem
## runs a burning building's rounds this way, an analysis spread over frames.
func apply_round(a: StructuralAnalysis, changed: Array[StringName] = []) -> bool:
	last_analysis = a
	var over := a.overloaded()
	if not over.is_empty():
		# The worst goes first; the rest may be fine once the loads find new paths.
		var m := get_member(over[0])
		_snap(m, float(a.critical_t.get(m.member_id, 0.0)))
		changed.append(m.member_id)
		return true
	if a.falling.is_empty():
		return false
	_drop(a.falling)
	changed.append_array(a.falling)
	return true


## Break a member outright (an axe, dynamite, the debug key): it falls and the rest settles.
func break_member(m: StructureMember, push := Vector3.ZERO) -> Array[StringName]:
	if m == null or m.broken or not is_instance_valid(m) or not collapses:
		return []
	if m.kind == &"glass":
		m.shatter(m.global_position, push.normalized() if push.length() > 0.01 else Vector3.DOWN)
		return [m.member_id]
	_snap(m, m.weakest_t(), push)
	var out: Array[StringName] = [m.member_id]
	out.append_array(settle())
	return out


## Break several members at once (a blast), each thrown by its own push, then settle once.
func break_members(list: Array[StructureMember], pushes: Array[Vector3]) -> Array[StringName]:
	var out: Array[StringName] = []
	if not collapses:
		return out
	for i in list.size():
		var m := list[i]
		if m == null or not is_instance_valid(m) or m.broken:
			continue
		var push: Vector3 = pushes[i] if i < pushes.size() else Vector3.ZERO
		if m.kind == &"glass":
			m.shatter(m.global_position, push.normalized() if push.length() > 0.01 else Vector3.DOWN)
		else:
			# Where the blast hit it, if it says; else where it's weakest.
			_snap(m, float(m.get_meta(&"blast_t", m.weakest_t())), push)
		out.append(m.member_id)
	out.append_array(settle())
	return out


## An overloaded member snaps at `t` along its length into two falling pieces (short ones just
## fall whole).
func _snap(m: StructureMember, t: float, push := Vector3.ZERO) -> void:
	unbatch(m)
	m.broken = true
	var length := m.length()
	var ai := m.axis_index()
	var mi := m.get_child(0) as MeshInstance3D
	var cs := m.get_child(1) as CollisionShape3D
	var new_pieces: Array = []
	if length < 0.4 or absf(t) > length * 0.5 - 0.1:
		var rb := _new_rubble([m.member_id])
		rb.global_transform = m.global_transform
		mi.reparent(rb, true)
		cs.reparent(rb, true)
		rb.mass = maxf(m.weight(tuning) / 9.81, 0.3)
		rb.linear_velocity = push
	else:
		var cut := t + length * 0.5  # from the member's start
		for side in 2:
			var piece_len := cut if side == 0 else length - cut
			var piece_size := m.size
			piece_size[ai] = piece_len
			var offset := Vector3.ZERO
			offset[ai] = (-length * 0.5 + piece_len * 0.5) if side == 0 else (length * 0.5 - piece_len * 0.5)
			var rb := _new_rubble([m.member_id])
			rb.global_transform = m.global_transform * Transform3D(Basis(), offset)
			var kick := Vector3(_rng.randf_range(-1, 1), 0.0, _rng.randf_range(-1, 1)).normalized()
			if m.is_upright() and side == 1:
				# The top of a snapped post kicks out past the stump and topples.
				var width := minf(m.cross_section().x, m.cross_section().y)
				rb.global_position += kick * width * 0.7 + Vector3.UP * 0.01
				rb.global_basis = Basis(Vector3(kick.z, 0.0, -kick.x), deg_to_rad(10.0)) * rb.global_basis
			var pmi := MeshInstance3D.new()
			pmi.mesh = MemberMesh.box(piece_size)
			pmi.material_override = WoodMaterials.get_material(m.wood, hash(m.member_id))
			rb.add_child(pmi)
			var pcs := CollisionShape3D.new()
			pcs.shape = _box_shape(piece_size)
			rb.add_child(pcs)
			new_pieces.append([pmi, pcs])
			rb.mass = maxf(m.weight(tuning) / 9.81 * piece_len / length, 0.2)
			# The two halves fold down about the break, never tidily: a snapped post doesn't stay
			# stacked on its own stump.
			kick *= 0.6
			rb.linear_velocity = push + kick * (0.3 if side == 0 else 1.0)
			rb.angular_velocity = m.global_basis.x.cross(Vector3.UP) * (0.4 if side == 0 else -0.4) \
					+ Vector3(kick.z, 0.0, -kick.x) * 1.5
			rb.set_meta(&"start_v", rb.linear_velocity)
		mi.queue_free()
		cs.queue_free()
		m.pieces = new_pieces
		m.set_meta(&"snapped", true)
	_wake_near(m.global_position, m.length() + 2.0)
	_play(&"timber_crack", m.global_position)
	Events.member_broken.emit(m.member_id)


## Members with nothing holding them up fall; those still touching each other fall together as
## one piece.
func _drop(ids: Array[StringName]) -> void:
	var left := {}
	for id in ids:
		left[id] = true
	while not left.is_empty():
		var start: StringName = left.keys()[0]
		var clump: Array[StringName] = []
		var stack: Array[StringName] = [start]
		left.erase(start)
		while not stack.is_empty():
			var id: StringName = stack.pop_back()
			clump.append(id)
			for n in get_member(id).touching:
				if left.has(n):
					left.erase(n)
					stack.append(n)
		var rb := _new_rubble(clump)
		var first := get_member(clump[0])
		rb.global_transform = Transform3D(Basis(), first.global_position)
		var mass := 0.0
		for id in clump:
			var m := get_member(id)
			unbatch(m)
			m.broken = true
			mass += m.weight(tuning) / 9.81
			for c in m.get_children():
				if c is MeshInstance3D or c is CollisionShape3D:
					c.reparent(rb, true)
			Events.member_broken.emit(id)
		rb.mass = maxf(mass, 0.3)
		_wake_near(rb.global_position, 6.0)


## Rubble asleep near something that just gave way wakes up (it may have been resting on it).
func _wake_near(at: Vector3, radius: float) -> void:
	for rb in rubble:
		if is_instance_valid(rb) and rb.global_position.distance_to(at) < radius:
			rb.sleeping = false
	_rewake.call_deferred(at, radius)


func _rewake(at: Vector3, radius: float) -> void:
	for rb in rubble:
		if is_instance_valid(rb) and rb.global_position.distance_to(at) < radius:
			rb.sleeping = false
			var v: Vector3 = rb.get_meta(&"start_v", Vector3.ZERO)
			if v != Vector3.ZERO and rb.linear_velocity.is_zero_approx():
				rb.linear_velocity = v
			rb.remove_meta(&"start_v")


func _new_rubble(ids: Array[StringName]) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.name = "Rubble"
	rb.collision_layer = Layers.WORLD
	rb.collision_mask = Layers.WORLD | Layers.PEOPLE | Layers.BODY_PARTS
	rb.contact_monitor = true
	rb.max_contacts_reported = 4
	rb.continuous_cd = true
	rb.set_meta(&"members", ids)
	var pm := PhysicsMaterial.new()
	pm.friction = 0.8
	pm.bounce = 0.05
	rb.physics_material_override = pm
	rb.add_to_group(&"rubble")
	var host: Node = get_parent() if get_parent() else self
	host.add_child(rb)
	rb.body_entered.connect(_on_rubble_hit.bind(rb))
	rubble.append(rb)
	return rb


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"structures", t)


func _physics_step(delta: float) -> void:
	_sound_cooldown = maxf(_sound_cooldown - delta, 0.0)
	for rb in rubble:
		if is_instance_valid(rb) and not rb.sleeping:
			rb.set_meta(&"v", rb.linear_velocity)


## Falling timber lands on something: hard enough and it breaks what it hits; a piece of several
## members breaks up.
func _on_rubble_hit(other: Node, rb: RigidBody3D) -> void:
	if not is_instance_valid(rb):
		return
	var v: Vector3 = rb.get_meta(&"v", rb.linear_velocity)
	var speed := v.length()
	if speed < tuning.harmless_speed:
		return
	var energy := 0.5 * rb.mass * speed * speed
	if other.has_meta(&"human_body") and energy > 5.0:
		# Timber coming down on someone: once per piece per person.
		var person: Object = other.get_meta(&"human_body")
		var hurt: Array = rb.get_meta(&"hurt", [])
		if not hurt.has(person):
			hurt.append(person)
			rb.set_meta(&"hurt", hurt)
			person.call_deferred(&"take_blow", other, energy, rb.global_position, v.normalized())
	if other is StructureMember and not (other as StructureMember).broken:
		var hit := other as StructureMember
		if energy > tuning.impact_toughness * hit.volume():
			var owner_structure := hit.get_parent() as Structure
			if owner_structure:
				owner_structure.break_member.call_deferred(hit, v * 0.3)
	if energy > 300.0 and _sound_cooldown <= 0.0:
		_sound_cooldown = 0.25
		_play(&"timber_crash", rb.global_position)
		ImpactEffects.burst(get_parent(), rb.global_position, Vector3.UP, Color(0.66, 0.56, 0.44), 18, 1.4, 0.07)
	var ids: Array = rb.get_meta(&"members", [])
	if ids.size() > 1 and speed > tuning.break_up_speed:
		_break_up.call_deferred(rb)


## A fallen piece of several members comes apart into separate members.
func _break_up(rb: RigidBody3D) -> void:
	if not is_instance_valid(rb) or rb.get_meta(&"broken_up", false):
		return
	rb.set_meta(&"broken_up", true)
	var v := rb.linear_velocity
	var w := rb.angular_velocity
	var meshes: Array[MeshInstance3D] = []
	var shapes: Array[CollisionShape3D] = []
	for c in rb.get_children():
		if c is MeshInstance3D:
			meshes.append(c)
		elif c is CollisionShape3D:
			shapes.append(c)
	var ids: Array = rb.get_meta(&"members", [])
	for i in mini(meshes.size(), shapes.size()):
		var id: StringName = ids[i] if i < ids.size() else &""
		var piece := _new_rubble([id])
		piece.global_transform = shapes[i].global_transform
		meshes[i].reparent(piece, true)
		shapes[i].reparent(piece, true)
		var m := get_member(id)
		piece.mass = maxf(m.weight(tuning) / 9.81, 0.3) if m else 1.0
		piece.linear_velocity = v + w.cross(piece.global_position - rb.global_position)
		piece.angular_velocity = w
	rubble.erase(rb)
	rb.queue_free()


func _play(id: StringName, at: Vector3) -> void:
	if not is_inside_tree():
		return
	Events.noise.emit(at, 60.0, &"timber", null)
	var p := AudioStreamPlayer3D.new()
	p.stream = SynthSounds.get_sound(id)
	p.unit_size = 10.0
	add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


## What's changed from the authored building: broken members, their holes, where the rubble lies.
func to_dict() -> Dictionary:
	var broken_ids: Array[String] = []
	var holes := {}
	for m in _order:
		if m.broken:
			broken_ids.append(String(m.member_id))
		if not m.holes.is_empty():
			holes[String(m.member_id)] = m.to_dict().holes
	var pieces := []
	for rb in rubble:
		if is_instance_valid(rb):
			var t := rb.global_transform
			pieces.append({"members": (rb.get_meta(&"members", []) as Array).map(func(x): return String(x)),
					"origin": [t.origin.x, t.origin.y, t.origin.z],
					"basis": [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z]})
	return {"id": String(structure_id), "broken": broken_ids, "holes": holes, "rubble": pieces}


func rand_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func chance(p: float) -> bool:
	return _rng.randf() < p


func _box_mesh(size: Vector3) -> Mesh:
	return MemberMesh.box(size)


func _box_shape(size: Vector3) -> BoxShape3D:
	var key := size.snappedf(0.001)
	if not _shape_cache.has(key):
		var shape := BoxShape3D.new()
		shape.size = size
		_shape_cache[key] = shape
	return _shape_cache[key]
