extends Node
## Player-facing settings, kept in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
## F2 cycles through these. The first is the default look.
const RESOLUTION_PRESETS: Array[Vector2i] = [
	Vector2i(640, 360), Vector2i(480, 270), Vector2i(320, 180), Vector2i(960, 540), Vector2i(1280, 720),
]

## Size of the low-resolution 3D render before it is scaled up with hard pixels.
var internal_resolution := RESOLUTION_PRESETS[0]
## Scale by whole numbers only (perfectly even pixels, may letterbox).
var integer_scaling := false
## Degrees of turn per mouse count.
var mouse_sensitivity := 0.1
## Degrees per second at full stick deflection.
var stick_look_speed := 150.0
## Degrees per pixel of touch drag.
var touch_look_sensitivity := 0.25
var invert_y := false
## Pixel shading: banded colour levels and ordered dither on the final frame (F6).
var pixel_shading := false
## Tests turn this off so they never touch the player's settings file.
var autosave := true


func _ready() -> void:
	load_from_disk()


func reset_to_defaults() -> void:
	internal_resolution = RESOLUTION_PRESETS[0]
	integer_scaling = false
	mouse_sensitivity = 0.1
	stick_look_speed = 150.0
	touch_look_sensitivity = 0.25
	invert_y = false
	pixel_shading = false
	changed.emit()


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	internal_resolution = cfg.get_value("video", "internal_resolution", internal_resolution)
	integer_scaling = cfg.get_value("video", "integer_scaling", integer_scaling)
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	stick_look_speed = cfg.get_value("controls", "stick_look_speed", stick_look_speed)
	touch_look_sensitivity = cfg.get_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
	invert_y = cfg.get_value("controls", "invert_y", invert_y)
	pixel_shading = cfg.get_value("video", "pixel_shading", pixel_shading)
	changed.emit()


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "internal_resolution", internal_resolution)
	cfg.set_value("video", "integer_scaling", integer_scaling)
	cfg.set_value("video", "pixel_shading", pixel_shading)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "stick_look_speed", stick_look_speed)
	cfg.set_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.save(PATH)


func set_internal_resolution(resolution: Vector2i) -> void:
	internal_resolution = Vector2i(maxi(resolution.x, 64), maxi(resolution.y, 36))
	_changed()


func cycle_internal_resolution() -> void:
	var i := RESOLUTION_PRESETS.find(internal_resolution)
	set_internal_resolution(RESOLUTION_PRESETS[(i + 1) % RESOLUTION_PRESETS.size()])


func set_integer_scaling(on: bool) -> void:
	integer_scaling = on
	_changed()


func set_pixel_shading(on: bool) -> void:
	pixel_shading = on
	_changed()


func _changed() -> void:
	if autosave:
		save_to_disk()
	changed.emit()
