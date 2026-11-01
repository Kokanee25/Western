class_name TrainView
extends Node3D
## The train's cars in the world (docs/briefs/train.md, steps 1 and 2; the models are step 3): boxes
## on trucks. Each car's two trucks stand on the track at their own distance, so the car's body is
## the chord between them and swings through a bend as a real one does; the trucks turn under it.
##
## Each car's body is a moving solid (an AnimatableBody3D, on the world's layer): it shoves loose
## things and men, the player stands on it and rides it (its velocity carries him, through the bend
## and up the grade), and bullets hit it. The boxes are shaped to be crossed back to front: the
## coach, express car and boxcar flat-roofed, the ore cars low, the tender stepped up from them
## (a step, the tank) and down at its front to the cab's floor; the engine's cab hollow, open at the
## back, its floor where the engineer stands. Step 3's models bring the real platforms and ladders.
##
## A child of the TrackLine (its space). `place_cars()` stands every car where the sim has it;
## `place(s)` stands them as one rigid train with its front at s (step 1's drawing).

const ENGINE := Color(0.13, 0.12, 0.12)
const IRON := Color(0.08, 0.08, 0.08)
const COLOURS := {&"tender": Color(0.14, 0.13, 0.13), &"ore": Color(0.30, 0.20, 0.14), &"box": Color(0.45, 0.17, 0.10),
	&"express": Color(0.22, 0.26, 0.17), &"coach": Color(0.40, 0.30, 0.14)}
## The fall plate's reach back over the tender's deck from the cab floor's end, m.
const FALL_PLATE := 0.85
## The engine's friction (its pilot): low, so what's struck slides off the V.
const PILOT_FRICTION := 0.08
## The car bodies' underside above the rail top (the trucks under it), m.
const SILL := 0.35

var sim: TrainSim
var track: TrackLine
var bodies: Array[Node3D] = []
var trucks: Array[Node3D] = []  # two a car
## The bodies are solid (AnimatableBody3D); false: drawing only (Node3D).
var solid := true

var _mats := {}


func _mat(colour: Color) -> StandardMaterial3D:
	var key := colour.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = colour
		m.roughness = 0.85
		_mats[key] = m
	return _mats[key]


func setup(on_track: TrackLine, train_sim: TrainSim) -> void:
	track = on_track
	sim = train_sim
	for c in get_children():
		c.free()
	bodies.clear()
	trucks.clear()
	var t := sim.tuning
	for i in sim.cars.size():
		var car: Dictionary = sim.cars[i]
		var body: Node3D
		if solid:
			var ab := AnimatableBody3D.new()
			ab.sync_to_physics = true
			ab.collision_layer = Layers.WORLD
			ab.collision_mask = 0
			ab.set_meta(&"surface", &"metal" if car.kind in [&"engine", &"tender"] else &"wood")
			ab.set_meta(&"train_car", i)
			if car.kind == &"engine":
				# The pilot's iron slats: smooth, so what it meets slides off its V, not ride along on it.
				var pm := PhysicsMaterial.new()
				pm.friction = PILOT_FRICTION
				ab.physics_material_override = pm
			body = ab
		else:
			body = Node3D.new()
		body.name = String(car.name).capitalize().replace(" ", "")
		add_child(body)
		bodies.append(body)
		_shape_car(body, car)
		for w in 2:
			var truck := Node3D.new()
			truck.name = "%sTruck%d" % [body.name, w]
			add_child(truck)
			_box(truck, Vector3(t.gauge + 0.35, 0.45, 1.6), Vector3(0, 0.3, 0), IRON, false)
			trucks.append(truck)


## The car's ends in its body's space: its body's origin is midway between its trucks, -Z forward.
static func ends(car: Dictionary) -> Vector2:
	var tr: Vector2 = car.trucks
	var back: float = float(car.length) * 0.5 - (tr.x + tr.y) * 0.5
	return Vector2(back - float(car.length) * 0.5, back + float(car.length) * 0.5)


## Where the engineer stands in the engine's cab, in its body's space (on the right, facing ahead).
static func cab_spot(car: Dictionary) -> Vector3:
	var e := ends(car)
	return Vector3(0.55, 1.3, e.y - 1.0)


func _shape_car(body: Node3D, car: Dictionary) -> void:
	var e := ends(car)
	var zf := e.x
	var zr := e.y
	var l: float = car.length
	var w: float = car.width
	var h: float = car.height
	var mid := (zf + zr) * 0.5
	match car.kind:
		&"engine":
			var cab := 2.4
			_slab(body, w - 0.3, 0.45, 1.15, zf, zr, ENGINE)  # the frame
			# The pilot (cowcatcher), down to the rail: a V of two raked sides that throws what's on the
			# line off to either side.
			for side in [-1.0, 1.0]:
				var half := (w - 0.3) * 0.5
				var rake := atan2(half, 1.0)
				var along := sqrt(half * half + 1.0)
				var piece := _box(body, Vector3(0.1, 0.63, along), Vector3(side * half * 0.5, 0.435, zf + 0.5), IRON)
				piece.rotation.y = side * rake
				var cs := body.get_child(body.get_child_count() - 1)
				if cs is CollisionShape3D:
					cs.rotation.y = side * rake
			var boiler := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.62
			cyl.bottom_radius = 0.62
			cyl.height = l - cab - 0.6
			boiler.mesh = cyl
			boiler.material_override = _mat(Color(0.12, 0.12, 0.13))
			boiler.rotation_degrees = Vector3(90, 0, 0)
			boiler.position = Vector3(0, 1.75, zf + 0.6 + cyl.height * 0.5)
			body.add_child(boiler)
			_solid(body, Vector3(1.24, 1.24, cyl.height), boiler.position)
			_box(body, Vector3(0.5, 1.1, 0.5), Vector3(0, 2.85, zf + 1.4), Color(0.1, 0.1, 0.1))  # the stack
			# The cab: floor, sides, front and roof, open at the back (the tender's deck meets it).
			var cab_col := Color(0.32, 0.12, 0.08)
			_slab(body, w, 1.15, 1.3, zr - cab, zr, cab_col)
			_box(body, Vector3(0.08, 2.0, cab), Vector3(w * 0.5 - 0.04, 2.3, zr - cab * 0.5), cab_col)
			_box(body, Vector3(0.08, 2.0, cab), Vector3(-w * 0.5 + 0.04, 2.3, zr - cab * 0.5), cab_col)
			_box(body, Vector3(w, 2.0, 0.08), Vector3(0, 2.3, zr - cab + 0.04), cab_col)
			_slab(body, w + 0.2, h - 0.1, h, zr - cab - 0.1, zr + 0.1, cab_col)
			# The fall plate (apron): hinged on the cab floor and lying on the tender's deck, over the
			# gap between them, however the slack moves it.
			_slab(body, w - 0.5, 1.29, 1.32, zr - 0.05, zr + FALL_PLATE, IRON)
		&"tender":
			var col: Color = COLOURS[&"tender"]
			_slab(body, w, SILL, 1.3, zf, zf + 1.4, col)  # the deck (coal) down to the cab's floor
			_slab(body, w, SILL, h, zf + 1.4, zr - 0.5, col)  # the tank
			_slab(body, w, SILL, h - 0.3, zr - 0.5, zr, col)  # a step up from the car behind
		_:
			var col: Color = COLOURS.get(car.kind, COLOURS[&"box"])
			_slab(body, w - 0.4, SILL, 0.95, zf, zr, IRON, false)  # the underframe (drawn)
			_slab(body, w, SILL, h, zf, zr, col)
			if car.kind == &"ore":
				_box(body, Vector3(w - 0.3, 0.06, l - 0.4), Vector3(0, h + 0.01, mid), Color(0.25, 0.24, 0.22), false)  # the ore
			else:
				_box(body, Vector3(w + 0.15, 0.08, l), Vector3(0, h + 0.04, mid), Color(0.18, 0.15, 0.13), false)  # the roof


## A box from y0 to y1 between z0 and z1, drawn and (if `collide`) solid.
func _slab(body: Node3D, w: float, y0: float, y1: float, z0: float, z1: float, colour: Color, collide := true) -> void:
	_box(body, Vector3(w, y1 - y0, z1 - z0), Vector3(0.0, (y0 + y1) * 0.5, (z0 + z1) * 0.5), colour, collide)


func _box(parent: Node3D, size: Vector3, at: Vector3, colour: Color, collide := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _mat(colour)
	mi.position = at
	parent.add_child(mi)
	if collide:
		_solid(parent, size, at)
	return mi


func _solid(parent: Node3D, size: Vector3, at: Vector3) -> void:
	if not (solid and parent is CollisionObject3D):
		return
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = at
	parent.add_child(cs)


## Stand every car where the sim has it now (`f` of the way from the last tick, for drawing between
## ticks; the solids at 1.0).
func place_cars(f := 1.0) -> void:
	for i in sim.cars.size():
		var front := sim.car_s(i, f)
		var tr: Vector2 = sim.cars[i].trucks
		_stand(i, front - tr.x, front - tr.y)


## Stand every car on the track as one rigid train with its front at s.
func place(s: float) -> void:
	for i in sim.cars.size():
		_stand(i, sim.truck_s(i, 0, s), sim.truck_s(i, 1, s))


func _stand(i: int, s0: float, s1: float) -> void:
	var f0 := track.transform_at(s0)
	var f1 := track.transform_at(s1)
	trucks[i * 2].transform = f0
	trucks[i * 2 + 1].transform = f1
	var fwd := (f0.origin - f1.origin).normalized()
	var up := (f0.basis.y + f1.basis.y).normalized()
	bodies[i].transform = Transform3D(Basis.looking_at(fwd, up), (f0.origin + f1.origin) * 0.5)
