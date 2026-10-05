class_name LookPreset
## A look as data: the settings that change how the game looks, read from and applied to the
## running game. A preset is JSON ({"name", "hour", "settings", "globals", "environment",
## "day_cycle"}); `user://looks/<name>.json` holds the look panel's, the dev bridge's `preset`
## command and `tools/apply_look.gd` apply one. Colours are [r, g, b, a] in the JSON.
##
## - settings: properties of the Settings autoload (mosaic, tile_look, texels_per_meter...)
## - globals: shader globals (project.godot [shader_globals]: min_square_px, tile_gradient...)
## - environment: properties of the street's WorldEnvironment's Environment (glow_*, fog_*,
##   adjustment_*, tonemap_*, ssao_*...)
## - day_cycle: properties of the DayCycle's config (DayCycleConfig: exposure_*, ambient_*,
##   fog_*, sun_*...)
## - hour: the time of day to show it at.

const DIR := "user://looks"


## Set one value by its address: "settings.<prop>", "global.<name>", "env.<prop>", "day.<prop>",
## or "hour". `tree` finds the street. False if the address names nothing.
static func set_value(tree: SceneTree, address: String, value: Variant) -> bool:
	var group := address.get_slice(".", 0)
	var key := address.substr(group.length() + 1)
	match group:
		"hour":
			var clock := _clock(tree)
			if clock == null:
				return false
			clock.set_time(float(value))
			return true
		"settings":
			var settings := tree.root.get_node_or_null(^"Settings")
			if settings == null or not key in settings:
				return false
			var v: Variant = _typed(value, settings.get(key))
			if settings.get(key) == v:
				return true  # unchanged (set_quantise_once would reload the scene for nothing)
			# Settings' own setter where there is one: it applies the globals and textures.
			if settings.has_method("set_" + key):
				settings.call("set_" + key, v)
			else:
				settings.set(key, v)
				settings.emit_signal(&"changed")
			return true
		"global":
			if not ProjectSettings.has_setting("shader_globals/" + key):
				return false
			RenderingServer.global_shader_parameter_set(StringName(key), _typed(value, RenderingServer.global_shader_parameter_get(StringName(key))))
			return true
		"env":
			var env := environment(tree)
			if env == null or not key in env:
				return false
			env.set(key, _typed(value, env.get(key)))
			return true
		"day":
			var clock := _clock(tree)
			if clock == null or not key in clock.config:
				return false
			clock.config.set(key, _typed(value, clock.config.get(key)))
			clock.set_time(clock.time_of_day)  # applied now, not at the next sky update
			return true
	return false


## Read one value by its address (as set_value takes it). Null if it names nothing.
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
			return RenderingServer.global_shader_parameter_get(StringName(key)) if ProjectSettings.has_setting("shader_globals/" + key) else null
		"env":
			var env := environment(tree)
			return env.get(key) if env and key in env else null
		"day":
			var clock := _clock(tree)
			return clock.config.get(key) if clock and key in clock.config else null
	return null


## Apply a preset (a parsed JSON dictionary). Returns the addresses it couldn't set.
static func apply(tree: SceneTree, preset: Dictionary) -> PackedStringArray:
	var missed := PackedStringArray()
	for group: String in ["settings", "globals", "environment", "day_cycle"]:
		var prefix: String = {"settings": "settings", "globals": "global", "environment": "env", "day_cycle": "day"}[group]
		for key: String in preset.get(group, {}):
			if not set_value(tree, "%s.%s" % [prefix, key], preset[group][key]):
				missed.append("%s.%s" % [prefix, key])
	if preset.has("hour"):
		set_value(tree, "hour", preset.hour)
	return missed


static func load_file(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


static func save_file(preset: Dictionary, name: String) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := "%s/%s.json" % [DIR, name.validate_filename()]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(to_json(preset))
	return path


static func to_json(preset: Dictionary) -> String:
	return JSON.stringify(_plain(preset), "  ", false)


## The street's environment (the one the game camera sees).
static func environment(tree: SceneTree) -> Environment:
	var we := tree.root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	return we.environment if we else null


static func _clock(tree: SceneTree) -> Node:
	return tree.root.find_child("DayCycle", true, false)


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
	if like is StringName and value is String:
		return StringName(value)
	return value


## Godot values as plain JSON (colours and vectors as arrays).
static func _plain(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k in v:
			out[String(k)] = _plain(v[k])
		return out
	if v is Array:
		return (v as Array).map(_plain)
	if v is Color:
		return [snappedf(v.r, 0.0001), snappedf(v.g, 0.0001), snappedf(v.b, 0.0001), snappedf(v.a, 0.0001)]
	if v is Vector3:
		return [v.x, v.y, v.z]
	if v is Vector2:
		return [v.x, v.y]
	if v is StringName:
		return String(v)
	return v
