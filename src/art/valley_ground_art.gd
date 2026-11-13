class_name ValleyGroundArt
extends RefCounted
## The valley's ground drawn real (#891): the material ValleyGround's blocks and the dug tiles wear
## (src/art/valley_ground.gdshader over six CC0 scans), and the ground map it reads
## (assets/textures/valley/ground_map_a.res, _b.res: tools/textures/valley_ground_map.gd), which the
## scatter (ValleyScatter) asks too: what road, water, pad, lot or rail bed is at a point.
## `ValleyGroundArt.main()` is the game's (made once); without its map (not baked) `ready` is false and
## the valley keeps its greybox colours.

const MAP_DIR := "res://assets/textures/valley/"
const SCANS := "res://assets/textures/scans/"
const SHADER := "res://src/art/valley_ground.gdshader"
const TUNING := "res://config/valley_ground_art.tres"
## Road classes in the map (tools/textures/valley_ground_map.gd).
enum { NO_ROAD, MAIN_STREET, TOWN_STREET, WAGON, LANE, TRACK, PATH }

var tuning: ValleyGroundArtTuning
var ready := false
## The ground's material (the blocks), and the dug tiles' (fresh loose earth by their COLOR.r).
var material: ShaderMaterial
var tile_material: ShaderMaterial
var width := 0
var depth := 0
var spacing := 2.0
var x0 := 0.0
var z0 := 0.0
var valley_json_sha256 := ""
## How long making it took (ms).
var load_ms := 0.0

var _a: Image
var _b: Image
var _a_data := PackedByteArray()
var _b_data := PackedByteArray()

static var _main: ValleyGroundArt


static func main() -> ValleyGroundArt:
	if _main == null:
		_main = ValleyGroundArt.new()
		_main.setup(load(TUNING) as ValleyGroundArtTuning)
	return _main


func setup(t: ValleyGroundArtTuning) -> void:
	var u := Time.get_ticks_usec()
	tuning = t if t else ValleyGroundArtTuning.new()
	if not ResourceLoader.exists(MAP_DIR + "ground_map_a.res"):
		push_warning("ValleyGroundArt: no ground map (godot --headless -s res://tools/textures/valley_ground_map.gd)")
		return
	_a = load(MAP_DIR + "ground_map_a.res") as Image
	_b = load(MAP_DIR + "ground_map_b.res") as Image
	if _a == null or _b == null:
		return
	width = _a.get_width()
	depth = _a.get_height()
	spacing = float(_a.get_meta(&"spacing", 2.0))
	x0 = float(_a.get_meta(&"x0", -2000.0))
	z0 = float(_a.get_meta(&"z0", -1400.0))
	valley_json_sha256 = String(_a.get_meta(&"valley_json_sha256", ""))
	_a_data = _a.get_data()
	_b_data = _b.get_data()
	material = _make(false)
	tile_material = _make(true)
	ready = true
	load_ms = (Time.get_ticks_usec() - u) / 1000.0


func _make(dug: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SHADER)
	m.set_shader_parameter(&"map_a", ImageTexture.create_from_image(_a))
	m.set_shader_parameter(&"map_b", ImageTexture.create_from_image(_b))
	m.set_shader_parameter(&"map_origin", Vector2(x0, z0))
	m.set_shader_parameter(&"map_size", Vector2(width, depth))
	m.set_shader_parameter(&"map_spacing", spacing)
	for layer: String in tuning.scans:
		var id := String(tuning.scans[layer])
		var dir := SCANS + id + "/"
		for role in ["albedo", "normal", "rough"]:
			var path: String = dir + role + ".jpg"
			if ResourceLoader.exists(path):
				m.set_shader_parameter(StringName(layer + "_" + role), load(path))
		m.set_shader_parameter(StringName(layer + "_m"), _metres(dir))
	for dial: String in ValleyGroundArtTuning.DIALS:
		m.set_shader_parameter(StringName(dial), tuning.get(dial))
	m.set_shader_parameter(&"dug_tile", dug)
	return m


func _metres(dir: String) -> float:
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + "meta.json")) if FileAccess.file_exists(dir + "meta.json") else null
	if meta is Dictionary and meta.get("metres") is Array and not (meta.metres as Array).is_empty():
		return float(meta.metres[0])
	return tuning.default_metres


# --- What's at a point (the scatter's rules) ---------------------------------------------------

func _index(x: float, z: float) -> int:
	var i := roundi((x - x0) / spacing)
	var j := roundi((z - z0) / spacing)
	if i < 0 or j < 0 or i >= width or j >= depth:
		return -1
	return j * width + i


## The nearest road at the bake point nearest (x, z): {across (m), half (m), class}; class NO_ROAD
## past MARGIN of any.
func road_at(x: float, z: float) -> Dictionary:
	var k := _index(x, z)
	if k < 0:
		return {"across": 0.0, "half": 0.0, "class": NO_ROAD}
	return {"across": _a_data.decode_half(k * 8), "half": _a_data.decode_half(k * 8 + 2),
		"class": roundi(_a_data.decode_half(k * 8 + 4))}


## Metres past the nearest road's edge (negative on it; INF with none near).
func off_road(x: float, z: float) -> float:
	var k := _index(x, z)
	if k < 0 or _a_data.decode_half(k * 8 + 4) < 0.5:
		return INF
	return absf(_a_data.decode_half(k * 8)) - _a_data.decode_half(k * 8 + 2)


## Metres to the nearest water's bed edge (0 in it; 60 and more far).
func water_at(x: float, z: float) -> float:
	var k := _index(x, z)
	return 60.0 if k < 0 else _a_data.decode_half(k * 8 + 6)


## The flags at (x, z): {pad, lot, rail, ford}, each true or false.
func flags_at(x: float, z: float) -> Dictionary:
	var k := _index(x, z)
	if k < 0:
		return {"pad": false, "lot": false, "rail": false, "ford": false}
	return {"pad": _b_data[k * 4] > 127, "lot": _b_data[k * 4 + 1] > 127, "rail": _b_data[k * 4 + 2] > 127,
		"ford": _b_data[k * 4 + 3] > 127}


## True where nothing should grow or lie: a road (and `clear` m past its edge), a pad, a town lot,
## the rail bed or a ford.
func kept_clear(x: float, z: float, clear := 1.0) -> bool:
	var k := _index(x, z)
	if k < 0:
		return true
	if _b_data[k * 4] > 127 or _b_data[k * 4 + 1] > 127 or _b_data[k * 4 + 2] > 127 or _b_data[k * 4 + 3] > 127:
		return true
	if _a_data.decode_half(k * 8 + 4) > 0.5:
		return absf(_a_data.decode_half(k * 8)) - _a_data.decode_half(k * 8 + 2) < clear
	return false
