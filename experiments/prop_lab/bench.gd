extends SceneTree
## (Untyped where it names the game's autoloads: -s scripts compile before the autoloads exist.)
## The prop lab's bench (docs/briefs/prop-lab.md, experiments/prop_lab/README.md): one kit prop on
## a floor of boards, one scenario from scenarios.json (the breakage lab's set, fire, a seated man
## whose chair is shot or kicked from under him), measured every physics tick; a summary, and with
## --render a frame at set moments after the event.
##
##   godot --headless --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- --scenario=NAME --out=DIR
##       [--model=bold_cowboy_s0] [--seed=1] [--seconds=6]
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/prop_lab/bench.gd -- \
##       --scenario=NAME --out=DIR --render
##   ... -- --look --out=DIR   # the kit's props beside PropModels' and a Studio man (the look sheet)
##
## Writes DIR/<scenario>/summary.json (and f_<ms>.png with --render).

const SCENARIOS := "res://experiments/prop_lab/scenarios.json"
## Where the floor's top is (m): boards on joists, as a room's.
const FLOOR_TOP := 0.3
## Seconds before the event (the man sits, the world settles).
const LEAD := 1.5
## Moments after the event a frame is taken (s; the first before it).
const SHOTS := [-0.3, 0.0, 0.08, 0.2, 0.35, 0.55, 0.8, 1.2, 2.0, 3.5]

var opts := {}
var sc := {}
var out_dir := ""
var vp: SubViewport
var world: Node3D
var prop: Node3D  # KitProp
var man: Node3D  # HumanBody
var lamp: Node3D
## The glass props put on it (scenario "glass": [{"id", "at", "lit"}]), and what they let go.
var glass: Array = []
var stack: Array = []  # more kit props, stood on the prop or beside it (crates, barrels)
var spilled: Array = []
var fire: Node
var ballistics: Node
var cam: Camera3D
var tick := 0
var event_tick := -1
var rng := RandomNumberGenerator.new()
var rec := {"loose_t": null, "limp_t": null, "max_piece_speed": 0.0, "faults": {"sunk": 0, "below_ground": 0, "flung": 0, "part_fast": 0},
		"caught": [], "consumed": [], "frames_ms": []}
var _shots_left: Array = []
var _last_us := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1] if kv.size() > 1 else "true"
	out_dir = opts.get("out", "build/prop_lab")
	rng.seed = int(opts.get("seed", "1"))
	if opts.has("look"):
		await _look()
		quit()
		return
	if opts.has("perf"):
		await _perf(String(opts.perf))
		quit()
		return
	var all: Array = JSON.parse_string(FileAccess.get_file_as_string(SCENARIOS)).scenarios
	if opts.get("scenario", "list") == "list":
		for s: Dictionary in all:
			print(s.name)
		quit()
		return
	for s: Dictionary in all:
		if s.name == opts.scenario:
			sc = s
	if sc.is_empty():
		push_error("no scenario %s" % opts.get("scenario"))
		quit(1)
		return
	out_dir = out_dir.path_join(sc.name)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_build_world()
	await _place_prop()
	if sc.get("seated", false):
		_seat_man()
	if sc.event.do == "drop_man":
		_hold_man(float(sc.event.get("height", 1.0)))
	var seconds := float(opts.get("seconds", sc.get("seconds", 6.0)))
	var total := int((LEAD + seconds) * 60.0)
	for s in SHOTS:
		_shots_left.append(int((LEAD + float(s)) * 60.0))
	root.get_node("Events").bullet_hit.connect(_on_hit)
	_last_us = Time.get_ticks_usec()
	while tick < total:
		await physics_frame
		var now := Time.get_ticks_usec()
		var ms := (now - _last_us) / 1000.0
		_last_us = now
		_step(ms)
		tick += 1
		if opts.has("render") and not _shots_left.is_empty() and tick >= int(_shots_left[0]):
			_shots_left.pop_front()
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(out_dir.path_join("f_%05d.png" % int(round((tick / 60.0 - LEAD) * 1000.0 + 1000.0))))
			_last_us = Time.get_ticks_usec()
	_write_summary()
	quit()


# --- The world -----------------------------------------------------------------------------------

func _build_world() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(960, 640)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	world.name = "Bench"
	vp.add_child(world)
	_lights(Color(1.0, 0.84, 0.64))
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	world.add_child(ground)
	# The floor: 4 x 4 m of boards on joists, a room's.
	var floor_s = load("res://src/structures/structure.gd").new()
	floor_s.name = "bench_floor"
	floor_s.structure_id = &"bench_floor"
	world.add_child(floor_s)
	for x in [-1.8, -0.6, 0.6, 1.8]:
		floor_s.add_member("joist%d" % int(x * 10), &"joist", &"framing", Vector3(0.05, 0.25, 4.0), Vector3(x, 0.125, 0))
	for i in 16:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(4.0, 0.05, 0.25), Vector3(0, 0.275, -1.875 + 0.25 * i))
	floor_s.infer_supports()
	ballistics = load("res://src/ballistics/ballistics.gd").new()
	world.add_child(ballistics)
	fire = load("res://src/fire/fire_system.gd").new()
	world.add_child(fire)
	world.add_child(load("res://src/structures/fittings.gd").new())
	cam = Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(-1.5, 1.2, 1.75)
	cam.look_at(Vector3(0.1, FLOOR_TOP + 0.45, 0))
	cam.fov = 50
	cam.current = true


func _lights(colour: Color) -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.09, 0.07)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.45, 0.38, 0.32)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_color = colour
	sun.shadow_enabled = true
	world.add_child(sun)


func _place_prop() -> void:
	if String(sc.prop) == "":
		# The floor alone (a frame-time baseline): a prop of no members.
		prop = load("res://src/props/kit_prop.gd").new()
		prop.structure_id = &"bench_prop"
		world.add_child(prop)
		for i in 6:
			await physics_frame
		return
	prop = load("res://src/props/prop_kit.gd").spawn(StringName(sc.prop), &"bench_prop")
	prop.position = Vector3(0, FLOOR_TOP, 0)
	world.add_child(prop)
	if sc.get("lamp", false):
		# In a structure's Props, as the saloon's lamps are, so Fittings takes it (it brings things
		# down when what they stand on goes).
		lamp = load("res://src/world/oil_lamp.gd").new()
		lamp.name = "TableLamp"
		_props_node().add_child(lamp)
		lamp.global_position = prop.global_position + Vector3(0.12, 0.761, -0.1)
		lamp.set_lit(true)
	for e: Dictionary in sc.get("stack", []):
		var k = load("res://src/props/prop_kit.gd").spawn(StringName(e.id), StringName("bench_stack%d" % stack.size()))
		k.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.get("yaw", 0.0)))), Vector3(0, FLOOR_TOP, 0) + _v(e.at))
		world.add_child(k)
		stack.append(k)
	for e: Dictionary in sc.get("glass", []):
		var g = load("res://src/props/prop_kit.gd").make(StringName(e.id))
		_props_node().add_child(g)
		g.global_position = Vector3(0, FLOOR_TOP, 0) + _v(e.at)
		if e.get("lit", false):
			var light = load("res://src/world/oil_lamp.gd").new()
			light.name = "Light"
			light.show_mesh = false
			g.add_child(light)
			light.position.y = 0.04
			light.set_lit(true)
		glass.append(g)
	root.get_node("Events").liquid_spilled.connect(func(at: Vector3, liquid: StringName, litres: float, _src: Node) -> void:
		spilled.append({"liquid": String(liquid), "litres": litres, "t": snappedf((tick - event_tick) / 60.0, 0.01)}))
	for i in 6:
		await physics_frame


## A "Props" node in the floor's structure, as a building's: Fittings looks there.
func _props_node() -> Node3D:
	var fl := world.get_node("bench_floor")
	var props := fl.get_node_or_null("Props") as Node3D
	if props == null:
		props = Node3D.new()
		props.name = "Props"
		fl.add_child(props)
	return props


func _member(id: String) -> Node:
	return prop.get_member(StringName("bench_prop/%s" % id))


## A Studio man sat in the chair, facing the way it does: posed sitting, his weight on the seat.
func _seat_man() -> void:
	man = load("res://src/bodies/human_body.gd").new()
	man.name = "Seated"
	man.body_model = StringName(opts.get("model", "bold_cowboy_s0"))
	man.has_gun = false
	man.start_holstered = true
	man.rng_seed = int(opts.get("seed", "1"))
	man.person_id = &"bench_man"
	var at: Vector3 = prop.global_transform * Vector3(0, 0, -0.03)
	man.global_transform = Transform3D(prop.global_basis * Basis(Vector3.UP, PI), at)
	world.add_child(man)
	man.set_pose(&"sit")


# --- Each tick -----------------------------------------------------------------------------------

func _step(ms: float) -> void:
	var t := tick / 60.0
	if man and not man.limp and event_tick < 0:
		man.set_pose(&"sit")
		if tick == int(1.0 * 60.0):
			prop.sit(man)
			rec.seat_h = snappedf((man.parts[&"pelvis"] as Node3D).global_position.y - FLOOR_TOP, 0.001)
	if tick == int(LEAD * 60.0):
		event_tick = tick
		rec.kg = prop.mass()
		_event()
	if event_tick >= 0:
		var since := (tick - event_tick) / 60.0
		rec.frames_ms.append(ms)
		if rec.loose_t == null and prop.loose:
			rec.loose_t = snappedf(since, 0.001)
		if man and rec.limp_t == null and man.limp:
			rec.limp_t = snappedf(since, 0.001)
	else:
		rec.get_or_add("before_ms", []).append(ms)
	_faults()
	rec.fire_spills_max = maxi(int(rec.get("fire_spills_max", 0)), (fire.get(&"spills") as Array).size())
	for i in glass.size():
		if glass[i].broken and not rec.get_or_add("glass_broken_t", {}).has(i):
			rec.glass_broken_t[i] = snappedf((tick - event_tick) / 60.0, 0.01) if event_tick >= 0 else -1.0
	for m in prop.get_members():
		if m.burning and not rec.caught.has(String(m.member_id)):
			rec.caught.append(String(m.member_id))
		if m.consumed and not rec.consumed.has(String(m.member_id)):
			rec.consumed.append(String(m.member_id))
			rec.get_or_add("consumed_t", []).append(snappedf(t - LEAD, 0.1))


func _faults() -> void:
	for r in prop.rubble:  # (untyped: burnt-away rubble is freed in place)
		if not is_instance_valid(r):
			continue
		var rb := r as RigidBody3D
		var v := rb.linear_velocity.length()
		rec.max_piece_speed = maxf(rec.max_piece_speed, v)
		if v > 20.0 and rb.mass > 0.5:
			rec.faults.flung += 1
			if not rec.has("flung_first"):
				rec.flung_first = {"t": snappedf((tick - event_tick) / 60.0, 0.001), "speed": snappedf(v, 0.1), "kg": snappedf(rb.mass, 0.1),
						"members": (rb.get_meta(&"members", []) as Array).map(func(x): return String(x).trim_prefix("bench_prop/")),
						"y": snappedf(rb.global_position.y, 0.01)}
		if rb.global_position.y < -0.05:
			rec.faults.below_ground += 1
	if man and man.limp:
		for sid: StringName in man.parts:
			var p := man.parts[sid] as Node3D
			if p is RigidBody3D and (p as RigidBody3D).linear_velocity.length() > 12.0:
				rec.faults.part_fast += 1
			if p.global_position.y < FLOOR_TOP - 0.06 and absf(p.global_position.x) < 1.8 and absf(p.global_position.z) < 1.8:
				rec.faults.sunk += 1


# --- The events ----------------------------------------------------------------------------------

func _event() -> void:
	var e: Dictionary = sc.event
	match String(e.do):
		"shoot":
			var target: Node3D = glass[int(e.at_glass)].body if e.has("at_glass") else _member(e.at_member)
			var aim := target.global_position
			if e.has("at_glass"):
				aim += Vector3.UP * float(e.get("height", 0.12))
			elif e.has("height"):
				aim.y = FLOOR_TOP + float(e.height)
			var from: Vector3 = prop.global_transform * _v(e.from)
			var dir := (aim - from).normalized()
			if e.weapon == "shotgun":
				var t = load("res://config/shotgun.tres")
				ballistics.fire_charge(from, dir, t.pellets, deg_to_rad(t.pattern_degrees), t.muzzle_velocity, t.pellet_mass, t.pellet_diameter, [] as Array[RID], rng)
			else:
				var t = load("res://config/revolver.tres")
				ballistics.fire(from, dir, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
		"dynamite":
			var blast = load("res://src/blast/blast.gd")
			blast.detonate(world, prop.global_transform * _v(e.at), blast.t().tnt_per_stick)
		"kick":
			var m: Node3D = _member(e.at_member)
			var at := Vector3(m.global_position.x, FLOOR_TOP + float(e.get("height", 0.12)), m.global_position.z)
			rec.kick = prop.take_blow(m, at, prop.global_basis * _v(e.impulse))
		"drop_man":
			man.go_limp()
		"burn":
			fire.set_physics_process(true)
			for id: String in e.ignite:
				fire.ignite(_member(id))


## A man on his back, his middle `h` over the prop's top (the breakage lab's man_on_table), held
## there till the event lets him drop limp.
func _hold_man(h: float) -> void:
	man = load("res://src/bodies/human_body.gd").new()
	man.name = "Dropped"
	man.body_model = StringName(opts.get("model", "bold_cowboy_s0"))
	man.has_gun = false
	man.rng_seed = int(opts.get("seed", "1"))
	man.person_id = &"bench_dropped"
	var top := 0.0
	for m in (prop.get_members() if prop else []):
		top = maxf(top, m.structure_aabb().end.y)
	# Lying on his back: his front up, his head toward +Z; his pelvis ~0.95 m up his own body.
	var b := Basis(Vector3.RIGHT, PI * 0.5)
	man.global_transform = Transform3D(b, Vector3(0, FLOOR_TOP + top + h, -0.95))
	world.add_child(man)


func _on_hit(info: Dictionary) -> void:
	var what := String(info.get("member_id", ""))
	if what == "" and info.has("segment"):
		what = "man:" + String(info.segment)
	elif what == "" and info.get("collider") is Node:
		what = String((info.collider as Node).name)
	rec.get_or_add("hits", []).append({"what": what.trim_prefix("bench_prop/"), "through": info.get("penetrated", false),
			"j_in": snappedf(float(info.get("energy_before", 0.0)), 1.0)})


func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


# --- The summary ---------------------------------------------------------------------------------

func _write_summary() -> void:
	var snapped: Array[String] = []
	for m in prop.get_members():
		if m.has_meta(&"snapped") or (m.broken and not prop.loose and not m.consumed):
			snapped.append(String(m.member_id).trim_prefix("bench_prop/"))
	var pieces := 0
	var farthest := 0.0
	var biggest: RigidBody3D = null
	for rb in prop.rubble:
		if is_instance_valid(rb) and (biggest == null or (rb as RigidBody3D).mass > biggest.mass):
			biggest = rb
	for rb in prop.rubble:
		if is_instance_valid(rb):
			pieces += 1
			farthest = maxf(farthest, Vector2((rb as Node3D).global_position.x, (rb as Node3D).global_position.z).length())
	var frames: Array = rec.frames_ms
	var before: Array = rec.get("before_ms", [0.0])
	var mean_before := _mean(before.slice(maxi(before.size() - 60, 0)))
	var out := {
		"scenario": sc.name, "prop": sc.prop, "members": prop.member_count(), "snapped": snapped,
		"loose": prop.loose, "loose_t": rec.loose_t,
		"upright": biggest == null or biggest.global_basis.y.y > 0.8, "pieces": pieces, "farthest_m": snappedf(farthest, 0.01),
		"max_piece_speed": snappedf(rec.max_piece_speed, 0.01), "caught": rec.caught, "consumed": rec.consumed,
		"consumed_t": rec.get("consumed_t", []), "faults": rec.faults,
		"frame": {"event_ms": snappedf(_max(frames.slice(0, 2)), 0.01),
				"settle_ms": snappedf(_max(frames.slice(2, 12)), 0.01),
				"added_ms_first_1s": snappedf(_mean(frames.slice(0, 60)) - mean_before, 0.01),
				"before_ms": snappedf(mean_before, 0.01)},
	}
	if rec.has("hits"):
		out.hits = rec.hits
	if not glass.is_empty():
		var gl := []
		for i in glass.size():
			gl.append({"id": String(glass[i].kit_id), "broken": glass[i].broken, "loose": glass[i].loose,
					"broken_t": rec.get("glass_broken_t", {}).get(i)})
		out.glass = gl
		out.spilled = spilled
		out.shards = get_nodes_in_group(&"glass_shards").size()
		out.fire_spills = int(rec.get("fire_spills_max", 0))
	if not stack.is_empty():
		out.stack = stack.map(func(k: Node) -> Dictionary: return {"id": String(k.kit_id), "loose": k.loose,
				"snapped": k.get_members().filter(func(m: Node) -> bool: return m.has_meta(&"snapped") or m.broken).size()})
	if rec.has("flung_first"):
		out.flung_first = rec.flung_first
	if rec.has("kick"):
		out.kick = rec.kick
	if prop.has_meta(&"blast_push"):
		var bp: Vector3 = prop.get_meta(&"blast_push")
		out.blast_push = [snappedf(bp.x, 0.1), snappedf(bp.y, 0.1), snappedf(bp.z, 0.1)]
		out.blast_v = snappedf(bp.length() / maxf(float(rec.get("kg", 1.0)), 0.1), 0.01)
	if sc.get("lamp", false):
		out.lamp = {"smashed": not is_instance_valid(lamp) or bool(lamp.get(&"broken")), "spills": (fire.get(&"spills") as Array).size()}
	if man:
		var pelvis := man.parts[&"pelvis"] as Node3D
		out.man = {"limp": man.limp, "limp_t": rec.limp_t, "seat_h": rec.get("seat_h"),
				"pelvis_end": [snappedf(pelvis.global_position.x, 0.01), snappedf(pelvis.global_position.y - FLOOR_TOP, 0.01), snappedf(pelvis.global_position.z, 0.01)],
				"on_floor": pelvis.global_position.y - FLOOR_TOP < 0.3}
	var fp := []
	for rb in prop.rubble:
		if is_instance_valid(rb):
			fp.append((rb as Node3D).global_position.snappedf(0.01))
	if man:
		fp.append((man.parts[&"pelvis"] as Node3D).global_position.snappedf(0.01))
	out.fingerprint = hash(str(fp))
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	print(JSON.stringify(out))


func _mean(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for x in a:
		s += float(x)
	return s / a.size()


func _max(a: Array) -> float:
	var m := 0.0
	for x in a:
		m = maxf(m, float(x))
	return m


# --- The look sheet ------------------------------------------------------------------------------

## The kit's chair and table (right) beside PropModels' (left), a Studio man between, in lamplight
## and daylight: DIR/look_<light>_<view>.png.
func _look() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	vp = SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 8)
	floor_mi.mesh = plane
	floor_mi.material_override = load("res://src/structures/wood_materials.gd").get_material(&"floor", 1)
	world.add_child(floor_mi)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	world.add_child(ground)
	var lib = load("res://src/props/prop_library.gd")
	var kit = load("res://src/props/prop_kit.gd")
	var props := String(opts.get("props", "")).split(",", false)
	if Array(props).any(func(id: String) -> bool: return lib.definition(StringName(id)).get("anchor", "floor") == "wall"):
		# A boarded wall to hang them on, its face at z = -0.8.
		var wall := StaticBody3D.new()
		var wcs := CollisionShape3D.new()
		var wbox := BoxShape3D.new()
		wbox.size = Vector3(12, 4, 0.1)
		wcs.shape = wbox
		wall.add_child(wcs)
		var wmi := MeshInstance3D.new()
		wmi.mesh = MemberMesh.box(Vector3(12, 4, 0.1))
		wmi.material_override = load("res://src/structures/wood_materials.gd").get_material(&"int_boards", 0)
		wall.add_child(wmi)
		wall.position = Vector3(0, 2.0, -0.85)
		world.add_child(wall)
	for side in [-1.0, 1.0]:
		var base := Vector3(side * 1.25, 0, 0)
		if not props.is_empty():
			# `--props=a,b,c`: those in a row each side instead of the table and chairs.
			for i in props.size():
				var id := StringName(props[i])
				var p: Node3D = lib.spawn(id) if side < 0 else kit.make(id)
				var x := (i - (props.size() - 1) * 0.5) * 0.75
				if lib.definition(id).get("anchor", "floor") == "wall":
					# Hung on the wall behind, at eye height.
					p.transform = Transform3D(Basis.IDENTITY, base + Vector3(x, 1.55 + 0.25 * (i % 2), -0.8))
				else:
					p.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(15.0 * i)), base + Vector3(x, 0, -0.4 + 0.2 * (i % 2)))
				world.add_child(p)
			continue
		var table: Node3D = lib.spawn(&"card_table") if side < 0 else kit.spawn(&"card_table")
		if side > 0 and opts.has("nobatch"):
			table.batch_meshes = false
		table.position = base + Vector3(0, 0, -0.4)
		world.add_child(table)
		for k in 2:
			var chair: Node3D = lib.spawn(&"chair") if side < 0 else kit.spawn(&"chair")
			var a := deg_to_rad(-40.0 + 80.0 * k + (0.0 if side < 0 else 180.0))
			chair.transform = Transform3D(Basis(Vector3.UP, a + PI), base + Vector3(sin(a), 0, cos(a)) * 0.85 + Vector3(0, 0, -0.4))
			world.add_child(chair)
	var m = load("res://src/bodies/human_body.gd").new()
	m.body_model = StringName(opts.get("model", "bold_cowboy_s0"))
	m.has_gun = false
	m.person_id = &"look_man"
	m.global_transform = Transform3D(Basis(Vector3.UP, 0.0), Vector3(0, 0, 0.3))
	world.add_child(m)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	world.add_child(sun)
	var lamp_light := OmniLight3D.new()
	lamp_light.position = Vector3(0, 2.2, 0.6)
	lamp_light.omni_range = 7.0
	lamp_light.light_color = Color(1.0, 0.74, 0.48)
	lamp_light.shadow_enabled = true
	world.add_child(lamp_light)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true
	for light in ["lamp", "day"]:
		if light == "lamp":
			env.environment.background_color = Color(0.08, 0.06, 0.05)
			env.environment.ambient_light_color = Color(0.25, 0.2, 0.17)
			sun.light_energy = 0.15
			sun.rotation_degrees = Vector3(-55, 20, 0)
			lamp_light.light_energy = 2.2
		else:
			env.environment.background_color = Color(0.55, 0.6, 0.68)
			env.environment.ambient_light_color = Color(0.5, 0.47, 0.42)
			sun.light_energy = 1.2
			sun.light_color = Color(1.0, 0.9, 0.75)
			sun.rotation_degrees = Vector3(-35, 40, 0)
			lamp_light.light_energy = 0.0
		for view in ["wide", "close"]:
			if view == "wide":
				cam.position = Vector3(0, 1.6, 3.6)
				cam.look_at(Vector3(0, 0.75, -0.2))
				cam.fov = 50
			else:
				cam.position = Vector3(0, 1.15, 1.9)
				cam.look_at(Vector3(0, 0.6, -0.4))
				cam.fov = 55
			for i in 10:
				await process_frame
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(out_dir.path_join("look_%s_%s.png" % [light, view]))


# --- The budget ----------------------------------------------------------------------------------

## The saloon's set of furniture (two card tables, four chairs at each, as SaloonBuilding places
## them) as kit props (`kit`) or PropLibrary's drawn props through StaticBatch (`lib`), untouched:
## physics-frame time and, rendered, draw calls. DIR/perf_<which>.json.
func _perf(which: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	_build_world()
	var lib = load("res://src/props/prop_library.gd")
	var kit = load("res://src/props/prop_kit.gd")
	var room := Node3D.new()
	room.name = "Props"
	world.add_child(room)
	if opts.get("set", "") == "stores":
		# The town's barrels, crates and bar stools (14, 12 with four stacked, 7) on a 4 x 4 m floor.
		var n := 0
		for id: StringName in [&"barrel", &"crate", &"bar_stool"]:
			var count: int = {&"barrel": 14, &"crate": 8, &"bar_stool": 7}[id]
			for i in count:
				var at := Vector3(-1.6 + 0.65 * (n % 6), FLOOR_TOP, -1.6 + 0.65 * (n / 6))
				n += 1
				var p: Node3D = kit.spawn(id) if which == "kit" else lib.spawn(id)
				p.position = at
				room.add_child(p)
				if id == &"crate" and i < 4:
					var up: Node3D = kit.spawn(id) if which == "kit" else lib.spawn(id)
					up.position = at + Vector3(0, 0.6, 0)
					room.add_child(up)
	for t: Vector3 in ([] if opts.get("set", "") == "stores" else [Vector3(-0.9, FLOOR_TOP, -0.6), Vector3(0.9, FLOOR_TOP, 0.8)]):
		var table: Node3D = kit.spawn(&"card_table") if which == "kit" else lib.spawn(&"card_table")
		table.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(15.0)), t)
		room.add_child(table)
		for k in 4:
			var a := deg_to_rad(15.0 + 90.0 * k)
			var chair: Node3D = kit.spawn(&"chair") if which == "kit" else lib.spawn(&"chair")
			chair.transform = Transform3D(Basis(Vector3.UP, a + PI), t + Vector3(sin(a), 0.0, cos(a)) * 0.85)
			room.add_child(chair)
	# A back bar's worth of bottles and a lamp on each table: the kit's glass props, or the drawn ones.
	for i in (0 if opts.get("set", "") == "stores" else 24):
		var at := Vector3(-1.8 + 0.15 * i, FLOOR_TOP, -1.6)
		var b: Node3D = kit.make(&"whiskey_bottle") if which == "kit" else lib.spawn(&"whiskey_bottle")
		b.position = at
		room.add_child(b)
	for t: Vector3 in ([] if opts.get("set", "") == "stores" else [Vector3(-0.9, FLOOR_TOP, -0.6), Vector3(0.9, FLOOR_TOP, 0.8)]):
		var l: Node3D = kit.make(&"oil_lamp") if which == "kit" else lib.spawn(&"oil_lamp")
		l.position = t + Vector3(0.1, 0.761, -0.1)
		room.add_child(l)
	# StaticBatch for both: the drawn props, and the kit's glass standing.
	var batch = load("res://src/world/static_batch.gd").new()
	batch.target = NodePath("..")
	room.add_child(batch)
	cam.position = Vector3(-3.2, 2.2, 3.4)
	cam.look_at(Vector3(0, FLOOR_TOP + 0.4, 0))
	for i in 30:
		await physics_frame
	var frames: Array = []
	var draws: Array = []
	var last := Time.get_ticks_usec()
	for i in 600:
		await physics_frame
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		if opts.has("render") and i % 60 == 0:
			await RenderingServer.frame_post_draw
			draws.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			last = Time.get_ticks_usec()
	var bodies := room.find_children("*", "StaticBody3D", true, false).size()
	var out := {"which": which, "frame_ms": snappedf(_mean(frames), 0.001), "worst_ms": snappedf(_max(frames), 0.01),
			"static_bodies": bodies, "draws": draws}
	var f := FileAccess.open(out_dir.path_join("perf_%s%s.json" % [which, "_" + String(opts.get("set")) if opts.has("set") else ""]), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	print(JSON.stringify(out))
