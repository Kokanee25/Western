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
	_bind(&"debug_pixel_shading", [KEY_F6], [])
	_bind(&"debug_texel_size", [KEY_F7], [])
	_bind(&"debug_overlay", [KEY_F3], [JOY_BUTTON_BACK])
	_bind(&"debug_time_scale", [KEY_T], [])
	_bind(&"debug_teleport", [KEY_F5], [JOY_BUTTON_DPAD_UP])
	_bind(&"debug_traces", [KEY_F8], [])
	_bind(&"debug_xray", [KEY_F10], [])
	# Letters too: in a browser F11 is full screen and F12 opens the developer tools.
	_bind(&"debug_break", [KEY_F11, KEY_K], [])
	_bind(&"debug_ignite", [KEY_F12, KEY_L], [])
	_bind(&"debug_wound", [KEY_J], [])
	_bind(&"toggle_gore", [KEY_F4], [])
	# The guns.
	_bind(&"fire", [], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]], [MOUSE_BUTTON_LEFT])
	_bind(&"aim", [], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]], [MOUSE_BUTTON_RIGHT])
	_bind(&"cock", [KEY_Q], [JOY_BUTTON_RIGHT_SHOULDER], [], [MOUSE_BUTTON_WHEEL_DOWN])
	_bind(&"reload", [KEY_R], [JOY_BUTTON_X])
	_bind(&"holster", [KEY_H], [JOY_BUTTON_LEFT_SHOULDER])
	# What's in your hand: 1 the revolver, 2 the shotgun, 3 dynamite, or the next (wheel up / Y).
	_bind(&"weapon_revolver", [KEY_1], [])
	_bind(&"weapon_shotgun", [KEY_2], [])
	_bind(&"weapon_dynamite", [KEY_3], [])
	_bind(&"weapon_next", [], [JOY_BUTTON_Y], [], [MOUSE_BUTTON_WHEEL_UP])
	# Hold to press on your wounds (a belt goes round a bleeding limb after a few seconds).
	_bind(&"tend_wounds", [KEY_B], [JOY_BUTTON_DPAD_DOWN])
	_bind(&"shout", [KEY_G], [JOY_BUTTON_DPAD_LEFT])
	_bind(&"debug_reset_outlaw", [KEY_F9], [JOY_BUTTON_DPAD_RIGHT])
	# Bring the gang into town now (they otherwise ride in after a while).
	_bind(&"debug_gang", [KEY_U], [])


func _bind(action: StringName, keys: Array, buttons: Array, axes: Array = [], mouse: Array = []) -> void:
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
	for m in mouse:
		var ev := InputEventMouseButton.new()
		ev.button_index = m
		InputMap.action_add_event(action, ev)
	for axis in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axis[0]
		ev.axis_value = axis[1]
		InputMap.action_add_event(action, ev)
