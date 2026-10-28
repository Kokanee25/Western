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
const LOOK_VERSION := 6
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
## The smallest square a texel may draw on screen, in render pixels (tiles.gdshaderinc
## `tile_square`; project.godot's shader global, set from here).
const MIN_SQUARE_PX := 2.0
## The quantise-once look (Pixel-factory's plan A1, 2026-10-03; I toggles, saved; the world is
## rebuilt from the other textures, so the scene reloads): nothing is cut into squares before
## the screen mosaic: tile light off, no minimum square, the factory's paintings laid on smooth
## at four times the texels with no palette (assets/textures/smooth/), the Tripo man's paint
## without squares, and the mosaic averaging each block with the darks kept (dark_weight), soft
## edged, in blocks of QUANTISE_TUNING.block_in render pixels under a roof and block_out in the
## open (the saloon painting's blocks are ~4 px, the street's ~6 at 1280 wide).
## The surface-blocks look (docs/briefs/renderer.md; M toggles, saved, off by default until Sean's
## eye): the blocks are the surfaces' own texels with soft edges (`block_soft` render pixels of
## blend across an edge, tiles.gdshaderinc), the light on them in `light_bands` steps with each
## material's shade tint, no minimum square (distance softens into the mip), and the screen mosaic
## and the finish off. The world's materials take their shader when built, so the scene reloads.
## `--blocks` on the command line turns it on for a run without saving it (the screenshot and
## flicker tools).
## Hard block edges since the bold style (Sean, 2026-10-05): the street painting's squares are
## crisp (0.5 render pixels of blend read as fuzz beside it).
const BLOCK_SOFT := 0.0
## The smallest square a far texel draws under the bold look, in render pixels: far surfaces stay
## blocks, as the painting's do, rather than softening into the mip.
const BOLD_MIN_SQUARE_PX := 4.0
## The bold look's line between boards, in screen pixels (texel_grid.gdshaderinc `seam_px`): the
## street painting draws it a pixel or so wide and dark at any distance.
const BOLD_SEAM_PX := 1.3
## 0: smooth light on the blocks (each block flat, lit at its centre, so the light still steps
## square by square); the judge preferred it to 8 or 12 bands (rings on the table).
const LIGHT_BANDS := 0.0
## Soft texel edges under the probe mosaic (see probe_mosaic below): 2 did no better.
const PROBE_SOFT := 1.0
const QUANTISE_TUNING := {
	"depth_power": 0.5, "soft": 0.5, "average": 1.0, "dark_weight": 2.0,
	"block_in": 4.0, "block_out": 6.0,
}

## Size of the low-resolution 3D render before it is scaled up with hard pixels (NATIVE: the
## window's size).
var internal_resolution := RESOLUTION_PRESETS[0]
## Which of TILE_LOOKS (P).
var tile_look: StringName = &"square"
## Scale by whole numbers only (perfectly even pixels, may letterbox).
var integer_scaling := false
## The finish pass (FINISH_SOFTEN, FINISH_GRADIENT) on.
var finish := false
## The screen mosaic (MOSAIC_K, MOSAIC_STEPS): off by default since 2026-10-06 (Sean: "no
## filters, the look has to be the art": it cut the drawn textures and his face into blotches);
## O still turns it on to compare.
var mosaic := false
## The fire drawn from the simulated flipbooks (FireFlipbook, docs/briefs/fire-look.md "The next
## approach") in place of the drawn fire sheets: on by default since Sean kept them (2026-10-22,
## issue #216: "keep flames for now"); the look panel (N) still turns them off.
var fire_flipbooks := true
## The quantise-once look (QUANTISE_TUNING) on (I).
var quantise_once := false
var surface_blocks := false
## The probe mosaic (src/render/probe_mosaic.gdshader, ProbeMosaic; a trial, V toggles, not saved):
## the frame in blocks fixed to the world by direction from an origin snapped to a grid (texel
## splatting's idea as one pass over the frame), so they stay put when you turn and walk. It
## replaces the screen mosaic while it's on, and wants the quantise-once textures under it (V
## turns those on with it, and the surface blocks off). probe_texels: texels a cube face (384:
## 3.3 px blocks at the saloon shot's lens, 1280x720); probe_cell: metres between origins;
## probe_bands: OKLab light bands (0: smooth light; 14 bands made a block near a band's edge flip
## as you moved: four times the flicker, tools/probe_walk.py stability). Under it the textures'
## texel edges are soft (PROBE_SOFT render pixels of blend) and the frame is multisampled
## (ProbeMosaic.MSAA): it re-reads the frame at each block's middle, and a texel edge or an
## outline that jumps a pixel there makes the whole block jump; the two together took its
## flicker down by a third to two fifths.
var probe_mosaic := false
var probe_texels := 384.0
var probe_cell := 0.5
var probe_bands := 0.0
## Its soft texel edges (PROBE_SOFT; --probe-soft=px on the command line for a trial).
var probe_soft := PROBE_SOFT
## The quantise-once and surface-blocks switches as they were when V turned the probe on.
var _look_before_probe := {}
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
## The people's pure half of their tick on the worker pool (PeopleTick, more-cores step 4): the same
## game either way. In the settings file ([performance] people_threads, no panel yet); for one run,
## `-- --people-threads=on|off`.
var people_threads := PEOPLE_THREADS
const PEOPLE_THREADS := true
var _people_threads_file := PEOPLE_THREADS
## People far off ticking less often, each tick with the time they missed (PeopleTick's bands,
## more-cores step 4b). In the settings file ([performance] people_bands); for one run,
## `-- --people-bands=on|off`.
var people_bands := PEOPLE_BANDS
const PEOPLE_BANDS := true
var _people_bands_file := PEOPLE_BANDS
## Physics on its own thread (more-cores step 6): Jolt's step runs beside the idle frame and the
## draw instead of after the physics ticks. Godot reads it only at start, from `ENGINE_PATH`
## (project.godot's `application/config/project_settings_override`), so this is what this run has
## and `set_physics_thread` is for the next start. Off until Sean has played it; no panel or key.
## `-- --physics-thread=on|off` sets it for the next start.
var physics_thread: bool = ProjectSettings.get_setting("physics/3d/run_on_separate_thread", false)
## The renderer on its own thread (more-cores step 7, Godot's "Separate" thread model): the draw
## runs beside the next frame's ticks instead of after them. Read at start like the physics thread
## (`ENGINE_PATH`, `[rendering] driver/threads/thread_model=2`); this is what this run has, and
## `set_render_thread` is for the next start. Off until Sean has played it; no panel or key.
## `-- --render-thread=on|off` sets it for the next start. A script run (`-s`: the screenshot,
## golden, tour and lab tools read the drawn frame) never takes it from the file: it refuses to
## start (`_refuse_render_thread`); Godot's own `--render-thread separate` on its command line
## asks for it by name (the suite run under it, `perf_bench`).
var render_thread: bool = not RenderingServer.is_on_render_thread()
## Engine settings read at start, before any script runs (Godot's own keys, section by section).
const ENGINE_PATH := "user://engine.cfg"
const THREAD_MODEL_KEY := "rendering/driver/threads/thread_model"
const THREAD_MODEL_SEPARATE := 2


func _ready() -> void:
	# A look for one run, unsaved (the screenshot, flicker and pan tools): --blocks, --quantise-once.
	var args := OS.get_cmdline_user_args()
	if "--blocks" in args or "--quantise-once" in args:
		surface_blocks = "--blocks" in args
		quantise_once = "--quantise-once" in args
		autosave = false
	# The probe mosaic trial for one run (--probe-mosaic [--probe-bands=N]), with the smooth
	# textures it wants.
	if "--probe-mosaic" in args:
		probe_mosaic = true
		quantise_once = true
		surface_blocks = false
		autosave = false
		for a in args:
			if a.begins_with("--probe-bands="):
				probe_bands = float(a.substr(14))
			elif a.begins_with("--probe-soft="):
				probe_soft = float(a.substr(13))
		# A trial: the probe over the game's own squared textures, not the smooth set.
		if "--probe-squares" in args:
			quantise_once = false
	load_from_disk()
	for a in args:
		if a.begins_with("--people-threads="):
			people_threads = a.substr(17) == "on"
		elif a.begins_with("--people-bands="):
			people_bands = a.substr(15) == "on"
		elif a.begins_with("--physics-thread="):
			set_physics_thread(a.substr(17) == "on")
		elif a.begins_with("--render-thread="):
			set_render_thread(a.substr(16) == "on")
	_protect_speakers()
	_refuse_render_thread()
	if physics_thread and DisplayServer.get_name() != "headless":
		add_child(SoftBodyDraw.new())


## Physics on its own thread from the next start on (`ENGINE_PATH`); this run keeps what it has.
func set_physics_thread(on: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(ENGINE_PATH)
	cfg.set_value("physics", "3d/run_on_separate_thread", on)
	cfg.save(ENGINE_PATH)
	print("Physics thread %s from the next start (this run: %s)" % ["on" if on else "off", "on" if physics_thread else "off"])


## The renderer on its own thread from the next start on (`ENGINE_PATH`); this run keeps what it has.
func set_render_thread(on: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(ENGINE_PATH)
	# Godot's keys: 1 is "Safe" (drawn on the main thread, the default), 2 "Separate".
	cfg.set_value("rendering", "driver/threads/thread_model", THREAD_MODEL_SEPARATE if on else 1)
	cfg.save(ENGINE_PATH)
	print("Render thread %s from the next start (this run: %s)" % ["on" if on else "off", "on" if render_thread else "off"])


## A script run (`-s`) that got the render thread from `ENGINE_PATH` quits at once. The tools
## await `frame_post_draw` and read the viewport's texture: with the thread, Godot posts that signal
## a frame late (deferred from the render thread) and the read waits for the frame drawing then,
## so the image isn't the frame the tool set up. Godot's `--render-thread separate` on the command
## line leaves the project setting alone, so a run that asks for the thread by name goes on.
func _refuse_render_thread() -> void:
	if not render_thread or not ("-s" in OS.get_cmdline_args() or "--script" in OS.get_cmdline_args()):
		return
	if int(ProjectSettings.get_setting(THREAD_MODEL_KEY, 1)) != THREAD_MODEL_SEPARATE:
		return
	push_error("The render thread is on in %s (Settings.render_thread): the tools read the drawn frame and need it off. "
			% ProjectSettings.globalize_path(ENGINE_PATH)
			+ "Run with Godot's --render-thread safe, or ask for the thread by name with --render-thread separate.")
	get_tree().quit(1)


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
	mosaic = false
	mouse_sensitivity = 0.1
	stick_look_speed = 150.0
	touch_look_sensitivity = 0.25
	invert_y = false
	pixel_shading = false
	texels_per_meter = 32.0
	reduced_gore = false
	tile_look = &"square"
	quantise_once = false
	surface_blocks = false
	probe_mosaic = false
	probe_texels = 384.0
	probe_cell = 0.5
	probe_bands = 0.0
	probe_soft = PROBE_SOFT
	_look_before_probe = {}
	_apply_quantise()
	_apply_texels()
	_apply_tiles()
	changed.emit()


func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		# No file (a first run, CI, the tools): the look the command line asked for still takes
		# its shaders and textures (--blocks, --quantise-once and --probe-mosaic only set switches).
		_apply_quantise()
		_apply_texels()
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
	# A new key: the old "fire_flipbooks" was saved off with every setting while off was the default.
	set_fire_flipbooks(bool(cfg.get_value("video", "flipbook_fire", fire_flipbooks)), false)
	# 5: the screen mosaic, and the finish's softening (the default till then) off under it.
	if look_version < 5:
		finish = false
		mosaic = true
	# 6: no screen filter (the mosaic off), whatever was saved.
	if look_version < 6:
		mosaic = false
	if (look_version < 2 and is_equal_approx(texels_per_meter, 40.0)) \
			or (look_version < 3 and is_equal_approx(texels_per_meter, 64.0)):
		texels_per_meter = PixelArt.DENSITY_PRESETS[0][0]
	reduced_gore = cfg.get_value("content", "reduced_gore", reduced_gore)
	_people_threads_file = bool(cfg.get_value("performance", "people_threads", PEOPLE_THREADS))
	people_threads = _people_threads_file
	_people_bands_file = bool(cfg.get_value("performance", "people_bands", PEOPLE_BANDS))
	people_bands = _people_bands_file
	tile_look = StringName(cfg.get_value("video", "tile_look", tile_look))
	if not tile_look in TILE_LOOKS:
		tile_look = &"square"
	# A look asked for on the command line wins over the file's.
	var asked := OS.get_cmdline_user_args()
	if not ("--blocks" in asked or "--quantise-once" in asked or "--probe-mosaic" in asked):
		quantise_once = cfg.get_value("video", "quantise_once", quantise_once)
		surface_blocks = cfg.get_value("video", "surface_blocks", surface_blocks)
	_apply_quantise()
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
	cfg.set_value("video", "flipbook_fire", fire_flipbooks)
	cfg.set_value("video", "pixel_shading", pixel_shading)
	cfg.set_value("video", "texels_per_meter", texels_per_meter)
	cfg.set_value("video", "tile_look", String(tile_look))
	cfg.set_value("video", "quantise_once", quantise_once)
	cfg.set_value("video", "surface_blocks", surface_blocks)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "stick_look_speed", stick_look_speed)
	cfg.set_value("controls", "touch_look_sensitivity", touch_look_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("content", "reduced_gore", reduced_gore)
	cfg.set_value("performance", "people_threads", _people_threads_file)
	cfg.set_value("performance", "people_bands", _people_bands_file)
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


## The simulated fire's flipbooks on or off (FireFX.flipbooks; burning members change over as
## FireFX next refreshes them). Loaded by path: naming FireFX here would compile the fire's
## scripts with this autoload.
func set_fire_flipbooks(on: bool, save := true) -> void:
	fire_flipbooks = on
	load("res://src/fire/fire_fx.gd").flipbooks = on
	if save:
		_changed()


## V: the probe mosaic trial on or off. It looks as meant over the quantise-once textures and
## not over the surface blocks, so turning it on turns those on and these off (the scene reloads);
## off puts back the look you had before it (so V, M and neither can be compared in turn).
func set_probe_mosaic(on: bool) -> void:
	if on == probe_mosaic:
		_changed()
		return
	probe_mosaic = on
	if on:
		_look_before_probe = {"quantise_once": quantise_once, "surface_blocks": surface_blocks}
		if surface_blocks or not quantise_once:
			surface_blocks = false
			set_quantise_once(true)
			return
	elif not _look_before_probe.is_empty():
		var was := _look_before_probe
		_look_before_probe = {}
		if was["quantise_once"] != quantise_once or was["surface_blocks"] != surface_blocks:
			surface_blocks = was["surface_blocks"]
			set_quantise_once(was["quantise_once"])
			return
	_apply_tiles()
	_changed()


## Whether the probe mosaic is drawn: the trial's setting, unless the surface-blocks look is on.
func probe_active() -> bool:
	return probe_mosaic and not surface_blocks


## Whether the screen mosaic is drawn: the setting, unless the surface-blocks look is on (it has
## no screen pass) or the probe mosaic trial is (it takes the screen mosaic's place).
func mosaic_active() -> bool:
	return mosaic and not surface_blocks and not probe_active()


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
	return "%s · texels %d/m %s · tiles %s · mosaic %s · finish %s · shading %s%s" % [res, int(texels_per_meter),
			"smoothed" if PixelArt.use_mipmaps else "crisp", tile_look, "on" if mosaic_active() else "off", "on" if finish else "off",
			"on" if pixel_shading else "off", (" · quantise once" if quantise_once else "") + (" · surface blocks" if surface_blocks else "")] \
			+ (" · probe mosaic %d texels, %.2f m" % [int(probe_texels), probe_cell] if probe_active() else "")


func set_tile_look(look: StringName) -> void:
	tile_look = look if look in TILE_LOOKS else &"square"
	_apply_tiles()
	_changed()


func cycle_tile_look() -> void:
	set_tile_look(TILE_LOOKS[(TILE_LOOKS.find(tile_look) + 1) % TILE_LOOKS.size()])


## The shader globals every tiled material reads (src/render/tiles.gdshaderinc) for this look.
func tile_globals() -> Dictionary:
	return {&"tile_light": 1.0 if surface_blocks else (0.0 if tile_look == &"off" or quantise_once else 1.0),
			&"tile_ragged": TILE_RAGGED if tile_look == &"ragged" and not surface_blocks else 0.0,
			&"tile_gradient": FINISH_GRADIENT if finish and not surface_blocks else 0.0,
			&"min_square_px": BOLD_MIN_SQUARE_PX if surface_blocks else 0.0 if quantise_once else MIN_SQUARE_PX,
			&"block_soft": BLOCK_SOFT if surface_blocks else (probe_soft if probe_active() else 0.0),
			&"light_bands": LIGHT_BANDS if surface_blocks else 0.0,
			&"seam_px": BOLD_SEAM_PX if surface_blocks else 0.0}


func _apply_tiles() -> void:
	var g := tile_globals()
	for k: StringName in g:
		RenderingServer.global_shader_parameter_set(k, g[k])


func _apply_texels() -> void:
	var mip := true
	for p in PixelArt.DENSITY_PRESETS:
		if is_equal_approx(p[0], texels_per_meter):
			mip = p[1]
	# The smooth set has four times the texels (reduce.py SMOOTH_TEXELS): laid at four times the
	# density, the paintings cover the same metres.
	# The bold set (M) is cut at PixelArt.BOLD_TEXELS a metre and laid at it, crisp.
	if surface_blocks:
		PixelArt.set_density(PixelArt.BOLD_TEXELS, false)
		return
	PixelArt.set_density(texels_per_meter * (4.0 if quantise_once else 1.0), mip)


## I: the quantise-once look on or off. The world's materials take their textures when they are
## built, so the running scene reloads (a few seconds; you start again at the spawn).
func set_quantise_once(on: bool) -> void:
	quantise_once = on
	_apply_quantise()
	_apply_texels()
	_apply_tiles()
	_changed()
	if is_inside_tree() and get_tree().current_scene != null:
		get_tree().reload_current_scene.call_deferred()


## M: the surface-blocks look on or off; the scene reloads (the materials take their shader when
## they are built).
func set_surface_blocks(on: bool) -> void:
	surface_blocks = on
	_apply_quantise()
	_apply_texels()
	_apply_tiles()
	_changed()
	if is_inside_tree() and get_tree().current_scene != null:
		get_tree().reload_current_scene.call_deferred()


## What the look sets before any material is built: the smooth texture sets and the mosaic's knobs.
func _apply_quantise() -> void:
	PixelArt.reset_for_look()
	PixelArt.blocks = surface_blocks
	PixelArt.bold = surface_blocks
	PixelArt.smooth = quantise_once
	PeopleBodies.smooth_paint = quantise_once
	DepthMosaic.tuning = QUANTISE_TUNING.duplicate() if quantise_once else {}


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
