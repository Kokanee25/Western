class_name GroundTile
extends StaticBody3D
## One dug tile of the ground (Ground, docs/briefs/dig-ground.md): `tile_cells` cells a side, its
## heights (above the authored ground, at the cells' corners: one more a side than cells, the edges
## shared with the next tile's) as a Jolt height field and a mesh in the ground's material, with the
## hardpan under it as a box. Its own body, so an edit rebuilds only this tile's shape.

var key: Vector2i
## (tile_cells + 1)² heights, row by row along x, rows along z (m, above the authored ground).
var heights := PackedFloat32Array()

var _n := 0  # points a side
var _cell := 0.05
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
	t.collision_layer = ground.collision_layer
	t.collision_mask = ground.collision_mask
	for m in [&"ground", &"surface"]:
		t.set_meta(m, ground.get_meta(m))
	var size := tn.tile_size()
	t.position = Vector3((at.x + 0.5) * size, 0.0, (at.y + 0.5) * size)
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
	var pan := CollisionShape3D.new()
	pan.name = "Hardpan"
	var box := BoxShape3D.new()
	box.size = Vector3(size, tn.slab_depth, size)
	pan.shape = box
	pan.position = Vector3(0.0, -tn.earth_depth - tn.slab_depth * 0.5, 0.0)
	t.add_child(pan)
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
	return global_transform * Vector3((i - half) * _cell, heights[index(i, j)], (j - half) * _cell)


## Shape and mesh from `heights`, after an edit.
func rebuild(material: Material) -> void:
	_shape.map_data = heights
	_mesh.mesh = _grid_mesh(material)


## The tile as a grid of quads, each split corner to corner as its height field is, normals from
## the heights round each point (central differences).
func _grid_mesh(material: Material) -> ArrayMesh:
	var half := (_n - 1) * 0.5
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	verts.resize(_n * _n)
	normals.resize(_n * _n)
	for j in _n:
		for i in _n:
			var h := heights[index(i, j)]
			verts[index(i, j)] = Vector3((i - half) * _cell, h, (j - half) * _cell)
			var dx := heights[index(mini(i + 1, _n - 1), j)] - heights[index(maxi(i - 1, 0), j)]
			var dz := heights[index(i, mini(j + 1, _n - 1))] - heights[index(i, maxi(j - 1, 0))]
			var sx := float(mini(i + 1, _n - 1) - maxi(i - 1, 0)) * _cell
			var sz := float(mini(j + 1, _n - 1) - maxi(j - 1, 0)) * _cell
			normals[index(i, j)] = Vector3(-dx / sx, 1.0, -dz / sz).normalized()
			tangents.append_array([1.0, 0.0, 0.0, 1.0])
	var idx := PackedInt32Array()
	for j in _n - 1:
		for i in _n - 1:
			var a := index(i, j)
			var b := index(i + 1, j)
			var c := index(i + 1, j + 1)
			var d := index(i, j + 1)
			idx.append_array([a, b, c, a, c, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material:
		mesh.surface_set_material(0, material)
	return mesh
