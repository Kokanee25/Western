extends SceneTree
## #1053: the other buildings' rooms re-checked after RoomLight's window cap (2.5 -> 12 m2) and the indoor
## exposure (RealLook exposure_indoor): each view rendered with the old light (`old`: max_area 2.5, exposure
## x1.05 indoors as out) and the new (`new`: the defaults), saved as <view>_<variant>.png, with the frame's mean
## luminance and its middle's, the exposure in use. Views from each building's render_valley.gd (its space).
## Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/light_recheck.gd -- \
##       --out=DIR [--views=doctor_office,...] [--variants=old,new] [--size=800x450] (one variant a run: a redo in
##       place stalled the second)

## name -> [valley building, camera, look at, fov, hour]
const VIEWS := {
	"doctor_office": ["doctor", Vector3(7.9, 2.55, 0.7), Vector3(2.5, 2.0, 3.6), 72.0, 12.0],
	"jail_office": ["jail", Vector3(10.05, 2.25, 6.6), Vector3(0.6, 1.5, 2.6), 70.0, 12.0],
	"saloon_b_door": ["saloon", Vector3(14.4, 2.6, 2.6), Vector3(4.5, 2.6, 10.5), 72.0, 12.0],
	"saloon_b_bar": ["saloon", Vector3(1.2, 2.65, 12.3), Vector3(12.0, 2.4, 3.5), 72.0, 15.5],
}
const VARIANTS := [["old", 2.5, 1.05], ["new", -1.0, -1.0]]

var out_dir := "build/light/recheck"
var only: PackedStringArray = []
var size := Vector2i(800, 450)
var variants: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--variants="):
			variants = a.substr(11).split(",")
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
		player.global_position = Vector3(0, -50, 0)
	for l in valley.find_children("*", "Label3D", true, false):
		l.visible = false
	# The doors' leaves out of the way inside (the buildings' own scripts do).
	for key in ["doctor", "jail", "saloon"]:
		var b: Node3D = valley.get(&"buildings").get(key)
		if b == null:
			continue
		for m in b.get_members():
			if String(m.member_id).contains("/door_"):
				b.unbatch(m)
				m.visible = false
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	var rl_script = load("res://src/render/room_light.gd")
	var look = load("res://src/render/real_look.gd")
	var cap0: float = rl_script.tune().opening_max_area
	var exp0: float = look.dials["exposure_indoor"]
	var lines: PackedStringArray = []
	for var_: Array in VARIANTS:
		if not variants.is_empty() and not variants.has(var_[0]):
			continue
		rl_script.tune().opening_max_area = cap0 if float(var_[1]) < 0.0 else float(var_[1])
		look.dials["exposure_indoor"] = exp0 if float(var_[2]) < 0.0 else float(var_[2])
		var rl := root.get_tree().get_first_node_in_group(&"room_light")
		if rl:
			rl.call(&"redo")
		for v: String in VIEWS:
			if not only.is_empty() and not only.has(v):
				continue
			var view: Array = VIEWS[v]
			var b: Node3D = valley.get(&"buildings").get(view[0])
			if b == null:
				push_error("no building %s" % view[0])
				continue
			if clock:
				clock.set_time(float(view[4]))
			cam.global_position = b.to_global(view[1])
			cam.look_at(b.to_global(view[2]), Vector3.UP)
			cam.fov = float(view[3])
			for i in 40:
				await process_frame
			await create_timer(5.0).timeout
			for i in 8:
				await process_frame
			var img := vp.get_texture().get_image()
			var path := "%s/%s_%s.png" % [out_dir, v, var_[0]]
			img.save_png(path)
			var all := 0.0
			var mid := 0.0
			var n := 0
			var nm := 0
			for y in range(0, img.get_height(), 4):
				for x in range(0, img.get_width(), 4):
					var l := img.get_pixel(x, y).get_luminance()
					all += l
					n += 1
					if absf(x - img.get_width() * 0.5) < img.get_width() * 0.25 and absf(y - img.get_height() * 0.5) < img.get_height() * 0.25:
						mid += l
						nm += 1
			var rlk := root.get_tree().get_first_node_in_group(&"real_look")
			var ex: float = rlk.get(&"_attributes").exposure_multiplier if rlk and rlk.get(&"_attributes") else -1.0
			var line := "%s %s: mean %.3f, middle %.3f, exposure x%.2f" % [v, var_[0], all / n, mid / nm, ex]
			print(line)
			lines.append(line)
	FileAccess.open(out_dir + "/recheck_%s.txt" % ",".join(variants), FileAccess.WRITE).store_string("\n".join(lines) + "\n")
	quit()
