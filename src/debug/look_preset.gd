class_name LookPreset
## A look as data: every setting that changes how the game looks, set and read by an address, and
## a preset as a set of them. The look panel (LookPanel), the dev bridge's `set`/`get`/`preset`
## commands and `--look=FILE` (the game, tools/screenshots.gd, any run of the main scene) all go
## through here. The settings and their ranges are the art session's list
## (docs/briefs/look_settings.md), laid out for the panel in config/look_panel.json.
##
## A preset is JSON: {"name": "...", "hour": 17.6, "values": {"<address>": value, ...}}; colours are
## [r, g, b, a]. `user://looks/<name>.json` holds the panel's.
##
## Addresses:
## - `hour`: the time of day
## - `settings.<prop>`: the Settings autoload (its setter if it has one: mosaic, tile_look, ...)
## - `global.<name>`: a shader global (project.godot [shader_globals]: min_square_px, ...)
## - `env.<prop>`: the street's Environment (glow_*, adjustment_*, ssao_*, fog_*, volumetric_fog_*)
## - `day.<prop>`: the DayCycle's config (exposure_*, ambient_*, sun_*, moon_*, fog_density...);
##   the DayCycle applies it every tick
## - `sun.<prop>`, `moon.<prop>`: the DayCycle's two DirectionalLight3Ds
## - `sky.<uniform>`: the sky's shader (sky.gdshader)
## - `ground.<uniform>`: the ground's shader (ground.gdshader)
## - `backdrop.<uniform>`: every ring of the painted backdrop (backdrop.gdshader)
## - `lamps.<group>.<energy|light_range|haze>`: a multiplier over every OilLamp in the group (all,
##   street, saloon) on the value it was built with
## - `building.<structure_id>.<night_ambient|room_haze>`: a building's night fill and room haze
## - `mosaic.<knob>`: the screen mosaic's knobs (DepthMosaic.KNOB_DEFAULTS, block_in, block_out)
## - `paint.<key>`: HumanBody.paint_look on every painted person

const DIR := "user://looks"
const LAMP_PROPS := ["energy", "light_range", "haze"]

## What every address read before anything set it this run (the panel's Reset goes back to it).
static var defaults := {}
## The lamp multipliers in force (they aren't a property anywhere to read back).
static var _lamp_scale := {}


## Set one value by its address. False if the address names nothing in this scene.
static func set_value(tree: SceneTree, address: String, value: Variant) -> bool:
	var was: Variant = get_value(tree, address)
	if was == null:
		return false
	if not defaults.has(address):
		defaults[address] = was
	var v: Variant = _typed(value, was)
	var group := address.get_slice(".", 0)
	var key := address.substr(group.length() + 1)
	match group:
		"hour":
			_clock(tree).set_time(float(v))
		"settings":
			var settings := tree.root.get_node(^"Settings")
			if settings.get(key) == v:
				return true  # unchanged (set_quantise_once would reload the scene for nothing)
			# Settings' own setter where there is one: it applies the globals and textures.
			if settings.has_method("set_" + key):
				settings.call("set_" + key, v)
			else:
				settings.set(key, v)
				settings.emit_signal(&"changed")
		"global":
			RenderingServer.global_shader_parameter_set(StringName(key), v)
		"env":
			environment(tree).set(key, v)
		"day":
			var clock := _clock(tree)
			clock.config.set(key, v)
			clock.set_time(clock.time_of_day)  # applied now
		"sun", "moon":
			_light(tree, group).set(key, v)
		"sky", "ground", "backdrop":
			for m in _materials(tree, group):
				m.set_shader_parameter(StringName(key), v)
		"lamps":
			var lamp_group := key.get_slice(".", 0)
			var prop := key.get_slice(".", 1)
			_lamp_scale[key] = float(v)
			for lamp in _lamps(tree, lamp_group):
				_scale_lamp(lamp, prop, float(v))
		"building":
			var b := _building(tree, key.get_slice(".", 0))
			var prop := key.get_slice(".", 1)
			b.set(prop, v)
			for c in b.get_children():
				if prop == "night_ambient" and c is ReflectionProbe and c.has_meta(&"night_ambient"):
					c.set_meta(&"night_ambient", v)
				elif prop == "room_haze" and c is FogVolume and (c as FogVolume).material is FogMaterial:
					((c as FogVolume).material as FogMaterial).density = v
			_clock(tree).set_time(_clock(tree).time_of_day)
		"mosaic":
			DepthMosaic.tuning[key] = v
			for m in tree.root.find_children("DepthMosaic", "", true, false):
				if m is DepthMosaic:
					if key == "block_in" or key == "block_out":
						m.set("_" + key, v)
						m.scene_blocks = DepthMosaic.tuning.has("block_in") and DepthMosaic.tuning.has("block_out")
					else:
						(m.material_override as ShaderMaterial).set_shader_parameter(StringName(key), v)
		"paint":
			HumanBody.paint_look[StringName(key)] = v
			for m in _paint_materials(tree):
				m.set_shader_parameter(StringName(key), v)
		_:
			return false
	return true


## Read one value by its address (as set_value takes it). Null if it names nothing here.
static func get_value(tree: SceneTree, address: String) -> Variant:
	var group := address.get_slice(".", 0)
	var key := address.substr(group.length() + 1)
	match group:
		"hour":
			var clock := _clock(tree)
			return clock.time_of_day if clock else null
		"settings":
			var settings := tree.root.get_node_or_null(^"Settings")
			return settings.get(key) if settings and key in settings else null
		"global":
			if not ProjectSettings.has_setting("shader_globals/" + key):
				return null
			var g: Variant = RenderingServer.global_shader_parameter_get(StringName(key))
			# The headless renderer keeps no globals: project.godot's value then.
			return g if g != null else (ProjectSettings.get_setting("shader_globals/" + key) as Dictionary).get("value")
		"env":
			var env := environment(tree)
			return env.get(key) if env and key in env else null
		"day":
			var clock := _clock(tree)
			return clock.config.get(key) if clock and key in clock.config else null
		"sun", "moon":
			var l := _light(tree, group)
			return l.get(key) if l and key in l else null
		"sky", "ground", "backdrop":
			var ms := _materials(tree, group)
			if ms.is_empty():
				return null
			var v: Variant = ms[0].get_shader_parameter(StringName(key))
			# A uniform left at its default reads back null: the default is in the shader's code.
			return v if v != null else uniform_default(ms[0].shader, key)
		"lamps":
			if not key.get_slice(".", 1) in LAMP_PROPS or _lamps(tree, key.get_slice(".", 0)).is_empty():
				return null
			return _lamp_scale.get(key, 1.0)
		"building":
			var b := _building(tree, key.get_slice(".", 0))
			var prop := key.get_slice(".", 1)
			return b.get(prop) if b and prop in b else null
		"mosaic":
			if DepthMosaic.tuning.has(key):
				return DepthMosaic.tuning[key]
			if key == "block_in" or key == "block_out":
				return Settings.QUANTISE_TUNING[key]
			return DepthMosaic.KNOB_DEFAULTS.get(key)
		"paint":
			return HumanBody.paint_look.get(StringName(key))
	return null


## A shader uniform's default, read from its code (and its includes): `uniform <type> name ... = value;`.
## Vectors come back as Colors (the look's are all colours). Null if it isn't there.
static func uniform_default(shader: Shader, name: String) -> Variant:
	if shader == null:
		return null
	var code := shader.code
	var inc := RegEx.create_from_string("#include\\s+\"([^\"]+)\"")
	for m in inc.search_all(shader.code):
		code += "\n" + FileAccess.get_file_as_string(m.get_string(1))
	var re := RegEx.create_from_string("uniform\\s+(\\w+)\\s+" + name + "\\b[^=;]*=\\s*([^;]+);")
	var hit := re.search(code)
	if hit == null:
		return null
	var type := hit.get_string(1)
	var text := hit.get_string(2).strip_edges()
	if type.begins_with("vec"):
		var nums := text.substr(text.find("(") + 1).trim_suffix(")").split(",")
		var f: Array[float] = []
		for n in nums:
			f.append(float(n))
		while f.size() < 3:
			f.append(f[0] if not f.is_empty() else 0.0)
		return Color(f[0], f[1], f[2], f[3] if f.size() > 3 else 1.0)
	if type == "int":
		return int(text)
	if type == "bool":
		return text == "true"
	return float(text)


## Apply a preset (a parsed JSON dictionary). Returns the addresses it couldn't set.
static func apply(tree: SceneTree, preset: Dictionary) -> PackedStringArray:
	var missed := PackedStringArray()
	var values: Dictionary = preset.get("values", {})
	for address: String in values:
		if not set_value(tree, address, values[address]):
			missed.append(address)
	if preset.has("hour"):
		set_value(tree, "hour", preset.hour)
	return missed


## The values at these addresses now, as a preset.
static func capture(tree: SceneTree, addresses: Array, name := "look") -> Dictionary:
	var values := {}
	for a: String in addresses:
		var v: Variant = get_value(tree, a)
		if v != null:
			values[a] = v
	var clock := _clock(tree)
	return {"name": name, "hour": snappedf(clock.time_of_day, 0.01) if clock else 12.0, "values": values}


## Everything set this run back to what it was.
static func reset(tree: SceneTree) -> void:
	for a: String in defaults.keys():
		if a != "hour":
			set_value(tree, a, defaults[a])


## A `--look=FILE` on the command line (after `--`): applied once the street is up.
static func apply_from_args(tree: SceneTree) -> void:
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--look="):
			var path := a.substr(7)
			var preset := load_file(path)
			if preset.is_empty():
				push_warning("--look: can't read %s" % path)
				return
			var missed := apply(tree, preset)
			print("[look] %s applied%s" % [path, "" if missed.is_empty() else "; not here: " + ", ".join(missed)])


static func load_file(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func save_file(preset: Dictionary, name: String) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := "%s/%s.json" % [DIR, name.validate_filename()]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(to_json(preset))
	return path


static func saved_names() -> PackedStringArray:
	var out := PackedStringArray()
	if not DirAccess.dir_exists_absolute(DIR):
		return out
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".json"):
			out.append(f.get_basename())
	return out


static func to_json(preset: Dictionary) -> String:
	return JSON.stringify(plain(preset), "  ", false)


## The street's environment (the one the game camera sees).
static func environment(tree: SceneTree) -> Environment:
	var we := tree.root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	return we.environment if we else null


static func _clock(tree: SceneTree) -> DayCycle:
	return tree.root.find_child("DayCycle", true, false) as DayCycle


static func _light(tree: SceneTree, which: String) -> DirectionalLight3D:
	var clock := _clock(tree)
	if clock == null:
		return null
	return clock.sun if which == "sun" else clock.moon


static func _materials(tree: SceneTree, which: String) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	match which:
		"sky":
			var env := environment(tree)
			if env and env.sky and env.sky.sky_material is ShaderMaterial:
				out.append(env.sky.sky_material)
		"ground":
			var g := tree.root.find_child("Ground", true, false)
			var mi := g.get_node_or_null(^"Mesh") as MeshInstance3D if g else null
			if mi:
				var m: Material = mi.material_override if mi.material_override else mi.get_active_material(0)
				if m is ShaderMaterial:
					out.append(m)
		"backdrop":
			var b := tree.root.find_child("Backdrop", true, false)
			if b and "_materials" in b:
				out.assign(b._materials)
	return out


static func _lamps(tree: SceneTree, group: String) -> Array[OilLamp]:
	var out: Array[OilLamp] = []
	for n in tree.root.find_children("*", "OilLamp", true, false):
		var lamp := n as OilLamp
		var in_saloon := false
		var p := lamp.get_parent()
		while p:
			if p is SaloonBuilding:
				in_saloon = true
				break
			p = p.get_parent()
		if group == "all" or (group == "saloon") == in_saloon:
			out.append(lamp)
	return out


static func _scale_lamp(lamp: OilLamp, prop: String, k: float) -> void:
	if not lamp.has_meta(&"base_" + prop):
		lamp.set_meta(&"base_" + prop, lamp.get(prop))
	var v: float = float(lamp.get_meta(&"base_" + prop)) * k
	lamp.set(prop, v)
	var light: OmniLight3D = lamp._light
	if light:
		match prop:
			"light_range":
				light.omni_range = v
			"haze":
				light.light_volumetric_fog_energy = v


static func _building(tree: SceneTree, id: String) -> Node:
	for n in tree.root.find_children("*", "FalseFrontBuilding", true, false):
		if String(n.get(&"structure_id")) == id:
			return n
	return null


## The body materials paint_look reaches: the painted pieces (they carry a uv_rect).
static func _paint_materials(tree: SceneTree) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for man in tree.get_nodes_in_group(&"people"):
		for mi in (man as Node).find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).material_override as ShaderMaterial
			if m and m.get_shader_parameter(&"uv_rect") != null and m.get_shader_parameter(&"paint_gain") != null:
				out.append(m)
	return out


## A JSON value made the type of the value it replaces (colours from arrays, ints from floats).
static func _typed(value: Variant, like: Variant) -> Variant:
	if like is Color and value is Array:
		var a: Array = value
		return Color(a[0], a[1], a[2], a[3] if a.size() > 3 else 1.0)
	if like is Color and value is String:
		return Color(value)
	if like is Vector3 and value is Array:
		return Vector3(value[0], value[1], value[2])
	if like is Vector2 and value is Array:
		return Vector2(value[0], value[1])
	if like is int and (value is float or value is String):
		return int(value)
	if like is float and (value is int or value is String):
		return float(value)
	if like is bool and value is String:
		return value == "true" or value == "1" or value == "on"
	if like is bool and (value is float or value is int):
		return value != 0
	if like is StringName and value is String:
		return StringName(value)
	return value


## Godot values as plain JSON (colours and vectors as arrays).
static func plain(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k in v:
			out[String(k)] = plain(v[k])
		return out
	if v is Array:
		return (v as Array).map(plain)
	if v is Color:
		return [snappedf(v.r, 0.0001), snappedf(v.g, 0.0001), snappedf(v.b, 0.0001), snappedf(v.a, 0.0001)]
	if v is Vector3:
		return [v.x, v.y, v.z]
	if v is Vector2:
		return [v.x, v.y]
	if v is StringName:
		return String(v)
	if v is float:
		return snappedf(v, 0.0001)
	return v
