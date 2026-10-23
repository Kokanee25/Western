extends TestCase
## Fixtures from the prop kit fitted to their place (PropKit.fit, spawn_fitted): a counter as long
## as its room, shelves as high as their wall, a table at a cot's height, the trough at any
## length; each stands as built, and what's on it comes down when it goes.


func _members(p: KitProp) -> Dictionary:
	var out := {}
	for m in p.get_members():
		out[String(m.member_id).get_slice("/", String(m.member_id).get_slice_count("/") - 1)] = m
	return out


func _spec(def: Dictionary, id: String) -> Dictionary:
	for s: Dictionary in def.members:
		if s.id == id:
			return s
	return {}


func test_a_counter_fitted_to_its_room_keeps_its_ends_at_the_ends_and_its_overhang() -> void:
	var def := PropKit.fit(PropKit.definition(&"counter"), Vector3(3.5, 0.99, 0.7))
	var box := PropKit.bounds(def)
	check_near(box.size.x, 3.5, 0.001, "as long as asked")
	check_near(box.size.z, 0.7, 0.001, "as deep as asked")
	check_near(PropKit.vec(_spec(def, "front").size).x, 3.5, 0.001, "the front runs its length")
	check_near(PropKit.vec(_spec(def, "end_r").at).x, 3.5 * 0.5 - 0.015, 0.001, "its end at the end")
	var front := PropKit.vec(_spec(def, "front").at).z - 0.015
	check_near(front - box.position.z, 0.06, 0.001, "the top overhangs the front by its 6 cm still")


func test_shelves_fitted_higher_keep_their_top_board_under_the_top_and_space_the_rest() -> void:
	var def := PropKit.fit(PropKit.definition(&"shelves"), Vector3(0.4, 2.3, 3.0))
	var ys: Array[float] = []
	for i in 4:
		ys.append(PropKit.vec(_spec(def, "shelf%d" % i).at).y)
	check_near(ys[3], 2.3 - 0.1 + 0.0125 - 0.0125, 0.02, "the top board 0.1 m under the top")
	check(ys[1] - ys[0] > 0.5 and ys[2] - ys[1] > 0.5, "the boards spread up the height (%s)" % [ys])
	check_near(PropKit.vec(_spec(def, "shelf0").size).z, 3.0 - 0.06, 0.001, "each board spans between the uprights")


func test_fitted_fixtures_stand_and_take_their_extras() -> void:
	var world := Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	var cot := PropKit.spawn_fitted(&"table", &"t_cot", Vector3(0.8, 0.45, 1.95), {"top": {"wood": "weathered_pine"}})
	world.add_child(cot)
	var counter := PropKit.spawn_fitted(&"counter", &"t_counter", Vector3(3.0, 0.99, 0.66), {"end_l": null},
			[{"id": "rail", "kind": "trim", "wood": "dark_trim", "size": [0.4, 0.05, 0.06], "at": [0.0, 1.0, 0.0]}])
	counter.position = Vector3(0, 0, 3)
	world.add_child(counter)
	await physics_frames(KitProp.SETTLE_FRAMES + 3)
	for p: KitProp in [cot, counter]:
		check(p.settle().is_empty() and not p.loose, "%s stands as built" % p.structure_id)
	check_near(_members(cot).top.global_position.y, 0.45 - 0.0175, 0.003, "the cot's top at its height")
	check(not _members(counter).has("end_l"), "the end against the wall left out")
	check(_members(counter).has("rail"), "and the extra on it")
	world.queue_free()
	await physics_frames(2)


func test_the_trough_is_built_of_the_kit_at_its_length_and_still_holds_water() -> void:
	var t := WaterTrough.new()
	t.structure_id = &"t_trough"
	t.length = 3.0
	add_child(t)
	await physics_frames(2)
	var m := _members(t)
	check_near((m.bottom as StructureMember).size.x, 3.0, 0.001, "its bottom as long as it is")
	check_near((m.end1 as StructureMember).position.x, 3.0 - 0.02, 0.001, "its far end at the end")
	check(t.is_in_group(&"water_source"), "a bucket fills at it")
	check(t.get_node_or_null(^"Water") != null, "it's full of water")
	t.queue_free()
	await physics_frames(2)
