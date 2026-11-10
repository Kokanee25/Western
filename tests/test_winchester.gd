extends TestCase
## The Winchester 1873 (#734, #777): its mechanism as rules (the lever's stroke, full and half
## cock, the gate, the dust cover, the .44-40 shared with the revolver), the gun in the player's
## hands on the test street (out off its sling, the lever, the gate, a shot down the sights), its
## ball, and the rope it's for.

var street: Node3D
var player: Player


func after_each() -> void:
	for a in [&"fire", &"aim", &"cock", &"reload", &"holster", &"weapon_rifle"]:
		Input.action_release(a)
	if street:
		street.queue_free()
		street = null
	await physics_frames(2)


func _ready_state(s: Winchester73State) -> void:
	while not s.ready():
		s.tick(0.05)


# --- The mechanism -------------------------------------------------------------------------------

func test_given_with_the_tube_full_and_the_chamber_empty() -> void:
	var s := Winchester73State.new()
	check_eq(s.tube, 15, "15 in the tube")
	check_eq(s.chamber, Winchester73State.Round.EMPTY, "nothing chambered")
	check_eq(s.pull_trigger(), Winchester73State.Shot.NONE, "the hammer's down: the trigger does nothing")


func test_the_lever_chambers_a_round_and_cocks_it() -> void:
	var s := Winchester73State.new()
	check(s.work_lever(), "the lever opens")
	check(s.lever_open, "open")
	check_eq(s.hammer, Winchester73State.Hammer.FULL_COCK, "the bolt coming back cocks the hammer")
	check_eq(s.carrier, Winchester73State.Round.LOADED, "the carrier lifts the tube's first round")
	check_eq(s.tube, 14, "out of the tube")
	check(s.cover_open, "the dust cover rides back with the bolt")
	check_eq(s.pull_trigger(), Winchester73State.Shot.NONE, "no shot with the lever open")
	_ready_state(s)
	check(not s.lever_open, "the stroke comes home by itself")
	check_eq(s.chamber, Winchester73State.Round.LOADED, "chambered")
	check(s.ready_to_fire(), "ready")
	check_eq(s.pull_trigger(), Winchester73State.Shot.FIRED, "it fires")
	check_eq(s.chamber, Winchester73State.Round.SPENT, "the case stays till the lever")
	check_eq(s.hammer, Winchester73State.Hammer.DOWN, "the hammer fell")
	_ready_state(s)
	var thrown: Array[int] = []
	s.ejected.connect(func(r: int) -> void: thrown.append(r))
	s.work_lever()
	check_eq(thrown, [Winchester73State.Round.SPENT] as Array[int], "the spent case is thrown out")
	_ready_state(s)
	check_eq(s.chamber, Winchester73State.Round.LOADED, "the next one in")
	check_eq(s.rounds_loaded(), 14, "14 live left")


func test_sixteen_shots_then_clicks() -> void:
	var s := Winchester73State.new()
	s.tuning.misfire_chance = 0.0
	s.tube = 15
	var shots := 0
	for i in 20:
		_ready_state(s)
		s.work_lever()
		_ready_state(s)
		if s.pull_trigger() == Winchester73State.Shot.FIRED:
			shots += 1
	check_eq(shots, 15, "fifteen from the tube")
	# Topped up with one chambered, fifteen in the tube: sixteen.
	s.chamber = Winchester73State.Round.LOADED
	s.hammer = Winchester73State.Hammer.FULL_COCK
	s.tube = 15
	check_eq(s.rounds_loaded(), 16, "15 + 1")


func test_half_cock_is_the_safety() -> void:
	var s := Winchester73State.new()
	s.work_lever()
	_ready_state(s)
	check(s.half_cock(), "eased down to half cock")
	_ready_state(s)
	check_eq(s.pull_trigger(), Winchester73State.Shot.SAFE, "the notch holds: no shot")
	check_eq(s.chamber, Winchester73State.Round.LOADED, "still loaded")
	check(s.thumb_cock(), "thumbed back to full, no lever")
	_ready_state(s)
	check_eq(s.tube, 14, "the round stayed: no lever worked")
	check_eq(s.pull_trigger(), Winchester73State.Shot.FIRED, "and it fires")


func test_loading_through_the_gate_a_round_at_a_time() -> void:
	var s := Winchester73State.new()
	s.tube = 3
	s.pouch = 20
	var t0 := 0.0
	var n := 0
	while s.load_round():
		n += 1
		while not s.ready():
			s.tick(0.01)
			t0 += 0.01
	check_eq(n, 12, "topped up to 15")
	check_eq(s.tube, 15, "full")
	check_eq(s.pouch, 8, "from the pouch")
	check(not s.load_round(), "no more than 15")
	check_near(t0, s.tuning.turn_to_load_time + 12 * s.tuning.gate_round_time, 0.05, "the turn once, then each round")
	s.work_lever()
	check(not s.load_round(), "not with the lever open (the carrier's up over the gate)")


func test_shares_the_revolvers_cartridges() -> void:
	var r := RevolverState.new()
	var s := Winchester73State.new()
	s.shared = r
	s.tube = 10
	var belt := r.belt
	check(s.load_round(), "loads from the belt")
	check_eq(r.belt, belt - 1, "one less on the belt")
	check_eq(s.cartridges(), belt - 1, "the same count both ways")


func test_a_live_round_is_thrown_out_by_the_lever() -> void:
	var s := Winchester73State.new()
	s.work_lever()
	_ready_state(s)
	var thrown: Array[int] = []
	s.ejected.connect(func(r: int) -> void: thrown.append(r))
	s.work_lever()
	check_eq(thrown, [Winchester73State.Round.LOADED] as Array[int], "out goes the live one")
	_ready_state(s)
	check_eq(s.tube, 13, "and the next comes up")


func test_the_cover_shuts_by_hand() -> void:
	var s := Winchester73State.new()
	s.work_lever()
	_ready_state(s)
	check(s.cover_open, "open after the lever")
	s.set_cover(false)
	check(not s.cover_open, "slid shut")


# --- The ball and the rope -----------------------------------------------------------------------

func test_ball_is_a_44_40_from_a_rifle() -> void:
	var t: Winchester73Tuning = load("res://config/winchester73.tres")
	check_near(t.muzzle_velocity, 400.0, 15.0, "~400 m/s from 24\" (#734)")
	var e := 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity
	check(e > 900.0 and e < 1200.0, "~1,000 J at the muzzle (%.0f)" % e)


func test_rope_cut_by_its_share() -> void:
	var world := Node3D.new()
	add_child(world)
	var rope := HangingRope.new()
	rope.load_kg = 80.0
	world.add_child(rope)
	# Through its middle: about two thirds of a 3/4" rope; parts under a man.
	var cut := rope.take_ball(Vector3(-0.015, -1.0, 0.0), Vector3.RIGHT, 0.00545)
	check(cut > 0.55 and cut < 0.8, "a centred .44 ball takes ~2/3 (%.2f)" % cut)
	check(rope.is_parted, "and it parts under a man's weight")
	rope.mend()
	check(not rope.is_parted, "mended")
	# A graze at the edge: a sliver, it holds; a second graze in the same place parts it.
	var g := rope.take_ball(Vector3(-0.015, -1.0, 0.0125), Vector3.RIGHT, 0.00545)
	check(g > 0.0 and g < 0.3, "a graze takes a sliver (%.2f)" % g)
	check(not rope.is_parted, "it holds")
	rope.take_ball(Vector3(-0.015, -1.01, 0.004), Vector3.RIGHT, 0.00545)
	check(rope.is_parted, "a second in the same place parts it")
	# Past the edge (inside the pad): touched nothing.
	rope.mend()
	check_eq(rope.take_ball(Vector3(-0.015, -1.0, 0.0151), Vector3.RIGHT, 0.00545), 0.0, "past its edge")
	world.queue_free()


func test_a_ball_through_the_rope_parts_it() -> void:
	var world := Node3D.new()
	add_child(world)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var rope := HangingRope.new()
	rope.load_kg = 80.0
	world.add_child(rope)
	rope.position = Vector3(0.0, 3.0, -20.0)
	await physics_frames(2)
	var t: Winchester73Tuning = load("res://config/winchester73.tres")
	var exclude: Array[RID] = []
	ballistics.fire(Vector3(0.0, 2.0, 0.0), Vector3(0.0, 0.0, -1.0), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, exclude)
	await physics_frames(20)
	check(rope.hits == 1, "the ball met the rope")
	check(rope.is_parted, "and cut it through")
	world.queue_free()


# --- In the player's hands -----------------------------------------------------------------------

func _street() -> Winchester73Viewmodel:
	street = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	player = street.get_node(^"Player")
	await physics_frames(5)
	var w := player.winchester()
	w.needs_captured_mouse = false
	return w


func test_off_the_sling_lever_and_fire() -> void:
	var w := await _street()
	check(w != null, "the player has the rifle")
	check(not w.drawn, "slung to start")
	Input.action_press(&"weapon_rifle")
	await process_frames(2)
	Input.action_release(&"weapon_rifle")
	check(await wait_until(func() -> bool: return w.is_ready_in_hand(), 200), "off the sling and in both hands")
	check(w.why_not(&"fire") != "", "says why it won't fire with nothing chambered (%s)" % w.why_not(&"fire"))
	Input.action_press(&"cock")
	await process_frames(2)
	Input.action_release(&"cock")
	check(await wait_until(func() -> bool: return w.state.ready_to_fire() and w.state.ready(), 60), "Q works the lever: chambered and cocked")
	var shots := [0]
	Events.shot_fired.connect(func(_o: Vector3, _d: Vector3, _s: Node) -> void: shots[0] += 1)
	Input.action_press(&"fire")
	await process_frames(2)
	Input.action_release(&"fire")
	await physics_frames(4)
	check_eq(shots[0], 1, "it fired")
	check_eq(w.state.chamber, Winchester73State.Round.SPENT, "the case stays in")
	# Held with a round in and the hammer back: half cock, and the trigger won't.
	await process_frames(20)
	w.cock_press()
	await wait_until(func() -> bool: return w.state.ready_to_fire(), 60)
	await process_frames(10)
	Input.action_press(&"cock")
	await process_frames(int(w.tuning.half_cock_hold * 60.0) + 6)
	Input.action_release(&"cock")
	await process_frames(2)
	check_eq(w.state.hammer, Winchester73State.Hammer.HALF_COCK, "held Q eases it to half cock")
	check_eq(w.state.chamber, Winchester73State.Round.LOADED, "the round still in")
	await wait_until(func() -> bool: return w.state.ready(), 60)
	check_eq(w.pull_trigger(), Winchester73State.Shot.SAFE, "on half cock the trigger does nothing")
	check(w.why_not(&"fire").contains("half cock"), "and says so")


func test_gate_loading_in_hand() -> void:
	var w := await _street()
	player.select_weapon(w)
	await wait_until(func() -> bool: return w.is_ready_in_hand(), 200)
	w.state.tube = 10
	var belt := player.revolver().state.belt
	Input.action_press(&"reload")
	await wait_until(func() -> bool: return w.state.tube == 15, 60 * 8)
	Input.action_release(&"reload")
	check_eq(w.state.tube, 15, "held R pushes them in one by one to full")
	check_eq(player.revolver().state.belt, belt - 5, "from the revolver's belt")
	check(w.state.loading, "turned to the gate")
	await process_frames(2)
	w.reload_press()
	check(not w.state.loading, "a press with the tube full brings it back round")


func test_aimed_down_the_sights() -> void:
	var w := await _street()
	player.select_weapon(w)
	await wait_until(func() -> bool: return w.is_ready_in_hand(), 200)
	w.steady_hands = true
	Input.action_press(&"aim")
	check(await wait_until(func() -> bool: return w.is_shouldered(), 60), "shouldered")
	await process_frames(30)
	var cam := player.camera
	var rear := (w.model.markers["SightRear"] as Marker3D).global_position
	var front := (w.model.markers["SightFront"] as Marker3D).global_position
	var to_rear := cam.global_transform.affine_inverse() * rear
	var to_front := cam.global_transform.affine_inverse() * front
	# The notch and the blade both on your line of sight (the middle of the view), the notch ~38 cm out.
	check(Vector2(to_rear.x, to_rear.y).length() < 0.003, "the notch on your eye's line (%s)" % to_rear)
	check(Vector2(to_front.x, to_front.y).length() < 0.003, "the blade in the notch (%s)" % to_front)
	check_near(-to_rear.z, Winchester73Viewmodel.EYE_RELIEF, 0.02, "your eye ~38 cm behind the notch")
	Input.action_release(&"aim")
