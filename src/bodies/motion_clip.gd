class_name MotionClip
extends RefCounted
## A clip of motion for a HumanBody (docs/MOCAP.md; DESIGN.md §7 "Bodies in motion"): each
## segment's turn from its parent's, as quaternions sampled at a fixed rate, with the root's travel
## in his own frame, his heading and his hips' height, read from `assets/animations/<name>.json`
## (made by `tools/blender/retarget_motion.py` from a captured or generated motion, beside the glTF
## it also writes). Played by `HumanBody.play_clip` as the targets his pose follows: the rig turns
## toward each frame, his root moves by the clip's travel through the same sliding and
## ground-snapping as walking, and what physics says wins (a wall or a man in his way stops the
## travel, a chair leg his boot meets takes the blow and may stop the boot, a ball that drops him
## ends the clip in the ragdoll).

static var _cache := {}

var name: StringName
var fps := 30.0
var frames: Array = []  ## [{segment: Quaternion}], one a sample
var root := PackedVector3Array()  ## the pelvis in his frame (x his right, -z ahead) each sample, m
var yaw := PackedFloat32Array()  ## his hips' heading each sample from the first's (rad; + turns left): what the clip's pelvis turn carries, for whoever reads it
var hips := PackedFloat32Array()  ## hip joints' height over the ground in leg lengths; empty: none
var events := {}  ## name -> seconds: "strike" (the boot lands), "draw" (his hand's on the gun)
var strikes: Array[StringName] = []  ## parts that strike what they meet while it plays (foot_r)
var source := ""


## The clip called `n`, loaded once (null when there's no such file).
static func load_clip(n: StringName) -> MotionClip:
	if _cache.has(n):
		return _cache[n]
	var clip: MotionClip = null
	var path := "res://assets/animations/%s.json" % n
	if FileAccess.file_exists(path):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			clip = MotionClip.new()
			clip._read(n, d)
	_cache[n] = clip
	return clip


func _read(n: StringName, d: Dictionary) -> void:
	name = n
	fps = float(d.get("fps", 30.0))
	source = String(d.get("source", ""))
	for fr: Dictionary in d.get("frames", []):
		var q := {}
		for key: String in fr:
			var a: Array = fr[key]
			q[StringName(key)] = Quaternion(a[0], a[1], a[2], a[3]).normalized()
		frames.append(q)
	for p: Array in d.get("root", []):
		root.append(Vector3(p[0], p[1], p[2]))
	for y: float in d.get("yaw", []):
		yaw.append(y)
	for h: float in d.get("hip_height", []):
		hips.append(h)
	events = d.get("events", {})
	for s: String in d.get("strikes", []):
		strikes.append(StringName(s))


## How long it plays (s).
func length() -> float:
	return (frames.size() - 1) / fps if frames.size() > 1 else 0.0


## Where in the samples `t` falls: [first sample, the next, how far between].
func _at(t: float) -> Array:
	var n := frames.size()
	if n == 0:
		return [0, 0, 0.0]
	var f := clampf(t * fps, 0.0, float(n - 1))
	var i0 := mini(int(f), n - 1)
	var i1 := mini(i0 + 1, n - 1)
	return [i0, i1, f - float(i0)]


## Each segment's turn at `t` (segment -> Quaternion), blended between samples.
func sample(t: float) -> Dictionary:
	var a := _at(t)
	var out := {}
	if frames.is_empty():
		return out
	var f0: Dictionary = frames[a[0]]
	var f1: Dictionary = frames[a[1]]
	for sid: StringName in f0:
		out[sid] = (f0[sid] as Quaternion).slerp(f1.get(sid, f0[sid]), a[2])
	return out


## The root's place in his frame at `t` (m).
func root_at(t: float) -> Vector3:
	if root.is_empty():
		return Vector3.ZERO
	var a := _at(t)
	return root[mini(a[0], root.size() - 1)].lerp(root[mini(a[1], root.size() - 1)], a[2])


## His heading at `t` from the clip's first sample (rad).
func yaw_at(t: float) -> float:
	if yaw.is_empty():
		return 0.0
	var a := _at(t)
	return lerp_angle(yaw[mini(a[0], yaw.size() - 1)], yaw[mini(a[1], yaw.size() - 1)], a[2])


## His hip joints' height at `t` in leg lengths (-1: the clip doesn't say).
func hips_at(t: float) -> float:
	if hips.is_empty():
		return -1.0
	var a := _at(t)
	return lerpf(hips[mini(a[0], hips.size() - 1)], hips[mini(a[1], hips.size() - 1)], a[2])


## The names of the events between `t0` (exclusive) and `t1` (inclusive).
func events_between(t0: float, t1: float) -> Array:
	var out := []
	for k: String in events:
		var at := float(events[k])
		if at > t0 and at <= t1:
			out.append(k)
	return out
