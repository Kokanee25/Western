class_name FloorDust
extends Node3D
## Dust sifting down through an upper floor's boards onto the room below (saloon B's dance floor
## over the bar: Sean's answer 4 on PR #772, #867). A building's spec names the floor (`dust`);
## SpecBuilding places one of these under it.
##
## A few motes hang in the room at rest (`rest`). Where someone moves on the boards above, dust
## falls under their feet: `stir(at, amount)` does the same for anything else that shakes the
## floor (a saw in a girder, a dropped keg). Motes are small lit quads, so they show where the
## windows' and lamps' light crosses them and are lost in the dark, as dust is.
##
## Nothing here is physics or sound: a look only, a handful of CPU particles (no shadows).

## The floor's rect in the parent's x, z: [x0, z0, x1, z1].
var rect := Rect2(0, 0, 4, 4)
## The boards' underside and the floor below, in the parent's y.
var top := 3.0
var bottom := 0.0
## How much hangs in the air with nobody above (this share of `motes`).
var rest := 0.2
var motes := 70
## How fast someone above must move to shake dust down (m/s), and how many falls at once.
var stir_speed := 0.5
var falls := 4

var _air: CPUParticles3D
var _pool: Array[CPUParticles3D] = []
var _next := 0
var _was := {}
var _tick := 0.0

static var _mat: StandardMaterial3D


func _ready() -> void:
	_air = _emitter(maxi(1, roundi(motes * rest)), 9.0)
	_air.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_air.emission_box_extents = Vector3(rect.size.x * 0.5, (top - bottom) * 0.45, rect.size.y * 0.5)
	_air.position = Vector3(rect.get_center().x, (top + bottom) * 0.5, rect.get_center().y)
	_air.gravity = Vector3(0, -0.012, 0)
	_air.initial_velocity_max = 0.03
	_air.emitting = rest > 0.0
	for i in falls:
		var f := _emitter(26, 5.5)
		f.one_shot = true
		f.emitting = false
		f.explosiveness = 0.25
		f.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		f.emission_box_extents = Vector3(0.45, 0.01, 0.45)
		f.gravity = Vector3(0, -0.22, 0)
		f.damping_min = 0.25
		f.damping_max = 0.5
		f.initial_velocity_max = 0.05
		_pool.append(f)


func _emitter(amount: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.randomness = 0.6
	p.direction = Vector3.DOWN
	p.spread = 60.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.012)
	p.mesh = q
	p.material_override = _material()
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.color_ramp = _fade()
	add_child(p)
	return p


static func _material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color(0.86, 0.8, 0.68, 0.55)
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_mat.vertex_color_use_as_albedo = true
		_mat.roughness = 1.0
		_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_mat.disable_receive_shadows = false
	return _mat


static func _fade() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.15, Color(1, 1, 1, 1))
	g.add_point(0.8, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	return g


## Dust shaken down under `at` (the parent's space; its y is ignored), `amount` 0..1.
func stir(at: Vector3, amount := 1.0) -> void:
	if _pool.is_empty() or not rect.has_point(Vector2(at.x, at.z)):
		return
	var f := _pool[_next]
	_next = (_next + 1) % _pool.size()
	f.position = Vector3(at.x, top - 0.02, at.z)
	f.initial_velocity_max = 0.03 + 0.06 * clampf(amount, 0.0, 1.0)
	f.restart()
	f.emitting = true


func _physics_process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.4
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var seen := {}
	for g: StringName in [&"people", &"player"]:
		for n in get_tree().get_nodes_in_group(g):
			var b := n as Node3D
			if b == null:
				continue
			var p := parent.to_local(b.global_position)
			var id := b.get_instance_id()
			seen[id] = p
			# On the boards above: their feet within a stride of the floor's top.
			if p.y < top - 0.1 or p.y > top + 1.2 or not rect.has_point(Vector2(p.x, p.z)):
				continue
			if _was.has(id) and ((_was[id] as Vector3) - p).length() / 0.4 > stir_speed:
				stir(p, clampf(((_was[id] as Vector3) - p).length() / 0.4 / 3.0, 0.3, 1.0))
	_was = seen
