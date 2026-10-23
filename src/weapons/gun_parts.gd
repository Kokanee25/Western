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
## change them), or a texture factory painting's own (`density`: PixelArt.factory_density). The
## guns' metals and wood use it; people's bodies make their own (`material`).
static func grid(key: String, tex: Texture2D, metallic := 0.0, roughness := 0.8, density := 0.0) -> ShaderMaterial:
	key = "grid:" + key
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = PixelArt.GRID_SHADER
		m.set_shader_parameter(&"albedo_tex", tex)
		m.set_shader_parameter(&"tint", Color.WHITE)
		m.set_shader_parameter(&"mapping", PixelArt.Mapping.TRIPLANAR)
		m.set_shader_parameter(&"texels_per_meter", density if density > 0.0 else HELD_TEXELS_PER_METER)
		m.set_shader_parameter(&"use_mipmaps", true)
		m.set_shader_parameter(&"metallic", metallic)
		m.set_shader_parameter(&"roughness", roughness)
		m.set_shader_parameter(&"specular", 0.5)
		_mats[key] = m
	return _mats[key]


## Worn blued steel, case-hardened colours, brass and walnut: the texture factory's paintings in
## the men's hand (`gun_blued`, `gun_case`, `prop_brass`, `walnut`: issue #274, Sean's #249) at
## their own density; without them, code squares as before.
static func blued() -> ShaderMaterial:
	return _painted("blued", "gun_blued", PixelArt.squares("held_blued", Color(0.34, 0.36, 0.4), 71, 0.4), 0.55, 0.32)


static func case_hardened() -> ShaderMaterial:
	return _painted("case", "gun_case", PixelArt.squares("held_case", Color(0.46, 0.44, 0.42), 73, 0.45), 0.55, 0.38)


static func brass() -> ShaderMaterial:
	return _painted("brass", "prop_brass", PixelArt.metal("brass", Color(0.72, 0.56, 0.27), 75), 0.85, 0.35)


static func walnut() -> ShaderMaterial:
	return _painted("walnut", "walnut", PixelArt.wood("walnut", Color(0.3, 0.17, 0.09), 77, 1, 0, 1.3), 0.0, 0.55)


## A factory painting (`factory_key`) where there is one, at its own texels a metre; `fallback`
## (code-painted, at what's in your hands' density) where there isn't.
static func _painted(key: String, factory_key: String, fallback: Texture2D, metallic: float, roughness: float) -> ShaderMaterial:
	var tex := PixelArt.factory(factory_key)
	var m := grid(key, fallback, metallic, roughness) if tex == null else grid(key, tex, metallic, roughness, PixelArt.factory_density(factory_key))
	_kinds[m] = StringName(key)
	return m


## What a gun part is made of, by its material ("blued", "case", "brass", "walnut"; "" for the
## rest: bores, primers): the side painting's flat colours and whether it takes the painting.
static var _kinds := {}


static func kind_of(mat: Material) -> StringName:
	return _kinds.get(mat, &"")


static func lead() -> ShaderMaterial:
	return grid("lead", PixelArt.metal("lead", Color(0.45, 0.45, 0.47), 79), 0.4, 0.6)


## Your hand's skin, on the grid: your body's (PlayerBody.SKIN), its squares quieter than a
## board's (skin seen close is smooth; the men's is painted smooth).
static func skin() -> ShaderMaterial:
	return grid("skin", PixelArt.squares("held_skin", PlayerBody.SKIN.lightened(0.08), 81, 0.12), 0.0, 0.7)


## Cloth for people's bodies (HumanBody reads these: StandardMaterial3D).
static func cloth(key: String, color: Color) -> StandardMaterial3D:
	return material("cloth:" + key, PixelArt.skin("cloth:" + key, color, 83), 0.0, 0.95)


## Your sleeve and cuff, on the grid like the gun in your hand.
static func held_cloth(key: String, color: Color) -> ShaderMaterial:
	return grid("cloth:" + key, PixelArt.squares("held_cloth:" + key, color, 83, 0.35), 0.0, 0.95)


static func box(parent: Node3D, n: String, size: Vector3, pos: Vector3, mat: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := _add(parent, n, mesh, pos, rot_deg, mat)
	mi.set_meta(&"shape", {"type": "box", "size": [size.x, size.y, size.z]})
	return mi


## A cylinder along the part's local Z axis (barrels, the cylinder, cartridges).
static func tube(parent: Node3D, n: String, radius: float, length: float, pos: Vector3, mat: Material, sides := 12, rot_deg := Vector3(90, 0, 0)) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = sides
	mesh.rings = 1
	var mi := _add(parent, n, mesh, pos, rot_deg, mat)
	mi.set_meta(&"shape", {"type": "tube", "radius": radius, "length": length, "sides": sides})
	return mi


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


# --- Shapes for the guns (the gun lab's remake, docs/briefs/gun-remake.md) ----------------------

## An outline (the part's (z, y), any winding) extruded across the part from x = -half_width to
## +half_width, its edges bevelled `bevel` deep: a frame, a hammer, a grip panel, a stock in profile.
static func profile(parent: Node3D, n: String, outline: PackedVector2Array, half_width: float, mat: Material,
		pos := Vector3.ZERO, rot_deg := Vector3.ZERO, bevel := 0.0012) -> MeshInstance3D:
	var mi := _add(parent, n, extrude(outline, half_width, bevel), pos, rot_deg, mat)
	# Its shape, for measuring how close a hand comes to it (the gun lab) and for Blender's rebuild.
	mi.set_meta(&"outline", outline)
	mi.set_meta(&"half_width", half_width)
	var pts := []
	for p in outline:
		pts.append([p.x, p.y])
	mi.set_meta(&"shape", {"type": "profile", "outline": pts, "half_width": half_width, "bevel": bevel})
	return mi


## A point's signed distance (m) to a `profile` part's surface, in the part's own space; negative
## inside.
static func profile_distance(mi: MeshInstance3D, p: Vector3) -> float:
	var poly: PackedVector2Array = mi.get_meta(&"outline")
	var q := Vector2(p.z, p.y)
	var d := INF
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		d = minf(d, q.distance_to(Geometry2D.get_closest_point_to_segment(q, a, b)))
	if Geometry2D.is_point_in_polygon(q, poly):
		d = -d
	var e := Vector2(d, absf(p.x) - float(mi.get_meta(&"half_width")))
	return e.max(Vector2.ZERO).length() + minf(maxf(e.x, e.y), 0.0)


## A band `thickness` wide along a line of (z, y) points, extruded like `profile`: a trigger guard,
## a backstrap.
static func stroke(parent: Node3D, n: String, points: PackedVector2Array, thickness: float, half_width: float,
		mat: Material, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in points.size():
		var a := points[maxi(i - 1, 0)]
		var b := points[mini(i + 1, points.size() - 1)]
		var t := (b - a).normalized()
		var nrm := Vector2(-t.y, t.x) * thickness * 0.5
		left.append(points[i] + nrm)
		right.append(points[i] - nrm)
	right.reverse()
	return profile(parent, n, left + right, half_width, mat, pos, rot_deg, minf(0.0008, half_width * 0.3))


## A profile of (radius, z) points turned round the part's Z axis: a barrel, a cylinder, a bead. A
## point at radius 0 closes that end.
static func turned(parent: Node3D, n: String, prof: PackedVector2Array, mat: Material, sides := 16,
		pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in prof.size() - 1:
		var a := prof[i]
		var b := prof[i + 1]
		var d := b - a
		# The surface's normal in (radius, z): the profile's tangent turned outwards.
		var nr := Vector2(d.y, -d.x).normalized()
		if nr.x < 0.0:
			nr = -nr
		for k in sides:
			var t0 := TAU * k / sides
			var t1 := TAU * (k + 1) / sides
			var c0 := Vector2(cos(t0), sin(t0))
			var c1 := Vector2(cos(t1), sin(t1))
			var p00 := Vector3(c0.x * a.x, c0.y * a.x, a.y)
			var p01 := Vector3(c1.x * a.x, c1.y * a.x, a.y)
			var p10 := Vector3(c0.x * b.x, c0.y * b.x, b.y)
			var p11 := Vector3(c1.x * b.x, c1.y * b.x, b.y)
			var n0 := Vector3(c0.x * nr.x, c0.y * nr.x, nr.y)
			var n1 := Vector3(c1.x * nr.x, c1.y * nr.x, nr.y)
			_tri(st, [p00, p10, p11], [n0, n0, n1])
			_tri(st, [p00, p11, p01], [n0, n1, n1])
	var mi := _add(parent, n, st.commit(), pos, rot_deg, mat)
	var pts := []
	for p in prof:
		pts.append([p.x, p.y])
	mi.set_meta(&"shape", {"type": "turned", "profile": pts, "sides": sides})
	return mi


## The extruded mesh `profile` uses (cached by its outline).
static var _extrusions := {}


static func extrude(outline: PackedVector2Array, hw: float, bevel: float) -> ArrayMesh:
	var key := "%s|%f|%f" % [outline, hw, bevel]
	if _extrusions.has(key):
		return _extrusions[key]
	var poly := outline.duplicate()
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	bevel = minf(bevel, hw * 0.45)
	var n := poly.size()
	# Each corner's inward offset (a mitre, capped) and its outward normal in (z, y).
	var inner := PackedVector2Array()
	var normals := PackedVector2Array()
	for i in n:
		var p := poly[i]
		var e0 := (p - poly[(i - 1 + n) % n]).normalized()
		var e1 := (poly[(i + 1) % n] - p).normalized()
		var n0 := Vector2(e0.y, -e0.x)
		var n1 := Vector2(e1.y, -e1.x)
		var nm := (n0 + n1).normalized()
		if nm == Vector2.ZERO:
			nm = n0
		normals.append(nm)
		inner.append(p - nm * bevel / maxf(nm.dot(n1), 0.4))
	var tris := Geometry2D.triangulate_polygon(inner)
	if tris.is_empty():
		tris = Geometry2D.triangulate_polygon(poly)
		inner = poly
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xo := hw - bevel
	for side in [1.0, -1.0]:
		var cap_n := Vector3(side, 0, 0)
		for t in range(0, tris.size(), 3):
			var a := inner[tris[t]]
			var b := inner[tris[t + 1]]
			var c := inner[tris[t + 2]]
			var pts := [Vector3(side * hw, a.y, a.x), Vector3(side * hw, b.y, b.x), Vector3(side * hw, c.y, c.x)]
			if side < 0.0:
				pts.reverse()
			_tri(st, pts, [cap_n, cap_n, cap_n])
	for i in n:
		var j := (i + 1) % n
		var pi := poly[i]
		var pj := poly[j]
		var ni := Vector3(0, normals[i].y, normals[i].x)
		var nj := Vector3(0, normals[j].y, normals[j].x)
		# The wall between the two bevels, then each bevel from the wall to its cap.
		var w := [Vector3(xo, pi.y, pi.x), Vector3(xo, pj.y, pj.x), Vector3(-xo, pj.y, pj.x), Vector3(-xo, pi.y, pi.x)]
		_quad(st, w, [ni, nj, nj, ni])
		for side in [1.0, -1.0]:
			var ii := inner[i]
			var ij := inner[j]
			var bn_i := (ni + Vector3(side, 0, 0)).normalized()
			var bn_j := (nj + Vector3(side, 0, 0)).normalized()
			var q := [Vector3(side * xo, pi.y, pi.x), Vector3(side * hw, ii.y, ii.x), Vector3(side * hw, ij.y, ij.x), Vector3(side * xo, pj.y, pj.x)]
			if side < 0.0:
				q = [q[3], q[2], q[1], q[0]]
				_quad(st, q, [bn_j, bn_j, bn_i, bn_i])
			else:
				_quad(st, q, [bn_i, bn_i, bn_j, bn_j])
	var mesh := st.commit()
	_extrusions[key] = mesh
	return mesh


static func _tri(st: SurfaceTool, p: Array, nrm: Array) -> void:
	# Godot draws a triangle's front where its corners run clockwise: put them so against its normal.
	var face := ((p[1] as Vector3) - (p[0] as Vector3)).cross((p[2] as Vector3) - (p[0] as Vector3))
	var order := [0, 1, 2] if face.dot((nrm[0] as Vector3) + (nrm[1] as Vector3) + (nrm[2] as Vector3)) < 0.0 else [0, 2, 1]
	for k in order:
		st.set_normal(nrm[k])
		st.add_vertex(p[k])


static func _quad(st: SurfaceTool, p: Array, nrm: Array) -> void:
	_tri(st, [p[0], p[1], p[2]], [nrm[0], nrm[1], nrm[2]])
	_tri(st, [p[0], p[2], p[3]], [nrm[0], nrm[2], nrm[3]])


## The side painting of a gun laid on every part that takes it (`kind_of` its material, and not
## marked "own_paint"): each vertex's UV is where it sits in the painting, seen from the gun's right
## (u along -Z, from `rect`'s z_max; v down from its y_max), at the parts' rest, so a moving part
## carries its own paint. rect: (z_min, y_min, z_max - z_min, y_max - y_min) in the gun's space.
static func project_side(root: Node3D, tex: Texture2D, rect: Rect2, metallic := 0.15, roughness := 0.7) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.metallic = metallic
	m.roughness = roughness
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if kind_of(mi.material_override) == &"" or mi.has_meta(&"own_paint") or mi.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var node: Node = mi
		while node != root and node != null:
			xf = (node as Node3D).transform * xf
			node = node.get_parent()
		var arrays: Array = (mi.mesh as PrimitiveMesh).get_mesh_arrays() if mi.mesh is PrimitiveMesh else mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv := PackedVector2Array()
		uv.resize(verts.size())
		for i in verts.size():
			var p := xf * verts[i]
			uv[i] = Vector2((rect.end.x - p.z) / rect.size.x, (rect.end.y - p.y) / rect.size.y)
		arrays[Mesh.ARRAY_TEX_UV] = uv
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mi.mesh = am
		mi.material_override = m


## Off, a gun is built bare (its factory materials), as the gun lab's side render and export want.
static var paint_guns := true


## A gun's side painting and its rect (assets/textures/guns/<gun>.png and .json, from the gun lab's
## side render and the texture factory), laid on `root`; false where there's none yet.
static func paint_gun(root: Node3D, gun: String) -> bool:
	if not paint_guns:
		return false
	var png := "res://assets/textures/guns/%s.png" % gun
	var info := "res://assets/textures/guns/%s.json" % gun
	if not ResourceLoader.exists(png) or not FileAccess.file_exists(info):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(info))
	if not d is Dictionary or not (d as Dictionary).has("rect"):
		return false
	var r: Array = d.rect
	project_side(root, load(png) as Texture2D, Rect2(r[0], r[1], r[2], r[3]))
	return true
