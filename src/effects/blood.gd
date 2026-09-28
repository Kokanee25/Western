class_name Blood
## Blood that lands on things: splats on the ground and walls where jets, drips, sprays out of exit
## wounds and coughs come down. Splats stay (consequences stay); a new one close to an old one
## grows it instead, and past the cap the nearest one grows. Shared by everyone in a world.

const MAX_SPLATS := 160
const MERGE_DISTANCE := 0.07
const ARTERIAL := Color(0.56, 0.04, 0.03)
const VENOUS := Color(0.3, 0.02, 0.03)

static var _splats: Array[Decal] = []


## Put (or grow) a splat of `ml` of blood at a point on a surface. Returns the decal.
static func splat(world: Node, at: Vector3, normal: Vector3, ml: float) -> Decal:
	var alive: Array[Decal] = []
	for d in _splats:
		if is_instance_valid(d):
			alive.append(d)
	_splats = alive
	var nearest: Decal = null
	var best := INF
	for d in _splats:
		if not d.is_inside_tree():
			continue
		var dist := d.global_position.distance_to(at)
		if dist < best:
			best = dist
			nearest = d
	if nearest != null and (best < MERGE_DISTANCE or _splats.size() >= MAX_SPLATS):
		_grow(nearest, ml)
		return nearest
	var d := Decal.new()
	d.name = "BloodSplat"
	d.texture_albedo = PixelArt.blood("splat%d" % (_splats.size() % 4), 40 + _splats.size() % 4, false, 16)
	d.modulate = Color(0.8, 0.75, 0.75)
	d.cull_mask = Layers.WORLD
	d.upper_fade = 0.0
	d.lower_fade = 0.0
	d.set_meta(&"ml", 0.0)
	d.add_to_group(&"blood_splats")
	world.add_child(d)
	d.global_position = at
	d.global_basis = HumanBody._along(normal).rotated(normal.normalized(), randf() * TAU) if normal.length() > 0.01 else Basis()
	_grow(d, ml)
	_splats.append(d)
	return d


static func _grow(d: Decal, ml: float) -> void:
	var total: float = d.get_meta(&"ml", 0.0) + ml
	d.set_meta(&"ml", total)
	# A thin film: ~2 mm deep on dirt, so area grows with volume.
	var r := clampf(sqrt(total * 1e-6 / 0.002 / PI), 0.012, 0.6)
	d.size = Vector3(r * 2.0, 0.12, r * 2.0)


## Throw blood from a point with a velocity and see where it comes down (world geometry only).
## Adds a splat there and returns the landing point, or null if it flew off into nothing.
static func throw(world: Node3D, from: Vector3, velocity: Vector3, ml: float, exclude: Array[RID] = []) -> Variant:
	var space := world.get_world_3d().direct_space_state
	var p := from
	var v := velocity
	var dt := 0.04
	for i in 50:
		var next := p + v * dt
		v.y -= 9.8 * dt
		var q := PhysicsRayQueryParameters3D.create(p, next, Layers.WORLD)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			splat(world, hit.position, hit.normal, ml)
			return hit.position
		p = next
	return null


## A spray out of an exit wound: several drops flung along the ball's path, spattering whatever
## is behind within a few metres.
static func spray(world: Node3D, from: Vector3, direction: Vector3, ml: float, drops: int, rng: RandomNumberGenerator) -> void:
	for i in drops:
		var dir := (direction + Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.2, 0.3), rng.randf_range(-0.35, 0.35))).normalized()
		throw(world, from, dir * rng.randf_range(3.0, 7.0), ml / drops)


static func clear() -> void:
	for d in _splats:
		if is_instance_valid(d):
			d.queue_free()
	_splats.clear()
