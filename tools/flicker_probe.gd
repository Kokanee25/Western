extends SceneTree
## Flicker on a still camera: renders N frames in a row from a fixed view and maps which pixels
## change between frames. Nothing in view is meant to move (the clock is stopped, the gun's out of
## hand), so what changes is flicker. Switch suspects off to find which it is.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://tools/flicker_probe.gd -- \
##       --view=saloon_night [--frames=24] [--off=ssao,volfog,...] [--off-script=res://path.gd] [--out=/tmp/flick]
## --view= a name from tools/screenshots.gd's VIEWS, or x,y,z,yaw,pitch,hour.
## --off-script= a script with `func off(street: Node3D, main: Node) -> void` run before capture.
## --pan=degrees: turn the view this much over the capture (flicker that only shows moving).
## --verbose: each frame's share of changed pixels (a pop shows as one big number).
## --clock: let the day go on (the sun and moon move a little every tick, as in play).
## Prints the share of pixels that changed by more than 8/255 between consecutive frames (mean
## and worst), and the share that flipped and flipped back (A, B, A: on a smooth pan an edge
## passing changes a pixel once; flicker changes it back), and writes <out>/<label>_first.png,
## <label>_heat.png (red = changed often) and <label>_flips.png (cyan = flipped back).

const OFFS := ["ssao", "volfog", "glow", "fog", "lamp_flicker", "lamp_shadows", "all_shadows",
		"sun_shadow", "finish", "tiles", "min_square", "batch", "people", "fog_volumes", "probes",
		"lights", "omni", "mosaic"]

var frames := 24
var view := "saloon_night"
var offs: PackedStringArray = []
var off_script := ""
var out := "/tmp/flicker"
var label := ""
var pan := 0.0
var clock_runs := false
var verbose := false
var _off_obj


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="):
			frames = int(a.substr(9))
		elif a.begins_with("--view="):
			view = a.substr(7)
		elif a.begins_with("--off="):
			offs = a.substr(6).split(",", false)
		elif a.begins_with("--off-script="):
			off_script = a.substr(13)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--label="):
			label = a.substr(8)
		elif a.begins_with("--pan="):
			pan = float(a.substr(6))
		elif a == "--clock":
			clock_runs = true
		elif a == "--verbose":
			verbose = true
	if label == "":
		label = view.replace(",", "_") + ("_off_" + "+".join(offs) if not offs.is_empty() else "")
	_run.call_deferred()


func _run() -> void:
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	settings.internal_resolution = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(out)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var viewport: SubViewport = main.get_node(^"GameViewport")
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var clock = street.get_node(^"DayCycle")
	var player = street.get_node(^"Player")
	player.input_enabled = false
	clock.set_physics_process(false)
	var v := _view()
	clock.set_time(v[5])
	player.global_position = Vector3(v[0], v[1], v[2])
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, deg_to_rad(v[3]), 0.0)
	player.input_enabled = true
	player.add_look(Vector2(0.0, v[4] - player.get_pitch_degrees()))
	player.input_enabled = false
	for w in player.weapons:
		w.selected = false
		w.drawn = false
		w.visible = false
	if clock_runs:
		clock.set_physics_process(true)
	for i in 90:
		await process_frame
	if not clock_runs:
		clock.set_process(false)
	for o in offs:
		_off(o, street, main)
	if off_script != "":
		_off_obj = load(off_script).new()  # kept: an off-script may watch frames
		_off_obj.off(street, main)
	for i in 30:
		await process_frame
	var prev: Image = null
	var prev2 := PackedByteArray()
	var heat := PackedInt32Array()
	var flips := PackedInt32Array()
	var flip_shares := PackedFloat32Array()
	var shares := PackedFloat32Array()
	var w := 0
	var h := 0
	var first: Image = null
	for f in frames:
		if pan != 0.0:
			player.rotation.y += deg_to_rad(pan / frames)
		await process_frame
		var img := viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		if prev == null:
			w = img.get_width()
			h = img.get_height()
			heat.resize(w * h)
			flips.resize(w * h)
			first = img
		else:
			var a := prev.get_data()
			var b := img.get_data()
			var changed := 0
			var flipped := 0
			var has2 := prev2.size() == b.size()
			for i in w * h:
				var k := i * 3
				var d := maxi(absi(a[k] - b[k]), maxi(absi(a[k + 1] - b[k + 1]), absi(a[k + 2] - b[k + 2])))
				if d > 8:
					heat[i] += 1
					changed += 1
					# Back to what it was two frames ago: it flipped and flipped back.
					if has2 and maxi(absi(prev2[k] - b[k]), maxi(absi(prev2[k + 1] - b[k + 1]), absi(prev2[k + 2] - b[k + 2]))) <= 4:
						flips[i] += 1
						flipped += 1
			shares.append(float(changed) / (w * h))
			if has2:
				flip_shares.append(float(flipped) / (w * h))
			prev2 = a
		prev = img
	var mean := 0.0
	var worst := 0.0
	for s in shares:
		mean += s / shares.size()
		worst = maxf(worst, s)
	var fmean := 0.0
	for s in flip_shares:
		fmean += s / maxf(flip_shares.size(), 1)
	if verbose:
		print("FRAMES %s: %s" % [label, " ".join(Array(shares).map(func(x: float) -> String: return "%.2f" % (x * 100.0)))])
	print("FLICKER %s: mean %.3f%%, worst %.3f%% of pixels change >8/255 frame to frame; %.3f%% flip and flip back (%d frames)" % [label, mean * 100.0, worst * 100.0, fmean * 100.0, frames])
	first.save_png("%s/%s_first.png" % [out, label])
	var hm := first.duplicate()
	for y in h:
		for x in w:
			var n := heat[y * w + x]
			var c := first.get_pixel(x, y).darkened(0.75)
			if n > 0:
				c = Color(1.0, 0.15, 0.1).lerp(Color(1, 1, 0.3), clampf(float(n) / (frames - 1), 0.0, 1.0))
			hm.set_pixel(x, y, c)
	hm.save_png("%s/%s_heat.png" % [out, label])
	var fm := first.duplicate()
	for y in h:
		for x in w:
			var n := flips[y * w + x]
			fm.set_pixel(x, y, Color(0.2, 1.0, 1.0).lerp(Color(1, 1, 1), clampf(float(n) / 4.0, 0.0, 1.0)) if n > 0 else first.get_pixel(x, y).darkened(0.75))
	fm.save_png("%s/%s_flips.png" % [out, label])
	quit()


func _view() -> Array:
	if view.count(",") == 5:
		var p := view.split(",")
		return [float(p[0]), float(p[1]), float(p[2]), float(p[3]), float(p[4]), float(p[5])]
	for v in load("res://tools/screenshots.gd").VIEWS:
		if v[0] == view:
			return [v[2].x, v[2].y, v[2].z, v[3], v[4], v[1]]
	push_error("no view " + view)
	return [0, 0, 0, 0, 0, 12]


func _env(street: Node) -> Environment:
	var we := street.find_child("WorldEnvironment", true, false) as WorldEnvironment
	return we.environment if we else null


func _off(o: String, street: Node3D, main: Node) -> void:
	var env := _env(street)
	match o:
		"ssao":
			env.ssao_enabled = false
		"volfog":
			env.volumetric_fog_enabled = false
		"glow":
			env.glow_enabled = false
		"fog":
			env.fog_enabled = false
		"lamp_flicker":
			for n in street.find_children("*", "", true, false):
				if n.get_script() and (n.get_script() as Script).get_global_name() == &"OilLamp":
					n.set_process(false)
		"lamp_shadows", "omni":
			for l in street.find_children("*", "OmniLight3D", true, false):
				(l as Light3D).shadow_enabled = false
		"all_shadows":
			for l in street.find_children("*", "Light3D", true, false):
				(l as Light3D).shadow_enabled = false
		"sun_shadow":
			for l in street.find_children("*", "DirectionalLight3D", true, false):
				(l as Light3D).shadow_enabled = false
		"lights":
			for l in street.find_children("*", "Light3D", true, false):
				if not l is DirectionalLight3D:
					(l as Light3D).visible = false
		"finish":
			root.get_node(^"Settings").set_finish(false)
		"tiles":
			root.get_node(^"Settings").set_tile_look(&"off")
		"mosaic":
			root.get_node(^"Settings").set_mosaic(false)
		"min_square":
			RenderingServer.global_shader_parameter_set(&"min_square_px", 0.0)
		"batch":
			for b in street.find_children("*", "", true, false):
				if b.get_script() and (b.get_script() as Script).get_global_name() == &"StaticBatch":
					b.release(street)
		"people":
			for p in street.get_tree().get_nodes_in_group(&"people"):
				(p as Node3D).visible = false
		"fog_volumes":
			for f in street.find_children("*", "FogVolume", true, false):
				(f as Node3D).visible = false
		"probes":
			for p in street.find_children("*", "ReflectionProbe", true, false):
				(p as Node3D).visible = false
		_:
			push_error("unknown --off " + o + "; known: " + ", ".join(OFFS))
