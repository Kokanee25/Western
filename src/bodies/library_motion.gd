class_name LibraryMotion
extends RefCounted
## A man moved by library clips (issues #529, #539; `Settings.library_motion`, off in the game until
## Sean passes them): since #539 real people from CMU's motion-capture database (the free packs'
## cartoon clips didn't pass), retargeted onto our 17 segments
## (`tools/blender/library_motion.py`, `assets/animations/library/`, its manifest). The body picks
## the clip by its own state, never a brain's say: walking, running, backing or sidestepping by the
## way his feet take him, crouched, aiming, standing about; a hit he stays up from plays a small
## reaction on top (its own switch, `hits`). One a man (HumanBody._lib), worked out in his pose's
## maths (on a worker with PeopleTick: his own data and the clips, loaded beforehand on the main
## thread, only).
##
## What the clip has of him by his pose (`mask_for`): standing easy, all of him; aiming, his legs
## and his free arm only (the shot leaves down the gun's own barrel, `hand.barrel()`, so his gun arm
## and the trunk it hangs from stay the pose's aim; the procedural aim and recoil on top as
## before); crouched, all but his gun arm; his hands up, bound, clutching, wincing, shoving, his
## legs and hips while he walks. Down, getting up, stumbling, dragged, sat, lying, limping or
## crawling: nothing (physics and the pose, as before). Deaths stay the ragdoll's.

const DIR := "library/"
## The clips by move (assets/animations/library/<move>.json).
const MOVES: Array[StringName] = [&"walk_gun", &"run_gun", &"idle", &"walk", &"run", &"walk_back", &"strafe_l",
		&"strafe_r", &"crouch_walk", &"crouch_idle", &"pistol_aim", &"hit_front", &"hit_head"]
## A move with no clip (none yet: the aim, the reload and the hits are to come, #539) leaves him on
## his pose. In the library but not picked by any state (the tools show them: the lineup, the sheet).
const SHOWN: Array[StringName] = [&"reload", &"stagger"]
## Faster than this (m/s) over the ground, the run.
const RUN_FROM := 2.4
## Slower than this he's standing.
const MOVE_FROM := 0.3
## Sidestepping when his feet go more across than along (the sideways share of his travel).
const SIDE_FROM := 0.7
## s to cross from one clip to the next, and to come on or let go of the layer.
const XFADE_S := 0.2
const EASE_S := 0.2
## The rig the clips' strides were measured on (thigh + shin, experiments/mocap_walk/rig_rest.json).
const RIG_LEG_M := 0.8
## Turned off, the hit reactions alone (Sean's call: bullet hits carry no flinch since "just get rid
## of these winces"; the walks and stances don't depend on them).
static var hits := true

const ALL := [&"pelvis", &"abdomen", &"chest", &"neck", &"head", &"thigh_l", &"shin_l", &"foot_l",
		&"thigh_r", &"shin_r", &"foot_r", &"upper_arm_l", &"forearm_l", &"hand_l", &"upper_arm_r",
		&"forearm_r", &"hand_r"]
const LEGS := [&"thigh_l", &"shin_l", &"foot_l", &"thigh_r", &"shin_r", &"foot_r"]
const FREE_ARM := [&"upper_arm_l", &"forearm_l", &"hand_l"]
const GUN_ARM := [&"upper_arm_r", &"forearm_r", &"hand_r"]
## Poses whose legs and hips the clip may have while he walks; the pose keeps the rest of him.
const LEGS_ONLY := [&"hands_up", &"hands_bound", &"clutch", &"wince", &"shove"]
## Poses the clip never touches: what they do with his legs is the point of them.
const NONE := [&"duck", &"tend", &"cower", &"sit", &"sit_back", &"kick", &"lie", &"prone", &"prone_aim"]

static var _clips := {}  ## move -> MotionClip (null: no file)
static var _loaded := false
## Other people's walks and runs (the manifest's `variant_of`): the base move -> the clips a man's
## seed picks from (the base's own first); a `style` variant (a drunk's walk) only for a man named
## to it in config/walks.json's `library`.
static var _pool := {}
## Each gait's and idle's mean turn a joint (clip -> {segment: Quaternion}), for his arm swing.
static var _means := {}
const ARMS := [&"upper_arm_l", &"forearm_l", &"upper_arm_r", &"forearm_r"]
## A man's own: how much longer his stride than the clip's (his cadence), how much more his arms
## swing (both about 1, set by his seed: `choose`).
const STRIDE_SPREAD := 0.06
const ARM_SPREAD := 0.2

var move := &""  ## the clip he's on now
var w := 0.0  ## how far the layer has him (0..1)
var hips := -1.0  ## his hip joints' height in the clip, in leg lengths (-1: none)
var _phase := 0.0  ## a gait's place in its loop (0..1), by the ground he covers
var _t := 0.0  ## an idle's or a held clip's time (s)
var _from := {}  ## the last frame of the clip he's crossing from
var _xf := 1.0  ## how far across (0..1)
var _last := {}  ## his last frame out (for letting go)
## For the tools only (tools/library_lineup.gd): this move whatever his state, at this time (s;
## -1: as it plays).
var force := &""
var force_at := -1.0
var own := {}  ## base move -> his own variant (walk -> walk_e)
var stride_k := 1.0
var arm_k := 1.0
var _hit: MotionClip
var _hit_t := 0.0


## The clips, once, on the main thread (MotionClip's cache isn't for workers).
static func preload_clips() -> void:
	if _loaded:
		return
	_loaded = true
	for m: StringName in MOVES + SHOWN:
		_clips[m] = MotionClip.load_clip(StringName(DIR + String(m)))
	var path := "res://assets/animations/library/manifest.json"
	var man: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	var clips: Dictionary = (man as Dictionary).get("clips", {}) if man is Dictionary else {}
	for k: String in clips:
		var e: Dictionary = clips[k]
		if not e.has("variant_of"):
			continue
		var c := MotionClip.load_clip(StringName(DIR + k))
		if c == null:
			continue
		_clips[StringName(k)] = c
		var base := StringName(e.variant_of)
		if not e.get("style", false):
			if not _pool.has(base):
				_pool[base] = [base] if _clips.get(base) != null else []
			(_pool[base] as Array).append(StringName(k))
	for k: StringName in _clips:
		var c := _clips[k] as MotionClip
		if c != null and c.kind in [&"gait", &"idle"]:
			_means[k] = _mean_turns(c)


## Each arm joint's mean turn over the clip (a normalised sum, the signs lined up with the first).
static func _mean_turns(c: MotionClip) -> Dictionary:
	var out := {}
	for sid: StringName in ARMS:
		var sum := Vector4.ZERO
		var first := Quaternion.IDENTITY
		var have := false
		for fr: Dictionary in c.frames:
			if not fr.has(sid):
				continue
			var q: Quaternion = fr[sid]
			if not have:
				first = q
				have = true
			if q.dot(first) < 0.0:
				q = -q
			sum += Vector4(q.x, q.y, q.z, q.w)
		if have and sum.length() > 1e-6:
			sum = sum.normalized()
			out[sid] = Quaternion(sum.x, sum.y, sum.z, sum.w)
	return out


## His own walk and run, stride and arm swing (on the main thread, as he's made): a walk named for
## him or his model in config/walks.json's `library`, else one of the pool by his seed; his stride
## and swing a little either side of the clip's, by his seed too.
func choose(body: HumanBody) -> void:
	var h: int = hash(String(body.person_id)) ^ (body.rng_seed * 7919)
	var named := WalkStyles.library_for(body.person_id, body.body_model)
	for base: StringName in _pool:
		var pool: Array = _pool[base]
		if pool.is_empty():
			continue
		own[base] = pool[posmod(h, pool.size())]
	if named != &"" and _clips.get(named) != null:
		var base := StringName(String(named).split("_")[0])
		own[base] = named
	var r := RandomNumberGenerator.new()
	r.seed = h
	stride_k = 1.0 + r.randf_range(-STRIDE_SPREAD, STRIDE_SPREAD)
	arm_k = 1.0 + r.randf_range(-ARM_SPREAD, ARM_SPREAD)


static func clip(m: StringName) -> MotionClip:
	return _clips.get(m) as MotionClip


## Which of his joints the clip leads in `pose` (empty: none), armed or not.
static func mask_for(pose: StringName, armed: bool, moving: bool) -> Array:
	if pose in NONE:
		return []
	if pose == &"aim" or pose == &"crouch_aim":
		return LEGS + FREE_ARM
	if pose == &"crouch":
		return ALL.filter(func(s: StringName) -> bool: return not (armed and s in GUN_ARM))
	if pose in LEGS_ONLY:
		return ([&"pelvis"] + LEGS) if moving else []
	return ALL


## The move for his state: `pose`, how fast and which way his feet take him (`local`: his travel
## this tick in his own frame, x his right, -z ahead, m/s).
static func move_for(pose: StringName, gait: StringName, speed: float, local: Vector3) -> StringName:
	var crouched := pose == &"crouch" or pose == &"crouch_aim"
	var moving := speed >= MOVE_FROM and (gait == &"walk" or gait == &"run")
	if crouched:
		return &"crouch_walk" if moving else &"crouch_idle"
	if moving:
		var flat := Vector2(local.x, local.z)
		if flat.length() > 0.05:
			var across := absf(flat.x) / flat.length()
			if across > SIDE_FROM:
				return &"strafe_r" if flat.x > 0.0 else &"strafe_l"
			if flat.y > 0.0:
				return &"walk_back"
		return &"run" if speed > RUN_FROM else &"walk"
	if pose == &"aim":
		return &"pistol_aim"
	return &"idle"


## This tick's frame (segment -> Quaternion) for the joints the clip has of him, or {} when it has
## none (and the layer's eased off). `body`: a HumanBody, its own fields only.
func now(body: HumanBody, delta: float) -> Dictionary:
	var off: bool = body.limp or body.prone or body.rising or body.stumbling > 0.0 or body.dragged_by != null \
			or body.gait == &"limp" or body.gait == &"crawl"
	var armed: bool = body.held_gun != null and not body.gun_holstered
	var moving: bool = body.move_speed >= MOVE_FROM and (body.gait == &"walk" or body.gait == &"run")
	var mask := [] if off else mask_for(body.pose, armed, moving)
	var want := &"" if mask.is_empty() else move_for(body.pose, body.gait, body.move_speed, body.lib_travel)
	if force != &"" and not mask.is_empty():
		want = force
	elif armed and (want == &"walk" or want == &"run") and clip(StringName(String(want) + "_gun")) != null:
		# A gun in his hand: Uthana's walk and run holding it (#539), not his own empty-handed one.
		want = StringName(String(want) + "_gun")
	elif own.has(want):
		want = own[want]
	var c := clip(want) if want != &"" else null
	if c == null or c.frames.is_empty():
		w = move_toward(w, 0.0, delta / EASE_S)
		hips = -1.0
		move = &""
		return _last if w > 0.0 else {}
	if want != move:
		if move != &"":
			_from = _last.duplicate()
			_xf = 0.0
		if c.kind != &"gait":
			_t = 0.0
		move = want
	w = move_toward(w, 1.0, delta / EASE_S)
	_xf = move_toward(_xf, 1.0, delta / XFADE_S)
	var at := 0.0
	var length := c.length()
	if c.kind == &"gait" and c.stride > 0.0:
		var stride := c.stride * stride_k * body.leg_length() / RIG_LEG_M
		_phase = fposmod(_phase + delta * body.move_speed / maxf(stride, 0.1), 1.0)
		at = _phase * length
	else:
		_t += delta
		at = fposmod(_t, length) if c.loop and length > 0.0 else minf(_t, length)
	if force_at >= 0.0:
		at = minf(force_at, length)
	var f := c.sample(at)
	hips = c.hips_at(at)
	var out := {}
	var means: Dictionary = _means.get(move, {}) if absf(arm_k - 1.0) > 0.01 else {}
	for sid: StringName in mask:
		if not f.has(sid):
			continue
		var q: Quaternion = f[sid]
		if means.has(sid):
			# His arm swing: the clip's turn about its mean, more or less.
			var mean: Quaternion = means[sid]
			var d := (mean.inverse() * q).normalized()
			var ang := d.get_angle()
			if ang > 1e-4:
				q = (mean * Quaternion(d.get_axis().normalized(), ang * arm_k)).normalized()
		if _xf < 1.0 and _from.has(sid):
			q = (_from[sid] as Quaternion).slerp(q, smoothstep(0.0, 1.0, _xf))
		out[sid] = q
	_last = out
	return out


## Down (the ragdoll has him): the layer lets go at once, as a played clip does.
func let_go() -> void:
	w = 0.0
	move = &""
	hips = -1.0
	_last = {}
	_hit = null


## A small reaction to a hit he stays up from, on top of whatever has him (each joint turned by
## what the clip turns from its first frame): from the front only, the head's for a head or neck
## hit, else the chest's. The libraries have no hits from behind or the side.
func on_hit(body: HumanBody, info: Dictionary) -> void:
	if not hits or body.limp or body.prone:
		return
	var dir: Vector3 = info.get("direction", Vector3.ZERO)
	var ahead := -body.global_basis.z
	if Vector2(dir.x, dir.z).length() < 0.1 or Vector2(dir.x, dir.z).normalized().dot(Vector2(ahead.x, ahead.z).normalized()) > -0.3:
		return  # not from in front of him
	var seg: StringName = info.get("segment", &"")
	_hit = clip(&"hit_head" if seg == &"head" or seg == &"neck" else &"hit_front")
	_hit_t = 0.0


## The hit's turns this tick (segment -> Quaternion, each a turn on top of his joint), {} when none.
## His gun arm is left alone.
func hit_now(delta: float) -> Dictionary:
	if _hit == null:
		return {}
	_hit_t += delta
	var length := _hit.length()
	if _hit_t >= length or _hit.frames.is_empty():
		_hit = null
		return {}
	var k := minf(1.0, minf(_hit_t, length - _hit_t) / 0.06)
	var f0: Dictionary = _hit.frames[0]
	var f := _hit.sample(_hit_t)
	var out := {}
	for sid: StringName in f:
		if sid in GUN_ARM or sid in LEGS or sid == &"pelvis" or not f0.has(sid):
			continue
		var d: Quaternion = (f0[sid] as Quaternion).inverse() * (f[sid] as Quaternion)
		out[sid] = Quaternion.IDENTITY.slerp(d, k)
	return out
