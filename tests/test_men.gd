extends TestCase
## The men who work (tools/characters/men.py, men.json): the made-clothes man with a portrait
## head, a build and colours each, the gang and the townsmen. They wear the game's hat over their
## own heads and lose it to a ball; a colourway wears his man's mesh in his own textures.

const MEN := [&"bold_made", &"heavy_made", &"lean_made"]
const WAYS := {&"storekeeper_made": &"heavy_made", &"barkeep_made": &"lean_made"}


func _man(model: StringName, id: String) -> HumanBody:
	var him := HumanBody.new()
	him.body_model = model
	him.person_id = StringName(id)
	add_child(him)
	return him


func test_each_is_whole_with_the_games_hat_over_his_own_head() -> void:
	for model in MEN:
		check(PeopleBodies.has_model(model), "assets/people/%s.glb is there" % model)
		var info := PeopleBodies.report(model)
		check(info.get("whole", false) and info.get("game_hat", false), "%s comes dressed and wears the game's hat" % model)
		var him := _man(model, "men_" + model)
		await physics_frames(2)
		for shape in ["skin", "head", "shirt", "vest", "trousers", "boots", "hat"]:
			check(him.skin_meshes.keys().any(func(k: String) -> bool: return k.begins_with(shape + "/")),
					"%s wears his %s" % [model, shape])
		# The band sits over his own eyes, not the anatomy's (his head is laid at its own height).
		var fit: Dictionary = PeopleBodies._hat_fits.get(model, {})
		check_near((fit.band as Vector3).y, float(info.hat_eye_y) + PeopleBodies.BAND_ABOVE_EYES, 0.001,
				"%s's hat band above his eyes" % model)
		var rows := BodyMesh.hat_rows(fit)
		check(float((rows[rows.size() - 1][0] as Vector3).y) >= float(fit.top), "%s's crown over his hair" % model)
		check(him.hat_body != null, "%s's hat is a thing a ball can hit" % model)
		him.take_hat_shot(him.hat_body.global_position + Vector3.FORWARD * 0.3, Vector3.BACK, 400.0, null)
		check(him.hat_off, "%s's hat comes off when it's shot" % model)
		him.queue_free()


func test_the_builds_differ() -> void:
	# His skin's width at the belly (a part made wider or narrower about its axis, men.json).
	var width := {}
	for model in MEN:
		var him := _man(model, "build_" + model)
		await physics_frames(2)
		var lo := INF
		var hi := -INF
		for key: String in him.skin_meshes:
			if not (key.begins_with("vest/")):
				continue
			var mi := him.skin_meshes[key] as MeshInstance3D
			for v: Vector3 in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				var p := mi.global_transform * v
				if absf(p.y - 1.1) < 0.03:
					lo = minf(lo, p.x)
					hi = maxf(hi, p.x)
		width[model] = hi - lo
		him.queue_free()
	check(width.heavy_made > width.bold_made * 1.05, "the heavy man is wider at the waist (%s)" % width)
	check(width.lean_made < width.bold_made * 0.95, "the lean man narrower (%s)" % width)


func test_a_townsman_wears_his_mans_mesh_in_his_own_colours() -> void:
	for way: StringName in WAYS:
		check(PeopleBodies.has_model(way), "%s loads (his man's mesh)" % way)
		check_eq(PeopleBodies.mesh_of(way), WAYS[way], "%s wears %s's mesh" % [way, WAYS[way]])
		var him := _man(way, "way_" + way)
		await physics_frames(2)
		var tex := (him.skin_meshes.get("shirt/chest") as MeshInstance3D)
		check(tex != null, "%s has a shirt" % way)
		him.queue_free()
	check(ResourceLoader.exists("res://assets/people/storekeeper_made_shirt.png"), "his own shirt texture")


func test_the_gang_and_townsmen_are_them() -> void:
	var models := []
	for g: Dictionary in TownLife.GANG:
		models.append(g.get("model", &""))
	check_eq(models, MEN, "the three riders are the three men")
	check_eq(TownLife.TOWNSMEN.values(), WAYS.keys(), "the townsmen their colourways")
