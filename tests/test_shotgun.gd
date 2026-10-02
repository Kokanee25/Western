extends TestCase
## The coach gun: two barrels, two hammers, break open to load; a charge of buckshot is nine
## pellets each flown on its own, spreading with range. Across a room they make separate small
## wounds; at point blank they arrive as one mass and destroy the region (ribs smashed and thrown
## out, the chest open). The player switches between it and the revolver.

var world: Node3D
var ballistics: Ballistics
var man: HumanBody
var rng := RandomNumberGenerator.new()
var near_misses := 0


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	rng.seed = 5
	near_misses = 0
	Events.near_miss.connect(_on_near_miss)


func after_each() -> void:
	Events.near_miss.disconnect(_on_near_miss)
	for a in [&"fire", &"cock", &"reload", &"weapon_shotgun", &"weapon_revolver"]:
		Input.action_release(a)
	world.queue_free()
	await physics_frames(2)


func _on_near_miss(_person: Node, _shooter: Node, _d: float, _at: Vector3, _speed: float, _tumbling: bool) -> void:
	near_misses += 1


func _add_man() -> void:
	man = HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	await physics_frames(2)


func _charge(from: Vector3, to: Vector3) -> Array[Ballistics.Bullet]:
	var t: ShotgunTuning = load("res://config/shotgun.tres")
	var exclude: Array[RID] = []
	return ballistics.fire_charge(from, (to - from).normalized(), t.pellets, deg_to_rad(t.pattern_degrees),
			t.muzzle_velocity, t.pellet_mass, t.pellet_diameter, exclude, rng, t.blast_joules, t.blast_reach)


func _all_done(pellets: Array[Ballistics.Bullet]) -> bool:
	for p in pellets:
		if p.alive:
			return false
	return true


# --- The mechanism -------------------------------------------------------------------------------

func test_two_hammers_two_barrels() -> void:
	var s := ShotgunState.new()
	check_eq(s.shells_loaded(), 2, "starts with both barrels loaded")
	check_eq(s.pull_trigger(), ShotgunState.Shot.NONE, "nothing until a hammer's back")
	check_eq(s.cock(), 0, "right hammer first")
	s.tick(1.0)
	check_eq(s.cock(), 1, "then the left")
	s.tick(1.0)
	check_eq(s.cock(), -1, "no third hammer")
	check_eq(s.pull_trigger(), ShotgunState.Shot.FIRED, "right barrel fires")
	check_eq(s.last_barrel, 0, "it was the right")
	s.tick(1.0)
	check_eq(s.pull_trigger(), ShotgunState.Shot.FIRED, "left barrel fires")
	s.tick(1.0)
	s.cock()
	s.tick(1.0)
	check_eq(s.pull_trigger(), ShotgunState.Shot.CLICK, "then it's empty")


func test_the_loaded_barrel_goes_first() -> void:
	var s := ShotgunState.new()
	s.barrels[0] = ShotgunState.Barrel.SPENT
	s.cock()
	s.tick(1.0)
	s.cock()
	s.tick(1.0)
	check_eq(s.pull_trigger(), ShotgunState.Shot.FIRED, "you pull the trigger that'll fire")
	check_eq(s.last_barrel, 1, "the left")


func test_break_open_and_reload() -> void:
	var s := ShotgunState.new()
	s.barrels.assign([ShotgunState.Barrel.SPENT, ShotgunState.Barrel.DUD])
	s.cock()
	s.tick(1.0)
	var pocket := s.pocket
	var counts := {"extracted": 0, "loaded": 0}
	s.extracted.connect(func(_i: int, _b: int) -> void: counts.extracted += 1)
	s.loaded.connect(func(_i: int) -> void: counts.loaded += 1)
	var steps := 0
	while s.reload_step():
		s.tick(1.0)
		steps += 1
		if steps > 10:
			break
	check(s.open, "it's open")
	check(not s.cocked_hammers.has(true), "opening let the hammers down")
	check_eq(counts.extracted, 2, "both empties pulled")
	check_eq(counts.loaded, 2, "two fresh shells in")
	check_eq(s.pocket, pocket - 2, "out of the pocket")
	check(s.close_action(), "closes")
	check_eq(s.shells_loaded(), 2, "loaded")


func test_empty_pockets_stop_loading() -> void:
	var s := ShotgunState.new()
	s.pocket = 0
	s.barrels.assign([ShotgunState.Barrel.SPENT, ShotgunState.Barrel.SPENT])
	while s.reload_step():
		s.tick(1.0)
	check_eq(s.shells_loaded(), 0, "nothing to load")


func test_state_round_trips() -> void:
	var s := ShotgunState.new()
	s.cock()
	s.barrels[1] = ShotgunState.Barrel.SPENT
	s.pocket = 3
	var t := ShotgunState.new()
	t.from_dict(s.to_dict())
	check_eq(t.to_dict(), s.to_dict(), "same after a round trip")


# --- The charge ----------------------------------------------------------------------------------

func test_the_pattern_opens_with_range() -> void:
	# Buckshot from a worn cylinder bore: well over a metre across at 25 m.
	var inside := 0
	var total := 0
	var widest := 0.0
	for k in 40:
		var pellets := _charge(Vector3.ZERO, Vector3(0, 0, -25))
		for p in pellets:
			var at25 := p.velocity.normalized() * (25.0 / absf(p.velocity.normalized().z))
			var off := Vector2(at25.x, at25.y).length()
			widest = maxf(widest, off)
			total += 1
			if off < 0.5:
				inside += 1
		ballistics.bullets.clear()
	var share := float(inside) / total
	check(share > 0.45 and share < 0.8, "%.0f%% of pellets inside 0.5 m at 25 m" % (share * 100.0))
	check(widest < 1.1, "the flyers stay within a metre or so (%.2f m)" % widest)


func test_pellets_slow_in_the_air() -> void:
	var pellets := _charge(Vector3(0, 50, 0), Vector3(0, 50, -100))
	var e0 := pellets[0].energy()
	await wait_until(func() -> bool: return pellets[0].position.z < -25.0, 60)
	var kept := pellets[0].energy() / e0
	# Round balls just over the speed of sound drag hard: 00 buck keeps about two thirds of its
	# energy over 25 m.
	check(kept > 0.55 and kept < 0.75, "a pellet keeps %.0f%% of its energy at 25 m" % (kept * 100.0))


func test_at_twenty_metres_a_charge_rarely_drops_him() -> void:
	# Sean: "long range shooting guys and dropping them in one shot". Across the street, a charge
	# should wound, not fell.
	var down := 0
	var hits := []
	var n := 16
	for k in n:
		await _add_man()
		var chest := (man.parts[&"chest"] as Node3D).global_position
		var pellets := _charge(chest + Vector3(0, 0, -20), chest)
		await wait_until(func() -> bool: return _all_done(pellets), 90)
		await physics_frames(30)
		var got := man.wounds.filter(func(w: Dictionary) -> bool: return w.kind == &"pellet").size()
		hits.append(got)
		if man.limp or not man.physiology.alive:
			down += 1
		man.queue_free()
		await physics_frames(1)
	print("  pellets on him from 20 m: %s; down %d of %d" % [hits, down, n])
	check(down <= n / 2, "down from one charge at 20 m: %d of %d" % [down, n])


func test_nine_separate_pellets() -> void:
	var pellets := _charge(Vector3.ZERO, Vector3(0, 0, -10))
	check_eq(pellets.size(), 9, "nine 00 buck")
	check(pellets[0].passed == pellets[8].passed, "they share who they've cracked past")
	check_near(pellets[0].energy(), 233.0, 25.0, "~230 J each (3.5 g at 365 m/s)")


func test_a_charge_cracks_past_once() -> void:
	await _add_man()
	man.add_to_group(&"people")
	var head := man.global_position + Vector3.UP * 1.5
	var pellets := _charge(head + Vector3(1.2, 0, -10), head + Vector3(1.2, 0, 10))
	await wait_until(func() -> bool: return _all_done(pellets), 90)
	check_eq(near_misses, 1, "one near miss for the whole charge")


# --- On a body -----------------------------------------------------------------------------------

func test_across_the_room_separate_small_wounds() -> void:
	await _add_man()
	var chest := (man.parts[&"chest"] as Node3D).global_position
	var pellets := _charge(chest + Vector3(0, 0, -7), chest)
	await wait_until(func() -> bool: return _all_done(pellets), 60)
	var pellet_wounds := man.wounds.filter(func(w: Dictionary) -> bool: return w.kind == &"pellet")
	check(pellet_wounds.size() >= 3, "several pellets hit (%d)" % pellet_wounds.size())
	var destroyed := false
	for seg: StringName in man.openings:
		for o: Dictionary in man.openings[seg]:
			destroyed = destroyed or o.get("destroyed", false)
	check(not destroyed, "nothing destroyed from 7 m")
	check(get_tree().get_nodes_in_group(&"bone_fragments").is_empty(), "no bone thrown")
	var lines := man.describe_wounds()
	check(" ".join(lines).contains("buckshot"), "the doctor sees buckshot: %s" % "; ".join(lines))


func test_point_blank_destroys_the_region() -> void:
	await _add_man()
	var chest := (man.parts[&"chest"] as Node3D).global_position + Vector3(0.05, 0.02, 0.0)
	# The muzzle a hand's breadth off his shirt.
	var pellets := _charge(chest + Vector3(0, 0, -0.25), chest)
	await wait_until(func() -> bool: return _all_done(pellets), 60)
	var biggest := {}
	for o: Dictionary in man.openings.get(&"chest", []):
		if biggest.is_empty() or o.radius > biggest.radius:
			biggest = o
	check(not biggest.is_empty() and biggest.get("destroyed", false), "the chest is destroyed (%.0f J)" % biggest.get("energy", 0.0))
	check(biggest.get("radius", 0.0) > 0.05, "a hole a hand across or more (%.1f cm radius)" % (biggest.get("radius", 0.0) * 100.0))
	check(man.physiology.broken.has(&"ribs_r"), "ribs smashed")
	var fragments := get_tree().get_nodes_in_group(&"bone_fragments")
	check(fragments.size() >= 3, "bone thrown out (%d pieces)" % fragments.size())
	for f: Node in fragments:
		check((f as RigidBody3D).collision_layer == Layers.DEBRIS, "fragments are debris")
		break
	check(man.physiology.lung_damage.has(&"lung_r"), "the open chest takes the lung")
	check(" ".join(man.describe_wounds()).contains("torn wide open"), "the doctor sees it")


func test_a_revolver_ball_never_destroys() -> void:
	await _add_man()
	var t: RevolverTuning = load("res://config/revolver.tres")
	var chest := (man.parts[&"chest"] as Node3D).global_position
	var b := ballistics.fire(chest + Vector3(0.04, 0, -0.2), Vector3.BACK, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 30)
	for o: Dictionary in man.openings.get(&"chest", []):
		check(not o.get("destroyed", false), "one ball point blank opens him but doesn't destroy (%.0f J)" % o.energy)
	check(get_tree().get_nodes_in_group(&"bone_fragments").is_empty(), "no bone thrown")


# --- In the player's hands ------------------------------------------------------------------------

func test_player_switches_to_the_shotgun_and_fires() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	# A board 6 m in front to catch the charge.
	var board := StaticBody3D.new()
	var bs := CollisionShape3D.new()
	var bb := BoxShape3D.new()
	bb.size = Vector3(3, 3, 0.1)
	bs.shape = bb
	board.add_child(bs)
	board.position = Vector3(0, 1.5, -6)
	world.add_child(board)
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	await physics_frames(3)
	var sg := player.shotgun()
	var rev := player.revolver()
	check(sg != null and not sg.visible, "the shotgun's there, put away")
	check(player.weapon == rev, "revolver in hand to start")
	Input.action_press(&"weapon_shotgun")
	await physics_frames(1)
	Input.action_release(&"weapon_shotgun")
	await wait_until(func() -> bool: return sg.is_ready_in_hand(), 180)
	check(player.weapon == sg and sg.is_ready_in_hand(), "shotgun in hand")
	check(not rev.drawn, "revolver back in the holster")
	sg.needs_captured_mouse = false
	var hits := []
	var on_hit := func(info: Dictionary) -> void: hits.append(info)
	Events.bullet_hit.connect(on_hit)
	# No misfire today (it's seeded from the node's path, which moves as tests are added).
	sg.state.tuning = sg.state.tuning.duplicate()
	sg.state.tuning.misfire_chance = 0.0
	sg.state.cock()
	sg.state.tick(1.0)
	sg.pull_trigger()
	await physics_frames(20)
	Events.bullet_hit.disconnect(on_hit)
	check(hits.size() >= 7, "the charge hit the board (%d pellets)" % hits.size())
	check_eq(sg.state.barrels[0], ShotgunState.Barrel.SPENT, "right barrel spent")
	var smokes := world.find_children("*", "GunSmoke", true, false)
	check(smokes.size() >= 1, "smoke")
	# And back.
	Input.action_press(&"weapon_revolver")
	await physics_frames(1)
	Input.action_release(&"weapon_revolver")
	await wait_until(func() -> bool: return rev.is_ready_in_hand(), 180)
	check(player.weapon == rev and not sg.visible, "revolver back out, shotgun away")
