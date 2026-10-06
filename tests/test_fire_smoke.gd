extends TestCase
## Smoke that knows the buildings (Sean: "realistic smoke that will sit under the overhang of the
## building then roll out and start going up in the air"; docs/briefs/smoke.md). A wall with a
## porch roof out in front of it, a board on the wall alight under the roof.

var world: Node3D
var fire: FireSystem
var building: Structure
var lit: StructureMember


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	fire = FireSystem.new()
	world.add_child(fire)
	# The smoke's rules at a set rate (the game's own rate is tuned for its look and may move).
	fire.tuning = fire.tuning.duplicate()
	fire.tuning.smoke_per_m2 = 25.0
	building = Structure.new()
	building.structure_id = &"porch"
	building.collapses = false
	world.add_child(building)
	# The front wall, boards 0.25 m wide from x -4 to 4, 3.2 m tall, at z 0; the porch roof 2.6 m
	# up, out to z -2.5 in front of it (-z), boards running out from the wall (a store's porch).
	for i in 32:
		var m := building.add_member("wall%d" % i, &"board", &"weathered_pine", Vector3(0.24, 3.2, 0.025), Vector3(-3.875 + i * 0.25, 1.6, 0.0))
		if i == 16:
			lit = m
	for i in 32:
		building.add_member("roof%d" % i, &"board", &"weathered_pine", Vector3(0.24, 0.03, 2.5), Vector3(-3.875 + i * 0.25, 2.6, -1.25))
	building.infer_supports()
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_it_gathers_under_the_overhang_rolls_out_and_rises() -> void:
	if not SmokeField.available():
		print("    (no native plugin: nothing to test)")
		return
	fire.ignite(lit)
	fire.step(0.25)
	fire.set_physics_process(false)  # held burning, as it is: the board's own smoke, nothing more
	var field := SmokeField.around(fire, fire._box_of(building), building)
	await physics_frames(60 * 20)
	# Most smoke in a band of points (the cells are half a metre: points, not exact heights).
	var most := func(xz: Vector2, y0: float, y1: float) -> float:
		var best := 0.0
		for x in [xz.x - 0.5, xz.x, xz.x + 0.5]:
			var y := y0
			while y <= y1:
				best = maxf(best, field.density_at(Vector3(x, y, xz.y)))
				y += 0.1
		return best
	var under: float = most.call(Vector2(0.1, -1.6), 1.4, 2.4)     # under the roof, out from the board
	var over: float = most.call(Vector2(0.1, -1.2), 2.9, 3.6)      # just over the roof, above the fire
	var out: float = most.call(Vector2(0.1, -2.65), 2.9, 4.5)      # past the roof's edge, risen
	print("    smoke: under %.3f, out %.3f, over %.3f" % [under, out, over])
	check(under > 0.1, "smoke gathers under the overhang (%.3f)" % under)
	check(out > 0.03, "rolls out past its edge and rises (%.3f)" % out)
	check(over < 0.25 * out, "little through the roof over the fire (%.3f, against %.3f past the edge)" % [over, out])
	# Under the roof it lies along the ceiling.
	var high: float = most.call(Vector2(0.1, -1.6), 1.8, 2.1)
	var low: float = most.call(Vector2(0.1, -1.6), 0.3, 0.7)
	check(high > 2.0 * low, "a layer under the roof (%.3f up high, %.3f low down)" % [high, low])


func test_a_burning_building_gets_its_smoke_and_loses_its_particles() -> void:
	if not SmokeField.available():
		print("    (no native plugin: nothing to test)")
		return
	fire.ignite(lit)
	await physics_frames(60 * 2)
	check_eq(fire._smoke.size(), 1, "one field for the building")
	check(fire.smoked(lit), "the burning board's smoke is the field's")
	var fx := fire._fx.get(lit) as FireFX
	if fx:
		var particles := fx.find_children("*", "GPUParticles3D", true, false).size() + lit.find_children("*", "GPUParticles3D", true, false).size()
		check(particles <= 1 * lit.pieces.size(), "flames only, no particle smoke (%d emitters)" % particles)
