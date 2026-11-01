class_name RubbleRest
extends Node3D
## Rubble and glass shards at rest drawn together (#459). After a blast or a collapse the street
## holds a thousand or more loose pieces, each its own body, mesh and shape, each mesh drawn again
## in every shadow pass. A piece that hasn't moved for REST_AFTER joins its patch of town (CELL):
## its meshes are drawn in the cell's mesh for its material (a new chunk of the cell, joined on a
## worker, at most every BUILD_GAP; past MAX_CHUNKS the cell's chunks are made one again), and its
## own mesh nodes are taken out of the tree once that shows; its shape nodes too while it's asleep,
## the shapes held on its body as shape owners (as StructureMember.rest), so it still lies there to
## be walked on, hit and pushed. The moment it moves (hit, shot, pushed, a blast, what it lay on
## gone) or something touches one of its pieces (the fire, a break: `touch`), its nodes go back
## where they were and its stretch of the cell's mesh is zeroed in place (non-indexed: its
## triangles collapse to a point; no rebuild, no hitch).
##
## The idea is PropBatch's (kit props at rest, docs/briefs/props-scale.md), for loose bodies.
## Only materials that look the same in any mesh's space are joined: the texel grid's UV and world
## mappings, the char overlay (in UVs), plain materials not mapped in their object's space. Like
## PropBatch it isn't used under the Compatibility renderer (an object's lights there are picked
## from a short list, so a cell would be lit differently).

## Patches of town (m): each cell's meshes are culled as one.
const CELL := 20.0
## Still this long (s) before a piece joins (not moved MOVED between looks, LOOK_EVERY apart):
## asleep, frozen (a prop's shards), or awake and not stirring (a pile beside a burning building
## is kept awake by what's going on round it, mostly without moving).
const REST_AFTER := 1.5
const LOOK_EVERY := 0.25
## A piece let go by `touch` (the fire on it, a break) waits this long (s) to join again.
const HOLD := 10.0
## Still: no point of it (its far end: its reach) has moved this far (m) since it was last looked at;
## in its cell, since it joined (a collapse wakes everything lying near, Structure._wake_near, and
## a pile wakes with any one of it, mostly without stirring; a shard jitters on the boards).
const MOVED := 0.015
## A woken piece in its cell is looked at every STIR_TICKS ticks (a share of them each tick) till it
## sleeps again: moving faster than STIR_SPEED (m/s, or STIR_SPIN rad/s) or moved from where it
## joined, it's let go. Its sleep is never forced (a body put to sleep in an awake pile is woken
## the next step, and the wakes spread: ~400,000 a blaze). What hits it, shoots it, blasts or
## shoves it lets it go at once (`let_go`).
const STIR_TICKS := 8
const STIR_SPEED := 0.05
const STIR_SPIN := 1.0
## A cell's new pieces are drawn at most this often (s), as a new chunk of it.
const BUILD_GAP := 0.5
## Past this many chunks a cell's are made one again.
const MAX_CHUNKS := 4
## A chunk's meshes are made a few a frame, up to this much (ms) of it (one merged from four of a
## street's cells was 8 ms in one go); it's shown when they're all made.
const MESH_MS := 2.0
## Joining is spread over ticks: this much (ms) a tick, or under World.deterministic this many pieces.
const JOIN_MS := 1.0
const JOIN_PIECES := 30
const TEXEL_SHADERS := ["res://src/render/texel_grid.gdshader", "res://src/render/texel_grid_blocks.gdshader"]
## The mesh channels a joined piece may carry (no custom channels, no bones).
const CHANNELS := [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]
const NOT_CHANNELS := [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3, Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS]

enum { JOINED, LATER, NEVER }

## Off (`-- --no-rubble-rest`: the before): every piece draws its own.
static var enabled := not "--no-rubble-rest" in OS.get_cmdline_user_args()

## RigidBody3D -> [still since (or held till), where it was at the last look]: waiting to join.
var _waiting := {}
## The waiting bodies in the order they're looked at (a share each tick: each every LOOK_EVERY).
var _look_queue: Array = []  # (untyped: a body may be freed in it)
## [own mesh node, its body, its entry] to take out of the tree, and [an old chunk's mesh] to free,
## after a chunk is shown: a share a frame (hundreds at once were 8 ms; drawn twice, the
## same triangles, for a frame or two meanwhile).
var _tidy: Array = []
## Pieces in a cell woken (watched: let go if they move), a share looked at each tick.
var _stirring: Array = []  # (untyped: a body may be freed in it)
var _stirring_set := {}
## instance id -> {"body", "cell", "parts": [[key, arrays]], "nodes": [[node, child index]],
## "owners", "gone", "at"}
var _rest := {}
## Vector3i -> {instance id: true}: joined since the cell's chunks were built.
var _pending := {}
## Vector3i -> [chunk]; a chunk {"meshes": {key -> MeshInstance3D}, "live": {instance id -> its
## stretches [[mesh, first vertex, count]]}}.
var _chunks := {}
var _built_at := {}  # Vector3i -> when its last chunk was made
## key -> [material, overlay or null, cast_shadow, layers]
var _keys := {}
## instance id -> a piece whose body left the tree, its nodes still kept (dealt with after).
var _leaving := {}
## Vector3i -> a cell's chunk being joined on a worker (`_build`, `_built`).
var _jobs := {}
## Why pieces didn't join, counted (the bench's census, tests).
var refused := {}
## What it's done, counted (the bench's census).
var counts := {}


## The rest for `n`'s world: a child of the topmost Node3D above it (the street), made the first
## time. Null where it isn't used.
static func for_node(n: Node) -> RubbleRest:
	if not enabled or RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return null
	var top: Node3D = null
	var p := n.get_parent()
	while p is Node3D:
		top = p
		p = p.get_parent()
	if top == null:
		return null
	var r := top.get_node_or_null(^"RubbleRest") as RubbleRest
	if r == null:
		r = RubbleRest.new()
		r.name = "RubbleRest"
		top.add_child(r)
	return r


## A loose piece (rubble, a shard) just made and in the tree: it joins when it's lain still a while.
static func watch(rb: RigidBody3D) -> void:
	if rb == null or not rb.is_inside_tree():
		return
	var r := for_node(rb)
	if r:
		_reach(rb)
		rb.sleeping_state_changed.connect(r._on_sleep.bind(rb))
		r._wait(rb, World.now())


## Something's happening to `m` (the fire, a break): any of its pieces lying in a cell are its
## body's own again, now.
static func touch(m: StructureMember) -> void:
	for p: Array in m.pieces:
		for o: Variant in p:
			if is_instance_valid(o) and (o as Node).has_meta(&"rest_body"):
				var rb: Variant = (o as Node).get_meta(&"rest_body")
				if is_instance_valid(rb) and (rb as Node).has_meta(&"resting_in"):
					((rb as Node).get_meta(&"resting_in") as RubbleRest)._count("let go: touched")
					((rb as Node).get_meta(&"resting_in") as RubbleRest).release(rb as RigidBody3D, true)


## A body about to be moved (shot, blasted, shoved, struck): if it's lying in a cell, its own again
## first. Anything else: nothing.
static func let_go(body: Object) -> void:
	if body is RigidBody3D and (body as Node).has_meta(&"resting_in"):
		var r: Variant = (body as Node).get_meta(&"resting_in")
		if is_instance_valid(r):
			(r as RubbleRest)._count("let go: pushed")
			(r as RubbleRest).release(body as RigidBody3D)


## Is it drawn in a cell (its nodes kept aside)?
static func resting(rb: RigidBody3D) -> bool:
	return is_instance_valid(rb) and rb.has_meta(&"resting_in")


func piece_count() -> int:
	return _rest.size()


## How many meshes it draws (tests, the bench).
func mesh_count() -> int:
	var n := 0
	for cell: Vector3i in _chunks:
		for ch: Dictionary in _chunks[cell]:
			n += (ch.meshes as Dictionary).size()
	return n


## Waiting to join from `since` (later: held), as it lies now.
func _wait(rb: RigidBody3D, since: float) -> void:
	if not _waiting.has(rb):
		_look_queue.append(rb)
	_waiting[rb] = [since, rb.global_transform]


## Its shape nodes out of the tree, held on the body as owners, in the order they were. Only while
## it's asleep: a body's shapes changed wakes it and resets its contacts, and done to bodies still
## awake in a pile it kept the pile awake for seconds longer (the physics' step 1.4x main's, #459).
func _shapes_aside(o: Variant) -> void:
	if not is_instance_valid(o) or not (o as Node).is_inside_tree():
		return  # (untyped: called deferred, it may be freed by then)
	var rb := o as RigidBody3D
	if not (rb.sleeping or rb.freeze):
		return
	var e: Dictionary = _rest.get(rb.get_instance_id(), {})
	if e.is_empty() or not (e.owners as Array).is_empty():
		return
	var shapes: Array = []
	for n: Array in e.nodes:
		if n[0] is CollisionShape3D and (n[0] as Node).get_parent() == rb:
			shapes.append(n[0])
	for cs: CollisionShape3D in shapes:
		rb.remove_child(cs)
	for cs: CollisionShape3D in shapes:
		var owner_id := rb.create_shape_owner(rb)
		rb.shape_owner_add_shape(owner_id, cs.shape)
		rb.shape_owner_set_transform(owner_id, cs.transform)
		rb.shape_owner_set_disabled(owner_id, cs.disabled)
		(e.owners as Array).append(owner_id)
	if not rb.freeze:
		rb.sleeping = true  # (asleep, it sleeps on)


func _on_sleep(rb: RigidBody3D) -> void:
	if not is_instance_valid(rb) or not rb.has_meta(&"resting_in"):
		return
	if rb.sleeping:
		_shapes_aside.call_deferred(rb)  # (asleep now, in the physics' flush: after)
		return
	_count("woken in its cell")
	if not _stirring_set.has(rb):
		_stirring_set[rb] = true  # (let go if it moves: _physics_process)
		_stirring.append(rb)


func _moved(rb: RigidBody3D, from: Transform3D) -> bool:
	var now_at := rb.global_transform
	var turned := now_at.basis.get_rotation_quaternion().angle_to(from.basis.get_rotation_quaternion())
	return now_at.origin.distance_to(from.origin) + turned * _reach(rb) > MOVED


## How far its farthest point is from its middle (its meshes' boxes), worked out once.
static func _reach(rb: RigidBody3D) -> float:
	if rb.has_meta(&"rest_reach"):
		return rb.get_meta(&"rest_reach")
	var r := 0.0
	for c: Node in rb.get_children():
		if c is MeshInstance3D:
			var box := (c as MeshInstance3D).transform * (c as MeshInstance3D).get_aabb()
			for i in 8:
				r = maxf(r, box.get_endpoint(i).length())
	if r <= 0.0:
		r = 0.5
	rb.set_meta(&"rest_reach", r)
	return r


func _physics_process(_delta: float) -> void:
	if _waiting.is_empty() and _pending.is_empty() and _stirring.is_empty() and _tidy.is_empty():
		return
	var t := Prof.start()
	var t_s := Prof.start()
	_look_at_stirring()
	Prof.stop(&"rr_stir", t_s)
	var t_j := Prof.start()
	var now := World.now()
	var budget := WorkBudget.new(JOIN_MS, JOIN_PIECES)
	var n := ceili(_look_queue.size() / maxf(LOOK_EVERY * Engine.physics_ticks_per_second, 1.0))
	for i in mini(n, _look_queue.size()):
		var o: Variant = _look_queue.pop_front()
		if not _waiting.has(o):
			continue  # (joined or let go since)
		if not is_instance_valid(o) or (o as Node).is_queued_for_deletion():
			_waiting.erase(o)
			continue
		var rb := o as RigidBody3D
		_look_queue.append(rb)
		var w: Array = _waiting[rb]
		budget.spend()
		if not rb.sleeping and not rb.freeze and _moved(rb, w[1]):
			_waiting[rb] = [maxf(now, float(w[0])), rb.global_transform]
		elif now - float(w[0]) >= REST_AFTER:
			var got := _join(rb)
			if got == LATER:
				_waiting[rb] = [now + HOLD - REST_AFTER, rb.global_transform]
			else:
				_waiting.erase(rb)
		if budget.over():
			break
	Prof.stop(&"rr_join", t_j)
	var t_b := Prof.start()
	for cell: Vector3i in _pending.keys():
		if now - float(_built_at.get(cell, -INF)) >= BUILD_GAP:
			_build(cell)
			_built_at[cell] = now
	Prof.stop(&"rr_build", t_b)
	var t_t := Prof.start()
	_tidy_up()
	Prof.stop(&"rr_tidy", t_t)
	Prof.stop(&"rubble_rest", t)


func _tidy_up() -> void:
	var budget := WorkBudget.new(JOIN_MS, JOIN_PIECES * 4)
	while not _tidy.is_empty() and not budget.over():
		var item: Array = _tidy.pop_front()
		budget.spend()
		if item.size() == 1:
			if is_instance_valid(item[0]):
				(item[0] as Node).queue_free()  # an old chunk's mesh
			continue
		var node: Variant = item[0]
		var rb: Variant = item[1]
		if not is_instance_valid(node) or not is_instance_valid(rb) or (node as Node).get_parent() != rb:
			continue
		var e: Variant = _rest.get((rb as Node).get_instance_id())
		if e == null or not is_same(e, item[2]):
			continue  # let go since: it draws itself again
		(rb as Node).remove_child(node)


## A share of the woken pieces in cells (each every STIR_TICKS ticks): moving, let go; still
## awake and not moving, looked at again later; asleep, done with.
func _look_at_stirring() -> void:
	var n := ceili(_stirring.size() / float(STIR_TICKS))
	for i in mini(n, _stirring.size()):
		var o: Variant = _stirring.pop_front()
		if not is_instance_valid(o) or not (o as Node).has_meta(&"resting_in") or (o as RigidBody3D).sleeping:
			_stirring_set.erase(o)
			continue
		var rb := o as RigidBody3D
		var why := ""
		if rb.linear_velocity.length_squared() > STIR_SPEED * STIR_SPEED:
			why = "let go: moving"
		elif rb.angular_velocity.length_squared() > STIR_SPIN * STIR_SPIN:
			why = "let go: turning"
		elif _moved(rb, (_rest[rb.get_instance_id()] as Dictionary).at):
			why = "let go: moved"
		if why == "":
			_stirring.append(rb)  # awake, not stirring: again in a while
			continue
		_stirring_set.erase(rb)
		_count(why)
		release(rb)  # (and it waits to lie still again)


func _join(rb: RigidBody3D) -> int:
	if not rb.is_inside_tree() or rb.is_queued_for_deletion():
		return _no(NEVER, "out of the world")
	var inv := global_transform.affine_inverse()
	var parts: Array = []
	var nodes: Array = []
	var kids := rb.get_children()
	for i in kids.size():
		var c: Node = kids[i]
		if c is CollisionShape3D:
			if (c as CollisionShape3D).shape == null:
				return _no(NEVER, "no shape")
			nodes.append([c, i])
		elif c is MeshInstance3D:
			nodes.append([c, i])
			if (c as MeshInstance3D).visible:
				var part: Variant = _part(c as MeshInstance3D, inv)
				if part is int:
					return part
				parts.append(part)
		else:
			return _no(LATER, "a %s on it" % c.get_class())  # its fire, a sound: not done yet
	if nodes.is_empty():
		return _no(NEVER, "nothing on it")
	var id := rb.get_instance_id()
	var cell := Vector3i(((inv * rb.global_position) / CELL).floor())
	# Its meshes go once its cell draws it (`_built`), or now if they're hidden; its shapes now if
	# it's asleep, else when it sleeps (`_shapes_aside`).
	for n: Array in nodes:
		(n[0] as Node).set_meta(&"rest_body", rb)
		if n[0] is MeshInstance3D and parts.is_empty():
			rb.remove_child(n[0])
	rb.set_meta(&"resting_in", self)
	_count("joined")
	var gone := _gone.bind(id)
	rb.tree_exiting.connect(gone, CONNECT_ONE_SHOT)
	_rest[id] = {"body": rb, "cell": cell, "parts": parts, "nodes": nodes, "owners": [], "gone": gone,
			"at": rb.global_transform}
	if rb.sleeping or rb.freeze:
		_shapes_aside(rb)
	if not parts.is_empty():
		(_pending.get_or_add(cell, {}) as Dictionary)[id] = true
	return JOINED


## [key, arrays in this node's space, non-indexed], or why not.
func _part(mi: MeshInstance3D, inv: Transform3D) -> Variant:
	var mesh := mi.mesh
	if mesh == null or mesh.get_surface_count() != 1 or mi.skin != null:
		return _no(NEVER, "mesh of %d surfaces" % (mesh.get_surface_count() if mesh else 0))
	if mesh is ArrayMesh and (mesh as ArrayMesh).get_blend_shape_count() > 0:
		return _no(NEVER, "blend shapes")
	var mat := mi.material_override if mi.material_override else mesh.surface_get_material(0)
	if mat == null or not joins(mat) or mi.transparency > 0.0:
		return _no(NEVER, "material %s" % (mat.shader.resource_path.get_file() if mat is ShaderMaterial and mat.shader else (mat.get_class() if mat else "none")))
	var over := mi.material_overlay
	if over != null:
		if not (over is ShaderMaterial and (over as ShaderMaterial).shader == Structure.CHAR_OVERLAY):
			return _no(NEVER, "overlay")
		if float((over as ShaderMaterial).get_shader_parameter(&"glow")) > 0.0:
			return _no(LATER, "alight")
	var st := SurfaceTool.new()
	st.append_from(mesh, 0, inv * mi.global_transform)
	st.deindex()
	var arrays := st.commit_to_arrays()
	if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
		return _no(NEVER, "no vertices")
	for slot: int in NOT_CHANNELS:
		if arrays[slot] != null:
			return _no(NEVER, "channel %d" % slot)
	var has := 0
	for slot: int in CHANNELS:
		if arrays[slot] != null:
			has |= 1 << slot
	var key := "%d|%d|%d|%d|%d" % [mat.get_instance_id(), over.get_instance_id() if over else 0, mi.cast_shadow, mi.layers, has]
	if not _keys.has(key):
		_keys[key] = [mat, over, mi.cast_shadow, mi.layers]
	return [key, arrays]


func _no(why: int, what: String) -> int:
	refused[what] = int(refused.get(what, 0)) + 1
	return why


func _count(what: String) -> void:
	counts[what] = int(counts.get(what, 0)) + 1


## Joined in a cell's mesh: the texel grid's UV and world mappings (a weathered mesh carries
## CUSTOM0, and no piece with custom channels joins: `_part`), or a plain material not mapped in
## its object's space (glass among them).
static func joins(mat: Material) -> bool:
	if mat is ShaderMaterial:
		var sm := mat as ShaderMaterial
		if sm.shader == null or not sm.shader.resource_path in TEXEL_SHADERS:
			return false
		return sm.get_shader_parameter(&"mapping") != PixelArt.Mapping.TRIPLANAR
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		return not (bm.uv1_triplanar and not bm.uv1_world_triplanar) and not bm.billboard_mode
	return false


## Its nodes back on its body where they were, and its stretch of its cell's mesh gone (now).
## `touched` (the fire, a break; not its waking): it was lying still, it lies still, and waits a
## while before joining again.
func release(rb: RigidBody3D, touched := false) -> void:
	if not is_instance_valid(rb):
		return
	var id := rb.get_instance_id()
	var e: Dictionary = _rest.get(id, {})
	if e.is_empty():
		return
	_leave(id, e)
	if rb.tree_exiting.is_connected(e.gone):
		rb.tree_exiting.disconnect(e.gone)
	var asleep := rb.sleeping
	_put_back(rb, e)
	if touched and asleep and rb.is_inside_tree():
		rb.sleeping = true
	if rb.is_inside_tree():
		_wait(rb, World.now() + (HOLD - REST_AFTER if touched else 0.0))


static func _put_back(rb: RigidBody3D, e: Dictionary) -> void:
	rb.remove_meta(&"resting_in")
	for o: int in e.owners:
		rb.remove_shape_owner(o)
	for n: Array in e.nodes:
		var node: Variant = n[0]
		if not is_instance_valid(node):
			continue
		(node as Node).remove_meta(&"rest_body")
		if (node as Node).is_queued_for_deletion() or (node as Node).get_parent() != null:
			continue  # (freed meanwhile: it goes, as it would have on the body; or never taken off)
		rb.add_child(node)
		rb.move_child(node, mini(int(n[1]), rb.get_child_count() - 1))


## Out of its cell: its stretch of its chunk's meshes zeroed (a chunk with none left goes); a job
## joining its cell is told (`_built` zeroes it in the new chunk).
func _leave(id: int, e: Dictionary) -> void:
	_rest.erase(id)
	var cell: Vector3i = e.cell
	if _pending.has(cell):
		(_pending[cell] as Dictionary).erase(id)
		if (_pending[cell] as Dictionary).is_empty():
			_pending.erase(cell)
	if _jobs.has(cell):
		((_jobs[cell] as Dictionary).left as Dictionary)[id] = true
	for ch: Dictionary in _chunks.get(cell, []):
		if (ch.live as Dictionary).has(id):
			_zero(ch.live[id])
			(ch.live as Dictionary).erase(id)
			if (ch.live as Dictionary).is_empty() and not _merging(cell, ch):
				_drop_chunk(cell, ch)
			return


## Is it drawn by its cell (not by itself)? (Tests.)
func drawn_by_cell(rb: RigidBody3D) -> bool:
	var e: Dictionary = _rest.get(rb.get_instance_id(), {})
	if e.is_empty():
		return false
	for ch: Dictionary in _chunks.get(e.cell, []):
		if (ch.live as Dictionary).has(rb.get_instance_id()):
			return true
	return false


## Is the chunk one a job is making a cell's new chunk from (it's dropped when that's in)?
func _merging(cell: Vector3i, ch: Dictionary) -> bool:
	return _jobs.has(cell) and _index_of(((_jobs[cell] as Dictionary).old as Array), ch) >= 0


## Where `item` itself is in `list` (-1: not there). Array.has and erase compare dictionaries by
## their contents, every key and value: a chunk's are its meshes and pieces.
static func _index_of(list: Array, item: Variant) -> int:
	for i in list.size():
		if is_same(list[i], item):
			return i
	return -1


static func _erase_same(list: Array, item: Variant) -> void:
	var i := _index_of(list, item)
	if i >= 0:
		list.remove_at(i)


func _drop_chunk(cell: Vector3i, ch: Dictionary) -> void:
	for mi: Variant in (ch.meshes as Dictionary).values():
		if is_instance_valid(mi):
			(mi as Node).queue_free()
	var list: Array = _chunks.get(cell, [])
	_erase_same(list, ch)
	if list.is_empty():
		_chunks.erase(cell)


## Its body is leaving the tree (freed with it, mostly): its nodes go with it, after.
func _gone(id: int) -> void:
	var e: Dictionary = _rest.get(id, {})
	if e.is_empty():
		return
	_leave(id, e)
	_leaving[id] = e
	_after_gone.call_deferred(id)


func _after_gone(id: int) -> void:
	var e: Dictionary = _leaving.get(id, {})
	_leaving.erase(id)
	if e.is_empty():
		return
	if is_instance_valid(e.body):
		_put_back(e.body as RigidBody3D, e)  # taken out, not freed (moved elsewhere): whole again
		return
	for n: Array in e.nodes:
		if is_instance_valid(n[0]) and not (n[0] as Node).is_inside_tree():
			(n[0] as Node).free()


## The cell's pieces joined since its last chunk, drawn as a new chunk; past MAX_CHUNKS, every
## piece in the cell as one chunk again. Their arrays are grouped and joined on a worker (`_built`
## when done): till then the old chunks draw what they drew and the new pieces draw themselves.
func _build(cell: Vector3i) -> void:
	if _jobs.has(cell):
		return  # (one at a time a cell: the next when it's in)
	var new_ids: Array = (_pending.get(cell, {}) as Dictionary).keys()
	_pending.erase(cell)
	var ids := new_ids.duplicate()
	var old: Array = []
	var list: Array = _chunks.get(cell, [])
	if list.size() >= MAX_CHUNKS:
		old = list.duplicate()
		for ch: Dictionary in old:
			ids.append_array((ch.live as Dictionary).keys())
	var items: Array = []
	for id: int in ids:
		if _rest.has(id):
			items.append([id, (_rest[id] as Dictionary).parts])
	if items.is_empty():
		return
	var fresh := {}  # id -> its entry (gone or joined again since: not this one)
	for id: int in new_ids:
		if _rest.has(id):
			fresh[id] = _rest[id]
	var job := {"cell": cell, "fresh": fresh, "old": old, "left": {}, "out": {}, "task": -1}
	_jobs[cell] = job
	if World.deterministic or GameQuit.quitting:
		job.out = _group_and_concat(items)
		_built(cell)
		return
	job.task = WorkerThreadPool.add_task(func() -> void:
		job.out = _group_and_concat(items)
		_built.call_deferred(cell), true, "rubble cell")  # high priority: a low one can hang the quit (#392, #435)


## The pieces' arrays by key, each key's joined (on a worker: pure data).
static func _group_and_concat(items: Array) -> Dictionary:
	var joined := {}  # key -> [[id, arrays]]
	for it: Array in items:
		for p: Array in it[1]:
			(joined.get_or_add(p[0], []) as Array).append([it[0], p[1]])
	return _concat_all(joined)


## Each key's pieces joined (on a worker: pure data). key -> [arrays, [[id, first, count]]]
static func _concat_all(joined: Dictionary) -> Dictionary:
	var out := {}
	for key: String in joined:
		var ranges: Array = []
		out[key] = [_concat(joined[key], ranges), ranges]
	return out


## A cell's new chunk in: its meshes made (a few a frame, hidden till all are), then its pieces
## drawn by it (their own meshes off now), the chunks it was made from gone, anything let go
## meanwhile zeroed in it.
func _built(cell: Vector3i) -> void:
	var job: Dictionary = _jobs.get(cell, {})
	if job.is_empty():
		return
	if int(job.task) >= 0:
		WorkerThreadPool.wait_for_task_completion(int(job.task))
		job.task = -1
	if not is_inside_tree():
		_jobs.erase(cell)
		return
	var t := Prof.start()
	var t0 := Time.get_ticks_usec()
	var ch: Dictionary = job.get_or_add("chunk", {"meshes": {}, "live": {}})
	var drawn: Dictionary = job.get_or_add("drawn", {})  # id -> [[mesh, first, count]]
	for key: String in job.out:
		if (ch.meshes as Dictionary).has(key):
			continue
		if not World.deterministic and (Time.get_ticks_usec() - t0) / 1000.0 > MESH_MS:
			Prof.stop(&"rr_mesh", t)
			var next: Callable = job.get_or_add("next", _built.bind(cell))
			if not get_tree().process_frame.is_connected(next):
				get_tree().process_frame.connect(next, CONNECT_ONE_SHOT)  # (the rest next frame)
			return
		var arrays: Array = job.out[key][0]
		var mi := MeshInstance3D.new()
		mi.name = "Cell"
		var k: Array = _keys[key]
		mi.material_override = k[0]
		mi.material_overlay = k[1]
		mi.cast_shadow = k[2]
		mi.layers = k[3]
		mi.visible = false
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mi.mesh = mesh
		add_child(mi)
		(ch.meshes as Dictionary)[key] = mi
		for r: Array in job.out[key][1]:
			(drawn.get_or_add(int(r[0]), []) as Array).append([mesh, r[1], r[2]])
	_jobs.erase(cell)
	var t_f := Prof.start()
	for mi: MeshInstance3D in (ch.meshes as Dictionary).values():
		mi.visible = true
	for ch_old: Dictionary in job.old:
		for mi: Variant in (ch_old.meshes as Dictionary).values():
			if is_instance_valid(mi):
				(mi as MeshInstance3D).visible = false
				_tidy.append([mi])
		_erase_same(_chunks.get(cell, []) as Array, ch_old)
	for id: int in job.left:
		if drawn.has(id):
			_zero(drawn[id])  # let go meanwhile: not drawn here
			drawn.erase(id)
	ch.live = drawn
	for id: int in job.fresh:
		var e: Dictionary = job.fresh[id]
		if not is_same(_rest.get(id), e):
			continue
		var rb: RigidBody3D = e.body
		for n: Array in e.nodes:
			if n[0] is MeshInstance3D and (n[0] as Node).get_parent() == rb:
				_tidy.append([n[0], rb, e])
	if (ch.live as Dictionary).is_empty():
		_drop_chunk(cell, ch)
	else:
		(_chunks.get_or_add(cell, []) as Array).append(ch)
	Prof.stop(&"rr_final", t_f)
	Prof.stop(&"rr_mesh", t)


## A tool's worker still joining a cell's arrays (GameQuit waits for it).
func running() -> bool:
	for job: Dictionary in _jobs.values():
		if int(job.task) >= 0 and not WorkerThreadPool.is_task_completed(int(job.task)):
			return true
	return false


func _zero(drawn: Array) -> void:
	for d: Array in drawn:
		var mesh := d[0] as ArrayMesh
		if mesh == null:
			continue
		var stride := RenderingServer.mesh_surface_get_format_vertex_stride(mesh.surface_get_format(0), mesh.surface_get_array_len(0))
		var zeros := PackedByteArray()
		zeros.resize(int(d[2]) * stride)
		RenderingServer.mesh_surface_update_vertex_region(mesh.get_rid(), 0, int(d[1]) * stride, zeros)


## The pieces' arrays one after another (each channel the first's has), and each piece's stretch.
static func _concat(list: Array, ranges: Array) -> Array:
	var first: Array = list[0][1]
	var out: Array = []
	out.resize(Mesh.ARRAY_MAX)
	for slot: int in CHANNELS:
		if first[slot] == null:
			continue
		var into: Variant = first[slot].duplicate()
		into.clear()
		for e: Array in list:
			into.append_array((e[1] as Array)[slot])
		out[slot] = into
	var at := 0
	for e: Array in list:
		var n: int = ((e[1] as Array)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		ranges.append([e[0], at, n])
		at += n
	return out


func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	for job: Dictionary in _jobs.values():
		if int(job.task) >= 0:
			WorkerThreadPool.wait_for_task_completion(int(job.task))
	_jobs.clear()
	# Freed with its world: what it kept aside goes too.
	for e: Dictionary in _rest.values() + _leaving.values():
		for n: Array in e.nodes:
			if is_instance_valid(n[0]) and not (n[0] as Node).is_inside_tree():
				(n[0] as Node).free()
