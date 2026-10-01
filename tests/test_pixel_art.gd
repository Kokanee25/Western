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
		var m := WoodMaterials.get_material(wood, 0) as ShaderMaterial
		check(m != null and m.shader == PixelArt.GRID_SHADER, "%s: on the texel grid" % wood)
		check_near(m.get_shader_parameter(&"uv_scale") * PixelArt.SIZE, PixelArt.texels_per_meter, 0.001, "%s: %d texels per metre" % [wood, PixelArt.texels_per_meter])
		check_eq(m.get_shader_parameter(&"use_mipmaps"), PixelArt.use_mipmaps, "%s: smoothing follows the setting" % wood)


func test_texel_size_changes_live() -> void:
	var m := WoodMaterials.get_material(&"framing", 1) as ShaderMaterial
	PixelArt.set_density(16.0, false)
	check_near(m.get_shader_parameter(&"uv_scale") * PixelArt.SIZE, 16.0, 0.001, "existing materials follow the new density")
	check(not m.get_shader_parameter(&"use_mipmaps"), "no mipmaps: crunchy")
	PixelArt.set_density(40.0, true)
	check(m.get_shader_parameter(&"use_mipmaps"), "and back")


func test_holed_members_stay_on_the_grid() -> void:
	var base := WoodMaterials.get_material(&"weathered_pine", 2) as ShaderMaterial
	var holed := PixelArt.hole_material(base)
	check(holed.shader == PixelArt.HOLE_SHADER, "the hole shader")
	check(holed.get_shader_parameter(&"albedo_tex") == base.get_shader_parameter(&"albedo_tex"), "same texture")
	check_eq(holed.get_shader_parameter(&"uv_offset"), base.get_shader_parameter(&"uv_offset"), "same offset, so the board doesn't jump")
	PixelArt.set_density(24.0, false)
	check_near(holed.get_shader_parameter(&"uv_scale") * PixelArt.SIZE, 24.0, 0.001, "follows the density")
	PixelArt.set_density(40.0, true)


func test_texel_lighting_is_a_setting() -> void:
	check(not Settings.texel_lighting, "off by default (the approved look)")
	check(Settings.look_description().contains("texel lighting off"), "described: %s" % Settings.look_description())
	Settings.set_texel_lighting(true)
	check(Settings.look_description().contains("texel lighting on"), "P turns it on")
	check(InputMap.has_action(&"debug_texel_lighting"), "bound to a key")
	Settings.reset_to_defaults()
	check(not Settings.texel_lighting, "reset turns it off")


func test_every_grid_shader_lights_per_texel() -> void:
	# The shaders that draw the store and the street all move LIGHT_VERTEX to the texel's centre.
	for path in ["res://src/render/texel_grid.gdshaderinc", "res://src/world/ground.gdshader"]:
		var code := FileAccess.get_file_as_string(path)
		check(code.contains("texel_lighting.gdshaderinc"), "%s includes texel lighting" % path)
		check(code.contains("LIGHT_VERTEX"), "%s sets LIGHT_VERTEX" % path)
	check(FileAccess.get_file_as_string("res://src/structures/member_holes.gdshader").contains("texel_grid.gdshaderinc"), "holes too")
	check(ProjectSettings.has_setting("shader_globals/texel_lighting"), "the global uniform is declared")


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
