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
