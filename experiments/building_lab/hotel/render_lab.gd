extends SceneTree
## The hotel built from its spec in the game's own street (its sky, light and look), out in the desert
## where the building lab works, drawn from a few views (#1226: layout A's grand stair through the arch, and
## the kitchen wing). For while the hotel isn't on its valley lot (#1227: render_valley.gd needs it there).
## Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/building_lab/hotel/render_lab.gd -- \
##       --out=DIR [--views=lobby,wing] [--size=1280x720]
##
## Minutes a view under lavapipe; never two runs at once.

const SPEC := "res://config/buildings/hotel.json"
const ORIGIN := Vector3(-40.0, 0.0, -60.0)
## name -> [camera, look at (the building's space: x from its EAST corner westward, z back from the front),
## fov, hour, inside (the doors' leaves hidden)].
const VIEWS := {
	"lobby": [Vector3(13.41, 1.9, 1.3), Vector3(13.41, 3.6, 12.0), 70.0, 15.0, true],
	# From the gallery, standing on the upper deck (floor 0.75 + 4.11 = 4.86 m) at eye height, looking down the well at the landing.
	"stair_hall": [Vector3(13.41, 6.45, 2.6), Vector3(13.41, 3.0, 14.5), 74.0, 15.0, true],
	# The front from the street, 16 m out (the sheet's front view), doors' leaves shown.
	"front": [Vector3(12.1, 2.4, -16.0), Vector3(12.1, 4.6, 0.0), 60.0, 15.5, false],
	"wing": [Vector3(19.5, 2.0, 30.0), Vector3(6.0, 4.0, 17.5), 55.0, 15.5, false],
	"kitchen": [Vector3(6.6, 2.0, 18.7), Vector3(3.0, 1.3, 22.4), 72.0, 15.0, true],
}

var out_dir := "build/hotel_lab_renders"
var only: PackedStringArray = []
var size := Vector2i(1280, 720)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var vp: SubViewport = main.get_node(^"GameViewport")
	vp.size = size
	var clock = street.get_node(^"DayCycle")
	clock.set_physics_process(false)
	var player = street.get_node(^"Player")
	player.input_enabled = false
	for w in player.weapons:
		w.visible = false
	player.global_position = Vector3(0, -50, 0)
	var building = load("res://src/structures/spec_building.gd").new()
	building.spec_path = SPEC
	building.name = "Hotel"
	building.position = ORIGIN
	street.add_child(building)
	var leaves: Array = []
	for m in building.get_members():
		if String(m.member_id).contains("/door_"):
			building.unbatch(m)
			leaves.append(m)
	var cam := Camera3D.new()
	cam.name = "HotelCamera"
	cam.far = 900.0
	street.add_child(cam)
	cam.current = true
	for i in 30:
		await physics_frame
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		for m in leaves:
			m.visible = not bool(view[4])
		clock.set_time(float(view[3]))
		cam.global_position = building.to_global(view[0])
		cam.look_at(building.to_global(view[1]), Vector3.UP)
		cam.fov = float(view[2])
		for i in 40:
			await process_frame
		await create_timer(5.0).timeout
		for i in 8:
			await process_frame
		var path := "%s/%s.png" % [out_dir, v]
		vp.get_texture().get_image().save_png(path)
		print("saved %s" % path)
	quit()
