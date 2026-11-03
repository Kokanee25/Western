class_name TrainLookout
extends RefCounted
## The engineer's eyes on the line ahead (train step 5, #616): what he sees of the damage and the
## blocks on it, and when. Ticked by the Train after its step.
##
##   - The line ahead is looked along for blocks (TrackState.scan_ahead, a few cells a tick, out to
##     the furthest he could see one by day).
##   - The first thing wrong ahead is looked for from his eye (leaning out of the cab's right side,
##     where he sits): a clear line to it (Sight, the people's sight service: the boiler and the
##     cut of a bend hide it as they hide anything), and near enough for the light on it. The
##     light: the sky's (SightLight.sky_lux by the day's light) and, at night, the headlight's
##     where its beam falls (it points along the engine, so on a bend it lights the outside of the
##     curve, not the line). How far he picks a thing out goes with the light's logarithm, as for
##     a man (SightLight.level), between its night and day reach; a gap in a rail he sees nearer
##     than a crate.
##   - Seen, he takes a moment to know it (a reaction time, seeded), then he's alarmed: the engineer
##     shuts the regulator and throws the brake on full (TrainEngineer). Whether it stops in time
##     is the 1D train's stopping distance.
##
## Deterministic: the same seed, light and line give the same sighting at the same distance.

var train: Train
var tuning: TrainTuning
## The day's light (0 night .. 1 day), or below 0 to read the DayCycle.
var daylight := -1.0
## What he's seen: the stretch, when, at what distance; then when he knew it.
var seen := {}
var seen_t := -1.0
var seen_d := 0.0
var alarm_t := INF
## Every sighting: {t, kind, what, distance (along the line), s, light (lux), range}.
var log: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _tick := 0
var _clock: DayCycle


func _init(t: Train, seed_value := 616) -> void:
	train = t
	tuning = t.tuning
	_rng.seed = seed_value


func reset(seed_value := 616) -> void:
	seen = {}
	seen_t = -1.0
	alarm_t = INF
	log.clear()
	_rng.seed = seed_value


## He knows something's wrong ahead (seen, and the moment to take it in has passed).
func alarmed() -> bool:
	return train.sim.time >= alarm_t


func _daylight() -> float:
	if daylight >= 0.0:
		return daylight
	if _clock == null or not is_instance_valid(_clock):
		if not train.is_inside_tree():
			return 1.0
		_clock = train.get_tree().root.find_child("DayCycle", true, false) as DayCycle
		if _clock == null:
			return 1.0
	return _clock.get_daylight()


## Which way the train's going (+1 toward the line's end).
func _dir() -> int:
	var v := train.sim.v
	if absf(v) > 0.05:
		return 1 if v > 0.0 else -1
	return train.sim.reverser


## His eye, in the world: on the engine's right, leaning out past the cab side, at a man's eye height.
func eye() -> Vector3:
	var c: Dictionary = train.sim.cars[0]
	var mid: float = (c.trucks.x + c.trucks.y) * 0.5
	var at := Vector3(tuning.lookout_eye.x, TrainCars.DECK + tuning.lookout_eye.y, float(c.length) - mid - 1.1)
	return train.track.global_transform * train.view.car_transform(0) * at


## Where on the stretch he'd see it: the near end of a break or a bend at the rail on its side, a
## block's middle.
func target(st: Dictionary, dir: int) -> Vector3:
	var s: float = float(st.from_s) if dir > 0 else float(st.to_s)
	var f := train.track.global_transform * train.track.transform_at(s)
	if st.kind == &"blocked":
		return f.origin + f.basis.y * 0.5
	var x := float(st.side) * (tuning.gauge * 0.5)
	return f * Vector3(x, 0.05, 0.0)


## The light on a point (lux): the sky's, and the headlight's if it's in its beam.
func light_at(p: Vector3, day: float) -> float:
	var lux := SightLight.sky_lux(day)
	if day < tuning.headlight_below_daylight:
		var c: Dictionary = train.sim.cars[0]
		var mid: float = (c.trucks.x + c.trucks.y) * 0.5
		var f := train.track.global_transform * train.view.car_transform(0)
		var lamp := f * Vector3(0.0, 2.6, -mid)
		var ahead := -f.basis.z * float(_dir())
		var to := p - lamp
		var d := to.length()
		if d > 0.5 and ahead.angle_to(to) < deg_to_rad(tuning.headlight_beam_deg):
			lux += tuning.headlight_cd / (d * d)
	return lux


## How far he picks out a thing of this kind in this light, m.
func reach(kind: StringName, lux: float) -> float:
	var near_far: Vector2 = tuning.see_block if kind == &"blocked" else tuning.see_break
	return clampf(lerpf(near_far.x, near_far.y, SightLight.level(lux)), 0.0, near_far.y)


func tick() -> void:
	_tick += 1
	var sim := train.sim
	var state := train.track.state
	if state == null:
		return
	var dir := _dir()
	var world := train.get_world_3d() if train.is_inside_tree() else null
	var front := sim.s if dir > 0 else sim.back_s()
	var ex: Array[RID] = []
	for b in train.view.solids:
		ex.append(b.get_rid())
	if world:
		state.scan_ahead(world, front, dir, tuning.see_block.y, tuning.scan_cells, sim.time, ex)
	if not seen.is_empty() or _tick % 6 != 0:
		return
	var st := state.first_ahead(front, dir, tuning.see_block.y)
	if st.is_empty():
		return
	var d: float = absf((float(st.from_s) if dir > 0 else float(st.to_s)) - front)
	if float(st.from_s) <= front and float(st.to_s) >= front:
		d = 0.0
	var day := _daylight()
	var p := target(st, dir)
	var lux := light_at(p, day)
	var r := reach(st.kind, lux)
	if d > r:
		return
	if world:
		var e := eye()
		# The train itself counts (the boiler on a left-hand bend, the tender backing up).
		if Sight.see(train, e, p, [] as Array[RID], 0.3) < 0.3:
			return
	seen = st
	seen_t = sim.time
	seen_d = d
	alarm_t = sim.time + _rng.randf_range(tuning.reaction.x, tuning.reaction.y)
	log.append({"t": sim.time, "kind": String(st.kind), "what": String(st.what), "distance": d, "s": front,
		"kmh": absf(sim.v) * 3.6, "lux": lux, "range": r, "daylight": day})
