extends SceneTree
## #1053: the store's light measured with grey cards (from #1052's review, light_review.gd.txt): the variants'
## dials `max_area` (RoomLight's cap), `exposure` (RealLook's exposure_indoor), `day_fill`, `window_day`.
## The general store in the game's own light (the building lab's step 4-5, #1035): the game's main scene in the
## valley (its real look, exposure and grade), the jail built on its lot by ValleyWorld, drawn from
## the target sheet's views (sheet/request.json) by our camera, the rooms lit as the doctor's are
## (#824, #829: lamps by night, the windows by day). Its doctor's twins: doctor/render_valley.gd
## (the sheet's views) and doctor/light_views.gd (--cpu). Untyped where it names game classes: -s
## scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/store/render_valley.gd -- \
##       --out=DIR [--views=front,office] [--size=1280x720] [--cpu]
##
## --cpu: each view's render CPU too (RenderingServer's measure, x0.65 for Sean's core as perf_bench
## scales) over 30 frames, printed and written to cpu.txt.
## ~10 min a view under lavapipe (start it with the real look: the default); never two runs at once.

## name -> [camera, look at (the building's space: x along the front from its EAST corner (west is +x),
## z back from the front, y over the street edge's ground; the shop's floor at 1.1, the loft's at 5.0, the
## cellar's at -1.4), fov, hour, inside]. Outside by the sheet's late-afternoon sun from the south-west;
## inside each camera at the room's far end, clear of every door's leaf (the leaves are set aside for
## the inside views), by day; the shop again by lamplight.
const VIEWS := {
	"shop12": [Vector3(8.4, 2.75, 1.6), Vector3(8.4, 2.6, 10.0), 72.0, 12.0, true],
	"counter12": [Vector3(8.4, 2.75, 10.3), Vector3(8.4, 2.7, 0.5), 72.0, 12.0, true],
	"shop16": [Vector3(8.4, 2.75, 1.6), Vector3(8.4, 2.6, 10.0), 72.0, 16.0, true],
	"counter16": [Vector3(8.4, 2.75, 10.3), Vector3(8.4, 2.7, 0.5), 72.0, 16.0, true],
	"front12": [Vector3(8.4, 1.75, -17.0), Vector3(8.4, 4.2, 0.0), 52.0, 12.0, false],
	"entry12": [Vector3(6.2, 1.75, -6.5), Vector3(8.4, 2.6, 0.6), 60.0, 12.0, false],
	"ceiling12": [Vector3(14.0, 2.2, 9.6), Vector3(6.0, 4.4, 3.0), 72.0, 12.0, true],
}
## Grey cards (18% linear, matte) on the shop floor and the back wall: [name, centre, normal].
const CARDS := [["front", Vector3(8.4, 1.12, 2.5), Vector3.UP], ["mid", Vector3(8.4, 1.12, 5.5), Vector3.UP],
	["back", Vector3(8.4, 1.12, 9.3), Vector3.UP], ["side", Vector3(3.0, 1.12, 8.5), Vector3.UP],
	["backwall", Vector3(4.5, 2.6, 10.68), Vector3.FORWARD]]

var out_dir := "build/store_renders"
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
	var building: Node3D = valley.get(&"buildings").get("general_store")
	if building == null:
		push_error("no general_store in the valley")
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
	cam.name = "StoreCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.18, 0.18, 0.18).linear_to_srgb()
	card_mat.roughness = 1.0
	card_mat.metallic_specular = 0.0
	var cards := []
	for c: Array in CARDS:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.5, 0.5)
		mi.mesh = pm
		mi.material_override = card_mat
		building.add_child(mi)
		var n: Vector3 = c[2]
		mi.position = c[1]
		if n == Vector3.FORWARD:
			mi.rotation_degrees = Vector3(-90, 0, 0)
		cards.append([c[0], mi])
	var log_lines: PackedStringArray = []
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
			var rlk := root.get_tree().get_first_node_in_group(&"real_look")
			if rlk and rlk.get(&"_attributes"):
				print("exposure ", rlk.get(&"_attributes").exposure_multiplier, " indoors ", rlk.get(&"_indoors"), " adapted ", rlk.get(&"_adapted"))
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
			var img := vp.get_texture().get_image()
			img.save_png(path)
			var vals := []
			for c: Array in cards:
				var p: Vector3 = (c[1] as Node3D).global_position
				if cam.is_position_behind(p):
					continue
				var sp := cam.unproject_position(p) * Vector2(size) / Vector2(vp.size)
				var acc := Color(0, 0, 0)
				var k := 0
				for dx in range(-2, 3):
					for dy in range(-2, 3):
						var q := Vector2i(int(sp.x) + dx, int(sp.y) + dy)
						if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
							acc += img.get_pixelv(q)
							k += 1
				if k > 0:
					vals.append("%s %.3f" % [c[0], (acc / k).get_luminance()])
			var ll := "%s %s: %s" % [v, var_[0], ", ".join(vals)]
			print(ll)
			log_lines.append(ll)
			print("saved %s (%d draws)" % [path, draws])
	FileAccess.open(out_dir + "/cards.txt", FileAccess.WRITE).store_string("\n".join(log_lines) + "\n")
	if cpu:
		FileAccess.open(out_dir + "/cpu.txt", FileAccess.WRITE).store_string("\n".join(cpu_lines) + "\n")
	quit()


func _apply(building: Node3D, dials: Dictionary) -> void:
	var probe := building.get_node_or_null(^"InteriorAmbient") as ReflectionProbe
	for k: String in dials:
		if k == "day_fill":
			probe.set_meta(&"day_ambient", float(dials[k]))
		elif k == "exposure":
			load("res://src/render/real_look.gd").dials["exposure_indoor"] = float(dials[k])
		elif k == "max_area":
			var rlc = load("res://src/render/room_light.gd")
			rlc.tune().opening_max_area = float(dials[k])
		elif k == "window_day":
			building.set_meta(&"room_window_gain", float(dials[k]))
		else:
			push_error("unknown dial " + k)
	print("variant: %s" % [dials])
	var rl := root.get_tree().get_first_node_in_group(&"room_light")
	if rl:
		rl.call(&"redo")
