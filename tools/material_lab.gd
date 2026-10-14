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
##       [--lab | --lab2 | --lab3] [--flag | --reshape | --build] [--man] [--lights=noon,golden,night]
##       [--views=...] [--pan=N] [--pan-lights=golden]
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
	# The timber pass (docs/briefs/material-lab-timber.md): the deck's plank ends face-on, the walk's
	# corner three-quarters, the deck's top, the posts and their bracket, and a man at gameplay
	# distance for scale.
	"deck_end_on": [Vector3(1.1, 0.42, -3.3), Vector3(1.1, 0.32, -2.4), 38.0],
	"deck_corner": [Vector3(-0.9, 0.95, -3.5), Vector3(1.0, 0.3, -2.2), 42.0],
	"deck_top": [Vector3(3.6, 1.55, -3.2), Vector3(3.7, 0.38, -1.4), 50.0],
	"post_close": [Vector3(4.95, 1.6, -3.4), Vector3(4.95, 1.45, -2.05), 42.0],
	"post_bracket": [Vector3(3.6, 1.3, -3.7), Vector3(4.8, 2.4, -2.0), 52.0],
	"gameplay": [Vector3(2.4, 1.65, -7.5), Vector3(4.6, 1.3, 0.0), 60.0],
	# The timber pass's finish (Sean's notes): the plank ends unobstructed, low and close; a post's
	# foot on the deck; the steps.
	"deck_ends": [Vector3(0.15, 0.46, -2.8), Vector3(1.3, 0.33, -2.43), 34.0],
	"post_base": [Vector3(4.3, 0.95, -3.2), Vector3(4.95, 0.45, -2.1), 40.0],
	"steps": [Vector3(1.2, 0.95, -3.9), Vector3(2.4, 0.25, -2.6), 45.0],
}
const WIDTH := 4.8


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://material_lab"
	var lights: Array = ["noon", "golden", "night"]
	var views: Array = VIEWS.keys()
	var pan := 0
	var geometry := 0
	var man := false
	var pan_lights: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg == "--lab":
			load("res://src/art/pixel_art.gd").lab = true
		# --lab2: the timber pass's woods (tools/textures/grain_woods.py); --flag: the members'
		# meshes redrawn with their ends flagged for end grain (today's geometry); --reshape: and
		# chamfered, the planks 45 mm and past the fascia (LabGeometry).
		elif arg == "--lab2":
			var pa = load("res://src/art/pixel_art.gd")
			pa.lab = true
			pa.lab_set = "lab2"
		# --lab3, --build: the finish (LabGeometry's `build`: the walk as built, the lowest
		# siding splashed).
		elif arg == "--lab3":
			var pa = load("res://src/art/pixel_art.gd")
			pa.lab = true
			pa.lab_set = "lab3"
		elif arg == "--build":
			geometry = 3
		elif arg.begins_with("--pan-lights="):
			pan_lights = Array(arg.substr(13).split(","))
		elif arg == "--flag":
			geometry = 1
		elif arg == "--reshape":
			geometry = 2
		elif arg == "--man":
			man = true
		elif arg.begins_with("--lights="):
			lights = Array(arg.substr(9).split(","))
		elif arg.begins_with("--views="):
			views = Array(arg.substr(8).split(","))
		elif arg.begins_with("--pan="):
			pan = int(arg.substr(6))
	# Whatever woods were counted before the lab's set was chosen, counted again.
	load("res://src/structures/wood_materials.gd").reset()
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
	# The town's dry grass grows across the desert here and stands in front of the low deck views.
	var grass := street.find_child("DryGrass", true, false)
	if grass:
		grass.visible = false
	for i in 3:
		await process_frame
	if geometry > 0:
		print("LabGeometry: %d meshes" % load("res://src/art/lab_geometry.gd").apply(set, geometry >= 2, 0.045, 0.03, geometry == 3))
	if man:
		_man(set)
	_count(set)
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
		set.get_node(^"LabLamp").visible = light == "night"
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
		for k in (pan if pan_lights.is_empty() or light in pan_lights else 0):
			var t: float = float(k) / maxf(pan - 1, 1)
			# Low and a step out from the deck: its plank ends, the posts and the walls all in it.
			var eye := Vector3(lerpf(1.0, 8.6, t), 1.25, -3.9)
			_place(cam, set, eye, eye + Vector3(0.7, -0.4, 2.6), 50.0)
			for i in 3:
				await process_frame
			viewport.get_texture().get_image().save_png("%s/pan_%s_%02d.png" % [out, light, k])
		if pan > 0 and (pan_lights.is_empty() or light in pan_lights):
			print("saved pan_%s (%d)" % [light, pan])
	quit()


func _place(cam: Camera3D, set: Node3D, eye: Vector3, at: Vector3, fov: float) -> void:
	cam.global_position = set.global_transform * eye
	cam.look_at(set.global_transform * at, Vector3.UP)
	cam.fov = fov


## A man standing on the saloon's porch, for scale and to judge the woods beside the people.
func _man(set: Node3D) -> void:
	var m = load("res://src/bodies/human_body.gd").new()
	m.name = "LabMan"
	m.body_model = &"bold_cowboy_rodin"
	set.add_child(m)
	m.global_position = set.global_transform * Vector3(3.3, 0.38, -1.3)
	m.face(set.global_transform * Vector3(3.3, 1.5, -6.0))
	m.set_pose(&"stand")


## What the set costs to draw: meshes, triangles and materials of its members (print).
func _count(set: Node3D) -> void:
	var meshes := 0
	var tris := 0
	var mats := {}
	for mi in set.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		meshes += 1
		mats[mi.material_override] = true
		for si in mi.mesh.get_surface_count():
			var a: Array = mi.mesh.surface_get_arrays(si)
			var idx = a[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	for mmi in set.find_children("*", "MultiMeshInstance3D", true, false):
		var mm: MultiMesh = mmi.multimesh
		meshes += 1
		mats[mmi] = true
		tris += mm.instance_count * mm.mesh.get_faces().size() / 3
	print("LabCount: %d meshes, %d triangles, %d materials" % [meshes, tris, mats.size()])
	var woods := {}
	for m in set.find_children("*", "StructureMember", true, false):
		woods[m.wood] = woods.get(m.wood, 0) + 1
	print("LabWoods: ", woods)
	# Which textures each wood's members draw with (their own meshes', and the batches').
	var tex := {}
	for m in set.find_children("*", "StructureMember", true, false):
		for c in m.get_children():
			if c is MeshInstance3D and c.material_override is ShaderMaterial:
				var t = (c.material_override as ShaderMaterial).get_shader_parameter(&"albedo_tex")
				var key := "%s <- %s" % [m.wood, (t.resource_path.get_base_dir().get_file() if t else "none")]
				tex[key] = tex.get(key, 0) + 1
	print("LabTextures: ", tex)


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
	# Lamplight on the saloon's wall by the close view: a warm light the colour of the game's oil
	# lamps (OilLamp's), on only at night (the woods by lamplight, not a second sun by day).
	var lamp := OmniLight3D.new()
	lamp.name = "LabLamp"
	lamp.light_color = Color(1.0, 0.74, 0.48)
	lamp.light_energy = 1.4
	lamp.omni_range = 6.0
	lamp.shadow_enabled = false
	set.add_child(lamp)
	lamp.position = Vector3(2.0, 2.1, -0.5)
	lamp.set_meta(&"night_only", true)
