class_name SheetStyle
## The character-sheet style trial (Prompt 07 territory, 2026-10-11; the target is
## docs/concept/style_candidates/character_sheet.png): a realistic model whose textures are cut
## into squares of a fixed real size, drawn nearest, lit by ordinary smooth light that crosses the
## squares; no per-texel light, no coarsening far off, no screen pass. `--sheet-style` on any run
## (Settings) turns it on for that run, unsaved; `--sheet-texels=16` lays the world at 16 a metre
## (32 by default). Off otherwise: nothing here changes the game's look.
##   The textures are made by tools/sheet_style.py into build/sheet_style/ (gitignored; run
## `python3 tools/sheet_style.py man world` first) and read with Image.load_from_file:
##   - a man with <model>_albedo.png there (his own Rodin colour in body-space squares: face 3 mm,
##     hat 6, clothes 7) is dressed in sheet_man.gdshader with his smooth normal map, as he's made
##     (every HumanBody that enters the tree, via SceneTree.node_added);
##   - the world's factory keys take the smooth set box-averaged to 32 (or 16) texels a metre.

static var on := false
static var texels := 32.0
## Which look (`--sheet-style=MODE`): "squares" (the trial's rounds 1-2: his Rodin colour cut into
## squares, build/sheet_style/), or the style lab's candidates (docs/briefs/style-lab.md) "painted"
## (B: the game's own painted textures under Godot's light, the world at 16 a metre) and "real"
## (C: the models' own colour, the world the smooth set at 128 a metre) and "sheet" (D: the models'
## own colour in irregular flat patches as the character sheet's, the world in patches and the road
## in blocks, all at 128 a metre), from build/sheet_style/<mode>/.
static var mode := "squares"
const DIR := "res://build/sheet_style/"
const SHADER := preload("res://src/art/sheet_man.gdshader")
static var _textures := {}
static var _tangents := {}


## An image from build/sheet_style/ as a mipmapped texture, or null if it isn't there.
static func texture(rel: String) -> Texture2D:
	if _textures.has(rel):
		return _textures[rel]
	var path := ProjectSettings.globalize_path(DIR + rel)
	var tex: Texture2D = null
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img:
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	_textures[rel] = tex
	return tex


## The world's texture for a factory key under the trial, or null (the factory's own then).
static func world_texture(key: String) -> Texture2D:
	if mode == "sheet":
		return texture("sheet/textures/%s.png" % key)
	return texture("%s/%s.png" % ["textures16" if texels <= 16.0 else "textures", key])


## Watch the tree for people to dress (Settings calls this when the trial is on).
static func watch(tree: SceneTree) -> void:
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)


static func _on_node_added(n: Node) -> void:
	if n.has_method(&"go_limp") and "body_model" in n:
		n.ready.connect(dress.bind(n), CONNECT_ONE_SHOT)


## The folder this mode's textures are in, under DIR.
static func _sub() -> String:
	return "" if mode == "squares" else mode + "/"


## A shape's material: its own <model>_<shape>_albedo.png, else his skin's, else the mode's one
## <model>_albedo.png; null if there's none.
static var _materials := {}


static func _material(model: String, shape: String) -> ShaderMaterial:
	var key := model + "/" + shape
	if _materials.has(key):
		return _materials[key]
	var names := [shape, "skin"] if shape != "skin" else ["skin"]
	var albedo: Texture2D = null
	var normal: Texture2D = null
	for n in names:
		albedo = texture("%s%s_%s_albedo.png" % [_sub(), model, n])
		if albedo:
			normal = texture("%s%s_%s_normal.png" % [_sub(), model, n])
			break
	if albedo == null:
		albedo = texture("%s%s_albedo.png" % [_sub(), model])
		normal = texture("%s%s_normal.png" % [_sub(), model])
	var mat: ShaderMaterial = null
	if albedo:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		mat.set_shader_parameter(&"albedo_tex", albedo)
		mat.set_shader_parameter(&"normal_tex", normal)
		mat.set_shader_parameter(&"use_normal", normal != null)
	_materials[key] = mat
	return mat


## His body's meshes in sheet_man.gdshader, each shape (HumanBody names a piece Shape_part, a
## joined shape Shape_whole) with its own texture: true if he had any.
static func dress(body: Node) -> bool:
	var model := String(body.get(&"body_model"))
	if model == "":
		return false
	var any := false
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.skin == null or m.mesh == null:
			continue
		var mat := _material(model, String(m.name).get_slice("_", 0).to_lower())
		if mat == null:
			continue
		m.mesh = with_tangents(m.mesh as ArrayMesh)
		m.material_override = mat
		any = true
	return any


## The mesh with tangents (for the normal map) worked out from its UVs: Lengyel's method
## (E. Lengyel, "Computing Tangent Space Basis Vectors for an Arbitrary Mesh", 2001), per vertex.
static func with_tangents(mesh: ArrayMesh) -> ArrayMesh:
	if mesh == null or mesh.get_surface_count() != 1:
		return mesh
	if _tangents.has(mesh):
		return _tangents[mesh]
	var a := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if uv.size() != v.size() or nrm.size() != v.size():
		_tangents[mesh] = mesh
		return mesh
	if idx.is_empty():
		idx.resize(v.size())
		for i in v.size():
			idx[i] = i
	var tan := PackedVector3Array()
	var bit := PackedVector3Array()
	tan.resize(v.size())
	bit.resize(v.size())
	for t in range(0, idx.size(), 3):
		var i0 := idx[t]
		var i1 := idx[t + 1]
		var i2 := idx[t + 2]
		var e1 := v[i1] - v[i0]
		var e2 := v[i2] - v[i0]
		var d1 := uv[i1] - uv[i0]
		var d2 := uv[i2] - uv[i0]
		var r := d1.x * d2.y - d2.x * d1.y
		if absf(r) < 1e-12:
			continue
		r = 1.0 / r
		var s := (e1 * d2.y - e2 * d1.y) * r
		var b := (e2 * d1.x - e1 * d2.x) * r
		for i in [i0, i1, i2]:
			tan[i] += s
			bit[i] += b
	var out := PackedFloat32Array()
	out.resize(v.size() * 4)
	for i in v.size():
		var n := nrm[i]
		var tt := (tan[i] - n * n.dot(tan[i]))
		tt = tt.normalized() if tt.length_squared() > 1e-16 else n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
		out[i * 4] = tt.x
		out[i * 4 + 1] = tt.y
		out[i * 4 + 2] = tt.z
		out[i * 4 + 3] = -1.0 if n.cross(tt).dot(bit[i]) < 0.0 else 1.0
	a[Mesh.ARRAY_TANGENT] = out
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	for shift in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
		flags |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << shift
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], {}, mesh.surface_get_format(0) & flags)
	_tangents[mesh] = m
	return m
