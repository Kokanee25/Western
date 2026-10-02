class_name Backdrop
extends Node3D
## The country round Salt Creek as a painted backdrop, as in docs/concept/street-golden-hour.png:
## red-rock spires and mesas far off, nearer hills, then foothills with junipers, each a 360-degree
## strip the image model painted and tools/textures/reduce_backdrop.py cut to squares
## (assets/textures/backdrop_<layer>.png + backdrop.json), stood on its own ring round the town
## (the far one 650 m out, inside the camera's 800 m) so they slide past each other a little as you
## walk. The big cathedral spires stand at the end of the street, where the painting has them.
## Lit by the time of day in backdrop.gdshader (gold rims at sunset, dark at night); no shadows,
## no collision (it's scenery miles off).

const SHADER := preload("res://src/art/backdrop.gdshader")
const INFO_PATH := "res://assets/textures/backdrop.json"
const TEXTURES := "res://assets/textures/%s"
## The ring's middle: the middle of the street between the store and the far false fronts.
const CENTRE := Vector3(-15.0, 0.0, -8.4)
## The eye height the strip's angles are measured from.
const EYE := 1.6
## Columns round the ring (a quad a degree) and degrees between rows (tan isn't straight).
const COLUMNS := 360
const ROW_DEGREES := 2.0

var layers: Array[MeshInstance3D] = []
var _materials: Array[ShaderMaterial] = []
var _day: DayCycle
var _env: Environment


func _ready() -> void:
	var info := load_info()
	var names: Array = (info.get("layers", {}) as Dictionary).keys()
	for lid: String in names:
		var layer: Dictionary = info.layers[lid]
		var path := TEXTURES % layer.texture
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.set_shader_parameter(&"albedo_tex", tex)
		m.set_shader_parameter(&"texels", Vector2(tex.get_width(), tex.get_height()))
		m.set_shader_parameter(&"centre", CENTRE)
		m.set_shader_parameter(&"haze", float(layer.haze))
		var mi := MeshInstance3D.new()
		mi.name = "Layer_" + lid
		mi.mesh = ring(float(layer.radius), float(layer.bottom), float(layer.top))
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = CENTRE
		add_child(mi)
		layers.append(mi)
		_materials.append(m)
	_day = get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	var we := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	_env = we.environment if we else null
	_light()


static func load_info() -> Dictionary:
	if not FileAccess.file_exists(INFO_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(INFO_PATH))
	return parsed if parsed is Dictionary else {}


## Where bearing `deg` points (degrees round from the town's middle, increasing to the right as you
## look out: 270 is west, down the street).
static func direction(deg: float) -> Vector3:
	var r := deg_to_rad(deg)
	return Vector3(sin(r), 0.0, -cos(r))


## A ring of `radius` metres whose rows run from `bottom` to `top` degrees above the horizon as
## seen from the middle at eye height; u round by bearing (0..1 for 0..360), v down from the top.
static func ring(radius: float, bottom: float, top: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := maxi(int(ceil((top - bottom) / ROW_DEGREES)), 1)
	for c in COLUMNS:
		var b0 := 360.0 * c / COLUMNS
		var b1 := 360.0 * (c + 1) / COLUMNS
		for r in rows:
			var a0 := lerpf(bottom, top, float(r) / rows)
			var a1 := lerpf(bottom, top, float(r + 1) / rows)
			var q := [[b0, a0], [b1, a0], [b1, a1], [b0, a1]]
			for k in [0, 1, 2, 0, 2, 3]:
				var b: float = q[k][0]
				var a: float = q[k][1]
				var d := direction(b)
				st.set_normal(-d)
				st.set_uv(Vector2(b / 360.0, (top - a) / (top - bottom)))
				st.add_vertex(d * radius + Vector3.UP * (EYE + radius * tan(deg_to_rad(a))))
	return st.commit()


func _process(_delta: float) -> void:
	_light()


## The time of day onto every layer: DayCycle's sun and its colour, the daylight, the fog's colour.
func _light() -> void:
	if _materials.is_empty():
		return
	var sun := Vector3(0.0, 1.0, 0.0)
	var sun_color := Color.WHITE
	var daylight := 1.0
	if _day:
		sun = _day.get_sun_direction()
		daylight = _day.get_daylight()
		if _day.config and _day.config.sun_color:
			sun_color = _day.config.sun_color.sample(_day.time_of_day / 24.0)
	var haze := _env.fog_light_color if _env else Color(0.8, 0.7, 0.6)
	for m in _materials:
		m.set_shader_parameter(&"sun_dir", sun)
		m.set_shader_parameter(&"sun_color", Vector3(sun_color.r, sun_color.g, sun_color.b))
		m.set_shader_parameter(&"daylight", daylight)
		m.set_shader_parameter(&"haze_color", Vector3(haze.r, haze.g, haze.b))
