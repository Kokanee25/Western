class_name Train
extends Node3D
## A train on a TrackLine (docs/briefs/train.md, steps 1 and 2): the 1D simulation (`TrainSim`)
## on the physics tick, driven by its `engineer` (TrainEngineer, when it has one) or by whoever
## sets its levers (the lab's cab), and its cars (`TrainView`) moved there as solids. A child of the
## TrackLine.
##
## The cars stand where the tick has them (they're solids the player rides: drawn between ticks they
## would slide under his feet, which are on the tick too). The leading end sweeps the line ahead of
## it each tick: a kit prop in the way is knocked loose (KitProp.take_blow) and then shoved by the
## car's solid; a man is pushed (HumanBody.take_push). Each coupler event is `coupler`.
##
## `record` keeps a row a tick (time, s, v, forces, levers, the gaps) for the lab's graphs.

signal coupler(event: Dictionary)
signal struck(what: Dictionary)

## The mass the leading end hits with (kg): its momentum and energy against a prop or a man, as
## the kit's blows count them (a train's own is far more; what's struck takes its speed either way).
const BLOW_MASS := 4000.0
## The sweep ahead of the leading end: height above the rail, and its depth past a tick's travel, m.
const SWEEP_LOW := 0.12
const SWEEP_HIGH := 1.9
const SWEEP_DEPTH := 0.35
## Pieces of a struck prop within this of the strike are thrown off the pilot, m.
const FLING_REACH := 1.5
## How much of the blow goes on ahead (the rest to the side, off the pilot's V).
const PILOT_AHEAD := 0.6
## A thing struck isn't struck again for this long, s.
const STRUCK_AGAIN := 2.0

var tuning: TrainTuning
var track: TrackLine
var sim: TrainSim
var view: TrainView
var engineer: TrainEngineer
var record := false
var rows: Array = []
## Sweep the line ahead of the leading end for props and men.
var sweep := true
## The last drawn distance (the engine's), for checks.
var drawn_s := 0.0
## What it costs: microseconds summed over ticks and drawn frames since `cost_reset()`.
var cost := {}
## What it's struck: {what, at, speed, result}.
var struck_log: Array[Dictionary] = []

var _events_seen := 0
var _struck := {}  # instance id -> time
var _sweep_shape := BoxShape3D.new()


func setup(on_track: TrackLine, t: TrainTuning, consist: Array = []) -> void:
	track = on_track
	tuning = t
	sim = TrainSim.new(t, track, consist)
	if view == null:
		view = TrainView.new()
		view.name = "Cars"
		add_child(view)
	view.setup(track, sim)


func place(s: float) -> void:
	sim.place(s)
	drawn_s = s
	view.place_cars()


func _physics_process(delta: float) -> void:
	if sim == null:
		return
	var t0 := Prof.start()
	var u := Time.get_ticks_usec()
	if engineer:
		engineer.tick(delta)
	sim.step(delta)
	view.place_cars()
	drawn_s = sim.s
	if sweep and absf(sim.v) > 0.2:
		_sweep()
	while _events_seen < sim.event_count:
		var back := sim.event_count - _events_seen
		_events_seen += 1
		if back <= sim.events.size():
			coupler.emit(sim.events[sim.events.size() - back])
	if record:
		rows.append(row())
	cost.tick_us = cost.get("tick_us", 0) + Time.get_ticks_usec() - u
	cost.ticks = cost.get("ticks", 0) + 1
	Prof.stop(&"train", t0)


func cost_reset() -> void:
	cost = {}


## The line just ahead of the leading end: what's in the way.
func _sweep() -> void:
	var n := sim.cars.size()
	var dir := 1.0 if sim.v > 0.0 else -1.0
	var i := 0 if dir > 0.0 else n - 1
	var car: Dictionary = sim.cars[i]
	var end_s: float = sim.x[i] if dir > 0.0 else sim.x[i] - float(car.length)
	var depth := absf(sim.u[i]) / float(Engine.physics_ticks_per_second) + SWEEP_DEPTH
	var f := track.global_transform * track.transform_at(end_s + dir * depth * 0.5)
	_sweep_shape.size = Vector3(float(car.width) + 0.1, SWEEP_HIGH - SWEEP_LOW, depth)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _sweep_shape
	q.transform = Transform3D(f.basis, f.origin + f.basis.y * (SWEEP_LOW + SWEEP_HIGH) * 0.5)
	q.collision_mask = Layers.WORLD | Layers.BODY_PARTS
	var own: Array[RID] = []
	for b in view.bodies:
		if b is CollisionObject3D:
			own.append((b as CollisionObject3D).get_rid())
	q.exclude = own
	var hits := World.space(self).intersect_shape(q, 16)
	if hits.is_empty():
		return
	var ahead := (f.basis * Vector3(0.0, 0.0, -1.0)) * dir
	var speed := absf(sim.u[i])
	for h in hits:
		var c: Object = h.collider
		if c == null:
			continue
		# (Duck-typed: the 1D train and its lab run headless without the people's and props' code.)
		var man: Object = c.get_meta(&"human_body") if c.has_meta(&"human_body") else null
		var parent: Object = (c as Node).get_parent() if c is Node else null
		var prop: Object = parent if parent != null and parent.has_method(&"take_blow") and parent.get(&"kit_id") != null else null
		var key: Object = man if man != null and man.has_method(&"take_push") else prop
		if key == null:
			continue
		var id := key.get_instance_id()
		if _struck.has(id) and sim.time - float(_struck[id]) < STRUCK_AGAIN:
			continue
		_struck[id] = sim.time
		var at := (c as Node3D).global_position if c is Node3D else f.origin
		# The pilot's V throws it aside: off to the side of the line it's on (the right if dead centre).
		var across := (at - f.origin).dot(f.basis.x)
		var aside := f.basis.x * (1.0 if across >= 0.0 else -1.0)
		var push := (ahead * PILOT_AHEAD + aside * (1.0 - PILOT_AHEAD)).normalized()
		var info := {"t": sim.time, "speed": speed, "at": at}
		if key == man:
			var kg: float = man.call(&"_body_mass")
			info.what = "man"
			info.who = String(man.get(&"person_id"))
			info.result = String(man.call(&"take_push", at, push, kg * speed * 1.5, 0.5 * kg * speed * speed, self))
		elif key == prop:
			info.what = "prop"
			info.prop = String(prop.get(&"kit_id"))
			info.result = String(prop.call(&"take_blow", c, at, push * BLOW_MASS * speed, BLOW_MASS))
			_fling(prop, at, push, speed, f.basis.y)
			var ev := get_node_or_null(^"/root/Events")
			if ev:
				ev.noise.emit(at, 15.0, &"crash", self)
		else:
			continue
		struck_log.append(info)
		struck.emit(info)


## What the pilot struck goes off it at its speed along the V (each piece a little faster or slower,
## by its order: no dice), and up a little: the pieces of a smashed prop thrown clear, not left to
## fall where it stood under the train.
func _fling(prop: Object, at: Vector3, push: Vector3, speed: float, up: Vector3) -> void:
	var pieces: Variant = prop.get(&"rubble")
	if not pieces is Array:
		return
	var k := 0
	for rb in pieces:
		if not (rb is RigidBody3D and is_instance_valid(rb)) or (rb as Node3D).global_position.distance_to(at) > FLING_REACH:
			continue
		var body := rb as RigidBody3D
		var share := 1.0 + 0.35 * float((k * 7) % 5) / 4.0
		body.linear_velocity = push * speed * share + up * speed * (0.1 + 0.05 * float(k % 3))
		body.angular_velocity = Vector3(float(k % 3) - 1.0, float((k + 1) % 3) - 1.0, float((k + 2) % 3) - 1.0) * speed * 0.5
		k += 1


func row() -> Dictionary:
	var r := {"t": sim.time, "s": sim.s, "v": sim.v, "throttle": sim.throttle, "regulator": sim.regulator,
		"steam": sim.steam, "brake_lever": sim.brake_lever, "brake": sim.brake, "f_tractive": sim.f_tractive,
		"f_resist": sim.f_resist, "f_grade": sim.f_grade, "f_brake": sim.f_brake,
		"grade": track.grade_at(sim.middle()) if track else 0.0, "limit": String(sim.limit)}
	for i in sim.cars.size():
		r["v%d" % i] = sim.u[i]
	for j in sim.cars.size() - 1:
		r["gap%d" % j] = sim.gap(j)
	return r
