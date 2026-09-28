extends Node3D
## F5 (or D-pad up) jumps the player between the Marker3D children: handy for reviewing places
## without walking there. Debug only.

var _index := 0


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_teleport"):
		jump_to_next()


func jump_to_next() -> void:
	var markers := get_children().filter(func(n: Node) -> bool: return n is Marker3D)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if markers.is_empty() or player == null:
		return
	_index = (_index + 1) % markers.size()
	var m: Marker3D = markers[_index]
	player.global_position = m.global_position
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, m.global_rotation.y, 0.0)
