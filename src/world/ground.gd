class_name Ground
extends StaticBody3D
## The street's ground, made ready to be dug (docs/briefs/dig-ground.md). Where it's never been
## dug it's flat at the authored height (y 0): a few big flat slabs to stand on and one mesh, the
## ground less its dug tiles cut into rectangles, so standing ground costs what the endless plane
## did. Where it has been dug it's a GroundTile: a height field of `tile_cells` cells a side, its own
## body (an edit rebuilds only that tile) and mesh. Every collider of it carries the `ground` meta
## (Ground.is_ground) and `surface` &"ground", so a ball glances off a crater's wall as dirt
## (Ballistics.surface_of), not as a board.

@export var tuning: GroundTuning
## The ground's material (art's ground.gdshader): the scene's Mesh child's, kept for the tiles.
var material: Material
## Vector2i (the tile's corner, in tiles) -> GroundTile.
var tiles := {}

var _mesh: MeshInstance3D


func _ready() -> void:
	if tuning == null:
		tuning = load("res://config/ground.tres")
	add_to_group(&"ground")
	set_meta(&"ground", true)
	set_meta(&"surface", &"ground")
	_mesh = get_node_or_null(^"Mesh") as MeshInstance3D
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Mesh"
		add_child(_mesh)
	if material == null:
		material = _mesh.material_override if _mesh.material_override else (_mesh.mesh.surface_get_material(0) if _mesh.mesh else null)
	# The scene's own collision (the old endless plane) gives way to the slabs.
	for c in get_children():
		if c is CollisionShape3D:
			remove_child(c)
			c.free()
	_rebuild_flat()


## The ground in `tree` (the first in group `ground`), or null.
static func of(tree: SceneTree) -> Ground:
	return tree.get_first_node_in_group(&"ground") as Ground


## Is `o` the ground (its flat slabs or a dug tile)?
static func is_ground(o: Object) -> bool:
	return o != null and is_instance_valid(o) and o is Node and (o as Node).has_meta(&"ground")


## The tile holding the point (x, z) (world), as its key.
func key_at(x: float, z: float) -> Vector2i:
	var size := tuning.tile_size()
	return Vector2i(floori(x / size), floori(z / size))


## The ground's height at (x, z) (world): the authored height where it's never been dug, else the
## tile's, between its points as its height field has it (each quad split corner (i, j) to
## (i + 1, j + 1)).
func height_at(x: float, z: float) -> float:
	var t: GroundTile = tiles.get(key_at(x, z))
	if t == null:
		return global_position.y
	var local := t.global_transform.affine_inverse() * Vector3(x, 0.0, z)
	var half := tuning.tile_cells * 0.5
	var u := clampf(local.x / tuning.cell + half, 0.0, tuning.tile_cells)
	var v := clampf(local.z / tuning.cell + half, 0.0, tuning.tile_cells)
	var i := mini(floori(u), tuning.tile_cells - 1)
	var j := mini(floori(v), tuning.tile_cells - 1)
	var fu := u - i
	var fv := v - j
	var h00 := t.heights[t.index(i, j)]
	var h11 := t.heights[t.index(i + 1, j + 1)]
	var h := 0.0
	if fu >= fv:
		h = h00 + (t.heights[t.index(i + 1, j)] - h00) * fu + (h11 - t.heights[t.index(i + 1, j)]) * fv
	else:
		h = h00 + (t.heights[t.index(i, j + 1)] - h00) * fv + (h11 - t.heights[t.index(i, j + 1)]) * fu
	return t.global_position.y + h


## The tile at `key`, made (flat, as the ground there was) if it isn't yet: the flat ground's
## slabs and mesh are cut again round it.
func dug_tile(key: Vector2i) -> GroundTile:
	if tiles.has(key):
		return tiles[key]
	var t := GroundTile.make(self, key)
	tiles[key] = t
	add_child(t)
	_rebuild_flat()
	return t


## The flat ground, outside every dug tile, as rectangles (world xz) within `half` of the middle.
func flat_rects(half: float) -> Array[Rect2]:
	var rects: Array[Rect2] = [Rect2(-half, -half, half * 2.0, half * 2.0)]
	var size := tuning.tile_size()
	var keys := tiles.keys()
	keys.sort()
	for key: Vector2i in keys:
		var hole := Rect2(key.x * size, key.y * size, size, size)
		var next: Array[Rect2] = []
		for r in rects:
			next.append_array(_minus(r, hole))
		rects = next
	return rects


## `r` less `hole`: up to four rectangles (the strips either side across, then above and below).
static func _minus(r: Rect2, hole: Rect2) -> Array[Rect2]:
	var cut := r.intersection(hole)
	if cut.size.x <= 0.0 or cut.size.y <= 0.0:
		return [r]
	var out: Array[Rect2] = []
	if cut.position.x > r.position.x:
		out.append(Rect2(r.position.x, r.position.y, cut.position.x - r.position.x, r.size.y))
	if cut.end.x < r.end.x:
		out.append(Rect2(cut.end.x, r.position.y, r.end.x - cut.end.x, r.size.y))
	if cut.position.y > r.position.y:
		out.append(Rect2(cut.position.x, r.position.y, cut.size.x, cut.position.y - r.position.y))
	if cut.end.y < r.end.y:
		out.append(Rect2(cut.position.x, cut.end.y, cut.size.x, r.end.y - cut.end.y))
	return out


## The flat ground's slabs (deep boxes, their tops at the authored height) and its one mesh.
func _rebuild_flat() -> void:
	for c in get_children():
		if c is CollisionShape3D:
			remove_child(c)
			c.free()
	var i := 0
	for r in flat_rects(tuning.reach_half):
		var cs := CollisionShape3D.new()
		cs.name = "Slab%d" % i
		var box := BoxShape3D.new()
		box.size = Vector3(r.size.x, tuning.slab_depth, r.size.y)
		cs.shape = box
		cs.position = Vector3(r.get_center().x, -tuning.slab_depth * 0.5, r.get_center().y)
		add_child(cs)
		i += 1
	_mesh.mesh = _flat_mesh(flat_rects(tuning.drawn_half))


## Quads at the authored height, facing up, in the ground's material (the shader works from the
## world position alone, so how the flat ground is cut into triangles doesn't show).
func _flat_mesh(rects: Array[Rect2]) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var span := tuning.drawn_half * 2.0
	for r in rects:
		var base := verts.size()
		for p: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			verts.append(Vector3(p.x, 0.0, p.y))
			normals.append(Vector3.UP)
			tangents.append_array([1.0, 0.0, 0.0, 1.0])
			uvs.append(p / span + Vector2(0.5, 0.5))
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material:
		mesh.surface_set_material(0, material)
	return mesh
