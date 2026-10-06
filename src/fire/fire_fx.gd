class_name FireFX
extends Node
## How one member looks in a fire: scorch and char creeping over it (char_overlay.gdshader, which
## stays after the fire's out), and while it burns, flames licking up off it and smoke rising.
## The flames ride on the member's own meshes, so they go with it when it falls.

const OVERLAY := preload("res://src/fire/char_overlay.gdshader")

var member: StructureMember

var _overlay: ShaderMaterial
var _emitters: Array[GPUParticles3D] = []

const FLAME := preload("res://src/fire/flame.gdshader")

static var _flame_mat: ShaderMaterial
static var _smoke_mat: StandardMaterial3D


## `smoke` false: a SmokeField draws this member's smoke (FireSystem.smoked), so no particles.
func refresh(flames: bool, tuning: FireTuning, smoke := true) -> void:
	if member == null or not is_instance_valid(member):
		queue_free()
		return
	if _overlay == null:
		_overlay = ShaderMaterial.new()
		_overlay.shader = OVERLAY
		_overlay.set_shader_parameter(&"texels_per_meter", PixelArt.texels_per_meter)
	var half := maxf(minf(member.size.x, minf(member.size.y, member.size.z)) * 0.5, 0.001)
	var scorch := clampf((member.temperature - 120.0) / 400.0, 0.0, 0.25)
	_overlay.set_shader_parameter(&"char_amount", clampf(maxf(member.char_depth / half, scorch), 0.0, 1.0))
	_overlay.set_shader_parameter(&"glow", clampf(member.burn_time / tuning.growth_seconds, 0.2, 1.0) if member.burning else 0.0)
	var meshes: Array[MeshInstance3D] = []
	for p: Array in member.pieces:
		if not is_instance_valid(p[0]):
			continue
		var mi := p[0] as MeshInstance3D
		if mi:
			meshes.append(mi)
			if mi.material_overlay != _overlay:
				mi.material_overlay = _overlay
	if flames and _emitters.is_empty():
		for mi in meshes:
			_emitters.append(_flames_on(mi))
			if smoke:
				_emitters.append(_smoke_on(mi))
	elif not flames and not _emitters.is_empty():
		_clear()


func _exit_tree() -> void:
	_clear()


func _clear() -> void:
	for e in _emitters:
		if is_instance_valid(e):
			e.emitting = false
			e.get_tree().create_timer(e.lifetime + 0.5).timeout.connect(e.queue_free) if e.is_inside_tree() else e.queue_free()
	_emitters.clear()


func _flames_on(mi: MeshInstance3D) -> GPUParticles3D:
	var box := mi.get_aabb()
	var area := box.size.x * box.size.y + box.size.y * box.size.z + box.size.x * box.size.z
	var p := _particles(clampi(int(area * 10.0), 4, 24), 0.9, _flame_material(), 0.42)
	(p.draw_pass_1 as QuadMesh).size = Vector2(0.36, 0.6)
	var pm := p.process_material as ParticleProcessMaterial
	# Off the surface, not inside the wood: a shell a hand's breadth round it, weighted to its top.
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box.size * 0.5 + Vector3(0.07, 0.05, 0.07)
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0, 1.4, 0)
	pm.scale_min = 0.7
	pm.scale_max = 1.5
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 0.6))
	shrink.add_point(Vector2(0.25, 1.0))
	shrink.add_point(Vector2(1.0, 0.2))
	var st := CurveTexture.new()
	st.curve = shrink
	pm.scale_curve = st
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.78, 0.35, 0.95))
	ramp.add_point(0.3, Color(1.0, 0.62, 0.16, 0.9))
	ramp.add_point(0.65, Color(0.9, 0.28, 0.05, 0.6))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.3, 0.06, 0.02, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	pm.color_ramp = tex
	mi.add_child(p)
	p.position = box.get_center() + Vector3.UP * box.size.y * 0.15
	return p


func _smoke_on(mi: MeshInstance3D) -> GPUParticles3D:
	var box := mi.get_aabb()
	var p := _particles(clampi(int(box.size.length() * 3.0), 3, 10), 5.0, _smoke_material(), 1.1)
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box.size * 0.5
	pm.direction = Vector3.UP
	pm.spread = 18.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.5
	pm.gravity = Vector3(0.25, 0.6, 0.0)
	pm.scale_min = 0.8
	pm.scale_max = 2.2
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.1, 0.09, 0.08, 0.0))
	ramp.add_point(0.12, Color(0.12, 0.1, 0.09, 0.7))
	ramp.add_point(0.6, Color(0.2, 0.19, 0.18, 0.45))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.28, 0.27, 0.26, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	pm.color_ramp = tex
	mi.add_child(p)
	p.position = box.get_center() + Vector3.UP * 0.2
	return p


static func _particles(amount: int, lifetime: float, mat: Material, size: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 10, 8))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.process_material = ParticleProcessMaterial.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	quad.material = mat
	p.draw_pass_1 = quad
	return p


static func _flame_material() -> ShaderMaterial:
	if _flame_mat == null:
		_flame_mat = ShaderMaterial.new()
		_flame_mat.shader = FLAME
		_flame_mat.set_shader_parameter(&"sprite", PixelArt.puff("flame", 61))
	return _flame_mat


static func _smoke_material() -> StandardMaterial3D:
	if _smoke_mat == null:
		_smoke_mat = StandardMaterial3D.new()
		_smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_smoke_mat.vertex_color_use_as_albedo = true
		_smoke_mat.albedo_texture = PixelArt.puff("fire_smoke", 67)
		_smoke_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		# Lit: dark against the night sky, glowing orange underneath from the fire.
	return _smoke_mat


## Water on fire: a burst of white steam rising off it, and a hiss. `members` how many it put out.
static func steam(parent: Node, at: Vector3, members: int) -> void:
	var p := _particles(clampi(10 + members * 6, 10, 60), 1.6, _steam_material(), 0.35)
	p.one_shot = true
	p.explosiveness = 0.85
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.35
	pm.direction = Vector3.UP
	pm.spread = 35.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(0, 0.8, 0)
	pm.damping_min = 0.6
	pm.damping_max = 1.2
	pm.scale_min = 0.8
	pm.scale_max = 2.2
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.92, 0.92, 0.9, 0.75))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.8, 0.8, 0.8, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	pm.color_ramp = tex
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	p.finished.connect(p.queue_free)
	var hiss := AudioStreamPlayer3D.new()
	hiss.stream = SynthSounds.get_sound(&"steam")
	hiss.unit_size = 4.0
	hiss.volume_db = linear_to_db(clampf(0.4 + members * 0.1, 0.4, 1.2))
	p.add_child(hiss)
	hiss.play()


static var _steam_mat: StandardMaterial3D


static func _steam_material() -> StandardMaterial3D:
	if _steam_mat == null:
		_steam_mat = StandardMaterial3D.new()
		_steam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_steam_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_steam_mat.vertex_color_use_as_albedo = true
		_steam_mat.albedo_texture = PixelArt.puff("steam", 71)
		_steam_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return _steam_mat


## Burning oil on the floor where a lamp smashed.
static func spill_flames(parent: Node, at: Vector3, radius: float) -> GPUParticles3D:
	var p := _particles(40, 0.7, _flame_material(), 0.12)
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(radius, 0.02, radius)
	pm.direction = Vector3.UP
	pm.spread = 10.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.2
	pm.gravity = Vector3(0, 1.5, 0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.6, 0.75, 1.0, 1.0))
	ramp.add_point(0.25, Color(1.0, 0.7, 0.2, 0.95))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.6, 0.1, 0.02, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	pm.color_ramp = tex
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	return p
