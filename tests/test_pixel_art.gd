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
		check_near(m.uv1_scale.x * PixelArt.SIZE, PixelArt.texels_per_meter, 0.001, "%s: %d texels per metre" % [wood, PixelArt.texels_per_meter])
		check_eq(m.texture_filter, PixelArt.texture_filter(), "%s: hard pixels" % wood)


func test_texel_size_changes_live() -> void:
	var m := WoodMaterials.get_material(&"framing", 1) as StandardMaterial3D
	PixelArt.set_density(16.0, false)
	check_near(m.uv1_scale.x * PixelArt.SIZE, 16.0, 0.001, "existing materials follow the new density")
	check_eq(m.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST, "no mipmaps: crunchy")
	PixelArt.set_density(40.0, true)
	check_eq(m.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS, "and back")


func test_texel_size_is_a_setting() -> void:
	check_near(Settings.texels_per_meter, 40.0, 0.001, "starts at 40 per metre")
	check(Settings.look_description().contains("40/m"), "described: %s" % Settings.look_description())
	Settings.cycle_texel_density()
	check_near(PixelArt.texels_per_meter, 24.0, 0.001, "F7 steps to 24")
	Settings.cycle_texel_density()
	Settings.cycle_texel_density()
	check_near(PixelArt.texels_per_meter, 40.0, 0.001, "three presses come back to 40")
	check(PixelArt.use_mipmaps, "smoothed again")
	Settings.reset_to_defaults()


func test_pixel_shading_is_a_setting() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await process_frames(2)
	var post := (main.get_node(^"Screen") as TextureRect).material as ShaderMaterial
	check(not post.get_shader_parameter(&"shading_enabled"), "off by default")
	Settings.set_pixel_shading(true)
	check(post.get_shader_parameter(&"shading_enabled"), "F6 turns it on")
	Settings.reset_to_defaults()
	main.queue_free()
	await process_frames(2)
