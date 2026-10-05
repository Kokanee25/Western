extends SceneTree
## A slow pan of a fixed view, frame by frame, to see how a look behaves in motion (docs/briefs/
## renderer.md: does the picture crawl or flicker as the camera turns?). Saves every frame, a
## strip of some of them, and two measures between consecutive frames (the flicker probe's,
## tools/flicker_probe.gd): the share of pixels that changed by more than 8/255, and the share
## that flipped and flipped back (A, B, A: an edge passing changes a pixel once; crawl and
## flicker change it back).
##
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://tools/pan_frames.gd -- \
##       --view=saloon_night --out=DIR [--frames=40] [--pan=20] [--label=default] [--blocks | --quantise-once | --no-mosaic]
##
## --view= a name from tools/screenshots.gd's VIEWS (its place, turn and hour; no staging).
## --pan= degrees turned over the whole pan (to the right). The look flags are Settings' own
## (--blocks, --quantise-once) or the mosaic off. Writes <out>/<label>_NNN.png, <label>_strip.png
## (every eighth frame, the first at full size) and <label>.json (the measures).

var view_name := "saloon_night"
var out := "user://pan"
var frames := 40
var pan := 20.0
var label := ""
var no_mosaic := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--view="):
			view_name = a.substr(7)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--frames="):
			frames = int(a.substr(9))
		elif a.begins_with("--pan="):
			pan = float(a.substr(6))
		elif a.begins_with("--label="):
			label = a.substr(8)
		elif a == "--no-mosaic":
			no_mosaic = true
	if label == "":
		label = view_name
	_run.call_deferred()


func _view() -> Array:
	var shots: Variant = load("res://tools/screenshots.gd")
	for v in shots.VIEWS:
		if v[0] == view_name:
			return v
	push_error("no view " + view_name)
	quit(1)
	return []


func _run() -> void:
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	settings.internal_resolution = Vector2i(1280, 720)
	if no_mosaic:
		settings.set_mosaic(false)
	DirAccess.make_dir_recursive_absolute(out)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var viewport: SubViewport = main.get_node(^"GameViewport")
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var clock = street.get_node(^"DayCycle")
	var player = street.get_node(^"Player")
	var town = main.find_child("TownLife", true, false)
	if town:
		town.gang_arrives = 1e9
	player.input_enabled = false
	clock.set_physics_process(false)
	var v := _view()
	if v.is_empty():
		return
	clock.set_time(v[1])
	player.global_position = v[2]
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, deg_to_rad(v[3]), 0.0)
	player.input_enabled = true
	player.add_look(Vector2(0.0, v[4] - player.get_pitch_degrees()))
	player.input_enabled = false
	for w in player.weapons:
		w.selected = false
		w.drawn = false
		w.visible = false
	for i in 90:
		await process_frame
	clock.set_process(false)
	var prev: PackedByteArray = PackedByteArray()
	var prev2: PackedByteArray = PackedByteArray()
	var changed := PackedFloat32Array()
	var flips := PackedFloat32Array()
	var strip: Image = null
	var w := 0
	var h := 0
	for f in frames:
		if f > 0:
			player.rotation.y -= deg_to_rad(pan / float(frames - 1))
		await process_frame
		await process_frame
		var img := viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		w = img.get_width()
		h = img.get_height()
		img.save_png(out.path_join("%s_%03d.png" % [label, f]))
		var data := img.get_data()
		if prev.size() == data.size():
			var n := w * h
			var c := 0
			var fl := 0
			for i in n:
				var j := i * 3
				var d := absi(data[j] - prev[j]) + absi(data[j + 1] - prev[j + 1]) + absi(data[j + 2] - prev[j + 2])
				if d > 24:
					c += 1
					if prev2.size() == data.size():
						var back := absi(data[j] - prev2[j]) + absi(data[j + 1] - prev2[j + 1]) + absi(data[j + 2] - prev2[j + 2])
						var went := absi(prev[j] - prev2[j]) + absi(prev[j + 1] - prev2[j + 1]) + absi(prev[j + 2] - prev2[j + 2])
						if back <= 12 and went > 24:
							fl += 1
			changed.append(float(c) / float(n))
			flips.append(float(fl) / float(n))
		prev2 = prev
		prev = data
		if f % 8 == 0:
			var small := img.duplicate()
			small.resize(w / 4, h / 4, Image.INTERPOLATE_NEAREST)
			if strip == null:
				strip = Image.create(w / 4 * ((frames + 7) / 8), h / 4, false, Image.FORMAT_RGB8)
			strip.blit_rect(small, Rect2i(0, 0, w / 4, h / 4), Vector2i(w / 4 * (f / 8), 0))
	if strip:
		strip.save_png(out.path_join("%s_strip.png" % label))
	var mean_c := 0.0
	var mean_f := 0.0
	for x in changed:
		mean_c += x
	for x in flips:
		mean_f += x
	mean_c /= maxf(changed.size(), 1.0)
	mean_f /= maxf(flips.size(), 1.0)
	var report := {"view": view_name, "label": label, "frames": frames, "pan_degrees": pan,
			"changed_mean": mean_c, "flipped_back_mean": mean_f, "changed": changed, "flipped_back": flips}
	var fh := FileAccess.open(out.path_join("%s.json" % label), FileAccess.WRITE)
	fh.store_string(JSON.stringify(report, " "))
	fh.close()
	print("%s %s: %d frames over %.1f deg: changed %.3f%% a frame, flipped back %.3f%%"
			% [label, view_name, frames, pan, mean_c * 100.0, mean_f * 100.0])
	quit()
