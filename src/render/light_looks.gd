class_name LightLooks
extends Node
## The light pass's looks (issues #318, #321). The game's light is Sean's pick, B by day and C at
## night (config/looks/light_game.json): every dial the two looks set is blended from B's to C's as
## the sun goes down. 8 cycles it with today's old light and the three looks on their own, so
## they can still be compared where you stand: the game's -> today's -> A (subtle) -> B (middle)
## -> C (strong). Each look is a LookPreset file of dials (config/looks/light_a.json ...: the noon
## exposure and shade fill, the sky and haze, the grade, the finish, the saloon's lamps at night),
## applied by LookPreset; "today's" puts every address any of them sets back to what it read
## before. The choice outlasts Backspace's reset (a static); `--light-look=game|today|a|b|c` picks
## one for a run (the screenshots). Not saved.

const GAME := "res://config/looks/light_game.json"
const FILES := ["res://config/looks/light_a.json", "res://config/looks/light_b.json", "res://config/looks/light_c.json"]
const NAMES := ["the game's (B by day, C at night)", "today's old light", "A (subtle)", "B (middle)", "C (strong)"]
const ARG_NAMES := ["game", "today", "a", "b", "c"]
## How much the sun's blend must move before the dials are set again (and how often it's looked at).
const BLEND_STEP := 0.02
const CHECK_SECONDS := 0.25

## 0 the game's, 1 today's, 2 A, 3 B, 4 C.
static var current := 0
static var _from_args_done := false

## The look files as parsed (night_share reads light_game.json every CHECK_SECONDS and blend reads
## three of them each step); emptied by pick, so 8 reads them afresh.
static var _files := {}

var _blend := -1.0  # the day-to-night blend last applied (the game's light), -1 none yet
var _since := 0.0


func _ready() -> void:
	if not _from_args_done:
		_from_args_done = true
		for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
			if a.begins_with("--light-look="):
				current = maxi(0, ARG_NAMES.find(a.substr(13).to_lower()))
	pick.call_deferred(get_tree(), current)
	# A jump of the clock (7, the bridge's `time`, the screenshots' views) re-blends on the next frame.
	Events.hour_changed.connect(func(_h: int) -> void: _since = CHECK_SECONDS)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"light_look"):
		pick(get_tree(), (current + 1) % NAMES.size())
		_blend = -1.0
		var overlay := get_tree().root.find_child("DebugOverlay", true, false)
		if overlay and overlay.has_method("toast"):
			overlay.toast("Light: %s   (8 for the next, 7 the hour)" % NAMES[current])
	if current != 0:
		return
	_since += delta
	if _since < CHECK_SECONDS and _blend >= 0.0:
		return
	_since = 0.0
	var p := Prof.start()  # F3 and F12's frames: "else" (#491's stall was this, untimed)
	var t := night_share(get_tree())
	if _blend < 0.0 or absf(t - _blend) >= BLEND_STEP or (t != _blend and (t == 0.0 or t == 1.0)):
		_blend = t
		blend(get_tree(), t)
	Prof.stop(&"light_looks", p)


## Every address any look sets.
static func addresses() -> PackedStringArray:
	var out := PackedStringArray()
	var sets: Array = []
	for f: String in FILES:
		sets.append(LookPreset.load_file(f).get("values", {}))
	sets.append(LookPreset.load_file(GAME).get("night_values", {}))
	sets.append(LookPreset.load_file(GAME).get("day_values", {}))
	for values: Dictionary in sets:
		for a: String in values:
			if not a in out:
				out.append(a)
	return out


## 0 by day, 1 by night, between as the sun goes down (light_game.json's night_from_sun and
## night_full_sun, the sun's height).
static func night_share(tree: SceneTree) -> float:
	var clock := tree.get_first_node_in_group(&"day_cycle") as DayCycle
	if clock == null:
		return 0.0
	var game := _file(GAME)
	var y := clock.get_sun_direction().y
	return 1.0 - smoothstep(float(game.get("night_full_sun", -0.05)), float(game.get("night_from_sun", 0.26)), y)


## Today's light, then look `index` over it: 0 the game's (blended by the sun now), 2..4 A, B, C.
static func pick(tree: SceneTree, index: int) -> void:
	current = index
	_files.clear()
	LightGrade.batching = true
	for a in addresses():
		if LookPreset.defaults.has(a):
			LookPreset.set_value(tree, a, LookPreset.defaults[a])
	LightGrade.batching = false
	LightGrade.apply(tree)
	if index == 0:
		blend(tree, night_share(tree))
		warm_grades(tree)
	elif index >= 2:
		var preset := LookPreset.load_file(FILES[index - 2])
		preset.erase("hour")  # the look is for every hour; 7 moves the clock
		var missed := LookPreset.apply(tree, preset)
		if not missed.is_empty():
			print("[light look] not here: ", ", ".join(missed))


## The game's light at night share `t`: each dial the day and night looks set, blended. A dial only
## one of them sets is blended with what the game has without it (the first value read).
static func blend(tree: SceneTree, t: float) -> void:
	var values := blended(tree, t)
	LightGrade.batching = true
	for a: String in values:
		LookPreset.set_value(tree, a, values[a])
	LightGrade.batching = false
	LightGrade.apply(tree)


## What blend sets at night share `t` (address -> value), only the addresses starting `prefix`.
static func blended(tree: SceneTree, t: float, prefix := "") -> Dictionary:
	var game := _file(GAME)
	var day: Dictionary = _file(game.day).get("values", {}).duplicate()
	var night: Dictionary = _file(game.night).get("values", {}).duplicate()
	# The game's own night over the night look's (the saloon's room at night, light pass round 3).
	night.merge(game.get("night_values", {}), true)
	# And its own low sun over the day look's (the street at golden hour, round 4): dials that act
	# only while the sun is up, so they are day's at every share, not blended toward the night's.
	var day_values: Dictionary = game.get("day_values", {})
	day.merge(day_values, true)
	var day_only: Array = game.get("day_only", [])
	var steps := grade_steps()
	var out := {}
	for a: String in _union(day, night):
		if not a.begins_with(prefix):
			continue
		var k := t
		for p: String in day_only:
			if a.begins_with(p):
				k = 0.0
		if day_values.has(a):
			k = 0.0
		if a.begins_with("grade."):
			k = roundf(k * steps) / steps  # each step a lookup of its own, built once
		var base: Variant = LookPreset.defaults[a] if LookPreset.defaults.has(a) else LookPreset.get_value(tree, a)
		var from: Variant = day.get(a, base)
		var to: Variant = night.get(a, base)
		if from == null or to == null:
			continue
		out[a] = mix(from, to, k)
	return out


static func grade_steps() -> int:
	return maxi(1, int(_file(GAME).get("grade_steps", 4)))


## Every grade step's lookup built now (the game's light picked, at load), so the dusk blend only
## finds them: each is ~15-25 ms to build, a hitch at each step (#491).
static func warm_grades(tree: SceneTree) -> void:
	var steps := grade_steps()
	for i in steps + 1:
		var dials := LightGrade.dials.duplicate()
		var values := blended(tree, float(i) / steps, "grade.")
		for a: String in values:
			var key := a.substr(6)
			if dials.has(key):
				dials[key] = LookPreset._typed(values[a], dials[key])  # as set_value types it
		LightGrade.warm(dials)


static func _file(path: String) -> Dictionary:
	if not _files.has(path):
		_files[path] = LookPreset.load_file(path)
	return _files[path]


static func _union(a: Dictionary, b: Dictionary) -> Array:
	var out: Array = a.keys()
	for k in b:
		if not k in out:
			out.append(k)
	return out


## Two look values (numbers, colours or JSON arrays) mixed; anything else switches at the middle.
static func mix(a: Variant, b: Variant, t: float) -> Variant:
	if (a is float or a is int) and (b is float or b is int):
		return lerpf(float(a), float(b), t)
	if a is Color and b is Color:
		return (a as Color).lerp(b, t)
	if a is Array and b is Array and (a as Array).size() == (b as Array).size():
		var out := []
		for i in (a as Array).size():
			out.append(mix(a[i], b[i], t))
		return out
	if a is Color and b is Array:
		return mix([a.r, a.g, a.b, a.a], b, t)
	if a is Array and b is Color:
		return mix(a, [b.r, b.g, b.b, b.a], t)
	return b if t >= 0.5 else a
