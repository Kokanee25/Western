extends TestCase
## Destruction step 2 (docs/DESTRUCTION_BRIEF.md): members carved as voxels by the native plugin.
## A shotgun charge bites a ragged hole out of a board and its pellets carry on; a ball carves a
## channel its own size that a line passes through; what's left of the section is what the
## structure stands on. Needs the plugin (addons/saltcreek_native: cargo build --release there and
## copy the library into its bin/); test_native says when it isn't loaded.

var world: Node3D
var wall: Structure
var board: StructureMember
var ballistics: Ballistics


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	# A test wall: two posts and a siding board nailed across their faces.
	wall = Structure.new()
	wall.structure_id = &"wall"
	world.add_child(wall)
	wall.add_member("post_l", &"post", &"framing", Vector3(0.1, 2.0, 0.1), Vector3(-0.55, 1.0, 0.0))
	wall.add_member("post_r", &"post", &"framing", Vector3(0.1, 2.0, 0.1), Vector3(0.55, 1.0, 0.0))
	board = wall.add_member("board", &"board", &"weathered_pine", Vector3(1.2, 0.15, 0.022), Vector3(0.0, 1.0, 0.061))
	wall.infer_supports()
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _plugin() -> bool:
	check(StructureMember.voxels_available(), "the native plugin carves (VoxelMember registered, voxel damage on)")
	return StructureMember.voxels_available()


func _fly() -> void:
	for i in 60:
		if ballistics.bullets.is_empty():
			break
		await physics_frames(1)


func _finish() -> void:
	var works := wall.get_node_or_null(^"VoxelWorks") as VoxelWorks
	if works:
		works.finish()
	await physics_frames(2)


func _gone_m3(m: StructureMember) -> float:
	return float(m.voxels.total() - m.voxels.solid()) * float(m.voxels.cell_volume())


func _ray_hits(from: Vector3, to: Vector3, m: StructureMember) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and hit.collider == m


func test_a_charge_at_contact_bites_a_known_volume_and_the_pellets_carry_on() -> void:
	if not _plugin():
		return
	var gun: Resource = load("res://config/shotgun.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var face_z := 0.072
	var pellets := ballistics.fire_charge(Vector3(0.0, 1.0, face_z + 0.03), Vector3.FORWARD, gun.pellets,
			deg_to_rad(gun.pattern_degrees), gun.muzzle_velocity, gun.pellet_mass, gun.pellet_diameter, [], rng,
			gun.blast_joules, gun.blast_reach)
	await _fly()
	check(board.voxels != null, "the board's voxelised on its first hit")
	# All the blast goes into the wood (the pellets after the first follow its hole and widen it),
	# and a share of what each spends going through.
	var spall := 0.0
	var channels := 0.0
	for h: Dictionary in board.holes:
		spall += float(h.spall)
		if h.through:
			channels += PI * pow(float(h.radius), 2.0) * (h.exit as Vector3).distance_to(h.entry)
	var tuning := StructureMember.voxel_damage_tuning()
	var from_blast: float = gun.blast_joules * tuning.blast_share / tuning.spall_cost(&"weathered_pine") * 1e-6
	check(spall >= from_blast * 0.98, "the whole blast tears wood out: %.1f cm³ of spall, %.1f from the blast" % [spall * 1e6, from_blast * 1e6])
	var gone := _gone_m3(board)
	var want := spall + channels
	check(gone > want * 0.85 and gone < want * 1.35, "the volume gone %.1f cm³ is what the hits asked for, %.1f" % [gone * 1e6, want * 1e6])
	var carried := 0
	for p in pellets:
		if not p.hits.is_empty() and p.hits[0].penetrated and float(p.hits[0].energy_after) > 50.0:
			carried += 1
	check(carried >= gun.pellets - 1, "the pellets go on through (%d of %d with energy left)" % [carried, gun.pellets])
	# A ragged bite right through, a few centimetres across.
	await _finish()
	var through := 0
	for off: Vector2 in [Vector2.ZERO, Vector2(0.015, 0), Vector2(-0.015, 0), Vector2(0, 0.015), Vector2(0, -0.015)]:
		if not _ray_hits(Vector3(off.x, 1.0 + off.y, 0.3), Vector3(off.x, 1.0 + off.y, -0.3), board):
			through += 1
	check(through == 5, "you see through it 1.5 cm from the middle every way (%d of 5)" % through)
	check(_ray_hits(Vector3(0.3, 1.0, 0.3), Vector3(0.3, 1.0, -0.3), board), "and the board's whole away from it")
	check(board.get_child(0).get_node_or_null(^"Carved") != null, "fresh-cut wood shows in the bite")
	check(not get_tree().get_nodes_in_group(&"wood_chips").is_empty(), "chips thrown")
	for c: Node in get_tree().get_nodes_in_group(&"wood_chips"):
		check_eq((c as RigidBody3D).collision_layer, Layers.DEBRIS, "chips are debris")


func test_the_same_charge_bites_the_same_hole() -> void:
	if not _plugin():
		return
	var gun: Resource = load("res://config/shotgun.tres")
	var shapes := []
	for run in 2:
		if run == 1:
			await after_each()
			await before_each()
		var rng := RandomNumberGenerator.new()
		rng.seed = 21
		ballistics.fire_charge(Vector3(0.0, 1.0, 1.5), Vector3.FORWARD, gun.pellets, deg_to_rad(gun.pattern_degrees),
				gun.muzzle_velocity, gun.pellet_mass, gun.pellet_diameter, [], rng, gun.blast_joules, gun.blast_reach)
		await _fly()
		shapes.append([board.voxels.solid(), board.voxel_section])
	check_eq(shapes[0], shapes[1], "seeded: the same voxels go")


func test_a_balls_channel_lets_a_line_through() -> void:
	if not _plugin():
		return
	var gun := RevolverTuning.new()
	var b := ballistics.fire(Vector3(0.2, 1.02, 3.0), Vector3.FORWARD, gun.muzzle_velocity, gun.bullet_mass, gun.bullet_diameter)
	await _fly()
	check(not b.hits.is_empty() and b.hits[0].penetrated, "the ball goes through the board")
	# The ball's own channel and the wood it splinters out, to the nearest whole cells (a cell at 64
	# a metre is about the ball's width).
	var gone := _gone_m3(board)
	var channel := PI * pow(gun.bullet_diameter * 0.5, 2.0) * 0.022
	var asked := channel + float(board.holes[0].spall)
	var cells: float = board.voxels.cell_volume()
	check(gone > channel * 0.8 and gone <= asked + 3.0 * cells, "a channel about the ball's size: %.2f cm³ (channel %.2f + spall %.2f, cells of %.2f)" % [
			gone * 1e6, channel * 1e6, float(board.holes[0].spall) * 1e6, cells * 1e6])
	await _finish()
	check(not _ray_hits(Vector3(0.2, 1.02, 0.5), Vector3(0.2, 1.02, -0.5), board), "a line down the channel passes")
	check(_ray_hits(Vector3(0.2, 1.06, 0.5), Vector3(0.2, 1.06, -0.5), board), "4 cm off it the board stops it")
	# The ball is the gun range's: one hole, through.
	check(board.holes.size() == 1 and board.holes[0].through, "one hole, through")
	check(board.section_left(StructuralAnalysis.load_tuning()) < 1.0, "the section's lost a little")


func test_a_stud_with_sixty_percent_gone_falls_when_loaded() -> void:
	if not _plugin():
		return
	var frame := Structure.new()
	frame.structure_id = &"frame"
	world.add_child(frame)
	frame.add_member("sill", &"sill", &"framing", Vector3(1.0, 0.1, 0.15), Vector3(0.0, 0.05, 2.0))
	var stud := frame.add_member("stud", &"stud", &"framing", Vector3(0.05, 2.4, 0.15), Vector3(0.0, 1.3, 2.0))
	stud.extra_load = 600.0 * 9.81  # what the wall above puts on it
	frame.infer_supports()
	var sound: float = StructuralAnalysis.new().analyse(frame).utilisation[stud.member_id]
	check(sound < 0.8, "the sound stud carries 600 kg (%.0f%%)" % (sound * 100.0))
	frame.settle()
	check(not stud.broken, "and stands")
	# Shot through at 1.2 m: a channel 8 cm wide across it, 60 % of its section (a 2x6).
	stud.carve_hit(stud.to_global(Vector3(-0.025, -0.1, 0.0)), stud.to_global(Vector3(0.025, -0.1, 0.0)), true, Vector3.RIGHT, 0.04, 0.0, 0.0)
	check(absf(stud.voxel_section.x - 0.4) < 0.06, "60 %% of its section's gone (%.0f %% left)" % (stud.voxel_section.x * 100.0))
	check(absf(stud.weakest_t() - (-0.1)) < 0.05, "at the hole (t %.2f)" % stud.weakest_t())
	frame.settle()
	check(stud.broken, "loaded, it gives way")


func test_without_voxel_damage_holes_are_drawn_as_before() -> void:
	var tuning := StructureMember.voxel_damage_tuning()
	var was := tuning.enabled
	tuning.enabled = false
	var gun := RevolverTuning.new()
	ballistics.fire(Vector3(0.2, 1.02, 3.0), Vector3.FORWARD, gun.muzzle_velocity, gun.bullet_mass, gun.bullet_diameter)
	await _fly()
	tuning.enabled = was
	check(board.voxels == null, "not voxelised")
	check(board.holes.size() == 1 and board.holes[0].through, "a drawn hole, through")
	var mat := (board.get_child(0) as MeshInstance3D).material_override as ShaderMaterial
	check(mat != null and mat.shader == StructureMember.HOLE_SHADER, "drawn by the hole shader")
