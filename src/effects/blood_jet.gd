class_name BloodJet
extends Node3D
## Blood coming out of one wound, driven by that wound's bleeds in the Physiology: a cut artery
## spurts in time with the heartbeat (harder while the pressure holds, weaker as he bleeds out),
## a vein pours dark and steady, anything else oozes and drips. Where it lands it leaves splats.
## Sits on the body segment at the wound with +Y out of the skin, so it moves with him.

var body: HumanBody
var bleed_ids: Array = []
## Share of the bleeds that comes out here (an exit wound splits it with the entry).
var share := 1.0

var _particles: GPUParticles3D
var _material: ParticleProcessMaterial
var _beat := 0.0
var _landing_ml := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(get_path())
	_particles = GPUParticles3D.new()
	_particles.name = "Drops"
	_particles.amount = 180
	_particles.lifetime = 1.1
	_particles.local_coords = false
	_particles.emitting = false
	_particles.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	_material = ParticleProcessMaterial.new()
	_material.direction = Vector3.UP
	_material.spread = 7.0
	_material.gravity = Vector3(0, -9.8, 0)
	_material.initial_velocity_min = 0.0
	_material.initial_velocity_max = 0.0
	_material.scale_min = 0.7
	_material.scale_max = 1.4
	# Drops stretch along their flight, so a jet reads as a stream.
	_material.particle_flag_align_y = true
	_particles.process_material = _material
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.018, 0.05, 0.018)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.35
	mesh.material = mat
	_particles.draw_pass_1 = mesh
	add_child(_particles)


## ml/s by kind coming out of this wound now.
func rates() -> Dictionary:
	var out := {&"artery": 0.0, &"vein": 0.0, &"ooze": 0.0}
	var p := body.physiology
	for i: int in bleed_ids:
		if i < p.bleeds.size():
			var b: Dictionary = p.bleeds[i]
			out[b.get("kind", &"ooze")] += p.bleed_rate(b) * share
	return out


func _physics_process(delta: float) -> void:
	if body == null or not is_instance_valid(body):
		return
	var p := body.physiology
	var r := rates()
	var total: float = r[&"artery"] + r[&"vein"] + r[&"ooze"]
	if total < 0.03:
		_particles.emitting = false
		return
	_particles.emitting = true
	var pulse := 1.0
	var speed := 0.0
	var colour := Blood.VENOUS
	if r[&"artery"] > 0.3:
		# Spurts on each beat: fast up-stroke, falling off before the next.
		_beat = fmod(_beat + delta * p.heart_rate() / 60.0, 1.0)
		pulse = pow(maxf(sin(_beat * TAU), 0.0), 2.0)
		speed = sqrt(r[&"artery"]) * 0.85 * sqrt(maxf(p.pressure(), 0.05)) * (0.3 + 0.7 * pulse)
		colour = Blood.ARTERIAL
		_material.spread = 6.0
		_particles.amount_ratio = clampf(0.15 + 0.85 * pulse, 0.0, 1.0) * clampf(r[&"artery"] / 10.0, 0.3, 1.0)
	elif r[&"vein"] > 0.3:
		speed = 0.25 + sqrt(r[&"vein"]) * 0.08
		_material.spread = 25.0
		_particles.amount_ratio = clampf(r[&"vein"] / 12.0, 0.2, 0.8)
	else:
		speed = 0.04
		_material.spread = 40.0
		_particles.amount_ratio = clampf(total / 3.0, 0.05, 0.3)
	_material.initial_velocity_min = speed * 0.85
	_material.initial_velocity_max = speed * 1.1
	_material.color = colour
	# Where it's coming down: a splat every so often, thrown the way the drops go.
	_landing_ml += total * delta
	var every := 6.0 if r[&"artery"] > 0.3 else 3.0
	if _landing_ml >= every:
		var n := global_basis.y.normalized()
		var v := n * speed + Vector3(_rng.randf_range(-0.2, 0.2), 0, _rng.randf_range(-0.2, 0.2))
		Blood.throw(body.get_parent() as Node3D, global_position + n * 0.02, v, _landing_ml, _exclude())
		_landing_ml = 0.0


func _exclude() -> Array[RID]:
	var out: Array[RID] = []
	for sid: StringName in body.parts:
		var part := body.parts[sid] as CollisionObject3D
		if part != null and is_instance_valid(part):
			out.append(part.get_rid())
	return out
