class_name GunParts
## Small helpers for building models from primitives in code: parts with pixel-art materials
## mapped at a fine texel density (hand-held things are seen up close).

const TEXELS_PER_METER := 320.0
## What's in your hands on the texel grid (guns, your hand and sleeve): the street painting's
## revolver and hand are in squares ~10 screen pixels across, about 160 a metre at arm's length.
const HELD_TEXELS_PER_METER := 160.0

static var _mats := {}


static func material(key: String, tex: Texture2D, metallic := 0.0, roughness := 0.8) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		m.uv1_triplanar = true
		var t := TEXELS_PER_METER / PixelArt.SIZE
		m.uv1_scale = Vector3(t, t, t)
		m.metallic = metallic
		m.roughness = roughness
		_mats[key] = m
	return _mats[key]


## The same on the texel grid like the world (lit tile by tile), mapped by position in the part's
## own space at what's in your hands' density (HELD_TEXELS_PER_METER; not tracked: F7 doesn't
## change them). The guns' metals and wood, and your hand and sleeve, use it; people's bodies make
## their own (`material`).
static func grid(key: String, tex: Texture2D, metallic := 0.0, roughness := 0.8) -> ShaderMaterial:
	key = "grid:" + key
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = PixelArt.GRID_SHADER
		m.set_shader_parameter(&"albedo_tex", tex)
		m.set_shader_parameter(&"tint", Color.WHITE)
		m.set_shader_parameter(&"mapping", PixelArt.Mapping.TRIPLANAR)
		m.set_shader_parameter(&"texels_per_meter", HELD_TEXELS_PER_METER)
		m.set_shader_parameter(&"use_mipmaps", true)
		m.set_shader_parameter(&"metallic", metallic)
		m.set_shader_parameter(&"roughness", roughness)
		m.set_shader_parameter(&"specular", 0.5)
		_mats[key] = m
	return _mats[key]


## Worn blued steel: grey with a blue cast, bright where the light catches an edge (as the street
## painting's revolver; darker and fully metallic it read black in the evening light).
static func blued() -> ShaderMaterial:
	return grid("blued", PixelArt.squares("held_blued", Color(0.34, 0.36, 0.4), 71, 0.4), 0.55, 0.32)


static func case_hardened() -> ShaderMaterial:
	return grid("case", PixelArt.squares("held_case", Color(0.46, 0.44, 0.42), 73, 0.45), 0.55, 0.38)


static func brass() -> ShaderMaterial:
	return grid("brass", PixelArt.metal("brass", Color(0.72, 0.56, 0.27), 75), 0.85, 0.35)


static func walnut() -> ShaderMaterial:
	return grid("walnut", PixelArt.wood("walnut", Color(0.3, 0.17, 0.09), 77, 1, 0, 1.3), 0.0, 0.55)


static func lead() -> ShaderMaterial:
	return grid("lead", PixelArt.metal("lead", Color(0.45, 0.45, 0.47), 79), 0.4, 0.6)


## Your hand's skin, sun-browned and warm, on the grid.
static func skin() -> ShaderMaterial:
	return grid("skin", PixelArt.squares("held_skin", Color(0.8, 0.56, 0.4), 81, 0.28), 0.0, 0.7)


## Cloth for people's bodies (HumanBody reads these: StandardMaterial3D).
static func cloth(key: String, color: Color) -> StandardMaterial3D:
	return material("cloth:" + key, PixelArt.skin("cloth:" + key, color, 83), 0.0, 0.95)


## Your sleeve and cuff, on the grid like the gun in your hand.
static func held_cloth(key: String, color: Color) -> ShaderMaterial:
	return grid("cloth:" + key, PixelArt.squares("held_cloth:" + key, color, 83, 0.35), 0.0, 0.95)


static func box(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, n, mesh, pos, rot_deg, mat)


## A cylinder along the part's local Z axis (barrels, the cylinder, cartridges).
static func tube(parent: Node3D, n: String, radius: float, length: float, pos: Vector3, mat: Material, sides := 12, rot_deg := Vector3(90, 0, 0)) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = sides
	mesh.rings = 1
	return _add(parent, n, mesh, pos, rot_deg, mat)


static func pivot(parent: Node3D, n: String, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = n
	p.position = pos
	parent.add_child(p)
	return p


static func _add(parent: Node3D, n: String, mesh: Mesh, pos: Vector3, rot_deg: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


## A flat part cut from its side profile, as a gunsmith draws it: `outline` is (forward, up) in
## metres (forward runs down -Z), extruded `half_width` either side of x = `at_x`, its edges
## bevelled by `bevel` so they catch the light. The outline is one simple polygon (it may be
## concave); keep `bevel` well under its narrowest part.
static func slab(parent: Node3D, n: String, outline: PackedVector2Array, half_width: float, mat: Material, bevel := 0.0012, at_x := 0.0, pos := Vector3.ZERO) -> MeshInstance3D:
	var pts := outline
	var count := pts.size()
	var area := 0.0
	for i in count:
		area += pts[i].x * pts[(i + 1) % count].y - pts[(i + 1) % count].x * pts[i].y
	var turn := 1.0 if area > 0.0 else -1.0
	# Each corner's outward direction (the mean of its two edges' outward normals) and the outline
	# pulled in by the bevel along it.
	var inset := PackedVector2Array()
	var outward: Array[Vector2] = []
	for i in count:
		var a := pts[(i - 1 + count) % count]
		var b := pts[i]
		var c := pts[(i + 1) % count]
		var n0 := Vector2((b - a).y, -(b - a).x).normalized() * turn
		var n1 := Vector2((c - b).y, -(c - b).x).normalized() * turn
		var nv := (n0 + n1).normalized()
		if nv == Vector2.ZERO:
			nv = n0
		outward.append(nv)
		inset.append(b - nv * bevel / maxf(nv.dot(n0), 0.5))
	var hw := half_width
	var bv := minf(bevel, hw * 0.45)
	var rings := [
		[inset, at_x + hw], [pts, at_x + hw - bv], [pts, at_x - hw + bv], [inset, at_x - hw]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var p3 := func(p: Vector2, x: float) -> Vector3: return Vector3(x, p.y, -p.x)
	for r in 3:
		var ra: PackedVector2Array = rings[r][0]
		var rb: PackedVector2Array = rings[r + 1][0]
		for i in count:
			var j := (i + 1) % count
			var mid := (outward[i] + outward[j]).normalized()
			var hint := Vector3(0.0, mid.y, -mid.x)
			if r == 0:
				hint = (hint + Vector3.RIGHT).normalized()
			elif r == 2:
				hint = (hint + Vector3.LEFT).normalized()
			_quad(st, p3.call(ra[i], rings[r][1]), p3.call(ra[j], rings[r][1]), p3.call(rb[j], rings[r + 1][1]), p3.call(rb[i], rings[r + 1][1]), hint)
	var tri := Geometry2D.triangulate_polygon(inset)
	for side in [1.0, -1.0]:
		var x: float = at_x + hw * side
		for t in range(0, tri.size(), 3):
			_tri(st, p3.call(inset[tri[t]], x), p3.call(inset[tri[t + 1]], x), p3.call(inset[tri[t + 2]], x), Vector3.RIGHT * side)
	var mi := _add(parent, n, st.commit(), pos, Vector3.ZERO, mat)
	return mi


## A round bar swept along `path` (points in the part's space), its cross-section an ellipse of
## `rx` across (as near to x as the path allows) and `ry` the other way, `sides` round. Ends
## capped. For the trigger guard's bow, straps, fingers.
static func sweep(parent: Node3D, n: String, path: PackedVector3Array, rx: float, ry: float, mat: Material, sides := 8, taper := 1.0) -> MeshInstance3D:
	var rings := []
	var side := Vector3.RIGHT
	for i in path.size():
		var t := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		# Parallel transport: keep the cross-section's x as near the last as the bend allows.
		side = (side - t * side.dot(t))
		if side.length_squared() < 1e-8:
			side = t.cross(Vector3.UP)
		side = side.normalized()
		var up := t.cross(side).normalized()
		var k := float(i) / maxf(path.size() - 1, 1)
		var s := lerpf(1.0, taper, k)
		var ring := PackedVector3Array()
		for j in sides:
			var a := TAU * j / sides
			ring.append(path[i] + side * cos(a) * rx * s + up * sin(a) * ry * s)
		rings.append(ring)
	return _add(parent, n, loft_mesh(rings, true), Vector3.ZERO, Vector3.ZERO, mat)


## A skin through rings of points in the part's space (each ring the same count, round the same
## way), on a part.
static func lofted(parent: Node3D, n: String, rings: Array, mat: Material, pos := Vector3.ZERO, closed := true) -> MeshInstance3D:
	return _add(parent, n, loft_mesh(rings, closed), pos, Vector3.ZERO, mat)


## The skin itself: a quad between neighbouring rings, flat-shaded (the facets are the form), the
## ends capped with a fan when `closed`. Normals point out from each ring's middle.
static func loft_mesh(rings: Array, closed := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = (rings[0] as PackedVector3Array).size()
	var centres: Array[Vector3] = []
	for ring: PackedVector3Array in rings:
		var c := Vector3.ZERO
		for v in ring:
			c += v
		centres.append(c / n)
	for i in rings.size() - 1:
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		var mid := (centres[i] + centres[i + 1]) * 0.5
		for k in n:
			var k1 := (k + 1) % n
			var hint := (a[k] + a[k1] + b[k] + b[k1]) * 0.25 - mid
			_quad(st, a[k], a[k1], b[k1], b[k], hint)
	if closed:
		for end in [0, rings.size() - 1]:
			var ring: PackedVector3Array = rings[end]
			var hint := centres[end] - centres[1 if end == 0 else end - 1]
			for k in n:
				_tri(st, centres[end], ring[k], ring[(k + 1) % n], hint)
	return st.commit()


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, hint: Vector3) -> void:
	_tri(st, a, b, c, hint)
	_tri(st, a, c, d, hint)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, hint: Vector3) -> void:
	var face := (b - a).cross(c - a)
	if face.length_squared() < 1e-16:
		return
	# Godot's front faces wind clockwise as seen: the right-hand normal points away.
	var verts := [a, b, c]
	if face.dot(hint) > 0.0:
		verts = [a, c, b]
		face = -face
	var nrm := -face.normalized()
	for v in verts:
		st.set_normal(nrm)
		st.set_uv(Vector2(v.x - v.z, v.y))
		st.add_vertex(v)
