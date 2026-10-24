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


func test_back_legs_kicked_out_he_goes_over_backwards_onto_his_back() -> void:
	# The chair faces -z as he does, its seat point over his origin (as the lab's kit_chair).
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var sp := chair.seat_position()
	chair.global_position -= Vector3(sp.x, 0.0, sp.z)
	var man := HumanBody.new()
	world.add_child(man)
	man.set_pose(&"sit_back")
	await physics_frames(50)
	check(chair.sit(man), "he sits")
	await physics_frames(10)
	var start := (man.parts[&"chest"] as Node3D).global_position
	# A kick at the foot of each back leg from behind (48 N·s, a kicking leg's 8 kg).
	var did: Array[StringName] = []
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken:
			did.append(chair.take_blow(m, Vector3(m.global_position.x, 0.12, m.global_position.z), Vector3(0, 0, -48), 8.0))
	check(did.has(&"broke"), "the kick breaks a back leg under him (%s)" % [did])
	# The chair goes over on its own balance (KitProp._check_balance, a tick or two on).
	for i in 30:
		if man.limp:
			break
		await physics_frames(1)
	check(chair.loose, "the chair goes over")
	check(man.limp, "he goes down with it")
	if not man.limp:
		return
	# His front in his ragdoll chest's own frame, as he goes over (he faced -z).
	var chest := man.parts[&"chest"] as Node3D
	var front_local := chest.global_basis.orthonormalized().inverse() * Vector3.FORWARD
	# Where he lies once he's down (before he gets up again: HumanBody.get_up).
	await physics_frames(95)
	check(man.limp, "still down")
	var up := (chest.global_basis.orthonormalized() * front_local).normalized().dot(Vector3.UP)
	check(up > 0.5, "he ends on his back (his chest's front %.2f up)" % up)
	check(chest.global_position.z > start.z + 0.2, "behind where he sat (%.2f m)" % (chest.global_position.z - start.z))


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


## The chair, its seat point over the origin, facing -z (as the lab's kit_chair), and a man sat back
## in it.
func _seated() -> Array:
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
	return [chair, man]


func _kick_back_legs(chair: KitProp) -> void:
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken:
			chair.take_blow(m, Vector3(m.global_position.x, 0.12, m.global_position.z), Vector3(0, 0, -48), 8.0)


func test_kicked_out_back_legs_leave_the_chairs_back_on_its_seat() -> void:
	# KitProp.knock_out: a kick takes the leg below the seat; the post above it, the crest and the
	# spindles stay on the seat (broken whole, the back fell away and he sank between the front legs).
	var got: Array = await _seated()
	var chair: KitProp = got[0]
	_kick_back_legs(chair)
	await physics_frames(3)
	var with_seat: Array = []
	for rb in chair.rubble:
		if is_instance_valid(rb) and (rb.get_meta(&"members", []) as Array).has(StringName("%s/seat" % chair.structure_id)):
			with_seat = rb.get_meta(&"members")
	check(with_seat.has(StringName("%s/crest" % chair.structure_id)), "the crest goes with the seat (%s)" % [with_seat])


func test_he_tips_back_with_the_chair_head_first() -> void:
	# HumanBody.ride and the tone across the light links: the chair pivots on its front legs and his
	# head and shoulders lead back; before, he sank straight down, his head coming 13 cm forward.
	var got: Array = await _seated()
	var chair: KitProp = got[0]
	var man: HumanBody = got[1]
	var pelvis0: float = (man.parts[&"pelvis"] as Node3D).global_position.y
	var head0: float = (man.parts[&"head"] as Node3D).global_position.z
	_kick_back_legs(chair)
	var back := -1.0
	for i in 90:
		await physics_frames(1)
		if man.limp and pelvis0 - (man.parts[&"pelvis"] as Node3D).global_position.y >= 0.15:
			back = (man.parts[&"head"] as Node3D).global_position.z - head0
			break
	check(back > 0.02, "his head has gone back %.2f m as his hips drop 15 cm" % back)


func test_his_head_doesnt_loll_back_as_he_goes_over() -> void:
	# Braced, his chin tucks; held only by the neck's own (capped) tone it fell back 36-42 degrees.
	var got: Array = await _seated()
	var chair: KitProp = got[0]
	var man: HumanBody = got[1]
	_kick_back_legs(chair)
	await physics_frames(2)
	if not man.limp:
		check(false, "he goes over")
		return
	var chest := man.parts[&"chest"] as Node3D
	var head := man.parts[&"head"] as Node3D
	var tilt0 := _head_back(chest, head)
	var most := -INF
	for i in 60:
		await physics_frames(1)
		most = maxf(most, _head_back(chest, head) - tilt0)
	check(most < 20.0, "his head goes back at most %.0f deg on his chest" % most)


func _head_back(chest: Node3D, head: Node3D) -> float:
	var up := chest.global_basis.orthonormalized().inverse() * head.global_basis.orthonormalized().y
	return rad_to_deg(atan2(up.z, up.y))


func test_a_mans_kick_takes_the_back_legs_out_and_puts_him_on_his_back() -> void:
	# HumanBody.kick: from the sat man's right, a low kick at the near back leg breaks it and goes on
	# into the far one (KitProp.take_blow); no leg is broken by script.
	var got: Array = await _seated()
	var chair: KitProp = got[0]
	var man: HumanBody = got[1]
	var near := chair.get_member(StringName("%s/post_back_l" % chair.structure_id))
	var at := Vector3(near.global_position.x, 0.07, near.global_position.z)
	var kicker := HumanBody.new()
	world.add_child(kicker)
	kicker.global_position = Vector3(1.5, 0.0, at.z)
	await physics_frames(5)
	kicker.global_position = kicker.kick_spot(at, kicker.global_position)
	await physics_frames(30)
	check(kicker.kick(at, &"front"), "he can kick it from there")
	# Kicked, he steps back out of the way (as the lab's kicker; a man does).
	var away := kicker.global_position + (kicker.global_position - at) * Vector3(1, 0, 1) * 2.0
	for i in 40:
		await physics_frames(1)
		if not kicker.kicking():
			kicker.walk_to(away, 1.6, 1.0 / 60.0, false)
		if man.limp:
			break
	var far := chair.get_member(StringName("%s/post_back_r" % chair.structure_id))
	check(near.broken and far.broken, "both back legs out (near %s, far %s)" % [near.broken, far.broken])
	check(man.limp, "he goes over")
	for i in 60:
		await physics_frames(1)
		kicker.walk_to(away, 1.6, 1.0 / 60.0, false)
	var chest := man.parts[&"chest"] as Node3D
	check((-chest.global_basis.z).y > 0.5, "on his back (%.2f)" % (-chest.global_basis.z).y)


func test_the_players_kick_breaks_a_chair_leg() -> void:
	# PlayerKick (E): the boot's sweep in front of you meets the leg and KitProp.take_blow breaks it.
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	await physics_frames(30)
	var leg := chair.get_member(StringName("%s/post_back_l" % chair.structure_id))
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
	player.input_enabled = false
	world.add_child(player)
	# Stood facing the leg, 0.5 m off it.
	player.global_position = Vector3(leg.global_position.x + 0.5, 0.0, leg.global_position.z)
	player.global_rotation.y = PI / 2.0
	await physics_frames(10)
	var result := [&""]
	player.kick.kicked.connect(func(r: StringName, _w: Node) -> void: result[0] = r)
	player.kick._strike()
	check(result[0] == &"broke", "the leg breaks (%s)" % result[0])
	check(leg.broken, "and is out")
	player.queue_free()
