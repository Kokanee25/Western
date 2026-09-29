class_name DebugBreaker
extends Node
## F11: break whatever member of a building you're looking at (a post, a stud, a beam), as if
## an axe or a charge had taken it out, and watch what the rest does. F12: set it alight.
## J: tear a wound open in a person. F4: reduced gore on/off (a real setting, saved).
## Debug only, for trying out structures and fire before there's dynamite.


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_break"):
		break_looked_at()
	if Input.is_action_just_pressed(&"debug_ignite"):
		ignite_looked_at()
	if Input.is_action_just_pressed(&"debug_wound"):
		wound_looked_at()
	if Input.is_action_just_pressed(&"toggle_gore"):
		Settings.set_reduced_gore(not Settings.reduced_gore)


## J: tear a big wound open in whoever you're looking at (a stand-in for point-blank buckshot or a
## blast until those exist), to see what's inside.
func wound_looked_at(energy := 1500.0) -> Dictionary:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return {}
	var cam := player.camera
	var from := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - cam.global_transform.basis.z * 30.0, Layers.BULLETS)
	q.exclude = [player.get_rid()]
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or not (hit.collider as Object).has_meta(&"human_body"):
		return {}
	var body: Object = (hit.collider as Object).get_meta(&"human_body")
	if body is HumanBody:
		return (body as HumanBody).open_wound_at(hit.collider, hit.position, energy)
	return {}


func ignite_looked_at() -> StructureMember:
	var m := looked_at()
	var fire := FireSystem.find(get_tree())
	if m and fire:
		fire.ignite(m)
	return m


func break_looked_at() -> StructureMember:
	var m := looked_at()
	if m == null:
		return null
	var s := m.get_parent() as Structure
	if s:
		var player := get_tree().get_first_node_in_group(&"player") as Player
		s.break_member(m, -player.camera.global_transform.basis.z * 1.5)
	return m


func looked_at() -> StructureMember:
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
	return hit.collider as StructureMember
