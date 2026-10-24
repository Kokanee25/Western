class_name Ground
extends StaticBody3D
## The street's ground, made ready to be dug (docs/briefs/dig-ground.md). Where it's never been
## dug it's the authored ground (TownLayout.ground_height): where that's flat at y 0 (from the
## saloon and store east), a few big flat slabs to stand on and one mesh, the ground less its dug
## tiles cut into rectangles, so standing ground costs what the endless plane did; west of that,
## where it slopes (the town's ground: the street's fall, the rise out of town), height fields a
## chunk of CHUNK_TILES tiles a side, drawn as one more mesh. Where it has been dug it's a
## GroundTile: a height field of `tile_cells` cells a side, its own
## body (an edit rebuilds only that tile) and mesh. Every collider of it carries the `ground` meta
## (Ground.is_ground) and `surface` &"ground", so a ball glances off a crater's wall as dirt
## (Ballistics.surface_of), not as a board.

@export var tuning: GroundTuning
## The ground's material (art's ground.gdshader): the scene's Mesh child's, kept for the tiles.
var material: Material
## Vector2i (the tile's corner, in tiles) -> GroundTile.
var tiles := {}

var _mesh: MeshInstance3D
var _rise_mesh: MeshInstance3D
## Vector2i (a chunk of the slope, in chunks) -> {dug: its dug tiles' keys, sorted; owners: its
## shape owners on its column's body (an edit swaps only those); verts, normals, index: its part of
## the slope's mesh}.
var _chunks := {}
## int (a column of chunks along x) -> the StaticBody3D its chunks' shapes are on (a body a chunk was
## ~280 more nodes in the street).
var _columns := {}
var _rise_tangents := PackedFloat32Array()

## Tiles a side of a chunk of the slope; its height field has a point every tile corner (the
## slope is gentle: between them it's within millimetres of the curve).
const CHUNK_TILES := 8
## Each chunk's room in the slope's mesh (points): a chunk cut round dug tiles into rectangles has
## at most four points a tile.
const CHUNK_SLOT := CHUNK_TILES * CHUNK_TILES * 4


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
	_road_line()
	# The scene's own collision (the old endless plane) gives way to the slabs.
	for c in get_children():
		if c is CollisionShape3D:
			remove_child(c)
			c.free()
	_rebuild_flat()


## The ground's material told where the street's middle runs (TownLayout.street_z), sampled as
## the shader takes it.
func _road_line() -> void:
	var sm := material as ShaderMaterial
	if sm == null:
		return
	var x0 := -200.0
	var step := 4.0
	var line := PackedFloat32Array()
	for i in 64:
		line.append(TownLayout.street_z(x0 + i * step))
	sm.set_shader_parameter(&"road_line", line)
	sm.set_shader_parameter(&"road_line_x0", x0)
	sm.set_shader_parameter(&"road_line_step", step)
	sm.set_shader_parameter(&"use_road_line", true)


## The ground in `tree` (the first in group `ground`), or null.
static func of(tree: SceneTree) -> Ground:
	return tree.get_first_node_in_group(&"ground") as Ground


## The ground's height at (x, z) in `tree`'s world: its Ground's, or 0 where there's none (a lab's
## floor, a test's world).
static func height_in(tree: SceneTree, x: float, z: float) -> float:
	var g := of(tree)
	return g.height_at(x, z) if g else 0.0


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
		return global_position.y + TownLayout.ground_height(x, z)
	var local := t.global_transform.affine_inverse() * Vector3(x, 0.0, z)
	var half := tuning.tile_cells * 0.5
	var u := clampf(local.x / tuning.cell + half, 0.0, tuning.tile_cells)
	var v := clampf(local.z / tuning.cell + half, 0.0, tuning.tile_cells)
	var i := mini(floori(u), tuning.tile_cells - 1)
	var j := mini(floori(v), tuning.tile_cells - 1)
	var fu := u - i
	var fv := v - j
	var h00 := t.surface(t.index(i, j))
	var h11 := t.surface(t.index(i + 1, j + 1))
	var h10 := t.surface(t.index(i + 1, j))
	var h01 := t.surface(t.index(i, j + 1))
	var h := 0.0
	if fu >= fv:
		h = h00 + (h10 - h00) * fu + (h11 - h10) * fv
	else:
		h = h00 + (h01 - h00) * fv + (h11 - h01) * fu
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


## The ground's slabs (deep boxes, their tops at the authored height) and its mesh, outside the
## dug tiles; and the rise's chunks that have gained or lost a dug tile.
func _rebuild_flat() -> void:
	for c in get_children():
		if c is CollisionShape3D:
			remove_child(c)
			c.free()
	var area := _rise_area()
	var i := 0
	for piece in _levelled(flat_rects(tuning.reach_half), area):
		var r: Rect2 = piece[0]
		var cs := CollisionShape3D.new()
		cs.name = "Slab%d" % i
		var box := BoxShape3D.new()
		box.size = Vector3(r.size.x, tuning.slab_depth, r.size.y)
		cs.shape = box
		cs.position = Vector3(r.get_center().x, float(piece[1]) - tuning.slab_depth * 0.5, r.get_center().y)
		add_child(cs)
		i += 1
	_mesh.mesh = _flat_mesh(_levelled(flat_rects(tuning.drawn_half), area))
	_rebuild_rise(area)


## Where the authored ground slopes (chunk-aligned: from where it stops being flat west to the drawn
## edge, and across the drawn ground), or an empty Rect2 if it's flat.
func _rise_area() -> Rect2:
	var east := TownLayout.ground_flat_east_of()
	if east == INF:
		return Rect2()
	var c := tuning.tile_size() * CHUNK_TILES
	var x0 := floorf(-tuning.drawn_half / c) * c
	var z0 := floorf(-tuning.drawn_half / c) * c
	var x1 := maxf(ceilf(east / c) * c, x0 + c)
	return Rect2(x0, z0, x1 - x0, -2.0 * z0)


## `rects` less the slope's area, each with the level its slab or quad stands at: 0 east of it, or
## past its drawn edge the height there (taken flat over the piece, so far out it never shows).
func _levelled(rects: Array[Rect2], area: Rect2) -> Array:
	var out := []
	for r in rects:
		if area.size == Vector2.ZERO:
			out.append([r, 0.0])
			continue
		for p in _minus(r, area):
			if p.position.x >= area.end.x - 0.01:
				out.append([p, 0.0])
			else:
				out.append([p, TownLayout.ground_height(clampf(p.get_center().x, area.position.x, area.end.x))])
	return out


## Quads at their levels, facing up, in the ground's material (the shader works from the world
## position alone, so how the flat ground is cut into triangles doesn't show).
func _flat_mesh(rects: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var span := tuning.drawn_half * 2.0
	for piece in rects:
		var r: Rect2 = piece[0]
		var y := float(piece[1])
		var base := verts.size()
		for p: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			verts.append(Vector3(p.x, y, p.y))
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


## The slope's chunks: each solid columns, a tile wide, tilted to the ground, as shape owners on its
## column of chunks' body, and its part of the slope's mesh; a chunk with dug tiles in it is cut
## round them into rectangles.
## Only the chunks whose dug tiles have changed are made again.
func _rebuild_rise(area: Rect2) -> void:
	if area.size == Vector2.ZERO:
		return
	var size := tuning.tile_size()
	var c := size * CHUNK_TILES
	var dug := {}
	for key: Vector2i in tiles:
		var ck := Vector2i(floori(float(key.x) / CHUNK_TILES), floori(float(key.y) / CHUNK_TILES))
		if not dug.has(ck):
			dug[ck] = []
		(dug[ck] as Array).append(key)
	var changed := false
	var c0 := Vector2i(roundi(area.position.x / c), roundi(area.position.y / c))
	var c1 := Vector2i(roundi(area.end.x / c), roundi(area.end.y / c))
	var slot := 0
	for cz in range(c0.y, c1.y):
		for cx in range(c0.x, c1.x):
			var ck := Vector2i(cx, cz)
			slot += 1
			var keys: Array = dug.get(ck, [])
			keys.sort()
			var known: Dictionary = _chunks.get(ck, {})
			if not known.is_empty() and known.dug == keys:
				continue
			if known.has("owners"):
				var col := _column(ck.x)
				for id: int in known.owners:
					col.remove_shape_owner(id)
			_chunks[ck] = _make_chunk(ck, keys, (slot - 1) * CHUNK_SLOT)
			changed = true
	for cx: int in _columns:
		var body: StaticBody3D = _columns[cx]
		if body.get_parent() == null:
			add_child(body)
	if changed or _rise_mesh == null:
		_rise_mesh_rebuild()


## A chunk's height fields and its part of the mesh: its points from `first` in the rise's mesh
## (its slot, CHUNK_SLOT long, padded), its triangles' indices already counted from there.
func _make_chunk(ck: Vector2i, dug: Array, first: int) -> Dictionary:
	var size := tuning.tile_size()
	var pieces: Array[Rect2] = [Rect2(ck.x * size * CHUNK_TILES, ck.y * size * CHUNK_TILES, size * CHUNK_TILES, size * CHUNK_TILES)]
	for key: Vector2i in dug:
		var next: Array[Rect2] = []
		for r in pieces:
			for q in _minus(r, Rect2(key.x * size, key.y * size, size, size)):
				# Cut on the tile grid, so anything under half a tile across is a float's sliver.
				if q.size.x > size * 0.5 and q.size.y > size * 0.5:
					next.append(q)
		pieces = next
	var body := _column(ck.x)
	var owners: Array[int] = []
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var idx := PackedInt32Array()
	var step := size
	for r in pieces:
		var nx := roundi(r.size.x / step) + 1
		var nz := roundi(r.size.y / step) + 1
		# The ground's height goes with x alone: sampled once a column (one more each side, for the
		# slope).
		var along := PackedFloat32Array()
		for i in range(-1, nx + 1):
			along.append(TownLayout.ground_height(r.position.x + i * step))
		var base := first + verts.size()
		var inv := 1.0 / (2.0 * step)
		for j in nz:
			for i in nx:
				var h := along[i + 1]
				verts.append(Vector3(r.position.x + i * step, h, r.position.y + j * step))
				normals.append(Vector3(-(along[i + 2] - along[i]) * inv, 1.0, 0.0).normalized())
		for j in nz - 1:
			for i in nx - 1:
				var a := base + j * nx + i
				idx.append_array([a, a + 1, a + nx + 1, a, a + nx + 1, a + nx])
		# The collision: between two tile corners the ground is a plane (it goes with x alone), so
		# each column is a solid box tilted to it, its top the surface (a height field has no
		# thickness, and debris falling fast went through one).
		for i in nx - 1:
			var x0 := r.position.x + i * step
			var h0 := along[i + 1]
			var h1 := along[i + 2]
			var tilt := atan2(h1 - h0, step)
			var up := Vector3(-sin(tilt), cos(tilt), 0.0)
			var box := BoxShape3D.new()
			box.size = Vector3(sqrt(step * step + (h1 - h0) * (h1 - h0)), tuning.slab_depth, r.size.y)
			var top := Vector3(x0 + step * 0.5, (h0 + h1) * 0.5, r.get_center().y)
			# Straight onto the body as a shape owner: a node each was ~2,300 more in the street.
			var owner := body.create_shape_owner(body)
			body.shape_owner_add_shape(owner, box)
			body.shape_owner_set_transform(owner, Transform3D(Basis(Vector3.BACK, tilt), top - up * tuning.slab_depth * 0.5))
			owners.append(owner)
	# Padded to the slot (unused points, under the ground at the chunk's corner).
	var pad := CHUNK_SLOT - verts.size()
	if pad > 0:
		var corner := Vector3(ck.x * size * CHUNK_TILES, -1.0, ck.y * size * CHUNK_TILES)
		var fill := PackedVector3Array()
		fill.resize(pad)
		fill.fill(corner)
		verts.append_array(fill)
		fill.fill(Vector3.UP)
		normals.append_array(fill)
	return {"dug": dug, "owners": owners, "verts": verts, "normals": normals, "index": idx}


## The body a column of the slope's chunks (along x) puts its shapes on, made the first time.
func _column(cx: int) -> StaticBody3D:
	if _columns.has(cx):
		return _columns[cx]
	var body := StaticBody3D.new()
	body.name = "Rise_%d" % cx
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	for m in [&"ground", &"surface"]:
		body.set_meta(m, get_meta(m))
	# Into the tree once its shapes are on (_rebuild_rise): each shape added to a body in the
	# world rebuilds its whole compound.
	_columns[cx] = body
	return body


## The rise's one mesh, from its chunks' parts.
func _rise_mesh_rebuild() -> void:
	if _rise_mesh == null:
		_rise_mesh = MeshInstance3D.new()
		_rise_mesh.name = "RiseMesh"
		add_child(_rise_mesh)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var idx := PackedInt32Array()
	# In the order the chunks were given their slots (the index arrays count from them).
	var keys := _chunks.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for ck: Vector2i in keys:
		var part: Dictionary = _chunks[ck]
		verts.append_array(part.verts)
		normals.append_array(part.normals)
		idx.append_array(part.index)
	if verts.is_empty():
		_rise_mesh.mesh = null
		return
	if _rise_tangents.size() != verts.size() * 4:
		_rise_tangents.resize(verts.size() * 4)
		for k in verts.size():
			_rise_tangents[k * 4] = 1.0
			_rise_tangents[k * 4 + 3] = 1.0
	var tangents := _rise_tangents
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
	_rise_mesh.mesh = mesh


# --- Digging: earth out at one point, down at another ---------------------------------------------

## A rectangle of the ground's points (global indices: point I is at x = I x cell), read out of the
## tiles to be worked on and written back: the surface's height and the loose earth's depth in it.
class Patch:
	var i0 := 0
	var j0 := 0
	var w := 0
	var d := 0
	var h := PackedFloat32Array()
	var loose := PackedFloat32Array()

	func at(i: int, j: int) -> int:
		return (j - j0) * w + (i - i0)


## Lower the ground under a bowl `radius` across its middle at `at` (world), by up to `depth` at the
## middle (less out to the edge, none at it), never below the hardpan. Loose earth goes first. The
## earth taken, as packed (bank) m³.
func take(at: Vector3, radius: float, depth: float) -> float:
	var p := _read_round(at, radius + tuning.slump_margin)
	var c2 := tuning.cell * tuning.cell
	var floor_h := -tuning.earth_depth
	var bank := 0.0
	for j in range(p.j0, p.j0 + p.d):
		for i in range(p.i0, p.i0 + p.w):
			var r := Vector2(i * tuning.cell - at.x, j * tuning.cell - at.z).length()
			if r >= radius:
				continue
			var k := p.at(i, j)
			var lower := minf(depth * (1.0 - (r * r) / (radius * radius)), p.h[k] - floor_h)
			if lower <= 0.0:
				continue
			var from_loose := minf(lower, p.loose[k])
			p.loose[k] -= from_loose
			p.h[k] -= lower
			bank += (from_loose / tuning.swell + (lower - from_loose)) * c2
	_slump(p)
	_write(p)
	return bank


## Lay `bank` m³ of earth (packed; it lies loose, swelled) as a heap `radius` across its middle at
## `at` (world), highest in the middle; or, with `ring_from` > 0, as a ring from there out to
## `radius`, highest at `ring_peak` (a crater's lip). It slides till it lies no steeper than loose
## earth will.
func put(at: Vector3, bank: float, radius: float, ring_from := 0.0, ring_peak := 0.0) -> void:
	var p := _read_round(at, radius + tuning.slump_margin)
	var weights := PackedFloat32Array()
	weights.resize(p.w * p.d)
	var total := 0.0
	for j in range(p.j0, p.j0 + p.d):
		for i in range(p.i0, p.i0 + p.w):
			var r := Vector2(i * tuning.cell - at.x, j * tuning.cell - at.z).length()
			var wgt := 0.0
			if ring_from > 0.0:
				if r > ring_from and r < radius:
					wgt = (r - ring_from) / maxf(ring_peak - ring_from, 1e-4) if r < ring_peak else (radius - r) / maxf(radius - ring_peak, 1e-4)
			else:
				wgt = maxf(0.0, 1.0 - r / radius)
			weights[p.at(i, j)] = wgt
			total += wgt
	if total <= 0.0:
		return
	var per := bank * tuning.swell / (total * tuning.cell * tuning.cell)
	for k in weights.size():
		if weights[k] > 0.0:
			p.h[k] += weights[k] * per
			p.loose[k] += weights[k] * per
	_slump(p)
	_write(p)


## The earth in the ground against the authored ground, as packed (bank) m³: what's been dug out
## less what's been laid down (loose earth counted packed). Zero when every hole's been filled.
func earth_moved() -> float:
	var c2 := tuning.cell * tuning.cell
	var n := tuning.tile_cells
	var sum := 0.0
	for key: Vector2i in tiles:
		var t: GroundTile = tiles[key]
		# Each tile its own points but the far edges (the next tile's), so a point counts once.
		for j in n:
			for i in n:
				var k := t.index(i, j)
				sum += (t.heights[k] - t.loose[k] + t.loose[k] / tuning.swell) * c2
	return sum


## Loose earth steeper than its angle of repose slides down onto its lower neighbours, half the
## excess at a time, pass after pass over the points still moving (and those next to them), till
## it's settled or `slump_passes` have gone. Packed earth stands as it's cut (a grave's walls).
func _slump(p: Patch) -> void:
	var drop := tuning.cell * tan(deg_to_rad(tuning.repose_degrees))
	var look := PackedInt32Array()
	for k in p.loose.size():
		if p.loose[k] > 0.0:
			look.append(k)
	var flag := PackedByteArray()
	flag.resize(p.loose.size())
	var steps := PackedInt32Array([1, -1, p.w, -p.w])
	for pass_n in tuning.slump_passes:
		if look.is_empty():
			break
		flag.fill(0)
		var next := PackedInt32Array()
		for k in look:
			var i := k % p.w
			var j := k / p.w
			if i == 0 or j == 0 or i == p.w - 1 or j == p.d - 1 or p.loose[k] <= 0.0:
				continue
			for s in steps:
				var kn := k + s
				var over := p.h[k] - p.h[kn] - drop
				if over <= 1e-5:
					continue
				var m := minf(over * 0.5, p.loose[k])
				p.h[k] -= m
				p.loose[k] -= m
				p.h[kn] += m
				p.loose[kn] += m
				# It and where it went look again, and so do the earth above it, now steeper.
				for q in [k, kn, k + 1, k - 1, k + p.w, k - p.w]:
					if flag[q] == 0:
						flag[q] = 1
						next.append(q)
				if p.loose[k] <= 0.0:
					break
		look = next


## The points round `at` (world) out to `reach`, as a patch.
func _read_round(at: Vector3, reach: float) -> Patch:
	var c := tuning.cell
	return _read(floori((at.x - reach) / c), floori((at.z - reach) / c), ceili((at.x + reach) / c), ceili((at.z + reach) / c))


func _read(i0: int, j0: int, i1: int, j1: int) -> Patch:
	var p := Patch.new()
	p.i0 = i0
	p.j0 = j0
	p.w = i1 - i0 + 1
	p.d = j1 - j0 + 1
	p.h.resize(p.w * p.d)
	p.loose.resize(p.w * p.d)
	var n := tuning.tile_cells
	for kz in range(floori(float(j0) / n), floori(float(j1) / n) + 1):
		for kx in range(floori(float(i0) / n), floori(float(i1) / n) + 1):
			var t: GroundTile = tiles.get(Vector2i(kx, kz))
			if t == null:
				continue
			for j in range(maxi(j0, kz * n), mini(j1, kz * n + n) + 1):
				for i in range(maxi(i0, kx * n), mini(i1, kx * n + n) + 1):
					var tk := t.index(i - kx * n, j - kz * n)
					var k := p.at(i, j)
					p.h[k] = t.heights[tk]
					p.loose[k] = t.loose[tk]
	return p


## The patch back into the tiles (made where the ground's changed and there's none yet), each tile
## rebuilt once; then what was resting there is woken, what's buried there and now uncovered handed
## back, and Events.ground_changed told.
func _write(p: Patch) -> void:
	var n := tuning.tile_cells
	var i1 := p.i0 + p.w - 1
	var j1 := p.j0 + p.d - 1
	var made := false
	var touched: Array[GroundTile] = []
	for kz in range(floori(float(p.j0) / n), floori(float(j1) / n) + 1):
		for kx in range(floori(float(p.i0) / n), floori(float(i1) / n) + 1):
			var key := Vector2i(kx, kz)
			var t: GroundTile = tiles.get(key)
			var changed := false
			for j in range(maxi(p.j0, kz * n), mini(j1, kz * n + n) + 1):
				for i in range(maxi(p.i0, kx * n), mini(i1, kx * n + n) + 1):
					var k := p.at(i, j)
					if t == null:
						if p.h[k] == 0.0 and p.loose[k] == 0.0:
							continue
						t = GroundTile.make(self, key)
						tiles[key] = t
						add_child(t)
						made = true
					var tk := t.index(i - kx * n, j - kz * n)
					if t.heights[tk] != p.h[k] or t.loose[tk] != p.loose[k]:
						t.heights[tk] = p.h[k]
						t.loose[tk] = p.loose[k]
						changed = true
			if t and changed:
				touched.append(t)
	for t in touched:
		t.rebuild(material)
	if made:
		_rebuild_flat()
	if touched.is_empty():
		return
	var area := Rect2(p.i0 * tuning.cell, p.j0 * tuning.cell, (p.w - 1) * tuning.cell, (p.d - 1) * tuning.cell)
	_wake(area)
	_uncover(area)
	Events.ground_changed.emit(area)


## Everything asleep over `area` (world xz) wakes: the ground it lay on may have gone from under it.
func _wake(area: Rect2) -> void:
	if not is_inside_tree():
		return
	var box := BoxShape3D.new()
	box.size = Vector3(area.size.x + 0.2, tuning.earth_depth + 4.0, area.size.y + 0.2)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.transform = Transform3D(Basis.IDENTITY, Vector3(area.get_center().x,
			TownLayout.ground_height(area.get_center().x, area.get_center().y) + 2.0 - tuning.earth_depth * 0.5, area.get_center().y))
	q.collision_mask = 0xFFFFFFFF
	# Not the ground itself: a height field answers once a triangle.
	var ex: Array[RID] = [get_rid()]
	var lo := key_at(area.position.x - 0.1, area.position.y - 0.1)
	var hi := key_at(area.end.x + 0.1, area.end.y + 0.1)
	for kz in range(lo.y, hi.y + 1):
		for kx in range(lo.x, hi.x + 1):
			var t: GroundTile = tiles.get(Vector2i(kx, kz))
			if t:
				ex.append(t.get_rid())
	q.exclude = ex
	for hit in get_world_3d().direct_space_state.intersect_shape(q, 512):
		if hit.collider is RigidBody3D:
			(hit.collider as RigidBody3D).sleeping = false


# --- What's buried --------------------------------------------------------------------------------

## Things under the ground (a strongbox, a cache, bones): id -> where it lies (world; its top).
var buried := {}


## `id` lies buried with its top at `at` (world), till the ground over it is dug down to it.
func bury(id: StringName, at: Vector3) -> void:
	buried[id] = at


func _uncover(area: Rect2) -> void:
	for id: StringName in buried.keys():
		var at: Vector3 = buried[id]
		if area.grow(tuning.cell).has_point(Vector2(at.x, at.z)) and height_at(at.x, at.z) <= at.y + 1e-4:
			buried.erase(id)
			Events.ground_uncovered.emit(id, at)


# --- Saving: the difference from the authored ground ---------------------------------------------

## The ground as the authored ground plus what's changed: each dug tile's heights and loose earth in
## millimetres (16-bit, deflated), and what's buried. Only the heights as they are now, not the
## digging that made them (docs/briefs/dig-ground.md, "Saving").
func to_dict() -> Dictionary:
	var out := {}
	var keys := tiles.keys()
	keys.sort()
	for key: Vector2i in keys:
		var t: GroundTile = tiles[key]
		var raw := PackedByteArray()
		raw.resize(t.heights.size() * 4)
		var any := false
		for k in t.heights.size():
			var h := clampi(roundi(t.heights[k] * 1000.0), -32768, 32767)
			var l := clampi(roundi(t.loose[k] * 1000.0), 0, 32767)
			any = any or h != 0 or l != 0
			raw.encode_s16(k * 2, h)
			raw.encode_s16(t.heights.size() * 2 + k * 2, l)
		if any:
			out["%d,%d" % [key.x, key.y]] = Marshalls.raw_to_base64(raw.compress(FileAccess.COMPRESSION_DEFLATE))
	var b := {}
	for id: StringName in buried:
		var at: Vector3 = buried[id]
		b[String(id)] = [at.x, at.y, at.z]
	return {"cell": tuning.cell, "tile_cells": tuning.tile_cells, "tiles": out, "buried": b}


## The ground back as `to_dict` had it (over the authored ground: every dug tile not in it goes).
func from_dict(d: Dictionary) -> void:
	for key: Vector2i in tiles:
		(tiles[key] as GroundTile).free()
	tiles.clear()
	var n2 := (tuning.tile_cells + 1) * (tuning.tile_cells + 1)
	var all: Dictionary = d.get("tiles", {})
	for name: String in all:
		var parts := name.split(",")
		var key := Vector2i(int(parts[0]), int(parts[1]))
		var raw := Marshalls.base64_to_raw(all[name]).decompress(n2 * 4, FileAccess.COMPRESSION_DEFLATE)
		var t := GroundTile.make(self, key)
		for k in n2:
			t.heights[k] = raw.decode_s16(k * 2) / 1000.0
			t.loose[k] = raw.decode_s16(n2 * 2 + k * 2) / 1000.0
		t.rebuild(material)
		tiles[key] = t
		add_child(t)
	buried.clear()
	var b: Dictionary = d.get("buried", {})
	for id: String in b:
		buried[StringName(id)] = Vector3(b[id][0], b[id][1], b[id][2])
	_rebuild_flat()
