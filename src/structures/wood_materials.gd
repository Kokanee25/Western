class_name WoodMaterials
## Shared placeholder materials. Each member picks a tint variant from a hash of its ID, so every
## board reads as its own piece of timber, and the same board is always the same colour.

const PALETTES := {
	&"weathered_pine": [Color(0.56, 0.48, 0.39), Color(0.5, 0.43, 0.35), Color(0.61, 0.53, 0.43), Color(0.47, 0.41, 0.34), Color(0.53, 0.47, 0.4)],
	&"framing": [Color(0.46, 0.34, 0.23), Color(0.42, 0.31, 0.21), Color(0.5, 0.38, 0.26)],
	&"floor": [Color(0.42, 0.3, 0.2), Color(0.38, 0.27, 0.18), Color(0.45, 0.33, 0.22), Color(0.4, 0.29, 0.2)],
	&"painted_ochre": [Color(0.74, 0.56, 0.31), Color(0.7, 0.52, 0.29), Color(0.77, 0.6, 0.35), Color(0.68, 0.53, 0.33)],
	&"painted_rust": [Color(0.55, 0.24, 0.16), Color(0.5, 0.22, 0.15), Color(0.58, 0.27, 0.18)],
	&"dark_trim": [Color(0.26, 0.19, 0.14), Color(0.23, 0.17, 0.12)],
	&"sign": [Color(0.86, 0.8, 0.66)],
}

static var _cache := {}
static var _grain: Texture2D
static var _glass: StandardMaterial3D
static var _water: StandardMaterial3D


static func variant_count(wood: StringName) -> int:
	return PALETTES.get(wood, [Color.WHITE]).size()


static func get_material(wood: StringName, variant: int) -> Material:
	if wood == &"glass":
		return glass()
	var palette: Array = PALETTES.get(wood, [Color(0.5, 0.45, 0.4)])
	var i := posmod(variant, palette.size())
	var key := "%s:%d" % [wood, i]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = palette[i]
		m.albedo_texture = _grain_texture()
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.6, 0.6, 0.6)
		m.roughness = 0.92
		_cache[key] = m
	return _cache[key]


static func glass() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.albedo_color = Color(0.55, 0.65, 0.6, 0.28)
		_glass.roughness = 0.15
		_glass.metallic_specular = 0.8
	return _glass


static func water() -> StandardMaterial3D:
	if _water == null:
		_water = StandardMaterial3D.new()
		_water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_water.albedo_color = Color(0.16, 0.2, 0.18, 0.82)
		_water.roughness = 0.05
		_water.metallic = 0.2
	return _water


## A stretched noise texture: reads as wood grain and grime at low resolution.
static func _grain_texture() -> Texture2D:
	if _grain == null:
		var noise := FastNoiseLite.new()
		noise.seed = 1882
		noise.frequency = 0.035
		noise.fractal_octaves = 3
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.72, 0.72, 0.72))
		ramp.set_color(1, Color(1.0, 1.0, 1.0))
		var tex := NoiseTexture2D.new()
		tex.width = 256
		tex.height = 32
		tex.seamless = true
		tex.noise = noise
		tex.color_ramp = ramp
		_grain = tex
	return _grain
