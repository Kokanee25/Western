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
	# Six: the concept painting's mosaic of close browns (2026-09-30; was five).
	check(colours.size() <= 6, "a handful of shades, like pixel art (%d)" % colours.size())


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
		check_near(m.get_shader_parameter(&"texels_per_meter"), PixelArt.texels_per_meter, 0.001, "%s: %d texels per metre" % [wood, PixelArt.texels_per_meter])
		check_eq(m.get_shader_parameter(&"use_mipmaps"), PixelArt.use_mipmaps, "%s: smoothing follows the setting" % wood)


func test_texel_size_changes_live() -> void:
	var m := WoodMaterials.get_material(&"framing", 1) as ShaderMaterial
	PixelArt.set_density(16.0, false)
	check_near(m.get_shader_parameter(&"texels_per_meter"), 16.0, 0.001, "existing materials follow the new density")
	check(not m.get_shader_parameter(&"use_mipmaps"), "no mipmaps: crunchy")
	PixelArt.set_density(32.0, true)
	check(m.get_shader_parameter(&"use_mipmaps"), "and back")


func test_holed_members_stay_on_the_grid() -> void:
	var base := WoodMaterials.get_material(&"weathered_pine", 2) as ShaderMaterial
	var holed := PixelArt.hole_material(base)
	check(holed.shader == PixelArt.HOLE_SHADER, "the hole shader")
	check(holed.get_shader_parameter(&"albedo_tex") == base.get_shader_parameter(&"albedo_tex"), "same texture")
	check_eq(holed.get_shader_parameter(&"uv_offset"), base.get_shader_parameter(&"uv_offset"), "same offset, so the board doesn't jump")
	PixelArt.set_density(24.0, false)
	check_near(holed.get_shader_parameter(&"texels_per_meter"), 24.0, 0.001, "follows the density")
	PixelArt.set_density(32.0, true)


func test_one_key_switches_tiles_everywhere() -> void:
	# The world, people and props share one tile look: one setting, one key (P), one pair of globals.
	check(InputMap.has_action(&"debug_tiles"), "bound to a key")
	var on_p := 0
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and (e as InputEventKey).physical_keycode == KEY_P:
				on_p += 1
	check_eq(on_p, 1, "nothing else on P")
	check(ProjectSettings.has_setting("shader_globals/tile_light"), "the global uniform is declared")
	check(ProjectSettings.has_setting("shader_globals/tile_ragged"), "and its ragged edge")
	check(not ProjectSettings.has_setting("shader_globals/texel_lighting"), "no second switch")


func test_every_grid_shader_lights_per_texel() -> void:
	# The shaders that draw the store, the street, the props and the people all move LIGHT_VERTEX
	# to the tile's centre, through the same include.
	for path in ["res://src/render/texel_grid.gdshaderinc", "res://src/world/ground.gdshader",
			"res://src/bodies/shaders/body_skin.gdshaderinc"]:
		var code := FileAccess.get_file_as_string(path)
		check(code.contains("tiles.gdshaderinc"), "%s includes the tiles" % path)
		check(code.contains("LIGHT_VERTEX"), "%s sets LIGHT_VERTEX" % path)
	check(FileAccess.get_file_as_string("res://src/structures/member_holes.gdshader").contains("texel_grid.gdshaderinc"), "holes too")


func test_texel_size_is_a_setting() -> void:
	check_near(Settings.texels_per_meter, 32.0, 0.001, "starts at 32 per metre")
	check(Settings.look_description().contains("32/m"), "described: %s" % Settings.look_description())
	Settings.cycle_texel_density()
	check_near(PixelArt.texels_per_meter, 24.0, 0.001, "F7 steps to 24")
	Settings.cycle_texel_density()
	check_near(PixelArt.texels_per_meter, 16.0, 0.001, "then 16")
	Settings.cycle_texel_density()
	check_near(PixelArt.texels_per_meter, 64.0, 0.001, "then the fine 64")
	Settings.cycle_texel_density()
	check_near(PixelArt.texels_per_meter, 32.0, 0.001, "four presses come back to 32")
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


func test_tile_look_is_a_setting() -> void:
	check_eq(Settings.tile_look, &"square", "every texel a tile lit as one colour by default")
	check_near(Settings.tile_globals()[&"tile_light"], 1.0, 0.001, "tile light on")
	Settings.cycle_tile_look()
	check_eq(Settings.tile_look, &"ragged", "P: ragged tiles")
	check_near(Settings.tile_globals()[&"tile_ragged"], Settings.TILE_RAGGED, 0.001, "tiles wander")
	Settings.cycle_tile_look()
	check_eq(Settings.tile_look, &"off", "P again: off")
	check_near(Settings.tile_globals()[&"tile_light"], 0.0, 0.001, "smooth light")
	check(Settings.look_description().contains("tiles off"), "described: %s" % Settings.look_description())
	Settings.reset_to_defaults()
	check_near(Settings.tile_globals()[&"tile_ragged"], 0.0, 0.001, "square again")


func test_quantise_once_is_a_setting() -> void:
	check(not Settings.quantise_once, "off by default: the game's look is unchanged")
	check(not PixelArt.smooth, "the factory's squares as before")
	check(DepthMosaic.tuning.is_empty(), "the mosaic at its defaults")
	check_near(Settings.tile_globals()[&"min_square_px"], Settings.MIN_SQUARE_PX, 0.001, "the far squares as before")
	Settings.set_quantise_once(true)
	check(PixelArt.smooth, "I: the smooth texture set")
	check(PeopleBodies.smooth_paint, "the man's paint without squares")
	check_near(PixelArt.texels_per_meter, 32.0 * 4.0, 0.001, "four times the texels for the smooth set")
	check_near(Settings.tile_globals()[&"tile_light"], 0.0, 0.001, "tile light off")
	check_near(Settings.tile_globals()[&"min_square_px"], 0.0, 0.001, "no minimum square")
	check(PixelArt.factory("floor").resource_path.contains("/smooth/"), "the smooth floor painting")
	check(DepthMosaic.tuning.has("dark_weight"), "the mosaic averages with the darks kept")
	check(Settings.look_description().contains("quantise once"), "described: %s" % Settings.look_description())
	# The mosaic on a camera takes the knobs, picks its block size by the roof over it, and gives
	# them back when the look goes off.
	var camera := Camera3D.new()
	get_tree().root.add_child(camera)
	var m := DepthMosaic.attach(camera, Settings.MOSAIC_K, Settings.MOSAIC_STEPS)
	var mat := m.material_override as ShaderMaterial
	check_near(mat.get_shader_parameter(&"dark_weight"), Settings.QUANTISE_TUNING["dark_weight"], 0.001, "dark-weighted")
	check(m.scene_blocks, "block size by the roof")
	await physics_frames(3)
	check_near(mat.get_shader_parameter(&"block_k"), Settings.QUANTISE_TUNING["block_out"], 0.001, "no roof over an empty world: block_out")
	Settings.set_quantise_once(false)
	DepthMosaic.attach(camera, Settings.MOSAIC_K, Settings.MOSAIC_STEPS)
	check_near(mat.get_shader_parameter(&"dark_weight"), 0.0, 0.001, "I again: the plain mosaic")
	check_near(mat.get_shader_parameter(&"average"), 0.0, 0.001, "point sampled")
	check(not m.scene_blocks, "one block rule")
	check(not PixelArt.smooth and not PeopleBodies.smooth_paint, "the squares back")
	check_near(PixelArt.texels_per_meter, 32.0, 0.001, "32 texels again")
	camera.queue_free()
	Settings.reset_to_defaults()


## The surface-blocks look (docs/briefs/renderer.md; art's test in this file, said in its entry).
func test_surface_blocks_is_a_setting() -> void:
	check(not Settings.surface_blocks, "off by default: the game's look is unchanged")
	check(not PixelArt.blocks, "the plain grid shaders")
	check(PixelArt.material(PixelArt.wood("test_blocks_off", Color(0.5, 0.4, 0.3), 1)).shader == PixelArt.GRID_SHADER, "a grid material on the plain shader")
	check_near(Settings.tile_globals()[&"block_soft"], 0.0, 0.001, "hard texel edges as before")
	check_near(Settings.tile_globals()[&"light_bands"], 0.0, 0.001, "smooth light as before")
	check(Settings.mosaic_active(), "the mosaic on, as the default is")
	Settings.set_surface_blocks(true)
	check(PixelArt.blocks, "M: the blocks shaders")
	var m := PixelArt.material(PixelArt.wood("test_blocks_on", Color(0.5, 0.4, 0.3), 2))
	check(m.shader == PixelArt.GRID_SHADER_BLOCKS, "a grid material on the blocks shader")
	check(PixelArt.is_grid_shader(m.shader), "and it counts as a grid shader")
	check(PixelArt.hole_material(m).shader == PixelArt.HOLE_SHADER_BLOCKS, "holes keep the look")
	check_near(Settings.tile_globals()[&"block_soft"], Settings.BLOCK_SOFT, 0.001, "soft edges")
	check_near(Settings.tile_globals()[&"min_square_px"], 0.0, 0.001, "no minimum square: distance softens")
	check_near(Settings.tile_globals()[&"tile_light"], 1.0, 0.001, "lit per block")
	check(not Settings.mosaic_active(), "no screen pass")
	check(Settings.look_description().contains("surface blocks"), "described: %s" % Settings.look_description())
	Settings.set_surface_blocks(false)
	check(not PixelArt.blocks and Settings.mosaic_active(), "M again: the look as before")
	Settings.reset_to_defaults()


func test_tiled_materials_follow_the_texel_grid() -> void:
	# Props (laid on by position, like the shot match's cups and table) are on the same grid.
	var m := PixelArt.material(PixelArt.wood("test_tiles", Color(0.4, 0.25, 0.12), 3), Color.WHITE, PixelArt.Mapping.TRIPLANAR)
	check(m.shader == PixelArt.GRID_SHADER, "the one grid material")
	check_near(m.get_shader_parameter(&"texels_per_meter"), PixelArt.texels_per_meter, 0.001, "on the world's grid")
	PixelArt.set_density(16.0, false)
	check_near(m.get_shader_parameter(&"texels_per_meter"), 16.0, 0.001, "follows F7")
	PixelArt.set_density(32.0, true)


func test_portrait_is_brought_to_face_tiles_without_holes() -> void:
	# A painted oval 384x256 with a hole where an eye socket was missed, the way projections come out.
	var p := Image.create(384, 256, false, Image.FORMAT_RGBA8)
	for y in 256:
		for x in 384:
			var d := Vector2((x - 192.0) / 90.0, (y - 128.0) / 110.0)
			if d.length() < 1.0:
				p.set_pixel(x, y, Color(0.7, 0.5, 0.4, 1.0))
	for y in range(100, 116):
		for x in range(150, 170):
			p.set_pixel(x, y, Color(0, 0, 0, 0))
	var t := PeopleArt.portrait_tiles(p)
	check_eq(Vector2i(t.get_width(), t.get_height()), Vector2i(PeopleArt.FACE_W, PeopleArt.FACE_H), "the face's own tile size")
	var hole := t.get_pixel(160 / 4, 108 / 4)
	check(hole.a > 0.99, "the hole is filled")
	check_near(hole.r, 0.7, 0.02, "with the skin round it")
	check(t.get_pixel(2, 2).a < 0.01, "outside the face stays clear")


func test_factory_textures_take_over_their_key_at_the_same_texel_size() -> void:
	# The texture factory (tools/textures/) writes assets/textures/<key>.png at 64 texels a metre,
	# any size: wherever one exists PixelArt hands it out for that key, and the grid lays its
	# texels at the world's size (texel_grid works the repeat out from the texture's own size).
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.2, 0.1))
	var old: Variant = PixelArt._cache.get("factory_test")
	PixelArt._cache["factory_test"] = ImageTexture.create_from_image(img)
	var tex := PixelArt.wood("factory_test", Color.RED, 1)
	check(tex.get_width() == 128 and tex.get_height() == 64, "a 2 m x 1 m texture comes back as it is")
	var m := PixelArt.material(tex)
	check_near(m.get_shader_parameter(&"texels_per_meter"), PixelArt.texels_per_meter, 0.001, "on the world's grid")
	PixelArt._cache.erase("factory_test")
	if old != null:
		PixelArt._cache["factory_test"] = old
	PixelArt.use_factory = false
	check(PixelArt.factory("floor") == null, "switched off, every key is painted in code")
	PixelArt.use_factory = true
