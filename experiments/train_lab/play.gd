extends Node
## The train lab's keys in a build (issue #543), added by main.gd when the lab's folder is there:
## 9 builds the test line (out on the flat south of town, the first time) and puts you in the
## cab; 0 changes the camera. The lab itself is lab.gd (its header lists the cab's keys); it finds
## the street and the player only when a key asks for the line, so until then it costs nothing.

const LAB := preload("res://experiments/train_lab/lab.gd")


func _ready() -> void:
	var lab := LAB.new()
	lab.name = "TrainLab"
	get_parent().add_child.call_deferred(lab)
