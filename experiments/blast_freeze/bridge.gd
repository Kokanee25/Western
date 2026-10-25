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
	"bf_blast": "bf_blast [at=X,Y,Z] [fire=N] [burn=S] [fuse=S] [seconds=S] [stall=MS] [out=FILE.json] -> the spec saloon (built if it isn't), N members alight near `at` (the saloon's own space) and left to burn S s, then a stick there and every frame recorded for S s after: the worst frame, frames over the stall line, where the time went",
	"bf_frames": "bf_frames [N] -> the last N recorded frames (bf_blast), newest last",
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
	var opts := {"at": "6.0,0.8,6.0", "fire": 0, "burn": 20.0, "fuse": 1.0, "seconds": 8.0, "stall": STALL_MS, "out": ""}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var town := street.get_node_or_null(^"TownLife") as TownLife
	var built := street.get_node_or_null(^"SpecSaloon") != null
	var saloon := SpecSaloon.ensure(street, town.places if town else null) as Structure
	if not built:
		await physics_frames(30)
	var parts := String(opts.at).split(",")
	if parts.size() != 3:
		return {"ok": false, "error": "at=X,Y,Z (the saloon's own space)"}
	var local := Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	var at := SpecSaloon.at(local)
	var fire := FireSystem.find(get_tree())
	var lit: Array = []
	var n_fire := int(opts.fire)
	if n_fire > 0 and fire:
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
	var members_before := saloon.member_count()
	var rubble_before := saloon.rubble.size()
	# Record from a second before the stick to `seconds` after it goes off.
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
	stick.went_off.connect(func() -> void: _event_tick = Engine.get_physics_frames())
	await seconds(float(opts.fuse) + float(opts.seconds))
	_recording = false
	Events.member_broken.disconnect(on_broken)
	Events.member_cut.disconnect(on_cut)
	var stall := float(opts.stall)
	var summary := _summarise(stall)
	summary["setup"] = {"at": arr(at), "at_local": [local.x, local.y, local.z], "lit": lit, "burn_s": float(opts.burn),
			"burning_before": burning_before, "members_before": members_before, "rubble_before": rubble_before,
			"members_after": saloon.member_count(), "rubble_after": saloon.rubble.size(),
			"burning_after": fire.burning_members().size() if fire else 0, "broken": _broken, "cut": _cut,
			"people": get_tree().get_nodes_in_group(&"people").size(), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
	# Which members are broken at the end: two runs of the same scenario should name the same.
	var broken_ids: Array = []
	for m: StructureMember in saloon.get_members():
		if m.broken:
			broken_ids.append(String(m.member_id))
	broken_ids.sort()
	summary.setup["broken_ids_hash"] = hash(broken_ids)
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
			"active": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS)})
	Prof._sum.clear()
	_last_us = now
