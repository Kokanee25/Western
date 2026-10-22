extends SceneTree
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)
## The barkeep's rag's lab (docs/briefs/barkeep-rag.md, experiments/barkeep_rag/README.md): the
## barkeep (barkeep_s2_talking) behind the kit's bar with his cloth over his shoulder and two cups,
## his brain and its chore (WipeBar) and his face (FaceLife) running as in the game; one scenario, seeded, measured every
## tick; a summary, and with --render the frames for the video (every other tick, 30 a second).
##
##   godot --headless --fixed-fps 60 -s res://experiments/barkeep_rag/bench.gd -- --scenario=NAME --out=DIR
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/barkeep_rag/bench.gd -- \
##       --scenario=NAME --out=DIR --render [--from=S] [--every=TICKS] [--cam=side|front|close]
##   ... -- --scenario=NAME --out=DIR --shots=S,S,...   # stills at those times only (quick)
##   ... -- --scenario=list
##
## Writes DIR/<scenario>/summary.json (and f_<frame>.png with --render).

## Each scenario: seconds; what happens and when ("when": "wipe" waits for him to be wiping, at or
## after "at"); "note" goes on the film.
const SCENARIOS := {
	"cycle": {"seconds": 62.0, "glass": 1.0, "note": "A whole go: off his shoulder, wiping, moving along, a cup, back on"},
	"customer": {"seconds": 40.0, "event": "customer", "at": 12.0, "when": "wipe", "leave": 14.0,
			"note": "A man comes to the bar mid-wipe: back over his shoulder; he goes, wiping again"},
	"trouble": {"seconds": 40.0, "event": "shot", "at": 12.0, "when": "wipe",
			"note": "A shot hits the bar by his hand: the cloth drops, he cowers; calm again, he fetches it"},
	"dropped": {"seconds": 38.0, "event": "drop", "at": 12.0, "when": "wipe", "cam": "behind",
			"note": "The cloth knocked out of his hand onto the floor: he bends for it"},
	"blast": {"seconds": 30.0, "event": "blast", "at": 4.0,
			"note": "A stick goes off across the room: the cloth's blown off his shoulder"},
	"burn": {"seconds": 58.0, "event": "fire", "at": 12.0, "when": "wipe",
			"note": "A flame held to the cloth as he wipes: it catches, he drops it and gets clear; it burns away"},
	"blood": {"seconds": 34.0, "event": "wound", "at": 12.0, "when": "wipe", "cam": "right",
			"note": "A stray ball in his side as he wipes: the hand with the cloth goes to the wound, the cloth bloodies"},
	"perf_on": {"seconds": 62.0, "glass": 1.0, "perf": true},
	"perf_off": {"seconds": 62.0, "perf": true, "no_cloth": true},
}
## Where he stands, behind the bar (the kit's bar: its top at 1.095 m, customers on +Z).
const POST := Vector3(0.0, 0.0, -0.74)
const FACES := Vector3(0.0, 1.4, 2.0)

var opts := {}
var sc := {}
var name_ := ""
var out_dir := ""
var vp: SubViewport
var world: Node3D
var bar: Node3D
var man: Node3D
var brain: Node
var chore: RefCounted
var cloth: Node3D
var customer: Node3D
var fire: Node
var ballistics: Node
var label: Label
var cam: Camera3D
var tick := 0
var event_tick := -1
var rec := {"steps": [], "faults": {"below_floor": 0, "in_bar": 0, "flung": 0, "lost_points": 0},
		"frames_ms": [], "brain_us": [], "cloth_us": [], "body_us": []}
var _last_step := -1
var _last_us := 0
var _top_box := AABB()
var _cups: Array = []
var _prev_pts := PackedVector3Array()
var _shots: Array = []
var _match := {}
## Where the camera stands (--cam=): across the bar to his left, in front, close on his hands.
const CAMS := {"side": [Vector3(1.55, 1.7, 1.25), Vector3(-0.05, 1.18, -0.45), 46.0],
		"front": [Vector3(-0.3, 1.75, 2.0), Vector3(0.0, 1.2, -0.5), 40.0],
		"close": [Vector3(0.9, 1.55, 0.6), Vector3(-0.1, 1.25, -0.55), 38.0],
		"behind": [Vector3(1.7, 1.6, -2.3), Vector3(-0.1, 0.75, -0.55), 52.0],
		"right": [Vector3(-1.15, 1.35, -0.45), Vector3(0.0, 1.02, -0.72), 44.0]}


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
	out_dir = String(opts.get("out", "build/barkeep_rag")).path_join(name_)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var prof = load("res://src/debug/prof.gd")
	prof.on = true
	_build_world()
	if opts.has("render"):
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED  # drawn only for the frames kept
	if opts.has("shots"):
		# Stills at these times only (s): the viewport draws nothing in between.
		for x in String(opts.shots).split(","):
			_shots.append(float(x))
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	await process_frame
	await physics_frame
	_spawn()
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
			_caption()
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(out_dir.path_join("s_%05d.png" % tick))
			_last_us = Time.get_ticks_usec()
		elif opts.has("render") and tick % int(opts.get("every", "2")) == 0 and tick >= int(float(opts.get("from", "0")) * 60.0):
			_caption()
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(out_dir.path_join("f_%05d.png" % tick))
			_last_us = Time.get_ticks_usec()
	_write_summary()
	quit()


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
	env.environment.ambient_light_color = Color(0.42, 0.36, 0.3)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 40, 0)
	sun.light_color = Color(1.0, 0.86, 0.68)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	world.add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.6, 2.4, 0.6)
	lamp.light_color = Color(1.0, 0.75, 0.45)
	lamp.light_energy = 1.4
	lamp.omni_range = 5.0
	lamp.shadow_enabled = true
	world.add_child(lamp)
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
	fm.albedo_color = Color(0.3, 0.22, 0.15)
	gm.material_override = fm
	ground.add_child(gm)
	world.add_child(ground)
	ballistics = load("res://src/ballistics/ballistics.gd").new()
	world.add_child(ballistics)
	fire = load("res://src/fire/fire_system.gd").new()
	world.add_child(fire)
	bar = load("res://src/props/prop_kit.gd").spawn(&"bar")
	world.add_child(bar)
	for m in bar.get_members():
		if String(m.member_id).ends_with("top"):
			_top_box = m.world_aabb()
	var lib = load("res://src/props/prop_library.gd")
	for x in [-0.42, 0.55]:
		var cup: Node3D = lib.spawn(&"tin_cup")
		cup.position = Vector3(x, 1.095, -0.12)
		world.add_child(cup)
		_cups.append(cup)
	cam = Camera3D.new()
	world.add_child(cam)
	var c: Array = CAMS.get(String(opts.get("cam", sc.get("cam", "side"))), CAMS.side)
	if c == CAMS.behind or c == CAMS.right:
		var fill := OmniLight3D.new()  # his side of the bar, lit for the camera behind him
		fill.position = Vector3(1.2, 2.3, -1.9)
		fill.light_color = Color(1.0, 0.8, 0.55)
		fill.light_energy = 1.2
		fill.omni_range = 5.0
		world.add_child(fill)
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
	man.shirt_color = Color(0.85, 0.84, 0.8)
	man.vest_color = Color(0.15, 0.14, 0.13)
	man.hat_color = Color(0, 0, 0, 0)
	man.bandana_color = Color(0, 0, 0, 0)
	brain = load("res://src/people/civilian_brain.gd").new()
	brain.name = "Brain"
	brain.post = POST
	brain.faces = FACES
	man.add_child(brain)
	world.add_child(man)
	man.global_position = POST
	man.face(FACES)
	if sc.get("no_cloth", false):
		return
	cloth = load("res://src/props/prop_kit.gd").make(&"bar_cloth")
	world.add_child(cloth)
	await physics_frame
	cloth.hang_on(man, "l")
	chore = load("res://src/people/wipe_bar.gd").new(man, cloth, POST, FACES)
	chore.tuning = chore.tuning.duplicate()
	if sc.has("glass"):
		chore.tuning.glass_chance = float(sc.glass)
	chore.set(&"_rest", 1.0)
	brain.chore = chore


# --- Each tick -----------------------------------------------------------------------------------

func _step(ms: float) -> void:
	var t := tick / 60.0
	rec.frames_ms.append(ms)
	var prof = load("res://src/debug/prof.gd")
	var sums: Dictionary = prof.get(&"_sum")
	rec.brain_us.append(int(sums.get(&"civilian_brain", 0)))
	rec.cloth_us.append(int(sums.get(&"cloth", 0)))
	rec.body_us.append(int(sums.get(&"people_body", 0)) + int(sums.get(&"people_skeleton", 0)))
	sums.clear()
	rec.get_or_add("active", []).append(1 if chore != null and int(chore.step) != 0 else 0)
	if chore != null and int(chore.step) != _last_step:
		_last_step = int(chore.step)
		rec.steps.append([snappedf(t, 0.01), String(chore.Step.keys()[_last_step]).to_lower(), String(chore.stopped)])
	if sc.has("event") and event_tick < 0 and t >= float(sc.at):
		if sc.get("when", "") != "wipe" or (chore != null and int(chore.step) == 3):
			event_tick = tick
			_event()
	if event_tick >= 0 and tick == event_tick + 30 and cloth != null and not cloth.burnt:
		rec.cloth_after_event = str(cloth.centre())
	if opts.has("debug") and chore != null and int(chore.step) == 5 and tick % 20 == 0:
		var cup = chore.get(&"_cup")
		print("glass t=%.2f phase %d palm_l %s cup %s cup_at %s parent %s" % [t, chore.get(&"_phase"), man.palm("l"),
				cup.global_position if cup else null, chore.get(&"_cup_at"), cup.get_parent().name if cup else ""])
	if opts.has("debug") and tick % 300 == 0 and fire != null:
		print("fire t=%.0f burning members %d spills %d smoke fields %d" % [t, fire.burning_members().size(), fire.spills.size(), (fire.get(&"_smoke") as Array).size()])
	if not _match.is_empty() and fire.spills.has(_match):
		fire.move_small_fire(_match, cloth.centre())  # held to it, wherever it goes
	if customer != null:
		_walk_customer()
	if cloth != null:
		_cloth_faults()


func _event() -> void:
	var t := tick / 60.0
	rec.event_t = snappedf(t, 0.01)
	match String(sc.event):
		"customer":
			customer = load("res://src/bodies/human_body.gd").new()
			customer.name = "Customer"
			customer.person_id = &"customer"
			customer.body_model = &"young_drifter_s3_talking"
			customer.rng_seed = 301
			customer.has_gun = false
			world.add_child(customer)
			customer.global_position = Vector3(3.2, 0.0, 2.2)
		"shot":
			var at: Vector3 = cloth.centre() + Vector3(0.12, 0.0, 0.05)
			var from := Vector3(1.6, 1.5, 2.6)
			ballistics.fire(from, (at - from).normalized(), 250.0, 0.0165, 0.0114)
			root.get_node("Events").noise.emit(from, 1.0, &"gunshot", null)
		"drop":
			# Knocked out of his hand, back over his shoulder onto the floor behind the bar.
			cloth.knock(str_to_var("Vector3(%s)" % opts.get("kv", "0, 1, -4")) * 0.035)
		"blast":
			load("res://src/blast/blast.gd").detonate(world, Vector3(2.6, 0.3, 3.6), float(opts.get("kg", "0.03")))
		"fire":
			# A small flame held to it for a few seconds (a lamp's, a match's): nothing else alight.
			_match = fire.small_fire(cloth.centre(), 0.04, 3.0, 0.0)
		"wound":
			var part: Node3D = man.parts[&"abdomen"]
			var side: Vector3 = man.global_basis.x
			var at: Vector3 = part.global_position + side * 0.11 - man.global_basis.z * 0.06
			var dir: Vector3 = (-side * 0.6 + man.global_basis.z * 0.8).normalized()
			rec.wound = man.take_bullet(part, at - dir * 0.05, dir, float(opts.get("joules", "400")), 0.0057).get("segment", "")


func _walk_customer() -> void:
	var t := (tick - event_tick) / 60.0
	var to := Vector3(-0.45, 0.0, 0.8) if t < float(sc.leave) else Vector3(3.6, 0.0, 3.0)
	if customer.global_position.distance_to(to) > 0.15:
		customer.walk_to(to, 1.2, 1.0 / 60.0)
	else:
		customer.face(Vector3(0.0, 1.5, -0.7))
	customer.set_pose(&"stand")


func _cloth_faults() -> void:
	var n: int = cloth.point_count()
	var pts := PackedVector3Array()
	var below := false
	var inside := false
	var flung := false
	var lo := INF
	var free: bool = int(cloth.held) == 0
	for i in n:
		var p: Vector3 = cloth.point(i)
		pts.append(p)
		lo = minf(lo, p.y)
		if not p.is_finite():
			rec.faults.lost_points += 1
			continue
		if p.y < -0.01:
			below = true
		if free and _top_box.grow(-0.012).has_point(p):
			inside = true
		if _prev_pts.size() == n and p.distance_to(_prev_pts[i]) * 60.0 > 20.0:
			flung = true
			if opts.has("debug"):
				print("flung t=%.2f point %d pinned %s from %s to %s held %d" % [tick / 60.0, i, cloth.pinned_points().has(i), _prev_pts[i], p, int(cloth.held)])
	_prev_pts = pts
	if below:
		rec.faults.below_floor += 1
	if inside:
		rec.faults.in_bar += 1
	if flung:
		rec.faults.flung += 1
		if rec.get_or_add("flung_t", []).size() < 12:
			rec.flung_t.append(snappedf(tick / 60.0, 0.01))
	rec.cloth_lowest = minf(float(rec.get("cloth_lowest", INF)), lo)


func _caption() -> void:
	var lines := []
	lines.append("%s   %.1f s" % [String(sc.get("note", name_)), tick / 60.0])
	if chore != null:
		lines.append("chore: %s   cloth: %s%s%s" % [String(chore.Step.keys()[int(chore.step)]).to_lower(),
				["free", "in his hand", "over his shoulder"][int(cloth.held)] if not cloth.burnt else "burnt away",
				"   burning" if cloth.burning else "", "   blood %.0f ml" % cloth.blood_ml if cloth.blood_ml > 0.0 else ""])
	var k := 30
	if rec.brain_us.size() > k:
		var b := 0.0
		var c := 0.0
		for i in range(rec.brain_us.size() - k, rec.brain_us.size()):
			b += rec.brain_us[i]
			c += rec.cloth_us[i]
		lines.append("brain + chore %.3f ms, cloth %.3f ms a tick (this core)" % [b / k / 1000.0, c / k / 1000.0])
	label.text = "\n".join(lines)


func _write_summary() -> void:
	var s := {"scenario": name_, "seconds": tick / 60.0, "steps": rec.steps, "faults": rec.faults}
	for k in ["event_t", "wound", "cloth_lowest", "flung_t", "cloth_after_event"]:
		if rec.has(k):
			s[k] = rec[k]
	if chore != null:
		s.chore = {"cycles": chore.cycles, "stretches": chore.wiped, "cups": chore.cups, "stopped": String(chore.stopped),
				"step": String(chore.Step.keys()[int(chore.step)]).to_lower()}
	if cloth != null:
		# Its texture as it ends (the blood's on the side against him, the char spread from where it caught).
		var img: Image = (cloth.get(&"_image") as Image).duplicate()
		img.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
		img.save_png(out_dir.path_join("cloth_texture.png"))
		s.cloth = {"held": ["free", "hand", "shoulder"][int(cloth.held)], "burning": cloth.burning, "burnt": cloth.burnt,
				"blood_ml": snappedf(cloth.blood_ml, 0.1), "bloodiness": snappedf(cloth.bloodiness(), 0.001),
				"centre": str(cloth.centre()) if not cloth.burnt else ""}
	s.barkeep = {"mood": String(brain.Mood.keys()[int(brain.mood)]).to_lower(), "at": str(man.global_position),
			"limp": man.limp}
	var skip := 120  # the first two seconds: loading
	s.ms = {"frame_mean": _mean(rec.frames_ms, skip), "brain_mean": _mean(rec.brain_us, skip) / 1000.0,
			"brain_max": _max(rec.brain_us, skip) / 1000.0, "cloth_mean": _mean(rec.cloth_us, skip) / 1000.0,
			"cloth_max": _max(rec.cloth_us, skip) / 1000.0, "body_mean": _mean(rec.body_us, skip) / 1000.0,
			"note": "this workspace's core (2.1 GHz); x0.65 for Sean's"}
	# While he's at it (the chore's steps, not idle): what the work itself costs.
	var on := []
	for i in rec.active.size():
		if rec.active[i] == 1:
			on.append(i)
	if not on.is_empty():
		var pick := func(a: Array) -> Array: return on.map(func(i: int) -> float: return float(a[i]))
		s.ms_working = {"ticks": on.size(), "frame_mean": _mean(pick.call(rec.frames_ms)),
				"brain_mean": _mean(pick.call(rec.brain_us)) / 1000.0, "cloth_mean": _mean(pick.call(rec.cloth_us)) / 1000.0,
				"body_mean": _mean(pick.call(rec.body_us)) / 1000.0}
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


func _max(a: Array, skip := 0) -> float:
	var m := 0.0
	for i in range(skip, a.size()):
		m = maxf(m, float(a[i]))
	return m
