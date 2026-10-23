class_name LightLooks
extends Node
## The light pass's three looks (issue #318, Sean: "it looks too cheap, too indie"), switched on
## 8 so Sean can flip between them where he stands: today's light, A (subtle), B (middle), C
## (strong). Each is a LookPreset file of dials (config/looks/light_a.json ...: the noon exposure
## and shade fill, the sky and haze, the grade, the finish, the saloon's lamps at night), applied
## by LookPreset; "today" puts every address any of them sets back to what it read before. The
## choice outlasts Backspace's reset (a static); `--light-look=a|b|c` picks one for a run (the
## screenshots). Not saved: until Sean picks, every run starts with today's.

const FILES := ["res://config/looks/light_a.json", "res://config/looks/light_b.json", "res://config/looks/light_c.json"]
const NAMES := ["today's light", "A (subtle)", "B (middle)", "C (strong)"]

## 0 today, 1 A, 2 B, 3 C.
static var current := 0
static var _from_args_done := false


func _ready() -> void:
	if not _from_args_done:
		_from_args_done = true
		for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
			if a.begins_with("--light-look="):
				current = maxi(0, "-abc".find(a.substr(13).to_lower()))
	if current != 0:
		pick.call_deferred(get_tree(), current)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"light_look"):
		pick(get_tree(), (current + 1) % NAMES.size())
		var overlay := get_tree().root.find_child("DebugOverlay", true, false)
		if overlay and overlay.has_method("toast"):
			overlay.toast("Light: %s   (8 for the next, 7 the hour)" % NAMES[current])


## Every address any look sets.
static func addresses() -> PackedStringArray:
	var out := PackedStringArray()
	for f: String in FILES:
		for a: String in LookPreset.load_file(f).get("values", {}):
			if not a in out:
				out.append(a)
	return out


## Today's light, then look `index` (1..3) over it.
static func pick(tree: SceneTree, index: int) -> void:
	current = index
	for a in addresses():
		if LookPreset.defaults.has(a):
			LookPreset.set_value(tree, a, LookPreset.defaults[a])
	if index > 0:
		var preset := LookPreset.load_file(FILES[index - 1])
		preset.erase("hour")  # the look is for every hour; 7 moves the clock
		var missed := LookPreset.apply(tree, preset)
		if not missed.is_empty():
			print("[light look] not here: ", ", ".join(missed))
