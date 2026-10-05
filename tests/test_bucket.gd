extends TestCase
## Putting a fire out (Sean: "it would be cool if you could actually have time to put it out";
## DESIGN.md: water puts it out): a bucket filled at a trough, thrown at burning boards, puts out
## the ones it drenches and leaves them wet, so they hold off the fire beside them a while. Water
## doesn't put out burning lamp oil.

var world: Node3D
var fire: FireSystem


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	fire = FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)  # the tests run the fire's rules themselves
	await physics_frames(2)


func after_each() -> void:
	for a in [&"fire", &"reload", &"weapon_bucket"]:
		Input.action_release(a)
	world.queue_free()
	await physics_frames(2)


func _player() -> Player:
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO  # facing -Z
	await physics_frames(3)
	var b := player.bucket()
	player.select_weapon(b)
	await wait_until(func() -> bool: return b.is_ready_in_hand(), 180)
	b.needs_captured_mouse = false
	return player


## A wall of boards across your way 2.5 m ahead, at chest height, all alight a while.
func _burning_wall(z := -2.5) -> Array[StructureMember]:
	var s := Structure.new()
	s.structure_id = &"wall"
	s.collapses = false
	world.add_child(s)
	var boards: Array[StructureMember] = []
	for i in 8:
		boards.append(s.add_member("b%d" % i, &"board", &"weathered_pine", Vector3(0.24, 2.2, 0.025), Vector3(-0.875 + i * 0.25, 1.1, z)))
	s.infer_supports()
	for b in boards:
		fire.ignite(b)
	for i in 20:
		fire.step(0.5)
	return boards


func test_it_fills_at_a_trough_and_nowhere_else() -> void:
	var trough := WaterTrough.new()
	trough.structure_id = &"trough"
	world.add_child(trough)
	trough.position = Vector3(-1.0, 0, -1.0)
	var player := await _player()
	var b := player.bucket()
	check(b.water_in_reach() != null, "the trough's within reach")
	Input.action_press(&"reload")
	await physics_frames(2)
	Input.action_release(&"reload")
	await wait_until(func() -> bool: return b.litres > 0.0, 120)
	check_eq(b.litres, BucketViewmodel.CAPACITY, "full")
	b.litres = 0.0
	player.global_position = Vector3(12, 0, 12)
	await physics_frames(2)
	check(not b.fill(), "no water out here")
	check_eq(b.litres, 0.0, "still empty")


func test_a_bucket_puts_out_a_burning_wall() -> void:
	var boards := _burning_wall()
	check_eq(boards.filter(func(m: StructureMember) -> bool: return m.burning).size(), 8, "the wall's alight")
	var player := await _player()
	var b := player.bucket()
	b.litres = BucketViewmodel.CAPACITY
	var thrown := b._let_go()
	check(thrown.landed.size() >= BucketViewmodel.DROPS * 0.6, "most of it reaches the wall (%d drops)" % thrown.landed.size())
	var still := boards.filter(func(m: StructureMember) -> bool: return m.burning).size()
	check(still <= 3, "most of it's out (%d of 8 still burning)" % still)
	check(boards.any(func(m: StructureMember) -> bool: return m.wet > 0.0), "and wet")
	check_eq(b.litres, 0.0, "the bucket's empty")


func test_wet_boards_hold_off_the_fire() -> void:
	var times: Array[float] = []
	for wet in [false, true]:
		var s := Structure.new()
		s.structure_id = StringName("rig_%s" % wet)
		s.collapses = false
		world.add_child(s)
		var x := 0.0 if not wet else 10.0
		var a := s.add_member("a", &"board", &"weathered_pine", Vector3(0.24, 2.0, 0.025), Vector3(x, 1.0, 0))
		var n := s.add_member("n", &"board", &"weathered_pine", Vector3(0.24, 2.0, 0.025), Vector3(x + 0.25, 1.0, 0))
		s.infer_supports()
		await physics_frames(1)
		if wet:
			fire.douse(n.global_position + Vector3(0, 0, 0.05), 0.15, 1.0)
			check(n.wet > 0.5, "the board's soaked (%.2f l)" % n.wet)
		fire.ignite(a)
		var t := 0.0
		while t < 900.0 and not n.burning:
			fire.step(0.5)
			t += 0.5
		check(n.burning, "it catches in the end (wet %s)" % wet)
		times.append(t)
	check(times[1] > times[0] + 30.0, "wet, it holds off the fire half a minute or more (%.0f s dry, %.0f s wet)" % [times[0], times[1]])


func test_water_doesnt_put_out_burning_oil() -> void:
	fire.spill(Vector3(0, 0, -2))
	var put_out := fire.douse(Vector3(0, 0.05, -2), 0.6, 10.0)
	check_eq(put_out, 0, "nothing put out")
	check_eq(fire.spills.size(), 1, "the oil burns on")


func test_nobody_takes_a_bucket_for_a_gun() -> void:
	var deeds: Array[StringName] = []
	var watch := func(actor: Node, kind: StringName, _t: Node, _at: Vector3) -> void:
		if actor is Player:
			deeds.append(kind)
	Events.deed.connect(watch)
	var player := await _player()
	await physics_frames(30)
	Events.deed.disconnect(watch)
	check(player.bucket().is_ready_in_hand(), "the bucket's out")
	check(not deeds.has(&"draw") and not deeds.has(&"aim_at"), "no one saw a weapon drawn (%s)" % [deeds])
