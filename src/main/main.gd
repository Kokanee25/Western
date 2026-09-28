extends Node
## Owns the pixel pipeline: the 3D world renders into a low-resolution SubViewport (a setting,
## 640x360 by default) and is drawn to the window with nearest-neighbour scaling, so modern
## lighting happens at low resolution and reads as chunky pixels. Also turns mouse motion into
## look input and handles capturing the mouse.

@onready var game_viewport: SubViewport = $GameViewport
@onready var screen: TextureRect = $Screen


func _ready() -> void:
	screen.texture = game_viewport.get_texture()
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var post := ShaderMaterial.new()
	post.shader = preload("res://src/render/pixel_screen.gdshader")
	screen.material = post
	Settings.changed.connect(_apply_settings)
	get_viewport().size_changed.connect(_layout)
	_apply_settings()
	if not DisplayServer.is_touchscreen_available() and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_settings() -> void:
	game_viewport.size = Settings.internal_resolution
	var post := screen.material as ShaderMaterial
	post.set_shader_parameter(&"shading_enabled", Settings.pixel_shading)
	post.set_shader_parameter(&"source_size", Vector2(Settings.internal_resolution))
	_layout()


func _layout() -> void:
	var rect := fit_rect(get_viewport().get_visible_rect().size, Vector2(game_viewport.size), Settings.integer_scaling)
	screen.position = rect.position
	screen.size = rect.size


## Where the low-res frame goes in the window: as large as fits, same aspect, centred; with
## `integer` only whole-number scales (perfectly even pixels, may letterbox).
static func fit_rect(window: Vector2, source: Vector2, integer: bool) -> Rect2:
	var scale := minf(window.x / source.x, window.y / source.y)
	if integer and scale >= 1.0:
		scale = floorf(scale)
	var size := (source * scale).floor()
	return Rect2(((window - size) * 0.5).floor(), size)


func get_display_scale() -> float:
	return screen.size.x / float(game_viewport.size.x)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var motion := (event as InputEventMouseMotion).screen_relative * Settings.mouse_sensitivity
			var pitch := motion.y if Settings.invert_y else -motion.y
			Events.look_input.emit(Vector2(motion.x, pitch))
	elif event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed(&"debug_resolution"):
		Settings.cycle_internal_resolution()
	elif event.is_action_pressed(&"debug_texel_size"):
		PixelArt.cycle_density()
	elif event.is_action_pressed(&"debug_pixel_shading"):
		Settings.set_pixel_shading(not Settings.pixel_shading)
