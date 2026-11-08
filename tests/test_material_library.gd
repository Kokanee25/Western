extends TestCase
## The material library (#701; MaterialLibrary, SamplePanel, scan_wood.gdshader;
## docs/briefs/material-library.md): every entry's scans are in the repo, a board's mesh carries
## the seed and its place for the vertex shader, and a panel builds the same boards every time.


func test_every_entry_has_its_scans_and_a_code() -> void:
	var entries: Array = MaterialLibrary.entries()
	check(entries.size() >= 8, "the woods are in the library (%d)" % entries.size())
	var codes := {}
	for e in entries:
		check(e.has("code") and not codes.has(e["code"]), "%s has its own swatch code" % e["id"])
		codes[e.get("code", "")] = true
		check(SamplePanel.CLASSES.has(StringName(e["class"])), "%s's class is a panel class" % e["id"])
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
