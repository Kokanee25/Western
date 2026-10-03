extends Node
## Player-facing settings, kept in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
## The 3D render at the window's own size: no screen pixels, only the tiles on surfaces (the
## painting's look).
const NATIVE := Vector2i.ZERO
## F2 cycles through these. The first is the default look: native, the window's own size (Sean,
## 2026-10-02, docs/ART_REVIEW.md §8.8: the blocks are the textures' squares on the surfaces, and
## a 1.5x nearest upscale only smeared them); then 1280x720 and down.
const RESOLUTION_PRESETS: Array[Vector2i] = [
	NATIVE, Vector2i(1280, 720), Vector2i(960, 540), Vector2i(640, 360), Vector2i(480, 270), Vector2i(320, 180),
]
## Bumped when the default look changes: a settings file from before keeps the player's choices
## but moves an old default resolution to the new one.
const LOOK_VERSION := 5
## The finish (docs/ART_REVIEW.md §8.7): block edges softened by about a render pixel
## (pixel_screen.gdshader `finish_soften`) and a faint gradient of the real lighting across each
## tile (tiles.gdshaderinc `tile_gradient`). Off by default since the screen mosaic (2026-10-03):
## the softening blurs its block edges.
const FINISH_SOFTEN := 0.5
const FINISH_GRADIENT := 0.3
## The painting's mosaic in screen space (src/render/depth_mosaic.gdshader, DepthMosaic on the
## game camera): the lit frame in blocks of about MOSAIC_K / depth render pixels (3-4 px on a man
## across a table, 2 px far off, at 1280 wide), one colour each, the light in MOSAIC_STEPS tones.
const MOSAIC_K := 5.0
const MOSAIC_STEPS := 14.0
## Mosaic tiles (P cycles): "off" = smooth light; "square" = every texel a tile lit as one colour;
## "ragged" = the same with uneven tile edges, like dabs of paint (src/render/tiles.gdshaderinc).
## The world, people and props all follow it.
const TILE_LOOKS: Array[StringName] = [&"off", &"square", &"ragged"]
## How far a ragged tile's centre wanders, in tiles.
const TILE_RAGGED := 0.3

## Size of the low-resolution 3D render before it is scaled up with hard pixels (NATIVE: the
## window's size).
var internal_resolution := RESOLUTION_PRESETS[0]
## Which of TILE_LOOKS (P).
var tile_look: StringName = &"square"
## Scale by whole numbers only (perfectly even pixels, may letterbox).
var integer_scaling := false
## The finish pass (FINISH_SOFTEN, FINISH_GRADIENT) on.
var finish := false
## The screen mosaic (MOSAIC_K, MOSAIC_STEPS) on.
var mosaic := true
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
var texels_per_meter := 32.0
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
	finish = false
	mosaic = true
	mouse_sensitivity = 0.1
	stick_look_speed = 150.0
	touch_look_sensitivity = 0.25
	invert_y = false
	pixel_shading = false
	texels_per_meter = 32.0
	reduced_gore = false
	tile_look = &"square"
	_apply_texels()
	_apply_tiles()
	changed.emit()


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		_apply_tiles()
		return
	internal_resolution = cfg.get_value("video", "internal_resolution", internal_resolution)
	var look_version := int(cfg.get_value("video", "look_version", 1))
	integer_scaling = cfg.get_value("video", "integer_scaling", integer_scaling)
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	stick_look_speed = cfg.get_value("controls", "stick_look_speed", stick_look_speed)
	touch_look_sensitivity = cfg.get_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
	invert_y = cfg.get_value("controls", "invert_y", invert_y)
	pixel_shading = cfg.get_value("video", "pixel_shading", pixel_shading)
	texels_per_meter = cfg.get_value("video", "texels_per_meter", texels_per_meter)
	# Each step moves only what was the default then (2: 1280x720 and 64 texels; 3: 32 texels,
	# the painting's square size, 2026-10-02; 4: native).
	if look_version < 2 and internal_resolution == Vector2i(640, 360):
		internal_resolution = Vector2i(1280, 720)
	if look_version < 4 and internal_resolution == Vector2i(1280, 720):
		internal_resolution = NATIVE
	finish = cfg.get_value("video", "finish", finish)
	mosaic = cfg.get_value("video", "mosaic", mosaic)
	# 5: the screen mosaic, and the finish's softening (the default till then) off under it.
	if look_version < 5:
		finish = false
		mosaic = true
	if (look_version < 2 and is_equal_approx(texels_per_meter, 40.0)) \
			or (look_version < 3 and is_equal_approx(texels_per_meter, 64.0)):
		texels_per_meter = PixelArt.DENSITY_PRESETS[0][0]
	reduced_gore = cfg.get_value("content", "reduced_gore", reduced_gore)
	tile_look = StringName(cfg.get_value("video", "tile_look", tile_look))
	if not tile_look in TILE_LOOKS:
		tile_look = &"square"
	_apply_texels()
	_apply_tiles()
	changed.emit()


func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "internal_resolution", internal_resolution)
	cfg.set_value("video", "look_version", LOOK_VERSION)
	cfg.set_value("video", "integer_scaling", integer_scaling)
	cfg.set_value("video", "finish", finish)
	cfg.set_value("video", "mosaic", mosaic)
	cfg.set_value("video", "pixel_shading", pixel_shading)
	cfg.set_value("video", "texels_per_meter", texels_per_meter)
	cfg.set_value("video", "tile_look", String(tile_look))
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "stick_look_speed", stick_look_speed)
	cfg.set_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("content", "reduced_gore", reduced_gore)
	cfg.save(PATH)


func set_internal_resolution(resolution: Vector2i) -> void:
	internal_resolution = NATIVE if resolution == NATIVE else Vector2i(maxi(resolution.x, 64), maxi(resolution.y, 36))
	_changed()


## The size the 3D actually renders at in a window this big.
func render_size(window: Vector2) -> Vector2i:
	if internal_resolution == NATIVE:
		return Vector2i(maxi(int(window.x), 64), maxi(int(window.y), 36))
	return internal_resolution


func cycle_internal_resolution() -> void:
	var i := RESOLUTION_PRESETS.find(internal_resolution)
	set_internal_resolution(RESOLUTION_PRESETS[(i + 1) % RESOLUTION_PRESETS.size()])


func set_integer_scaling(on: bool) -> void:
	integer_scaling = on
	_changed()


func set_finish(on: bool) -> void:
	finish = on
	_apply_tiles()
	_changed()


func set_mosaic(on: bool) -> void:
	mosaic = on
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


## One line describing the current look, e.g. "1280×720 · texels 32/m smoothed · tiles square · shading off".
func look_description() -> String:
	var res := "native" if internal_resolution == NATIVE else "%d×%d" % [internal_resolution.x, internal_resolution.y]
	return "%s · texels %d/m %s · tiles %s · mosaic %s · finish %s · shading %s" % [res, int(texels_per_meter),
			"smoothed" if PixelArt.use_mipmaps else "crisp", tile_look, "on" if mosaic else "off", "on" if finish else "off",
			"on" if pixel_shading else "off"]


func set_tile_look(look: StringName) -> void:
	tile_look = look if look in TILE_LOOKS else &"square"
	_apply_tiles()
	_changed()


func cycle_tile_look() -> void:
	set_tile_look(TILE_LOOKS[(TILE_LOOKS.find(tile_look) + 1) % TILE_LOOKS.size()])


## The shader globals every tiled material reads (src/render/tiles.gdshaderinc) for this look.
func tile_globals() -> Dictionary:
	return {&"tile_light": 0.0 if tile_look == &"off" else 1.0,
			&"tile_ragged": TILE_RAGGED if tile_look == &"ragged" else 0.0,
			&"tile_gradient": FINISH_GRADIENT if finish else 0.0}


func _apply_tiles() -> void:
	var g := tile_globals()
	for k: StringName in g:
		RenderingServer.global_shader_parameter_set(k, g[k])


func _apply_texels() -> void:
	var mip := true
	for p in PixelArt.DENSITY_PRESETS:
		if is_equal_approx(p[0], texels_per_meter):
			mip = p[1]
	PixelArt.set_density(texels_per_meter, mip)


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
