extends BridgeLab
## Issue #694 (a proper hands-up): films of a man putting his hands up, the pose before #694 beside
## the new one, from the same build, light and camera. Lab only. README.md beside it has the runs.
##
##   hu_man MODEL X Y Z [YAW]       a man of that body model there, no brain (studio men by their id;
##                                  gang:NAME brings that gang man, his brain stopped)
##   hu_cam front|side|three [DIST] the free camera on him: from in front, his right, or between
##   hu_film DIR old|new [FRAMES] [LEAD]  he stands; LEAD frames on, his hands go up the old way or
##                                  the new; every frame drawn saved to DIR/0000.png...
##
## "old" is the pose before #694 exactly: its numbers (upper arms 150 degrees about z, forearms 25,
## head 8) reached by the same Euler blend the old pose had (the stand pose's goal plus offsets up
## to the old numbers), so no copy of the old code is needed to film it.

const HELP := {
	"hu_man": "hu_man MODEL|gang:NAME X Y Z [YAW] -> a man there, no brain (#694's films)",
	"hu_cam": "hu_cam front|side|three [DIST] -> the free camera on the hu_man",
	"hu_film": "hu_film DIR old|new [FRAMES=150] [LEAD=20] -> his hands up the old way or the new, each frame to DIR",
}

## The old hands_up (before #694), as offsets over the stand pose's goal.
const OLD := {&"upper_arm_r": Vector3(0, 0, 150), &"forearm_r": Vector3(0, 0, 25),
		&"upper_arm_l": Vector3(0, 0, -150), &"forearm_l": Vector3(0, 0, -25), &"head": Vector3(8, 0, 0)}

var man: HumanBody


func _cmd_hu_man(a: Array) -> Dictionary:
	if a.size() < 4:
		return {"ok": false, "error": "hu_man MODEL|gang:NAME X Y Z [YAW]"}
	if man and is_instance_valid(man) and man.person_id == &"hu_man":
		man.queue_free()
	var at := Vector3(float(a[1]), float(a[2]), float(a[3]))
	var yaw := deg_to_rad(-float(a[4])) if a.size() >= 5 else 0.0
	var model: String = a[0]
	if model.begins_with("gang:"):
		var town = main.find_child("TownLife", true, false)
		town.bring_gang([StringName(model.substr(5))])
		man = town.gang[-1]
		man.get_node("Brain").set_physics_process(false)
		man.get_node("Brain").set_process(false)
		man.global_position = at
		man.rotation.y = yaw
	else:
		man = HumanBody.new()
		man.person_id = &"hu_man"
		man.name = "HuMan"
		man.has_gun = false
		man.body_model = StringName(model)
		man.enter(street, at, yaw)
	await physics_frames(30)
	return {"person": String(man.person_id), "at": [at.x, at.y, at.z]}


func _cmd_hu_cam(a: Array) -> Dictionary:
	if man == null:
		return {"ok": false, "error": "hu_man first"}
	var view: String = a[0] if a.size() > 0 else "front"
	var dist := float(a[1]) if a.size() > 1 else 3.0
	var fwd := -man.global_basis.z
	var right := man.global_basis.x
	var d := fwd
	if view == "side":
		d = right
	elif view == "three":
		d = (fwd + right).normalized()
	var p := man.global_position
	var cam := p + d * dist + Vector3(0, 1.35, 0)
	var t := p + Vector3(0, 1.2, 0)
	return await bridge._cmd_camera([str(cam.x), str(cam.y), str(cam.z), str(t.x), str(t.y), str(t.z), "50"])


func _cmd_hu_film(a: Array) -> Dictionary:
	if man == null:
		return {"ok": false, "error": "hu_man first"}
	if DisplayServer.get_name() == "headless":
		return {"ok": false, "error": "headless: nothing is drawn"}
	var dir: String = a[0]
	var mode: String = a[1] if a.size() > 1 else "new"
	var frames := int(a[2]) if a.size() > 2 else 150
	var lead := int(a[3]) if a.size() > 3 else 20
	DirAccess.make_dir_recursive_absolute(dir)
	var hidden := _hide_overlays()
	for k: StringName in OLD:
		man.pose_offsets.erase(k)
	man.set_pose(&"stand")
	man._apply_pose(0.0, true)
	await physics_frames(30)
	for f in frames:
		if f == lead:
			if mode == "old":
				for k: StringName in OLD:
					man.pose_offsets[k] = OLD[k]
			else:
				man.set_pose(&"hands_up")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%04d.png" % [dir, f])
	for c: CanvasLayer in hidden:
		if is_instance_valid(c):
			c.visible = true
	return {"frames": frames, "dir": dir, "mode": mode, "hid": hidden.size()}


## The screen's words (toasts, the clock, a report's line) off while filming: every CanvasLayer
## but the one the game's picture is drawn in.
func _hide_overlays() -> Array[CanvasLayer]:
	var out: Array[CanvasLayer] = []
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var c := n as CanvasLayer
		if c.visible and c.find_children("*", "SubViewportContainer", true, false).is_empty() \
				and c.find_children("*", "SubViewport", true, false).is_empty():
			c.visible = false
			out.append(c)
	return out
