class_name TrainCars
extends RefCounted
## The cars' shapes as boxes (docs/briefs/train.md, step 2; the real models are step 3): one list a
## car, drawn and solid alike, so what you see is what you stand on. Built to be walked end to end
## (Sean, 2026-11-01: back to front, moving or stopped): every car's floor is at `DECK` above the
## rail, its deck runs a little past its ends (`LIP`) so the gap between cars is a stride, and
## where a car is taller the way over it is steps (no step higher than the player can take):
##
##   coach, express  a shell: end platforms, walls, a roof, a doorway in each end; you walk the aisle
##   box             shut: a ladder up each end to the roof walk (Ladder, step 3)
##   ore             a floor with low sides, open ends: you walk along inside
##   tender          the coal space in front at deck height, steps up over the tank, steps down behind
##   engine          the cab at the back (open to the tender), the boiler, the frame, a pilot in front
##
## A shape: {size: Vector3, at: Vector3 (its middle), colour, solid: bool, surface} in the car's
## frame (origin on the rail top midway between its trucks, -Z toward its front, +Y up); the pilot
## is {hull: PackedVector3Array} (a wedge that shoves things aside); a ladder is {ladder, at (its
## foot), height, facing (+1: it faces the car's back, -1 its front)}.

## The car floors above the rail top, m (a narrow-gauge car's floor ~1.1 m).
const DECK := 1.1
## How far each car's floor reaches past its ends, m: the gap left to step over is
## `coupler_gap - 2 x LIP` (0.3 m at the couplers' middle).
const LIP := 0.15
## The under-frame's bottom (the sills), m above the rail.
const FRAME_BOTTOM := 0.65
## Stairs: rise and run, m (the player steps up 0.3 at most).
const RISE := 0.25
const RUN := 0.28


## The shapes of a car (`car` as TrainSim.cars[i]).
static func shapes(car: Dictionary, t: TrainTuning) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var l: float = car.length
	var tr: Vector2 = car.trucks
	var mid := (tr.x + tr.y) * 0.5  # the car's front is this far ahead of its frame's origin
	var w := t.car_width * 0.5
	var kind: StringName = car.kind
	var wood := &"wood"
	var colour := Color(0.45, 0.17, 0.10)
	match kind:
		&"engine", &"tender":
			wood = &"metal"
			colour = Color(0.13, 0.12, 0.12)
		&"ore":
			colour = Color(0.27, 0.19, 0.13)
		&"express":
			colour = Color(0.22, 0.30, 0.22)
		&"coach":
			colour = Color(0.55, 0.40, 0.17)
	# A box from `z0` to `z1` metres behind the car's front, `x0..x1` across, `y0..y1` up.
	var box := func(z0: float, z1: float, x0: float, x1: float, y0: float, y1: float, c := colour, solid := true) -> void:
		out.append({"size": Vector3(x1 - x0, y1 - y0, z1 - z0),
			"at": Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5 - mid),
			"colour": c, "solid": solid, "surface": wood})
	# Stairs from z_a (at height y_a) to z_b (at y_b), filled down to the deck: the steps drawn, and
	# walked as a ramp laid over their nosings (as the saloon's stair is: treads this short catch a
	# walker's feet on every riser).
	var stairs := func(z_a: float, z_b: float, y_a: float, y_b: float, x0: float, x1: float) -> void:
		var steps := maxi(1, int(ceil(absf(y_b - y_a) / RISE)))
		var dz := (z_b - z_a) / steps
		var dy := (y_b - y_a) / steps
		for k in steps:
			var za := z_a + dz * k
			var zb := za + dz
			box.call(minf(za, zb), maxf(za, zb), x0, x1, DECK, y_a + dy * (k + 1), colour, false)
		# The ramp's top: from the floor a step before the first riser to the last nosing.
		var p0 := Vector2(z_a - dz, y_a)
		var p1 := Vector2(z_b - dz, y_b)
		var run := p1 - p0
		var along := run.length()
		var thick := 0.06
		var normal := Vector2(-run.y, run.x).normalized() * (1.0 if run.x > 0.0 else -1.0)  # up out of the ramp
		var centre := (p0 + p1) * 0.5 - normal * thick * 0.5
		out.append({"size": Vector3(x1 - x0, thick, along), "at": Vector3((x0 + x1) * 0.5, centre.y, centre.x - mid),
			"basis": Basis(Vector3.RIGHT, atan2(-run.y, run.x)), "colour": colour, "solid": true, "drawn": false,
			"surface": wood})
	# The floor and its frame, every car, a lip past each end.
	var deck_w := w if kind != &"engine" else 0.95
	box.call(-LIP, l + LIP, -deck_w, deck_w, FRAME_BOTTOM, DECK, colour.darkened(0.35))
	match kind:
		&"engine":
			var cab := 2.6
			# The boiler and smokebox, in front of the cab.
			out.append({"cylinder": true, "radius": 0.62, "height": l - cab - 1.4,
				"at": Vector3(0.0, 1.75, (1.2 + l - cab) * 0.5 - mid), "colour": colour, "solid": true, "surface": wood})
			box.call(1.9, 2.4, -0.25, 0.25, 2.3, 3.4, colour.darkened(0.2))  # the stack
			box.call(3.6, 4.6, -0.35, 0.35, 2.3, 2.8, colour)  # the steam dome
			# The cab: its front (the backhead) and sides, its roof; open behind to the tender.
			var red := Color(0.32, 0.12, 0.08)
			box.call(l - cab, l - cab + 0.08, -1.1, 1.1, DECK, DECK + 2.1, red)
			# The sides stop short of the back: the gangway, open either side, where you get on and off.
			box.call(l - cab, l - 0.75, -1.1, -1.02, DECK, DECK + 2.1, red)
			box.call(l - cab, l - 0.75, 1.02, 1.1, DECK, DECK + 2.1, red)
			box.call(l - cab - 0.15, l + 0.1, -1.18, 1.18, DECK + 2.1, DECK + 2.18, red.darkened(0.3))
			# The pilot: a wedge ahead of the frame that shoves what's on the line aside.
			var hull := PackedVector3Array()
			for p in [Vector3(-0.12, 0.12, 0.0), Vector3(0.12, 0.12, 0.0), Vector3(-0.12, 0.9, 0.0), Vector3(0.12, 0.9, 0.0),
					Vector3(-0.95, 0.12, 1.3), Vector3(0.95, 0.12, 1.3), Vector3(-0.95, 0.9, 1.3), Vector3(0.95, 0.9, 1.3)]:
				hull.append(Vector3(p.x, p.y, p.z - LIP - mid))
			out.append({"hull": hull, "colour": Color(0.2, 0.18, 0.17), "solid": true, "surface": wood})
		&"tender":
			var top := DECK + 0.9
			stairs.call(0.25, 1.45, DECK, top, -1.0, 1.0)
			box.call(1.45, l - 1.45, -1.0, 1.0, DECK, top)
			stairs.call(l - 0.25, l - 1.45, DECK, top, -1.0, 1.0)
		&"ore":
			box.call(-LIP, l + LIP, -w, -w + 0.1, DECK, DECK + 0.6)
			box.call(-LIP, l + LIP, w - 0.1, w, DECK, DECK + 0.6)
		&"box":
			# Shut (its side doors closed): a solid box you go over by a ladder at each end and
			# its roof walk (step 3, Ladder; step 2 had steps up from each end).
			var roof := DECK + 2.0
			box.call(0.0, l, -w, w, DECK, roof)
			for end in [0.0, l]:
				out.append({"ladder": true, "at": Vector3(0.0, DECK, end - mid), "height": roof - DECK,
					"facing": -1.0 if end == 0.0 else 1.0, "solid": false, "drawn": false})
		&"coach", &"express":
			var plat := 0.9
			var h := 2.3
			var door := 0.45
			box.call(plat, l - plat, -w, -w + 0.08, DECK, DECK + h)  # sides
			box.call(plat, l - plat, w - 0.08, w, DECK, DECK + h)
			box.call(plat - 0.3, l - plat + 0.3, -w - 0.08, w + 0.08, DECK + h, DECK + h + 0.1, colour.darkened(0.4))  # roof
			for z in [plat, l - plat - 0.08]:  # the end walls, a doorway in each
				box.call(z, z + 0.08, -w, -door, DECK, DECK + h)
				box.call(z, z + 0.08, door, w, DECK, DECK + h)
				box.call(z, z + 0.08, -door, door, DECK + 2.0, DECK + h)
	return out


## The trucks' box (drawn only: the wheels are under the deck).
static func truck_shape(t: TrainTuning) -> Dictionary:
	return {"size": Vector3(t.gauge + 0.35, 0.45, 1.6), "at": Vector3(0, 0.3, 0), "colour": Color(0.08, 0.08, 0.08)}
