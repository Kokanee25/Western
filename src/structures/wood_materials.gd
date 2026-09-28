class_name WoodMaterials
## Shared materials for structure members: pixel-art textures (PixelArt) read with nearest
## filtering at PixelArt.texels_per_meter. Each member picks a tint/offset variant from a hash of
## its ID, so every board reads as its own piece of timber, and the same board always looks the same.

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
		var base: Color = palette[0]
		var tint: Color = palette[i]
		var m := StandardMaterial3D.new()
		m.albedo_texture = texture_for(wood)
		# Variants: the same texture, slightly re-tinted and shifted, so neighbouring boards differ.
		m.albedo_color = Color(tint.r / base.r, tint.g / base.g, tint.b / base.b).clamp(Color(0, 0, 0), Color(1.2, 1.2, 1.2))
		PixelArt.track(m)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(key)
		m.uv1_offset = Vector3(rng.randf(), rng.randf(), 0.0)
		m.roughness = 0.95
		m.metallic_specular = 0.2
		_cache[key] = m
	return _cache[key]


## The pixel-art texture for a wood (see PixelArt). Grain runs along u.
static func texture_for(wood: StringName) -> Texture2D:
	var palette: Array = PALETTES.get(wood, [Color(0.5, 0.45, 0.4)])
	var base: Color = palette[0]
	match wood:
		&"painted_ochre", &"painted_rust":
			return PixelArt.painted(String(wood), base, Color(0.52, 0.42, 0.32), 31, 0.2)
		&"sign":
			return PixelArt.painted(String(wood), base, Color(0.52, 0.42, 0.32), 37, 0.1)
		&"framing":
			return PixelArt.wood(String(wood), base, 41, 1, 2, 1.2)
		&"floor":
			return PixelArt.wood(String(wood), base, 43, 2, 5)
		&"dark_trim":
			return PixelArt.wood(String(wood), base, 47, 0, 1, 0.8)
		_:
			return PixelArt.wood(String(wood), base, 53, 2, 4)


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
