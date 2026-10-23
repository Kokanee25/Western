extends SceneTree
## Starts the building lab's runner (runner.gd: every headless check, written to results/<date>/).
##   godot --headless --fixed-fps 60 -s res://experiments/building_lab/run.gd -- --out=experiments/building_lab/results/2026-10-22


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	root.add_child(load("res://experiments/building_lab/runner.gd").new())
