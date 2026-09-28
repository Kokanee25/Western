extends Node
## Builds the input map in code so every binding lives in one readable place.
## Keyboard + mouse and controller (Xbox names; any SDL-mapped pad works).

const STICK_DEADZONE := 0.2


func _ready() -> void:
	_bind(&"move_forward", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind(&"move_back", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind(&"move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind(&"move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind(&"look_left", [], [], [[JOY_AXIS_RIGHT_X, -1.0]])
	_bind(&"look_right", [], [], [[JOY_AXIS_RIGHT_X, 1.0]])
	_bind(&"look_up", [], [], [[JOY_AXIS_RIGHT_Y, -1.0]])
	_bind(&"look_down", [], [], [[JOY_AXIS_RIGHT_Y, 1.0]])
	_bind(&"jump", [KEY_SPACE], [JOY_BUTTON_A])
	# Hold to run (Shift) or click the left stick to run until you stop.
	_bind(&"run", [KEY_SHIFT], [])
	_bind(&"run_toggle", [], [JOY_BUTTON_LEFT_STICK])
	# Hold to crouch (Ctrl) or toggle (C, B button, right stick click).
	_bind(&"crouch", [KEY_CTRL], [])
	_bind(&"crouch_toggle", [KEY_C], [JOY_BUTTON_B, JOY_BUTTON_RIGHT_STICK])
	_bind(&"release_mouse", [KEY_ESCAPE], [])
	_bind(&"debug_help", [KEY_F1], [])
	_bind(&"debug_resolution", [KEY_F2], [])
	_bind(&"debug_overlay", [KEY_F3], [JOY_BUTTON_BACK])
	_bind(&"debug_time_scale", [KEY_T], [JOY_BUTTON_Y])


func _bind(action: StringName, keys: Array, buttons: Array, axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, STICK_DEADZONE)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		InputMap.action_add_event(action, ev)
	for axis in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axis[0]
		ev.axis_value = axis[1]
		InputMap.action_add_event(action, ev)
