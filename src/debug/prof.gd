class_name Prof
## Where the frame goes, by system, for F3 and tools/perf_bench.gd: each system's frame entry
## (its _process / _physics_process) is timed while `on` (F3 open, or the bench), and adds up per
## frame. Off, a timer costs one call that returns 0.

static var on := false
## system -> microseconds spent since the last `roll()`
static var _sum := {}
static var _frames := 0
## system -> milliseconds a frame, averaged over the last window
static var per_frame := {}
## The last `frame()`'s own frame (BugRecorder's ring, #433): system -> ms since the frame before
## (keys stay once seen, 0 when it took nothing), its TOP biggest costs largest first (counts,
## q_* and n_*, left out; &"" past the last), and Engine.get_process_frames() when it was taken.
const TOP := 8
static var frame_ms := {}
static var frame_top_names: Array[StringName] = [&"", &"", &"", &"", &"", &"", &"", &""]
static var frame_top_ms := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0])
static var frame_number := -1
## system -> _sum at the last frame(), and whether it's a cost (not a count).
static var _seen := {}
static var _cost := {}
static var _rolled_at := 0


static func start() -> int:
	return Time.get_ticks_usec() if on else 0


## `n` of something this frame (a ray, a part moved): per_frame shows the count a frame, as if ms.
static func count(system: StringName, n := 1) -> void:
	if on:
		_sum[system] = int(_sum.get(system, 0)) + n * 1000


## `usec` microseconds measured elsewhere (PhysicsWindow).
static func add(system: StringName, usec: int) -> void:
	if on:
		_sum[system] = int(_sum.get(system, 0)) + usec


static func stop(system: StringName, t0: int) -> void:
	if t0 != 0:
		_sum[system] = int(_sum.get(system, 0)) + Time.get_ticks_usec() - t0


## Once a frame (the overlay): the frame's own costs into `frame_ms`/`frame_top_*`, and every
## `window` frames or `seconds` of wall clock, whichever comes first, the sums become `per_frame`
## (by frames alone, F3 at 3 fps showed nothing for 20 s). The clock only says when the readout
## rolls; nothing a tick does reads it.
static func frame(window := 60, seconds := 1.0) -> void:
	_frames += 1
	_take_frame()
	var now := Time.get_ticks_usec()
	if _frames >= window or now - _rolled_at >= int(seconds * 1000000.0):
		roll()


## What each system took since the last frame(): the sums' growth (a lab clearing `_sum` reads as
## the sum itself).
static func _take_frame() -> void:
	for k: StringName in frame_ms:
		frame_ms[k] = 0.0
	for i in TOP:
		frame_top_names[i] = &""
		frame_top_ms[i] = 0.0
	for k: StringName in _sum:
		var v: int = _sum[k]
		var d: int = v - int(_seen.get(k, 0))
		if d < 0:
			d = v
		_seen[k] = v
		var ms := d / 1000.0
		frame_ms[k] = ms
		if not _cost.has(k):
			_cost[k] = not (String(k).begins_with("q_") or String(k).begins_with("n_"))
		if not _cost[k] or ms <= frame_top_ms[TOP - 1]:
			continue
		var i := TOP - 1
		while i > 0 and frame_top_ms[i - 1] < ms:
			frame_top_ms[i] = frame_top_ms[i - 1]
			frame_top_names[i] = frame_top_names[i - 1]
			i -= 1
		frame_top_ms[i] = ms
		frame_top_names[i] = k
	frame_number = Engine.get_process_frames()


static func roll() -> void:
	per_frame.clear()
	for k: StringName in _sum:
		per_frame[k] = float(_sum[k]) / 1000.0 / maxf(_frames, 1)
	_sum.clear()
	_seen.clear()
	_frames = 0
	_rolled_at = Time.get_ticks_usec()


## The biggest `n`, as "name 1.23" pieces, largest first.
static func top(n := 8) -> PackedStringArray:
	var keys := per_frame.keys()
	keys.sort_custom(func(a: StringName, b: StringName) -> bool: return per_frame[a] > per_frame[b])
	var out: PackedStringArray = []
	for k: StringName in keys.slice(0, n):
		out.append("%s %.2f" % [k, per_frame[k]])
	return out
