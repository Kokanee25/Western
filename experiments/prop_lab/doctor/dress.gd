extends SceneTree
## The prop factory's doctor batches in his rooms, in the game's own light (#788; docs/briefs/
## prop-factory.md, "Every prop is checked": judged beside the building it lives in). The game's main
## scene in the valley (its real look, exposure and grade) with the doctor built on his lot by
## ValleyWorld (#765), the batch laid in from dress.json, drawn from the views below at their hours.
## Untyped where it names game classes: -s scripts compile before autoloads.
##
##   xvfb-run -a godot --rendering-driver vulkan -s res://experiments/prop_lab/doctor/dress.gd -- \
##       --out=DIR [--batch=D1 | D1,D2,D3] [--views=surgery,sick_room] [--size=1280x720] [--counts] [--no-rows]
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
	# D2 (#805): the dispensary from inside its door, its shelving and his counter under the high window.
	"dispensary": [Vector3(5.75, 2.6, 4.2), Vector3(7.85, 1.75, 7.55), 66.0, 10.0],
	# His counter as he works at it (make_up): the scales, the mortar, a few bottles.
	"counter": [Vector3(6.75, 2.5, 7.35), Vector3(8.15, 1.95, 6.55), 56.0, 10.0],
	# The shelving's bottles, close.
	"shelves": [Vector3(6.55, 2.55, 5.85), Vector3(6.55, 2.3, 7.95), 58.0, 10.0],
	# The front office: his roll-top and chair against its back wall, from the street door.
	"front_office": [Vector3(3.6, 2.5, 0.55), Vector3(1.2, 1.55, 3.4), 64.0, 10.0],
	# The desk, close: the pigeonholes, its curved sides, the drawers' pulls.
	"desk": [Vector3(2.05, 2.45, 1.95), Vector3(1.15, 1.75, 3.45), 56.0, 10.0],
	# D3 (#819): the hall's pegs, his coat and hat on them, from the front office's end, and close.
	"hall": [Vector3(4.75, 2.5, 4.3), Vector3(4.35, 2.1, 8.2), 66.0, 10.0],
	"pegs": [Vector3(5.3, 2.45, 8.2), Vector3(4.12, 2.25, 8.2), 75.0, 10.0],
	# The sick room's far end: its washstand, the bedside chair, the spare blankets on the empty cot.
	"sick_wash": [Vector3(3.3, 2.4, 9.0), Vector3(2.2, 1.4, 11.0), 62.0, 15.0],
	# The chamber pot under the first cot; the folded blankets, close.
	"pot": [Vector3(2.2, 1.75, 10.9), Vector3(0.8, 1.1, 10.0), 50.0, 15.0],
	"blankets": [Vector3(2.5, 2.25, 10.9), Vector3(3.42, 1.62, 9.95), 45.0, 15.0],
	# His bookcase beside the desk, close; the sitting room's books, table and chair.
	"bookcase": [Vector3(2.75, 2.45, 1.75), Vector3(2.75, 1.78, 3.6), 50.0, 10.0],
	"sitting_room": [Vector3(5.7, 2.5, 11.0), Vector3(6.9, 1.6, 9.0), 66.0, 15.0],
}
## The views a batch is judged in (all of them without --views). `--batch=D1,D2,D3` lays several
## (D3's views show D1's cots and D2's desk); its views are the last one's.
const BATCH_VIEWS := {"D1": ["surgery", "surgery_night", "wash", "instruments", "sick_room"],
		"D2": ["dispensary", "counter", "shelves", "front_office", "desk"],
		"D3": ["hall", "pegs", "sick_room", "pot", "blankets", "bookcase", "front_office", "sitting_room"]}

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
	var entries: Array = []
	var listed: Array = []
	for b in batch_name.split(","):
		listed.append_array(spec.batches[b])
	for e: Dictionary in listed:
		if not e.has("row"):
			entries.append(e)
			continue
		if OS.get_cmdline_user_args().has("--no-rows"):
			continue  # (a placement check without the shelves' ~190 bottles: the load is minutes shorter)
		# A row: the kits in turn along its step (a shelf of bottles), its gaps left.
		var row: Dictionary = e.row
		for k in int(row.count):
			if (row.get("skip", []) as Array).has(float(k)) or (row.get("skip", []) as Array).has(k):
				continue
			var one := e.duplicate(true)
			one.erase("row")
			one.id = "%s_%d" % [e.id, k]
			one.kit = (row.kits as Array)[k % (row.kits as Array).size()]
			one.at = [float(e.at[0]) + float(row.step[0]) * k, float(e.at[1]) + float(row.step[1]) * k, float(e.at[2]) + float(row.step[2]) * k]
			# Set down by hand, not on a ruler (round 1's critic: rows like wallpaper): each a little
			# off its place and turned, by its id (the same every run).
			var j: Array = row.get("jitter", [0.0, 0.0, 0.0])
			if not j.is_empty():
				var h := hash(String(one.id))
				one.at[0] += float(j[0]) * (float(h % 1000) / 500.0 - 1.0)
				one.at[2] += float(j[1]) * (float((h / 1000) % 1000) / 500.0 - 1.0)
				one.facing = float(e.get("facing", 0.0)) + float(j[2]) * (float((h / 1000000) % 1000) / 500.0 - 1.0)
			entries.append(one)
	for e: Dictionary in entries:
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
		var last := batch.get_slice(",", batch.get_slice_count(",") - 1)
		if only.is_empty() and BATCH_VIEWS.has(last) and not (BATCH_VIEWS[last] as Array).has(v):
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
		print("%s: %d draw calls in the frame" % [v, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
		var path := "%s/%s.png" % [out_dir, v]
		vp.get_texture().get_image().save_png(path)
		print("saved %s" % path)
	quit()
