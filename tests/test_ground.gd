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
	for p: Vector2 in [Vector2(0, 0), Vector2(-50.3, -8.4), Vector2(299, -299), Vector2(-1200, 900)]:
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
