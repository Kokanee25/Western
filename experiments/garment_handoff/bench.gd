extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The garment handoff's bench (#895; lab only; README.md beside it): MetaHuman Sean (his Studio
## build, copied into assets/people/ for the run, never committed) on a plain floor with a kit chair
## by him, the long glove worn, the handoff on cue at 0.5 s; every tick measured. Headless for the
## numbers; under xvfb with --shots for a few stills (plain lights: the film is the bridge's, in the
## game's real look).
##
##   godot --headless --fixed-fps 60 -s res://experiments/garment_handoff/bench.gd -- --out=DIR [--no-glove] [--seconds=S] [--debug]
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/garment_handoff/bench.gd -- \
##       --out=DIR --shots=2,3,4 [--cam=front|side|close] [--debug]
##
## Writes DIR/summary.json (and s_<tick>.png for --shots).

## The man: a Studio man in the repo by default (`--model=`; the lab used `sean_metahuman_s3`, his
## files copied in for a run and never committed).
var MODEL := &"barkeep_s2_talking"
var Handoff: GDScript
const CAMS := {
	"front": [Vector3(0.9, 1.45, -2.1), Vector3(0.25, 1.05, 0.0), 40.0],
	"side": [Vector3(2.4, 1.3, -0.4), Vector3(0.35, 1.0, -0.2), 40.0],
	"close": [Vector3(0.75, 1.35, -1.05), Vector3(0.2, 1.08, -0.35), 38.0],
	"left": [Vector3(-0.85, 1.4, -1.0), Vector3(0.0, 1.05, -0.3), 40.0],
	"hands": [Vector3(-0.2, 1.75, -1.25), Vector3(0.15, 1.05, -0.45), 42.0],
	"floor": [Vector3(1.9, 1.5, -1.6), Vector3(0.9, 0.5, -0.4), 45.0],
}

var opts := {}
var prof: GDScript
var vp: SubViewport
var world: Node3D
var man: Node3D
var chair: Node3D
var handoff: Node3D
var cam: Camera3D
var tick := 0
var _shots: Array = []
var frames_ms: Array = []
var phase_ms := {}
var phase_us := {}
var _prof_was := {}
## Prof's systems read a tick: the glove's own and the man's.
const SYSTEMS := [&"cloth", &"glove_handoff", &"garment", &"people_body", &"people_skeleton"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	Handoff = load("res://experiments/garment_handoff/handoff.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1] if kv.size() > 1 else "true"
	MODEL = StringName(opts.get("model", String(MODEL)))
	var out_dir := String(opts.get("out", "build/garment_handoff"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	prof = load("res://src/debug/prof.gd")
	prof.on = true
	_build_world()
	if opts.has("shots"):
		for x in String(opts.shots).split(","):
			_shots.append(float(x))
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	await process_frame
	await physics_frame
	man = load("res://src/bodies/human_body.gd").new()
	man.name = "Sean"
	man.person_id = &"sean"
	man.body_model = MODEL
	man.has_gun = false
	world.add_child(man)
	man.global_position = Vector3.ZERO
	man.face(Vector3(0, 1.4, -3.0))
	chair = load("res://src/props/prop_kit.gd").spawn(&"chair")
	world.add_child(chair)
	chair.global_position = Vector3(0.95, 0.0, -0.75)
	chair.rotation_degrees.y = 200.0
	for i in 20:
		await physics_frame
	if String(MODEL).contains("metahuman"):
		_own_materials()
	var info := {}
	if not opts.has("no-glove") or opts.has("bare"):
		handoff = Handoff.new()
		handoff.name = "Handoff"
		handoff.no_take = opts.has("no-take")
		handoff.with_glove = not opts.has("bare")
		if opts.has("perf"):
			handoff.measure = false
			handoff.measure_skin = false
			handoff.tune.end_after_rest = 2.0
		handoff.tris = int(opts.get("tris", "700"))
		handoff.part_tune = {}
		for k in ["precision", "skin_every", "give"]:
			if opts.has(k):
				handoff.part_tune[k] = float(opts[k])
		world.add_child(handoff)
		info = handoff.dress(man, chair)
		if opts.has("hide-glove") and handoff.part:
			handoff.part.worn_mesh.visible = false
		if opts.has("all-skin") and handoff.part:
			handoff.part.taken.connect(func() -> void: handoff.part.collider.near = false)
		print("dressed ", info)
	var total := int(float(opts.get("seconds", "11")) * 60.0)
	var last := Time.get_ticks_usec()
	while tick < total:
		await physics_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		tick += 1
		if tick == 30 and handoff:
			handoff.begin()
		var ph: String = handoff.phase if handoff else ("worn" if tick < 30 else "none")
		var us := {}
		for k in SYSTEMS:
			var now_us := int(prof._sum.get(k, 0))
			us[k] = now_us - int(_prof_was.get(k, 0))
			_prof_was[k] = now_us
		if tick > 10:
			frames_ms.append(ms)
			if not phase_ms.has(ph):
				phase_ms[ph] = []
				phase_us[ph] = {}
			phase_ms[ph].append(ms)
			for k in SYSTEMS:
				phase_us[ph][k] = int(phase_us[ph].get(k, 0)) + int(us[k])
		if not _shots.is_empty() and tick >= int(round(float(_shots[0]) * 60.0)):
			_shots.pop_front()
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(out_dir.path_join("s_%05d.png" % tick))
			last = Time.get_ticks_usec()
		if handoff and handoff.done and _shots.is_empty():
			break
	var s := {"model": String(MODEL), "ticks": tick, "glove": not opts.has("no-glove"), "dress": info,
			"frame_ms_mean": _mean(frames_ms), "phase_ms": {}}
	for k in phase_ms:
		var n: int = phase_ms[k].size()
		s.phase_ms[k] = {"mean": _mean(phase_ms[k]), "median": _median(phase_ms[k]), "n": n}
		for sy in SYSTEMS:
			s.phase_ms[k][String(sy)] = snappedf(float(phase_us[k].get(sy, 0)) / 1000.0 / maxf(n, 1), 0.001)
	if handoff:
		var r: Dictionary = handoff.rec.duplicate()
		r.erase("through")
		for k in r.us:
			r.us[k] = snappedf(float(r.us[k]) / maxf(float(r.ticks.get(k, 1)), 1.0), 0.1)
		s.handoff = r
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(s, "  "))
	f.close()
	print(JSON.stringify(s))
	quit()


## His GLB's own materials on his skin's meshes (as the Studio and the skeleton lab draw a
## MetaHuman: the game's people shaders expect the painted men's textures).
func _own_materials() -> void:
	var scene := load("res://assets/people/%s.glb" % MODEL) as PackedScene
	var r := scene.instantiate()
	var mats := {}
	for mi in r.find_children("*", "MeshInstance3D", true, false):
		var shape := String(mi.name).to_lower().trim_prefix("body_").trim_prefix("cloth_")
		if mi.mesh and mi.mesh.get_surface_count() > 0:
			mats[shape] = mi.mesh.surface_get_material(0)
	r.free()
	for c in man.skeleton.get_children():
		if c is MeshInstance3D:
			for shape: String in mats:
				if String(c.name).begins_with(shape.to_pascal_case() + "_"):
					c.material_override = mats[shape]
					break


func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return snappedf(float(b[b.size() / 2]), 0.001)


func _mean(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var t := 0.0
	for x in a:
		t += float(x)
	return snappedf(t / a.size(), 0.001)


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
	env.environment.background_color = Color(0.12, 0.1, 0.08)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.45, 0.4)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 150, 0)
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := StaticBody3D.new()
	ground.name = "Floor"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	var gm := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	gm.mesh = pm
	gm.position.y = 0.5
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.35, 0.27, 0.19)
	gm.material_override = fm
	ground.add_child(gm)
	world.add_child(ground)
	cam = Camera3D.new()
	world.add_child(cam)
	var c: Array = CAMS.get(String(opts.get("cam", "front")), CAMS.front)
	cam.position = c[0]
	cam.look_at(c[1])
	cam.fov = c[2]
	cam.current = true
