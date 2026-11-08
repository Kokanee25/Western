extends TestCase
## The restless pieces that keep a pile awake, held still (#585): a piece that has stayed where it
## is, with nothing given way near it, but still turns or jiggles, is frozen where it lies so Jolt
## can put the rest of its pile to sleep; moving pieces, quiet ones and anything near a break are
## left to Jolt; a held piece is let go, awake, the moment it's struck or something near it gives way.

var world: Node3D
var s: Structure


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = WorldBoundaryShape3D.new()
	ground.add_child(cs)
	world.add_child(ground)
	s = Structure.new()
	s.structure_id = &"rig"
	world.add_child(s)
	s.add_member("stud", &"post", &"framing", Vector3(0.1, 0.1, 1.2), Vector3(5, 0.3, 5))
	s.add_member("plank", &"post", &"framing", Vector3(0.1, 0.1, 1.2), Vector3(8, 0.3, 5))
	s.infer_supports()
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _sleeper() -> RubbleSleep:
	return world.get_node_or_null(^"RubbleSleep") as RubbleSleep


## Both members down as rubble, landed.
func _down() -> Array:
	s._drop([&"rig/stud", &"rig/plank"] as Array[StringName])
	var bodies := s.rubble.duplicate()
	await physics_frames(90)
	return bodies


## Looks a still spell apart, long after the drop's own wakes (`spin`: kept turning in place).
func _looks(spin: RigidBody3D = null, slide: RigidBody3D = null) -> void:
	var t := RubbleSleep._time() + RubbleSleep.QUIET_S + 1.0
	for i in 3:
		if spin:
			spin.sleeping = false
			spin.angular_velocity = Vector3(0, 3.0, 0)
		if slide:
			slide.sleeping = false
			slide.global_position += Vector3(0.1, 0, 0)
			slide.linear_velocity = Vector3(0.2, 0, 0)
		_sleeper().look(t + i * RubbleSleep.STILL_S)


func test_a_piece_turning_in_place_is_held_still() -> void:
	var bodies := await _down()
	check(_sleeper() != null, "a sleeper for the world")
	if _sleeper() == null:
		return
	var rb: RigidBody3D = bodies[0]
	_looks(rb)
	check(_sleeper().held(rb), "turning where it lies for a still spell: held")
	check(rb.freeze, "frozen where it lies")
	check(not _sleeper().held(bodies[1]), "the quiet one left to Jolt")
	var at := rb.global_position
	await physics_frames(30)
	check(rb.global_position.distance_to(at) < 0.001, "and it stays put")


func test_moving_and_quiet_pieces_are_left_to_jolt_till_kept_awake() -> void:
	var bodies := await _down()
	var rb: RigidBody3D = bodies[0]
	_looks(null, rb)
	check(not _sleeper().held(rb), "going somewhere: not held")
	var quiet: RigidBody3D = bodies[1]
	quiet.sleeping = false
	quiet.linear_velocity = Vector3.ZERO
	quiet.angular_velocity = Vector3.ZERO
	quiet.global_position += Vector3(0, 0, 0.1)  # (its still spell begins now)
	var t := RubbleSleep._time() + 10.0
	_sleeper().look(t)
	_sleeper().look(t + RubbleSleep.STILL_S)
	check(not _sleeper().held(quiet), "awake but not moving: left to sleep with its pile")
	check(not quiet.freeze, "not frozen")
	# Still awake long past that (something in its pile keeps Jolt from sleeping it, #647): held.
	quiet.sleeping = false
	_sleeper().look(t + RubbleSleep.STILL_S + RubbleSleep.QUIET_AWAKE_S + 0.1)
	check(_sleeper().held(quiet), "kept awake quiet past its spell: held")
	check(quiet.freeze, "frozen")


func test_nothing_is_held_near_a_break() -> void:
	var bodies := await _down()
	var rb: RigidBody3D = bodies[0]
	var t := RubbleSleep._time() + RubbleSleep.QUIET_S + 1.0
	# Something gave way next to it just before the looks.
	RubbleSleep.disturbed(s, rb.global_position + Vector3(0.5, 0, 0), 1.0)
	var key: Vector3i = _sleeper()._disturbed.keys()[_sleeper()._disturbed.size() - 1]
	_sleeper()._disturbed[key][2] = t  # (as if it gave way at the looks' time)
	for i in 3:
		rb.sleeping = false
		rb.angular_velocity = Vector3(0, 3.0, 0)
		_sleeper().look(t + i * RubbleSleep.STILL_S * 0.5)
	check(not _sleeper().held(rb), "turning near a break: left to Jolt")


func test_a_held_piece_is_let_go_when_struck() -> void:
	var bodies := await _down()
	var rb: RigidBody3D = bodies[0]
	_looks(rb)
	check(_sleeper().held(rb), "held")
	RubbleRest.let_go(rb)  # (as a ball, a blast or a shove does before it moves it)
	check(not _sleeper().held(rb), "let go")
	check(not rb.freeze, "a body again")
	check(not rb.sleeping, "and awake")
	var at := rb.global_position
	rb.apply_impulse(Vector3(3.0 * rb.mass, 0, 0))  # (3 m/s along the ground, the same tick)
	await physics_frames(10)
	check(rb.global_position.distance_to(at) > 0.1, "it moves when pushed")


func test_a_held_piece_is_let_go_when_something_near_gives_way() -> void:
	var bodies := await _down()
	var rb: RigidBody3D = bodies[0]
	_looks(rb)
	check(_sleeper().held(rb), "held")
	s._wake_near(rb.global_position + Vector3(0.5, 0, 0), 2.0)  # (a break beside it: what it lay on may be gone)
	check(not _sleeper().held(rb), "let go")
	check(not rb.freeze, "a body again")
	var t := RubbleSleep._time()
	for i in 3:  # (looks a still spell long, all within the quiet after it)
		rb.sleeping = false
		rb.angular_velocity = Vector3(0, 3.0, 0)
		_sleeper().look(t + i * RubbleSleep.STILL_S * 0.5)
	check(not _sleeper().held(rb), "and not held again till that's quiet")


func test_rubble_landing_on_a_held_piece_lets_it_go() -> void:
	var bodies := await _down()
	var rb: RigidBody3D = bodies[0]
	_looks(rb)
	check(_sleeper().held(rb), "held")
	var other: RigidBody3D = bodies[1]
	other.set_meta(&"v", Vector3(0, -6.0, 0))
	s._on_rubble_hit(rb, other)
	check(not _sleeper().held(rb), "a piece coming down on it lets it go")


## A piece knocked out of a pile held still lets go what's held lying on it or against it (#647:
## quiet pieces are held too now, so whole piles are; one shot out mustn't leave the rest hanging).
func test_a_held_piece_knocked_loose_lets_go_what_lies_against_it() -> void:
	var bodies := await _down()
	var rb: RigidBody3D = bodies[0]
	var other: RigidBody3D = bodies[1]
	# The two lying together, as in a pile (the plank against the stud's side).
	other.global_position = rb.global_position + Vector3(0, 0.12, 0)
	await physics_frames(30)
	var t := RubbleSleep._time() + RubbleSleep.QUIET_S + 1.0
	for i in 4:
		rb.sleeping = false
		rb.angular_velocity = Vector3(0, 3.0, 0)
		other.sleeping = false
		_sleeper().look(t + i * RubbleSleep.STILL_S)
	check(_sleeper().held(rb) and _sleeper().held(other), "both held (%s, %s)" % [_sleeper().held(rb), _sleeper().held(other)])
	RubbleRest.let_go(rb)
	check(not _sleeper().held(rb), "the one struck let go")
	check(not _sleeper().held(other), "and the one against it (%.2f m apart)" % rb.global_position.distance_to(other.global_position))
	check(not other.freeze, "a body again")
