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
