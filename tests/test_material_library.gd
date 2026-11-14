extends TestCase
## The material library (#701; MaterialLibrary, SamplePanel, scan_wood.gdshader;
## docs/briefs/material-library.md): every entry's scans are in the repo, a board's mesh carries
## the seed and its place for the vertex shader, and a panel builds the same boards every time.


func test_every_entry_has_its_scans_and_a_code() -> void:
	var entries: Array = MaterialLibrary.entries()
	check(entries.size() >= 8, "the woods are in the library (%d)" % entries.size())
	var codes := {}
	for e0 in entries:
		check(e0.has("code") and not codes.has(e0["code"]), "%s has its own swatch code" % e0["id"])
		codes[e0.get("code", "")] = true
		var e := MaterialLibrary.resolved(e0)
		check(SamplePanel.CLASSES.has(StringName(e["wood_class"])), "%s's wood class is a panel class" % e["id"])
		# Stone and lime (#860) name their scans by slot (face_scan, plaster_scan); woods by `scans`.
		var ids: Array = []
		for slot in (e.get("scans", {}) as Dictionary):
			ids.append(String(e["scans"][slot]["id"]))
		for k in ["face_scan", "plaster_scan"]:
			if e.has(k):
				ids.append(String(e[k]))
		for id: String in ids:
			var dir: String = MaterialLibrary.SCANS + id + "/"
			check(ResourceLoader.exists(dir + "albedo.jpg"), "%s's scan %s is in the repo" % [e["id"], dir])
			check(FileAccess.file_exists(dir + "meta.json"), "%s's scan %s has its source and licence" % [e["id"], dir])


func test_a_board_carries_its_seed_and_place() -> void:
	var m := SamplePanel.board_mesh(2.0, 0.15, 0.02, 0.37, 0.5, Vector2(1, 0.6), 1.25)
	var a: Array = m.surface_get_arrays(0)
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var c0: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM0]
	var c1: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM1]
	var c2: PackedFloat32Array = a[Mesh.ARRAY_CUSTOM2]
	check_eq(c0.size(), v.size() * 4, "CUSTOM0 is four floats a vertex")
	check_eq(c1.size(), v.size() * 4, "CUSTOM1 is four floats a vertex")
	var ends := 0
	for i in v.size():
		check(is_equal_approx(c0[i * 4], 0.37), "every vertex has the board's seed")
		check(c0[i * 4 + 1] >= 0.0 and c0[i * 4 + 1] <= 1.0, "its place along the board is 0..1")
		if c0[i * 4 + 3] == 1.0:
			ends += 1
	check(ends > 0, "the ends are flagged for end grain")
	check(is_equal_approx(c1[3], 0.5), "the warp rides with the board")
	check(is_equal_approx(c2[2], 1.25), "the ground's height rides with the board")
	# The warp has room in the culling box.
	check(m.custom_aabb.size.z >= 0.02 + 0.03, "the culling box has room for the warp")


func test_a_panel_builds_the_same_boards_every_time() -> void:
	var e := MaterialLibrary.entry("rough_pine_batten")
	var counts := []
	var first_x := []
	for i in 2:
		var p := SamplePanel.new()
		p.entry = e
		p.age_name = &"old"
		add_child(p)
		p.build()
		counts.append(p.boards)
		first_x.append((p.part_nodes[&"wall"].get_child(1) as Node3D).position.x)
		p.free()
	check(counts[0] > 10, "a wall, a floor and a rail of boards (%d)" % counts[0])
	check_eq(counts[0], counts[1], "the same boards each time")
	check(is_equal_approx(first_x[0], first_x[1]), "in the same places")


func test_old_rough_boards_warp_more_than_new_fine_ones() -> void:
	var rough: Dictionary = SamplePanel.CLASSES[&"rough"]
	var fine: Dictionary = SamplePanel.CLASSES[&"fine"]
	check(rough["warp"][2] > rough["warp"][0], "rough boards warp more as they age")
	check(rough["warp"][2] > fine["warp"][2] * 3.0, "an old shed's boards warp far more than a fine room's")
	check(rough["gap"][2] > rough["gap"][0], "gaps open with age")
	check(fine["width_var"] < rough["width_var"], "planed fine boards are truer to size")


func test_the_rail_top_is_a_bar_rail_for_the_shader() -> void:
	var p := SamplePanel.new()
	p.entry = MaterialLibrary.entry("fine_walnut_tg")
	p.age_name = &"old"
	add_child(p)
	p.build()
	var rail: Node = p.part_nodes[&"rail"]
	var top := rail.get_child(rail.get_child_count() - 1) as MeshInstance3D
	var c2: PackedFloat32Array = top.mesh.surface_get_arrays(0)[Mesh.ARRAY_CUSTOM2]
	check(is_equal_approx(c2[3], 1.0), "the rail's top board carries the bar rail's role (rings, elbows)")
	var post := rail.get_child(0) as MeshInstance3D
	var p2: PackedFloat32Array = post.mesh.surface_get_arrays(0)[Mesh.ARRAY_CUSTOM2]
	check(is_equal_approx(p2[3], 0.0), "a post is a plain board")
	p.free()


## Each scan's grain runs the way the library says: the albedo changes most across its grain.
## (C2's fir boards drew their grain across the board, two rounds running, from a guessed direction.)
func test_every_scan_grain_runs_the_way_the_library_says() -> void:
	for e0 in MaterialLibrary.entries():
		var e := MaterialLibrary.resolved(e0)
		for slot in (e.get("scans", {}) as Dictionary):
			var sc: Dictionary = e["scans"][slot]
			var path := ProjectSettings.globalize_path(MaterialLibrary.SCANS + String(sc["id"]) + "/albedo.jpg")
			var img := Image.load_from_file(path)
			if img == null:
				check(false, "%s's scan loads" % sc["id"])
				continue
			img.resize(256, 256)
			var dx := 0.0
			var dy := 0.0
			for y in range(0, 255, 3):
				for x in range(0, 255, 3):
					var c := img.get_pixel(x, y).get_luminance()
					dx += absf(img.get_pixel(x + 1, y).get_luminance() - c)
					dy += absf(img.get_pixel(x, y + 1).get_luminance() - c)
			var measured := "u" if dy > dx else "v"
			check_eq(measured, String(sc.get("grain", "u")), "%s (%s's %s): grain along %s" % [sc["id"], e["id"], slot, measured])


## The weave (#721, #763): a board's seed is hashed in the fragment shader into the board's place in
## each scan, so it must reach it exact. Interpolated, its last bits differed from pixel to pixel and
## the hash made blocks, a weave and smudge of every scan at 1 m. Anything per board that's hashed
## stays a flat varying.
func test_the_boards_seed_reaches_the_fragment_shader_flat() -> void:
	var code: String = (load("res://src/render/scan_wood.gdshader") as Shader).code
	check(code.contains("varying flat float v_seed;"), "v_seed is a flat varying")
	check(not code.contains("varying float v_seed;"), "and not an interpolated one")
	# The same fault's one other case (the audit, PR #775): a flame's seed in the old tongues' shader.
	var flame: String = (load("res://src/fire/flame.gdshader") as Shader).code
	check(flame.contains("varying flat float seed;"), "a flame's seed is flat too")


## Paint (#721's paint round): each coat lies over a wood in the library, takes its scans and its own
## layout, and sets the shader's paint; the wood's own floor stays bare where the entry says.
func test_a_paint_lies_over_a_wood_and_draws_its_coat() -> void:
	var paints: Array = MaterialLibrary.entries("paint")
	check(paints.size() >= 5, "the paints are in the library (%d)" % paints.size())
	for e0 in paints:
		var base := MaterialLibrary.entry(String(e0.get("over", "")))
		check(not base.is_empty() and base.get("family", "") == "wood", "%s lies over a wood (%s)" % [e0["id"], e0.get("over", "")])
		var e := MaterialLibrary.resolved(e0)
		check_eq(String(e["id"]), String(e0["id"]), "%s keeps its own id" % e0["id"])
		check(e.has("scans"), "%s takes its wood's scans" % e0["id"])
		check_eq(String(e["layout"]), String(e0.get("layout", base["layout"])), "%s's layout is its own, else its wood's" % e0["id"])
		var m := ShaderMaterial.new()
		m.shader = SamplePanel.SHADER
		MaterialLibrary.apply(m, e0, 0.5, &"wall")
		check(float(m.get_shader_parameter("paint")) > 0.5, "%s's wall is painted" % e0["id"])
		var c: Color = m.get_shader_parameter("paint_color")
		var want: Array = e0["paint_color"]
		check(is_equal_approx(c.r, want[0]) and is_equal_approx(c.b, want[2]), "%s's colour reaches the shader" % e0["id"])
		var f := ShaderMaterial.new()
		f.shader = SamplePanel.SHADER
		MaterialLibrary.apply(f, e0, 0.5, &"floor")
		check(float(f.get_shader_parameter("paint")) < 0.5, "%s's porch floor stays bare" % e0["id"])
	var p := SamplePanel.new()
	p.entry = MaterialLibrary.entry("painted_green_trim")
	p.age_name = &"few"
	add_child(p)
	p.build()
	check(p.boards > 10, "a paint's panel builds (%d boards)" % p.boards)
	p.free()


## Step 0 of the paint round (after PR #775): the lab's per-member values in texel_grid that feed a
## hash or a floor() are flat too.
func test_texel_grid_per_member_values_are_flat() -> void:
	var f := FileAccess.open("res://src/render/texel_grid.gdshaderinc", FileAccess.READ)
	var code := f.get_as_text()
	for v in ["varying flat float lab_u0;", "varying flat vec4 weather_frame;", "varying flat vec4 weather_nails;"]:
		check(code.contains(v), v)


## A floor's traffic map (#825): feet's wear along a way, none off it; dark by a wall, not where feet go.
func test_a_traffic_map_wears_the_ways_and_keeps_the_walls_dark() -> void:
	var img := MaterialLibrary.traffic_image(Vector2(3.0, 2.0), [[Vector2(0.0, 1.0), Vector2(2.5, 1.0), 1.0]],
			[[0.0, 0.0, 3.0, 2.0]], 0.1, 0.6, 0.4)
	check_eq(img.get_size(), Vector2i(30, 20), "a texel every 0.1 m")
	check(img.get_pixel(15, 9).r > 0.9 and img.get_pixel(15, 10).r > 0.9, "the way's middle is worn")
	check(img.get_pixel(15, 2).r < 0.01, "half a metre off it isn't")
	check(img.get_pixel(15, 0).g > 0.8, "by the wall it's dark")
	check(img.get_pixel(15, 6).g < 0.05, "out in the room it isn't")
	check(img.get_pixel(0, 9).g < 0.6, "where feet reach a wall, less")


## The doctor's ground floor's ways (#825): from the street door to his desk, through the hall.
func test_the_doctors_floor_has_his_ways() -> void:
	var b = load("res://experiments/building_lab/spec_building.gd").new()
	b.spec = b.load_spec("res://experiments/building_lab/doctor/doctor.json")
	b._lv = {"ground": float(b.spec.levels.ground.top)}
	var tw: Dictionary = b.traffic_ways()
	check((tw.rooms as Array).size() == 8, "his eight ground-floor rooms")
	var to_desk := false
	var hall := 0
	# (his desk point from the spec: #844 moved it to his chair)
	var desk := Vector2.ZERO
	for u: Dictionary in b.spec.use_points:
		if u.id == "desk":
			desk = Vector2(float(u.at[0]), float(u.at[2]))
	for w: Array in tw.ways:
		if (w[0] as Vector2).distance_to(Vector2(4.71, 0.0)) < 0.05 and (w[1] as Vector2).distance_to(desk) < 0.05:
			to_desk = true
		if (w[0] as Vector2).x > 4.0 and (w[0] as Vector2).x < 5.4 and (w[1] as Vector2).x > 4.0 and (w[1] as Vector2).x < 5.4:
			hall += 1
	check(to_desk, "the street door to the desk")
	check(hall >= 3, "along the hall, door to door (%d)" % hall)
	check(tw.size.x > 8.0 and tw.size.y > 14.0, "the map covers his floor")
	b.free()


## Floors and furniture (#825; the doctor's room review, causes 2 and 5): each floor wears where feet
## go, each furniture entry has its own finish, and a room's furniture never takes its floor's wood.
func test_floors_and_furniture_keep_apart() -> void:
	var floors := MaterialLibrary.entries("floor")
	var furniture := MaterialLibrary.entries("furniture")
	check(floors.size() >= 1 and furniture.size() >= 2, "a floor and the furniture woods are in the library")
	for e in floors:
		check(float(e.get("traffic", 0.0)) > 0.0, "%s wears where feet go" % e.id)
	for e in furniture:
		check(float(MaterialLibrary.resolved(e).get("furniture", 0.0)) > 0.0, "%s has the furniture finish" % e.id)
	check_eq(PropKit.lib_parts("lib:furniture_oak/old/front"), ["furniture_oak", "old", 2.0], "a drawer's front")
	check_eq(PropKit.lib_parts("lib:fine_walnut_tg/few/top"), ["fine_walnut_tg", "few", 1.0], "a worked top")
	# The doctor: the floor his spec draws (its `want` once passed, else its `use`) isn't any of the
	# woods his rooms' furniture is drawn in.
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/building_lab/doctor/doctor.json"))
	var f: Dictionary = spec.materials.finishes.floor
	var floor_id := String(f.use.entry)
	if f.has("want") and (MaterialLibrary.entry(String(f.want.entry)).get("approved", []) as Array).has(String(f.want.age)):
		floor_id = String(f.want.entry)
	var dress: Dictionary = spec.dressing
	for batch in dress.batches:
		for p: Dictionary in dress.batches[batch]:
			var path := "res://assets/props/kit/%s.json" % p.get("kit", "")
			if not FileAccess.file_exists(path):
				continue
			var kit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			for m: Dictionary in kit.get("members", []):
				var look := String(m.get("look", ""))
				if look.begins_with("lib:"):
					check(String(PropKit.lib_parts(look)[0]) != floor_id, "%s's %s isn't the floor's wood (%s)" % [p.kit, m.id, floor_id])
