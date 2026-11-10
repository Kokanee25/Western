extends SceneTree
## The SAA (#693 step 1) in the game under the real look: the street at an hour, the gun held in the
## air over the road with a camera of the lab's own; a turntable, close shots and the mechanism
## driven through its parts (saa_rig.gd). Nothing in the game changes.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver vulkan --resolution 1600x900 \
##       -s res://experiments/gun_lab/saa/saa_views.gd -- --real --out=build/saa/views [--gun=75] [--hour=16] \
##       [--only=turntable,side,threeq,sunlit,close,mech] [--steps=24]
##
## Untyped on purpose (a -s script compiles before the autoloads exist).

const SETTLE := 14  # frames held at each pose: FSR2 builds its picture over several frames

var out := "build/saa/views"
var viewport: SubViewport
var cam: Camera3D
var gun: Node3D
var rig


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "75"
	var hour := 16.0
	var only := "turntable,side,threeq,sunlit,close,mech"
	var steps := 24
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--gun="):
			tag = a.substr(6)
		elif a.begins_with("--hour="):
			hour = float(a.substr(7))
		elif a.begins_with("--only="):
			only = a.substr(7)
		elif a.begins_with("--steps="):
			steps = int(a.substr(8))
	DirAccess.make_dir_recursive_absolute(out)
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	print("real look: ", settings.real_look)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	viewport = main.get_node(^"GameViewport")
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var clock = street.get_node(^"DayCycle")
	clock.set_time(hour)
	clock.set_physics_process(false)
	var town_life = main.find_child("TownLife", true, false)
	if town_life:
		town_life.gang_arrives = 1e9
	var player = street.get_node(^"Player")
	player.input_enabled = false
	for c in player.camera.get_children():
		if c is Node3D:
			c.visible = false
	# The place: over the road east of the store, the sun behind the camera at 16:00 (the gun lab's).
	var base := Vector3(13.0, 1.35, -8.4)
	base.y += TownLayout.ground_height(base.x)
	player.global_position = Vector3(base.x + 6.0, TownLayout.ground_height(base.x + 6.0), base.z + 30.0)
	player.visible = false
	cam = Camera3D.new()
	cam.near = 0.01
	cam.fov = 32.0
	street.add_child(cam)
	cam.current = true
	gun = (load("res://experiments/gun_lab/saa/saa_%s.glb" % tag) as PackedScene).instantiate()
	street.add_child(gun)
	gun.global_position = base
	rig = load("res://experiments/gun_lab/saa/saa_rig.gd").new(gun, "res://experiments/gun_lab/saa/saa_%s_rig.json" % tag)
	# Every room's probe drawn (screenshots.gd's wait), then the look settled.
	for _i in 7 * root.find_children("*", "ReflectionProbe", true, false).size() + 30:
		await process_frame
	var aabb := _bounds(gun)
	var centre := aabb.get_center()
	print("gun bounds (m): ", aabb.size, " centre ", centre - base)

	if "turntable" in only:
		# The gun turns about the vertical through its middle; the camera stays, a little above.
		_look(centre + Vector3(0.0, 0.17, 0.50), centre)
		var offset := Transform3D(Basis.IDENTITY, base - centre)
		for i in steps:
			gun.global_transform = Transform3D(Basis(Vector3.UP, TAU * i / steps), centre) * offset
			await _shot("turntable_%02d" % i)
		gun.global_transform = Transform3D(Basis.IDENTITY, base)
	if "side" in only:
		# Straight side views from far off with a narrow lens (near orthographic), for setting beside
		# the Met gun's photo (overlay.py does the exact overlay from Blender's side render).
		var g := gun.global_transform
		var mid: Vector3 = g * Vector3(0.0, 0.0, -0.09)
		cam.fov = 7.0
		for side in [["side_left", -1.0], ["side_right", 1.0]]:
			_look(mid + g.basis.x * 2.6 * side[1], mid)
			await _shot(side[0])
			# Where the bore's two points land in the frame (overlay.py --plain lays it on the photo).
			var pts := {}
			for n in ["Muzzle", "BoreBreech"]:
				var px := cam.unproject_position(g * _marker(n))
				pts[n] = [px.x * viewport.size.x / viewport.get_visible_rect().size.x, px.y * viewport.size.y / viewport.get_visible_rect().size.y]
			var f := FileAccess.open("%s/%s.json" % [out, side[0]], FileAccess.WRITE)
			f.store_string(JSON.stringify(pts))
		cam.fov = 32.0
	if "threeq" in only:
		# Three-quarter views: from behind on the left (as the Smithsonian's photos of the Colt are taken)
		# and from in front on the right.
		var g := gun.global_transform
		_look(g * Vector3(-0.27, 0.13, 0.20), g * Vector3(0.0, 0.02, -0.03))
		await _shot("threeq_rear_left")
		_look(g * Vector3(0.27, 0.12, -0.30), g * Vector3(0.0, 0.02, -0.07))
		await _shot("threeq_front_right")
	if "sunlit" in only:
		# Each side of the gun turned to face the sun (Sean's question: is the dark grip panel in the
		# other views walnut in shadow, or black?), the camera on the sun's side.
		var sun: Vector3 = clock.get_sun_direction()
		var sh := Vector3(sun.x, 0.0, sun.z).normalized()
		for side in [["sunlit_left", -1.0], ["sunlit_right", 1.0]]:
			# The gun's local X turned so its chosen side (-X left, +X right) faces the sun.
			var want: Vector3 = sh * side[1]
			var yaw := atan2(-want.z, want.x)
			gun.global_transform = Transform3D(Basis(Vector3.UP, yaw), centre) * Transform3D(Basis.IDENTITY, base - centre)
			_look(centre + sh * 0.62 + Vector3(0, 0.12, 0), centre)
			await _shot(side[0])
		gun.global_transform = Transform3D(Basis.IDENTITY, base)
	if "close" in only:
		# The gun's own frame: barrel along -Z, right +X, up +Y.
		var g := gun.global_transform
		var cyl: Vector3 = g * Vector3(0.0, 0.026, -0.02)
		_look(g * Vector3(0.30, 0.07, -0.03), cyl + g.basis * Vector3(0, -0.012, 0.02))
		await _shot("close_right")
		_look(g * Vector3(-0.30, 0.06, -0.03), g * Vector3(0.0, 0.014, 0.0))
		await _shot("close_left")
		_look(g * Vector3(0.12, 0.08, -0.46), g * Vector3(0.0, 0.03, -0.17))
		await _shot("close_muzzle")
		_look(g * Vector3(-0.08, 0.14, 0.22), g * Vector3(0.0, 0.02, -0.05))
		await _shot("close_hammer_top")
		# Loading: half cock, the gate open, a spent case pushed out by the ejector.
		rig.hammer("half")
		rig.gate(1.0)
		rig.to_gate(2)
		rig.chamber(2, "spent")
		rig.ejector(0.75)
		_look(g * Vector3(0.21, 0.035, 0.10), g * Vector3(0.012, 0.03, -0.02))
		await _shot("close_loading")
		rig.ejector(0.0)
		rig.gate(0.0)
		rig.chamber(2, "loaded")
		rig.cylinder(0.0)
		# Full cock from behind and the shooter's left; then down the sights.
		rig.hammer("full")
		rig.cylinder(1.0)
		_look(g * Vector3(-0.12, 0.09, 0.20), g * Vector3(0.0, 0.03, -0.02))
		await _shot("close_cocked")
		var rear: Vector3 = g * _marker("SightRear")
		var front: Vector3 = g * _marker("SightFront")
		var los := (front - rear).normalized()
		cam.fov = 40.0
		_look(rear - los * 0.30 + Vector3(0, 0.004, 0), rear + los * 30.0)
		await _shot("fp_sights")
		cam.fov = 32.0
		rig.hammer("rest")
		rig.cylinder(0.0)
	if "mech" in only:
		# The lockwork driven by the rig: rest, safety, half, full (the cylinder turning as the hammer
		# comes from half to full), the trigger pulled, the gate opened, the ejector run.
		var g := gun.global_transform
		_look(g * Vector3(0.30, 0.05, 0.03), g * Vector3(0.0, 0.025, 0.0))
		var frames := [["rest", 0.0, 0.0, 0.0, 0.0], ["safety", 0.0, 0.0, 0.0, 0.0], ["half", 0.0, 0.0, 0.0, 0.0],
				["half", 0.5, 0.0, 0.0, 0.0], ["full", 1.0, 0.0, 0.0, 0.0], ["fired", 1.0, 1.0, 0.0, 0.0],
				["gate", 1.0, 0.0, 1.0, 0.0], ["eject", 1.0, 0.0, 1.0, 1.0]]
		for i in frames.size():
			var f: Array = frames[i]
			match f[0]:
				"fired":
					rig.hammer("rest")
					rig.trigger(1.0)
				"gate", "eject":
					rig.hammer("half")
					rig.to_gate(0)
					rig.gate(f[3])
					rig.ejector(f[4])
					rig.chamber(0, "spent")
				_:
					var notch: String = f[0]
					if f[1] > 0.0 and f[1] < 1.0:
						var h: float = rig.rig["moving"]["Hammer"]["notches_deg"]["half"]
						var full: float = rig.rig["moving"]["Hammer"]["notches_deg"]["full"]
						rig.hammer(lerpf(h, full, f[1]))
					else:
						rig.hammer(notch)
					rig.cylinder(f[1])
			await _shot("mech_%d_%s" % [i, f[0]])
	print("SAA views done -> ", out)
	quit()


func _marker(n: String) -> Vector3:
	var m: Dictionary = rig.rig["markers"]
	var p: Array = m[n]
	# Markers are in the gun root's (ColtSAA's) space; the scene root adds nothing.
	return Vector3(p[0], p[1], p[2])


func _look(from: Vector3, at: Vector3) -> void:
	cam.global_position = from
	cam.look_at(at, Vector3.UP)


func _shot(n: String) -> void:
	for _i in SETTLE:
		await process_frame
	viewport.get_texture().get_image().save_png("%s/%s.png" % [out, n])
	print("saved ", n)


func _bounds(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
