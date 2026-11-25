extends SceneTree
## The line shack in the game's own light (#1250, the building lab's steps 4-5): the game's main scene in
## the valley, No Justice's hideout set up on its pad (NoJusticeHideout, its crew dead about their fire as
## the cabin's set-up has them), drawn by our camera: outside from the north-east (the door, the lean-to)
## and the south-west (the storeroom), inside from the door toward the storeroom and back to the door.
## `--before`: the old stand-in box (the hideout's FalseFrontBuilding gable box as it was) in its place,
## for the before/after sheet. Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/building_lab/line_shack/render_valley.gd -- \
##       --out=DIR [--views=front,inside] [--size=960x540] [--before]
##
## ~10 min a view under lavapipe; never two runs at once.

## name -> [camera, look at (the shack's own space: x east from its west front corner, z south from its
## front face, y over its floor's ground), fov, hour].
const VIEWS := {
	"front": [Vector3(9.0, 1.7, -7.0), Vector3(2.4, 1.6, 2.6), 55.0, 15.5],
	"back": [Vector3(-5.5, 1.7, 11.5), Vector3(2.0, 1.4, 4.5), 55.0, 15.5],
	"inside": [Vector3(2.7, 1.9, 0.35), Vector3(1.0, 1.0, 5.6), 74.0, 11.0],
	"inside_door": [Vector3(1.3, 1.9, 4.6), Vector3(2.6, 1.1, 0.0), 74.0, 11.0],
}

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
	settings.set_world(&"valley")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var overlay := main.get_node_or_null(^"DebugOverlay") as CanvasLayer
	if overlay:
		overlay.visible = false
	var vp: SubViewport = main.get_node(^"GameViewport")
	vp.size = size
	var valley: Node3D = main.find_child("Valley", true, false)
	var player = valley.get_node_or_null(^"Player")
	for i in 5:
		await physics_frame
	var h = load("res://src/moments/moment.gd").start_named(&"no_justice_hideout", valley, null,
			{"set_up": true, "arrive": true, "no_next": true, "hour": 12.0})
	if h == null or h.shack == null:
		push_error("no hideout")
		quit(1)
		return
	h.alarm_t = 0.0
	for g: Dictionary in h.crew:
		if is_instance_valid(g.man) and g.man.physiology.alive:
			g.man.physiology._die(&"heart")
	if player:
		player.input_enabled = false
		for w in player.get(&"weapons"):
			w.visible = false
		player.global_position = Vector3(0, -50, 0)
	if is_instance_valid(h.joe):
		h.joe.global_position = h._shack_door(14.0) + Vector3(6.0, 0.0, 0.0)
	var shack: Node3D = h.shack
	var frame := shack.global_transform
	if before:
		_old_box(h, shack)
	for l in valley.find_children("*", "Label3D", true, false):
		l.visible = false
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.name = "ShackCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		if clock:
			clock.set_time(float(view[3]))
		cam.global_position = frame * (view[0] as Vector3)
		cam.look_at(frame * (view[1] as Vector3), Vector3.UP)
		cam.fov = float(view[2])
		# Lavapipe: wait out the clock's re-blend of the look after the jump (~5 s, CLAUDE.md).
		for i in 40:
			await process_frame
		await create_timer(5.0).timeout
		for i in 8:
			await process_frame
		var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var path := "%s/%s%s.png" % [out_dir, "before_" if before else "", v]
		vp.get_texture().get_image().save_png(path)
		print("saved %s (%d draws)" % [path, draws])
	quit()


## The hideout's stand-in as it was before #1250 (no_justice_hideout.gd's `_build_shack` then): a
## FalseFrontBuilding gable box 4.2 x 5.0 m, walls 2.3 m, floor 0.32 m, a 24 degree roof, its door shut.
func _old_box(h, shack: Node3D) -> void:
	var at := shack.global_transform
	shack.get_parent().remove_child(shack)
	var box = old_box_node()
	h.street.add_child(box)
	box.global_transform = at


## The old box itself (render_lab.gd draws it too).
static func old_box_node() -> Node3D:
	var box = load("res://src/structures/false_front_building.gd").new()
	box.name = "OldShack"
	box.structure_id = &"old_shack"
	box.width = 4.2
	box.depth = 5.0
	box.wall_height = 2.3
	box.front_height = 2.3
	box.floor_top = 0.32
	box.door_size = Vector2(0.95, 1.95)
	box.gable_front = true
	box.front_wood = &"weathered_pine"
	box.front_windows = false
	box.porch = false
	box.porch_lantern = false
	box.furnished = false
	box.sign_text = ""
	box.roof_pitch_degrees = 24.0
	return box
