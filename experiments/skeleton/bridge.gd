extends BridgeLab
## Issue #696 (the fuller skeleton): films of a man's shoulders, arms, wrists and fingers before
## and after, from the same build, light and camera. Lab only; README.md beside it has the runs.
##
##   sk_man MODEL X Y Z [YAW] [gun]   a man of that body model there, no brain; `gun`: a revolver
##                                    in his holster (sk_film draw takes it out). A MetaHuman (his
##                                    report's route `metahuman`) is drawn with his own materials.
##   sk_rig on|off                    the deform bones on, or each moving as the bone it's part of
##                                    (the 17-bone skeleton's skin: the "before")
##   sk_cam front|side|three|hand [DIST] [HEIGHT] [AT]   the free camera on him
##   sk_film DIR ACTION [FRAMES] [LEAD]   every frame drawn to DIR; ACTION: rest, hands_up, aim,
##                                    reach, wrist, draw (from LEAD on)

const HELP := {
	"sk_man": "sk_man MODEL X Y Z [YAW] [gun] -> a man there, no brain (#696's films)",
	"sk_rig": "sk_rig on|off -> the deform bones on, or following their segments (the 17-bone skin)",
	"sk_cam": "sk_cam front|side|three|hand [DIST=3] [HEIGHT=1.35] [AT=1.2] -> the free camera on the sk_man",
	"sk_film": "sk_film DIR rest|hands_up|aim|reach|wrist|draw [FRAMES=120] [LEAD=15] -> each frame to DIR",
	"sk_cost": "sk_cost [N=2000] -> the sk_man's bones posed N times, the deform rig on and off (microseconds a pose)",
}

var man: HumanBody


func _cmd_sk_man(a: Array) -> Dictionary:
	if a.size() < 4:
		return {"ok": false, "error": "sk_man MODEL X Y Z [YAW] [gun]"}
	if man and is_instance_valid(man):
		man.queue_free()
		await physics_frames(2)
	var at := Vector3(float(a[1]), float(a[2]), float(a[3]))
	var yaw := deg_to_rad(-float(a[4])) if a.size() >= 5 else 0.0
	man = HumanBody.new()
	man.person_id = &"sk_man"
	man.name = "SkMan"
	man.has_gun = a.size() >= 6 and a[5] == "gun"
	man.start_holstered = true
	man.body_model = StringName(a[0])
	man.enter(street, at, yaw)
	await physics_frames(30)
	var own := 0
	if String(PeopleBodies.report(man.body_model).get("route", "")) == "metahuman":
		own = _own_materials()
	return {"person": String(man.person_id), "at": [at.x, at.y, at.z], "bones": man.skeleton.get_bone_count(),
			"own_materials": own, "fitted": not man.anatomy.maps.is_empty()}


## His GLB's own materials on his skin's meshes (as the Studio's test scene draws a MetaHuman: the
## game's people shaders expect the painted men's textures).
func _own_materials() -> int:
	var scene := load(PeopleBodies.PATH % man.body_model) as PackedScene
	var root := scene.instantiate()
	var mats := {}
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var shape := String(mi.name).to_lower().trim_prefix("body_").trim_prefix("cloth_")
		if mi.mesh and mi.mesh.get_surface_count() > 0:
			mats[shape] = mi.mesh.surface_get_material(0)
	root.free()
	var n := 0
	for c in man.skeleton.get_children():
		var mi := c as MeshInstance3D
		if mi == null:
			continue
		for shape: String in mats:
			if String(mi.name).begins_with(shape.to_pascal_case() + "_"):
				mi.material_override = mats[shape]
				n += 1
				break
	return n


func _cmd_sk_rig(a: Array) -> Dictionary:
	DeformRig.on = a.is_empty() or a[0] != "off"
	return {"deform": DeformRig.on}


func _cmd_sk_cam(a: Array) -> Dictionary:
	if man == null:
		return {"ok": false, "error": "sk_man first"}
	var view: String = a[0] if a.size() > 0 else "front"
	var dist := float(a[1]) if a.size() > 1 else 3.0
	var height := float(a[2]) if a.size() > 2 else 1.35
	var at_h := float(a[3]) if a.size() > 3 else 1.2
	var fwd := -man.global_basis.z
	var right := man.global_basis.x
	var d := fwd
	var p := man.global_position
	if view == "side":
		d = right
	elif view == "three":
		d = (fwd + right).normalized()
	elif view == "hand":
		# His right hand in his aim, from his right and a little in front.
		d = (right * 0.8 + fwd * 0.6).normalized()
		p += right * 0.25 + fwd * 0.45
	var cam := p + d * dist + Vector3(0, height, 0)
	var t := p + Vector3(0, at_h, 0)
	return await bridge._cmd_camera([str(cam.x), str(cam.y), str(cam.z), str(t.x), str(t.y), str(t.z), "40"])


func _cmd_sk_film(a: Array) -> Dictionary:
	if man == null:
		return {"ok": false, "error": "sk_man first"}
	if DisplayServer.get_name() == "headless":
		return {"ok": false, "error": "headless: nothing is drawn"}
	var dir: String = a[0]
	var action: String = a[1] if a.size() > 1 else "rest"
	var frames := int(a[2]) if a.size() > 2 else 120
	var lead := int(a[3]) if a.size() > 3 else 15
	DirAccess.make_dir_recursive_absolute(dir)
	var hidden := _hide_overlays()
	man.pose_offsets.clear()
	if man.held_gun != null and not man.gun_holstered:
		man.holster_gun(true)
	man.set_pose(&"stand")
	man._apply_pose(0.0, true)
	await physics_frames(30)
	var fwd := -man.global_basis.z
	var right := man.global_basis.x
	# The reach: a shelf in front of him a little over his head, his right hand to it.
	var shelf := man.global_position + fwd * 0.42 + right * 0.18 + Vector3(0, man.anatomy.height - 0.05, 0)
	for f in frames:
		var t := float(f - lead) / 60.0
		if f == lead:
			match action:
				"hands_up":
					man.set_pose(&"hands_up")
				"aim":
					man.set_pose(&"aim")
				"draw":
					man.set_pose(&"aim")
					man.draw_gun()
		if f >= lead:
			match action:
				"reach":
					man.reach_to("r", shelf, -fwd, clampf(t / 0.6, 0.0, 1.0))
				"wrist":
					# His palm turned down and up (pronation, supination), 80 degrees each way, his
					# forearm held out in front.
					man.pose_offsets = {&"upper_arm_r": Vector3(55, 0, 0), &"forearm_r": Vector3(30, 0, 0),
							&"hand_r": Vector3(0, 80.0 * sin(t * TAU / 2.5), 0)}
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%04d.png" % [dir, f])
	man.pose_offsets.clear()
	for c: CanvasLayer in hidden:
		if is_instance_valid(c):
			c.visible = true
	return {"frames": frames, "dir": dir, "action": action, "deform": DeformRig.on}


## The screen's words off while filming: every CanvasLayer but the game picture's.
func _hide_overlays() -> Array[CanvasLayer]:
	var out: Array[CanvasLayer] = []
	for n in get_tree().root.find_children("*", "CanvasLayer", true, false):
		var c := n as CanvasLayer
		if c.visible and c.find_children("*", "SubViewportContainer", true, false).is_empty() \
				and c.find_children("*", "SubViewport", true, false).is_empty():
			c.visible = false
			out.append(c)
	return out


## What the fuller skeleton costs a man a tick: his bones posed (_update_skeleton: the 17 from his
## parts, the deform rig, the shoulder helpers, the fingers) N times with the deform rig on and off,
## and the deform rig's own pose alone. Microseconds a call, on this machine.
func _cmd_sk_cost(a: Array) -> Dictionary:
	if man == null:
		return {"ok": false, "error": "sk_man first"}
	var n := int(a[0]) if a.size() > 0 else 2000
	man.set_pose(&"hands_up")
	man._apply_pose(0.0, true)
	await physics_frames(5)
	var out := {"bones": man.skeleton.get_bone_count()}
	for mode in [false, true, false, true]:
		DeformRig.on = mode
		var t0 := Time.get_ticks_usec()
		for i in n:
			man._update_skeleton({}, 1.0 / 60.0)
		out["skeleton_us_" + ("on" if mode else "off")] = float(Time.get_ticks_usec() - t0) / n
	DeformRig.on = true
	var extra := [Vector2.ZERO, Vector2.ZERO]
	var t1 := Time.get_ticks_usec()
	for i in n:
		DeformRig.pose(man.skeleton, man._deform, extra, [null, null], 0.0, 1.0 / 60.0)
	out["deform_pose_us"] = float(Time.get_ticks_usec() - t1) / n
	man.set_pose(&"stand")
	return out
