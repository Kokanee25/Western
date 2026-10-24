class_name PlayerKick
extends Node
## Your kick (E; Sean, 2026-10-24: "a man or the player should be able to kick a chair's legs
## out"): a low kick with the right leg, its boot swept along in front of you at shin height. What
## it meets takes the blow: a kit prop's member through KitProp.take_blow (a chair's leg breaks and
## the boot goes on into the next in its way; a table's moves or holds), as a man's kick does
## (HumanBody.kick); a loose thing (a spittoon, a piece of wreck) is knocked along. Your visible
## leg (PlayerBody.kick) draws up and snaps out with it.

## Seconds: drawing the knee up, the snap out (the boot meets things here), and back.
const TIMES := [0.16, 0.07, 0.3]
## The boot's speed at the snap (m/s) and the leg's share of you behind it (kg): HumanBody's kick.
const SPEED := 9.0
const MASS := 8.0
## Where the boot sweeps: from this far ahead of you to this far, at this height (m), a boot wide.
const FROM := 0.2
const TO := 0.9
const HEIGHT := 0.12
const BOOT := 0.07

signal kicked(result: StringName, what: Node)

var player: Player
var _t := -1.0
var _struck := false


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if _t < 0.0:
		if player.input_enabled and Input.is_action_just_pressed(&"kick") and player.is_on_floor():
			_t = 0.0
			_struck = false
		return
	_t += delta
	var t0: float = TIMES[0]
	var t1: float = t0 + TIMES[1]
	var t2: float = t1 + TIMES[2]
	var k := 0.0
	if _t < t0:
		k = 0.5 * smoothstep(0.0, 1.0, _t / t0)
	elif _t < t1:
		k = 0.5 + 0.5 * (_t - t0) / TIMES[1]
		if not _struck:
			_struck = true
			_strike()
	else:
		k = 1.0 - smoothstep(0.0, 1.0, (_t - t1) / TIMES[2])
	player.body.kick = k
	if _t >= t2:
		player.body.kick = 0.0
		_t = -1.0


## The boot's sweep ahead of you: the first thing on the world in its way takes the blow.
func _strike() -> void:
	var fwd := -player.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var start := player.global_position + fwd * FROM + Vector3.UP * HEIGHT
	var ball := SphereShape3D.new()
	ball.radius = BOOT
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = ball
	q.transform = Transform3D(Basis(), start)
	q.motion = fwd * (TO - FROM)
	q.collision_mask = Layers.WORLD
	q.exclude = [player.get_rid()]
	var space := player.get_world_3d().direct_space_state
	var frac := space.cast_motion(q)
	if frac.size() < 2 or frac[1] >= 1.0:
		kicked.emit(&"", null)
		return
	q.transform = Transform3D(Basis(), start + q.motion * frac[1])
	q.motion = Vector3.ZERO
	var rest := space.get_rest_info(q)
	if rest.is_empty():
		kicked.emit(&"", null)
		return
	var hit: Object = instance_from_id(int(rest.collider_id))
	var at: Vector3 = rest.point
	var blow := fwd * SPEED * MASS
	var result := &"held"
	if hit is StructureMember and (hit as Node).get_parent() and (hit as Node).get_parent().has_method(&"take_blow"):
		result = (hit as Node).get_parent().call(&"take_blow", hit, at, blow, MASS)
	elif hit is RigidBody3D:
		# A loose thing: knocked along, at most at the boot's speed.
		var rb := hit as RigidBody3D
		rb.apply_impulse(blow.limit_length(rb.mass * SPEED), at - rb.global_position)
		result = &"moved"
	kicked.emit(result, hit as Node)
