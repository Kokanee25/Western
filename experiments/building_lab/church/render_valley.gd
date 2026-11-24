extends SceneTree
## The church in the game's own light (the building lab's step 5, #1142), as the jail's and the doctor's render scripts: the game's main
## scene in the valley, the church built on its place by ValleyWorld, drawn from the sheet's views by our camera. Camera numbers are in the
## building's space (x west from its east corner, z back from the tower's front... the front wall at 0, y over the pad).
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/church/render_valley.gd -- \
##       --out=DIR [--views=front,office] [--size=1280x720] [--cpu]
##
## --cpu: each view's render CPU too (RenderingServer's measure, x0.65 for Sean's core as perf_bench
## scales) over 30 frames, printed and written to cpu.txt.
## ~10 min a view under lavapipe (start it with the real look: the default); never two runs at once.

## name -> [camera, look at (the building's space: x east from its west corner, z back from its
## front, y over the street edge's ground; its floor at 0.6), fov, hour, inside]. Outside, the
## sheet's summer evening from the north-west (the front faces north, in its own shade), the roof
## from its back over the deck to the front parapet; inside, the office west along its windowed
## front wall and the corridor from its end wall (the sheet's ways, round 2); otherwise
## each camera in the room's far corner clear of every door's leaf (the leaves are set aside for
## the inside views, as the doctor's), by day; the corridor and the office again at night.
const VIEWS := {
	"wide": [Vector3(-24.0, 4.0, -46.0), Vector3(6.0, 5.0, -2.0), 64.0, 17.0, false],
	"hill": [Vector3(46.0, 6.5, 22.0), Vector3(42.0, 1.8, 62.0), 66.0, 17.0, false],
	"front": [Vector3(4.265, 3.0, -30.0), Vector3(4.265, 6.2, 0.0), 50.0, 17.0, false],
	"side": [Vector3(30.0, 3.0, 5.0), Vector3(4.2, 4.2, 6.5), 52.0, 17.0, false],
	"tower": [Vector3(4.265, 3.0, -15.0), Vector3(4.265, 11.0, -1.5), 42.0, 17.0, false],
	"nave": [Vector3(4.265, 2.4, 1.0), Vector3(4.265, 2.6, 13.0), 72.0, 14.0, true],
	# The nave by lamplight, its lamps hung from the trusses' ties (#1203).
	"nave_lit": [Vector3(4.265, 2.4, 1.0), Vector3(4.265, 3.2, 13.0), 72.0, 20.5, true],
	"pulpit": [Vector3(4.265, 2.2, 7.0), Vector3(4.265, 1.9, 13.3), 60.0, 14.0, true],
	# A lane-side window close, in the late light from the west (its pointed head, #1142 round 4).
	"window": [Vector3(12.8, 2.6, 2.4), Vector3(8.53, 3.7, 5.4), 38.0, 17.0, false],
	# The sheet's two cemetery views: from its far side back toward the church over the funeral's fresh
	# grave and the rows, and low beside that grave (the cemetery's pad 3 m over the church's).
	"graveyard": [Vector3(56.0, 5.0, 71.5), Vector3(35.0, 4.6, 50.0), 60.0, 17.0, false],
	"grave": [Vector3(49.6, 4.4, 64.8), Vector3(40.0, 4.2, 55.5), 62.0, 17.0, false],
}

var out_dir := "build/church_renders"
var only: PackedStringArray = []
var size := Vector2i(1280, 720)
var cpu := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a == "--cpu":
			cpu = true
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
		player.global_position = Vector3(0, -50, 0)
	var building: Node3D = valley.get(&"buildings").get("church")
	if building == null:
		push_error("no church in the valley (valley.json's church place needs its spec)")
		quit(1)
		return
	var leaves: Array = []
	for m in building.get_members():
		if String(m.member_id).contains("/door_"):
			building.unbatch(m)
			leaves.append(m)
	# The valley's place names (its markers' labels) are a map's, not the picture's.
	for l in valley.find_children("*", "Label3D", true, false):
		l.visible = false
	# (and so are the places' coloured posts, the map's MultiMesh beside them)
	for mm in valley.find_children("*", "MultiMeshInstance3D", true, false):
		if mm.name == "Posts" and mm.get_parent().get(&"posts") != null:
			mm.visible = false
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.name = "ChurchCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	print("lamps in the building: %d" % building.find_children("*", "OilLamp", true, false).size())
	var vp_rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var cpu_lines: PackedStringArray = []
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		for m in leaves:
			m.visible = not bool(view[4])
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
		var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		if cpu:
			var ms: Array[float] = []
			for i in 30:
				await process_frame
				ms.append(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu())
			ms.sort()
			var line := "%s: render CPU median %.2f ms here, %.2f at Sean's (x0.65); %d draws" % [v, ms[15], ms[15] * 0.65, draws]
			print(line)
			cpu_lines.append(line)
		var path := "%s/%s.png" % [out_dir, v]
		vp.get_texture().get_image().save_png(path)
		print("saved %s (%d draws)" % [path, draws])
	if cpu:
		FileAccess.open(out_dir + "/cpu.txt", FileAccess.WRITE).store_string("\n".join(cpu_lines) + "\n")
	quit()
