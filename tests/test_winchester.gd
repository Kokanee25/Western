extends TestCase
## The Winchester 1873 (#734 step 2): the lever, the hammer, half cock, the gate, the dust cover,
## the .44-40 shared with the Colt, its model's parts moving by the rig, the player carrying it, and
## the rope its sights are for (Rope: cut by the band a ball sweeps, parted past half).

var world: Node3D
var ballistics: Ballistics


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	ballistics = Ballistics.new()
	world.add_child(ballistics)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _state(tube := 15) -> Winchester73State:
	var t := Winchester73Tuning.new()
	t.misfire_chance = 0.0
	t.start_tube = tube
	var s := Winchester73State.new(t, 1)
	s.own_belt = 20
	return s


## Run the clock till the hands are free.
static func _wait(s: Winchester73State) -> void:
	s.tick(10.0)


# --- The mechanism -------------------------------------------------------------------------------

func test_carried_tube_full_chamber_empty_hammer_down() -> void:
	var s := Winchester73State.new()
	check_eq(s.tube, 15, "fifteen in the tube")
	check_eq(s.chamber, Winchester73State.Round.EMPTY, "the chamber empty (carried safe)")
	check_eq(s.hammer, Winchester73State.Hammer.DOWN, "the hammer down")
	check_eq(s.pull_trigger(), Winchester73State.Shot.NONE, "the trigger does nothing on a hammer that's down")


func test_the_lever_chambers_a_round_and_cocks() -> void:
	var s := _state()
	var lifted := [0]
	s.lifted.connect(func() -> void: lifted[0] += 1)
	check(s.open_lever(), "the lever opens")
	check_eq(s.hammer, Winchester73State.Hammer.FULL_COCK, "the bolt cocks the hammer")
	check(s.cover_open, "the bolt pushes the dust cover back")
	check_eq(s.carrier, Winchester73State.Round.LOADED, "the carrier lifts a round")
	check_eq(s.tube, 14, "one out of the tube")
	check_eq(lifted[0], 1, "lifted once")
	check_eq(s.pull_trigger(), Winchester73State.Shot.NONE, "no firing with the lever open")
	_wait(s)
	check(s.close_lever(), "the lever closes")
	check_eq(s.chamber, Winchester73State.Round.LOADED, "the round's in the chamber")
	check_eq(s.carrier, Winchester73State.Round.EMPTY, "the carrier down for the next")
	_wait(s)
	check_eq(s.pull_trigger(), Winchester73State.Shot.FIRED, "fires at full cock")
	check_eq(s.chamber, Winchester73State.Round.SPENT, "a spent case in the chamber")
	check_eq(s.hammer, Winchester73State.Hammer.DOWN, "the hammer fell")
	_wait(s)
	check_eq(s.pull_trigger(), Winchester73State.Shot.NONE, "no second shot without the lever")


func test_the_lever_throws_out_what_is_in_the_chamber() -> void:
	var s := _state()
	var out: Array[int] = []
	s.ejected.connect(func(r: int) -> void: out.append(r))
	s.open_lever(); _wait(s); s.close_lever(); _wait(s)
	s.pull_trigger(); _wait(s)
	s.open_lever(); _wait(s)
	check_eq(out, [Winchester73State.Round.SPENT] as Array[int], "the spent case flies out")
	s.close_lever(); _wait(s)
	# Worked again without firing: the live round goes out too (it's how a lever gun is unloaded).
	s.open_lever(); _wait(s)
	check_eq(out.size(), 2, "a live round thrown out by the lever")
	check_eq(out[1], Winchester73State.Round.LOADED, "it was live")
	s.close_lever(); _wait(s)
	check_eq(s.tube, 12, "three lifted from the tube")


func test_sixteen_shots_then_click() -> void:
	var s := _state()
	s.tuning.start_chambered = false
	s.open_lever(); _wait(s); s.close_lever(); _wait(s)
	var shots := 0
	for i in 20:
		if s.pull_trigger() == Winchester73State.Shot.FIRED:
			shots += 1
		_wait(s)
		s.open_lever(); _wait(s); s.close_lever(); _wait(s)
	check_eq(shots, 15, "fifteen from a full tube, the chamber empty to start")
	var s2 := _state()
	s2.open_lever(); _wait(s2); s2.close_lever(); _wait(s2)
	s2.load_gate(); _wait(s2)
	check_eq(s2.rounds_ready(), 16, "fifteen in the tube and one up the spout")


func test_half_cock_is_the_safety() -> void:
	var s := _state()
	s.open_lever(); _wait(s); s.close_lever(); _wait(s)
	check(s.hammer_press(), "eased down")
	check_eq(s.hammer, Winchester73State.Hammer.HALF_COCK, "to half cock")
	_wait(s)
	check_eq(s.pull_trigger(), Winchester73State.Shot.NONE, "the trigger's dead at half cock")
	check_eq(s.chamber, Winchester73State.Round.LOADED, "still loaded")
	check(s.hammer_press(), "thumbed back")
	check_eq(s.hammer, Winchester73State.Hammer.FULL_COCK, "to full cock")
	_wait(s)
	check_eq(s.pull_trigger(), Winchester73State.Shot.FIRED, "and it fires")


func test_the_gate_takes_one_at_a_time_any_time() -> void:
	var s := _state(10)
	check(s.load_gate(), "a round through the gate")
	check_eq(s.tube, 11, "into the tube")
	check(not s.load_gate(), "one at a time: the hands are busy")
	_wait(s)
	s.open_lever()
	_wait(s)
	check(not s.load_gate(), "not with the lever open (the carrier's across the gate)")
	s.close_lever()
	_wait(s)
	while s.load_gate():
		_wait(s)
	check_eq(s.tube, 15, "topped up to fifteen")
	check(not s.reload_step(), "nothing to do with the tube full")
	check_eq(s.own_belt, 20 - 6, "six off the belt")


func test_shares_the_colts_belt() -> void:
	var colt := RevolverState.new()
	var s := _state(14)
	s.shares = colt
	var before := colt.belt
	check_eq(s.belt(), before, "the belt is the Colt's")
	check(s.load_gate(), "loads from it")
	check_eq(colt.belt, before - 1, "one fewer for the Colt")
	colt.belt = 0
	_wait(s)
	check(not s.load_gate(), "none left for either")


func test_the_dust_cover() -> void:
	var s := _state()
	check(not s.cover_open, "shut when carried")
	s.open_lever(); _wait(s)
	check(not s.close_cover(), "can't shut it over an open action")
	s.close_lever(); _wait(s)
	check(s.close_cover(), "slid shut")
	check(not s.cover_open, "it's shut")


# --- The model and the gun in your hands ---------------------------------------------------------

func test_the_model_has_its_parts_and_they_move() -> void:
	var m := Winchester73Model.new()
	world.add_child(m)
	for n in ["Receiver", "Barrel", "MagTube", "Lever", "Hammer", "Trigger", "Bolt", "Carrier", "DustCover", "Gate",
			"RearSight", "FrontSight", "Buttstock"]:
		check(m.parts.get(n) != null, "the model has its %s" % n)
	var bolt := m.parts["Bolt"] as Node3D
	var bolt0 := bolt.position
	m.lever(1.0)
	check_near(bolt.position.z - bolt0.z, 0.04699, 0.002, "the bolt goes back 1.85\" with the lever")
	check_near(rad_to_deg((m.parts["Lever"] as Node3D).basis.get_euler().x), 52.0, 0.5, "the lever throws 52 degrees")
	check(m.markers.has("SightRear") and m.markers.has("SightFront") and m.markers.has("Muzzle"), "its sights and muzzle are marked")
	check((m.marker("SightFront") - m.marker("SightRear")).length() > 0.45, "a long sight radius (~20\")")
	check(m.sling != null and m.sling.mesh != null, "it has a sling")


func test_the_player_carries_it_and_fires_a_44_40() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	var player: Player = street.get_node(^"Player")
	await physics_frames(5)
	var rifle := player.rifle()
	check(rifle != null, "the player has the rifle")
	check(rifle in player.weapons, "among the guns")
	rifle.needs_captured_mouse = false
	player.select_weapon(rifle)
	await wait_until(func() -> bool: return rifle.is_ready_in_hand(), 180)
	check(rifle.is_ready_in_hand(), "it comes off the sling into the hands")
	check(rifle.state.shares == player.revolver().state, "it shares the Colt's belt")
	check(rifle.why_not(&"fire") != "", "the hammer's down: it says why it won't fire")
	var shots: Array = []
	var balls: Array = []
	var on_shot := func(_o: Vector3, d: Vector3, _s: Node) -> void:
		shots.append(d)
		var bl := player.get_tree().get_first_node_in_group(&"ballistics") as Ballistics
		if bl and not bl.bullets.is_empty():
			balls.append([bl.bullets[-1].velocity.length(), bl.bullets[-1].mass])
	Events.shot_fired.connect(on_shot)
	rifle.work_lever()
	await wait_until(func() -> bool: return not rifle.state.lever_open and rifle.state.ready(), 120)
	check_eq(rifle.state.chamber, Winchester73State.Round.LOADED, "the lever chambered one")
	rifle.pull_trigger()
	await physics_frames(3)
	check_eq(shots.size(), 1, "it fired")
	Events.shot_fired.disconnect(on_shot)
	check_eq(balls.size(), 1, "one ball")
	if not balls.is_empty():
		check_near(balls[0][0], 400.0, 5.0, "a .44-40 from 24\": ~400 m/s")
		check_near(balls[0][1], 0.013, 0.0005, "a 200-grain bullet")
	await wait_until(func() -> bool: return rifle.state.ready(), 60)
	rifle.work_lever()
	await physics_frames(40)
	check(street.get_tree().get_nodes_in_group(&"spent_cases").size() > 0, "the case flew out of the port")
	street.queue_free()
	await physics_frames(2)


# --- The rope ------------------------------------------------------------------------------------

func test_rope_cut_share_by_where_the_ball_crosses() -> void:
	var r := 0.011
	var ball := 0.00545
	var middle := Rope.cut_share([Vector2(-ball, ball)], r)
	var edge := Rope.cut_share([Vector2(r - ball, r + ball)], r)
	check_near(middle, 0.61, 0.03, "through the middle ~three fifths")
	check(edge < 0.25 and edge > 0.1, "grazing the edge a fifth or less (%.2f)" % edge)
	check_near(Rope.cut_share([Vector2(-r, r)], r), 1.0, 0.001, "all of it")
	check_near(Rope.cut_share([Vector2(-r, 0.0), Vector2(-0.5 * r, r)], r), 1.0, 0.001, "overlapping cuts don't count twice")


func test_a_ball_through_the_middle_parts_a_hanging_rope() -> void:
	var rope := Rope.new()
	rope.position = Vector3(0, 4, 0)
	world.add_child(rope)
	var parted := [false]
	rope.parted.connect(func(_y: float) -> void: parted[0] = true)
	await physics_frames(2)
	var ex: Array[RID] = []
	ballistics.fire(Vector3(-30, 3.0, 0.0), Vector3.RIGHT, 400.0, 0.013, 0.0109, ex)
	await physics_frames(20)
	check_eq(rope.hits, 1, "the ball touched it")
	check(parted[0], "and it parted")
	var fell := world.find_child("RopeEnd", true, false) as RigidBody3D
	check(fell != null, "what was below falls")


func test_two_grazes_at_one_height_part_it_two_at_different_heights_dont() -> void:
	var rope := Rope.new()
	rope.swings = false
	world.add_child(rope)
	var one := rope.add_cut(1.0, 0.0105, 0.00545)
	check(one < 0.25, "one graze cuts a fifth (%.2f)" % one)
	var share := rope.add_cut(1.01, -0.0105, 0.00545)
	check(share > 0.35 and share < 0.5, "two at one height add up (%.2f)" % share)
	var other := rope.add_cut(1.4, 0.0, 0.00545)
	check(other > 0.55, "a fresh height is its own section (%.2f)" % other)
