class_name WorkBudget
extends RefCounted
## One frame's budget for work spread over frames: `ms` of the wall clock, or under
## `World.deterministic` `units` of the work itself (members analysed, batches built), so how far
## a collapse gets on a tick doesn't depend on the machine. The counts are set to about what the
## milliseconds buy on this workspace's 2.1 GHz core.

var _t0 := Time.get_ticks_usec()
var _ms: float
var _units: int
var _spent := 0


func _init(ms: float, units: int) -> void:
	_ms = ms
	_units = units


## `n` units of work done.
func spend(n := 1) -> void:
	_spent += n


func over() -> bool:
	if World.deterministic:
		return _spent > _units
	return (Time.get_ticks_usec() - _t0) / 1000.0 > _ms
