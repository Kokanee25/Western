extends TestCase
## A Character Studio man's skinned hands (tools/faces/hands.py): MakeHuman's hands on his
## skin, on the 15 finger bones a hand. (Its own file, run after test_body_impacts: a talking
## Studio man spawned before it changed how its plain outlaw slumps into a railing: issue #247.)

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _drawn_finger_shown(m: HumanBody, fid: StringName) -> bool:
	for mi in (m.fingers[fid] as Node3D).find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).visible:
			return true
	return false


func test_a_studio_mans_new_hands_bend_in_the_skin() -> void:
	# tools/faces/hands.py: his Rodin hands (a mitten) cut off, MakeHuman's on, skinned to the 15
	# finger bones a hand; the finger nodes still curl and grip, and pose the bones.
	var studio := HumanBody.new()
	studio.body_model = &"sean_s3_talking"
	studio.position = Vector3(-3, 0, 0)
	world.add_child(studio)
	await physics_frames(2)
	check_eq(studio._finger_rig.size(), 30, "thirty finger bones in his skeleton")
	check(not _drawn_finger_shown(studio, &"index_r"), "the drawn fingers hidden: his own bend")
	studio.curl_hand("r", 1.0)
	await physics_frames(2)
	var sk: Skeleton3D = studio.skeleton
	var tip := sk.find_bone("finger_index_r_2")
	var knuckle := sk.find_bone("finger_index_r_0")
	var bent := sk.get_bone_global_pose(tip).basis.y.dot(sk.get_bone_global_pose(knuckle).basis.y)
	check(bent < 0.6, "a fist bends his index finger's last bone well round from its first (%.2f)" % bent)
	studio.queue_free()
