class_name GunSmoke
extends Node3D
## A black-powder cloud. The shot throws a short jet of puffs out of the muzzle (and a wisp out of a
## revolver's cylinder gap); the air stops them within a metre or two, the warm gas rises, the
## breeze takes it (hardly at all indoors), and each puff spreads and thins as it goes.
##
## Each puff is a fixed amount of smoke, so its density through the middle falls with the square of
## its radius: dense for the first instant at the muzzle, then translucent (Sean, 2026-10-18: "I
## want to be able to actually see the bad guy react to being shot"). The puffs are simulated
## here, not on the graphics card, so `transmittance()` can say how much of a man shows through the
## smoke (tests/test_gun_feel.gd; people's eyes can use it too). Drawn as one MultiMesh of lit
## billboards; under a roof the newest few clouds also leave a volumetric haze that fills the room.
## The puffs ride this node (local coordinates) and the node drifts on the breeze.

static var tuning: SmokeTuning
static var _clouds: Array[Node] = []
static var _material: StandardMaterial3D
## At most this many puffs in one cloud (dynamite's is a big `amount`).
const MAX_PUFFS := 40

var indoors := false
var _fog: FogVolume
var _fog_mat: FogMaterial
var _age := 0.0
var _life := 14.0
var _drift := Vector3.ZERO
var _thin := 1.4
var _rng := RandomNumberGenerator.new()
var _mm: MultiMesh
## Per puff, in this node's space: where, how fast, its radius, its smoke (m²), when it left.
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _rad := PackedFloat32Array()
var _mass := PackedFloat32Array()
var _born := PackedFloat32Array()
var _wander := PackedVector3Array()
var _fog_mass := 0.0


## `amount`: how much powder burnt, relative to a .45 Colt load (a 12-bore shell makes nearly twice
## the cloud). `gap`: a revolver's sideways axis, for the wisp out of each side of the cylinder gap.
static func spawn(parent: Node, at: Vector3, direction: Vector3, amount := 1.0, gap := Vector3.ZERO) -> GunSmoke:
	_load_tuning()
	var alive: Array[Node] = []
	for c in _clouds:
		if is_instance_valid(c):
			alive.append(c)
	_clouds = alive
	while _clouds.size() >= tuning.max_clouds:
		_clouds.pop_front().queue_free()
	var s := GunSmoke.new()
	parent.add_child(s)
	s.global_position = at
	s._start(direction, _is_indoors(s, at), amount, gap)
	# Only the newest clouds keep a fog volume.
	_clouds.append(s)
	var with_fog := 0
	for i in range(_clouds.size() - 1, -1, -1):
		var c := _clouds[i] as GunSmoke
		if c._fog:
			with_fog += 1
			if with_fog > tuning.max_fog_volumes:
				c._fog.queue_free()
				c._fog = null
	return s


## The web build's renderer (Compatibility) has no volumetric fog; the puffs do the work there.
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


## How much light gets through every cloud between `from` and `to` (1 = clear, 0 = nothing).
static func transmittance(from: Vector3, to: Vector3) -> float:
	var depth := 0.0
	for c in _clouds:
		if is_instance_valid(c) and c.is_inside_tree():
			depth += (c as GunSmoke).optical_depth(from, to)
	return exp(-depth)


## The smoke's optical depth along the segment from `from` to `to`. Each puff is a Gaussian ball of
## smoke: through it at `b` from its middle the depth is mass / r² * e^(-b²/r²).
func optical_depth(from: Vector3, to: Vector3) -> float:
	var inv := global_transform.affine_inverse()
	var a := inv * from
	var b := inv * to
	var seg := b - a
	var length := seg.length()
	if length < 1e-4:
		return 0.0
	var dir := seg / length
	var depth := 0.0
	for i in _pos.size():
		var r := _rad[i]
		var along := (_pos[i] - a).dot(dir)
		# Only the part of the puff between the two ends (a soft edge a radius either side).
		if along < -r or along > length + r:
			continue
		var off := (_pos[i] - (a + dir * clampf(along, 0.0, length))).length_squared()
		depth += _mass[i] / (r * r) * exp(-off / (r * r))
	if _fog and _fog_mat:
		depth += _fog_depth(a, dir, length)
	return depth


## Through the room's haze: its density times the chord the segment cuts through the ellipsoid.
func _fog_depth(a: Vector3, dir: Vector3, length: float) -> float:
	var half := _fog.size * 0.5
	var o := (a - _fog.position) / half
	var d := dir / half
	var qa := d.dot(d)
	var qb := 2.0 * o.dot(d)
	var qc := o.dot(o) - 1.0
	var disc := qb * qb - 4.0 * qa * qc
	if disc <= 0.0:
		return 0.0
	var s := sqrt(disc)
	var t0 := clampf((-qb - s) / (2.0 * qa), 0.0, length)
	var t1 := clampf((-qb + s) / (2.0 * qa), 0.0, length)
	return _fog_mat.density * (t1 - t0)


func _start(direction: Vector3, under_roof: bool, amount := 1.0, gap := Vector3.ZERO) -> void:
	indoors = under_roof
	var wind := tuning.wind * (tuning.indoor_wind if indoors else 1.0)
	_drift = wind + Vector3.UP * tuning.rise
	_life = tuning.lifetime if indoors else tuning.outdoor_lifetime
	_thin = tuning.thin_indoors if indoors else tuning.thin_outdoors
	# Seeded by where and which way the shot went, to the centimetre: in play no two clouds match,
	# and the same shot (the screenshot tool's fixed views) makes the same smoke.
	_rng.seed = hash([Vector3i((global_position * 100.0).round()), Vector3i((direction * 1000.0).round())]) & 0x7fffffff
	var dir := direction.normalized()
	var side := dir.cross(Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT).normalized()
	var up := side.cross(dir)
	var n := clampi(int(round(tuning.jet_puffs * amount)), 1, MAX_PUFFS)
	for i in n:
		# Out along the bore, opening a little: the slow ones stop near the muzzle, the fast ones
		# carry a metre or two.
		var spread := _rng.randf_range(0.0, 0.18)
		var turn := _rng.randf() * TAU
		var v := (dir + (side * cos(turn) + up * sin(turn)) * spread).normalized()
		var speed := lerpf(tuning.jet_speed.x, tuning.jet_speed.y, pow(float(i) / maxf(n - 1, 1), 0.8)) * _rng.randf_range(0.85, 1.15)
		_add(v * speed * sqrt(amount), tuning.puff_mass * sqrt(amount) * _rng.randf_range(0.8, 1.2))
	if gap != Vector3.ZERO:
		var g := gap.normalized()
		for s in [-1.0, 1.0]:
			_add(g * s * _rng.randf_range(1.5, 2.5) - dir * 0.5, tuning.puff_mass * tuning.gap_share, -dir * 0.2)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_mm.mesh = quad
	_mm.instance_count = _pos.size()
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Puffs"
	mmi.multimesh = _mm
	mmi.material_override = _puff_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-8, -3, -8), Vector3(16, 10, 16))
	add_child(mmi)
	_draw()

	# The room's haze: indoors only (out of doors the breeze takes it), the newest few clouds.
	if not indoors or not supports_fog_volumes():
		return
	_fog_mass = tuning.fog_density * sqrt(amount)
	_fog = FogVolume.new()
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	_fog.size = Vector3(0.8, 0.6, 0.8) * sqrt(amount)
	_fog_mat = FogMaterial.new()
	_fog_mat.density = 0.0
	_fog_mat.albedo = tuning.colour
	_fog.material = _fog_mat
	add_child(_fog)
	_fog.position = dir * 1.2


func _add(v: Vector3, mass: float, at := Vector3.ZERO) -> void:
	_pos.append(at)
	_vel.append(v)
	_rad.append(tuning.start_radius)
	_mass.append(mass)
	_born.append(0.0)
	_wander.append(Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.3, 1), _rng.randf_range(-1, 1)) * tuning.turbulence)


func _process(delta: float) -> void:
	var t := Prof.start()
	_process_step(delta)
	Prof.stop(&"smoke", t)


func _process_step(delta: float) -> void:
	_age += delta
	var t := clampf(_age / _life, 0.0, 1.0)
	# The breeze takes a moment to get hold of the cloud, then carries it off.
	global_position += _drift * delta * smoothstep(0.0, 0.2, _age / 14.0)
	var drag := exp(-tuning.jet_drag * delta)
	var lift := tuning.buoyancy * exp(-_age) * delta
	var thin := exp(-delta / maxf(_thin, 0.01))
	var reach := tuning.spread_radius
	for i in _pos.size():
		_vel[i] = _vel[i] * drag + Vector3.UP * lift
		_pos[i] += (_vel[i] + _wander[i] * minf(_age * 2.0, 1.0)) * delta
		var spread := tuning.start_radius + (reach - tuning.start_radius) * (1.0 - exp(-_age / maxf(tuning.spread_time, 0.01)))
		_rad[i] = spread + tuning.growth * _age
		_mass[i] *= thin
	if _fog:
		var s := lerpf(0.8, 3.5, sqrt(t))
		_fog.size = Vector3(s, s * 0.7, s)
		# The haze is what the puffs have shed, spread through the volume it fills.
		var shed := 1.0 - exp(-_age / maxf(_thin, 0.01))
		_fog_mat.density = _fog_mass * shed * pow(1.0 - t, 2.0) / maxf(s * s * 0.7, 0.5)
	_draw()
	if _age > _life:
		queue_free()


## Each puff a billboard three radii across (the texture's soft edge is about there), as opaque
## through its middle as its smoke makes it, fading out over the cloud's last fifth.
func _draw() -> void:
	if _mm == null:
		return
	var end := clampf((_life - _age) / (_life * 0.2), 0.0, 1.0)
	for i in _pos.size():
		var r := _rad[i]
		var alpha := (1.0 - exp(-_mass[i] / (r * r))) * end
		_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * r * 3.0), _pos[i]))
		_mm.set_instance_color(i, Color(tuning.colour, alpha))


## The opacity looking straight through the cloud's densest puff (tests).
func densest() -> float:
	var most := 0.0
	for i in _pos.size():
		most = maxf(most, 1.0 - exp(-_mass[i] / (_rad[i] * _rad[i])))
	return most


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
		_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_material.billboard_keep_scale = true
		_material.roughness = 1.0
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return _material
