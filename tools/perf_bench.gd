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
## --hour=H: the street starts at that hour (23: night, every lamp lit).
## --scene=blast: dynamite and no fire (the game since #458): a stick in each of three buildings,
## 20 s for the rubble to come down and lie, then measured.
## --scene=calm|fire: just one; --scene=blaze: the fire left 45 s first, till the whole town
## burns; --scene=wall: a shotgun charge into the store's front from 3 m every half second while it
## measures (voxel damage, docs/DESTRUCTION_BRIEF.md step 2); --no-voxels: drawn holes instead.
## --clutter=N: the street with N times its kit props (tools/prop_clutter.gd: the copies in rows
## along the street; docs/briefs/props-scale.md). --no-prop-batch: kit props drawn each its own;
## --no-member-rest: members keep their mesh and shape nodes at rest (both the before).
## --no-perf-ring: without the bug report's frame-timing ring and its viewport measuring (PerfRing, #437).
## --folk=N: the street's townsfolk N times over, the copies standing two streets off
## (tools/folk_copies.gd; more-cores step 4b: far men ticking less often, `--people-bands=off` the before).
## --census-by: the census's particles, visible meshes and collision shapes by what owns them.
## --by-ticks: waits and measures in physics ticks, not frames (drawn, without --fixed-fps: the cap's
## before and after over the same game time, #435).
## --spikes=MS: each frame longer than that, with what each system took in it. "timed" is each system's own frame entries (Prof), the rest is
## the engine's (physics, culling, the scene tree) and anything not timed. Godot's process/physics time monitors read nonsense headless (the
## loop's not paced), so the frame is wall clock; draw calls and render CPU need --render.
## Untyped on purpose: -s scripts compile before autoloads exist.
##
## THE VALLEY (#865, the review's R4): `-- --world=valley` runs the valley instead, its scenes
## `day` (Main Street at two in the afternoon, you by the saloon's yard looking west down it), `night`
## (nine at night in saloon B's bar room, #1230: its bar and card table, the lamps lit), `gunfight`
## (the day's street, two crews of three shooting it out 20 to 40 m from you) and `blast` (the day's
## street, a stick in the saloon's front and one in the doctor's, measured from 3 s after), each
## after the valley's load; `chaos` (#1117, only by --scene=chaos, here or in the town): the gunfight,
## three sticks in the saloon, the store alight 15 s on (the town only: the valley has no fire), a line
## a second for --chaos-seconds=200 (the chaos playtest's slowdown, docs/reviews/2026-11-chaos-bench.md), (`load`: the bake, the scene, and the scene by part, ValleyWorld.load_ms).
## --townsfolk=N: N more townsfolk on Main Street (tools/valley/valley_townsfolk.gd), half near you
## and half far (--band=near|far: all in one band). --bodies: the collision bodies (Jolt's
## max_bodies counts them) by what owns them. tools/valley/bench_runs.py runs the counts and scenes
## one game at a time and writes the table.

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
## --by-ticks: every wait and measure counted in physics ticks, not frames (a drawn run in real time,
## where the catch-up cap changes how many ticks a frame runs: the same game time either way, #435).
var by_ticks := false
## Each scene against config/frame_budget.tres (off with --no-budget, and with --quick).
var budget_report := true
## Leave out the render time read (viewport_get_measured_render_time_cpu makes a separate render
## thread wait for the main one every frame, so it hides what the thread gains): --no-render-time.
var render_time := true
## Times the street's kit props (1: as it is).
var clutter := 1
## Times the street's townsfolk (1: as it is).
var folk := 1
## --census-by: the census's particles, visible meshes and collision shapes counted by what owns
## them (the nearest scripted node up the tree: its class, or its script's file).
var census_by := false
## The valley's bench (#865): N more townsfolk, where they stand, the bodies census.
var townsfolk := 0
var band := "mix"
var folk_models := []
var folk_far_models := []
var folk_dress := false
var bodies := false
var valley := false
## --extra-bodies=N: N more static boxes at rest off the town (what more bodies cost Jolt, #865).
var extra_bodies := 0
## --scene=chaos (#1117): how long the timeline runs after the blast (game seconds).
var chaos_seconds := 200.0
var catch_up_guard := false


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
		elif a == "--census-by":
			census_by = true
		elif a.begins_with("--townsfolk="):
			townsfolk = int(a.substr(12))
		elif a.begins_with("--band="):
			band = a.substr(7)
		elif a.begins_with("--folk-model="):
			# The townsfolk all made of these men instead (#889: one MetaHuman repeated), the far band
			# of --folk-far-model's (his lighter level), re-dressed with --folk-dress.
			folk_models = Array(a.substr(13).split(","))
		elif a.begins_with("--folk-far-model="):
			folk_far_models = Array(a.substr(17).split(","))
		elif a == "--folk-dress":
			folk_dress = true
		elif a == "--bodies":
			bodies = true
		elif a.begins_with("--extra-bodies="):
			extra_bodies = int(a.substr(15))
		elif a == "--world=valley":
			valley = true
		elif a == "--no-render-time":
			render_time = false
		elif a.begins_with("--clutter="):
			clutter = int(a.substr(10))
		elif a.begins_with("--folk="):
			folk = int(a.substr(7))
		elif a == "--no-prop-batch":
			pass  # PropBatch reads it itself
		elif a == "--no-perf-ring":
			pass  # BugRecorder reads it itself: no frame-timing ring (PerfRing), no viewport measuring
		elif a == "--by-ticks":
			by_ticks = true
		elif a.begins_with("--catch-up="):
			# Physics ticks a frame may run to catch up (the bridge's 40, project.godot's 2).
			Engine.max_physics_steps_per_frame = int(a.substr(11))
		elif a == "--catch-up-guard":
			# The bridge's limit (CatchUp): it follows what a tick costs.
			catch_up_guard = true
		elif a.begins_with("--chaos-seconds="):
			chaos_seconds = float(a.substr(16))
		elif a.begins_with("--spikes="):
			spikes = float(a.substr(9))
		elif a.begins_with("--hour="):
			# The hour the street starts at (the day cycle's 17:00 otherwise): 23 for the lamps lit.
			(load("res://config/day_cycle.tres") as DayCycleConfig).start_hour = float(a.substr(7))
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
	if by_ticks:
		var t0 := Engine.get_physics_frames()
		while Engine.get_physics_frames() - t0 < n:
			await process_frame
		return
	for i in n:
		await process_frame


## Frame times (ms) over `n` frames, wall clock, plus the monitors averaged.
func _measure(n: int) -> Dictionary:
	var times := PackedFloat32Array()
	var mon := {"render_cpu_ms": 0.0, "render_gpu_ms": 0.0, "draw_calls": 0.0, "objects_in_frame": 0.0, "primitives": 0.0,
			"process_ms": 0.0, "physics_ms": 0.0, "ticks": 0.0}
	# The frame's own process and physics, from the bug report's ring (#435; Godot's monitors are a
	# second's worst frame and worst tick): none with --no-perf-ring.
	var rec = main.get_node_or_null(^"BugRecorder") if main else null
	var ring = rec.perf if rec and rec.perf_on else null
	var ticks0 := Engine.get_physics_frames()
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
	ticks0 = Engine.get_physics_frames()
	var i := 0
	while (Engine.get_physics_frames() - ticks0 < n) if by_ticks else i < n:
		await process_frame
		# Never rolled while it measures: the systems are the whole run's mean (with the default
		# second, they were only the last second's).
		prof.frame(1 << 30, 1e9)
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
		i += 1
		mon.draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME) / n
		mon.objects_in_frame += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME) / n
		mon.primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / n
		# The main thread's own work (headless the loop isn't paced: one tick a frame).
		if ring:
			var row: Dictionary = ring.last_frame()
			mon.process_ms += float(row.get("process_ms", 0.0)) / n
			mon.physics_ms += float(row.get("physics_ms", 0.0)) / n
		if vp_rid.is_valid():
			mon.render_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) / n
			mon.render_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(vp_rid) / n
	if by_ticks:  # the sums above were over n; there were i frames
		for k in mon:
			mon[k] *= float(n) / maxf(i, 1)
	mon.ticks = float(Engine.get_physics_frames() - ticks0) / maxf(i, 1)  # physics ticks a frame (the catch-up, #435)
	mon["frames_measured"] = i
	# Memory after the run (#889): the engine's static memory and, drawn, the video memory.
	mon["static_mb"] = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	mon["video_mb"] = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	mon["texture_mb"] = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
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
	var by := {}
	var count_by := func(key: String, n: Node) -> void:
		if not census_by:
			return
		var o := n.get_parent()
		while o and o.get_script() == null:
			o = o.get_parent()
		var s: Script = o.get_script() if o else null
		var who := "none" if s == null else (String(s.get_global_name()) if s.get_global_name() != &"" else s.resource_path.get_file())
		if not by.has(key):
			by[key] = {}
		by[key][who] = int(by[key].get(who, 0)) + 1
	var on_body := func(key: String, n: Node) -> void:
		# A mesh or shape on a loose body: whether that's asleep, awake or frozen, and its group.
		var p := n.get_parent()
		if not census_by or not p is RigidBody3D:
			return
		var rb := p as RigidBody3D
		var g := "rubble" if rb.is_in_group(&"rubble") else ("glass_shards" if rb.is_in_group(&"glass_shards") else ("wood_chips" if rb.is_in_group(&"wood_chips") else "other"))
		var st := "frozen" if rb.freeze else ("asleep" if rb.sleeping else "awake")
		if rb.has_meta(&"resting_in"):
			st += ", in a cell"  # (RubbleRest: its shapes or its own meshes not off it yet)
		by.get_or_add(key + "_on_bodies", {})[g + " " + st] = int(by.get(key + "_on_bodies", {}).get(g + " " + st, 0)) + 1
	for n in street.find_children("*", "", true, false):
		if n is MeshInstance3D:
			count.call("meshes")
			if (n as MeshInstance3D).is_visible_in_tree():
				count.call("meshes_visible")
				count_by.call("meshes_visible", n)
				on_body.call("meshes_visible", n)
		elif n is MultiMeshInstance3D:
			count.call("multimeshes")
		elif n is GPUParticles3D or n is CPUParticles3D:
			count.call("particles")
			count_by.call("particles", n)
		elif n is Light3D:
			count.call("lights")
		if n is RigidBody3D:
			count.call("rigid_bodies")
			if not (n as RigidBody3D).sleeping and not (n as RigidBody3D).freeze:
				count.call("rigid_awake")
				if census_by:
					# What's still moving (it can't rest in a cell: RubbleRest, #459), by its group.
					var g := "rubble" if n.is_in_group(&"rubble") else ("glass_shards" if n.is_in_group(&"glass_shards") else n.get_class())
					by.get_or_add("rigid_awake", {})[g] = int(by.get("rigid_awake", {}).get(g, 0)) + 1
		elif n is StaticBody3D:
			count.call("static_bodies")
		elif n is AnimatableBody3D:
			count.call("animatable_bodies")
		if n is CollisionShape3D:
			count.call("collision_shapes")
			count_by.call("collision_shapes", n)
			on_body.call("collision_shapes", n)
		if n.get_script() != null:
			var g: String = (n.get_script() as Script).get_global_name()
			if g in ["StructureMember", "HumanBody", "Structure", "FireFX", "GunSmoke", "BloodJet"]:
				count.call(g)
	if census_by:
		c["by"] = by
		var rest := street.get_node_or_null(^"RubbleRest")
		if rest:
			c["rubble_rest"] = {"pieces": rest.piece_count(), "meshes": rest.mesh_count(), "waiting": rest._waiting.size(), "refused": rest.refused, "counts": rest.counts, "state": rest.state()}
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
		["Player (+wounds, composure, deeds, guns)", by_class.call(["Player", "PlayerWounds", "PlayerComposure", "PlayerDeeds", "RevolverViewmodel", "ShotgunViewmodel", "Winchester73Viewmodel", "DynamiteViewmodel"]), "both"],
		["TownLife", by_class.call(["TownLife"]), "process"],
		["Debug overlay/traces/spawns", by_class.call(["DebugOverlay", "BulletTraces", "DebugSpawns", "OutlawSpawner", "DebugBreaker"]), "process"],
		["Art: Backdrop, DepthMosaic", by_class.call(["Backdrop", "DepthMosaic"]), "process"],
	]
	if valley:
		g.append_array([
			["FaceLife (blinks, breath, mouth)", by_class.call(["FaceLife"]), "physics"],
			["FaceGaze (eyes)", by_class.call(["FaceGaze"]), "process"],
			["FaceSpeech", by_class.call(["FaceSpeech"]), "both"],
			["ValleyFolk (the clock, talk)", by_class.call(["ValleyFolk"]), "process"],
			["CardGame", by_class.call(["CardGame"]), "both"],
			["RoomLight", by_class.call(["RoomLight"]), "both"],
			["ValleyGround (levels)", by_class.call(["ValleyGround", "Ground"]), "both"],
			["ValleyRailway (the train)", by_class.call(["ValleyRailway"]), "both"],
		])
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
	if valley:
		await _run_valley()
		return
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
	if clutter > 1:
		await physics_frame  # (it finds each one's floor: World.space's rule)
		var made: Array = load("res://tools/prop_clutter.gd").lay(street, clutter)
		print("clutter: %d more kit props" % made.size())
		await _frames(120)
	if folk > 1:
		await physics_frame  # (it finds each one's ground: World.space's rule)
		var copies: Array = load("res://tools/folk_copies.gd").lay(street, folk)
		print("folk: %d more townsfolk, two streets off" % copies.size())
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
	if only == "blast":
		scenes.append("blast")
	if only == "chaos":
		var c: Dictionary = await _town_chaos(player)
		report["chaos"] = c
		scenes = []
	for s in scenes:
		if s == "fire":
			_set_off_dynamite_and_fires()
			await _frames(180)
		elif s == "blast":
			_set_off_dynamite()
			await _frames(60 * 20)
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
## A stick in each of the first three buildings, where `_set_off_dynamite_and_fires` puts its two,
## and nothing lit (#459: fire is out of play).
func _set_off_dynamite() -> void:
	var blast = load("res://src/blast/blast.gd")
	var done := 0
	for b in street.get_children():
		var sname: String = (b.get_script() as Script).get_global_name() if b.get_script() else ""
		if sname not in ["FalseFrontBuilding", "SaloonBuilding"]:
			continue
		var members: Array = b.find_children("*", "StructureMember", true, false)
		if members.is_empty():
			continue
		blast.detonate(street, (members[members.size() / 3] as Node3D).global_position + Vector3(0, 0.3, 0), 0.2)
		done += 1
		if done >= 3:
			break


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
		if p == &"":
			continue  # a count (lines asked, men ticked), not a time
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


## The valley's memory after its load against the budget (#1259): Godot's static memory, peak and
## current RSS, the structures' members and what they come to a member.
func _memory_report() -> void:
	var fb = load("res://config/frame_budget.tres")
	var hwm := 0.0
	var now := 0.0
	var f := FileAccess.open("/proc/self/status", FileAccess.READ)
	while f and not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("VmHWM:"):
			hwm = float(line.split(":")[1].strip_edges().split(" ")[0]) / 1024.0
		elif line.begins_with("VmRSS:"):
			now = float(line.split(":")[1].strip_edges().split(" ")[0]) / 1024.0
	var members := 0
	var biggest := {}
	for st in root.get_tree().get_nodes_in_group(&"structures"):
		var n: int = st.member_count()
		members += n
		if n > 2000:
			biggest[String(st.name)] = n
	var static_mb := OS.get_static_memory_usage() / 1048576.0
	report["memory"] = {"static_mb": static_mb, "peak_rss_mb": hwm, "rss_mb": now, "members": members, "big": biggest}
	print("   memory: static %.0f MB, RSS %.0f MB, peak RSS %.0f MB; %d members in structures (over 2,000: %s)" % [
			static_mb, now, hwm, members, JSON.stringify(biggest)])
	print("   memory budget: peak RSS %.0f/%.0f MB%s" % [hwm, fb.valley_peak_mb, " OVER" if hwm > fb.valley_peak_mb else ""])


func _print(s: String, e: Dictionary) -> void:
	var f: Dictionary = e.frames
	if f.has("charges"):
		print("\n   %d charges into the store's front" % f.charges)
	print("\n== %s: avg %.2f ms (%.0f fps), p99 %.2f ms, max %.1f ms; render cpu %.2f ms, draw calls %.0f, objects in frame %.0f" % [
			s, f.avg_ms, 1000.0 / maxf(f.avg_ms, 0.001), f.p99_ms, f.max_ms, f.render_cpu_ms, f.draw_calls, f.objects_in_frame])
	if render or by_ticks:
		print("   main thread: process %.2f ms, physics %.2f ms a frame (%.2f ticks, %d frames)" % [f.get("process_ms", 0.0), f.get("physics_ms", 0.0), f.get("ticks", 0.0), int(f.get("frames_measured", 0))])
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



# --- The valley (#865) ----------------------------------------------------------------------------

## Where you stand by day: Main Street by the saloon's yard, looking west down the street (the
## saloon, the store's row, the crossroads); at night: in saloon B's bar room (the folk's room place).
const DAY_AT := Vector3(40.0, 0.0, 2.0)
const DAY_HEADING := 270.0
const NIGHT_AT := Vector3(29.2, 0.0, -8.0)
const NIGHT_HEADING := 355.0
## `--scene=road` (art's, #891: the land's scatter): the East Road by the sheriff's opening site,
## looking up it to the east-north-east, at two in the afternoon. Only when asked for.
const ROAD_AT := Vector3(450.0, 0.0, 95.0)
const ROAD_HEADING := 68.0


func _run_valley() -> void:
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	var t0 := Time.get_ticks_usec()
	load("res://src/world/valley_terrain.gd").main()
	var t1 := Time.get_ticks_usec()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	var t2 := Time.get_ticks_usec()
	await _frames(3)
	var t3 := Time.get_ticks_usec()
	street = main.find_child("Valley", true, false)
	var folk = street.get("folk")
	report["load"] = {"bake_ms": (t1 - t0) / 1000.0, "scene_ms": (t2 - t1) / 1000.0, "first_frames_ms": (t3 - t2) / 1000.0,
			"parts_ms": street.get("load_ms"), "folk_ms": folk.build_ms if folk else {}}
	print("load: bake %.0f ms, scene %.0f ms, first 3 frames %.0f ms; parts %s; folk %s" % [
			report.load.bake_ms, report.load.scene_ms, report.load.first_frames_ms, JSON.stringify(report.load.parts_ms), JSON.stringify(report.load.folk_ms)])
	var player = street.get_node(^"Player")
	player.input_enabled = false
	if extra_bodies > 0:
		_add_extra_bodies(extra_bodies)
		await _frames(3)
	var clock = street.get_node_or_null(^"DayCycle")
	var scenes := ["day", "night", "gunfight", "blast"] if only == "" else [only]
	if only == "load":
		scenes = []
	for s: String in scenes:
		var night := s == "night"
		var at: Vector3 = NIGHT_AT if night else (ROAD_AT if s == "road" else DAY_AT)
		_stand(player, at, NIGHT_HEADING if night else (ROAD_HEADING if s == "road" else DAY_HEADING))
		if clock:
			clock.set_time(21.0 if night else 14.0)
		if folk:
			folk._look = 0.0  # (the folk read the clock now, not in half a second)
		if night and folk and folk.room_place() != &"":
			# In saloon B's bar room by its bar, looking at the card table (#1230: the night moved in).
			var ra: Vector3 = folk.places.at(folk.room_place())
			player.global_position = ra + Vector3.UP * 0.1
			var to: Vector3 = folk.props.table.global_position - ra
			player.rotation.y = atan2(-to.x, -to.z)
		await _frames(60)
		var made: Array = []
		var lay_ms := 0.0
		if townsfolk > 0:
			await physics_frame
			var vt = load("res://tools/valley/valley_townsfolk.gd")
			vt.models = folk_models
			vt.far_models = folk_far_models
			vt.dress = folk_dress
			var tl := Time.get_ticks_usec()
			made = vt.lay(street, townsfolk, player.global_position,
					band, Vector3(NIGHT_AT.x, 0.0, NIGHT_AT.z) if night else Vector3.INF)
			lay_ms = (Time.get_ticks_usec() - tl) / 1000.0
		await _frames(120)
		var extra := {}
		if s == "gunfight":
			extra = await _gunfight(player)
		elif s == "blast":
			await physics_frame  # (a blast asks the world: in the physics frame)
			extra = _valley_blast()
			await _frames(180)
		elif s == "chaos":
			# Its own measure: the timeline through the spike. No budget or ablation after it.
			extra = await _valley_chaos(player)
			report[s] = extra
			continue
		var m: Dictionary = await _measure(int(seconds * 60.0))
		var entry := {"frames": m, "census": _census(), "people": _people_census(player)}
		entry.people["townsfolk_added"] = made.size()
		entry.people["townsfolk_lay_ms"] = lay_ms
		entry.merge(extra)
		if bodies:
			entry["bodies"] = _bodies_census()
		if budget_report:
			entry["budget"] = await _budget(m)
		if ablate:
			entry["systems"] = await _ablate(s, m)
		report[s] = entry
		_print(s, entry)
		print("   people: %s" % JSON.stringify(entry.people))
		if extra:
			print("   %s" % JSON.stringify(extra))
		if bodies:
			print("   bodies: %s" % JSON.stringify(entry.bodies))
		for man in made:
			if is_instance_valid(man):
				man.queue_free()
		await _frames(2)
	if only == "load":
		_memory_report()
	if only == "load" and bodies:
		await _frames(60)
		report["bodies"] = _bodies_census()
		print("   bodies: %s" % JSON.stringify(report.bodies))
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "  "))
	quit()


## N static boxes (0.3 m, like a member's piece) at rest in a grid 300 m south of the town, each its
## own body as the members are: what N more bodies cost Jolt's step, queries and memory.
func _add_extra_bodies(n: int) -> void:
	var holder := Node3D.new()
	holder.name = "BenchExtraBodies"
	street.add_child(holder)
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.3, 0.3, 0.3)
	var side := int(ceil(sqrt(float(n))))
	for i in n:
		var b := StaticBody3D.new()
		var c := CollisionShape3D.new()
		c.shape = shape
		b.add_child(c)
		b.position = Vector3(-150.0 + float(i % side) * 0.5, 2.0, 300.0 + float(i / side) * 0.5)
		holder.add_child(b)
	print("extra bodies: %d" % n)


func _stand(player: Node3D, at: Vector3, heading: float) -> void:
	var ground = street.get_node_or_null(^"Ground")
	if ground:
		at.y = ground.height_at(at.x, at.z) + 0.05
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, -deg_to_rad(heading), 0.0)


## Everyone in the world by band (PeopleTick's: within 25 m every tick, past 60 m every 4th), and how
## many of each have a face that lives (FaceLife).
func _people_census(player: Node3D) -> Dictionary:
	var out := {"men": 0, "near_25": 0, "mid": 0, "far_60": 0, "faces": 0, "dead": 0}
	for n in street.find_children("*", "", true, false):
		var s = n.get_script()
		if s == null:
			continue
		var g: String = (s as Script).get_global_name()
		if g == "HumanBody":
			out.men += 1
			var d: float = (n as Node3D).global_position.distance_to(player.global_position)
			if d <= 25.0:
				out.near_25 += 1
			elif d >= 60.0:
				out.far_60 += 1
			else:
				out.mid += 1
			if n.get("physiology") != null and not n.physiology.alive:
				out.dead += 1
		elif g == "FaceLife":
			out.faces += 1
	return out


## Two crews of three on the street west of you, 20 to 40 m off, turned on each other: the gang's
## three (TownLife.GANG's men) by the saloon's front and three more outlaws across by the jail.
func _gunfight(player: Node3D) -> Dictionary:
	var town_life = load("res://src/people/town_life.gd")
	var folk = street.get("folk")
	var crews := [[], []]
	var brains := [[], []]
	var spots := [[Vector3(16, 0, -6), Vector3(19, 0, -3), Vector3(13, 0, -2)],
			[Vector3(2, 0, 6), Vector3(-1, 0, 3), Vector3(4, 0, 2)]]
	var ground = street.get_node_or_null(^"Ground")
	for c in 2:
		for i in 3:
			var g: Dictionary = town_life.GANG[i]
			var man = load("res://src/bodies/human_body.gd").new()
			var id := "%s_%d" % [g.id, c]
			man.name = id.capitalize()
			man.person_id = StringName(id)
			man.rng_seed = 700 + 10 * c + i
			man.shirt_color = g.shirt
			man.coat_color = g.coat
			man.hat_color = g.hat
			man.body_model = g.model
			man.has_gun = true
			var brain = load("res://src/bodies/outlaw_brain.gd").new()
			brain.name = "Brain"
			brain.temper = g.temper
			brain.nerve = maxf(g.nerve, 0.7)  # (a fight that lasts the measure, not one that runs off)
			brain.proud = g.proud
			var friends: Array[StringName] = []
			for k in 3:
				if k != i:
					friends.append(StringName("%s_%d" % [town_life.GANG[k].id, c]))
			brain.friends = friends
			if folk:
				brain.places = folk.places
			man.add_child(brain)
			var at: Vector3 = spots[c][i]
			if ground:
				at.y = ground.height_at(at.x, at.z) + 0.05
			var other: Vector3 = spots[1 - c][0]
			man.enter(street, at, man.yaw_toward(at, other))
			crews[c].append(man)
			brains[c].append(brain)
	await _frames(60)
	for c in 2:
		for i in 3:
			brains[c][i].turn_on(crews[1 - c][i])
	await _frames(120)
	return {"crews": 6}


## A stick in the saloon's front and one in the doctor's (the valley's two spec buildings on Main
## Street), as the old street's blast scene puts one in each of three buildings.
func _valley_blast() -> Dictionary:
	var blast = load("res://src/blast/blast.gd")
	var out := {"sticks": []}
	var bs: Dictionary = street.get("buildings")
	for id in ["saloon", "doctor"]:
		var b: Node3D = bs.get(id)
		if b == null:
			continue
		var members: Array = b.find_children("*", "StructureMember", true, false)
		if members.is_empty():
			continue
		# The member nearest the street at about waist height: the front.
		var best: Node3D = null
		var best_d := INF
		var front := b.global_position + Vector3(0.0, 1.0, 0.0)
		front.z = 0.0
		for m: Node3D in members:
			var d := m.global_position.distance_to(front)
			if d < best_d:
				best_d = d
				best = m
		blast.detonate(street, best.global_position + Vector3(0, 0.3, 0), 0.2)
		out.sticks.append(id)
	return out


## The chaos round's slowdown (#1117, docs/playtests/2026-11-20-chaos.md finding 2): the gang
## shooting it out by the saloon, a bundle of three sticks in saloon B, and the general store set
## alight 15 s on; then each frame timed for `chaos_seconds`, a line a second (the second's mean and
## worst frame, the physics ticks a frame ran, the systems' share, members broken and burning, nodes)
## and the frames over --spikes with what each system took.
func _valley_chaos(player: Node3D) -> Dictionary:
	await _gunfight(player)
	var bs: Dictionary = street.get("buildings")
	return await _chaos(bs.get("saloon"), bs.get("general_store"))


## The same in the old town (where the playtest's bridge was, and the only world with a FireSystem):
## the gang turned on you, three sticks in the Saloon, the Store alight 15 s on.
func _town_chaos(player: Node3D) -> Dictionary:
	for n in street.find_children("*", "OutlawBrain", true, false):
		if n.has_method(&"turn_on"):
			n.turn_on(player)
	return await _chaos(street.get_node(^"Saloon"), street.get_node(^"Store"))


func _chaos(saloon: Node3D, store: Node3D) -> Dictionary:
	var prof = load("res://src/debug/prof.gd")
	var rec = main.get_node_or_null(^"BugRecorder")
	var ring = rec.perf if rec and rec.perf_on else null
	var members: Array = street.find_children("*", "StructureMember", true, false)
	var at := _middle(saloon)
	await physics_frame
	var stick = load("res://src/blast/dynamite_stick.gd").make(street, at, Vector3.ZERO, 0.05, 3)
	stick.light()
	print("chaos: three sticks at %s, %d members in the world" % [at, members.size()])
	prof.on = true
	prof.roll()
	var lit := false
	var frames := int(chaos_seconds * 60.0)
	var sec := {}
	var sec_frames := 0
	var sec_ms := 0.0
	var sec_worst := 0.0
	var sec_phys := 0.0
	var timeline := []
	var worst := {"frame_ms": 0.0}
	var last := Time.get_ticks_usec()
	var total_ms := 0.0
	var over_budget := 0
	var t_start := Engine.get_physics_frames()
	var i := 0
	var sec_ticks := 0
	var sec_start := 0
	while (Engine.get_physics_frames() - t_start < frames) if by_ticks else i < frames:
		var game := (Engine.get_physics_frames() - t_start) if by_ticks else i
		if not lit and game >= 15 * 60:
			lit = true
			var fire = load("res://src/fire/fire_system.gd").find(self)
			var m: Node = _nearest_timber(store, _middle(store), fire)
			if fire and m:
				fire.ignite(m)
			print("chaos: the store alight at %s (%s)" % [m.get(&"member_id") if m else "nothing", "fire" if fire else "no FireSystem"])
		var ticks0 := Engine.get_physics_frames()
		await process_frame
		i += 1
		prof.frame(1 << 30, 1e9)
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		total_ms += ms
		sec_ticks += Engine.get_physics_frames() - ticks0
		if catch_up_guard and ring:
			var row: Dictionary = ring.last_frame()
			load("res://src/main/catch_up.gd").after_frame(float(row.get("physics_ms", 0.0)), int(row.get("ticks", 0)))
		var phys := float(ring.last_frame().get("physics_ms", 0.0)) if ring else 0.0
		for k in prof.frame_ms:
			sec[k] = float(sec.get(k, 0.0)) + float(prof.frame_ms[k])
		sec_frames += 1
		sec_ms += ms
		sec_phys += phys
		sec_worst = maxf(sec_worst, ms)
		if ms > 33.3:
			over_budget += 1
		if spikes > 0.0 and ms > spikes:
			var parts := []
			for k in prof.frame_ms:
				if float(prof.frame_ms[k]) > 0.5 and not String(k).begins_with("n_") and not String(k).begins_with("q_"):
					parts.append("%s %.1f" % [k, float(prof.frame_ms[k])])
			print("   spike t %.1f: %.1f ms, %d ticks (physics %.1f): %s" % [game / 60.0, ms, Engine.get_physics_frames() - ticks0, phys, ", ".join(parts)])
		if ms > float(worst.frame_ms):
			worst = {"frame_ms": ms, "t": game / 60.0, "systems": prof.frame_ms.duplicate()}
		var game_now := (Engine.get_physics_frames() - t_start) if by_ticks else i
		if game_now - sec_start >= 60:
			sec_start = game_now
			var broken := 0
			var burning := 0
			for m: Node in members:
				if not is_instance_valid(m):
					continue
				if m.get(&"broken"):
					broken += 1
				if m.get(&"burning"):
					burning += 1
			# The loose bodies (a broken piece, a shard, a body thrown): all, and those Jolt still steps.
			var loose := 0
			var awake := 0
			for b: RigidBody3D in street.find_children("*", "RigidBody3D", true, false):
				loose += 1
				if not b.sleeping and not b.freeze:
					awake += 1
			var top := []
			for k in sec:
				if not String(k).begins_with("n_") and not String(k).begins_with("q_") and float(sec[k]) / sec_frames > 0.3:
					top.append([k, float(sec[k]) / sec_frames])
			top.sort_custom(func(a, b) -> bool: return a[1] > b[1])
			var row := {"t": game_now / 60.0, "avg_ms": sec_ms / sec_frames, "worst_ms": sec_worst,
					"physics_ms": sec_phys / sec_frames, "ticks_a_frame": float(sec_ticks) / sec_frames, "frames": sec_frames,
					"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
					"broken": broken, "burning": burning, "loose": loose, "awake": awake, "top": top.slice(0, 6)}
			timeline.append(row)
			var tops := []
			for t in row.top:
				tops.append("%s %.1f" % [t[0], t[1]])
			print("t %5.0f  frames %3d avg %6.1f  worst %6.1f  physics %6.1f  ticks %4.1f  nodes %5d  broken %4d burning %3d loose %4d awake %4d | %s" % [
					row.t, sec_frames, row.avg_ms, row.worst_ms, row.physics_ms, row.ticks_a_frame, row.nodes,
					broken, burning, loose, awake, ", ".join(tops)])
			sec = {}
			sec_ticks = 0
			sec_frames = 0
			sec_ms = 0.0
			sec_worst = 0.0
			sec_phys = 0.0
	prof.on = false
	var w_parts := []
	for k in worst.get("systems", {}):
		if float(worst.systems[k]) > 1.0:
			w_parts.append([k, float(worst.systems[k])])
	w_parts.sort_custom(func(a, b) -> bool: return a[1] > b[1])
	frames = i
	print("chaos: %d frames, mean %.1f ms, %d over 33 ms, worst %.1f ms at t %.1f: %s" % [frames, total_ms / frames,
			over_budget, worst.frame_ms, worst.get("t", 0.0), JSON.stringify(w_parts.slice(0, 8))])
	return {"mean_ms": total_ms / frames, "frames_over_33": over_budget, "worst": {"ms": worst.frame_ms, "t": worst.get("t", 0.0),
			"systems": w_parts.slice(0, 8)}, "timeline": timeline}


## The middle of a building's members, a metre over its floor.
func _middle(b: Node3D) -> Vector3:
	var sum := Vector3.ZERO
	var n := 0
	for m: Node3D in b.find_children("*", "StructureMember", true, false):
		sum += m.global_position
		n += 1
	var c := sum / maxf(n, 1)
	c.y = b.global_position.y + 1.0
	return c


## The building's unbroken timber nearest a point (what the bridge's `ignite X Y Z` takes).
func _nearest_timber(b: Node3D, at: Vector3, fire) -> Node:
	var best: Node = null
	var best_d := INF
	for m in b.find_children("*", "StructureMember", true, false):
		if m.broken or (fire and not fire.flammable(m)):
			continue
		var d: float = m.world_aabb().get_center().distance_to(at)
		if d < best_d:
			best_d = d
			best = m
	return best


## The collision bodies in the world (each a Jolt body, against project.godot's max_bodies) by what
## owns them: the valley's own children, the spec buildings, the grey-box town, the kit props, people.
func _bodies_census() -> Dictionary:
	var by := {}
	var kinds := {}
	var total := 0
	for n in street.find_children("*", "CollisionObject3D", true, false):
		total += 1
		var k: String = n.get_class()
		kinds[k] = int(kinds.get(k, 0)) + 1
		var owner_name := _body_owner(n)
		by[owner_name] = int(by.get(owner_name, 0)) + 1
	var keys := by.keys()
	keys.sort_custom(func(a, b) -> bool: return by[a] > by[b])
	var sorted := {}
	for k in keys:
		sorted[k] = by[k]
	return {"total": total, "max_bodies": ProjectSettings.get_setting("physics/jolt_physics_3d/limits/max_bodies", 0),
			"kinds": kinds, "by": sorted}


## What a body belongs to: a person, a kit prop (its prop id), a spec building, or the valley's child
## it hangs under (the ground, the railway, the markers' town by its child).
func _body_owner(n: Node) -> String:
	var p := n
	var kit := ""
	while p != null and p != street:
		var s = p.get_script()
		if s != null:
			var g: String = (s as Script).get_global_name()
			if g == "HumanBody":
				return "people"
			if g == "KitProp" and kit == "":
				kit = "kit:" + String(p.get(&"prop_id")) if p.get(&"prop_id") != null else "kit"
		if p.get_parent() == street:
			var top := String(p.name)
			if top == "Markers" and n != p:
				var q := n
				while q.get_parent() != p:
					q = q.get_parent()
				top = "Markers/" + String(q.name).rstrip("0123456789_")
			return top + (" (" + kit + ")" if kit != "" else "")
		p = p.get_parent()
	return "?"
