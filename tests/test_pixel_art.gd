extends TestCase
## Pixel-art textures and member UVs: textures are deterministic and tile seamlessly, texels are
## the same size on every member, and the grain runs along each board's length.


func test_textures_are_deterministic_small_and_few_coloured() -> void:
	PixelArt._cache.clear()
	var a := PixelArt.wood("t1", Color(0.5, 0.4, 0.3), 9).get_image()
	PixelArt._cache.clear()
	var b := PixelArt.wood("t1", Color(0.5, 0.4, 0.3), 9).get_image()
	check_eq(a.get_width(), PixelArt.SIZE, "texture size")
	check(a.get_data() == b.get_data(), "same seed, same pixels")
	var colours := {}
	for y in PixelArt.SIZE:
		for x in PixelArt.SIZE:
			colours[a.get_pixel(x, y).to_html()] = true
	check(colours.size() <= 5, "a handful of shades, like pixel art (%d)" % colours.size())


func test_noise_tiles_seamlessly() -> void:
	for y in [0, 17, 40]:
		check_near(PixelArt._noise(0, y, 3, 24, 5), PixelArt._noise(PixelArt.SIZE, y, 3, 24, 5), 0.0001, "wraps in x")
	for x in [0, 23, 51]:
		check_near(PixelArt._noise(x, 0, 3, 24, 5), PixelArt._noise(x, PixelArt.SIZE, 3, 24, 5), 0.0001, "wraps in y")


func test_member_uvs_follow_the_grain() -> void:
	# A stud: long in y. On its broad faces, u must run along y in metres.
	var size := Vector3(0.05, 3.0, 0.1)
	var mesh := MemberMesh.box(size)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var max_u := 0.0
	for i in verts.size():
		if absf(normals[i].z) > 0.9:
			check_near(uvs[i].x, verts[i].y + size.y * 0.5, 0.0001, "u is metres along the length")
			max_u = maxf(max_u, uvs[i].x)
	check_near(max_u, 3.0, 0.0001, "u spans the whole 3 m")
	check(MemberMesh.box(size) == mesh, "meshes are shared per size")


func test_texel_density_is_the_same_everywhere() -> void:
	for wood in [&"weathered_pine", &"framing", &"painted_ochre", &"floor"]:
		var m := WoodMaterials.get_material(wood, 0) as StandardMaterial3D
		check_near(m.uv1_scale.x * PixelArt.SIZE, PixelArt.TEXELS_PER_METER, 0.001, "%s: %d texels per metre" % [wood, PixelArt.TEXELS_PER_METER])
		check_eq(m.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS, "%s: hard pixels" % wood)
