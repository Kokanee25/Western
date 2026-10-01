extends TestCase
## Props from assets/props/manifest.json: placeholders until models exist, models scaled to their
## real-world size and anchored on the floor or against the wall; the saloon test room stands up
## and is furnished.


func test_manifest_is_valid() -> void:
	var ids := PropLibrary.ids()
	check(ids.size() >= 10, "at least 10 props (%d)" % ids.size())
	for id in ids:
		var def := PropLibrary.definition(id)
		check(String(def.get("prompt", "")).length() > 10, "%s has a prompt" % id)
		var s := PropLibrary.size_of(id)
		check(s.x > 0.0 and s.y > 0.0 and s.z > 0.0 and s.y < 3.0, "%s has a real-world size" % id)
		check(def.get("anchor", "floor") in ["floor", "wall"], "%s anchor" % id)


func test_placeholder_matches_size() -> void:
	PropLibrary.use_models = false
	var prop := PropLibrary.spawn(&"card_table")
	PropLibrary.use_models = true
	add_child(prop)
	var b := PropLibrary.bounds_of(prop)
	check(prop.get_meta(&"placeholder"), "no model: the box")
	check(b.size.is_equal_approx(PropLibrary.size_of(&"card_table")), "placeholder is the manifest size")
	check_near(b.position.y, 0.0, 0.001, "sits on the floor")
	check_near(b.get_center().x, 0.0, 0.001, "centred")
	prop.queue_free()


func test_every_prop_has_a_code_model_its_real_size_on_the_texel_grid() -> void:
	# PropModels builds each prop at the manifest's size (so PropLibrary barely rescales it), and
	# everything but see-through glass is on the texel grid, lit tile by tile.
	for id in PropLibrary.ids():
		var sid := StringName(id)
		check(PropModels.has_model(sid), "%s has a model" % id)
		var prop := PropLibrary.spawn(sid)
		add_child(prop)
		check(not prop.get_meta(&"placeholder"), "%s: not a box" % id)
		var want := PropLibrary.size_of(sid)
		var model := PropModels.build(sid)
		var raw := PropLibrary._model_bounds(model)
		model.free()
		check(absf(raw.size.y - want.y) / want.y < 0.25, "%s: built about its real height (%.2f vs %.2f m)" % [id, raw.size.y, want.y])
		var b := PropLibrary.bounds_of(prop)
		check(absf(b.size.x - want.x) / want.x < 0.35 and absf(b.size.z - want.z) / want.z < 0.6,
				"%s: about its real width and depth (%s vs %s)" % [id, b.size, want])
		for mi: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
			var m := mi.material_override
			check(m is ShaderMaterial and (m as ShaderMaterial).shader == PixelArt.GRID_SHADER or mi.name == &"Chimney",
					"%s/%s on the texel grid" % [id, mi.name])
		prop.queue_free()


func test_model_is_scaled_and_anchored() -> void:
	# A fake 'model': a 2 x 4 x 1 box floating off-centre, like an import in arbitrary units.
	var model := Node3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2, 4, 1)
	mi.mesh = box
	mi.position = Vector3(5, 7, -3)
	model.add_child(mi)
	var prop := PropLibrary.spawn(&"barrel", model)
	add_child(prop)
	await physics_frames(1)
	check(not prop.get_meta(&"placeholder"), "uses the model")
	var b := PropLibrary.bounds_of(prop)
	check_near(b.size.y, PropLibrary.size_of(&"barrel").y, 0.001, "scaled to the real height")
	check_near(b.size.x, 0.45, 0.001, "kept its proportions")
	check_near(b.position.y, 0.0, 0.001, "bottom on the floor")
	check_near(b.get_center().x, 0.0, 0.001, "centred in x")
	check_near(b.get_center().z, 0.0, 0.001, "centred in z")
	var shape := prop.get_child(1) as CollisionShape3D
	check((shape.shape as BoxShape3D).size.is_equal_approx(b.size), "collision fits the model")
	prop.queue_free()


func test_wall_props_hang_from_their_back() -> void:
	var prop := PropLibrary.spawn(&"deer_head")
	add_child(prop)
	var b := PropLibrary.bounds_of(prop)
	check_near(b.position.z, 0.0, 0.001, "back against the wall")
	check_near(b.get_center().y, 0.0, 0.001, "hung from its middle")
	prop.queue_free()


func test_saloon_stands_and_is_furnished() -> void:
	var saloon := SaloonBuilding.new()
	saloon.structure_id = &"saloon"
	add_child(saloon)
	await physics_frames(1)
	check(saloon.member_count() > 600, "member-built (%d)" % saloon.member_count())
	var falling := saloon.members_without_load_path()
	check(falling.is_empty(), "everything supported: %s" % [falling.slice(0, 8)])
	var props := saloon.get_node(^"Props").get_children()
	var kinds := {}
	for p in props:
		kinds[p.get_meta(&"prop_id")] = true
	for id in PropLibrary.ids():
		check(kinds.has(StringName(id)), "the room uses %s" % id)
	var lights := saloon.find_children("Light", "OilLamp", true, false)
	check(lights.size() >= 7, "lamps and sconces give light (%d)" % lights.size())
	saloon.queue_free()
