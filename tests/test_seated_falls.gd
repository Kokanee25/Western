extends TestCase
## A man sat back in the prop kit's chair (pose sit_back) whose back legs are kicked out goes over
## backwards with it and ends on his back (Sean, 2026-10-21; the ragdoll lab's group U).

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


## How many go over at once (the fall turns on the physics engine's body order: what's been made
## before him tips a man over his back or his side; alone ~9 in 10 end on their backs, across 33
## orders, #688's main build 3374), and how many of them must end on their backs.
const KICKED_MEN := 8
const ON_BACK_AT_LEAST := 4


func test_back_legs_kicked_out_he_goes_over_backwards_onto_his_back() -> void:
	# Eight chairs in a row, 4 m apart, each facing -z as its man does, its seat point over his
	# origin (as the lab's kit_chair): one fall is one draw of the engine's order, so most of them
	# must end on their backs, not every one.
	var chairs: Array[KitProp] = []
	var men: Array[HumanBody] = []
	for i in KICKED_MEN:
		var x := (i - (KICKED_MEN - 1) * 0.5) * 4.0
		var chair := PropLibrary.spawn(&"chair") as KitProp
		world.add_child(chair)
		chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3(x, 0.0, 0.0))
		var sp := chair.seat_position()
		chair.global_position -= Vector3(sp.x - x, 0.0, sp.z)
		var man := HumanBody.new()
		man.rng_seed = 30 + i
		man.position = Vector3(x, 0.0, 0.0)  # (the world's at the origin)
		world.add_child(man)
		man.set_pose(&"sit_back")
		chairs.append(chair)
		men.append(man)
	await physics_frames(50)
	for i in KICKED_MEN:
		check(chairs[i].sit(men[i]), "he sits (%d)" % i)
	await physics_frames(10)
	var starts: Array[Vector3] = []
	for man in men:
		starts.append((man.parts[&"chest"] as Node3D).global_position)
	# A kick at the foot of each back leg from behind (48 N·s, a kicking leg's 8 kg).
	for i in KICKED_MEN:
		var chair := chairs[i]
		var did: Array[StringName] = []
		for id in ["post_back_l", "post_back_r"]:
			var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
			if m and not m.broken:
				did.append(chair.take_blow(m, Vector3(m.global_position.x, 0.12, m.global_position.z), Vector3(0, 0, -48), 8.0))
		check(did.has(&"broke"), "the kick breaks a back leg under him (%d: %s)" % [i, did])
	# The chair goes over on its own balance (KitProp._check_balance, a tick or two on).
	for t in 30:
		if men.all(func(m: HumanBody) -> bool: return m.limp):
			break
		await physics_frames(1)
	# His front in his ragdoll chest's own frame, as he goes over (he faced -z).
	var fronts: Array[Vector3] = []
	for i in KICKED_MEN:
		check(chairs[i].loose, "the chair goes over (%d)" % i)
		check(men[i].limp, "he goes down with it (%d)" % i)
		var chest := men[i].parts[&"chest"] as Node3D
		fronts.append(chest.global_basis.orthonormalized().inverse() * Vector3.FORWARD)
	if not failures.is_empty():
		return
	# Where they lie once they're down (before they get up again: HumanBody.get_up).
	await physics_frames(95)
	var on_back := 0
	var how: PackedStringArray = []
	for i in KICKED_MEN:
		check(men[i].limp, "still down (%d)" % i)
		var chest := men[i].parts[&"chest"] as Node3D
		var up := (chest.global_basis.orthonormalized() * fronts[i]).normalized().dot(Vector3.UP)
		var behind := chest.global_position.z - starts[i].z
		check(behind > 0.2, "behind where he sat (%d: %.2f m)" % [i, behind])
		if up > 0.5:
			on_back += 1
		how.append("%.2f" % up)
	check(on_back >= ON_BACK_AT_LEAST, "most end on their backs (%d of %d; their chests' fronts up: %s)" % [on_back, KICKED_MEN, ", ".join(how)])


## How far his upper arm hangs away from his trunk (degrees): ~0-25 sat with his hands in his lap.
func _arm_out(man: HumanBody, side: String) -> float:
	var arm := man.parts[StringName("upper_arm_" + side)] as Node3D
	var chest := man.parts[&"chest"] as Node3D
	return rad_to_deg((-arm.global_basis.y).angle_to(-chest.global_basis.y))


func _seated_kicked_over(dead: bool) -> HumanBody:
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var sp := chair.seat_position()
	chair.global_position -= Vector3(sp.x, 0.0, sp.z)
	var man := HumanBody.new()
	world.add_child(man)
	man.set_pose(&"sit_back")
	await physics_frames(50)
	chair.sit(man)
	await physics_frames(10)
	if dead:
		man.physiology.alive = false
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken:
			chair.take_blow(m, Vector3(m.global_position.x, 0.12, m.global_position.z), Vector3(0, 0, -48), 8.0)
	for i in 30:
		if man.limp:
			break
		await physics_frames(1)
	return man


func test_awake_he_throws_his_arms_out_as_his_chair_goes() -> void:
	# HumanBody.brace: awake, his arms go out and his chin tucks in (Sean, 2026-10-22).
	var man: HumanBody = await _seated_kicked_over(false)
	check(man.limp, "he goes over with the chair")
	await physics_frames(20)
	var out := maxf(_arm_out(man, "r"), _arm_out(man, "l"))
	check(out > 45.0, "an arm flung out from his side (%.0f deg)" % out)


func test_dead_in_his_chair_his_hands_stay_in_his_lap() -> void:
	var man: HumanBody = await _seated_kicked_over(true)
	await physics_frames(20)
	if man.limp:
		var out := maxf(_arm_out(man, "r"), _arm_out(man, "l"))
		check(out < 45.0, "no arm flung out (%.0f deg)" % out)
