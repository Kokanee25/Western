extends Node
## The train lab in a running game (issue #543): the test line built out south of town with its
## train, the cameras for watching it (cab, chase, lineside), the debug cab key, a scripted driver,
## and a log of every drawn frame for the jitter and drift checks. Used by the lab's bridge
## commands (bridge.gd) and by its keys in a build (play.gd, added by main.gd):
##
##   9    build the line (the first time) and get in the cab / out of it again
##   0    the next camera: cab, chase, lineside at the curve, lineside at A, you
##   in the cab: W / S the regulator open / shut, D / A the brake on / off, R the reverser
##
## Nothing in the town changes: the line is laid in the street's space far out on the flat.

const LINE := preload("res://experiments/train_lab/test_line.gd")
const SC := preload("res://experiments/train_lab/scenarios.gd")
const VIEWS := [&"cab", &"chase", &"curve", &"side_a", &"player"]

var street: Node3D
var player: Player
var tuning: TrainTuning
var line: TrackLine
var train: Train
var camera: Camera3D
var view := &"player"
var side_at := 120.0  # the lineside camera's spot along the line
var driver := &""  # "" (the levers as set), "whole" (scenarios' driver to B), "hold" (holds hold_kmh)
var hold_kmh := 25.0
var frames: Array = []  # a row a drawn frame while `logging`
var logging := false
var _hud: Label
var _yaw := 0.0
var _pitch := -4.0


func _ready() -> void:
	process_priority = 100  # after the train has drawn its cars
	process_physics_priority = -100  # the driver before the train's tick


func ensure_built() -> TrackLine:
	if line and is_instance_valid(line):
		return line
	if street == null or not is_instance_valid(street):  # the game was reset (Backspace): find the new one
		street = get_tree().root.find_child("TestStreet", true, false) as Node3D
		player = get_tree().root.find_child("Player", true, false) as Player
	tuning = load("res://config/train.tres")
	line = LINE.build(street, tuning)
	train = line.get_node(^"Train")
	return line


func _physics_process(_delta: float) -> void:
	if train == null or not is_instance_valid(train):
		return
	match driver:
		&"whole":
			SC._driver(train.sim, line, hold_kmh)
		&"hold":
			var kph := train.sim.v * 3.6
			train.sim.throttle = 1.0 if kph < hold_kmh - 1.0 else (0.35 if kph < hold_kmh else 0.0)
			var grade := line.grade_at(train.sim.s - train.sim.length * 0.5)
			train.sim.brake_lever = 0.6 if grade < -0.005 and kph > hold_kmh + 1.0 else 0.0
			if grade < -0.005:
				train.sim.throttle = 0.0


func _process(delta: float) -> void:
	if train == null or not is_instance_valid(train):
		return
	if view == &"cab" and player and not player.can_process():
		_cab_keys(delta)
	_place_camera()
	if logging:
		frames.append(_frame_row())
	if _hud:
		_hud.text = _hud_text()


# --- Cameras ---------------------------------------------------------------------------------

func set_view(v: StringName) -> void:
	ensure_built()
	view = v
	if v == &"player":
		if camera:
			camera.queue_free()
			camera = null
		if player:
			player.process_mode = Node.PROCESS_MODE_INHERIT
			player.camera.make_current()
		return
	if camera == null:
		camera = Camera3D.new()
		camera.name = "TrainLabCamera"
		street.add_child(camera)
		if player:
			camera.attributes = player.camera.attributes
			camera.cull_mask = player.camera.cull_mask
			camera.far = player.camera.far
			camera.near = player.camera.near
			camera.fov = player.camera.fov
		DepthMosaic.apply(camera, Settings.mosaic, Settings.MOSAIC_K, Settings.MOSAIC_STEPS)
	camera.make_current()
	if player:  # in the cab you drive, not walk
		player.process_mode = Node.PROCESS_MODE_DISABLED if v == &"cab" else Node.PROCESS_MODE_INHERIT
	if v == &"curve":
		side_at = 520.0
	elif v == &"side_a":
		side_at = 150.0
	_yaw = 0.0
	_pitch = -4.0
	_place_camera()


func _place_camera() -> void:
	if camera == null or view == &"player":
		return
	var engine: Node3D = train.view.bodies[0]
	var ef := engine.global_transform
	match view:
		&"cab":
			var c: Dictionary = train.sim.cars[0]
			var back: float = float(c.length) * 0.5 - (c.trucks.x + c.trucks.y) * 0.5
			var at := ef * Vector3(1.2, 2.9, back + float(c.length) * 0.5 - 1.6)  # leaning out of the right-hand window
			camera.global_transform = Transform3D(ef.basis * Basis.from_euler(Vector3(deg_to_rad(_pitch), deg_to_rad(_yaw), 0.0)), at)
		&"chase":
			var at := ef * Vector3(-9.0, 4.5, 16.0)
			camera.global_position = at
			camera.look_at(ef * Vector3(0.0, 1.5, 4.0), Vector3.UP)
		_:
			var f := line.global_transform * line.transform_at(side_at)
			var at := f * Vector3(-10.0, 1.7, 0.0)
			camera.global_position = at
			camera.look_at(ef * Vector3(0.0, 1.8, 4.0), Vector3.UP)


# --- The cab ---------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_9:
				ensure_built()
				set_view(&"player" if view == &"cab" else &"cab")
				_show_hud(view != &"player")
				get_viewport().set_input_as_handled()
			KEY_0:
				ensure_built()
				var i := VIEWS.find(view)
				set_view(VIEWS[(i + 1) % VIEWS.size()])
				_show_hud(view != &"player")
				get_viewport().set_input_as_handled()
			KEY_R:
				if view == &"cab" and train:
					train.sim.reverser = -train.sim.reverser
					get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and view == &"cab":
		_yaw = clampf(_yaw - event.relative.x * 0.15, -120.0, 120.0)
		_pitch = clampf(_pitch - event.relative.y * 0.15, -60.0, 50.0)


func _cab_keys(delta: float) -> void:
	var sim := train.sim
	var lever := 0.5 * delta  # a lever's whole travel in two seconds held
	if Input.is_physical_key_pressed(KEY_W):
		sim.throttle = minf(1.0, sim.throttle + lever)
	if Input.is_physical_key_pressed(KEY_S):
		sim.throttle = maxf(0.0, sim.throttle - lever)
	if Input.is_physical_key_pressed(KEY_D):
		sim.brake_lever = minf(1.0, sim.brake_lever + lever)
	if Input.is_physical_key_pressed(KEY_A):
		sim.brake_lever = maxf(0.0, sim.brake_lever - lever)


func _show_hud(on: bool) -> void:
	if on and _hud == null:
		var layer := CanvasLayer.new()
		layer.name = "TrainLabHud"
		layer.layer = 50
		add_child(layer)
		_hud = Label.new()
		_hud.position = Vector2(16, 16)
		_hud.add_theme_font_size_override(&"font_size", 18)
		_hud.add_theme_color_override(&"font_outline_color", Color.BLACK)
		_hud.add_theme_constant_override(&"outline_size", 4)
		layer.add_child(_hud)
	if _hud:
		_hud.get_parent().visible = on


func _hud_text() -> String:
	var sim := train.sim
	var next := ""
	for m in line.marks:
		var d: float = float(line.marks[m]) - sim.s
		if d > -5.0:
			next = "  mark %s in %d m" % [m, int(d)]
			break
	return "TRAIN LAB (%s)  9 cab  0 camera\n%.1f km/h%s\nregulator %d%% (hand %d%%)  W/S\nbrake %d%% (handle %d%%)  D/A\nreverser %s  R   grade %.1f%%   %s" % [
		String(view), sim.v * 3.6, next, int(sim.regulator * 100.0), int(sim.throttle * 100.0),
		int(sim.brake * 100.0), int(sim.brake_lever * 100.0), "fwd" if sim.reverser > 0 else "back",
		line.grade_at(sim.s - sim.length * 0.5) * 100.0, String(sim.limit)]


# --- The checks ------------------------------------------------------------------------------

## A drawn frame: where each car's trucks are drawn against where the line says they are, and
## each body's heading (for the jitter and drift checks in graphs.py).
func _frame_row() -> Dictionary:
	var sim := train.sim
	var r := {"t": sim.time, "s": train.drawn_s, "v": sim.v, "frame": Engine.get_process_frames()}
	var worst := 0.0
	for i in sim.cars.size():
		var drawn := train.view.trucks[i * 2].global_position
		var want := line.to_global(line.point_at(sim.truck_s(i, 0, train.drawn_s)))
		worst = maxf(worst, drawn.distance_to(want))
		var b: Node3D = train.view.bodies[i]
		var fwd := -b.global_basis.z
		r["yaw%d" % i] = atan2(-fwd.x, -fwd.z)
		r["x%d" % i] = b.global_position.x
		r["z%d" % i] = b.global_position.z
		r["y%d" % i] = b.global_position.y
	r.truck_off = worst
	r.k = line.curvature_at(sim.s - sim.cars[0].length * 0.5)
	return r


func write_frames(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null or frames.is_empty():
		return 0
	var keys: Array = frames[0].keys()
	f.store_line(",".join(keys))
	for r in frames:
		var vals := PackedStringArray()
		for k in keys:
			vals.append(str(r[k]))
		f.store_line(",".join(vals))
	f.close()
	return frames.size()
