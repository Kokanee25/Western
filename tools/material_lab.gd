extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The material lab (art, 2026-10-14; Sean's brief: one section of Salt Creek's architecture in the
## masters' painted woods): a short run of the real fronts out in the desert west of town, built by
## the game's own classes (FalseFrontBuilding with FacadeArt's porch, posts and brackets; Boardwalk),
## so every board is a member with its UVs, damage and materials as in the game. A red-sided saloon
## front, a pale store front, their timber porches and boardwalks; rendered in daylight, golden hour
## and lamplit night from fixed views, and a short walk past them.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/material_lab.gd -- --out=DIR \
##       [--lab] [--lights=noon,golden,night] [--views=front,close,post,walk_detail] [--pan=N]
##
## --lab: the lab's woods (tools/textures/paint_woods.py, PixelArt.lab); without, production's.
## Writes DIR/<light>_<view>.png and, with --pan, DIR/pan_<light>_<k>.png (N frames walking past).

## Where the set stands: empty desert west of the hotel, the fronts facing -X (toward the low
## western sun, so golden hour rakes across them as the street painting's light does).
const ORIGIN := Vector3(-72.0, 0.0, 26.0)
const YAW := 90.0
const HOURS := {"noon": 12.0, "golden": 17.6, "night": 22.5}
## [name, eye, look at, vertical fov] in the set's space (the fronts along +X, faces toward -Z).
const VIEWS := {
	"front": [Vector3(5.0, 2.2, -7.0), Vector3(5.0, 2.0, 0.0), 55.0],
	"close": [Vector3(1.4, 1.7, -2.6), Vector3(1.0, 1.6, 0.0), 50.0],
	"post": [Vector3(5.4, 1.7, -3.4), Vector3(4.9, 1.6, -2.1), 45.0],
	"walk_detail": [Vector3(6.6, 1.9, -3.4), Vector3(7.2, 0.4, -1.0), 50.0],
}
const WIDTH := 4.8


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://material_lab"
	var lights: Array = ["noon", "golden", "night"]
	var views: Array = VIEWS.keys()
	var pan := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg == "--lab":
			load("res://src/art/pixel_art.gd").lab = true
		elif arg.begins_with("--lights="):
			lights = Array(arg.substr(9).split(","))
		elif arg.begins_with("--views="):
			views = Array(arg.substr(8).split(","))
		elif arg.begins_with("--pan="):
			pan = int(arg.substr(6))
	DirAccess.make_dir_recursive_absolute(out)
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
	var set := Node3D.new()
	set.name = "MaterialLab"
	street.add_child(set)
	set.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(YAW)), ORIGIN)
	_build(set)
	var cam := Camera3D.new()
	cam.name = "LabCamera"
	street.add_child(cam)
	cam.current = true
	var mosaic: Script = load("res://src/render/depth_mosaic.gd")
	mosaic.apply(cam, settings.mosaic_active(), settings.MOSAIC_K, settings.MOSAIC_STEPS)
	for i in 30:
		await physics_frame
	for light in lights:
		clock.set_time(HOURS[light])
		for i in 20:
			await process_frame
		for v in views:
			var view: Array = VIEWS[v]
			_place(cam, set, view[0], view[1], view[2])
			for i in 12:
				await process_frame
			viewport.get_texture().get_image().save_png("%s/%s_%s.png" % [out, light, v])
			print("saved %s_%s" % [light, v])
		# The walk: past the fronts along the boardwalk's edge, looking at the walls (texels must
		# stay on the boards as the camera moves).
		for k in pan:
			var t: float = float(k) / maxf(pan - 1, 1)
			var eye := Vector3(lerpf(1.0, 8.6, t), 1.65, -3.4)
			_place(cam, set, eye, eye + Vector3(0.9, -0.05, 2.6), 50.0)
			for i in 3:
				await process_frame
			viewport.get_texture().get_image().save_png("%s/pan_%s_%02d.png" % [out, light, k])
		if pan > 0:
			print("saved pan_%s (%d)" % [light, pan])
	quit()


func _place(cam: Camera3D, set: Node3D, eye: Vector3, at: Vector3, fov: float) -> void:
	cam.global_position = set.global_transform * eye
	cam.look_at(set.global_transform * at, Vector3.UP)
	cam.fov = fov


## Two fronts side by side along +X, each with its boardwalk: the saloon's red lap siding (its
## timber porch posts and brackets, FacadeArt "saloon"), then the store's pale boards ("store").
func _build(set: Node3D) -> void:
	# [name, wood, FacadeArt style, windows]: the saloon's front without its windows, so a run of its
	# siding shows (the painting's red boards are its walls between and under the windows).
	var fronts := [["LabSaloon", &"saloon_red", "saloon", false], ["LabStore", &"store_boards", "store", true]]
	for i in fronts.size():
		var f: Array = fronts[i]
		var b = load("res://src/structures/false_front_building.gd").new()
		b.name = f[0]
		b.structure_id = StringName((f[0] as String).to_snake_case())
		b.build_seed = 900 + i
		b.width = WIDTH
		b.depth = 4.0
		b.wall_height = 3.4
		b.front_height = 4.6
		b.front_wood = f[1]
		b.facade = f[2]
		b.sign_text = ""
		b.porch = true
		b.porch_lantern = true
		b.furnished = false
		b.front_windows = f[3]
		b.position = Vector3(i * (WIDTH + 0.3), 0.0, 0.0)
		set.add_child(b)
		var walk = load("res://src/structures/boardwalk.gd").new()
		walk.name = f[0] + "Walk"
		walk.structure_id = StringName((f[0] as String).to_snake_case() + "_walk")
		walk.length = WIDTH
		walk.steps = [Vector2(WIDTH * 0.5, 1.6)]
		walk.position = b.position
		set.add_child(walk)
	# An oil lantern on the saloon's wall by the close view (lit from dusk): the woods by lamplight.
	var lamp = load("res://src/world/oil_lamp.gd").new()
	lamp.name = "LabLantern"
	lamp.lit_from_hour = 18
	lamp.lit_until_hour = 6
	lamp.energy = 1.0
	lamp.light_range = 6.0
	lamp.casts_shadows = false
	set.add_child(lamp)
	lamp.position = Vector3(2.3, 2.1, -0.25)
