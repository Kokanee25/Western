class_name GunSmoke
extends Node3D
## A black-powder cloud: a big grey-white burst out of the muzzle that slows almost at once, grows,
## drifts up and hangs for many seconds. Two layers: chunky lit particles (every renderer, so lamps
## light them) and a volumetric fog volume that fills the air and takes the light shafts.
## Old clouds are freed when too many are hanging about.

const MAX_CLOUDS := 14
const LIFETIME := 16.0

static var _clouds: Array[Node] = []
static var _material: StandardMaterial3D

var _fog: FogVolume
var _fog_mat: FogMaterial
var _age := 0.0


static func spawn(parent: Node, at: Vector3, direction: Vector3) -> GunSmoke:
	var alive: Array[Node] = []
	for c in _clouds:
		if is_instance_valid(c):
			alive.append(c)
	_clouds = alive
	while _clouds.size() >= MAX_CLOUDS:
		_clouds.pop_front().queue_free()
	var s := GunSmoke.new()
	parent.add_child(s)
	s.global_position = at
	s._start(direction)
	_clouds.append(s)
	return s


func _start(direction: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.name = "Puffs"
	p.one_shot = true
	p.amount = 42
	p.lifetime = LIFETIME * 0.8
	p.explosiveness = 0.92
	p.randomness = 0.5
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-6, -3, -6), Vector3(12, 8, 12))
	var pm := ParticleProcessMaterial.new()
	pm.direction = direction.normalized()
	pm.spread = 16.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 7.0
	pm.damping_min = 5.0
	pm.damping_max = 9.0
	pm.gravity = Vector3(0.05, 0.1, 0.0)
	pm.scale_min = 0.8
	pm.scale_max = 1.6
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.25))
	grow.add_point(Vector2(0.15, 0.9))
	grow.add_point(Vector2(1.0, 2.4))
	var grow_tex := CurveTexture.new()
	grow_tex.curve = grow
	pm.scale_curve = grow_tex
	var fade := Gradient.new()
	fade.set_color(0, Color(0.9, 0.88, 0.84, 0.75))
	fade.set_color(1, Color(0.8, 0.8, 0.8, 0.0))
	fade.add_point(0.35, Color(0.86, 0.85, 0.82, 0.45))
	var fade_tex := GradientTexture1D.new()
	fade_tex.gradient = fade
	pm.color_ramp = fade_tex
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.45, 0.45)
	quad.material = _puff_material()
	p.draw_pass_1 = quad
	add_child(p)
	p.emitting = true

	_fog = FogVolume.new()
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_fog.size = Vector3(0.8, 0.6, 0.8)
	_fog_mat = FogMaterial.new()
	_fog_mat.density = 1.2
	_fog_mat.albedo = Color(0.85, 0.84, 0.82)
	_fog.material = _fog_mat
	add_child(_fog)
	_fog.position = direction.normalized() * 0.9


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / LIFETIME, 0.0, 1.0)
	if _fog:
		var s := lerpf(0.8, 4.0, sqrt(t))
		_fog.size = Vector3(s, s * 0.7, s)
		_fog.position.y += delta * 0.08
		_fog_mat.density = lerpf(1.2, 0.0, t) * lerpf(1.0, 0.25, sqrt(t))
	if _age > LIFETIME:
		queue_free()


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
