class_name GunParts
## Small helpers for building models from primitives in code: parts with pixel-art materials
## mapped at a fine texel density (hand-held things are seen up close).

const TEXELS_PER_METER := 320.0

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
## own space at the guns' finer density (not tracked: F7 doesn't change the guns). The guns' own
## metals and wood use it; skin and cloth stay StandardMaterial3Ds (people read their textures).
static func grid(key: String, tex: Texture2D, metallic := 0.0, roughness := 0.8) -> ShaderMaterial:
	key = "grid:" + key
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = PixelArt.GRID_SHADER
		m.set_shader_parameter(&"albedo_tex", tex)
		m.set_shader_parameter(&"tint", Color.WHITE)
		m.set_shader_parameter(&"mapping", PixelArt.Mapping.TRIPLANAR)
		m.set_shader_parameter(&"texels_per_meter", TEXELS_PER_METER)
		m.set_shader_parameter(&"use_mipmaps", true)
		m.set_shader_parameter(&"metallic", metallic)
		m.set_shader_parameter(&"roughness", roughness)
		m.set_shader_parameter(&"specular", 0.5)
		_mats[key] = m
	return _mats[key]


static func blued() -> ShaderMaterial:
	return grid("blued", PixelArt.metal("blued", Color(0.2, 0.22, 0.27), 71), 0.75, 0.35)


static func case_hardened() -> ShaderMaterial:
	return grid("case", PixelArt.metal("case", Color(0.36, 0.34, 0.33), 73, 0.8), 0.7, 0.4)


static func brass() -> ShaderMaterial:
	return grid("brass", PixelArt.metal("brass", Color(0.72, 0.56, 0.27), 75), 0.85, 0.35)


static func walnut() -> ShaderMaterial:
	return grid("walnut", PixelArt.wood("walnut", Color(0.3, 0.17, 0.09), 77, 1, 0, 1.3), 0.0, 0.55)


static func lead() -> ShaderMaterial:
	return grid("lead", PixelArt.metal("lead", Color(0.45, 0.45, 0.47), 79), 0.4, 0.6)


static func skin() -> StandardMaterial3D:
	return material("skin", PixelArt.skin("skin", Color(0.74, 0.54, 0.42), 81), 0.0, 0.7)


static func cloth(key: String, color: Color) -> StandardMaterial3D:
	return material("cloth:" + key, PixelArt.skin("cloth:" + key, color, 83), 0.0, 0.95)


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
