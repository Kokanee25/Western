class_name GunKick
extends RefCounted
## A gun's kick as a push, not a flip (DESIGN.md §7 "Recoil"; Sean: "should push, not flip"). The
## shot gives the gun a shove (a velocity, not a jump in angle), so the muzzle rises over a few
## hundredths of a second, the hand's muscles bring it back down like a spring, it dips a little
## past where it was and settles. A damped spring hit by an impulse: angle(t) =
## v0/wd * e^(-zeta wn t) * sin(wd t). `rise` (seconds to the top) and `damping` (zeta) set its
## shape; `fire()` scales v0 so the top is the peak asked for.
##
## One spring for each way it moves: pitch (muzzle up, degrees), yaw (to the right, degrees), roll
## (degrees) and back (towards you, metres); all share the shape.

var rise := 0.075
var damping := 0.62
var pitch := 0.0
var yaw := 0.0
var roll := 0.0
var back := 0.0
var _v := Vector4.ZERO


## Shove it: the tops it reaches (pitch, yaw, roll in degrees; back in metres).
func fire(peak_pitch: float, peak_yaw := 0.0, peak_roll := 0.0, peak_back := 0.0) -> void:
	var k := 1.0 / unit_peak()
	_v += Vector4(peak_pitch, peak_yaw, peak_roll, peak_back) * k


## Natural frequency (rad/s) that puts the top `rise` seconds after the shove.
func omega() -> float:
	var z := clampf(damping, 0.05, 0.95)
	var s := sqrt(1.0 - z * z)
	return atan2(s, z) / (s * maxf(rise, 0.005))


## The top reached by a shove of 1/s.
func unit_peak() -> float:
	var z := clampf(damping, 0.05, 0.95)
	var wn := omega()
	var wd := wn * sqrt(1.0 - z * z)
	var tp := atan2(sqrt(1.0 - z * z), z) / wd
	return exp(-z * wn * tp) * sin(wd * tp) / wd


## Advance `delta` seconds (sub-stepped: the spring is stiff).
func step(delta: float) -> void:
	var z := clampf(damping, 0.05, 0.95)
	var wn := omega()
	var steps := maxi(1, ceili(delta / 0.004))
	var h := delta / steps
	var x := Vector4(pitch, yaw, roll, back)
	for i in steps:
		# Semi-implicit Euler: the velocity first, then the position with the new velocity.
		_v += (-wn * wn * x - 2.0 * z * wn * _v) * h
		x += _v * h
	pitch = x.x
	yaw = x.y
	roll = x.z
	back = x.w


func is_still() -> bool:
	return absf(pitch) < 0.01 and _v.length() < 0.05
