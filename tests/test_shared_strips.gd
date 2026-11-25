extends TestCase
## Strips shared by their shape (#1259, PropKit.shared_strips): a member drawn as several boards side by
## side (#826) takes one mesh per (length, width, thickness, strip), its strips' seeds, warp, nails and
## ground on its node. Merged into a batch it comes out float for float as its own strips mesh did (so
## scan_wood draws it as before); drawn on its own it gets its own mesh back.


func _strips(length: float, width: float, rng: int, warp: float, nails: Vector2, ground: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	PropKit.shared_strips(mi, length, width, 0.019, 0.09, rng, warp, nails, ground)
	return mi


func test_members_of_one_shape_share_a_mesh() -> void:
	var a := _strips(2.4, 0.27, 11, 0.5, Vector2(1, 0.6), 0.0)
	var b := _strips(2.4, 0.27, 987654321, 0.2, Vector2(2, 0.4), 0.95)
	var c := _strips(2.4, 0.31, 11, 0.5, Vector2(1, 0.6), 0.0)
	check(a.mesh == b.mesh, "two members of one shape share their mesh")
	check(a.mesh != c.mesh, "a wider member has its own")
	check(a.mesh.has_meta(&"board_frame") and a.mesh.has_meta(&"strip_widths"), "it batches as a board and keeps its strips' widths")
	for mi in [a, b, c]:
		mi.free()


func test_a_batch_of_shared_strips_is_their_own_meshes_merged() -> void:
	# (the last strip ripped narrower in some: 0.31 = 3 x 0.09 + 0.04; 0.2 = 2 x 0.09 + 0.02 taken in)
	var specs := [[2.4, 0.27, 11, 0.5, Vector2(1, 0.6), 0.0], [2.4, 0.27, -4611686018427387, 0.2, Vector2(2, 0.4), 0.95],
			[1.1, 0.31, 4242424242, 1.0, Vector2(0, 0.6), -3.2], [3.05, 0.2, 7, 0.0, Vector2(1, 0.5), 12.25]]
	var shared: Array = []
	var own: Array = []
	for i in specs.size():
		var s: Array = specs[i]
		var xf := Transform3D(Basis.from_euler(Vector3(0.1 * i, 0.7 * i, 0.0)), Vector3(i * 0.3, 1.0, -i))
		var mi := _strips(s[0], s[1], s[2], s[3], s[4], s[5])
		shared.append([MemberMesh.arrays_of(mi.mesh), xf, PropKit.board_values(mi)])
		var m := PropKit.strips_mesh(s[0], s[1], 0.019, 0.09, s[2], s[3], s[4], s[5])
		own.append([MemberMesh.arrays_of(m), xf])
		mi.free()
	# Mixed with plain shared boards in one batch, as a wall's are.
	var board := MeshInstance3D.new()
	PropKit.shared_board(board, 2.4, 0.15, 0.022, 0.37, 0.5, Vector2(1, 0.6), 1.25, 3.0)
	shared.append([MemberMesh.arrays_of(board.mesh), Transform3D(), PropKit.board_values(board)])
	own.append([MemberMesh.arrays_of(PropKit.board_mesh(2.4, 0.15, 0.022, 0.37, 0.5, Vector2(1, 0.6), 1.25, 3.0)), Transform3D()])
	board.free()
	var got: Array = Structure._merge_members(shared, false)
	var want: Array = Structure._merge_members(own, false)
	for slot: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_INDEX,
			Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2]:
		check(got[slot] == want[slot], "the batch's channel %d is the members' own, float for float" % slot)


func test_strips_drawn_on_their_own_get_their_own_mesh() -> void:
	var mi := _strips(2.4, 0.31, 31337, 0.5, Vector2(1, 0.6), 1.25)
	var shape := mi.mesh
	PropKit.own_board(mi)
	check(mi.mesh != shape and not mi.mesh.has_meta(&"strips_shared"), "its own mesh now")
	check(not mi.has_meta(&"board") and not mi.has_meta(&"strips_rng"), "its values are in its mesh, not on its node")
	var got: Array = MemberMesh.arrays_of(mi.mesh)
	var want: Array = MemberMesh.arrays_of(PropKit.strips_mesh(2.4, 0.31, 0.019, 0.09, 31337, 0.5, Vector2(1, 0.6), 1.25))
	for slot: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_INDEX]:
		check(got[slot] == want[slot], "channel %d is strips_mesh's" % slot)
	PropKit.own_board(mi)  # (twice: nothing)
	check(not mi.mesh.has_meta(&"strips_shared"), "still its own")
	mi.free()
