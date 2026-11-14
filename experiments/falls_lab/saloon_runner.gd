extends Node3D
## The falls lab in the building lab's saloon (issue #759; falls.gd `--saloon`): a fresh saloon
## (experiments/building_lab/spec_building.gd, saloon.json) for each case and seed, a man in it
## going limp with a push (a ball's or a shove's: `push` m/s, his ragdoll's own fall after), and what
## his fall did: to him (HumanBody.last_fall, his harm, whether he dies of it in ten minutes) and to
## the saloon (the members broken, by kind), whether he's still drawn where he lies (#562), and the
## worst frame from his push to the end (#492's gate: none over 100 ms at Sean's, x0.65 here).
## Cases (the spec's own space: the front along +x at z 0, the street at -z):
## - gallery: on the front gallery's floor at the well's rail, pushed through it into the hall
##   (3.66 m down to the hall floor);
## - balcony: on the street balcony, pushed over its rail to the street (4.44 m);
## - roof: let go 4 m over the saloon's roof boards (as off a higher roof or the false front);
## - roof_edge: on the roof's boards by the eave over the street, pushed off it (onto the balcony
##   below and on to the street).

const SPEC_SCRIPT := "res://experiments/building_lab/spec_building.gd"
var args := {}
var cases: Array[String] = ["gallery", "balcony", "roof", "roof_edge"]
var seeds := 6
var seconds := 5.0
var out := ""

var _saloon: Node3D
var _man: HumanBody
var _queue: Array = []  ## [case, seed]
var _phase := ""
var _t := 0
var _rows: Array = []
var _falls: Array = []
var _last_us := 0
var _worst_ms := 0.0
var _ground: StaticBody3D
## --film=DIR: a camera off to his side, a frame every 2 ticks (30 fps) from the push to the end,
## as DIR/<case>_<seed>/f_0000.png (drawn runs only: xvfb and lavapipe, falls.gd's header).
var film := ""
var _cam: Camera3D
var _frame := 0


func _ready() -> void:
	if args.has("cases"):
		cases.assign(String(args.cases).split(","))
	seeds = int(args.get("seeds", seeds))
	seconds = float(args.get("seconds", seconds))
	out = String(args.get("out", "build/falls_lab/saloon"))
	film = String(args.get("film", ""))
	if film != "":
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-50, 30, 0)
		sun.shadow_enabled = true
		add_child(sun)
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.62, 0.64, 0.66)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.8, 0.8, 0.8)
		e.ambient_light_energy = 0.6
		env.environment = e
		add_child(env)
		_cam = Camera3D.new()
		_cam.fov = 60.0
		add_child(_cam)
		_cam.current = true
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(out)
	_ground = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	cs.shape = box
	_ground.add_child(cs)
	add_child(_ground)
	_ground.position = Vector3(8, -0.5, 4)
	for c in cases:
		for k in seeds:
			_queue.append([c, k + 1])
	_next()


func _next() -> void:
	if _man:
		_man.queue_free()
		_man = null
	if _saloon:
		_saloon.queue_free()
		_saloon = null
	if _queue.is_empty():
		var f := FileAccess.open(out.path_join("saloon.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(_rows, "  "))
		f.close()
		print("falls lab (saloon): %d runs into %s" % [_rows.size(), out])
		get_tree().quit(0)
		return
	_saloon = load(SPEC_SCRIPT).new()
	_saloon.name = "Saloon"
	_saloon.set(&"structure_id", &"spec_saloon")
	add_child(_saloon)
	_phase = "settle"
	_t = 0


func _roof_y(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 30.0, z), Vector3(x, 0.5, z))
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return float((hit.position as Vector3).y) if hit else 7.5


func _physics_process(_delta: float) -> void:
	if _saloon == null:
		return
	_t += 1
	var now := Time.get_ticks_usec()
	if _phase == "fall":
		_worst_ms = maxf(_worst_ms, (now - _last_us) / 1000.0)
		if _cam and _t % 2 == 0:
			get_viewport().get_texture().get_image().save_png(film.path_join("%s_%d/f_%04d.png" % [_queue[0][0], _queue[0][1], _frame]))
			_frame += 1
	_last_us = now
	var c: String = _queue[0][0]
	var sd: int = _queue[0][1]
	if _phase == "settle" and _t == 20:
		# Its first analysis now (the game's slices it in at load through the fire's queue: this lab
		# has no fire), so the fall's frames are the break's, not the first look's (~500 ms here).
		(_saloon as Structure).settle()
	if _phase == "settle" and _t == 30:
		_man = HumanBody.new()
		_man.rng_seed = sd
		_man.person_id = &"faller"
		var dice := RandomNumberGenerator.new()
		dice.seed = hash(["saloon_falls", c, sd])
		var x := dice.randf_range(7.0, 12.0)
		var at: Vector3
		var face := Vector3.FORWARD
		match c:
			"gallery":
				at = Vector3(x, 4.44, 1.5)
				face = Vector3.BACK  # toward the well (+z)
			"balcony":
				at = Vector3(x, 4.44, -1.9)
				face = Vector3.FORWARD  # toward the street (-z)
			"roof":
				at = Vector3(x, _roof_y(x, 6.0) + 4.0, 6.0)
			"roof_edge":
				at = Vector3(x, _roof_y(x, 0.6) + 0.05, 0.6)
				face = Vector3.FORWARD
		add_child(_man)
		_man.global_transform = Transform3D(Basis.looking_at(face), at)
		_falls.clear()
		_man.fell_from.connect(func(f: Dictionary) -> void: _falls.append(f.duplicate(true)))
	elif _phase == "settle" and _t == 40:
		var dice := RandomNumberGenerator.new()
		dice.seed = hash(["saloon_push", c, sd])
		var face := -_man.global_basis.z
		var push := Vector3.ZERO
		match c:
			"gallery", "balcony":
				push = face * dice.randf_range(2.5, 4.0)
			"roof_edge":
				push = face * dice.randf_range(1.5, 3.0)
		_man.go_limp(push)
		if _cam:
			# Out the way he goes (the street, the hall), a little to his side, looking back up at him
			# and down to where he'll come down.
			var at := _man.global_position + face * 1.2 + Vector3.DOWN * 1.8
			_cam.global_position = _man.global_position + face * 7.0 + Vector3(3.0, -1.6, 0.0)
			_cam.look_at(at)
			_frame = 0
			DirAccess.make_dir_recursive_absolute(film.path_join("%s_%d" % [c, sd]))
		_phase = "fall"
		_t = 0
		_worst_ms = 0.0
	elif _phase == "fall" and _t > int(seconds * 60.0):
		_score(c, sd)
		_queue.pop_front()
		_next()


func _score(c: String, sd: int) -> void:
	var p := _man.physiology
	var harm: Array = []
	for f: Dictionary in _falls:
		harm.append_array(Array(f.harm))
	var t := 0.0
	while p.alive and t < 600.0:
		p.step(1.0)
		t += 1.0
	var broke := {}
	for m: StructureMember in (_saloon as Structure).get_members():
		if m.broken:
			broke[String(m.kind)] = int(broke.get(String(m.kind), 0)) + 1
	var pelvis := (_man.parts[&"pelvis"] as Node3D).global_position
	_rows.append({"case": c, "seed": sd, "landings": _falls.map(func(f: Dictionary) -> Dictionary: return {"kind": String(f.kind), "speed": f.speed, "blows": f.blows}),
			"harm": harm, "dead": not p.alive, "cause": String(p.cause_of_death), "broke": broke,
			"lies_at": [snappedf(pelvis.x, 0.01), snappedf(pelvis.y, 0.01), snappedf(pelvis.z, 0.01)],
			"need": snappedf(_man._impacts.peak_need if _man._impacts else 0.0, 0.001),
			"drawn": preload("res://experiments/falls_lab/falls_runner.gd").drawn(_man), "worst_frame_ms": snappedf(_worst_ms, 0.1)})
	print("%s %d: need %.2f %s | broke %s | lies y %.2f | dead %s | worst %.0f ms" % [c, sd, _man._impacts.peak_need if _man._impacts else 0.0, ", ".join(PackedStringArray(harm.filter(func(h: String) -> bool: return h != "bruised"))), broke, pelvis.y, not p.alive, _worst_ms])
