class_name BloodJet
extends Node3D
## Blood coming out of one wound, driven by that wound's bleeds in the Physiology: a cut artery
## spurts in time with the heartbeat (harder while the pressure holds, weaker as he bleeds out),
## a vein pours dark and steady, anything else oozes and drips. Where it lands it leaves splats.
## Sits on the body segment at the wound with +Y out of the skin, so it moves with him.

## An artery's jet: the pressure behind it over a beat (mmHg, a healthy man's: Physiology.pressure()
## scales it down as he bleeds), systole the first share of the beat, blood's density (kg/m³) and
## the share of the ideal speed it keeps through the torn vessel and the hole (an orifice's
## discharge coefficient).
const SYSTOLIC_MMHG := 120.0
const DIASTOLIC_MMHG := 80.0
const SYSTOLE := 0.35
const PA_PER_MMHG := 133.32
const BLOOD_DENSITY := 1060.0
const DISCHARGE := 0.6

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
	_particles = Blood.drop_particles(320, 0.9)
	_particles.name = "Drops"
	_particles.emitting = false
	_material = _particles.process_material as ParticleProcessMaterial
	_material.direction = Vector3.UP
	_material.spread = 7.0
	_material.initial_velocity_min = 0.0
	_material.initial_velocity_max = 0.0
	add_child(_particles)


## How fast blood leaves an artery with `mmhg` behind it (m/s): Bernoulli's v = sqrt(2P/rho), less
## what the torn vessel and the hole take (5.5 m/s ideal at 120 mmHg: experiments/body_lab/README.md).
static func jet_speed(mmhg: float) -> float:
	return DISCHARGE * sqrt(2.0 * maxf(mmhg, 0.0) * PA_PER_MMHG / BLOOD_DENSITY)


## ml/s by kind coming out of this wound now.
func rates() -> Dictionary:
	var out := {&"artery": 0.0, &"vein": 0.0, &"ooze": 0.0}
	var p := body.physiology
	for i: int in bleed_ids:
		if i < p.bleeds.size():
			var b: Dictionary = p.bleeds[i]
			var kind: StringName = b.get("kind", &"ooze")
			if out.has(kind):
				out[kind] += p.bleed_rate(b) * share
	return out


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"blood", t)


func _physics_step(delta: float) -> void:
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
		# Spurts on each beat: the pressure behind it climbs fast from diastolic to systolic in the
		# first third of the beat and falls away; the jet leaves at the speed that pressure gives
		# (Bernoulli, less what the torn vessel and the hole take), and both fall as he bleeds out.
		_beat = fmod(_beat + delta * p.heart_rate() / 60.0, 1.0)
		pulse = sin(_beat / SYSTOLE * PI) if _beat < SYSTOLE else 0.0
		var mmhg := lerpf(DIASTOLIC_MMHG, SYSTOLIC_MMHG, pulse) * p.pressure()
		speed = jet_speed(mmhg)
		colour = Blood.ARTERIAL
		_material.spread = 4.0
		_particles.amount_ratio = clampf(0.35 + 0.65 * pulse, 0.0, 1.0) * clampf(r[&"artery"] / 10.0, 0.3, 1.0)
	elif r[&"vein"] > 0.3:
		speed = 0.25 + sqrt(r[&"vein"]) * 0.08
		_material.spread = 25.0
		_particles.amount_ratio = clampf(r[&"vein"] / 12.0, 0.2, 0.8)
	else:
		speed = 0.04
		_material.spread = 40.0
		_particles.amount_ratio = clampf(total / 3.0, 0.05, 0.3)
	# A hand pressed over the hole: it wells out between his fingers and runs down, not spurts.
	var covered := body.hand_over(global_position)
	if covered > 0.0:
		speed = lerpf(speed, 0.05, covered)
		_material.spread = lerpf(_material.spread, 50.0, covered)
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
