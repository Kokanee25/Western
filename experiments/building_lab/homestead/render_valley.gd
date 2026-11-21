extends SceneTree
## Harlan's homestead in the game's own light (#1126, the building lab's step 5): the game's main scene
## in the valley (its real look), the homestead built on its pad by ValleyWorld (Homestead), drawn from
## the target sheet's views (sheet/request.json) by our camera: outside in the late-afternoon sun from
## the lane, the yard, the barn and the spring; inside the cabin by day. The store's render_valley.gd's
## twin. Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/homestead/render_valley.gd -- \
##       --out=DIR [--views=lane,inside] [--size=1280x720] [--cpu]
##
## ~10 min a view under lavapipe; never two runs at once.

## name -> [camera, look at (the pad's space: x east from its west edge, z south from its north edge, y
## over the pad; a negative y: that much over the ground there), fov, hour, inside].
const VIEWS := {
	"yard": [Vector3(15.5, -1.7, -13.0), Vector3(14.0, 2.0, 14.0), 55.0, 17.0, false],
	"cabin_front": [Vector3(8.6, 1.7, 3.2), Vector3(8.0, 2.1, 13.0), 55.0, 17.0, false],
	"cabin_back": [Vector3(15.0, 1.7, 20.5), Vector3(9.5, 2.0, 15.0), 58.0, 17.0, false],
	"barn": [Vector3(13.5, 1.7, 8.5), Vector3(21.5, 1.8, 15.5), 58.0, 17.0, false],
	"spring": [Vector3(67.0, -1.8, -43.0), Vector3(20.0, 1.0, 12.0), 55.0, 17.0, false],
	"inside": [Vector3(8.5, 2.2, 13.75), Vector3(6.6, 1.3, 17.2), 74.0, 10.5, true],
}

var out_dir := "build/homestead_renders"
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
	var home: Node3D = valley.get(&"homesteads").get("harlan_homestead")
	if home == null:
		push_error("no harlan_homestead in the valley")
		quit(1)
		return
	var building: Node3D = home.buildings.cabin
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
	cam.name = "HomesteadCamera"
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
			cam.global_position = home.to_global(_on(home, view[0]))
			cam.look_at(home.to_global(_on(home, view[1])), Vector3.UP)
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


## A view's point in the pad's space; a negative y is that much over the ground there (off the pad).
func _on(home: Node3D, p: Vector3) -> Vector3:
	if p.y < 0.0:
		return Vector3(p.x, home.ground_at(p.x, p.z) - p.y, p.z)
	return p
