class_name PlayerMotion
extends RefCounted
## How a man with weight in boots moves the eyes and the gun: steps (a footfall each, the head low
## and dropped on the heel strike, high over the planted foot, side to side once a stride), a lean
## into strafes and turns and into a push off, a dip on landing, a crouch that sinks and a stand
## that rises (springs, not slides), a winded man's breath heaving him, and the gun lagging the
## view and riding the steps. The Player steps it every physics frame and reads the offsets; the
## guns read `hand_pos`/`hand_turn`. Every number is in PlayerTuning ("Steps" onward).
## Ideas (not code) from the way weighty first-person games are usually described: footfall-timed
## bob with a sharp low, camera roll into strafes, spring-driven landing and crouch, weapon lag.

## Footfalls taken (whole steps; the fraction is how far into the next one).
var steps := 0.0
## Where the eyes are above the feet (m), sprung towards standing or crouched.
var eye_height := 1.64
## Offsets this frame: the head's position (m; x to the right, y up) and turn (degrees: x pitch up,
## z roll to the left).
var head_pos := Vector3.ZERO
var head_turn := Vector3.ZERO
## The gun in your hands: where it's pushed off its pose (m, camera space) and how far it's turned
## off your line of sight (degrees: x to the right, y up; the shot goes with it).
var hand_pos := Vector3.ZERO
var hand_turn := Vector2.ZERO
## What's in your hands pushed out ahead of you this far (m: a shove with the shotgun held across,
## PlayerShove), on top of the rest.
var push_out := 0.0
## True on the frame a foot comes down.
var footfall := false
## The last landing's fall speed (m/s, for tests and the bridge).
var last_landing := 0.0

var _dip := Spring.new()
var _eye := Spring.new()
var _roll := Spring.new()
var _tilt := Spring.new()
var _hand_x := Spring.new()
var _hand_y := Spring.new()
var _hand_z := Spring.new()
var _look := Vector2.ZERO
var _was_on_floor := true
var _last_velocity := Vector3.ZERO
var _breath := 0.0
## The eyes still below where a step up put them (m, negative), easing back.
var _step_lag := 0.0


## A damped spring (natural frequency in Hz, damping ratio 1 = no overshoot) for one number.
class Spring:
	var x := 0.0
	var v := 0.0

	func step(target: float, delta: float, hz: float, damping: float) -> float:
		var w := TAU * maxf(hz, 0.01)
		v += (-w * w * (x - target) - 2.0 * damping * w * v) * delta
		x += v * delta
		return x

	func kick(dv: float) -> void:
		v += dv


## The body was lifted onto a step this frame: the eyes follow it up over a moment.
func stepped(gained: float) -> void:
	_step_lag = maxf(_step_lag - gained, -0.3)


## A blow landing through you (your shove or kick meeting something): the head jolts down by
## this (m/s on the dip's spring) and comes back.
func thump(dv: float) -> void:
	_dip.kick(-dv)


func reset(eye: float) -> void:
	eye_height = eye
	_eye.x = eye
	_eye.v = 0.0


## The view turned this much since the last frame (degrees: x right, y up); the gun lags it.
func looked(delta_degrees: Vector2) -> void:
	_look += delta_degrees


## The step length (m) at this speed: short and quick crouched, longer as he runs.
static func step_length(t: PlayerTuning, speed: float, crouching: bool) -> float:
	if crouching:
		return t.step_crouch
	if speed <= t.walk_speed:
		return t.step_walk * lerpf(0.7, 1.0, clampf(speed / maxf(t.walk_speed, 0.01), 0.0, 1.0))
	return lerpf(t.step_walk, t.step_run, clampf(inverse_lerp(t.walk_speed, t.run_speed, speed), 0.0, 1.0))


## One physics frame. `local_velocity` is the player's velocity in its own frame (x right, -z
## forward); `fall_speed` how fast he was coming down before this frame's move (m/s, positive down).
func step(t: PlayerTuning, delta: float, local_velocity: Vector3, on_floor: bool, crouching: bool,
		aiming: bool, winded: float, fall_speed: float) -> void:
	var flat := Vector2(local_velocity.x, local_velocity.z)
	var speed := flat.length()
	var walk := maxf(t.walk_speed, 0.01)
	# Steps: a footfall each time the count passes a whole number.
	footfall = false
	if on_floor and speed > 0.2:
		var before := steps
		steps += speed * delta / maxf(step_length(t, speed, crouching), 0.05)
		footfall = floorf(steps) > floorf(before)
	var phase := fposmod(steps, 1.0)
	var run_k := clampf(inverse_lerp(t.walk_speed, t.run_speed, speed), 0.0, 1.0)
	var strength := clampf(speed / walk, 0.0, 1.0) if on_floor else 0.0
	if crouching:
		strength *= t.bob_crouch
	var amp := lerpf(t.bob_walk, t.bob_run, run_k) * strength
	# Low on the heel strike (phase 0), high over the planted foot; sharp makes the low a jolt.
	var s := absf(sin(PI * phase))
	var shape := lerpf(s * s, s, t.bob_sharpness)
	var bob := 2.0 * amp * (shape - lerpf(0.5, 2.0 / PI, t.bob_sharpness))
	var side := sin(PI * steps) * t.bob_side * strength * lerpf(1.0, 1.4, run_k)
	# The weight landing on each foot drops the head a little more; a landing a lot more.
	if footfall:
		_dip.kick(-t.step_thud * strength * lerpf(1.0, 1.6, run_k))
	if on_floor and not _was_on_floor and fall_speed > 0.5:
		last_landing = fall_speed
		var depth := minf(fall_speed * t.land_dip, t.land_dip_max)
		_dip.kick(-depth * TAU * t.head_hz)
	_was_on_floor = on_floor
	var dip := _dip.step(0.0, delta, t.head_hz, t.head_damping)
	# Crouching sinks, standing rises: a spring, so heavier settles slower and overshoots a touch.
	var target_eye := t.crouch_eye_height if crouching else t.stand_eye_height
	eye_height = _eye.step(target_eye, delta, t.crouch_hz, t.crouch_damping)
	# Winded: his breath heaves him, deeper and faster the more winded.
	_breath += delta * t.breath_rate * (1.0 + winded * 1.5)
	var heave := sin(_breath * TAU) * t.breath_heave * winded
	_step_lag *= exp(-delta * t.step_ease)
	head_pos = Vector3(side, bob + dip + heave + _step_lag, 0.0)
	# Lean: roll into a strafe and into a turn (turning right at speed, he leans right); pitch into
	# a push off and back against a stop.
	var accel := (local_velocity - _last_velocity) / maxf(delta, 0.001)
	_last_velocity = local_velocity
	var yaw_rate := _look.x / maxf(delta, 0.001) if on_floor else 0.0
	var turn := clampf(yaw_rate / 180.0, -2.0, 2.0) * clampf(speed / maxf(t.run_speed, 0.01), 0.0, 1.0)
	var roll_target := -local_velocity.x * t.strafe_lean - turn * t.turn_lean \
			+ sin(PI * steps) * t.bob_roll * strength
	var tilt_target := clampf(accel.z * t.accel_tilt, -t.tilt_max, t.tilt_max) if on_floor else 0.0
	var aim_k := t.aim_motion if aiming else 1.0
	head_turn = Vector3(_tilt.step(tilt_target, delta, t.lean_hz, t.lean_damping), 0.0,
			_roll.step(roll_target * aim_k, delta, t.lean_hz, t.lean_damping))
	# The gun: it lags the view's turn, rides the steps (down on the footfall, across with the
	# stride), drops on a landing, and swings back against a push off.
	var lag := (-_look / maxf(delta, 0.001)) * t.hand_lag / 100.0
	lag = lag.limit_length(t.hand_lag_max)
	_look = Vector2.ZERO
	var hx := _hand_x.step(lag.x + side * 100.0 * t.hand_bob_turn, delta, t.hand_hz, t.hand_damping)
	var hy := _hand_y.step(lag.y + (bob + dip) * 100.0 * t.hand_bob_turn, delta, t.hand_hz, t.hand_damping)
	var hz := _hand_z.step(clampf(-accel.z * t.hand_push, -0.04, 0.04) if on_floor else 0.0, delta, t.hand_hz, t.hand_damping)
	hand_turn = Vector2(hx, hy) * aim_k
	hand_pos = Vector3(side * t.hand_bob, (bob + dip) * t.hand_bob, hz) * aim_k + Vector3(0.0, 0.0, -push_out)


func describe() -> String:
	return "step %.2f  head %.3f m  roll %.2f°  tilt %.2f°  gun %.2f°,%.2f°" % [steps, head_pos.y,
			head_turn.z, head_turn.x, hand_turn.x, hand_turn.y]
