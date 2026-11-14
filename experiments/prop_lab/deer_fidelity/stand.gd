extends SceneTree
## The deer head's fidelity stand (issue #524; README.md beside this file): each version of the deer
## (deer_variants.gd) hung alone on a boarded wall at the saloon's height, the same cameras and the
## same light for every one, and its cost.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/prop_lab/deer_fidelity/stand.gd -- \
##       --out=DIR [--only=C0,A] [--views=front,close] [--lights=studio] [--dir=VARIANTS]
##
## DIR/<variant>_<light>_<view>.png and DIR/costs.json. Views: front, threeq, profile (2 m off,
## a narrow lens: the model itself), close (a step away from under it, the player's eye and lens),
## across (the saloon's width off, 9 m, the player's eye and lens). Lights: studio (neutral: a
## grey room, one white key; A's), day (the prop lab's daylight), lamp (its lamplight, at night).

## (Loaded at run time: the -s script compiles before the autoloads the kit names exist.)
var DV: GDScript
## Where the deer hangs: its origin (the plaque's top, on the wall), as the saloon's (2.7 m up).
const HANG := Vector3(0, 2.7, 0)
## The middle of the head and neck, in its own space (what the near cameras look at).
const MIDDLE := Vector3(0, -0.06, 0.2)
const EYE := 1.64
const GAME_FOV := 75.0

var opts := {}
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D
var lamp: OmniLight3D
var fill: DirectionalLight3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var out: String = opts.get("out", "build/deer_fidelity/stand")
	DirAccess.make_dir_recursive_absolute(out)
	DV = load("res://experiments/prop_lab/deer_fidelity/deer_variants.gd")
	var dv = DV.new(opts.get("dir", ""))
	var ids: Array = Array(String(opts.get("only", ",".join(DV.VARIANTS.keys()))).split(",", false))
	var views: Array = Array(String(opts.get("views", "front,threeq,profile,close,across")).split(",", false))
	var lights: Array = Array(String(opts.get("lights", "studio,day,lamp")).split(",", false))
	_build_room()
	var costs := {}
	var crops := {}
	for id: String in ids:
		var t0 := Time.get_ticks_usec()
		var deer: Node3D = dv.node(id)
		var load_ms := (Time.get_ticks_usec() - t0) / 1000.0
		deer.position = HANG
		world.add_child(deer)
		var was := {}
		for k: String in DV.globals(id):
			was[k] = RenderingServer.global_shader_parameter_get(StringName(k))
			RenderingServer.global_shader_parameter_set(StringName(k), DV.globals(id)[k])
		var c := {"label": DV.VARIANTS[id].label, "triangles": dv.triangles(id), "materials": 1, "load_ms": snappedf(load_ms, 0.1)}
		c.merge(dv.texture_bytes(id))
		var render := {}
		for light: String in lights:
			_light(light)
			for view: String in views:
				_view(view)
				for i in 6:
					await process_frame
				await RenderingServer.frame_post_draw
				vp.get_texture().get_image().save_png(out.path_join("%s_%s_%s.png" % [id, light, view]))
				if light == "studio" and view in ["close", "across"]:
					render[view] = await _render_cost()
		c["render"] = render
		if crops.is_empty():
			crops = await _crops(deer, views)
		costs[id] = c
		print(id, " ", JSON.stringify(c))
		deer.queue_free()
		for k: String in was:
			RenderingServer.global_shader_parameter_set(StringName(k), was[k])
		await process_frame
	var f := FileAccess.open(out.path_join("costs.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(costs, "  "))
	f = FileAccess.open(out.path_join("crops.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(crops, "  "))
	quit()


## Each view's square round the deer on the frame (px: x, y, side), for the contact sheet: the
## deer drawn alone on a flat background, its pixels' box.
func _crops(_deer: Node3D, views: Array) -> Dictionary:
	var out := {}
	for n: String in ["Wall", "Floor"]:
		(world.get_node(n) as Node3D).visible = false
	_light("studio")
	env.background_color = Color(1, 0, 1)
	for view: String in views:
		_view(view)
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var lo := Vector2i(img.get_width(), img.get_height())
		var hi := Vector2i(-1, -1)
		var bg := img.get_pixel(0, 0)
		for y in range(0, img.get_height(), 2):
			for x in range(0, img.get_width(), 2):
				var c := img.get_pixel(x, y)
				if absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) > 0.12:
					lo = lo.min(Vector2i(x, y))
					hi = hi.max(Vector2i(x, y))
		var side := int(maxi(hi.x - lo.x, hi.y - lo.y) * 1.1) + 4
		var c := (lo + hi) / 2
		out[view] = [c.x - side / 2, c.y - side / 2, side]
	for n: String in ["Wall", "Floor"]:
		(world.get_node(n) as Node3D).visible = true
	return out


## Draw calls and the frame's render time with only the deer on (the wall and floor hidden), 30 frames:
## under lavapipe the GPU's work is the CPU's, so its time stands in for what the card would do.
func _render_cost() -> Dictionary:
	for n: String in ["Wall", "Floor"]:
		(world.get_node(n) as Node3D).visible = false
	var rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for i in 4:
		await RenderingServer.frame_post_draw
	var gpu := 0.0
	var cpu := 0.0
	var draws := 0
	for i in 30:
		await RenderingServer.frame_post_draw
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		draws = RenderingServer.viewport_get_render_info(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
				RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	RenderingServer.viewport_set_measure_render_time(rid, false)
	for n: String in ["Wall", "Floor"]:
		(world.get_node(n) as Node3D).visible = true
	return {"gpu_ms": snappedf(gpu / 30.0, 0.01), "cpu_ms": snappedf(cpu / 30.0, 0.01), "draws": draws}


func _build_room() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(1280, 720)  # the game's 3D resolution
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	# The wall it hangs on (the saloon's inside boards), its face at z = 0, and a floor.
	var wall := MeshInstance3D.new()
	wall.name = "Wall"
	wall.mesh = MemberMesh.box(Vector3(14, 6, 0.1))
	wall.material_override = load("res://src/structures/wood_materials.gd").get_material(&"int_boards", 0)
	wall.position = Vector3(0, 3.0, -0.05)
	world.add_child(wall)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(14, 14)
	floor_mi.mesh = plane
	floor_mi.material_override = load("res://src/structures/wood_materials.gd").get_material(&"floor", 1)
	floor_mi.position = Vector3(0, 0, 7)
	floor_mi.name = "Floor"
	wall.add_sibling(floor_mi)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	world.add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	world.add_child(sun)
	fill = DirectionalLight3D.new()
	world.add_child(fill)
	lamp = OmniLight3D.new()
	lamp.omni_range = 7.0
	lamp.light_color = Color(1.0, 0.74, 0.48)
	lamp.shadow_enabled = true
	world.add_child(lamp)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true


func _light(which: String) -> void:
	fill.light_energy = 0.0
	lamp.light_energy = 0.0
	match which:
		"studio":
			# Neutral: a grey room, one white key high and to the left, a soft fill from the right.
			env.background_color = Color(0.32, 0.32, 0.32)
			env.ambient_light_color = Color(0.4, 0.4, 0.4)
			env.ambient_light_energy = 1.0
			sun.light_color = Color.WHITE
			sun.light_energy = 1.3
			sun.rotation_degrees = Vector3(-35, -30, 0)
			fill.light_color = Color.WHITE
			fill.light_energy = 0.35
			fill.rotation_degrees = Vector3(-10, 50, 0)
		"day":
			# The prop lab's daylight (bench.gd --look), the sun in at a window from the left.
			env.background_color = Color(0.55, 0.6, 0.68)
			env.ambient_light_color = Color(0.5, 0.47, 0.42)
			env.ambient_light_energy = 1.0
			sun.light_energy = 1.2
			sun.light_color = Color(1.0, 0.9, 0.75)
			sun.rotation_degrees = Vector3(-35, -40, 0)
		"lamp":
			# Its lamplight: night, one oil lamp in a sconce a metre and a half off along the wall.
			env.background_color = Color(0.08, 0.06, 0.05)
			env.ambient_light_color = Color(0.25, 0.2, 0.17)
			env.ambient_light_energy = 1.0
			sun.light_energy = 0.15
			sun.light_color = Color(0.6, 0.7, 1.0)
			sun.rotation_degrees = Vector3(-55, 20, 0)
			lamp.light_energy = 2.2
			lamp.position = HANG + Vector3(-1.4, -0.5, 0.35)


func _view(which: String) -> void:
	var mid := HANG + MIDDLE
	match which:
		"front", "threeq", "profile":
			var yaw: float = {"front": 0.0, "threeq": 40.0, "profile": 80.0}[which]
			cam.fov = 30.0
			cam.position = mid + Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0, 0.05, 2.0)
		"close":
			# A couple of steps off, standing under it: the player's eye and lens.
			cam.fov = GAME_FOV
			cam.position = Vector3(0.3, EYE, 1.6)
		"across":
			cam.fov = GAME_FOV
			cam.position = Vector3(1.5, EYE, 9.0)
	cam.look_at(mid)
