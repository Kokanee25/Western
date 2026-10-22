extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The building lab's renders: the saloon built from its spec, set down in the game's own street
## (its sky, light and look) out in the desert where the material lab works, and drawn from the
## sheet's views (docs/concept/saloon-sheet.png) and Sean's saloon picture's, for the blind critic.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/building_lab/render.gd -- --out=DIR [--views=a,b]

const ORIGIN := Vector3(-72.0, 0.0, 26.0)
const HOURS := {"golden": 17.6, "night": 22.5}
## name -> [camera, look at, fov, light], in the building's space.
const VIEWS := {
	"front": [Vector3(7.62, 3.2, -24.0), Vector3(7.62, 5.2, 0.0), 45.0, "golden"],
	"side_east": [Vector3(36.0, 3.0, 8.0), Vector3(15.24, 4.6, 7.5), 45.0, "golden"],
	"front_night": [Vector3(7.62, 3.2, -24.0), Vector3(7.62, 5.2, 0.0), 45.0, "night"],
	"entrance": [Vector3(7.62, 2.35, 0.7), Vector3(8.24, 3.0, 12.0), 72.0, "night"],
	"from_balcony": [Vector3(13.84, 6.0, 1.3), Vector3(6.74, 0.8, 8.8), 72.0, "night"],
	"picture": [Vector3(10.64, 1.95, 9.7), Vector3(2.44, 1.7, 6.2), 62.0, "night"],
}

var _out := "user://building_lab"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--views="):
			only = Array(arg.substr(8).split(","))
	DirAccess.make_dir_recursive_absolute(_out)
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var viewport: SubViewport = main.get_node(^"GameViewport")
	var clock = street.get_node(^"DayCycle")
	clock.set_physics_process(false)
	var player = street.get_node(^"Player")
	player.input_enabled = false
	for w in player.weapons:
		w.visible = false
	var grass := street.find_child("DryGrass", true, false)
	if grass:
		grass.visible = false
	var building = load("res://experiments/building_lab/spec_building.gd").new()
	building.name = "SpecSaloon"
	building.position = ORIGIN
	street.add_child(building)
	var walk = load("res://src/structures/boardwalk.gd").new()
	walk.structure_id = &"spec_walk"
	walk.length = 16.44
	walk.top = 0.78
	walk.steps = [Vector2(7.62, 1.83)]
	walk.position = ORIGIN
	street.add_child(walk)
	var cam := Camera3D.new()
	cam.name = "LabCamera"
	street.add_child(cam)
	cam.current = true
	var mosaic: Script = load("res://src/render/depth_mosaic.gd")
	mosaic.apply(cam, settings.mosaic_active(), settings.MOSAIC_K, settings.MOSAIC_STEPS)
	for i in 30:
		await physics_frame
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		clock.set_time(HOURS[view[3]])
		for l in building.lamps:
			l.set_lit(view[3] == "night")
		cam.global_position = building.to_global(view[0])
		cam.look_at(building.to_global(view[1]), Vector3.UP)
		cam.fov = view[2]
		for i in 24:
			await process_frame
		var path := "%s/%s.png" % [_out, v]
		viewport.get_texture().get_image().save_png(path)
		print("saved %s" % path)
	quit()
