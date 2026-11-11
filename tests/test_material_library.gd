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
		for slot in (e["scans"] as Dictionary):
			var dir: String = MaterialLibrary.SCANS + String(e["scans"][slot]["id"]) + "/"
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
	for e0 in MaterialLibrary.entries("wood"):
		var e := MaterialLibrary.resolved(e0)
		for slot in (e["scans"] as Dictionary):
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


## Paint round 2 (#804): every dial the library sets is a uniform of the shader (a misspelt one is
## silently dropped), and the round's dials are there: an indoor film that doesn't erode, the
## outdoor strips.
func test_every_library_dial_is_a_shader_uniform() -> void:
	var code: String = (load("res://src/render/scan_wood.gdshader") as Shader).code
	for d in MaterialLibrary.DIALS + MaterialLibrary.COLOURS:
		check(code.contains("uniform float %s " % d) or code.contains("uniform vec3 %s " % d)
				or code.contains("uniform float %s;" % d), "%s is a scan_wood uniform" % d)
	for d in ["paint_erode_inside", "paint_strips"]:
		check(d in MaterialLibrary.DIALS, "%s is a library dial" % d)
