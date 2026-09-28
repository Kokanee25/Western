extends TestCase
## Bullets: travel time and drop, through thin boards (hole you can see through, slower after),
## stopped by thick timber (a blind hole), knocking loose things about, announced on the bus.

var world: Node3D
var ballistics: Ballistics
var wall: Structure
var hits: Array[Dictionary] = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	wall = Structure.new()
	wall.structure_id = &"testwall"
	world.add_child(wall)
	# A pine board 2.5 cm thick at z = -5, and a 20 cm framing beam at z = -8.
	wall.add_member("board", &"board", &"weathered_pine", Vector3(2, 2, 0.025), Vector3(0, 1, -5))
	wall.add_member("beam", &"beam", &"framing", Vector3(2, 2, 0.2), Vector3(0, 1, -8))
	hits.clear()
	Events.bullet_hit.connect(_on_hit)
	await physics_frames(2)


func after_each() -> void:
	Events.bullet_hit.disconnect(_on_hit)
	world.queue_free()
	await physics_frames(1)


func _on_hit(info: Dictionary) -> void:
	hits.append(info)


func _fire() -> Ballistics.Bullet:
	var t: RevolverTuning = load("res://config/revolver.tres")
	return ballistics.fire(Vector3(0, 1, 0), Vector3.FORWARD, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)


func test_through_a_board_and_into_a_beam() -> void:
	var b := _fire()
	check_near(b.energy(), 475.0, 5.0, "a .45 Colt carries about 475 J")
	await wait_until(func() -> bool: return not b.alive, 60)
	check_eq(hits.size(), 2, "hit the board, then the beam")
	var board := wall.get_member(&"testwall/board")
	var beam := wall.get_member(&"testwall/beam")
	check(hits[0].penetrated, "went through the pine board")
	check(hits[0].energy_after < hits[0].energy_before, "lost energy in the board")
	check(not hits[1].penetrated, "stopped in the beam")
	check_eq(board.holes.size(), 1, "the board has a hole")
	check(board.holes[0].through, "and it goes right through")
	check_near((board.holes[0].exit - board.holes[0].entry).length(), 0.025, 0.001, "through the board's thickness")
	check(beam.holes.size() == 1 and not beam.holes[0].through, "a blind hole in the beam")
	var mat := (board.get_child(0) as MeshInstance3D).material_override as ShaderMaterial
	check(mat != null and mat.get_shader_parameter(&"hole_count") == 1, "the board draws its hole")


func test_bullets_take_time_and_drop() -> void:
	wall.get_member(&"testwall/beam").free()
	wall.get_member(&"testwall/board").free()
	var b := _fire()
	await physics_frames(10)
	check_near(b.position.z, -b.velocity.length() * 10.0 / 60.0, 1.5, "travels ~240 m/s, not instantly")
	check(b.position.y < 1.0, "and drops under gravity")


func test_thick_beam_alone_stops_it_cold() -> void:
	wall.get_member(&"testwall/board").free()
	var b := _fire()
	await wait_until(func() -> bool: return not b.alive, 60)
	check_eq(hits.size(), 1, "one hit")
	check(not hits[0].penetrated, "20 cm of framing stops a pistol bullet")


func test_knocks_loose_things_about() -> void:
	wall.get_member(&"testwall/board").free()
	wall.get_member(&"testwall/beam").free()
	var can := RigidBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.1
	cyl.height = 0.3
	shape.shape = cyl
	can.add_child(shape)
	can.mass = 0.05
	can.gravity_scale = 0.0
	can.set_meta(&"ballistic_thickness", 0.0006)
	world.add_child(can)
	can.global_position = Vector3(0, 1, -4)
	await physics_frames(2)
	var b := _fire()
	await physics_frames(10)
	check(can.linear_velocity.z < -1.0, "the can is knocked away (%s)" % can.linear_velocity)
	check(hits.size() >= 1 and hits[0].penetrated, "and the bullet goes through the tin")


func test_holes_are_saved_with_the_member() -> void:
	var b := _fire()
	await wait_until(func() -> bool: return not b.alive, 60)
	var d := wall.get_member(&"testwall/board").to_dict()
	check_eq(d.holes.size(), 1, "hole in the save data")
	check(d.holes[0].through, "through")


func test_glass_shatters_and_the_bullet_goes_on() -> void:
	wall.get_member(&"testwall/board").free()
	var pane := wall.add_member("pane", &"glass", &"glass", Vector3(1.0, 1.2, 0.006), Vector3(0, 1, -3))
	await physics_frames(2)
	var broken: Array[StringName] = []
	var on_broken := func(id: StringName) -> void: broken.append(id)
	Events.member_broken.connect(on_broken)
	var b := _fire()
	await wait_until(func() -> bool: return not b.alive, 60)
	Events.member_broken.disconnect(on_broken)
	check(pane.broken, "the pane is broken")
	check_eq(broken, [&"testwall/pane"] as Array[StringName], "announced")
	check(not (pane.get_child(0) as MeshInstance3D).visible, "the pane is gone, not turned opaque")
	var shards := get_tree().get_nodes_in_group(&"glass_shards")
	check(shards.size() >= 8, "it broke into shards (%d)" % shards.size())
	check(hits.size() == 2 and hits[1].member_id == &"testwall/beam", "the bullet carried on into the beam")
	check(pane.to_dict().broken, "broken in the save data")
	for s in shards:
		s.queue_free()
