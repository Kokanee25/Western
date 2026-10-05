class_name LookPanel
extends CanvasLayer
## The live look panel (docs/briefs/review-tools.md): N (controller: Back + Start) opens sliders for
## every look setting, grouped as config/look_panel.json lays them out (the art session's list,
## docs/briefs/look_settings.md). Changes apply as you drag. A time-of-day slider at the top; Save
## writes user://looks/<name>.json, Export copies the preset to the clipboard to paste into chat,
## Load reads a saved one, Reset puts everything back as the game started. A preset Sean exports
## renders exactly with `--look=FILE` (LookPreset).

const LAYOUT := "res://config/look_panel.json"
const WIDTH := 460.0

var _root: Control
var _rows := {}  # address -> {control, value_label, item}
var _name_edit: LineEdit
var _load_menu: OptionButton
var _toast: Label
var _toast_left := 0.0
var _hour: HSlider
var _hour_label: Label
var _was_captured := false
var _syncing := false
var _layout := {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	_build()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_root.visible = true
	_set_player_input(false)
	# The key help would show through beside it.
	var overlay := get_parent().get_node_or_null(^"DebugOverlay") if get_parent() else null
	if overlay and "_help" in overlay:
		overlay._help.visible = false
		overlay._help_timer = -1.0
	_refresh()
	_fill_load_menu()


func close() -> void:
	_root.visible = false
	_set_player_input(true)
	if _was_captured and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"look_panel") and not (_name_edit and _name_edit.has_focus()):
		toggle()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START \
			and Input.is_joy_button_pressed(event.device, JOY_BUTTON_BACK):
		toggle()
		get_viewport().set_input_as_handled()
	elif is_open() and event.is_action_pressed(&"release_mouse"):
		close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
	if is_open() and not _hour.has_focus():
		var clock := _clock()
		if clock:
			_syncing = true
			_hour.value = clock.time_of_day
			_hour_label.text = clock.get_clock_text()
			_syncing = false


# -- Building it ---------------------------------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.name = "LookPanel"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP  # clicks beside the panel mustn't grab the mouse
	add_child(_root)
	var bg := PanelContainer.new()
	bg.position = Vector2(8, 8)
	bg.custom_minimum_size = Vector2(WIDTH, 0)
	bg.anchor_bottom = 1.0
	bg.offset_bottom = -8.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.05, 0.95)
	style.set_content_margin_all(8)
	bg.add_theme_stylebox_override(&"panel", style)
	_root.add_child(bg)
	var outer := VBoxContainer.new()
	bg.add_child(outer)
	var title := Label.new()
	title.text = "LOOK  (N or Esc to close)"
	outer.add_child(title)
	# The clock, always at the top.
	var hrow := HBoxContainer.new()
	outer.add_child(hrow)
	var hl := Label.new()
	hl.text = "Time of day"
	hl.custom_minimum_size.x = 150
	hrow.add_child(hl)
	_hour = HSlider.new()
	_hour.min_value = 0.0
	_hour.max_value = 24.0
	_hour.step = 1.0 / 60.0
	_hour.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hour.value_changed.connect(_on_hour)
	hrow.add_child(_hour)
	_hour_label = Label.new()
	_hour_label.custom_minimum_size.x = 56
	hrow.add_child(_hour_label)
	# Buttons.
	var brow := HBoxContainer.new()
	outer.add_child(brow)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "preset name"
	_name_edit.text = "my_look"
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(_name_edit)
	_button(brow, "Save", _on_save)
	_button(brow, "Export", _on_export)
	_button(brow, "Reset", _on_reset)
	var lrow := HBoxContainer.new()
	outer.add_child(lrow)
	_load_menu = OptionButton.new()
	_load_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lrow.add_child(_load_menu)
	_button(lrow, "Load", _on_load)
	_button(lrow, "Close", close)
	_toast = Label.new()
	_toast.visible = false
	_toast.modulate = Color(1.0, 0.85, 0.5)
	outer.add_child(_toast)
	# The groups.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for g: Dictionary in _layout.get("groups", []):
		var body := VBoxContainer.new()
		var head := Button.new()
		head.text = "▸ " + String(g.name)
		head.toggle_mode = true
		head.alignment = HORIZONTAL_ALIGNMENT_LEFT
		head.toggled.connect(func(on: bool) -> void:
			body.visible = on
			head.text = ("▾ " if on else "▸ ") + String(g.name))
		list.add_child(head)
		body.visible = false
		list.add_child(body)
		for item: Dictionary in g.items:
			_row(body, item)


func _button(parent: Control, text: String, call: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(call)
	parent.add_child(b)
	return b


func _row(parent: Control, item: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.tooltip_text = String(item.get("what", ""))
	parent.add_child(row)
	var label := Label.new()
	label.text = String(item.label)
	label.custom_minimum_size.x = 170
	label.clip_text = true
	label.tooltip_text = row.tooltip_text
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(label)
	var key: String = item.key
	var kind: String = item.get("kind", "float")
	var control: Control
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 56
	match kind:
		"color":
			var c := ColorPickerButton.new()
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.color_changed.connect(func(col: Color) -> void: _apply_value(key, col))
			control = c
		"bool":
			var cb := CheckBox.new()
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cb.toggled.connect(func(on: bool) -> void: _apply_value(key, on))
			control = cb
		"choice":
			var ob := OptionButton.new()
			ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for o: String in item.options:
				ob.add_item(o)
			ob.item_selected.connect(func(i: int) -> void: _set_choice(key, item, i))
			control = ob
		_:
			var s := HSlider.new()
			s.min_value = float(item.min)
			s.max_value = float(item.max)
			s.step = float(item.get("step", 0.0))  # 0: no snapping (a value stays what it was set to)
			s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			s.value_changed.connect(func(v: float) -> void:
				value_label.text = _num(v)
				_apply_value(key, v))
			control = s
	control.tooltip_text = row.tooltip_text
	row.add_child(control)
	row.add_child(value_label)
	_rows[key] = {"control": control, "value": value_label, "item": item, "row": row}


# -- Values in and out -----------------------------------------------------------------------------

func _apply_value(key: String, v: Variant) -> void:
	if _syncing:
		return
	if not LookPreset.set_value(get_tree(), key, v):
		_say("%s: not in this scene" % key)


func _set_choice(key: String, item: Dictionary, i: int) -> void:
	var cur: Variant = LookPreset.get_value(get_tree(), key)
	_apply_value(key, i if cur is int else String(item.options[i]))


## Every row from the game's current values; a row whose setting isn't in this scene is greyed.
func _refresh() -> void:
	_syncing = true
	for key: String in _rows:
		var r: Dictionary = _rows[key]
		var v: Variant = LookPreset.get_value(get_tree(), key)
		(r.row as Control).modulate = Color(1, 1, 1, 1.0 if v != null else 0.4)
		if v == null:
			continue
		var c: Control = r.control
		if c is HSlider:
			(c as HSlider).value = float(v)
			(r.value as Label).text = _num(float(v))
		elif c is ColorPickerButton and v is Color:
			(c as ColorPickerButton).color = v
		elif c is CheckBox:
			(c as CheckBox).button_pressed = bool(v)
		elif c is OptionButton:
			var opts: Array = r.item.options
			(c as OptionButton).select(int(v) if v is int else opts.find(String(v)))
	_syncing = false


func _all_keys() -> Array:
	return _rows.keys()


func preset() -> Dictionary:
	return LookPreset.capture(get_tree(), _all_keys(), _name_edit.text)


func _on_hour(v: float) -> void:
	if _syncing:
		return
	var clock := _clock()
	if clock:
		clock.set_time(v)
		_hour_label.text = clock.get_clock_text()


func _on_save() -> void:
	var path := LookPreset.save_file(preset(), _name_edit.text)
	_fill_load_menu()
	_say("saved %s" % ProjectSettings.globalize_path(path))


func _on_export() -> void:
	DisplayServer.clipboard_set(LookPreset.to_json(preset()))
	_say("copied to the clipboard: paste it into the chat")


func _on_load() -> void:
	if _load_menu.item_count == 0:
		return
	var name := _load_menu.get_item_text(_load_menu.selected)
	var missed := LookPreset.apply(get_tree(), LookPreset.load_file("%s/%s.json" % [LookPreset.DIR, name]))
	_name_edit.text = name
	_refresh()
	_say("loaded %s%s" % [name, "" if missed.is_empty() else " (not here: %d)" % missed.size()])


func _on_reset() -> void:
	LookPreset.reset(get_tree())
	_refresh()
	_say("back to how the game started")


func _fill_load_menu() -> void:
	_load_menu.clear()
	for n in LookPreset.saved_names():
		_load_menu.add_item(n)


func _say(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_left = 4.0


func _set_player_input(on: bool) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		player.input_enabled = on


func _clock() -> DayCycle:
	return get_tree().root.find_child("DayCycle", true, false) as DayCycle


static func _num(v: float) -> String:
	return ("%.0f" if absf(v) >= 100.0 else "%.2f" if absf(v) >= 1.0 else "%.3f") % v
