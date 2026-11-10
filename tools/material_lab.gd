extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The material lab (art; roadmap 1.4a, Sean 2026-10-21; docs/briefs/building-pipeline.md "Material
## lab"). One material at a time on a test stand (MaterialStand: a wall, a post and beam, a deck and
## steps, every cut end in end grain) out in the desert west of town, under the game's three lights
## (noon, golden hour, the lamplit saloon), with the Character Studio's three men in front of it:
## the style every material is judged against, never a material alone.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/material_lab.gd -- --out=DIR \
##       [--material=saloon_red,floor,... | --material=all] [--set=SET] [--lights=noon,golden,saloon]
##       [--views=...] [--no-masks] [--no-stains]
##   ... -s res://tools/material_lab.gd -- --out=DIR --repeats   # Main Street's neighbour repeats
##
## --material: the woods under test (MaterialStand.PART_OF's keys), each a run of its own: its parts
## take it, the rest of the stand stays the game's; `props` puts a card table, chairs and a barrel on
## the deck and judges their textures; `stair` builds the hotel's dark oak stair (OakStair) in the
## stand's place, the men round it. Without: the stand as the game draws it.
## --set: the woods of a candidate set (assets/textures/<SET>/, its lab.json) for the woods it has;
## the game's (assets/textures/woods/) for the rest. Without: the game's woods (the baseline).
## Writes DIR/<material>/<light>_<view>.png, beside each the masks the measuring reads
## (<view>_mask0-2.png: each man alone; <view>_mask3.png: the parts under test; white on black; the
## same in every light and every set, so drawn once; --no-masks to reuse another run's), and DIR/<material>/numbers.json (boards, thicknesses, strips,
## draws, triangles, texture memory, the men's texel density). tools/material_measure.py reads it.
## --panels=FAMILY[,FAMILY]: the material library's sample panels instead of the stand (#701;
## SamplePanel, config/material_library.json, docs/briefs/material-library.md): every entry of the
## family (a class: rough, common, fine; or `long`: one wood on a long wall, part 1's before and
## after; or `shape`: part 5's warp before and after) at each age, side by side, a man beside the
## one in view; views `far` (5 m) and `near` (1 m), lights noon, golden and `saloon` (night, a room
## round the panel, the saloon's lamps). --man=MODEL (default bold_cowboy_s0), --entries=a,b,
## --ages=new,few,old, --hires (the 4K scans where pulled), --review (Sean's shots only; run the
## window at 2560x1440: `--resolution 2560x1440` under an xvfb screen that size). Writes DIR/<family>/<entry>_<age>/<light>_<view>.png and DIR/<family>/numbers.json.
## --repeats: no stand; how often two boards side by side on Main Street draw the same strip
## (WoodMaterials picks a strip by hash(member_id)), per wood -> DIR/repeats.json.

## Where the stand stands: open desert west of the hotel, the wall facing -X toward the low western
## sun, so golden hour rakes across it as the street painting's light does (as the Oct 14 lab).
const ORIGIN := Vector3(-72.0, 0.0, 26.0)
const YAW := 90.0
const HOURS := {"noon": 12.0, "golden": 17.6, "saloon": 22.5}
## The Studio's men (Sean's approved three, 2026-10-21): [model, where they stand, looking at].
## The bold cowboy on the deck before the wall, the old rancher by the open end and the post, the
## young drifter beside the steps.
const MEN := [
	[&"bold_cowboy_s0", Vector3(2.0, 0.42, -0.75), Vector3(1.4, 1.5, -6.0)],
	[&"old_rancher_s1", Vector3(-0.55, 0.0, -2.2), Vector3(0.6, 1.5, -6.0)],
	[&"young_drifter_s1", Vector3(2.55, 0.0, -2.3), Vector3(1.2, 1.5, -6.0)],
]
## [eye, look at, vertical fov] in the stand's space. Every view has a man in it.
const VIEWS := {
	# The whole stand, the three men in front: the scale of everything.
	"stand": [Vector3(1.5, 1.6, -7.2), Vector3(1.5, 1.25, 0.0), 45.0],
	# At gameplay distance, standing.
	"gameplay": [Vector3(0.2, 1.65, -10.5), Vector3(1.6, 1.3, 0.0), 55.0],
	# The wall's face behind the man on the deck.
	"wall": [Vector3(2.3, 1.65, -3.3), Vector3(2.1, 1.4, 0.0), 42.0],
	# The siding's open end (its cut ends, the studs) by the old rancher.
	"wall_end": [Vector3(-1.9, 1.6, -2.9), Vector3(0.1, 1.2, -0.3), 45.0],
	# The post, the beam's end over it, the rancher in front.
	"post": [Vector3(-1.4, 1.75, -4.3), Vector3(0.3, 1.6, -1.65), 45.0],
	# The deck's plank ends and the rim, low, the drifter beside the steps.
	"deck_ends": [Vector3(0.4, 0.62, -3.0), Vector3(1.6, 0.4, -1.9), 40.0],
	# The deck's planks close, looking down as you stand on the boardwalk (Sean's photo, 2026-10-25).
	"deck_close": [Vector3(0.9, 1.75, -2.3), Vector3(1.5, 0.42, -0.5), 50.0],
	# The steps from above, as you walk up them.
	"steps": [Vector3(1.4, 1.65, -3.9), Vector3(1.7, 0.3, -1.9), 50.0],
	# The three men close, for their reference sheet (tools/textures/men_reference.py; --views=men).
	"men": [Vector3(1.0, 1.15, -6.4), Vector3(1.0, 0.95, -1.5), 27.0],
	# The props on the deck (--material=props), the bold cowboy beside them.
	"props": [Vector3(1.75, 1.5, -3.1), Vector3(1.05, 0.7, -0.8), 44.0],
	"props_close": [Vector3(0.5, 1.3, -2.2), Vector3(1.3, 0.85, -0.8), 50.0],
	# The oak stair (--material=stair, OakStair: the flight rising along +Z from z 0, its open side at
	# x 0): three-quarter from the foot, the newel and the bullnose, along the balusters, the treads
	# and runner.
	"stair": [Vector3(-2.3, 2.0, -3.4), Vector3(0.5, 1.25, 1.4), 55.0],
	"stair_newel": [Vector3(-1.5, 1.45, -1.45), Vector3(-0.15, 0.85, 0.2), 45.0],
	"stair_rail": [Vector3(-1.2, 2.3, 0.4), Vector3(0.1, 1.9, 2.4), 50.0],
	"stair_treads": [Vector3(-0.9, 1.9, -1.2), Vector3(0.6, 0.9, 1.0), 50.0],
	# Up at the walkway's railing from the lobby floor, the drifter behind it.
	"stair_walk": [Vector3(-2.6, 1.5, 0.2), Vector3(-1.2, 2.6, 3.6), 55.0],
}
## Which views judge which part (with the two whole views).
const PART_VIEWS := {
	&"siding": ["wall", "wall_end"], &"siding_low": ["wall"], &"studs": ["wall_end"], &"trim": ["wall"],
	&"deck": ["deck_ends", "steps"], &"treads": ["steps"], &"joists": ["deck_ends"], &"rim": ["deck_ends"],
	&"frame": ["post"], &"stringers": ["steps", "deck_ends"], &"props": ["props", "props_close"],
	&"oak_treads": ["stair", "stair_treads"], &"oak_newels": ["stair_newel"], &"oak_balusters": ["stair_rail", "stair_walk"],
}
## Round the stair: the bold cowboy at the newel, the rancher in front of the flight, the drifter up
## on the walkway behind its railing (OakStair's landing and walkway at 13 x 0.19 m).
const STAIR_MEN := [
	[&"bold_cowboy_s0", Vector3(-0.95, 0.015, 0.55), Vector3(-2.0, 1.5, -4.0)],
	[&"old_rancher_s1", Vector3(0.9, 0.015, -1.3), Vector3(-1.5, 1.5, -4.0)],
	[&"young_drifter_s1", Vector3(-1.5, 2.47, 4.0), Vector3(-1.5, 2.4, -2.0)],
]
## The lamplit saloon's light (SaloonDressing's): sconces' lamps, a lamp hung over the deck and one
## across the room behind the camera (the saloon's lamps are all round the room, so the men are lit
## from the front too), each made brighter and reaching further as the room's are. The sconces
## stand off the wall: on it, their hot spots filled the wall's frame.
const SCONCES := [Vector3(0.6, 2.1, -0.7), Vector3(2.7, 2.1, -0.7), Vector3(1.5, 2.3, -4.2)]
const HANGING := Vector3(1.5, 2.45, -1.3)
## Render layers the masks are drawn on (none of the game's: Layers uses the first ten).
const MASK_WOOD := 1 << 15
const MASK_MEN := [1 << 16, 1 << 17, 1 << 18]

var _out := "user://material_lab"
var _masks := true
var _panel_man: StringName = &"bold_cowboy_s0"
var _panel_entries: Array = []
var _panel_ages: Array = ["new", "few", "old"]
## --review: only the shots Sean reviews by (#721; run at 2560x1440 with --hires): 1 m at noon, 5 m
## at golden hour, and for the fine woods 1 m at night and the bar rail at noon.
var _review := false
## Frames a panel shot waits after the camera moves (--settle=N).
var _settle := 40
var _probe_aa := false
var _probe_ss := false
## --aa=taa: the review renders through Godot's TAA instead of the real look's FSR2. Under lavapipe
## FSR2 at native scale anti-aliases almost nothing (the probe, #721: a 1 m board's pixel noise FSR2
## 11.8, no upscaler 10.5, MSAA 4x 10.4, TAA 3.1): its crawl was the "burlap". Lab only; the game's
## own setting is Sean's call.
var _aa_taa := false
const REVIEW_SHOTS := [["noon", "near"], ["golden", "far"]]
const REVIEW_FINE := [["saloon", "near"], ["noon", "rail"]]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var lights: Array = ["noon", "golden", "saloon"]
	var only_views: Array = []
	var materials: Array = [""]
	var set := ""
	var repeats := false
	var stains := true
	var panels := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--panels="):
			panels = arg.substr(9)
		elif arg == "--hires":
			load("res://src/art/material_library.gd").hi_res = true
		elif arg == "--review":
			_review = true
		elif arg == "--aa=taa":
			_aa_taa = true
		elif arg == "--probe-ss":
			_probe_ss = true
		elif arg == "--probe-aa":
			_probe_aa = true
		elif arg.begins_with("--settle="):
			_settle = int(arg.substr(9))
		elif arg.begins_with("--man="):
			_panel_man = StringName(arg.substr(6))
		elif arg.begins_with("--entries="):
			_panel_entries = Array(arg.substr(10).split(","))
		elif arg.begins_with("--ages="):
			_panel_ages = Array(arg.substr(7).split(","))
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--material="):
			var m := arg.substr(11)
			materials = load("res://src/art/material_stand.gd").PART_OF.keys() + ["props"] if m == "all" else Array(m.split(","))
		elif arg.begins_with("--set="):
			set = arg.substr(6)
		elif arg.begins_with("--lights="):
			lights = Array(arg.substr(9).split(","))
		elif arg.begins_with("--views="):
			only_views = Array(arg.substr(8).split(","))
		elif arg == "--no-masks":
			_masks = false
		elif arg == "--repeats":
			repeats = true
		elif arg == "--no-stains":
			# The woods as the game draws them today (no member carries the weathering frame).
			stains = false
	var pa = load("res://src/art/pixel_art.gd")
	if set != "":
		pa.lab = true
		pa.lab_set = set
	load("res://src/structures/wood_materials.gd").reset()
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
	# The town's dry grass grows across the desert here and stands in front of the low views.
	var grass := street.find_child("DryGrass", true, false)
	if grass:
		grass.visible = false
	if repeats:
		for i in 10:
			await physics_frame
		DirAccess.make_dir_recursive_absolute(_out)
		_repeats(street)
		quit()
		return
	if panels != "":
		await _panels(street, viewport, clock, settings, panels, lights)
		quit()
		return
	var place := Node3D.new()
	place.name = "MaterialLab"
	street.add_child(place)
	# On the ground where it stands (the town's ground climbs west since 2026-10-25: TownLayout).
	var tl = load("res://src/world/town_layout.gd")
	place.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(YAW)),
			ORIGIN + Vector3.UP * float(tl.ground_height(ORIGIN.x, ORIGIN.z)))
	var lamps := _lamps(place)
	var men := _men(place)
	var cam := Camera3D.new()
	cam.name = "LabCamera"
	street.add_child(cam)
	cam.current = true
	var mosaic: Script = load("res://src/render/depth_mosaic.gd")
	mosaic.apply(cam, settings.mosaic_active(), settings.MOSAIC_K, settings.MOSAIC_STEPS)
	for i in 30:
		await physics_frame
	var men_density := _men_density(men)
	for mat in materials:
		# interior / interior_square: the saloon's woodwork (InteriorStand; docs/briefs/interior-woodwork.md),
		# profiled or every piece square; its own views, men and lamps.
		var interior: bool = mat.begins_with("interior")
		var script_path := "res://src/art/oak_stair.gd" if mat == "stair" else ("res://src/art/interior_stand.gd" if interior else "res://src/art/material_stand.gd")
		var stand = load(script_path).new()
		stand.name = "Stand"
		stand.material = StringName(mat) if mat != "props" else &""
		if mat == "interior_square":
			stand.profiled = false
		if not stains and "weathered" in stand:
			stand.weathered = false
		place.add_child(stand)
		stand.build()
		_stand_men(place, men, STAIR_MEN if mat == "stair" else (stand.MEN if interior else MEN))
		var lamp_at: Array = stand.LAMPS if interior else SCONCES + [HANGING]
		for i in lamps.size():
			lamps[i].position = lamp_at[i]
			# Indoors the lamps are seen and cast shadows (raised panels, chamfers and mouldings
			# read by them); on the outdoor stand, as before.
			# (OilLamp reads both when it's built: set what it built.)
			lamps[i].casts_shadows = interior
			lamps[i]._light.shadow_enabled = interior
			(lamps[i].get_node(^"Model") as Node3D).visible = interior
			lamps[i]._flame.visible = interior
		var views_of: Dictionary = stand.VIEWS if interior else VIEWS
		var name: String = mat if mat != "" else "stand"
		var dir := "%s/%s" % [_out, name]
		DirAccess.make_dir_recursive_absolute(dir)
		var focus: Array = stand.focus_parts() if mat != "props" else [&"props"]
		for part in focus:
			if stand.part_nodes.has(part):
				for mi in (stand.part_nodes[part] as Node).find_children("*", "MeshInstance3D", true, false):
					(mi as MeshInstance3D).layers |= MASK_WOOD
		if mat == "props":
			for mi in _props(stand).find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).layers |= MASK_WOOD
		var views: Array = ["stair"] if mat == "stair" else (stand.VIEWS.keys() if interior else ["stand", "gameplay"])
		for part in focus:
			for v in PART_VIEWS.get(part, []):
				# (The interior stand's turnings are the oak stair's parts but not its views.)
				if not views.has(v) and views_of.has(v):
					views.append(v)
		if not only_views.is_empty():
			views = only_views
		_write_numbers(dir, stand, men_density, views)
		for light in lights:
			clock.set_time(HOURS[light])
			for l in lamps:
				l.visible = light == "saloon"
			for i in 20:
				await process_frame
			for v in views:
				var view: Array = views_of[v]
				cam.global_position = place.global_transform * (view[0] as Vector3)
				cam.look_at(place.global_transform * (view[1] as Vector3), Vector3.UP)
				cam.fov = view[2]
				for i in 12:
					await process_frame
				var path := "%s/%s_%s" % [dir, light, v]
				viewport.get_texture().get_image().save_png(path + ".png")
				# The masks are the geometry's alone: drawn once a view, in the first light.
				if _masks and light == lights[0]:
					await _write_masks(viewport, cam, stand, men, "%s/%s" % [dir, v])
				print("saved %s/%s_%s" % [name, light, v])
		stand.queue_free()
		await process_frame
	quit()


## The three men, standing, unarmed.
func _men(place: Node3D) -> Array:
	var out := []
	for i in MEN.size():
		var m = load("res://src/bodies/human_body.gd").new()
		m.name = "LabMan%d" % i
		m.body_model = MEN[i][0]
		m.has_gun = false
		place.add_child(m)
		m.global_position = place.global_transform * (MEN[i][1] as Vector3)
		m.face(place.global_transform * (MEN[i][2] as Vector3))
		m.set_pose(&"stand")
		out.append(m)
	return out


## The saloon's lamps, on only for its light.
func _lamps(place: Node3D) -> Array:
	var sd = load("res://src/art/saloon_dressing.gd")
	var out := []
	for p in SCONCES + [HANGING]:
		var lamp = load("res://src/world/oil_lamp.gd").new()
		lamp.name = "LabLamp"
		lamp.show_mesh = false
		lamp.lit_from_hour = 17
		lamp.lit_until_hour = 4
		lamp.energy = (0.6 if p == HANGING else sd.SCONCE_ENERGY) * sd.LAMP_GAIN
		lamp.light_range = (5.0 if p == HANGING else sd.SCONCE_REACH) * sd.LAMP_REACH
		lamp.haze = 1.2 * sd.LAMP_HAZE
		lamp.casts_shadows = false
		place.add_child(lamp)
		lamp.position = p
		if p != HANGING:
			lamp.attenuation = sd.SCONCE_FALLOFF
		out.append(lamp)
	return out


## Masks for the measuring: each man alone (R, G, B) and the parts under test, each drawn white,
## unlit, on black, from the same camera.
func _write_masks(viewport: SubViewport, cam: Camera3D, stand: Node3D, men: Array, path: String) -> void:
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var keep_env := cam.environment
	var keep_mask := cam.cull_mask
	cam.environment = env
	var groups := []
	for i in men.size():
		groups.append([MASK_MEN[i], (men[i] as Node).find_children("*", "MeshInstance3D", true, false)])
	groups.append([MASK_WOOD, stand.find_children("*", "MeshInstance3D", true, false).filter(
			func(mi): return (mi as MeshInstance3D).layers & MASK_WOOD)])
	var shots := []
	for g in groups:
		var saved := {}
		for mi in g[1]:
			saved[mi] = [(mi as MeshInstance3D).material_override, (mi as MeshInstance3D).layers]
			(mi as MeshInstance3D).material_override = white
			(mi as MeshInstance3D).layers |= g[0]
		cam.cull_mask = g[0]
		for i in 3:
			await process_frame
		shots.append(viewport.get_texture().get_image())
		for mi in saved:
			(mi as MeshInstance3D).material_override = saved[mi][0]
			(mi as MeshInstance3D).layers = saved[mi][1]
	cam.environment = keep_env
	cam.cull_mask = keep_mask
	# Combined (men over wood) by tools/material_measure.py.
	for i in shots.size():
		(shots[i] as Image).save_png("%s_mask%d.png" % [path, i])


## The men's clothes' texels a metre: their texture's texels over their mesh's area, per man.
func _men_density(men: Array) -> Dictionary:
	var out := {}
	for m in men:
		var texel_area := 0.0
		var area := 0.0
		for mi in (m as Node).find_children("*", "MeshInstance3D", true, false):
			var mesh := (mi as MeshInstance3D).mesh
			if mesh == null:
				continue
			var s3 := (mi as MeshInstance3D).global_transform.basis.get_scale()
			var sc := (s3.x + s3.y + s3.z) / 3.0
			for si in mesh.get_surface_count():
				var a: Array = mesh.surface_get_arrays(si)
				var uv = a[Mesh.ARRAY_TEX_UV]
				if uv == null or (uv as PackedVector2Array).is_empty():
					continue
				var mat := (mi as MeshInstance3D).get_active_material(si)
				var tex: Texture2D = null
				if mat is StandardMaterial3D:
					tex = (mat as StandardMaterial3D).albedo_texture
				elif mat is ShaderMaterial:
					for p in [&"albedo_tex", &"texture_albedo", &"albedo_texture", &"paint_tex"]:
						var t = (mat as ShaderMaterial).get_shader_parameter(p)
						if t is Texture2D:
							tex = t
							break
				var tsize := Vector2(tex.get_size()) if tex else Vector2(2048, 2048)
				var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
				var idx = a[Mesh.ARRAY_INDEX]
				var n: int = (idx as PackedInt32Array).size() if idx != null else v.size()
				for t in range(0, n, 3):
					var i0: int = idx[t] if idx != null else t
					var i1: int = idx[t + 1] if idx != null else t + 1
					var i2: int = idx[t + 2] if idx != null else t + 2
					area += (v[i1] - v[i0]).cross(v[i2] - v[i0]).length() * 0.5 * sc * sc
					var u0: Vector2 = uv[i0] * tsize
					var u1: Vector2 = uv[i1] * tsize
					var u2: Vector2 = uv[i2] * tsize
					texel_area += absf((u1 - u0).cross(u2 - u0)) * 0.5
		out[String((m as Node).get(&"body_model"))] = {"texels_per_metre": sqrt(texel_area / maxf(area, 1e-6)), "area_m2": area}
	return out


func _write_numbers(dir: String, stand: Node3D, men_density: Dictionary, views: Array) -> void:
	var woods := {}
	for wood in stand.boards:
		var list: Array = stand.boards[wood]
		var thick := {}
		var strips := {}
		for b in list:
			var size: Vector3 = b.size
			var key := "%s %.0fx%.0f mm" % [b.part, size.y * 1000.0, size.z * 1000.0]
			thick[key] = thick.get(key, 0) + 1
			strips[b.strip] = strips.get(b.strip, 0) + 1
		var pa = load("res://src/art/pixel_art.gd")
		woods[String(wood)] = {"boards": list.size(), "sizes": thick, "strips_used": strips.size(),
				"strips": load("res://src/structures/wood_materials.gd").strip_count(wood),
				"texels_per_metre": pa.lab_density(String(wood), pa.lab_set if pa.lab and pa._lab_has(String(wood)) else pa.WOODS_SET)}
	var info: Dictionary = stand.numbers()
	info["material"] = String(stand.material)
	info["set"] = load("res://src/art/pixel_art.gd").lab_set if load("res://src/art/pixel_art.gd").lab else "woods"
	info["woods"] = woods
	info["men"] = men_density
	info["views"] = views
	info["focus"] = stand.focus_parts().map(func(p): return String(p))
	var f := FileAccess.open(dir + "/numbers.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(info, " "))
	f.close()


## Boards side by side on Main Street that draw the same strip: per wood, the pairs of parallel
## members of that wood within 3 cm of each other, and how many of them share a strip (production
## picks it by hash(member_id); 1 / strips would be chance).
func _repeats(street: Node3D) -> void:
	var wm = load("res://src/structures/wood_materials.gd")
	var cells := {}
	var members := street.find_children("*", "StructureMember", true, false)
	for m in members:
		var box: AABB = m.world_aabb()
		var c := Vector3i((box.get_center() / 2.0).floor())
		if not cells.has(c):
			cells[c] = []
		cells[c].append(m)
	var out := {}
	for m in members:
		var strips: int = wm.strip_count(m.wood)
		if strips <= 0:
			continue
		var box: AABB = m.world_aabb().grow(0.03)
		var c := Vector3i((m.world_aabb().get_center() / 2.0).floor())
		var axis: Vector3 = (m as Node3D).global_transform.basis * _long(m.size)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					for o in cells.get(c + Vector3i(dx, dy, dz), []):
						if o == m or o.wood != m.wood or String(o.member_id) <= String(m.member_id):
							continue
						if not box.intersects(o.world_aabb()):
							continue
						var oa: Vector3 = (o as Node3D).global_transform.basis * _long(o.size)
						if absf(axis.normalized().dot(oa.normalized())) < 0.95:
							continue
						var e: Dictionary = out.get(String(m.wood), {"pairs": 0, "same": 0, "strips": strips})
						e.pairs += 1
						if posmod(hash(m.member_id), strips) == posmod(hash(o.member_id), strips):
							e.same += 1
						out[String(m.wood)] = e
	for w in out:
		out[w]["share"] = snappedf(float(out[w].same) / maxf(out[w].pairs, 1), 0.001)
		out[w]["chance"] = snappedf(1.0 / out[w].strips, 0.001)
	print("LabRepeats: ", out)
	var f := FileAccess.open(_out + "/repeats.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()


static func _long(size: Vector3) -> Vector3:
	return Vector3.RIGHT if size.x >= size.y and size.x >= size.z else (Vector3.UP if size.y >= size.z else Vector3.BACK)


## The props judged with the woods (--material=props): a card table and two chairs on the deck by
## the bold cowboy, a barrel against the wall: the game's own (PropLibrary), so they draw with the
## textures PixelArt hands out (the set's, under --set).
func _props(stand: Node3D) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Props"
	stand.add_child(holder)
	var top: float = stand.DECK_TOP
	for p in [[&"card_table", Vector3(0.85, top, -0.85), 10.0], [&"chair", Vector3(0.35, top, -0.95), 80.0],
			[&"chair", Vector3(1.3, top, -0.55), -110.0], [&"barrel", Vector3(2.85, top, -0.35), 0.0]]:
		var prop = load("res://src/props/prop_library.gd").spawn(p[0])
		holder.add_child(prop)
		prop.position = p[1]
		prop.rotation_degrees.y = p[2]
	return holder


## The men to their places for this run (the stand's or the stair's).
func _stand_men(place: Node3D, men: Array, where: Array) -> void:
	for i in men.size():
		var at: Vector3 = place.global_transform * (where[i][1] as Vector3)
		if is_zero_approx((where[i][1] as Vector3).y):
			# A man on the sand stands on the ground where he is (it slopes out here).
			at.y = float(load("res://src/world/town_layout.gd").ground_height(at.x, at.z))
		men[i].global_position = at
		men[i].face(place.global_transform * (where[i][2] as Vector3))


# --- the material library's sample panels (#701) ---------------------------------------------

## The panels in a row along -X, each PANEL_STEP apart, out in the desert; facing south-west, so
## the noon sun (high, to the south: DayCycle) lights their face and golden hour's (low, west) rakes it.
const PANEL_STEP := 3.4
const PANEL_YAW := 45.0
## [eye, look at, fov] in a panel's space (SamplePanel: wall x 0..2, y 0..2 at z 0, floor to -1.2).
const PANEL_VIEWS := {
	"far": [Vector3(1.35, 1.6, -5.0), Vector3(1.25, 1.0, 0.0), 42.0],
	"near": [Vector3(1.05, 1.35, -1.05), Vector3(1.0, 0.85, 0.0), 50.0],
}
## The fine woods add the bar's rail from above, where hands and glasses go (Sean, #718).
const RAIL_VIEW := [Vector3(1.0, 1.6, -1.9), Vector3(1.05, 1.07, -1.15), 45.0]
## The long wall (part 1): from 6 m at an angle, and square on.
const LONG_VIEWS := {
	"long_angle": [Vector3(-1.5, 1.6, -5.0), Vector3(6.0, 1.0, 0.0), 50.0],
	"long_square": [Vector3(6.0, 1.3, -7.5), Vector3(6.0, 1.0, 0.0), 55.0],
}
## Part 5 under raking light: along the wall's face, low.
const SHAPE_VIEWS := {
	"rake": [Vector3(-0.6, 1.2, -0.9), Vector3(2.0, 0.9, -0.05), 40.0],
	"near": [Vector3(0.75, 1.45, -1.0), Vector3(1.0, 0.75, 0.0), 50.0],
}
## The man beside a panel: right of the wall, on the floor patch's corner, turned to the camera.
const PANEL_MAN := [Vector3(2.45, 0.0, -0.55), Vector3(0.0, 1.5, -6.0)]
## Night: the saloon's lamps round the panel (two sconces off the wall, one hung, one behind the camera).
const PANEL_LAMPS := [Vector3(-0.15, 1.9, -0.35), Vector3(2.2, 1.9, -0.35), Vector3(1.0, 2.55, -1.8), Vector3(1.2, 2.3, -5.4)]


func _panels(street: Node3D, viewport: SubViewport, clock, settings, families: String, lights: Array) -> void:
	var ml = load("res://src/art/material_library.gd")
	var sp = load("res://src/art/sample_panel.gd")
	var tl = load("res://src/world/town_layout.gd")
	var place := Node3D.new()
	place.name = "MaterialLibraryLab"
	street.add_child(place)
	place.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(PANEL_YAW)),
			ORIGIN + Vector3.UP * float(tl.ground_height(ORIGIN.x, ORIGIN.z)))
	var cam := Camera3D.new()
	cam.name = "LabCamera"
	street.add_child(cam)
	cam.current = true
	var man = load("res://src/bodies/human_body.gd").new()
	man.name = "LabMan"
	man.body_model = _panel_man
	man.has_gun = false
	place.add_child(man)
	man.set_pose(&"stand")
	# The saloon's lamps, placed round each panel for the night.
	var lamps := []
	var sd = load("res://src/art/saloon_dressing.gd")
	for i in PANEL_LAMPS.size():
		var lamp = load("res://src/world/oil_lamp.gd").new()
		lamp.name = "PanelLamp%d" % i
		lamp.show_mesh = false
		lamp.lit_from_hour = 17
		lamp.lit_until_hour = 4
		var hung: bool = i == 2
		lamp.energy = (0.6 if hung else sd.SCONCE_ENERGY) * sd.LAMP_GAIN
		lamp.light_range = (5.0 if hung else sd.SCONCE_REACH) * sd.LAMP_REACH
		lamp.haze = 1.2 * sd.LAMP_HAZE
		lamp.casts_shadows = true
		place.add_child(lamp)
		if not hung:
			lamp.attenuation = sd.SCONCE_FALLOFF
		lamp._light.shadow_enabled = true
		lamps.append(lamp)
	var room := _night_room()
	place.add_child(room)
	for i in 30:
		await physics_frame
	for family in families.split(","):
		var specs := _panel_specs(ml, family)
		var dir := "%s/%s" % [_out, family]
		DirAccess.make_dir_recursive_absolute(dir)
		var built := []
		var x := 0.0
		for spec in specs:
			var p = sp.new()
			p.entry = spec["entry"]
			p.age_name = StringName(spec["age"])
			p.seed_base = int(spec.get("seed", 0))
			place.add_child(p)
			var at: Vector3 = place.global_transform * Vector3(-x, 0.0, 0.0)
			p.global_position = Vector3(at.x, float(tl.ground_height(at.x, at.z)), at.z)
			p.global_basis = place.global_basis
			if spec.has("long"):
				p.wall_size = Vector2(spec["long"], 2.0)
			p.build()
			for m in p.find_children("*", "MeshInstance3D", true, false):
				var mat := (m as MeshInstance3D).material_override as ShaderMaterial
				if mat == null:
					continue
				if spec.has("variety"):
					mat.set_shader_parameter("variety", spec["variety"])
				if spec.has("warp_gain"):
					mat.set_shader_parameter("warp_gain", spec["warp_gain"])
				for d in spec.get("dials", {}):
					mat.set_shader_parameter(d, spec["dials"][d])
			p.visible = false
			built.append([spec, p, x])
			x += PANEL_STEP + (float(spec["long"]) - 2.0 if spec.has("long") else 0.0)
		var numbers := {"family": family, "man": String(_panel_man), "panels": []}
		# A family rendered in parts (--entries=) keeps the other parts' panels.
		if FileAccess.file_exists(dir + "/numbers.json"):
			var had = JSON.parse_string(FileAccess.get_file_as_string(dir + "/numbers.json"))
			if had is Dictionary:
				var mine := {}
				for spec in specs:
					mine[spec["name"]] = true
				for q in had.get("panels", []):
					if not mine.has(q.get("name", "")):
						numbers["panels"].append(q)
		for b in built:
			var spec: Dictionary = b[0]
			var p: Node3D = b[1]
			var px: float = b[2]
			# Only this panel and its neighbours drawn (a long row is many boards).
			for o in built:
				(o[1] as Node3D).visible = absf(float(o[2]) - px) < PANEL_STEP * 1.5 or o[1] == p
			var name: String = spec["name"]
			var pdir := "%s/%s" % [dir, name]
			DirAccess.make_dir_recursive_absolute(pdir)
			var views: Dictionary = spec.get("views", PANEL_VIEWS)
			var pt: Transform3D = p.global_transform
			var extra := Vector3(float(spec.get("long", 2.0)) - 2.0, 0.0, 0.0)
			var man_at: Vector3 = pt * ((PANEL_MAN[0] as Vector3) + extra)
			man.global_position = Vector3(man_at.x, float(tl.ground_height(man_at.x, man_at.z)), man_at.z)
			man.face(pt * (PANEL_MAN[1] as Vector3))
			room.global_transform = pt
			for i in lamps.size():
				lamps[i].global_position = pt * (PANEL_LAMPS[i] as Vector3)
			numbers["panels"].append({"name": name, "entry": spec["entry"].get("id", ""), "age": spec["age"],
					"boards": p.boards, "triangles": _triangles(p), "man_height": _man_height(man),
					"rail_height": float(sp.CLASSES[StringName(spec["entry"].get("class", "common"))]["rail"]["h"]),
					"wall_height": 2.0})
			# A probe's viewport settings for this panel's shots (put back after).
			var view_was := {}
			for k in spec.get("view", {}):
				view_was[k] = viewport.get(k)
				viewport.set(k, spec["view"][k])
			# A probe's environment settings and SSIL quality for this panel's shots (put back after).
			var env: Environment = load("res://src/debug/look_preset.gd").environment(self)
			var env_was := {}
			for k in spec.get("env", {}):
				env_was[k] = env.get(k)
				env.set(k, spec["env"][k])
			if spec.get("ssil_full", false):
				RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_HIGH, false, 0.5, 4, 50.0, 300.0)
			# Each light with its views, or (--review) just the shots Sean reviews by.
			var shots := []
			for light in lights:
				for v in views:
					shots.append([light, v])
			if _review:
				shots = REVIEW_SHOTS.duplicate()
				if views.has("rail"):
					shots += REVIEW_FINE
			var lit := ""
			for shot in shots:
				var light: String = shot[0]
				var v: String = shot[1]
				if light != lit:
					lit = light
					clock.set_time(HOURS[light])
					var night: bool = light == "saloon"
					for l in lamps:
						l.visible = night
					room.visible = night
					for i in 12:
						await process_frame
				var view: Array = views[v]
				cam.global_position = pt * (view[0] as Vector3)
				cam.look_at(pt * (view[1] as Vector3), Vector3.UP)
				cam.fov = view[2]
				if _aa_taa:
					viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
					viewport.use_taa = true
				# The real look's temporal upscaler (FSR2) settles over ~40 frames after a cut
				# (config/looks/real.json "frames"); at 6 the unsettled jitter read as a woven
				# crosshatch on fine grain: round 1 and 2's "burlap" was partly that.
				for i in _settle:
					await process_frame
				# Nothing over the picture (the blacksmith's subtitles, the wound words).
				for c in viewport.find_children("*", "CanvasLayer", true, false):
					(c as CanvasLayer).visible = false
				await process_frame
				var path := "%s/%s_%s.png" % [pdir, light, v]
				viewport.get_texture().get_image().save_png(path)
				print("saved %s/%s/%s_%s" % [family, name, light, v])
			for k in view_was:
				viewport.set(k, view_was[k])
			for k in env_was:
				env.set(k, env_was[k])
			if spec.get("ssil_full", false):
				RenderingServer.environment_set_ssil_quality(RenderingServer.ENV_SSIL_QUALITY_MEDIUM, true, 0.5, 4, 50.0, 300.0)
		var f := FileAccess.open(dir + "/numbers.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(numbers, "  "))
		f.close()
		for b in built:
			(b[1] as Node).queue_free()
		await process_frame


## What a family puts on panels: [{entry, age, name, ...}].
func _panel_specs(ml, family: String) -> Array:
	var out := []
	if family == "bisect":
		# The weave's bisect (#721, Sean 2026-11-10): one flat panel, the same 1 m shot, the shader's
		# layers on one at a time (scan_wood.gdshader `bisect`), then all of them without round 4's dials.
		var bid: String = _panel_entries[0] if not _panel_entries.is_empty() else "rough_pine_batten"
		var be: Dictionary = ml.entry(bid)
		var bage: String = _panel_ages[0] if _panel_ages.size() < 3 else "old"
		var names := ["0_flat", "1_colour", "2_contrast", "3_normal", "4_rough", "5_boards", "6_weathering",
				"7_shelter", "8_edge_dirt", "9_all"]
		for k in names.size():
			out.append({"entry": be, "age": bage, "name": "%s_%s_%s" % [bid, bage, names[k]], "warp_gain": 0.0,
					"dials": {"bisect": k}, "views": {"near": PANEL_VIEWS["near"]}, "seed": 3})
		out.append({"entry": be, "age": bage, "name": "%s_%s_9_all_no_r4" % [bid, bage], "warp_gain": 0.0,
				"dials": {"bisect": 99, "shelter_dark": 0.0, "old_dark": 0.0, "lap_shade": 0.0,
				"tint_old": Color(1, 1, 1)}, "views": {"near": PANEL_VIEWS["near"]}, "seed": 3})
		return out
	if family == "probe":
		# One panel, the same shot, dials varied: what makes the 1 m picture noisy (#721).
		var pid: String = _panel_entries[0] if not _panel_entries.is_empty() else "rough_pine_batten"
		var pe: Dictionary = ml.entry(pid)
		var age: String = _panel_ages[0] if _panel_ages.size() < 3 else "few"
		var variants := {
			"base": {}, "no_relief": {"normal_strength": 0.0}, "soft_relief": {"detail_bias": 2.0},
			"no_sheen": {"roughness_add": 0.6, "specular_wood": 0.0}, "albedo_soft": {"detail_bias": 2.0, "albedo_bias": 1.0},
		}
		# --probe-ss: the same shot with the real look's screen-space effects varied (the 1 m patches).
		if _probe_ss:
			variants = {
				"ss_base": {"env": {}},
				"no_ssil": {"env": {"ssil_enabled": false}},
				"no_ssao": {"env": {"ssao_enabled": false}},
				"no_ssil_ssao": {"env": {"ssil_enabled": false, "ssao_enabled": false}},
				"ssil_full": {"env": {}, "ssil_full": true},
			}
		# --probe-aa: the same shot under the viewport's upscalers and antialiasing instead.
		if _probe_aa:
			variants = {
				"fsr2": {"view": {}},
				"bilinear": {"view": {"scaling_3d_mode": Viewport.SCALING_3D_MODE_BILINEAR}},
				"taa": {"view": {"scaling_3d_mode": Viewport.SCALING_3D_MODE_BILINEAR, "use_taa": true}},
				"msaa4": {"view": {"scaling_3d_mode": Viewport.SCALING_3D_MODE_BILINEAR, "msaa_3d": Viewport.MSAA_4X}},
			}
		for vn in variants:
			var d: Dictionary = variants[vn]
			var dials: Dictionary = {} if (d.has("view") or d.has("env")) else d
			out.append({"entry": pe, "age": age, "name": "%s_%s_%s" % [pid, age, vn], "dials": dials,
					"view": d.get("view", {}), "env": d.get("env", {}), "ssil_full": d.get("ssil_full", false),
					"views": {"near": PANEL_VIEWS["near"]}, "seed": 3})
		return out
	if family == "long" or family == "shape":
		# Part 1 on a long wall, part 5 on a rough wall: before (off) and after, each age.
		var id: String = "common_pine_lap" if family == "long" else "rough_pine_batten"
		if not _panel_entries.is_empty():
			id = _panel_entries[0]
		var e: Dictionary = ml.entry(id)
		for age in (["few"] if family == "long" else _panel_ages):
			if family == "long":
				out.append({"entry": e, "age": age, "name": "%s_%s_before" % [id, age], "variety": 0.0, "long": 12.0, "views": LONG_VIEWS})
				out.append({"entry": e, "age": age, "name": "%s_%s_after" % [id, age], "variety": 1.0, "long": 12.0, "views": LONG_VIEWS})
			else:
				out.append({"entry": e, "age": age, "name": "%s_%s_true" % [id, age], "warp_gain": 0.0, "views": SHAPE_VIEWS})
				out.append({"entry": e, "age": age, "name": "%s_%s_warped" % [id, age], "warp_gain": 1.0, "views": SHAPE_VIEWS})
		return out
	var i := 0
	for e in ml.entries(family):
		if not _panel_entries.is_empty() and not _panel_entries.has(e["id"]):
			continue
		for age in _panel_ages:
			var spec := {"entry": e, "age": age, "name": "%s_%s" % [e["id"], age], "seed": i}
			if String(e.get("class", "")) == "fine":
				var v := PANEL_VIEWS.duplicate()
				v["rail"] = RAIL_VIEW
				spec["views"] = v
			out.append(spec)
			i += 1
	return out


## A plain room round a panel for the night (the saloon's): side walls, a ceiling, a wall behind
## the camera, dark painted boards; the panel is its far wall.
func _night_room() -> Node3D:
	var room := Node3D.new()
	room.name = "NightRoom"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.11, 0.075)
	mat.roughness = 0.8
	for b in [[Vector3(-0.45, 1.6, -3.3), Vector3(0.1, 3.4, 6.8)], [Vector3(3.15, 1.6, -3.3), Vector3(0.1, 3.4, 6.8)],
			[Vector3(1.35, 3.25, -3.3), Vector3(3.7, 0.1, 6.8)], [Vector3(1.35, 1.6, -6.6), Vector3(3.7, 3.4, 0.1)],
			[Vector3(1.35, 1.6, 0.06), Vector3(3.7, 3.4, 0.04)], [Vector3(1.35, -0.03, -3.3), Vector3(3.7, 0.04, 6.8)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = b[1]
		mi.mesh = bm
		mi.material_override = mat
		mi.position = b[0]
		room.add_child(mi)
	room.visible = false
	return room


func _triangles(n: Node) -> int:
	var t := 0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = (mi as MeshInstance3D).mesh
		for s in m.get_surface_count():
			t += (m.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return t


## The man's height in metres (his skin's box, standing).
func _man_height(man: Node3D) -> float:
	var top := -INF
	var bottom := INF
	for mi in man.find_children("*", "MeshInstance3D", true, false):
		if not (mi as MeshInstance3D).visible:
			continue
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		top = maxf(top, bb.end.y)
		bottom = minf(bottom, bb.position.y)
	return snappedf(top - bottom, 0.01) if top > bottom else 0.0
