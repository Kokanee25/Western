extends SceneTree
## The jail in the game's own light (the building lab's step 5, #811): the game's main scene in the
## valley (its real look, exposure and grade), the jail built on its lot by ValleyWorld, drawn from
## the target sheet's views (sheet/request.json) by our camera, the rooms lit as the doctor's are
## (#824, #829: lamps by night, the windows by day). Its doctor's twins: doctor/render_valley.gd
## (the sheet's views) and doctor/light_views.gd (--cpu). Untyped where it names game classes: -s
## scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/jail/render_valley.gd -- \
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
	"front": [Vector3(5.5, 1.75, -16.0), Vector3(5.5, 2.6, 0.0), 45.0, 18.0, false],
	"corner": [Vector3(-13.0, 1.75, -8.5), Vector3(6.0, 2.4, 6.5), 48.0, 18.0, false],
	"yard": [Vector3(24.0, 1.75, 30.0), Vector3(9.5, 2.2, 16.0), 50.0, 18.0, false],
	"rear": [Vector3(15.0, 1.75, 50.0), Vector3(12.0, 2.4, 23.0), 55.0, 18.0, false],
	"office": [Vector3(10.05, 2.25, 6.6), Vector3(0.6, 1.5, 2.6), 70.0, 10.0, true],
	"desk": [Vector3(4.2, 2.2, 2.2), Vector3(0.9, 1.5, 5.4), 62.0, 15.5, true],
	"guard_room": [Vector3(9.95, 2.25, 13.1), Vector3(5.6, 1.5, 8.6), 70.0, 10.0, true],
	"corridor": [Vector3(7.0, 2.2, 22.35), Vector3(7.6, 1.3, 14.6), 70.0, 11.0, true],
	"cell": [Vector3(9.95, 2.0, 22.05), Vector3(6.9, 1.4, 19.2), 72.0, 15.0, true],
	"corridor_night": [Vector3(7.0, 2.2, 22.35), Vector3(7.6, 1.3, 14.6), 70.0, 21.5, true],
	"office_night": [Vector3(10.05, 2.25, 6.6), Vector3(0.6, 1.5, 2.6), 70.0, 21.5, true],
	"roof": [Vector3(5.5, 5.95, 9.5), Vector3(4.0, 4.3, -2.0), 66.0, 18.5, false],
}

var out_dir := "build/jail_renders"
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
	var building: Node3D = valley.get(&"buildings").get("jail")
	if building == null:
		push_error("no jail in the valley (valley.json's jail lot needs its spec)")
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
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.name = "JailCamera"
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
