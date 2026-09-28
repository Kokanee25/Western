class_name DebugBreaker
extends Node
## F11: break whatever member of a building you're looking at (a post, a stud, a beam), as if
## an axe or a charge had taken it out, and watch what the rest does. Debug only, for trying out
## the structure system before there's fire and dynamite.


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_break"):
		break_looked_at()


func break_looked_at() -> StructureMember:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return null
	var cam := player.camera
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 40.0, Layers.WORLD)
	q.exclude = [player.get_rid()]
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or not hit.collider is StructureMember:
		return null
	var m := hit.collider as StructureMember
	var s := m.get_parent() as Structure
	if s:
		s.break_member(m, dir * 1.5)
	return m
