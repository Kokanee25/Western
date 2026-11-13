extends SceneTree
## Saloon B on its valley lot (#848 step 1 the frame, #867 step 2 the look): the lab's renders of
## the building as built, in the game's own scene (the valley, the real look): the four sides, the
## corner, the well from the gallery, the bar room by day and by lamp, the dance hall. The doctor's
## light_views.gd, for this building. The valley's place posts and names are hidden.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/saloon_b/render_frame.gd -- \
##       --out=DIR [--views=front,side,...] [--size=1280x720] [--cpu] [--variants=NAME:dial=v,dial=v;NAME2:...]
##
## --variants: each view once a variant, in one load, saved as VIEW_NAME.png: `day_fill`,
## `window_day` (the spec's `light`), `room.<RoomLightTuning dial>` (as the doctor's light_views.gd).
##
## --cpu: each view's render CPU (the frame's CPU side, RenderingServer's measure; x0.65 for Sean's
## core as perf_bench scales) over 30 frames, printed and written to cpu.txt, no pictures; and the
## building's members, the bodies in the world and its draws.
## ~10 min a view under lavapipe; never two runs at once.

## name -> [camera, look at (the building's space: x from its east corner, z back from Main Street,
## the ground floor at 0.95), fov, hour].
const VIEWS := {
	# The sheet's views by its ids (saloon_b/sheet/request.json), for tools/buildings/judge_pairs.py.
	"front": [Vector3(9.4, 2.4, -19.0), Vector3(9.4, 4.6, 0.0), 58.0, 11.0],
	# The corner from the crossroads at dusk, the lamps lit (the sheet's); `corner_day` in the afternoon.
	"corner": [Vector3(26.5, 1.9, -9.5), Vector3(13.6, 4.5, 3.4), 54.0, 19.4],
	"corner_day": [Vector3(26.5, 1.9, -9.5), Vector3(13.6, 4.5, 3.4), 54.0, 15.5],
	# The back and the yard from the north-east: the outside stair up the yard wall.
	"rear": [Vector3(-13.5, 4.2, 33.0), Vector3(4.5, 4.4, 15.0), 58.0, 10.0],
	# Inside from the corner doors: the bar on the right, the posts and girders, the well.
	"door": [Vector3(14.4, 2.6, 2.6), Vector3(4.5, 2.6, 10.5), 72.0, 15.5],
	# From behind the bar's far end, back toward the corner doors and the card tables under the well.
	"bar": [Vector3(1.2, 2.65, 12.3), Vector3(12.0, 2.4, 3.5), 72.0, 19.0],
	# The dance hall from its back corner by the yard: the front's doors to the balcony, the well's rail.
	"dance": [Vector3(0.9, 6.6, 12.6), Vector3(8.5, 6.2, 3.0), 72.0, 19.0],
	# From the gallery's back corner over the rail: the well, the card tables, the bar under the girders.
	"gallery": [Vector3(15.9, 6.55, 12.9), Vector3(9.0, 1.6, 6.0), 72.0, 19.0],
	# Not on the sheet: the side street, the yard, the bar room by lamp light (the two on the bar,
	# the wheel in the well, the wall lamps).
	"side": [Vector3(36.0, 2.6, 10.0), Vector3(16.5, 4.6, 10.6), 58.0, 15.5],
	"yard": [Vector3(-19.5, 3.2, 12.0), Vector3(0.0, 4.4, 11.0), 58.0, 10.0],
	"door_night": [Vector3(14.4, 2.6, 2.6), Vector3(4.5, 2.6, 10.5), 72.0, 21.0],
}

var out_dir := "build/saloon_b_frame"
var only: PackedStringArray = []
var size := Vector2i(1280, 720)
var cpu := false
var variants: Array = []  # [[name, {dial: value}]]


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
		elif a.begins_with("--variants="):
			for part in a.substr(11).split(";", false):
				var parts := part.split(":")
				var dials := {}
				for d in (parts[1] if parts.size() > 1 else "").split(",", false):
					var kv := d.split("=")
					dials[kv[0]] = float(kv[1])
				variants.append([parts[0], dials])
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
	var building: Node3D = valley.get(&"buildings").get("saloon")
	if building == null:
		push_error("no saloon built in the valley")
		quit(1)
		return
	for n in valley.find_children("L_*", "Label3D", true, false) + valley.find_children("Posts", "MultiMeshInstance3D", true, false):
		n.visible = false
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.name = "FrameCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	var bodies := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CollisionObject3D:
			bodies += 1
		stack.append_array(n.get_children())
	var lines: PackedStringArray = []
	lines.append("saloon B in the valley: %d members, %d lamps; %d collision bodies in the world" % [building.get_members().size(),
			building.find_children("*", "OilLamp", true, false).size(), bodies])
	print(lines[0])
	var vp_rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	if variants.is_empty():
		variants = [["", {}]]
	for var_: Array in variants:
		_apply(building, var_[1])
		var suffix := "" if String(var_[0]) == "" else "_" + String(var_[0])
		for v: String in VIEWS:
			if not only.is_empty() and not only.has(v):
				continue
			var view: Array = VIEWS[v]
			if clock:
				clock.set_time(float(view[3]))
			cam.global_position = building.to_global(view[0])
			cam.look_at(building.to_global(view[1]), Vector3.UP)
			cam.fov = float(view[2])
			# (the look re-blends after a clock jump: a frame is ~15 s under lavapipe here, so a few do)
			for i in 14:
				await process_frame
			await create_timer(5.0).timeout
			for i in 4:
				await process_frame
			var draws: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			if cpu:
				var ms: Array[float] = []
				for i in 20:
					await process_frame
					ms.append(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu())
				ms.sort()
				var line := "%s: render CPU median %.2f ms here, %.2f at Sean's (x0.65); %d draws" % [v, ms[10], ms[10] * 0.65, draws]
				print(line)
				lines.append(line)
				continue
			var path := "%s/%s%s.png" % [out_dir, v, suffix]
			vp.get_texture().get_image().save_png(path)
			print("saved %s (%d draws)" % [path, draws])
	if cpu:
		FileAccess.open(out_dir + "/cpu.txt", FileAccess.WRITE).store_string("\n".join(lines) + "\n")
	quit()


## A variant's dials (the doctor's light_views.gd): the spec's `light` numbers and RoomLight's.
func _apply(building: Node3D, dials: Dictionary) -> void:
	if dials.is_empty():
		return
	var probe := building.get_node_or_null(^"InteriorAmbient") as ReflectionProbe
	for k: String in dials:
		var v: float = dials[k]
		if k == "day_fill":
			probe.set_meta(&"day_ambient", v)
		elif k == "window_day":
			building.set_meta(&"room_window_gain", v)
		elif k.begins_with("room."):
			# (RoomLight can't be named here: an -s script compiles it before the autoloads.)
			load("res://config/room_light.tres").set(StringName(k.substr(5)), v)
		else:
			push_error("unknown dial " + k)
	print("variant: %s" % [dials])
	var rl := root.get_tree().get_first_node_in_group(&"room_light")
	if rl:
		rl.call(&"redo")
