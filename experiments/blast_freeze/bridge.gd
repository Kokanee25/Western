extends BridgeLab
## The blast-freeze lab (README.md beside this file; issue #374): Sean's 20-second freeze when a
## stick of dynamite goes off in the spec saloon with a fire already burning. One command sets the
## scene up (the building lab's saloon, a fire lit near the spot and left to grow, the men if asked),
## then throws the stick and records every frame through the blast: wall-clock ms, each system's
## share (Prof), the blast's and the settle's own timers, what broke, what fell. Its answer is the
## headline (the worst frame, the frames over the stall line, where the time went); the whole trace
## goes to `out`.

const SpecSaloon := preload("res://experiments/gunfight_lab/spec_saloon.gd")

const HELP := {
	"bf_blast": "bf_blast [at=X,Y,Z] [fire=N] [burn=S] [fuse=S] [seconds=S] [stall=MS] [player=X,Y,Z] [census=1] [in=street] [sticks=N] [gap=S] [spread=M] [out=FILE.json] -> the spec saloon (or Main Street's first buildings, in=street; `sticks` of them `gap` s apart, `spread` m along the saloon's front) (built if it isn't), the player put at `player` (the saloon's own space; left where he is if not given), N members alight near `at` (the saloon's own space) and left to burn S s, then a stick there and every frame recorded for S s after: the worst frame, frames over the stall line, where the time went",
	"bf_frames": "bf_frames [N] -> the last N recorded frames (bf_blast), newest last",
	"bf_analyse": "bf_analyse -> the spec saloon (built if it isn't) analysed from the top, a member at a time, timed: µs a member by kind (count, mean, worst) and the ten slowest (more-cores step 5: the load check's slices)",
	"bf_batches": "bf_batches -> the batches every structure in the town draws in (Structure.batch_count), in all and the five largest, and the spec saloon's if it's built",
	"bf_shot": "bf_shot [from=X,Y,Z] [dirs=x,-x,z,-z] [gap=S] [stall=MS] [out=FILE.json] -> the spec saloon (built if it isn't), a revolver ball from `from` (the saloon's own space) each way in `dirs`, `gap` s apart, every frame recorded: each shot's worst frame and what was in it, and the saloon's batches (members a material) (Sean's per-shot hitch, #385)",
}

## A frame longer than this (ms, this workspace's wall clock) counts as a stall.
const STALL_MS := 50.0

var _frames: Array[Dictionary] = []
var _recording := false
var _last_us := 0
var _event_tick := -1
var _broken := 0
var _cut := 0


func _cmd_bf_blast(a: Array) -> Dictionary:
	var opts := {"at": "6.0,0.8,6.0", "fire": 0, "burn": 20.0, "fuse": 1.0, "seconds": 8.0, "stall": STALL_MS, "out": "", "player": "", "census": 0, "in": "saloon", "sticks": 1, "gap": 0.4, "spread": 3.0}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var on_street := String(opts["in"]) == "street"
	var town := street.get_node_or_null(^"TownLife") as TownLife
	var built := street.get_node_or_null(^"SpecSaloon") != null
	var saloon: Structure = null
	if not on_street:
		saloon = SpecSaloon.ensure(street, town.places if town else null) as Structure
		if not built:
			await physics_frames(30)
	var parts := String(opts.at).split(",")
	if parts.size() != 3:
		return {"ok": false, "error": "at=X,Y,Z (the saloon's own space)"}
	var local := Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	# Where the sticks go: in the saloon `at`, the rest `spread` m apart along its front; on Main
	# Street (in=street) perf_bench's spots, a third of the way through the first buildings' members.
	var spots: Array[Vector3] = []
	var n_sticks := maxi(int(opts.sticks), 1)
	if on_street:
		for b in street.get_children():
			var sname: String = (b.get_script() as Script).get_global_name() if b.get_script() else ""
			if sname not in ["FalseFrontBuilding", "SaloonBuilding"]:
				continue
			var ms: Array = b.find_children("*", "StructureMember", true, false)
			if ms.is_empty():
				continue
			spots.append((ms[ms.size() / 3] as Node3D).global_position + Vector3(0, 0.3, 0))
			if spots.size() >= n_sticks:
				break
	else:
		for k in n_sticks:
			spots.append(SpecSaloon.at(local + Vector3(float(opts.spread) * k, 0.0, 0.0)))
	var at: Vector3 = spots[0]
	if String(opts.player) != "" and player:
		# Where he stands decides the fire's bands (FireSystem.bands): in the hall, everything near.
		var pp := String(opts.player).split(",")
		player.global_position = SpecSaloon.at(Vector3(float(pp[0]), float(pp[1]), float(pp[2])))
		player.velocity = Vector3.ZERO
		await physics_frames(2)
	var fire := FireSystem.find(get_tree())
	var lit: Array = []
	var n_fire := int(opts.fire)
	if n_fire > 0 and fire and saloon:
		# The nearest flammable boards to the spot, so the fire is where the stick lands.
		var cands: Array = []
		for m: StructureMember in saloon.get_members():
			if m.broken or m.burning or not fire.flammable(m) or not (m.kind in [&"floor_board", &"board", &"roof_board"]):
				continue
			cands.append([m.world_aabb().get_center().distance_to(at), m])
		cands.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		for i in mini(n_fire, cands.size()):
			var m: StructureMember = cands[i][1]
			fire.ignite(m)
			lit.append(String(m.member_id))
		await seconds(float(opts.burn))
	var burning_before := fire.burning_members().size() if fire else 0
	var members_before := saloon.member_count() if saloon else 0
	var rubble_before := saloon.rubble.size() if saloon else 0
	# Record from a second before the stick to `seconds` after it goes off.
	PhysicsWindow.add_to(get_tree().root)  # the frame as window, step (Jolt's) and rest
	_frames.clear()
	_broken = 0
	_cut = 0
	_event_tick = -1
	Prof.on = true
	Prof._sum.clear()
	var on_broken := func(_id: StringName) -> void: _broken += 1
	var on_cut := func(_m: Node, _p: Array) -> void: _cut += 1
	Events.member_broken.connect(on_broken)
	Events.member_cut.connect(on_cut)
	_last_us = Time.get_ticks_usec()
	_recording = true
	await seconds(1.0)
	var stick := DynamiteStick.make(street, at, Vector3.ZERO, float(opts.fuse))
	stick.light()
	for k in range(1, spots.size()):
		DynamiteStick.make(street, spots[k], Vector3.ZERO, float(opts.fuse) + float(opts.gap) * k).light()
	# The census walks the whole tree (~26,000 nodes, ~0.1 s): only when asked, as it lands on the
	# frames measured (#538: it was the stick's frame's deferred calls and the one before).
	var take_census := int(opts.census) != 0
	var census := [_census() if take_census else {}, {}]
	stick.went_off.connect(func() -> void:
		_event_tick = Engine.get_physics_frames()
		if take_census:
			(func() -> void: census[1] = _census()).call_deferred())
	await seconds(float(opts.fuse) + float(opts.gap) * (spots.size() - 1) + float(opts.seconds))
	_recording = false
	Events.member_broken.disconnect(on_broken)
	Events.member_cut.disconnect(on_cut)
	var stall := float(opts.stall)
	var summary := _summarise(stall)
	summary["setup"] = {"at": arr(at), "at_local": [local.x, local.y, local.z], "lit": lit, "burn_s": float(opts.burn),
			"in": String(opts["in"]), "spots": spots.map(func(v: Vector3) -> Array: return arr(v)), "gap": float(opts.gap),
			"burning_before": burning_before, "members_before": members_before, "rubble_before": rubble_before,
			"members_after": saloon.member_count() if saloon else 0, "rubble_after": saloon.rubble.size() if saloon else 0,
			"burning_after": fire.burning_members().size() if fire else 0, "broken": _broken, "cut": _cut,
			"people": get_tree().get_nodes_in_group(&"people").size(), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"player": arr(player.global_position) if player else [], "player_from_stick": player.global_position.distance_to(at) if player else -1.0,
			"fire_bands": (load("res://src/fire/fire_system.gd") as Script).get(&"bands")}  # null before step 5
	# Which members are broken at the end: two runs of the same scenario should name the same.
	var broken_ids: Array = []
	for st: Node in ([saloon] if saloon else get_tree().get_nodes_in_group(&"structures")):
		if not is_instance_valid(st) or not st is Structure:
			continue
		for m: StructureMember in (st as Structure).get_members():
			if m.broken:
				broken_ids.append(String(m.member_id))
	broken_ids.sort()
	summary.setup["broken_ids_hash"] = hash(broken_ids)
	# What the stick's frame added, by class (the nodes in the tree just after it went off).
	var added: Array = []
	for k: String in census[1]:
		var n := int(census[1][k]) - int(census[0].get(k, 0))
		if n != 0:
			added.append([n, k])
	added.sort()
	added.reverse()
	summary["stick_added"] = added.slice(0, 12)
	summary.setup["broken_now"] = broken_ids.size()
	summary["broken_ids"] = broken_ids
	if String(opts.out) != "":
		var path := String(opts.out)
		if not path.is_absolute_path():
			path = ProjectSettings.globalize_path("res://").path_join(path)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		var full := summary.duplicate()
		full["frames"] = _frames
		f.store_string(JSON.stringify(full, " "))
		f.close()
		summary["out"] = path
	summary.erase("broken_ids")
	log_event("lab", "bf_blast: worst frame %.0f ms, %d over %.0f ms (%.1f s in all)" % [summary.worst_ms, summary.stalls, stall, summary.stall_s])
	return summary


## Sean's per-shot hitch (#385, more-cores step 2): a ball into the saloon's wall, each way in turn,
## each frame recorded (wall clock and Prof, as bf_blast), and per shot the worst frame in the
## second after it.
func _cmd_bf_shot(a: Array) -> Dictionary:
	var opts := {"from": "6.0,1.5,6.0", "dirs": "x,-x,z,-z", "gap": 1.0, "stall": STALL_MS, "out": ""}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var town := street.get_node_or_null(^"TownLife") as TownLife
	var built := street.get_node_or_null(^"SpecSaloon") != null
	var saloon := SpecSaloon.ensure(street, town.places if town else null) as Structure
	if not built:
		await physics_frames(30)
	await seconds(1.0)  # the build's own rebuilds and shadow out of the way
	var p := String(opts.from).split(",")
	var from := SpecSaloon.at(Vector3(float(p[0]), float(p[1]), float(p[2])))
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var t: RevolverTuning = load("res://config/revolver.tres")
	var sizes: Array = []
	for key: Variant in saloon._batch_members:
		sizes.append((saloon._batch_members[key] as Array).size())
	sizes.sort()
	_frames.clear()
	_event_tick = -1
	Prof.on = true
	Prof._sum.clear()
	_last_us = Time.get_ticks_usec()
	_recording = true
	await seconds(0.5)
	var shots: Array = []
	for d: String in String(opts.dirs).split(","):
		var axis := {"x": Vector3.RIGHT, "-x": Vector3.LEFT, "z": Vector3.BACK, "-z": Vector3.FORWARD}.get(d, Vector3.FORWARD) as Vector3
		# The saloon's own axes in the world (it may stand turned).
		var dir := (SpecSaloon.at(axis) - SpecSaloon.at(Vector3.ZERO)).normalized()
		var damaged := [0]
		var on_damaged := func(_info: Dictionary) -> void: damaged[0] += 1
		Events.bullet_hit.connect(on_damaged)
		var tick := Engine.get_physics_frames()
		_event_tick = tick
		ballistics.fire(from, dir, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, [])
		await seconds(float(opts.gap))
		Events.bullet_hit.disconnect(on_damaged)
		var worst := {}
		for f: Dictionary in _frames:
			if int(f.tick) >= tick and (worst.is_empty() or float(f.ms) > float(worst.ms)):
				worst = f
		shots.append({"dir": d, "hits": damaged[0], "worst_ms": worst.get("ms", 0.0),
				"worst_after_ticks": int(worst.get("tick", tick)) - tick, "top": _top(worst.get("prof", {}), 6)})
	_recording = false
	var summary := _summarise(float(opts.stall))
	summary["shots"] = shots
	summary["batches"] = {"count": saloon.batch_count(), "members": saloon.member_count(),
			"largest": sizes.slice(maxi(sizes.size() - 5, 0)), "median": sizes[sizes.size() / 2] if not sizes.is_empty() else 0}
	if String(opts.out) != "":
		var path := String(opts.out)
		if not path.is_absolute_path():
			path = ProjectSettings.globalize_path("res://").path_join(path)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		var full := summary.duplicate()
		full["frames"] = _frames
		f.store_string(JSON.stringify(full, " "))
		f.close()
		summary["out"] = path
	log_event("lab", "bf_shot: %s" % [shots.map(func(x: Dictionary) -> String: return "%s %.0f ms" % [x.dir, x.worst_ms])])
	return summary


func _cmd_bf_analyse(_a: Array) -> Dictionary:
	var town := street.get_node_or_null(^"TownLife") as TownLife
	var built := street.get_node_or_null(^"SpecSaloon") != null
	var saloon := SpecSaloon.ensure(street, town.places if town else null) as Structure
	if not built:
		await physics_frames(30)
	var out := {}
	for run in 2:  # the second with every member's geometry already kept
		var a := StructuralAnalysis.new(saloon.tuning)
		var t0 := Time.get_ticks_usec()
		a.begin(saloon)
		var t_begin := Time.get_ticks_usec() - t0
		var by_kind := {}
		var slow: Array = []
		var n := a.left()
		var t_all := Time.get_ticks_usec()
		for i in n:
			var m: StructureMember = a._sorted[a._next]
			var t := Time.get_ticks_usec()
			a.advance(1)
			var us := Time.get_ticks_usec() - t
			var k: Array = by_kind.get_or_add(String(m.kind), [0, 0, 0])
			k[0] += 1
			k[1] += us
			k[2] = maxi(k[2], us)
			slow.append([us, String(m.member_id), m.supported_by.size(), (a._received.get(m.member_id, {}) as Dictionary).size()])
		var total := Time.get_ticks_usec() - t_all
		slow.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
		var kinds := {}
		for k: String in by_kind:
			var v: Array = by_kind[k]
			kinds[k] = "n %d mean %.0f worst %d (total %.1f ms)" % [v[0], float(v[1]) / v[0], v[2], v[1] / 1000.0]
		var whole := StructuralAnalysis.new(saloon.tuning)
		var t_w := Time.get_ticks_usec()
		whole.begin(saloon)
		whole.advance(whole.left())
		out["whole%d_ms" % run] = (Time.get_ticks_usec() - t_w) / 1000.0  # begin and every member in one go, untimed inside
		out["run%d" % run] = {"begin_ms": t_begin / 1000.0, "members": n, "advance_ms": total / 1000.0,
				"us_a_member": float(total) / maxi(n, 1), "kinds": kinds, "slowest": slow.slice(0, 10)}
	return out


func _cmd_bf_batches(_a: Array) -> Dictionary:
	var rows: Array = []
	var total := 0
	for s: Node in get_tree().get_nodes_in_group(&"structures"):
		var st := s as Structure
		if st == null:
			continue
		total += st.batch_count()
		rows.append([st.batch_count(), String(st.name), st.member_count()])
	rows.sort()
	return {"structures": rows.size(), "batches": total, "largest": rows.slice(maxi(rows.size() - 5, 0))}


func _cmd_bf_frames(a: Array) -> Dictionary:
	var n := int(a[0]) if a.size() > 0 else 20
	return {"frames": _frames.slice(maxi(_frames.size() - n, 0))}


## The headline: the worst frame and what was in it, every frame over the stall line, the sum of the
## blast's own timers over the recording.
func _summarise(stall: float) -> Dictionary:
	var worst := {}
	var stalls: Array = []
	var stall_s := 0.0
	var totals := {}
	var after_sum := 0.0
	var after_n := 0
	for f in _frames:
		var ms: float = f.ms
		if worst.is_empty() or ms > float(worst.ms):
			worst = f
		if ms > stall:
			stalls.append({"tick": f.tick, "after": f.after, "ms": snappedf(ms, 0.1), "top": _top(f.prof, 5)})
			stall_s += ms / 1000.0
		for k: String in f.prof:
			totals[k] = float(totals.get(k, 0.0)) + float(f.prof[k])
		if int(f.after) > 60 and int(f.after) <= 60 * 6:
			after_sum += ms
			after_n += 1
	var keys := totals.keys()
	keys.sort_custom(func(x: String, y: String) -> bool: return totals[x] > totals[y])
	var tot := {}
	for k: String in keys.slice(0, 16):
		tot[k] = snappedf(totals[k], 0.1)
	return {"frames": _frames.size(), "worst_ms": snappedf(float(worst.get("ms", 0.0)), 0.1),
			"worst_after": worst.get("after", -1), "worst_top": _top(worst.get("prof", {}), 8),
			"stalls": stalls.size(), "stall_s": snappedf(stall_s, 0.2), "stall_frames": stalls.slice(0, 12),
			"after_mean_ms": snappedf(after_sum / maxf(after_n, 1.0), 0.1), "totals_ms": tot}


static func _top(prof: Dictionary, n: int) -> Array:
	var keys := prof.keys()
	keys.sort_custom(func(x: String, y: String) -> bool: return prof[x] > prof[y])
	var out: Array = []
	for k: String in keys.slice(0, n):
		out.append("%s %.1f" % [k, prof[k]])
	return out


func _census() -> Dictionary:
	var out := {}
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var k := n.get_class()
		if n is RigidBody3D:
			k += ":rubble" if n.is_in_group(&"rubble") else ":%s<%s>" % [n.get_parent().name if n.get_parent() else "", n.get_script().resource_path.get_file() if n.get_script() else ""]
		out[k] = int(out.get(k, 0)) + 1
		stack.append_array(n.get_children())
	return out


## The rubble bodies in the world, or those of them awake (moving: the physics engine's work).
func _rubble_count(awake: bool) -> int:
	var n := 0
	for rb: Node in get_tree().get_nodes_in_group(&"rubble"):
		if not awake or not (rb as RigidBody3D).sleeping:
			n += 1
	return n


func _process(_delta: float) -> void:
	if not _recording:
		return
	var now := Time.get_ticks_usec()
	var tick := Engine.get_physics_frames()
	var prof := {}
	for k: StringName in Prof._sum:
		prof[String(k)] = snappedf(float(Prof._sum[k]) / 1000.0, 0.01)
	var fire := FireSystem.find(get_tree())
	_frames.append({"tick": tick, "after": tick - _event_tick if _event_tick >= 0 else -1,
			"ms": snappedf((now - _last_us) / 1000.0, 0.01), "prof": prof,
			"hot": fire.active.size() if fire else 0, "broken": _broken,
			"set": fire._check.last_set if fire and fire._check else -1,
			"seeds": fire._check.last_seeds if fire and fire._check else -1,
			"left": fire._check.left() if fire and fire._check else -1,
			"queue": fire._to_settle.size() if fire else -1,
			"active": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS),
			"rubble": _rubble_count(false), "awake": _rubble_count(true),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT)})
	Prof._sum.clear()
	_last_us = now
