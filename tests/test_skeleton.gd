extends TestCase
## The fuller skeleton (#696): every man's skin has clavicles, twist bones and finger bones after
## his 17 segment bones; they only shape the skin (the parts, the hitboxes and the ragdoll stay on
## the 17), standing easy they sit exactly on the bones they move with, raised arms lift the
## clavicles within a shoulder girdle's limits, a turned wrist twists the forearm's skin along its
## length; and a man's own proportions (Anatomy.fitted) move his hitboxes with him, within limits.

var world: Node3D


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
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _man(model := &"") -> HumanBody:
	var man := HumanBody.new()
	man.body_model = model
	world.add_child(man)
	return man


## A bone's move from its rest, in the skeleton's space (its skin matrix: every bone is a root but
## the fingers).
func _move(sk: Skeleton3D, name: String) -> Transform3D:
	var i := sk.find_bone(name)
	return sk.get_bone_global_pose(i) * sk.get_bone_global_rest(i).affine_inverse()


func _close(a: Transform3D, b: Transform3D, eps := 1e-4) -> bool:
	return a.origin.distance_to(b.origin) < eps and (a.basis.x - b.basis.x).length() < eps \
			and (a.basis.y - b.basis.y).length() < eps and (a.basis.z - b.basis.z).length() < eps


func test_every_man_has_the_fuller_skeleton() -> void:
	for model: StringName in [&"", &"doctor_s2_talking"]:
		var man := _man(model)
		await physics_frames(2)
		var sk := man.skeleton
		var first := DeformRig.first_bind(man.anatomy)
		check_eq(first, 47, "the deform bones after 17 segments and 30 finger bones")
		for k in DeformRig.NAMES.size():
			check_eq(sk.find_bone(String(DeformRig.NAMES[k])), first + k, "%s: %s in its place" % [model, DeformRig.NAMES[k]])
		for name: String in PeopleBodies.finger_bone_names():
			check(sk.find_bone(name) >= 17, "%s: %s" % [model, name])
		check_eq(man.parts.size(), 17, "%s: still 17 parts (hitboxes, the ragdoll's bodies)" % model)
		man.queue_free()


func _turn_deg(a: Transform3D, b: Transform3D) -> float:
	return rad_to_deg((a.basis.inverse() * b.basis).get_rotation_quaternion().get_angle())


func test_standing_easy_the_deform_bones_hang_with_their_bones() -> void:
	var man := _man()
	await physics_frames(2)
	man.set_pose(&"stand")
	await physics_frames(30)
	var sk := man.skeleton
	for side in ["r", "l"]:
		check(_turn_deg(_move(sk, "chest"), _move(sk, "clavicle_" + side)) < 3.0,
				"%s clavicle about where his chest has it standing easy" % side)
		for limb in ["upper_arm", "forearm"]:
			var seg: Dictionary = man.anatomy.segments[StringName("%s_%s" % [limb, side])]
			var axis := ((seg.b as Vector3) - (seg.a as Vector3)).normalized()
			var m := _move(sk, "%s_%s" % [limb, side])
			for k in 2:
				var tw := _move(sk, "%s_twist_%s_%d" % [limb, side, k])
				# Only a roll about the limb's length between them: the limb's line the same.
				check(rad_to_deg((m.basis * axis).angle_to(tw.basis * axis)) < 0.5,
						"%s %s twist %d along his %s" % [side, limb, k, limb])
				var c := ((seg.a as Vector3) + (seg.b as Vector3)) * 0.5
				check((tw * c).distance_to(m * c) < 0.002, "%s %s twist %d where his %s is" % [side, limb, k, limb])


func test_hands_up_lifts_the_clavicles_within_the_girdles_limits() -> void:
	var man := _man()
	await physics_frames(2)
	man.set_pose(&"hands_up")
	await physics_frames(90)
	var sk := man.skeleton
	var t := SkeletonTuning.shared()
	for side in ["r", "l"]:
		var ends := DeformRig.clavicle_ends(man.anatomy, side)
		var chest := _move(sk, "chest")
		var clav := _move(sk, "clavicle_" + side)
		var tip_chest := chest * (ends[1] as Vector3)
		var tip_clav := clav * (ends[1] as Vector3)
		var rise := (tip_clav - tip_chest).dot(chest.basis.y.normalized())
		check(rise > 0.015, "his %s shoulder's tip is up %.1f cm with his hands up" % [side, rise * 100.0])
		var angle := rad_to_deg((chest.basis.inverse() * clav.basis).get_rotation_quaternion().get_angle())
		check(angle <= sqrt(t.clav_rise_max ** 2 + t.clav_forward_max ** 2) + 0.5, "%s within the limits (%.1f degrees)" % [side, angle])
		check(angle > 8.0, "%s turned enough to show (%.1f degrees)" % [side, angle])
	# Standing again they come back down.
	man.set_pose(&"stand")
	await physics_frames(120)
	for side in ["r", "l"]:
		check(_turn_deg(_move(sk, "chest"), _move(sk, "clavicle_" + side)) < 3.0, "%s clavicle back down" % side)


func test_a_turned_wrist_twists_the_forearm_along_its_length() -> void:
	var man := _man()
	await physics_frames(2)
	man.set_pose(&"stand")
	man.pose_offsets = {&"hand_r": Vector3(0, 80, 0)}
	await physics_frames(60)
	var sk := man.skeleton
	var fa := _move(sk, "forearm_r")
	var axis := ((man.anatomy.segments[&"forearm_r"].b as Vector3) - (man.anatomy.segments[&"forearm_r"].a as Vector3)).normalized()
	var hand_tw := DeformRig.twist_of((fa.basis.inverse() * _move(sk, "hand_r").basis).get_rotation_quaternion(), axis)
	var t0 := DeformRig.twist_of((fa.basis.inverse() * _move(sk, "forearm_twist_r_0").basis).get_rotation_quaternion(), axis)
	var t1 := DeformRig.twist_of((fa.basis.inverse() * _move(sk, "forearm_twist_r_1").basis).get_rotation_quaternion(), axis)
	var shares := SkeletonTuning.shared().fore_twist_shares
	check(hand_tw.get_angle() > deg_to_rad(60.0), "his hand rolled (%.0f degrees)" % rad_to_deg(hand_tw.get_angle()))
	check_near(t0.get_angle() / hand_tw.get_angle(), shares.x, 0.02, "halfway down the forearm takes its share of the roll")
	check_near(t1.get_angle() / hand_tw.get_angle(), shares.y, 0.02, "at the wrist all of it")
	# The joint never wrings: no two neighbours along the forearm more than about half the roll apart.
	check(t0.get_angle() <= hand_tw.get_angle() * 0.55, "elbow to the middle: half or less")


func test_the_skin_is_shared_out_to_the_deform_bones() -> void:
	var data := BodyMesh.build(Anatomy.shared(), {"shirt": true, "trousers": true, "boots": true})
	var di := DeformRig.bind_index(Anatomy.shared())
	var seen := {}
	for shape: String in ["skin", "shirt"]:
		var pieces: Dictionary = data.shapes[shape]
		for b: int in pieces:
			var a := (pieces[b][0] as ArrayMesh).surface_get_arrays(0)
			var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
			var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			for v in verts.size():
				var sum := 0.0
				for k in 4:
					sum += weights[v * 4 + k]
					if weights[v * 4 + k] > 0.0:
						for n: StringName in di:
							if bones[v * 4 + k] == di[n]:
								seen[n] = true
								if String(n).begins_with("clavicle"):
									check(verts[v].y > 1.22, "%s's skin on the clavicle only over the shoulder (y %.2f)" % [shape, verts[v].y])
				if absf(sum - 1.0) > 1e-3:
					check(false, "%s: a vertex's weights sum to %.3f" % [shape, sum])
					return
	for n: StringName in DeformRig.NAMES:
		check(seen.has(n), "some of his skin on %s" % n)


func test_his_pieces_are_cut_as_before() -> void:
	# The pieces (wounds, a limb coming off) are still his 17 parts: no piece of a deform bone.
	var data := BodyMesh.build(Anatomy.shared(), {"shirt": true, "trousers": true, "boots": true})
	for shape: String in data.shapes:
		for b: int in data.shapes[shape]:
			check(b < 17, "%s piece on bone %d" % [shape, b])


func test_a_man_with_no_proportions_has_the_shared_anatomy() -> void:
	check(Anatomy.for_model(&"") == Anatomy.shared(), "no model: the shared anatomy")
	check(Anatomy.for_model(&"doctor_s2_talking") == Anatomy.shared(), "a Studio man fitted to it: the shared one")


func test_his_own_proportions_move_his_hitboxes_within_limits() -> void:
	var a := Anatomy.shared()
	var ua: Dictionary = a.segments[&"upper_arm_r"]
	# His upper arm 2.6 cm lower at the shoulder, 10% shorter; his forearm 40% longer (held to the limit).
	var his_a: Vector3 = (ua.a as Vector3) + Vector3(-0.024, -0.026, 0.0)
	var his_b: Vector3 = his_a + ((ua.b as Vector3) - (ua.a as Vector3)) * 0.9
	var fa: Dictionary = a.segments[&"forearm_r"]
	var ends := {"upper_arm_r": {"a": [his_a.x, his_a.y, his_a.z], "b": [his_b.x, his_b.y, his_b.z]},
			"forearm_r": {"a": [his_b.x, his_b.y, his_b.z],
				"b": [his_b.x + ((fa.b as Vector3) - (fa.a as Vector3)).x * 1.4, his_b.y + ((fa.b as Vector3) - (fa.a as Vector3)).y * 1.4,
					his_b.z + ((fa.b as Vector3) - (fa.a as Vector3)).z * 1.4]}}
	var f := a.fitted(ends)
	check((f.segments[&"upper_arm_r"].a as Vector3).distance_to(his_a) < 1e-4, "his shoulder joint where his is")
	check((f.segments[&"upper_arm_r"].b as Vector3).distance_to(his_b) < 1e-4, "his elbow where his is")
	var len_f := ((f.segments[&"forearm_r"].b as Vector3) - (f.segments[&"forearm_r"].a as Vector3)).length()
	var len_0 := ((fa.b as Vector3) - (fa.a as Vector3)).length()
	check_near(len_f / len_0, SkeletonTuning.shared().length_max, 0.002, "a forearm past the limits held to them")
	check(f.fit_report.forearm_r.held.has("length"), "and the report says so")
	var hum := f.structure(&"humerus_r")
	check((hum.a as Vector3).y < (a.structure(&"humerus_r").a as Vector3).y - 0.02, "his humerus moved down with his arm")
	check_eq(f.segments[&"chest"].a, a.segments[&"chest"].a, "a segment not given stays")
	check_eq(f.segments[&"upper_arm_r"].radius, ua.radius, "girth kept")


func test_a_clip_with_a_clavicle_channel_leads_it() -> void:
	var man := _man()
	await physics_frames(2)
	var sk := man.skeleton
	man._clip_w = 1.0
	man._pose_played = {&"clavicle_r": Quaternion(Vector3(0, 0, 1), deg_to_rad(20.0))}
	man._update_skeleton({}, 0.0)
	var rel := (_move(sk, "chest").basis.inverse() * _move(sk, "clavicle_r").basis).get_rotation_quaternion()
	check_near(rad_to_deg(rel.get_angle()), 20.0, 0.5, "the clip's 20 degrees")
	man._clip_w = 0.0
	man._pose_played = {}
	man._update_skeleton({}, 0.0)
	rel = (_move(sk, "chest").basis.inverse() * _move(sk, "clavicle_r").basis).get_rotation_quaternion()
	check(rad_to_deg(rel.get_angle()) < 2.0, "without it the drive again (%.1f)" % rad_to_deg(rel.get_angle()))
