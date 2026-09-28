class_name OutlawSpawner
extends Node3D
## Puts the test outlaw (a HumanBody with an OutlawBrain) here, facing this node's -Z.
## F9 (D-pad right) clears him away, with his dropped gun, any fingers and the blood, and brings a
## fresh one.

var outlaw: HumanBody
var _count := 0


func _ready() -> void:
	spawn.call_deferred()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_reset_outlaw"):
		spawn()


func spawn() -> HumanBody:
	if outlaw != null and is_instance_valid(outlaw):
		outlaw.queue_free()
	for group in [&"dropped_guns", &"severed_parts"]:
		for n in get_tree().get_nodes_in_group(group):
			n.queue_free()
	Blood.clear()
	_count += 1
	outlaw = HumanBody.new()
	outlaw.name = "Outlaw%d" % _count
	outlaw.person_id = &"outlaw"
	outlaw.rng_seed = _count
	var brain := OutlawBrain.new()
	brain.name = "Brain"
	outlaw.add_child(brain)
	get_parent().add_child(outlaw)
	outlaw.global_transform = global_transform
	return outlaw


func brain() -> OutlawBrain:
	if outlaw == null or not is_instance_valid(outlaw):
		return null
	return outlaw.get_node_or_null(^"Brain") as OutlawBrain
