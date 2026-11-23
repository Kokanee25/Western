extends SceneTree
## The game's own viewmodels (RevolverViewmodel with the approved Colt, Winchester73Viewmodel) from
## the player's eye on a plain stage, for posing by eye (#1014): seconds a pose, not the town's
## ten minutes. Each pose is the game's state driven in game seconds (the viewmodel's _process
## stepped by hand at 60 a second), so a cock or a kick is caught at a set time after it starts.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan --resolution 1280x720 \
##       -s res://experiments/viewmodel_rig/game_views.gd -- --out=build/vmg [--guns=revolver,winchester] \
##       [--only=idle,aimed,cocking,firing,reloading] [--light=day|lamp|both] [--fov=DEG] [--painted-arms]
##       [--shot-at=S] [--fog]
##
## --fov sets the viewmodel's own field of view (0: the world camera's, as before #1014).
## Writes OUT/<gun>_<pose>_<light>.png. Untyped where it touches game classes (a -s script compiles
## before the autoloads).

const POSES := ["idle", "aimed", "cocking", "firing", "reloading"]

var out := "build/vmg"
var guns := ["revolver", "winchester"]
var only := POSES
var lights := ["day"]
var fov := -1.0
var cam: Camera3D
var world: Node3D
var sun: DirectionalLight3D
var env: Environment
var lamp: OmniLight3D
var close := false
## --world-layer: the gun's meshes on the world's layer, not VIS_HELD (a test of the held layer's light).
var world_layer := false
## --variants=FILE: a JSON list of {"name": .., "set": {hold key: value}} (config/fp_holds.json's
## keys), each rendered in turn with its holds changed: for trying settings side by side.
var variants := [{"name": "", "set": {}}]
## The stage's own nodes (all else in the world is a shot's leavings).
var stage_nodes: Array[Node] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--guns="):
			guns = Array(a.substr(7).split(","))
		elif a.begins_with("--only="):
			only = Array(a.substr(7).split(","))
		elif a.begins_with("--light="):
			lights = ["day", "lamp"] if a.substr(8) == "both" else [a.substr(8)]
		elif a.begins_with("--variants="):
			variants = JSON.parse_string(FileAccess.get_file_as_string(a.substr(11)))
		elif a == "--world-layer":
			world_layer = true
		elif a == "--fog":
			fog = true
		elif a.begins_with("--shot-at="):
			shot_at = float(a.substr(10))
		elif a == "--close":
			close = true
		elif a.begins_with("--fov="):
			fov = float(a.substr(6))
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280, 720)
	_stage()
	stage_nodes = world.get_children()
	var holds: Dictionary = load("res://src/weapons/held_hand.gd").call(&"holds")
	var base := holds.duplicate(true)
	for v: Dictionary in variants:
		holds.clear()
		holds.merge(base.duplicate(true))
		for k: String in v["set"]:
			holds[k] = v["set"][k]
		var tag: String = ("_" + String(v["name"])) if String(v["name"]) != "" else ""
		for g: String in guns:
			for light: String in lights:
				_light(light)
				for p: String in only:
					var vm := _gun(g)
					await _frames(2)
					_pose(vm, g, p)
					if world_layer:
						for mi in vm.find_children("*", "MeshInstance3D", true, false):
							(mi as MeshInstance3D).layers = 1
					await _frames(4)
					var path := out.path_join("%s_%s_%s%s.png" % [g, p, light, tag])
					root.get_texture().get_image().save_png(path)
					Engine.time_scale = 1.0
					print("shot ", path)
					if close:
						await _close(vm, path.get_basename())
					vm.queue_free()
					# What the shot left in the world (smoke, flash, brass) goes too: each pose clean.
					for n in world.get_children():
						if not n in stage_nodes:
							n.queue_free()
					await _frames(1)
	quit()


## Close looks at the hand on the gun: from its right, its left and from above, 30 cm off.
func _close(vm: Node3D, base: String) -> void:
	var model: Node3D = vm.get(&"model")
	var gt := model.global_transform.orthonormalized()
	var at := gt * Vector3(0.0, 0.0, -0.03)
	var c := Camera3D.new()
	c.near = 0.01
	c.fov = 40.0
	world.add_child(c)
	for side: String in ["right", "left", "top"]:
		var off: Vector3 = {"right": Vector3(0.3, 0.02, 0.05), "left": Vector3(-0.3, 0.02, 0.05), "top": Vector3(0.05, 0.3, 0.06)}[side]
		c.global_position = gt * off
		c.look_at(at, gt.basis.y if side != "top" else -gt.basis.z)
		c.current = true
		await _frames(3)
		root.get_texture().get_image().save_png("%s_%s.png" % [base, side])
	cam.current = true
	c.queue_free()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## A fresh viewmodel under the camera (its own state each pose).
func _gun(g: String) -> Node3D:
	var script: Script = load("res://src/weapons/revolver_viewmodel.gd") if g == "revolver" \
			else load("res://src/weapons/winchester73_viewmodel.gd")
	var vm: Node3D = script.new()
	vm.name = "Gun"
	vm.set(&"needs_captured_mouse", false)
	vm.set(&"steady_hands", true)
	cam.fov = 75.0
	cam.rotation = Vector3.ZERO
	cam.position = Vector3.ZERO
	cam.add_child(vm)
	vm.set_process(false)
	vm.set_physics_process(false)
	if fov >= 0.0:
		vm.set(&"view_fov", fov)
	vm.set(&"selected", false)  # no controls read
	return vm


func _step(vm: Node3D, seconds: float) -> void:
	var n := int(round(seconds * 60.0))
	var vk: Object = vm.get(&"view_kick")
	for i in n:
		vm.call(&"_process", 1.0 / 60.0)
		# The view's kick (the gun's _animate_camera only moves a selected gun's camera).
		vk.call(&"step", 1.0 / 60.0)
		# Time stands still for a shot (`_shoot`): the smoke is stepped by hand with the gun (#1048).
		# Its own _process still saw a frame's time now and then with time at 0 (0.03 s over the shot's
		# four held frames), so it's switched off till the frame is saved.
		if Engine.time_scale == 0.0:
			for c in get_root().find_children("*", "GunSmoke", true, false):
				c.set_process(false)
				c.call(&"step", 1.0 / 60.0)
		cam.rotation = Vector3(deg_to_rad(vk.get(&"pitch")), deg_to_rad(-vk.get(&"yaw")), 0.0)


## A real shot (#1019): the gun's own _fire (the ball, smoke, the world's flash and light, the held
## flash, the kick), caught `shot_at` game seconds in. The world's flash and light run on timers, so
## time stands still (time_scale 0) until the frame is saved; `_frames` puts it back.
var shot_at := 0.05
## `--fog`: the valley's volumetric haze (scenes/valley.tscn), so the smoke's fog volume shows as in
## the game (#1048: off, the stage drew only the cloud's particles).
var fog := false


func _shoot(vm: Node3D) -> void:
	vm.set(&"_trigger", 1.0)
	var lit := get_root().find_children("*", "OmniLight3D", true, false)
	vm.call(&"_fire")
	# The world's flash light (ImpactEffects) dies on a 0.07 s timer, which stands still here: past
	# that it's put out by hand, so a later frame is lit as the game lights it (#1048).
	var world_lights: Array[Node] = []
	for l in get_root().find_children("*", "OmniLight3D", true, false):
		if l not in lit and not vm.is_ancestor_of(l):
			world_lights.append(l)
	Engine.time_scale = 0.0
	for i in int(round(shot_at * 60.0)):
		_step(vm, 1.0 / 60.0)
		if (i + 1) / 60.0 >= 0.07:
			for l in world_lights:
				if is_instance_valid(l):
					l.queue_free()
			world_lights.clear()


func _pose(vm: Node3D, g: String, p: String) -> void:
	var st: Object = vm.get(&"state")
	_step(vm, 0.5)
	if g == "revolver":
		match p:
			"aimed":
				st.call(&"cock")
				vm.set(&"aiming", true)
				_step(vm, 1.0)
			"cocking":
				vm.call(&"cock_press")
				_step(vm, 0.08)
			"firing":
				st.call(&"cock")
				vm.set(&"aiming", true)
				_step(vm, 1.0)
				_shoot(vm)
			"reloading":
				st.set(&"hammer", 1)
				var ch: Array = st.get(&"chambers")
				for i in ch.size():
					ch[i] = 2  # spent
				ch[0] = 1  # the round just pressed in
				st.set(&"gate_open", true)
				_step(vm, 0.6)
				vm.set(&"_ejector", 0.0)
	else:
		match p:
			"aimed":
				vm.set(&"aiming", true)
				_step(vm, 1.2)
			"cocking":
				vm.call(&"lever_open")
				_step(vm, 0.4)
			"firing":
				vm.set(&"aiming", true)
				_step(vm, 1.2)
				_shoot(vm)
			"reloading":
				st.set(&"tube", 0)
				st.set(&"own_belt", 20)  # a round to load (#1031: with none the reload never started)
				vm.call(&"reload_press")
				_step(vm, 0.5)


func _light(which: String) -> void:
	var day := which == "day"
	sun.visible = day
	lamp.visible = not day
	env.background_energy_multiplier = 1.0 if day else 0.04
	env.ambient_light_energy = 0.8 if day else 0.05


func _stage() -> void:
	world = Node3D.new()
	root.add_child(world)
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.52, 0.75)
	sm.sky_horizon_color = Color(0.78, 0.74, 0.66)
	sm.ground_horizon_color = Color(0.55, 0.47, 0.38)
	sm.ground_bottom_color = Color(0.32, 0.27, 0.22)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	if fog:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.006
		env.volumetric_fog_albedo = Color(0.8, 0.75, 0.68)
		env.volumetric_fog_length = 48.0
		env.volumetric_fog_ambient_inject = 0.15
	we.environment = env
	world.add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_energy = 2.2
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-32.0, 150.0, 0.0)
	world.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.52, 0.43, 0.33)
	fm.roughness = 1.0
	pm.material = fm
	floor_mi.mesh = pm
	world.add_child(floor_mi)
	for i in 5:
		var post := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.25, 2.4, 0.25)
		var wm := StandardMaterial3D.new()
		wm.albedo_color = Color(0.4, 0.3, 0.22)
		bm.material = wm
		post.mesh = bm
		post.position = Vector3(-6.0 + i * 3.0, 1.2, -9.0 - (i % 2) * 3.0)
		world.add_child(post)
	lamp = OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.7, 0.4)
	lamp.light_energy = 2.5
	lamp.omni_range = 6.0
	lamp.shadow_enabled = true
	lamp.position = Vector3(0.9, 1.9, -0.6)
	world.add_child(lamp)
	world.add_child(load("res://src/ballistics/ballistics.gd").new())  # the real shot needs one
	var head := Node3D.new()
	head.position = Vector3(0, 1.62, 0)
	world.add_child(head)
	cam = Camera3D.new()
	cam.near = 0.05
	cam.far = 400.0
	cam.fov = 75.0
	head.add_child(cam)
	cam.current = true
