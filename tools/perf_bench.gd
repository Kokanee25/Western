extends SceneTree
## The performance bench: the real game (main scene, test street) with the townsfolk and the gang
## in, run for a while in two scenes, (a) the calm street and (b) the street after dynamite, with
## buildings burning and rubble down. For each: average and 99th-percentile frame time, Godot's
## monitors (process/physics time, objects, physics bodies, draw calls when rendering), a census
## of what's in the scene, and what each system costs, found by switching it off for a while and
## seeing what the frame saves ("ablation": it catches what a system makes others do as well).
##
##   godot --headless --fixed-fps 60 -s res://tools/perf_bench.gd -- [--seconds=30] [--out=file.json]
##   xvfb-run -a godot --rendering-driver opengl3 --fixed-fps 60 -s res://tools/perf_bench.gd -- --render
## --quick: shorter runs and no ablation (for the CI guard). --no-ablate: full length, no ablation.
## --scene=calm|fire: just one; --scene=blaze: the fire left 45 s first, till the whole town
## burns; --scene=wall: a shotgun charge into the store's front from 3 m every half second while it
## measures (voxel damage, docs/DESTRUCTION_BRIEF.md step 2); --no-voxels: drawn holes instead.
## --spikes=MS: each frame longer than that, with what each system took in it. "timed" is each system's own frame entries (Prof), the rest is
## the engine's (physics, culling, the scene tree) and anything not timed. Godot's process/physics time monitors read nonsense headless (the
## loop's not paced), so the frame is wall clock; draw calls and render CPU need --render.
## Untyped on purpose: -s scripts compile before autoloads exist.

var seconds := 30.0
var quick := false
var ablate := true
var render := false
var only := ""
var out_path := ""
var main: Node
var street: Node
var report := {}
var _voxel_tuning: Resource
## Print frames longer than this (ms) with what each system took in them (0 = off).
var spikes := 0.0
## Each scene against config/frame_budget.tres (off with --no-budget, and with --quick).
var budget_report := true
## Leave out the render time read (viewport_get_measured_render_time_cpu makes a separate render
## thread wait for the main one every frame, so it hides what the thread gains): --no-render-time.
var render_time := true


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			seconds = float(a.substr(10))
		elif a == "--quick":
			quick = true
			ablate = false
		elif a == "--no-ablate":
			ablate = false
		elif a == "--render":
			render = true
		elif a.begins_with("--scene="):
			only = a.substr(8)
		elif a.begins_with("--out="):
			out_path = a.substr(6)
		elif a == "--no-budget":
			budget_report = false
		elif a == "--no-render-time":
			render_time = false
		elif a.begins_with("--spikes="):
			spikes = float(a.substr(9))
		elif a == "--no-smoke":
			# Fire's smoke as the old particles, no SmokeField (the cost of the smoke).
			(load("res://config/fire.tres") as FireTuning).smoke_fields = 0
		elif a == "--no-voxels":
			# Before voxel damage: holes drawn by the shader (as without the plugin).
			_voxel_tuning = load("res://config/voxel_damage.tres")  # kept: the members load the same
			_voxel_tuning.set(&"enabled", false)
	if quick:
		seconds = minf(seconds, 8.0)
		budget_report = false
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Frame times (ms) over `n` frames, wall clock, plus the monitors averaged.
func _measure(n: int) -> Dictionary:
	var times := PackedFloat32Array()
	var mon := {"render_cpu_ms": 0.0, "draw_calls": 0.0, "objects_in_frame": 0.0, "process_ms": 0.0, "physics_ms": 0.0}
	var vp: Viewport = main.get_node_or_null(^"GameViewport") if main else null
	var vp_rid: RID = vp.get_viewport_rid() if vp and render_time else RID()
	if vp_rid.is_valid():
		RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var prof = load("res://src/debug/prof.gd")
	prof.on = true
	await process_frame
	prof.roll()
	var last := Time.get_ticks_usec()
	var before := {}
	for i in n:
		await process_frame
		prof.frame(1 << 30)
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		if spikes > 0.0:
			# What each system took in this frame, for frames over the limit.
			var sums: Dictionary = prof._sum.duplicate()
			if (now - last) / 1000.0 > spikes:
				var parts := []
				for k in sums:
					var d: float = (float(sums[k]) - float(before.get(k, 0))) / 1000.0
					if d > 0.5:
						parts.append("%s %.1f" % [k, d])
				print("   spike: frame %d %.1f ms: %s" % [i, (now - last) / 1000.0, ", ".join(parts)])
			before = sums
		last = now
		mon.draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME) / n
		mon.objects_in_frame += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME) / n
		# The main thread's own work (meaningless headless: the loop isn't paced).
		mon.process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0 / n
		mon.physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0 / n
		if vp_rid.is_valid():
			mon.render_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) / n
	var sorted := times.duplicate()
	sorted.sort()
	var avg := 0.0
	for t in times:
		avg += t / times.size()
	prof.roll()
	prof.on = false
	var out := {"systems_ms": prof.per_frame.duplicate(), "avg_ms": avg, "p99_ms": sorted[int(sorted.size() * 0.99) - 1] if sorted.size() > 1 else avg,
			"max_ms": sorted[sorted.size() - 1]}
	out.merge(mon)
	return out


func _census() -> Dictionary:
	var c := {}
	var count := func(key: String) -> void: c[key] = int(c.get(key, 0)) + 1
	for n in street.find_children("*", "", true, false):
		if n is MeshInstance3D:
			count.call("meshes")
			if (n as MeshInstance3D).is_visible_in_tree():
				count.call("meshes_visible")
		elif n is MultiMeshInstance3D:
			count.call("multimeshes")
		elif n is GPUParticles3D or n is CPUParticles3D:
			count.call("particles")
		elif n is Light3D:
			count.call("lights")
		if n is RigidBody3D:
			count.call("rigid_bodies")
			if not (n as RigidBody3D).sleeping and not (n as RigidBody3D).freeze:
				count.call("rigid_awake")
		elif n is StaticBody3D:
			count.call("static_bodies")
		elif n is AnimatableBody3D:
			count.call("animatable_bodies")
		if n is CollisionShape3D:
			count.call("collision_shapes")
		if n.get_script() != null:
			var g: String = (n.get_script() as Script).get_global_name()
			if g in ["StructureMember", "HumanBody", "Structure", "FireFX", "GunSmoke", "BloodJet"]:
				count.call(g)
	c["nodes"] = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	c["objects"] = Performance.get_monitor(Performance.OBJECT_COUNT)
	c["physics_active"] = Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
	c["physics_pairs"] = Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS)
	return c


## The systems, by the nodes that run them; each is switched off (or hidden) for a stretch.
func _groups() -> Array:
	var by_class := func(names: Array, mode := "process") -> Array:
		var out := []
		for n in root.find_children("*", "", true, false):
			var s = n.get_script()
			if s != null and (s as Script).get_global_name() in names:
				out.append(n)
		return out
	var g := [
		["HumanBody (physiology, pose)", by_class.call(["HumanBody"]), "physics"],
		["HumanBody (skeleton, pieces)", by_class.call(["HumanBody"]), "process"],
		["Senses", by_class.call(["Senses"]), "physics"],
		["OutlawBrain + Crew", by_class.call(["OutlawBrain"]), "physics"],
		["CivilianBrain", by_class.call(["CivilianBrain"]), "physics"],
		["Structure.settle + analysis", by_class.call(["Structure", "FalseFrontBuilding", "SaloonBuilding", "Boardwalk", "TargetBoard", "RangeCover", "HitchingRail", "WaterTrough"]), "physics"],
		["FireSystem", by_class.call(["FireSystem"]), "physics"],
		["Ballistics", by_class.call(["Ballistics"]), "physics"],
		["DayCycle", by_class.call(["DayCycle"]), "both"],
		["OilLamp", by_class.call(["OilLamp"]), "process"],
		["GunSmoke", by_class.call(["GunSmoke"]), "process"],
		["BloodJet", by_class.call(["BloodJet"]), "physics"],
		["DynamiteStick", by_class.call(["DynamiteStick"]), "physics"],
		["Player (+wounds, composure, deeds, guns)", by_class.call(["Player", "PlayerWounds", "PlayerComposure", "PlayerDeeds", "RevolverViewmodel", "ShotgunViewmodel", "DynamiteViewmodel"]), "both"],
		["TownLife", by_class.call(["TownLife"]), "process"],
		["Debug overlay/traces/spawns", by_class.call(["DebugOverlay", "BulletTraces", "DebugSpawns", "OutlawSpawner", "DebugBreaker"]), "process"],
		["Art: Backdrop, DepthMosaic", by_class.call(["Backdrop", "DepthMosaic"]), "process"],
	]
	if render:
		g.append(["(hidden) people", by_class.call(["HumanBody"]), "hide"])
		g.append(["(hidden) structures", by_class.call(["Structure", "FalseFrontBuilding", "SaloonBuilding", "Boardwalk", "TargetBoard", "RangeCover", "HitchingRail", "WaterTrough"]), "hide"])
		g.append(["(hidden) dressing", by_class.call(["StreetDressing", "StreetScenery"]), "hide"])
	return g


func _switch(nodes: Array, mode: String, on: bool) -> void:
	for n in nodes:
		if not is_instance_valid(n):
			continue
		if mode == "process" or mode == "both":
			n.set_process(on)
		if mode == "physics" or mode == "both":
			n.set_physics_process(on)
		if mode == "hide" and n is Node3D:
			n.visible = on


func _ablate(scene_name: String, base: Dictionary) -> Array:
	var rows := []
	var n := int(5.0 * 60.0)
	for grp in _groups():
		var nodes: Array = grp[1]
		if nodes.is_empty():
			continue
		_switch(nodes, grp[2], false)
		await _frames(10)
		var m: Dictionary = await _measure(n)
		_switch(nodes, grp[2], true)
		await _frames(10)
		# Measured against a fresh baseline each time (the scene keeps changing as it plays).
		var b: Dictionary = await _measure(n)
		rows.append({"system": grp[0], "nodes": nodes.size(), "saves_ms": b.avg_ms - m.avg_ms,
				"render_cpu_ms": b.render_cpu_ms - m.render_cpu_ms, "draw_calls": b.draw_calls - m.draw_calls})
	rows.sort_custom(func(a, b) -> bool: return a.saves_ms > b.saves_ms)
	return rows


func _run() -> void:
	root.get_node(^"Settings").autosave = false
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _frames(3)
	street = main.find_child("TestStreet", true, false)
	var player = street.get_node(^"Player")
	player.input_enabled = false
	var town = street.get_node(^"TownLife")
	town.bring_gang()
	# Stand in the street looking down it, at the saloon and the store.
	player.global_position = Vector3(11.0, 0.0, -9.0)
	player.rotation = Vector3(0, deg_to_rad(121.0), 0)
	await _frames(120)
	var scenes := []
	if only == "" or only == "calm":
		scenes.append("calm")
	if only == "" or only == "fire":
		scenes.append("fire")
	if only == "blaze":
		scenes.append("blaze")
	if only == "wall":
		scenes.append("wall")
	for s in scenes:
		if s == "fire":
			_set_off_dynamite_and_fires()
			await _frames(180)
		elif s == "blaze":
			# The fire left to spread till the whole town's alight.
			_set_off_dynamite_and_fires()
			await _frames(60 * 45)
		var frames := int(seconds * 60.0)
		if s == "wall":
			process_frame.connect(_shoot_the_wall)
		var m: Dictionary = await _measure(frames)
		if s == "wall":
			process_frame.disconnect(_shoot_the_wall)
			m["charges"] = _charges
		var entry := {"frames": m, "census": _census()}
		if budget_report:
			entry["budget"] = await _budget(m)
		if ablate:
			entry["systems"] = await _ablate(s, m)
		report[s] = entry
		_print(s, entry)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "  "))
	quit()


var _wall_frame := 0
var _charges := 0
var _wall_rng := RandomNumberGenerator.new()


## Every 30 frames a shotgun charge from 3 m into one of the store's front boards (in turn, low to
## high), as the player's gun fires it.
func _shoot_the_wall() -> void:
	_wall_frame += 1
	if _wall_frame % 30 != 1:
		return
	var store = null
	for b in street.get_children():
		if b.get(&"structure_id") == &"store":
			store = b
	var boards: Array = store.get_members().filter(func(m) -> bool:
			return String(m.member_id).contains("front") and m.kind == &"board" and not m.broken)
	if boards.is_empty():
		return
	var m = boards[(_charges * 7) % boards.size()]
	var thin := 0
	for i in 3:
		if m.size[i] < m.size[thin]:
			thin = i
	var n: Vector3 = m.global_basis[thin].normalized()
	var player = street.get_node(^"Player")
	if n.dot(player.global_position - m.global_position) < 0.0:
		n = -n
	var gun: Resource = load("res://config/shotgun.tres")
	_wall_rng.seed = 40 + _charges
	var at: Vector3 = m.global_position + n * 3.0
	var none: Array[RID] = []
	root.get_tree().get_first_node_in_group(&"ballistics").fire_charge(at, -n, gun.pellets, deg_to_rad(gun.pattern_degrees),
			gun.muzzle_velocity, gun.pellet_mass, gun.pellet_diameter, none, _wall_rng, gun.blast_joules, gun.blast_reach)
	_charges += 1


## Two sticks against the store's front, a third at the saloon's; the store, the saloon and one
## more building set alight; a few rounds fired (brass on the ground).
func _set_off_dynamite_and_fires() -> void:
	var blast = load("res://src/blast/blast.gd")
	var fire = street.find_child("FireSystem", true, false)
	var lit := 0
	for b in street.get_children():
		var sname: String = (b.get_script() as Script).get_global_name() if b.get_script() else ""
		if sname not in ["FalseFrontBuilding", "SaloonBuilding"]:
			continue
		var members: Array = b.find_children("*", "StructureMember", true, false)
		if members.is_empty():
			continue
		var m = members[members.size() / 3]
		if lit < 2:
			blast.detonate(street, (m as Node3D).global_position + Vector3(0, 0.3, 0), 0.2)
		for k in 4:
			fire.ignite(members[(members.size() * (k + 1)) / 7])
		lit += 1
		if lit >= 3:
			break
	var gun = street.get_node(^"Player").revolver()
	if gun:
		gun.needs_captured_mouse = false
		gun.take_out()
		for k in 3:
			gun.state.busy = 0.0
			gun.state.cock()
			gun.state.busy = 0.0
			gun.pull_trigger()


## The physics engine's share of the frame (not a script timer): the scene measured with the
## physics server paused and running, 3 s each.
func _physics_engine_ms() -> float:
	PhysicsServer3D.set_active(false)
	await _frames(20)
	var off: Dictionary = await _measure(180)
	PhysicsServer3D.set_active(true)
	await _frames(20)
	var on: Dictionary = await _measure(180)
	return maxf(on.avg_ms - off.avg_ms, 0.0)


## The scene's frame in the budget's parts, scaled to Sean's core (FrameBudget.clock_scale).
func _budget(m: Dictionary) -> Dictionary:
	var fb = load("res://config/frame_budget.tres")
	var physics: float = await _physics_engine_ms()
	var parts := {}
	var timed := 0.0
	for k in m.systems_ms:
		var p: StringName = fb.part_of(k)
		parts[p] = float(parts.get(p, 0.0)) + float(m.systems_ms[k])
		timed += float(m.systems_ms[k])
	parts[&"physics"] = physics
	# What no timer covers (the engine's own process, the scene tree, culling) goes to "else";
	# headless there's no render, so the frame is the simulation alone.
	var render_cpu: float = m.get("render_cpu_ms", 0.0)
	parts[&"render_cpu"] = render_cpu
	var rest: float = m.avg_ms - timed - physics - (render_cpu if render else 0.0)
	parts[&"else"] = float(parts.get(&"else", 0.0)) + maxf(rest, 0.0)
	var out := {}
	for p in fb.budgets:
		out[p] = float(parts.get(p, 0.0)) * fb.clock_scale
	out[&"total"] = m.avg_ms * fb.clock_scale
	return out


func _print_budget(b: Dictionary) -> void:
	var fb = load("res://config/frame_budget.tres")
	var bits := []
	for p in fb.budgets:
		var over: bool = float(b[p]) > float(fb.budgets[p])
		bits.append("%s %.2f/%.1f%s" % [p, b[p], fb.budgets[p], " OVER" if over else ""])
	bits.append("total %.2f/%.1f%s" % [b.total, fb.total, " OVER" if b.total > fb.total else ""])
	print("   budget (ms at 3.25 GHz%s): %s" % ["" if render else ", no render", "  ".join(bits)])


func _print(s: String, e: Dictionary) -> void:
	var f: Dictionary = e.frames
	if f.has("charges"):
		print("\n   %d charges into the store's front" % f.charges)
	print("\n== %s: avg %.2f ms (%.0f fps), p99 %.2f ms, max %.1f ms; render cpu %.2f ms, draw calls %.0f, objects in frame %.0f" % [
			s, f.avg_ms, 1000.0 / maxf(f.avg_ms, 0.001), f.p99_ms, f.max_ms, f.render_cpu_ms, f.draw_calls, f.objects_in_frame])
	if render:
		print("   main thread: process %.2f ms, physics %.2f ms a frame" % [f.get("process_ms", 0.0), f.get("physics_ms", 0.0)])
	print("   census: %s" % JSON.stringify(e.census))
	if e.has("budget"):
		_print_budget(e.budget)
	var sys: Dictionary = f.systems_ms
	var keys := sys.keys()
	keys.sort_custom(func(a, b) -> bool: return sys[a] > sys[b])
	print("   timed (ms a frame): %s" % "  ".join(keys.map(func(k) -> String: return "%s %.2f" % [k, sys[k]])))
	if e.has("systems"):
		for r in e.systems:
			print("   %-42s %4d nodes  saves %6.2f ms  (render cpu %5.2f, draws %5.0f)" % [
					r.system, r.nodes, r.saves_ms, r.render_cpu_ms, r.draw_calls])
