extends TestCase
## A man in the world: real bullets from Ballistics go through his clothes and anatomy, leave
## wounds where they went in, drop him when he can't stand, take fingers and the gun off him.

var world: Node3D
var ballistics: Ballistics
var man: HumanBody
var body_hits: Array[Dictionary] = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	man = HumanBody.new()
	man.name = "Outlaw"
	world.add_child(man)
	body_hits.clear()
	Events.body_hit.connect(_on_body_hit)
	await physics_frames(2)


func after_each() -> void:
	Events.body_hit.disconnect(_on_body_hit)
	world.queue_free()
	await physics_frames(1)


func _on_body_hit(info: Dictionary) -> void:
	body_hits.append(info)


## Fire a .45 from `from` towards `to` (world points) and wait for it to finish.
func _shoot(from: Vector3, to: Vector3) -> Ballistics.Bullet:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (to - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	return b


## A .45 ball from the revolver arriving at `at` on `seg` going `dir`, this tick (the clock of what
## follows starts at the hit; _shoot waits for the ball to be spent).
func _ball(seg: StringName, at: Vector3, dir: Vector3) -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	man.take_bullet(man.parts[seg], at - dir * 0.15, dir, 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity,
			t.bullet_diameter * 0.5, t.bullet_mass, 5.0)


## Where a rest-pose point on a segment is now, in the world (he's posed, arms not hanging straight).
func _world(seg: StringName, rest: Vector3) -> Vector3:
	var part: Node3D = man.parts[seg]
	return part.global_transform * (rest - man.anatomy.segment_center(seg))


func test_built_from_the_anatomy() -> void:
	check_eq(man.parts.size(), 17, "a hitbox per segment")
	check_eq(man.fingers.size(), 10, "ten fingers")
	check_eq((man.finger_bones[&"index_r"] as Array).size(), 3, "three bones a finger")
	check(man.held_gun != null, "holding a revolver")
	check_eq(man.outer_garment(&"chest").id, &"vest", "vest over the shirt")
	check_eq(man.outer_garment(&"head"), {}, "bare head skin (hat's just a hat)")


func test_leg_shot_through_the_clothes() -> void:
	await _shoot(Vector3(0.07, 0.7, -6), Vector3(0.07, 0.7, 0))
	check_eq(body_hits.size(), 1, "one body hit")
	if body_hits.is_empty():
		return
	check_eq(body_hits[0].segment, &"thigh_r", "in the right thigh")
	check(man.physiology.cut.has(&"femoral_r"), "femoral artery cut")
	check_eq(man.wounds.size(), 1, "one wound recorded")
	check(man.wounds[0].garments.has(&"trousers"), "through the trousers")
	check(not man.limp, "still standing for now")
	var stain: Decal = man.wounds[0].stain
	var before := stain.size.x
	man.physiology.step(30.0)
	await physics_frames(2)
	check(stain.size.x > before * 1.5, "blood spreads through the trousers (%.2f -> %.2f m)" % [before, stain.size.x])


func test_ball_goes_through_into_whatever_is_behind() -> void:
	var backstop := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.3)
	shape.shape = box
	backstop.add_child(shape)
	backstop.position = Vector3(0, 1, 3)
	world.add_child(backstop)
	await physics_frames(2)
	var at := _world(&"forearm_r", man.anatomy.segment_center(&"forearm_r"))
	var b := await _shoot(at + Vector3(0, 0, -6), at)
	check(body_hits.size() >= 1 and body_hits[0].segment == &"forearm_r", "through the forearm")
	check(b.hits.size() >= 2, "and on into something else (%d hits)" % b.hits.size())


func test_head_shot_drops_him() -> void:
	await _shoot(Vector3(0, 1.64, -6), Vector3(0, 1.64, 0))
	check(not man.physiology.alive, "dead")
	await physics_frames(3)
	check(man.limp, "limp")
	await physics_frames(120)
	var chest: RigidBody3D = man.parts[&"chest"]
	check(chest.global_position.y < 0.6, "on the ground (chest at %.2f m)" % chest.global_position.y)


func test_broken_leg_drops_him_but_he_lives() -> void:
	await _shoot(Vector3(6, 0.7, 0.0), Vector3(0, 0.7, 0.0))
	check(man.physiology.broken.has(&"femur_r"), "femur broken")
	await physics_frames(2)
	check(man.limp and man.physiology.is_conscious(), "down, but awake")


func test_shot_off_finger_falls() -> void:
	var st := man.anatomy.structure(&"index_r")
	var at := _world(&"hand_r", st.a.lerp(st.b, 0.75))
	var side: Vector3 = (man.parts[&"hand_r"] as Node3D).global_basis.x
	await _shoot(at + side * 6.0, at)
	check(man.physiology.lost_fingers.has(&"index_r"), "index finger off")
	check(not man.fingers.has(&"index_r"), "gone from the hand")
	var bits := get_tree().get_nodes_in_group(&"severed_parts")
	check_eq(bits.size(), 1, "one finger lying about")


func test_arm_shot_drops_the_gun() -> void:
	man.draw_gun()  # in his hand (a holstered gun stays in its holster)
	await physics_frames(2)
	await _shoot(Vector3(0.21, 1.3, -6), Vector3(0.21, 1.3, 0))
	check(man.physiology.broken.has(&"humerus_r"), "upper arm broken")
	await physics_frames(2)
	check(man.held_gun == null, "gun dropped")
	check_eq(get_tree().get_nodes_in_group(&"dropped_guns").size(), 1, "it's on the ground")


func test_turned_body_still_hits_the_right_place() -> void:
	man.rotation_degrees.y = 90.0  # now facing -X
	await physics_frames(2)
	await _shoot(Vector3(-6, 0.7, -0.07), Vector3(0, 0.7, -0.07))
	check(body_hits.size() == 1 and body_hits[0].segment == &"thigh_r", "right thigh from his front")
	check(man.physiology.cut.has(&"femoral_r"), "femoral again")


func test_wounds_are_saved() -> void:
	await _shoot(Vector3(0.07, 0.7, -6), Vector3(0.07, 0.7, 0))
	var d := man.to_dict()
	check_eq(d.wounds.size(), 1, "the wound")
	check((d.garment_holes.trousers as Array).size() == 1, "the hole in his trousers")
	check(d.physiology.cut.has(&"femoral_r"), "and what it cut")


func test_neck_artery_spurts_and_leaves_splats() -> void:
	Blood.clear()
	var at := _world(&"neck", Vector3(0.03, 1.5, -0.02))
	await _shoot(at + Vector3(6, 0, 0), at)
	var jets := man.find_children("*", "BloodJet", true, false)
	check(jets.size() >= 1, "blood coming out of the neck (%d jets)" % jets.size())
	if jets.is_empty():
		return
	await physics_frames(10)
	var spurting := false
	for j: BloodJet in jets:
		var r := j.rates()
		if r[&"artery"] > 1.0 or r[&"vein"] > 1.0:
			spurting = true
	check(spurting, "pumping, not oozing")
	await wait_until(func() -> bool: return get_tree().get_nodes_in_group(&"blood_splats").size() > 0, 60 * 6)
	check(get_tree().get_nodes_in_group(&"blood_splats").size() > 0, "and it lands on the ground")


func test_through_and_through_spatters_the_wall_behind() -> void:
	Blood.clear()
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.2)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 1.5, 1.2)
	world.add_child(wall)
	await physics_frames(2)
	var at := _world(&"forearm_r", man.anatomy.segment_center(&"forearm_r"))
	await _shoot(at + Vector3(0, 0, -6), at)
	var on_wall := 0
	for d: Node3D in get_tree().get_nodes_in_group(&"blood_splats"):
		if d.global_position.z > 1.0:
			on_wall += 1
	check(on_wall > 0, "blood on the wall behind him (%d splats)" % on_wall)


func test_xray_shows_the_anatomy() -> void:
	await _shoot(Vector3(0.07, 0.7, -6), Vector3(0.07, 0.7, 0))
	man.set_xray(true)
	var shown := 0
	for sid: StringName in man.visuals:
		var x := (man.visuals[sid] as Node3D).get_node_or_null(^"XRay")
		if x:
			shown += x.get_child_count()
	check(shown >= man.anatomy.structures.size(), "every structure drawn, plus the ball's track (%d)" % shown)
	man.set_xray(false)
	check((man.visuals[&"chest"] as Node3D).get_node_or_null(^"XRay") == null, "and off again")


## How far the knee is bent (degrees, signed about his right).
func _knee_bend(man: HumanBody, side: String) -> float:
	var thigh := man.parts[StringName("thigh_" + side)] as Node3D
	var shin := man.parts[StringName("shin_" + side)] as Node3D
	var right := thigh.global_basis.x.normalized()
	var a := -thigh.global_basis.y.normalized()
	var b := -shin.global_basis.y.normalized()
	return rad_to_deg(a.signed_angle_to(b, right))


## Shot dead running (Sean: "as real as possible so just drops if dead esp running"): he goes on
## over his legs and down on his front, not down onto his knees. Before the stance leg held for an
## instant, a running man killed folded one knee right under him (150 deg by 0.4 s) and knelt.
func test_killed_running_he_pitches_over_not_onto_his_knees() -> void:
	for n in 4:
		var runner := HumanBody.new()
		runner.has_gun = false
		world.add_child(runner)
		runner.global_position = Vector3(-15.0 + n * 4.0, 0.0, 15.0)
		await physics_frames(2)
		var target := runner.global_position + Vector3(0, 0, -30)
		# Four points in his stride (the lab's group J: 1.5 to 1.95 s of running).
		for i in 90 + n * 9:
			runner.walk_to(target, 3.5, 1.0 / 60.0)
			await physics_frames(1)
		var died_at := runner.global_position
		runner.physiology._die(&"brain")
		runner.go_limp()
		await physics_frames(24)
		var r := _knee_bend(runner, "r")
		var l := _knee_bend(runner, "l")
		print("  stride %d: knees at 0.4 s %.0f / %.0f" % [n, l, r])
		check(absf(r) < 100.0 and absf(l) < 100.0,
				"stride %d: he didn't drop onto his knees (knees %.0f / %.0f at 0.4 s)" % [n, l, r])
		await physics_frames(150)
		var chest := (runner.parts[&"chest"] as Node3D).global_position
		check(chest.y < 0.35, "stride %d: he's down (chest %.2f m up)" % [n, chest.y])
		check(died_at.z - chest.z > 1.0, "stride %d: he went on forwards (%.2f m)" % [n, died_at.z - chest.z])
		runner.queue_free()


## Dropped by a ball, he looks hit, not fainted: he doubles over a belly wound, and a shot leg goes
## from under him so he leans to that side. (Before, every knockdown was the same faint: he stood
## stiff, leant back, then sank.) His own muscles do it (HumanBody._hunch): no push.
func test_a_ball_that_drops_him_shows_where_it_hit() -> void:
	var lean := {}
	for case: String in ["belly", "thigh_r"]:
		var shot := HumanBody.new()
		shot.has_gun = false
		world.add_child(shot)
		shot.global_position = Vector3(-6.0 if case == "belly" else 6.0, 0.0, 6.0)
		await physics_frames(30)
		var seg := &"abdomen" if case == "belly" else &"thigh_r"
		var part := shot.parts[seg] as Node3D
		var front := part.global_position - shot.global_basis.z * 0.1
		shot.go_limp()
		var dir := shot.global_basis.z
		(shot.parts[seg] as RigidBody3D).apply_impulse(dir * 4.5, front - part.global_position)
		shot._hunch(seg, front, dir)
		await physics_frames(27)
		var up := (shot.parts[&"chest"] as Node3D).global_basis.y
		# Forward is his -z, his right +x.
		lean[case] = Vector2(rad_to_deg(asin(clampf(up.dot(-shot.global_basis.z), -1.0, 1.0))),
				rad_to_deg(asin(clampf(up.dot(shot.global_basis.x), -1.0, 1.0))))
		shot.queue_free()
	print("  at 0.45 s: belly-shot chest %.0f deg forward; thigh-shot chest %.0f deg to his right" % [lean.belly.x, lean.thigh_r.y])
	check(lean.belly.x > 10.0, "doubled over the belly wound (%.0f deg forward)" % lean.belly.x)
	check(lean.thigh_r.y > 5.0, "the shot leg gave and he leans to it (%.0f deg)" % lean.thigh_r.y)


## Shot down walking, he doesn't drop in his tracks: his stride carries him on a step or so as he
## folds round it, then his legs go (Sean, 2026-10-16: "walking stumble"). Before, he dropped where
## the ball found him, knees first. Hit again as he stumbles, he's down at once.
func test_shot_down_walking_he_stumbles_on_a_step_then_drops() -> void:
	for again in [false, true]:
		var walker := HumanBody.new()
		walker.has_gun = false
		world.add_child(walker)
		walker.global_position = Vector3(-8.0 if again else 8.0, 0.0, 15.0)
		await physics_frames(2)
		var target := walker.global_position + Vector3(0, 0, -30)
		for i in 90:
			walker.walk_to(target, 1.4, 1.0 / 60.0)
			await physics_frames(1)
		var hit_at := walker.global_position
		var chest := walker.parts[&"chest"] as Node3D
		walker._knocked(&"chest", chest.global_position - walker.global_basis.z * 0.12, walker.global_basis.z, 4.5)
		if again:
			check(not walker.limp and walker.stumbling > 0.0, "he stumbles on")
			await physics_frames(6)
			walker._fall_now()
			check(walker.limp, "hit again as he stumbles, he's down at once")
			walker.queue_free()
			continue
		check(not walker.limp, "not down the instant he's hit")
		# He isn't thrown back by it, he folds over it (Sean: the chest shots were "too quickly
		# pushed back before falling", the flinch threw his chest back 45 degrees; then "still too
		# much of a super fast backwards jerk" at 4 degrees in one tick).
		var back := 0.0
		for i in 9:
			await physics_frames(1)
			var up := (walker.parts[&"chest"] as Node3D).global_basis.y
			back = maxf(back, rad_to_deg(asin(clampf(up.dot(walker.global_basis.z), -1.0, 1.0))))
		print("  chest back at most %.0f deg in the first 0.15 s" % back)
		check(back < 2.0, "not jerked back (%.0f deg)" % back)
		# Anyone else's walking doesn't move him now: his last steps are his body's.
		var before := walker.global_position
		walker.stumbling = maxf(walker.stumbling, 0.1)
		walker.walk_to(walker.global_position + Vector3(10, 0, 0), 3.0, 1.0 / 60.0)
		check(walker.global_position.x == before.x, "a brain can't walk him off sideways as he goes")
		var frames := 0
		while not walker.limp and frames < 90:
			await physics_frames(1)
			frames += 1
		var on := hit_at.z - walker.global_position.z
		print("  down after %.2f s, %.2f m on from where he was hit" % [frames / 60.0, on])
		check(walker.limp, "down within 1.5 s (%.2f s)" % (frames / 60.0))
		check(frames >= 15, "he stayed up a moment (%.2f s)" % (frames / 60.0))
		check(on > 0.3, "carried on forwards (%.2f m)" % on)
		walker.queue_free()


## Hit and still on his feet, the ball itself doesn't move him: no flinch, no wince (Sean: the
## flinch threw him back 50 degrees in a twentieth of a second; a wince in its place was still
## "like a twitch", "just get rid of these winces"). A .45 stopped in him is 4.5 N*s: centimetres.
func test_a_ball_that_doesnt_drop_him_doesnt_jerk_him() -> void:
	man.physiology.tuning = man.physiology.tuning.duplicate()
	man.physiology.tuning.knockdown_max = 0.0
	await physics_frames(10)
	# Through his right arm: on his feet after (a chest shot can take his legs: prone, another path).
	var arm := man.parts[&"upper_arm_r"] as Node3D
	var chest := man.parts[&"chest"] as Node3D
	var arm_was := arm.global_basis.y
	var chest_was := chest.global_basis.y
	var fwd := -man.global_basis.z
	_ball(&"upper_arm_r", arm.global_position, -fwd)
	check(not man.limp and not man.prone, "still on his feet")
	check(body_hits.size() > 0 and body_hits[0].segment == &"upper_arm_r", "the ball went through his arm")
	# What the wound does to him comes on as a hurt would (_favour_step), not as a kick: in the
	# tenth of a second after the ball nothing moves past his breath, and nothing ever turns fast.
	var moved := 0.0
	var fastest := 0.0
	var arm_last := arm_was
	for i in 30:
		await physics_frames(1)
		var a := rad_to_deg(arm.global_basis.y.angle_to(arm_was))
		if i < 6:
			moved = maxf(moved, a)
			moved = maxf(moved, rad_to_deg(chest.global_basis.y.angle_to(chest_was)))
		fastest = maxf(fastest, rad_to_deg(arm.global_basis.y.angle_to(arm_last)) * 60.0)
		arm_last = arm.global_basis.y
	print("  arm and chest moved at most %.1f deg in the tenth of a second after the hit; the arm turned at most %.0f deg/s" % [moved, fastest])
	# (Within his breath: a degree or so.)
	check(moved < 2.0, "no flinch or wince from the ball (%.1f deg)" % moved)
	check(fastest < 40.0, "nothing jerks (%.0f deg/s)" % fastest)


## Shot and still up, you see what the wound does to him as it comes on (Sean, 2026-10-21): a leg
## and he takes his weight off it, his gun arm and it sags out of his aim, his body and he guards it
## and goes slower; not at once (in a tenth of a second, under 2 deg) and not fast.
func _hit_and_watch(seg: StringName, rest_point: Vector3, from_dir: Vector3, watch: Callable) -> Array:
	man.physiology.tuning = man.physiology.tuning.duplicate()
	man.physiology.tuning.knockdown_max = 0.0
	await physics_frames(10)
	var before: float = watch.call()
	_ball(seg, _world(seg, rest_point), -from_dir)
	check(body_hits.size() > 0 and body_hits[0].segment == seg, "the ball hit his %s (%s)" % [seg, body_hits[0].segment if body_hits.size() > 0 else "nothing"])
	var early := 0.0
	var late := 0.0
	for i in 90:
		await physics_frames(1)
		var d: float = watch.call() - before
		if i < 6:
			early = maxf(early, absf(d))
		late = d
	check(not man.limp and not man.prone, "still on his feet")
	return [early, late]


func test_a_leg_hit_he_favours_it() -> void:
	# Through the front of his right thigh, to the outside of the bone: the muscle.
	var knee := func() -> float: return -_joint_bend(man, &"thigh_r", &"shin_r")
	var r: Array = await _hit_and_watch(&"thigh_r", man.anatomy.segment_center(&"thigh_r") + Vector3(0.04, 0.0, 0.0),
			-man.global_basis.z, knee)
	print("  right knee eased %.1f deg in a tenth of a second, %.1f deg by 1.5 s" % [r[0], r[1]])
	check(r[0] < 2.0, "not at once (%.1f deg)" % r[0])
	check(r[1] > 5.0, "his weight's off that leg: the knee eased %.1f deg" % r[1])
	# And he walks shorter and slower on it.
	var from := man.global_position
	for i in 60:
		man.walk_to(from + Vector3(0, 0, -10), 1.4, 1.0 / 60.0)
		await physics_frames(1)
	var pace := man.global_position.distance_to(from)
	print("  walked %.2f m in a second (asked 1.4 m/s)" % pace)
	check(pace < 1.2, "slower on the hurt leg (%.2f m/s)" % pace)


func test_an_arm_hit_lets_his_gun_hand_sag() -> void:
	man.draw_gun()
	await physics_frames(40)
	man.set_pose(&"aim")
	await physics_frames(30)
	# Through the outside of his right upper arm, not the bone.
	# How far his upper arm is raised from hanging (its length runs down -y).
	var pitch := func() -> float: return rad_to_deg((-(man.parts[&"upper_arm_r"] as Node3D).global_basis.y).angle_to(Vector3.DOWN))
	var r: Array = await _hit_and_watch(&"upper_arm_r", man.anatomy.segment_center(&"upper_arm_r") + Vector3(0.05, 0.0, 0.0),
			-man.global_basis.z, pitch)
	print("  gun arm moved %.1f deg in a tenth of a second, %.1f deg by 1.5 s" % [r[0], r[1]])
	check(man.held_gun != null, "he's still got the gun")
	check(man.physiology.can_hold("r"), "and can hold it")
	check(r[0] < 2.0, "not at once (%.1f deg)" % r[0])
	check(r[1] < -6.0, "his gun hand sags (%.1f deg)" % r[1])


func test_a_body_hit_slows_him() -> void:
	var from := man.global_position
	for i in 60:
		man.walk_to(from + Vector3(0, 0, -10), 1.4, 1.0 / 60.0)
		await physics_frames(1)
	var pace_before := man.global_position.distance_to(from)
	var lean := func() -> float: return rad_to_deg((man.parts[&"chest"] as Node3D).global_basis.y.angle_to(Vector3.UP))
	# Low in his belly, from in front, off to his left.
	var r: Array = await _hit_and_watch(&"abdomen", man.anatomy.segment_center(&"abdomen") + Vector3(-0.08, 0.0, 0.0),
			-man.global_basis.z, lean)
	print("  chest bent %.1f deg in a tenth of a second, %.1f deg by 1.5 s" % [r[0], r[1]])
	check(r[0] < 2.0, "not at once (%.1f deg)" % r[0])
	check(r[1] > 4.0, "he guards it (%.1f deg)" % r[1])
	from = man.global_position
	for i in 60:
		man.walk_to(from + Vector3(0, 0, -10), 1.4, 1.0 / 60.0)
		await physics_frames(1)
	var pace := man.global_position.distance_to(from)
	print("  walked %.2f m in a second before, %.2f after" % [pace_before, pace])
	check(pace < pace_before * 0.85, "slower for it (%.2f against %.2f)" % [pace, pace_before])


## Timber coming down on him: it knocks him over only if its push would (as a blast's does), and
## gives him no more than a piece that heavy can: a 2 kg board at 160 J doesn't, a 50 kg beam does.
func test_a_blow_knocks_him_down_only_as_hard_as_it_pushes() -> void:
	var chest := man.parts[&"chest"] as Node3D
	man.take_blow(chest, 160.0, chest.global_position, Vector3.BACK, sqrt(2.0 * 2.0 * 160.0))
	await physics_frames(2)
	check(not man.limp, "a light board doesn't shove him over")
	man.take_blow(chest, 400.0, chest.global_position, Vector3.BACK, sqrt(2.0 * 50.0 * 400.0))
	check(man.limp, "a beam does")
	await physics_frames(1)
	var p := 0.0
	for sid: StringName in man.parts:
		p += (man.parts[sid] as RigidBody3D).linear_velocity.z * (man.parts[sid] as RigidBody3D).mass
	# 200 N*s of beam on an 80 kg man: they go on together, 200 * 80 / 130 = 123 N*s to him.
	print("  the beam gave him %.0f N*s (it had 200)" % p)
	check(p < 140.0 and p > 100.0, "what a 50 kg beam can give: %.0f N*s" % p)


## The light links hold on their joints as he lands face first (the neck swung 19 deg past its
## limit landing that way: experiments/physics_lab E_chest_from_back, 2026-10-21).
func test_his_neck_holds_landing_face_first() -> void:
	man.go_limp(Vector3(0, 0, -1.2))
	var neck := man.parts[&"neck"] as Node3D
	var chest := man.parts[&"chest"] as Node3D
	# Its swing: how far the neck's own axis leans from where it was on the chest (the cone; its
	# twist about itself is another 25).
	var rest := chest.global_basis.orthonormalized().inverse() * neck.global_basis.orthonormalized().y
	var worst := 0.0
	for i in 150:
		await physics_frames(1)
		var now := chest.global_basis.orthonormalized().inverse() * neck.global_basis.orthonormalized().y
		worst = maxf(worst, rad_to_deg(rest.angle_to(now)))
	print("  the neck swung at most %.1f deg on the chest (its cone 30)" % worst)
	check(worst < 36.0, "within its limit and a little (%.1f deg)" % worst)


## Sat at a table, his forearms before him, he goes down and they stay out of his chest (left out
## of colliding as they touched, his forearm went 5 cm into it: M_seated_ball).
func test_sat_at_a_table_his_arms_stay_out_of_him() -> void:
	var seat := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(0.45, 0.44, 0.45)
	cs.shape = bx
	seat.add_child(cs)
	world.add_child(seat)
	seat.global_position = Vector3(0, 0.22, 0.05)
	var top := StaticBody3D.new()
	var cs2 := CollisionShape3D.new()
	var bx2 := BoxShape3D.new()
	bx2.size = Vector3(1.2, 0.05, 0.8)
	cs2.shape = bx2
	top.add_child(cs2)
	world.add_child(top)
	top.global_position = Vector3(0, 0.74, -0.75)
	man.set_pose(&"sit")
	await physics_frames(60)
	man.go_limp()
	var began := {}
	for arm in [&"forearm_l", &"forearm_r", &"hand_l", &"hand_r"]:
		for trunk in [&"chest", &"abdomen"]:
			began[[arm, trunk]] = maxf(_depth(man.parts[arm], man.parts[trunk]), 0.0)
	var deepest := 0.0
	for i in 180:
		await physics_frames(1)
		for pair: Array in began:
			deepest = maxf(deepest, _depth(man.parts[pair[0]], man.parts[pair[1]]) - float(began[pair]))
	print("  a forearm or hand at most %.3f m further into his trunk than it began" % deepest)
	check(deepest < 0.03, "his arms stay out of him (%.3f m)" % deepest)


## How deep two parts' capsules lie in each other (m).
func _depth(a: Node3D, b: Node3D) -> float:
	var best := -INF
	for ca in a.get_children():
		for cb in b.get_children():
			if not (ca is CollisionShape3D and cb is CollisionShape3D and (ca as CollisionShape3D).shape is CapsuleShape3D \
					and (cb as CollisionShape3D).shape is CapsuleShape3D):
				continue
			var sa := (ca as CollisionShape3D).shape as CapsuleShape3D
			var sb := (cb as CollisionShape3D).shape as CapsuleShape3D
			var xa := a.global_transform * (ca as CollisionShape3D).transform
			var xb := b.global_transform * (cb as CollisionShape3D).transform
			var ha := sa.height * 0.5 - sa.radius
			var hb := sb.height * 0.5 - sb.radius
			var pts := Geometry3D.get_closest_points_between_segments(xa * Vector3(0, -ha, 0), xa * Vector3(0, ha, 0),
					xb * Vector3(0, -hb, 0), xb * Vector3(0, hb, 0))
			best = maxf(best, sa.radius + sb.radius - pts[0].distance_to(pts[1]))
	return best


func test_knees_only_bend_the_right_way() -> void:
	var world := Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(20, 1, 20)
	cs.shape = bs
	ground.add_child(cs)
	ground.position.y = -0.5
	world.add_child(ground)
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	await physics_frames(3)
	# Dead, and his last instant of tone gone (HumanBody.TONE_FADE_DEAD): the hinges' own limits.
	man.physiology._die(&"test")
	man.go_limp()
	await physics_frames(int(HumanBody.TONE_FADE_DEAD * 60.0 * 4.0))
	var shin_r := man.parts[&"shin_r"] as RigidBody3D
	var shin_l := man.parts[&"shin_l"] as RigidBody3D
	# Kick the right shin forwards (the wrong way for a knee), the left one backwards: about each
	# thigh's own right (the hinge's axis), as he's turned as he fell.
	for i in 20:
		shin_r.apply_torque_impulse((man.parts[&"thigh_r"] as Node3D).global_basis.x * 4.0)
		shin_l.apply_torque_impulse(-(man.parts[&"thigh_l"] as Node3D).global_basis.x * 4.0)
		await physics_frames(1)
	var r := _knee_bend(man, "r")
	var l := _knee_bend(man, "l")
	print("  knee bends after the kicks: right %.0f, left %.0f" % [r, l])
	# (A knee bends negative: he may have folded it the right way as he fell.)
	check(r < 15.0, "the right knee won't bend forwards (%.0f)" % r)
	check(absf(l) > 20.0, "the left one bends back (%.0f)" % l)
	# Elbows the other way: the forearm comes forward, never back past straight.
	var fr := man.parts[&"forearm_r"] as RigidBody3D
	var fl := man.parts[&"forearm_l"] as RigidBody3D
	for i in 20:
		# About each upper arm's own right (the hinge's axis): he's turned as he fell.
		fr.apply_torque_impulse((man.parts[&"upper_arm_r"] as Node3D).global_basis.x * 1.5)
		fl.apply_torque_impulse(-(man.parts[&"upper_arm_l"] as Node3D).global_basis.x * 1.5)
		await physics_frames(1)
	var er := _joint_bend(man, &"upper_arm_r", &"forearm_r")
	var el := _joint_bend(man, &"upper_arm_l", &"forearm_l")
	print("  elbow bends: right (pushed forward) %.0f, left (pushed back) %.0f" % [er, el])
	check(er > 20.0, "the right elbow bends forward (%.0f)" % er)
	check(el > -15.0, "the left never bends back past straight (%.0f)" % el)
	world.queue_free()


func _joint_bend(man: HumanBody, upper: StringName, lower: StringName) -> float:
	var a_part := man.parts[upper] as Node3D
	var b_part := man.parts[lower] as Node3D
	var right := a_part.global_basis.x.normalized()
	return rad_to_deg((-a_part.global_basis.y).signed_angle_to(-b_part.global_basis.y, right))
func test_skin_and_clothes_are_one_skinned_body() -> void:
	check(man.skeleton != null, "a skeleton")
	check_eq(man.skeleton.get_bone_count(), 17, "a bone per segment")
	for key in ["skin/chest", "skin/thigh_l", "skin/forearm_r", "skin/hand_r", "head/head", "shirt/chest", "vest/chest",
			"trousers/pelvis", "boots/foot_r", "gun_belt/pelvis", "holster/pelvis", "hat/head", "hat_brim/head"]:
		var mi: MeshInstance3D = man.skin_meshes.get(key)
		if check(mi != null and mi.mesh != null and mi.mesh.get_surface_count() == 1, "%s built" % key):
			check(mi.layers & Layers.VIS_BODY != 0, "%s takes wound decals" % key)
	# The skin wraps the hitboxes: every skin vertex lies near some segment's capsules.
	var verts := PackedVector3Array()
	for key: String in man.skin_meshes:
		if key.begins_with("skin/"):
			verts.append_array((man.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var worst := 0.0
	for v in verts:
		var best := INF
		for sid: StringName in man.anatomy.segments:
			for c: Array in man.anatomy.segments[sid].capsules:
				var a: Vector3 = c[0]
				var ab: Vector3 = (c[1] as Vector3) - a
				var t := clampf((v - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
				best = minf(best, absf(v.distance_to(a + ab * t) - float(c[2])))
		worst = maxf(worst, best)
	check(worst < 0.07, "skin within 7 cm of the hitboxes everywhere (worst %.3f m)" % worst)


func test_body_follows_the_ragdoll() -> void:
	await _shoot(Vector3(0, 1.64, -6), Vector3(0, 1.64, 0))
	await physics_frames(120)
	await process_frames(2)
	var head: Node3D = man.parts[&"head"]
	var i := man.skeleton.find_bone("head")
	var bone_world := man.skeleton.global_transform * man.skeleton.get_bone_global_pose(i)
	check(bone_world.origin.distance_to(head.global_position) < 0.01, "the head's skin is where the ragdoll's head is")
	check(head.global_position.y < 0.5, "and that's on the ground")


func test_he_has_the_generated_makehuman_body() -> void:
	check(PeopleBodies.has_model(man.body_model), "assets/people/%s.glb is there" % man.body_model)
	var tris := 0
	for key: String in man.skin_meshes:
		if key.begins_with("head/"):
			tris += (man.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
	check(tris > 800, "a real head (%d triangles, the lofted one has a few hundred)" % tris)
	# Without it he falls back to the lofted body.
	var plain := HumanBody.new()
	plain.body_model = &""
	plain.person_id = &"plain"
	add_child(plain)
	await physics_frames(2)
	var plain_tris := 0
	for key: String in plain.skin_meshes:
		if key.begins_with("head/"):
			plain_tris += (plain.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
	check(plain_tris > 0 and plain_tris < tris, "BodyMesh when there's no model (%d)" % plain_tris)
	plain.queue_free()


func test_the_tripo_man_comes_dressed() -> void:
	# The stranger (assets/people/stranger.glb, tools/blender/fit_tripo.py) is a Tripo model fitted
	# to our bones: his own skin and head on our skeleton, his clothes, hat and boots in his skin,
	# so none of BodyMesh's are put on him. (A stopgap: test_the_layered_man_wears_his_own_hat.)
	check(PeopleBodies.has_model(&"stranger"), "assets/people/stranger.glb is there")
	var him := HumanBody.new()
	him.body_model = &"stranger"
	him.person_id = &"stranger_test"
	add_child(him)
	await physics_frames(2)
	var shapes := {}
	var head_tris := 0
	for key: String in him.skin_meshes:
		shapes[key.get_slice("/", 0)] = true
		if key.begins_with("head/"):
			head_tris += (him.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
	check(shapes.has("skin") and shapes.has("head"), "his skin and head (%s)" % [shapes.keys()])
	check(not shapes.has("hat") and not shapes.has("boots") and not shapes.has("shirt"), "nothing of BodyMesh's over his own clothes (%s)" % [shapes.keys()])
	check(head_tris > 800, "a real head (%d triangles)" % head_tris)
	var top := 0.0
	for key: String in him.skin_meshes:
		for v: Vector3 in (him.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			top = maxf(top, v.y)
	check(top > 1.7 and top < 2.1, "stood at our height, hat and all (%.2f m)" % top)
	him.queue_free()


func test_a_fitted_mans_drawn_eyes_are_his_heads_eyes() -> void:
	# A fitted man whose face has been found (tools/blender/fit_tripo.py EYES_RULE) has his head
	# placed so the eyes drawn on him are the anatomy's eyes: a shot through his face goes through
	# his head's hitbox, his eyes, his brain. (The stylised Rodin stranger's sat 12 cm over it.)
	var a := Anatomy.shared()
	var checked := 0
	for file in DirAccess.get_files_at("res://assets/people"):
		if not file.ends_with(".json"):
			continue
		var report: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/people/" + file))
		if not report is Dictionary or not (report as Dictionary).has("eyes"):
			continue
		for side in ["right", "left"]:
			var e: Array = report["eyes"][side]
			var drawn := Vector3(e[0], e[1], e[2])
			var eye: Vector3 = a.structure(StringName("eye_" + side[0])).a
			check(drawn.distance_to(eye) < 0.015, "%s: his %s eye on the anatomy's (%.1f cm off)" % [file, side, drawn.distance_to(eye) * 100.0])
		checked += 1
	check(checked > 0, "a fitted man with his eyes found (%d)" % checked)


func test_the_layered_man_wears_his_own_hat() -> void:
	# The same man built in layers (assets/people/stranger_layered.glb): his body painted
	# bare-headed and coatless, and his hat a piece modelled alone and hung on his head as its
	# own mesh, so it can be shot off; nothing of BodyMesh's on him.
	check(PeopleBodies.has_model(&"stranger_layered"), "assets/people/stranger_layered.glb is there")
	var him := HumanBody.new()
	him.body_model = &"stranger_layered"
	him.person_id = &"stranger_layered_test"
	add_child(him)
	await physics_frames(2)
	var shapes := {}
	var hat_top := 0.0
	var head_top := 0.0
	for key: String in him.skin_meshes:
		shapes[key.get_slice("/", 0)] = true
		for v: Vector3 in (him.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			if key.begins_with("hat/"):
				hat_top = maxf(hat_top, v.y)
			elif key.begins_with("head/"):
				head_top = maxf(head_top, v.y)
	check(shapes.has("skin") and shapes.has("head") and shapes.has("hat"), "his skin, head and his own hat (%s)" % [shapes.keys()])
	check(not shapes.has("hat_brim") and not shapes.has("boots") and not shapes.has("shirt"), "nothing of BodyMesh's (%s)" % [shapes.keys()])
	check(hat_top > head_top and hat_top - head_top < 0.2, "the hat on his head (crown %.2f over it)" % (hat_top - head_top))
	him.queue_free()


func test_the_hat_sits_on_his_own_head() -> void:
	# The generated head sits further forward and is bigger than BodyMesh's: the crown has to clear
	# it, every bit of head above the band inside the crown. The crown fitted to the painting's man
	# (HAT_CROWN) already does, so it stays where it was fitted; a head it doesn't clear gets the
	# crown moved round it, the band low on his brow.
	var head := PackedVector3Array()
	for key: String in man.skin_meshes:
		if key.begins_with("head/"):
			head.append_array((man.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var fit := PeopleBodies.hat_fit(head)
	if not check(not fit.is_empty(), "a fit for his head"):
		return
	var rows := BodyMesh.hat_rows(fit)
	check(rows == BodyMesh.HAT_CROWN, "the painted hat clears his head, so it stays where it was fitted")
	var band: Array = rows[0]
	var outside := 0
	var checked := 0
	for p in head:
		if p.y < (band[0] as Vector3).y:
			continue
		checked += 1
		var c: Vector3 = band[0]
		var dz := p.z - c.z
		var depth: float = band[2] if dz < 0.0 else band[3]
		var e := Vector2((p.x - c.x) / float(band[1]), dz / depth)
		if e.length() > 1.0:
			outside += 1
	check(checked > 50, "head above the band (%d)" % checked)
	check_eq(outside, 0, "no part of his head pokes out of the crown")
	# A bigger head, further forward: the crown is moved and widened round it.
	var big := {"band": (fit.band as Vector3) + Vector3(0.0, 0.0, -0.03), "half_width": float(fit.half_width) + 0.02,
			"half_depth": float(fit.half_depth) + 0.02}
	check(not BodyMesh.hat_clears(big), "the crown as it is wouldn't clear that head")
	var moved: Array = BodyMesh.hat_rows(big)[0]
	check_near((moved[0] as Vector3).y, PeopleBodies.EYE_HEIGHT + PeopleBodies.BAND_ABOVE_EYES, 0.001, "the band just above his brow")
	check(float(moved[1]) >= float(big.half_width) + BodyMesh.HAT_CLEARANCE - 0.0001, "wide enough")
	var front := (moved[0] as Vector3).z - ((big.band as Vector3).z - float(big.half_depth))
	var back := ((big.band as Vector3).z + float(big.half_depth)) - (moved[0] as Vector3).z
	check(float(moved[2]) > front and float(moved[3]) > back, "deep enough front and back")


func test_generated_clothes_are_worn_as_the_outfit_says() -> void:
	var keys: Array = man.skin_meshes.keys()
	check(keys.any(func(k: String) -> bool: return k.begins_with("cravat/")), "the tie from the generated body")
	check(not keys.any(func(k: String) -> bool: return k.begins_with("bandana/")), "and no lofted bandana floating round it")
	check(not keys.any(func(k: String) -> bool: return k.begins_with("coat/")), "no coat on a man without one")
	var coated := HumanBody.new()
	coated.person_id = &"coated"
	coated.coat_color = Color(0.4, 0.3, 0.2, 1.0)
	add_child(coated)
	await physics_frames(2)
	var coat: MeshInstance3D = coated.skin_meshes.get("coat/chest")
	if check(coat != null, "the draped coat when he wears one"):
		var tex = (coat.material_override as ShaderMaterial).get_shader_parameter(&"albedo_tex")
		check(tex is Texture2D and (tex as Texture2D).get_width() >= 64, "with its baked pixel texture")
	coated.queue_free()


func test_the_coat_skirt_hangs_from_his_hips_not_his_arms() -> void:
	var coated := HumanBody.new()
	coated.person_id = &"skirted"
	coated.coat_color = Color(0.4, 0.3, 0.2, 1.0)
	add_child(coated)
	await physics_frames(2)
	var arm_bones: Array[int] = []
	var order := coated.anatomy.segment_order()
	for i in order.size():
		if String(order[i]).begins_with("forearm") or String(order[i]).begins_with("hand") or String(order[i]).begins_with("upper_arm"):
			arm_bones.append(i)
	var bad := 0
	var low := 0
	for key: String in coated.skin_meshes:
		if not key.begins_with("coat/"):
			continue
		var a := (coated.skin_meshes[key] as MeshInstance3D).mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var bs: PackedInt32Array = a[Mesh.ARRAY_BONES]
		var ws: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		for i in vs.size():
			if vs[i].y > 0.86:
				continue
			low += 1
			for k in 4:
				if arm_bones.has(bs[i * 4 + k]) and ws[i * 4 + k] > 0.05:
					bad += 1
					break
	check(low > 20, "the coat has a skirt (%d vertices below the hips)" % low)
	check_eq(bad, 0, "and none of it is tied to his arms")
	coated.queue_free()


func _drawn_finger_shown(m: HumanBody, fid: StringName) -> bool:
	for mi in (m.fingers[fid] as Node3D).find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).visible:
			return true
	return false


func test_a_whole_mans_own_hands_get_no_second_set_of_fingers() -> void:
	# The Character Studio's men have Rodin's hands in their skin: the drawn fingers would be a
	# second hand on his. Hidden; one shot off still flies as a drawn finger.
	var studio := HumanBody.new()
	studio.body_model = &"bold_cowboy_s0"
	studio.position = Vector3(3, 0, 0)
	world.add_child(studio)
	await physics_frames(2)
	check(not _drawn_finger_shown(studio, &"index_r"), "his drawn fingers hidden")
	check(_drawn_finger_shown(man, &"index_r"), "the default man's still drawn")
	var knuckle := studio.fingers[&"index_r"] as Node3D
	studio.sever_finger(&"index_r", Vector3.RIGHT)
	var shown := false
	for mi in knuckle.find_children("*", "MeshInstance3D", true, false):
		shown = shown or (mi as MeshInstance3D).visible
	check(shown, "the finger shot off flies, drawn")


func test_a_studio_man_wears_his_bandana_at_his_neck_or_over_his_face() -> void:
	# tools/faces/bandana.py gives a Studio man two: at his neck, and over his nose and mouth.
	# He wears the one over his face when masked, else the neck one if he wears a bandana; never both.
	var a := Anatomy.new()
	var outfit := {"bandana": true, "mask": false}
	var down: Dictionary = PeopleBodies.build(a, outfit, &"hothead_lyle_s2_talking").shapes
	check(down.has("bandana") and not down.has("bandana_mask"), "a bandana, down: at his neck")
	outfit.mask = true
	var up: Dictionary = PeopleBodies.build(a, outfit, &"hothead_lyle_s2_talking").shapes
	check(up.has("bandana_mask") and not up.has("bandana"), "masked: over his face, not at his neck too")
	var none: Dictionary = PeopleBodies.build(a, {"bandana": false, "mask": false}, &"hothead_lyle_s2_talking").shapes
	check(not none.has("bandana") and not none.has("bandana_mask"), "no bandana: neither")
