extends RefCounted
## tools/member_memory.gd's measuring (#1259), loaded at run time (the structures need the autoloads).
## Also used by tests/test_member_memory.gd.

const SpecBuilding := preload("res://src/structures/spec_building.gd")


static func mem() -> float:
	return OS.get_static_memory_usage() / 1024.0


## Peak and current RSS in KB (Linux; 0 elsewhere).
static func rss() -> Vector2:
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	if f == null:
		return Vector2.ZERO
	var out := Vector2.ZERO
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("VmHWM:"):
			out.x = float(line.split(":")[1].strip_edges().split(" ")[0])
		elif line.begins_with("VmRSS:"):
			out.y = float(line.split(":")[1].strip_edges().split(" ")[0])
	return out


## A spec built on its own under `parent`: the phases as they add, then the parts as they're taken
## away. Returns a dictionary of KB (whole and a member) by part.
static func measure(parent: Node, spec_path: String) -> Dictionary:
	var phases := {}
	var t0 := mem()
	var rss0 := rss()
	var b := MeasuredBuilding.new()
	b.spec_path = spec_path
	b.structure_id = StringName(spec_path.get_file().get_basename() + "_spec")
	b.mem_marks = phases
	parent.add_child(b)
	for i in 3:
		await parent.get_tree().process_frame
	# The batches' shadow is made on a worker: wait for it.
	if b._shadow_task >= 0:
		WorkerThreadPool.wait_for_task_completion(b._shadow_task)
		b._shadow_task = -1
	for i in 3:
		await parent.get_tree().process_frame
	var whole := mem() - t0
	var n := b.member_count()
	var peak := rss()
	var counts: Dictionary = b.counts
	var parts := take_apart(b)
	var r := {"spec": spec_path, "members": n, "whole_kb": whole, "kb_per_member": whole / maxf(n, 1),
		"peak_rss_mb": peak.x / 1024.0, "rss_added_mb": (peak.y - rss0.y) / 1024.0, "phases_kb": {}, "parts_kb": {}, "counts": counts}
	var last := 0.0
	for k in ["build", "age", "supports", "settle_in", "batches"]:
		if phases.has(k):
			r.phases_kb[k] = float(phases[k]) - t0 - last
			last = float(phases[k]) - t0
	var sum := 0.0
	for k: String in parts:
		r.parts_kb[k] = parts[k]
		sum += float(parts[k])
	r.parts_kb["(rest: script statics, materials, caches)"] = whole - sum
	return r


## The finished building taken apart a part at a time, each drop the part's cost.
static func take_apart(b: Structure) -> Dictionary:
	var out := {}
	var at := [mem()]  # (a lambda captures by value: the array is shared)
	var step := func(name: String) -> void:
		var now := mem()
		out[name] = float(at[0]) - now
		at[0] = now
	# The batches: the arrays kept to remake them, then their meshes, nodes and the shadow.
	b._batch_arrays.clear()
	step.call("batch arrays (CPU copy)")
	if b._shadow:
		b._shadow.mesh = null
	if b._inst_shadow_node:
		b._inst_shadow_node.multimesh = null
	b._inst_shadow.clear()
	for key in b._batches:
		var bn: Node = b._batches[key]
		if bn is MeshInstance3D:
			(bn as MeshInstance3D).mesh = null
		elif bn is MultiMeshInstance3D:
			(bn as MultiMeshInstance3D).multimesh = null
	step.call("batch + shadow meshes")
	b._clear_batches()
	step.call("batch nodes and lists")
	# The support graph and what the analysis keeps.
	for m: StructureMember in b.get_members():
		m.supported_by = []
		m.dependents = []
		m.support_points = {}
		m.support_boxes = {}
		m.touching = []
		m.analysis_cache = {}
		m.extra_points = PackedVector2Array()
	b.last_analysis = null
	b._records.clear()
	b._record_stale.clear()
	b._by_stack.clear()
	step.call("support graph")
	# Each member's mesh and shape resources (shared ones go when the last member lets go).
	var mis: Array[MeshInstance3D] = []
	var css: Array[CollisionShape3D] = []
	var rows: Array[StructureMember] = []  # resting with their nodes freed (#1262): a row of data each
	for m: StructureMember in b.get_members():
		if m._rest_data != null:
			rows.append(m)
			continue
		m.realise()
		for c in m.get_children():
			if c is MeshInstance3D:
				mis.append(c)
			elif c is CollisionShape3D:
				css.append(c)
		m.pieces = []
	for mi in mis:
		mi.mesh = null
		mi.material_override = null
	for m in rows:
		m._rest_data[1] = null
		m._rest_data[2] = null
	step.call("member meshes")
	for cs in css:
		cs.shape = null
	for m in rows:
		m.remove_shape_owner(m._rest_owner)
		m._rest_owner = -1
	b._shape_cache.clear()
	step.call("member shapes")
	for mi in mis:
		mi.free()
	step.call("MeshInstance3D nodes")
	for cs in css:
		cs.free()
	step.call("CollisionShape3D nodes")
	for m in rows:
		m._rest_data = null
	step.call("resting members' rows (their nodes freed)")
	var ms: Array[StructureMember] = b.get_members().duplicate()
	for m in ms:
		b.remove_child(m)
	step.call("bodies in the space")
	b.members.clear()
	b._order.clear()
	for m in ms:
		m.free()
	ms.clear()
	step.call("StructureMember nodes (body, script)")
	for c in b.get_children():
		c.free()
	step.call("other children (lamps, kit props, dressing)")
	if OS.has_environment("MM_CENSUS"):
		load("res://build/probe_lib2.gd").census(b)
	b.free()
	step.call("the structure (its own lists and spec)")
	MemberMesh._cache.clear()
	PropKit._shared_boards.clear()
	PropKit._made.clear()
	step.call("mesh caches (MemberMesh, PropKit)")
	return out


static func print_report(r: Dictionary) -> void:
	var n: int = r.members
	print("%s: %d members, %.0f MB static (%.1f KB a member); peak RSS %.0f MB (+%.0f MB)" % [
		r.spec, n, float(r.whole_kb) / 1024.0, r.kb_per_member, r.peak_rss_mb, r.rss_added_mb])
	print("  counts: %s" % [r.counts])
	print("  as built (phase: MB, KB a member):")
	for k: String in r.phases_kb:
		print("    %-14s %8.1f MB %7.2f KB" % [k, float(r.phases_kb[k]) / 1024.0, float(r.phases_kb[k]) / n])
	print("  taken apart (part: MB, KB a member):")
	for k: String in r.parts_kb:
		print("    %-44s %8.1f MB %7.2f KB" % [k, float(r.parts_kb[k]) / 1024.0, float(r.parts_kb[k]) / n])


## SpecBuilding with its rebuild's phases marked.
class MeasuredBuilding:
	extends SpecBuilding
	var mem_marks: Dictionary
	var counts := {}

	func rebuild() -> void:
		_clear_batches()
		_rng.seed = build_seed
		build()
		mem_marks["build"] = OS.get_static_memory_usage() / 1024.0
		BuildingAge.alter(self)
		mem_marks["age"] = OS.get_static_memory_usage() / 1024.0
		infer_supports()
		mem_marks["supports"] = OS.get_static_memory_usage() / 1024.0
		BuildingAge.settle_in(self)
		bounds()
		mem_marks["settle_in"] = OS.get_static_memory_usage() / 1024.0
		_batch_all()
		mem_marks["batches"] = OS.get_static_memory_usage() / 1024.0
		var meshes := {}
		var verts := 0
		var rows := 0
		for m: StructureMember in get_members():
			var mesh := m.drawn_mesh()  # (not drawn_node: that makes a resting member's nodes again)
			if mesh:
				meshes[mesh] = true
			if m._rest_data != null:
				rows += 1
		for mesh: Mesh in meshes:
			verts += mesh.surface_get_array_len(0)
		var bverts := 0
		var instances := 0
		for k in _batches:
			if _batches[k] is MultiMeshInstance3D:
				instances += (_batches[k] as MultiMeshInstance3D).multimesh.instance_count
			else:
				bverts += ((_batches[k] as MeshInstance3D).mesh as ArrayMesh).surface_get_array_len(0)
		counts = {"distinct_member_meshes": meshes.size(), "their_vertices": verts, "batches": _batches.size(),
			"batch_vertices": bverts, "board_instances": instances, "resting_as_rows": rows}
