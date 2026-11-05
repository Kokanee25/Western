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

static var _chunk_material: StandardMaterial3D
static var _dust_material: StandardMaterial3D
static var _glow_material: StandardMaterial3D

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
	_chunks(world, at, vent, dust, size, seed_value, speed_cap(world, at, vent))
	var c := BlastCloud.new()
	c.name = "BlastCloud"
	world.add_child(c)
	c.global_position = at
	c._start_next_tick(vent, dust, size, seed_value)
	return c


## The dust begins a tick after the flash (#538: its three particle systems were ~5-8 ms of the
## blast's own tick, the heaviest of the game's frames; a tick later is the same picture).
func _start_next_tick(vent: Vector3, dust: Color, size: float, seed_value: int) -> void:
	_size = size
	await get_tree().physics_frame
	if is_inside_tree():
		# The first instant's ring of dust along the ground and its dirt thrown up (#596 step 3):
		# where it went off, not riding the cloud's drift.
		var world := get_parent() as Node3D
		_ring(world, global_position, dust, size, seed_value)
		_spray(world, global_position, vent, dust, size, seed_value, speed_cap(world, global_position, vent))
		_start(vent, dust, size, seed_value, GunSmoke._is_indoors(self, global_position))


## The way the blast vents: away from whatever's close round the charge (the ground under it, a
## wall it lay against), from rays a metre out every way; straight up in the open.
static func vent_of(world: Node3D, at: Vector3) -> Vector3:
	var space := World.space(world)
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
	var hit := World.space(world).intersect_ray(q)
	if not hit.is_empty() and hit.collider is StructureMember:
		var m := hit.collider as StructureMember
		if m.is_masonry():
			return MasonryMaterials.dust_colour(m.wood, Color(0.58, 0.56, 0.52))
		return Color(0.6, 0.5, 0.38)
	return Color(0.56, 0.45, 0.34)


## The flash (#596 step 3): one light, no shadows, white-hot going orange and out in a tenth of a
## second, and a burst of glows at the charge thrown out along the vent and gone with it. No rolling
## fireball: dynamite doesn't make one (a core of hot puffs drew a dark red blot in the sky when a
## frame ran long). BlastTuning's "The first instant".
static func _flash(world: Node3D, at: Vector3, vent: Vector3, size: float, seed_value: int) -> void:
	var tn := Blast.t()
	var light := OmniLight3D.new()
	light.name = "BlastFlash"
	light.light_color = tn.flash_hot
	light.light_energy = tn.flash_energy * size
	light.omni_range = tn.flash_range * size
	light.shadow_enabled = false
	world.add_child(light)
	light.global_position = at + vent * 0.4
	var tw := light.create_tween().set_parallel()
	tw.tween_property(light, "light_energy", 0.0, tn.flash_s)
	tw.tween_property(light, "light_color", tn.flash_cool, tn.flash_s * 0.6)
	tw.chain().tween_callback(light.queue_free)
	flash_sprites(world, at + vent * 0.1, vent, size, seed_value + 1)


## The flash's glows: unlit, white at their birth, orange by half their life, gone at `flash_s`
## (drawn over what's behind, not added to it: added, they were lost on the sunlit street). Their clock is the frame's (not the particles' 30 a second: three steps would be all).
static func flash_sprites(world: Node3D, at: Vector3, vent: Vector3, size: float, seed_value: int) -> GPUParticles3D:
	var tn := Blast.t()
	var p := _particles(world, tn.flash_sprites, tn.flash_s, seed_value)
	p.name = "BlastFlashGlow"
	p.fixed_fps = 0
	p.interpolate = false
	p.randomness = 0.3
	p.layers = Layers.VIS_AIR
	var pm := _pm(&"flash")
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.15 * size
	pm.direction = vent
	pm.spread = 70.0
	pm.initial_velocity_min = 0.3 * tn.flash_sprite_speed * sqrt(size)
	pm.initial_velocity_max = tn.flash_sprite_speed * sqrt(size)
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	pm.scale_curve = _curve([Vector2(0.0, 0.7), Vector2(0.4, 1.0), Vector2(1.0, 1.3)])
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	var hot := tn.flash_hot
	var mid := tn.flash_cool
	mid.a = 0.9
	var out := tn.flash_cool.darkened(0.2)
	out.a = 0.0
	pm.color_ramp = _ramp([[0.0, hot], [0.5, mid], [1.0, out]])
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * tn.flash_sprite_m * size
	quad.material = _glow()
	p.draw_pass_1 = quad
	p.global_position = at
	p.emitting = true
	return p


## The ring (#596 step 3): dust kicked out flat along the ground all round the charge, fast, stopping
## within a few metres (its speed and reach set the drag) and then hanging and fading. Only with
## ground or a floor under the charge, weaker as the charge is higher over it.
static func _ring(world: Node3D, at: Vector3, dust: Color, size: float, seed_value: int) -> GPUParticles3D:
	var tn := Blast.t()
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.2, at + Vector3.DOWN * (tn.ring_height + 0.2), Layers.WORLD)
	var hit := World.space(world).intersect_ray(q)
	if hit.is_empty():
		return null
	var k := clampf(1.0 - maxf(at.y - hit.position.y, 0.0) / tn.ring_height, 0.0, 1.0)
	if k < 0.05:
		return null
	return ring_at(world, hit.position, dust, size, k, seed_value + 6, room_reach(world, hit.position, tn.ring_reach * size))


## How far the ring may run before walls take most of it (m, at most `reach`): eight rays out along
## the floor, the third nearest wall (the puffs don't collide: in the saloon they ran on out through
## its walls and were seen outside). One wall beside it, it still runs out the other ways.
static func room_reach(world: Node3D, ground: Vector3, reach: float) -> float:
	var space := World.space(world)
	var from := ground + Vector3.UP * 0.3
	var d: Array[float] = []
	for i in 8:
		var dir := Vector3.RIGHT.rotated(Vector3.UP, TAU * i / 8.0)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + dir * reach, Layers.WORLD))
		d.append(reach if hit.is_empty() else from.distance_to(hit.position))
	d.sort()
	return d[2] * 0.9 if d[2] < reach else reach


## The ring's puffs on the ground at `ground`, `k` its strength (1 on the ground under the charge).
static func ring_at(world: Node3D, ground: Vector3, dust: Color, size: float, k: float, seed_value: int, max_reach := INF) -> GPUParticles3D:
	var tn := Blast.t()
	var p := _particles(world, int(tn.ring_puffs * size * (0.5 + 0.5 * k)), tn.ring_s, seed_value)
	p.name = "BlastRing"
	p.randomness = 0.4
	p.layers = Layers.VIS_AIR
	var pm := _pm(&"ring")
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.35 * size
	pm.emission_ring_inner_radius = 0.2 * size
	pm.emission_ring_height = 0.05
	pm.direction = Vector3.RIGHT
	pm.spread = 180.0
	pm.flatness = 1.0
	var speed := tn.ring_speed * sqrt(size) * (0.6 + 0.4 * k)
	var reach := maxf(minf(tn.ring_reach * size * (0.5 + 0.5 * k), max_reach), 0.3)
	speed = minf(speed, tn.ring_speed * reach / tn.ring_reach)  # a short run is a slower one, not a harder stop
	pm.initial_velocity_min = speed * 0.85
	pm.initial_velocity_max = speed * 1.15
	# Damping takes speed off at a steady rate: stopped at `reach` (the middle speed's), in a blink.
	var drag := speed * speed / (2.0 * reach)
	pm.damping_min = drag * 0.9
	pm.damping_max = drag * 1.1
	pm.gravity = Vector3(0, 0.15, 0)
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	pm.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.1, 1.0), Vector2(1.0, 2.4)])
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -20.0
	pm.angular_velocity_max = 20.0
	var low := Color(dust.r * 0.8, dust.g * 0.8, dust.b * 0.8, 0.9)
	var mid := Color(dust.r * 0.95, dust.g * 0.95, dust.b * 0.95, 0.7)
	var pale := dust.lerp(Color(0.92, 0.9, 0.86), 0.4)
	pale.a = 0.0
	pm.color_ramp = _ramp([[0.0, low], [0.35, mid], [1.0, pale]])
	p.process_material = pm
	p.draw_pass_1 = _quad(tn.ring_puff_m * size)
	p.global_position = ground + Vector3.UP * tn.ring_puff_m * size * 0.3
	p.emitting = true
	return p


## The loose dirt (#596 step 3): bits of the ground (splinters, on boards) thrown up out of the vent,
## streaks along their flight, falling back; kept under a ceiling by `cap` (m/s).
static func _spray(world: Node3D, at: Vector3, vent: Vector3, dust: Color, size: float, seed_value: int, cap: float) -> GPUParticles3D:
	var tn := Blast.t()
	var p := _particles(world, int(tn.spray_bits * size), tn.spray_s, seed_value + 7)
	p.name = "BlastDirt"
	p.randomness = 0.5
	var pm := _pm(&"spray")
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.12 * size
	pm.direction = vent
	pm.spread = tn.spray_spread
	var vmax := minf(tn.spray_speed_max * sqrt(size), cap)
	pm.initial_velocity_max = vmax
	pm.initial_velocity_min = minf(tn.spray_speed_min * sqrt(size), vmax * 0.4)
	pm.gravity = Vector3(0, -9.8, 0)
	pm.damping_min = 0.3
	pm.damping_max = 1.2
	pm.particle_flag_align_y = true
	pm.scale_min = 0.5
	pm.scale_max = 1.4
	pm.color_initial_ramp = _ramp([[0.0, Color(dust.r * 0.32, dust.g * 0.3, dust.b * 0.28)],
			[1.0, Color(dust.r * 0.72, dust.g * 0.7, dust.b * 0.66)]])
	p.process_material = pm
	var box := BoxMesh.new()
	box.size = Vector3(0.03, tn.spray_bit_m, 0.03)
	box.material = _chunk()
	p.draw_pass_1 = box
	p.global_position = at
	p.emitting = true
	return p


## The fastest (m/s) anything thrown up out of the vent may go and still turn under the ceiling over
## the charge (a room's: the dirt went up through the saloon's ceiling and came back down through it);
## no limit in the open.
static func speed_cap(world: Node3D, at: Vector3, vent: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.05, at + Vector3.UP * 12.0, Layers.WORLD)
	var hit := World.space(world).intersect_ray(q)
	if hit.is_empty():
		return INF
	var room := maxf(hit.position.y - at.y - 0.3, 0.4)
	return sqrt(2.0 * 9.8 * room) / maxf(vent.y, 0.35)


## Dark lumps of what it blew apart (clods of dirt, splinters of board), flung out in arcs.
static func _chunks(world: Node3D, at: Vector3, vent: Vector3, dust: Color, size: float, seed_value: int, cap := INF) -> void:
	var p := _particles(world, int(46 * size), 1.8, seed_value + 2)
	p.randomness = 0.6
	var pm := _pm(&"chunks")
	pm.direction = vent
	pm.spread = 55.0
	pm.initial_velocity_max = minf(15.0 * sqrt(size), cap)
	pm.initial_velocity_min = minf(5.0 * sqrt(size), pm.initial_velocity_max * 0.4)
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
	p.emitting = false  # (made emitting: set again when placed, `finished` never came, #459)
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
	var jet := _dust(&"jet", int(40 * size), 7.0, seed_value + 3)
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
	var billow := _dust(&"billow", int(44 * size), LIFETIME * 0.8, seed_value + 4)
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
	var surge := _dust(&"surge", int(30 * size), LIFETIME * 0.6, seed_value + 5)
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
func _dust(kind: StringName, amount: int, lifetime: float, seed_value: int) -> GPUParticles3D:
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
	# The scorch decal (0.3 m up) painted a dark band across the cloud's foot.
	p.layers = Layers.VIS_AIR
	var pm := _pm(kind)
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


static func _quad(side: float) -> QuadMesh:
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


## The flash's glow: unshaded, the colour the particle carries.
static func _glow() -> StandardMaterial3D:
	if _glow_material == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = PixelArt.puff("flash", 103)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.no_depth_test = false
		_glow_material = m
	return _glow_material


static func _chunk() -> StandardMaterial3D:
	if _chunk_material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		_chunk_material = m
	return _chunk_material


## The curves and ramps made once and shared (they never change once made): a material given new
## ones built them on the spot, ~2 ms each, on the blast's own tick (#596 step 3).
static var _textures := {}


static func _curve(points: Array) -> CurveTexture:
	var key := var_to_str(points)
	if _textures.has(key):
		return _textures[key]
	var c := Curve.new()
	c.max_value = 4.0
	for pt: Vector2 in points:
		c.add_point(pt)
	var tex := CurveTexture.new()
	tex.curve = c
	_textures[key] = tex
	return tex


static func _ramp(stops: Array) -> GradientTexture1D:
	var key := var_to_str(stops)
	if _textures.has(key):
		return _textures[key]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s: Array) -> float: return s[0]))
	g.colors = PackedColorArray(stops.map(func(s: Array) -> Color: return s[1]))
	var tex := GradientTexture1D.new()
	tex.gradient = g
	_textures[key] = tex
	return tex


static var _warmed := false
## Each kind of particle's materials, a few made once and taken in turn (`_pm`).
const POOL := 2
static var _pools := {}
static var _next := {}


## A particle material for `kind` (its caller sets every field it uses, every time): one of `POOL`
## made once and taken in turn. A new one cost ~4 ms when it was first given to its particles, every
## material every blast (the dust's three were #538's 5-8 ms on the tick after); a pool of two, so
## two blasts drawn in one frame (a bundle volley, two ticks a frame) aren't given one's settings.
static func _pm(kind: StringName) -> ParticleProcessMaterial:
	if not _pools.has(kind):
		_pools[kind] = []
		_next[kind] = 0
	var pool: Array = _pools[kind]
	var i: int = _next[kind]
	_next[kind] = (i + 1) % POOL
	if i >= pool.size():
		pool.append(ParticleProcessMaterial.new())
	return pool[i]


## The first stick in the world warms the first instant's materials and particle shaders where it
## lies (a speck each, gone in 0.3 s), if the drawn game's load hasn't already (the revolver's
## warm-up; headless runs don't): made on a blast's tick they were ~4 ms of it (#596 step 3).
static func ready_once(near: Node3D) -> void:
	if _warmed or not is_instance_valid(near) or not near.is_inside_tree():
		return
	var parent := near.get_parent() as Node3D
	if parent == null:
		return
	var tree := near.get_tree()
	for n in warm_up(parent, near.global_position + Vector3.DOWN * 50.0):
		tree.create_timer(0.3).timeout.connect(n.queue_free)


## Draw it once, out of sight, so its materials are compiled at load rather than on the first blast
## (the first instant's particles too, a speck each, so their process shaders are made).
static func warm_up(parent: Node3D, at: Vector3) -> Array[Node]:
	_warmed = true
	var out: Array[Node] = []
	var dust := Color(0.56, 0.45, 0.34)
	for i in POOL:  # every material of every pool, set as a blast sets it
		out.append(flash_sprites(parent, at, Vector3.UP, 0.001, 0))
		out.append(ring_at(parent, at, dust, 0.001, 1.0, 0))
		out.append(_spray(parent, at, Vector3.UP, dust, 0.001, 0, INF))
		_chunks(parent, at, Vector3.UP, dust, 0.001, 0)  # (frees itself)
		var c := BlastCloud.new()
		parent.add_child(c)
		c.global_position = at
		c._start(Vector3.UP, dust, 0.001, 0, false)
		out.append(c)
	for mat: Material in [_chunk(), _dust_mat(), _glow()]:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.001
		box.material = mat
		mi.mesh = box
		parent.add_child(mi)
		mi.global_position = at
		out.append(mi)
	return out
