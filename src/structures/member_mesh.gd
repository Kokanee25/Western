class_name MemberMesh
## Box meshes for structure members with texture coordinates in metres, laid so the grain (u)
## runs along each member's length on every face. With PixelArt.texels_per_meter applied in the
## material, texels are the same size on every board, beam and post.

static var _cache := {}


static func box(size: Vector3) -> ArrayMesh:
	var key := size.snappedf(0.001)
	if _cache.has(key):
		return _cache[key]
	var mesh := _from_template(size)
	if mesh == null:
		mesh = _built(size)
	_cache[key] = mesh
	return mesh


## Laid out once a kind of box (which axis is longest, and which of the other two is the longer:
## that decides every face's u and v): each vertex's corner (±0.5 an axis), and its u and v axes.
## A cut's ends are each a size of their own, so each missed the cache and was built the long way
## (~70 µs here, a blast's ~140 ends, #538). [corners, normals, indices, axes (u, v a vertex)]
static var _templates := {}


static func _kind_of(size: Vector3) -> int:
	var long_axis := 0
	for a in 3:
		if size[a] > size[long_axis]:
			long_axis = a
	var p0 := 1 if long_axis == 0 else 0
	var p1 := 2 if long_axis != 2 else 1
	return long_axis * 2 + (0 if size[p0] >= size[p1] else 1)


static func _from_template(size: Vector3) -> ArrayMesh:
	if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
		return null
	var kind := _kind_of(size)
	var tpl: Array = _templates.get(kind, [])
	if tpl.is_empty():
		return null
	var corners: PackedVector3Array = tpl[0]
	var axes: PackedInt32Array = tpl[3]
	var n := corners.size()
	var verts := PackedVector3Array()
	verts.resize(n)
	var uvs := PackedVector2Array()
	uvs.resize(n)
	var face_sizes := PackedVector2Array()
	face_sizes.resize(n)
	var half := size * 0.5
	for i in n:
		var v := corners[i] * size
		verts[i] = v
		var p := v + half
		var u := axes[i * 2]
		var w := axes[i * 2 + 1]
		uvs[i] = Vector2(p[u], p[w])
		face_sizes[i] = Vector2(size[u], size[w])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = tpl[1]
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = face_sizes
	arrays[Mesh.ARRAY_INDEX] = tpl[2]
	return made(arrays)


## The box the long way (a BoxMesh's faces, each laid out), its kind's template kept.
static func _built(size: Vector3) -> ArrayMesh:
	var src := BoxMesh.new()
	src.size = size
	var arrays := src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs := PackedVector2Array()
	uvs.resize(verts.size())
	# The face's size in metres (its UVs run from 0 to this): texel lighting keeps the point it
	# lights a texel at on the face (texel_grid.gdshaderinc).
	var face_sizes := PackedVector2Array()
	face_sizes.resize(verts.size())
	var long_axis := 0
	for a in 3:
		if size[a] > size[long_axis]:
			long_axis = a
	var corners := PackedVector3Array()
	corners.resize(verts.size())
	var axes := PackedInt32Array()
	axes.resize(verts.size() * 2)
	for i in verts.size():
		var n := normals[i].abs()
		var face_axis := 0 if n.x >= n.y and n.x >= n.z else (1 if n.y >= n.z else 2)
		var plane: Array[int] = []
		for a in 3:
			if a != face_axis:
				plane.append(a)
		var u_axis := long_axis
		if long_axis == face_axis:
			u_axis = plane[0] if size[plane[0]] >= size[plane[1]] else plane[1]
		var v_axis := plane[0] if plane[0] != u_axis else plane[1]
		var p := verts[i] + size * 0.5
		uvs[i] = Vector2(p[u_axis], p[v_axis])
		face_sizes[i] = Vector2(size[u_axis], size[v_axis])
		corners[i] = verts[i].sign() * 0.5
		axes[i * 2] = u_axis
		axes[i * 2 + 1] = v_axis
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = face_sizes
	arrays[Mesh.ARRAY_TANGENT] = null
	if size.x > 0.0 and size.y > 0.0 and size.z > 0.0 and not _templates.has(_kind_of(size)):
		_templates[_kind_of(size)] = [corners, arrays[Mesh.ARRAY_NORMAL], arrays[Mesh.ARRAY_INDEX], axes]
	return made(arrays)


## A member's box drawn bent (BuildingAge: a sagging beam, a hollow tread): the box in `segments`
## along its length, each vertex put where `warp` (member space to member space) sends it. Its
## texture coordinates are the straight box's (MemberMesh.box), so the grain follows the bend.
static func warped(size: Vector3, segments: int, warp: Callable) -> ArrayMesh:
	var long_axis := 0
	for a in 3:
		if size[a] > size[long_axis]:
			long_axis = a
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var face_sizes := PackedVector2Array()
	var indices := PackedInt32Array()
	for face_axis in 3:
		var plane: Array[int] = []
		for a in 3:
			if a != face_axis:
				plane.append(a)
		var u_axis := long_axis
		if long_axis == face_axis:
			u_axis = plane[0] if size[plane[0]] >= size[plane[1]] else plane[1]
		var v_axis := plane[0] if plane[0] != u_axis else plane[1]
		var nu := segments if u_axis == long_axis else 1
		for s: float in [-1.0, 1.0]:
			var normal := Vector3.ZERO
			normal[face_axis] = s
			var base := verts.size()
			for i in nu + 1:
				for j in 2:
					var p := Vector3.ZERO
					p[face_axis] = s * size[face_axis] * 0.5
					p[u_axis] = size[u_axis] * (float(i) / nu - 0.5)
					p[v_axis] = size[v_axis] * (j - 0.5)
					verts.append(warp.call(p))
					normals.append(normal)
					uvs.append(Vector2(p[u_axis] + size[u_axis] * 0.5, p[v_axis] + size[v_axis] * 0.5))
					face_sizes.append(Vector2(size[u_axis], size[v_axis]))
			# Two triangles a segment, wound as BoxMesh's (their cross product against the normal).
			var across := Vector3.ZERO
			across[u_axis] = 1.0
			var up := Vector3.ZERO
			up[v_axis] = 1.0
			var flip := across.cross(up).dot(normal) > 0.0
			for i in nu:
				var a := base + i * 2
				var quad := [a, a + 2, a + 3, a + 1]
				if flip:
					indices.append_array([quad[0], quad[2], quad[1], quad[0], quad[3], quad[2]])
				else:
					indices.append_array([quad[0], quad[1], quad[2], quad[0], quad[2], quad[3]])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = face_sizes
	arrays[Mesh.ARRAY_INDEX] = indices
	return made(arrays)


## A mesh of these arrays, with them kept on it (`arrays_of`).
static func made(arrays: Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.set_meta(&"arrays", arrays)
	return mesh


## A mesh's first surface as arrays, without asking the renderer for them where it can (#626).
## `surface_get_arrays` on Vulkan reads each buffer back from the GPU and waits for every frame in
## flight first (RenderingDevice.buffer_get_data): with the GPU busy, a frame's worth for each
## piece RubbleRest joined (Sean's F12s: its join at ~40 ms a frame as the farmhouse's rubble
## settled; headless, where the lab runs, it costs nothing). The arrays a mesh was made from are
## kept on it (`made`); a primitive's are made again on the CPU; any other mesh is read back once
## and kept. They carry the channels the renderer's would: a mesh with normals and no tangents is
## given the tangents the renderer gives it (`_tangents`), so a batch or cell merged from them is
## drawn as before.
static func arrays_of(mesh: Mesh) -> Array:
	var arrays: Array
	if mesh.has_meta(&"arrays"):
		arrays = mesh.get_meta(&"arrays")
		if arrays[Mesh.ARRAY_NORMAL] == null or arrays[Mesh.ARRAY_TANGENT] != null:
			return arrays
	else:
		arrays = (mesh as PrimitiveMesh).get_mesh_arrays() if mesh is PrimitiveMesh else mesh.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_NORMAL] != null and arrays[Mesh.ARRAY_TANGENT] == null:
		arrays = arrays.duplicate()
		arrays[Mesh.ARRAY_TANGENT] = _tangents(arrays[Mesh.ARRAY_NORMAL])
	mesh.set_meta(&"arrays", arrays)
	return arrays


## The tangent the renderer stores for a normal given none (its rule, Godot 4.7's
## RenderingServer: a vector turned off the normal, crossed with it; handedness +1).
static func _tangents(normals: PackedVector3Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(normals.size() * 4)
	for i in normals.size():
		var n := normals[i]
		var t := Vector3(n.z, -n.x, n.y).cross(n.normalized()).normalized()
		out[i * 4] = t.x
		out[i * 4 + 1] = t.y
		out[i * 4 + 2] = t.z
		out[i * 4 + 3] = 1.0
	return out


## The arrays it was made of as they are (no tangents added): pure data a worker can place
## (RubbleRest's join, #642). Anything not made by `made` (or a primitive) is `arrays_of`'s.
static func made_arrays(mesh: Mesh) -> Array:
	if mesh.has_meta(&"arrays"):
		return mesh.get_meta(&"arrays")
	return arrays_of(mesh)


## The arrays' triangles one by one (no index), placed by `xf`: what SurfaceTool's append_from,
## deindex and commit_to_arrays make of them, without the read back (`arrays_of`). Normals with no
## tangents get the renderer's (`_tangents`). Pure: safe on a worker.
static func placed(arrays: Array, xf: Transform3D) -> Array:
	if arrays[Mesh.ARRAY_NORMAL] != null and arrays[Mesh.ARRAY_TANGENT] == null:
		arrays = arrays.duplicate()
		arrays[Mesh.ARRAY_TANGENT] = _tangents(arrays[Mesh.ARRAY_NORMAL])
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	var index: Variant = arrays[Mesh.ARRAY_INDEX]
	var idx: PackedInt32Array = index if index != null else PackedInt32Array()
	for slot: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
		var src: Variant = arrays[slot]
		if src == null:
			continue
		if idx.is_empty():
			out[slot] = src.duplicate()
			continue
		var width := 4 if slot == Mesh.ARRAY_TANGENT else 1
		var dst: Variant = src.duplicate()
		dst.resize(idx.size() * width)
		for i in idx.size():
			for k in width:
				dst[i * width + k] = src[idx[i] * width + k]
		out[slot] = dst
	out[Mesh.ARRAY_VERTEX] = xf * (out[Mesh.ARRAY_VERTEX] as PackedVector3Array)
	var turn := Transform3D(xf.basis, Vector3.ZERO)
	if out[Mesh.ARRAY_NORMAL] != null:
		out[Mesh.ARRAY_NORMAL] = turn * (out[Mesh.ARRAY_NORMAL] as PackedVector3Array)
	if out[Mesh.ARRAY_TANGENT] != null:
		var tan: PackedFloat32Array = out[Mesh.ARRAY_TANGENT]
		for i in tan.size() / 4:
			var t := xf.basis * Vector3(tan[i * 4], tan[i * 4 + 1], tan[i * 4 + 2])
			tan[i * 4] = t.x
			tan[i * 4 + 1] = t.y
			tan[i * 4 + 2] = t.z
		out[Mesh.ARRAY_TANGENT] = tan
	return out
