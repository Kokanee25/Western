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
## Under World.deterministic a settle's budget is members analysed, this many a millisecond of it
## (about what a millisecond analyses here: the spec saloon's 5,150 in ~340 ms, measured
## 2026-10-27 by the blast-freeze lab's `bf_analyse`; it was 30, from ~170 ms).
const MEMBERS_A_MS := 15
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
## A batch is one material's members, or a piece of them ([Material, piece]: see BATCH_PIECE).
## Batch -> MeshInstance3D drawing its members.
var _batches := {}
## StructureMember -> the batch it's drawn in.
var _batched := {}
## Batch -> the members in it (the other way round, so a rebuild reads its own, not all).
var _batch_members := {}
## Batch -> its mesh arrays, kept for the shadow mesh (merged off the main thread).
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
var _hide_after := {}  # members batched after the build (a cut's ends): hidden when their batch has them
var _rebuild_queued := false
var _rebuild_timed := false
var _panes: Array[StructureMember] = []
var _panes_of := -1  # _order.size() when _panes was made
var _last_rebuild := -INF
## The fire takes members out of a burning building's batches one at a time; rebuilding a batch
## (every member of that material in the building) each time it did was a long frame.
const BATCH_REBUILD_GAP := 0.5
## Batches are rebuilt until this much of a drawn frame's main thread (ms) is spent, every
## structure's together; the rest wait a frame (a fallen board's copy stands in its batch that frame
## longer: a collapse dirtied a dozen materials a frame, 65 ms, 2026-10-25). It was each structure's
## own 6 ms on each physics tick, 90-163 ms a frame for seconds after a stick under the catch-up
## (Sean's F12 reports, #459); a piece's mesh is now merged on a worker (`_merge_members`) and only
## made into a mesh here.
const BATCH_FRAME_MS := 3.0
## Under World.deterministic, the members rebuilt a frame instead (~25 us each).
const BATCH_FRAME_MEMBERS := 240
static var _batch_frame := -1
static var _batch_frame_us := 0
static var _batch_frame_units := 0
## Batch -> how many times it's been made dirty (a job's result is stale if it's changed since).
var _batch_gen := {}
## The batches being merged on a worker: [[key, gen, members, fire]], their arrays in _batch_out.
var _batch_job: Array = []
var _batch_out: Array = []
var _batch_task := -1
## A member mesh's arrays, read once (the worker mustn't ask the rendering server: it waits on the
## main thread, which deadlocks the moment the main thread waits on it).
static var _mesh_arrays := {}
const MESH_ARRAYS_KEPT := 20000
## A material's members are batched in pieces of at most this many, near ones together (in the
## order of 2 m cells along a Morton curve): a ball into one board rebuilt the material's batch for
## the whole building, 683 members of the spec saloon's, ~20 ms on the physics frame every shot
## (Sean's per-shot hitch, #385). A kit prop or a small building's material is one piece still.
const BATCH_PIECE := 64
const BATCH_CELL := 2.0
## The fire's look on its members (FireSystem: scorch and char, the glow of a burning front):
## StructureMember -> Vector2(char_amount, glow). A member still in a batch is drawn charred by
## its batch (#434: a saloon burning whole was 2,500 members each drawn on its own, 18,000 draws):
## a batch with any of them has each vertex's member's place (CUSTOM2) and the char_batch overlay,
## its `looks` that place's. One drawn on its own (broken, holed, cut) has a char_overlay, shared by
## every member whose look is in the same step (CHAR_STEPS, GLOW_STEPS: instance uniforms ran out
## on a town's charred rubble, 4,096 under the Compatibility renderer).
var _fire_look := {}
var _fire_mats := {}  # batch -> its char_batch ShaderMaterial (built with places)
var _looks := {}  # batch (one with places) -> each place's look, as sent
var _slot := {}  # StructureMember in a batch with places -> its place
var _looks_dirty := {}
var _looks_queued := false
const CHAR_BATCH := preload("res://src/fire/char_batch.gdshader")
const CHAR_OVERLAY := preload("res://src/fire/char_overlay.gdshader")
static var _char_overlays := {}  # Vector2i(char step, glow step) -> ShaderMaterial
const CHAR_STEPS := 32
const GLOW_STEPS := 8


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
	# Nor its analysis or its batches on a worker (issue #392: every task of ours waited for before it's freed).
	if what == NOTIFICATION_PREDELETE:
		wait_analysis()
		if _batch_task >= 0:
			WorkerThreadPool.wait_for_task_completion(_batch_task)
			_batch_task = -1


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
	_fire_look.clear()
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
		mi.visible = false
	for mat in groups:
		var pieces := _batch_pieces(groups[mat])
		for i in pieces.size():
			var key := [mat, i]
			_batch_members[key] = pieces[i]
			for m: StructureMember in pieces[i]:
				_batched[m] = key
	# Unbatched members (holed, burning) are walls to a far lamp too (OilLamp).
	for m in _order:
		var own := m.get_child(0) as MeshInstance3D
		if own:
			own.layers |= Layers.VIS_WALLS
	for key in _batch_members:
		_build_batch(key)
	_build_shadow()
	if rest_batched and members_rest:
		for m: StructureMember in _batched:
			m.rest()


## One material's members in pieces of at most BATCH_PIECE, each piece near together: sorted by
## their 2 m cell's place on a Morton curve (then as built), and cut in runs.
static func _batch_pieces(members: Array) -> Array:
	if members.size() <= BATCH_PIECE:
		return [members]
	var low := Vector3.INF
	for m: StructureMember in members:
		low = low.min(m.transform.origin)
	var keyed: Array = []
	for i in members.size():
		var c := ((members[i] as StructureMember).transform.origin - low) / BATCH_CELL
		keyed.append([_morton(int(c.x), int(c.y), int(c.z)), i])
	keyed.sort()  # (by cell, then the order they were built in: the same every time)
	var out: Array = []
	var n := ceili(members.size() / float(BATCH_PIECE))
	var each := ceili(members.size() / float(n))  # even pieces, not 64, 64, ..., 3
	for k in range(0, keyed.size(), each):
		out.append(keyed.slice(k, k + each).map(func(e: Array) -> StructureMember: return members[e[1]]))
	return out


## Three cell indices (each under 1024) interleaved bit by bit: near cells, near numbers.
static func _morton(x: int, y: int, z: int) -> int:
	var out := 0
	for b in 10:
		out |= ((x >> b) & 1) << (3 * b) | ((y >> b) & 1) << (3 * b + 1) | ((z >> b) & 1) << (3 * b + 2)
	return out


func _build_batch(key: Array) -> void:
	var list: Array = _batch_members.get(key, [])
	var fire := _any_fire(list)
	if list.is_empty():
		_apply_batch(key, list, [], false)
		return
	var st := SurfaceTool.new()
	var counts := PackedInt32Array()
	for m: StructureMember in list:
		var mi := m.drawn_node()
		st.append_from(mi.mesh, 0, m.transform * mi.transform)
		if fire:
			counts.append(mi.mesh.surface_get_array_len(0))
	var arrays := st.commit_to_arrays()
	if fire:
		var places := _places(arrays, counts)
		if places.is_empty():
			fire = false
		else:
			arrays[Mesh.ARRAY_CUSTOM2] = places
	_apply_batch(key, list, arrays, fire)


func _any_fire(list: Array) -> bool:
	for m: StructureMember in list:
		if _fire_look.has(m):
			return true
	return false


## A batch's mesh made from its arrays (worked out here or on a worker) for `list`, its members as
## they were then; nothing left of it if `list` is empty.
func _apply_batch(key: Array, list: Array, arrays: Array, fire: bool) -> void:
	var mat: Material = key[0]
	var old: MeshInstance3D = _batches.get(key)
	if list.is_empty() or arrays.is_empty():
		if old:
			old.queue_free()
		_batches.erase(key)
		_batch_arrays.erase(key)
		_fire_mats.erase(key)
		_looks.erase(key)
		return
	var flags := 0
	if fire:
		flags = Mesh.ARRAY_CUSTOM_R_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT
	_batch_arrays[key] = arrays
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	if old == null:
		old = MeshInstance3D.new()
		old.name = "Batch"
		old.material_override = mat
		add_child(old, false, Node.INTERNAL_MODE_BACK)
		_batches[key] = old
	old.mesh = mesh
	if fire:
		if not _fire_mats.has(key):
			var cm := ShaderMaterial.new()
			cm.shader = CHAR_BATCH
			cm.set_shader_parameter(&"texels_per_meter", PixelArt.texels_per_meter)
			_fire_mats[key] = cm
		var looks := PackedVector2Array()
		looks.resize(BATCH_PIECE)
		for i in list.size():
			if _batched.get(list[i]) == key:  # (not one unbatched since the job began)
				_slot[list[i]] = i
			looks[i] = _fire_look.get(list[i], Vector2.ZERO)
		_looks[key] = looks
		old.material_overlay = _fire_mats[key]
		(_fire_mats[key] as ShaderMaterial).set_shader_parameter(&"looks", looks)
	else:
		_fire_mats.erase(key)
		_looks.erase(key)
		old.material_overlay = null


## Each vertex's member's place in the batch (CUSTOM2.x), from how many vertices each member's mesh
## gave it; empty if the batch's vertices aren't those (they always are: append_from keeps them).
static func _places(arrays: Array, counts: PackedInt32Array) -> PackedFloat32Array:
	var n: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var places := PackedFloat32Array()
	places.resize(n)
	var at := 0
	for i in counts.size():
		if at + counts[i] > n:
			push_warning("Structure: a batch's vertices aren't its members' (%d > %d)" % [at + counts[i], n])
			return PackedFloat32Array()
		for v in range(at, at + counts[i]):
			places[v] = float(i)
		at += counts[i]
	if at != n:
		push_warning("Structure: a batch's vertices aren't its members' (%d of %d)" % [at, n])
		return PackedFloat32Array()
	return places


## The fire's look on a member (FireSystem: `char_amount` 0 sound to 1 charred through, `glow` its
## burning front's, 0 when out): drawn by its batch while it's in one, else over its own meshes.
func show_fire(m: StructureMember, char_amount: float, glow: float) -> void:
	var v := Vector2(snappedf(char_amount, 0.01), snappedf(glow, 0.01))
	if _fire_look.has(m) and _fire_look[m] == v:
		return
	_fire_look[m] = v
	var key: Variant = _batched.get(m)
	if key == null:
		_own_fire_look(m)
	elif not _fire_mats.has(key):
		# Its batch was drawn without places: again, with them (a piece of 64 members at most).
		_dirty_batch(key)
		if not _rebuild_queued:
			_rebuild_queued = true
			_rebuild_dirty_batches.call_deferred()
	else:
		var looks: PackedVector2Array = _looks[key]
		looks[_slot[m]] = v
		_looks[key] = looks
		if not _looks_dirty.has(key):
			_looks_dirty[key] = true
			if not _looks_queued:
				_looks_queued = true
				_send_dirty_looks.call_deferred()


func has_fire_look(m: StructureMember) -> bool:
	return _fire_look.has(m)


func fire_look(m: StructureMember) -> Vector2:
	return _fire_look.get(m, Vector2.ZERO)


## The batches whose looks changed this frame send them, once each.
func _send_dirty_looks() -> void:
	var t := Prof.start()
	_looks_queued = false
	for key: Array in _looks_dirty:
		if _fire_mats.has(key):
			(_fire_mats[key] as ShaderMaterial).set_shader_parameter(&"looks", _looks[key])
	_looks_dirty.clear()
	Prof.stop(&"char_looks", t)


## A member drawn on its own: the char overlay of its look's step over each of its meshes.
func _own_fire_look(m: StructureMember) -> void:
	if not _fire_look.has(m):
		return
	RubbleRest.touch(m)
	var mat := char_material(_fire_look[m])
	for p: Array in m.pieces:
		if not is_instance_valid(p[0]):
			continue
		var mi := p[0] as MeshInstance3D
		if mi and mi.material_overlay != mat:
			mi.material_overlay = mat


## The char overlay for a look (char_amount, glow), its step's: made once and shared.
static func char_material(look: Vector2) -> ShaderMaterial:
	var step := Vector2i(roundi(clampf(look.x, 0.0, 1.0) * CHAR_STEPS), roundi(clampf(look.y, 0.0, 1.0) * GLOW_STEPS))
	if look.y > 0.0:
		step.y = maxi(step.y, 1)  # alight: some glow, however little
	var mat: ShaderMaterial = _char_overlays.get(step)
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = CHAR_OVERLAY
		mat.set_shader_parameter(&"texels_per_meter", PixelArt.texels_per_meter)
		mat.set_shader_parameter(&"char_amount", float(step.x) / CHAR_STEPS)
		mat.set_shader_parameter(&"glow", float(step.y) / GLOW_STEPS)
		_char_overlays[step] = mat
	return mat


## Draw this member on its own from now on (something's happened to it). `soon` (the fire's
## heating, a member at a time all over a burning building): its batch is rebuilt without it at
## most every BATCH_REBUILD_GAP, and it's shown then, not drawn twice meanwhile.
func unbatch(m: StructureMember, soon := false) -> void:
	RubbleRest.touch(m)  # (its pieces lying at rest in a cell are their bodies' own again)
	m.realise()
	if not _batched.has(m):
		return
	var key: Array = _batched[m]
	_batched.erase(m)
	_slot.erase(m)
	_hide_after.erase(m)
	(_batch_members.get(key, []) as Array).erase(m)
	_dirty_batch(key)
	_own_fire_look(m)  # charred, it stays charred
	var mi := m.get_child(0) as MeshInstance3D
	if soon:
		_show_after[m] = key
		if not _rebuild_timed and not _rebuild_queued and is_inside_tree():
			_rebuild_timed = true
			var wait := maxf(_last_rebuild + BATCH_REBUILD_GAP - World.now(), 0.0)
			get_tree().create_timer(wait, true, true).timeout.connect(_rebuild_dirty_batches)
		return
	if mi:
		mi.visible = true
	if not _rebuild_queued:
		_rebuild_queued = true
		_rebuild_dirty_batches.call_deferred()


## A member made after the build (a cut's ends) into a batch of its material with room (a new
## piece if none has), drawn on its own till that batch is drawn with it (#459: a blast's cut boards
## were each a draw of their own for good).
func _batch_new(m: StructureMember) -> void:
	if not batch_meshes or _batch_members.is_empty() or _batched.has(m):
		return
	var mi := m.drawn_node()
	if mi == null or not mi.visible or m.kind == &"glass" or mi.material_override == null \
			or mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON or mi.material_overlay != null:
		return
	var mat := mi.material_override
	var key: Variant = null
	var next := 0
	for k: Array in _batch_members:
		if k[0] == mat:
			next = maxi(next, int(k[1]) + 1)
			if key == null and (_batch_members[k] as Array).size() < BATCH_PIECE:
				key = k
	if key == null:
		key = [mat, next]
		_batch_members[key] = []
	(_batch_members[key] as Array).append(m)
	_batched[m] = key
	_hide_after[m] = key
	_dirty_batch(key)
	if not _rebuild_queued:
		_rebuild_queued = true
		_rebuild_dirty_batches.call_deferred()


func _dirty_batch(key: Array) -> void:
	_batch_dirty[key] = true
	_batch_gen[key] = int(_batch_gen.get(key, 0)) + 1


## The dirty batches again, within the drawn frame's budget (every structure's together): each
## piece's members gathered here, merged on a worker, made into its mesh when that's done.
func _rebuild_dirty_batches() -> void:
	_rebuild_queued = false
	_rebuild_timed = false
	if not is_inside_tree() or _batch_dirty.is_empty():
		if _batch_task < 0:
			_show_rebuilt()
		return
	if _batch_task >= 0:
		_rebuild_next_frame()  # (one job at a time: the rest when it's in)
		return
	var frame := Engine.get_process_frames()
	if frame != _batch_frame:
		_batch_frame = frame
		_batch_frame_us = 0
		_batch_frame_units = 0
	var t := Prof.start()
	var t0 := Time.get_ticks_usec()
	var job: Array = []
	for key: Array in _batch_dirty.keys():
		if _batch_over(t0):
			break
		var list: Array = (_batch_members.get(key, []) as Array).duplicate()
		_batch_frame_units += list.size()
		_batch_dirty.erase(key)
		var inputs: Variant = null if list.is_empty() else _member_inputs(list)
		if inputs == null:
			_build_batch(key)  # (nothing left of it, or members the merge doesn't take: here)
			_show_rebuilt(key)
			continue
		job.append([key, int(_batch_gen.get(key, 0)), list, _any_fire(list), inputs])
	_batch_frame_us += Time.get_ticks_usec() - t0
	if not job.is_empty():
		_batch_job = job
		if World.deterministic or GameQuit.quitting:
			# The same frame for frame: done now, on this thread.
			_batch_out = _merge_job(job)
			_batch_done()
		else:
			_batch_task = WorkerThreadPool.add_task(func() -> void:
				_batch_out = _merge_job(job)
				_batch_done.call_deferred(), true, "structure batches")  # high priority: a low one can hang the quit (#392, #435)
	Prof.stop(&"batches", t)
	if not _batch_dirty.is_empty():
		_rebuild_next_frame()
	_last_rebuild = World.now()


func _batch_over(t0: int) -> bool:
	if World.deterministic:
		return _batch_frame_units > BATCH_FRAME_MEMBERS
	return (_batch_frame_us + Time.get_ticks_usec() - t0) / 1000.0 > BATCH_FRAME_MS


func _rebuild_next_frame() -> void:
	_rebuild_queued = true
	if is_inside_tree() and not get_tree().process_frame.is_connected(_rebuild_dirty_batches):
		get_tree().process_frame.connect(_rebuild_dirty_batches, CONNECT_ONE_SHOT)


## Each member's mesh arrays (read once a mesh) and where it sits; null if they don't all carry
## the channels the merge takes (it falls back to the SurfaceTool's, here).
func _member_inputs(list: Array) -> Variant:
	var out: Array = []
	var shape := -1
	for m: StructureMember in list:
		var mi := m.drawn_node()
		if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
			return null
		var arrays: Variant = _mesh_arrays.get(mi.mesh)
		if arrays == null:
			if _mesh_arrays.size() > MESH_ARRAYS_KEPT:
				_mesh_arrays.clear()
			arrays = mi.mesh.surface_get_arrays(0)
			_mesh_arrays[mi.mesh] = arrays
		var has := _channels(arrays)
		if has < 0 or (shape >= 0 and has != shape):
			return null
		shape = has
		out.append([arrays, m.transform * mi.transform])
	return out


## Which of the merge's channels the arrays carry (a bit each), or -1 if they carry one it doesn't
## take (custom channels, bones).
static func _channels(arrays: Array) -> int:
	if arrays.size() < Mesh.ARRAY_MAX or arrays[Mesh.ARRAY_VERTEX] == null:
		return -1
	for slot: int in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]:
		if arrays[slot] != null:
			return -1
	var has := 0
	for slot: int in [Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_INDEX]:
		if arrays[slot] != null:
			has |= 1 << slot
	return has


## A job's batches merged (on a worker: pure data, no rendering calls).
static func _merge_job(job: Array) -> Array:
	var out: Array = []
	for j: Array in job:
		out.append(_merge_members(j[4], j[3]))
	return out


## Members' arrays one after another in the batch's space, as the SurfaceTool's append_from makes
## them (an index if they have one; each member's vertex count for its places when `fire`).
static func _merge_members(inputs: Array, fire: bool) -> Array:
	var first: Array = inputs[0][0]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()
	var counts := PackedInt32Array()
	var indexed: bool = first[Mesh.ARRAY_INDEX] != null
	for inp: Array in inputs:
		var a: Array = inp[0]
		var xf: Transform3D = inp[1]
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var base := verts.size()
		verts.append_array(xf * v)
		if first[Mesh.ARRAY_NORMAL] != null:
			var n: PackedVector3Array = Transform3D(xf.basis, Vector3.ZERO) * (a[Mesh.ARRAY_NORMAL] as PackedVector3Array)
			for i in n.size():
				n[i] = n[i].normalized()
			normals.append_array(n)
		if first[Mesh.ARRAY_TANGENT] != null:
			var tin: PackedFloat32Array = a[Mesh.ARRAY_TANGENT]
			var tout := PackedFloat32Array()
			tout.resize(tin.size())
			for i in range(0, tin.size(), 4):
				var tv := (xf.basis * Vector3(tin[i], tin[i + 1], tin[i + 2])).normalized()
				tout[i] = tv.x
				tout[i + 1] = tv.y
				tout[i + 2] = tv.z
				tout[i + 3] = tin[i + 3]
			tangents.append_array(tout)
		if first[Mesh.ARRAY_COLOR] != null:
			colors.append_array(a[Mesh.ARRAY_COLOR])
		if first[Mesh.ARRAY_TEX_UV] != null:
			uvs.append_array(a[Mesh.ARRAY_TEX_UV])
		if first[Mesh.ARRAY_TEX_UV2] != null:
			uv2s.append_array(a[Mesh.ARRAY_TEX_UV2])
		if indexed:
			for i: int in (a[Mesh.ARRAY_INDEX] as PackedInt32Array):
				indices.append(i + base)
		counts.append(v.size())
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	if first[Mesh.ARRAY_NORMAL] != null:
		arrays[Mesh.ARRAY_NORMAL] = normals
	if first[Mesh.ARRAY_TANGENT] != null:
		arrays[Mesh.ARRAY_TANGENT] = tangents
	if first[Mesh.ARRAY_COLOR] != null:
		arrays[Mesh.ARRAY_COLOR] = colors
	if first[Mesh.ARRAY_TEX_UV] != null:
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	if first[Mesh.ARRAY_TEX_UV2] != null:
		arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	if indexed:
		arrays[Mesh.ARRAY_INDEX] = indices
	if fire:
		arrays[Mesh.ARRAY_CUSTOM2] = _places(arrays, counts)
	return arrays


## A job's batches in: each made into its mesh (as its members were when the job began; a batch
## changed since is left dirty and its members unbatched meanwhile not shown yet).
func _batch_done() -> void:
	if _batch_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_batch_task)
	_batch_task = -1
	var job := _batch_job
	var out := _batch_out
	_batch_job = []
	_batch_out = []
	if not is_inside_tree() or job.size() != out.size():
		return
	var t := Prof.start()
	for i in job.size():
		var j: Array = job[i]
		var arrays: Array = out[i]
		var fire: bool = j[3]
		if fire and (arrays[Mesh.ARRAY_CUSTOM2] as PackedFloat32Array).is_empty():
			fire = false  # (the vertices weren't its members': drawn without places)
			arrays[Mesh.ARRAY_CUSTOM2] = null
		_apply_batch(j[0], j[2], arrays, fire)
		if int(_batch_gen.get(j[0], 0)) == int(j[1]):
			_show_rebuilt(j[0])
	Prof.stop(&"batches", t)
	_shadow_soon()
	if not _batch_dirty.is_empty():
		_rebuild_next_frame()


## A batch merge on a worker, not finished yet (GameQuit waits for it).
func batches_running() -> bool:
	return _batch_task >= 0 and not WorkerThreadPool.is_task_completed(_batch_task)


## Members unbatched `soon` shown now their batch is drawn without them (`key`; all with no key:
## nothing left to rebuild).
func _show_rebuilt(key: Variant = null) -> void:
	for m: Variant in _hide_after.keys():
		if key != null and _hide_after[m] != key:
			continue
		_hide_after.erase(m)
		if is_instance_valid(m) and _batched.has(m) and (m as StructureMember).get_child_count() > 0:
			var own := (m as StructureMember).get_child(0) as MeshInstance3D
			if own:
				own.visible = false
			if rest_batched and members_rest:
				(m as StructureMember).rest()
	for m: Variant in _show_after.keys():
		if key != null and _show_after[m] != key:
			continue
		_show_after.erase(m)
		if is_instance_valid(m) and (m as StructureMember).get_child_count() > 0:
			var mi := (m as StructureMember).get_child(0) as MeshInstance3D
			if mi and not (m as StructureMember).consumed:
				mi.visible = true


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
	if _shadow_task >= 0 or not is_inside_tree() or GameQuit.quitting:
		return
	var wait := maxf(_shadow_last + SHADOW_REBUILD_GAP - World.now(), 0.0)
	if wait > 0.0:
		get_tree().create_timer(wait, true, true).timeout.connect(_shadow_start)
	else:
		_shadow_start()


func _shadow_start() -> void:
	if _shadow_task >= 0 or not _shadow_wanted or not is_inside_tree() or GameQuit.quitting:
		return
	_shadow_wanted = false
	_shadow_last = World.now()
	var parts := _batch_arrays.values()  # the arrays themselves are never changed, only replaced
	_shadow_task = WorkerThreadPool.add_task(func() -> void:
		_shadow_result = _merge_batches(parts)
		_shadow_done.call_deferred(), true, "structure shadow mesh")  # high priority: a low one can hang the quit (#392, #435)


## A shadow merge on a worker, not finished yet (GameQuit waits for it).
func shadow_running() -> bool:
	return _shadow_task >= 0 and not WorkerThreadPool.is_task_completed(_shadow_task)


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
	if _batch_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_batch_task)
		_batch_task = -1
	_batch_job = []
	_batch_out = []
	_shadow_wanted = false
	if _shadow and is_instance_valid(_shadow):
		_shadow.free()
	_shadow = null
	for key in _batches:
		var mi: MeshInstance3D = _batches[key]
		if is_instance_valid(mi):
			mi.free()
	_batches.clear()
	_batched.clear()
	_batch_members.clear()
	_batch_arrays.clear()
	_batch_dirty.clear()
	_show_after.clear()
	_hide_after.clear()
	_fire_mats.clear()
	_looks.clear()
	_slot.clear()
	_looks_dirty.clear()


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
	_record_stale[id] = true


## Each member's LoadRecord (what the analysis reads of it), id -> record, taken again when it's
## been marked dirty since, or for an analysis from the top (`_record_round`): more-cores step 8.
var _records := {}
var _record_stale := {}
var _record_round := 0
## Analyses begun on it so far (FireSystem knows another has been since its own: a blast's settle).
var analysis_epoch := 0


## Its record as it stands (taken again if it's changed since the last).
func load_record(m: StructureMember) -> LoadRecord:
	var r: LoadRecord = _records.get(m.member_id)
	if r == null or r.taken_in != _record_round or _record_stale.has(m.member_id):
		if r == null:
			r = LoadRecord.new()
			_records[m.member_id] = r
		r.take(m, tuning, self)
		r.taken_in = _record_round
		_record_stale.erase(m.member_id)
	return r


## Every record to take again (an analysis from the top: anything changed without saying so is
## caught there).
func records_all_stale() -> void:
	_record_round += 1


## An analysis of it on a worker (FireSystem's) finished before anything else touches it.
func wait_analysis() -> void:
	if last_analysis != null:
		last_analysis.wait()


## The graph is new (built, or worked out again): the next analysis starts from the top.
func invalidate_analysis() -> void:
	wait_analysis()
	_analysis_valid = false
	_dirty.clear()
	_records.clear()
	_record_stale.clear()


## An analysis of it as it stands, begun (`advance` to finish it, as FireSystem does a slice a
## frame): the last one brought up to date for what's changed since (a few dozen members), or
## from the top when there's no last one, the graph is new, `full` is asked, most of it changed,
## or `incremental` is off.
func start_analysis(full := false) -> StructuralAnalysis:
	wait_analysis()
	analysis_epoch += 1
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
## Returns the ids that broke or fell. Past `budget_ms` on this frame (under World.deterministic,
## its MEMBERS_A_MS members analysed), a FireSystem in the world takes the rest a slice a frame (its
## queue), so a big collapse costs a few frames, never one long one; without one (tests, the labs'
## stands) it runs to the end.
func settle(budget_ms := INF) -> Array[StringName]:
	wait_analysis()
	_settle_pending = false
	var changed: Array[StringName] = []
	if not collapses or not is_inside_tree():
		return changed
	var budget: WorkBudget = WorkBudget.new(budget_ms, int(budget_ms * MEMBERS_A_MS)) if budget_ms < INF else null
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
		if budget:
			budget.spend(a.left() + 1)
		a.advance(a.left())
		Prof.stop(&"settle_analyse", t_a)
		var t_r := Prof.start()
		var more := apply_round(a, changed)
		Prof.stop(&"settle_apply", t_r)
		if not more:
			break
		if budget and budget.over():
			var fire := FireSystem.find(get_tree())
			if fire and fire.queue_settle(self):
				break
	return changed


## One round of settling from an analysis of it as it stands: the worst overloaded member snaps,
## else what has no load path falls. True if something did (another round is due). FireSystem
## runs a burning building's rounds this way, an analysis spread over frames.
func apply_round(a: StructuralAnalysis, changed: Array[StringName] = []) -> bool:
	a.wait()
	wait_analysis()
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
	var t_u := Prof.start()
	unbatch(m)
	Prof.stop(&"cut_unbatch", t_u)
	m.broken = true
	mark_dirty(m.member_id)
	m.set_meta(&"cut", Vector2(t0, t1))
	for c in m.get_children():
		if c is MeshInstance3D or c is CollisionShape3D:
			c.queue_free()
	m.pieces = []
	var ai := m.axis_index()
	var t_e := Prof.start()
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
		if m.look != &"":
			p.look = m.look
		_batch_new(p)
		mark_dirty(p.member_id)
		p.temperature = m.temperature
		p.char_depth = m.char_depth
		p.wet = m.wet
		left.append(p)
	Prof.stop(&"cut_ends", t_e)
	var t_l := Prof.start()
	_relink(m, left)
	Prof.stop(&"cut_relink", t_l)
	var t_c := Prof.start()
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
		mi.material_override = WoodMaterials.get_material(m.drawn_wood(), hash(m.member_id) + k)
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
	Prof.stop(&"cut_chunks", t_c)
	var t_w := Prof.start()
	_wake_near(m.global_position, length + 2.0)
	_play(&"timber_crack", m.global_position)
	Prof.stop(&"cut_wake", t_w)
	var t_s := Prof.start()
	Events.member_broken.emit(m.member_id)
	Events.member_cut.emit(m, left)
	Prof.stop(&"cut_signals", t_s)
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
			pmi.material_override = WoodMaterials.get_material(m.drawn_wood(), hash(m.member_id))
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
		_own_fire_look(m)
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
	RubbleRest.watch(rb)
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
	var rest := RubbleRest.for_node(rb)
	if rest:
		rest.release(rb)
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
