class_name MemberMesh
## Box meshes for structure members with texture coordinates in metres, laid so the grain (u)
## runs along each member's length on every face. With PixelArt.texels_per_meter applied in the
## material, texels are the same size on every board, beam and post.

static var _cache := {}


static func box(size: Vector3) -> ArrayMesh:
	var key := size.snappedf(0.001)
	if _cache.has(key):
		return _cache[key]
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
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = face_sizes
	arrays[Mesh.ARRAY_TANGENT] = null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_cache[key] = mesh
	return mesh


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
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
