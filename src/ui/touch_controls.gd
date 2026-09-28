extends Control
## On-screen controls for phones and tablets (mainly the web build): drag on the left half to
## move, drag on the right half to look, and buttons for jump, crouch, run and time speed.
## Hidden when there is no touch screen.

const BUTTONS := [
	[&"jump", "JUMP"],
	[&"crouch_toggle", "CROUCH"],
	[&"run_toggle", "RUN"],
	[&"debug_time_scale", "TIME"],
]

var _move_touch := -1
var _move_origin := Vector2.ZERO
var _move_vector := Vector2.ZERO
var _look_touch := -1
var _button_touches := {}  # touch index -> action


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	set_process_input(visible)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _radius() -> float:
	return size.y * 0.16


func _button_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var r := size.y * 0.075
	var base := Vector2(size.x - r * 2.6, size.y - r * 2.6)
	var offsets := [Vector2(0, 0), Vector2(-r * 2.4, 0), Vector2(0, -r * 2.4), Vector2(-r * 2.4, -r * 2.4)]
	for o in offsets:
		rects.append(Rect2(base + o - Vector2(r, r), Vector2(r, r) * 2.0))
	return rects


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			var rects := _button_rects()
			for i in rects.size():
				if rects[i].grow(8.0).has_point(touch.position):
					var action: StringName = BUTTONS[i][0]
					_button_touches[touch.index] = action
					Input.action_press(action)
					queue_redraw()
					return
			if touch.position.x < size.x * 0.5 and _move_touch < 0:
				_move_touch = touch.index
				_move_origin = touch.position
				_set_move(Vector2.ZERO)
			elif _look_touch < 0:
				_look_touch = touch.index
		else:
			if _button_touches.has(touch.index):
				Input.action_release(_button_touches[touch.index])
				_button_touches.erase(touch.index)
			if touch.index == _move_touch:
				_move_touch = -1
				_set_move(Vector2.ZERO)
			if touch.index == _look_touch:
				_look_touch = -1
		queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _move_touch:
			_set_move((drag.position - _move_origin) / _radius())
			queue_redraw()
		elif drag.index == _look_touch:
			var d := drag.relative * Settings.touch_look_sensitivity
			Events.look_input.emit(Vector2(d.x, -d.y))


func _set_move(v: Vector2) -> void:
	_move_vector = v.limit_length(1.0)
	_axis(&"move_right", &"move_left", _move_vector.x)
	_axis(&"move_back", &"move_forward", _move_vector.y)


static func _axis(positive: StringName, negative: StringName, value: float) -> void:
	if value > 0.05:
		Input.action_press(positive, value)
		Input.action_release(negative)
	elif value < -0.05:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	else:
		Input.action_release(positive)
		Input.action_release(negative)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var ink := Color(1.0, 0.95, 0.85, 0.5)
	if _move_touch >= 0:
		draw_arc(_move_origin, _radius(), 0.0, TAU, 32, ink, 3.0)
		draw_circle(_move_origin + _move_vector * _radius(), _radius() * 0.35, Color(1.0, 0.95, 0.85, 0.35))
	var rects := _button_rects()
	for i in rects.size():
		var held: bool = _button_touches.values().has(BUTTONS[i][0])
		var c := rects[i].get_center()
		var r := rects[i].size.x * 0.5
		draw_circle(c, r, Color(0.1, 0.07, 0.05, 0.55 if held else 0.35))
		draw_arc(c, r, 0.0, TAU, 32, ink, 2.0)
		var text: String = BUTTONS[i][1]
		var fs := int(r * 0.42)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, c + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
