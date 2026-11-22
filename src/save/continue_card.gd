class_name ContinueCard
extends CanvasLayer
## The start's card (#1148; there's no title screen yet): the game started on the valley with a save
## in the slot offers it, "Continue: day N, the hour" (Enter, or a pad's A) or a new game (Space, or
## B). Continue loads the save (SaveGame.load_slot: the valley built again, the save on it before
## the black lifts). A new game leaves the old save alone: it's only written over by your next sleep.
## Not offered on a story or test start (`--mission=`, `--moment=`, the smoke test, `--no-continue`),
## after a reset or a load, headless, or under the dev bridge unless `--continue-card` (the bridge has
## `continue` and `newgame`). While it's up the clock's held and you can't move.

signal answered(continued: bool)

var slot := "slot1"
var head := {}
var _player: Player
var _was_held := false
var _was_input := true
var _label: Label

## Answered once a run (or not offered): it's never offered again till the game's started anew.
static var done := false


## Would a start now offer Continue (a save in `slot` and a plain start)?
static func offered(args: PackedStringArray = OS.get_cmdline_user_args(), slot_name := "slot1", headless := DisplayServer.get_name() == "headless") -> bool:
	if done or GameReset.just_reset or not SaveGame.pending.is_empty():
		return false
	if headless or "--no-continue" in args or "--smoke-test" in args:
		return false
	if "--dev-bridge" in args and not "--continue-card" in args:
		return false
	for a: String in args:
		if a.begins_with("--mission=") or a.begins_with("--moment="):
			return false
	return not SaveGame.head(slot_name).is_empty()


func _ready() -> void:
	layer = 97
	head = SaveGame.head(slot)
	var black := ColorRect.new()
	black.color = Color(0.03, 0.025, 0.02, 0.97)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_color_override(&"font_color", Color(0.93, 0.88, 0.78))
	_label.add_theme_font_size_override(&"font_size", 26)
	_label.text = text()
	black.add_child(_label)
	_hold.call_deferred()


func text() -> String:
	var hour := float(head.get("hour", 0.0))
	var clock := "%02d:%02d" % [int(hour) % 24, int(fposmod(hour, 1.0) * 60.0)]
	return "SALT CREEK\n\nEnter: Continue (day %d, %s)\nSpace: a new game\n\n(the save is kept till you next sleep in a bed)" % [int(head.get("day", 1)), clock]


func _hold() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player:
		_was_input = _player.input_enabled
		_player.input_enabled = false
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if clock:
		_was_held = clock.held
		clock.set_held(true)


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	if (key and key.keycode in [KEY_ENTER, KEY_KP_ENTER]) or (pad and pad.button_index == JOY_BUTTON_A):
		get_viewport().set_input_as_handled()
		choose(true)
	elif (key and key.keycode == KEY_SPACE) or (pad and pad.button_index == JOY_BUTTON_B):
		get_viewport().set_input_as_handled()
		choose(false)


## Continue (the save loaded) or a new game (the card gone, the world as it started).
func choose(continued: bool) -> void:
	if done and not visible:
		return
	done = true
	visible = false
	answered.emit(continued)
	if continued and SaveGame.load_slot(get_tree(), slot):
		return
	if _player and is_instance_valid(_player):
		_player.input_enabled = _was_input
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if clock:
		clock.set_held(_was_held)
	queue_free()
