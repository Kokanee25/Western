extends SceneTree
## The doctor's office in the game's own light (the building lab's step 5, #765): the game's main
## scene in the valley (its real look, exposure and grade), the doctor's built on its lot by
## ValleyWorld, drawn from the target sheet's views (sheet/request.json) by our camera, each at the
## sheet's time of day. Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/doctor/render_valley.gd -- --out=DIR [--views=front,surgery] [--size=1280x720]
##
## ~10 min a view under lavapipe (check the log's "Vulkan" line); never two runs at once (~10 GB each).

## name -> [camera, look at (the building's space: x from its east corner, z back from its front,
## y over the street edge's ground), fov, hour].
const VIEWS := {
	"front": [Vector3(4.6, 1.75, -17.0), Vector3(4.4, 3.3, 0.0), 42.0, 13.0],
	"side_yard": [Vector3(-13.5, 1.75, -15.0), Vector3(2.0, 3.0, 5.0), 45.0, 16.5],
	"rear": [Vector3(15.0, 1.9, 27.0), Vector3(4.0, 3.2, 13.0), 45.0, 8.5],
	# Inside, each camera in the room's far corner, clear of every door's leaf (round 1 stood behind
	# them), by day (no lamps yet: the sheet's evening sick room would be black).
	"front_office": [Vector3(7.9, 2.55, 0.7), Vector3(2.5, 2.0, 3.6), 72.0, 11.0],
	"surgery": [Vector3(3.6, 2.55, 4.25), Vector3(0.2, 2.0, 6.6), 72.0, 9.0],
	"dispensary": [Vector3(8.15, 2.55, 7.9), Vector3(5.6, 2.0, 4.1), 72.0, 11.0],
	"sick_room": [Vector3(0.45, 2.55, 11.0), Vector3(3.8, 1.8, 8.5), 72.0, 15.0],
	"quarters": [Vector3(8.15, 2.55, 14.25), Vector3(5.6, 1.9, 11.6), 72.0, 8.0],
}

var out_dir := "build/doctor_renders"
var only: PackedStringArray = []
var size := Vector2i(1280, 720)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	settings.set_world(&"valley")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var overlay := main.get_node_or_null(^"DebugOverlay") as CanvasLayer
	if overlay:
		overlay.visible = false
	var vp: SubViewport = main.get_node(^"GameViewport")
	vp.size = size
	var valley: Node3D = main.find_child("Valley", true, false)
	var player = valley.get_node_or_null(^"Player")
	if player:
		player.input_enabled = false
		for w in player.get(&"weapons"):
			w.visible = false
	var building: Node3D = valley.get(&"buildings").get("doctor")
	if building == null:
		push_error("no doctor's building in the valley (valley.json's doctor lot needs its spec)")
		quit(1)
		return
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.name = "DoctorCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 30:
		await physics_frame
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		if clock:
			clock.set_time(float(view[3]))
		cam.global_position = building.to_global(view[0])
		cam.look_at(building.to_global(view[1]), Vector3.UP)
		cam.fov = float(view[2])
		# Lavapipe: wait out the clock's re-blend of the look after the jump (~5 s, CLAUDE.md).
		for i in 40:
			await process_frame
		await create_timer(5.0).timeout
		for i in 8:
			await process_frame
		var path := "%s/%s.png" % [out_dir, v]
		vp.get_texture().get_image().save_png(path)
		print("saved %s" % path)
	quit()
