class_name TrainWreck
extends RefCounted
## A train off the rails (train step 5, #616; docs/briefs/train.md): the hand-off from the 1D train
## on its curve to Jolt rigid bodies, as animation hands off to the ragdoll.
##
##   - Each car becomes a RigidBody3D with its own shapes (TrainCars: decks, shells, the wheels, the
##     pilot) and its model, its mass the car's, going at the speed the 1D train had it, the way
##     its car pointed (and turning as the bend turned it): momentum handed over, not made up.
##   - The couplers become joints with their free play (`coupler_slack` along, a little across) and
##     loose in yaw, so the cars behind run in on the front, pile up and jackknife; a coupler
##     strained past `coupler_tears` (its pins sheared) lets go.
##   - The engine's leading wheels drop off the end of the broken rail toward that side (a nudge of
##     `derail_kick` m/s a m/s it was going, across): past that it's the physics, the ballast's
##     shoulder and the fill. At walking pace it lurches off and tips into the ballast; at speed, a
##     wreck.
##   - A car stopped harder than `car_break_dv` (m/s inside BREAK_WINDOW) breaks into big sections:
##     its front half, its back half and its roof (a shell's), each its own body with its share of
##     the shapes and the model (TrainModels.car_section), never every board.
##   - Men riding (the engineer, the passengers) ride on in their places till their car jolts past
##     `thrown_g` or tips past THROWN_TILT: then they go limp, moving on as they were (HumanBody.
##     go_limp carries each part's own speed) while the car stops under them: thrown by their own
##     bodies, not a script.
##   - What's left lies as rubble does everywhere: in the `rubble` group, frozen by RubbleSleep once
##     it's still and nothing near has moved, let go on a blow or a blast.
##
## `to_dict` keeps it by the route's places (each body's transform in the line's frame at its
## section and distance along it), `TrainWreck.restore` lays it again on a line built from the
## same route or a re-laid one.

const BREAK_WINDOW := 0.15
const THROWN_TILT := 35.0
## The first moments of the hand-off are the bodies settling onto the track (a few cm): no jolt
## is read before this, s.
const SETTLE_S := 0.15
## A wreck body this far under its line has gone through the ground (the deepest gorge is ~70 m).
const LOST_BELOW := 150.0
## Body i as a RigidBody3D, or null once it's gone (a car broken into sections).
func body(i: int) -> RigidBody3D:
	var o: Variant = bodies[i].body
	return o as RigidBody3D if is_instance_valid(o) and not (o as Node).is_queued_for_deletion() else null


## A wreck body: a train car's, or a section of one.
const GROUP := &"train_wreck"

var train: Train
var tuning: TrainTuning
## Bodies: [{body: RigidBody3D, car (index), kind, part ("whole", "front", "back", "roof")}].
var bodies: Array[Dictionary] = []
## Couplers still holding: [{joint, a, b (indices into bodies), at_a, at_b (anchors in each body's frame)}].
var couplers: Array[Dictionary] = []
## Riders still riding: [{man, body (index)}].
var riders: Array[Dictionary] = []
## What happened, in order: {t, what, car, ...} (couplers torn, cars broken, men thrown).
var events: Array[Dictionary] = []
var time := 0.0
## Each body's speed a little while ago, for its jolt: body index -> [[t, velocity], ...].
var _hist := {}
var _rng := RandomNumberGenerator.new()
var _limp_tick := -1
## The couplers' play in pitch, degrees (loose off a bridge: `start`).
var _pitch := 15.0
## Bodies whose riders the jolt has thrown (index -> [g, tilt] when it did): the rest go a tick apart.
var _jolted := {}


func _init(t: Train) -> void:
	train = t
	tuning = t.tuning
	_rng.seed = hash(Vector2i(int(t.sim.s * 100.0), int(t.sim.time * 60.0)))


func _host() -> Node3D:
	return train.track.get_parent() as Node3D if train.track.get_parent() is Node3D else train.track


func _physics_mat() -> PhysicsMaterial:
	var m := PhysicsMaterial.new()
	m.friction = tuning.wreck_friction
	m.bounce = 0.02
	return m


## Hand the train over to the bodies, moving as the 1D train had it.
func start(what: Dictionary) -> void:
	var sim := train.sim
	var view := train.view
	var host := _host()
	var mat := _physics_mat()
	for i in sim.cars.size():
		var solid := view.solids[i]
		var car: Dictionary = sim.cars[i]
		var rb := _body(host, solid.global_transform, float(car.mass), mat, "%sWreck" % String(car.name).capitalize())
		# Its shapes and ladders, and the riders on it: what was the solid's is the body's.
		for c in solid.get_children():
			if c is CollisionShape3D or c is Ladder:
				c.reparent(rb, true)
			elif c is HumanBody:
				c.reparent(rb, true)
				riders.append({"man": c, "body": i})
				_ride(c as HumanBody, rb, true)
		# The drawn car and its trucks.
		view.bodies[i].reparent(rb, true)
		for w in 2:
			view.trucks[i * 2 + w].reparent(rb, true)
		rb.set_meta(&"train_car", i)
		rb.set_meta(&"surface", solid.get_meta(&"surface", &"wood"))
		rb.set_meta(&"wreck_part", "whole")
		_centre_low(rb, car)
		# Its speed along the way it pointed, and the bend's turn.
		var fwd := -solid.global_basis.z
		var mid := float(sim.x[i]) - float(car.length) * 0.5
		var k := train.track.curvature_at(mid)
		rb.linear_velocity = fwd * float(sim.vel[i])
		rb.angular_velocity = solid.global_basis.y * float(sim.vel[i]) * k
		bodies.append({"body": rb, "car": i, "kind": car.kind, "part": "whole"})
		solid.collision_layer = 0
		solid.queue_free()
	view.solids.clear()
	# Off a bridge (the deck gone from under it) a car hangs from its coupler: link and pin takes a
	# pull, not a bending moment, so it swings free in pitch and its weight drags the rest over the
	# edge (held at step 5's 15 degrees, the cars on the deck held a 31 t engine out over a 19 m
	# hole like a beam: the trestle lab, #623).
	_pitch = 70.0 if StringName(what.get("kind", "")) == &"fell" else 15.0
	for j in sim.cars.size() - 1:
		_couple(j, j + 1)
	if StringName(what.get("kind", "")) == &"fell":
		# The deck gone from under it (a bridge): nothing throws it across; what's over the gap falls.
		events.append({"t": 0.0, "what": "fell", "kmh": absf(float(sim.vel[0])) * 3.6, "car": int(what.get("car", -1))})
		sim.set_speed(0.0)
		return
	# The engine's leading wheels off the end of the broken rail: across toward that side, its nose down.
	var e := body(0)
	var side := float(what.get("side", 0))
	if side == 0.0:
		side = -1.0 if _rng.randf() < 0.5 else 1.0
	var speed := absf(float(sim.vel[0]))
	var across := clampf(speed * tuning.derail_kick, tuning.derail_kick_min, 3.0)
	var nose := e.global_transform * Vector3(0.0, 0.5, -float(sim.cars[0].length) * 0.5)
	e.apply_impulse(e.global_basis.x * side * across * e.mass, nose - e.global_position)
	events.append({"t": 0.0, "what": "derailed", "kmh": speed * 3.6, "side": side})
	sim.set_speed(0.0)


func _body(host: Node3D, at: Transform3D, mass: float, mat: PhysicsMaterial, nm: String) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.name = nm
	rb.mass = mass
	rb.physics_material_override = mat
	rb.collision_layer = Layers.WORLD
	rb.collision_mask = Layers.WORLD | Layers.DEBRIS
	rb.continuous_cd = true
	rb.can_sleep = true
	rb.add_to_group(&"rubble")
	rb.add_to_group(GROUP)
	host.add_child(rb)
	rb.global_transform = at
	return rb


## Its weight low, where a car's is (the frame, the trucks, the boiler on the engine).
func _centre_low(rb: RigidBody3D, car: Dictionary) -> void:
	rb.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	var h := 1.5 if car.kind in [&"engine"] else (1.2 if car.kind == &"tender" else 0.9)
	rb.center_of_mass = Vector3(0.0, h, 0.0)


## The coupler between bodies a and b (car j and j + 1) as a joint at the middle of their gap.
func _couple(a: int, b: int) -> void:
	var ra := bodies[a].body as RigidBody3D
	var rbb := bodies[b].body as RigidBody3D
	var ca: Dictionary = train.sim.cars[bodies[a].car]
	var cb: Dictionary = train.sim.cars[bodies[b].car]
	var mid_a: float = (ca.trucks.x + ca.trucks.y) * 0.5
	var mid_b: float = (cb.trucks.x + cb.trucks.y) * 0.5
	var y := 0.8  # the drawheads' height
	var back_a := ra.global_transform * Vector3(0.0, y, float(ca.length) - mid_a)
	var front_b := rbb.global_transform * Vector3(0.0, y, -mid_b)
	var at := (back_a + front_b) * 0.5
	var j := Generic6DOFJoint3D.new()
	j.name = "Coupler%d" % a
	_host().add_child(j)
	j.global_transform = Transform3D(ra.global_basis, at)
	var half := tuning.coupler_slack * 0.5
	j.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	j.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	j.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	j.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -0.03)
	j.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.03)
	j.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -0.03)
	j.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.03)
	j.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -half)
	j.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, half)
	# Link and pin: it turns freely in yaw (the jackknife), a little in pitch and roll.
	for ax in [[j.set_flag_x, j.set_param_x, _pitch], [j.set_flag_y, j.set_param_y, 75.0], [j.set_flag_z, j.set_param_z, 25.0]]:
		(ax[0] as Callable).call(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
		(ax[1] as Callable).call(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, deg_to_rad(-float(ax[2])))
		(ax[1] as Callable).call(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, deg_to_rad(float(ax[2])))
	j.exclude_nodes_from_collision = false  # their ends bang together as they bunch
	j.node_a = j.get_path_to(ra)
	j.node_b = j.get_path_to(rbb)
	couplers.append({"joint": j, "a": a, "b": b, "at_a": ra.global_transform.affine_inverse() * at,
		"at_b": rbb.global_transform.affine_inverse() * at})


func tick(delta: float) -> void:
	time += delta
	_couplers()
	for i in bodies.size():
		var rb := body(i)
		if rb == null:
			continue
		if not rb.freeze and rb.global_position.y < train.track.to_global(Vector3(0.0, train.track.lowest - LOST_BELOW, 0.0)).y:
			# Through the ground somehow (a thin section at speed): falling for ever costs the
			# physics every tick (Structure's rubble the same).
			rb.freeze = true
			rb.visible = false
			events.append({"t": time, "what": "lost", "body": i})
			continue
		_plough(rb)
		var h: Array = _hist.get_or_add(i, [])
		h.append([time, rb.linear_velocity])
		while h.size() > 2 and float(h[1][0]) < time - BREAK_WINDOW:
			h.pop_front()
		var dv: Vector3 = rb.linear_velocity - (h[0][1] as Vector3)
		var span := maxf(time - float(h[0][0]), delta)
		var jolt := dv.length() / span / 9.81
		var tilt := rad_to_deg(rb.global_basis.y.angle_to(Vector3.UP))
		_throw_riders(i, jolt, tilt)
		if bodies[i].part == "whole" and dv.length() > tuning.car_break_dv and bodies[i].kind in [&"ore", &"box", &"express", &"coach"]:
			_break_car(i, dv.length())


## Off the rails a car's wheels still roll over the ties (its grip, `wreck_friction`, is the
## wheels' on what they meet), but off the bed it ploughs: a drag of up to `plough_g` of its
## weight, against its going, as far as it's out past the ballast's top, pulled at its bottom (so
## a car running off the shoulder digs in and goes over).
func _plough(rb: RigidBody3D) -> void:
	if rb.freeze or rb.sleeping:
		return
	var v := rb.linear_velocity
	v.y = 0.0
	var speed := v.length()
	if speed < 0.05:
		return
	var line := train.track
	var local := line.global_transform.affine_inverse() * rb.global_position
	if local.y < line.lowest - 2.5:
		return  # well under the line (fallen off a bridge): nothing to plough
	var s := line.curve.get_closest_offset(local)
	var p := line.point_at(s)
	if local.y < p.y - 2.5 or (line.on_crossing(s) and local.y < p.y + 4.0 and _off_deck(line, s, local)):
		return  # falling, or off a bridge's deck: nothing under its wheels to plough
	var off := Vector2(local.x - p.x, local.z - p.z).length()
	var out := clampf((off - tuning.ballast_top * 0.5 + 0.6) / 1.0, 0.0, 1.0)
	var g := tuning.roll_g + (tuning.plough_g - tuning.roll_g) * out
	var f := -v / speed * minf(g * rb.mass * 9.81, rb.mass * speed / get_physics_dt())
	# (At its wheels' height under its middle: offset from the body's origin, the world's way round.)
	rb.apply_force(f, rb.global_basis * Vector3(rb.center_of_mass.x, 0.2, rb.center_of_mass.z))


## Off the sides of a bridge's deck (past its ties' ends).
func _off_deck(line: TrackLine, s: float, local: Vector3) -> bool:
	var p := line.point_at(s)
	return Vector2(local.x - p.x, local.z - p.z).length() > tuning.tie_size.x * 0.5 + 0.3


func get_physics_dt() -> float:
	return 1.0 / Engine.physics_ticks_per_second


## A coupler pulled past `coupler_tears` from where it holds (its pins sheared, its link bent) lets go.
func _couplers() -> void:
	for k in range(couplers.size() - 1, -1, -1):
		var c: Dictionary = couplers[k]
		var ra := body(c.a)
		var rbb := body(c.b)
		var gone := ra == null or rbb == null or not is_instance_valid(c.joint)
		if not gone:
			var pa: Vector3 = ra.global_transform * (c.at_a as Vector3)
			var pb: Vector3 = rbb.global_transform * (c.at_b as Vector3)
			gone = pa.distance_to(pb) > tuning.coupler_tears
		if gone:
			if is_instance_valid(c.joint):
				(c.joint as Node).queue_free()
			couplers.remove_at(k)
			events.append({"t": time, "what": "coupler torn", "between": [bodies[c.a].car, bodies[c.b].car]})


## A rider's parts (posed, kinematic: his seat holds him) don't push his own car about while he
## rides it; thrown, they're bodies like any other in it.
func _ride(man: HumanBody, rb: RigidBody3D, on: bool) -> void:
	for seg in man.parts:
		var part := man.parts[seg] as PhysicsBody3D
		if part == null or not is_instance_valid(part):
			continue
		if on:
			rb.add_collision_exception_with(part)
		else:
			rb.remove_collision_exception_with(part)


func _throw_riders(i: int, jolt: float, tilt: float) -> void:
	if time < SETTLE_S:
		return
	if jolt >= tuning.thrown_g or tilt >= THROWN_TILT:
		if not _jolted.has(i):
			_jolted[i] = [jolt, tilt]
	if not _jolted.has(i):
		return
	jolt = _jolted[i][0]
	tilt = _jolted[i][1]
	for k in range(riders.size() - 1, -1, -1):
		var r: Dictionary = riders[k]
		if int(r.body) != i:
			continue
		var man := r.man as HumanBody
		if not is_instance_valid(man):
			riders.remove_at(k)
			continue
		# One man a tick goes limp (a ragdoll made is ~30 ms here: seven at once were a 215 ms
		# frame); the rest a tick or two later, as their car keeps jolting them.
		if _limp_tick == Engine.get_physics_frames():
			continue
		_limp_tick = Engine.get_physics_frames()
		riders.remove_at(k)
		man.remove_meta(&"train_rides")
		var rb := body(i)
		if rb:
			_ride(man, rb, false)
		man.go_limp()
		man.reparent(_host(), true)
		events.append({"t": time, "what": "thrown", "who": String(man.person_id), "car": bodies[i].car,
			"g": jolt, "tilt": tilt})


## A car stopped hard breaks into its front half, back half and (a shell's) roof: each a body of
## its own with the shapes and the boards in it, the car's speed and spin, its share of the mass.
func _break_car(i: int, dv: float) -> void:
	var rb := body(i)
	if rb == null:
		return
	var ci: int = bodies[i].car
	var car: Dictionary = train.sim.cars[ci]
	var mid: float = (car.trucks.x + car.trucks.y) * 0.5
	var l: float = car.length
	var shell: bool = car.kind in [&"coach", &"express", &"box"]
	var roof_y := TrainCars.DECK + (2.0 if car.kind == &"box" else 2.25)
	var parts := [["front", -INF, l * 0.5, -INF, roof_y], ["back", l * 0.5, INF, -INF, roof_y]]
	if shell:
		parts.append(["roof", -INF, INF, roof_y, INF])
	var mat := rb.physics_material_override
	var made: Array[RigidBody3D] = []
	for p: Array in parts:
		var nb := _body(_host(), rb.global_transform, float(car.mass) * (0.12 if p[0] == "roof" else (0.44 if shell else 0.5)), mat,
			"%s%s" % [rb.name, String(p[0]).capitalize()])
		nb.set_meta(&"train_car", ci)
		nb.set_meta(&"surface", rb.get_meta(&"surface", &"wood"))
		nb.set_meta(&"wreck_part", p[0])
		nb.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		nb.center_of_mass = Vector3(0.0, roof_y if p[0] == "roof" else 0.9, (((maxf(float(p[1]), 0.0) + minf(float(p[2]), l)) * 0.5) - mid))
		nb.linear_velocity = rb.linear_velocity
		nb.angular_velocity = rb.angular_velocity
		var model: Node3D = TrainModels.car_section(car, tuning, float(p[1]), float(p[2]), float(p[3]), float(p[4]))
		nb.add_child(model)
		made.append(nb)
	# The shapes and whatever rides it go where their middle is.
	for c in rb.get_children():
		var local: Vector3 = (c as Node3D).position if c is Node3D else Vector3.ZERO
		if c is HumanBody:
			local = rb.global_transform.affine_inverse() * (c as HumanBody).global_position
		var u := local.z + mid
		var k := 0 if u < l * 0.5 else 1
		if shell and local.y >= roof_y - 0.05 and c is CollisionShape3D:
			k = 2
		if c is CollisionShape3D or c is Ladder or c is HumanBody:
			c.reparent(made[k], true)
		elif c is Node3D and String(c.name).contains("Truck"):
			c.reparent(made[k], true)
	# The car's own drawn body goes (its sections are drawn now).
	for c in rb.get_children():
		c.queue_free()
	# Couplers to it go to the section at that end.
	for c: Dictionary in couplers:
		if int(c.a) == i or int(c.b) == i:
			if is_instance_valid(c.joint):
				(c.joint as Node).queue_free()
	couplers = couplers.filter(func(c: Dictionary) -> bool: return int(c.a) != i and int(c.b) != i)
	var base := bodies.size()
	for k in made.size():
		bodies.append({"body": made[k], "car": ci, "kind": car.kind, "part": parts[k][0]})
	for r: Dictionary in riders:
		if int(r.body) == i and is_instance_valid(r.man):
			var at := (r.man as Node3D).get_parent()
			for k in made.size():
				if at == made[k]:
					r.body = base + k
	bodies[i].part = "broken"
	rb.remove_from_group(&"rubble")
	rb.queue_free()
	events.append({"t": time, "what": "car broken", "car": ci, "dv": dv})


## Every wreck body as the route's places: {car, part, key (its section and distance), local (its
## transform in the line's frame there: [origin, basis rows])}.
func to_dict() -> Dictionary:
	var out := []
	var line := train.track
	for i in bodies.size():
		var b: Dictionary = bodies[i]
		var rb := body(i)
		if rb == null or b.part == "broken":
			continue
		var in_line := line.global_transform.affine_inverse() * rb.global_transform
		var s := _nearest_s(in_line.origin)
		var local := line.transform_at(s).affine_inverse() * in_line
		out.append({"car": int(b.car), "part": String(b.part), "key": line.key_of(s), "local": _xf(local)})
	return {"bodies": out, "derail": train.derail.duplicate()}


func _nearest_s(p: Vector3) -> float:
	var line := train.track
	return line.curve.get_closest_offset(p)


static func _xf(t: Transform3D) -> Array:
	return [t.origin.x, t.origin.y, t.origin.z, t.basis.x.x, t.basis.x.y, t.basis.x.z,
		t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z]


static func _from_xf(a: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8]), Vector3(a[9], a[10], a[11])), Vector3(a[0], a[1], a[2]))


## Lay a saved wreck on `t`'s line (built from the same route, or a re-laid one with the same
## sections): every body where the save had it in the line's frame at its section and distance,
## asleep (frozen as rubble that's lain still). The train's solids are its bodies from then on.
static func restore(t: Train, d: Dictionary) -> TrainWreck:
	var w := TrainWreck.new(t)
	var line := t.track
	var view := t.view
	var host := w._host()
	var mat := w._physics_mat()
	var whole := {}
	for b: Dictionary in d.get("bodies", []):
		var s := line.s_of(b.key)
		if is_nan(s):
			continue
		var at := line.global_transform * line.transform_at(s) * _from_xf(b.local)
		var ci := int(b.car)
		var car: Dictionary = t.sim.cars[ci]
		var rb := w._body(host, at, float(car.mass), mat, "%sWreck%s" % [String(car.name).capitalize(), String(b.part).capitalize()])
		rb.set_meta(&"train_car", ci)
		rb.set_meta(&"wreck_part", b.part)
		w._centre_low(rb, car)
		if b.part == "whole":
			var solid := view.solids[ci]
			for c in solid.get_children():
				if c is CollisionShape3D or c is Ladder:
					c.reparent(rb, false)
			var frame := view.car_transform(ci)
			for k in 2:
				var truck := view.trucks[ci * 2 + k]
				var local := frame.affine_inverse() * truck.transform
				truck.reparent(rb, false)
				truck.transform = local
			view.bodies[ci].reparent(rb, false)
			view.bodies[ci].transform = Transform3D.IDENTITY
			whole[ci] = true
		else:
			# A section: its shapes again from the car's list, its boards.
			var mid: float = (car.trucks.x + car.trucks.y) * 0.5
			var l: float = car.length
			var roof_y := TrainCars.DECK + (2.0 if car.kind == &"box" else 2.25)
			var r: Vector4 = {"front": Vector4(-INF, l * 0.5, -INF, roof_y), "back": Vector4(l * 0.5, INF, -INF, roof_y),
				"roof": Vector4(-INF, INF, roof_y, INF)}[b.part]
			rb.add_child(TrainModels.car_section(car, t.tuning, r.x, r.y, r.z, r.w))
			for sh: Dictionary in TrainCars.shapes(car, t.tuning):
				if not sh.get("solid", false) or sh.has("ladder") or sh.has("hull"):
					continue
				var u: float = float((sh.at as Vector3).z) + mid
				var y: float = float((sh.at as Vector3).y)
				if u >= r.x and u < r.y and y >= r.z and y < r.w:
					view._solid_shape_into(rb, sh)
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		rb.freeze = true
		w.bodies.append({"body": rb, "car": ci, "kind": car.kind, "part": b.part})
	# Cars not in the wreck (sections only, or not saved): gone from the line.
	for i in view.solids.size():
		view.solids[i].queue_free()
		if not whole.has(i):
			view.bodies[i].queue_free()
	for i in view.trucks.size():
		if not whole.has(i / 2):
			view.trucks[i].queue_free()
	view.solids.clear()
	t.derail = d.get("derail", {"numeric": false})
	t.wreck = w
	t.sim.set_speed(0.0)
	return w
