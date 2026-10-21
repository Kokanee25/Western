class_name BlastCloud
extends Node3D
## What a charge throws up, after the road-blasting footage Sean picked (2026-10-21; described in
## docs/briefs/blast-look.md): a flash over in a blink and next to no fire; a dark jet of dust and
## grit out of whichever side is open (away from the ground, the wall it lay against); then a cloud
## of whatever it blew apart (street dirt, splintered boards), dark and dense at the root and lit
## pale on top where it billows, climbing slowly and drifting off on the breeze; a surge of dust
## rolling out along the ground; dark chunks flung in arcs. Everything is lit by the world (the
## cloud isn't a light), seeded by where it went off, and scaled by the cube root of the charge.

## How long the cloud hangs (s); a charge's dust stays longer than a shot's smoke.
const LIFETIME := 16.0

static var _hot_material: StandardMaterial3D
static var _chunk_material: StandardMaterial3D
static var _dust_material: StandardMaterial3D

var _drift := Vector3.ZERO
var _age := 0.0
var _size := 1.0
var _fog: FogVolume
var _fog_mat: FogMaterial


## A charge of `kg` TNT gone off at `at`.
static func spawn(world: Node3D, at: Vector3, kg: float) -> BlastCloud:
	var size := pow(maxf(kg, 0.01) / 0.15, 1.0 / 3.0)
	var vent := vent_of(world, at)
	var dust := dust_of(world, at)
	var seed_value := hash(Vector3i((at * 100.0).round())) & 0x7fffffff
	_flash(world, at, vent, size, seed_value)
	_chunks(world, at, vent, dust, size, seed_value)
	var c := BlastCloud.new()
	c.name = "BlastCloud"
	world.add_child(c)
	c.global_position = at
	c._start(vent, dust, size, seed_value, GunSmoke._is_indoors(c, at))
	return c


## The way the blast vents: away from whatever's close round the charge (the ground under it, a
## wall it lay against), from rays a metre out every way; straight up in the open.
static func vent_of(world: Node3D, at: Vector3) -> Vector3:
	var space := world.get_world_3d().direct_space_state
	var open := Vector3.ZERO
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				if x == 0 and y == 0 and z == 0:
					continue
				var d := Vector3(x, y, z).normalized()
				var q := PhysicsRayQueryParameters3D.create(at + d * 0.03, at + d * 1.0, Layers.WORLD)
				if space.intersect_ray(q).is_empty():
					open += d
	if open.length() < 0.01:
		return Vector3.UP
	# A blast always throws up as well as out: the open side, leaning up.
	return (open.normalized() + Vector3.UP * 0.6).normalized()


## The colour of what it throws up: the street's dirt, boards' wood, stone.
static func dust_of(world: Node3D, at: Vector3) -> Color:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.1, at + Vector3.DOWN * 0.6, Layers.WORLD)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit.collider is StructureMember:
		var m := hit.collider as StructureMember
		if m.wood == &"stone":
			return Color(0.58, 0.56, 0.52)
		return Color(0.6, 0.5, 0.38)
	return Color(0.56, 0.45, 0.34)


## The flash: a hot white light gone in a tenth of a second, and a small fierce core that's gone
## before the dust is out (no rolling fireball: dynamite doesn't make one).
static func _flash(world: Node3D, at: Vector3, vent: Vector3, size: float, seed_value: int) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.86, 0.66)
	light.light_energy = 14.0 * size
	light.omni_range = 18.0 * size
	light.shadow_enabled = false
	world.add_child(light)
	light.global_position = at + vent * 0.4
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.12)
	tw.tween_callback(light.queue_free)
	var p := _particles(world, int(10 * size), 0.16, seed_value + 1)
	var pm := ParticleProcessMaterial.new()
	pm.direction = vent
	pm.spread = 60.0
	pm.initial_velocity_min = 2.0 * size
	pm.initial_velocity_max = 6.0 * size
	pm.damping_min = 20.0
	pm.damping_max = 30.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.8
	pm.scale_max = 1.4
	pm.scale_curve = _curve([Vector2(0.0, 0.6), Vector2(0.3, 1.0), Vector2(1.0, 0.2)])
	pm.color_ramp = _ramp([[0.0, Color(1.0, 0.96, 0.86, 1.0)], [0.5, Color(1.0, 0.72, 0.4, 0.8)], [1.0, Color(0.6, 0.4, 0.3, 0.0)]])
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.7, 0.7) * size
	quad.material = _hot()
	p.draw_pass_1 = quad
	p.global_position = at
	p.emitting = true


## Dark lumps of what it blew apart (clods of dirt, splinters of board), flung out in arcs.
static func _chunks(world: Node3D, at: Vector3, vent: Vector3, dust: Color, size: float, seed_value: int) -> void:
	var p := _particles(world, int(46 * size), 1.8, seed_value + 2)
	p.randomness = 0.6
	var pm := ParticleProcessMaterial.new()
	pm.direction = vent
	pm.spread = 55.0
	pm.initial_velocity_min = 5.0 * sqrt(size)
	pm.initial_velocity_max = 15.0 * sqrt(size)
	pm.gravity = Vector3(0, -9.8, 0)
	pm.damping_min = 0.2
	pm.damping_max = 0.8
	pm.scale_min = 0.3
	pm.scale_max = 1.0
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -540.0
	pm.angular_velocity_max = 540.0
	pm.color = Color(dust.r * 0.5, dust.g * 0.47, dust.b * 0.44)
	p.process_material = pm
	var box := BoxMesh.new()
	box.size = Vector3(0.05, 0.035, 0.07)
	box.material = _chunk()
	p.draw_pass_1 = box
	p.global_position = at
	p.emitting = true


static func _particles(world: Node3D, amount: int, lifetime: float, seed_value: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.amount = maxi(amount, 1)
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.local_coords = false
	p.use_fixed_seed = true
	p.seed = seed_value
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-20, -4, -20), Vector3(40, 24, 40))
	world.add_child(p)
	p.finished.connect(p.queue_free)
	return p


## The dust: the jet out of the open side, the cloud that billows up over it, the surge along the
## ground, and (where the renderer has them) a fog volume that fills the air the cloud's in.
func _start(vent: Vector3, dust: Color, size: float, seed_value: int, indoors: bool) -> void:
	_size = size
	GunSmoke._load_tuning()
	var tn := GunSmoke.tuning
	_drift = tn.wind * (tn.indoor_wind if indoors else 1.0) * 0.8 + Vector3.UP * 0.18
	var root := dust * 0.62
	root.a = 0.92
	var mid := dust * 0.95
	mid.a = 0.72
	var pale := dust.lerp(Color(0.92, 0.9, 0.86), 0.5)
	pale.a = 0.0
	# The jet: dense and dark, fast out of the open side, stopping within a few metres.
	var jet := _dust(int(40 * size), 7.0, seed_value + 3)
	var jm := jet.process_material as ParticleProcessMaterial
	jm.direction = vent
	jm.spread = 24.0
	jm.initial_velocity_min = 5.0 * size
	jm.initial_velocity_max = 13.0 * size
	jm.damping_min = 10.0
	jm.damping_max = 15.0
	jm.gravity = Vector3(0, 0.1, 0)
	jm.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.15, 1.2), Vector2(1.0, 2.6)])
	jm.color_ramp = _ramp([[0.0, root], [0.35, mid], [1.0, pale]])
	jet.draw_pass_1 = _quad(1.3 * size)
	# The billow: slower, wider, climbing, darker at its root, paling as it rises and spreads.
	var billow := _dust(int(44 * size), LIFETIME * 0.8, seed_value + 4)
	var bm := billow.process_material as ParticleProcessMaterial
	bm.direction = vent
	bm.spread = 50.0
	bm.initial_velocity_min = 1.5 * size
	bm.initial_velocity_max = 5.0 * size
	bm.damping_min = 2.5
	bm.damping_max = 5.0
	bm.gravity = Vector3(0, 0.22, 0)
	bm.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.1, 1.0), Vector2(1.0, 3.2)])
	bm.color_ramp = _ramp([[0.0, root], [0.2, mid], [1.0, pale]])
	billow.draw_pass_1 = _quad(1.6 * size)
	# The surge: dust thrown out low and rolling along the ground all round.
	var surge := _dust(int(30 * size), LIFETIME * 0.6, seed_value + 5)
	var sm := surge.process_material as ParticleProcessMaterial
	sm.direction = Vector3.RIGHT
	sm.spread = 180.0
	sm.flatness = 1.0
	# Born through the lowest metre, not in one plane (their tops lined up into a hard dark edge).
	sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sm.emission_box_extents = Vector3(0.5, 0.35, 0.5) * size
	sm.initial_velocity_min = 4.0 * size
	sm.initial_velocity_max = 9.0 * size
	sm.damping_min = 5.0
	sm.damping_max = 8.0
	sm.gravity = Vector3(0, 0.05, 0)
	sm.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.2, 1.0), Vector2(1.0, 2.4)])
	var low := dust * 0.9
	low.a = 0.6
	sm.color_ramp = _ramp([[0.0, low], [0.3, mid], [1.0, pale]])
	surge.draw_pass_1 = _quad(1.2 * size)
	surge.position = Vector3.UP * 0.45 * size
	if not GunSmoke.supports_fog_volumes():
		return
	_fog = FogVolume.new()
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_fog.size = Vector3.ONE * 0.5
	_fog_mat = FogMaterial.new()
	_fog_mat.density = 0.0
	_fog_mat.albedo = dust.lerp(Color(0.9, 0.88, 0.84), 0.3)
	_fog.material = _fog_mat
	add_child(_fog)
	_fog.position = vent * 1.2 * size


## Lit dust particles riding this node (it drifts on the breeze): GunSmoke's puffs, shaded by the
## world's light so the cloud's top catches the sun and its root is dark.
func _dust(amount: int, lifetime: float, seed_value: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.amount = maxi(amount, 1)
	p.lifetime = lifetime
	p.explosiveness = 0.95
	p.randomness = 0.5
	p.local_coords = true
	p.use_fixed_seed = true
	p.seed = seed_value
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-20, -4, -20), Vector3(40, 24, 40))
	var pm := ParticleProcessMaterial.new()
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 1.0
	pm.turbulence_noise_scale = 3.5
	pm.turbulence_noise_speed = Vector3(0.1, 0.25, 0.1)
	pm.turbulence_influence_min = 0.04
	pm.turbulence_influence_max = 0.12
	pm.scale_min = 0.7
	pm.scale_max = 1.5
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -10.0
	pm.angular_velocity_max = 10.0
	p.process_material = pm
	add_child(p)
	p.emitting = true
	return p


func _quad(side: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(side, side)
	quad.material = _dust_mat()
	return quad


## The gun smoke's lit puff, faded where it meets the ground or a wall (a puff the size of a man cut
## by the street drew a hard dark edge).
static func _dust_mat() -> StandardMaterial3D:
	if _dust_material == null:
		_dust_material = GunSmoke._puff_material().duplicate() as StandardMaterial3D
		_dust_material.proximity_fade_enabled = true
		_dust_material.proximity_fade_distance = 0.8
	return _dust_material


func _process(delta: float) -> void:
	var t0 := Prof.start()
	_age += delta
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	global_position += _drift * delta * smoothstep(0.0, 0.25, t)
	if _fog:
		# It swells as the dust spreads, thickest a second or two in, thinning as it drifts.
		var s := lerpf(1.0, 6.0, sqrt(t)) * _size
		_fog.size = Vector3(s, s * 0.75, s)
		_fog_mat.density = 0.6 * smoothstep(0.0, 0.08, t) * pow(1.0 - t, 1.5)
	if _age > LIFETIME:
		queue_free()
	Prof.stop(&"smoke", t0)


static func _hot() -> StandardMaterial3D:
	if _hot_material == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = PixelArt.puff("flash", 103)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.vertex_color_use_as_albedo = true
		_hot_material = m
	return _hot_material


static func _chunk() -> StandardMaterial3D:
	if _chunk_material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		_chunk_material = m
	return _chunk_material


static func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	c.max_value = 4.0
	for pt: Vector2 in points:
		c.add_point(pt)
	var tex := CurveTexture.new()
	tex.curve = c
	return tex


static func _ramp(stops: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s: Array) -> float: return s[0]))
	g.colors = PackedColorArray(stops.map(func(s: Array) -> Color: return s[1]))
	var tex := GradientTexture1D.new()
	tex.gradient = g
	return tex


## Draw it once, out of sight, so its materials are compiled at load rather than on the first blast.
static func warm_up(parent: Node3D, at: Vector3) -> Array[Node]:
	var out: Array[Node] = []
	for mat: Material in [_hot(), _chunk(), _dust_mat()]:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.001
		box.material = mat
		mi.mesh = box
		parent.add_child(mi)
		mi.global_position = at
		out.append(mi)
	return out
