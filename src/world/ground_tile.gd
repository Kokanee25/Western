class_name GroundTile
extends StaticBody3D
## One dug tile of the ground (Ground, docs/briefs/dig-ground.md): `tile_cells` cells a side, its
## heights (above the authored ground, at the cells' corners: one more a side than cells, the edges
## shared with the next tile's) as a Jolt height field and a mesh in the ground's material. A height
## field has no thickness, and a small thing moving fast (a bone fragment, a chip: 10 cm a tick)
## goes through it, so under it the earth is solid: a box a column of COLUMN cells, its top just
## under the lowest of the surface over it, down through the hardpan. Its own body, so an edit
## rebuilds only this tile's shapes.

## Cells a side of the solid earth's columns under the surface (8: 40 cm at 5 cm cells).
const COLUMN := 8

var key: Vector2i
## (tile_cells + 1)² heights, row by row along x, rows along z (m, above the authored ground).
var heights := PackedFloat32Array()
## The authored ground's height at each point (TownLayout.ground_height; empty where it's flat):
## the surface is it plus `heights`, so digging works in heights above it, wherever it stands.
var base := PackedFloat32Array()
## How deep the loose earth (thrown, shovelled) lies on the packed at each point (m); part of the
## height above.
var loose := PackedFloat32Array()

var _n := 0  # points a side
var _cell := 0.05
var _depth := 2.0
var _slab := 10.0
var _columns: Array[CollisionShape3D] = []
var _shape: HeightMapShape3D
var _mesh: MeshInstance3D


static func make(ground: Ground, at: Vector2i) -> GroundTile:
	var t := GroundTile.new()
	t.key = at
	t.name = "Tile_%d_%d" % [at.x, at.y]
	var tn := ground.tuning
	t._cell = tn.cell
	t._n = tn.tile_cells + 1
	t.heights.resize(t._n * t._n)
	t.loose.resize(t._n * t._n)
	t._depth = tn.earth_depth
	t.collision_layer = ground.collision_layer
	t.collision_mask = ground.collision_mask
	for m in [&"ground", &"surface"]:
		t.set_meta(m, ground.get_meta(m))
	var size := tn.tile_size()
	t.position = Vector3((at.x + 0.5) * size, 0.0, (at.y + 0.5) * size)
	# The authored ground under it, where it climbs (highest at its north-west corner): its height
	# times a factor along and one across (TownLayout.ground_height).
	if TownLayout.ground_height(at.x * size, at.y * size) != 0.0:
		var along := PackedFloat32Array()
		var across := PackedFloat32Array()
		for i in t._n:
			along.append(TownLayout.rise_along(at.x * size + i * tn.cell))
			across.append(TownLayout.rise_across(at.y * size + i * tn.cell))
		var height := float(TownLayout.rise().height)
		t.base.resize(t._n * t._n)
		for j in t._n:
			for i in t._n:
				t.base[j * t._n + i] = height * along[i] * across[j]
	# The height field: Godot centres it on its shape's origin with points 1 apart, so scaled to the
	# cell (Jolt takes a scaled height field on a static body).
	t._shape = HeightMapShape3D.new()
	t._shape.map_width = t._n
	t._shape.map_depth = t._n
	var cs := CollisionShape3D.new()
	cs.name = "Earth"
	cs.shape = t._shape
	cs.scale = Vector3(tn.cell, 1.0, tn.cell)
	t.add_child(cs)
	t._slab = tn.slab_depth
	var cols := ceili(float(tn.tile_cells) / COLUMN)
	for k in cols * cols:
		var col := CollisionShape3D.new()
		col.name = "Earth%d" % k
		col.shape = BoxShape3D.new()
		t.add_child(col)
		t._columns.append(col)
	t._mesh = MeshInstance3D.new()
	t._mesh.name = "Mesh"
	t.add_child(t._mesh)
	t.rebuild(ground.material)
	return t


## The point (i along x, j along z) as an index into `heights`.
func index(i: int, j: int) -> int:
	return j * _n + i


## A point's place in the world (its height included).
func point(i: int, j: int) -> Vector3:
	var half := (_n - 1) * 0.5
	return global_transform * Vector3((i - half) * _cell, surface(index(i, j)), (j - half) * _cell)


## The surface's height at point `k` (the authored ground's and what's above it).
func surface(k: int) -> float:
	return heights[k] + base[k] if not base.is_empty() else heights[k]


## Every point's surface.
func _surface() -> PackedFloat32Array:
	if base.is_empty():
		return heights
	var out := heights.duplicate()
	for k in out.size():
		out[k] += base[k]
	return out


## Shape and mesh from `heights`, after an edit.
func rebuild(material: Material) -> void:
	_shape.map_data = _surface()
	_mesh.mesh = _grid_mesh(material)
	_rebuild_columns()


## The solid earth under the surface: each column's box from the hardpan's foot up to 1 cm under
## the lowest point of the surface over it.
func _rebuild_columns() -> void:
	var half := (_n - 1) * 0.5
	var cols := ceili(float(_n - 1) / COLUMN)
	var bottom := -_depth - _slab
	var surf := _surface()
	for cj in cols:
		for ci in cols:
			var i0 := ci * COLUMN
			var j0 := cj * COLUMN
			var i1 := mini(i0 + COLUMN, _n - 1)
			var j1 := mini(j0 + COLUMN, _n - 1)
			var low := INF
			for j in range(j0, j1 + 1):
				for i in range(i0, i1 + 1):
					low = minf(low, surf[index(i, j)])
			var top := low - 0.01
			var col := _columns[cj * cols + ci]
			(col.shape as BoxShape3D).size = Vector3((i1 - i0) * _cell, top - bottom, (j1 - j0) * _cell)
			col.position = Vector3(((i0 + i1) * 0.5 - half) * _cell, (top + bottom) * 0.5, ((j0 + j1) * 0.5 - half) * _cell)


## The tile as a grid of quads, each split corner to corner as its height field is, normals from
## the heights round each point (central differences). COLOR is for the ground's look (art's):
## r the loose earth's depth (full at 20 cm), g kept for how freshly it was turned, b how far below
## the authored ground (full at the hardpan). What every tile of a size shares (the grid's x and z,
## its triangles, the tangents) is made once.
func _grid_mesh(material: Material) -> ArrayMesh:
	var shared := _shared(_n, _cell)
	var verts: PackedVector3Array = (shared.grid as PackedVector3Array).duplicate()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	normals.resize(_n * _n)
	colors.resize(_n * _n)
	var n := _n
	var last := n - 1
	var inv2 := 0.5 / _cell
	var inv1 := 1.0 / _cell
	var inv_loose := 1.0 / 0.2
	var inv_depth := 1.0 / _depth
	var surf := _surface()
	var k := 0
	for j in n:
		var up := -n if j > 0 else 0
		var dn := n if j < last else 0
		var sz := inv2 if (j > 0 and j < last) else inv1
		for i in n:
			var h := heights[k]
			verts[k].y = surf[k]
			var l := -1 if i > 0 else 0
			var r := 1 if i < last else 0
			var sx := inv2 if (i > 0 and i < last) else inv1
			normals[k] = Vector3((surf[k + l] - surf[k + r]) * sx, 1.0, (surf[k + up] - surf[k + dn]) * sz).normalized()
			colors[k] = Color(minf(loose[k] * inv_loose, 1.0), 0.0, clampf(-h * inv_depth, 0.0, 1.0))
			k += 1
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = shared.tangents
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = shared.index
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material:
		mesh.surface_set_material(0, material)
	return mesh


static var _shared_cache := {}


## The grid's points at height 0 (centred), its triangles and tangents, for `n` points a side.
static func _shared(n: int, cell: float) -> Dictionary:
	var key := Vector2(n, cell)
	if _shared_cache.has(key):
		return _shared_cache[key]
	var half := (n - 1) * 0.5
	var grid := PackedVector3Array()
	var tangents := PackedFloat32Array()
	for j in n:
		for i in n:
			grid.append(Vector3((i - half) * cell, 0.0, (j - half) * cell))
			tangents.append_array([1.0, 0.0, 0.0, 1.0])
	var idx := PackedInt32Array()
	for j in n - 1:
		for i in n - 1:
			var a := j * n + i
			idx.append_array([a, a + 1, a + n + 1, a, a + n + 1, a + n])
	_shared_cache[key] = {"grid": grid, "tangents": tangents, "index": idx}
	return _shared_cache[key]
