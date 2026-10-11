class_name FireFX
extends Node
## How one member looks in a fire: scorch and char creeping over it (char_overlay.gdshader, which
## stays after the fire's out), and while it burns, its fire and smoke rising. The fire is a sheet
## (fire_sheet.gdshader, the art session's: one continuous fire a member, every sheet drawing the
## same field so a burning front is one mass); `sheets` false draws the older flipbook tongues
## (flame.gdshader) instead, for comparing. Both ride on the member's own meshes, so they go with
## it when it falls.

const OVERLAY := preload("res://src/fire/char_overlay.gdshader")

var member: StructureMember

var _overlay: ShaderMaterial
var _emitters: Array[Node3D] = []

const FLAME := preload("res://src/fire/flame.gdshader")
const SHEET := preload("res://src/fire/fire_sheet.gdshader")
## How much taller than FireTuning's tongue a sheet's fire stands: the fire painting's flames are a
## storey tall (the art session, judged on the view livery_fire_dusk).
const SHEET_GROW := 1.8
## Timber of a building's frame: its fire is drawn behind it, so it stands dark against its flames.
const FRAME_KINDS := [&"sill", &"post", &"joist", &"stud", &"plate", &"beam", &"header", &"ledger",
		&"rafter", &"cripple", &"ridge"]

## Fire as sheets (true) or as the flipbook tongues (false, for comparing; --flame-sprites).
static var sheets := true
static var _sheet_mat: ShaderMaterial
static var _sheet_quad: QuadMesh

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
			if sheets:
				_emitters.append(_sheet_on(mi, tuning, false))
				if _over_opening():
					_emitters.append(_sheet_on(mi, tuning, true))
			else:
				_emitters.append(_flames_on(mi, tuning))
				if _over_opening():
					_emitters.append(_opening_flames(mi, tuning))
			if smoke:
				_emitters.append(_smoke_on(mi))
	elif not flames and not _emitters.is_empty():
		_clear()
	# The fire grows as it burns.
	if flames:
		var size := _flame_size(tuning)
		var heat := sheet_heat(member, tuning)
		for e in _emitters:
			if not is_instance_valid(e) or not e.has_meta(&"flame"):
				continue
			if e is GPUParticles3D:
				((e as GPUParticles3D).draw_pass_1 as QuadMesh).size = size * float(e.get_meta(&"flame"))
			else:
				(e as GeometryInstance3D).set_instance_shader_parameter(&"heat", heat)


func _exit_tree() -> void:
	_clear()


func _clear() -> void:
	for e in _emitters:
		if not is_instance_valid(e):
			continue
		var p := e as GPUParticles3D
		if p:
			p.emitting = false
			p.get_tree().create_timer(p.lifetime + 0.5).timeout.connect(p.queue_free) if p.is_inside_tree() else p.queue_free()
		else:
			e.queue_free()
	_emitters.clear()


## The tongues' size now: from catching to fully alight over `growth_seconds` of burning.
func _flame_size(tuning: FireTuning) -> Vector2:
	var grown := clampf(member.burn_time / maxf(tuning.growth_seconds, 0.01), 0.0, 1.0) if member.burning else 0.0
	return tuning.flame_size_catching.lerp(tuning.flame_size_alight, grown)


## How much of its sheet a burning member's fire fills: from a tongue's catching height to all of
## it over `growth_seconds`, as the flipbook tongues grow.
static func sheet_heat(m: StructureMember, tuning: FireTuning) -> float:
	var grown := clampf(m.burn_time / maxf(tuning.growth_seconds, 0.01), 0.0, 1.0) if m.burning else 0.0
	return lerpf(tuning.flame_size_catching.y / tuning.flame_size_alight.y, 1.0, grown)


## The member's fire as one sheet: stood at the foot of a standing member (the boards of a
## wall burn up their whole face) and reaching a grown tongue's height over its top, or on top of
## one lying flat (its thinnest side up); over a door or window head (`opening`), standing in the opening under it, so the
## fire inside pours out of its top. As wide as the member plus half a tongue, so the sheets of a
## wall's boards overlap and draw one fire.
func _sheet_on(mi: MeshInstance3D, tuning: FireTuning, opening: bool) -> MeshInstance3D:
	var box := mi.global_transform * mi.get_aabb()
	var flame := tuning.flame_size_alight.y * SHEET_GROW
	var width := maxf(box.size.x, box.size.z) + tuning.flame_size_alight.x * 0.6
	var foot := box.get_center()
	var height := flame
	if opening:
		foot.y = box.position.y - 0.9
		width = maxf(box.size.x, box.size.z)
	elif box.size.y > minf(box.size.x, box.size.z):
		# Standing (a post, a wall's board: its thin side faces sideways), not lying flat.
		foot.y = box.position.y
		height = box.size.y + flame
	else:
		foot.y = box.end.y - 0.05
	var sheet := MeshInstance3D.new()
	sheet.mesh = _sheet_mesh()
	sheet.material_override = _sheet_material()
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sheet.set_meta(&"flame", 1.0)
	# The shader turns and sizes the quad round its foot; this box only has to hold it.
	var r := maxf(width, height) + 0.5
	sheet.custom_aabb = AABB(Vector3(-r, -r, -r), Vector3(2.0 * r, 2.0 * r, 2.0 * r))
	mi.add_child(sheet)
	sheet.global_position = foot
	sheet.set_instance_shader_parameter(&"size", Vector2(width, height))
	sheet.set_instance_shader_parameter(&"heat", sheet_heat(member, tuning))
	if not opening and member.kind in FRAME_KINDS:
		sheet.set_instance_shader_parameter(&"behind", 1.0)
		# Its cross section, not a beam's length: behind the timber, not behind the building.
		var half := box.size * 0.5
		sheet.set_instance_shader_parameter(&"half_box", Vector3(minf(half.x, 0.3), half.y, minf(half.z, 0.3)))
	return sheet


static func _sheet_mesh() -> QuadMesh:
	if _sheet_quad == null:
		_sheet_quad = QuadMesh.new()
		_sheet_quad.size = Vector2.ONE
	return _sheet_quad


static func _sheet_material() -> ShaderMaterial:
	if _sheet_mat == null:
		_sheet_mat = ShaderMaterial.new()
		_sheet_mat.shader = SHEET
	return _sheet_mat


## Is this the head or header over a door or window? The fire inside pours out of the opening's top.
func _over_opening() -> bool:
	var id := String(member.member_id)
	return id.ends_with("/head") or id.ends_with("/header")


## Tongues off the member's upper half (its top face, if it lies flat), licking up and off it: a
## few big ones, not a sprinkle over its whole shell (the art session, docs/briefs/fire-look.md:
## the painting's fire is masses of tall tongues pouring off the tops).
func _flames_on(mi: MeshInstance3D, tuning: FireTuning) -> GPUParticles3D:
	var box := mi.get_aabb()
	var area := box.size.x * box.size.y + box.size.y * box.size.z + box.size.x * box.size.z
	var p := _particles(clampi(int(area * 3.3), 2, tuning.flames_a_member), 0.9, _flame_material(), 0.42)
	p.set_meta(&"flame", 1.0)
	(p.draw_pass_1 as QuadMesh).size = _flame_size(tuning)
	var pm := p.process_material as ParticleProcessMaterial
	# Off the surface, not inside the wood: a hand's breadth round its upper half.
	var upright := box.size.y > maxf(box.size.x, box.size.z)
	var band := box.size.y * 0.25 if upright else 0.02
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(box.size.x * 0.5 + 0.07, band + 0.05, box.size.z * 0.5 + 0.07)
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0, 1.4, 0)
	pm.scale_min = 0.8
	pm.scale_max = 1.2
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
	# Centred on the upper half (an upright member) or just over its top (one lying flat).
	p.position = box.get_center() + Vector3.UP * (box.size.y * 0.25 if upright else box.size.y * 0.5 + 0.05)
	return p


## A few tongues pouring up out of the top of the opening under this head or header.
func _opening_flames(mi: MeshInstance3D, tuning: FireTuning) -> GPUParticles3D:
	var box := mi.get_aabb()
	var p := _flames_on(mi, tuning)
	p.amount = clampi(int(maxf(box.size.x, box.size.z) * 2.0), 2, 4)
	p.set_meta(&"flame", 1.15)
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_box_extents = Vector3(box.size.x * 0.5, 0.05, box.size.z * 0.5)
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.2
	p.position = box.get_center() - Vector3.UP * (box.size.y * 0.5 + 0.1)
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
		_flame_mat.set_shader_parameter(&"sprite", load("res://assets/textures/drawn/flames.png"))
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
