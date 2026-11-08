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

const PATH := "res://config/material_library.json"
const SCANS := "res://assets/textures/scans/"
const DIALS := ["weathering", "value_jitter", "hue_jitter", "rough_jitter", "roughness_add",
		"normal_strength", "grime", "sun_fade", "streaks", "joint_dirt", "layer_new", "varnish",
		"specular_wood", "saw_marks"]

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


## The entry's fields for a part: the part's own (entry[role]) over the entry's.
static func for_role(e: Dictionary, role: StringName) -> Dictionary:
	var out := e.duplicate()
	var own = e.get(String(role), null)
	if own is Dictionary:
		out.merge(own, true)
	return out


## Sets a scan_wood.gdshader material from an entry at an age (0 new .. 1 old) for a part.
static func apply(m: ShaderMaterial, e: Dictionary, age: float, role: StringName) -> void:
	var r := for_role(e, role)
	var scans: Dictionary = r.get("scans", {})
	for slot in ["a", "a2", "b"]:
		var has: bool = scans.has(slot)
		if slot != "a":
			m.set_shader_parameter("has_" + slot, has)
		if not has:
			continue
		var s: Dictionary = scans[slot]
		var dir: String = SCANS + String(s["id"]) + "/"
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
	for t in ["tint_new", "tint_mid", "tint_old", "varnish_amber"]:
		if r.has(t):
			var c: Array = r[t]
			m.set_shader_parameter(t, Color(c[0], c[1], c[2]))
	for d in DIALS:
		if r.has(d):
			m.set_shader_parameter(d, float(r[d]))
	if r.has("wear_band"):
		m.set_shader_parameter("wear_band", Vector2(r["wear_band"][0], r["wear_band"][1]))
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
