extends SceneTree
## Our rig at rest, for the retarget (retarget.py): each segment's pivot (its joint) and its two
## ends a, b, in the body's frame (facing -z, his right +x), as JSON after "RIG ".
##   godot --headless -s res://experiments/mocap_walk/rig_rest.gd | grep '^RIG ' | cut -c5- \
##       > experiments/mocap_walk/rig_rest.json


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var man: Node3D = load("res://src/bodies/human_body.gd").new()
	root.add_child(man)
	await process_frame
	var out := {}
	for sid: StringName in man.anatomy.segment_order():
		var s: Dictionary = man.anatomy.segments[sid]
		var a: Vector3 = s.a
		var b: Vector3 = s.b
		var p: Vector3 = man._pivot_rest(sid)
		out[String(sid)] = {"parent": String(s.parent), "pivot": [p.x, p.y, p.z], "a": [a.x, a.y, a.z], "b": [b.x, b.y, b.z]}
	print("RIG " + JSON.stringify(out))
	quit()
