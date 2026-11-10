class_name DebugBreaker
extends Node
## F11: break whatever member of a building you're looking at (a post, a stud, a beam), as if
## an axe or a charge had taken it out, and watch what the rest does. F12: set it alight.
## J: tear a wound open in a person. F4: reduced gore on/off (a real setting, saved).
## Debug only, for trying out structures and fire before there's dynamite.
## Minus: the rope range (#777): a rope hung 30 m ahead of you, a man's weight on it, to shoot at
## with the Winchester; again 60 m; again it's taken down. Go up somewhere first (the saloon's
## balcony, a roof): it hangs from a metre over your eye.


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_break"):
		break_looked_at()
	if Input.is_action_just_pressed(&"debug_ignite"):
		ignite_looked_at()
	if Input.is_action_just_pressed(&"debug_wound"):
		wound_looked_at()
	if Input.is_action_just_pressed(&"toggle_gore"):
		Settings.set_reduced_gore(not Settings.reduced_gore)
	if Input.is_action_just_pressed(&"debug_rope"):
		var at := 30.0 if _rope == null else 60.0 if _rope_at < 45.0 else 0.0
		hang_rope(at)


var _rope: HangingRope
var _rope_at := 0.0


## A rope `metres` ahead of you along your view (level), hanging 2.5 m from a metre over your eye,
## a man's weight on it (`HangingRope`); 0 takes it down. Returns it.
func hang_rope(metres: float) -> HangingRope:
	if _rope and is_instance_valid(_rope):
		if _rope.fallen and is_instance_valid(_rope.fallen):
			_rope.fallen.queue_free()
		_rope.queue_free()
	_rope = null
	_rope_at = metres
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null or metres <= 0.0:
		return null
	var cam := player.camera.global_transform
	var ahead := -cam.basis.z
	ahead.y = 0.0
	ahead = ahead.normalized()
	_rope = HangingRope.new()
	_rope.name = "RopeRange"
	_rope.length = 2.5
	_rope.load_kg = 80.0
	player.get_parent().add_child(_rope)
	_rope.global_position = cam.origin + ahead * metres + Vector3.UP * 1.0
	if player.wounds:
		player.wounds.say("A rope hung %d m off." % int(metres), 2.5)
	return _rope


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
	var hit := World.space(cam).intersect_ray(q)
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
	var hit := World.space(cam).intersect_ray(q)
	if hit.is_empty() or not hit.collider is StructureMember:
		return null
	return hit.collider as StructureMember
