extends Node
## The blast-freeze lab's last _process of a frame (#538): when it ran.


func _process(_delta: float) -> void:
	var lab: Node = get_meta(&"lab")
	lab.set(&"_late_us", Time.get_ticks_usec())
