extends SceneTree
## The viewmodel rig lab's views (#896): each gun's poses (poses/<gun>.json) from the player's eye,
## held by the first-person rig (fp_arms.gd: the MetaHuman's hands, modelled sleeves) or, for the
## side-by-side, by today's HeldHand at the same places. Nothing in the game changes.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan --resolution 1280x720 \
##       -s res://experiments/viewmodel_rig/views.gd -- --out=build/vmr/plain [--stage=plain|street|lamp] \
##       [--hands=fp|held] [--only=saa:idle,saa:aim,...] [--extra] [--kick]
##
## --stage=plain: a floor, a sky and the sun, no town: seconds a pose, for posing by eye.
## --stage=street: Main Street at 16:00 under the real look (the gun lab's place); --stage=lamp: the
## same street at 21:30 by the oil lamp nearest the store's porch, the camera turned to it.
## --extra adds, per pose, a close look at the right hand (the wrist and fingers) from its side.
## --kick adds a recoil strip for the aim poses (GunKick, 0/40/80/160 ms after the shot).
## Writes OUT/<gun>_<pose>.png (and _close, _kick_<ms>). Untyped where it touches game classes.

const SETTLE_PLAIN := 3
const SETTLE_REAL := 14   # frames held for FSR2 to settle (the gun lab's)

var out := "build/vmr/plain"
var stage := "plain"
var hands := "fp"
var only := ""
var extra := false
var do_kick := false
var hour := 16.0
var cam: Camera3D
var world: Node3D
var viewport: Viewport
var settle := SETTLE_PLAIN


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--stage="):
			stage = a.substr(8)
		elif a.begins_with("--hands="):
			hands = a.substr(8)
		elif a.begins_with("--only="):
			only = a.substr(7)
		elif a == "--extra":
			extra = true
		elif a == "--kick":
			do_kick = true
		elif a.begins_with("--hour="):
			hour = float(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out)
	if stage == "plain":
		_plain()
	else:
		await _street()
	var base_out := out
	var lights := ["day"] if stage != "real" else ["day", "lamp"]
	for light in lights:
		if stage == "real":
			await _light(light)
		for kind in (["fp", "held"] if hands == "both" else [hands]):
			out = base_out if stage != "real" and hands != "both" else "%s/%s_%s" % [base_out, light, kind]
			DirAccess.make_dir_recursive_absolute(out)
			await _render_set(kind)
	print("vmr views done -> ", base_out)
	quit()


func _render_set(kind: String) -> void:
	var arms = null
	if kind == "fp":
		arms = load("res://experiments/viewmodel_rig/fp_arms.gd").new()
		world.add_child(arms)
		if not arms.ok:
			push_error("no fp arms: run tools/blender/fp_arms.py first")
			quit(1)
			return
	# VMR_GUNS=a,b: other pose files (poses/<a>.json), for trying variants
	for gun in OS.get_environment("VMR_GUNS").split(",") if OS.get_environment("VMR_GUNS") != "" else ["saa", "win73"]:
		var rig = load("res://experiments/viewmodel_rig/fp_rig.gd").new("res://experiments/viewmodel_rig/poses/%s.json" % gun, cam, arms)
		for p in rig.poses():
			if only != "" and not ("%s:%s" % [gun, p]) in only.split(","):
				continue
			rig.set_pose(p)
			await _shot("%s_%s" % [gun, p])
			if extra:
				await _close(rig, arms, gun, p)
			if do_kick and p == "aim":
				rig.fire()
				var t := 0.0
				for ms in [40, 80, 160]:
					rig.step(ms / 1000.0 - t)
					t = ms / 1000.0
					await _shot("%s_%s_kick_%03d" % [gun, p, ms])
				rig.step(1.0)
		rig.held.queue_free()
		for s in rig.held_hands:
			rig.held_hands[s].queue_free()
		if arms:
			for s in ["r", "l"]:
				arms.reset(s)
			arms.apply()
	if arms:
		arms.queue_free()
	await process_frame


## A close look at the hand(s) on the gun: from the right of the gun, a little ahead and above, at
## the right wrist (the left's for a pose without a right hand), a narrow lens.
func _close(rig, arms, gun: String, p: String) -> void:
	var keep := cam.global_transform
	var fov := cam.fov
	var held_keep: Transform3D = rig.held.global_transform
	# The held gun stays where it is in the world; the camera moves (the hands are in world space).
	var pd: Dictionary = rig.data["poses"][p]
	var s := "r" if pd.get("r") != null else "l"
	if OS.get_cmdline_user_args().has("--close-left") and pd.get("l") != null:
		s = "l"
	var h = rig.hand_data(pd, s)
	var space: Node3D = rig.gun
	if h.has("in"):
		space = rig.gun.find_child(h["in"], true, false)
	var at: Vector3 = space.global_transform * rig._v(h["at"])
	var along: Vector3 = (space.global_transform.basis * rig._v(h["along"])).normalized()
	var g: Transform3D = rig.gun.global_transform
	var right: Vector3 = g.basis.x.normalized() * (1.0 if s == "r" else -1.0)
	var target := at + along * 0.03
	rig.held.top_level = true
	rig.held.global_transform = held_keep
	cam.fov = 38.0
	cam.global_position = target + right * 0.30 + g.basis.y.normalized() * 0.08 - g.basis.z.normalized() * 0.10
	cam.look_at(target, g.basis.y.normalized())
	await _shot("%s_%s_close" % [gun, p])
	if OS.get_cmdline_user_args().has("--far-side"):
		# and from the gun's other side: the fingers wrapped round it
		cam.global_position = target - right * 0.30 + g.basis.y.normalized() * 0.04 - g.basis.z.normalized() * 0.06
		cam.look_at(target, g.basis.y.normalized())
		await _shot("%s_%s_far" % [gun, p])
	cam.global_transform = keep
	cam.fov = fov
	rig.held.top_level = false
	rig.held.transform = rig._held_base


func _shot(n: String) -> void:
	for _i in settle:
		await process_frame
	viewport.get_texture().get_image().save_png("%s/%s.png" % [out, n])
	print("saved ", n)


## A floor, a sky and the late-afternoon sun from behind the right shoulder.
func _plain() -> void:
	world = Node3D.new()
	root.add_child(world)
	viewport = root
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.52, 0.75)
	sm.sky_horizon_color = Color(0.78, 0.74, 0.66)
	sm.ground_horizon_color = Color(0.55, 0.47, 0.38)
	sm.ground_bottom_color = Color(0.32, 0.27, 0.22)
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 2.2
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-32.0, 150.0, 0.0)
	world.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.52, 0.43, 0.33)
	fm.roughness = 1.0
	pm.material = fm
	floor_mi.mesh = pm
	world.add_child(floor_mi)
	# a post and a wall ahead for scale and a backdrop
	var wall := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(8, 3, 0.2)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.45, 0.36, 0.27)
	bm.material = wm
	wall.mesh = bm
	wall.position = Vector3(0, 1.5, -7)
	world.add_child(wall)
	cam = Camera3D.new()
	cam.near = 0.01
	cam.fov = 75.0
	world.add_child(cam)
	cam.position = Vector3(0, 1.62, 0)
	cam.current = true


## Main Street under the real look (as the gun lab's win73_views.gd), by day or by a lamp at night.
func _street() -> void:
	settle = SETTLE_REAL
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	print("real look: ", settings.real_look)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	viewport = main.get_node(^"GameViewport")
	world = main.get_node(^"GameViewport/TestStreet")
	_clock = world.get_node(^"DayCycle")
	_clock.set_time(hour if stage != "lamp" else 21.5)
	_clock.set_physics_process(false)
	var town_life = main.find_child("TownLife", true, false)
	if town_life:
		town_life.gang_arrives = 1e9
	var player = world.get_node(^"Player")
	player.input_enabled = false
	player.visible = false
	for c in player.camera.get_children():
		if c is Node3D:
			c.visible = false
	cam = Camera3D.new()
	cam.near = 0.01
	world.add_child(cam)
	cam.current = true
	if stage == "real":
		return
	await _light(stage if stage == "lamp" else "day")


var _clock


## The camera's place and the hour: by day over the road east of the store with the sun behind you;
## by night (21:30) an arm's length from the lit oil lamp nearest there.
func _light(which: String) -> void:
	var clock = _clock
	clock.set_time(16.0 if which == "day" else 21.5)
	var player = world.get_node(^"Player")
	# By day: over the road east of the store, the sun behind (the gun lab's place). By night: an
	# arm's length from the lit lamp nearest that place, looking past it down the street.
	var base := Vector3(13.0, 0.0, -8.4)
	var eye := Vector3(base.x, TownLayout.ground_height(base.x) + 1.62, base.z)
	var sun: Vector3 = clock.get_sun_direction()
	var look := eye - Vector3(sun.x, 0.0, sun.z).normalized()   # the sun behind you (the gun lab's)
	if which == "lamp":
		for _i in 20:
			await process_frame
		for l in root.find_children("*", "Node3D", true, false):
			if l.has_method("should_be_lit") and l.has_method("set_lit"):
				l.set_lit(l.should_be_lit(21))
		var best = null
		var bd := 1e9
		for l in root.find_children("*", "Node3D", true, false):
			if l.has_method("light_position") and l.has_method("shines") and l.shines():
				var d: float = l.light_position().distance_to(base)
				if d < bd:
					bd = d
					best = l
		if best:
			var lp: Vector3 = best.light_position()
			var flat := Vector3(lp.x - base.x, 0.0, lp.z - base.z).normalized()
			eye = Vector3(lp.x, TownLayout.ground_height(lp.x) + 1.62, lp.z) - flat * 1.4
			# the lamp a little ahead and to the left, so it lights the hands from the front left
			look = eye + flat.rotated(Vector3.UP, deg_to_rad(-35.0))
			print("lamp at ", lp, " eye ", eye)
	player.global_position = eye + Vector3(6, -1.6, 30)
	cam.global_position = eye
	cam.look_at(Vector3(look.x, eye.y - 0.05, look.z), Vector3.UP)
	for _i in 7 * root.find_children("*", "ReflectionProbe", true, false).size() + 30:
		await process_frame
