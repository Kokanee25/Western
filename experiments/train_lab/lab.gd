extends Node
## The train lab in a running game (issues #543, #551): a line built out on the flat round town
## from its route file (routes/), with its train, the cameras for watching it (cab, chase,
## lineside), the debug cab key, a scripted driver, and a log of every drawn frame for the jitter
## and drift checks. Step 2: the engineer (a man in the cab) driving to the route's timetable
## (timetables/), a crate on the line, the player put on a car to ride it, a scripted crossing of
## the whole train back to front, and the slack readout for the films. Used by the lab's bridge
## commands (bridge.gd) and by its keys in a build (play.gd, added by main.gd):
##
##   9    build the line (the first time) and get in the cab / out of it again
##   0    the next camera: cab, chase, lineside at the curve, lineside at the depot, you
##   6    the engineer drives to the timetable (again: he stops driving)
##   5    put me on the train (the coach's roof), to ride it or cross it to the cab
##   in the cab: W / S the regulator open / shut, D / A the brake on / off, R the reverser
##
## Nothing in the town changes: the line is laid in the street's space far out on the flat.

const LINE := preload("res://experiments/train_lab/test_line.gd")
const SC := preload("res://experiments/train_lab/scenarios.gd")
const VIEWS := [&"cab", &"chase", &"curve", &"side_a", &"player"]
const CROSS_TIMEOUT := 120.0

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
## The route the line is laid from (routes/<name>.json).
var route_name := "test_line"
var timetable: Timetable
var engineer_man: Node3D
## The scripted crossing of the train back to front (cross()): its state and what it did.
var crossing := false
var cross_log: Array = []
var _cross_t := 0.0
var _cross_car := -1
var _jumped_at := -10.0
## The slack readout on the HUD (gaps and speeds a car, the last coupler events).
var show_slack := false
var _slack_hud: Label
var _events: Array = []


func _ready() -> void:
	process_priority = 100  # after the train has drawn its cars
	process_physics_priority = -100  # the driver before the train's tick


func ensure_built(which := "") -> TrackLine:
	if line and is_instance_valid(line) and (which == "" or which == route_name):
		return line
	if which != "":
		route_name = which
	if street == null or not is_instance_valid(street):  # the game was reset (Backspace): find the new one
		street = get_tree().root.find_child("TestStreet", true, false) as Node3D
		player = get_tree().root.find_child("Player", true, false) as Player
	tuning = load("res://config/train.tres")
	timetable = null
	engineer_man = null
	line = LINE.build(street, tuning, route_name)
	train = line.get_node(^"Train")
	train.coupler.connect(_on_coupler)
	return line


func _on_coupler(e: Dictionary) -> void:
	_events.append(e)
	if _events.size() > 6:
		_events.pop_front()


# --- The engineer ----------------------------------------------------------------------------

## The engineer drives to the route's timetable, `late` s late off the first stop; the clock starts
## `lead` s before its leave time. A man stands at the cab's right-hand window.
func start_engineer(late := 0.0, lead := 20.0) -> Dictionary:
	ensure_built()
	var first := line.mark(line.stops[0]) if not line.stops.is_empty() else train.sim.s
	train.sim.brake_lever = 1.0
	train.place(first)
	timetable = Timetable.work_out(LINE.timetable_data(route_name), line, tuning)
	var e := TrainEngineer.new(train.sim, line, tuning)
	e.late_start = late
	e.follow(timetable, float(timetable.stops[0].leave) - lead)
	train.engineer = e
	driver = &""
	_place_engineer_man()
	return {"timetable": timetable.summary(), "problems": Array(timetable.problems), "late": late}


func stop_engineer() -> void:
	if train:
		train.engineer = null


func _place_engineer_man() -> void:
	if engineer_man and is_instance_valid(engineer_man):
		return
	var engine: Node3D = train.view.bodies[0]
	var spot := engine.to_global(TrainView.cab_spot(train.sim.cars[0]))
	var fwd := -engine.global_basis.z
	var man := HumanBody.new()
	man.rng_seed = 1882
	man.person_id = &"engineer"
	man.name = "Engineer"
	man.has_gun = false
	man.enter(engine, spot, atan2(-fwd.x, -fwd.z))
	engineer_man = man


# --- The player on the train -----------------------------------------------------------------

## Which car the player is on (or over), and where along it: {car, along (0 its front end .. its
## length), on (standing on it)}, or {car: -1}.
func player_on() -> Dictionary:
	if player == null or train == null:
		return {"car": -1}
	for i in train.sim.cars.size():
		var car: Dictionary = train.sim.cars[i]
		var b: Node3D = train.view.bodies[i]
		var p := b.to_local(player.global_position)
		var e := TrainView.ends(car)
		if absf(p.x) < float(car.width) * 0.5 + 0.2 and p.z > e.x - 0.35 and p.z < e.y + 0.35 and p.y > 0.5 and p.y < float(car.height) + 2.5:
			return {"car": i, "name": String(car.name), "along": p.z - e.x, "height": p.y, "on": player.is_on_floor()}
	return {"car": -1}


## Put the player on a car (by index or name), standing on its top (or the cab floor), facing ahead.
func ride(which: String) -> Dictionary:
	ensure_built()
	var i := int(which) if which.is_valid_int() else -1
	for k in train.sim.cars.size():
		if String(train.sim.cars[k].name) == which:
			i = k
	i = clampi(i, 0, train.sim.cars.size() - 1)
	var car: Dictionary = train.sim.cars[i]
	var b: Node3D = train.view.bodies[i]
	var e := TrainView.ends(car)
	var local := Vector3(0.0, float(car.height) + 0.05, (e.x + e.y) * 0.5)
	if car.kind == &"engine":
		local = TrainView.cab_spot(car) + Vector3(-1.0, 0.05, 0.0)
	elif car.kind == &"tender":
		local = Vector3(0.0, float(car.height) + 0.05, e.y - 1.5)
	var fwd := -b.global_basis.z
	player.global_position = b.to_global(local)
	player.velocity = Vector3.ZERO
	player.rotation.y = atan2(-fwd.x, -fwd.z)
	return {"car": String(car.name), "at": [player.global_position.x, player.global_position.y, player.global_position.z]}


## Walk the player from where he is to the cab, car by car, jumping each gap, while the train runs.
func cross(on := true) -> void:
	crossing = on
	_cross_t = 0.0
	_cross_car = -1
	if on:
		cross_log.clear()
	else:
		_release_keys()


func _release_keys() -> void:
	for a in [&"move_forward", &"jump", &"run"]:
		Input.action_release(a)


func _cross_tick(delta: float) -> void:
	_cross_t += delta
	var where := player_on()
	var i := int(where.car)
	if i != _cross_car:
		cross_log.append({"t": snappedf(_cross_t, 0.01), "car": where.get("name", "off"), "kmh": snappedf(train.sim.v * 3.6, 0.1)})
		_cross_car = i
	if i < 0 and player.is_on_floor() and _cross_t > 1.0:
		cross_log.append({"t": snappedf(_cross_t, 0.01), "fell": true, "at": [player.global_position.x, player.global_position.y, player.global_position.z]})
		cross(false)
		return
	var in_cab := i == 0 and float(where.along) < float(train.sim.cars[0].length) - 0.8
	if in_cab or _cross_t > CROSS_TIMEOUT:
		cross_log.append({"t": snappedf(_cross_t, 0.01), "done": in_cab})
		cross(false)
		return
	if i < 0:
		return  # in the air over a gap
	# Face along the train toward the car ahead's front end (in the cab, its middle).
	var ahead: Node3D = train.view.bodies[maxi(i - 1, 0)]
	var e_ahead := TrainView.ends(train.sim.cars[maxi(i - 1, 0)])
	var aim := ahead.to_global(Vector3(0.0, 0.0, e_ahead.x))
	if i <= 1:
		aim = train.view.bodies[0].to_global(TrainView.cab_spot(train.sim.cars[0]) - Vector3(0.55, 0.0, 0.0))
	var to := aim - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	Input.action_press(&"move_forward")
	# At the front end of this car, jump the gap (a short hop down onto a low car, a hop up onto a step).
	var car: Dictionary = train.sim.cars[i]
	# (Not off the tender's deck into the cab: they're level, and the cab's roof is low over it.)
	var near_end: bool = float(where.along) < 0.55 and car.kind != &"tender" and i > 0
	if near_end and player.is_on_floor() and _cross_t - _jumped_at > 0.6:
		Input.action_press(&"jump")
		_jumped_at = _cross_t
		cross_log.append({"t": snappedf(_cross_t, 0.01), "jump_from": String(car.name), "kmh": snappedf(train.sim.v * 3.6, 0.1)})
	else:
		Input.action_release(&"jump")


func _physics_process(delta: float) -> void:
	if train == null or not is_instance_valid(train):
		return
	if crossing and player:
		_cross_tick(delta)
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
	if show_slack:
		_slack_text()


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
			KEY_5:
				ensure_built()
				if view != &"player":
					set_view(&"player")
					_show_hud(true)
				ride(String(train.sim.cars[train.sim.cars.size() - 1].name))
				get_viewport().set_input_as_handled()
			KEY_6:
				ensure_built()
				if train.engineer:
					stop_engineer()
				else:
					start_engineer()
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


## The slack readout: each coupler's gap past bunched (mm, of its play), each car's speed, the
## last coupler events.
func set_slack(on: bool) -> void:
	show_slack = on
	if on and _slack_hud == null:
		var layer := CanvasLayer.new()
		layer.name = "TrainSlackHud"
		layer.layer = 51
		add_child(layer)
		_slack_hud = Label.new()
		_slack_hud.position = Vector2(16, 300)
		_slack_hud.add_theme_font_size_override(&"font_size", 16)
		_slack_hud.add_theme_color_override(&"font_outline_color", Color.BLACK)
		_slack_hud.add_theme_constant_override(&"outline_size", 4)
		layer.add_child(_slack_hud)
	if _slack_hud:
		_slack_hud.get_parent().visible = on


func _slack_text() -> void:
	if _slack_hud == null or train == null:
		return
	var sim := train.sim
	var bunched := tuning.coupler_gap - tuning.coupler_slack * 0.5
	var lines := PackedStringArray(["%.1f km/h   slack (mm out of %d)   car km/h" % [sim.v * 3.6, int(tuning.coupler_slack * 1000.0)]])
	for i in sim.cars.size():
		var l := "%-8s %5.1f" % [String(sim.cars[i].name), sim.u[i] * 3.6]
		if i < sim.cars.size() - 1:
			var mm := (sim.gap(i) - bunched) * 1000.0
			var bar := "#".repeat(clampi(int(mm / 6.5), 0, 12))
			l += "   |%-10s| %3d" % [bar, int(mm)]
		lines.append(l)
	for e in _events:
		if sim.time - float(e.t) < 4.0:
			lines.append("CLANK %s %s-%s (%.2f m/s)" % ["runs out" if e.kind == &"out" else "bunches", e.between[0], e.between[1], e.speed])
	_slack_hud.text = "\n".join(lines)


func _hud_text() -> String:
	var sim := train.sim
	var next := ""
	for m in line.stops:
		var d: float = float(line.marks[m]) - sim.s
		if d > -5.0:
			next = "  %s in %d m" % [m, int(d)]
			break
	if train.engineer:
		var e := train.engineer
		next += "\nengineer: %s to %s, %s, %+d s" % [String(e.state), String(timetable.stops[e.stop_i].at) if timetable else "-",
			Timetable.clock_text(e.clock), int(e.delay())]
	return "TRAIN LAB (%s)  9 cab  0 camera  6 engineer  5 ride\n%.1f km/h%s\nregulator %d%% (hand %d%%)  W/S\nbrake %d%% (handle %d%%)  D/A\nreverser %s  R   grade %.1f%%   %s" % [
		String(view), sim.v * 3.6, next, int(sim.regulator * 100.0), int(sim.throttle * 100.0),
		int(sim.brake * 100.0), int(sim.brake_lever * 100.0), "fwd" if sim.reverser > 0 else "back",
		line.grade_at(sim.middle()) * 100.0, String(sim.limit)]


# --- The checks ------------------------------------------------------------------------------

## A drawn frame: where each car's trucks are drawn against where the line says they are, and
## each body's heading (for the jitter and drift checks in graphs.py).
func _frame_row() -> Dictionary:
	var sim := train.sim
	var r := {"t": sim.time, "s": train.drawn_s, "v": sim.v, "frame": Engine.get_process_frames()}
	var worst := 0.0
	for i in sim.cars.size():
		var drawn := train.view.trucks[i * 2].global_position
		var want := line.to_global(line.point_at(sim.truck_s(i, 0)))
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
