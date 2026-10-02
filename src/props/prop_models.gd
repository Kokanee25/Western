class_name PropModels
## Low-poly models of the props in assets/props/manifest.json, built in code (DESIGN.md §4: solid,
## readable low-poly models with pixel-art textures). Every surface is on the texel grid
## (PixelArt.material(): lit tile by tile, the world's texel size), with the texture factory's
## materials where it has one (dark_trim, floor...). PropLibrary uses these when there's no .glb for
## a prop; they're built at the manifest's real size, origin at the bottom centre (floor props) or
## with the back on z = 0 facing +Z (wall props). Glass that has to be seen through (a lamp's
## chimney) is the one thing off the grid.

const BRASS := Color(0.72, 0.55, 0.26)
const TIN := Color(0.6, 0.58, 0.53)
const IRON := Color(0.2, 0.19, 0.18)
const FELT := Color(0.16, 0.3, 0.2)
const BOTTLE_GLASS := [Color(0.2, 0.12, 0.05), Color(0.12, 0.17, 0.08), Color(0.26, 0.15, 0.06)]

static var _materials := {}
static var _meshes := {}


## The model for a prop, or null if there's no builder for it.
static func build(id: StringName, variant := 0) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	match id:
		&"card_table": _card_table(root)
		&"chair": _chair(root)
		&"bar_stool": _bar_stool(root)
		&"upright_piano": _piano(root)
		&"barrel": _barrel(root)
		&"spittoon": _spittoon(root)
		&"oil_lamp": lamp(root)
		&"whiskey_bottle": bottle(root, variant)
		&"tin_cup": cup(root)
		&"deer_head": _deer_head(root)
		&"framed_painting": _painting(root, variant)
		&"wall_sconce": _sconce(root)
		_:
			root.free()
			return null
	return root


static func has_model(id: StringName) -> bool:
	return id in [&"card_table", &"chair", &"bar_stool", &"upright_piano", &"barrel", &"spittoon",
			&"oil_lamp", &"whiskey_bottle", &"tin_cup", &"deer_head", &"framed_painting", &"wall_sconce"]


# --- materials ---------------------------------------------------------------------------------

static func _mat(key: String, tex: Texture2D, tint := Color.WHITE, rough := 0.9, metal := 0.0, spec := 0.3) -> ShaderMaterial:
	if not _materials.has(key):
		var m := PixelArt.material(tex, tint, PixelArt.Mapping.UV, Vector3.ZERO, rough, metal, spec)
		m.resource_name = key
		_materials[key] = m
	return _materials[key]


## Dark oiled wood (the bar's: the texture factory's dark_trim where there is one).
static func dark_wood() -> ShaderMaterial:
	return _mat("dark_wood", PixelArt.wood("dark_trim", Color(0.26, 0.19, 0.14), 47, 0, 1, 0.8))


static func mid_wood() -> ShaderMaterial:
	return _mat("mid_wood", PixelArt.wood("prop_wood", Color(0.38, 0.25, 0.15), 211, 1, 2, 0.9))


static func staves() -> ShaderMaterial:
	return _mat("staves", PixelArt.wood("prop_staves", Color(0.42, 0.28, 0.16), 213, 1, 3, 1.1))


static func brass() -> ShaderMaterial:
	return _mat("brass", PixelArt.metal("prop_brass", BRASS, 215), Color.WHITE, 0.45, 0.5, 0.6)


static func tin() -> ShaderMaterial:
	# Dull tin, lit mostly as paint (fully metallic it has nothing to reflect and goes black).
	return _mat("tin", PixelArt.metal("shot_tin", TIN, 71, 0.5), Color.WHITE, 0.5, 0.25, 0.5)


static func iron() -> ShaderMaterial:
	return _mat("iron", PixelArt.metal("prop_iron", IRON, 217, 0.6), Color.WHITE, 0.7, 0.5)


static func felt() -> ShaderMaterial:
	return _mat("felt", PixelArt.dirt("prop_felt", FELT, 219), Color.WHITE, 1.0, 0.0, 0.1)


static func bottle_glass(variant: int) -> ShaderMaterial:
	var c: Color = BOTTLE_GLASS[posmod(variant, BOTTLE_GLASS.size())]
	return _mat("glass%d" % posmod(variant, BOTTLE_GLASS.size()), PixelArt.metal("prop_glass", Color(0.5, 0.5, 0.5), 221, 0.0),
			c * 2.0, 0.12, 0.0, 0.9)


## A lamp's glass chimney (src/props/chimney_glass.gdshader): glowing amber from the flame when its
## lamp is lit (the instance parameter `glow`, set by OilLamp), faint clear glass when it isn't.
static func chimney_glass() -> ShaderMaterial:
	if not _materials.has("chimney"):
		var m := ShaderMaterial.new()
		m.shader = preload("res://src/props/chimney_glass.gdshader")
		_materials["chimney"] = m
	return _materials["chimney"]


## The lamp's dark old brass (the painting's lamp foot is near-black bronze with lit edges).
static func lamp_brass() -> ShaderMaterial:
	return _mat("lamp_brass", PixelArt.metal("prop_brass", BRASS, 215), Color(0.36, 0.3, 0.24), 0.5, 0.5, 0.6)


## Pewter: a dark grey mug, its texels mottled, catching the lamp at its rim.
static func pewter() -> ShaderMaterial:
	return _mat("pewter", PixelArt.metal("prop_pewter", Color(0.62, 0.6, 0.56), 239, 0.8), Color.WHITE, 0.4, 0.3, 0.7)


# --- meshes ------------------------------------------------------------------------------------

## A surface of revolution round Y through `profile` (radius, height) points from bottom to top,
## UVs in metres (u round the outside, v up the profile; `grain_up` swaps them so wood grain runs
## up, like barrel staves). Faces outward; `inside` makes it face inward (a cup's inner wall).
static func lathe(profile: PackedVector2Array, segments: int, grain_up := false, inside := false) -> ArrayMesh:
	var key := "%s:%d:%s:%s" % [profile, segments, grain_up, inside]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := [0.0]
	for i in range(1, profile.size()):
		along.append(along[i - 1] + profile[i].distance_to(profile[i - 1]))
	var r_mean := 0.0
	for p in profile:
		r_mean += p.x
	r_mean /= profile.size()
	for i in profile.size() - 1:
		var a := profile[i]
		var b := profile[i + 1]
		# Outward normal of this band in the (r, y) plane.
		var d := b - a
		var n2 := Vector2(d.y, -d.x).normalized() * (-1.0 if inside else 1.0)
		for s in segments:
			var t0 := TAU * s / segments
			var t1 := TAU * (s + 1) / segments
			var quad := [[a, t0, along[i]], [a, t1, along[i]], [b, t1, along[i + 1]], [b, t0, along[i + 1]]]
			var verts: Array[Vector3] = []
			var norms: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for q in quad:
				var p: Vector2 = q[0]
				var t: float = q[1]
				verts.append(Vector3(cos(t) * p.x, p.y, sin(t) * p.x))
				var tm := (t0 + t1) * 0.5
				norms.append(Vector3(cos(t) * n2.x, n2.y, sin(t) * n2.x).normalized())
				var around := t * r_mean
				uvs.append(Vector2(q[2], around) if grain_up else Vector2(around, q[2]))
			var order := [0, 1, 2, 0, 2, 3]
			# Godot's front faces wind clockwise as seen: the right-hand normal points away.
			var face := (verts[1] - verts[0]).cross(verts[2] - verts[0])
			if face.length_squared() < 1e-14:
				face = (verts[2] - verts[0]).cross(verts[3] - verts[0])
			var outward := norms[0] + norms[2]
			if face.dot(outward) > 0.0:
				order = [0, 2, 1, 0, 3, 2]
			for k in order:
				st.set_normal(norms[k])
				st.set_uv(uvs[k])
				st.add_vertex(verts[k])
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## A flat disc (a lid, a table top, a cup's bottom) facing up (or down), UVs in metres.
static func disc(radius: float, segments: int, y: float, up := true) -> ArrayMesh:
	var key := "disc:%f:%d:%f:%s" % [radius, segments, y, up]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := Vector3.UP if up else Vector3.DOWN
	for s in segments:
		var t0 := TAU * s / segments
		var t1 := TAU * (s + 1) / segments
		var v0 := Vector3(0, y, 0)
		var v1 := Vector3(cos(t0) * radius, y, sin(t0) * radius)
		var v2 := Vector3(cos(t1) * radius, y, sin(t1) * radius)
		# Godot's front faces wind clockwise as seen: the right-hand normal points away from n.
		if (v1 - v0).cross(v2 - v0).dot(n) > 0.0:
			var tmp := v1
			v1 = v2
			v2 = tmp
		for v: Vector3 in [v0, v1, v2]:
			st.set_normal(n)
			st.set_uv(Vector2(v.x + radius, v.z + radius))
			st.add_vertex(v)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## A skin lofted through rings of points (each the same count, in order round the same way): a
## quad between neighbours, flat-shaded (low-poly: the facets are the form). UVs in metres: u
## along the loft, v round it. `closed_ends` caps the first and last ring with a fan.
static func loft(rings: Array, closed_ends := true) -> ArrayMesh:
	var key := "loft:%s:%s" % [rings, closed_ends]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = (rings[0] as PackedVector3Array).size()
	var along := 0.0
	var centres: Array[Vector3] = []
	for ring: PackedVector3Array in rings:
		var c := Vector3.ZERO
		for v in ring:
			c += v
		centres.append(c / n)
	var tris: Array = []
	for i in rings.size() - 1:
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		var step := centres[i].distance_to(centres[i + 1])
		var around_a := 0.0
		var around_b := 0.0
		for k in n:
			var k1 := (k + 1) % n
			var da := a[k].distance_to(a[k1])
			var db := b[k].distance_to(b[k1])
			var quad := [[a[k], Vector2(along, around_a)], [a[k1], Vector2(along, around_a + da)],
					[b[k1], Vector2(along + step, around_b + db)], [b[k], Vector2(along + step, around_b)]]
			var outward: Vector3 = (a[k] + a[k1] + b[k] + b[k1]) * 0.25 - (centres[i] + centres[i + 1]) * 0.5
			tris.append([quad[0], quad[1], quad[2], outward])
			tris.append([quad[0], quad[2], quad[3], outward])
			around_a += da
			around_b += db
		along += step
	if closed_ends:
		for end in [0, rings.size() - 1]:
			var ring: PackedVector3Array = rings[end]
			var c := centres[end]
			var outward := c - centres[1 if end == 0 else end - 1]
			for k in n:
				tris.append([[c, Vector2(0, 0)], [ring[k], Vector2(0, 0.1)], [ring[(k + 1) % n], Vector2(0.1, 0.1)], outward])
	for t in tris:
		var v0: Vector3 = t[0][0]
		var v1: Vector3 = t[1][0]
		var v2: Vector3 = t[2][0]
		var face := (v1 - v0).cross(v2 - v0)
		if face.length_squared() < 1e-14:
			continue
		var order := [0, 1, 2]
		# Godot's front faces wind clockwise as seen: the right-hand normal points away.
		if face.dot(t[3]) > 0.0:
			order = [0, 2, 1]
			face = -face
		var nrm := face.normalized()
		for k in order:
			st.set_normal(nrm)
			st.set_uv(t[k][1])
			st.add_vertex(t[k][0])
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## An ellipse of `segments` points round `centre`, half-widths `rz` (across, z) and `ry` (up),
## in the plane across x (a body's cross-section), tilted `lean` radians about z.
static func _ring(centre: Vector3, rz: float, ry: float, segments := 12, lean := 0.0) -> PackedVector3Array:
	var out := PackedVector3Array()
	var b := Basis(Vector3.BACK, lean)
	for k in segments:
		var t := TAU * k / segments
		out.append(centre + b * Vector3(0.0, sin(t) * ry, cos(t) * rz))
	return out


## A limb segment: a tapered round bar from `a` (radius r0) to `b` (radius r1).
static func _limb(parent: Node3D, name: String, a: Vector3, b: Vector3, r0: float, r1: float, mat: Material, segments := 8) -> MeshInstance3D:
	var d := b - a
	var basis := Basis.looking_at(d, Vector3.FORWARD if absf(d.normalized().y) > 0.99 else Vector3.UP)
	# The lathe runs up Y; looking_at points -Z along d: turn Y onto -Z.
	basis = basis * Basis(Vector3.RIGHT, -PI * 0.5)
	return _add(parent, name, lathe(_profile([[r0, 0.0], [r1, d.length()]]), segments), mat, Transform3D(basis, a))


static func _add(parent: Node3D, name: String, mesh: Mesh, mat: Material, xf := Transform3D.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	parent.add_child(mi)
	return mi


## A box of `size` with its centre at `at` (and turned by `basis`), UVs in metres along its length.
static func _box(parent: Node3D, name: String, size: Vector3, at: Vector3, mat: Material, basis := Basis.IDENTITY) -> MeshInstance3D:
	return _add(parent, name, MemberMesh.box(size), mat, Transform3D(basis, at))


static func _profile(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(Vector2(p[0], p[1]))
	return out


# --- the props ---------------------------------------------------------------------------------

## A round card table: green baize in a dark wooden rim, a turned pedestal and four feet.
static func _card_table(root: Node3D) -> void:
	var r := 0.6
	var h := 0.76
	_add(root, "Felt", disc(r - 0.06, 20, h), felt())
	_add(root, "Rim", lathe(_profile([[r - 0.06, h], [r - 0.06, h + 0.012], [r, h + 0.006], [r, h - 0.04], [r - 0.05, h - 0.05]]), 20), dark_wood())
	_add(root, "Under", disc(r - 0.05, 20, h - 0.05, false), dark_wood())
	_add(root, "Pedestal", lathe(_profile([[0.12, 0.08], [0.07, 0.2], [0.09, 0.32], [0.06, 0.45], [0.06, 0.6], [0.1, h - 0.05]]), 8, true), dark_wood())
	for k in 4:
		var b := Basis(Vector3.UP, k * PI * 0.5 + PI * 0.25)
		_box(root, "Foot%d" % k, Vector3(0.06, 0.07, 0.5), b * Vector3(0, 0.035, 0.22), dark_wood(), b)


## A spindle-back saloon chair facing +Z (you sit looking +Z).
static func _chair(root: Node3D) -> void:
	var w := mid_wood()
	_box(root, "Seat", Vector3(0.44, 0.035, 0.42), Vector3(0, 0.45, 0.02), w)
	for x in [-0.19, 0.19]:
		for z in [-0.17, 0.2]:
			_box(root, "Leg", Vector3(0.035, 0.45, 0.035), Vector3(x, 0.225, z), w)
		_box(root, "Upright", Vector3(0.035, 0.47, 0.035), Vector3(x, 0.69, -0.18), w)
		_box(root, "Stretcher", Vector3(0.025, 0.025, 0.36), Vector3(x, 0.15, 0.015), w)
	_box(root, "Rail", Vector3(0.44, 0.07, 0.03), Vector3(0, 0.88, -0.19), w)
	for k in 5:
		_box(root, "Spindle", Vector3(0.018, 0.33, 0.018), Vector3(-0.14 + k * 0.07, 0.64, -0.185), w)


static func _bar_stool(root: Node3D) -> void:
	var w := dark_wood()
	_add(root, "Seat", lathe(_profile([[0.17, 0.73], [0.19, 0.745], [0.19, 0.76]]), 12), w)
	_add(root, "SeatTop", disc(0.19, 12, 0.76), w)
	for k in 4:
		var a := k * PI * 0.5 + PI * 0.25
		var foot := Vector3(cos(a) * 0.17, 0.0, sin(a) * 0.17)
		var top := Vector3(cos(a) * 0.11, 0.73, sin(a) * 0.11)
		var mid := (foot + top) * 0.5
		var b := Basis.looking_at(top - foot, Vector3.FORWARD if absf((top - foot).normalized().y) > 0.99 else Vector3.UP)
		_box(root, "Leg%d" % k, Vector3(0.03, 0.03, foot.distance_to(top)), mid, w, b)
	_add(root, "FootRing", lathe(_profile([[0.155, 0.25], [0.165, 0.26], [0.155, 0.27]]), 12), brass())


## An upright piano in dark walnut against the wall behind it (its back to -Z), keys toward +Z.
static func _piano(root: Node3D) -> void:
	var w := dark_wood()
	_box(root, "Case", Vector3(1.5, 1.2, 0.4), Vector3(0, 0.62, -0.1), w)
	_box(root, "Top", Vector3(1.54, 0.04, 0.44), Vector3(0, 1.24, -0.1), w)
	_box(root, "KeyBed", Vector3(1.4, 0.08, 0.22), Vector3(0, 0.72, 0.2), w)
	_box(root, "Fallboard", Vector3(1.4, 0.16, 0.04), Vector3(0, 0.84, 0.13), w)
	_box(root, "Panel", Vector3(1.2, 0.36, 0.02), Vector3(0, 1.0, 0.105), _mat("piano_panel", PixelArt.wood("prop_burl", Color(0.33, 0.18, 0.1), 223, 3, 1, 0.6)))
	# Keys: an ivory strip with black keys in twos and threes.
	_box(root, "Keys", Vector3(1.3, 0.025, 0.15), Vector3(0, 0.77, 0.23), _mat("ivory", PixelArt.painted("prop_ivory", Color(0.86, 0.82, 0.7), Color(0.5, 0.45, 0.4), 225, 0.0), Color.WHITE, 0.5))
	var black := _mat("ebony", PixelArt.metal("prop_ebony", Color(0.07, 0.06, 0.05), 227), Color.WHITE, 0.4)
	var x := -0.62
	var pattern := [1, 1, 0, 1, 1, 1, 0]
	var i := 0
	while x < 0.62:
		if pattern[i % 7] == 1:
			_box(root, "Black", Vector3(0.012, 0.02, 0.09), Vector3(x + 0.0185, 0.79, 0.2), black)
		x += 0.0185
		i += 1
	for side in [-1.0, 1.0]:
		_box(root, "Cheek", Vector3(0.05, 0.75, 0.3), Vector3(side * 0.72, 0.4, 0.15), w)
		_box(root, "Toe", Vector3(0.06, 0.06, 0.12), Vector3(side * 0.68, 0.03, 0.32), w)
		# Brass candle sconces either side of the music desk.
		_add(root, "Candle", lathe(_profile([[0.02, 0.0], [0.02, 0.012], [0.008, 0.02], [0.008, 0.07]]), 6), brass(),
				Transform3D(Basis.IDENTITY, Vector3(side * 0.55, 1.05, 0.14)))


## An oak barrel: bulged staves, the grain running up, four iron hoops.
static func _barrel(root: Node3D) -> void:
	var pts := []
	for k in 9:
		var t := float(k) / 8.0
		pts.append([0.25 + 0.05 * sin(t * PI), 0.9 * t])
	_add(root, "Staves", lathe(_profile(pts), 14, true), staves())
	_add(root, "Head", disc(0.25, 14, 0.885), _mat("barrel_head", PixelArt.wood("prop_barrel_head", Color(0.38, 0.25, 0.14), 229, 1, 2)))
	for y in [0.06, 0.24, 0.66, 0.84]:
		var t: float = y / 0.9
		var r := 0.25 + 0.05 * sin(t * PI) + 0.004
		_add(root, "Hoop", lathe(_profile([[r, y - 0.025], [r + 0.004, y], [r, y + 0.025]]), 14), iron())


static func _spittoon(root: Node3D) -> void:
	_add(root, "Body", lathe(_profile([[0.1, 0.0], [0.14, 0.04], [0.15, 0.1], [0.12, 0.16], [0.07, 0.19], [0.1, 0.24], [0.12, 0.25]]), 12), brass())
	_add(root, "Inside", lathe(_profile([[0.06, 0.12], [0.06, 0.19], [0.1, 0.24], [0.115, 0.25]]), 12, false, true), _mat("spit", PixelArt.metal("prop_spit", Color(0.18, 0.13, 0.08), 231), Color.WHITE, 0.3))


## A kerosene table lamp, as the saloon painting has it: a low, wide foot of dark brass, a squat
## font, a burner collar with its prongs, and a tall glass chimney swelling round the flame and
## narrowing to the top (the light comes from OilLamp; its flame sits inside at 0.205 m). Shared by
## OilLamp.
static func lamp(root: Node3D) -> void:
	_add(root, "Foot", lathe(_profile([[0.072, 0.0], [0.076, 0.012], [0.07, 0.03], [0.05, 0.045], [0.042, 0.06], [0.058, 0.08], [0.062, 0.1], [0.04, 0.122], [0.026, 0.13]]), 12), lamp_brass())
	_add(root, "Collar", lathe(_profile([[0.03, 0.13], [0.034, 0.145], [0.03, 0.155]]), 10), lamp_brass())
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		_box(root, "Prong", Vector3(0.006, 0.03, 0.006), Vector3(cos(a) * 0.031, 0.168, sin(a) * 0.031), lamp_brass())
	_add(root, "Chimney", lathe(_profile([[0.03, 0.155], [0.044, 0.18], [0.05, 0.21], [0.046, 0.245], [0.032, 0.285], [0.023, 0.32], [0.022, 0.38]]), 12), chimney_glass())


## A whiskey bottle in dark glass: shoulders, a neck, a cork and a paper label with a few lines
## of print on it. `variant` picks the glass and the label.
static func bottle(root: Node3D, variant := 0) -> void:
	_add(root, "Glass", lathe(_profile([[0.03, 0.0], [0.042, 0.004], [0.044, 0.02], [0.044, 0.19], [0.038, 0.215], [0.016, 0.24], [0.013, 0.27], [0.015, 0.275], [0.014, 0.285]]), 10), bottle_glass(variant))
	_add(root, "Base", disc(0.03, 10, 0.0, false), bottle_glass(variant))
	_add(root, "Cork", lathe(_profile([[0.012, 0.28], [0.011, 0.3]]), 6), _mat("cork", PixelArt.dirt("prop_cork", Color(0.55, 0.4, 0.25), 233)))
	_add(root, "Label", lathe(_profile([[0.0455, 0.07], [0.0455, 0.15]]), 10), _mat("label%d" % posmod(variant, 3), label_texture(posmod(variant, 3)), Color.WHITE, 0.9))


## A pewter mug, as the painting's: straight sides with a band near the foot and a rolled rim
## that catches the light, a dark inside, and a loop handle.
static func cup(root: Node3D) -> void:
	_add(root, "Outside", lathe(_profile([[0.036, 0.0], [0.039, 0.004], [0.039, 0.016], [0.037, 0.02], [0.04, 0.1]]), 10), pewter())
	_add(root, "Inside", lathe(_profile([[0.033, 0.008], [0.037, 0.1]]), 10, false, true), _mat("tin_in", PixelArt.metal("prop_tin_in", Color(0.14, 0.13, 0.12), 235), Color.WHITE, 0.7, 0.1))
	_add(root, "Bottom", disc(0.034, 10, 0.008), _mat("tin_in", null))
	_add(root, "Lip", lathe(_profile([[0.037, 0.1], [0.042, 0.102], [0.041, 0.106], [0.037, 0.104]]), 10), pewter())
	# The handle: a flat strap out from under the rim, down and back in near the foot.
	_box(root, "HandleTop", Vector3(0.035, 0.008, 0.016), Vector3(0.055, 0.088, 0.0), pewter())
	_box(root, "HandleSide", Vector3(0.008, 0.06, 0.016), Vector3(0.071, 0.058, 0.0), pewter())
	_box(root, "HandleFoot", Vector3(0.03, 0.008, 0.016), Vector3(0.057, 0.028, 0.0), pewter())


## A mounted stag: a shield plaque, neck and head from tapered blocks, ears and branching antlers.
static func _deer_head(root: Node3D) -> void:
	var plaque := dark_wood()
	_box(root, "Plaque", Vector3(0.34, 0.44, 0.03), Vector3(0, 0, 0.015), plaque)
	var hide := _mat("hide", PixelArt.dirt("prop_hide", Color(0.45, 0.32, 0.2), 237))
	var dark := _mat("hide_dark", PixelArt.dirt("prop_hide_dark", Color(0.18, 0.12, 0.08), 239))
	_box(root, "Neck", Vector3(0.2, 0.26, 0.2), Vector3(0, -0.04, 0.12), hide, Basis(Vector3.RIGHT, -0.35))
	_box(root, "Head", Vector3(0.15, 0.15, 0.2), Vector3(0, 0.07, 0.28), hide, Basis(Vector3.RIGHT, 0.25))
	_box(root, "Muzzle", Vector3(0.09, 0.08, 0.14), Vector3(0, 0.01, 0.41), hide, Basis(Vector3.RIGHT, 0.45))
	_box(root, "Nose", Vector3(0.06, 0.04, 0.03), Vector3(0, -0.03, 0.48), dark)
	for side in [-1.0, 1.0]:
		_box(root, "Eye", Vector3(0.02, 0.02, 0.02), Vector3(side * 0.07, 0.1, 0.33), dark)
		_box(root, "Ear", Vector3(0.12, 0.05, 0.02), Vector3(side * 0.12, 0.17, 0.24), hide, Basis(Vector3.FORWARD, side * 0.5))
		_antler(root, Vector3(side * 0.05, 0.16, 0.25), side)


static func _antler(root: Node3D, base: Vector3, side: float) -> void:
	var bone := _mat("antler", PixelArt.painted("prop_antler", Color(0.78, 0.7, 0.55), Color(0.45, 0.36, 0.25), 241, 0.3))
	# Main beam: up, out and back, curving forward at the top, with tines off its front.
	var pts := [base, base + Vector3(side * 0.1, 0.12, -0.04), base + Vector3(side * 0.2, 0.24, -0.05),
			base + Vector3(side * 0.26, 0.36, 0.0), base + Vector3(side * 0.25, 0.46, 0.06)]
	for i in pts.size() - 1:
		_stick(root, pts[i], pts[i + 1], 0.022 - i * 0.003, bone)
		if i > 0:
			_stick(root, pts[i], pts[i] + Vector3(side * 0.02, 0.1, 0.07), 0.012, bone)
	_stick(root, pts[0], pts[0] + Vector3(side * 0.03, 0.06, 0.09), 0.014, bone)


static func _stick(root: Node3D, a: Vector3, b: Vector3, thick: float, mat: Material) -> void:
	var d := b - a
	var basis := Basis.looking_at(d, Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.FORWARD)
	_box(root, "Tine", Vector3(thick, thick, d.length()), (a + b) * 0.5, mat, basis)


## An oil landscape in a gilded frame (variant picks the picture).
static func _painting(root: Node3D, variant := 0) -> void:
	var gilt := _mat("gilt", PixelArt.metal("prop_gilt", Color(0.66, 0.5, 0.24), 243, 0.3), Color.WHITE, 0.5, 0.4, 0.5)
	var w := 1.0
	var h := 0.7
	var f := 0.08
	_box(root, "FrameTop", Vector3(w, f, 0.05), Vector3(0, h * 0.5 - f * 0.5, 0.025), gilt)
	_box(root, "FrameBottom", Vector3(w, f, 0.05), Vector3(0, -h * 0.5 + f * 0.5, 0.025), gilt)
	_box(root, "FrameLeft", Vector3(f, h - 2 * f, 0.05), Vector3(-w * 0.5 + f * 0.5, 0, 0.025), gilt)
	_box(root, "FrameRight", Vector3(f, h - 2 * f, 0.05), Vector3(w * 0.5 - f * 0.5, 0, 0.025), gilt)
	# The canvas: a thin board with UVs in metres (u across, v up), the picture laid on it once.
	var canvas_size := Vector2(w - 2 * f, h - 2 * f)
	var m := ShaderMaterial.new()
	m.shader = PixelArt.GRID_SHADER
	m.set_shader_parameter(&"albedo_tex", landscape_texture(posmod(variant, 2)))
	m.set_shader_parameter(&"tint", Color.WHITE)
	m.set_shader_parameter(&"roughness", 0.8)
	# The picture covers the canvas once (not tiled), one texel a tile all the same.
	m.set_shader_parameter(&"texels_per_meter", float(landscape_texture(0).get_width()) / canvas_size.x)
	m.set_shader_parameter(&"use_mipmaps", false)
	_box(root, "Canvas", Vector3(canvas_size.x, canvas_size.y, 0.01), Vector3(0, 0, 0.02), m)


## An oil lamp in a wall bracket: a brass back plate and arm holding a lamp with its chimney.
static func _sconce(root: Node3D) -> void:
	_box(root, "Plate", Vector3(0.08, 0.16, 0.012), Vector3(0, -0.02, 0.006), brass())
	_box(root, "Arm", Vector3(0.02, 0.02, 0.12), Vector3(0, -0.06, 0.07), brass())
	var lamp_root := Node3D.new()
	lamp_root.name = "Lamp"
	lamp_root.scale = Vector3.ONE * 0.85
	lamp_root.position = Vector3(0, -0.21, 0.13)
	root.add_child(lamp_root)
	lamp(lamp_root)
	_add(root, "Reflector", lathe(_profile([[0.07, 0.0], [0.05, 0.02], [0.0, 0.025]]), 10), brass(),
			Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, -0.02, 0.012)))


# --- painted textures --------------------------------------------------------------------------

## A bottle label: cream paper, a dark border, a few lines of print and a red seal.
static func label_texture(variant: int) -> ImageTexture:
	var key := "label_tex%d" % variant
	if _materials.has(key):
		return _materials[key]
	# Old paper gone brown in the bottle's shadow, the print dark (the painting's labels barely
	# stand out from the glass).
	var paper: Color = [Color(0.4, 0.3, 0.2), Color(0.46, 0.4, 0.3), Color(0.36, 0.27, 0.17)][variant]
	var ink: Color = [Color(0.16, 0.09, 0.05), Color(0.12, 0.1, 0.1), Color(0.32, 0.08, 0.05)][variant]
	# 0.29 m round x 0.08 m tall at the world's texels a metre (the grid lays it at that).
	var w := maxi(int(round(0.29 * PixelArt.texels_per_meter)), 6)
	var h := maxi(int(round(0.08 * PixelArt.texels_per_meter)), 3)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + variant
	for y in h:
		for x in w:
			var c := paper.darkened(rng.randf() * 0.15)
			if y == 0 or y == h - 1:
				c = ink
			elif x >= w / 3 and x <= w * 2 / 3 and rng.randf() < 0.55:
				c = ink.lerp(paper, rng.randf() * 0.3)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_materials[key] = tex
	return tex


## A small landscape for the frames: sky, mountains, a plain, done in a few strokes of colour.
static func landscape_texture(variant: int) -> ImageTexture:
	var key := "landscape_tex%d" % variant
	if _materials.has(key):
		return _materials[key]
	# 0.84 x 0.54 m of canvas at 64 a metre.
	var w := 54
	var h := 35
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 400 + variant
	var sky_top := Color(0.35, 0.42, 0.5) if variant == 0 else Color(0.55, 0.38, 0.28)
	var sky_low := Color(0.78, 0.62, 0.42)
	var ridge := []
	var y0 := h * 0.45
	for x in w:
		y0 += rng.randf_range(-1.6, 1.6)
		y0 = clampf(y0, h * 0.25, h * 0.6)
		ridge.append(y0)
	for y in h:
		for x in w:
			var c: Color
			if y < ridge[x]:
				c = sky_top.lerp(sky_low, float(y) / ridge[x])
			elif y < h * 0.68:
				c = Color(0.34, 0.3, 0.32).lerp(Color(0.42, 0.36, 0.3), (y - ridge[x]) / (h * 0.68 - ridge[x] + 0.01))
			else:
				c = Color(0.5, 0.42, 0.26).lerp(Color(0.32, 0.27, 0.16), (y - h * 0.68) / (h * 0.32))
			c = c.darkened(rng.randf() * 0.1)
			# The canvas's v runs up, the picture's rows down.
			img.set_pixel(x, h - 1 - y, c)
	var tex := ImageTexture.create_from_image(img)
	_materials[key] = tex
	return tex


# --- the street ---------------------------------------------------------------------------------

static func weathered() -> ShaderMaterial:
	return _mat("weathered", PixelArt.wood("weathered_pine", Color(0.56, 0.48, 0.39), 53, 2, 4))


static func straw() -> ShaderMaterial:
	return _mat("straw", PixelArt.dirt("prop_straw", Color(0.74, 0.6, 0.33), 245))


static func canvas() -> ShaderMaterial:
	return _mat("canvas", PixelArt.painted("prop_canvas", Color(0.82, 0.76, 0.62), Color(0.6, 0.52, 0.4), 247, 0.05))


## A packing crate, 0.6 m: boards with battens round its edges.
static func crate(root: Node3D, s := 0.6) -> void:
	var w := weathered()
	_box(root, "Body", Vector3(s - 0.02, s - 0.02, s - 0.02), Vector3(0, s * 0.5, 0), w)
	var b := 0.05
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_box(root, "Corner", Vector3(b, s, b), Vector3(x * (s - b) * 0.5, s * 0.5, z * (s - b) * 0.5), dark_wood())
	for y in [b * 0.5, s - b * 0.5]:
		for x in [-1.0, 1.0]:
			_box(root, "Batten", Vector3(b, b, s), Vector3(x * (s - b) * 0.5, y, 0), dark_wood())
			_box(root, "Batten", Vector3(s, b, b), Vector3(0, y, x * (s - b) * 0.5), dark_wood())


## A hay bale, 0.9 x 0.45 x 0.5 m, tied twice round.
static func hay_bale(root: Node3D) -> void:
	# A bulging block of straw with rounded ends: rounded-rectangle rings along x.
	var rings := []
	var profile := [[-0.45, 0.17, 0.2], [-0.42, 0.21, 0.24], [-0.3, 0.23, 0.26], [-0.1, 0.235, 0.265], [0.1, 0.235, 0.265],
			[0.3, 0.23, 0.26], [0.42, 0.21, 0.24], [0.45, 0.17, 0.2]]
	for q in profile:
		var ring := PackedVector3Array()
		for k in 12:
			var t := TAU * k / 12.0
			var c := cos(t)
			var sn := sin(t)
			# Pushed out toward the corners: a rounded square, not a cylinder.
			var r := lerpf(1.0, 1.0 / maxf(absf(c), absf(sn)), 0.75)
			ring.append(Vector3(q[0], 0.225 + sn * q[1] * r * 0.92, c * q[2] * r * 0.92))
		rings.append(ring)
	_add(root, "Hay", loft(rings), straw())
	# Two twine ties sunk into it, and loose straws poking out of the ends.
	var twine := _mat("twine", PixelArt.dirt("prop_twine", Color(0.4, 0.3, 0.18), 249))
	for x in [-0.22, 0.22]:
		# A band round the bale, a little proud of it.
		var band := []
		for dx in [-0.012, 0.012]:
			var ring := PackedVector3Array()
			for k in 12:
				var t := TAU * k / 12.0
				var c := cos(t)
				var sn := sin(t)
				var r := lerpf(1.0, 1.0 / maxf(absf(c), absf(sn)), 0.75) * 0.935
				ring.append(Vector3(x + dx, 0.225 + sn * 0.235 * r, c * 0.265 * r))
			band.append(ring)
		_add(root, "Twine", loft(band, false), twine)
	var rng := RandomNumberGenerator.new()
	rng.seed = 251
	for i in 14:
		var side := -1.0 if i % 2 == 0 else 1.0
		var at := Vector3(side * rng.randf_range(0.3, 0.46), rng.randf_range(0.05, 0.42), rng.randf_range(-0.22, 0.22))
		var d := Vector3(side * rng.randf_range(0.08, 0.16), rng.randf_range(-0.04, 0.06), rng.randf_range(-0.05, 0.05))
		_limb(root, "Straw", at, at + d, 0.006, 0.002, straw(), 4)


## A carriage lantern on a wall bracket (its back on z = 0, facing +Z): a tin box with glass on
## three sides, a peaked cap; the light comes from an OilLamp in it (StreetDressing adds one).
static func lantern(root: Node3D) -> void:
	var tin_dark := iron()
	_box(root, "Bracket", Vector3(0.03, 0.03, 0.22), Vector3(0, 0.36, 0.11), tin_dark)
	_box(root, "Plate", Vector3(0.1, 0.2, 0.015), Vector3(0, 0.32, 0.008), tin_dark)
	var c := Vector3(0, 0.0, 0.2)
	_box(root, "Base", Vector3(0.17, 0.03, 0.17), c + Vector3(0, 0.015, 0), tin_dark)
	_box(root, "Top", Vector3(0.17, 0.03, 0.17), c + Vector3(0, 0.255, 0), tin_dark)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_box(root, "Post", Vector3(0.015, 0.24, 0.015), c + Vector3(x * 0.077, 0.135, z * 0.077), tin_dark)
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var g := BoxMesh.new()
	g.size = Vector3(0.15, 0.21, 0.15)
	glass.mesh = g
	glass.material_override = chimney_glass()
	glass.position = c + Vector3(0, 0.135, 0)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glass)
	_add(root, "Cap", lathe(_profile([[0.12, 0.27], [0.0, 0.36]]), 4), tin_dark, Transform3D(Basis(Vector3.UP, PI * 0.25), c))
	_add(root, "Ring", lathe(_profile([[0.025, 0.36], [0.03, 0.38], [0.025, 0.4]]), 6), tin_dark, Transform3D(Basis.IDENTITY, c))


## A wagon wheel of `radius` in the XY plane (axle along Z): iron tyre, felloe, spokes, hub.
static func wheel(root: Node3D, at: Vector3, radius: float, spokes := 12) -> void:
	var w := Node3D.new()
	w.name = "Wheel"
	w.position = at
	root.add_child(w)
	var rot := Basis(Vector3.RIGHT, PI * 0.5)
	_add(w, "Tyre", lathe(_profile([[radius, -0.04], [radius, 0.04]]), 16), iron(), Transform3D(rot, Vector3.ZERO))
	_add(w, "Felloe", lathe(_profile([[radius - 0.06, 0.035], [radius - 0.06, -0.035]]), 16, false, true), dark_wood(), Transform3D(rot, Vector3.ZERO))
	_add(w, "Hub", lathe(_profile([[0.06, -0.09], [0.08, -0.03], [0.08, 0.03], [0.06, 0.09]]), 8), dark_wood(), Transform3D(rot, Vector3.ZERO))
	for k in spokes:
		var a := TAU * k / spokes
		var b := Basis(Vector3.BACK, a)
		_box(w, "Spoke", Vector3(0.03, radius - 0.08, 0.025), b * Vector3(0, (radius - 0.02) * 0.5, 0), mid_wood(), b)


## A covered wagon, 3.4 m long along X (its tongue toward -X), canvas on hoops.
static func wagon(root: Node3D) -> void:
	var w := weathered()
	var bed_y := 0.95
	_box(root, "Floor", Vector3(3.2, 0.06, 1.2), Vector3(0, bed_y, 0), w)
	for z in [-0.6, 0.6]:
		_box(root, "Side", Vector3(3.2, 0.5, 0.04), Vector3(0, bed_y + 0.25, z), w)
	for x in [-1.6, 1.6]:
		_box(root, "End", Vector3(0.04, 0.5, 1.2), Vector3(x, bed_y + 0.25, 0), w)
	for x in [-1.0, 1.15]:
		_box(root, "Axle", Vector3(0.1, 0.1, 1.7), Vector3(x, 0.55, 0), dark_wood())
	for z in [-0.82, 0.82]:
		wheel(root, Vector3(-1.0, 0.5, z), 0.5)
		wheel(root, Vector3(1.15, 0.65, z), 0.65)
	_box(root, "Tongue", Vector3(2.2, 0.08, 0.08), Vector3(-2.6, 0.55, 0), dark_wood(), Basis(Vector3.BACK, 0.08))
	# The canvas: a half-tube over five hoops, gathered a little at the ends.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 10
	var r := 0.72
	var y0 := bed_y + 0.5
	for i in n:
		var a0 := PI * i / n
		var a1 := PI * (i + 1) / n
		var p := [Vector3(-1.75, y0 + sin(a0) * r * 0.95, -cos(a0) * r * 0.9), Vector3(1.75, y0 + sin(a0) * r * 0.95, -cos(a0) * r * 0.9),
				Vector3(1.75, y0 + sin(a1) * r * 0.95, -cos(a1) * r * 0.9), Vector3(-1.75, y0 + sin(a1) * r * 0.95, -cos(a1) * r * 0.9)]
		var mid := Vector3(0, y0, 0)
		for tri in [[0, 1, 2], [0, 2, 3]]:
			var v0: Vector3 = p[tri[0]]
			var v1: Vector3 = p[tri[1]]
			var v2: Vector3 = p[tri[2]]
			var out := ((v0 + v1 + v2) / 3.0 - mid) * Vector3(0, 1, 1)
			if (v1 - v0).cross(v2 - v0).dot(out) > 0.0:
				var t := v1
				v1 = v2
				v2 = t
			for v: Vector3 in [v0, v1, v2]:
				st.set_normal(((v - mid) * Vector3(0, 1, 1)).normalized())
				st.set_uv(Vector2(v.x + 1.75, (atan2(v.y - y0, -v.z) + 0.0) * r))
				st.add_vertex(v)
	_add(root, "Canvas", st.commit(), canvas())
	for x in [-1.6, -0.8, 0.0, 0.8, 1.6]:
		_add(root, "Hoop", lathe(_profile([[r * 0.92, -0.015], [r * 0.92, 0.015]]), 12), dark_wood(),
				Transform3D(Basis(Vector3.BACK, PI * 0.5).scaled(Vector3(1, 1, 1)), Vector3(x, y0, 0)))


## A water tower: four splayed legs braced across, a platform, a staved tank with hoops and a
## pointed roof. About 11 m tall.
static func water_tower(root: Node3D) -> void:
	var legs := 7.0
	var w := weathered()
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var foot := Vector3(x * 1.9, 0, z * 1.9)
			var top := Vector3(x * 1.3, legs, z * 1.3)
			var b := Basis.looking_at(top - foot, Vector3.FORWARD)
			_box(root, "Leg", Vector3(0.2, 0.2, foot.distance_to(top)), (foot + top) * 0.5, dark_wood(), b)
	for y in [2.2, 4.6]:
		var half := lerpf(1.9, 1.3, y / legs)
		for side in 4:
			var b := Basis(Vector3.UP, side * PI * 0.5)
			_box(root, "Brace", Vector3(half * 2.0, 0.1, 0.06), b * Vector3(0, y, half), w, b)
			var d := Basis(Vector3.UP, side * PI * 0.5) * Basis(Vector3.BACK, 0.75)
			_box(root, "Cross", Vector3(half * 2.6, 0.08, 0.05), b * Vector3(0, y + 1.1, half), w, d)
	_box(root, "Platform", Vector3(3.4, 0.12, 3.4), Vector3(0, legs + 0.06, 0), w)
	var pts := []
	for k in 6:
		var t := float(k) / 5.0
		pts.append([1.5 + 0.06 * sin(t * PI), legs + 0.12 + 3.0 * t])
	_add(root, "Tank", lathe(_profile(pts), 16, true), staves())
	for y in [0.5, 1.5, 2.5]:
		_add(root, "Hoop", lathe(_profile([[1.56, legs + y - 0.04], [1.58, legs + y], [1.56, legs + y + 0.04]]), 16), iron())
	_add(root, "Roof", lathe(_profile([[1.7, legs + 3.1], [0.05, legs + 4.4]]), 16), dark_wood())


## A telegraph pole, 7 m, a crossarm with two glass insulators on it.
static func telegraph_pole(root: Node3D) -> void:
	_box(root, "Pole", Vector3(0.2, 7.0, 0.2), Vector3(0, 3.5, 0), dark_wood())
	_box(root, "Arm", Vector3(1.4, 0.1, 0.1), Vector3(0, 6.6, 0), dark_wood())
	var glass := _mat("insulator", PixelArt.metal("prop_insulator", Color(0.4, 0.55, 0.5), 251), Color.WHITE, 0.2, 0.0, 0.7)
	for x in [-0.55, 0.55]:
		_add(root, "Insulator", lathe(_profile([[0.03, 6.65], [0.045, 6.7], [0.02, 6.78]]), 6), glass, Transform3D(Basis.IDENTITY, Vector3(x, 0, 0)))


## A saddled horse standing at a rail, head at -X (docs/ART_REVIEW.md §3.5: the painting's horses
## have form; a few hundred faces read at their size). Lofted body (chest, girth, barrel, flank,
## croup), an arched neck, a long head with a jaw, ears, a mane and a hanging tail, legs with
## knees and hocks on round hooves; a blanket and a stock saddle (swell, horn, seat, cantle,
## skirts, fenders, stirrups, cinch) and a headstall. Dark points: a bay.
static func horse(root: Node3D) -> void:
	var hide := _mat("horse", PixelArt.dirt("prop_horse", Color(0.42, 0.24, 0.13), 253))
	var dark := _mat("horse_dark", PixelArt.dirt("prop_horse_dark", Color(0.12, 0.08, 0.06), 255))
	var leather := _mat("leather", PixelArt.dirt("prop_leather", Color(0.32, 0.18, 0.09), 259))
	var blanket := _mat("blanket", PixelArt.painted("prop_blanket", Color(0.5, 0.12, 0.08), Color(0.3, 0.2, 0.15), 257, 0.1))
	# The body, chest to rump: [x, half-width, half-height, centre height].
	var body := [[-0.78, 0.17, 0.26, 1.2], [-0.62, 0.27, 0.37, 1.18], [-0.42, 0.33, 0.41, 1.2], [-0.1, 0.35, 0.4, 1.19],
			[0.22, 0.34, 0.38, 1.21], [0.5, 0.31, 0.36, 1.26], [0.74, 0.26, 0.3, 1.3], [0.9, 0.12, 0.16, 1.32]]
	var rings := []
	for b in body:
		rings.append(_ring(Vector3(b[0], b[3], 0), b[1], b[2]))
	_add(root, "Body", loft(rings), hide)
	# The withers rise into the neck: an arch of rings up and forward to the poll.
	var neck := []
	# (A ring's lean is its top's tilt about z: negative leans it back, square to a neck rising
	# forward; positive leans it forward, square to a head dropping forward.)
	var neck_path := [[-0.62, 1.42, 0.19, 0.24, -0.3], [-0.78, 1.6, 0.17, 0.22, -0.5], [-0.95, 1.78, 0.15, 0.19, -0.6],
			[-1.1, 1.92, 0.13, 0.16, -0.5], [-1.2, 1.98, 0.12, 0.13, -0.2]]
	for q in neck_path:
		neck.append(_ring(Vector3(q[0], q[1], 0), q[2], q[3], 10, q[4]))
	_add(root, "Neck", loft(neck), hide)
	# The head hangs down and forward off the poll: wide at the jaw, narrowing to the muzzle.
	var head := []
	var head_path := [[-1.2, 1.98, 0.12, 0.13, 0.2], [-1.3, 1.9, 0.13, 0.17, 0.6], [-1.4, 1.76, 0.11, 0.19, 0.9],
			[-1.5, 1.6, 0.09, 0.13, 1.0], [-1.58, 1.48, 0.075, 0.09, 1.0]]
	for q in head_path:
		head.append(_ring(Vector3(q[0], q[1], 0), q[2], q[3], 10, q[4]))
	_add(root, "Head", loft(head), hide)
	_add(root, "Muzzle", loft([_ring(Vector3(-1.58, 1.48, 0), 0.075, 0.09, 10, 1.0), _ring(Vector3(-1.65, 1.4, 0), 0.055, 0.06, 10, 1.0)]), dark)
	for z in [-0.07, 0.07]:
		_limb(root, "Ear", Vector3(-1.17, 2.04, z), Vector3(-1.2, 2.2, z * 1.4), 0.03, 0.006, hide, 6)
		_box(root, "Eye", Vector3(0.04, 0.03, 0.02), Vector3(-1.32, 1.9, z * 2.0), dark)
	# Mane: a ragged crest down the neck; forelock between the ears; tail hanging off the rump.
	var crest := []
	for q in neck_path:
		var c := Vector3(q[0], q[1], 0)
		var up := Basis(Vector3.BACK, q[4]) * Vector3(0, q[3], 0)
		crest.append(PackedVector3Array([c + up + Vector3(0.03, -0.01, 0.035), c + up + Vector3(0.0, 0.06, 0.0), c + up + Vector3(0.03, -0.01, -0.035), c + up + Vector3(0.07, -0.05, 0.0)]))
	_add(root, "Mane", loft(crest), dark)
	_limb(root, "Forelock", Vector3(-1.2, 2.06, 0), Vector3(-1.32, 1.9, 0.02), 0.03, 0.01, dark, 5)
	var tail := [_ring(Vector3(0.88, 1.32, 0), 0.06, 0.06, 6), _ring(Vector3(1.0, 1.08, 0), 0.1, 0.08, 6),
			_ring(Vector3(1.05, 0.78, 0), 0.09, 0.07, 6), _ring(Vector3(1.03, 0.48, 0), 0.05, 0.04, 6)]
	_add(root, "Tail", loft(tail), dark)
	# Legs: fore from the shoulder, straight down; hind from the stifle, angled at the hock.
	for z in [-0.17, 0.17]:
		var fx := -0.52
		_limb(root, "Forearm", Vector3(fx - 0.04, 1.0, z), Vector3(fx, 0.62, z), 0.09, 0.055, hide)
		_limb(root, "Knee", Vector3(fx, 0.64, z), Vector3(fx, 0.52, z), 0.062, 0.05, hide, 6)
		_limb(root, "Cannon", Vector3(fx, 0.54, z), Vector3(fx + 0.01, 0.14, z), 0.045, 0.04, dark, 6)
		_limb(root, "Pastern", Vector3(fx + 0.01, 0.15, z), Vector3(fx - 0.03, 0.06, z), 0.045, 0.05, dark, 6)
		_add(root, "Hoof", lathe(_profile([[0.07, 0.0], [0.065, 0.06], [0.05, 0.075]]), 8), dark, Transform3D(Basis.IDENTITY, Vector3(fx - 0.03, 0.0, z)))
		var hx := 0.6
		_limb(root, "Thigh", Vector3(hx - 0.02, 1.05, z), Vector3(hx + 0.08, 0.68, z), 0.12, 0.06, hide)
		_limb(root, "Gaskin", Vector3(hx + 0.08, 0.7, z), Vector3(hx + 0.2, 0.46, z), 0.06, 0.045, hide, 6)
		_limb(root, "Hock", Vector3(hx + 0.2, 0.48, z), Vector3(hx + 0.18, 0.38, z), 0.055, 0.045, dark, 6)
		_limb(root, "HindCannon", Vector3(hx + 0.18, 0.4, z), Vector3(hx + 0.12, 0.14, z), 0.042, 0.038, dark, 6)
		_limb(root, "HindPastern", Vector3(hx + 0.12, 0.15, z), Vector3(hx + 0.09, 0.06, z), 0.042, 0.048, dark, 6)
		_add(root, "HindHoof", lathe(_profile([[0.07, 0.0], [0.065, 0.06], [0.05, 0.075]]), 8), dark, Transform3D(Basis.IDENTITY, Vector3(hx + 0.09, 0.0, z)))
	# Blanket: a square of felt over the back, following the barrel.
	var blanket_rings := []
	for x in [-0.45, -0.2, 0.05, 0.25]:
		blanket_rings.append(_arc(x, 0.03, 1.25, 0.41, 1.19, 8))
	_add(root, "Blanket", loft(blanket_rings, false), blanket)
	# The stock saddle: skirts over the blanket, a seat dished between the swell and the cantle.
	var skirt_rings := []
	for x in [-0.38, -0.15, 0.1, 0.22]:
		skirt_rings.append(_arc(x, 0.055, 1.05, 0.41, 1.19, 8))
	_add(root, "Skirts", loft(skirt_rings, false), leather)
	var seat_x := [-0.34, -0.26, -0.16, -0.02, 0.1, 0.16]
	var seat_y := [1.74, 1.68, 1.64, 1.64, 1.69, 1.78]
	var seat_w := [0.1, 0.14, 0.17, 0.18, 0.17, 0.12]
	var seat := []
	for i in seat_x.size():
		seat.append(_arc(seat_x[i], seat_y[i] - 1.19 - 0.41, seat_w[i] * 5.0, 0.41, 1.19, 6))
	_add(root, "Seat", loft(seat, false), leather)
	_add(root, "Horn", lathe(_profile([[0.035, 1.72], [0.025, 1.8], [0.045, 1.84], [0.03, 1.86]]), 8), leather, Transform3D(Basis.IDENTITY, Vector3(-0.34, 0, 0)))
	for z in [-0.3, 0.3]:
		_box(root, "Fender", Vector3(0.2, 0.45, 0.02), Vector3(-0.1, 1.42, z), leather)
		_add(root, "Stirrup", lathe(_profile([[0.05, 0.0], [0.055, 0.015], [0.05, 0.03]]), 8), iron(), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.1, 1.17, z)))
		_box(root, "Cinch", Vector3(0.06, 0.4, 0.02), Vector3(-0.3, 0.98, z * 1.1), leather)
	_box(root, "CinchUnder", Vector3(0.06, 0.02, 0.66), Vector3(-0.3, 0.79, 0), leather)
	# Headstall and throatlatch.
	_box(root, "Browband", Vector3(0.02, 0.02, 0.22), Vector3(-1.24, 1.97, 0), leather)
	for z in [-0.1, 0.1]:
		_box(root, "Cheek", Vector3(0.02, 0.3, 0.02), Vector3(-1.4, 1.78, z), leather, Basis(Vector3.BACK, 0.45))
	_box(root, "Nose", Vector3(0.02, 0.02, 0.2), Vector3(-1.5, 1.58, 0), leather)


## A ring over the top of a body section at x: the body's ellipse (rz, ry round height cy) pushed
## out by `off`, the top `span` radians either side of straight up, as a PackedVector3Array (an
## open loft row: a blanket, a skirt, a seat).
static func _arc(x: float, off: float, span: float, ry: float, cy: float, n: int, rz := 0.35) -> PackedVector3Array:
	var out := PackedVector3Array()
	for k in n:
		var t := PI * 0.5 - span + 2.0 * span * k / float(n - 1)
		out.append(Vector3(x, cy + sin(t) * (ry + off), cos(t) * (rz + off)))
	return out
