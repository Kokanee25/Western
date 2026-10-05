extends SceneTree
## The probe mosaic trial in motion (src/render/probe_mosaic.gd): the saloon shot's set at night,
## the camera taken along fixed paths at a fixed step, every frame saved, so the screen mosaic, the
## probe mosaic and no mosaic can be compared frame by frame (tools/probe_walk.py measures the
## shimmer and makes the side-by-side video). Run it at a fixed step, so the probe's cross-fades
## and everyone's idles are the same in every run:
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 30 -s res://tools/probe_walk.gd -- \
##       --out=DIR [--paths=turn,walk,strafe,circle,approach] [--probe-mosaic[=texels]] [--probe-cell=m]
##       [--probe-bands=n] [--no-mosaic] [--quantise-once] [--blocks] [--size=1280x720] [--frames=1.0]
## (--blocks is Settings' own: the surface-blocks look.)
## --frames scales every path's frame count (0.5 = a quick look). Writes DIR/<path>_<nnn>.png and
## DIR/poses.json (each frame's camera, the probe's origin and how far its blocks have crossed).
## Untyped where it names the game's classes: -s scripts compile before the autoloads exist.

## Each path: [name, frames at 30 fps]. "still" holds the shot's view (flicker at rest, and the
## frame time); "face" holds a close three-quarter view of his face; the rest move.
const PATHS := [["still", 30], ["turn", 72], ["walk", 60], ["strafe", 54], ["circle", 66], ["approach", 45], ["face", 20]]

var out := "/tmp/probe_walk"
var only: PackedStringArray = ["still", "turn", "walk", "strafe", "circle", "approach"]
var size := Vector2i(1280, 720)
var frame_scale := 1.0
var hour := 23.67
## A warm light that only reaches people, by the table lamp (--face-key=energy): the painting's
## key on his face.
var face_key := 0.0
## --depth-pass: every frame each pixel's distance (probe_mosaic.gdshader debug 4) instead of the
## picture, for tools/probe_walk.py's reprojection (`stability`): the same paths, so one depth run
## serves every look's run.
var depth_pass := false


func _initialize() -> void:
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--paths="):
			only = a.substr(8).split(",", false)
		elif a.begins_with("--size="):
			size = Vector2i(int(a.substr(7).get_slice("x", 0)), int(a.substr(7).get_slice("x", 1)))
		elif a.begins_with("--frames="):
			frame_scale = float(a.substr(9))
		elif a.begins_with("--hour="):
			hour = float(a.substr(7))
		elif a.begins_with("--face-key="):
			face_key = float(a.substr(11))
		elif a == "--depth-pass":
			depth_pass = true
		elif a.begins_with("--probe-mosaic"):
			if a.begins_with("--probe-mosaic="):
				settings.probe_texels = float(a.substr(15))
			settings.set_probe_mosaic(true)
		elif a.begins_with("--probe-cell="):
			settings.probe_cell = float(a.substr(13))
		elif a.begins_with("--probe-bands="):
			settings.probe_bands = float(a.substr(14))
		elif a == "--no-mosaic":
			settings.set_mosaic(false)
		elif a == "--quantise-once":
			settings.set_quantise_once(true)
	settings.internal_resolution = size
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	(main.get_node(^"DebugOverlay") as CanvasLayer).visible = false
	var viewport: SubViewport = main.get_node(^"GameViewport")
	var street: Node3D = main.get_node(^"GameViewport/TestStreet")
	var clock = street.get_node(^"DayCycle")
	var player = street.get_node(^"Player")
	player.input_enabled = false
	clock.set_physics_process(false)
	clock.set_time(hour)
	var spawner = main.find_child("OutlawSpawn", true, false)
	if spawner.outlaw:
		spawner.outlaw.queue_free()
	var town = main.find_child("TownLife", true, false)
	if town:
		town.gang_arrives = 1e9
	var sm = load("res://src/art/shot_match.gd")
	sm.stage(street)
	if face_key > 0.0:
		add_face_key(street, face_key)
	player.set_physics_process(false)
	player.body.visible = false
	sm.hands_off_camera(player)
	for i in 30:
		await physics_frame
	sm.frame_camera(player, street)
	var cam: Camera3D = player.camera
	var rig: Transform3D = sm.rig(street)
	var eye: Vector3 = rig * sm.EYE
	var look: Vector3 = rig * sm.LOOK
	var head: Vector3 = (street.find_child("SeatedMan", true, false).parts[&"head"] as Node3D).global_position
	var table: Vector3 = rig.origin + Vector3.UP * eye.y
	var fwd := Vector3(look.x - eye.x, 0.0, look.z - eye.z).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	if depth_pass:
		# Nothing between the shader's bytes and the saved frame: no tone curve, glow or grading.
		var env: Environment = load("res://src/debug/look_preset.gd").environment(self)
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.tonemap_exposure = 1.0
		env.tonemap_white = 1.0
		env.glow_enabled = false
		env.adjustment_enabled = false
		var probe = load("res://src/render/probe_mosaic.gd").attach(cam, 384.0, 0.5, 0.0)
		(probe.material_override as ShaderMaterial).set_shader_parameter(&"debug", 4)
		var old := cam.get_node_or_null(^"DepthMosaic")
		if old:
			old.queue_free()
	# Settle the probe at the shot's eye before the first path.
	cam.global_transform = _looking(eye, look)
	for i in 20:
		await process_frame
	var poses := []
	for p in PATHS:
		if not p[0] in only:
			continue
		var n := maxi(int(p[1] * frame_scale), 2)
		var ms := 0.0
		for f in n:
			var t := float(f) / float(n - 1)
			var xf := _pose(p[0], t, eye, look, head, table, fwd, right)
			cam.global_transform = xf
			var t0 := Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			ms += (Time.get_ticks_usec() - t0) / 1000.0
			var img := viewport.get_texture().get_image()
			img.save_png("%s/%s_%03d.png" % [out, p[0], f])
			var probe = cam.get_node_or_null(^"ProbeMosaic")
			var b := xf.basis
			poses.append({"path": p[0], "frame": f, "camera": [xf.origin.x, xf.origin.y, xf.origin.z],
					"basis": [[b.x.x, b.x.y, b.x.z], [b.y.x, b.y.y, b.y.z], [b.z.x, b.z.y, b.z.z]],
					"fov": cam.fov, "size": [img.get_width(), img.get_height()],
					"origin": [probe.origin().x, probe.origin().y, probe.origin().z] if probe else null,
					"fade": probe.fading() if probe else null})
		print("%s: %d frames, %.0f ms a frame (wall clock, this machine)" % [p[0], n, ms / n])
	var fa := FileAccess.open("%s/poses.json" % out, FileAccess.WRITE)
	fa.store_string(JSON.stringify(poses, " "))
	fa.close()
	quit()


## Where the camera is at t (0-1) along a path.
func _pose(path: String, t: float, eye: Vector3, look: Vector3, head: Vector3, table: Vector3,
		fwd: Vector3, right: Vector3) -> Transform3D:
	var s := 0.5 - 0.5 * cos(PI * t)  # eased in and out
	match path:
		"turn":
			# Stand at the seat and look 25 degrees either way and back.
			var yaw := deg_to_rad(25.0) * sin(TAU * t)
			return _looking(eye, eye + (look - eye).rotated(Vector3.UP, yaw))
		"walk":
			# Walk up to the seat from 2 m back, looking at the man.
			return _looking(eye - fwd * 2.0 * (1.0 - s), look)
		"strafe":
			# Sidestep 1.8 m across the seat, facing the same way.
			var at := eye + right * lerpf(-0.9, 0.9, s)
			return _looking(at, at + (look - eye))
		"circle":
			# Round the table at the seat's distance, 60 degrees, looking at him.
			var offset := Vector3(eye.x - table.x, 0.0, eye.z - table.z).rotated(Vector3.UP, deg_to_rad(-60.0) * s)
			return _looking(Vector3(table.x, eye.y, table.z) + offset, head)
		"approach":
			# Lean in from the seat to 0.55 m from his face.
			var to := head + (eye - head).normalized() * 0.55
			return _looking(eye.lerp(to, s), head)
		"face":
			# His face from 0.8 m, 40 degrees round to his left of square to the seat, at eye level.
			var side := Vector3(eye.x - head.x, 0.0, eye.z - head.z).normalized().rotated(Vector3.UP, deg_to_rad(-40.0))
			return _looking(head + side * 0.8 + Vector3.UP * 0.02, head + Vector3.DOWN * 0.03)
	return _looking(eye, look)


## A warm light by the table lamp that only reaches people (Layers.VIS_BODY), at the height of his
## face: the painting lights his face from the lamp's side, and our lamp on the table lights it from
## below. A trial (--face-key=energy); not in the game.
static func add_face_key(street: Node3D, energy: float) -> OmniLight3D:
	var lamp := street.find_child("TableLamp", true, false) as Node3D
	var key := OmniLight3D.new()
	key.name = "FaceKey"
	key.light_color = Color(1.0, 0.74, 0.48)
	key.light_energy = energy
	key.omni_range = 3.0
	key.omni_attenuation = 1.0
	key.light_cull_mask = 2  # Layers.VIS_BODY: people only
	key.light_volumetric_fog_energy = 0.0
	key.shadow_enabled = true
	key.shadow_bias = 0.03
	lamp.get_parent().add_child(key)
	key.global_position = lamp.global_position + Vector3.UP * 0.5
	return key


func _looking(from: Vector3, at: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(at - from, Vector3.UP), from)
