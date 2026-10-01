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
const BOTTLE_GLASS := [Color(0.22, 0.11, 0.04), Color(0.12, 0.18, 0.08), Color(0.3, 0.16, 0.05)]

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


## A see-through glass chimney (off the grid: glass you see the flame through). Unshaded: lit by
## the flame a few centimetres inside it, it would burn white.
static func chimney_glass() -> StandardMaterial3D:
	if not _materials.has("chimney"):
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.86, 0.62, 0.2)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials["chimney"] = m
	return _materials["chimney"]


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


## A kerosene table lamp: brass foot and font, a burner collar and a glass chimney (the light
## comes from OilLamp; its flame sits inside the chimney at 0.2 m). Shared by OilLamp.
static func lamp(root: Node3D) -> void:
	_add(root, "Foot", lathe(_profile([[0.065, 0.0], [0.07, 0.01], [0.05, 0.03], [0.025, 0.05], [0.03, 0.08], [0.06, 0.11], [0.065, 0.14], [0.03, 0.165], [0.022, 0.175]]), 12), brass())
	_add(root, "Collar", lathe(_profile([[0.028, 0.165], [0.032, 0.18], [0.03, 0.19]]), 10), brass())
	_add(root, "Chimney", lathe(_profile([[0.026, 0.19], [0.03, 0.21], [0.042, 0.25], [0.04, 0.29], [0.024, 0.33], [0.022, 0.38]]), 12), chimney_glass())


## A whiskey bottle in dark glass: shoulders, a neck, a cork and a paper label with a few lines
## of print on it. `variant` picks the glass and the label.
static func bottle(root: Node3D, variant := 0) -> void:
	_add(root, "Glass", lathe(_profile([[0.03, 0.0], [0.042, 0.004], [0.044, 0.02], [0.044, 0.19], [0.038, 0.215], [0.016, 0.24], [0.013, 0.27], [0.015, 0.275], [0.014, 0.285]]), 10), bottle_glass(variant))
	_add(root, "Base", disc(0.03, 10, 0.0, false), bottle_glass(variant))
	_add(root, "Cork", lathe(_profile([[0.012, 0.28], [0.011, 0.3]]), 6), _mat("cork", PixelArt.dirt("prop_cork", Color(0.55, 0.4, 0.25), 233)))
	_add(root, "Label", lathe(_profile([[0.0455, 0.07], [0.0455, 0.15]]), 10), _mat("label%d" % posmod(variant, 3), label_texture(posmod(variant, 3)), Color.WHITE, 0.9))


## A tin mug, open at the top (the inside's dark).
static func cup(root: Node3D) -> void:
	_add(root, "Outside", lathe(_profile([[0.036, 0.0], [0.038, 0.004], [0.04, 0.1]]), 10), tin())
	_add(root, "Inside", lathe(_profile([[0.033, 0.008], [0.037, 0.1]]), 10, false, true), _mat("tin_in", PixelArt.metal("prop_tin_in", Color(0.3, 0.29, 0.27), 235), Color.WHITE, 0.6, 0.2))
	_add(root, "Bottom", disc(0.034, 10, 0.008), _mat("tin_in", null))
	_add(root, "Lip", lathe(_profile([[0.037, 0.1], [0.04, 0.1]]), 10), tin())


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
	var paper: Color = [Color(0.82, 0.76, 0.58), Color(0.86, 0.82, 0.68), Color(0.76, 0.66, 0.46)][variant]
	var ink: Color = [Color(0.18, 0.1, 0.06), Color(0.12, 0.1, 0.1), Color(0.35, 0.08, 0.05)][variant]
	# 0.29 m round x 0.08 m tall at 64 a metre.
	var img := Image.create(19, 5, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + variant
	for y in 5:
		for x in 19:
			var c := paper.darkened(rng.randf() * 0.12)
			if y == 0 or y == 4:
				c = ink
			elif x >= 6 and x <= 12 and (y == 2 or (y == 1 and rng.randf() < 0.6) or (y == 3 and rng.randf() < 0.4)):
				c = ink.lerp(paper, rng.randf() * 0.3)
			img.set_pixel(x, y, c)
	img.set_pixel(9, 3, Color(0.6, 0.12, 0.08))
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
