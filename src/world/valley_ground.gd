class_name ValleyGround
extends Node3D
## The valley's undug ground, from the bake (ValleyTerrain; docs/briefs/valley-plan.md §12, G2):
## made and owned by the valley's Ground (Ground.terrain), which still does all the digging. Two
## halves, neither knowing the other:
##
## - **Collision:** a chunk of `chunk_cells` cells a side (128 m) is a StaticBody3D holding one Jolt
##   height field of the bake's own points (so a ray down meets ValleyTerrain.height exactly), and
##   under it solid boxes (a height field has no thickness; GroundTile's columns, coarser), all
##   made at load. A chunk with a dug tile in it (Ground.tiles: 4 m, two cells a side) is made again
##   as squares of `column_cells` cells: each a small height field, or where a tile is, a mesh of
##   the square's quads less the tile's; and the boxes under that square go. The tile's own field
##   and columns stand there instead. (A NaN point holes a Jolt height field by the triangles that
##   use it, not by quads: no set of points leaves out exactly a tile and nothing round it.)
## - **Drawing:** a quadtree of blocks: level 0 a chunk at 2 m, each level up twice the side at half
##   the points (64 quads a side always), the top level's blocks always there. Godot's visibility
##   ranges swap a block for its four children as the camera comes within `split` x its side
##   (`visibility_parent`, HLOD), so a block is never drawn with its children. Children are built
##   on a frame budget as the camera nears and freed as it goes; skirts hang from every block's
##   edge to hide the cracks where neighbours are at different levels. A dug tile's mesh is drawn
##   exactly when its chunk's level 0 is (the level 0 mesh has the tile's quads left out).

var ground: Ground
var terrain: ValleyTerrain
var tuning: ValleyGroundTuning
## The drawn ground's material (vertex colours: the greybox's dirt and rock).
var material: Material
## Chunks along x and z.
var chunks := Vector2i.ZERO
## Vector2i (chunk) -> StaticBody3D.
var bodies := {}
## Where the drawing's levels are chosen from, instead of the viewport's camera (a test's, a tool's).
var focus: Variant = null
## How many blocks have been built, all told (the tests' and the bench's count).
var built := 0

var _fields := {}  # Vector2i (chunk) -> HeightMapShape3D (kept for when its holes are filled)
var _holes := {}  # Vector2i (chunk) -> Array (its dug tiles' keys, sorted)
var _roots: Array[Block] = []
var _blocks := {}  # Vector3i (level, x, z) -> Block
var _index_cache := {}
var _boxes := {}
var _building := false

## Frames between choosing the levels (while nothing's waiting to be built).
const LOOK_EVERY := 4
var _tile_quads := 2


class Block:
	var level := 0
	var at := Vector2i.ZERO
	var size := 0.0
	var mi: MeshInstance3D
	var parent: Block
	## Child index (0..3) -> Block, as they're built; `expect` of them exist inside the bake.
	var kids := {}
	var expect := 0
	var split := false


func setup(g: Ground, t: ValleyTerrain, tn: ValleyGroundTuning, mat: Material) -> void:
	ground = g
	terrain = t
	tuning = tn
	material = mat
	var side := tuning.chunk_cells
	chunks = Vector2i(ceili(float(terrain.width - 1) / side), ceili(float(terrain.depth - 1) / side))
	var tq := ground.tuning.tile_size() / terrain.spacing
	_tile_quads = roundi(tq)
	if absf(tq - _tile_quads) > 1e-4 or side % _tile_quads != 0:
		push_error("ValleyGround: a dug tile (%.2f m) must be a whole number of the bake's cells and divide a chunk" % ground.tuning.tile_size())


func chunk_size() -> float:
	return tuning.chunk_cells * terrain.spacing


# --- Collision ----------------------------------------------------------------------------------

## Every chunk's body (at load: ~1,000 of them, a height field and its boxes each).
func build_collision() -> void:
	for cz in chunks.y:
		for cx in chunks.x:
			_make_body(Vector2i(cx, cz))


func _make_body(ck: Vector2i) -> void:
	var body := StaticBody3D.new()
	body.name = "Chunk_%d_%d" % [ck.x, ck.y]
	body.collision_layer = ground.collision_layer
	body.collision_mask = ground.collision_mask
	for m in [&"ground", &"surface"]:
		body.set_meta(m, ground.get_meta(m))
	var c := chunk_size()
	body.position = Vector3(terrain.x0 + (ck.x + 0.5) * c, 0.0, terrain.z0 + (ck.y + 0.5) * c)
	bodies[ck] = body
	_shape_chunk(ck)
	add_child(body)


## A chunk's shapes, made again: its one height field (none dug) or its squares (some dug), and
## the boxes under it.
func _shape_chunk(ck: Vector2i) -> void:
	var body: StaticBody3D = bodies[ck]
	for id: int in body.get_shape_owners():
		body.remove_shape_owner(id)
	var side := tuning.chunk_cells
	var scaled := Basis.from_scale(Vector3(terrain.spacing, 1.0, terrain.spacing))
	if not _holes.has(ck):
		var field: HeightMapShape3D = _fields.get(ck)
		if field == null:
			# Godot centres a height field on its shape's origin with points 1 apart: scaled to the bake's.
			field = HeightMapShape3D.new()
			field.map_width = side + 1
			field.map_depth = side + 1
			field.map_data = _points(ck, 0, 0, side)
			_fields[ck] = field
		_add_shape(body, field, Transform3D(scaled, Vector3.ZERO))
	else:
		var holed := _holed_quads(ck)
		var cc := maxi(tuning.column_cells, 1)
		for sz in ceili(float(side) / cc):
			for sx in ceili(float(side) / cc):
				var mid := Vector3(((sx + 0.5) * cc - side * 0.5) * terrain.spacing, 0.0, ((sz + 0.5) * cc - side * 0.5) * terrain.spacing)
				var mine := {}
				for q: Vector2i in holed:
					if q.x / cc == sx and q.y / cc == sz:
						mine[q] = true
				if mine.is_empty():
					var f := HeightMapShape3D.new()
					f.map_width = cc + 1
					f.map_depth = cc + 1
					f.map_data = _points(ck, sx * cc, sz * cc, cc)
					_add_shape(body, f, Transform3D(scaled, mid))
				else:
					var faces := _faces(ck, sx * cc, sz * cc, cc, mine)
					if not faces.is_empty():
						var m := ConcavePolygonShape3D.new()
						m.set_faces(faces)
						_add_shape(body, m, Transform3D.IDENTITY)
	_make_columns(ck)


func _add_shape(body: StaticBody3D, shape: Shape3D, xf: Transform3D) -> void:
	var owner := body.create_shape_owner(body)
	body.shape_owner_add_shape(owner, shape)
	body.shape_owner_set_transform(owner, xf)


## (n + 1)² of the bake's points from cell (i0, j0) of a chunk, row by row.
func _points(ck: Vector2i, i0: int, j0: int, n: int) -> PackedFloat32Array:
	var gi := ck.x * tuning.chunk_cells + i0
	var gj := ck.y * tuning.chunk_cells + j0
	var out := PackedFloat32Array()
	for jj in n + 1:
		var j := mini(gj + jj, terrain.depth - 1)
		var row := j * terrain.width
		if gi + n + 1 <= terrain.width:
			out.append_array(terrain.heights.slice(row + gi, row + gi + n + 1))
		else:
			for ii in n + 1:
				out.append(terrain.heights[row + mini(gi + ii, terrain.width - 1)])
	return out


## A square of a chunk (n cells from cell (i0, j0)) as triangles in the chunk body's space, split as
## its height field would be, less the quads in `skip`.
func _faces(ck: Vector2i, i0: int, j0: int, n: int, skip: Dictionary) -> PackedVector3Array:
	var side := tuning.chunk_cells
	var half := side * 0.5
	var gi := ck.x * side
	var gj := ck.y * side
	var sp := terrain.spacing
	var out := PackedVector3Array()
	for jj in range(j0, mini(j0 + n, side)):
		for ii in range(i0, mini(i0 + n, side)):
			if skip.has(Vector2i(ii, jj)):
				continue
			var p00 := Vector3((ii - half) * sp, terrain.sample(gi + ii, gj + jj), (jj - half) * sp)
			var p10 := Vector3((ii + 1 - half) * sp, terrain.sample(gi + ii + 1, gj + jj), (jj - half) * sp)
			var p01 := Vector3((ii - half) * sp, terrain.sample(gi + ii, gj + jj + 1), (jj + 1 - half) * sp)
			var p11 := Vector3((ii + 1 - half) * sp, terrain.sample(gi + ii + 1, gj + jj + 1), (jj + 1 - half) * sp)
			out.append_array([p00, p10, p01, p10, p11, p01])
	return out


## The quads (cells from the chunk's corner) under its dug tiles.
func _holed_quads(ck: Vector2i) -> Dictionary:
	var out := {}
	for key: Vector2i in _holes.get(ck, []):
		var q := _tile_quad(key, ck)
		for dj in _tile_quads:
			for di in _tile_quads:
				out[q + Vector2i(di, dj)] = true
	return out


## The solid boxes under a chunk's ground, but under a square holding a dug tile (shape owners
## after its ground's).
func _make_columns(ck: Vector2i) -> void:
	var body: StaticBody3D = bodies[ck]
	var cc := tuning.column_cells
	if cc <= 0:
		return
	var side := tuning.chunk_cells
	var squares := ceili(float(side) / cc)
	var holed := {}
	for q: Vector2i in _holed_quads(ck):
		holed[Vector2i(q.x / cc, q.y / cc)] = true
	var lows := _square_lows(ck, cc, squares)
	var half := side * 0.5
	for sz in squares:
		for sx in squares:
			if holed.has(Vector2i(sx, sz)):
				continue
			var top := lows[sz * squares + sx] - 0.01
			var w := (mini(sx * cc + cc, side) - sx * cc) * terrain.spacing
			var d := (mini(sz * cc + cc, side) - sz * cc) * terrain.spacing
			_add_shape(body, _box(Vector3(w, tuning.column_depth, d)), Transform3D(Basis.IDENTITY, Vector3(
					(sx * cc - half) * terrain.spacing + w * 0.5, top - tuning.column_depth * 0.5, (sz * cc - half) * terrain.spacing + d * 0.5)))


## The lowest of the bake's points over each square of `cc` cells of a chunk (its edges counted in
## both squares either side), row by row along x: the rows' lows by square first, then down.
func _square_lows(ck: Vector2i, cc: int, squares: int) -> PackedFloat32Array:
	var side := tuning.chunk_cells
	var w := terrain.width
	var hs := terrain.heights
	var i0 := ck.x * side
	var j0 := ck.y * side
	var rows := PackedFloat32Array()
	rows.resize((side + 1) * squares)
	for jj in side + 1:
		var base := mini(j0 + jj, terrain.depth - 1) * w
		for sx in squares:
			var low := INF
			for ii in range(sx * cc, mini(sx * cc + cc, side) + 1):
				var h := hs[base + mini(i0 + ii, w - 1)]
				if h < low:
					low = h
			rows[jj * squares + sx] = low
	var out := PackedFloat32Array()
	out.resize(squares * squares)
	for sz in squares:
		for sx in squares:
			var low := INF
			for jj in range(sz * cc, mini(sz * cc + cc, side) + 1):
				low = minf(low, rows[jj * squares + sx])
			out[sz * squares + sx] = low
	return out


## One box shape a size, shared by every column that size.
func _box(size: Vector3) -> BoxShape3D:
	if not _boxes.has(size):
		var box := BoxShape3D.new()
		box.size = size
		_boxes[size] = box
	return _boxes[size]


## The chunk a dug tile is in (Vector2i(-1, -1) outside the bake).
func tile_chunk(key: Vector2i) -> Vector2i:
	var size := ground.tuning.tile_size()
	var c := chunk_size()
	var ck := Vector2i(floori((key.x * size - terrain.x0) / c), floori((key.y * size - terrain.z0) / c))
	if ck.x < 0 or ck.y < 0 or ck.x >= chunks.x or ck.y >= chunks.y:
		return Vector2i(-1, -1)
	return ck


## A dug tile's first quad in its chunk (cells from the chunk's corner).
func _tile_quad(key: Vector2i, ck: Vector2i) -> Vector2i:
	var size := ground.tuning.tile_size()
	return Vector2i(roundi((key.x * size - terrain.x0) / terrain.spacing) - ck.x * tuning.chunk_cells,
			roundi((key.y * size - terrain.z0) / terrain.spacing) - ck.y * tuning.chunk_cells)


## The dug tiles are these (Ground.tiles' keys): each chunk whose set changed has its field and
## boxes made again, and its level 0 mesh if it's built; then every tile's mesh is drawn with its
## chunk's level 0.
func set_holes(tiles: Dictionary) -> void:
	var by := {}
	for key: Vector2i in tiles:
		var ck := tile_chunk(key)
		if ck.x < 0:
			continue
		if not by.has(ck):
			by[ck] = []
		(by[ck] as Array).append(key)
	var all := by.duplicate()
	for ck: Vector2i in _holes:
		all[ck] = true
	var changed: Array = []
	for ck: Vector2i in all:
		var keys: Array = by.get(ck, [])
		keys.sort()
		if keys == _holes.get(ck, []):
			continue
		if keys.is_empty():
			_holes.erase(ck)
		else:
			_holes[ck] = keys
		if bodies.has(ck):
			_shape_chunk(ck)
		var b: Block = _blocks.get(Vector3i(0, ck.x, ck.y))
		if b:
			b.mi.mesh = _block_mesh(b)
		changed.append(ck)
	_sync_tiles(changed if not changed.is_empty() else [Vector2i(-1, -1)])


## The chunks' bodies under `area` (world xz): Ground._wake leaves them out of its query, as it
## does itself and its tiles (a height field answers once a triangle).
func bodies_in(area: Rect2) -> Array[RID]:
	var out: Array[RID] = []
	var c := chunk_size()
	for cz in range(floori((area.position.y - terrain.z0) / c), floori((area.end.y - terrain.z0) / c) + 1):
		for cx in range(floori((area.position.x - terrain.x0) / c), floori((area.end.x - terrain.x0) / c) + 1):
			var body: StaticBody3D = bodies.get(Vector2i(cx, cz))
			if body:
				out.append(body.get_rid())
	return out


# --- Drawing ------------------------------------------------------------------------------------

## The top level's blocks (always drawn while nothing nearer is), then everything the camera
## (or `at`) wants, built now with no budget.
func build_drawing(at: Variant = null) -> void:
	var top := tuning.levels - 1
	var span := tuning.chunk_cells << top
	for bz in ceili(float(terrain.depth - 1) / span):
		for bx in ceili(float(terrain.width - 1) / span):
			var b := _build_block(top, Vector2i(bx, bz), null)
			if b:
				_roots.append(b)
	prime(at)


## Everything wanted from `at` (or the camera) built at once (the start, a jump).
func prime(at: Variant = null) -> void:
	for pass_n in 64:
		var p: Variant = at if at != null else _focus()
		if p == null:
			return
		var want := _wants(p)
		if want.is_empty():
			return
		for w: Array in want:
			_grow(w[1], null)


func _process(_dt: float) -> void:
	var p: Variant = _focus()
	if p == null or _roots.is_empty():
		return
	# The levels chosen every LOOK_EVERY frames (a block's side is 128 m or more; at a gallop that's
	# a metre a look), building while anything's wanted.
	if not _building and Engine.get_process_frames() % LOOK_EVERY != 0:
		return
	var t := Prof.start()
	var want := _wants(p)
	_building = not want.is_empty()
	var budget := WorkBudget.new(tuning.build_ms, tuning.build_units)
	for w: Array in want:
		if budget.over():
			break
		_grow(w[1], budget)
	Prof.stop(&"valley_ground", t)


func _focus() -> Variant:
	if focus != null:
		return focus
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam.global_position if cam else null


## The blocks whose children are wanted from `p`, nearest first (and those too far, unsplit).
func _wants(p: Vector3) -> Array:
	var want := []
	# (in this node's space: Godot measures a visibility range to a block's middle in the world's,
	# the same while the ground stands unscaled)
	var lp := to_local(p) if is_inside_tree() else p
	for r in _roots:
		_walk(r, lp, want)
	want.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return want


func _walk(b: Block, p: Vector3, want: Array) -> void:
	var d := p.distance_to(b.mi.position)
	if b.split:
		if d > (tuning.split + tuning.evict) * b.size:
			_unsplit(b)
			return
		for k: int in b.kids:
			_walk(b.kids[k], p, want)
	elif b.level > 0 and d < (tuning.split + tuning.prepare) * b.size:
		want.append([d, b])


## Build `b`'s children not yet built (on `budget`, or all), and once they all are, draw them in
## its place when the camera's near enough.
func _grow(b: Block, budget: WorkBudget) -> void:
	for k in 4:
		if b.kids.has(k):
			continue
		if budget and budget.over():
			return
		var c := _build_block(b.level - 1, b.at * 2 + Vector2i(k % 2, k / 2), b)
		if c:
			b.kids[k] = c
			if budget:
				budget.spend()
	if b.kids.size() >= b.expect:
		b.split = true
		b.mi.visibility_range_begin = tuning.split * b.size
		b.mi.visibility_range_begin_margin = tuning.margin * b.size


## `b` drawn whole again and its children freed (the camera's gone far off).
func _unsplit(b: Block) -> void:
	b.mi.visibility_range_begin = 0.0
	b.mi.visibility_range_begin_margin = 0.0
	b.split = false
	var freed: Array = []
	for k: int in b.kids:
		_free_block(b.kids[k], freed)
	b.kids.clear()
	if not freed.is_empty():
		_sync_tiles(freed)


## (the level 0 chunks freed into `freed`)
func _free_block(b: Block, freed: Array) -> void:
	for k: int in b.kids:
		_free_block(b.kids[k], freed)
	b.kids.clear()
	_blocks.erase(Vector3i(b.level, b.at.x, b.at.y))
	if b.level == 0:
		freed.append(b.at)
	b.mi.queue_free()


## How many of a block's four children lie inside the bake.
func _children_inside(level: int, at: Vector2i) -> int:
	if level == 0:
		return 0
	var n := 0
	var span := tuning.chunk_cells << (level - 1)
	for k in 4:
		var c := at * 2 + Vector2i(k % 2, k / 2)
		if c.x * span < terrain.width - 1 and c.y * span < terrain.depth - 1:
			n += 1
	return n


func _build_block(level: int, at: Vector2i, parent: Block) -> Block:
	var s := 1 << level
	var i0 := at.x * tuning.chunk_cells * s
	var j0 := at.y * tuning.chunk_cells * s
	if i0 >= terrain.width - 1 or j0 >= terrain.depth - 1:
		return null
	var b := Block.new()
	b.level = level
	b.at = at
	b.size = tuning.chunk_cells * s * terrain.spacing
	b.parent = parent
	b.expect = _children_inside(level, at)
	b.mi = MeshInstance3D.new()
	b.mi.name = "L%d_%d_%d" % [level, at.x, at.y]
	b.mi.mesh = _block_mesh(b)
	add_child(b.mi)
	if parent:
		b.mi.visibility_parent = b.mi.get_path_to(parent.mi)
	_blocks[Vector3i(level, at.x, at.y)] = b
	built += 1
	if level == 0:
		_sync_tiles([at])
	return b


## A block's mesh: its grid of the bake's points every 2^level, normals from the slope at its own
## spacing, the greybox's colours by slope and height, its skirt; its node set at its middle (where
## Godot measures a visibility range from). Level 0 leaves out its chunk's dug tiles' quads.
func _block_mesh(b: Block) -> ArrayMesh:
	var s := 1 << b.level
	var side := tuning.chunk_cells
	var i0 := b.at.x * side * s
	var j0 := b.at.y * side * s
	var nx := mini(side, (terrain.width - 1 - i0) / s)
	var nz := mini(side, (terrain.depth - 1 - j0) / s)
	var n := nx + 1
	var count := n * (nz + 1)
	# The block's points and a ring round them (clamped at the bake's edge), for the slopes.
	var en := n + 2
	var ex := PackedFloat32Array()
	ex.resize(en * (nz + 3))
	var w := terrain.width
	var hts := terrain.heights
	var last_i := terrain.width - 1
	var last_j := terrain.depth - 1
	for jj in range(-1, nz + 2):
		var row := clampi(j0 + jj * s, 0, last_j) * w
		var at := (jj + 1) * en
		for ii in range(-1, n + 1):
			ex[at + ii + 1] = hts[row + clampi(i0 + ii * s, 0, last_i)]
	var hs := PackedFloat32Array()
	hs.resize(count)
	var lo := INF
	var hi := -INF
	for jj in nz + 1:
		var at := (jj + 1) * en + 1
		for ii in n:
			var h := ex[at + ii]
			hs[jj * n + ii] = h
			if h < lo:
				lo = h
			if h > hi:
				hi = h
	# The skirt: past the most this block's edge differs from the bake along it.
	var err := 0.0
	if s > 1:
		var edges := [[Vector2i(0, 0), Vector2i(1, 0), nx], [Vector2i(0, nz), Vector2i(1, 0), nx],
				[Vector2i(0, 0), Vector2i(0, 1), nz], [Vector2i(nx, 0), Vector2i(0, 1), nz]]
		for e: Array in edges:
			var from: Vector2i = e[0]
			var dir: Vector2i = e[1]
			for q in int(e[2]):
				var a := from + dir * q
				var ha := hs[a.y * n + a.x]
				var hb := hs[(a.y + dir.y) * n + a.x + dir.x]
				var at0 := (j0 + a.y * s) * w + i0 + a.x * s
				var stride := dir.y * w + dir.x
				for f in range(1, s):
					var d := absf(ha + (hb - ha) * float(f) / s - hts[at0 + stride * f])
					if d > err:
						err = d
	var skirt := err + tuning.skirt_extra
	var step := s * terrain.spacing
	var centre := Vector3(terrain.x0 + (i0 + nx * s * 0.5) * terrain.spacing, (lo - skirt + hi) * 0.5,
			terrain.z0 + (j0 + nz * s * 0.5) * terrain.spacing)
	var perimeter := _perimeter(nx, nz)
	var total := count + perimeter.size()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	verts.resize(total)
	normals.resize(total)
	colors.resize(total)
	var ox := -nx * s * 0.5 * terrain.spacing
	var oz := -nz * s * 0.5 * terrain.spacing
	var rock_lo := tan(deg_to_rad(tuning.rock_from))
	var rock_hi := tan(deg_to_rad(tuning.rock_full))
	var inv := 1.0 / (2.0 * step)
	var dirt := tuning.dirt
	var k := 0
	for jj in nz + 1:
		var at := (jj + 1) * en + 1
		for ii in n:
			var e := at + ii
			var h := ex[e]
			verts[k] = Vector3(ox + ii * step, h - centre.y, oz + jj * step)
			var gx := (ex[e + 1] - ex[e - 1]) * inv
			var gz := (ex[e + en] - ex[e - en]) * inv
			normals[k] = Vector3(-gx, 1.0, -gz).normalized()
			var c := dirt
			if h < tuning.bottom_below:
				c = c.lerp(tuning.bottom, clampf((tuning.bottom_below - h) * 0.25, 0.0, 1.0))
			var slope2 := gx * gx + gz * gz
			if slope2 > rock_lo * rock_lo:
				c = c.lerp(tuning.rock, clampf((sqrt(slope2) - rock_lo) / (rock_hi - rock_lo), 0.0, 1.0))
			colors[k] = c
			k += 1
	for p in perimeter.size():
		var at := perimeter[p]
		verts[count + p] = verts[at] - Vector3(0.0, skirt, 0.0)
		normals[count + p] = normals[at]
		colors[count + p] = colors[at]
	var index: PackedInt32Array
	var holes: Array = _holes.get(Vector2i(b.at.x, b.at.y), []) if b.level == 0 else []
	if holes.is_empty():
		index = _shared_index(nx, nz, perimeter, count)
	else:
		var skip := {}
		for key: Vector2i in holes:
			var q := _tile_quad(key, b.at)
			for dj in _tile_quads:
				for di in _tile_quads:
					skip[Vector2i(q.x + di, q.y + dj)] = true
		index = _grid_index(nx, nz, skip)
		index.append_array(_skirt_index(perimeter, count))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = index
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material:
		mesh.surface_set_material(0, material)
	if b.mi:
		b.mi.position = centre
	else:
		push_error("ValleyGround: a block's mesh before its node")
	return mesh


## The grid's edge points, once round clockwise seen from above (north edge west to east, the
## east edge north to south, ...), as indices into the grid.
func _perimeter(nx: int, nz: int) -> PackedInt32Array:
	var n := nx + 1
	var out := PackedInt32Array()
	for ii in nx:
		out.append(ii)
	for jj in nz:
		out.append(jj * n + nx)
	for ii in range(nx, 0, -1):
		out.append(nz * n + ii)
	for jj in range(nz, 0, -1):
		out.append(jj * n)
	return out


## Each quad split as Jolt splits its height field ((i + 1, j) to (i, j + 1)), facing up; `skip`'s
## quads left out.
func _grid_index(nx: int, nz: int, skip := {}) -> PackedInt32Array:
	var n := nx + 1
	var idx := PackedInt32Array()
	for jj in nz:
		for ii in nx:
			if not skip.is_empty() and skip.has(Vector2i(ii, jj)):
				continue
			var a := jj * n + ii
			idx.append_array([a, a + 1, a + n, a + 1, a + n + 1, a + n])
	return idx


## The skirt: a strip down from each edge point to its copy below (the copies after the grid's
## `count` points), facing out.
func _skirt_index(perimeter: PackedInt32Array, count: int) -> PackedInt32Array:
	var idx := PackedInt32Array()
	var m := perimeter.size()
	for p in m:
		var q := (p + 1) % m
		idx.append_array([perimeter[p], count + p, perimeter[q], perimeter[q], count + p, count + q])
	return idx


func _shared_index(nx: int, nz: int, perimeter: PackedInt32Array, count: int) -> PackedInt32Array:
	var key := Vector2i(nx, nz)
	if not _index_cache.has(key):
		var idx := _grid_index(nx, nz)
		idx.append_array(_skirt_index(perimeter, count))
		_index_cache[key] = idx
	return _index_cache[key]


## Each dug tile's mesh drawn exactly when its chunk's level 0 is (its parent's range), and not
## while that isn't built (the coarser levels have no hole for it). `only`: those chunks' tiles
## (a block built or freed, a chunk's holes changed); all of them otherwise.
func _sync_tiles(only: Array = []) -> void:
	if ground == null:
		return
	var chunks_to := only if not only.is_empty() else _holes.keys()
	for ck: Vector2i in chunks_to:
		var b: Block = _blocks.get(Vector3i(0, ck.x, ck.y))
		for key: Vector2i in _holes.get(ck, []):
			var t: GroundTile = ground.tiles.get(key)
			if t == null or not is_instance_valid(t):
				continue
			var mi := t.drawn()
			if mi == null:
				continue
			if b == null or b.parent == null or b.mi.is_queued_for_deletion() or not b.mi.is_inside_tree() or not mi.is_inside_tree():
				# (no level 0 there: the coarser levels have no hole for it; and no link to a block
				# that's going)
				mi.visibility_parent = NodePath()
				mi.visible = b != null and b.parent == null and not b.mi.is_queued_for_deletion()
				continue
			mi.visible = true
			mi.visibility_parent = mi.get_path_to(b.parent.mi)


## Blocks built and drawn now, by level (the bench's numbers).
func census() -> Dictionary:
	var by := {}
	for key: Vector3i in _blocks:
		by[key.x] = int(by.get(key.x, 0)) + 1
	return {"blocks": _blocks.size(), "by_level": by, "built": built, "chunks": bodies.size()}
