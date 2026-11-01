extends TestCase
## A man bladed behind a narrow post (PostPose, issue #531): side-on with the threat at his left,
## his right upper arm down by his ribs, the forearm level across his belly along the threat's line
## (clear of him), the left arm hanging, his trunk behind the post, his eye just past its edge, the
## gun clear of it; each man his own (the dials by his seed), the same man the same each time.

const THREAT := Vector3(0.0, 1.6, -6.0)

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _posed(seed: int, dials := {}) -> HumanBody:
	var man := HumanBody.new()
	man.rng_seed = seed
	man.start_holstered = false
	world.add_child(man)
	man.global_position = Vector3(0.0, 0.0, 0.6)
	await physics_frames(2)
	var d := man.take_post(THREAT, dials)
	await physics_frames(90)
	PostPose.place_at(man, Vector3.ZERO, THREAT, float(d.peek))
	await physics_frames(2)
	return man


func _cross_dials(seed: int) -> Dictionary:
	var d := PostPose.dials(seed)
	d.style = &"cross"
	return d


func test_the_family_varies_by_seed_and_holds_for_a_man() -> void:
	var styles := {}
	var legs := {}
	var shows := {}
	for s in 40:
		var d := PostPose.dials(s)
		styles[d.style] = true
		legs[d.legs] = true
		shows[d.show] = true
	check(styles.has(&"cross") and styles.has(&"regular"), "both the gun across him and the regular hold: %s" % [styles.keys()])
	check(legs.has(&"straight") and legs.has(&"staggered"), "legs straight and staggered: %s" % [legs.keys()])
	check(shows.size() == 3, "none, a bit of chest, his backside: %s" % [shows.keys()])
	check_eq(PostPose.dials(7), PostPose.dials(7), "the same man draws the same dials")
	check(PostPose.dials(7) != PostPose.dials(8), "two men draw their own")


func test_the_gun_across_his_body() -> void:
	for s in [3, 9, 12]:
		var man := await _posed(s, _cross_dials(s))
		var sh := (man.pivots[&"upper_arm_r"] as Node3D).global_position
		var el := (man.pivots[&"forearm_r"] as Node3D).global_position
		var wr := (man.pivots[&"hand_r"] as Node3D).global_position
		var fore := wr - el
		var to_threat := THREAT - el
		check(rad_to_deg((el - sh).angle_to(Vector3.DOWN)) < 30.0, "seed %d: the upper arm hangs near straight down (%.1f)" % [s, rad_to_deg((el - sh).angle_to(Vector3.DOWN))])
		var bend := rad_to_deg((sh - el).angle_to(wr - el))
		check(bend > 75.0 and bend < 115.0, "seed %d: the elbow bent about square (%.1f)" % [s, bend])
		check(absf(rad_to_deg(asin(fore.normalized().y))) < 10.0, "seed %d: the forearm level" % s)
		check(absf(rad_to_deg(Vector2(fore.x, fore.z).angle_to(Vector2(to_threat.x, to_threat.z)))) < 10.0, "seed %d: the forearm along the threat's line" % s)
		# Across his front, right to left: the wrist further to his left than the elbow, both in
		# front of him.
		var right := man.global_basis.x
		check((wr - el).dot(right) < -0.15, "seed %d: the forearm runs across him to his left" % s)
		var shl := (man.pivots[&"upper_arm_l"] as Node3D).global_position
		var ell := (man.pivots[&"forearm_l"] as Node3D).global_position
		check(rad_to_deg((ell - shl).angle_to(Vector3.DOWN)) < 8.0, "seed %d: the left arm hangs" % s)
		var caps := PostPose.capsules_now(man)
		var gap := INF
		for k: Array in caps:
			if k[0] == &"forearm_r":
				for t: Array in caps:
					if t[0] in [&"abdomen", &"chest", &"pelvis"]:
						gap = minf(gap, PostPose.seg_distance(k[1], k[2], t[1], t[2]) - float(k[3]) - float(t[3]))
		check(gap > 0.0, "seed %d: the forearm clear of his belly (%.3f)" % [s, gap])
		man.queue_free()
		await physics_frames(1)


func test_behind_the_post_and_seeing_past_it() -> void:
	var post := AABB(Vector3(-0.1, 0.0, -0.1), Vector3(0.2, 3.66, 0.2))
	for s in [1, 2, 3, 5]:
		var man := await _posed(s)
		var caps := PostPose.capsules_now(man)
		var trunk_in := true
		for k: Array in caps:
			for i in 11:
				var p: Vector3 = (k[1] as Vector3).lerp(k[2], i / 10.0)
				# The axis point's distance to the post's sides (below 0 inside it), against the radius.
				var dx := absf(p.x) - 0.1
				var dz := absf(p.z) - 0.1
				var dist := Vector2(maxf(dx, 0.0), maxf(dz, 0.0)).length() if dx > 0.0 or dz > 0.0 else maxf(dx, dz)
				check(dist >= float(k[3]) - 0.003, "seed %d: %s not into the post (%.3f)" % [s, k[0], float(k[3]) - dist])
			if k[0] in [&"chest", &"abdomen", &"pelvis"]:
				for p: Vector3 in [k[1], k[2]]:
					trunk_in = trunk_in and absf(p.x) < 0.1
		check(trunk_in, "seed %d: his trunk's middle line behind the post's width" % s)
		var eye := PostPose.eye_now(man)
		check(post.intersects_segment(eye, THREAT) == null, "seed %d: his eye sees past the edge" % s)
		var lo := INF
		for k: Array in caps:
			if k[0] in [&"chest", &"abdomen", &"pelvis", &"upper_arm_l"]:
				lo = minf(lo, minf((k[1] as Vector3).z, (k[2] as Vector3).z) - float(k[3]))
		if man.post_pose.has(&"upper_arm_r") and PostPose.dials(s).style == &"cross":
			check_near(lo, 0.1, 0.02, "seed %d: his left side against the post's face" % s)
		var gun := man.held_gun
		var box := AABB()
		var first := true
		for g in gun.find_children("*", "MeshInstance3D", true, false):
			var bb := (g as MeshInstance3D).global_transform * (g as MeshInstance3D).get_aabb()
			box = bb if first else box.merge(bb)
			first = false
		check(not box.intersects(post), "seed %d: the gun clear of the post" % s)
		man.queue_free()
		await physics_frames(1)


func test_point_fired_spread() -> void:
	check_near(PostPose.point_spread(2.4), 7.5, 0.01, "a calm man's 2.4 degrees pointed is 7.5")
	check(PostPose.point_spread(4.0) > PostPose.point_spread(2.4), "worse aimed, worse pointed")
