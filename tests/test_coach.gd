extends TestCase
## The Baron's iron-plated coach and its strongbox (the prop lab, #782; tools/props/coach.py): the
## coach stands on its wheels and pole, weighs what an armoured Concord would, its plates stop a
## ball and its roof's boards don't, its doors open on their hinges and hang on their posts, and the
## strongbox under its rear bench stays shut till its padlock's shot off or its key's turned.

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


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _place(id: StringName, at := Vector3.ZERO) -> KitProp:
	var p := PropKit.spawn(id)
	p.position = at
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 4)
	return p


func _m(p: KitProp, id: String) -> StructureMember:
	return p.get_member(StringName("%s/%s" % [p.structure_id, id]))


func _shoot(from: Vector3, at: Vector3) -> Ballistics.Bullet:
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (at - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(3)
	return b


func test_the_coach_stands_and_weighs_an_armoured_concords_weight() -> void:
	var def := PropKit.definition(&"baron_coach")
	check(def.get("in_game", false) and def.has("factory"), "the factory's, in the game")
	var c := await _place(&"baron_coach")
	check(c.settle().is_empty() and not c.loose, "it stands: nothing breaks or falls")
	check(c.members_without_load_path().is_empty(), "every member has its way down to the ground")
	var feet := c.get_members().filter(func(m: StructureMember) -> bool: return m.grounded)
	check(feet.size() == 5, "five feet: the felloe under each hub and the pole's tip (%d)" % feet.size())
	# A Concord ~1,000-1,130 kg empty; 28 plates of 8 mm iron ~640 kg more.
	var kg := c.mass()
	check(kg >= 1300.0 and kg <= 1800.0, "it weighs %.0f kg empty" % kg)
	# A batch a look and its dress (oak, pine, plate iron, iron, leather): one coach, not a street of them.
	check(c.batch_count() <= 10, "untouched it draws in a few batches (%d)" % c.batch_count())
	check(PropLibrary.spawn(&"baron_coach") is KitProp, "PropLibrary hands it out by name")
	var box := c.carried("strongbox")
	check(box != null and not box.loose, "its strongbox stands under the rear bench")
	if box:
		check(box.mass() >= 35.0 and box.mass() <= 55.0, "the strongbox weighs %.0f kg" % box.mass())
		check(box.global_position.y > 1.0, "on the coach's floor, not the ground (%.2f)" % box.global_position.y)


func test_its_plates_are_members_of_their_own_for_the_dents() -> void:
	var plates: Array = []
	for m: Dictionary in PropKit.definition(&"baron_coach").members:
		if m.get("plate", false):
			plates.append(m)
	check(plates.size() == 28, "28 plates (%d)" % plates.size())
	for p: Dictionary in plates:
		var s: Array = p.size
		check(p.wood == "iron" and absf(float(s.min()) - 0.008) < 1e-4, "%s: iron, 8 mm" % p.id)


func test_a_plate_stops_a_ball_and_the_roof_does_not() -> void:
	var c := await _place(&"baron_coach")
	var plate := _m(c, "plate_l_fore_low")
	var b := await _shoot(plate.global_position + Vector3(0.3, 0.1, -5.0), plate.global_position)
	check(not b.hits.is_empty() and b.hits[0].member_id == plate.member_id, "the ball meets the plate")
	check(not b.hits.is_empty() and not b.hits[0].penetrated, "and doesn't go through it")
	var inside := b.hits.filter(func(h: Dictionary) -> bool: return h.member_id != plate.member_id and String(h.member_id).begins_with(String(c.structure_id)))
	check(inside.is_empty(), "nothing behind it is hit (%d)" % inside.size())
	var roof := _m(c, "roof3")
	var r := await _shoot(roof.global_position + Vector3(0.4, 4.0, 0.1), roof.global_position + Vector3(0.4, 0, 0.1))
	check(not r.hits.is_empty() and r.hits[0].member_id == roof.member_id and r.hits[0].penetrated, "a ball goes through the roof's boards")


func test_the_doors_open_and_hang_on_their_posts() -> void:
	var c := await _place(&"baron_coach")
	var door := _m(c, "plate_l_door_up")
	var shut := door.position
	check(c.open_hinge("door_l"), "the left door opens")
	await physics_frames(2)
	check(door.position.z < shut.z - 0.3, "outward, on the left (z %.2f -> %.2f)" % [shut.z, door.position.z])
	check(c.members_without_load_path().is_empty(), "it hangs on its post, open")
	check(c.settle().is_empty() and not c.loose, "and the coach still stands")
	check(c.open_hinge("door_r", 0.5), "the right door half open")
	check(_m(c, "plate_r_door_up").position.z > 0.75, "outward on the right")
	# Open, it hangs on its post alone: the post shot away, the door goes with it (shut, it stands
	# in its frame on the sill).
	var falling := c.members_without_load_path({_m(c, "post_l_door_fore").member_id: true})
	check(falling.has(door.member_id), "open and without its hinge post the door falls")
	c.open_hinge("door_l", 0.0)
	check(door.position.distance_to(shut) < 0.001, "and shut again where it was")
	check(not c.members_without_load_path({_m(c, "post_l_door_fore").member_id: true}).has(door.member_id), "shut, it stands on its sill")


func test_the_strongbox_opens_only_when_its_lock_is_shot_or_its_key_turned() -> void:
	var box := await _place(&"strongbox")
	check(box.settle().is_empty() and not box.loose, "it stands")
	check(box.is_locked("lid") and not box.open_hinge("lid"), "locked, the lid won't open")
	var wall := _m(box, "end_r")
	var w := await _shoot(wall.global_position + Vector3(5.0, 0.02, 0.03), wall.global_position + Vector3(0, 0.02, 0.03))
	check(not w.hits.is_empty() and w.hits[0].member_id == wall.member_id and not w.hits[0].penetrated, "a ball doesn't go through its wall")
	check(not _m(box, "papers").broken, "the papers are whole")
	var lock := _m(box, "padlock")
	await _shoot(lock.global_position + Vector3(0.05, 0.3, 4.0), lock.global_position)
	check(lock.broken, "a .45 ball breaks the padlock")
	check(not box.is_locked("lid") and box.open_hinge("lid"), "and the lid opens")
	check(_m(box, "lid").position.y > 0.4 or _m(box, "lid").position.z < -0.3, "up and back (%s)" % _m(box, "lid").position)
	var keyed := await _place(&"strongbox", Vector3(3, 0, 0))
	keyed.unlock("lid")
	check(keyed.open_hinge("lid"), "with the key it opens, the lock whole")


func test_two_spokes_out_under_a_hub_and_the_body_still_rides() -> void:
	var c := await _place(&"baron_coach")
	var broken := {_m(c, "hind_r_spoke8").member_id: true, _m(c, "hind_r_spoke9").member_id: true}
	var falling := c.members_without_load_path(broken)
	check(falling.has(_m(c, "hind_r_hub").member_id), "that hub drops")
	check(not falling.has(_m(c, "roof0").member_id), "the body's still carried")
	var both := c.members_without_load_path({_m(c, "brace_l").member_id: true, _m(c, "brace_r").member_id: true})
	check(both.has(_m(c, "sill_l_fore").member_id) and both.has(_m(c, "plate_back_up_a").member_id), "both braces gone, the body comes down")
	check(not both.has(_m(c, "front_axle").member_id), "the running gear stays")
