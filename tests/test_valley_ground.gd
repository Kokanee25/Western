extends TestCase
## The valley's ground (docs/briefs/valley-plan.md §12, G2): the bake of config/valley.json read as
## written, the ground's height (Ground.height_at) where a ray meets its collision and within 1 cm
## of the bake, its levels of detail, and the digging (Ground's own, as in the town: tests/
## test_ground.gd) over it: a crater on its slopes, a hole a box falls into, a save that comes back.

var world: Node3D
var ground: Ground


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	ground = Ground.new()
	ground.tuning = load("res://config/ground_valley.tres")
	ground.terrain = ValleyTerrain.main()
	ground.material = StandardMaterial3D.new()
	ground.valley_material = StandardMaterial3D.new()
	world.add_child(ground)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _down(x: float, z: float, top := 400.0) -> Dictionary:
	var space := world.get_world_3d().direct_space_state
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, -200.0, z), Layers.WORLD))


func test_the_bake_reads_as_written() -> void:
	var t := ValleyTerrain.main()
	check(t.is_loaded(), "the bake is there")
	check_eq(Vector2i(t.width, t.depth), Vector2i(2241, 1857), "2 m points over the envelope, in whole chunks")
	check_eq(t.spacing, 2.0, "at 2 m")
	var env := ValleyLayout.main().envelope()
	check(t.rect().encloses(env), "it covers the envelope (%s)" % t.rect())
	check_near(t.height(0.0, 0.0), 0.0, 1e-4, "the crossroads at Y 0")
	# Points the bake holds (tools/valley/valley_plan.py's own heights there, from its file).
	for p: Vector3 in [Vector3(2374, 23.2032, 1438), Vector3(204, 13.216, -1180), Vector3(-590, 26.8576, -892),
			Vector3(24, -3.408, 102), Vector3(-1422, 41.0176, 1196), Vector3(-2000, 174.08, 2312), Vector3(2400, -30.0, -1048)]:
		check_near(t.height(p.x, p.z), p.y, 1e-3, "the bake at (%d, %d)" % [p.x, p.z])
	# The plan's shaping in it: the town's plane, the places' pads.
	check_near(t.height(100.0, 50.0), -0.006 * 100.0 - 0.032 * 50.0, 0.01, "the town's plane")
	var v := ValleyLayout.main()
	for id in ["widow_homestead", "ore_works", "mine", "harlan_homestead", "baron_ranch", "church"]:
		var at := v.place_at(id)
		# (A place's hills over its pad: G6's farmhouse knoll on the widow's.)
		var hills := 0.0
		for b: Dictionary in (v.place(id).get("hills", {}) as Dictionary).get("bumps", []):
			var d := Vector2(float(b.at[0]), float(b.at[1])).length()
			var k := clampf(1.0 - d / float(b.r), 0.0, 1.0)
			hills += float(b.h) * k * k * (3.0 - 2.0 * k)
		check_near(t.height(at.x, at.y), float(v.place_pad(id).y) + hills, 0.03, "%s on its pad" % id)
	check(t.meta.get("valley_json_sha256", "") != "", "it says which valley.json it was baked from")


func test_the_bake_is_this_valley_json_s() -> void:
	# Baked from the file as it is (tools/valley/valley_plan.py --bake after any edit to it).
	var sha := FileAccess.get_sha256("res://config/valley.json").substr(0, 16)
	check_eq(String(ValleyTerrain.main().meta.get("valley_json_sha256", "")), sha, "config/valley_ground/ baked from this valley.json (re-bake: valley_plan.py --bake)")


func test_the_ground_is_where_the_bake_says() -> void:
	var t := ground.terrain
	var rng := RandomNumberGenerator.new()
	rng.seed = 709
	var worst := 0.0
	var worst_at := Vector2.ZERO
	var missed := 0
	var off := 0
	var r := ValleyLayout.main().envelope()
	for k in 2000:
		var x := rng.randf_range(r.position.x, r.end.x)
		var z := rng.randf_range(r.position.y, r.end.y)
		var hit := _down(x, z)
		if hit.is_empty() or not Ground.is_ground(hit.collider):
			missed += 1
			continue
		var d := absf((hit.position as Vector3).y - ground.height_at(x, z))
		if d > worst:
			worst = d
			worst_at = Vector2(x, z)
		if absf(ground.height_at(x, z) - t.height(x, z)) > 1e-6:
			off += 1
	check_eq(missed, 0, "a ray finds the ground everywhere in the envelope")
	check(worst < 0.01, "where it meets the collision is Ground.height_at, within 1 cm (worst %.4f m at %s)" % [worst, worst_at])
	check_eq(off, 0, "and undug, Ground.height_at is the bake's")
	# At the bake's own points, the raw file's heights (offset + scale x value) within its step.
	var worst_pt := 0.0
	for k in 300:
		var i := rng.randi_range(0, t.width - 1)
		var j := rng.randi_range(0, t.depth - 1)
		worst_pt = maxf(worst_pt, absf(ground.height_at(t.x0 + i * t.spacing, t.z0 + j * t.spacing) - t.sample(i, j)))
	check(worst_pt < 1e-4, "on the bake's points exactly (%.5f)" % worst_pt)
	check_eq(Ballistics.surface_of(_down(0.3, 0.3).collider, Vector3.UP), &"ground", "a ball meets it as dirt")


func test_the_chunks_and_the_levels() -> void:
	var vg := ground.valley
	check(vg != null, "the valley's chunks")
	check_eq(vg.chunks, Vector2i(35, 29), "128 m chunks over the bake")
	check_eq(vg.bodies.size(), 35 * 29, "a body each")
	vg.focus = Vector3(0, 1.7, 0)
	vg.prime()
	var c := vg.census()
	check(int(c.by_level.get(0, 0)) >= 9, "the chunks round the crossroads drawn at 2 m (%s)" % c)
	check(int(c.by_level.get(4, 0)) == 6, "and the top level's six blocks always there")
	# Never a block drawn and its children with it: a block with children built has them in its
	# place only nearer than its split (Godot's visibility ranges, HLOD).
	var bad := 0
	for b: ValleyGround.Block in vg._blocks.values():
		if b.parent and b.mi.visibility_parent.is_empty():
			bad += 1
		if not b.kids.is_empty() and b.split and b.mi.visibility_range_begin <= 0.0:
			bad += 1
		if not b.split and b.mi.visibility_range_begin > 0.0:
			bad += 1
	check_eq(bad, 0, "each block shown or swapped for its children by distance")
	# Off to the far corner: built there, the crossroads' finest freed.
	vg.focus = Vector3(2300, 30, 2100)
	vg.prime()
	await process_frames(2)
	var near_town := vg._blocks.has(Vector3i(0, 15, 10))
	var near_corner := vg._blocks.has(Vector3i(0, 33, 27))
	check(not near_town, "the crossroads' chunk freed once far off")
	check(near_corner, "the far corner's drawn at 2 m")


func test_a_stick_s_crater_on_the_valley_s_slope() -> void:
	# On the bench's slope north of town (a few degrees), not the town's plane.
	var x := 40.0
	var z := -150.0
	var y0 := ground.height_at(x, z)
	var slope := (ground.height_at(x + 1, z) - ground.height_at(x - 1, z)) * 0.5
	var at := Vector3(x, y0 + DynamiteStick.RADIUS + 0.004, z)
	var report := Blast.detonate(world, at, 0.2)
	var size := Blast.crater_size(0.2, DynamiteStick.RADIUS + 0.004)
	check(report.has("crater"), "it made a crater")
	check_near(ground.height_at(x, z) - y0, -size.y, 0.03, "its middle the fit's depth down (%.3f, the slope %.3f)" % [ground.height_at(x, z) - y0, slope])
	var r := size.x * 0.5
	check(ground.height_at(x, z + r * 1.25) - ground.terrain.height(x, z + r * 1.25) > 0.005, "a lip of loose earth round it")
	check_near(ground.height_at(x + r * 3.0, z), ground.terrain.height(x + r * 3.0, z), 0.002, "and past it, the bake")
	await physics_frames(2)
	var hit := _down(x, z, y0 + 5.0)
	check(not hit.is_empty() and hit.collider is GroundTile, "a ray down its middle meets the dug tile, not the chunk under it")
	if not hit.is_empty():
		check_near((hit.position as Vector3).y, ground.height_at(x, z), 0.01, "at the crater's floor")
	var ck := ground.valley.tile_chunk(ground.key_at(x, z))
	check(ground.valley._holes.has(ck), "its chunk has the tile cut out")
	await wait_until(func() -> bool: return get_tree().get_nodes_in_group(&"clods").is_empty(), 900)
	check(get_tree().get_nodes_in_group(&"clods").is_empty(), "every clod has come down and lain as earth")
	var packed := float(report.crater.taken_m3) * Blast.t().crater_packed
	check_near(ground.earth_moved(), -packed, packed * 0.1, "the earth counted: short only what was packed down")


func test_dug_tiles_meet_the_chunks_with_no_seam() -> void:
	# Across a slope, tiles side by side over a chunk's edge (x = -2000 + 128 k: 48 is one).
	var size := ground.tuning.tile_size()
	for k in [Vector2i(11, -40), Vector2i(12, -40), Vector2i(12, -39)]:
		ground.dug_tile(k)
	await physics_frames(2)
	var worst := 0.0
	var missed := 0
	for i in 50:
		for j in 40:
			var x := 11 * size - 1.0 + i * 0.211
			var z := -40 * size - 1.0 + j * 0.211
			var hit := _down(x, z)
			if hit.is_empty() or not Ground.is_ground(hit.collider):
				missed += 1
				continue
			worst = maxf(worst, absf((hit.position as Vector3).y - ground.terrain.height(x, z)))
	check_eq(missed, 0, "a ray finds the ground across the tiles and the chunk round them")
	check(worst < 0.01, "and it's the bake's, within 1 cm (worst %.4f m)" % worst)
	check(_down(12.5 * size, -39.5 * size).collider is GroundTile, "a dug tile is its own body")
	check(not (_down(13.5 * size, -39.5 * size).collider is GroundTile), "next to it, the chunk")


func test_a_box_asleep_falls_into_a_hole_dug_under_it() -> void:
	var x := -300.0
	var z := 300.0
	var y := ground.height_at(x, z)
	var box := RigidBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = BoxShape3D.new()
	(cs.shape as BoxShape3D).size = Vector3(0.3, 0.3, 0.3)
	box.add_child(cs)
	world.add_child(box)
	box.global_position = Vector3(x, y + 0.2, z)
	await physics_frames(120)
	var rest := box.global_position.y
	check_near(rest, y + 0.15, 0.05, "it lies on the valley's ground (%.3f over %.3f)" % [rest, y])
	ground.take(Vector3(x, y, z), 0.8, 0.6)
	await physics_frames(120)
	check(box.global_position.y < rest - 0.3, "and drops into the hole dug under it (%.3f -> %.3f)" % [rest, box.global_position.y])
	check(box.global_position.y > ground.height_at(x, z) - 0.05, "onto its floor, not through it")


func test_saved_and_loaded_valley_ground_is_the_same_to_the_millimetre() -> void:
	var at := Vector3(500.0, 0.0, 600.0)
	at.y = ground.height_at(at.x, at.z)
	var bank := ground.take(at, 1.0, 0.5)
	ground.put(at + Vector3(2.5, 0, 0), bank, 0.9)
	var before := JSON.stringify(ground.to_dict())
	var h := ground.height_at(at.x, at.z)
	ground.from_dict({})
	check_near(ground.height_at(at.x, at.z), ground.terrain.height(at.x, at.z), 1e-6, "cleared: the bake again")
	check(ground.valley._holes.is_empty(), "and no chunk cut")
	ground.from_dict(JSON.parse_string(before))
	check(JSON.stringify(ground.to_dict()) == before, "the same ground to the millimetre")
	check_near(ground.height_at(at.x, at.z), h, 0.0015, "the hole back")
	await physics_frames(2)
	var hit := _down(at.x, at.z, at.y + 5.0)
	check(not hit.is_empty() and hit.collider is GroundTile, "and its collision")


func test_holes_dug_deep_in_the_canyon_and_high_on_the_bench() -> void:
	# The canyon's floor by the trestle is ~20 m under the crossroads, the mine's bench ~80 m over:
	# a tile's solid earth stands under its own surface wherever that is.
	var t := ground.terrain
	for p: Vector2 in [Vector2(2380, -1040), Vector2(1183, -80), ValleyLayout.main().place_at("mine")]:
		var y := ground.height_at(p.x, p.y)
		ground.take(Vector3(p.x, y, p.y), 1.0, 0.6)
		var tile := ground.tiles.get(ground.key_at(p.x, p.y)) as GroundTile
		check(tile != null, "a tile dug at (%.0f, %.0f), %.1f m" % [p.x, p.y, y])
		if tile == null:
			continue
		var bad := 0
		for c in tile.get_children():
			if c is CollisionShape3D and c.shape is BoxShape3D:
				var box := c.shape as BoxShape3D
				var top := tile.global_position.y + (c as Node3D).position.y + box.size.y * 0.5
				if box.size.y <= 0.0 or top > ground.height_at(tile.global_position.x, tile.global_position.z) + 0.6:
					bad += 1
		check_eq(bad, 0, "its columns stand under it, down past the hardpan (%.1f m)" % y)
		check_near(ground.height_at(p.x, p.y), y - 0.6, 0.02, "and the hole is 0.6 m deep")
	check(t.height(2380, -1040) < -20.0, "(the low spot is low)")
