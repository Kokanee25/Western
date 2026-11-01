class_name Train
extends Node3D
## A train on a TrackLine (docs/briefs/train.md, steps 1 and 2): the 1D simulation (`TrainSim`,
## each car its own mass on couplers with slack) on the physics tick; the cars' solids placed on
## the same tick (they shove crates and men, carry riders, stop bullets); the drawn cars placed
## between ticks at the interpolated distance, so they move smoothly at any frame rate, except
## while someone stands on the train (the rider moves on the tick, so the cars he's on are drawn
## on it too, or they'd shimmer against him). A child of the TrackLine.
##
## A man standing where a car comes is struck (`take_blow`, by the car's speed: below a walking
## pace he's shoved, above it he goes down; down, his limp body is pushed by the solids as any
## loose thing is). A loose kit prop (a crate) is pushed by the solids; one still standing is
## knocked loose first. Every slack-out and bunch is emitted (`coupler`) for the sound (step 4).
##
## `record` keeps a row a tick (time, s, v, forces, levers) for the lab's graphs.

signal coupler(event: Dictionary)

var tuning: TrainTuning
var track: TrackLine
var sim: TrainSim
var view: TrainView
## Who to watch for riding (the player): while he stands on a car, the cars are drawn on the tick.
var rider: CharacterBody3D
var riding := false
var record := false
var rows: Array = []
## The last drawn distance (the engine's s as drawn) and how far through the tick it was, for checks.
var drawn_s := 0.0
var drawn_frac := 1.0
## What it costs: microseconds summed over ticks and drawn frames since `cost_reset()`.
var cost := {}
## Men struck and props knocked loose (for the lab's checks): {t, who, speed, car}.
var struck: Array[Dictionary] = []

var _near_props: Array = []
var _near_men: Array = []
var _near_until := 0.0

const STRIKE_MARGIN := 0.15  # m round a car's ends and sides a man counts as in its way
const STRIKE_DOWN_SPEED := 2.0  # m/s: slower a car shoves a man (he may stagger clear), faster it strikes him


func setup(on_track: TrackLine, t: TrainTuning) -> void:
	track = on_track
	tuning = t
	sim = TrainSim.new(t, track)
	process_physics_priority = -50  # before the player and people, so they stand on where it is
	if view == null:
		view = TrainView.new()
		view.name = "Cars"
		add_child(view)
	view.setup(track, sim)


func place(s: float, slack := -1.0) -> void:
	sim.place(s, slack)
	drawn_s = s
	view.place(1.0)
	view.place_solids()


func _physics_process(delta: float) -> void:
	if sim == null:
		return
	var t0 := Prof.start()
	var u := Time.get_ticks_usec()
	sim.step(delta)
	var u1 := Time.get_ticks_usec()
	cost.sim_us = cost.get("sim_us", 0) + u1 - u
	view.place_solids()
	var u2 := Time.get_ticks_usec()
	cost.solids_us = cost.get("solids_us", 0) + u2 - u1
	if absf(sim.v) > 0.05:
		_strike()
	cost.strike_us = cost.get("strike_us", 0) + Time.get_ticks_usec() - u2
	for e in sim.take_events():
		coupler.emit(e)
	riding = _riding()
	if record:
		rows.append(row())
	cost.tick_us = cost.get("tick_us", 0) + Time.get_ticks_usec() - u
	cost.ticks = cost.get("ticks", 0) + 1
	Prof.stop(&"train", t0)


func _process(_delta: float) -> void:
	if sim == null:
		return
	var t0 := Prof.start()
	var u := Time.get_ticks_usec()
	var frac := 1.0 if riding else Engine.get_physics_interpolation_fraction()
	drawn_s = sim.car_front(0, frac)
	drawn_frac = frac
	view.place(frac)
	cost.draw_us = cost.get("draw_us", 0) + Time.get_ticks_usec() - u
	cost.draws = cost.get("draws", 0) + 1
	Prof.stop(&"train_view", t0)


## Is the rider standing on a car?
func _riding() -> bool:
	return car_under(rider) >= 0


## The car a body stands on (what's just under its feet is a car's solid), or -1.
func car_under(who: CharacterBody3D) -> int:
	if who == null or not is_instance_valid(who) or not who.is_on_floor():
		return -1
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return -1
	var at := who.global_position
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.3, at + Vector3.DOWN * 0.4, Layers.WORLD)
	q.exclude = [who.get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty() or hit.collider == null or not (hit.collider as Object).has_meta(&"train_car"):
		return -1
	return int((hit.collider as Object).get_meta(&"train_car"))


## Men and props in a moving car's way. Cheap: only cars moving, only things within reach of the
## train's ends and sides (a box round each car in its own frame).
func _strike() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var w := tuning.car_width * 0.5 + STRIKE_MARGIN
	# A circle round the whole train first: most of the town is nowhere near it. Who's inside it (with
	# room for the train's run and theirs) is looked up twice a second, not every tick.
	var a := view.solids[0].global_position
	var z := view.solids[view.solids.size() - 1].global_position
	var centre := (a + z) * 0.5
	var reach := a.distance_to(z) * 0.5 + 15.0
	if sim.time >= _near_until:
		_near_until = sim.time + 0.5
		_near_props.clear()
		_near_men.clear()
		var wide := reach + absf(sim.v) * 0.5 + 10.0
		for node: Node in tree.get_nodes_in_group(&"structures"):
			if node is KitProp and (node as Node3D).global_position.distance_to(centre) < wide:
				_near_props.append(node)
		for node: Node in tree.get_nodes_in_group(&"people"):
			if (node as Node3D).global_position.distance_to(centre) < wide:
				_near_men.append(node)
	for node: Node in _near_props:
		var prop := node as KitProp
		if not is_instance_valid(prop) or prop.loose or prop.global_position.distance_to(centre) > reach:
			continue
		var j := _car_at(prop.global_position + Vector3.UP * 0.3, w + 0.2)
		if j < 0:
			continue
		# Struck: it goes loose, thrown on and off to the side it stood on (the pilot's wedge turns it
		# aside), and the solids shove what's left from there.
		var b := view.solids[j]
		var speed := float(sim.vel[j])
		var off := (prop.global_position - b.global_position).dot(b.global_basis.x)
		var aside := signf(off) if absf(off) > 0.02 else 1.0
		# The wedge's faces are ~35 degrees off the line: it's pushed off them mostly sideways.
		var go := -b.global_basis.z * speed * 0.5 + b.global_basis.x * aside * absf(speed) * 0.85 + Vector3.UP * 0.4
		prop.go_loose(go)
		struck.append({"t": sim.time, "who": String(prop.name), "speed": absf(float(sim.vel[j])), "car": j, "how": "loose"})
	for man: Node in _near_men:
		var hb := man as HumanBody
		if hb == null or not is_instance_valid(hb) or hb.limp or hb.has_meta(&"train_rides") or hb.global_position.distance_to(centre) > reach:
			continue
		var i := _car_at(hb.global_position + Vector3.UP * 0.9, w)
		if i < 0:
			continue
		var speed := absf(float(sim.vel[i]))
		var fwd := -view.solids[i].global_basis.z * signf(float(sim.vel[i]))
		# Off to one side of the car's middle line, he's flung that way as well as on.
		var side := view.solids[i].global_basis.x
		var off := (hb.global_position - view.solids[i].global_position).dot(side)
		var dir := (fwd + side * signf(off) * 0.6).normalized()
		if sim.time - float(hb.get_meta(&"train_struck_t", -99.0)) < 0.7:
			continue  # he's been shoved; give it time to take him out of the way
		hb.set_meta(&"train_struck_t", sim.time)
		# The car meets him and carries him on: what it gives him is his mass at the car's speed
		# (and some: he's thrown, not set going). A walking pace shoves him; faster puts him down.
		var body_mass := 75.0
		var at := hb.global_position + Vector3.UP * 1.0
		var how := &"blow"
		if speed < STRIKE_DOWN_SPEED:
			how = hb.take_push(at, dir, body_mass * speed * 1.6, 0.0, self)
		else:
			hb.take_blow(null, 0.5 * body_mass * speed * speed, at, dir, body_mass * speed * 1.6)
		struck.append({"t": sim.time, "who": String(hb.person_id), "speed": speed, "car": i, "how": String(how)})


## The car whose box (plus `half_width` either side, STRIKE_MARGIN at its ends) holds `p`, or -1.
func _car_at(p: Vector3, half_width: float) -> int:
	for i in view.solids.size():
		var b := view.solids[i]
		var local := b.global_transform.affine_inverse() * p
		var c: Dictionary = sim.cars[i]
		var tr: Vector2 = c.trucks
		var mid := (tr.x + tr.y) * 0.5
		var front := -mid - TrainCars.LIP - STRIKE_MARGIN
		var back := float(c.length) - mid + TrainCars.LIP + STRIKE_MARGIN
		if local.z > front and local.z < back and absf(local.x) < half_width and local.y > -0.3 and local.y < 3.6:
			return i
	return -1


func cost_reset() -> void:
	cost = {}


func row() -> Dictionary:
	var r := {"t": sim.time, "s": sim.s, "v": sim.v, "throttle": sim.throttle, "regulator": sim.regulator,
		"steam": sim.steam, "brake_lever": sim.brake_lever, "brake": sim.brake, "f_tractive": sim.f_tractive,
		"f_resist": sim.f_resist, "f_grade": sim.f_grade, "f_brake": sim.f_brake,
		"grade": track.grade_at(sim.s - sim.length * 0.5) if track else 0.0, "limit": String(sim.limit)}
	for i in sim.cars.size():
		r["v%d" % i] = sim.vel[i]
	for j in sim.coupler_force.size():
		r["c%d" % j] = sim.coupler_force[j]
	return r
