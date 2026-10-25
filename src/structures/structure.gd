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
## Members drawn in a batch are their bodies alone till something happens to them
## (StructureMember.rest: their mesh and shape nodes out of the tree): a building's or a kit
## prop's hundred members are a hundred nodes, not three hundred (docs/briefs/props-scale.md).
@export var rest_batched := true
## Off for every structure (`-- --no-member-rest`: the bench's before).
static var members_rest := not "--no-member-rest" in OS.get_cmdline_user_args()
## How long it has stood (years): 0 as built. Older, it shows it (BuildingAge: sagging, leaning,
## boards gone and patched, worn steps), the same way every load.
@export var age_years := 0.0

## StringName -> StructureMember
var members := {}

var _order: Array[StructureMember] = []
## Below this a fallen piece has gone through the ground and is removed (Structure._physics_step).
const LOST_BELOW := -5.0
## A cut leaves no end shorter than this (m): it goes with the stretch.
const CUT_MIN_PIECE := 0.15
## The stretch a cut tears out flies in pieces about this long (m).
const CUT_CHUNK := 0.3
## Fallen pieces (RigidBody3D), still in the world.
var rubble: Array[RigidBody3D] = []
var tuning: TimberTuning
## The last analysis of it, kept and brought up to date for what's changed since (start_analysis);
## F3 and tests read it.
var last_analysis: StructuralAnalysis
## Members changed since last_analysis (id -> true): broken, holed, charred, loaded, added, or the
## ground gone from under them. `start_analysis` works these out again, and what their loads reach.
var _dirty := {}
## last_analysis is of this support graph (false once the graph is worked out anew).
var _analysis_valid := false
## Analyses carried over and brought up to date (StructuralAnalysis.begin_update); off, every one
## is done from the top (`-- --full-analysis`: the before for the blast-freeze lab, and the check).
static var incremental := not "--full-analysis" in OS.get_cmdline_user_args()
## A settle that has run this long (ms) on one frame hands the rest to the FireSystem's slices
## (settle_soon): a blast's collapse unfolds over a few frames, not one long one (issue #374).
const SETTLE_FRAME_MS := 6.0
## A building of more members than this with no analysis yet has its first done a slice a frame
## (a budgeted settle hands it on), never on the frame that broke it.
const SLICED_ABOVE := 1500
## A budgeted settle with more changed members than this waiting (a blast's cuts and panes on top
## of a fire's charring) leaves them all to the FireSystem's slices, not the frame that broke them.
const SETTLE_DIRTY_NOW := 48
## An analysis in progress with more members than this still to do isn't finished on a budgeted
## settle's frame either.
const SLICE_LEFT := 300
## What falls in one round, at most (members; whole clumps): the rest the next round, so a floor
## of hundreds coming down is a few frames' rubble, not one frame's.
const DROP_PER_ROUND := 40
var _settle_pending := false
var _sound_cooldown := 0.0
var _rng := RandomNumberGenerator.new()
var _shape_cache := {}
## Material -> MeshInstance3D drawing the batched members of that material.
var _batches := {}
## StructureMember -> the Material of the batch it's drawn in.
var _batched := {}
## Material -> the members in its batch (the other way round, so a rebuild reads its own, not all).
var _batch_members := {}
## Material -> its batch's mesh arrays, kept for the shadow mesh (merged off the main thread).
var _batch_arrays := {}
var _batch_dirty := {}
## The shadow mesh (every batch merged) is built on a worker thread, at most every
## SHADOW_REBUILD_GAP: a far lamp's shadow of a fallen board lingers that long at most (it was
## 60 ms on the main thread for the spec saloon, every frame something broke, 2026-10-25).
const SHADOW_REBUILD_GAP := 1.0
var _shadow_task := -1
var _shadow_wanted := false
var _shadow_last := -INF
var _shadow_result: Array = []
## One shadow-only mesh of every batched member, for far lamps' shadows alone (Layers.VIS_WALLS):
## the batches are a material each (each wood's board strips, ~45 on the saloon), and a far lamp
## drew all of them in each of its shadow passes. The sun and near lamps still take theirs from
## the batches (from one merged mesh the sun's shadow came out a little different on thin edges
## near the camera).
var _shadow: MeshInstance3D
var _by_stack: Array[StructureMember] = []  # see by_stack()
var _show_after := {}  # members unbatched `soon`: shown when their batch is rebuilt
var _rebuild_queued := false
var _rebuild_timed := false
var _panes: Array[StructureMember] = []
var _panes_of := -1  # _order.size() when _panes was made
var _last_rebuild := -INF
## The fire takes members out of a burning building's batches one at a time; rebuilding a batch
## (every member of that material in the building) each time it did was a long frame.
const BATCH_REBUILD_GAP := 0.5
## Batches are rebuilt until this much of a frame (ms) is spent; the rest wait a frame (a fallen
## board's copy stands in its batch that frame longer: a collapse dirtied a dozen materials a frame,
## 65 ms, 2026-10-25).
const BATCH_FRAME_MS := 6.0


func _ready() -> void:
	add_to_group(&"structures")
	tuning = StructuralAnalysis.load_tuning()
	rebuild()
	Events.ground_changed.connect(_on_ground_changed)
	if _order.size() > SLICED_ABOVE:
		# A big building's first analysis now, a slice a frame (the fire's routine look), so the
		# first thing to break it finds one to carry over, not every member to work out.
		_first_look.call_deferred()


func _first_look() -> void:
	if not is_inside_tree() or _analysis_valid:
		return
	var fire := FireSystem.find(get_tree())
	if fire:
		fire.queue_check(self)


func _notification(what: int) -> void:
	# A shadow mesh still building on a worker writes to this object when it's done: not after it's gone.
	if what == NOTIFICATION_PREDELETE and _shadow_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_shadow_task)
		_shadow_task = -1


## The ground was dug (Ground, docs/briefs/dig-ground.md): a member standing on it (a post, a sill)
## whose bottom has lost the earth at all its corners and its middle is held up by the ground no
## more, and what stands on it settles.
func _on_ground_changed(area: Rect2) -> void:
	if not is_inside_tree():
		return
	var g := Ground.of(get_tree())
	if g == null:
		return
	var lost := false
	for m: StructureMember in get_members():
		if not m.grounded or m.broken:
			continue
		var box := m.world_aabb()
		var foot := Rect2(box.position.x, box.position.z, box.size.x, box.size.z)
		if not area.intersects(foot, true):
			continue
		var held := false
		for p: Vector2 in [foot.position, Vector2(foot.end.x, foot.position.y), foot.end, Vector2(foot.position.x, foot.end.y), foot.get_center()]:
			if g.height_at(p.x, p.y) > box.position.y - g.tuning.undercut:
				held = true
				break
		if not held:
			m.grounded = false
			mark_dirty(m.member_id)
			lost = true
	if lost:
		settle_soon()


func rebuild() -> void:
	_clear_batches()
	for m in _order:
		m.free()
	members.clear()
	_order.clear()
	_panes_of = -1
	_rng.seed = build_seed
	build()
	BuildingAge.alter(self)  # what the years broke and replaced: the graph is worked out with it
	infer_supports()
	BuildingAge.settle_in(self)  # how it has settled: a look, after the graph
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


## Its panes, kept (a blast looks at glass much further out than at timber: Blast.gather).
func panes() -> Array[StructureMember]:
	if _panes_of != _order.size():
		_panes = members_of_kind(&"glass")
		_panes_of = _order.size()
	return _panes


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
	m.damaged.connect(_on_member_damaged.bind(m))
	members[id] = m
	_order.append(m)
	return m


## Take a member out again before the support graph is worked out (BuildingAge: a board long gone).
func remove_built(m: StructureMember) -> void:
	invalidate_analysis()
	members.erase(m.member_id)
	_order.erase(m)
	_panes_of = -1
	m.free()


## Work out supports from geometry: a member rests on every lower-tier member it touches.
func infer_supports() -> void:
	invalidate_analysis()
	_by_stack.clear()
	var boxes := {}
	for m in _order:
		boxes[m] = m.structure_aabb()
		m.dependents.clear()  # before any linking: the others' links fill it
	for m in _order:
		m.supported_by.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
		var box: AABB = boxes[m]
		_place_in_stack(m, box)
		for other in _order:
			if other != m:
				_link(m, box, other, boxes[other])


## Where a member sits in the stack (its tier, then its height), and whether it's on the ground.
func _place_in_stack(m: StructureMember, box: AABB) -> void:
	var tier := StructureMember.tier_of(m.kind)
	m.grounded = tier <= 1 and box.position.y <= GROUND_EPSILON
	m.stack_key = tier * 100.0 + box.position.y


## `m` touching `other` (their boxes, structure space): it notes the touch, and rests on `other` if
## that's a lower tier, or the same kind stacked underneath it (timbers in a pile).
func _link(m: StructureMember, box: AABB, other: StructureMember, other_box: AABB) -> void:
	var grown := box.grow(CONTACT_EPSILON)
	if not grown.intersects(other_box):
		return
	m.touching.append(other.member_id)
	var tier := StructureMember.tier_of(m.kind)
	var other_tier := StructureMember.tier_of(other.kind)
	var beneath := other_tier == tier and other_box.end.y <= box.position.y + CONTACT_EPSILON \
			and other_box.position.y < box.position.y - CONTACT_EPSILON
	if other_tier < tier or beneath:
		m.supported_by.append(other.member_id)
		other.dependents.append(m.member_id)
		var contact := grown.intersection(other_box)
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
		var mi := m.drawn_node()
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
	_batch_members = groups
	# Unbatched members (holed, burning) are walls to a far lamp too (OilLamp).
	for m in _order:
		var own := m.get_child(0) as MeshInstance3D
		if own:
			own.layers |= Layers.VIS_WALLS
	for mat in groups:
		_build_batch(mat)
	_build_shadow()
	if rest_batched and members_rest:
		for m: StructureMember in _batched:
			m.rest()


func _build_batch(mat: Material) -> void:
	var old: MeshInstance3D = _batches.get(mat)
	var st := SurfaceTool.new()
	var any := false
	for m: StructureMember in _batch_members.get(mat, []):
		var mi := m.drawn_node()
		st.append_from(mi.mesh, 0, m.transform * mi.transform)
		any = true
	if not any:
		if old:
			old.queue_free()
		_batches.erase(mat)
		_batch_arrays.erase(mat)
		return
	var arrays := st.commit_to_arrays()
	_batch_arrays[mat] = arrays
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
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
	m.realise()
	if not _batched.has(m):
		return
	var mat: Material = _batched[m]
	_batched.erase(m)
	(_batch_members.get(mat, []) as Array).erase(m)
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
	var t := Prof.start()
	var t0 := Time.get_ticks_usec()
	for mat in _batch_dirty.keys():
		_build_batch(mat)
		_batch_dirty.erase(mat)
		if (Time.get_ticks_usec() - t0) / 1000.0 > BATCH_FRAME_MS and not _batch_dirty.is_empty():
			# The rest next frame.
			_rebuild_queued = true
			get_tree().physics_frame.connect(_rebuild_dirty_batches, CONNECT_ONE_SHOT)
			break
	Prof.stop(&"batches", t)
	_shadow_soon()
	for m: Variant in _show_after:
		if is_instance_valid(m) and (m as StructureMember).get_child_count() > 0:
			var mi := (m as StructureMember).get_child(0) as MeshInstance3D
			if mi and not (m as StructureMember).consumed:
				mi.visible = true
	_show_after.clear()
	_last_rebuild = Time.get_ticks_msec() / 1000.0


## The shadow mesh now, on this thread (the build; tests).
func _build_shadow() -> void:
	_set_shadow(_merge_batches(_batch_arrays.values()))


## One set of mesh arrays of them all (vertices, normals, indices; empty for none). Pure data, no
## rendering calls: runs on a worker (a worker asking the rendering server for a mesh's arrays
## waits on the main thread, which deadlocks the moment the main thread waits on the worker).
## The batches sit at the structure's origin, so their vertices need no moving.
static func _merge_batches(parts: Array) -> Array:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for arrays: Array in parts:
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: Variant = arrays[Mesh.ARRAY_NORMAL]
		var idx: Variant = arrays[Mesh.ARRAY_INDEX]
		var base := verts.size()
		verts.append_array(v)
		if n is PackedVector3Array:
			normals.append_array(n)
		if idx is PackedInt32Array:
			for i: int in idx:
				indices.append(i + base)
		else:
			for i in v.size():
				indices.append(base + i)
	if verts.is_empty():
		return []
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	if normals.size() == verts.size():
		out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_INDEX] = indices
	return out


func _set_shadow(arrays: Array) -> void:
	if arrays.is_empty():
		if _shadow and is_instance_valid(_shadow):
			_shadow.queue_free()
		_shadow = null
		return
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if _shadow == null or not is_instance_valid(_shadow):
		_shadow = MeshInstance3D.new()
		_shadow.name = "Shadow"
		_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		_shadow.layers = Layers.VIS_WALLS
		add_child(_shadow, false, Node.INTERNAL_MODE_BACK)
	_shadow.mesh = mesh


## The shadow mesh again, soon: on a worker thread, one at a time, at most every
## SHADOW_REBUILD_GAP; asked again meanwhile, once more when that's done.
func _shadow_soon() -> void:
	_shadow_wanted = true
	if _shadow_task >= 0 or not is_inside_tree():
		return
	var wait := maxf(_shadow_last + SHADOW_REBUILD_GAP - Time.get_ticks_msec() / 1000.0, 0.0)
	if wait > 0.0:
		get_tree().create_timer(wait, true, true).timeout.connect(_shadow_start)
	else:
		_shadow_start()


func _shadow_start() -> void:
	if _shadow_task >= 0 or not _shadow_wanted or not is_inside_tree():
		return
	_shadow_wanted = false
	_shadow_last = Time.get_ticks_msec() / 1000.0
	var parts := _batch_arrays.values()  # the arrays themselves are never changed, only replaced
	_shadow_task = WorkerThreadPool.add_task(func() -> void:
		_shadow_result = _merge_batches(parts)
		_shadow_done.call_deferred(), false, "structure shadow mesh")


func _shadow_done() -> void:
	if _shadow_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_shadow_task)
	_shadow_task = -1
	if not is_inside_tree():
		return
	_set_shadow(_shadow_result)
	_shadow_result = []
	if _shadow_wanted:
		_shadow_soon()


func _clear_batches() -> void:
	if _shadow_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_shadow_task)
		_shadow_task = -1
	_shadow_wanted = false
	if _shadow and is_instance_valid(_shadow):
		_shadow.free()
	_shadow = null
	for mat in _batches:
		var mi: MeshInstance3D = _batches[mat]
		if is_instance_valid(mi):
			mi.free()
	_batches.clear()
	_batched.clear()
	_batch_members.clear()
	_batch_arrays.clear()
	_batch_dirty.clear()
	_show_after.clear()


## How many draw calls its intact members take (tests, F3).
func batch_count() -> int:
	return _batches.size()


# --- Standing and falling -----------------------------------------------------------------------

func _on_member_damaged(m: StructureMember) -> void:
	mark_dirty(m.member_id)
	settle_soon()


## A member whose loads or strength changed since the last analysis (broken, holed, charred, a man
## on it, new from a cut, the ground gone under it): the next analysis works it, and what its
## load reaches, out again. Whatever breaks a member says so here (or the building stands wrong
## until the fire's next full check).
func mark_dirty(id: StringName) -> void:
	_dirty[id] = true


## The graph is new (built, or worked out again): the next analysis starts from the top.
func invalidate_analysis() -> void:
	_analysis_valid = false
	_dirty.clear()


## An analysis of it as it stands, begun (`advance` to finish it, as FireSystem does a slice a
## frame): the last one brought up to date for what's changed since (a few dozen members), or
## from the top when there's no last one, the graph is new, `full` is asked, most of it changed,
## or `incremental` is off.
func start_analysis(full := false) -> StructuralAnalysis:
	if not full and incremental and _analysis_valid and last_analysis != null \
			and _dirty.size() * 3 < _order.size() and last_analysis.begin_update(self, _dirty):
		_dirty.clear()
		return last_analysis
	var t := Prof.start()
	var a := StructuralAnalysis.new(tuning)
	a.begin(self)
	Prof.stop(&"analysis_full_begin", t)
	last_analysis = a
	_analysis_valid = true
	_dirty.clear()
	return a



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
## Returns the ids that broke or fell. Past `budget_ms` on this frame, a FireSystem in the world
## takes the rest a slice a frame (its queue), so a big collapse costs a few frames, never one long
## one; without one (tests, the labs' stands) it runs to the end.
func settle(budget_ms := INF) -> Array[StringName]:
	_settle_pending = false
	var changed: Array[StringName] = []
	if not collapses or not is_inside_tree():
		return changed
	var t0 := Time.get_ticks_usec()
	if budget_ms < INF and ((not _analysis_valid and _order.size() > SLICED_ABOVE) \
			or (_analysis_valid and last_analysis != null and last_analysis.left() > SLICE_LEFT) \
			or _dirty.size() > SETTLE_DIRTY_NOW):
		# No analysis of it yet and it's big (the first is every member), one in progress a slice a
		# frame with much still to do (the fire's routine look), or many changed members waiting: a
		# slice a frame for this too.
		var fire := FireSystem.find(get_tree())
		if fire and fire.queue_settle(self):
			return changed
	for round_ in 64:
		var t_a := Prof.start()
		var a := start_analysis()
		a.advance(a.left())
		Prof.stop(&"settle_analyse", t_a)
		var t_r := Prof.start()
		var more := apply_round(a, changed)
		Prof.stop(&"settle_apply", t_r)
		if not more:
			break
		if (Time.get_ticks_usec() - t0) / 1000.0 > budget_ms:
			var fire := FireSystem.find(get_tree())
			if fire and fire.queue_settle(self):
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
	var dropped := _drop(a.falling, DROP_PER_ROUND)
	changed.append_array(dropped)
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
	out.append_array(settle(SETTLE_FRAME_MS))
	return out


## Break several members at once (a blast), each thrown by its own push, then settle once. A
## member with a stretch in `cuts` (Vector2(t0, t1), or null) has that stretch cut out instead.
func break_members(list: Array[StructureMember], pushes: Array[Vector3], cuts: Array = []) -> Array[StringName]:
	var out: Array[StringName] = []
	if not collapses:
		return out
	var structural := false
	for i in list.size():
		var m := list[i]
		if m == null or not is_instance_valid(m) or m.broken:
			continue
		var push: Vector3 = pushes[i] if i < pushes.size() else Vector3.ZERO
		var cut: Variant = cuts[i] if i < cuts.size() else null
		if m.kind == &"glass":
			m.shatter(m.global_position, push.normalized() if push.length() > 0.01 else Vector3.DOWN)
		elif cut is Vector2:
			cut_member(m, (cut as Vector2).x, (cut as Vector2).y, push)
		else:
			# Where the blast hit it, if it says; else where it's weakest.
			_snap(m, float(m.get_meta(&"blast_t", m.weakest_t())), push)
		out.append(m.member_id)
		structural = structural or m.kind != &"glass"
	# Panes carry nothing: a building that only lost glass doesn't need its loads worked out again
	# (a whole building's analysis, ~0.1 s for the saloon, for a window across the street).
	if structural:
		var t_s := Prof.start()
		out.append_array(settle(SETTLE_FRAME_MS))
		Prof.stop(&"blast_settle", t_s)
	return out


## Cut the stretch `t0`..`t1` (along it, from its middle) out of a member, as a charge tears a
## hole in a board: the stretch flies as short pieces (thrown by `push`), and what's left either
## side stays in the frame as a member of its own (`<id>/a`, `<id>/b`), resting on whatever held
## that part of it. An end shorter than CUT_MIN_PIECE goes with the stretch. The member itself is
## broken (its record: `cut` meta, `to_dict`'s "cuts"). Returns the pieces left standing.
func cut_member(m: StructureMember, t0: float, t1: float, push := Vector3.ZERO) -> Array[StructureMember]:
	var left: Array[StructureMember] = []
	if m == null or not is_instance_valid(m) or m.broken or m.consumed:
		return left
	var length := m.length()
	var half := length * 0.5
	var lo := clampf(minf(t0, t1), -half, half)
	t1 = clampf(maxf(t0, t1), -half, half)
	t0 = lo
	if t0 - -half < CUT_MIN_PIECE:
		t0 = -half
	if half - t1 < CUT_MIN_PIECE:
		t1 = half
	unbatch(m)
	m.broken = true
	mark_dirty(m.member_id)
	m.set_meta(&"cut", Vector2(t0, t1))
	for c in m.get_children():
		if c is MeshInstance3D or c is CollisionShape3D:
			c.queue_free()
	m.pieces = []
	var ai := m.axis_index()
	var base := String(m.member_id).trim_prefix(String(structure_id) + "/")
	for side in 2:
		var a := -half if side == 0 else t1
		var b := t0 if side == 0 else half
		if b - a < CUT_MIN_PIECE:
			continue
		var size := m.size
		size[ai] = b - a
		var offset := Vector3.ZERO
		offset[ai] = (a + b) * 0.5
		var p := add_member("%s/%s" % [base, "a" if side == 0 else "b"], m.kind, m.wood, size, m.transform * offset, m.transform.basis)
		p.set_meta(&"cut_from", m.member_id)
		mark_dirty(p.member_id)
		p.temperature = m.temperature
		p.char_depth = m.char_depth
		p.wet = m.wet
		left.append(p)
	_relink(m, left)
	m.set_meta(&"cut_pieces", left)
	# The stretch, in pieces about a hand-span long, thrown.
	var n := maxi(1, ceili((t1 - t0) / CUT_CHUNK))
	for k in n:
		var ca := t0 + (t1 - t0) * k / n
		var cb := t0 + (t1 - t0) * (k + 1) / n
		var size := m.size
		size[ai] = cb - ca
		var offset := Vector3.ZERO
		offset[ai] = (ca + cb) * 0.5
		var rb := _new_rubble([m.member_id])
		rb.global_transform = m.global_transform * Transform3D(Basis(), offset)
		var mi := MeshInstance3D.new()
		mi.mesh = MemberMesh.box(size)
		mi.material_override = WoodMaterials.get_material(m.wood, hash(m.member_id) + k)
		rb.add_child(mi)
		var cs := CollisionShape3D.new()
		cs.shape = _box_shape(size)
		rb.add_child(cs)
		rb.mass = maxf(m.weight(tuning) / 9.81 * (cb - ca) / length, 0.05)
		# Short pieces are small debris (you walk through them), as wood chips are.
		if maxf(size.x, maxf(size.y, size.z)) < Fittings.SMALL:
			rb.collision_layer = Layers.DEBRIS
			rb.collision_mask = Layers.DEBRIS_MASK
		var spread := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.2, 1.0), _rng.randf_range(-1, 1)) * 0.25
		rb.linear_velocity = push * _rng.randf_range(0.6, 1.1) + spread * push.length()
		rb.angular_velocity = Vector3(_rng.randf_range(-12, 12), _rng.randf_range(-12, 12), _rng.randf_range(-12, 12))
		rb.set_meta(&"start_v", rb.linear_velocity)
	_wake_near(m.global_position, length + 2.0)
	_play(&"timber_crack", m.global_position)
	Events.member_broken.emit(m.member_id)
	Events.member_cut.emit(m, left)
	return left


## The pieces left of `old` take its place in the support graph: each touches, rests on and holds
## up whichever of `old`'s neighbours its own box meets (the rules of infer_supports, worked for
## them alone: the whole building's would be thousands of box tests).
func _relink(old: StructureMember, pieces: Array[StructureMember]) -> void:
	var boxes := {}
	for p in pieces:
		boxes[p] = p.structure_aabb()
		_place_in_stack(p, boxes[p])
	for id: StringName in old.touching:
		var o := get_member(id)
		if o == null:
			continue
		var obox := o.structure_aabb()
		o.touching.erase(old.member_id)
		o.supported_by.erase(old.member_id)
		o.support_points.erase(old.member_id)
		o.support_boxes.erase(old.member_id)
		o.analysis_cache = {}
		for p in pieces:
			_link(p, boxes[p], o, obox)
			_link(o, obox, p, boxes[p])
	_by_stack.clear()


## An overloaded member snaps at `t` along its length into two falling pieces (short ones just
## fall whole).
func _snap(m: StructureMember, t: float, push := Vector3.ZERO) -> void:
	unbatch(m)
	m.broken = true
	mark_dirty(m.member_id)
	var length := m.length()
	var ai := m.axis_index()
	var mi: MeshInstance3D = null
	var cs: CollisionShape3D = null
	for c in m.get_children():
		if c is MeshInstance3D and mi == null:
			mi = c
		elif c is CollisionShape3D and cs == null:
			cs = c
	if mi == null or cs == null or m.consumed:
		return  # burnt away already: nothing left to fall (the soak found one snapped after)
	var new_pieces: Array = []
	if length < 0.4 or absf(t) > length * 0.5 - 0.1:
		if cs.disabled:
			# A shattered pane: nothing solid to fall (a body with no shape falls through the ground).
			mi.queue_free()
			return
		var rb := _new_rubble([m.member_id])
		rb.global_transform = m.global_transform
		if not cs.shape is BoxShape3D:
			cs.shape = _box_shape(m.size)  # carved (concave): a moving body takes its box
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
## one piece. Up to `at_most` members (whole clumps; every one by default): the ids that fell.
func _drop(ids: Array[StringName], at_most := 0) -> Array[StringName]:
	var fallen: Array[StringName] = []
	var left := {}
	for id in ids:
		left[id] = true
	while not left.is_empty():
		if at_most > 0 and fallen.size() >= at_most:
			break
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
		fallen.append_array(clump)
		var rb := _new_rubble(clump)
		var first := get_member(clump[0])
		rb.global_transform = Transform3D(Basis(), first.global_position)
		var mass := 0.0
		for id in clump:
			var m := get_member(id)
			unbatch(m)
			m.broken = true
			mark_dirty(id)
			mass += m.weight(tuning) / 9.81
			for c in m.get_children():
				if c is MeshInstance3D or c is CollisionShape3D:
					c.reparent(rb, true)
				if c is CollisionShape3D and not (c as CollisionShape3D).shape is BoxShape3D:
					# Carved (concave): a moving body takes its box, as in _snap, or it falls
					# through the ground (a blasted sign, the nightly soak, 2026-10-13).
					(c as CollisionShape3D).shape = _box_shape(m.size)
			Events.member_broken.emit(id)
		if not has_solid_shape(rb):
			# Only shattered glass or burnt-away members: no shape to land with (it'd fall for ever).
			rubble.erase(rb)
			rb.queue_free()
			continue
		rb.mass = maxf(mass, 0.3)
		_wake_near(rb.global_position, 6.0)
	return fallen


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


## Has this body a shape left to land with? Not a shattered pane's (disabled) nor one going this
## frame (a member burnt away as it fell: the nightly soak, 2026-10-13, found a sign falling
## through the ground with nothing left to hold it up).
static func has_solid_shape(body: Node) -> bool:
	return body.get_children().any(func(c: Node) -> bool:
		return c is CollisionShape3D and not (c as CollisionShape3D).disabled and not c.is_queued_for_deletion())


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
	var lost: Array[RigidBody3D] = []
	for rb in rubble:
		if is_instance_valid(rb) and not rb.sleeping:
			rb.set_meta(&"v", rb.linear_velocity)
			if rb.global_position.y < LOST_BELOW:
				lost.append(rb)
	for rb in lost:
		# Gone through the ground somehow: a piece falling for ever costs the physics every frame.
		push_warning("rubble %s fell through the ground at %s; removed" % [rb.get_meta(&"members", []), rb.global_position])
		rubble.erase(rb)
		rb.queue_free()


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
			person.call_deferred(&"take_blow", other, energy, rb.global_position, v.normalized(), rb.mass * speed)
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
	if GameAudio.enabled():
		GameAudio.play(self, id, at, {"unit_size": 10.0, "limit": GameAudio.t().breaking_limit})
		return
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
	# Members a stretch was cut out of: the cut (along it, from its middle) remakes its pieces.
	var cuts := {}
	for m in _order:
		if m.has_meta(&"cut"):
			var c: Vector2 = m.get_meta(&"cut")
			cuts[String(m.member_id)] = [c.x, c.y]
	return {"id": String(structure_id), "broken": broken_ids, "holes": holes, "rubble": pieces, "cuts": cuts}


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
