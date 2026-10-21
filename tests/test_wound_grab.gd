extends TestCase
## A hand to the wound (HumanBody._grab): hit and still on his feet, a man puts a free hand over the
## hole after a beat, not in a flinch; never the gun hand or the arm that's hit
## (experiments/body_lab/results/2026-10-21_hand_to_wound).

var world: Node3D
var ballistics: Ballistics


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
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _man(gun_out := false) -> HumanBody:
	var man := HumanBody.new()
	man.has_gun = gun_out
	world.add_child(man)
	await physics_frames(10)
	if gun_out:
		man.draw_gun()
		man.set_pose(&"aim")
		await physics_frames(40)
	return man


## A ball into a rest-pose point inside him, from 5 m in front.
func _shoot(man: HumanBody, seg: StringName, rest_point: Vector3) -> void:
	var part: Node3D = man.parts[seg]
	var at := part.global_transform * (rest_point - man.anatomy.segment_center(seg))
	var t: RevolverTuning = load("res://config/revolver.tres")
	var before := man.wounds.size()
	ballistics.fire(at + Vector3(0, 0, -5), Vector3.BACK, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return man.wounds.size() > before, 60)


func _palm_to_hole(man: HumanBody) -> float:
	var g: Dictionary = man._grab
	var hole: Vector3 = (man.parts[g.seg] as Node3D).global_transform * (g.at as Vector3)
	return (man.parts[StringName("hand_" + g.side)] as Node3D).global_position.distance_to(hole) - HumanBody.GRAB_OFF_SKIN


func test_shot_in_the_arm_the_other_hand_goes_to_it() -> void:
	var man := await _man()
	await _shoot(man, &"upper_arm_r", Vector3(0.2025, 1.235, -0.0175))
	check(not man._grab.is_empty() and man._grab.side == "l", "his left hand goes to his right arm")
	check(man._grab.get("t", 1.0) < HumanBody.GRAB_DELAY and man._grab.get("w", 1.0) == 0.0,
			"not at once: a beat first, no flinch (%.2f s in)" % man._grab.get("t", 1.0))
	await physics_frames(60)
	check(man._grab.get("w", 0.0) > 0.99, "and then it's there (%.2f)" % man._grab.get("w", 0.0))
	check(_palm_to_hole(man) < 0.03, "his palm over the hole (%.1f cm)" % (_palm_to_hole(man) * 100.0))


func test_the_gun_hand_keeps_his_gun() -> void:
	var man := await _man(true)
	await _shoot(man, &"upper_arm_l", Vector3(-0.2025, 1.235, -0.0175))
	check(man._grab.is_empty(), "shot in his left arm with his gun in his right: no hand to spare")
	check(not man.gun_holstered and man.held_gun != null, "he keeps his gun")


func test_a_shot_hand_is_held_in_front_of_him() -> void:
	var man := await _man()
	await _shoot(man, &"hand_r", Vector3(0.2375, 0.815, -0.011))
	await physics_frames(70)
	check(not man._grab.is_empty() and man._grab.side == "l", "the left hand holds the right")
	check(_palm_to_hole(man) < 0.04, "on the wound (%.1f cm)" % (_palm_to_hole(man) * 100.0))
	var hand: Vector3 = man.to_local((man.parts[&"hand_r"] as Node3D).global_position)
	check(hand.z < -0.1 and absf(hand.x) < 0.2, "brought in, in front of him (%s)" % hand)


func test_out_of_reach_he_leaves_it() -> void:
	var man := await _man()
	await _shoot(man, &"shin_r", Vector3(0.1, 0.3, -0.02))
	await physics_frames(60)
	check(man._grab.is_empty(), "standing, his hand can't reach his shin")
