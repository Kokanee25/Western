class_name GunHand
extends RefCounted
## Where a gang member's barrel really points (docs/briefs/three-gunmen.md, gap 2; the gunfight
## lab's first fix): it swings onto what he wants with a hand's lag, wanders by the player's own
## sway model (Sway) sized by his state, kicks when he fires, and has to settle again after drawing,
## swinging round, moving, his own shot, a near miss or a ball into him. OutlawBrain steps it every
## tick and fires along `barrel()`: his misses come from the gun's state, not from dice.

var tuning: GunHandTuning
var sway: Sway
## Where he's pointing it (unit, world), the wander and the kick aside.
var dir := Vector3.ZERO
## The wander and the kick now (degrees: x to the right, y up).
var offset := Vector2.ZERO
## Seconds held up and still (the wander shrinks from `unsettled` times over `settle_time`).
var steady := 0.0
var winded := 0.0
var kick := GunKick.new()
var _rng := RandomNumberGenerator.new()


func _init(t: GunHandTuning, seed_value: int) -> void:
	tuning = t
	sway = Sway.new(seed_value)
	_rng.seed = seed_value * 3 + 1


## On `delta`, swinging toward `want` (unit, world). `aimed`: up in an aim pose (else held low);
## `speed` m/s; `stress` multiplies the wander (fear, pain, shock, rounds cracking past); `shake`
## adds to the tremor (a hurt arm); `eye` multiplies the wander (the wrong eye).
func step(delta: float, want: Vector3, aimed: bool, crouched: bool, speed: float, stress: float, shake := 0.0, eye := 1.0) -> void:
	var t := tuning
	if dir == Vector3.ZERO:
		dir = want
	var ang := dir.angle_to(want)
	var turn := minf(ang * (1.0 - exp(-delta / maxf(t.hand_lag, 0.001))), deg_to_rad(t.turn_rate) * delta)
	if ang > 1e-5:
		var axis := dir.cross(want)
		dir = (dir.rotated(axis.normalized(), turn) if axis.length() > 1e-6 else want).normalized()
	steady *= exp(-rad_to_deg(turn) / maxf(t.turn_unsettle, 0.01))
	if aimed and speed < 0.5:
		steady += delta
	else:
		steady = 0.0
	if speed > 3.0:
		winded = 1.0
	else:
		winded = maxf(winded - delta / maxf(t.winded_seconds, 0.01), 0.0)
	var amp := (t.sway_aim if aimed else t.sway_hip) * lerpf(t.unsettled, 1.0, clampf(steady / maxf(t.settle_time, 0.01), 0.0, 1.0))
	if crouched:
		amp *= t.crouch_sway
	amp = (amp + speed * t.move_sway) * stress * eye
	var breath := t.breath * (1.0 + winded * 1.5) * (t.crouch_sway if crouched else 1.0)
	kick.step(delta)
	offset = sway.step(delta, amp, breath, t.breath_rate, 1.0 + winded * 1.5, (t.tremor + shake) * stress) \
			+ Vector2(kick.yaw, kick.pitch)


## Where the ball goes now: `dir` turned by the wander and the kick.
func barrel() -> Vector3:
	var d := dir.rotated(Vector3.UP, deg_to_rad(-offset.x))
	var right := d.cross(Vector3.UP)
	if right.length() < 1e-4:
		return d
	return d.rotated(right.normalized(), deg_to_rad(offset.y)).normalized()


## How far the barrel is off `want` now (degrees).
func error_to(want: Vector3) -> float:
	return rad_to_deg(barrel().angle_to(want))


## His shot's gone off: the gun climbs in his hand (the revolver's kick) and he has to settle again.
func fired(gun: RevolverTuning) -> void:
	kick.rise = gun.kick_rise
	kick.damping = gun.kick_damping
	kick.fire(gun.kick_degrees * gun.kick_aimed, _rng.randfn(0.0, gun.kick_side_degrees))
	steady = 0.0


## Jolted (a near miss, a ball into him, a snatched trigger): off line, and settling again.
func jerk(degrees: float) -> void:
	sway.add_jerk(degrees, _rng)
	steady = 0.0
