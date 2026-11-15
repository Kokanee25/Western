extends TestCase
## The first instant of a blast (issue #596 step 3): a white-orange flash (one light, no shadows,
## gone in about a tenth of a second, and glows that go with it), a low ring of dust kicked out
## along the ground, loose dirt thrown up. GPU particles only: nothing new for the physics.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_slab(Vector3(0, -0.5, 0))
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _slab(at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)
	body.global_position = at


func _named(prefix: String) -> Array[Node]:
	var out: Array[Node] = []
	for n in world.get_children():
		if String(n.name).begins_with(prefix):
			out.append(n)
	return out


func _bodies() -> int:
	var count := 0
	for n in world.find_children("*", "PhysicsBody3D", true, false):
		count += 1
	return count


func test_a_stick_on_the_ground_flashes_rings_and_throws_dirt() -> void:
	var tn := Blast.t()
	var bodies := _bodies()
	BlastCloud.spawn(world, Vector3(0, 0.03, 0), tn.tnt_per_stick)
	var lights := _named("BlastFlash").filter(func(n: Node) -> bool: return n is OmniLight3D)
	check_eq(lights.size(), 1, "one light")
	var light := lights[0] as OmniLight3D
	check(not light.shadow_enabled, "the flash casts no shadows")
	check(light.light_energy > 10.0, "it's bright: %.1f" % light.light_energy)
	check(light.light_color.b > 0.7, "it starts white-hot")
	var glows := _named("BlastFlashGlow")
	check_eq(glows.size(), 1, "the flash's glows")
	check(glows.size() == 1 and (glows[0] as GPUParticles3D).lifetime <= 0.12, "the glows go with the flash")
	await physics_frames(2)
	var ring := _named("BlastRing")
	var dirt := _named("BlastDirt")
	check_eq(ring.size(), 1, "a ring of dust on the ground")
	check_eq(dirt.size(), 1, "dirt thrown up")
	if ring.size() == 1:
		var r := ring[0] as GPUParticles3D
		var pm := r.process_material as ParticleProcessMaterial
		check(r.global_position.y < 0.5, "the ring is low: %.2f" % r.global_position.y)
		check_near(pm.flatness, 1.0, 0.001, "kicked out flat")
		var v := (pm.initial_velocity_min + pm.initial_velocity_max) * 0.5
		var reach := v * v / (pm.damping_min + pm.damping_max)
		check(reach > 2.5 and reach < 8.0, "it stops a few metres out: %.1f m" % reach)
		check(v / ((pm.damping_min + pm.damping_max) * 0.5) < 0.8, "and in a blink")
	if dirt.size() == 1:
		var pm := (dirt[0] as GPUParticles3D).process_material as ParticleProcessMaterial
		check(pm.gravity.y < -9.0, "the dirt falls back")
		check(pm.direction.y > 0.5, "thrown up: %s" % pm.direction)
	check_eq(_bodies(), bodies, "no new bodies for the physics")
	await physics_frames(10)
	check(not is_instance_valid(light), "the flash is gone by a sixth of a second")


func test_high_off_the_ground_there_is_no_ring() -> void:
	BlastCloud.spawn(world, Vector3(0, 3.0, 0), Blast.t().tnt_per_stick)
	await physics_frames(2)
	check_eq(_named("BlastRing").size(), 0, "no ring 3 m up")
	check_eq(_named("BlastDirt").size(), 1, "but its dirt")


func test_under_a_ceiling_the_dirt_turns_under_it() -> void:
	_slab(Vector3(0, 3.5, 0))  # a ceiling 3 m over the floor
	await physics_frames(2)
	var at := Vector3(0, 0.03, 0)
	var vent := BlastCloud.vent_of(world, at)
	var cap := BlastCloud.speed_cap(world, at, vent)
	check(cap < Blast.t().spray_speed_max, "a cap under the ceiling: %.1f m/s" % cap)
	var up := cap * maxf(vent.y, 0.35)
	check(up * up / (2.0 * 9.8) < 3.0, "its rise %.2f m stays under it" % (up * up / 19.6))
	check_eq(BlastCloud.speed_cap(world, Vector3(30, 0.03, 30), Vector3.UP), INF, "no cap in the open")


func test_the_same_blast_throws_the_same() -> void:
	BlastCloud.spawn(world, Vector3(1, 0.03, 2), 0.2)
	BlastCloud.spawn(world, Vector3(1, 0.03, 2), 0.2)
	await physics_frames(2)
	var dirt := _named("BlastDirt")
	check_eq(dirt.size(), 2, "two")
	if dirt.size() == 2:
		check_eq((dirt[0] as GPUParticles3D).seed, (dirt[1] as GPUParticles3D).seed, "seeded by where it went off")
		check((dirt[0] as GPUParticles3D).use_fixed_seed, "a fixed seed")


func test_in_a_small_room_the_ring_stops_at_the_walls() -> void:
	for wall: Array in [[Vector3(2.5, 1, 0), Vector3(1, 3, 6)], [Vector3(-2.5, 1, 0), Vector3(1, 3, 6)],
			[Vector3(0, 1, 2.5), Vector3(6, 3, 1)], [Vector3(0, 1, -2.5), Vector3(6, 3, 1)]]:
		var body := StaticBody3D.new()
		body.collision_layer = Layers.WORLD
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall[1]
		shape.shape = box
		body.add_child(shape)
		world.add_child(body)
		body.global_position = wall[0]
	await physics_frames(2)
	BlastCloud.spawn(world, Vector3(0, 0.03, 0), Blast.t().tnt_per_stick)
	await physics_frames(2)
	var ring := _named("BlastRing")
	check_eq(ring.size(), 1, "a ring")
	if ring.size() == 1:
		var pm := (ring[0] as GPUParticles3D).process_material as ParticleProcessMaterial
		var v := (pm.initial_velocity_min + pm.initial_velocity_max) * 0.5
		var reach := v * v / (pm.damping_min + pm.damping_max)
		check(reach < 2.1, "it stops inside the walls 2 m off: %.2f m" % reach)
