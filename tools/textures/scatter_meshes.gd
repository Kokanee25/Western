extends SceneTree
## The valley scatter's meshes (#891; ValleyScatter): each Poly Haven model's pieces (assets/props/scans/<id>/,
## fetched by .github/workflows/scans.yml) cut to two levels of detail, a near one and a far one, by
## Godot's own simplifier (ImporterMesh.generate_lods), its vertices compacted, saved beside the model
## as <piece>_near.res and <piece>_far.res (ArrayMesh, the model's own material). A scan's 15-90k
## triangles drawn hundreds of times would not fit the frame; these keep what reads at their range.
##
##   godot --headless -s res://tools/textures/scatter_meshes.gd
##
## And the trees ValleyTrees builds, baked to assets/props/trees/. Plants keep their own near mesh (a simplifier collapses leaf and blade cards into twigs) and are cut
## only a little far off. Re-run when a model or a target below changes. Untyped where it names game classes.

## id -> [near triangles, far triangles] a piece (at most; a piece with fewer keeps its own).
const TARGETS := {
	"namaqualand_boulder_03": [6000, 900],
	"namaqualand_boulder_05": [5000, 800],
	"rock_07": [3000, 500],
	"namaqualand_rocks_01": [1500, 250],
	"namaqualand_stones_01": [600, 120],
	"grass_medium_02": [100000, 700],
	"wild_rooibos_bush": [100000, 2500],
	"dead_tree_trunk_02": [5000, 800],
}

var _done := false


func _process(_d: float) -> bool:
	if not _done:
		_done = true
		_run()
		quit(0)
	return false


func _run() -> void:
	# The trees built in code (ValleyTrees), baked so the game loads them rather than building them.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/props/trees"))
	var trees = load("res://src/art/valley_trees.gd")
	for kind in [&"pine", &"cottonwood"]:
		for v in trees.VARIANTS:
			for near in [true, false]:
				var t: Dictionary = trees.build(kind, near, v)
				var base: String = trees.baked_path(kind, near, v)
				ResourceSaver.save(t.trunk, base + "_trunk.res", ResourceSaver.FLAG_COMPRESS)
				ResourceSaver.save(t.crown, base + "_crown.res", ResourceSaver.FLAG_COMPRESS)
				print("tree %s: %d + %d triangles" % [base.get_file(), _tris(t.trunk), _tris(t.crown)])
	for id: String in TARGETS:
		var dir := "res://assets/props/scans/%s/" % id
		var ps: PackedScene = load(dir + id + ".gltf")
		var root := ps.instantiate()
		var pieces := {}
		for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			pieces[String(mi.name)] = mi
		var names := pieces.keys()
		names.sort()
		var n := 0
		for name: String in names:
			var mi: MeshInstance3D = pieces[name]
			var near := _cut(mi.mesh, int(TARGETS[id][0]))
			var far := _cut(mi.mesh, int(TARGETS[id][1]))
			var base := "%s%s" % [dir, name.to_lower()]
			ResourceSaver.save(near, base + "_near.res", ResourceSaver.FLAG_COMPRESS)
			ResourceSaver.save(far, base + "_far.res", ResourceSaver.FLAG_COMPRESS)
			print("%s %s: %d -> %d / %d triangles" % [id, name, _tris(mi.mesh), _tris(near), _tris(far)])
			n += 1
		root.free()


func _tris(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		var idx = a[Mesh.ARRAY_INDEX]
		t += (idx.size() if idx != null and idx.size() > 0 else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t


## The mesh with every surface simplified toward `target` triangles in all (shared by the surfaces as
## they share the triangles now), vertices compacted to those the kept triangles use.
func _cut(m: Mesh, target: int) -> ArrayMesh:
	var total := _tris(m)
	var out := ArrayMesh.new()
	for s in m.get_surface_count():
		var arrays: Array = m.surface_get_arrays(s)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var want := maxi(12, int(float(target) * (idx.size() / 3.0) / maxf(total, 1.0)))
		var best := idx
		if idx.size() / 3 > want:
			var im := ImporterMesh.new()
			var clean := arrays.duplicate()
			im.add_surface(Mesh.PRIMITIVE_TRIANGLES, clean)
			im.generate_lods(25.0, 60.0, [])
			for k in im.get_surface_lod_count(0):
				var li: PackedInt32Array = im.get_surface_lod_indices(0, k)
				best = li
				if li.size() / 3 <= want:
					break
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _compact(arrays, best))
		out.surface_set_material(out.get_surface_count() - 1, m.surface_get_material(s))
	return out


func _compact(arrays: Array, idx: PackedInt32Array) -> Array:
	var remap := {}
	var order := PackedInt32Array()
	var new_idx := PackedInt32Array()
	new_idx.resize(idx.size())
	for k in idx.size():
		var v := idx[k]
		if not remap.has(v):
			remap[v] = order.size()
			order.append(v)
		new_idx[k] = remap[v]
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	for a in Mesh.ARRAY_MAX:
		var src = arrays[a]
		if src == null or a == Mesh.ARRAY_INDEX:
			continue
		var per := 1
		if a == Mesh.ARRAY_TANGENT:
			per = 4
		elif a == Mesh.ARRAY_BONES or a == Mesh.ARRAY_WEIGHTS:
			continue
		var dst = src.duplicate()
		dst.resize(order.size() * per)
		for k in order.size():
			for c in per:
				dst[k * per + c] = src[order[k] * per + c]
		out[a] = dst
	out[Mesh.ARRAY_INDEX] = new_idx
	return out
