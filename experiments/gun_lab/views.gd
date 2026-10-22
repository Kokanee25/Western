extends SceneTree
## The gun lab's quick views: the player (scenes/player.tscn: his camera, guns and body) alone on a
## plain floor under a sun, no town, so a pose or a hand can be looked at in seconds, not the
## town's minutes. Not the baseline's frames (those are the town's, run.py): for working.
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 960x540 \
##       -s res://experiments/gun_lab/views.gd -- --out=DIR [--gun=revolver|shotgun] [--only=rest,aim]
## States: rest, aim, look_down, cocked, reload_open, reload_eject, reload_insert (revolver), open,
## pulled, loaded (shotgun). Writes DIR/<gun>_<state>.png.



func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	# Loaded now, not at compile time: the scripts it uses need the autoloads (Events, Settings).
	var impl: Node = load("res://experiments/gun_lab/views_impl.gd").new()
	root.add_child(impl)
	impl.call(&"run")
