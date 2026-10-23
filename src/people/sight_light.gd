class_name SightLight
extends RefCounted
## The light falling on a man, for the eyes of whoever looks at him (`Senses`): the sky's where it
## reaches him, and each lit `OilLamp` whose light reaches him along a clear line, so a wall keeps
## a room's lamps in. In lux; `sight_range(lux)` is how far a man can be picked out in it. Only the
## lit man's light counts, not the watcher's: a man in the dark sees one under a lamp. Worked out at
## most once a Senses tick a man and shared by every watcher. The perception lab's problem 3
## (2026-10-22): the sky alone, so at night lamps lit nobody and a black room was as starlit as the
## street. Numbers: config/sight.tres (`SightTuning`).

static var tuning: SightTuning
## Per man (instance id): {frame, lamps (lux), sky (0..1 of the open sky), reach (the lamps with a
## clear line to him), lines_at, lines_frame, and the range for the daylight it was last asked at:
## day, range}.
static var _cache := {}
static var _lamps: Array[Node] = []
static var _lamps_frame := -1
const CACHE_MAX := 512


static func tune() -> SightTuning:
	if tuning == null:
		tuning = load("res://config/sight.tres")
	return tuning


## Lux on `who` (at his chest), with the sky at `daylight` (0 night .. 1 day).
static func lux_on(who: Node3D, daylight: float) -> float:
	var e := _entry(who, lit_point(who))
	return sky_lux(daylight) * float(e.sky) + float(e.lamps)


## How far off a man can be picked out (m) in the light on `who`: what Senses asks of everyone it
## looks at, every tick, so kept with his light till that's worked out again.
static func range_of(who: Node3D, daylight: float) -> float:
	if tuning != null:
		var e: Dictionary = _cache.get(who.get_instance_id(), {})
		if not e.is_empty() and Engine.get_physics_frames() - int(e.frame) < tuning.refresh_frames and e.day == daylight:
			return e.range
	var e := _entry(who, lit_point(who))
	e.day = daylight
	e.range = sight_range(sky_lux(daylight) * float(e.sky) + float(e.lamps))
	return e.range


## Where the light on a man is taken: his chest.
static func lit_point(who: Node3D) -> Vector3:
	if who is Player:
		return who.global_position + Vector3.UP * (0.9 if (who as Player).is_crouching else 1.2)
	if who is HumanBody:
		var chest := (who as HumanBody).parts.get(&"chest") as Node3D
		if chest:
			return chest.global_position
	return who.global_position + Vector3.UP * 1.2


## The open sky's light: `night_lux` at daylight 0, `day_lux` at 1, by ratios in between.
static func sky_lux(daylight: float) -> float:
	var t := tune()
	return t.night_lux * pow(t.day_lux / t.night_lux, clampf(daylight, 0.0, 1.0))


## Light as the day's 0..1 under an open sky (so daylight 0.3 in the open is 0.3); over 1 brighter
## than the day, under 0 darker than a night sky.
static func level(lux: float) -> float:
	var t := tune()
	return log(maxf(lux, 1e-9) / t.night_lux) / log(t.day_lux / t.night_lux)


## How far a man can be picked out (m) in this much light on him.
static func sight_range(lux: float) -> float:
	var t := tune()
	return clampf(lerpf(t.range_night, t.range_day, level(lux)), 0.0, t.range_day)


## The lamps' light and the sky's share on him, worked out again once `refresh_frames` have passed.
## The lines (which lamps reach him, how much sky) only once he's moved or `lines_frames` have passed:
## between, a lamp put out or lit counts at once, and so does his step towards or away from one.
static func _entry(who: Node3D, at: Vector3) -> Dictionary:
	var t := tune()
	var frame := Engine.get_physics_frames()
	var id := who.get_instance_id()
	var e: Dictionary = _cache.get(id, {})
	if not e.is_empty() and frame - int(e.frame) < t.refresh_frames:
		return e
	if e.is_empty():
		if _cache.size() >= CACHE_MAX:
			_cache.clear()
		e = {"frame": frame, "lamps": 0.0, "sky": 1.0, "reach": [], "lines_at": Vector3.INF, "lines_frame": -1,
				"day": -1.0, "range": 0.0}
		_cache[id] = e
	e.frame = frame
	if (e.lines_at as Vector3).distance_to(at) > t.lines_moved_m or frame - int(e.lines_frame) >= t.lines_frames:
		var space := who.get_world_3d().direct_space_state
		var ex: Array[RID] = []
		if who is CollisionObject3D:
			ex.append((who as CollisionObject3D).get_rid())
		e.sky = _sky_on(at, space, ex)
		e.reach = _lamps_reaching(at, space, ex)
		e.lines_at = at
		e.lines_frame = frame
	e.lamps = _lamps_on(at, e.reach)
	e.day = -1.0  # its range is worked out again
	return e


## Lux from the lamps in `reach` that are lit: each one's energy falling off over its range as Godot
## draws an omni light (a window (1 - (d/r)^4)^2 times d^-attenuation, from Godot's light docs).
static func _lamps_on(at: Vector3, reach: Array) -> float:
	var t := tune()
	var lux := 0.0
	for n: Variant in reach:
		if not is_instance_valid(n):
			continue
		var lamp := n as OilLamp
		if not lamp.shines():
			continue
		var d := lamp.light_position().distance_to(at)
		if d >= lamp.light_range:
			continue
		var nd := d / lamp.light_range
		var window := 1.0 - nd * nd * nd * nd
		lux += t.lux_per_energy * lamp.energy * window * window * pow(maxf(d, t.lamp_near_m), -lamp.attenuation)
	return lux


## Every lamp, lit or not, within its range of `at` (and the slack he can walk before the lines are
## looked at again) with nothing solid between its flame and him.
static func _lamps_reaching(at: Vector3, space: PhysicsDirectSpaceState3D, ex: Array[RID]) -> Array:
	var slack := tune().lines_moved_m
	var out := []
	for n: Node in _all_lamps():
		var lamp := n as OilLamp
		if lamp.broken or not lamp.is_inside_tree():
			continue
		var from := lamp.light_position()
		if from.distance_to(at) >= lamp.light_range + slack:
			continue
		if _lamp_reaches(lamp, from, at, space, ex):
			out.append(lamp)
	return out


## Nothing solid between the flame and him: the lamp's own glass, hitbox and fitting aside.
static func _lamp_reaches(lamp: OilLamp, from: Vector3, to: Vector3, space: PhysicsDirectSpaceState3D, ex: Array[RID]) -> bool:
	var skip := ex.duplicate()
	var own := lamp.hitbox_rid()
	if own.is_valid():
		skip.append(own)
	for i in 3:
		var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
		q.exclude = skip
		var hit := space.intersect_ray(q)
		if hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15:
			return true
		# The fitting it hangs in or stands on (a wall lamp's back plate, its bracket).
		if (hit.position as Vector3).distance_to(from) > 0.35:
			return false
		skip.append(hit.rid)
	return false


## The share of the open sky that reaches `at`: all of it with nothing overhead, else the share of
## a ring of rays round him that get out, at least a shut room's `room_sky`.
static func _sky_on(at: Vector3, space: PhysicsDirectSpaceState3D, ex: Array[RID]) -> float:
	var t := tune()
	if _open(at, at + Vector3.UP * t.sky_ray_m, space, ex):
		return 1.0
	var el := deg_to_rad(t.sky_elevation_deg)
	var open := 0
	for i in t.sky_rays:
		var az := TAU * float(i) / float(t.sky_rays)
		var dir := Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az))
		if _open(at, at + dir * t.sky_ray_m, space, ex):
			open += 1
	return maxf(float(open) / float(maxi(t.sky_rays, 1)), t.room_sky)


static func _open(from: Vector3, to: Vector3, space: PhysicsDirectSpaceState3D, ex: Array[RID]) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	q.exclude = ex
	return space.intersect_ray(q).is_empty()


## Every lamp in the world, gathered once a physics frame.
static func _all_lamps() -> Array[Node]:
	var frame := Engine.get_physics_frames()
	if frame != _lamps_frame:
		_lamps_frame = frame
		_lamps = (Engine.get_main_loop() as SceneTree).get_nodes_in_group(&"oil_lamps")
	return _lamps
