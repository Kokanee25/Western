extends SceneTree
## Saloon B's placed props (#950: its spec's `dressing`, S1-S3) in their rooms, for the blind critic:
## the building built from its spec as the game builds it (SpecBuilding, PropDressing), set down in
## the game's own street out in the desert (the building lab's spot, play.gd's ORIGIN), drawn by lamp
## or by day. The valley's own render (saloon_b/render_frame.gd) needs ~10 GB; this one fits a 7 GB
## sandbox. Untyped where it names game classes: -s scripts compile before autoloads.
##
##   VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json xvfb-run -a godot --rendering-driver vulkan \
##       -s res://experiments/prop_lab/saloon/place_views.gd -- --out=DIR [--views=a,b] [--size=1280x720]
##
## ~10 min a view under lavapipe; never two runs at once.

## name -> [camera, look at (the building's space: x from its east corner, z back from Main Street,
## the ground floor at 0.95), fov, hour].
const VIEWS := {
	# The bar room from by the card tables: the bar, its arm rail and glasses, the back bar's bottles,
	# the hanging lamps lit over the drinkers, the box stove.
	"bar_night": [Vector3(7.4, 2.55, 1.2), Vector3(1.6, 1.45, 7.5), 66.0, 21.5],
	"bar_day": [Vector3(7.4, 2.55, 1.2), Vector3(1.6, 1.45, 7.5), 66.0, 14.0],
	# Behind the bar, the bartender's aisle: the work boards, the slat mats, the till and scales.
	"aisle_night": [Vector3(1.0, 2.6, 1.9), Vector3(1.2, 1.2, 8.0), 62.0, 21.5],
	# The well: No Law's table under the chandelier, the piano and the faro bank by the arch.
	"well_night": [Vector3(12.4, 2.6, 2.6), Vector3(11.0, 1.2, 10.5), 66.0, 21.5],
	# The gaming room: the faro table under its shaded lamp, the wheel on the wall.
	"gaming_night": [Vector3(11.9, 2.5, 14.1), Vector3(7.5, 1.6, 18.0), 66.0, 21.5],
	# S5 (#1030), the walls: the bar room's back wall from the card tables (the clock by the bar's end,
	# the deer head over the store room's door, the skull over the arch).
	"back_wall_night": [Vector3(6.6, 2.5, 6.4), Vector3(4.6, 2.55, 13.36), 70.0, 21.5],
	"back_wall_day": [Vector3(6.6, 2.5, 6.4), Vector3(4.6, 2.55, 13.36), 70.0, 14.0],
	# The back bar stocked, the rifle over it, the nude's corner (its front end) beyond.
	"back_bar_night": [Vector3(5.6, 2.35, 9.8), Vector3(0.3, 2.7, 4.0), 66.0, 21.5],
	# The booze (#1222): the back bar's labelled bottles by lamplight at 1 m (the bartender in his aisle) and
	# at 3 m (a drinker across the bar): the labels legible close, a blur of colour across the bar.
	"booze_1m_night": [Vector3(1.32, 2.5, 6.15), Vector3(0.3, 2.5, 6.0), 50.0, 21.5],
	"booze_3m_night": [Vector3(3.25, 2.6, 6.6), Vector3(0.3, 2.5, 6.0), 50.0, 21.5],
	# The clock close, from the bar's end (a man reading the time).
	"clock_night": [Vector3(3.3, 2.6, 11.6), Vector3(2.9, 2.75, 13.36), 50.0, 21.5],
	# The dressing room (room 6, the upper floor at 4.91): the mirror, the pegs and trunk, the screen.
	"dressing_night": [Vector3(1.55, 6.55, 15.75), Vector3(1.3, 5.6, 20.6), 72.0, 21.5],
}

var _out := "user://saloon_b_place"
var _size := Vector2i(1280, 720)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only: Array = []
	var without := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--without="):
			# A dressing batch left out (#1030: S5's cost, its draw calls with and without).
			without = arg.substr(10)
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--views="):
			only = Array(arg.substr(8).split(","))
		elif arg.begins_with("--size="):
			var s := arg.substr(7).split("x")
			_size = Vector2i(int(s[0]), int(s[1]))
	DirAccess.make_dir_recursive_absolute(_out)
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var viewport: SubViewport = main.get_node(^"GameViewport")
	viewport.size = _size
	var clock = street.get_node(^"DayCycle")
	clock.set_physics_process(false)
	var player = street.get_node(^"Player")
	player.input_enabled = false
	for w in player.weapons:
		w.visible = false
	var building = load("res://src/structures/spec_building.gd").new()
	building.name = "SaloonB"
	building.spec_path = "res://config/buildings/saloon_b.json"
	if without != "":
		var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(building.spec_path))
		for b in without.split(","):
			(spec.dressing.batches as Dictionary).erase(b)
		var f := FileAccess.open("user://saloon_b_without.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(spec))
		f.close()
		building.spec_path = "user://saloon_b_without.json"
	building.position = load("res://experiments/building_lab/play.gd").ORIGIN
	street.add_child(building)
	var cam := Camera3D.new()
	cam.name = "LabCamera"
	street.add_child(cam)
	cam.current = true
	var mosaic: Script = load("res://src/render/depth_mosaic.gd")
	mosaic.apply(cam, settings.mosaic_active(), settings.MOSAIC_K, settings.MOSAIC_STEPS)
	for i in 120:
		await physics_frame  # the kit props set down and join their batches
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		clock.set_time(view[3])
		var night: bool = float(view[3]) >= 17.0 or float(view[3]) < 4.0
		for l in building.find_children("*", "OilLamp", true, false):
			l.set_lit(night)  # every lamp, the dressing's in the props too
		for i in 4:
			await physics_frame
		cam.global_position = building.to_global(view[0])
		cam.look_at(building.to_global(view[1]), Vector3.UP)
		cam.fov = view[2]
		for i in 24:
			await process_frame
		print("%s: %d draw calls, %d objects, %d primitives" % [v,
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
				RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
		var path := "%s/%s.png" % [_out, v]
		viewport.get_texture().get_image().save_png(path)
		print("saved %s" % path)
	quit()
