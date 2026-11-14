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


## Getting up among his broken chair's pieces and knocked down again as he rises (#834: Earl), the
## ragdoll that takes his rising rig's place is put in among the pieces the rig was let through
## (HumanBody._spare_rubble): those in him are let through it too, till they're clear of him, so the
## engine doesn't shove them out at him (eight blows of 8 to 36 J on Earl's thigh, pelvis and shin: he
## never stood again); he gets up after.
func test_knocked_down_as_he_rises_among_the_pieces_they_dont_break_him() -> void:
	var man: HumanBody = await _seated_kicked_over(false)
	check(man.limp, "he goes over with the chair")
	await physics_frames(90)
	man.get_up()
	check(man.rising, "he's getting up")
	await physics_frames(3)
	check(not man._spared.is_empty(), "the chair's pieces let through his rising body")
	# The seat, right in his hips as he goes down again (as the engine had Earl's).
	var piece: RigidBody3D = man._spared[0]
	for rb: RigidBody3D in man._spared:
		if rb.mass > piece.mass:
			piece = rb
	RubbleRest.let_go(piece)
	piece.global_transform = Transform3D(piece.global_basis, (man.parts[&"pelvis"] as Node3D).global_position)
	piece.linear_velocity = Vector3.ZERO
	var blows := []
	var on_hit := func(info: Dictionary) -> void:
		if info.get("person") == man and info.get("kind") == &"blow" and not info.has("pushed"):
			blows.append(info)
	Events.body_hit.connect(on_hit)
	man.go_limp()
	man.brace()
	await physics_frames(1)
	# What the engine would push it against now, its exceptions honoured (the man's parts or not).
	var tm := PhysicsTestMotionParameters3D.new()
	tm.from = piece.global_transform
	tm.motion = Vector3.UP * 0.01
	tm.recovery_as_collision = true
	tm.max_collisions = 16
	var res := PhysicsTestMotionResult3D.new()
	var touched := []
	if PhysicsServer3D.body_test_motion(piece.get_rid(), tm, res):
		for i in res.get_collision_count():
			var b := res.get_collider(i) as Node
			if b != null and b.has_meta(&"human_body") and b.get_meta(&"human_body") == man and not touched.has(b.name):
				touched.append(b.name)
	check(touched.is_empty(), "the seat in him is let through the body he falls in (in %s)" % [touched])
	await physics_frames(50)
	Events.body_hit.disconnect(on_hit)
	check_eq(blows.size(), 0, "no blows from the pieces he's put down in (%s)" % [blows.map(
			func(b: Dictionary) -> String: return "%s %.0f J" % [b.segment, b.joules])])
	check(man.physiology.can_stand(), "his legs his own")
	# Clear of him, it's his to meet again.
	RubbleRest.let_go(piece)
	piece.global_position += Vector3(0, 0, 1.5) + Vector3(1.5, 0.3, 0)
	await physics_frames(30)
	check(not man._spared.has(piece), "once it's clear of him, not let through any more")
	var up := await wait_until(func() -> bool: return not man.limp and not man.rising, 60 * 12)
	check(up, "and he gets up again")


## Getting up beside a building (#925): the pieces let through his rising body are every loose one in
## reach, however many standing members are in reach with them. The space's query gives so many
## shapes and no more (64, then): by the saloon's wall the standing ones filled it, the chair's
## pieces weren't let through, and the engine flung them out of him (3.8 kJ on Earl's thigh as he
## rose: broken, he never stood again; beside 90 standing bodies 3 kicked men in 48 never rose and
## 2 more were hurt, none of 480 with nothing by them).
func test_getting_up_by_a_wall_every_piece_in_reach_is_let_through() -> void:
	# A wall's worth of standing members a step from him: 240 posts within the reach.
	for i in 240:
		var post := StaticBody3D.new()
		post.collision_layer = Layers.WORLD
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.04, 2.0, 0.04)
		shape.shape = box
		post.add_child(shape)
		post.position = Vector3(-1.8 + (i % 60) * 0.06, 1.0, 1.2 + (i / 60) * 0.06)
		world.add_child(post)
	var man: HumanBody = await _seated_kicked_over(false)
	check(man.limp, "he goes over with the chair")
	await physics_frames(90)
	var blows := []
	var on_hit := func(info: Dictionary) -> void:
		if info.get("person") == man and info.get("kind") == &"blow" and float(info.get("joules", 0.0)) > 60.0:
			blows.append("%s %.0f J" % [info.segment, info.joules])
	Events.body_hit.connect(on_hit)
	var pelvis := (man.parts[&"pelvis"] as Node3D).global_position
	man.get_up()
	check(man.rising, "he's getting up")
	var near := 0
	var missed := []
	for n: Node in get_tree().get_nodes_in_group(&"rubble"):
		var rb := n as RigidBody3D
		if rb == null or not world.is_ancestor_of(rb) or rb.global_position.distance_to(pelvis) > HumanBody.SPARE_RADIUS - 0.5:
			continue
		near += 1
		if not man._spared.has(rb):
			missed.append(rb.name)
	check(near >= 3, "the chair's pieces lie about him (%d)" % near)
	check(missed.is_empty(), "every loose piece in reach is let through his rising body (%d of %d not: %s)" % [missed.size(), near, missed.slice(0, 5)])
	var up := await wait_until(func() -> bool: return not man.limp and not man.rising, 60 * 12)
	Events.body_hit.disconnect(on_hit)
	check(up, "he gets up")
	check(blows.is_empty(), "nothing flung at him as he rose (%s)" % [blows])
	check(man.physiology.can_stand(), "his legs his own (%s)" % man.physiology.describe())
