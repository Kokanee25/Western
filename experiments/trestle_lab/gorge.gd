extends RefCounted
## The trestle lab's gorge (#623): a canyon cut across the line to fit the route's crossing, so it
## moves with the line ("the lab's gorge is generated to fit it"). Its axis crosses the line at the
## crossing's middle, square to it there; its rims are where the crossing ends (the abutments sit on
## them); its floor `floor_half` m either side of the axis at `depth` m below the rim; its walls
## fall `1 - x^wall_power` from the rim (steep at the top, easing into the floor); its axis wanders
## `meander` m either way along its length. The route file's "gorge" block holds the numbers.
##
##   var g := GORGE.new(line, route.data.get("gorge", {}))
##   line.ground_y = g.height        # before line.build(): the fill and the bents reach down to it
##   line.add_child(g.build())       # drawn and solid (the cars and the wreck land on it)
##
## Space: the line's (its ground on the flat at y 0).

var line: TrackLine
var depth := 66.0
var floor_half := 22.0
var wall_power := 1.7
var meander := 8.0
## The river on its floor: {half_width, depth} (m; none if empty). Drawn only: what falls in lands on
## the floor under it.
var river := {}
var mid_s := 0.0
var half_rim := 150.0
## The gorge's frame: the crossing's middle on the ground, `a` along the line there, `b` across it
## (the gorge's axis).
var origin := Vector3.ZERO
var dir_a := Vector3.FORWARD
var dir_b := Vector3.RIGHT


func _init(on_line: TrackLine, spec: Dictionary) -> void:
	line = on_line
	depth = float(spec.get("depth", depth))
	floor_half = float(spec.get("floor_half", floor_half))
	wall_power = float(spec.get("wall_power", wall_power))
	meander = float(spec.get("meander", meander))
	river = spec.get("river", {})
	var c: Dictionary = line.crossings[0] if not line.crossings.is_empty() else {"from_s": line.length * 0.4, "to_s": line.length * 0.6}
	mid_s = (float(c.from_s) + float(c.to_s)) * 0.5
	half_rim = (float(c.to_s) - float(c.from_s)) * 0.5
	var f := line.transform_at(mid_s)
	origin = Vector3(f.origin.x, 0.0, f.origin.z)
	dir_a = Vector3(-f.basis.z.x, 0.0, -f.basis.z.z).normalized()
	dir_b = Vector3(f.basis.x.x, 0.0, f.basis.x.z).normalized()


## How far below the flat the ground is at (x, z), line space.
func depth_at(x: float, z: float) -> float:
	var p := Vector3(x, 0.0, z) - origin
	var b := p.dot(dir_b)
	var a := p.dot(dir_a) - meander * sin(b / 70.0)
	var u := absf(a) / maxf(half_rim, 1.0)
	var uf := floor_half / maxf(half_rim, 1.0)
	if u <= uf:
		return depth
	if u >= 1.0:
		return 0.0
	return depth * (1.0 - pow((u - uf) / (1.0 - uf), wall_power))


## The ground's height (line space): TrackLine.ground_y.
func height(x: float, z: float) -> float:
	return -depth_at(x, z)


## The ground drawn and solid over the whole line (fine rows over the gorge, coarse past it), its
## rock darker and redder the deeper it is. One StaticBody3D on WORLD.
func build() -> Node3D:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var s := 0.0
	while s <= line.length:
		var p := line.point_at(s) - origin
		var q := Vector2(p.dot(dir_a), p.dot(dir_b))
		lo = lo.min(q)
		hi = hi.max(q)
		s += 20.0
	lo -= Vector2(80.0, 140.0)
	hi += Vector2(80.0, 140.0)
	# Along the gorge at least 400 m either way (the far rim's cameras stand out there).
	lo.y = minf(lo.y, -400.0)
	hi.y = maxf(hi.y, 400.0)
	var rows_a: Array[float] = []
	var a := lo.x
	while a < hi.x:
		rows_a.append(a)
		var near := absf(a) < half_rim + meander + 30.0
		a += 3.0 if near else 25.0
	rows_a.append(hi.x)
	var rows_b: Array[float] = []
	var b := lo.y
	while b < hi.y:
		rows_b.append(b)
		b += 8.0 if absf(b) < 200.0 else 25.0
	rows_b.append(hi.y)
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	for av in rows_a:
		for bv in rows_b:
			var p := origin + dir_a * av + dir_b * bv
			var d := depth_at(p.x, p.z)
			verts.append(Vector3(p.x, -d - 0.02, p.z))
			var k := clampf(d / maxf(depth, 1.0), 0.0, 1.0)
			cols.append(Color(0.47, 0.37, 0.26).lerp(Color(0.43, 0.25, 0.17), k * 0.8))
	var idx := PackedInt32Array()
	var nb := rows_b.size()
	for i in rows_a.size() - 1:
		for j in nb - 1:
			var v0 := i * nb + j
			var v1 := v0 + 1
			var v2 := v0 + nb
			var v3 := v2 + 1
			idx.append_array([v0, v2, v1, v1, v2, v3])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_normals()
	var mesh := st.commit()
	var body := StaticBody3D.new()
	body.name = "Gorge"
	body.collision_layer = Layers.WORLD
	body.set_meta(&"surface", &"dirt")
	var mi := MeshInstance3D.new()
	mi.name = "GorgeGround"
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mi.material_override = mat
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var tri := mesh.create_trimesh_shape()
	tri.backface_collision = true
	cs.shape = tri
	body.add_child(cs)
	if not river.is_empty():
		body.add_child(_river(rows_b))
	return body


## The river: a strip of water along the gorge's axis (following its wander), `depth` over the floor.
func _river(rows_b: Array[float]) -> MeshInstance3D:
	var hw := float(river.get("half_width", 8.0))
	var y := -depth + float(river.get("depth", 0.8))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rows_b.size() - 1:
		var q := []
		for bv: float in [rows_b[i], rows_b[i + 1]]:
			var a0 := meander * sin(bv / 70.0)
			for side in [-1.0, 1.0]:
				var p: Vector3 = origin + dir_a * (a0 + float(side) * hw) + dir_b * bv
				q.append(Vector3(p.x, y, p.z))
		st.add_vertex(q[0]); st.add_vertex(q[2]); st.add_vertex(q[1])
		st.add_vertex(q[1]); st.add_vertex(q[2]); st.add_vertex(q[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "River"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.30, 0.28)
	mat.roughness = 0.15
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi
