extends SceneTree
## The line shack built from its spec in the game's own street (its sky, light and look), out in the desert
## where the building lab works, drawn from render_valley.gd's views (#1250). The valley version needs more
## memory than a session's container has under lavapipe (killed twice); this draws the same building in the
## same light, only not on the hideout's pad. `--before`: the old stand-in box in its place.
## Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/line_shack/render_lab.gd -- \
##       --out=DIR [--views=front,inside] [--size=960x540] [--before]
##
## Minutes a view under lavapipe; never two runs at once.

const SPEC := "res://config/buildings/line_shack.json"
const ORIGIN := Vector3(-40.0, 0.0, -60.0)
const Valley := preload("res://experiments/building_lab/line_shack/render_valley.gd")

var out_dir := "build/line_shack_renders"
var only: PackedStringArray = []
var size := Vector2i(960, 540)
var before := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a == "--before":
			before = true
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
	if before:
		var box = Valley.old_box_node()
		street.add_child(box)
		box.position = at
	else:
		var building = load("res://src/structures/spec_building.gd").new()
		building.spec_path = SPEC
		building.name = "LineShack"
		building.structure_id = &"line_shack_lab"
		building.position = at
		street.add_child(building)
	var frame := Transform3D(Basis.IDENTITY, at)
	# The doors' leaves, hidden for the views inside (the front one is kicked in by then; open, it fills
	# the view from the door).
	var leaves: Array = []
	for s in street.get_children():
		if s.has_method(&"get_members") and s.name == "LineShack":
			for m in s.get_members():
				if String(m.member_id).contains("/door_"):
					s.unbatch(m)
					leaves.append(m)
	var cam := Camera3D.new()
	cam.name = "ShackCamera"
	cam.far = 900.0
	street.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	for v: String in Valley.VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = Valley.VIEWS[v]
		for m in leaves:
			m.visible = not v.begins_with("inside")
		clock.set_time(float(view[3]))
		cam.global_position = frame * (view[0] as Vector3)
		cam.look_at(frame * (view[1] as Vector3), Vector3.UP)
		cam.fov = float(view[2])
		for i in 40:
			await process_frame
		await create_timer(5.0).timeout
		for i in 8:
			await process_frame
		var path := "%s/%s%s.png" % [out_dir, "before_" if before else "", v]
		vp.get_texture().get_image().save_png(path)
		print("saved %s" % path)
	quit()
