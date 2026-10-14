extends SceneTree
## The render lab (experiments/render_lab/README.md): one small stage with the game's own assets
## (a Rodin portrait man in his hat, the code-modelled chair, barrel and card table, a saloon
## corner and a street façade built of the game's board members and lamps, the game's sky, sun,
## grade and day cycle) photographed from fixed cameras in fixed lights, once per look. Only the
## look changes between runs; nothing here touches the game's own scenes or defaults.
##
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://experiments/render_lab/lab.gd -- \
##       --out=build/render_lab/base --look=base [--shots=man_near,man_far,props,corner,facade]
##       [--lights=lamp,day,golden] [--motion] [--probe] [--man=bold_cowboy_rodin] [--size=1280x720]
##
## --look=: base (the game as it is), paint (the experiment: LabLooks), blocks (the existing M
## look, for reference: pass --blocks too, Settings reads it before anything is built).
## --probe: each still also as painted (every surface's own colour, unlit, no grade): the
## light's share of each pixel is the lit frame against it (tools: analyse.py light).
## --motion: two camera paths as numbered frames (an orbit round the man in lamplight, a walk
## past the façade at golden hour) for analyse.py motion.

const LabLooks := preload("res://experiments/render_lab/lab_looks.gd")

## Where things stand. The corner is open toward +Z; the façade faces +Z far enough off that the
## corner's lamps don't reach it.
const CORNER := Vector3.ZERO
const FACADE := Vector3(40, 0, 0)
## Behind the card table, its lamp between him and the camera (the saloon painting's way).
const MAN_IN := Vector3(0.25, 0.0, -2.25)
const MAN_OUT := FACADE + Vector3(-0.8, 0.0, 0.2)
## The lights: an hour of the game's day cycle and which set the man and props stand in.
const LIGHTS := {"lamp": {"hour": 22.0, "set": "in"}, "day": {"hour": 12.5, "set": "out"},
		"golden": {"hour": 17.6, "set": "out"}}
## The man's three views (degrees round from straight in front) and two distances: near (his head
## and shoulders, a man across a table) and far (the whole man at a normal distance in play).
const VIEWS := {"front": 0.0, "three_quarter": 40.0, "profile": 90.0}
const NEAR := {"dist": 0.85, "height": 1.62, "aim": 1.6, "fov": 40.0}
const FAR := {"dist": 4.0, "height": 1.65, "aim": 1.0, "fov": 60.0}

var out := "build/render_lab/base"
var look := "base"
var shots := ["man_near", "man_far", "props", "corner", "facade"]
var lights := ["lamp", "day", "golden"]
var motion := false
var probe := false
var man_id := "bold_cowboy_rodin"
var size := Vector2i(1280, 720)
## --env=name:value,...: Environment properties set over the day cycle's (an existing control
## tried as a control, e.g. --env=tonemap_mode:4 for AgX, tonemap_exposure:0.8).
var env_over := {}

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var env_node: WorldEnvironment
var day: Node
var men := {}
var lamps: Array = []
var stats := {"frames": 0, "render_cpu_ms": [], "render_gpu_ms": []}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--look="):
			look = a.substr(7)
		elif a.begins_with("--shots="):
			shots = Array(a.substr(8).split(","))
		elif a.begins_with("--lights="):
			lights = Array(a.substr(9).split(","))
		elif a == "--motion":
			motion = true
		elif a == "--probe":
			probe = true
		elif a.begins_with("--man="):
			man_id = a.substr(6)
		elif a.begins_with("--env="):
			for pair in a.substr(6).split(","):
				env_over[pair.get_slice(":", 0)] = float(pair.get_slice(":", 1))
		elif a.begins_with("--size="):
			var p := a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	_build()
	for f in 20:
		await physics_frame
	var looks := look.split(",")
	var base_out := out
	for lk in looks:
		# One run, several looks: the switch is live (lab_looks.gd swaps the materials' shaders in
		# place), each look's frames in its own folder.
		out = base_out if looks.size() == 1 else base_out.path_join(lk)
		DirAccess.make_dir_recursive_absolute(out)
		stats = {"frames": 0, "render_cpu_ms": [], "render_gpu_ms": []}
		var t1 := Time.get_ticks_msec()
		LabLooks.apply(world, lk)
		var log := []
		for l: String in lights:
			_set_light(l)
			for f in 30:
				await process_frame
			for s: String in shots:
				for fr: Array in _frames_for(s, l):
					_place_camera(fr[1])
					await _settle()
					_save("%s__%s" % [fr[0], l])
					if probe:
						LabLooks.probe(world, env_node.environment, true)
						await _settle()
						_save("%s__%s__paint" % [fr[0], l], false)
						LabLooks.probe(world, env_node.environment, false)
					log.append("%s__%s" % [fr[0], l])
		if motion:
			await _motion()
		stats["seconds"] = (Time.get_ticks_msec() - t1) / 1000.0
		stats["look"] = lk
		stats["shots"] = log
		stats["render_cpu_ms_mean"] = _mean(stats.render_cpu_ms)
		stats["render_gpu_ms_mean"] = _mean(stats.render_gpu_ms)
		stats.erase("render_cpu_ms")
		stats.erase("render_gpu_ms")
		var f := FileAccess.open(out + "/run.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(stats, "\t"))
		f.close()
		print("render_lab: %s, %d frames in %.0f s" % [lk, stats.frames, stats.seconds])
	print("render_lab: done in %.0f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit(0)


# --- the stage ---------------------------------------------------------------------------------

func _build() -> void:
	vp = SubViewport.new()
	vp.size = size
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# As the game's GameViewport (scenes/main.tscn): every lamp's shadow a cell of one size.
	vp.positional_shadow_atlas_size = 4096
	vp.positional_shadow_atlas_quad_0 = 3
	vp.positional_shadow_atlas_quad_1 = 3
	vp.positional_shadow_atlas_quad_3 = 3
	root.add_child(vp)
	RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	world = Node3D.new()
	world.name = "Lab"
	vp.add_child(world)
	# The game's own sky, sun, moon, grade and day cycle, taken from the street scene's file
	# (instanced but never put in the tree, so none of the street is built).
	var street: Node = load("res://scenes/test_street.tscn").instantiate()
	env_node = street.get_node("WorldEnvironment")
	var sun: Node = street.get_node("Sun")
	var moon: Node = street.get_node("Moon")
	var cycle: Node = street.get_node("DayCycle")
	var ground: Node = street.get_node("Ground")
	for n: Node in [env_node, sun, moon, ground]:
		n.owner = null
		street.remove_child(n)
		world.add_child(n)
	env_node.environment = env_node.environment.duplicate(true)
	cycle.owner = null
	street.remove_child(cycle)
	cycle.sun = sun
	cycle.moon = moon
	cycle.world_environment = env_node
	cycle.time_scale = 0.0
	world.add_child(cycle)
	cycle.set_process(false)
	cycle.set_physics_process(false)
	day = cycle
	street.free()
	_corner()
	_facade()
	# A HumanBody faces -Z: turned round to face +Z, the cameras' side.
	men["in"] = _man(MAN_IN, 180.0)
	men["out"] = _man(MAN_OUT, 180.0)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true


func _boards(parent: Node3D, wood: StringName, length: float, count: int, width: float,
		thick: float, place: Callable) -> void:
	for i in count:
		var mi := MeshInstance3D.new()
		mi.mesh = MemberMesh.box(Vector3(length, width, thick))
		mi.material_override = WoodMaterials.get_material(wood, i)
		parent.add_child(mi)
		mi.transform = place.call(i)


## A saloon corner: a floor of the saloon's boards, two walls and a ceiling, a card table with a
## lamp on it, a chair, a barrel and a sconce, open toward +Z.
func _corner() -> void:
	var c := Node3D.new()
	c.name = "Corner"
	world.add_child(c)
	c.position = CORNER
	var bw := 0.15
	_boards(c, &"floor", 6.0, 30, bw, 0.03, func(i): return Transform3D(Basis.from_euler(Vector3(-PI / 2, 0, 0)), Vector3(0, 0.015, -3.0 + bw * (i + 0.5))))
	var wh := 0.2
	_boards(c, &"saloon_wall", 6.0, 16, wh, 0.025, func(i): return Transform3D(Basis.IDENTITY, Vector3(0, wh * (i + 0.5), -3.0)))
	_boards(c, &"saloon_wall", 4.5, 16, wh, 0.025, func(i): return Transform3D(Basis.from_euler(Vector3(0, PI / 2, 0)), Vector3(-3.0, wh * (i + 0.5), -0.75)))
	_boards(c, &"saloon_wall", 4.5, 16, wh, 0.025, func(i): return Transform3D(Basis.from_euler(Vector3(0, PI / 2, 0)), Vector3(3.0, wh * (i + 0.5), -0.75)))
	_boards(c, &"floor", 6.0, 30, bw, 0.03, func(i): return Transform3D(Basis.from_euler(Vector3(PI / 2, 0, 0)), Vector3(0, 3.2, -3.0 + bw * (i + 0.5))))
	var table: Node3D = PropModels.build(&"card_table")
	c.add_child(table)
	table.position = Vector3(0.7, 0, -1.4)
	var chair: Node3D = PropModels.build(&"chair")
	c.add_child(chair)
	chair.position = Vector3(1.55, 0, -1.0)
	chair.rotation_degrees.y = -70.0
	var barrel: Node3D = PropModels.build(&"barrel")
	c.add_child(barrel)
	barrel.position = Vector3(-2.3, 0, -2.3)
	var lamp = load("res://src/world/oil_lamp.gd").new()
	c.add_child(lamp)
	lamp.position = table.position + Vector3(0.1, 0.78, 0.05)
	lamps.append(lamp)
	var sconce = load("res://src/world/oil_lamp.gd").new()
	sconce.energy = 1.0
	sconce.light_range = 6.0
	c.add_child(sconce)
	sconce.position = Vector3(-1.4, 2.0, -2.8)
	lamps.append(sconce)
	var sm: Node3D = PropModels.build(&"wall_sconce")
	if sm:
		c.add_child(sm)
		sm.position = sconce.position + Vector3(0, -0.25, -0.1)


## A street façade: lap siding of the street's weathered pine on a sill, corner posts, a door
## frame and a board walk, a sign over the door; a wall lantern beside it.
func _facade() -> void:
	var f := Node3D.new()
	f.name = "Facade"
	world.add_child(f)
	f.position = FACADE
	var wh := 0.2
	_boards(f, &"weathered_pine", 7.0, 22, wh, 0.03, func(i): return Transform3D(Basis.from_euler(Vector3(-0.05, 0, 0)), Vector3(0, 0.35 + wh * (i + 0.5) * 0.97, -2.0)))
	for x in [-3.5, 3.5, -0.6, 0.6]:
		var post := MeshInstance3D.new()
		post.mesh = MemberMesh.box(Vector3(0.15, 4.6, 0.15))
		post.material_override = WoodMaterials.get_material(&"weathered_pine", int(x * 10))
		f.add_child(post)
		post.position = Vector3(x, 2.3, -1.9)
	_boards(f, &"weathered_pine", 7.0, 12, 0.18, 0.04, func(i): return Transform3D(Basis.from_euler(Vector3(-PI / 2, 0, 0)), Vector3(0, 0.3, -1.85 + 0.18 * (i + 0.5))))
	var door := MeshInstance3D.new()
	door.mesh = BoxMesh.new()
	door.mesh.size = Vector3(1.05, 2.2, 0.05)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.035, 0.025)
	door.material_override = dark
	f.add_child(door)
	door.position = Vector3(0, 1.45, -1.97)
	var tex := PixelArt.factory("sign")
	var sign_tex: Texture2D = load("res://assets/textures/sign_saloon_drawn.png") if ResourceLoader.exists("res://assets/textures/sign_saloon_drawn.png") else tex
	var sign := MeshInstance3D.new()
	sign.mesh = MemberMesh.box(Vector3(3.2, 0.7, 0.05))
	# The box's front face runs u right to left: the lettering flipped to read from the street.
	var flipped := sign_tex.get_image()
	flipped.flip_y()
	var sm := PixelArt.material(ImageTexture.create_from_image(flipped))
	sm.set_shader_parameter(&"fixed_squares", true)
	sign.material_override = sm
	f.add_child(sign)
	sign.position = Vector3(0, 3.3, -1.92)
	var lantern = load("res://src/world/oil_lamp.gd").new()
	lantern.energy = 0.9
	lantern.light_range = 5.0
	f.add_child(lantern)
	lantern.position = Vector3(1.0, 2.3, -1.75)
	lamps.append(lantern)


func _man(at: Vector3, turn: float) -> Node3D:
	var body_script = load("res://src/bodies/human_body.gd")
	var m = body_script.new()
	m.body_model = StringName(man_id)
	m.person_id = StringName("lab_" + man_id + str(at.x))
	m.rng_seed = 7
	world.add_child(m)
	m.global_position = at
	m.rotation_degrees.y = turn
	return m


func _set_light(l: String) -> void:
	day.set_time(LIGHTS[l].hour)
	for k: String in env_over:
		var v = env_over[k]
		env_node.environment.set(k, int(v) if k.ends_with("_mode") else v)
	for lamp in lamps:
		lamp.set_lit(lamp.should_be_lit(int(LIGHTS[l].hour)))
		# Held steady: no flicker, so frames differ by the camera and the look alone.
		lamp.set_process(false)
		lamp._light.light_energy = lamp.energy


# --- the shots ---------------------------------------------------------------------------------

## The frames for a shot in a light: [name, {pos, aim, fov}].
func _frames_for(s: String, l: String) -> Array:
	var set_name: String = LIGHTS[l].set
	var man: Node3D = men[set_name]
	var r := []
	match s:
		"man_near", "man_far":
			var d: Dictionary = NEAR if s == "man_near" else FAR
			for v: String in VIEWS:
				var a := deg_to_rad(VIEWS[v])
				var base := man.global_position
				var dir := Vector3(sin(a), 0, cos(a))
				r.append(["%s_%s" % [s, v], {"pos": base + dir * d.dist + Vector3(0, d.height, 0),
						"aim": base + Vector3(0, d.aim, 0), "fov": d.fov}])
		"props":
			if set_name == "in":
				r.append(["props", {"pos": CORNER + Vector3(0.9, 1.5, 1.2), "aim": CORNER + Vector3(0.0, 0.5, -1.6), "fov": 55.0}])
		"corner":
			if set_name == "in":
				r.append(["corner", {"pos": CORNER + Vector3(2.2, 1.6, 1.3), "aim": CORNER + Vector3(-1.2, 1.1, -2.2), "fov": 70.0}])
		"facade":
			if set_name == "out":
				r.append(["facade", {"pos": FACADE + Vector3(2.5, 1.65, 5.5), "aim": FACADE + Vector3(-0.5, 2.0, -2.0), "fov": 70.0}])
	return r


func _place_camera(c: Dictionary) -> void:
	cam.fov = c.fov
	cam.global_position = c.pos
	cam.look_at(c.aim, Vector3.UP)


func _settle() -> void:
	# Frames enough for shadows, fog, a new shader and the probe swap all to catch up.
	for f in 8:
		await process_frame


func _save(name: String, timed := true) -> void:
	var img := vp.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	if not timed:
		return
	var rid := vp.get_viewport_rid()
	stats.frames += 1
	stats.render_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
	stats.render_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))


## Two paths, one frame a step, for analyse.py motion: an orbit of 60 degrees round the man in the
## corner's lamplight at 1.8 m, and a sideways walk past the façade at golden hour.
func _motion() -> void:
	var dir := out + "/motion"
	DirAccess.make_dir_recursive_absolute(dir + "/orbit")
	DirAccess.make_dir_recursive_absolute(dir + "/walk")
	_set_light("lamp")
	for f in 8:
		await process_frame
	var man: Node3D = men["in"]
	var n := 48
	for i in n:
		var a := deg_to_rad(-30.0 + 60.0 * i / float(n - 1))
		_place_camera({"pos": man.global_position + Vector3(sin(a) * 1.8, 1.6, cos(a) * 1.8),
				"aim": man.global_position + Vector3(0, 1.35, 0), "fov": 60.0})
		await process_frame
		await process_frame
		vp.get_texture().get_image().save_png("%s/orbit/%03d.png" % [dir, i])
	_set_light("golden")
	for f in 8:
		await process_frame
	for i in n:
		var x := -2.0 + 4.0 * i / float(n - 1)
		_place_camera({"pos": FACADE + Vector3(x, 1.65, 4.0), "aim": FACADE + Vector3(x * 0.6, 1.8, -2.0), "fov": 70.0})
		await process_frame
		await process_frame
		vp.get_texture().get_image().save_png("%s/walk/%03d.png" % [dir, i])


func _mean(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for v in a:
		s += v
	return s / a.size()
