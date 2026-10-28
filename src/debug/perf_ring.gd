class_name PerfRing
extends RefCounted
## The frame's numbers for the bug report (#433; BugRecorder, F12): every frame what it took (the
## wall clock between frames, the engine's process and physics time, how many physics ticks ran,
## the renderer's CPU and GPU time, what it drew, nodes, bodies awake) and, while F3 is up (Prof on
## and rolled each frame by the overlay), the eight systems that cost most. Kept in fixed rings
## (nothing allocated a frame): the last FRAME_SECONDS at every frame (up to FRAMES of them) and
## the last SECONDS seconds as one-second means and worsts. F12 writes them as `perf.json` and a
## `perf_summary` at the top of `report.json`; `tools/perf_report.py` reads them.
##
## Only what the engine and Prof already measure is read (no new queries); `sample()` runs on the
## main thread, in BugRecorder's _process (last in the frame), and nothing it notes changes a tick.
## The process/physics split is the engine's own (the previous frame's process, this frame's
## physics); render times lag the frame by one or two.

const FIELDS: PackedStringArray = ["frame_ms", "process_ms", "physics_ms", "ticks", "render_cpu_ms",
		"render_gpu_ms", "draws", "objects", "nodes", "bodies_awake"]
const NF := 10
const TOP := 8
## Frames kept: FRAME_SECONDS of them up to 273 fps.
const FRAMES := 4096
const FRAME_SECONDS := 15.0
const SECONDS := 600
## A frame: t (s since the start), the fields, TOP system ids (index into _names + 1, 0 none), their ms.
const FSTRIDE := 1 + NF + 2 * TOP
## A second: t, frames, the fields' means, their worsts, TOP system ids, their mean ms over the
## frames that had them (the profiler on).
const SSTRIDE := 2 + 2 * NF + 2 * TOP

var _frames := PackedFloat32Array()
var _fn := 0  # frames written; the next goes at _fn % FRAMES
var _secs := PackedFloat32Array()
var _sn := 0
var _names: Array[StringName] = []
var _ids := {}
var _is_cost := PackedByteArray()
var _start := 0
var _last := 0
var _last_ticks := 0
var _row := PackedFloat32Array()
## Viewports measured (the root and every SubViewport), by RID.
var _viewports: Array[RID] = []
## Reading a render time makes a separate render thread wait for the main one (perf_bench's
## note), so with that thread model it's read only while F3 is up.
var _render_every_frame := true
# This second so far.
var _sec_start := 0
var _sec_n := 0
var _sec_sum := PackedFloat64Array()
var _sec_max := PackedFloat32Array()
var _sec_prof := 0
var _sec_sys := {}  # name id -> ms summed this second
## What sample() itself costs, in µs, with F3 closed [0] and open [1] (the gate: under 0.1 ms open).
var cost_sum := PackedInt64Array([0, 0])
var cost_n := PackedInt64Array([0, 0])
var cost_worst := PackedInt64Array([0, 0])


func _init() -> void:
	_frames.resize(FRAMES * FSTRIDE)
	_secs.resize(SECONDS * SSTRIDE)
	_row.resize(NF)
	_sec_sum.resize(NF)
	_sec_max.resize(NF)
	_render_every_frame = int(ProjectSettings.get_setting("rendering/driver/threads/thread_model", 1)) != 2


## Measure `vp`'s render time from now on (until it leaves the tree).
func watch(vp: Viewport) -> void:
	var rid := vp.get_viewport_rid()
	if _viewports.has(rid):
		return
	RenderingServer.viewport_set_measure_render_time(rid, true)
	_viewports.append(rid)
	vp.tree_exiting.connect(_forget.bind(rid), CONNECT_ONE_SHOT)


func _forget(rid: RID) -> void:
	_viewports.erase(rid)


## Once a frame, on the main thread.
func sample() -> void:
	var t0 := Time.get_ticks_usec()
	var ticks := Engine.get_physics_frames()
	if _last == 0:
		_start = t0
		_last = t0
		_sec_start = t0
		_last_ticks = ticks
		return
	var cpu := 0.0
	var gpu := 0.0
	if _render_every_frame or Prof.on:
		for rid in _viewports:
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	_row[0] = (t0 - _last) / 1000.0
	_row[1] = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_row[2] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_row[3] = ticks - _last_ticks
	_row[4] = cpu
	_row[5] = gpu
	_row[6] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_row[7] = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	_row[8] = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_row[9] = Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)
	_last = t0
	_last_ticks = ticks
	if t0 - _sec_start >= 1000000:
		_close_second(t0)
	var prof := Prof.frame_number == Engine.get_process_frames()
	var base := (_fn % FRAMES) * FSTRIDE
	_frames[base] = (t0 - _start) / 1000000.0
	for i in NF:
		_frames[base + 1 + i] = _row[i]
		_sec_sum[i] += _row[i]
		_sec_max[i] = maxf(_sec_max[i], _row[i])
	for i in TOP:
		var name: StringName = Prof.frame_top_names[i] if prof else &""
		_frames[base + 1 + NF + i] = _id(name) + 1 if name != &"" else 0
		_frames[base + 1 + NF + TOP + i] = Prof.frame_top_ms[i] if name != &"" else 0.0
	_fn += 1
	_sec_n += 1
	if prof:
		_sec_prof += 1
		for k: StringName in Prof.frame_ms:
			var ms: float = Prof.frame_ms[k]
			if ms > 0.0:
				var id := _id(k)
				_sec_sys[id] = float(_sec_sys.get(id, 0.0)) + ms
	var spent := Time.get_ticks_usec() - t0
	var open := 1 if prof else 0
	cost_sum[open] += spent
	cost_n[open] += 1
	cost_worst[open] = maxi(cost_worst[open], spent)


func _id(name: StringName) -> int:
	var id: int = _ids.get(name, -1)
	if id < 0:
		id = _names.size()
		_names.append(name)
		_ids[name] = id
		_is_cost.append(0 if String(name).begins_with("q_") or String(name).begins_with("n_") else 1)
	return id


func _close_second(now: int) -> void:
	if _sec_n > 0:
		var row := _second_row()
		var base := (_sn % SECONDS) * SSTRIDE
		for i in SSTRIDE:
			_secs[base + i] = row[i]
		_sn += 1
	_sec_start = now
	_sec_n = 0
	_sec_prof = 0
	_sec_sys.clear()
	for i in NF:
		_sec_sum[i] = 0.0
		_sec_max[i] = 0.0


## This second so far, as a row of SSTRIDE.
func _second_row() -> PackedFloat32Array:
	var row := PackedFloat32Array()
	row.resize(SSTRIDE)
	row[0] = (_sec_start - _start) / 1000000.0
	row[1] = _sec_n
	for i in NF:
		row[2 + i] = _sec_sum[i] / maxf(_sec_n, 1)
		row[2 + NF + i] = _sec_max[i]
	var ids := _sec_sys.keys().filter(func(id: int) -> bool: return _is_cost[id] == 1)
	ids.sort_custom(func(a: int, b: int) -> bool: return _sec_sys[a] > _sec_sys[b])
	for i in mini(TOP, ids.size()):
		row[2 + 2 * NF + i] = ids[i] + 1
		row[2 + 2 * NF + TOP + i] = _sec_sys[ids[i]] / maxf(_sec_prof, 1)
	return row


# -- The report ------------------------------------------------------------------------------------

## The two rings as perf.json: rows of numbers under their columns, each row's last item its
## systems {name: ms}.
func to_dict() -> Dictionary:
	var frames := []
	for b in _frame_bases():
		var row := [snappedf(_frames[b], 0.001)]
		for i in NF:
			row.append(snappedf(_frames[b + 1 + i], 0.01))
		row.append(_systems(_frames, b + 1 + NF))
		frames.append(row)
	var seconds := []
	var rows: Array[PackedFloat32Array] = []
	for s in range(maxi(0, _sn - SECONDS), _sn):
		rows.append(_secs.slice((s % SECONDS) * SSTRIDE, (s % SECONDS + 1) * SSTRIDE))
	if _sec_n > 0:
		rows.append(_second_row())
	for r in rows:
		var row := [snappedf(r[0], 0.01), int(r[1])]
		for i in 2 * NF:
			row.append(snappedf(r[2 + i], 0.01))
		row.append(_systems(r, 2 + 2 * NF))
		seconds.append(row)
	var worsts := PackedStringArray()
	for f in FIELDS:
		worsts.append(f + "_worst")
	return {
		"about": "BugRecorder's timing rings (src/debug/perf_ring.gd): frames, the last %d s at every frame; seconds, the last %d s as means and worsts; ms unless named; systems (Prof) only while F3 was up" % [int(FRAME_SECONDS), SECONDS],
		"frames_columns": ["t"] + Array(FIELDS) + ["systems"],
		"frames": frames,
		"seconds_columns": ["t", "frames"] + Array(FIELDS) + Array(worsts) + ["systems"],
		"seconds": seconds,
		"recorder_us": _costs(),
		"render_time_every_frame": _render_every_frame,
	}


func _costs() -> Dictionary:
	var out := {}
	for i in 2:
		out["f3_open" if i == 1 else "f3_closed"] = {"mean": snappedf(float(cost_sum[i]) / maxf(cost_n[i], 1), 0.1),
				"worst": cost_worst[i], "frames": cost_n[i]}
	return out


## The ring's frames from the last FRAME_SECONDS, oldest first (their offsets in _frames).
func _frame_bases() -> PackedInt32Array:
	var out := PackedInt32Array()
	if _fn == 0:
		return out
	var newest := _frames[((_fn - 1) % FRAMES) * FSTRIDE]
	for f in range(maxi(0, _fn - FRAMES), _fn):
		var b := (f % FRAMES) * FSTRIDE
		if _frames[b] >= newest - FRAME_SECONDS:
			out.append(b)
	return out


func _systems(a: PackedFloat32Array, at: int) -> Dictionary:
	var out := {}
	for i in TOP:
		var id := int(a[at + i])
		if id > 0:
			out[String(_names[id - 1])] = snappedf(a[at + TOP + i], 0.01)
	return out


## The worst frame of the last FRAME_SECONDS with its split and systems, the mean and the 95th
## percentile, the three biggest costs over the frames the profiler saw, and the worst second.
func summary() -> Dictionary:
	var bases := _frame_bases()
	if bases.is_empty():
		return {"frames": 0}
	var ms := PackedFloat32Array()
	var worst := bases[0]
	var sums := {}
	var prof := 0
	for b in bases:
		ms.append(_frames[b + 1])
		if _frames[b + 1] > _frames[worst + 1]:
			worst = b
		if _frames[b + 1 + NF] > 0:
			prof += 1
			for i in TOP:
				var id := int(_frames[b + 1 + NF + i])
				if id > 0:
					sums[id] = float(sums.get(id, 0.0)) + _frames[b + 1 + NF + TOP + i]
	var sorted := ms.duplicate()
	sorted.sort()
	var split := {"at": snappedf(_frames[worst], 0.01)}
	for i in NF:
		split[FIELDS[i]] = snappedf(_frames[worst + 1 + i], 0.01)
	split["systems"] = _systems(_frames, worst + 1 + NF)
	# What none of the three accounts for: a load, the engine's own work, a stall (#437's review).
	split["untimed_ms"] = snappedf(maxf(0.0, _frames[worst + 1] - _frames[worst + 2] - _frames[worst + 3] - _frames[worst + 5]), 0.01)
	var ids := sums.keys()
	ids.sort_custom(func(a: int, b: int) -> bool: return sums[a] > sums[b])
	var biggest := []
	for id: int in ids.slice(0, 3):
		biggest.append({"name": String(_names[id - 1]), "ms": snappedf(sums[id] / prof, 0.01)})
	var total := 0.0
	for x in ms:
		total += x
	var out := {
		"seconds": snappedf(_frames[bases[bases.size() - 1]] - _frames[bases[0]], 0.01),
		"frames": bases.size(), "mean_ms": snappedf(total / bases.size(), 0.01),
		"p95_ms": snappedf(sorted[mini(sorted.size() - 1, int(round(0.95 * (sorted.size() - 1))))], 0.01),
		"worst": split, "biggest": biggest, "profiler_frames": prof,
		"recorder_us": _costs(),
	}
	var worst_s := -1
	var worst_mean := -1.0
	for s in range(maxi(0, _sn - SECONDS), _sn):
		var m := _secs[(s % SECONDS) * SSTRIDE + 2]
		if m > worst_mean:
			worst_mean = m
			worst_s = s
	if worst_s >= 0:
		var b := (worst_s % SECONDS) * SSTRIDE
		out["worst_second"] = {"at": snappedf(_secs[b], 0.01), "frames": int(_secs[b + 1]),
				"mean_ms": snappedf(_secs[b + 2], 0.01), "worst_ms": snappedf(_secs[b + 2 + NF], 0.01)}
	return out


## The summary in a few lines (the replay prints them first; perf_report.py says the same).
static func summary_lines(s: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if int(s.get("frames", 0)) == 0:
		out.append("perf: no frames recorded")
		return out
	var w: Dictionary = s.worst
	out.append("perf: the last %.1f s, %d frames: mean %.1f ms (%.0f fps), p95 %.1f, worst %.1f at %.1f s" % [
			s.seconds, s.frames, s.mean_ms, 1000.0 / maxf(s.mean_ms, 0.001), s.p95_ms, w.frame_ms, w.at])
	out.append("  the worst frame: process %.1f, physics %.1f (%d ticks), render cpu %.1f, gpu %.1f, untimed %.1f; draws %d, objects %d, nodes %d, bodies awake %d" % [
			w.process_ms, w.physics_ms, int(w.ticks), w.render_cpu_ms, w.render_gpu_ms, float(w.get("untimed_ms", 0.0)),
			int(w.draws), int(w.objects), int(w.nodes), int(w.bodies_awake)])
	if not (w.systems as Dictionary).is_empty():
		out.append("  its systems: " + _pieces(w.systems))
	if (s.biggest as Array).is_empty():
		out.append("  systems: none (the profiler is on only while F3 is up: open F3, then F12)")
	else:
		var big := {}
		for b: Dictionary in s.biggest:
			big[b.name] = b.ms
		out.append("  biggest a frame (over the %d frames F3 was up): %s" % [s.profiler_frames, _pieces(big)])
	if s.has("worst_second"):
		var ws: Dictionary = s.worst_second
		out.append("  the worst second of the last %d min: at %.0f s, mean %.1f ms, worst %.1f (%d frames)" % [
				int(SECONDS / 60.0), ws.at, ws.mean_ms, ws.worst_ms, ws.frames])
	return out


static func _pieces(d: Dictionary) -> String:
	var parts := PackedStringArray()
	for k: String in d:
		parts.append("%s %.2f" % [k, d[k]])
	return "  ".join(parts)
