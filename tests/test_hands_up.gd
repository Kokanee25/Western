extends TestCase
## Hands up (#694, Sean): elbows bent ~90-110 degrees, hands at head height with the palms to you,
## the upper arms out at shoulder height a little forward; and they come up forward and out
## together, elbows bending early, hands leading, in about half a second with a small overshoot,
## not swung out to the sides and over in one flat arc.

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


func _man() -> HumanBody:
	var man := HumanBody.new()
	world.add_child(man)
	return man


## [shoulder, elbow, wrist, the hand's middle, the palm's normal] for one side, in his own frame
## (facing -Z, his right +X, feet at y 0).
func _arm(man: HumanBody, side: String) -> Array:
	var inv := man.global_transform.affine_inverse()
	var ua := man.pivots[StringName("upper_arm_" + side)] as Node3D
	var fa := man.pivots[StringName("forearm_" + side)] as Node3D
	var hd := man.pivots[StringName("hand_" + side)] as Node3D
	var palm := (inv.basis * hd.global_basis * Vector3(-1.0 if side == "r" else 1.0, 0, 0)).normalized()
	return [inv * ua.global_position, inv * fa.global_position, inv * hd.global_position,
			inv * (hd.global_transform * Vector3(0, -0.07, 0)), palm]


func _bend(a: Array) -> float:
	var up: Vector3 = (a[1] as Vector3) - (a[0] as Vector3)
	var lo: Vector3 = (a[2] as Vector3) - (a[1] as Vector3)
	return rad_to_deg(up.angle_to(lo))


func test_the_pose_is_a_surrender_not_arms_straight_up() -> void:
	var man := _man()
	await physics_frames(2)
	man.set_pose(&"hands_up")
	await physics_frames(60)
	var head := (man.pivots[&"head"] as Node3D).global_position.y - man.global_position.y
	for side in ["r", "l"]:
		var a := _arm(man, side)
		var sh: Vector3 = a[0]
		var el: Vector3 = a[1]
		var hand: Vector3 = a[3]
		var sx := 1.0 if side == "r" else -1.0
		check(_bend(a) > 85.0 and _bend(a) < 115.0, "his %s elbow bent %.0f degrees" % [side, _bend(a)])
		check(absf(el.y - sh.y) < 0.12, "his %s upper arm about level with his shoulder (elbow %.2f, shoulder %.2f)" % [side, el.y, sh.y])
		check(el.x * sx > sh.x * sx + 0.15, "his %s elbow out to the side" % side)
		check(el.z < sh.z - 0.03, "his %s elbow a little forward (z %.2f)" % [side, el.z])
		check(hand.y > head - 0.05 and hand.y < head + 0.25, "his %s hand at head height (%.2f, head %.2f)" % [side, hand.y, head])
		check(hand.y > el.y + 0.15, "his %s hand over his elbow" % side)
		var palm: Vector3 = a[4]
		check(palm.dot(Vector3.FORWARD) > 0.8, "his %s palm to the front (%.2f)" % [side, palm.dot(Vector3.FORWARD)])
	var r := _arm(man, "r")
	var l := _arm(man, "l")
	check_near((r[3] as Vector3).x, -(l[3] as Vector3).x, 0.01, "both hands alike")
	check_near((r[3] as Vector3).y, (l[3] as Vector3).y, 0.01, "at the same height")


func test_they_come_up_forward_and_out_quickly_with_a_settle() -> void:
	var man := _man()
	await physics_frames(30)
	var start := _arm(man, "r")
	man.set_pose(&"hands_up")
	var top := -INF
	var widest := -INF
	var forward_early := false
	var bent_early := false
	var heights: Array[float] = []
	for f in 50:
		await physics_frames(1)
		var a := _arm(man, "r")
		var hand: Vector3 = a[3]
		heights.append(hand.y)
		top = maxf(top, hand.y)
		widest = maxf(widest, hand.x)
		var t := (f + 1) / 60.0
		if t <= 0.2 and hand.z < (start[3] as Vector3).z - 0.15:
			forward_early = true
		if t <= 0.15 and _bend(a) > 60.0:
			bent_early = true
	var final := _arm(man, "r")
	var end_y: float = (final[3] as Vector3).y
	check(forward_early, "his hands go forward first, in the first fifth of a second")
	check(bent_early, "his elbows bent early")
	check(heights[35] > end_y - 0.03, "up near the top by 0.6 s (%.2f of %.2f)" % [heights[35], end_y])
	check(top > end_y + 0.015 and top < end_y + 0.12, "a small overshoot (%.3f over)" % (top - end_y))
	check(widest < (final[3] as Vector3).x + 0.1, "never swung out wider than he ends (%.2f, ends %.2f)" % [widest, (final[3] as Vector3).x])


func test_he_lets_them_down_the_short_way() -> void:
	var man := _man()
	await physics_frames(2)
	man.set_pose(&"hands_up")
	await physics_frames(60)
	var up := _arm(man, "r")
	man.set_pose(&"stand")
	var top := -INF
	for f in 45:
		await physics_frames(1)
		top = maxf(top, (_arm(man, "r")[3] as Vector3).y)
	var down := _arm(man, "r")
	check(top <= (up[3] as Vector3).y + 0.01, "his hands don't go up over his head on the way down")
	check((down[3] as Vector3).y < 1.0, "his hands down by his sides (%.2f)" % (down[3] as Vector3).y)


func test_a_snapped_pose_is_there_at_once() -> void:
	var man := _man()
	await physics_frames(2)
	man.set_pose(&"hands_up")
	man._apply_pose(0.0, true)
	var a := _arm(man, "r")
	check(_bend(a) > 85.0, "bent at once (%.0f)" % _bend(a))


func test_a_gang_man_giving_up_is_still_seen_to_give_up() -> void:
	# What the AI and the witnesses go by is his brain's mood and the event (DeedWatch makes it a
	# "surrender" deed where he stands), never how high his arms are: the new pose changes neither.
	var deeds: Array = []
	var on_deed := func(actor: Node, kind: StringName, _t: Node, _at: Vector3) -> void: deeds.append([actor, kind])
	Events.deed.connect(on_deed)
	var man := HumanBody.new()
	var brain := OutlawBrain.new()
	brain.name = "Brain"
	man.add_child(brain)
	world.add_child(man)
	await physics_frames(10)
	brain._surrender()
	check_eq(brain.mood, OutlawBrain.Mood.SURRENDERED, "surrendered, by his brain")
	check(deeds.any(func(d: Array) -> bool: return d[0] == man and d[1] == &"surrender"), "a surrender deed for the witnesses")
	check_eq(man.pose, &"hands_up", "his hands up")
	await physics_frames(45)
	var a := _arm(man, "r")
	var head := (man.pivots[&"head"] as Node3D).global_position.y - man.global_position.y
	check((a[3] as Vector3).y > head - 0.05, "and up at head height (%.2f)" % (a[3] as Vector3).y)
	Events.deed.disconnect(on_deed)
