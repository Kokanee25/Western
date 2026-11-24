extends SceneTree
## The Salt Creek Hotel in the game's own light (the building lab's step 5, #1220): the game's main scene
## in the valley (its real look, exposure and grade), the hotel built on its lot by ValleyWorld (its cellar
## and the drift dug), drawn from the target sheet's views (sheet/request.json) by our camera. The
## undertaker's render_valley.gd with the hotel's views. Untyped where it names game classes: -s scripts
## compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/hotel/render_valley.gd -- \
##       --out=DIR [--views=front,gallery] [--size=1280x720] [--cpu]
##
## ~10-15 min a view under lavapipe; never two runs at once.

## name -> [camera, look at (the building's space: x along the front from its EAST corner (west is +x),
## z back from the front, y over the walk's street edge's ground; the floor at 0.75, the upper's at 4.87,
## the cellar's flags at -1.92), fov, hour, inside]. Outside by an afternoon sun on the south front;
## inside each camera at the room's far end, the leaves set aside; the cellar by its lamps.
const VIEWS := {
	"front": [Vector3(15.5, 1.7, -19.5), Vector3(12.0, 5.0, 0.0), 60.0, 15.5, false],
	"gallery": [Vector3(3.5, 1.65, -8.5), Vector3(11.0, 5.2, -1.2), 64.0, 16.0, false],
	"lobby": [Vector3(9.6, 2.35, 0.75), Vector3(15.2, 2.3, 7.9), 72.0, 15.0, true],
	"bar": [Vector3(17.95, 2.3, 7.9), Vector3(23.0, 1.7, 1.2), 72.0, 15.0, true],
	"cellar": [Vector3(18.6, -0.35, 4.0), Vector3(24.0, -1.3, 9.45), 74.0, 12.0, true],
}

var out_dir := "build/hotel_renders"
var only: PackedStringArray = []
var size := Vector2i(1280, 720)
var cpu := false
## --variants=NAME:dial=v,dial=v;NAME2:...: each view once a variant (the doctor's light_views.gd dials:
## day_fill, window_day), saved as <view>_<NAME>.png: the light trials (#1035).
var variants: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--variants="):
			for part in a.substr(11).split(";"):
				var kv := part.split(":")
				var dials := {}
				for d in kv[1].split(","):
					var e := d.split("=")
					dials[e[0]] = float(e[1])
				variants.append([kv[0], dials])
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
	var building: Node3D = valley.get(&"buildings").get("hotel")
	if building == null:
		push_error("no hotel in the valley")
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
	cam.name = "HotelCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	print("lamps in the building: %d" % building.find_children("*", "OilLamp", true, false).size())
	var vp_rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var cpu_lines: PackedStringArray = []
	if variants.is_empty():
		variants = [["", {}]]
	for var_: Array in variants:
		_apply(building, var_[1])
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
			var path := "%s/%s%s.png" % [out_dir, v, "" if var_[0] == "" else "_" + String(var_[0])]
			vp.get_texture().get_image().save_png(path)
			print("saved %s (%d draws)" % [path, draws])
	if cpu:
		FileAccess.open(out_dir + "/cpu.txt", FileAccess.WRITE).store_string("\n".join(cpu_lines) + "\n")
	quit()


func _apply(building: Node3D, dials: Dictionary) -> void:
	var probe := building.get_node_or_null(^"InteriorAmbient") as ReflectionProbe
	for k: String in dials:
		if k == "day_fill":
			probe.set_meta(&"day_ambient", float(dials[k]))
		elif k == "window_day":
			building.set_meta(&"room_window_gain", float(dials[k]))
		else:
			push_error("unknown dial " + k)
	print("variant: %s" % [dials])
	var rl := root.get_tree().get_first_node_in_group(&"room_light")
	if rl:
		rl.call(&"redo")
