class_name PixelArt
## Pixel-art textures painted in code: small, tileable, a handful of shades per colour, read with
## nearest-neighbour filtering so every texel shows. Deterministic from a seed, so the town looks
## the same every time. The long axis of the texture (u) is the direction of the grain.

## How many texels per metre the world uses. Walls, boards and ground all share it, so pixels are
## the same size everywhere. Fewer = chunkier. Read when materials are first made.
static var texels_per_meter := 32.0
## Mipmaps smooth distant texels (less shimmer, softer look); off = crunchy all the way out.
static var use_mipmaps := true
## The concept painting's mosaic: how much each texel's shade wanders from the pattern under it, in
## small clusters (two-texel patches plus a little per texel), so wood and dirt read as a patchwork
## of squares in a few close browns rather than smooth streaks. 0 = the plain pattern.
static var mosaic := 0.6


## Texel-size presets F7 cycles through: [texels per metre, mipmaps]. The first is the default:
## 32 a metre, the size the judge measures the paintings' squares at (2026-10-02; was 64, and 40
## before that). The factory's textures are cut at it (tools/textures/materials.json).
const DENSITY_PRESETS := [[32.0, true], [24.0, false], [16.0, false], [64.0, true]]

## The material for everything on the texel grid (src/render/texel_grid.gdshaderinc), and the
## same with bullet holes cut in it (StructureMember).
const GRID_SHADER := preload("res://src/render/texel_grid.gdshader")
const HOLE_SHADER := preload("res://src/structures/member_holes.gdshader")
## The same two under the surface-blocks look (docs/briefs/renderer.md): their banded, tinted
## light(). Picked when `blocks` is on (Settings.surface_blocks, before the world is built).
const GRID_SHADER_BLOCKS := preload("res://src/render/texel_grid_blocks.gdshader")
const HOLE_SHADER_BLOCKS := preload("res://src/structures/member_holes_blocks.gdshader")
static var blocks := false
## What the lower bands of light lean toward under the surface-blocks look: the world's wood and
## dirt a warm brown (the paintings' half-light is never grey).
const SHADE_TINT := Color(1.0, 0.86, 0.72)

## How a grid material lays its texture on: the mesh's UVs (in metres; members), or by position
## along whichever axis a face looks down most (blockouts, props), in mesh or world space.
enum Mapping { UV, TRIPLANAR, WORLD_TRIPLANAR }

## Every material that uses the texel grid, so a density change can reach them all.
static var _materials: Array[ShaderMaterial] = []
## Use the texture factory's textures (assets/textures/<key>.png, tools/textures/) where there is
## one for a key; off = every texture painted in code, as before (for comparisons).
static var use_factory := true
## The "quantise once" set (tools/textures/reduce.py --smooth: the same paintings at four times
## the texels, no palette, assets/textures/smooth/), so the only quantisation is the screen
## mosaic's. Off by default; tools/screenshots.gd --quantise-once.
static var smooth := false
## The bold set (tools/textures/reduce.py --bold: the same paintings at BOLD_TEXELS a metre, each
## texel a clearly different colour from its neighbours, assets/textures/bold/): the street
## painting's style (Sean, 2026-10-05, DESIGN.md §4). Picked under the surface-blocks look (M).
static var bold := false
const FACTORY_PATH := "res://assets/textures/%s.png"
const SMOOTH_PATH := "res://assets/textures/smooth/%s.png"
const BOLD_PATH := "res://assets/textures/bold/%s.png"
## The bold set's texels a metre (reduce.py BOLD_TEXELS): the world is laid at it under M.
const BOLD_TEXELS := 16.0
## Wood drawn board by board from the street painting's rules (tools/textures/draw_boards.py:
## a strip a board, its squares stretched along the grain, each board its own tone), laid at
## DRAWN_TEXELS a metre whatever the look's density (a board a hand wide needs six squares across
## for its line and grain to show). The facade's own woods always; the rest under the bold look.
const DRAWN_PATH := "res://assets/textures/drawn/%s.png"
const DRAWN_TEXELS := 32.0
const DRAWN_ALWAYS := ["timber", "store_boards", "saloon_red", "jail_boards", "weathered_pine", "road", "road_wide"]
## The main street (docs/briefs/road.md; roadmap 1.4, Sean's road, 2026-10-15): smooth painted earth
## to the boardwalks, packed and churned (the texture factory's road_compact and road_loose, painted
## from his target, each with its _height), blended and rutted by the street's map
## (tools/textures/draw_street.py); ground.gdshader's street path. The drawn road above is the
## ground past the map. Each earth's texels a metre.
const STREET_MAP := "res://assets/textures/street/street_map.png"
const STREET_INFO := "res://assets/textures/street/street_map.json"
const EARTH_TEXELS := 128.0
## Drawn textures laid at their own density (squares a metre), not DRAWN_TEXELS: the saloon
## painting's table top is squares about 5 render pixels across, a quarter of what 32 gave
## (tools/textures/draw_table.py).
const DRAWN_DENSITY := {"shot_table": 128.0}
## The drawn road's squares a metre (tools/textures/draw_road.py TEXELS), whatever the look's density:
## 32 since roadmap 1.4 (2026-10-15, the road at the portrait man's square size, 36-48 a metre; 16
## before, Sean 2026-10-12's "the squares don't read" at the old factory road's per-texel noise).
const DRAWN_ROAD_TEXELS := 32.0
static var use_drawn := true
## The material lab's woods (tools/textures/paint_woods.py, tools/material_lab.gd; 2026-10-14, Sean's
## brief: an experiment, off in the game): with it on, a key with a lab texture is drawn from it,
## at DRAWN_TEXELS, its boards' long edges a dark seam on one side and a lit lip on the other
## (texel_grid edge_lip), as the exterior wood sheet draws them.
const LAB_PATH := "res://assets/textures/%s/%s.png"
const LAB_EDGE_SHADE := 0.32
const LAB_EDGE_LIP := 1.4
static var lab := false
## Which lab set: "lab" (paint_woods.py, the first, squares) or "lab2" (grain_woods.py, the timber
## pass: 128 texels a metre, mipmapped, never coarsened, end grain on LabGeometry's ends).
static var lab_set := "lab"
## The game's woods (Sean chose the material lab's final candidate C, 2026-10-15; docs/briefs/
## material-lab-timber.md): tools/textures/grain_woods.py --set=woods -> assets/textures/woods/,
## the woods its lab.json lists drawn from it whatever the look (timber, floor, the red and pale
## sidings, weathered pine, framing, dark trim): coherent boards at 128 texels a metre, mipmapped,
## never coarsened, end grain and worn paint ends where a member's mesh flags them. Off: the woods
## as before (drawn/, the factory).
const WOODS_SET := "woods"
static var woods := true
## The squares the game's woods are drawn in, texels a side (texel_grid square_texels): 1, C's own
## texels, 128 a metre, smooth. They were 4 (32 a metre, the portrait man's squares; roadmap 1.4,
## 2026-10-15) until Sean chose the painted-illustration look (DESIGN.md §4, 2026-10-16: smooth
## painted wood beside the painted men). Over 1 needs the textures drawn in them too
## (woods_grain.json `squares`, grain_woods.py squared).
const WOODS_SQUARE := 1.0
## Their end grain's (256 a metre).
const WOODS_END_SQUARE := 1.0
## The same for the drawn textures laid finer than DRAWN_TEXELS (DRAWN_DENSITY), none: the table's top
## in 4s read as a checkerboard at four times the painting's squares (the blind critic, 2026-10-15_r2:
## the saloon painting draws it finer than the man, about 5 px a square).
const DRAWN_SQUARES := {}
## Each set's lab.json woods, read once: {set: {wood: entry}}.
static var _sets := {}
const FACTORY_INDEX := "res://assets/textures/textures.json"
static var _factory_index: Variant = null


## A set's woods (assets/textures/<set>/lab.json "woods"), {} if it has none.
static func _set_woods(set: String) -> Dictionary:
	if not _sets.has(set):
		var jp := "res://assets/textures/%s/lab.json" % set
		var woods_of := {}
		if FileAccess.file_exists(jp):
			var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(jp))
			if info is Dictionary:
				woods_of = (info as Dictionary).get("woods", {})
		_sets[set] = woods_of
	return _sets[set]


## Whether the lab set paints this wood (assets/textures/<lab_set>/lab.json).
static func _lab_has(wood: String) -> bool:
	return _set_woods(lab_set).has(wood)


## A set's wood's entry (its lab.json): texels_per_metre, end_texels, end_wear...
static func _wood_info(set: String, key: String) -> Dictionary:
	return _set_woods(set).get(_wood_of(key), {})


## A lab wood's squares a metre (assets/textures/<lab_set>/lab.json), DRAWN_TEXELS if unsaid.
static func lab_density(key: String, set := "") -> float:
	return float(_wood_info(set if set != "" else lab_set, key).get("texels_per_metre", DRAWN_TEXELS))


## A factory tile's own texels a metre (assets/textures/textures.json: its texels over its metres;
## the props and table painted in the man's hand are 128, the older tiles 32), 0 for what is laid at
## the world's: a board strip (sized to its board), a sign, the ground, or one the index doesn't list.
static func factory_density(key: String) -> float:
	if _factory_index == null:
		var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(FACTORY_INDEX)) if FileAccess.file_exists(FACTORY_INDEX) else null
		_factory_index = info if info is Dictionary else {}
	if _wood_of(key) != key:
		return 0.0
	var e: Variant = (_factory_index as Dictionary).get(key)
	if not (e is Dictionary and (e as Dictionary).get("kind") == "tile"):
		return 0.0
	var texels: Array = (e as Dictionary).get("texels", [])
	var metres: Array = (e as Dictionary).get("metres", [])
	return float(texels[0]) / float(metres[0]) if texels.size() == 2 and metres.size() == 2 and float(metres[0]) > 0.0 else 0.0


## A pixel-art material on the texel grid: `tex` repeats every SIZE texels at texels_per_meter,
## nearest filtering, each texel a tile lit as one colour (src/render/tiles.gdshaderinc;
## Settings.tile_look, P). The world's members, blockouts and props all use it.
static func material(tex: Texture2D, tint := Color.WHITE, mapping := Mapping.UV, offset := Vector3.ZERO,
		roughness := 0.95, metallic := 0.0, specular := 0.2, shade_tint := SHADE_TINT) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = grid_shader()
	m.set_shader_parameter(&"albedo_tex", tex)
	m.set_shader_parameter(&"shade_tint", shade_tint)
	m.set_shader_parameter(&"tint", tint)
	m.set_shader_parameter(&"mapping", mapping)
	m.set_shader_parameter(&"uv_offset", offset)
	m.set_shader_parameter(&"roughness", roughness)
	m.set_shader_parameter(&"metallic", metallic)
	m.set_shader_parameter(&"specular", specular)
	if tex and tex.resource_path.contains("/drawn/"):
		var drawn_key := tex.resource_path.get_file().get_basename()
		m.set_meta(&"texels", DRAWN_DENSITY.get(drawn_key, DRAWN_TEXELS))
		m.set_shader_parameter(&"square_texels", float(DRAWN_SQUARES.get(drawn_key, 1.0)))
	elif tex and tex.resource_path.contains("/textures/lab/"):
		m.set_meta(&"texels", lab_density(tex.resource_path.get_file().get_basename()))
		m.set_shader_parameter(&"edge_shade", LAB_EDGE_SHADE)
		m.set_shader_parameter(&"edge_lip", LAB_EDGE_LIP)
	elif tex and (tex.resource_path.contains("/textures/lab2/") or tex.resource_path.contains("/textures/lab3/")
			or tex.resource_path.contains("/textures/lab4/") or tex.resource_path.contains("/textures/%s/" % WOODS_SET)):
		# The timber pass (lab2) and its finish (lab3): fine texels, mipmapped (far off they
		# average, not shimmer), never coarsened into squares, the edges a soft line, end grain
		# where LabGeometry flags an end; lab3's painted woods worn to bare wood near board ends.
		var key := tex.resource_path.get_file().get_basename()
		var dir := tex.resource_path.get_base_dir()
		var set := dir.get_file()
		m.set_shader_parameter(&"fixed_squares", true)
		if set == WOODS_SET:
			# The game's woods keep to the world's texel grid at a fixed multiple of it (128 a
			# metre at the default 32), so F7's texel size and the mipmap setting move them too.
			m.set_meta(&"texels_scale", lab_density(key, set) / DRAWN_TEXELS)
			m.set_shader_parameter(&"square_texels", WOODS_SQUARE)
			m.set_shader_parameter(&"end_square_texels", WOODS_END_SQUARE)
		else:
			m.set_meta(&"texels", lab_density(key, set))
			m.set_meta(&"mipmaps", true)
		m.set_shader_parameter(&"edge_shade", 0.78)
		m.set_shader_parameter(&"edge_lip", 1.1)
		var end := "%s/%s_end.png" % [dir, _wood_of(key)]
		if ResourceLoader.exists(end):
			m.set_shader_parameter(&"end_tex", load(end))
			m.set_shader_parameter(&"use_end_tex", true)
		var et := float(_wood_info(set, key).get("end_texels", 0.0))
		if et > 0.0:
			m.set_meta(&"end_scale", et / lab_density(key, set))
			m.set_shader_parameter(&"end_texels", et)
		var bare := "%s/%s_bare.png" % [dir, _wood_of(key)]
		var wear := float(_wood_info(set, key).get("end_wear", 0.0))
		if wear > 0.0 and ResourceLoader.exists(bare):
			m.set_shader_parameter(&"wear_tex", load(bare))
			m.set_shader_parameter(&"end_wear", wear)
	elif tex and tex.resource_path.get_base_dir() == FACTORY_PATH.get_base_dir():
		# A factory tile at its own density (a multiple of the world's, so F7 moves it too).
		var fd := factory_density(tex.resource_path.get_file().get_basename())
		if fd > 0.0:
			m.set_meta(&"texels_scale", fd / DRAWN_TEXELS)
	return track(m)


## The same material with bullet holes (the hole uniforms are set by the member).
static func hole_material(base: ShaderMaterial) -> ShaderMaterial:
	var m := base.duplicate() as ShaderMaterial
	m.shader = hole_shader()
	for k in [&"texels", &"texels_scale", &"end_scale", &"mipmaps"]:
		if base.has_meta(k):
			m.set_meta(k, base.get_meta(k))
	return track(m)


## The grid shader for the look in force, and the holed one (either may be in use: compare with
## is_grid_shader / is_hole_shader, not with GRID_SHADER).
static func grid_shader() -> Shader:
	return GRID_SHADER_BLOCKS if blocks else GRID_SHADER


static func hole_shader() -> Shader:
	return HOLE_SHADER_BLOCKS if blocks else HOLE_SHADER


static func is_grid_shader(s: Shader) -> bool:
	return s == GRID_SHADER or s == GRID_SHADER_BLOCKS


static func is_hole_shader(s: Shader) -> bool:
	return s == HOLE_SHADER or s == HOLE_SHADER_BLOCKS


## Keep a material laid out on the texel grid (the ground's shader too: it reads texels_per_meter,
## and takes the texture factory's road).
static func track(m: ShaderMaterial) -> ShaderMaterial:
	_materials.append(m)
	_apply(m)
	if m.shader and m.shader.resource_path.ends_with("ground.gdshader"):
		var road := factory("road")
		m.set_shader_parameter(&"road_tex", road)
		m.set_shader_parameter(&"use_road_tex", road != null)
		var wide := factory("road_wide")
		m.set_shader_parameter(&"wide_tex", wide)
		m.set_shader_parameter(&"use_wide_tex", wide != null)
		var drawn := wide != null and wide.resource_path.contains("/drawn/")
		m.set_shader_parameter(&"keep_tracks", drawn)
		m.set_shader_parameter(&"road_texels", DRAWN_ROAD_TEXELS if drawn else 0.0)
		_street(m)
	return m


## The street's path in the ground shader, when its map and both earths (with their heights) are
## there and the look isn't the quantise-once trial.
static func _street(m: ShaderMaterial) -> void:
	var compact := factory("road_compact")
	var loose := factory("road_loose")
	var ok := not smooth and compact != null and loose != null and ResourceLoader.exists(STREET_MAP) \
			and ResourceLoader.exists(_height_path(compact)) and ResourceLoader.exists(_height_path(loose))
	m.set_shader_parameter(&"use_street", ok)
	if not ok:
		return
	m.set_shader_parameter(&"street_map", load(STREET_MAP))
	m.set_shader_parameter(&"compact_tex", compact)
	m.set_shader_parameter(&"loose_tex", loose)
	m.set_shader_parameter(&"compact_h", load(_height_path(compact)))
	m.set_shader_parameter(&"loose_h", load(_height_path(loose)))
	m.set_shader_parameter(&"earth_metres", float(compact.get_width()) / EARTH_TEXELS)
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(STREET_INFO)) if FileAccess.file_exists(STREET_INFO) else null
	if info is Dictionary:
		var a: Array = (info as Dictionary).get("area", [])
		if a.size() == 4:
			m.set_shader_parameter(&"street_area", Vector4(a[0], a[1], a[2], a[3]))
		m.set_shader_parameter(&"street_rut_range", float((info as Dictionary).get("rut_range", 0.12)))


static func _height_path(tex: Texture2D) -> String:
	return tex.resource_path.get_basename() + "_height.png"


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
	var tpm: float = m.get_meta(&"texels", texels_per_meter * float(m.get_meta(&"texels_scale", 1.0)))
	m.set_shader_parameter(&"texels_per_meter", tpm)
	if m.has_meta(&"end_scale"):
		m.set_shader_parameter(&"end_texels", tpm * float(m.get_meta(&"end_scale")))
	m.set_shader_parameter(&"use_mipmaps", m.get_meta(&"mipmaps", use_mipmaps))
	if smooth:
		m.set_shader_parameter(&"smooth_source", true)


## Filtering for StandardMaterial3Ds that follow the mipmap setting (people's baked garments).
static func texture_filter() -> BaseMaterial3D.TextureFilter:
	return BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS if use_mipmaps else BaseMaterial3D.TEXTURE_FILTER_NEAREST



const SIZE := 64

static var _cache := {}


## The texture factory's texture for `key` (an image-model painting cut to tiles at 64 texels a
## metre, any size: the grid material lays every texel at texels_per_meter), or null.
static func factory(key: String) -> Texture2D:
	if not use_factory:
		return null
	if lab and ResourceLoader.exists(LAB_PATH % [lab_set, key]):
		return load(LAB_PATH % [lab_set, key]) as Texture2D
	if lab and _lab_has(_wood_of(key)):
		# A wood the lab set paints is all the lab's: no falling back to production's strips past
		# the lab's last board (WoodMaterials counts strips until one is missing).
		return null
	if woods and not lab and not smooth and _set_woods(WOODS_SET).has(_wood_of(key)):
		# The game's woods: likewise all theirs.
		var wp := LAB_PATH % [WOODS_SET, key]
		return load(wp) as Texture2D if ResourceLoader.exists(wp) else null
	if use_drawn and not smooth and (bold or _wood_of(key) in DRAWN_ALWAYS) and ResourceLoader.exists(DRAWN_PATH % key):
		return load(DRAWN_PATH % key) as Texture2D
	var path := (SMOOTH_PATH if smooth else BOLD_PATH if bold else FACTORY_PATH) % key
	if (smooth or bold) and not ResourceLoader.exists(path):
		path = FACTORY_PATH % key
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## The wood a texture key names: "floor_b3" -> "floor" (a board strip's number dropped).
static func _wood_of(key: String) -> String:
	var i := key.rfind("_b")
	return key.substr(0, i) if i > 0 and key.substr(i + 2).is_valid_int() else key


## A look switch (M, I) reloads the scene: what was made for the old look must be made again
## (textures from another set, materials with another shader), so the caches are emptied.
static func reset_for_look() -> void:
	_cache.clear()
	_materials.clear()
	WoodMaterials.reset()


static func _from_factory(key: String) -> Texture2D:
	var tex := factory(key)
	if tex:
		_cache[key] = tex
	return tex


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
static func wood(key: String, base: Color, seed: int, knots := 2, cracks := 3, grain := 1.0) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	if _from_factory(key):
		return _cache[key]
	var shades := ramp(base, 6, 0.55)
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
			img.set_pixel(x, y, shades[_band(_mosaic(v, x, y, seed), shades.size())])
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
static func painted(key: String, paint: Color, timber: Color, seed: int, wear := 0.3) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	if _from_factory(key):
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
			var s := _band(_mosaic(streak * 0.8 + 0.2 * _noise(x, y, 4, 4, seed + 17), x, y, seed), shades.size())
			# paint lifts at the edge of a peel: a darker rim
			if peel < wear + 0.04:
				s = 0
			img.set_pixel(x, y, shades[s])
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Packed dirt: speckled, with scattered pebbles.
static func dirt(key: String, base: Color, seed: int) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	if _from_factory(key):
		return _cache[key]
	var shades := ramp(base, 5, 0.3)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for y in SIZE:
		for x in SIZE:
			var v := _noise(x, y, 16, 16, seed) * 0.6 + _noise(x, y, 4, 4, seed + 1) * 0.25 + rng.randf() * 0.15
			img.set_pixel(x, y, shades[_band(_mosaic(v, x, y, seed), shades.size())])
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
static func metal(key: String, base: Color, seed: int, mottle := 0.0) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	if _from_factory(key):
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
## Squares: a few close shades of `base`, each texel its own, with a broad wander under them (the
## street painting's hand and revolver: every square a shade off the next). `spread`: how far the
## shades reach either side of `base`.
static func squares(key: String, base: Color, seed: int, spread := 0.3) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var shades := ramp(base, 5, spread)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var v := _noise(x, y, 8, 8, seed) * 0.45 + _hash(x, y, seed + 7) * 0.55
			img.set_pixel(x, y, shades[_band(v, shades.size())])
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


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


## The painted blood marks (splats, stains, the pool, wounds), by PixelArt.blood's key.
const BLOOD_PATH := "res://assets/textures/blood/%s.png"

## Blood: an irregular blob in three reds, soaked darker in the middle. `hole` adds the dark
## punched hole of a bullet wound at the centre. Alpha is hard-edged (use alpha scissor).
static func blood(key: String, seed: int, hole := false, n := 32) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	# Painted in the game's hand where there's one (tools/textures/paint_blood.py, cut_blood.py).
	if use_factory and ResourceLoader.exists(BLOOD_PATH % key):
		_cache[key] = load(BLOOD_PATH % key)
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


## A pattern value v (0..1) at texel (x, y) with the mosaic laid over it.
static func _mosaic(v: float, x: int, y: int, seed: int) -> float:
	if mosaic <= 0.0:
		return v
	var patch := _noise(x, y, 32, 32, seed + 41) * 0.75 + _hash(posmod(x, SIZE), posmod(y, SIZE), seed + 43) * 0.25
	return lerpf(v, v * 0.5 + patch * 0.5 + (patch - 0.5) * 0.3, mosaic)


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
