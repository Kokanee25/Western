extends SceneTree
## A hand of the real card game photographed from your seat (#1294): a small stage (a floor, a lamp, the
## kit card table and four kit chairs, two of the roster's card players and the player sat at the south
## chair; CardGame playing them), shot at four beats: the table (your cards face down, chips and silver),
## your hand lifted to read, your draw with two cards marked, the showdown turned up. Not the valley:
## saloon B under lavapipe is too slow and too big for a workspace (and crashes at night, #1260). Not the
## pixel pipeline either: the player's camera straight to the window.
##
##   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a -s "-screen 0 960x540x24" \
##       godot --path . --rendering-driver vulkan --resolution 960x540 -s res://tools/card_shot.gd -- --out=DIR
##
## The stage itself is tools/card_shot_stage.gd, loaded once the autoloads exist (-s scripts compile before them).

func _initialize() -> void:
	(func() -> void: root.add_child(load("res://tools/card_shot_stage.gd").new())).call_deferred()
