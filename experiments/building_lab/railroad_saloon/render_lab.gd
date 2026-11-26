extends SceneTree
## The Silver Spike (#1286) built from its spec in the game's own street (its sky, light and look), out in
## the desert where the building lab works, turned to face south as on its lot (the valley under lavapipe
## needs more memory than a session's container has: line_shack/render_lab.gd's way). Views from the target
## sheet's (sheet/): the front from Back Street, the bar room by lamplight, the dance floor upstairs.
## Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/railroad_saloon/render_lab.gd -- \
##       --out=DIR [--views=front,bar,upstairs] [--size=960x540]
##
## Minutes a view under lavapipe; never two runs at once. Start the real look with --game-args=--real
## is not needed here: the street's main scene starts in it (#641).

const SPEC := "res://config/buildings/railroad_saloon.json"
const ORIGIN := Vector3(-40.0, 0.0, -60.0)
## view: [camera, looked at (the building's own space: x west from its east front corner, z back from the
## front, y up from the pad), fov, the clock's hour]
const VIEWS := {
	"front": [Vector3(6.6, 1.7, -11.5), Vector3(3.4, 3.2, 4.0), 50.0, 16.5],
	"rear": [Vector3(1.5, 1.7, 17.0), Vector3(4.6, 3.0, 5.0), 55.0, 17.5],
	"bar": [Vector3(6.6, 1.65, 0.55), Vector3(1.0, 1.5, 5.6), 72.0, 21.0],
	"upstairs": [Vector3(5.7, 4.85, 8.75), Vector3(3.2, 4.3, 0.5), 74.0, 16.0],
}

var out_dir := "build/railroad_saloon_renders"
var only: PackedStringArray = []
var size := Vector2i(960, 540)


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
	var at := ORIGIN
	at.y = float(load("res://src/world/town_layout.gd").ground_height(ORIGIN.x, ORIGIN.z))
	var frame := Transform3D(Basis(Vector3.UP, PI), at)  # (facing 180, as on its lot)
	var building = load("res://src/structures/spec_building.gd").new()
	building.spec_path = SPEC
	building.name = "RailroadSaloon"
	building.structure_id = &"railroad_saloon_lab"
	building.transform = frame
	street.add_child(building)
	# The doors' leaves, hidden for the views inside (open, one fills the view from beside it).
	var leaves: Array = []
	for m in building.get_members():
		if String(m.member_id).contains("/door_"):
			building.unbatch(m)
			leaves.append(m)
	var cam := Camera3D.new()
	cam.name = "SaloonCamera"
	cam.far = 900.0
	street.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		for m in leaves:
			m.visible = v == "front" or v == "rear"
		clock.set_time(float(view[3]))
		cam.global_position = frame * (view[0] as Vector3)
		cam.look_at(frame * (view[1] as Vector3), Vector3.UP)
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
