class_name RoomReflections
extends ReflectionProbe
## A room's reflection probe (the saloon's brass, glass and tin see the room in it) taken again
## whenever the room's light changes: the lamps lit or put out, the sun up or down. Taken once at the
## build, the probe kept the room as it was then (the game starts at noon, its lamps out), so at
## night the brass gave back a dark room (light pass round 5: the critic's "dull dark blobs").
## Taking it costs a frame or two of the GPU's time, a few times a day at most. It also lights and
## puts out the lamps in the room's painted mirrors.

## The hour the lamps are lit from and put out at (SaloonDressing's lamps), and the sun's.
const LAMPS_FROM := 17
const LAMPS_UNTIL := 4
const SUN_FROM := 6
const SUN_UNTIL := 19

## The room's painted mirrors (mirror.gdshader): their lamps lit with the room's.
var mirrors: Array[ShaderMaterial] = []

var _state := -1


func _ready() -> void:
	update_mode = ReflectionProbe.UPDATE_ONCE
	Events.hour_changed.connect(_on_hour)
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle if is_inside_tree() else null
	_state = state(clock.get_hour()) if clock else -1
	_light_mirrors()


## Which light the room is in at this hour: the lamps' (bit 0) and the sun's (bit 1).
static func state(hour: int) -> int:
	var lamps := hour >= LAMPS_FROM or hour < LAMPS_UNTIL
	var sun := hour >= SUN_FROM and hour < SUN_UNTIL
	return int(lamps) | (int(sun) << 1)


func _on_hour(hour: int) -> void:
	var s := state(hour)
	if s == _state:
		return
	_state = s
	_light_mirrors()
	retake()


## Take the room again (after the lamps' own hour_changed has lit them: deferred a frame).
func retake() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	# UPDATE_ONCE takes it again when the probe changes: switched to always for a frame and back.
	update_mode = ReflectionProbe.UPDATE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		update_mode = ReflectionProbe.UPDATE_ONCE


func _light_mirrors() -> void:
	var lit := _state < 0 or bool(_state & 1)
	for m in mirrors:
		m.set_shader_parameter(&"glow", 1.0 if lit else 0.0)
