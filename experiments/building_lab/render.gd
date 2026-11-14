extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The building lab's renders: the saloon built from its spec, set down in the game's own street
## (its sky, light and look) out in the desert where the material lab works, and drawn from the
## sheet's views (docs/concept/saloon-sheet.png) and Sean's saloon picture's, for the blind critic.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/building_lab/render.gd -- --out=DIR [--views=a,b]
##   ... -- --out=DIR --wear   # the wear map: every member tinted by its marks (docs/briefs/lived-in.md)
##   ... -- --out=DIR --worn   # the marks drawn (wear_paint.gd: the batches in the worn wood), the views and the close ones

const HOURS := {"golden": 17.6, "night": 22.5}
## name -> [camera, look at, fov, light], in the building's space.
const VIEWS := {
	"front": [Vector3(7.62, 3.2, -24.0), Vector3(7.62, 5.2, 0.0), 45.0, "golden"],
	"side_east": [Vector3(36.0, 3.0, 8.0), Vector3(15.24, 4.6, 7.5), 45.0, "golden"],
	"front_night": [Vector3(7.62, 3.2, -24.0), Vector3(7.62, 5.2, 0.0), 45.0, "night"],
	"entrance": [Vector3(7.62, 2.35, 0.7), Vector3(8.24, 3.0, 12.0), 72.0, "night"],
	"from_balcony": [Vector3(13.84, 6.0, 1.3), Vector3(6.74, 0.8, 8.8), 72.0, "night"],
	"picture": [Vector3(10.64, 1.95, 9.7), Vector3(2.44, 1.7, 6.2), 62.0, "night"],
	# Close, for the wear: the stair's treads and rail, the floor in front of the bar, the gallery's rail.
	"stair_close": [Vector3(12.9, 1.75, 5.2), Vector3(14.6, 1.7, 8.0), 60.0, "night"],
	"bar_floor": [Vector3(5.6, 2.1, 4.6), Vector3(2.2, 0.8, 6.8), 60.0, "night"],
	"gallery_close": [Vector3(7.6, 5.9, 0.7), Vector3(10.4, 4.9, 1.9), 60.0, "night"],
}

## The wear map's views: [camera, look at, fov (or the plan's width, orthographic), cut height
## (members starting above it are hidden: a plan), in the building's space].
const WEAR_VIEWS := {
	"wear_plan_ground": [Vector3(7.62, 40.0, 8.5), Vector3(7.62, 0.0, 8.5), 19.0, 2.0],
	"wear_plan_upper": [Vector3(7.62, 40.0, 8.5), Vector3(7.62, 0.0, 8.5), 19.0, 5.6],
	"wear_entrance": [Vector3(7.62, 2.35, 0.7), Vector3(8.24, 1.0, 9.0), 72.0, 99.0],
	"wear_front": [Vector3(7.62, 3.2, -24.0), Vector3(7.62, 5.2, 0.0), 45.0, 99.0],
	"wear_back": [Vector3(7.62, 4.0, 40.0), Vector3(7.62, 4.5, 17.07), 45.0, 99.0],
}
## A mark's colour on the map (the strongest mark on a member shows, brighter as it's deeper).
const WEAR_COLOURS := {
	&"foot": Color(1.0, 0.55, 0.1), &"heel": Color(1.0, 0.85, 0.2), &"scuff": Color(0.9, 0.4, 0.4), &"hand": Color(0.2, 0.9, 1.0),
	&"boot": Color(0.2, 0.9, 1.0), &"grime": Color(0.55, 0.45, 0.2), &"elbow": Color(0.3, 0.6, 1.0), &"rings": Color(0.3, 0.6, 1.0),
	&"cut": Color(0.3, 0.6, 1.0), &"spill": Color(0.6, 0.2, 0.9), &"soot": Color(0.35, 0.35, 0.4), &"splash": Color(0.65, 0.4, 0.15),
	&"bleach": Color(0.95, 0.95, 0.85), &"streak": Color(0.3, 0.4, 1.0), &"new": Color(0.2, 1.0, 0.3), &"pale": Color(1.0, 0.2, 0.8),
	&"holes": Color(1.0, 0.2, 0.8), &"bullet": Color(1.0, 0.0, 0.0), &"scrubbed": Color(1.0, 0.2, 0.8), &"carved": Color(1.0, 0.2, 0.8),
}

var _out := "user://building_lab"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only: Array = []
	var wear := false
	var worn := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--wear":
			wear = true
		elif arg == "--worn":
			worn = true
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
	var building = load("res://experiments/building_lab/play.gd").build(street)
	var cam := Camera3D.new()
	cam.name = "LabCamera"
	street.add_child(cam)
	cam.current = true
	var mosaic: Script = load("res://src/render/depth_mosaic.gd")
	mosaic.apply(cam, settings.mosaic_active(), settings.MOSAIC_K, settings.MOSAIC_STEPS)
	for i in 30:
		await physics_frame
	if wear:
		await _wear_map(building, cam, viewport, clock, only)
		quit()
		return
	if worn:
		var made: Dictionary = load("res://experiments/building_lab/wear_paint.gd").apply(building, [0.78, 4.44] as Array[float])
		print("worn: %d marks drawn, volume %s, floor maps %s, %d batches in %d worn materials" % [made.marks_drawn, made.volume, made.floor_map, made.batches, made.materials])
		await process_frame
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


## The wear map: batches hidden, every member drawn on its own in a flat colour, its strongest mark's
## (dark grey for none), from the plans and a few views.
func _wear_map(building: Node3D, cam: Camera3D, viewport: SubViewport, clock, only: Array) -> void:
	clock.set_time(12.0)
	var plain := StandardMaterial3D.new()
	plain.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plain.albedo_color = Color(0.16, 0.16, 0.17)
	var mats := {}
	var structures: Array = [building]
	structures.append_array(building.find_children("*", "KitProp", true, false))
	var members: Array = []
	for pb in root.find_children("PropBatch", "", true, false):
		(pb as Node3D).visible = false  # the kit props drawn together
	for st in structures:
		for c in st.get_children(true):
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false  # the batches
		for m in st.get_members():
			members.append(m)
			m.call(&"realise")  # its own mesh back in the tree (at rest it's its body alone)
			var mi := m.get_child(0) as MeshInstance3D
			mi.visible = true
			# Marks over the whole member tint it; a mark with a stretch (`along`) or a place
			# (`at`, `r`) is drawn as a box over just that part of it, so the map shows where.
			mi.material_override = plain
			for d in mi.get_children():
				if d is MeshInstance3D:
					(d as MeshInstance3D).visible = false
			var whole: Dictionary = {}
			for mk: Dictionary in m.get_meta(&"marks", []):
				var mat := _wear_material(mats, mk)
				if mk.has("along") or mk.has("at"):
					var box := BoxMesh.new()
					var size: Vector3 = m.size + Vector3.ONE * 0.012
					var c := Vector3.ZERO
					var ax: int = m.axis_index()
					if mk.has("along"):
						var t0 := float(mk.along[0])
						var t1 := float(mk.along[1])
						size[ax] = maxf(t1 - t0, 0.12)
						c[ax] = (t0 + t1) * 0.5
					else:
						var r := float(mk.r)
						var at := Vector3(mk.at[0], mk.at[1], mk.at[2])
						for k in 3:
							if m.size[k] > r * 2.0:
								size[k] = r * 2.0
								c[k] = clampf(at[k], -m.size[k] * 0.5 + r, m.size[k] * 0.5 - r)
					box.size = size
					var over := MeshInstance3D.new()
					over.mesh = box
					over.material_override = mat
					over.position = c
					mi.add_child(over)
				elif whole.is_empty() or float(mk.s) > float(whole.s):
					whole = mk
			if not whole.is_empty():
				mi.material_override = _wear_material(mats, whole)
	for lamp in building.lamps:
		lamp.visible = false
	for v: String in WEAR_VIEWS:
		if not only.is_empty() and not only.has(v):
			continue
		var view: Array = WEAR_VIEWS[v]
		var cut: float = view[3]
		for m in members:
			(m.get_child(0) as MeshInstance3D).visible = building.to_local(m.global_position).y - m.size.y * 0.5 < cut or m.size.y > 3.0 and cut > 50.0
		var plan := cut < 50.0
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL if plan else Camera3D.PROJECTION_PERSPECTIVE
		cam.global_position = building.to_global(view[0])
		cam.look_at(building.to_global(view[1]), Vector3.BACK if plan else Vector3.UP)
		if plan:
			cam.size = view[2]
		else:
			cam.fov = view[2]
		for i in 16:
			await process_frame
		var path := "%s/%s.png" % [_out, v]
		viewport.get_texture().get_image().save_png(path)
		print("saved %s" % path)


func _wear_material(mats: Dictionary, mk: Dictionary) -> Material:
	var key := "%s_%d" % [mk.kind, int(float(mk.s) * 4.0)]
	if not mats.has(key):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var col: Color = WEAR_COLOURS.get(StringName(mk.kind), Color.WHITE)
		mat.albedo_color = col.lerp(Color(0.16, 0.16, 0.17), 0.65 * (1.0 - clampf(float(mk.s), 0.0, 1.0)))
		mats[key] = mat
	return mats[key]
