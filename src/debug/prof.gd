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


static func start() -> int:
	return Time.get_ticks_usec() if on else 0


static func stop(system: StringName, t0: int) -> void:
	if t0 != 0:
		_sum[system] = int(_sum.get(system, 0)) + Time.get_ticks_usec() - t0


## Once a frame (the overlay, or the bench): every `window` frames the sums become `per_frame`.
static func frame(window := 60) -> void:
	_frames += 1
	if _frames >= window:
		roll()


static func roll() -> void:
	per_frame.clear()
	for k: StringName in _sum:
		per_frame[k] = float(_sum[k]) / 1000.0 / maxf(_frames, 1)
	_sum.clear()
	_frames = 0


## The biggest `n`, as "name 1.23" pieces, largest first.
static func top(n := 8) -> PackedStringArray:
	var keys := per_frame.keys()
	keys.sort_custom(func(a: StringName, b: StringName) -> bool: return per_frame[a] > per_frame[b])
	var out: PackedStringArray = []
	for k: StringName in keys.slice(0, n):
		out.append("%s %.2f" % [k, per_frame[k]])
	return out
