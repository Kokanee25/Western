class_name PhysicsWindow
extends Node
## The frame split three ways for Prof (docs/briefs/more-cores.md, step 1): `window`, our scripts'
## physics ticks (from the first to tick to the last, by process_physics_priority); `step`, from
## the last to tick to the idle process (Jolt's step, and the deferred calls flushed after the
## ticks); `rest`, the remainder of the frame (the idle process, drawing, the engine). Two of these
## make a pair (`add_to`); they time only while Prof is on, and add each frame when the next starts.

const FIRST := -1000000
const LAST := 1000000

var _first := true
var _other: PhysicsWindow
var _start := 0
var _end := 0
var _idle := 0


## The pair, under `parent` (once: a second call finds the first's).
static func add_to(parent: Node) -> PhysicsWindow:
	var have := parent.get_node_or_null(^"PhysicsWindow") as PhysicsWindow
	if have:
		return have
	var first := PhysicsWindow.new()
	first.name = "PhysicsWindow"
	first.process_physics_priority = FIRST
	first.process_priority = FIRST
	var last := PhysicsWindow.new()
	last.name = "PhysicsWindowEnd"
	last._first = false
	last.process_physics_priority = LAST
	last.set_process(false)
	first._other = last
	parent.add_child(first)
	parent.add_child(last)
	return first


func _physics_process(_delta: float) -> void:
	if not Prof.on:
		_start = 0
		return
	var now := Time.get_ticks_usec()
	if not _first:
		_end = now
		return
	var end := _other._end
	if _start > 0 and end >= _start and _idle >= end:
		Prof.add(&"window", end - _start)
		Prof.add(&"step", _idle - end)
		Prof.add(&"rest", now - _idle)
	_start = now


func _process(_delta: float) -> void:
	if _first and Prof.on:
		_idle = Time.get_ticks_usec()
