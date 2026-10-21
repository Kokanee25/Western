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


func test_every_board_carries_where_it_weathers() -> void:
	# Round 3's weathering layer (texel_grid `weathered`): each board's ground, drip line and
	# amount in CUSTOM0, the siding's nails in CUSTOM1; the wall weathers from the deck it stands on.
	var s := _stand(&"")
	for part in [&"siding", &"deck", &"frame"]:
		var mi := (s.part_nodes[part] as Node).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var a: Array = mi.mesh.surface_get_arrays(0)
		var c0: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM0]
		var c1: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM1]
		var w: Array = MaterialStand.WEATHER[part]
		check_near(c0[0], w[0], 0.0001, "%s: its ground" % part)
		check_near(c0[1], w[1], 0.0001, "%s: its drip line" % part)
		check_near(c0[2], w[2], 0.0001, "%s: how much" % part)
		check_eq(c1[0] > 0.0, part == &"siding", "%s: nails on the siding only" % part)
	check_near((MaterialStand.WEATHER[&"siding"] as Array)[0], MaterialStand.DECK_TOP, 0.0001, "the wall splashes from the deck")
	s.free()


func test_the_oak_stair_indoors_has_no_weather() -> void:
	var s := OakStair.new()
	s.build()
	var mi := (s.part_nodes[&"oak_treads"] as Node).find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	check(mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_CUSTOM0] == null, "no weathering frame indoors")
	s.free()


func test_a_set_with_a_stain_sheet_weathers_its_woods() -> void:
	# The studio6 set's lab.json names its sheet (paint_woods.py --set=studio6 --cut); its woods'
	# materials take it, with the seams a pixel wide; the game's woods don't.
	if not FileAccess.file_exists("res://assets/textures/mlab_studio6/lab.json"):
		return  # a cut set, not in git
	var m := PixelArt.material(load("res://assets/textures/mlab_studio6/floor_b0.png"))
	check(m.get_shader_parameter(&"use_weather") == true, "the set's woods weather")
	check(m.get_shader_parameter(&"weather_tex") is Texture2D, "with its stain sheet")
	check(m.get_shader_parameter(&"edge_aa") == true, "seams a pixel wide")
	var g := PixelArt.material(load("res://assets/textures/woods/floor_b0.png"))
	check(g.get_shader_parameter(&"use_weather") != true, "the game's woods untouched")
	check(g.get_shader_parameter(&"edge_aa") != true, "their seams as they were")
