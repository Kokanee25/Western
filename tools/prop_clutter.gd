extends RefCounted
## A cluttered street for the bench (docs/briefs/props-scale.md): `times` as many of the street's
## kit props as it has, the copies of each one alike (a fitted counter keeps its fit), laid in rows
## along the street either side of its middle, like with like, each where nothing else stands and
## on whatever's under it. Hung props stay on their walls (they'd need one).
##
##   var made: Array = PropClutter.lay(street, 4)
## Untyped where it meets the game's classes: perf_bench (an -s script) loads it before autoloads.

## The rows (z, where the street's middle is -8.4; they follow it round its bend) and how far down
## the street they run (x), m. (The middle, -7.0 to -9.4, left for riders and walkers.)
const ROWS := [-5.2, -11.2, -6.4, -10.0]
const FROM_X := 8.0
const TO_X := -110.0
const GAP := 0.35


static func lay(street: Node3D, times := 4) -> Array:
	var sources := []
	for p in street.find_children("*", "KitProp", true, false):
		if p.get(&"loose") or p.call(&"hung"):
			continue
		sources.append(p)
	sources.sort_custom(func(a, b) -> bool: return String(a.get(&"kit_id")) < String(b.get(&"kit_id")))
	var root := Node3D.new()
	root.name = "Clutter"
	street.add_child(root)
	var space: PhysicsDirectSpaceState3D = World.space(street)
	var made := []
	var taken: Array[Rect2] = []  # what it's put down itself (a body added this frame isn't in a query yet)
	var row := 0
	var x := FROM_X
	var kit = load("res://src/props/prop_kit.gd")
	for k in times - 1:
		for src in sources:
			var def: Dictionary = src.get(&"definition")
			var box: AABB = kit.bounds(def)
			var width := box.size.x
			var placed := false
			while not placed and row < ROWS.size():
				var along: float = x - box.end.x
				var z: float = TownLayout.street_z(along + box.get_center().x) + ROWS[row] - TownLayout.OLD_MIDDLE
				var lo: float = minf(TownLayout.ground_height(along + box.position.x), TownLayout.ground_height(along + box.end.x))
				var hi: float = maxf(TownLayout.ground_height(along + box.position.x), TownLayout.ground_height(along + box.end.x))
				var at := Vector3(along, hi, z - box.get_center().z)
				if at.x + box.position.x < TO_X:
					row += 1
					x = FROM_X
					continue
				var foot := Rect2(at.x + box.position.x, at.z + box.position.z, box.size.x, box.size.z).grow(0.05)
				if _free(space, at, box) and not taken.any(func(r: Rect2) -> bool: return r.intersects(foot)):
					taken.append(foot)
					var p = kit.spawn(src.get(&"kit_id"))
					p.set(&"definition", def.duplicate(true))
					root.add_child(p)
					var y := _ground(space, at, box, lo)
					if y == lo:
						# On the street: tilted to its slope (the ground goes with x alone), its feet on it.
						var slope: float = TownLayout.ground_height(at.x + 0.5) - TownLayout.ground_height(at.x - 0.5)
						p.global_transform = Transform3D(Basis(Vector3.BACK, atan(slope)), Vector3(at.x, TownLayout.ground_height(at.x), at.z))
					else:
						p.global_position = Vector3(at.x, y, at.z)
					made.append(p)
					placed = true
				x -= width + GAP if placed else 0.5
			if row >= ROWS.size():
				return made
	return made


## Nothing solid in its box there (a horse, a rail, a trough, a wagon).
static func _free(space: PhysicsDirectSpaceState3D, at: Vector3, box: AABB) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size + Vector3(0.1, 0.0, 0.1)
	q.shape = shape
	q.transform = Transform3D(Basis(), at + box.get_center() + Vector3.UP * 0.03)  # a wheel lying flat is 6 cm
	q.collision_mask = 1 | 8  # Layers.WORLD | Layers.PEOPLE
	return space.intersect_shape(q, 1).is_empty()


## The boards under its middle, or `low` when it's the ground there.
static func _ground(space: PhysicsDirectSpaceState3D, at: Vector3, box: AABB, low: float) -> float:
	var c := Vector3(at.x + box.get_center().x, at.y, at.z + box.get_center().z)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(c + Vector3.UP * 2.0, c + Vector3.DOWN * 2.0, 1))
	if hit.is_empty() or Ground.is_ground(hit.collider):
		return low
	return (hit.position as Vector3).y
