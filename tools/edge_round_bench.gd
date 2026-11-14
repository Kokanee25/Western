extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The eased edges' two ways measured (#873): every library board of a building as the game draws it
## (PropKit.board_mesh, its edges eased by scan_wood.gdshader's `edge_round`, no extra geometry)
## against the same boards as bevelled meshes (a quarter round of two segments on each long arris,
## its sides hard, its ends flat: the cheapest mesh that rounds a silhouette). Prints vertices,
## triangles and the time to build them for the building's boards.
##
##   godot --headless -s res://tools/edge_round_bench.gd -- [--spec=res://experiments/building_lab/saloon_b/saloon_b.json]

func _initialize() -> void:
	await process_frame
	var Lab = load("res://experiments/building_lab/lab.gd")
	var Kit = load("res://src/props/prop_kit.gd")
	var spec := "res://experiments/building_lab/saloon_b/saloon_b.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spec="):
			spec = a.get_slice("=", 1)
	Lab.spec_path = spec
	var lab = Lab.new()
	root.add_child(lab)
	Lab.spec_path = ""
	await process_frame
	var boards: Array = []
	for m in lab.building.get_members():
		var mi = m.drawn_node()
		if mi == null or mi.mesh == null or not mi.mesh.has_meta(&"board_frame"):
			continue
		var cd: PackedFloat32Array = (mi.mesh.get_meta(&"arrays") as Array)[Mesh.ARRAY_CUSTOM1]
		boards.append(Vector3(cd[0], cd[1], cd[2]))
	var res := {}
	for way in ["shader", "bevel"]:
		var verts := 0
		var tris := 0
		var t0 := Time.get_ticks_usec()
		for b: Vector3 in boards:
			var arr: Array = Kit.board_mesh(b.x, b.y, b.z, 0.5, 0.5, Vector2.ZERO, 0.0).get_meta(&"arrays") if way == "shader" \
					else bevelled(b.x, b.y, b.z, minf(0.004, 0.45 * minf(b.y, b.z)))
			verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		res[way] = [verts, tris, (Time.get_ticks_usec() - t0) / 1000.0]
		print("%-6s %d boards: %d vertices, %d triangles, built in %.0f ms" % [way, boards.size(), verts, tris, res[way][2]])
	print("bevel / shader: vertices x%.2f, triangles x%.2f, build time x%.2f" % [
			float(res.bevel[0]) / res.shader[0], float(res.bevel[1]) / res.shader[1], res.bevel[2] / res.shader[2]])
	quit(0)


## A board L x W x T (X along, Y across, Z through) with its four long arrises rounded `r` (two
## segments a corner), its flats hard, the same rows along it as board_mesh's, its ends flat caps.
## With the library shader's channels and made into a mesh, as board_mesh is (a fair build time).
static func bevelled(length: float, width: float, thick: float, r: float) -> Array:
	var nx := clampi(ceili(length / 0.4), 2, 14)
	var hw := width * 0.5
	var ht := thick * 0.5
	# The section's outline: per corner an arc of 3 points, per side its two ends (hard): 20 a ring.
	var ring: Array[Vector2] = []
	var rn: Array[Vector2] = []
	var centres := [Vector2(hw - r, ht - r), Vector2(-hw + r, ht - r), Vector2(-hw + r, -ht + r), Vector2(hw - r, -ht + r)]
	for k in 4:
		var a0 := PI * 0.5 * k
		for j in 3:
			var a := a0 + PI * 0.25 * j
			ring.append(centres[k] + Vector2(cos(a), sin(a)) * r)
			rn.append(Vector2(cos(a), sin(a)))
		var a1 := a0 + PI * 0.5
		var nf := Vector2(cos(a1), sin(a1))
		ring.append(centres[k] + nf * r)
		rn.append(nf)
		ring.append(centres[(k + 1) % 4] + nf * r)
		rn.append(nf)
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var idx := PackedInt32Array()
	var rs := ring.size()
	# The library shader's channels on every vertex, as board_mesh fills them (a fair build time).
	var chan := func(p: Vector3, face: float) -> void:
		uv.append(Vector2(p.x, p.y))
		c0.append_array([0.5, p.x / length, p.y / maxf(hw, 0.001), face])
		c1.append_array([length, width, thick, 0.5])
		c2.append_array([0.0, 0.0, 0.0, 0.0])
	for i in nx + 1:
		var x := length * i / nx
		for j in rs:
			v.append(Vector3(x, ring[j].x, ring[j].y))
			n.append(Vector3(0.0, rn[j].x, rn[j].y))
			chan.call(v[v.size() - 1], 0.0)
	for i in nx:
		for j in rs:
			var a := i * rs + j
			var b := i * rs + (j + 1) % rs
			idx.append_array([a, a + rs, b, b, a + rs, b + rs])
	for e in [0.0, length]:
		var base := v.size()
		for j in rs:
			v.append(Vector3(e, ring[j].x, ring[j].y))
			n.append(Vector3(-1.0 if e == 0.0 else 1.0, 0.0, 0.0))
			chan.call(v[v.size() - 1], 1.0)
		for j in range(1, rs - 1):
			idx.append_array([base, base + j, base + j + 1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_CUSTOM0] = c0
	arrays[Mesh.ARRAY_CUSTOM1] = c1
	arrays[Mesh.ARRAY_CUSTOM2] = c2
	arrays[Mesh.ARRAY_INDEX] = idx
	var fmt := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) \
			| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
			| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT)
	ArrayMesh.new().add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, fmt)
	return arrays
