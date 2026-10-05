extends SceneTree
## The camera tour (docs/briefs/review-tools.md item "tour video"): a fixed, smooth 30-second path
## through the town, so every build has a video Sean can watch on his phone. Down the street at
## golden hour, past the store, up to the saloon and in, the card table, the bar while night
## falls, and out into the street at night. Run under Movie Maker so every frame is written:
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan \
##       --resolution 1280x720 --fixed-fps 30 --write-movie build/tour/frame.png \
##       -s res://tools/tour.gd -- [--render=960x540] [--light]
##   ffmpeg -framerate 30 -i build/tour/frame%08d.png -c:v libx264 -pix_fmt yuv420p -crf 23 tour.mp4
##
## --render=WxH renders the 3D at that size (scaled up to the window, as F2 does; default the
## window's own size). --light turns off the volumetric haze and SSAO to render faster (CI).
## --look=FILE applies a look preset first, as the game does. --frames=N stops after N frames and
## --start=S begins S seconds in (previews).

const SECONDS := 30.0
## The path: [time s, eye position, looking at, hour]. Catmull-Rom through the points, the hour
## eased between them.
const PATH := [
	[0.0, Vector3(30.0, 1.7, -9.5), Vector3(-20.0, 2.5, -9.0), 17.6],
	[5.0, Vector3(16.0, 1.7, -8.0), Vector3(-20.0, 2.0, -10.0), 17.62],
	[9.0, Vector3(7.5, 1.7, -5.5), Vector3(2.0, 2.0, 0.5), 17.65],
	[12.5, Vector3(7.5, 1.7, -12.5), Vector3(7.0, 2.0, -18.0), 17.68],
	[15.5, Vector3(7.0, 1.65, -18.6), Vector3(8.0, 1.3, -24.0), 17.7],
	[19.0, Vector3(10.6, 1.5, -22.3), Vector3(9.4, 0.9, -21.0), 19.0],
	[23.0, Vector3(6.6, 1.6, -21.0), Vector3(3.0, 1.4, -23.5), 23.2],
	[26.5, Vector3(7.0, 1.7, -18.2), Vector3(7.0, 1.6, -10.0), 23.4],
	[30.0, Vector3(5.0, 1.8, -10.5), Vector3(-20.0, 2.5, -9.0), 23.5],
]

## Frames a second of the video (run with --fixed-fps 30 so each frame is this much game time).
const FPS := 30.0

var _camera: Camera3D
var _clock: Node
var _frame := 0
var _stop_at := -1


func _initialize() -> void:
	var render := Vector2i.ZERO
	var light := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--render="):
			var p := a.substr(9).split("x")
			render = Vector2i(int(p[0]), int(p[1]))
		elif a == "--light":
			light = true
		elif a.begins_with("--frames="):
			_stop_at = int(a.substr(9))
		elif a.begins_with("--start="):
			_frame = int(float(a.substr(8)) * FPS)
	var settings := root.get_node(^"Settings")
	settings.autosave = false
	if render != Vector2i.ZERO:
		settings.internal_resolution = render
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	for n in ["DebugOverlay", "LookPanel", "TouchLayer"]:
		var c := main.get_node_or_null(NodePath(n)) as CanvasLayer
		if c:
			c.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var street := main.find_child("TestStreet", true, false) as Node3D
	_clock = street.get_node(^"DayCycle")
	_clock.set_physics_process(false)  # the tour sets the hour itself
	var player := street.get_node(^"Player")
	player.input_enabled = false
	player.global_position = Vector3(60.0, 0.0, 40.0)  # out of the way, out of shot
	if light:
		var env: Environment = load("res://src/debug/look_preset.gd").environment(self)
		env.volumetric_fog_enabled = false
		env.ssao_enabled = false
	# The gang rides in at once, so the street has them in it.
	var town := street.get_node_or_null(^"TownLife")
	if town:
		town.bring_gang()
	_camera = Camera3D.new()
	_camera.name = "TourCamera"
	street.add_child(_camera)
	var eye: Camera3D = player.camera
	_camera.attributes = eye.attributes
	_camera.cull_mask = eye.cull_mask & ~load("res://src/bodies/layers.gd").VIS_HELD
	_camera.fov = 70.0
	_camera.near = eye.near
	_camera.far = eye.far
	_camera.make_current()
	load("res://src/render/depth_mosaic.gd").apply(_camera, settings.mosaic, settings.MOSAIC_K, settings.MOSAIC_STEPS)
	if _stop_at > 0:
		_stop_at += _frame
	_place(float(_frame) / FPS)
	process_frame.connect(_step)


func _step() -> void:
	_frame += 1
	var t := float(_frame) / FPS
	_place(t)
	if t >= SECONDS or (_stop_at > 0 and _frame >= _stop_at):
		process_frame.disconnect(_step)
		quit()


func _place(t: float) -> void:
	var i := 0
	while i < PATH.size() - 2 and t > float(PATH[i + 1][0]):
		i += 1
	var a: Array = PATH[i]
	var b: Array = PATH[i + 1]
	var u := clampf((t - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
	var p0: Array = PATH[maxi(i - 1, 0)]
	var p3: Array = PATH[mini(i + 2, PATH.size() - 1)]
	var eye := _spline(p0[1], a[1], b[1], p3[1], u)
	var look := _spline(p0[2], a[2], b[2], p3[2], u)
	var hour := lerpf(float(a[3]), float(b[3]), smoothstep(0.0, 1.0, u))
	_camera.global_position = eye
	_camera.look_at(look, Vector3.UP)
	if absf(hour - _clock.time_of_day) > 0.0005:
		_clock.set_time(hour)


static func _spline(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: float) -> Vector3:
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)
