class_name MaterialLibrary
extends RefCounted
## The material library (#701, Sean 2026-11-08; docs/briefs/material-library.md): every material a
## building may use, each an entry of `config/material_library.json` with its id, family, class,
## scans and dials. Sean approves entries on the material lab's sample panels (SamplePanel,
## `tools/material_lab.gd --panels=FAMILY`); an entry's `approved` says which ages he passed.
## Buildings pick from this library only, once they're built again (#695, #660).
##
## A wood entry:
##   id, family ("wood"), class (rough | common | fine: SamplePanel.CLASSES), name, layout
##   (board_batten | vertical | lap | horizontal), board_w, board_t (metres), expose (lap),
##   nails (rows a board: 0, 1, 2), nail_at (0..1 of the half width from the middle),
##   scans: {a: {id, grain: "u"|"v"}, a2: ..., b: ...} (a the fresh scan, a2 its variant, b weathered),
##   tint_new, tint_mid, tint_old ([r, g, b] multipliers), and any of scan_wood.gdshader's dials
##   by name (varnish, weathering, grime, sun_fade, streaks, joint_dirt, value_jitter, ...).
##   `floor` and `rail` may hold the same fields for those parts (their own scans, tints, dials).
## A paint entry (family "paint", #721's paint round): `over` names the wood it's laid on, whose
## fields it takes under its own (`resolved`): its layout and boards may differ (trim boards, narrow
## inside boards; `panel_class` the panel's gaps and warp, e.g. a fine joinery's for boards inside); paint_color, paint_under ([r, g, b]) and the `paint_*` dials; `inside` for a coat
## indoors. A building takes a finish by its id, as a wood.
## A floor entry (family "floor", #825) is a wood with `traffic` (feet's wear: scan_wood's traffic map,
## `traffic_map` here); a furniture entry (family "furniture") a wood or paint with `furniture` (the
## joined piece's finish: rubbed arrises, pulls, dust) and scans mapped at a furniture board's scale.
## A floor, a wall and the furniture in one room never share an entry (`docs/briefs/prop-factory.md`,
## `experiments/building_lab/RECIPE.md`). `panel_class` the boards' class where `class` names the family.

const PATH := "res://config/material_library.json"
const SCANS := "res://assets/textures/scans/"
## 4K copies for the lab's sharp close-ups (git-ignored; pulled from the pool branch
## claude/salt-creek-material-panels-tjivo2-scans4k, #721). Used when `hi_res` and the scan is there.
const SCANS_HI := "res://assets/textures/scans4k/"
static var hi_res := false
const DIALS := ["weathering", "value_jitter", "hue_jitter", "rough_jitter", "roughness_add",
		"normal_strength", "grime", "sun_fade", "streaks", "joint_dirt", "layer_new", "varnish",
		"specular_wood", "saw_marks", "detail_bias", "weathered_bias", "weathered_grain", "albedo_bias",
		"grain_contrast", "eaves_m", "edge_shelter", "b_stochastic", "varnish_dark",
		"age_split", "checks", "end_rot", "contact", "arris",
		"paint", "paint_inside", "paint_chalk", "paint_fade", "paint_peel", "paint_crack", "paint_thin_new",
		"paint_thin", "paint_relief", "paint_brush", "paint_rough_new", "paint_yellow", "bead",
		"traffic", "furniture"]
## The eased edges (#873; scan_wood.gdshader's `edge_round`): each class's arris radius new and old, in
## metres. Planed common boards a couple of millimetres from the plane and handling, round as a
## thumb's edge after years of weather and hands; rough-sawn boards leave the saw near square, then
## splinter and wear rounder than any; fine joinery is eased just enough to take a polish and stays
## crisper. (Period practice: an arris "taken off" with a plane's stroke or two, Nicholson's Mechanic's
## Companion; wear and weathering rounding exposed edges, USDA Wood Handbook ch. 16.)
const EDGE_ROUND := {"rough": [0.0012, 0.007], "common": [0.002, 0.006], "fine": [0.0015, 0.0035]}
## Colours an entry may set ([r, g, b], sRGB as the shader's source_color).
const COLOURS := ["tint_new", "tint_mid", "tint_old", "varnish_amber", "paint_color", "paint_under", "paint_dust", "furniture_dust"]

static var _data: Dictionary = {}
static var _noise: NoiseTexture2D


static func data() -> Dictionary:
	if _data.is_empty():
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f:
			_data = JSON.parse_string(f.get_as_text())
	return _data


static func entries(family := "") -> Array:
	var out := []
	for e in data().get("entries", []):
		if family == "" or e.get("family", "") == family or e.get("class", "") == family:
			out.append(e)
	return out


static func entry(id: String) -> Dictionary:
	for e in data().get("entries", []):
		if e.get("id", "") == id:
			return e
	return {}


## The entry with what it lies `over` (a paint's wood) under its own fields; `wood_class` the wood's
## class (SamplePanel's sizes). A wood comes back as it is (and its class as `wood_class`).
static func resolved(e: Dictionary) -> Dictionary:
	if e.has("wood_class"):
		return e
	var out := e.duplicate()
	var base_id := String(e.get("over", ""))
	if base_id != "":
		out = entry(base_id).duplicate()
		out.merge(e, true)
		out["wood_class"] = e.get("panel_class", entry(base_id).get("class", "common"))
	else:
		out["wood_class"] = e.get("panel_class", e.get("class", "common"))
	return out


## The entry's fields for a part: the part's own (entry[role]) over the entry's.
static func for_role(e: Dictionary, role: StringName) -> Dictionary:
	var out := e.duplicate()
	var own = e.get(String(role), null)
	if own is Dictionary:
		out.merge(own, true)
	return out


## Sets a scan_wood.gdshader material from an entry at an age (0 new .. 1 old) for a part.
static func apply(m: ShaderMaterial, e: Dictionary, age: float, role: StringName) -> void:
	var r := for_role(resolved(e), role)
	var scans: Dictionary = r.get("scans", {})
	for slot in ["a", "a2", "b"]:
		var has: bool = scans.has(slot)
		if slot != "a":
			m.set_shader_parameter("has_" + slot, has)
		if not has:
			continue
		var s: Dictionary = scans[slot]
		var dir: String = scan_dir(String(s["id"]))
		m.set_shader_parameter("albedo_" + slot, load(dir + "albedo.jpg"))
		if ResourceLoader.exists(dir + "normal.jpg"):
			m.set_shader_parameter("normal_" + slot, load(dir + "normal.jpg"))
		if ResourceLoader.exists(dir + "rough.jpg"):
			m.set_shader_parameter("rough_" + slot, load(dir + "rough.jpg"))
		m.set_shader_parameter("grain_v_" + slot, String(s.get("grain", "u")) == "v")
		m.set_shader_parameter("tile_" + slot, _tile(dir, s))
	# The variant at the fresh scan's mean colour, so a wall's boards differ by a board's worth,
	# not by two woods (the scans' meta.json `mean_linear`; `match_variants: false` keeps them apart).
	if scans.has("a") and scans.has("a2") and bool(r.get("match_variants", true)):
		var ma := _mean(SCANS + String(scans["a"]["id"]) + "/")
		var m2 := _mean(SCANS + String(scans["a2"]["id"]) + "/")
		m.set_shader_parameter("a2_gain", Vector3(ma.x / maxf(m2.x, 1e-4), ma.y / maxf(m2.y, 1e-4), ma.z / maxf(m2.z, 1e-4)))
	for t in COLOURS:
		if r.has(t):
			var c: Array = r[t]
			m.set_shader_parameter(t, Color(c[0], c[1], c[2]))
	for d in DIALS:
		if r.has(d):
			m.set_shader_parameter(d, float(r[d]))
	if r.has("wear_band"):
		m.set_shader_parameter("wear_band", Vector2(r["wear_band"][0], r["wear_band"][1]))
	# The eased edges' radius, new and old (#873): the entry's `edge_round` [new, old] (m), else its class's.
	var er: Array = r.get("edge_round", EDGE_ROUND.get(String(r.get("wood_class", "common")), EDGE_ROUND["common"]))
	m.set_shader_parameter("edge_round", Vector2(float(er[0]), float(er[1])))
	m.set_shader_parameter("age", age)
	m.set_shader_parameter("big_noise", noise())


## The metres a scan covers (along its grain, across): the entry's `metres`, else the scan's
## meta.json (the source's own size), else 2 m.
static func _tile(dir: String, s: Dictionary) -> Vector2:
	var mt = s.get("metres", null)
	if mt == null:
		var f := FileAccess.open(dir + "meta.json", FileAccess.READ)
		if f:
			mt = (JSON.parse_string(f.get_as_text()) as Dictionary).get("metres", null)
	if mt == null or (mt as Array).size() < 2:
		return Vector2(2.0, 2.0)
	var v := Vector2(float(mt[0]), float(mt[1]))
	# meta's metres are the image's (width, height); along the grain first.
	return v if String(s.get("grain", "u")) == "u" else Vector2(v.y, v.x)


## A scan's folder: the 4K copy when `hi_res` and it's there, else the repo's.
static func scan_dir(id: String) -> String:
	if hi_res and FileAccess.file_exists(SCANS_HI + id + "/albedo.jpg"):
		return SCANS_HI + id + "/"
	return SCANS + id + "/"


static func _mean(dir: String) -> Vector3:
	var f := FileAccess.open(dir + "meta.json", FileAccess.READ)
	if f:
		var mt = (JSON.parse_string(f.get_as_text()) as Dictionary).get("mean_linear", null)
		if mt is Array and (mt as Array).size() == 3:
			return Vector3(mt[0], mt[1], mt[2])
	return Vector3.ONE


## The large-scale layer's noise (seamless, the same every run).
static func noise() -> NoiseTexture2D:
	if _noise == null:
		var n := FastNoiseLite.new()
		n.seed = 701
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.012
		n.fractal_octaves = 4
		_noise = NoiseTexture2D.new()
		_noise.width = 512
		_noise.height = 512
		_noise.seamless = true
		_noise.generate_mipmaps = true
		_noise.noise = n
		_noise.normalize = true
	return _noise


# --- a floor's traffic (#825) ---------------------------------------------------------------------

## A floor's traffic map (scan_wood.gdshader's `traffic_map`), over a plane `size` metres (its own x, z),
## a texel every `px` metres. R where feet go: each way [a, b, weight] (Vector2s in the plane's metres)
## a band `width` wide, feathered at its sides, ways summed as chances (where several cross, more); G by
## a wall: inside each room's rect [x0, z0, x1, z1], within `wall_m` of its sides, less where feet go.
static func traffic_image(size: Vector2, ways: Array, rooms: Array, px := 0.1, width := 0.75, wall_m := 0.5) -> Image:
	var w := maxi(2, ceili(size.x / px))
	var h := maxi(2, ceili(size.y / px))
	var feet := PackedFloat32Array()
	feet.resize(w * h)
	feet.fill(0.0)
	var hw := width * 0.5
	for way: Array in ways:
		var a: Vector2 = way[0]
		var b: Vector2 = way[1]
		var k := float(way[2]) if way.size() > 2 else 1.0
		var ab := b - a
		var l2 := maxf(ab.length_squared(), 1e-6)
		var i0 := clampi(floori((minf(a.x, b.x) - hw) / px), 0, w - 1)
		var i1 := clampi(ceili((maxf(a.x, b.x) + hw) / px), 0, w - 1)
		var j0 := clampi(floori((minf(a.y, b.y) - hw) / px), 0, h - 1)
		var j1 := clampi(ceili((maxf(a.y, b.y) + hw) / px), 0, h - 1)
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				var p := Vector2((i + 0.5) * px, (j + 0.5) * px)
				var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
				var d := p.distance_to(a + ab * t) / hw
				if d >= 1.0:
					continue
				var v := k * (1.0 - smoothstep(0.3, 1.0, d))
				var at := j * w + i
				feet[at] = 1.0 - (1.0 - feet[at]) * (1.0 - v)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for j in h:
		for i in w:
			var p := Vector2((i + 0.5) * px, (j + 0.5) * px)
			var g := 0.0
			for r: Array in rooms:
				if p.x < r[0] or p.x > r[2] or p.y < r[1] or p.y > r[3]:
					continue
				var d := minf(minf(p.x - r[0], r[2] - p.x), minf(p.y - r[1], r[3] - p.y))
				g = maxf(g, 1.0 - smoothstep(0.05, wall_m, d))
			var f := feet[j * w + i]
			img.set_pixel(i, j, Color(f, g * (1.0 - f), 0.0))
	return img


## Sets a scan_wood material's traffic map: `img` over the plane whose (0, 0) is `origin` in the world,
## its x along `ax` and its z along `az` (unit vectors in the world), `size` metres, for the floor at
## world height `y` (other levels over the same plane keep a patchy wear only).
static func set_traffic(m: ShaderMaterial, img: Image, origin: Vector3, ax: Vector3, az: Vector3, size: Vector2, y: float) -> void:
	m.set_shader_parameter(&"has_traffic_map", true)
	m.set_shader_parameter(&"traffic_map", ImageTexture.create_from_image(img))
	m.set_shader_parameter(&"traffic_origin", origin)
	m.set_shader_parameter(&"traffic_u", ax.normalized() / maxf(size.x, 0.01))
	m.set_shader_parameter(&"traffic_v", az.normalized() / maxf(size.y, 0.01))
	m.set_shader_parameter(&"traffic_y", y)
