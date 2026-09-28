extends CanvasLayer
## Developer overlay drawn at full window resolution (the game itself has almost no HUD).
## F1 shows the controls, F3 shows clock/speed/resolution readouts.

const HELP := """SALT CREEK — M0 test street
Move: WASD / left stick     Look: mouse / right stick
Run: hold Shift / click left stick     Crouch: hold Ctrl, or C / B
Jump: Space / A     Time speed: T / Y     Debug readout: F3 / View
Pixel size: F2     Pixel shading: F6     Texel size: F7     Jump to next place (street, store, saloon): F5 / D-pad up
Release mouse: Esc     This help: F1"""

var _help: Label
var _readout: Label
var _help_timer := 14.0


func _ready() -> void:
	_help = _label(Vector2(16, 16))
	_help.text = HELP
	_readout = _label(Vector2(16, 16))
	_readout.visible = false
	if DisplayServer.is_touchscreen_available():
		_help.text = "SALT CREEK — M0 test street\nLeft thumb: move   Right thumb: look\nButtons: jump, crouch, run, time speed"


func _label(pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override(&"font_size", 16)
	l.add_theme_color_override(&"font_color", Color(1.0, 0.95, 0.85))
	l.add_theme_color_override(&"font_outline_color", Color(0.05, 0.03, 0.02))
	l.add_theme_constant_override(&"outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_help"):
		_help.visible = not _help.visible
		_help_timer = -1.0
	if Input.is_action_just_pressed(&"debug_overlay"):
		_readout.visible = not _readout.visible
	if _help_timer > 0.0:
		_help_timer -= delta
		if _help_timer <= 0.0:
			_help.visible = false
	_readout.position.y = _help.position.y + (_help.size.y + 8.0 if _help.visible else 0.0)
	if _readout.visible:
		_readout.text = _readout_text()


func _readout_text() -> String:
	var lines: PackedStringArray = []
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if clock:
		lines.append("Day %d  %s  x%s time" % [clock.day, clock.get_clock_text(), str(clock.time_scale)])
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		var state := "crouching" if player.is_crouching else ("running" if player.is_running else "walking")
		var p := player.global_position
		lines.append("%.1f m/s %s   pos %.1f, %.1f, %.1f" % [player.get_horizontal_speed(), state, p.x, p.y, p.z])
	lines.append("%d fps   render %dx%d" % [Engine.get_frames_per_second(), Settings.internal_resolution.x, Settings.internal_resolution.y])
	return "\n".join(lines)
