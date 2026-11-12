extends SceneTree
## The doctor's office lit as a room (#824, #821 pick 1): the four views the cheap judge sees before
## and after, in the game's own scene (the valley, the real look, its exposure), both prop batches in
## his rooms (experiments/prop_lab/doctor/dress.gd's `dress`). The doors' leaves are set aside as
## dress.gd does.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/doctor/light_views.gd -- \
##       --out=DIR [--views=desk,dispensary,window,night] [--size=1280x720] [--probe-test] [--cpu]
##
## --probe-test: after the views, the desk once more with the building's interior probe grown past
## its outer walls' inside boards (the review's inferred cause of the orange / blue-grey corner,
## docs/reviews/2026-11-doctor-room.md cause 1), saved as desk_probe.png.
## --cpu: each view's render CPU (the frame's CPU side, RenderingServer's measure; x0.65 for Sean's
## core as perf_bench scales) over 30 frames, printed and written to cpu.txt, no pictures.
## --variants=NAME:dial=v,dial=v;NAME2:...: each view once a variant, in one load, saved as
## <view>_<NAME>.png (#829's light trials). Dials: `day_fill` (the building's fill by day, its
## probe's `day_ambient`), `window_day` (its `room_window_gain`), `room.<RoomLightTuning dial>`.
## A variant's dials stay for the next ones; NAME `base` with no dials is the spec as it is.
## ~10 min a view under lavapipe; never two runs at once.

## name -> [camera, look at (the building's space; the ground floor at 0.95), fov, hour].
const VIEWS := {
	# The desk in the front office's west corner, the partition behind it and the yard wall beside it.
	"desk": [Vector3(2.05, 2.45, 1.95), Vector3(1.15, 1.75, 3.45), 56.0, 10.0],
	# The dispensary from inside its door, the shelving and his counter under the high window.
	"dispensary": [Vector3(5.75, 2.6, 4.2), Vector3(7.85, 1.75, 7.55), 66.0, 10.0],
	# The front office's west show window from inside, by morning light.
	"window": [Vector3(3.1, 2.5, 2.4), Vector3(1.85, 2.3, 0.0), 58.0, 10.0],
	# The surgery at night, its lamp lit.
	"night": [Vector3(3.6, 2.45, 4.3), Vector3(1.6, 1.25, 6.1), 66.0, 21.5],
}

var out_dir := "build/doctor_light"
var only: PackedStringArray = []
var size := Vector2i(1280, 720)
var probe_test := false
var cpu := false
var variants: Array = []  # [[name, {dial: value}]]
var shots_first: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a == "--probe-test":
			probe_test = true
		elif a == "--cpu":
			cpu = true
		elif a.begins_with("--variants="):
			for v: String in a.substr(11).split(";", false):
				var parts := v.split(":", true, 1)
				var dials := {}
				if parts.size() > 1:
					for kv: String in parts[1].split(",", false):
						var p := kv.split("=")
						dials[p[0]] = float(p[1])
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
	var building: Node3D = valley.get(&"buildings").get("doctor")
	if building == null:
		push_error("no doctor's building in the valley")
		quit(1)
		return
	for m in building.get_members():
		if String(m.member_id).contains("/door_"):
			building.unbatch(m)
			m.visible = false
	var dress = load("res://experiments/prop_lab/doctor/dress.gd")
	dress.dress(building, "D1")
	dress.dress(building, "D2")
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.name = "LightCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	print("lamps in the building: %d" % building.find_children("*", "OilLamp", true, false).size())
	var shots: Array = []
	for v: String in VIEWS:
		if only.is_empty() or only.has(v):
			shots.append([v, VIEWS[v]])
	if probe_test:
		shots.append(["desk_probe", VIEWS.desk])
	var vp_rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var cpu_lines: PackedStringArray = []
	if variants.is_empty():
		variants = [["", {}]]
	shots_first = shots[0]
	for var_: Array in variants:
		_apply(building, var_[1])
		for s: Array in shots:
			await _shot(s, var_[0], building, clock, cam, vp, vp_rid, cpu_lines)
	if cpu:
		FileAccess.open(out_dir + "/cpu.txt", FileAccess.WRITE).store_string("\n".join(cpu_lines) + "\n")
	quit()


func _apply(building: Node3D, dials: Dictionary) -> void:
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


## Each opening's light now (its reach, its sun patch), for the log.
func _print_openings(building: Node3D) -> void:
	var rl := root.get_tree().get_first_node_in_group(&"room_light")
	if rl == null:
		return
	for o: Dictionary in rl.call(&"openings_of", building):
		var p: Dictionary = o.get("patch", {})
		var sp := o.spot as SpotLight3D
		print("  %s %s %s: sky %.2f reach %.2f tilt %.0f%s" % [o.wall, o.kind, o.rect, sp.light_energy if sp else 0.0, float(o.get("reach", -1.0)), float(o.get("tilt", -1.0)),
				"" if p.is_empty() else "  sun patch at %s n %s gain %.3f" % [building.to_local(p.pos), p.normal, p.gain]])


func _shot(s: Array, variant: String, building: Node3D, clock: Node, cam: Camera3D, vp: SubViewport, vp_rid: RID, cpu_lines: PackedStringArray) -> void:
	var v: String = s[0]
	var view: Array = s[1]
	if v == "desk_probe":
		var probe := building.get_node_or_null(^"InteriorAmbient") as ReflectionProbe
		if probe:
			# To the wall lines (the inside boards ~0.12 m in, fully inside the box), blending
			# over the last 5 cm: the siding outside stays out of it.
			var was := probe.size
			probe.size = Vector3(building.get(&"width"), was.y, building.get(&"depth"))
			probe.blend_distance = 0.05
			print("probe %s -> %s" % [was, probe.size])
	if clock:
		clock.set_time(float(view[3]))
	cam.global_position = building.to_global(view[0])
	cam.look_at(building.to_global(view[1]), Vector3.UP)
	cam.fov = float(view[2])
	for i in 40:
		await process_frame
	await create_timer(5.0).timeout
	for i in 8:
		await process_frame
	if s == shots_first:
		_print_openings(building)
	print("%s: %d draw calls in the frame" % [v, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	if cpu:
		var ms: Array[float] = []
		for i in 30:
			await process_frame
			ms.append(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu())
		ms.sort()
		var line := "%s: render CPU median %.2f ms here, %.2f at Sean's (x0.65); %d draws" % [v, ms[15], ms[15] * 0.65,
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)]
		print(line)
		cpu_lines.append(line if variant == "" else variant + " " + line)
		return
	var path := "%s/%s.png" % [out_dir, v if variant == "" else v + "_" + variant]
	vp.get_texture().get_image().save_png(path)
	print("saved %s" % path)
