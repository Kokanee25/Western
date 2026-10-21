class_name Sway
extends RefCounted
## The wander of a gun held out, one model for the player's gun (WeaponViewmodel) and the gang's
## (GunHand), so a man's misses come from the same things yours do (docs/briefs/three-gunmen.md,
## gap 2). A slow drift (two unrelated slow waves on each axis, so it never quite repeats),
## breathing (up and down), a fine shake, and jerks that die away. Degrees: x to the right, y up.
## Whoever holds the gun sizes each part every step, from its own state.

var time := 0.0
var breath_phase := 0.0
var jerk := Vector2.ZERO
var _phase: Array[float] = []


func _init(seed_value := 9001) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	for i in 6:
		_phase.append(r.randf() * TAU)


## On `delta` and return where it's wandered to: `drift` (the wander's size), `breath` (how far the
## muzzle rises and falls), `breaths` a second (times `hurry`, winded), `shake` (the tremor's size).
func step(delta: float, drift: float, breath: float, breaths: float, hurry: float, shake: float) -> Vector2:
	time += delta
	var w := time
	var p := _phase
	var wander := Vector2(sin(w * 0.71 + p[0]) * 0.6 + sin(w * 1.37 + p[1]) * 0.4,
			sin(w * 0.53 + p[2]) * 0.6 + sin(w * 1.13 + p[3]) * 0.4) * drift
	breath_phase += delta * TAU * breaths * hurry
	var rise := sin(breath_phase) * breath
	var tremor := Vector2(sin(w * 23.1 + p[4]), sin(w * 29.7 + p[5])) * shake
	jerk *= exp(-delta * 7.0)
	return wander + Vector2(0.0, rise) + tremor + jerk


## A flinch: the gun jerks off line (degrees), then comes back.
func add_jerk(degrees: float, rng: RandomNumberGenerator) -> void:
	jerk += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.5, 1.0)).normalized() * degrees
