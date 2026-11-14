class_name HeadGesture
extends RefCounted
## A nod or a shake of the head, read from the way you look (Sean's "head-shake controls" for
## answering people: the smallest first cut, issue #746). A nod is the view pitching down, up and
## down again (or up, down, up); a shake, turning one way, back and back again; each swing at least
## `swing_deg`, the three swings within `window_s`, and the view moving mostly on that axis. Mouse or
## stick: it reads the view, so both work. Pure: feed it the yaw and pitch each tick and it answers
## &"nod", &"shake" or &"" (once a gesture's read it starts over).

## Each swing at least this far (degrees).
var swing_deg := 6.0
## The three swings (two turns back) within this long (s).
var window_s := 1.4
## The gesture's axis moved at least this many times as much as the other meanwhile.
var dominance := 1.5

var _t := 0.0
var _last := Vector2(INF, INF)
var _odo := Vector2.ZERO  # how far each axis has moved all told (degrees)
var _axes: Array[_Axis] = [_Axis.new(), _Axis.new()]  # yaw, pitch


class _Axis:
	var pos := 0.0  ## followed by its changes (the yaw's wrap doesn't matter)
	var dir := 0  ## +1, -1, or 0 before its first swing
	var extreme := 0.0  ## the furthest it got the way it's going
	var marks: Array[float] = []  ## when each swing was made (its swing_deg reached)
	var odos: Array[Vector2] = []  ## both axes' odometers at each mark

	func reset() -> void:
		dir = 0
		extreme = pos
		marks.clear()
		odos.clear()


## Feed the view's yaw and pitch (degrees) after `dt` seconds. Returns &"nod", &"shake" or &"".
func feed(yaw_deg: float, pitch_deg: float, dt: float) -> StringName:
	_t += dt
	var v := Vector2(yaw_deg, pitch_deg)
	if _last.x == INF:
		_last = v
		return &""
	var d := Vector2(wrapf(v.x - _last.x, -180.0, 180.0), v.y - _last.y)
	_last = v
	_odo += d.abs()
	var got := &""
	for i in 2:
		var a := _axes[i]
		a.pos += d[i]
		if _step(a) and a.marks.size() >= 3 and a.marks[-1] - a.marks[-3] <= window_s:
			# The view moved mostly this way over the gesture (not round and round).
			var moved := _odo - a.odos[-3]
			if moved[i] >= moved[1 - i] * dominance:
				got = &"shake" if i == 0 else &"nod"
	if got != &"":
		for a in _axes:
			a.reset()
	return got


## The axis has moved: is this a new swing (its first, or a turn back of at least swing_deg from the
## furthest it got)? Keeps the last three swings' times.
func _step(a: _Axis) -> bool:
	if a.dir == 0:
		if absf(a.pos - a.extreme) < swing_deg:
			return false
		a.dir = 1 if a.pos > a.extreme else -1
	elif (a.pos - a.extreme) * a.dir > 0.0:
		a.extreme = a.pos
		return false
	elif absf(a.pos - a.extreme) >= swing_deg:
		a.dir = -a.dir
	else:
		return false
	a.extreme = a.pos
	a.marks.append(_t)
	a.odos.append(_odo)
	while a.marks.size() > 3:
		a.marks.pop_front()
		a.odos.pop_front()
	return true
