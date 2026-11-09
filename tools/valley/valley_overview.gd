extends SceneTree
## The valley's greybox from straight overhead (Sean, 2026-11-09: a fresh one after every G step):
## the whole playable area (config/valley.json's envelope, 4.4 x 3.6 km) drawn orthographically,
## NORTH UP (-Z at the top, east to the right; the plan's maps are west-up), fog and haze off, the
## sun at `--hour` (noon), the ground at its finest level everywhere; and close views of the town,
## the canyon (the great trestle, Bridges A and B) and the west (the mine and the Ore Works) at more
## pixels a metre. Each is drawn in tiles (one game, its own viewport) and written as PNG with a
## manifest of what metre each pixel is; then tools/valley/valley_overview.py stitches them, lays the
## plan's lines and names over a copy (valley_plan.py's: roads, rail, creek, places) and writes the
## JPGs to experiments/valley/results/overview_*.jpg.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://tools/valley/valley_overview.gd -- [--ppm=1.0] [--hour=12] [--out=experiments/valley/results] [--only=whole,town,canyon,west] [--no-python]
##
## Lavapipe here (check the log's "Vulkan" line: without mesa-vulkan-drivers it's OpenGL). ~15 min.
## Untyped where it names game classes: -s scripts compile before autoloads exist.

## The views: name, the world rect (filled in from the plan at the start), pixels a metre (0: --ppm).
var views: Array = []
var ppm := 1.0
var hour := 12.0
var out_dir := "experiments/valley/results"
var only: PackedStringArray = []
var run_python := true
## A tile's side at most (px): lavapipe draws a big viewport slowly but surely; tiles keep memory down.
const TILE_PX := 2048
## The camera's height (m: the ground's highest is ~175) and how far it sees.
const CAM_Y := 600.0
const CAM_FAR := 1200.0
## Frames drawn before a tile is read (the ground's blocks shown, shadows and exposure settled).
const SETTLE_FRAMES := 6

var vp: SubViewport
var cam: Camera3D
var valley: Node3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ppm="):
			ppm = float(a.substr(6))
		elif a.begins_with("--hour="):
			hour = float(a.substr(7))
		elif a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
		elif a == "--no-python":
			run_python = false
	_run.call_deferred()


func _run() -> void:
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	# The ground at its finest level everywhere: its blocks split from any distance (this run only;
	# the resource isn't saved).
	var vt = load("res://config/valley_terrain.tres")
	vt.split = 1000.0
	vp = SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	root.add_child(vp)
	valley = load("res://scenes/valley.tscn").instantiate()
	vp.add_child(valley)
	await process_frame
	var player = valley.get_node_or_null(^"Player")
	if player:
		player.input_enabled = false
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = 1.0
	cam.far = CAM_FAR
	# Looking straight down, north (-Z) up the picture, east (+X) to the right.
	cam.basis = Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))
	valley.add_child(cam)
	cam.current = true
	_views()
	var day = valley.get_node_or_null(^"DayCycle")
	if day:
		day.set_time(hour)
		day.time_scale = 0.0
		day.held = true
	var sun := valley.get_node_or_null(^"Sun") as DirectionalLight3D
	if sun:
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
		sun.directional_shadow_max_distance = CAM_FAR
	var ground = valley.get_node_or_null(^"Ground")
	var t0 := Time.get_ticks_msec()
	if ground and ground.valley:
		ground.valley.focus = Vector3(0, CAM_Y, 0)
		ground.valley.prime(Vector3(0, CAM_Y, 0))
	print("ground at its finest: %.1f s, %d blocks" % [(Time.get_ticks_msec() - t0) / 1000.0, ground.valley.built if ground and ground.valley else 0])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/overview"))
	var manifest := {"hour": hour, "views": []}
	for v: Dictionary in views:
		if not only.is_empty() and not String(v.name) in only:
			continue
		manifest.views.append(await _draw(v))
	var mpath := ProjectSettings.globalize_path("res://build/overview/manifest.json")
	var f := FileAccess.open(mpath, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("manifest ", mpath)
	var code := 0
	if run_python:
		var out := []
		code = OS.execute("python3", [ProjectSettings.globalize_path("res://tools/valley/valley_overview.py"), "--manifest=" + mpath, "--out=" + out_dir], out, true)
		print("".join(out))
	quit(code)


## The views from the plan: the whole envelope; the town (its ground's rect and 60 m round); the
## canyon (Bridge A, the trestle's middle and Bridge B, 150 m round); the west (the mine's and the
## Ore Works' pads, 150 m round).
func _views() -> void:
	var lay = valley.layout
	var env: Rect2 = lay.envelope()
	views.append({"name": "whole", "rect": env, "ppm": ppm})
	var tr: Dictionary = (lay.town().get("ground", {}) as Dictionary).get("rect", {"x": [-175, 190], "z": [-125, 150]})
	var town := Rect2(Vector2(float(tr.x[0]), float(tr.z[0])), Vector2(float(tr.x[1]) - float(tr.x[0]), float(tr.z[1]) - float(tr.z[0]))).grow(60.0)
	views.append({"name": "town", "rect": town, "ppm": 4.0})
	var pl = valley.places()
	var canyon := Rect2()
	var first := true
	for id in [&"bridge_a", &"bridge_b", &"bridge_c"]:
		if pl.has(id):
			var p: Vector3 = pl.at(id)
			if first:
				canyon = Rect2(Vector2(p.x, p.z), Vector2.ZERO)
				first = false
			else:
				canyon = canyon.expand(Vector2(p.x, p.z))
	views.append({"name": "canyon", "rect": canyon.grow(150.0), "ppm": 2.0})
	var west := Rect2()
	first = true
	for id in ["mine", "ore_works"]:
		var p: Dictionary = lay.place(id)
		var c := Vector2(float(p.at[0]), float(p.at[1]))
		var pad: Dictionary = p.get("pad", {})
		var r := maxf(float(pad.get("w", 0.0)), float(pad.get("d", 0.0))) * 0.5
		var b := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
		west = b if first else west.merge(b)
		first = false
	views.append({"name": "west", "rect": west.grow(150.0), "ppm": 2.5})


## A view drawn tile by tile: each tile's camera over its middle, the tile read to a PNG.
func _draw(v: Dictionary) -> Dictionary:
	var rect: Rect2 = v.rect
	var p: float = v.ppm
	var w_px := roundi(rect.size.x * p)
	var h_px := roundi(rect.size.y * p)
	var nx := ceili(float(w_px) / TILE_PX)
	var nz := ceili(float(h_px) / TILE_PX)
	var tw := ceili(float(w_px) / nx)
	var th := ceili(float(h_px) / nz)
	vp.size = Vector2i(tw, th)
	cam.size = th / p
	var tiles := []
	var t0 := Time.get_ticks_msec()
	for j in nz:
		for i in nx:
			var x0 := rect.position.x + i * tw / p
			var z0 := rect.position.y + j * th / p
			cam.global_position = Vector3(x0 + tw / p * 0.5, CAM_Y, z0 + th / p * 0.5)
			_no_fog()
			for k in SETTLE_FRAMES:
				await process_frame
				_no_fog()
			var img := vp.get_texture().get_image()
			var path := "res://build/overview/%s_%d_%d.png" % [v.name, i, j]
			img.save_png(path)
			tiles.append({"file": ProjectSettings.globalize_path(path), "px": [i * tw, j * th]})
	print("%s: %d x %d px in %d x %d tiles, %.1f s" % [v.name, w_px, h_px, nx, nz, (Time.get_ticks_msec() - t0) / 1000.0])
	return {"name": v.name, "x0": rect.position.x, "z0": rect.position.y, "ppm": p, "width": w_px, "height": h_px, "tiles": tiles}


## Fog and haze off (the day's look may set them again as the sun moves: every frame).
func _no_fog() -> void:
	var we := valley.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment.fog_enabled = false
		we.environment.volumetric_fog_enabled = false
