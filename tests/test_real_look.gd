extends TestCase
## The real look (RealLook, Settings.real_look; docs/briefs/red-dead.md R0): on, the world's shaders
## are recompiled with REAL_LOOK, the texel grid's globals are off and the environment takes the
## realistic dials; off, every one of them is as it was. The painted look is the default.

var holder: Node
var real: RealLook
var was_real := false


func before_each() -> void:
	Settings.autosave = false
	was_real = Settings.real_look
	Settings.real_look = false
	holder = Node.new()
	add_child(holder)
	holder.add_child(load("res://scenes/test_street.tscn").instantiate())
	real = RealLook.new()
	holder.add_child(real)
	await process_frames(3)


func after_each() -> void:
	Settings.set_real_look(false)
	await process_frames(2)
	Settings.real_look = was_real
	Settings.apply_tile_globals()
	LookPreset.defaults.clear()
	holder.queue_free()
	await process_frames(2)


func test_the_painted_look_is_the_default() -> void:
	check(not RealLook.shaders_real, "the world's shaders are the painted look's while it's off")
	check(not Settings.real_look, "off unless asked for")
	var code: String = (load("res://src/render/texel_grid.gdshader") as Shader).code
	check(not code.contains(RealLook.DEFINE), "the texel grid's code as written")


func test_on_recompiles_the_shaders_and_off_puts_them_back() -> void:
	var before := {}
	for p: String in RealLook.SHADERS:
		before[p] = (load(p) as Shader).code
	Settings.set_real_look(true)
	await process_frames(2)
	for p: String in RealLook.SHADERS:
		var code: String = (load(p) as Shader).code
		var at := code.find(RealLook.DEFINE)
		check(at > code.find("shader_type"), "%s: REAL_LOOK defined after its shader_type" % p)
	var g := Settings.tile_globals()
	check(g[&"min_square_px"] == 0.0 and g[&"tile_light"] == 0.0 and g[&"seam_px"] == 0.0,
			"no squares, no light per texel, no painted seams: %s" % [g])
	check(not Settings.mosaic_active() and not Settings.probe_active(), "no screen mosaic")
	Settings.set_real_look(false)
	await process_frames(2)
	for p: String in RealLook.SHADERS:
		check((load(p) as Shader).code == before[p], "%s back as written" % p)


func test_the_environment_takes_the_dials_and_gets_them_back() -> void:
	var env := LookPreset.environment(get_tree())
	var tone := env.tonemap_mode
	var ssil := env.ssil_enabled
	Settings.set_real_look(true)
	await process_frames(2)
	check(env.tonemap_mode == Environment.TONE_MAPPER_AGX, "AgX under the real look")
	check(env.ssil_enabled and env.sdfgi_enabled, "SSIL and SDFGI on")
	var we := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	check(we.camera_attributes is CameraAttributesPractical, "an exposure multiplier")
	Settings.set_real_look(false)
	await process_frames(2)
	check(env.tonemap_mode == tone and env.ssil_enabled == ssil, "the painted look's tonemap and SSIL back")
	check(we.camera_attributes == null or not (we.camera_attributes is CameraAttributesPractical), "no multiplier")


func test_nearest_materials_are_filtered_and_put_back() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mi.material_override = m
	holder.add_child(mi)
	Settings.set_real_look(true)
	await process_frames(2)
	check(m.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "drawn smooth")
	check(PixelArt.texture_filter() == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC,
			"what's made while it's on is smooth too")
	var late := MeshInstance3D.new()
	late.mesh = BoxMesh.new()
	var m2 := StandardMaterial3D.new()
	m2.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	late.material_override = m2
	holder.add_child(late)
	await process_frames(2)
	check(m2.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "and what's added after")
	Settings.set_real_look(false)
	await process_frames(2)
	check(m.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS, "back to nearest")
	check(m2.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "both")


func test_its_dials_are_look_addresses() -> void:
	check(LookPreset.get_value(get_tree(), "real.exposure") != null, "real.exposure")
	check(LookPreset.get_value(get_tree(), "view.msaa_3d") != null, "view.msaa_3d")
	check(LookPreset.set_value(get_tree(), "real.relief", 0.008), "real.relief settable")
	check(is_equal_approx(float(RealLook.dials.relief), 0.008), "and set")
	RealLook.dials.relief = 0.004


## R1: a lamp hung over a room (meta lamp_group "hung") is shaded under the real look: its tin
## shade casts a shadow and the lamp casts shadows (with the camera near), its light multiplied by
## real.hung_energy after OilLamp's flicker; off, all as it was.
func test_hung_lamps_are_shaded_and_put_back() -> void:
	var root := Node3D.new()
	holder.add_child(root)
	var lamp := OilLamp.new()
	lamp.set_meta(&"lamp_group", &"hung")
	lamp.casts_shadows = false
	lamp.lit_from_hour = 0
	lamp.lit_until_hour = 24
	root.add_child(lamp)
	var shade := MeshInstance3D.new()
	shade.name = "Shade"
	shade.mesh = BoxMesh.new()
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shade)
	var cam := Camera3D.new()
	holder.add_child(cam)
	cam.current = true
	await process_frames(2)
	var light: OmniLight3D = lamp._light
	check(not light.shadow_enabled, "no shadow in the painted look")
	var was := float(RealLook.dials.hung_energy)
	RealLook.dials.hung_energy = 2.0
	Settings.set_real_look(true)
	await process_frames(3)
	check(light.shadow_enabled, "the lamp casts shadows, the camera near")
	check(shade.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "and its shade casts one")
	var ratio := light.light_energy / maxf(lamp.energy, 0.0001)
	check(ratio > 1.8 and ratio < 2.2, "its light x hung_energy over the flicker (%.2f)" % ratio)
	await process_frames(3)
	ratio = light.light_energy / maxf(lamp.energy, 0.0001)
	check(ratio < 2.2, "not compounding frame on frame (%.2f)" % ratio)
	Settings.set_real_look(false)
	await process_frames(2)
	RealLook.dials.hung_energy = was
	check(not light.shadow_enabled, "no shadow again")
	check(shade.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "the shade casts none")
	check(light.light_energy < lamp.energy * 1.2, "its own energy back")
