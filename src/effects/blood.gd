class_name Blood
## Blood that lands on things: splats on the ground and walls where jets, drips, sprays out of exit
## wounds and coughs come down. Splats stay (consequences stay); a new one close to an old one
## grows it instead, and past the cap the nearest one grows. Shared by everyone in a world.

const MAX_SPLATS := 160
const MERGE_DISTANCE := 0.07
const ARTERIAL := Color(0.56, 0.04, 0.03)
const VENOUS := Color(0.3, 0.02, 0.03)

static var _splats: Array[Decal] = []

## A drop's radius (m) and how long a stretch of its flight it draws (s).
const DROP_RADIUS := 0.0048
const TRAIL_SECONDS := 0.035
static var _drop_mesh: TubeTrailMesh
static var _drop_ramps: Array[GradientTexture1D] = []


## Blood drops in flight, for a jet or a burst: each drop draws its last few hundredths of a second
## of flight as a thin tube (a particle trail). Where they leave close together, a jet's tubes run
## into one stream; out along the arc, slowing and spreading, they come apart into drops. The
## boxes they replaced read as red bricks.
static func drop_particles(amount: int, lifetime: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.trail_enabled = true
	p.trail_lifetime = TRAIL_SECONDS
	p.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	if _drop_mesh == null:
		_drop_mesh = TubeTrailMesh.new()
		_drop_mesh.radius = DROP_RADIUS
		_drop_mesh.radial_steps = 4
		_drop_mesh.sections = 8
		_drop_mesh.section_length = 0.01
		_drop_mesh.section_rings = 1
		var thin := Curve.new()  # fuller at the head of each drop, drawn out to a tail
		thin.add_point(Vector2(0.0, 0.35))
		thin.add_point(Vector2(1.0, 1.0))
		_drop_mesh.curve = thin
		var mat := StandardMaterial3D.new()
		mat.use_particle_trails = true
		mat.vertex_color_use_as_albedo = true
		# Wet, but no hard highlights: the look is painted.
		mat.roughness = 0.55
		mat.metallic_specular = 0.25
		_drop_mesh.material = mat
		# Each drop a little different, and darkening as it flies.
		for ends in [[Color(1, 1, 1), Color(0.78, 0.74, 0.74)], [Color(1, 1, 1), Color(0.7, 0.66, 0.66)]]:
			var g := Gradient.new()
			g.set_color(0, ends[0])
			g.set_color(1, ends[1])
			var t := GradientTexture1D.new()
			t.gradient = g
			_drop_ramps.append(t)
	p.draw_pass_1 = _drop_mesh
	var pm := ParticleProcessMaterial.new()
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	pm.color_initial_ramp = _drop_ramps[0]
	pm.color_ramp = _drop_ramps[1]
	p.process_material = pm
	return p


## A burst of blood drops (a cough, a limb torn off): `count` drops thrown along `dir`.
static func burst(parent: Node, at: Vector3, dir: Vector3, count: int, speed: float, colour := ARTERIAL) -> void:
	var p := drop_particles(count, 1.2)
	p.one_shot = true
	p.explosiveness = 0.9
	var pm := p.process_material as ParticleProcessMaterial
	pm.direction = dir.normalized()
	pm.spread = 35.0
	pm.initial_velocity_min = speed * 0.4
	pm.initial_velocity_max = speed
	pm.color = colour
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	p.finished.connect(p.queue_free)


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
