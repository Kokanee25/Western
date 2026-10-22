extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The mopping lab (docs/briefs/mopping.md, experiments/mopping/README.md): a room of boards with the
## kit's bar, the barkeep behind it (barkeep_s2_talking, his brain and MopFloor as in the game), his
## mop and bucket in the corner behind the bar's end, the street outside the door and a trough on
## it; one scenario, seeded, measured every tick; a summary, and with --render the frames for the
## film.
##
##   godot --headless --fixed-fps 60 -s res://experiments/mopping/bench.gd -- --scenario=NAME --out=DIR
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/mopping/bench.gd -- \
##       --scenario=NAME --out=DIR --render [--from=S] [--every=TICKS]
##   ... -- --scenario=NAME --out=DIR --shots=S,S,...   # stills at those times only
##   ... -- --scenario=list

const SCENARIOS := {
	"muddy": {"seconds": 170.0, "walkers": 3, "wet": 0.5,
			"note": "Three men in off a muddy street to the bar and out: then he mops"},
	"spill": {"seconds": 120.0, "cam": "close", "spills": [[0.8, -0.6, "whiskey", 0.6], [-1.0, -1.5, "beer", 0.4]],
			"note": "A bottle of whiskey and a jug of beer on the floor: he mops them up"},
	"blood": {"seconds": 150.0, "cam": "close", "blood": [0.4, -1.0, 90.0],
			"note": "Blood on the floor after a fight: he mops it"},
	"trouble": {"seconds": 150.0, "walkers": 3, "wet": 0.5, "event": "shot", "after_mop": 6.0,
			"note": "A shot as he mops: the mop dropped, the bucket down; calm again, he finishes"},
	"change_water": {"seconds": 300.0, "mud": 420.0,
			"note": "A filthy floor: his bucket's water goes black, he empties it outside and fills it at the trough"},
	"perf_on": {"seconds": 170.0, "walkers": 3, "wet": 0.5, "perf": true},
	"perf_off": {"seconds": 170.0, "walkers": 3, "wet": 0.5, "perf": true, "no_mop": true},
}
const FLOOR_TOP := 0.12
const POST := Vector3(0.0, FLOOR_TOP, 1.8)
const FACES := Vector3(0.0, 1.5, -2.0)
const HOME := Vector3(-2.3, FLOOR_TOP, 2.45)
const TROUGH_AT := Vector3(2.0, 0.0, -5.4)
const CAMS := {"room": [Vector3(3.4, 2.7, -3.9), Vector3(-0.3, 0.2, -0.3), 56.0],
		"close": [Vector3(2.3, 2.1, -2.9), Vector3(-0.2, 0.2, -0.7), 50.0]}

var opts := {}
var sc := {}
var name_ := ""
var out_dir := ""
var vp: SubViewport
var world: Node3D
var man: Node3D
var brain: Node
var chore: RefCounted
var mop: Node3D
var bucket: Node3D
var marks: Node3D
var places: RefCounted
var walkers: Array = []
var label: Label
var cam: Camera3D
var tick := 0
var event_tick := -1
var rec := {"steps": [], "mess": [], "faults": {"below_floor": 0, "flung": 0}, "frames_ms": [], "people_us": [],
		"mop_us": [], "marks_us": [], "active": []}
var _last_step := -1
var _last_us := 0
var _shots: Array = []
var _prev := PackedVector3Array()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1] if kv.size() > 1 else "true"
	if opts.get("scenario", "list") == "list":
		for k in SCENARIOS:
			print(k)
		quit()
		return
	name_ = String(opts.scenario)
	sc = SCENARIOS.get(name_, {})
	if sc.is_empty():
		push_error("no scenario %s" % name_)
		quit(1)
		return
	out_dir = String(opts.get("out", "build/mopping")).path_join(name_)
	DirAccess.make_dir_recursive_absolute(out_dir)
	load("res://src/debug/prof.gd").on = true
	_build_world()
	if opts.has("render"):
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if opts.has("shots"):
		for x in String(opts.shots).split(","):
			_shots.append(float(x))
		if not opts.has("always"):
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	await process_frame
	await physics_frame
	await _spawn()
	var total := int(float(opts.get("seconds", sc.seconds)) * 60.0)
	_last_us = Time.get_ticks_usec()
	while tick < total:
		await physics_frame
		var now := Time.get_ticks_usec()
		var ms := (now - _last_us) / 1000.0
		_last_us = now
		_step(ms)
		tick += 1
		if not _shots.is_empty() and tick >= int(round(float(_shots[0]) * 60.0)):
			_shots.pop_front()
			await _frame("s_%05d.png" % tick)
		elif opts.has("render") and tick % int(opts.get("every", "2")) == 0 and tick >= int(float(opts.get("from", "0")) * 60.0):
			await _frame("f_%05d.png" % tick)
	_write_summary()
	quit()


func _frame(file: String) -> void:
	_caption()
	if opts.has("debug"):
		for at in [Vector3(0.8, FLOOR_TOP, -0.6), Vector3(-1.0, FLOOR_TOP, -1.5)]:
			print("at ", at, " mess ", marks.mess(at, 0.5), " key ", marks.key(at), " surface ", marks.surface_at(at, 0.3))
		print("cells ", marks.cells.size(), " sample ", marks.cells.keys().slice(0, 5))
		for c in marks.get_children():
			if c is Decal:
				print("decal ", c.name, " ", c.global_position, " ", c.size, " visible ", c.is_visible_in_tree(), " tex ", c.texture_albedo.get_size() if c.texture_albedo else null)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out_dir.path_join(file))
	_last_us = Time.get_ticks_usec()


# --- The world -----------------------------------------------------------------------------------

func _build_world() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(960, 540)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	world.name = "Lab"
	vp.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.1, 0.08, 0.06)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.3, 0.26, 0.22)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_color = Color(1.0, 0.88, 0.7)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := StaticBody3D.new()
	ground.name = "Street"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	var gm := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	gm.mesh = pm
	gm.position.y = 0.5
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.42, 0.33, 0.24)
	gm.material_override = fm
	ground.add_child(gm)
	world.add_child(ground)
	# The room: 8 x 6 m of boards on sleepers, its door side toward -Z (the street).
	var room = load("res://src/structures/structure.gd").new()
	room.name = "room"
	room.structure_id = &"room"
	world.add_child(room)
	for x in [-3.7, -2.5, -1.25, 0.0, 1.25, 2.5, 3.7]:
		room.add_member("sleeper%d" % int(x * 10), &"joist", &"framing", Vector3(0.1, FLOOR_TOP - 0.03, 6.0), Vector3(x, (FLOOR_TOP - 0.03) * 0.5, 0.0))
	var z := -3.0
	var i := 0
	while z < 3.0 - 0.01:
		room.add_member("board%02d" % i, &"floor_board", &"floor", Vector3(8.0, 0.03, 0.145), Vector3(0, FLOOR_TOP - 0.015, z + 0.0725))
		z += 0.15
		i += 1
	room.infer_supports()
	marks = load("res://src/world/floor_marks.gd").new()
	marks.name = "FloorMarks"
	marks.tuning = load("res://config/floor_marks.tres").duplicate()
	marks.tuning.street_wet = float(sc.get("wet", 0.0))
	world.add_child(marks)
	var bar = load("res://src/props/prop_kit.gd").spawn(&"bar")
	bar.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0, FLOOR_TOP, 1.0))
	world.add_child(bar)
	var trough = load("res://src/structures/water_trough.gd").new()
	trough.name = "Trough"
	trough.structure_id = &"trough"
	trough.position = TROUGH_AT
	world.add_child(trough)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.0, 2.8, -0.5)
	lamp.light_color = Color(1.0, 0.78, 0.5)
	lamp.light_energy = 1.2
	lamp.omni_range = 7.0
	world.add_child(lamp)
	places = load("res://src/people/waypoints.gd").new()
	places.add(&"post", POST)
	places.add(&"bar_end_inside", Vector3(-2.2, FLOOR_TOP, 1.8), [&"post"])
	places.add(&"bar_end", Vector3(-2.2, FLOOR_TOP, 0.0), [&"bar_end_inside"])
	places.add(&"floor", Vector3(0.0, FLOOR_TOP, -0.8), [&"bar_end"])
	places.add(&"door", Vector3(0.0, FLOOR_TOP, -2.7), [&"floor"])
	places.add(&"street", Vector3(0.0, 0.0, -4.2), [&"door"])
	places.add(&"trough", Vector3(2.9, 0.0, -4.6), [&"street"])
	cam = Camera3D.new()
	world.add_child(cam)
	var c: Array = CAMS.get(String(opts.get("cam", sc.get("cam", "room"))), CAMS.room)
	cam.position = c[0]
	cam.look_at(c[1])
	cam.fov = c[2]
	cam.current = true
	var layer := CanvasLayer.new()
	vp.add_child(layer)
	label = Label.new()
	label.position = Vector2(12, 8)
	label.add_theme_font_size_override(&"font_size", 15)
	label.add_theme_color_override(&"font_color", Color(1, 0.95, 0.85))
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override(&"shadow_offset_x", 1)
	label.add_theme_constant_override(&"shadow_offset_y", 1)
	layer.add_child(label)


func _spawn() -> void:
	man = load("res://src/bodies/human_body.gd").new()
	man.name = "Barkeep"
	man.person_id = &"barkeep"
	man.body_model = &"barkeep_s2_talking"
	man.rng_seed = int(opts.get("seed", "102"))
	man.has_gun = false
	brain = load("res://src/people/civilian_brain.gd").new()
	brain.name = "Brain"
	brain.post = POST
	brain.faces = FACES
	brain.places = places
	man.add_child(brain)
	world.add_child(man)
	man.global_position = POST
	man.face(FACES)
	if sc.get("no_mop", false):
		_dirty()
		return
	bucket = load("res://src/props/prop_kit.gd").make(&"mop_bucket")
	world.add_child(bucket)
	bucket.global_position = HOME
	mop = load("res://src/props/prop_kit.gd").make(&"mop")
	world.add_child(mop)
	await physics_frame
	mop.stand_at(HOME + Vector3(0.18, 0.06, 0.18), Vector3(0.12, 1.0, 0.0))
	chore = load("res://src/people/mop_floor.gd").new(man, mop, bucket, POST, HOME)
	chore.tuning = chore.tuning.duplicate()
	chore.places = places
	chore.outside = places.at(&"street") + Vector3(0.0, 0.0, -0.4)
	chore.set(&"_look", 1.0)
	brain.chores = [chore]
	_dirty()


## The floor's starting mess, by scenario.
func _dirty() -> void:
	for s: Array in sc.get("spills", []):
		root.get_node("Events").liquid_spilled.emit(Vector3(s[0], FLOOR_TOP, s[1]), StringName(s[2]), float(s[3]), null)
	if sc.has("blood"):
		var b: Array = sc.blood
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var blood = load("res://src/effects/blood.gd")
		for k in 9:
			var at := Vector3(b[0] + rng.randf_range(-0.6, 0.6), FLOOR_TOP, b[1] + rng.randf_range(-0.5, 0.5))
			blood.splat(world, at, Vector3.UP, float(b[2]) / 9.0 * rng.randf_range(0.5, 1.5))
	if sc.has("mud"):
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var each := float(sc.mud) / 600.0
		for k in 600:
			var at := Vector3(rng.randf_range(-2.5, 2.5), FLOOR_TOP, rng.randf_range(-2.6, 0.2))
			marks.add_dirt(at, each, 0.8)


# --- Each tick -----------------------------------------------------------------------------------

func _step(ms: float) -> void:
	var t := tick / 60.0
	rec.frames_ms.append(ms)
	var sums: Dictionary = load("res://src/debug/prof.gd").get(&"_sum")
	rec.people_us.append(int(sums.get(&"civilian_brain", 0)) + int(sums.get(&"people_body", 0)) + int(sums.get(&"people_skeleton", 0)))
	rec.mop_us.append(int(sums.get(&"mop", 0)))
	rec.marks_us.append(int(sums.get(&"floor_marks", 0)))
	sums.clear()
	rec.active.append(1 if chore != null and chore.busy() else 0)
	if chore != null and int(chore.step) != _last_step:
		_last_step = int(chore.step)
		rec.steps.append([snappedf(t, 0.01), String(chore.Step.keys()[_last_step]).to_lower(), String(chore.stopped)])
	_walkers(t)
	if sc.has("event") and event_tick < 0 and chore != null and int(chore.step) == int(chore.Step.MOP):
		rec.get_or_add("mop_from", t)
		if t - float(rec.mop_from) >= float(sc.get("after_mop", 5.0)):
			event_tick = tick
			rec.event_t = snappedf(t, 0.01)
			root.get_node("Events").noise.emit(Vector3(2.0, 1.2, -2.0), 1.0, &"gunshot", null)
	if tick % 60 == 0:
		var m: Dictionary = marks.mess(Vector3(0, FLOOR_TOP, 0), 6.0)
		rec.mess.append([int(t), snappedf(m.dirt, 0.01), snappedf(m.liquid, 0.1), snappedf(m.blood, 0.1), snappedf(m.stain, 0.01)])
	if mop != null:
		_mop_faults()


## Customers: in off the street to the bar, a while there, and out.
func _walkers(t: float) -> void:
	var n := int(sc.get("walkers", 0))
	for i in n:
		var t0 := 2.0 + i * 4.0
		if t < t0:
			continue
		if walkers.size() <= i:
			var w = load("res://src/bodies/human_body.gd").new()
			w.name = "Customer%d" % i
			w.person_id = StringName("customer%d" % i)
			w.body_model = [&"young_drifter_s3_talking", &"hothead_lyle_s2_talking", &"old_rancher_s3_talking"][i % 3]
			w.rng_seed = 300 + i
			w.has_gun = false
			world.add_child(w)
			w.global_position = Vector3(-1.0 + i * 0.9, 0.0, -9.0)
			walkers.append({"man": w, "leg": 0})
		var e: Dictionary = walkers[i]
		if not is_instance_valid(e.man):
			continue
		var w: Node3D = e.man
		var at_bar := Vector3(-0.8 + i * 0.8, FLOOR_TOP, 0.2)
		var path := [Vector3(-1.0 + i * 0.9, 0.0, -3.6), Vector3(-0.6 + i * 0.6, FLOOR_TOP, -2.4), at_bar]
		var stay := 10.0
		var leg: int = e.leg
		if leg < path.size():
			if w.walk_to(path[leg], 1.3, 1.0 / 60.0):
				e.leg = leg + 1
				e.arrived = t
		elif t - float(e.get("arrived", t)) < stay:
			w.face(Vector3(at_bar.x, 1.5, 3.0))
		else:
			var out := [Vector3(-0.6 + i * 0.6, FLOOR_TOP, -2.4), Vector3(-1.0 + i * 0.9, 0.0, -3.6), Vector3(-6.0 + i, 0.0, -12.0)]
			var k: int = leg - path.size()
			if k < out.size():
				if w.walk_to(out[k], 1.3, 1.0 / 60.0):
					e.leg = leg + 1
			elif w.is_inside_tree():
				w.queue_free()
		w.set_pose(&"stand")


func _mop_faults() -> void:
	var n: int = mop.point_count()
	var pts := PackedVector3Array()
	var below := false
	var flung := false
	for i in n:
		var p: Vector3 = mop.point(i)
		pts.append(p)
		if p.y < -0.02:
			below = true
		if _prev.size() == n and p.distance_to(_prev[i]) * 60.0 > 20.0:
			flung = true
	_prev = pts
	if below:
		rec.faults.below_floor += 1
	if flung:
		rec.faults.flung += 1
		if rec.get_or_add("flung_t", []).size() < 30:
			rec.flung_t.append([snappedf(tick / 60.0, 0.01), String(chore.Step.keys()[int(chore.step)]).to_lower() if chore else ""])


func _caption() -> void:
	var lines := [String(sc.get("note", name_)) + "   %.1f s" % (tick / 60.0)]
	if chore != null:
		lines.append("chore: %s   mop: %.0f ml water, %.1f g dirt, %.1f ml blood   bucket: %.1f l, murk %.2f" % [
				String(chore.Step.keys()[int(chore.step)]).to_lower(), mop.water_ml, mop.dirt, mop.blood,
				bucket.water_ml / 1000.0, bucket.murk()])
	var m: Dictionary = marks.mess(Vector3(0, FLOOR_TOP, 0), 6.0)
	lines.append("on the floor: dirt %.1f g, spilt %.0f ml, blood %.0f ml, stains %.1f" % [m.dirt, m.liquid, m.blood, m.stain])
	label.text = "\n".join(lines)


func _write_summary() -> void:
	var s := {"scenario": name_, "seconds": tick / 60.0, "steps": rec.steps, "mess": rec.mess, "faults": rec.faults}
	if rec.has("event_t"):
		s.event_t = rec.event_t
	if rec.has("flung_t"):
		s.flung_t = rec.flung_t
	if chore != null:
		s.chore = {"goes": chore.goes, "stretches": chore.stretches, "changes": chore.changes, "stopped": String(chore.stopped),
				"step": String(chore.Step.keys()[int(chore.step)]).to_lower()}
		s.mop = {"water_ml": snappedf(mop.water_ml, 1), "dirt": snappedf(mop.dirt, 0.01), "blood": snappedf(mop.blood, 0.1),
				"standing": int(mop.state) == 0}
		s.bucket = {"litres": snappedf(bucket.water_ml / 1000.0, 0.01), "murk": snappedf(bucket.murk(), 0.01),
				"dirt": snappedf(bucket.dirt, 0.01), "blood": snappedf(bucket.blood, 0.1), "home": bucket.global_position.distance_to(HOME) < 0.6}
	s.barkeep = {"mood": String(brain.Mood.keys()[int(brain.mood)]).to_lower(), "at": str(man.global_position)}
	s.chunks = marks.chunk_count()
	var skip := 120
	s.ms = {"frame_mean": _mean(rec.frames_ms, skip), "people_mean": _mean(rec.people_us, skip) / 1000.0,
			"mop_mean": _mean(rec.mop_us, skip) / 1000.0, "marks_mean": _mean(rec.marks_us, skip) / 1000.0,
			"note": "this workspace's core (2.1 GHz); x0.65 for Sean's"}
	var on := []
	for i in rec.active.size():
		if rec.active[i] == 1:
			on.append(i)
	if not on.is_empty():
		var pick := func(a: Array) -> Array: return on.map(func(i: int) -> float: return float(a[i]))
		s.ms_working = {"ticks": on.size(), "frame_mean": _mean(pick.call(rec.frames_ms)), "people_mean": _mean(pick.call(rec.people_us)) / 1000.0,
				"mop_mean": _mean(pick.call(rec.mop_us)) / 1000.0, "marks_mean": _mean(pick.call(rec.marks_us)) / 1000.0}
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(s, "  "))
	print(JSON.stringify(s))


func _mean(a: Array, skip := 0) -> float:
	var n := 0
	var sum := 0.0
	for i in range(skip, a.size()):
		sum += float(a[i])
		n += 1
	return snappedf(sum / maxf(n, 1), 0.0001)
