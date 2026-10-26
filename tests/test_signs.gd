extends TestCase
## The painted sign boards (#402) drawn from their imported textures, VRAM-compressed (#287): the
## board's UVs run down it as the picture's rows do, so nothing is read back, decompressed and
## flipped (a full-size copy of every board kept in memory).


func test_a_painted_board_draws_its_compressed_texture() -> void:
	for id in [&"sign_saloon_r1", &"sign_rooms", &"sign_eating_house"]:
		var mi := SignArt.board(id, Vector2(3.0, 0.8))
		check(mi != null, "%s painted" % id)
		var tex = (mi.material_override as ShaderMaterial).get_shader_parameter(&"albedo_tex")
		check(tex is CompressedTexture2D, "%s drawn from its import, not a copy (%s)" % [id, tex])
		var stub := FileAccess.get_file_as_string(PixelArt.FACTORY_PATH % id + ".import")
		check(stub.contains("compress/mode=2"), "%s VRAM-compressed" % id)
		mi.free()


func test_the_board_reads_the_right_way_up() -> void:
	# The top of the board (+y) samples the picture's first rows (v near 0).
	var mesh := SignArt.board(&"sign_rooms", Vector2(2.0, 0.5)).mesh as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in verts.size():
		if verts[i].z > 0.0:
			check_near(uvs[i].y, 0.25 - verts[i].y, 1e-4, "v runs down the face")
			check_near(uvs[i].x, verts[i].x + 1.0, 1e-4, "u runs across it")
