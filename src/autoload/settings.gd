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
## Cock the hammer automatically after each shot (an assist; the real thing is off).
var auto_cock := false
## Pixel shading: banded colour levels and ordered dither on the final frame (F6).
var pixel_shading := false
## Texture pixels per metre (F7); the chunky presets also turn off distance smoothing.
var texels_per_meter := 40.0
## Texel lighting (P): light, shadows and fog flat across each texture texel, like the blocks in
## the concept art, instead of smooth across it.
var texel_lighting := false
## Reduced gore: bad wounds show as dark soaked patches, the body never opens (F4).
var reduced_gore := false
## Tests turn this off so they never touch the player's settings file.
var autosave := true


func _ready() -> void:
	load_from_disk()
	_protect_speakers()


## The master output never clips and carries no sub-bass: a hard limiter just under full scale,
## and a cut below ~40 Hz (nothing small can play it anyway). Loud, deep moments (the shotgun, a
## building coming down) at full scale made a monitor's built-in speakers drop out and blank the
## screen with them.
func _protect_speakers() -> void:
	var master := AudioServer.get_bus_index(&"Master")
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) is AudioEffectHardLimiter:
			return
	var cut := AudioEffectHighPassFilter.new()
	cut.cutoff_hz = 40.0
	AudioServer.add_bus_effect(master, cut)
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.5
	limiter.pre_gain_db = -3.0
	AudioServer.add_bus_effect(master, limiter)


func reset_to_defaults() -> void:
	internal_resolution = RESOLUTION_PRESETS[0]
	integer_scaling = false
	mouse_sensitivity = 0.1
	stick_look_speed = 150.0
	touch_look_sensitivity = 0.25
	invert_y = false
	pixel_shading = false
	texels_per_meter = 40.0
	texel_lighting = false
	reduced_gore = false
	_apply_texels()
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
	texels_per_meter = cfg.get_value("video", "texels_per_meter", texels_per_meter)
	texel_lighting = cfg.get_value("video", "texel_lighting", texel_lighting)
	reduced_gore = cfg.get_value("content", "reduced_gore", reduced_gore)
	_apply_texels()
	changed.emit()


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "internal_resolution", internal_resolution)
	cfg.set_value("video", "integer_scaling", integer_scaling)
	cfg.set_value("video", "pixel_shading", pixel_shading)
	cfg.set_value("video", "texels_per_meter", texels_per_meter)
	cfg.set_value("video", "texel_lighting", texel_lighting)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "stick_look_speed", stick_look_speed)
	cfg.set_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("content", "reduced_gore", reduced_gore)
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


func cycle_texel_density() -> void:
	var presets := PixelArt.DENSITY_PRESETS
	var i := 0
	for j in presets.size():
		if is_equal_approx(presets[j][0], texels_per_meter):
			i = j
	texels_per_meter = presets[(i + 1) % presets.size()][0]
	_apply_texels()
	_changed()


## One line describing the current look, e.g.
## "640×360 · texels 40/m smoothed · texel lighting off · shading off".
func look_description() -> String:
	return "%d×%d · texels %d/m %s · texel lighting %s · shading %s" % [internal_resolution.x, internal_resolution.y,
			int(texels_per_meter), "smoothed" if PixelArt.use_mipmaps else "crisp", "on" if texel_lighting else "off",
			"on" if pixel_shading else "off"]


func set_texel_lighting(on: bool) -> void:
	texel_lighting = on
	PixelArt.set_texel_lighting(on)
	_changed()


func _apply_texels() -> void:
	var mip := true
	for p in PixelArt.DENSITY_PRESETS:
		if is_equal_approx(p[0], texels_per_meter):
			mip = p[1]
	PixelArt.set_density(texels_per_meter, mip)
	PixelArt.set_texel_lighting(texel_lighting)


func set_reduced_gore(on: bool) -> void:
	reduced_gore = on
	_changed()


func set_pixel_shading(on: bool) -> void:
	pixel_shading = on
	_changed()


func _changed() -> void:
	if autosave:
		save_to_disk()
	changed.emit()
