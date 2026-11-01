extends TestCase
## Batches rebuilt off the main thread, within one drawn frame's budget for every structure (#459:
## after a stick `batches` was 90-163 ms a frame for seconds, each structure its own 6 ms on each
## physics tick): a piece's members merged on a worker come out as the SurfaceTool made them; a
## cut's new ends join their material's batch.

var world: Node3D
var store: FalseFrontBuilding


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	store = FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	store.collapses = false
	world.add_child(store)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _a_board() -> StructureMember:
	for m in store.get_members():
		if m.kind == &"board" and store._batched.has(m):
			return m
	return null


## The merge (on a worker) and the SurfaceTool's (on this thread) make the same mesh of a piece.
func test_the_workers_merge_is_the_surface_tools() -> void:
	var m := _a_board()
	var key: Array = store._batched[m]
	var list: Array = store._batch_members[key]
	var st := SurfaceTool.new()
	for o: StructureMember in list:
		var mi := o.drawn_node()
		st.append_from(mi.mesh, 0, o.transform * mi.transform)
	var want := st.commit_to_arrays()
	var inputs: Variant = store._member_inputs(list)
	check(inputs != null, "the merge takes a building's boards")
	if inputs == null:
		return
	var got := Structure._merge_members(inputs, false)
	var wv: PackedVector3Array = want[Mesh.ARRAY_VERTEX]
	var gv: PackedVector3Array = got[Mesh.ARRAY_VERTEX]
	check_eq(gv.size(), wv.size(), "as many vertices")
	check_eq((got[Mesh.ARRAY_INDEX] as PackedInt32Array), (want[Mesh.ARRAY_INDEX] as PackedInt32Array), "the same triangles")
	var worst := 0.0
	for i in mini(gv.size(), wv.size()):
		worst = maxf(worst, gv[i].distance_to(wv[i]))
	check(worst < 1e-4, "in the same places (worst %.6f m)" % worst)
	var wn: PackedVector3Array = want[Mesh.ARRAY_NORMAL]
	var gn: PackedVector3Array = got[Mesh.ARRAY_NORMAL]
	var worst_n := 0.0
	for i in mini(gn.size(), wn.size()):
		worst_n = maxf(worst_n, gn[i].distance_to(wn[i]))
	check(worst_n < 1e-3, "facing the same way (worst %.5f)" % worst_n)
	check_eq((got[Mesh.ARRAY_TEX_UV] as PackedVector2Array), (want[Mesh.ARRAY_TEX_UV] as PackedVector2Array), "the same texture coordinates")
	if want[Mesh.ARRAY_TANGENT] != null:
		var wt: PackedFloat32Array = want[Mesh.ARRAY_TANGENT]
		var gt: PackedFloat32Array = got[Mesh.ARRAY_TANGENT] if got[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
		var worst_t := 0.0 if gt.size() == wt.size() else INF
		for i in mini(gt.size(), wt.size()):
			worst_t = maxf(worst_t, absf(gt[i] - wt[i]))
		check(worst_t < 1e-3, "the same tangents (worst %.5f)" % worst_t)


## A member unbatched: its batch is rebuilt without it (on a worker) and it's drawn on its own.
func test_an_unbatched_member_leaves_its_batch() -> void:
	var m := _a_board()
	var key: Array = store._batched[m]
	var before := ((store._batches[key] as MeshInstance3D).mesh as ArrayMesh).surface_get_array_len(0)
	var own := (m.drawn_node().mesh as ArrayMesh).surface_get_array_len(0)
	store.unbatch(m)
	for i in 30:
		await physics_frames(1)
		if store._batch_task < 0 and store._batch_dirty.is_empty():
			break
	check(not store._batched.has(m), "out of its batch")
	check((m.get_child(0) as MeshInstance3D).visible, "drawn on its own")
	var after := ((store._batches[key] as MeshInstance3D).mesh as ArrayMesh).surface_get_array_len(0)
	check_eq(after, before - own, "its batch drawn without it")


## A cut's ends are new members: each goes into a batch of its material and is drawn by it.
func test_a_cuts_ends_join_their_materials_batch() -> void:
	var m := _a_board()
	var left := store.cut_member(m, -0.1, 0.1)
	check(not left.is_empty(), "the cut leaves its ends")
	for p in left:
		check(store._batched.has(p), "%s in a batch" % p.member_id)
	for i in 30:
		await physics_frames(1)
		if store._batch_task < 0 and store._batch_dirty.is_empty():
			break
	for p in left:
		check(p.resting(), "%s drawn by its batch (its own nodes aside)" % p.member_id)


## Many batches dirty at once in many structures: the main thread's share of a drawn frame stays
## inside the budget (under World.deterministic the count of members instead).
func test_the_rebuild_keeps_to_its_frame() -> void:
	var stores: Array[FalseFrontBuilding] = [store]
	for k in 3:
		var s := FalseFrontBuilding.new()
		s.structure_id = StringName("store%d" % k)
		s.build_seed = 7 + k
		s.collapses = false
		s.position = Vector3(30.0 * (k + 1), 0, 0)
		world.add_child(s)
		stores.append(s)
	await physics_frames(2)
	for s in stores:
		for key: Array in s._batch_members:
			s._dirty_batch(key)
	var frame := Engine.get_process_frames()
	for s in stores:
		s._rebuild_dirty_batches()
	check(Structure._batch_frame == frame, "counted against this frame")
	var ms := Structure._batch_frame_us / 1000.0
	print("    main thread this frame: %.1f ms over %d structures (budget %.1f)" % [ms, stores.size(), Structure.BATCH_FRAME_MS])
	check(ms < Structure.BATCH_FRAME_MS + 3.0, "within the frame's budget, give or take the last piece (%.1f ms)" % ms)
	var left := 0
	for s in stores:
		left += s._batch_dirty.size()
	check(left > 0, "the rest wait for later frames (%d batches)" % left)
	for i in 240:
		await physics_frames(1)
		left = 0
		for s in stores:
			left += s._batch_dirty.size() + (1 if s._batch_task >= 0 else 0)
		if left == 0:
			break
	check_eq(left, 0, "and all of them get done")
