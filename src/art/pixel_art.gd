class_name PixelArt
## Pixel-art textures painted in code: small, tileable, a handful of shades per colour, read with
## nearest-neighbour filtering so every texel shows. Deterministic from a seed, so the town looks
## the same every time. The long axis of the texture (u) is the direction of the grain.

## How many texels per metre the world uses. Walls, boards and ground all share it, so pixels are
## the same size everywhere. Fewer = chunkier. Read when materials are first made.
static var texels_per_meter := 40.0
## Mipmaps smooth distant texels (less shimmer, softer look); off = crunchy all the way out.
static var use_mipmaps := true


## Texel-size presets F7 cycles through: [texels per metre, mipmaps].
const DENSITY_PRESETS := [[40.0, true], [24.0, false], [16.0, false]]

## The material for everything on the texel grid (src/render/texel_grid.gdshaderinc), and the
## same with bullet holes cut in it (StructureMember).
const GRID_SHADER := preload("res://src/render/texel_grid.gdshader")
const HOLE_SHADER := preload("res://src/structures/member_holes.gdshader")

## How a grid material lays its texture on: the mesh's UVs (in metres; members), or by position
## along whichever axis a face looks down most (blockouts, props), in mesh or world space.
enum Mapping { UV, TRIPLANAR, WORLD_TRIPLANAR }

## Every material that uses the texel grid, so a density change can reach them all.
static var _materials: Array[ShaderMaterial] = []


## A pixel-art material on the texel grid: `tex` repeats every SIZE texels at texels_per_meter,
## nearest filtering, lit per texel when texel lighting is on (Settings.texel_lighting).
static func material(tex: Texture2D, tint := Color.WHITE, mapping := Mapping.UV, offset := Vector3.ZERO,
		roughness := 0.95, metallic := 0.0, specular := 0.2) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GRID_SHADER
	m.set_shader_parameter(&"albedo_tex", tex)
	m.set_shader_parameter(&"tint", tint)
	m.set_shader_parameter(&"mapping", mapping)
	m.set_shader_parameter(&"uv_offset", offset)
	m.set_shader_parameter(&"roughness", roughness)
	m.set_shader_parameter(&"metallic", metallic)
	m.set_shader_parameter(&"specular", specular)
	return track(m)


## The same material with bullet holes (the hole uniforms are set by the member).
static func hole_material(base: ShaderMaterial) -> ShaderMaterial:
	var m := base.duplicate() as ShaderMaterial
	m.shader = HOLE_SHADER
	return track(m)


## Keep a material laid out on the texel grid (the ground's shader too: it reads texels_per_meter).
static func track(m: ShaderMaterial) -> ShaderMaterial:
	_materials.append(m)
	_apply(m)
	return m


static func set_density(texels: float, mipmaps: bool) -> void:
	texels_per_meter = texels
	use_mipmaps = mipmaps
	var live: Array[ShaderMaterial] = []
	for m in _materials:
		if is_instance_valid(m):
			_apply(m)
			live.append(m)
	_materials = live


static func _apply(m: ShaderMaterial) -> void:
	m.set_shader_parameter(&"uv_scale", texels_per_meter / SIZE)
	m.set_shader_parameter(&"texels_per_meter", texels_per_meter)
	m.set_shader_parameter(&"use_mipmaps", use_mipmaps)


## Filtering for StandardMaterial3Ds that follow the mipmap setting (people's baked garments).
static func texture_filter() -> BaseMaterial3D.TextureFilter:
	return BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS if use_mipmaps else BaseMaterial3D.TEXTURE_FILTER_NEAREST


## Texel lighting (light, shadows and fog flat across each texel) on or off for every material
## at once: a global shader uniform, declared in project.godot [shader_globals].
static func set_texel_lighting(on: bool) -> void:
	RenderingServer.global_shader_parameter_set(&"texel_lighting", on)


const SIZE := 64

static var _cache := {}


## Shades from dark to light around a base colour, warmer in the shadows (like hand-picked
## pixel-art ramps rather than plain darkening).
static func ramp(base: Color, count := 5, spread := 0.42) -> Array[Color]:
	var out: Array[Color] = []
	for i in count:
		var t := float(i) / float(count - 1)  # 0 dark .. 1 light
		var k := lerpf(1.0 - spread, 1.0 + spread * 0.45, t)
		var c := Color(base.r * k, base.g * k, base.b * k)
		# shadows lean red-brown, highlights lean yellow
		c = c.lerp(Color(c.r * 1.05, c.g * 0.93, c.b * 0.85), (1.0 - t) * 0.5)
		c = c.lerp(Color(c.r * 1.04, c.g * 1.03, c.b * 0.9), t * 0.3)
		out.append(c.clamp())
	return out


## Bare timber: grain streaks along u, the odd knot and check (crack).
static func wood(key: String, base: Color, seed: int, knots := 2, cracks := 3, grain := 1.0) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var shades := ramp(base)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in SIZE:
		for x in SIZE:
			# grain lines run along x (few cells along, many across); a slow wobble bends them
			var wobble := (_noise(x, y, 4, 2, seed + 7) - 0.5) * 6.0
			var g := _noise(x, int(round(y + wobble)), 3, 24, seed)
			var broad := _noise(x, y, 4, 4, seed + 13)
			var v := lerpf(broad, g, clampf(0.55 * grain, 0.0, 1.0))
			img.set_pixel(x, y, shades[_band(v, shades.size())])
	for i in knots:
		_knot(img, shades, rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1), rng.randi_range(2, 3))
	for i in cracks:
		var cy := rng.randi_range(0, SIZE - 1)
		var cx := rng.randi_range(0, SIZE - 1)
		for j in rng.randi_range(6, 18):
			img.set_pixel((cx + j) % SIZE, cy, shades[0])
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Painted boards: flat paint with brush streaks, worn and peeling to grey timber underneath.
static func painted(key: String, paint: Color, timber: Color, seed: int, wear := 0.3) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var under: Image = wood(key + ":under", timber, seed + 101, 1, 2).get_image()
	var shades := ramp(paint, 3, 0.16)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var peel := _noise(x, y, 8, 8, seed + 3) * 0.65 + _noise(x, y, 4, 4, seed + 5) * 0.35
			if peel < wear:
				img.set_pixel(x, y, under.get_pixel(x, y))
				continue
			var streak := _noise(x, y, 3, 20, seed + 11)
			var s := _band(streak * 0.8 + 0.2 * _noise(x, y, 4, 4, seed + 17), shades.size())
			# paint lifts at the edge of a peel: a darker rim
			if peel < wear + 0.04:
				s = 0
			img.set_pixel(x, y, shades[s])
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Packed dirt: speckled, with scattered pebbles.
static func dirt(key: String, base: Color, seed: int) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var shades := ramp(base, 5, 0.3)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in SIZE:
		for x in SIZE:
			var v := _noise(x, y, 16, 16, seed) * 0.6 + _noise(x, y, 4, 4, seed + 1) * 0.25 + rng.randf() * 0.15
			img.set_pixel(x, y, shades[_band(v, shades.size())])
	for i in 18:
		var px := rng.randi_range(0, SIZE - 1)
		var py := rng.randi_range(0, SIZE - 1)
		img.set_pixel(px, py, shades[4])
		img.set_pixel((px + 1) % SIZE, (py + 1) % SIZE, shades[0])
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Metal: speckled blued steel, brass, tin. `mottle` > 0 gives case-hardened colour patches
## (the frame of a Colt: purple, blue and straw from the bone-charcoal quench).
static func metal(key: String, base: Color, seed: int, mottle := 0.0) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var shades := ramp(base, 4, 0.35)
	var patches: Array[Color] = [Color(0.36, 0.28, 0.4), Color(0.27, 0.33, 0.45), Color(0.6, 0.5, 0.33), Color(0.4, 0.38, 0.36)]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in SIZE:
		for x in SIZE:
			var v := _noise(x, y, 8, 8, seed) * 0.5 + _noise(x, y, 16, 3, seed + 3) * 0.3 + rng.randf() * 0.2
			var c := shades[_band(v, shades.size())]
			if mottle > 0.0:
				var m := _noise(x, y, 6, 6, seed + 9)
				var pc := patches[_band(_noise(x, y, 4, 4, seed + 21), patches.size())]
				c = c.lerp(pc, clampf((m - 0.35) * 2.0, 0.0, 1.0) * mottle)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Skin: flat tones with a few darker creases and knuckle marks.
static func skin(key: String, base: Color, seed: int) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var shades := ramp(base, 4, 0.22)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var v := _noise(x, y, 8, 8, seed) * 0.7 + _noise(x, y, 32, 32, seed + 1) * 0.3
			img.set_pixel(x, y, shades[_band(v * 0.8 + 0.2, shades.size())])
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Blood: an irregular blob in three reds, soaked darker in the middle. `hole` adds the dark
## punched hole of a bullet wound at the centre. Alpha is hard-edged (use alpha scissor).
static func blood(key: String, seed: int, hole := false, n := 32) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var shades: Array[Color] = [Color(0.2, 0.02, 0.02), Color(0.33, 0.04, 0.03), Color(0.46, 0.07, 0.05)]
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var cells := maxi(n / 8, 2)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var wob := (_noise(x * 64 / n, y * 64 / n, cells, cells, seed) - 0.5) * 0.7
			if d + wob > 0.95:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var soak := clampf(1.0 - d * 1.3 + (_noise(x * 64 / n, y * 64 / n, cells * 2, cells * 2, seed + 3) - 0.5) * 0.5, 0.0, 0.999)
			var c := shades[2 - _band(soak, 3)]
			if hole and d < 0.2:
				c = Color(0.05, 0.01, 0.01) if d < 0.13 else Color(0.14, 0.02, 0.02)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## A soft round puff in a few shades (smoke, dust), alpha falling off in steps.
static func puff(key: String, seed: int) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var n := 16
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
			var wob := (_noise(x * 4, y * 4, 4, 4, seed) - 0.5) * 0.35
			var a := clampf(1.0 - (d + wob), 0.0, 1.0)
			a = floor(a * 4.0) / 4.0
			var shade: float = 0.82 + 0.18 * floor(_noise(x * 4, y * 4, 8, 8, seed + 5) * 3.0) / 2.0
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _knot(img: Image, shades: Array[Color], cx: int, cy: int, r: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r * 2, r * 2 + 1):
			var d := sqrt(pow(dx / 2.0, 2) + dy * dy)
			if d <= r:
				var s := 0 if d < r * 0.5 else 1
				img.set_pixel(posmod(cx + dx, SIZE), posmod(cy + dy, SIZE), shades[s])


static func _band(v: float, count: int) -> int:
	return clampi(int(floor(clampf(v, 0.0, 0.9999) * count)), 0, count - 1)


## Tileable value noise on a SIZE x SIZE grid: `cx` x `cy` cells, 0..1.
static func _noise(x: int, y: int, cells_x: int, cells_y: int, seed: int) -> float:
	var fx := float(posmod(x, SIZE)) / SIZE * cells_x
	var fy := float(posmod(y, SIZE)) / SIZE * cells_y
	var ix := int(floor(fx))
	var iy := int(floor(fy))
	var tx := fx - ix
	var ty := fy - iy
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var a := _hash(ix % cells_x, iy % cells_y, seed)
	var b := _hash((ix + 1) % cells_x, iy % cells_y, seed)
	var c := _hash(ix % cells_x, (iy + 1) % cells_y, seed)
	var d := _hash((ix + 1) % cells_x, (iy + 1) % cells_y, seed)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


static func _hash(x: int, y: int, seed: int) -> float:
	var h := (x * 374761393 + y * 668265263 + seed * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0
