extends SceneTree
## The Winchester 1873 (#734 step 1) in the game under the real look: the street at an hour, the gun
## held in the air over the road with a camera of the lab's own; a turntable, the straight sides (with
## where the bore's points land, for overlay.py --plain), three-quarters, each side turned to the sun,
## close shots and the mechanism driven through its parts (win73_rig.gd). Nothing in the game changes.
## The Colt's saa_views.gd is the pattern.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver vulkan --resolution 1600x900 \
##       -s res://experiments/gun_lab/win73/win73_views.gd -- --real --out=build/win73/views [--gun=24] [--hour=16] \
##       [--only=turntable,side,threeq,sunlit,close,mech,fp] [--steps=24]
##
## Untyped on purpose (a -s script compiles before the autoloads exist).

const SETTLE := 14  # frames held at each pose: FSR2 builds its picture over several frames

var out := "build/win73/views"
var viewport: SubViewport
var cam: Camera3D
var gun: Node3D
var rig


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "24"
	var hour := 16.0
	var only := "turntable,side,threeq,sunlit,close,mech,fp"
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
	gun = (load("res://experiments/gun_lab/win73/win73_%s.glb" % tag) as PackedScene).instantiate()
	street.add_child(gun)
	gun.global_position = base
	rig = load("res://experiments/gun_lab/win73/win73_rig.gd").new(gun, "res://experiments/gun_lab/win73/win73_%s_rig.json" % tag)
	# Every room's probe drawn (screenshots.gd's wait), then the look settled.
	for _i in 7 * root.find_children("*", "ReflectionProbe", true, false).size() + 30:
		await process_frame
	var aabb := _bounds(gun)
	var centre := aabb.get_center()
	print("gun bounds (m): ", aabb.size, " centre ", centre - base)

	if "turntable" in only:
		# The gun turns about the vertical through its middle; the camera stays, a little above.
		_look(centre + Vector3(0.0, 0.40, 1.30), centre)
		var offset := Transform3D(Basis.IDENTITY, base - centre)
		for i in steps:
			gun.global_transform = Transform3D(Basis(Vector3.UP, TAU * i / steps), centre) * offset
			await _shot("turntable_%02d" % i)
		gun.global_transform = Transform3D(Basis.IDENTITY, base)
	if "side" in only:
		# Straight side views from far off with a narrow lens (near orthographic), for setting beside
		# the photo (overlay.py --plain; the exact overlay is from Blender's side render).
		var g := gun.global_transform
		var mid: Vector3 = g * (aabb.get_center() - base)
		cam.fov = 7.0
		for side in [["side_left", -1.0], ["side_right", 1.0]]:
			_look(mid + g.basis.x * 6.0 * side[1], mid)
			await _shot(side[0])
			var pts := {}
			for n in ["Muzzle", "ReceiverFront"]:
				var px := cam.unproject_position(g * _marker(n))
				pts[n] = [px.x * viewport.size.x / viewport.get_visible_rect().size.x, px.y * viewport.size.y / viewport.get_visible_rect().size.y]
			var f := FileAccess.open("%s/%s.json" % [out, side[0]], FileAccess.WRITE)
			f.store_string(JSON.stringify(pts))
		cam.fov = 32.0
	if "threeq" in only:
		# Three-quarter views of the action: from behind on the left (the shooter's view of it) and from
		# in front on the right (the loading side).
		var g := gun.global_transform
		var act: Vector3 = g * _marker("Port") + g.basis * Vector3(0.0, -0.03, 0.0)
		_look(act + g.basis * Vector3(-0.30, 0.17, 0.32), act)
		await _shot("threeq_rear_left")
		_look(act + g.basis * Vector3(0.36, 0.14, -0.30), act)
		await _shot("threeq_front_right")
		# and the whole gun, three-quarter from in front on the right
		_look(centre + g.basis * Vector3(0.75, 0.32, -0.75), centre)
		await _shot("threeq_whole")
	if "sunlit" in only:
		# Each side of the gun turned to face the sun, the camera on the sun's side (wood in shade reads
		# dark; turned to the sun it shows its grain: the Colt's question).
		var sun: Vector3 = clock.get_sun_direction()
		var sh := Vector3(sun.x, 0.0, sun.z).normalized()
		for side in [["sunlit_left", -1.0], ["sunlit_right", 1.0]]:
			var want: Vector3 = sh * side[1]
			var yaw := atan2(-want.z, want.x)
			gun.global_transform = Transform3D(Basis(Vector3.UP, yaw), centre) * Transform3D(Basis.IDENTITY, base - centre)
			_look(centre + sh * 1.45 + Vector3(0, 0.22, 0), centre)
			await _shot(side[0])
		gun.global_transform = Transform3D(Basis.IDENTITY, base)
	if "fp" in only:
		await _first_person(clock)
	if "close" in only:
		# The gun's own frame: barrel along -Z, right +X, up +Y.
		var g := gun.global_transform
		var act: Vector3 = g * _marker("Port")
		_look(act + g.basis * Vector3(0.36, 0.02, 0.0), act + g.basis * Vector3(0.0, -0.035, 0.0))
		await _shot("close_right")
		_look(act + g.basis * Vector3(-0.36, 0.02, 0.0), act + g.basis * Vector3(0.0, -0.035, 0.0))
		await _shot("close_left")
		var muz: Vector3 = g * _marker("Muzzle")
		_look(muz + g.basis * Vector3(0.12, 0.07, -0.22), muz + g.basis * Vector3(0.0, -0.01, 0.06))
		await _shot("close_muzzle")
		_look(act + g.basis * Vector3(-0.07, 0.17, 0.20), act + g.basis * Vector3(0.0, 0.0, 0.03))
		await _shot("close_hammer_top")
		# Loading: a round's nose pressing the gate in (the tube's first round shown as the one going in).
		rig.gate(1.0)
		var gp: Vector3 = g * _marker("GatePoint")
		_look(gp + g.basis * Vector3(0.20, 0.03, 0.06), gp)
		await _shot("close_loading")
		rig.gate(0.0)
		# The lever thrown: the bolt back, the carrier up with a round, the hammer cocked, the cover back.
		rig.cover(1.0)
		rig.carrier_round("loaded")
		rig.lever(1.0)
		_look(act + g.basis * Vector3(0.24, 0.20, 0.10), act + g.basis * Vector3(0.0, -0.02, 0.0))
		await _shot("close_open")
		rig.lever(0.0, true)
		rig.carrier_round("empty")
		rig.chamber("loaded")
		rig.cover(0.0)
		# Down the sights at full cock: the front blade's top in the buckhorn's notch.
		var rear: Vector3 = g * _marker("SightRear")
		var front: Vector3 = g * _marker("SightFront")
		var los := (front - rear).normalized()
		cam.fov = 40.0
		_look(rear - los * 0.28 + Vector3(0, 0.004, 0), rear + los * 30.0)
		await _shot("fp_sights")
		cam.fov = 32.0
		rig.hammer("rest")
		rig.chamber("empty")
	if "mech" in only:
		# The action driven by the rig, from the right: rest, half cock, the lever's throw (bolt back,
		# hammer cocking, the carrier lifting a round), closing (the round chambered, the carrier
		# dropping), cocked, fired, the cover back, the gate pressed.
		var g := gun.global_transform
		var act: Vector3 = g * _marker("Port")
		# wide enough for the lever's open loop and the bolt out over the wrist
		_look(act + g.basis * Vector3(0.60, 0.0, 0.03), act + g.basis * Vector3(0.0, -0.075, 0.035))
		var frames := [["rest"], ["half"], ["open_035", 0.35], ["open_070", 0.70], ["open_100", 1.0], ["close_050", 0.5],
				["closed_cocked", 0.0], ["fired"], ["cover_open"], ["gate_in"]]
		for i in frames.size():
			var f: Array = frames[i]
			var n: String = f[0]
			if n == "rest":
				rig.hammer("rest")
			elif n == "half":
				rig.hammer("half")
			elif n.begins_with("open"):
				rig.hammer("rest")
				rig.carrier_round("loaded")
				rig.chamber("spent")
				rig.lever(f[1])
			elif n.begins_with("close"):
				# Closing, the bolt carries the round off the carrier into the chamber (shown already
				# there: the lab has no round in between).
				rig.chamber("loaded")
				rig.carrier_round("empty")
				rig.lever(f[1], true)
			elif n == "fired":
				rig.fire()
			elif n == "cover_open":
				rig.cover(1.0)
			elif n == "gate_in":
				rig.cover(0.0)
				rig.gate(1.0)
			await _shot("mech_%d_%s" % [i, n])
		rig.gate(0.0)
	print("Win73 views done -> ", out)
	quit()


## First person, in the hands (Sean on #767: judge the surfaces in game light and in first person in
## the hands, as the Colt is). The rifle hangs under the lab's camera at the game's field of view (the
## player's 75 degrees, 62 aiming, as the coach gun), held by two of the game's own HeldHands (the
## painted Studio arms the coach gun is held in, used here, not changed): the right round the wrist
## with its fingers through the lever's loop and the index on the trigger, the left under the forend.
## Shouldered (down the sights), at the low ready, and turned to look at the action; each with the sun
## behind you and with it to your right.
func _first_person(clock) -> void:
	var sun: Vector3 = clock.get_sun_direction()
	var sh := Vector3(sun.x, 0.0, sun.z).normalized()
	var eye := cam.global_position
	var street_eye := Vector3(gun.global_position.x, TownLayout.ground_height(gun.global_position.x) + 1.62, gun.global_position.z)
	var held := Node3D.new()
	cam.add_child(held)
	var keep := gun.global_transform
	gun.get_parent().remove_child(gun)
	held.add_child(gun)
	gun.transform = Transform3D.IDENTITY  # the gun's own space is the held node's (it kept its street place)
	var r = _hand(true, gun, _d(-5.0, -1.95, 0.72), Vector3(0.12, -0.75, 0.65), Vector3(-1.0, 0.15, 0.0), Vector3(0.45, -0.55, 0.70))
	for f in {"middle": 72.0, "ring": 66.0, "little": 60.0}:
		r.grasp(f, {"middle": 72.0, "ring": 66.0, "little": 60.0}[f])
	r.grasp("index", 12.0, 28.0)
	r.shoulder = Vector3(0.19, -0.2, 0.07)
	r.elbow_pole = Vector3(0.5, -1.0, 0.2)
	var l = _hand(false, gun, _d(8.2, -1.50, 0.0), Vector3(-0.7, -0.35, 0.6), Vector3(0.3, 1.0, 0.0), Vector3(-0.7, -0.5, 0.6))
	for f in {"index": 12.0, "middle": 50.0, "ring": 56.0, "little": 64.0}:
		l.grasp(f, {"index": 12.0, "middle": 50.0, "ring": 56.0, "little": 64.0}[f])
	l.shoulder = Vector3(-0.19, -0.2, 0.07)
	l.elbow_pole = Vector3(-0.5, -1.0, 0.2)
	rig.hammer("full")
	var rear := _marker("SightRear")
	var front := _marker("SightFront")
	for heading in [["sunbehind", -sh], ["sunright", sh.cross(Vector3.UP)]]:
		cam.global_position = street_eye
		cam.look_at(street_eye + heading[1], Vector3.UP)
		# Shouldered: the rear notch 30 cm before the eye on the sight line, the front blade in it.
		cam.fov = 62.0
		var los := (front - rear).normalized()
		var b := Basis.looking_at(los, Vector3.UP).inverse()
		held.transform = Transform3D(b, -(b * rear) + Vector3(0.0, 0.0, -0.30))
		await _shot("fp_aim_%s" % heading[0])
		# The low ready: the wrist at the right hip's height out front, the muzzle down and in.
		cam.fov = 75.0
		var bl := Basis.from_euler(Vector3(deg_to_rad(-9.0), deg_to_rad(11.0), deg_to_rad(-6.0)))
		held.transform = Transform3D(bl, Vector3(0.20, -0.30, -0.30) - bl * _d(-4.6, -1.8, 0.0))
		await _shot("fp_ready_%s" % heading[0])
		# Looking at the action: brought up and turned so its right side (the gate) faces you.
		var bi := Basis.from_euler(Vector3(deg_to_rad(8.0), deg_to_rad(62.0), deg_to_rad(10.0)))
		held.transform = Transform3D(bi, Vector3(0.02, -0.12, -0.36) - bi * _d(-1.2, -0.9, 0.0))
		await _shot("fp_action_%s" % heading[0])
	rig.hammer("rest")
	cam.fov = 32.0
	r.queue_free()
	l.queue_free()
	held.remove_child(gun)
	cam.get_parent().add_child(gun)
	gun.global_transform = keep
	held.queue_free()
	cam.global_position = eye


## A design point (f along the bore from the breech, u up from the bore, l to the right; inches) in the
## gun's own space (win73_blender.py: the origin under the trigger at f -4.4, u -2.1).
func _d(f: float, u: float, l: float) -> Vector3:
	return Vector3(l, u + 2.1, -(f + 4.4)) * 0.0254


## A HeldHand at `pos` in `parent`'s space laid along `wrist_dir` (knuckles back towards its wrist),
## its palm towards `palm_dir`, its forearm aimed `forearm` (the coach gun's way of placing one).
func _hand(is_right: bool, parent: Node3D, pos: Vector3, wrist_dir: Vector3, palm_dir: Vector3, forearm: Vector3):
	var h = load("res://src/weapons/held_hand.gd").new(is_right)
	h.position = pos
	var z := wrist_dir.normalized()
	var x := (palm_dir - z * palm_dir.dot(z)).normalized() * (-1.0 if is_right else 1.0)
	h.basis = Basis(x, z.cross(x), z)
	parent.add_child(h)
	h.build()
	h.aim_forearm(forearm)
	return h


func _marker(n: String) -> Vector3:
	var m: Dictionary = rig.rig["markers"]
	var p: Array = m[n]
	# Markers are in the gun root's (Win73's) space; the scene root adds nothing.
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
