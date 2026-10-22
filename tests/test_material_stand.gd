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
	# By area (a worn tread is more than six faces): the end-grain faces cover every board's two
	# cut ends, the flagged long faces its four sides, to within what the treads' rounding takes off.
	var s := _stand(&"")
	var ends_want := 0.0
	var long_want := 0.0
	for wood in s.boards:
		for b in s.boards[wood]:
			var z: Vector3 = b.size
			ends_want += 2.0 * z.y * z.z
			long_want += 2.0 * z.x * (z.y + z.z)
	var ends := 0.0
	var long := 0.0
	for mi in s.find_children("*", "MeshInstance3D", true, false):
		var a: Array = (mi as MeshInstance3D).mesh.surface_get_arrays(0)
		var cols: PackedColorArray = a[Mesh.ARRAY_COLOR]
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count := idx.size() if idx.size() > 0 else vs.size()
		for t in range(0, count, 3):
			var k := [t, t + 1, t + 2] if idx.is_empty() else [idx[t], idx[t + 1], idx[t + 2]]
			var area := ((vs[k[1]] - vs[k[0]]) as Vector3).cross(vs[k[2]] - vs[k[0]]).length() * 0.5
			check(cols[k[0]].g < 0.5, "every face flagged")
			if cols[k[0]].r > 0.5:
				ends += area
			else:
				long += area
	check_near(ends / ends_want, 1.0, 0.02, "two cut ends a board in end grain")
	check_near(long / long_want, 1.0, 0.02, "four long faces a board, each flagged with its strip offset")
	s.free()


func test_the_treads_are_worn_round_most_in_the_middle() -> void:
	# Sean, 2026-10-21: the stairs' edges round from foot traffic. On the second tread (no
	# bullnose), the top is worn lower in the middle than at the strings, and at the wall string
	# the flat top runs to within the small round's reach of the nosing.
	var s := OakStair.new()
	s.room = false
	s.build()
	var top := OakStair.STEP_RISE * 2.0
	var nose := OakStair.GOING - OakStair.NOSE
	var lowest_mid := INF
	var top_at_string := false
	for mi in (s.part_nodes[&"oak_treads"] as Node).find_children("*", "MeshInstance3D", true, false):
		for v in (mi as MeshInstance3D).mesh.get_faces():
			if absf(v.y - top) > 0.01 or v.z < nose - 0.001 or v.z > OakStair.GOING * 2.0 - OakStair.NOSE:
				continue
			if absf(v.x - OakStair.WIDTH * 0.5) < 0.05:
				lowest_mid = minf(lowest_mid, v.y)
			if v.x > OakStair.WIDTH - 0.001 and absf(v.y - top) < 0.0005 and v.z < nose + OakStair.NOSING_WEAR.x + 0.001:
				top_at_string = true
	check(lowest_mid < top - 0.001, "the middle of the tread worn down (top %.4f against %.4f)" % [lowest_mid, top])
	check(top_at_string, "at the string the round is only the moulding's (%.0f mm)" % (OakStair.NOSING_WEAR.x * 1000.0))
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


func test_the_stairs_walkway_has_a_railing_to_fall_over() -> void:
	# Sean, 2026-10-21: "a small walk way at the top of the stairs with a railing for a body to
	# fall over". Its floor holds at the landing's height; its front railing stops a body at waist
	# height, a metre over the floor, and below it is the lobby's floor 2.47 m down.
	var s := OakStair.new()
	s.solid = true
	add_child(s)
	s.build()
	await physics_frames(2)
	var space := s.get_world_3d().direct_space_state
	var ly := s.landing_y()
	var wz := s._walk_z()
	var mid := Vector3(-OakStair.WALK_LENGTH * 0.5, 0.0, (wz.x + wz.y) * 0.5)
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(s.to_global(mid + Vector3(0.07, 4.0, 0.0)), s.to_global(mid + Vector3(0.07, -1.0, 0.0))))
	check(not floor_hit.is_empty() and absf(s.to_local(floor_hit.position).y - ly) < 0.01, "the walkway's floor at the landing's height")
	var waist := space.intersect_ray(PhysicsRayQueryParameters3D.create(s.to_global(mid + Vector3(0.0, ly + 0.95, 0.0)), s.to_global(mid + Vector3(0.0, ly + 0.95, -2.0))))
	check(not waist.is_empty() and s.to_local(waist.position).z > wz.x - 0.1, "the front railing stops a body at the walkway's edge")
	var over := space.intersect_ray(PhysicsRayQueryParameters3D.create(s.to_global(mid + Vector3(0.0, ly + 1.3, 0.0)), s.to_global(mid + Vector3(0.0, ly + 1.3, -2.0))))
	check(over.is_empty(), "nothing above the railing: a body can go over it")
	var drawn := (s.part_nodes[&"oak_rail"] as Node).find_children("*", "MeshInstance3D", true, false)
	check(not drawn.is_empty(), "the rails are drawn, not only solid")
	s.queue_free()


func test_the_interior_stand_builds_profiled_and_square() -> void:
	# The saloon's woodwork (docs/briefs/interior-woodwork.md): built both ways, every piece's every
	# face flagged (long or end grain), and the profiled one has more to it than the square one.
	var tris := {}
	for profiled in [true, false]:
		var s := InteriorStand.new()
		s.profiled = profiled
		s.build()
		var n := 0
		for mi in s.find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).mesh
			if not (m is ArrayMesh) or (mi as MeshInstance3D).material_override is StandardMaterial3D:
				continue
			var a: Array = m.surface_get_arrays(0)
			if a[Mesh.ARRAY_COLOR] == null:
				continue  # the lathe's turnings and brass
			var cols: PackedColorArray = a[Mesh.ARRAY_COLOR]
			for c in cols:
				if c.g > 0.5:
					check(false, "an unflagged face (profiled %s)" % profiled)
					break
			n += cols.size() / 3
		tris[profiled] = n
		for part in [&"int_wainscot", &"int_bar", &"int_posts", &"int_brackets", &"int_rail", &"oak_balusters"]:
			check(s.part_nodes.has(part), "%s built (profiled %s)" % [part, profiled])
		s.free()
	check(tris[true] > tris[false] * 2, "profiles add shape (%d against %d triangles)" % [tris[true], tris[false]])


func test_every_profile_is_closed_and_counter_clockwise() -> void:
	for runs in [Profiles.rect(0.1, 0.02), Profiles.chamfered(0.2, 0.2, 0.02), Profiles.rounded(0.18, 0.03, 0.008, [1]),
			Profiles.bar_top(0.7, 0.05), Profiles.handrail(0.075, 0.06), Profiles.ogee(0.06, 0.045), Profiles.beaded(0.148, 0.02, 0.006)]:
		for i in runs.size():
			var a: PackedVector2Array = runs[i]
			var b: PackedVector2Array = runs[(i + 1) % runs.size()]
			check(a[a.size() - 1].distance_to(b[0]) < 1e-5, "each run starts where the last ended")
		var ring := Profiles.outline(runs)
		check(not Geometry2D.is_polygon_clockwise(ring), "counter-clockwise (outward normals)")
		check(Geometry2D.triangulate_polygon(ring).size() >= 3, "fills (its ends in end grain)")


func test_the_interior_woods_are_in_the_game() -> void:
	# Sean picked the interior stain (C, 2026-10-21): four woods in the game's woods set, each with
	# its strips and end grain, drawn with seams a pixel wide; the outside's woods untouched.
	for wood in [&"int_floor", &"int_timber", &"int_boards", &"int_oak"]:
		check(WoodMaterials.strip_count(wood) >= 7, "%s has its boards (%d)" % [wood, WoodMaterials.strip_count(wood)])
		var m := WoodMaterials.get_material(wood, 0) as ShaderMaterial
		check(m != null and m.get_shader_parameter(&"edge_aa") == true, "%s drawn with seams a pixel wide" % wood)
		check(m.get_shader_parameter(&"end_tex") is Texture2D, "%s has its end grain" % wood)
	var outside := WoodMaterials.get_material(&"floor", 0) as ShaderMaterial
	check(outside.get_shader_parameter(&"edge_aa") != true, "the outside's floor as it was")


func test_the_bar_is_a_kit_prop_drawn_as_woodwork() -> void:
	# The saloon's bar (assets/props/kit/bar.json): members (so it breaks and burns), drawn with the
	# woodwork shapes (profile, panel, cut), its top in the polished interior bar top.
	check(PropKit.has(&"bar"), "the bar's kit file")
	var def := PropKit.definition(&"bar")
	var members := PropKit.expand(def)
	check(members.size() >= 25, "its members laid out (%d)" % members.size())
	var shapes := {}
	for mspec in members:
		if mspec.has("draw"):
			shapes[mspec.draw.shape] = true
	for s in ["profile", "panel", "cut"]:
		check(shapes.has(s), "drawn with %s" % s)
	var top: Dictionary = members.filter(func(x): return x.id == "top")[0]
	check(String(top.look) == "wood:int_bar_top", "its top the polished bar top")
	check(WoodMaterials.strip_count(&"int_bar_top") >= 3, "the bar top's wood in the game")
	var m := StructureMember.new()
	m.member_id = &"top"
	m.size = PropKit.vec(top.size)
	var mesh := PropKit.draw_mesh(top.draw, m)
	var aabb := mesh.get_aabb()
	check(aabb.size.distance_to(m.size) < 0.01, "the top's drawn shape fills its box (%s against %s)" % [aabb.size, m.size])
	m.free()


## A building's own members drawn as woodwork (PropKit.dress_member): the saloon's wainscot, casings
## and chamfered posts are members (they break, burn, fall) and draw in one batch a look.
class _Dressed extends Structure:
	func build() -> void:
		for i in 3:
			var m := add_member("post%d" % i, &"post", &"oak", Vector3(0.2, 3.0, 0.2), Vector3(i * 1.0, 1.5, 0.0))
			PropKit.dress_member(m, {"shape": "profile", "profile": "chamfered", "along": "y", "across": "x", "up": "z",
					"args": [0.02]}, "wood:int_timber")


func test_a_buildings_members_are_drawn_as_woodwork() -> void:
	var s := _Dressed.new()
	add_child(s)
	await physics_frames(2)
	var m: StructureMember = s.get_members()[0]
	var mi := m.get_child(0) as MeshInstance3D
	check(mi.mesh.get_faces().size() > 36, "the post drawn chamfered, not a box (%d)" % mi.mesh.get_faces().size())
	check(mi.mesh.get_aabb().size.distance_to(m.size) < 0.01, "its drawn shape fills its box")
	check(s.batch_count() == 1, "three posts in one wood draw in one batch (%d)" % s.batch_count())
	s.free()


func test_a_set_with_light_bands_steps_its_woods_light() -> void:
	# Round 6 (2026-10-22): a set's lab.json "light_bands" draws its woods with the blocks light at
	# that many steps (the men's painted bands), on the woods only; the game's woods keep theirs.
	if not FileAccess.file_exists("res://assets/textures/mlab_studio9/lab.json"):
		return  # a cut set, not in git
	var m := PixelArt.material(load("res://assets/textures/mlab_studio9/floor_b0.png"))
	check(m.shader == PixelArt.GRID_SHADER_BLOCKS, "the set's woods take the banded light")
	check(float(m.get_shader_parameter(&"wood_bands")) == 4.0, "at the set's steps")
	check(PixelArt.hole_material(m).shader == PixelArt.HOLE_SHADER_BLOCKS, "and keep it when shot")
	var g := PixelArt.material(load("res://assets/textures/woods/floor_b0.png"))
	check(g.shader == PixelArt.grid_shader(), "the game's woods as the world's")


func test_the_back_bar_mirrors_paint_the_room() -> void:
	# The back bar's mirrors (prop:mirror) paint the lamplit room they give back (mirror.gdshader).
	var m := PropKit.material("prop:mirror", 0) as ShaderMaterial
	check(m != null and m.shader != null and m.shader.resource_path.ends_with("mirror.gdshader"), "the painted reflection")
	check(m.shader.get_code().contains("room_depth"), "a room in front of the glass")
