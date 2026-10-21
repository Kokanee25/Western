extends TestCase
## The material lab's stand (roadmap 1.4a, tools/material_lab.gd): every board's cut ends flagged
## for end grain, its long faces flagged with its own place along its strip, no board drawing the
## same strip as the one beside it, and the wood under test on its parts only.


func _stand(material: StringName) -> MaterialStand:
	var s := MaterialStand.new()
	s.material = material
	s.build()
	return s


func test_every_board_has_its_cut_ends_in_end_grain() -> void:
	var s := _stand(&"")
	var boards := 0
	for wood in s.boards:
		boards += (s.boards[wood] as Array).size()
	var ends := 0
	var long := 0
	for mi in s.find_children("*", "MeshInstance3D", true, false):
		var a: Array = (mi as MeshInstance3D).mesh.surface_get_arrays(0)
		var cols: PackedColorArray = a[Mesh.ARRAY_COLOR]
		# Six vertices a face (two triangles).
		for i in range(0, cols.size(), 6):
			if cols[i].g < 0.5 and cols[i].r > 0.5:
				ends += 1
			elif cols[i].g < 0.5:
				long += 1
	check_eq(ends, boards * 2, "two cut ends a board")
	check_eq(long, boards * 4, "four long faces a board, each flagged with its strip offset")
	s.free()


func test_no_board_shares_a_strip_with_the_one_beside_it() -> void:
	var s := _stand(&"")
	for wood in s.boards:
		var by_part := {}
		for b in s.boards[wood]:
			if not by_part.has(b.part):
				by_part[b.part] = []
			by_part[b.part].append(b.strip)
		for part in by_part:
			var picks: Array = by_part[part]
			if WoodMaterials.strip_count(wood) < 2:
				continue
			for i in range(1, picks.size()):
				check(picks[i] != picks[i - 1], "%s %s: board %d and %d differ" % [wood, part, i - 1, i])
	s.free()


func test_the_wood_under_test_goes_on_its_parts_only() -> void:
	var s := _stand(&"store_boards")
	check(s.boards.has(&"store_boards"), "the store's boards on the wall")
	check(not s.boards.has(&"saloon_red"), "the saloon's red off it")
	check(s.boards.has(&"floor"), "the deck stays the game's floor")
	check_eq(s.focus_parts(), [&"siding", &"siding_low"], "judged on the wall")
	s.free()


func test_boards_are_their_real_sizes() -> void:
	var s := _stand(&"")
	for b in s.boards[&"floor"]:
		if b.part == &"deck":
			check_near(b.size.z, 0.045, 0.0001, "deck planks 45 mm")
			check_near(b.size.y, 0.15, 0.0001, "and 150 mm wide")
	for b in s.boards[&"timber"]:
		check(b.size.y >= 0.15 and b.size.z >= 0.15, "posts and beam 150 mm or more")
	s.free()


func test_the_oak_stairs_strings_clear_the_floor_and_the_first_step() -> void:
	# Sean, 2026-10-21: the open string ran through the bullnose step to the floor.
	var s := OakStair.new()
	s.build()
	var low := INF
	var on_step := INF
	for mi in (s.part_nodes[&"oak_strings"] as Node).find_children("*", "MeshInstance3D", true, false):
		for v in (mi as MeshInstance3D).mesh.get_faces():
			low = minf(low, v.y)
			if v.x < -0.001 and v.z < OakStair.GOING:
				on_step = minf(on_step, v.y)
	check(low >= 0.0, "no string under the floor (lowest %.3f)" % low)
	check(on_step >= OakStair.STEP_RISE, "the open string sits on the first step (lowest there %.3f)" % on_step)
	s.free()


func test_the_solid_oak_stair_can_be_stood_and_fallen_on() -> void:
	# Sean, 2026-10-21: the ragdoll session's stairs. A ray down onto each tread stops at its top;
	# down onto the rail it stops at the rail; the runner and the lobby's boards add no shapes.
	var s := OakStair.new()
	s.solid = true
	s.room = false
	add_child(s)
	s.build()
	await physics_frames(2)
	var space := s.get_world_3d().direct_space_state
	for i in [0, 5, 11]:
		var z: float = i * OakStair.GOING + OakStair.GOING * 0.5
		var x := OakStair.WIDTH * 0.5
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(s.to_global(Vector3(x, 4.0, z)), s.to_global(Vector3(x, -1.0, z))))
		check(not hit.is_empty(), "tread %d is solid" % i)
		if not hit.is_empty():
			check_near(s.to_local(hit.position).y, (i + 1) * OakStair.STEP_RISE, 0.01, "tread %d stops a fall at its top" % i)
	var zr := 6.5 * OakStair.GOING
	var rail := space.intersect_ray(PhysicsRayQueryParameters3D.create(s.to_global(Vector3(0.0, 4.0, zr)), s.to_global(Vector3(0.0, 0.5, zr))))
	check(not rail.is_empty() and s.to_local(rail.position).y > s.pitch_y(zr) + 0.6, "the rail catches a body over the open side")
	var body := s.get_node(^"Collision") as StaticBody3D
	check(body != null and body.collision_layer == Layers.WORLD, "on the world's layer")
	s.queue_free()
