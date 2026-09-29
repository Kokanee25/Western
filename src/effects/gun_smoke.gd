class_name GunSmoke
extends Node3D
## A black-powder cloud: a grey-white burst out of the muzzle that slows almost at once, then billows,
## grows, rises and drifts off on the breeze (hardly at all indoors), thinning as it goes. Two layers:
## chunky lit particles (every renderer, so lamps light them) and, for the newest few clouds, a
## volumetric fog volume that fills the air and takes the light shafts. The particles ride this node
## (local coordinates), so the whole cloud drifts together.

static var tuning: SmokeTuning
static var _clouds: Array[Node] = []
static var _material: StandardMaterial3D

var _fog: FogVolume
var _fog_mat: FogMaterial
var _age := 0.0
var _drift := Vector3.ZERO


## `amount`: how much powder burnt, relative to a .45 Colt load (a 12-bore shell makes nearly twice
## the cloud).
static func spawn(parent: Node, at: Vector3, direction: Vector3, amount := 1.0) -> GunSmoke:
	_load_tuning()
	var alive: Array[Node] = []
	for c in _clouds:
		if is_instance_valid(c):
			alive.append(c)
	_clouds = alive
	while _clouds.size() >= tuning.max_clouds:
		_clouds.pop_front().queue_free()
	# Only the newest clouds keep a fog volume.
	var with_fog := 0
	for i in range(_clouds.size() - 1, -1, -1):
		var c := _clouds[i] as GunSmoke
		if c._fog:
			with_fog += 1
			if with_fog >= tuning.max_fog_volumes:
				c._fog.queue_free()
				c._fog = null
	var s := GunSmoke.new()
	parent.add_child(s)
	s.global_position = at
	s._start(direction, _is_indoors(s, at), amount)
	_clouds.append(s)
	return s


## The web build's renderer (Compatibility) has no volumetric fog; the particles do the work there.
static func supports_fog_volumes() -> bool:
	return RenderingServer.get_current_rendering_method() != "gl_compatibility"


static func _load_tuning() -> void:
	if tuning == null:
		tuning = load("res://config/smoke.tres")


## A roof overhead within a few metres means indoors: no breeze.
static func _is_indoors(node: Node3D, at: Vector3) -> bool:
	var space := node.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + Vector3.UP * 6.0, Layers.WORLD))
	return not hit.is_empty()


func _start(direction: Vector3, indoors: bool, amount := 1.0) -> void:
	var wind := tuning.wind * (tuning.indoor_wind if indoors else 1.0)
	_drift = wind + Vector3.UP * tuning.rise
	var p := GPUParticles3D.new()
	p.name = "Puffs"
	p.one_shot = true
	p.amount = maxi(1, int(tuning.puffs * amount))
	p.lifetime = tuning.lifetime * 0.85
	p.explosiveness = 0.92
	p.randomness = 0.5
	p.local_coords = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-8, -3, -8), Vector3(16, 10, 16))
	var pm := ParticleProcessMaterial.new()
	pm.direction = direction.normalized()
	pm.spread = 18.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 6.0
	pm.damping_min = 4.0
	pm.damping_max = 7.0
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = tuning.turbulence > 0.0
	pm.turbulence_noise_strength = 1.0
	pm.turbulence_noise_scale = 3.0
	pm.turbulence_noise_speed = Vector3(0.1, 0.2, 0.1)
	pm.turbulence_influence_min = tuning.turbulence * 0.05
	pm.turbulence_influence_max = tuning.turbulence * 0.15
	pm.scale_min = 0.8
	pm.scale_max = 1.5
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.25))
	grow.add_point(Vector2(0.12, 0.9))
	grow.add_point(Vector2(1.0, 2.6))
	var grow_tex := CurveTexture.new()
	grow_tex.curve = grow
	pm.scale_curve = grow_tex
	var fade := Gradient.new()
	fade.set_color(0, Color(0.9, 0.88, 0.84, 0.7))
	fade.set_color(1, Color(0.8, 0.8, 0.8, 0.0))
	fade.add_point(0.3, Color(0.86, 0.85, 0.82, 0.4))
	var fade_tex := GradientTexture1D.new()
	fade_tex.gradient = fade
	pm.color_ramp = fade_tex
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -12.0
	pm.angular_velocity_max = 12.0
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.45, 0.45) * sqrt(amount)
	quad.material = _puff_material()
	p.draw_pass_1 = quad
	add_child(p)
	p.emitting = true

	if not supports_fog_volumes():
		return
	_fog = FogVolume.new()
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_fog.size = Vector3(0.8, 0.6, 0.8) * sqrt(amount)
	_fog_mat = FogMaterial.new()
	_fog_mat.density = tuning.fog_density
	_fog_mat.albedo = Color(0.85, 0.84, 0.82)
	_fog.material = _fog_mat
	add_child(_fog)
	_fog.position = direction.normalized() * 0.9


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / tuning.lifetime, 0.0, 1.0)
	# The breeze takes a moment to get hold of the cloud, then carries it off.
	global_position += _drift * delta * smoothstep(0.0, 0.2, t)
	if _fog:
		var s := lerpf(0.8, 3.5, sqrt(t))
		_fog.size = Vector3(s, s * 0.7, s)
		_fog_mat.density = tuning.fog_density * pow(1.0 - t, 2.0)
	if _age > tuning.lifetime:
		queue_free()


## Draw every effect once, out of sight, so their shaders are compiled at load rather than on the
## first shot (a first-shot hitch otherwise).
static func warm_up(parent: Node3D, camera: Camera3D) -> void:
	_load_tuning()
	var at := camera.global_position - camera.global_transform.basis.z * 3.0
	var s := GunSmoke.new()
	parent.add_child(s)
	s.global_position = at
	s._start(Vector3.FORWARD, false)
	if s._fog_mat:
		s._fog_mat.density = 0.0
	s.scale = Vector3.ONE * 0.001
	ImpactEffects.burst(parent, at, Vector3.UP, Color(0.6, 0.5, 0.4), 1, 0.0, 0.001)
	var flash := ImpactEffects.flash_mesh()
	flash.scale = Vector3.ONE * 0.001
	parent.add_child(flash)
	flash.global_position = at
	# A speck of drilled timber, so the bullet-hole shader is ready too.
	var hole := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.001
	hole.mesh = box
	var hm := ShaderMaterial.new()
	hm.shader = StructureMember.HOLE_SHADER
	hole.material_override = hm
	parent.add_child(hole)
	hole.global_position = at
	var tree := parent.get_tree()
	for n in [s, flash, hole]:
		tree.create_timer(0.3).timeout.connect(n.queue_free)


static func _puff_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_texture = PixelArt.puff("smoke", 101)
		_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_material.vertex_color_use_as_albedo = true
		_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_material.roughness = 1.0
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return _material
