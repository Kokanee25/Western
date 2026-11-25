extends TestCase
## Boards shared by their shape (#1246, PropKit.shared_board): a building's plain boards take one mesh
## per (length, width, thickness, role), their own seed, warp and nails on their nodes. Merged into a
## batch they come out float for float as their own meshes did (so scan_wood draws them as before);
## drawn on their own they get their own mesh back; boards of one shape share one mesh.


func _board(length: float, seed: float, warp: float, nails: Vector2, ground: float, role := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	PropKit.shared_board(mi, length, 0.15, 0.022, seed, warp, nails, ground, role)
	return mi


func test_boards_of_one_shape_share_a_mesh() -> void:
	var a := _board(2.4, 0.11, 0.5, Vector2(1, 0.6), 0.0)
	var b := _board(2.4, 0.73, 0.2, Vector2(2, 0.4), 0.3)
	var c := _board(2.5, 0.11, 0.5, Vector2(1, 0.6), 0.0)
	var d := _board(2.4, 0.11, 0.5, Vector2(1, 0.6), 0.0, 4.0)
	check(a.mesh == b.mesh, "two boards of one size and role share their mesh")
	check(a.mesh != c.mesh, "a longer board has its own shape")
	check(a.mesh != d.mesh, "a tread (another role) has its own shape")
	check(a.mesh.has_meta(&"board_frame"), "a shared board batches in its own frame as a board does")
	for mi in [a, b, c, d]:
		mi.free()


func test_a_batch_of_shared_boards_is_their_own_meshes_merged() -> void:
	var specs := [[2.4, 0.11, 0.5, Vector2(1, 0.6), 0.0, 0.0], [2.4, 0.73, 0.2, Vector2(2, 0.4), 0.95, 0.0],
			[1.1, 0.42, 1.0, Vector2(0, 0.6), -3.2, 5.0], [3.05, 0.99999, 0.0, Vector2(1, 0.5), 12.25, 3.0]]
	var shared: Array = []
	var own: Array = []
	for i in specs.size():
		var s: Array = specs[i]
		var xf := Transform3D(Basis.from_euler(Vector3(0.1 * i, 0.7 * i, 0.0)), Vector3(i * 0.3, 1.0, -i))
		var mi := _board(s[0], s[1], s[2], s[3], s[4], s[5])
		shared.append([MemberMesh.arrays_of(mi.mesh), xf, PropKit.board_values(mi)])
		var m := PropKit.board_mesh(s[0], 0.15, 0.022, s[1], s[2], s[3], s[4], s[5])
		own.append([MemberMesh.arrays_of(m), xf])
		mi.free()
	var got: Array = Structure._merge_members(shared, false)
	var want: Array = Structure._merge_members(own, false)
	for slot: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_INDEX,
			Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2]:
		check(got[slot] == want[slot], "the batch's channel %d is the boards' own, float for float" % slot)


func test_a_board_drawn_on_its_own_gets_its_own_mesh() -> void:
	var mi := _board(2.4, 0.37, 0.5, Vector2(1, 0.6), 1.25, 3.0)
	var shape := mi.mesh
	PropKit.own_board(mi)
	check(mi.mesh != shape and not mi.mesh.has_meta(&"board_shared"), "its own mesh now")
	check(not mi.has_meta(&"board"), "its values are in its mesh, not on its node")
	var got: Array = MemberMesh.arrays_of(mi.mesh)
	var want: Array = MemberMesh.arrays_of(PropKit.board_mesh(2.4, 0.15, 0.022, 0.37, 0.5, Vector2(1, 0.6), 1.25, 3.0))
	for slot: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_INDEX]:
		check(got[slot] == want[slot], "channel %d is board_mesh's" % slot)
	PropKit.own_board(mi)  # (twice: nothing)
	check(not mi.mesh.has_meta(&"board_shared"), "still its own")
	mi.free()
