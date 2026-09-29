class_name GlassCuts
## A window breaking throws shards: mostly on with whatever broke it, some back the other way.
## Each is traced as a small, low-energy cutter; anyone it reaches within a couple of metres gets a
## shallow slice (faces and hands, mostly), and some shards stay in the wound for the doctor.

const REACH := 2.4


static func spray(world: Node3D, at: Vector3, direction: Vector3, pane_area: float, seed: int, exclude: Array[RID] = []) -> int:
	if world == null or not world.is_inside_tree():
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var space := world.get_world_3d().direct_space_state
	var dir := direction.normalized() if direction.length() > 0.01 else Vector3.FORWARD
	var count := clampi(int(pane_area * 24.0), 8, 22)
	var cuts := 0
	var cut_already := {}
	for i in count:
		var d := dir if rng.randf() < 0.8 else -dir
		d = _cone(d, deg_to_rad(38.0), rng)
		d.y -= rng.randf_range(0.0, 0.25)
		var q := PhysicsRayQueryParameters3D.create(at, at + d.normalized() * REACH * rng.randf_range(0.5, 1.0), Layers.BULLETS)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty() or not (hit.collider as Object).has_meta(&"human_body"):
			continue
		var person: Object = (hit.collider as Object).get_meta(&"human_body")
		# A handful of cuts each at most; flying glass slows fast with distance.
		var n: int = cut_already.get(person, 0)
		if n >= 4:
			continue
		cut_already[person] = n + 1
		var travelled := at.distance_to(hit.position)
		var depth := rng.randf_range(0.002, 0.009) * clampf(1.4 - travelled / REACH, 0.3, 1.0)
		person.call(&"take_cut", hit.collider, hit.position, d.normalized(), depth, rng.randf() < 0.3)
		cuts += 1
	return cuts


static func _cone(d: Vector3, radians: float, rng: RandomNumberGenerator) -> Vector3:
	var side := d.cross(Vector3.UP)
	if side.length() < 0.01:
		side = d.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(d).normalized()
	var r := sqrt(rng.randf()) * tan(radians)
	var a := rng.randf() * TAU
	return (d + side * cos(a) * r + up * sin(a) * r).normalized()
