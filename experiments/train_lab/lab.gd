extends Node
## The train lab in a running game (issues #543, #551): the test line built out south of town with
## its train, the cameras for watching it (cab, chase, lineside), the debug cab key, a scripted
## driver, the engineer running the timetable, the player put aboard and walked the train, and a
## log of every drawn frame for the jitter and drift checks. Used by the lab's bridge commands
## (bridge.gd) and by its keys in a build (play.gd, added by main.gd):
##
##   9    build the line (the first time) and get in the cab / out of it again
##   0    the next camera: cab, chase, lineside at the curve, lineside at the depot, you
##   8    you on the coach's back platform, the engineer running the timetable (depot, the mine
##        and back): walk the train to the cab, ride it, jump off (8 again: back on, a new run)
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
var driver := &""  # "" (the levers as set), "whole" (scenarios' driver to B), "hold" (holds hold_kmh), "engineer"
var route_file := LINE.ROUTE
var timetable: TrainTimetable
var engineer: TrainEngineer
var engineer_body: HumanBody
## The player walked along the train by script (train_cross): toward the front, car by car.
var crossing := false
var cross_run := false
var cross_jump := true  # a hop over each gap
var cross_log: Array = []  # [t, car under him] each tick while crossing
var _cross_car := -1
var placed: Array = []  # the crates and men put on the line (train_crate, train_man)
var hits: Array = []  # balls that struck a car: {car, surface, at, energy}
var _cross_gap_jumped := -1
var hold_kmh := 25.0
var frames: Array = []  # a row a drawn frame while `logging`
var logging := false
var _hud: Label
var _yaw := 0.0
var _pitch := -4.0


func _ready() -> void:
	process_priority = 100  # after the train has drawn its cars
	process_physics_priority = -100  # the driver before the train's tick
	Events.bullet_hit.connect(_on_bullet_hit)


func _on_bullet_hit(info: Dictionary) -> void:
	var c: Object = info.get("collider")
	if c != null and is_instance_valid(c) and c.has_meta(&"train_car"):
		hits.append({"car": int(c.get_meta(&"train_car")), "surface": String(c.get_meta(&"surface", &"")),
			"at": info.position, "ricochet": info.get("ricochet", false)})


func ensure_built() -> TrackLine:
	if line and is_instance_valid(line):
		return line
	if street == null or not is_instance_valid(street):  # the game was reset (Backspace): find the new one
		street = get_tree().root.find_child("TestStreet", true, false) as Node3D
		player = get_tree().root.find_child("Player", true, false) as Player
	tuning = load("res://config/train.tres")
	line = LINE.build(street, tuning, route_file)
	train = line.get_node(^"Train")
	train.rider = player
	return line


## Build (or rebuild) on another route file.
func set_route(file: String) -> TrackLine:
	route_file = file
	if line and is_instance_valid(line):
		line.free()
	line = null
	engineer = null
	engineer_body = null
	driver = &""
	return ensure_built()


## The engineer in the cab, running the timetable from the depot (`late` s late).
func start_engineer(late := 0.0, file := "res://experiments/train_lab/timetable.json") -> TrainEngineer:
	ensure_built()
	timetable = TrainTimetable.load_file(file)
	timetable.fill(line, tuning)
	train.place(line.mark_s("depot"))
	engineer = TrainEngineer.new(train.sim, line)
	train.sim.time = 0.0
	engineer.run(timetable, late)
	_put_engineer_in_cab()
	engineer.body = engineer_body
	driver = &"engineer"
	return engineer


## His body standing in the cab on the engine's solid (it rides with it); a ball can kill him, and
## then nobody's driving.
func _put_engineer_in_cab() -> void:
	if engineer_body and is_instance_valid(engineer_body):
		engineer_body.queue_free()
	var engine: AnimatableBody3D = train.view.solids[0]
	var c: Dictionary = train.sim.cars[0]
	var mid: float = (c.trucks.x + c.trucks.y) * 0.5
	var at := Vector3(0.55, TrainCars.DECK, float(c.length) - mid - 1.1)  # on the right, at the brake stand
	var man := HumanBody.new()
	man.person_id = &"engineer"
	man.name = "Engineer"
	man.rng_seed = 551
	man.has_gun = false
	man.set_meta(&"train_rides", true)
	man.enter(engine, engine.global_transform * at, engine.global_rotation.y)
	engineer_body = man


func _physics_process(delta: float) -> void:
	if train == null or not is_instance_valid(train):
		return
	if crossing:
		_cross_step()
	match driver:
		&"engineer":
			if engineer:
				var u := Time.get_ticks_usec()
				engineer.drive(delta)
				train.cost.engineer_us = train.cost.get("engineer_us", 0) + Time.get_ticks_usec() - u
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


## The follow camera: alongside car `watch.car` (drawn, between ticks), at `watch.eye` in its frame,
## looking at `watch.target`.
var watch := {}


func _place_camera() -> void:
	if camera == null or view == &"player" or view == &"fixed":
		return
	if view == &"follow":
		var c: Dictionary = train.sim.cars[watch.car]
		var mid: float = (c.trucks.x + c.trucks.y) * 0.5
		var f: Transform3D = train.view.bodies[watch.car].global_transform
		var eye: Vector3 = watch.eye
		var tgt: Vector3 = watch.target
		camera.global_position = f * Vector3(eye.x, eye.y, eye.z - mid)
		camera.look_at(f * Vector3(tgt.x, tgt.y, tgt.z - mid), Vector3.UP)
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
			KEY_8:
				start_engineer()
				board(train.sim.cars.size() - 1, "back")
				_show_hud(true)
				get_viewport().set_input_as_handled()
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
	var eng := ""
	if driver == &"engineer" and engineer:
		var e := engineer
		var st: String = ["standing", "running", "done"][e.state]
		var bound: String = timetable.stops[mini(e.stop + (1 if e.state == TrainEngineer.RUN else 0), timetable.stops.size() - 1)].mark
		next = "  to the %s in %d m" % [bound, int(absf(e.target - sim.s))] if e.state == TrainEngineer.RUN else ""
		eng = "\nengineer: %s, %s, holding %d km/h, %+d s against the timetable (run %d s)%s" % [st, bound, int(e.cruise * 3.6), int(e.delay()), int(sim.time), "" if e._alive() else "  (DEAD: nobody's driving)"]
		var on := train.car_under(player)
		if on >= 0:
			eng += "\nyou're on the %s" % String(sim.cars[on].name)
	else:
		for m in line.marks:
			var d: float = float(line.marks[m]) - sim.s
			if d > -5.0:
				next = "  mark %s in %d m" % [m, int(d)]
				break
	return "TRAIN LAB (%s)  9 cab  0 camera  8 ride\n%.1f km/h%s\nregulator %d%% (hand %d%%)  W/S\nbrake %d%% (handle %d%%)  D/A\nreverser %s  R   grade %.1f%%   %s" % [
		String(view), sim.v * 3.6, next, int(sim.regulator * 100.0), int(sim.throttle * 100.0),
		int(sim.brake * 100.0), int(sim.brake_lever * 100.0), "fwd" if sim.reverser > 0 else "back",
		line.grade_at(sim.s - sim.length * 0.5) * 100.0, String(sim.limit)] + eng


# --- The checks ------------------------------------------------------------------------------

## A drawn frame: where each car's trucks are drawn against where the line says they are, and
## each body's heading (for the jitter and drift checks in graphs.py).
func _frame_row() -> Dictionary:
	var sim := train.sim
	var r := {"t": sim.time, "s": train.drawn_s, "v": sim.v, "frame": Engine.get_process_frames()}
	var worst := 0.0
	for i in sim.cars.size():
		var drawn := train.view.trucks[i * 2].global_position
		var want := line.to_global(line.point_at(sim.truck_s(i, 0, train.drawn_frac)))
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


# --- Aboard (step 2) -----------------------------------------------------------------------

## A point on car i in its own frame: `along` m behind its front (negative: from its back), `up`
## above the rail, `side` to its right.
func car_point(i: int, along: float, up := TrainCars.DECK, side := 0.0) -> Vector3:
	var c: Dictionary = train.sim.cars[i]
	var mid: float = (c.trucks.x + c.trucks.y) * 0.5
	var z := along if along >= 0.0 else float(c.length) + along
	return train.view.solids[i].global_transform * Vector3(side, up, z - mid)


## The player standing on car i (`where`: back, front, mid, or metres behind its front), facing the
## engine. He rides from there.
func board(i: int, where := "back") -> Dictionary:
	ensure_built()
	set_view(&"player")
	var along := -0.4 if where == "back" else (0.4 if where == "front" else (float(train.sim.cars[i].length) * 0.5 if where == "mid" else float(where)))
	var at := car_point(i, along, TrainCars.DECK + 0.05)
	player.global_position = at
	var fwd := -train.view.solids[i].global_basis.z
	# On a moving car he's moving with it (set down still, the car would run on from under him).
	player.velocity = fwd * float(train.sim.vel[i])
	player.rotation.y = atan2(-fwd.x, -fwd.z)
	return {"car": i, "at": at}


## Walk the player forward along the train, car by car, to the cab (the scripted crossing):
## steered at the middle of the car ahead, a hop over each gap if `jump`, run if `run`.
func cross(run := false, jump := true) -> void:
	crossing = true
	cross_run = run
	cross_jump = jump
	cross_log.clear()
	_cross_car = train.car_under(player)
	_cross_gap_jumped = -1


func _cross_step() -> void:
	var on := train.car_under(player)
	if on >= 0:
		_cross_car = on
	cross_log.append([train.sim.time, on, player.global_position.y])
	if _cross_car < 0:
		_cross_end()
		return
	# Aim at a point 3 m ahead of him along his car's middle line (or the next car's, near its front).
	var target: Vector3
	var c: Dictionary = train.sim.cars[_cross_car]
	var local := train.view.solids[_cross_car].global_transform.affine_inverse() * player.global_position
	var mid: float = (c.trucks.x + c.trucks.y) * 0.5
	var from_front := local.z + mid  # m behind his car's front
	if _cross_car == 0 and from_front < float(c.length) - 1.6:
		_cross_end()  # in the cab
		return
	if from_front < 1.2 and _cross_car > 0:
		target = car_point(_cross_car - 1, -2.0, TrainCars.DECK)
		if cross_jump and _cross_gap_jumped != _cross_car and from_front < 0.55:
			_cross_gap_jumped = _cross_car
			_act(&"jump", true)
			get_tree().create_timer(0.1, true, true).timeout.connect(func() -> void: _act(&"jump", false))
	else:
		target = car_point(_cross_car, maxf(from_front - 3.0, 0.0), TrainCars.DECK)
	var to := target - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	_act(&"move_forward", true)
	if cross_run:
		_act(&"run", true)


func _cross_end() -> void:
	crossing = false
	_act(&"move_forward", false)
	_act(&"run", false)


## Off the side (`side` left or right): a quarter turn that way, a couple of quick steps and the
## leap (from a stand the air carries him little: PlayerTuning.air_accel).
func jump_off(side := "right") -> void:
	var s := 1.0 if side == "right" else -1.0
	player.rotate_y(-s * PI * 0.5)
	_act(&"move_forward", true)
	_act(&"run", true)
	var tree := get_tree()
	tree.create_timer(0.3, true, true).timeout.connect(func() -> void: _act(&"jump", true))
	tree.create_timer(0.45, true, true).timeout.connect(func() -> void: _act(&"jump", false))
	tree.create_timer(1.6, true, true).timeout.connect(func() -> void:
		_act(&"move_forward", false)
		_act(&"run", false))


## A kit crate standing on the line at s (`side` m right of its middle).
func place_crate(s: float, side := 0.0, kind := &"crate") -> KitProp:
	ensure_built()
	var f := line.global_transform * line.transform_at(s)
	var prop := PropKit.spawn(kind)
	street.add_child(prop)
	# On the ballast's top (the ties are half sunk in it; the rails stand on them).
	var t := tuning
	prop.global_position = f * Vector3(side, -t.rail_size.y - t.tie_size.y * 0.5, 0.0)
	prop.global_rotation.y = f.basis.get_euler().y + 0.3
	placed.append(prop)
	return prop


## A townsman standing on the line at s.
func place_man(s: float, side := 0.0) -> HumanBody:
	ensure_built()
	var f := line.global_transform * line.transform_at(s)
	var man := HumanBody.new()
	man.person_id = StringName("on_line%d" % get_tree().get_frame())
	man.name = String(man.person_id).capitalize()
	man.rng_seed = 777
	man.has_gun = false
	man.enter(street, f * Vector3(side, -tuning.rail_size.y - tuning.tie_size.y * 0.5, 0.0), f.basis.get_euler().y)
	placed.append(man)
	return man


## What became of everything put on the line: where it is now (a loose prop's pieces by their
## middle), how far along the line and how far off its middle (m; the rails are 0.46 either side,
## the ballast's shoulder ~1.6, the train's side 1.15).
func placed_report() -> Array:
	var out := []
	for n in placed:
		if not is_instance_valid(n):
			continue
		var at: Vector3 = (n as Node3D).global_position
		var state := ""
		var pieces := 0
		var extra := {}
		if n is KitProp:
			var kp := n as KitProp
			state = "loose" if kp.loose else "standing"
			var sum := Vector3.ZERO
			var off_ties := 0
			for rb in kp.rubble:
				if is_instance_valid(rb):
					var p := (rb as Node3D).global_position
					sum += p
					pieces += 1
					var lp := line.to_local(p)
					var ps := line.curve.get_closest_offset(lp)
					if absf((line.transform_at(ps).affine_inverse() * lp).x) > tuning.tie_size.x * 0.5:
						off_ties += 1
			extra.off_the_ties = off_ties
			if pieces > 0:
				at = sum / pieces
		elif n is HumanBody:
			var hb := n as HumanBody
			state = "limp" if hb.limp else "standing"
			at = hb.parts[&"pelvis"].global_position if hb.parts.has(&"pelvis") else at
		var local := line.to_local(at)
		var s := line.curve.get_closest_offset(local)
		var f := line.transform_at(s)
		var row := {"name": String(n.name), "state": state, "pieces": pieces, "s": snappedf(s, 0.01),
			"off_line": snappedf((f.affine_inverse() * local).x, 0.01), "at": [snappedf(at.x, 0.01), snappedf(at.y, 0.01), snappedf(at.z, 0.01)]}
		row.merge(extra)
		out.append(row)
	return out


## Press or let go of an action as a key would (an input event: what the player reads).
func _act(action: StringName, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)
