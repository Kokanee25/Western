extends SceneTree
## What a mesh's arrays cost to read back (#626: RubbleRest's join at ~40 ms a frame in Sean's
## F12s, free in the headless lab). Draws N box meshes made the way a member's are (MemberMesh.box),
## renders a few frames, then times `surface_get_arrays` (what SurfaceTool.append_from calls) on
## each mesh, against the same read of arrays kept on the CPU. Headless the renderer keeps no GPU
## buffers, so run it rendered:
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/readback_cost.gd -- [--n=40]
## Untyped on purpose: -s scripts compile before autoloads exist.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var n := 40
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.substr(4))
	var root3d := Node3D.new()
	root.add_child(root3d)
	var cam := Camera3D.new()
	root3d.add_child(cam)
	cam.position = Vector3(0, 2, 12)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	root3d.add_child(sun)
	sun.rotation_degrees = Vector3(-50, 30, 0)
	var meshes: Array = []
	for i in n:
		# A box of its own size each (MemberMesh caches by size): a fresh mesh, as a new piece's.
		var mesh: ArrayMesh = load("res://src/structures/member_mesh.gd").box(Vector3(0.6 + i * 0.013, 0.025, 0.15))
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3((i % 10) - 5.0, 0.3 * (i / 10), 0)
		root3d.add_child(mi)
		meshes.append(mesh)
	for k in 10:
		await process_frame
	var t0 := Time.get_ticks_usec()
	var worst := 0
	for mesh: ArrayMesh in meshes:
		var t := Time.get_ticks_usec()
		var _a := mesh.surface_get_arrays(0)
		worst = maxi(worst, Time.get_ticks_usec() - t)
	var read_all := Time.get_ticks_usec() - t0
	# The same read again (does Godot keep a copy after the first?), then one after a frame.
	t0 = Time.get_ticks_usec()
	for mesh: ArrayMesh in meshes:
		var _a := mesh.surface_get_arrays(0)
	var again := Time.get_ticks_usec() - t0
	await process_frame
	t0 = Time.get_ticks_usec()
	var _b := (meshes[0] as ArrayMesh).surface_get_arrays(0)
	var one_after_frame := Time.get_ticks_usec() - t0
	# A SurfaceTool's append (RubbleRest._part's read) of one.
	await process_frame
	t0 = Time.get_ticks_usec()
	var st := SurfaceTool.new()
	st.append_from(meshes[1], 0, Transform3D.IDENTITY)
	var append_one := Time.get_ticks_usec() - t0
	print("readback: %d meshes, %s renderer" % [n, RenderingServer.get_current_rendering_driver_name()])
	print("  surface_get_arrays: %.3f ms a mesh (worst %.3f), again %.3f ms a mesh" % [read_all / 1000.0 / n, worst / 1000.0, again / 1000.0 / n])
	print("  one after a frame: %.3f ms; SurfaceTool.append_from one: %.3f ms" % [one_after_frame / 1000.0, append_one / 1000.0])
	quit(0)
