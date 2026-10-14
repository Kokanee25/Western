extends SceneTree
## The game itself with the render lab's look switch (experiments/render_lab/README.md): L flips
## between the game's look and the experiment, live, with nothing reloaded and nothing saved; the
## game's own files are untouched. Everything else plays as normal.
##
##   godot --path . -s res://experiments/render_lab/play.gd [-- --lab-look=paint]

const LabLooks := preload("res://experiments/render_lab/lab_looks.gd")
const LOOKS := ["base", "paint"]

var _i := 0
var _held := false
var _label: Label


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lab-look="):
			_i = maxi(LOOKS.find(a.substr(11)), 0)
	LabLooks.install(self, LOOKS[_i])
	change_scene_to_file("res://scenes/main.tscn")
	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_color_override(&"font_color", Color(1, 0.92, 0.75))
	root.add_child.call_deferred(_label)
	_show()


func _process(_delta: float) -> bool:
	var down := Input.is_physical_key_pressed(KEY_L)
	if down and not _held:
		_i = (_i + 1) % LOOKS.size()
		LabLooks.apply(root, LOOKS[_i])
		_show()
	_held = down
	return false


func _show() -> void:
	_label.text = "render lab: %s (L)" % LOOKS[_i]
