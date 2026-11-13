extends TestCase
## The valley's ground drawn real and its scatter (#891, art's: ValleyGroundArt, ValleyScatter): the
## ground map baked from this valley.json, what it says at known places (Main Street, a wagon road, the
## creek, a pad, a town lot, the rail bed), the material made, and the scatter: nothing on a road, a
## pad, a lot or the rail bed; the same every run; boulders and trunks in a body a cell; quick to make.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_the_map_is_baked_from_this_valley_json() -> void:
	var art := ValleyGroundArt.main()
	check(art.ready, "the ground map is there (godot --headless -s res://tools/textures/valley_ground_map.gd)")
	var t := ValleyTerrain.main()
	check_eq(Vector2i(art.width, art.depth), Vector2i(t.width, t.depth), "on the bake's grid")
	check_eq(art.valley_json_sha256, String(t.meta.get("valley_json_sha256", "")),
		"baked over the same valley.json as the heights (re-bake: tools/textures/valley_ground_map.gd)")


func test_the_map_knows_the_roads_and_the_town() -> void:
	var art := ValleyGroundArt.main()
	var ms := art.road_at(0.0, 0.0)
	check_eq(int(ms.class), ValleyGroundArt.MAIN_STREET, "Main Street at the crossroads")
	check_near(float(ms.half), 10.05, 0.01, "its half width to the fronts")
	var off := art.road_at(-60.0, 6.0)
	check_eq(int(off.class), ValleyGroundArt.MAIN_STREET, "Main Street west of the crossroads")
	check_near(absf(float(off.across)), 6.0, 0.01, "6 m across its middle")
	# The East Road between its bends (130, 0) -> (300, 40): a wagon road 5 m wide.
	var er := art.road_at(215.0, 20.0)
	check_eq(int(er.class), ValleyGroundArt.WAGON, "the East Road is a wagon road")
	check(absf(float(er.across)) < 1.0, "on its middle (%.2f m)" % float(er.across))
	check(art.off_road(215.0, 20.0) < 0.0, "inside it")
	check(art.off_road(215.0, 60.0) == INF or art.off_road(215.0, 60.0) > 5.0, "40 m off it, clear of it")
	check(art.flags_at(0.0, 30.0).lot, "a town lot behind the south fronts")
	check(art.flags_at(432.0, 470.0).pad, "Harlan's homestead's pad")
	check(art.kept_clear(0.0, 0.0), "nothing grows in Main Street")
	check(art.kept_clear(0.0, 30.0), "nor on a town lot")
	# The creek: somewhere along its line the map is at its bed.
	var line := ValleyLayout.main().water_line("creek")
	var mid := line[line.size() / 2]
	check(art.water_at(mid.x, mid.y) < 2.0, "the creek's line is at its bed (%.1f m)" % art.water_at(mid.x, mid.y))
	check(art.water_at(-1800.0, -1300.0) > 30.0, "the north-west corner is far from water")


func test_the_material_has_its_scans() -> void:
	var art := ValleyGroundArt.main()
	for m: ShaderMaterial in [art.material, art.tile_material]:
		check(m != null and m.shader != null, "a material with its shader")
		for layer in ["dirt", "dry", "grass", "trail", "mud", "rock"]:
			check(m.get_shader_parameter(StringName(layer + "_albedo")) is Texture2D, "%s's albedo" % layer)
			check(m.get_shader_parameter(StringName(layer + "_normal")) is Texture2D, "%s's normal" % layer)
			check(float(m.get_shader_parameter(StringName(layer + "_m"))) > 0.5, "%s's metres a tile" % layer)
	check(art.tile_material.get_shader_parameter(&"dug_tile") == true, "the dug tiles' own")


func _scatter() -> ValleyScatter:
	var s := ValleyScatter.new()
	s.setup(ValleyTerrain.main(), ValleyGroundArt.main(), load("res://config/valley_scatter.tres"))
	world.add_child(s)
	return s


## Every instance's place (world xz) and species, as the cells keep them.
func _instances(s: ValleyScatter) -> Array:
	var out := []
	for cell: Node3D in s.get_children():
		for p: Vector3 in cell.get_meta(&"points", PackedVector3Array()):
			out.append([String(cell.name).get_slice("_", 0), p])
	return out


func test_the_scatter_keeps_off_roads_pads_and_lots() -> void:
	var s := _scatter()
	var art := ValleyGroundArt.main()
	var u := Time.get_ticks_msec()
	# The sheriff's road by the opening site, and Harlan's place.
	s.make_all_round(Vector3(480.0, 0.0, 120.0))
	var ms := Time.get_ticks_msec() - u
	var all := _instances(s)
	check(all.size() > 200, "something grows round the opening site (%d)" % all.size())
	var bad := 0
	for it: Array in all:
		var p: Vector3 = it[1]
		var f := art.flags_at(p.x, p.z)
		if art.off_road(p.x, p.z) < 0.0 or f.pad or f.lot or f.rail:
			bad += 1
			if bad < 6:
				print("  on the way: %s at %s off_road %.2f %s" % [it[0], p, art.off_road(p.x, p.z), f])
	check_eq(bad, 0, "none on a road, a pad, a lot or the rail bed")
	check(ms < 20000, "made round a place in %d ms" % ms)
	print("  scatter round the opening site: %d instances, %d cells in %d ms, %s" % [all.size(), s.cells_made, ms, s.placed])


func test_the_scatter_is_the_same_every_run() -> void:
	var a := _scatter()
	a.make_all_round(Vector3(-1100.0, 0.0, 1030.0))
	var first := _instances(a)
	a.queue_free()
	await physics_frames(1)
	var b := _scatter()
	b.make_all_round(Vector3(-1100.0, 0.0, 1030.0))
	var second := _instances(b)
	check_eq(second.size(), first.size(), "as many")
	var same := true
	for i in mini(first.size(), second.size()):
		if not (first[i][1] as Vector3).is_equal_approx(second[i][1]):
			same = false
			break
	check(same, "in the same places")


func test_bodies_are_few() -> void:
	var s := _scatter()
	s.make_all_round(Vector3(-1100.0, 0.0, 1030.0))
	var bodies := 0
	var shapes := 0
	for cell: Node3D in s.get_children():
		for c in cell.get_children():
			if c is StaticBody3D:
				bodies += 1
				shapes += (c as StaticBody3D).get_shape_owners().size()
	check(bodies <= 250, "a body a cell at most (%d bodies, %d shapes)" % [bodies, shapes])
	check(shapes > 0, "the trunks and boulders can be stood behind")


func test_the_scatter_frees_what_it_leaves() -> void:
	var s := _scatter()
	s.make_all_round(Vector3(480.0, 0.0, 120.0))
	var n := s.get_child_count()
	s.make_all_round(Vector3(-1500.0, 0.0, -1000.0))
	await physics_frames(1)
	check(s.get_child_count() <= n + 400, "the cells left behind are freed (%d then %d)" % [n, s.get_child_count()])
	var far := 0
	for cell: Node3D in s.get_children():
		if not cell.is_queued_for_deletion() and Vector2(cell.position.x, cell.position.z).distance_to(Vector2(480, 120)) < 300.0:
			far += 1
	check_eq(far, 0, "none left round the first place")
