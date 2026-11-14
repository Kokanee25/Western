extends SceneTree
## A man with his arms raised, to judge his armpits and shoulders: built as the game builds him
## (HumanBody, his game materials), each pose (ARM_POSES) shot from the front and from his front
## three-quarter on each side, saved as DIR/<pose>_<view>.png. Untyped where it touches game
## classes (-s scripts compile before the autoloads exist).
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/arm_poses.gd -- \
##       --id=barkeep_s2_talking --out=DIR [--size=640x640] [--only=forward,side] [--share=0.35]

## Degrees over his stand pose (HumanBody.pose_offsets: x lifts an arm forward, z out to his side).
const ARM_POSES := {
	"rest": {},
	"forward": {&"upper_arm_r": Vector3(85, 0, 0), &"upper_arm_l": Vector3(85, 0, 0)},
	"side": {&"upper_arm_r": Vector3(0, 0, 85), &"upper_arm_l": Vector3(0, 0, -85)},
	"across": {&"upper_arm_r": Vector3(75, 0, -40), &"forearm_r": Vector3(60, 0, 0),
			&"upper_arm_l": Vector3(75, 0, 40), &"forearm_l": Vector3(60, 0, 0)},
	"up": {&"upper_arm_r": Vector3(0, 0, 150), &"upper_arm_l": Vector3(0, 0, -150)},
}
## Camera yaw (degrees round him, 0 in front of him) for each view.
const VIEWS := {"front": 0.0, "right": 45.0, "left": -45.0}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var id := "barkeep_s2_talking"
	var out := "/tmp/arm_poses"
	var size := Vector2i(640, 640)
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="):
			id = a.substr(5)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--size="):
			var wh := a.substr(7).split("x")
			size = Vector2i(int(wh[0]), int(wh[1]))
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
		elif a.begins_with("--share="):
			# PeopleBodies.shoulder_share (0: no shoulder helpers), for a before and after.
			load("res://src/bodies/people_bodies.gd").shoulder_share = float(a.substr(8))
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.5, 0.5, 0.52)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.68)
	env.ambient_light_energy = 0.7
	env_node.environment = env
	w.add_child(env_node)
	var sun := DirectionalLight3D.new()
	w.add_child(sun)
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	var cam := Camera3D.new()
	cam.fov = 30.0
	w.add_child(cam)
	cam.current = true
	var m = load("res://src/bodies/human_body.gd").new()
	m.body_model = StringName(id)
	m.person_id = StringName(id + "_arms")
	m.rng_seed = 7
	m.face_life = false
	w.add_child(m)
	m.global_position = Vector3.ZERO
	for f in 6:
		await physics_frame
	m.face(Vector3(0, 0, -5))
	m.set_pose(&"stand")
	m._apply_pose(0.0, true)
	m.process_mode = Node.PROCESS_MODE_DISABLED   # held still: each picture differs by its pose alone
	var aim := Vector3(0, 1.3, 0)
	for pose: String in ARM_POSES:
		if not only.is_empty() and not pose in only:
			continue
		m.pose_offsets = ARM_POSES[pose].duplicate()
		m._apply_pose(0.0, true)
		m._update_skeleton()
		for view: String in VIEWS:
			var yaw := deg_to_rad(float(VIEWS[view]))
			cam.position = aim + Vector3(sin(yaw), 0.15, -cos(yaw)) * 2.6
			cam.look_at(aim)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png("%s/%s_%s.png" % [out, pose, view])
	print("arm_poses: done %s" % id)
	quit()
