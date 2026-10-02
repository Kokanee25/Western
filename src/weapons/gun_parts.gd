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
