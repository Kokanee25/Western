extends SceneTree
## The prop factory's doctor batches in his rooms, in the game's own light (#788; docs/briefs/
## prop-factory.md, "Every prop is checked": judged beside the building it lives in). The game's main
## scene in the valley (its real look, exposure and grade) with the doctor built on his lot by
## ValleyWorld (#765), the batch laid in from dress.json, drawn from the views below at their hours.
## Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/prop_lab/doctor/dress.gd -- \
##       --out=DIR [--batch=D1] [--views=surgery,sick_room] [--size=1280x720] [--counts]
##
## ~10 min a view under lavapipe; never two runs at once (~10 GB each). --counts prints the draws
## (the frame's) and the batch's triangles and batches, then quits.

## name -> [camera, look at (the building's space: y over the street edge's ground; the ground
## floor is at 0.95), fov, hour].
const VIEWS := {
	# The surgery from the doctor's side by the hall door (the doors' leaves are set aside), the table's
	# drawers toward us, the east windows beyond, by morning light.
	"surgery": [Vector3(3.6, 2.45, 4.3), Vector3(1.6, 1.25, 6.1), 66.0, 9.5],
	# The same at night: the reflector lamp lit on the instrument table.
	"surgery_night": [Vector3(3.6, 2.45, 4.3), Vector3(1.6, 1.25, 6.1), 66.0, 21.5],
	# The washstand and the instrument table, close.
	"wash": [Vector3(2.4, 2.3, 6.2), Vector3(3.75, 1.55, 7.6), 58.0, 10.0],
	"instruments": [Vector3(1.45, 2.25, 6.0), Vector3(0.42, 1.72, 5.25), 50.0, 10.0],
	# The sick room, its two cots, in the afternoon.
	"sick_room": [Vector3(3.85, 2.45, 11.2), Vector3(1.4, 1.2, 9.2), 66.0, 15.0],
}

var out_dir := "build/doctor_props"
var batch := "D1"
var only: PackedStringArray = []
var size := Vector2i(1280, 720)
var counts := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--batch="):
			batch = a.substr(8)
		elif a.begins_with("--views="):
			only = a.substr(8).split(",")
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a == "--counts":
			counts = true
	_run.call_deferred()


## The batch's props laid into `building` (its floor `floor_y` in its space): by name.
static func dress(building: Node3D, batch_name: String, floor_y := 0.95) -> Dictionary:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/prop_lab/doctor/dress.json"))
	var kit = load("res://src/props/prop_kit.gd")
	var holder := Node3D.new()
	holder.name = "PropLabDress"
	building.add_child(holder)
	var placed := {}
	var tops := {}
	for e: Dictionary in spec.batches[batch_name]:
		var id := StringName(e.kit)
		var node: Node3D
		if e.has("cloth_over"):
			# Cloth hung over what it's to hang over (the washstand's towel bar: the kit's
			# `towel_bar` member): ClothProp.hang_over pins its middle on the bar, the rest drapes.
			var under: Node3D = placed[e.cloth_over]
			var cloth: Node3D = kit.make(id)
			holder.add_child(cloth)
			var bar = under.call(&"get_member", StringName("%s/towel_bar" % under.get(&"structure_id")))
			if bar:
				var top: Vector3 = bar.global_position + Vector3.UP * (float(bar.size.y) * 0.5 + 0.005)
				cloth.call(&"hang_over", bar, bar.global_basis.z, top)
			placed[e.id] = cloth
			continue
		if e.has("fit"):
			node = kit.spawn_fitted(id, StringName("dress_%s" % e.id), Vector3(e.fit[0], e.fit[1], e.fit[2]))
		else:
			node = kit.make(id)
		var y := floor_y + float(e.at[1]) + float(e.get("lift", 0.0))
		if e.has("on"):
			y = float(tops[e.on]) + float(e.get("lift", 0.0))
		node.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.get("facing", 0.0)))), Vector3(e.at[0], y, e.at[2]))
		holder.add_child(node)
		# Its top: a fitted fixture's height, a member prop's highest top board (not a splashback over
		# it), a glass or loose prop's size.
		var h: float = float(e.fit[1]) if e.has("fit") else kit.bounds(kit.definition(id)).end.y
		if not e.has("fit") and kit.definition(id).has("members"):
			var tb := 0.0
			for m: Dictionary in kit.expand(kit.definition(id)):
				if String(m.kind) == "furniture_top":
					tb = maxf(tb, float(m.at[1]) + float(m.size[1]) * 0.5)
			if tb > 0.0:
				h = tb
		elif not kit.definition(id).has("members"):
			h = float((kit.definition(id).get("size", [0, 0.1, 0]) as Array)[1])
		if id == &"wash_basin":
			h = 0.014  # (its floor: the pitcher stands in it)
		tops[e.id] = y + h
		if e.has("light"):
			var lamp = load("res://src/world/oil_lamp.gd").new()
			lamp.name = "Light"
			lamp.show_mesh = false
			lamp.lit_from_hour = 17
			lamp.lit_until_hour = 4
			# (a reflector lamp throws more of its light one way: a little over the sconces' 1.1)
			lamp.energy = 1.6
			lamp.light_range = 7.0
			lamp.position = Vector3(0, float(e.light), 0)
			node.add_child(lamp)
		placed[e.id] = node
	return placed


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
	if player:
		player.input_enabled = false
		for w in player.get(&"weapons"):
			w.visible = false
		player.global_position = Vector3(0, -50, 0)
	var building: Node3D = valley.get(&"buildings").get("doctor")
	if building == null:
		push_error("no doctor's building in the valley (#778: valley.json's doctor lot needs its spec)")
		quit(1)
		return
	# The doors' leaves stand open into the rooms, across the views: set aside for the props' judge
	# (the building's, not a prop's; its own judge sees them).
	for m in building.get_members():
		if String(m.member_id).contains("/door_"):
			building.unbatch(m)
			m.visible = false
	var placed := dress(building, batch)
	var clock = valley.find_child("DayCycle", true, false)
	if clock:
		clock.set_physics_process(false)
	var cam := Camera3D.new()
	cam.name = "PropCamera"
	cam.far = 900.0
	valley.add_child(cam)
	cam.current = true
	for i in 40:
		await physics_frame
	var report := []
	for k: String in placed:
		var p: Node3D = placed[k]
		var tris := 0
		for mi: MeshInstance3D in p.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh:
				tris += mi.mesh.get_faces().size() / 3
		var line := "%s: %s at %s, %d triangles" % [k, p.get(&"kit_id"), building.to_local(p.global_position).snapped(Vector3.ONE * 0.01), tris]
		if p.has_method(&"batch_count"):
			line += ", %d batches, %s" % [p.batch_count(), "standing" if not p.get(&"loose") else "LOOSE"]
		else:
			line += ", %s" % ("standing" if not p.get(&"loose") and not p.get(&"broken") else "LOOSE/BROKEN")
		report.append(line)
	print("\n".join(report))
	FileAccess.open(out_dir + "/placed.txt", FileAccess.WRITE).store_string("\n".join(report) + "\n")
	for v: String in VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = VIEWS[v]
		if clock:
			clock.set_time(float(view[3]))
		cam.global_position = building.to_global(view[0])
		cam.look_at(building.to_global(view[1]), Vector3.UP)
		cam.fov = float(view[2])
		for i in 40:
			await process_frame
		await create_timer(5.0).timeout
		for i in 8:
			await process_frame
		if counts:
			var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			print("%s: %d draw calls in the frame" % [v, draws])
			continue
		var path := "%s/%s.png" % [out_dir, v]
		vp.get_texture().get_image().save_png(path)
		print("saved %s" % path)
	quit()
