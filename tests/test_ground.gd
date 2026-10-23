extends TestCase
## The ground made ready to be dug (docs/briefs/dig-ground.md, step 1): flat where it's never been
## dug, a tile's height field where it has, with no seam a ray, a box or a ball can find between them.

var world: Node3D
var ground: Ground


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	ground = Ground.new()
	world.add_child(ground)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _down(x: float, z: float) -> Dictionary:
	var space := world.get_world_3d().direct_space_state
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, 5.0, z), Vector3(x, -5.0, z), Layers.WORLD))


func test_the_flat_ground_is_at_zero_out_past_its_drawn_edge() -> void:
	for p: Vector2 in [Vector2(0, 0), Vector2(30.3, -8.4), Vector2(299, -299), Vector2(1200, 900)]:
		var hit := _down(p.x, p.y)
		check(not hit.is_empty() and absf((hit.position as Vector3).y) < 1e-3, "ground at y 0 at %s" % p)
		check(not hit.is_empty() and Ground.is_ground(hit.collider), "and it's the ground")
	check_eq(Ballistics.surface_of(ground, Vector3.RIGHT), &"ground", "a ball glances off it as dirt, even off a steep face")


func test_a_dug_tile_meets_the_flat_ground_with_no_seam() -> void:
	# Three tiles side by side and one off on its own; flat, as the ground there was.
	for k in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(-5, 3)]:
		ground.dug_tile(k)
	await physics_frames(2)
	var size := ground.tuning.tile_size()
	var worst := 0.0
	var missed := 0
	# Across the tiles and their edges, on a grid that never lines up with the cells.
	for i in 60:
		for j in 60:
			var x := -1.0 + i * 0.137
			var z := -1.0 + j * 0.137
			var hit := _down(x, z)
			if hit.is_empty() or not Ground.is_ground(hit.collider):
				missed += 1
				continue
			worst = maxf(worst, absf((hit.position as Vector3).y))
	check_eq(missed, 0, "a ray finds the ground everywhere across the tiles")
	check(worst < 1e-3, "and it's flat to the millimetre (worst %.4f m)" % worst)
	check(_down(1.5 * size, 0.5 * size).collider is GroundTile, "a dug tile is its own body")
	check(_down(3.5 * size, 0.5 * size).collider == ground, "next to it, the flat ground")


func test_the_flat_ground_covers_all_but_the_dug_tiles() -> void:
	for k in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-5, 3)]:
		ground.dug_tile(k)
	var half := ground.tuning.drawn_half
	var size := ground.tuning.tile_size()
	var area := 0.0
	for r in ground.flat_rects(half):
		area += r.get_area()
		for k: Vector2i in ground.tiles:
			var hole := Rect2(k.x * size, k.y * size, size, size)
			var o := r.intersection(hole)
			# Rect2 is single precision: 300 m out, a shared edge can overlap by a sliver.
			check(minf(o.size.x, o.size.y) < 1e-4, "no flat rectangle over a dug tile (%s over %s)" % [r, hole])
	check_near(area, 4.0 * half * half - 3.0 * size * size, 0.01, "the flat rest is the whole ground less the tiles")
	var mesh := (ground.get_node(^"Mesh") as MeshInstance3D).mesh
	check_eq(mesh.get_surface_count(), 1, "drawn as one mesh")


func test_a_tile_s_heights_land_where_they_should() -> void:
	# One point raised: the height field and height_at agree on where (x along i, z along j).
	var t := ground.dug_tile(Vector2i(2, -1))
	var i := 10
	var j := 50
	t.heights[t.index(i, j)] = 0.3
	t.rebuild(ground.material)
	await physics_frames(2)
	var p := t.point(i, j)
	check_near(p.y, 0.3, 1e-6, "the point is raised")
	var hit := _down(p.x, p.z)
	check(not hit.is_empty() and absf((hit.position as Vector3).y - 0.3) < 0.005, "a ray down meets it there (%s)" % [hit.get("position")])
	check_near(ground.height_at(p.x, p.z), 0.3, 1e-4, "height_at has it")
	var arrays := (t.get_node(^"Mesh") as MeshInstance3D).mesh.surface_get_arrays(0)
	check_near((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array)[t.index(i, j)].y, 0.3, 1e-6, "and it's drawn there")
	check((arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array)[t.index(i + 1, j)].x > 0.5, "the slope beside it faces away from it")
	var beside := _down(p.x + 0.2, p.z)
	check(not beside.is_empty() and absf((beside.position as Vector3).y) < 1e-3, "four cells off, the ground is flat")


func test_the_mesh_faces_up() -> void:
	var t := ground.dug_tile(Vector2i(0, 0))
	for m: Mesh in [(ground.get_node(^"Mesh") as MeshInstance3D).mesh, (t.get_node(^"Mesh") as MeshInstance3D).mesh]:
		var a := m.surface_get_arrays(0)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		# Godot's front faces wind clockwise seen from the front: (b - a) x (c - a) points away.
		var n := (v[idx[2]] - v[idx[0]]).cross(v[idx[1]] - v[idx[0]])
		check(n.y > 0.0, "its triangles face up, so it's drawn from above")


func test_things_rest_on_a_tile_as_on_the_flat_ground() -> void:
	ground.dug_tile(Vector2i(0, 0))
	var size := ground.tuning.tile_size()
	var boxes: Array[RigidBody3D] = []
	for x in [0.5 * size, 0.5 * size + size * 2.0, size - 0.02]:  # on the tile, on the flat, astride the edge
		var rb := RigidBody3D.new()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.3, 0.2, 0.3)
		cs.shape = box
		rb.add_child(cs)
		rb.position = Vector3(x, 0.5, 1.0)
		world.add_child(rb)
		boxes.append(rb)
	await physics_frames(120)
	for rb in boxes:
		check_near(rb.global_position.y, 0.1, 0.02, "a box comes to rest on the ground at x %.2f" % rb.global_position.x)


# --- Step 2: take and put -------------------------------------------------------------------------

func test_earth_taken_is_earth_put_down() -> void:
	var at := Vector3(10.0, 0.0, -4.0)
	var bank := ground.take(at, 0.4, 0.2)
	check(bank > 0.01, "a bowl's worth taken (%.4f m³)" % bank)
	check_near(ground.height_at(at.x, at.z), -0.2, 0.002, "the bowl's middle is 0.2 m down")
	check_near(ground.earth_moved(), -bank, bank * 0.02, "the ground is short what was taken")
	ground.put(at + Vector3(1.5, 0, 0), bank, 0.5)
	check_near(ground.earth_moved(), 0.0, bank * 0.02, "and whole again once it's laid down")
	check(ground.height_at(at.x + 1.5, at.z) > 0.0, "a heap where it went")


func test_ten_scoops_over_one_spot_go_deeper_till_the_hardpan() -> void:
	var at := Vector3(-3.3, 0.0, 6.1)
	var last := 0.0
	for k in 10:
		ground.take(at, 0.3, 0.15)
		var h := ground.height_at(at.x, at.z)
		check(h < last - 0.1, "scoop %d goes deeper (%.2f m)" % [k + 1, h])
		last = h
	for k in 10:
		ground.take(at, 0.3, 0.15)
	check_near(ground.height_at(at.x, at.z), -ground.tuning.earth_depth, 1e-4, "and stops at the hardpan")


func test_a_hole_filled_back_in_stands_proud_by_the_swell() -> void:
	var at := Vector3(4.0, 0.0, 4.0)
	var bank := ground.take(at, 0.5, 0.4)
	ground.put(at, bank, 0.5)
	check_near(ground.earth_moved(), 0.0, bank * 0.02, "all the earth is back")
	check(ground.height_at(at.x, at.z) > -0.05, "the hole's filled (%.3f)" % ground.height_at(at.x, at.z))


func test_loose_earth_slides_to_its_angle_but_a_cut_wall_stands() -> void:
	# A grave: packed walls stand upright.
	var at := Vector3(1.6, 0.0, 1.6)  # astride four tiles
	ground.take(at, 0.4, 1.0)
	var c := ground.tuning.cell
	check(ground.height_at(at.x, at.z) - ground.height_at(at.x + 0.38, at.z) < -0.05, "the cut is steep near its edge")
	# A heap of loose earth: nowhere steeper than its angle of repose (a little over, between passes).
	var p := Vector3(-6.0, 0.0, -6.0)
	ground.put(p, 0.05, 0.25)
	var steepest := 0.0
	for i in range(-12, 13):
		var a := ground.height_at(p.x + i * c, p.z)
		var b := ground.height_at(p.x + (i + 1) * c, p.z)
		steepest = maxf(steepest, absf(b - a) / c)
	check(rad_to_deg(atan(steepest)) < ground.tuning.repose_degrees + 6.0, "a heap's no steeper than loose earth lies (%.0f°)" % rad_to_deg(atan(steepest)))


func test_saved_and_loaded_ground_is_the_same_to_the_millimetre() -> void:
	ground.take(Vector3(1.6, 0, 1.6), 0.5, 0.3)
	ground.put(Vector3(3.0, 0, 1.6), 0.02, 0.6)
	ground.bury(&"strongbox", Vector3(9.0, -0.5, 9.0))
	var d := ground.to_dict()
	var text := JSON.stringify(d)
	var before := []
	for i in 40:
		before.append(ground.height_at(0.7 + i * 0.09, 1.6))
	ground.from_dict(JSON.parse_string(text))
	await physics_frames(2)
	var worst := 0.0
	for i in 40:
		worst = maxf(worst, absf(ground.height_at(0.7 + i * 0.09, 1.6) - float(before[i])))
	check(worst <= 0.0006, "the same to the millimetre (worst %.4f m)" % worst)
	check(ground.buried.has(&"strongbox"), "what's buried stays buried")
	check(text.length() < 20000, "and it's small (%d characters)" % text.length())
	var hit := _down(1.6, 1.6)
	check(not hit.is_empty() and absf((hit.position as Vector3).y - ground.height_at(1.6, 1.6)) < 0.005, "and it collides where it's drawn")


func test_digging_down_to_a_buried_thing_hands_it_back() -> void:
	var found := []
	var on := func(id: StringName, _at: Vector3) -> void: found.append(id)
	Events.ground_uncovered.connect(on)
	ground.bury(&"cache", Vector3(2.0, -0.5, 2.0))
	for k in 3:
		ground.take(Vector3(2.0, 0, 2.0), 0.4, 0.15)
	check(found.is_empty(), "not yet at 0.45 m")
	ground.take(Vector3(2.0, 0, 2.0), 0.4, 0.15)
	Events.ground_uncovered.disconnect(on)
	check_eq(found, [&"cache"], "dug down to it, it's handed back")


func test_a_box_asleep_on_the_ground_falls_into_a_hole_dug_under_it() -> void:
	var rb := RigidBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.2, 0.2, 0.2)
	cs.shape = box
	rb.add_child(cs)
	rb.position = Vector3(5.0, 0.3, 5.0)
	world.add_child(rb)
	await wait_until(func() -> bool: return rb.sleeping, 600)
	check(rb.sleeping, "it's asleep on the flat ground")
	ground.take(Vector3(5.0, 0, 5.0), 0.6, 0.4)
	await physics_frames(120)
	check(rb.global_position.y < -0.15, "it fell into the hole (y %.2f)" % rb.global_position.y)


func test_an_edit_is_cheap() -> void:
	var t0 := Time.get_ticks_usec()
	ground.take(Vector3(1.6, 0, 1.6), 0.25, 0.13)
	ground.put(Vector3(1.6, 0, 1.6), 0.005, 0.6, 0.25, 0.32)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("    a stick's crater and lip over four tiles: %.1f ms" % ms)
	check(ms < 200.0, "a crater's edit takes %.1f ms" % ms)


# --- Step 3: the crater ---------------------------------------------------------------------------

func test_a_stick_s_crater_is_the_fit_s_size() -> void:
	var s := Blast.crater_size(0.2, 0.0)
	check_near(s.x, 0.8 * pow(0.2, 1.0 / 3.0), 1e-4, "0.8 x cbrt(0.2 kg) across (%.2f m)" % s.x)
	check_near(s.y, s.x * 0.27, 1e-4, "and 0.27 of that deep (%.2f m)" % s.y)
	check(Blast.crater_size(0.2, 0.09).x < s.x * 0.6, "gone off higher, smaller")
	check_eq(Blast.crater_size(0.2, 0.5).x, 0.0, "and half a metre up, none")


func test_a_stick_on_the_dirt_digs_its_crater_and_throws_the_lip() -> void:
	var at := Vector3(2.3, DynamiteStick.RADIUS + 0.004, -1.1)
	var report := Blast.detonate(world, at, 0.2)
	var size := Blast.crater_size(0.2, at.y)
	check(report.has("crater"), "it made a crater")
	var r := size.x * 0.5
	check_near(ground.height_at(at.x, at.z), -size.y, 0.03, "its middle is about the fit's depth down (%.3f)" % ground.height_at(at.x, at.z))
	var lip := ground.height_at(at.x + r * 1.25, at.z)
	check(lip > 0.005, "a lip of loose earth round it (%.3f m)" % lip)
	check(ground.height_at(at.x + r * 2.5, at.z) < 0.002, "and beyond the lip, the street as it was")
	# The clods come down and lie as earth.
	await wait_until(func() -> bool: return get_tree().get_nodes_in_group(&"clods").is_empty(), 900)
	check(get_tree().get_nodes_in_group(&"clods").is_empty(), "every clod has come down and lain as earth")
	var packed := float(report.crater.taken_m3) * Blast.t().crater_packed
	check_near(ground.earth_moved(), -packed, packed * 0.1, "the earth counted: short only what was packed down")


func test_the_same_blast_digs_the_same_crater() -> void:
	# The bowl and the lip, as the blast leaves them (where the clods land is the physics': the
	# breakage lab's --repeat=2 checks that, a fresh game each run).
	var at := Vector3(-4.0, DynamiteStick.RADIUS + 0.004, 7.0)
	Blast.detonate(world, at, 0.2)
	var first := JSON.stringify(ground.to_dict())
	for c in get_tree().get_nodes_in_group(&"clods"):
		c.free()
	ground.from_dict({})
	Blast.detonate(world, at, 0.2)
	check(JSON.stringify(ground.to_dict()) == first, "the same ground to the millimetre")


func test_no_crater_under_boards_or_well_above_the_dirt() -> void:
	var s := Structure.new()
	s.structure_id = &"walk"
	world.add_child(s)
	s.add_member("plank", &"plank", &"pine", Vector3(1.0, 0.05, 0.3), Vector3(6.0, 0.4, 6.0))
	s.infer_supports()
	await physics_frames(2)
	var on_board := Blast.detonate(world, Vector3(6.0, 0.425 + DynamiteStick.RADIUS, 6.0), 0.2)
	check(not on_board.has("crater"), "on a plank: the plank takes it, the dirt under it doesn't crater")
	var high := Blast.detonate(world, Vector3(-8.0, 1.2, -8.0), 0.2)
	check(not high.has("crater"), "a metre up: no crater")
	check(ground.tiles.is_empty(), "the ground's undug")


# --- Step 4: what stands, walks and lies round a hole --------------------------------------------

func test_a_post_whose_foot_is_dug_out_loses_the_ground() -> void:
	var s := Structure.new()
	s.structure_id = &"shed"
	world.add_child(s)
	s.add_member("post", &"post", &"framing", Vector3(0.15, 2.0, 0.15), Vector3(6.0, 1.0, 6.0))
	s.add_member("near", &"post", &"framing", Vector3(0.15, 2.0, 0.15), Vector3(9.0, 1.0, 6.0))
	s.infer_supports()
	await physics_frames(2)
	var post := s.get_member(&"shed/post")
	var near := s.get_member(&"shed/near")
	ground.take(Vector3(9.0, 0, 6.6), 0.4, 0.3)  # a hole beside the other post: its foot's still on earth
	await physics_frames(2)
	check(near.grounded and not near.broken, "a hole beside a post leaves it standing")
	ground.take(Vector3(6.0, 0, 6.0), 0.6, 0.5)
	await physics_frames(4)
	check(not post.grounded, "dug out from under, the post is held by the ground no more")
	check(post.broken, "and it falls")


func test_a_chair_over_a_hole_goes_loose() -> void:
	var chair := PropLibrary.spawn(&"chair")
	if not chair is KitProp:
		check(true, "(the chair isn't a kit prop here)")
		chair.free()
		return
	world.add_child(chair)
	chair.global_position = Vector3(-6.0, 0.0, -6.0)
	await physics_frames(12)
	check(not (chair as KitProp).loose, "it stands on the street")
	ground.take(Vector3(-6.0, 0, -6.0), 0.7, 0.4)
	await physics_frames(20)
	check((chair as KitProp).loose, "dug out from under it, it goes loose and falls in")


func test_a_barrel_in_the_street_falls_into_a_hole_dug_under_it() -> void:
	var dressing := Node3D.new()
	dressing.name = "StreetDressing"
	world.add_child(dressing)
	var barrel := PropLibrary.spawn(&"barrel")
	dressing.add_child(barrel)
	barrel.global_position = Vector3(12.0, 0.0, 3.0)
	var other := PropLibrary.spawn(&"barrel")
	dressing.add_child(other)
	other.global_position = Vector3(14.0, 0.0, 3.0)
	# The barrels are the prop kit's (KitProp): they find their own feet, and look again when the
	# ground near them is dug.
	await physics_frames(KitProp.SETTLE_FRAMES + 4)
	check(barrel is KitProp and not barrel.loose and not other.loose, "both barrels stand on the ground")
	ground.take(Vector3(12.0, 0, 3.0), 0.6, 0.5)
	await physics_frames(int(KitProp.CHECK_EVERY * 60.0) + 6)
	check(barrel.loose, "the one over the hole falls in")
	check(not other.loose, "the other stands")


func test_a_man_walking_into_a_deep_hole_goes_in_but_steps_through_a_crater() -> void:
	var walker := HumanBody.new()
	walker.has_gun = false
	world.add_child(walker)
	walker.global_position = Vector3(20.0, 0.0, 10.0)
	await physics_frames(2)
	# A stick's crater on his way: he walks down into it and out.
	ground.take(Vector3(20.0, 0, 8.0), 0.25, 0.12)
	var target := walker.global_position + Vector3(0, 0, -6)
	var lowest := INF
	for i in 200:
		walker.walk_to(target, 1.4, 1.0 / 60.0)
		lowest = minf(lowest, walker.global_position.y)
		await physics_frames(1)
	check(not walker.limp, "a crater doesn't trip him")
	check(lowest < -0.05, "he steps down into it on the way (%.2f)" % lowest)
	# A grave dug across his path: he goes in.
	ground.take(walker.global_position + Vector3(0, 0, -1.0), 0.8, 1.6)
	target = walker.global_position + Vector3(0, 0, -6)
	for i in 120:
		walker.walk_to(target, 1.4, 1.0 / 60.0)
		await physics_frames(1)
		if walker.limp:
			break
	check(walker.limp, "walking on into a hole deeper than a man, he goes in")


func test_a_man_standing_where_a_hole_is_dug_goes_in() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	man.global_position = Vector3(-15.0, 0.0, 12.0)
	await physics_frames(2)
	man.walk_to(man.global_position + Vector3(1, 0, 0), 1.4, 1.0 / 60.0)  # a step: he's stood on it
	await physics_frames(2)
	ground.take(man.global_position, 0.9, 1.8)
	await physics_frames(3)
	check(man.limp, "the ground dug from under him, he falls in")


func test_a_small_fast_thing_doesn_t_go_through_a_dug_tile() -> void:
	# A bone fragment or a chip thrown down at a crater (a height field has no thickness).
	ground.take(Vector3(1.0, 0, 1.0), 0.4, 0.2)
	var bits: Array[RigidBody3D] = []
	for k in 6:
		var rb := RigidBody3D.new()
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.02, 0.02, 0.02)
		cs.shape = box
		rb.add_child(cs)
		rb.mass = 0.006
		rb.position = Vector3(0.7 + k * 0.12, 0.3, 1.0)
		rb.linear_velocity = Vector3(0.5, -9.0, 0.3)
		world.add_child(rb)
		bits.append(rb)
	await physics_frames(90)
	var worst := 0.0
	for rb in bits:
		worst = maxf(worst, ground.height_at(rb.global_position.x, rb.global_position.z) - rb.global_position.y)
	check(worst < 0.12, "none ends deeper than a crater's own depth under the surface (worst %.3f m)" % worst)


func test_west_of_the_store_it_slopes_as_the_layout_says_with_no_seam() -> void:
	# The town's ground (config/town.json): height fields by the chunk, the flat slabs east of them.
	var worst := 0.0
	var missed := 0
	for p: Vector2 in [Vector2(-6, -8), Vector2(-20.3, -9), Vector2(-35, 4), Vector2(-60, -18), Vector2(-80.3, -20.6),
			Vector2(-120, -30), Vector2(-152, 40), Vector2(-140, 210), Vector2(-299, -299), Vector2(-1.0, 0.0)]:
		var hit := _down(p.x, p.y)
		if hit.is_empty() or not Ground.is_ground(hit.collider):
			missed += 1
			continue
		worst = maxf(worst, absf((hit.position as Vector3).y - TownLayout.ground_height(p.x)))
		check_near(ground.height_at(p.x, p.y), TownLayout.ground_height(p.x), 0.001, "height_at says so at %s" % p)
	check_eq(missed, 0, "a ray finds the ground everywhere on the slope")
	check(worst < 0.02, "at the layout's height (worst %.3f m off)" % worst)
	check(TownLayout.ground_height(-120) > 1.0, "and it's up there")


func test_a_tile_dug_on_the_rise_starts_as_the_ground_was() -> void:
	var at := Vector3(-100.0, 0.0, -24.0)
	var before := ground.height_at(at.x, at.z)
	check(before > 1.0, "risen ground (%.2f m)" % before)
	var bank := ground.take(Vector3(at.x, before, at.z), 0.5, 0.3)
	await physics_frames(2)
	check(bank > 0.0, "earth came out")
	check_near(ground.height_at(at.x, at.z), before - 0.3, 0.02, "the hole's 30 cm under the ground there")
	var off := at + Vector3(1.0, 0.0, 0.0)
	check_near(ground.height_at(off.x, off.z), TownLayout.ground_height(off.x, off.z), 0.005, "beside it, the ground as it was")
	var hit := _down(off.x, off.z)
	check(not hit.is_empty() and absf((hit.position as Vector3).y - TownLayout.ground_height(off.x, off.z)) < 0.02,
			"and a ray meets it there (%s)" % [hit.get("position")])
	# Across the dug tile's edge to the chunk's small fields round it: no seam.
	var size := ground.tuning.tile_size()
	var key := ground.key_at(at.x, at.z)
	var missed := 0
	for i in 40:
		var x := key.x * size - 0.5 + i * 0.11
		var h := _down(x, at.z + 1.3)
		if h.is_empty():
			missed += 1
	check_eq(missed, 0, "a ray finds the ground across the tile's edge")
