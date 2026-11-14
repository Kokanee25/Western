class_name StoneFinish
extends RefCounted
## A stone building's walls drawn in the material library's stone and lime (#860, #857; the shader
## `rubble_stone.gdshader`; entries `rubble_stone`, `plaster_whitewash`, `rubble_whitewash`). The
## builder's stone pieces stay the members they are (destruction, the support graph and the tests
## untouched); only how they draw changes:
##
## - **One material a building**, the rubble laid in the building's own space (`to_local`), so the
##   pieces batch together as before and the joints run across their seams.
## - **Each piece its own mesh** (`piece_mesh`): its box with the arrises that show knocked off
##   (`exposed`: a face no other stone piece covers; an edge between two such faces is chamfered a
##   few cm), so a corner, a parapet's top or a reveal isn't ruled. COLOR carries its seed (r) and
##   whether it's dressed stone (g); UV where on its face, UV2 that face's size in metres.
## - **The building's space** (`set_space`): its ground plane (damp and dirt rise from it), the rooms'
##   regions (a face looking into one takes its plaster or whitewash), its convex corners (quoins), the
##   drip lines (streaks under the sills and the coping).

const SHADER := preload("res://src/render/rubble_stone.gdshader")

## Library fields the shader takes by the same name (floats), and colours.
const DIALS := ["size_jitter", "joint", "joint_depth", "stone_relief", "bed_wander", "arris_round", "tone_spread",
		"dressed_joint", "limewash", "roughness_stone", "roughness_mortar", "normal_strength", "damp_height",
		"dirt_height", "streaks", "soot", "face_tile", "plaster_tile"]
const COLOURS := ["tone_a", "tone_b", "tone_c", "tone_d", "mortar_color", "dressed_color", "limewash_color",
		"damp_tint", "dirt_color", "streak_color", "whitewash_color", "plaster_color", "grime_color"]
const FINISH_KIND := {"plaster_whitewash": 1, "rubble_whitewash": 2}


## The material from an outside entry at an age (0 new .. 1 old) and the inside entries' colours
## (plaster_whitewash's, rubble_whitewash's) at their age.
static func material(outside: Dictionary, age: float, inside_age := 0.6) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter(&"big_noise", MaterialLibrary.noise())
	_apply(m, MaterialLibrary.resolved(outside))
	for id in ["plaster_whitewash", "rubble_whitewash"]:
		var e := MaterialLibrary.entry(id)
		if not e.is_empty():
			_apply(m, MaterialLibrary.resolved(e))
	m.set_shader_parameter(&"age", age)
	m.set_shader_parameter(&"inside_age", inside_age)
	var sz: Array = outside.get("stone", [0.35, 0.22])
	m.set_shader_parameter(&"stone_size", Vector2(float(sz[0]), float(sz[1])))
	var q: Array = outside.get("quoin", [0.45, 0.3, 0.3])
	m.set_shader_parameter(&"quoin", Vector3(float(q[0]), float(q[1]), float(q[2])))
	return m


static func _apply(m: ShaderMaterial, e: Dictionary) -> void:
	for d in DIALS:
		if e.has(d):
			m.set_shader_parameter(d, float(e[d]))
	for c in COLOURS:
		if e.has(c):
			var a: Array = e[c]
			m.set_shader_parameter(c, Color(a[0], a[1], a[2]))
	for slot in [["face", "face_scan"], ["plaster", "plaster_scan"]]:
		var sid := String(e.get(slot[1], ""))
		if sid == "":
			continue
		var dir := MaterialLibrary.SCANS + sid + "/"
		if not ResourceLoader.exists(dir + "albedo.jpg"):
			continue
		m.set_shader_parameter("has_" + slot[0], true)
		m.set_shader_parameter(slot[0] + "_albedo", load(dir + "albedo.jpg"))
		m.set_shader_parameter(slot[0] + "_mean", scan_mean(dir))


## The building's space: `to_local` (world -> building), its ground plane [a, b, c] (y = a + b x + c z),
## regions [{rect: [x0, z0, x1, z1], y: [floor, ceiling], finish: id}], corners [Vector2], drips
## [[Vector2 a, Vector2 b, y, Vector2 out, length]].
static func set_space(m: ShaderMaterial, to_local: Transform3D, plane: Array, regions: Array, corners: Array, drips: Array) -> void:
	m.set_shader_parameter(&"to_local", Projection(to_local))
	m.set_shader_parameter(&"ground", Vector3(float(plane[0]), float(plane[1]), float(plane[2])))
	var rr: Array[Vector4] = []
	var ra: Array[Vector4] = []
	for r: Dictionary in regions.slice(0, 8):
		var rc: Array = r.rect
		rr.append(Vector4(rc[0], rc[1], rc[2], rc[3]))
		ra.append(Vector4(r.y[0], r.y[1], float(FINISH_KIND.get(String(r.finish), 1)), 0.0))
	while rr.size() < 8:
		rr.append(Vector4.ZERO)
		ra.append(Vector4.ZERO)
	m.set_shader_parameter(&"region_count", mini(regions.size(), 8))
	m.set_shader_parameter(&"regions", rr)
	m.set_shader_parameter(&"region_at", ra)
	var cs: Array[Vector2] = []
	for c: Vector2 in corners.slice(0, 16):
		cs.append(c)
	m.set_shader_parameter(&"corner_count", cs.size())
	while cs.size() < 16:
		cs.append(Vector2.ZERO)
	m.set_shader_parameter(&"corners", cs)
	var da: Array[Vector4] = []
	var dt: Array[Vector4] = []
	for d: Array in drips.slice(0, 96):
		da.append(Vector4(d[0].x, d[0].y, d[1].x, d[1].y))
		dt.append(Vector4(d[2], d[3].x, d[3].y, d[4]))
	m.set_shader_parameter(&"drip_count", da.size())
	while da.size() < 96:
		da.append(Vector4.ZERO)
		dt.append(Vector4.ZERO)
	m.set_shader_parameter(&"drips", da)
	m.set_shader_parameter(&"drip_at", dt)


static var _means := {}

## A scan's mean colour, linear (its meta.json `mean_linear` where it has one, else worked out from its
## albedo once): the shader takes a scan's detail as its ratio to this, not its colour.
static func scan_mean(dir: String) -> Vector3:
	if _means.has(dir):
		return _means[dir]
	var mean := MaterialLibrary._mean(dir)
	if mean.is_equal_approx(Vector3.ONE):
		var img := (load(dir + "albedo.jpg") as Texture2D).get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(16, 16, Image.INTERPOLATE_BILINEAR)
		var sum := Vector3.ZERO
		for y in 16:
			for x in 16:
				var c := img.get_pixel(x, y).srgb_to_linear()
				sum += Vector3(c.r, c.g, c.b)
		mean = sum / 256.0
	_means[dir] = mean.clamp(Vector3.ONE * 0.02, Vector3.ONE)
	return _means[dir]


# --- the pieces' meshes --------------------------------------------------------------------------

## The faces: 0 +x, 1 -x, 2 +y, 3 -y, 4 +z, 5 -z.
const FACES := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]


## Which faces of each box no other box covers: boxes [AABB], a bit a face (FACES' order). A face is
## covered where other boxes overlap a thin slab over it by more than `cover` of its area.
static func exposed(boxes: Array, cover := 0.6) -> PackedInt32Array:
	var cell := 1.0
	var grid := {}
	for i in boxes.size():
		var b: AABB = boxes[i]
		var lo := (b.position / cell).floor()
		var hi := (b.end / cell).floor()
		for x in range(int(lo.x), int(hi.x) + 1):
			for y in range(int(lo.y), int(hi.y) + 1):
				for z in range(int(lo.z), int(hi.z) + 1):
					var k := Vector3i(x, y, z)
					if not grid.has(k):
						grid[k] = []
					(grid[k] as Array).append(i)
	var out := PackedInt32Array()
	out.resize(boxes.size())
	for i in boxes.size():
		var b: AABB = boxes[i]
		var near := {}
		var lo := ((b.position - Vector3.ONE * 0.05) / cell).floor()
		var hi := ((b.end + Vector3.ONE * 0.05) / cell).floor()
		for x in range(int(lo.x), int(hi.x) + 1):
			for y in range(int(lo.y), int(hi.y) + 1):
				for z in range(int(lo.z), int(hi.z) + 1):
					for j in grid.get(Vector3i(x, y, z), []):
						if j != i:
							near[j] = true
		var mask := 0
		for f in 6:
			var n: Vector3 = FACES[f]
			var ax := int(n.abs().max_axis_index())
			var slab := b
			var t := 0.01
			if n[ax] > 0.0:
				slab.position[ax] = b.end[ax] - t * 0.5
			else:
				slab.position[ax] = b.position[ax] - t * 0.5
			slab.size[ax] = t
			var area := 1.0
			for k in 3:
				if k != ax:
					area *= maxf(b.size[k], 1e-4)
			var covered := 0.0
			for j: int in near:
				var o: AABB = boxes[j]
				var isect := slab.intersection(o)
				if isect.size == Vector3.ZERO and not slab.intersects(o):
					continue
				var a := 1.0
				for k in 3:
					if k != ax:
						a *= maxf(minf(slab.end[k], o.end[k]) - maxf(slab.position[k], o.position[k]), 0.0)
				covered += a
			if covered < area * cover:
				mask |= 1 << f
		out[i] = mask
	return out


## A box `size` about its centre, the edges between two faces in `faces` (a bit each, FACES' order)
## chamfered `c` (each a 45-degree facet c wide): a face's border cells c wide, the arris's vertices
## moved in half c along both its faces (the cell either side then lies in the facet). `seed` 0..1 and
## `dressed` go in COLOR (r, g); UV over each face 0..1, UV2 the face's size.
static func piece_mesh(size: Vector3, faces: int, c: float, seed: float, dressed: bool) -> ArrayMesh:
	var h := size * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := Color(seed, 1.0 if dressed else 0.0, 0.0, 1.0)
	var cd := minf(c, size[size.min_axis_index()] * 0.3)
	for f in 6:
		var n: Vector3 = FACES[f]
		var a := int(n.abs().max_axis_index())
		var bx := (a + 1) % 3
		var cx := (a + 2) % 3
		var s := n[a]
		# Its border cells as wide as the chamfer (a hidden face's too: a corner moved by its neighbours'
		# chamfers clips its corner cell, and its edge cells keep the arris's points, no crack).
		var cc := cd
		var cb := [-h[bx], -h[bx] + cc, h[bx] - cc, h[bx]]
		var ccv := [-h[cx], -h[cx] + cc, h[cx] - cc, h[cx]]
		var grid := []
		var moved := false
		for i in 4:
			var row := []
			for j in 4:
				var p := Vector3.ZERO
				p[a] = s * h[a]
				p[bx] = cb[i]
				p[cx] = ccv[j]
				var q := _chamfered(p, h, faces, cd)
				if not q.is_equal_approx(p):
					moved = true
				row.append([q, Vector2((p[bx] + h[bx]) / size[bx], (p[cx] + h[cx]) / size[cx])])
			grid.append(row)
		var uv2 := Vector2(size[bx], size[cx])
		if not moved:
			_quad(st, grid[0][0], grid[3][0], grid[3][3], grid[0][3], n, col, uv2)
			continue
		for i in 3:
			for j in 3:
				_quad(st, grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1], n, col, uv2)
	st.index()
	return st.commit()


## Where a box's surface point goes when the box's arrises between exposed faces are chamfered `c`:
## along each axis whose face it lies on, in half c if an edge it lies on (that face and another
## it's also on, both exposed) is chamfered.
static func _chamfered(p: Vector3, h: Vector3, faces: int, c: float) -> Vector3:
	if c <= 0.0:
		return p
	var on := []  # the faces p lies on
	for k in 3:
		if absf(absf(p[k]) - h[k]) < 1e-5:
			var f := k * 2 + (0 if p[k] > 0.0 else 1)
			if faces & (1 << f):
				on.append([k, f])
	var q := p
	if on.size() < 2:
		return q
	for e in on:
		q[e[0]] -= signf(p[e[0]]) * c * 0.5
	return q


## Two triangles of a quad (corners [pos, uv] round it), wound to face `n` (Godot's front faces are
## clockwise seen from outside), each with its own flat normal; degenerate ones dropped.
static func _quad(st: SurfaceTool, a: Array, b: Array, c: Array, d: Array, n: Vector3, col: Color, uv2: Vector2) -> void:
	for t in [[a, b, c], [a, c, d]]:
		var p0: Vector3 = t[0][0]
		var p1: Vector3 = t[1][0]
		var p2: Vector3 = t[2][0]
		var cr := (p1 - p0).cross(p2 - p0)
		if cr.length_squared() < 1e-12:
			continue
		var tri: Array = t
		if cr.dot(n) > 0.0:
			tri = [t[0], t[2], t[1]]
			cr = -cr
		var nn := -cr.normalized()
		for v: Array in tri:
			st.set_normal(nn)
			st.set_color(col)
			st.set_uv(v[1])
			st.set_uv2(uv2)
			st.add_vertex(v[0])
