extends TestCase
## A Character Studio man's shoulder helpers (PeopleBodies.shoulder_share, issue #388): a bone a
## shoulder turned a share of the way from his chest to his upper arm, carrying the blend between
## them, so his raised arm doesn't go thin. (Its own file, run after test_body_impacts: a talking
## Studio man spawned before it changed how its plain outlaw slumps into a railing: issue #247.)

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


## A bone's move from its rest, in the skeleton's space (the chest, arms and helpers are roots).
func _move(sk: Skeleton3D, bone: int) -> Transform3D:
	return sk.get_bone_pose(bone) * sk.get_bone_rest(bone).affine_inverse()


func test_only_a_studio_man_has_shoulder_helpers() -> void:
	var studio := HumanBody.new()
	studio.body_model = &"doctor_s2_talking"
	world.add_child(studio)
	var plain := HumanBody.new()
	plain.position = Vector3(2, 0, 0)
	world.add_child(plain)
	await physics_frames(2)
	check_eq(studio._shoulders.size(), 2, "the doctor has a helper a shoulder")
	check(studio.skeleton.find_bone("shoulder_r") >= 0 and studio.skeleton.find_bone("shoulder_l") >= 0,
			"both in his skeleton")
	check_eq(plain._shoulders.size(), 0, "a man not made by the Studio has none")


func test_with_his_hands_up_the_helper_takes_its_share_of_the_turn() -> void:
	var studio := HumanBody.new()
	studio.body_model = &"doctor_s2_talking"
	world.add_child(studio)
	await physics_frames(2)
	studio.set_pose(&"hands_up")
	studio._apply_pose(0.0, true)
	await physics_frames(40)
	var sk: Skeleton3D = studio.skeleton
	var chest := _move(sk, sk.find_bone("chest"))
	for side in ["r", "l"]:
		var arm := (chest.affine_inverse() * _move(sk, sk.find_bone("upper_arm_" + side))).basis
		var helper := (chest.affine_inverse() * _move(sk, sk.find_bone("shoulder_" + side))).basis
		# Each the shorter way round (the left arm's 150 degrees about -z reads 210 about +z).
		var a := arm.get_rotation_quaternion().get_angle()
		a = minf(a, TAU - a)
		var h := helper.get_rotation_quaternion().get_angle()
		h = minf(h, TAU - h)
		check(a > deg_to_rad(120.0), "his %s arm is raised (%.0f degrees)" % [side, rad_to_deg(a)])
		check_near(h / a, PeopleBodies.shoulder_share, 0.02, "his %s helper turned its share of the arm's turn" % side)


func test_the_helpers_leave_his_pieces_as_they_were() -> void:
	# The triangles are shared out to his body parts by his own weights, helpers or not.
	var anatomy := Anatomy.shared()
	var outfit := {"shirt": true, "trousers": true, "boots": true}
	var share := PeopleBodies.shoulder_share
	PeopleBodies.shoulder_share = 0.0
	var before: Dictionary = PeopleBodies.build(anatomy, outfit, &"doctor_s2_talking").shapes
	PeopleBodies.shoulder_share = share
	var after: Dictionary = PeopleBodies.build(anatomy, outfit, &"doctor_s2_talking").shapes
	check_eq(after.keys(), before.keys(), "the same shapes")
	for shape: String in before:
		if not before[shape] is Dictionary:
			continue
		var b: Dictionary = before[shape]
		var a: Dictionary = after[shape]
		check_eq(a.keys(), b.keys(), "%s: the same pieces" % shape)
		for bone: int in b:
			if a.has(bone):
				check_eq((a[bone][0] as ArrayMesh).surface_get_array_len(0), (b[bone][0] as ArrayMesh).surface_get_array_len(0),
						"%s piece %d: the same vertices" % [shape, bone])
