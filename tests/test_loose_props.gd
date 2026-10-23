extends TestCase
## The prop kit's loose rigid props (LooseProp: the spittoon, the tin cup): they stand where
## they're put and draw batched; a ball goes through them, holing both sides, and knocks them; a
## boot sends one rolling, dented; tipped, a spittoon lets its spit go; its table going over or a
## blast close by takes a cup off; nothing breaks them and they don't burn.

var world: Node3D
var floor_s: Structure
var spilled: Array = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	floor_s = Structure.new()
	floor_s.structure_id = &"floor"
	world.add_child(floor_s)
	for x in [-1.8, -0.6, 0.6, 1.8]:
		floor_s.add_member("joist%d" % int(x * 10), &"joist", &"framing", Vector3(0.05, 0.25, 4.0), Vector3(x, 0.125, 0))
	for i in 16:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(4.0, 0.05, 0.25), Vector3(0, 0.275, -1.875 + 0.25 * i))
	floor_s.infer_supports()
	spilled.clear()
	Events.liquid_spilled.connect(_on_spilled)


func after_each() -> void:
	Events.liquid_spilled.disconnect(_on_spilled)
	world.queue_free()
	await physics_frames(2)


func _on_spilled(_at: Vector3, liquid: StringName, litres: float, _source: Node) -> void:
	spilled.append({"liquid": liquid, "litres": litres})


func _put(id: StringName, at := Vector3(0, 0.3, 0)) -> LooseProp:
	var p := PropKit.make(id) as LooseProp
	world.add_child(p)
	p.global_position = at
	await physics_frames(GlassProp.SETTLE_FRAMES + 3)
	return p


func _verts(p: LooseProp) -> PackedVector3Array:
	var out := PackedVector3Array()
	for mi: MeshInstance3D in p.model.find_children("*", "MeshInstance3D", true, false):
		if not mi.name.begins_with("Mark"):
			out.append_array(mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	return out


func test_they_are_loose_props_and_stand() -> void:
	for id: StringName in [&"spittoon", &"tin_cup"]:
		var p := await _put(id, Vector3(0, 0.3, 0))
		check(p is LooseProp, "the kit makes the %s a loose prop" % id)
		check(not p.loose and not p.broken, "it stands where it's put")
		check_near(p.body.global_position.y, 0.3, 0.02, "on the boards")
		check(PropLibrary.spawn(id) is LooseProp, "PropLibrary hands out the kit's %s" % id)
		p.queue_free()
		await physics_frames(1)


func test_a_ball_holes_the_spittoon_both_sides_and_knocks_it() -> void:
	var p := await _put(&"spittoon")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var aim := p.body.global_position + Vector3(0, 0.15, 0)
	var from := aim + Vector3(-5, 0.4, 0)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (aim - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(2)
	check(p.loose, "it's knocked loose")
	check_eq(p.holes, 2, "a hole in and a hole out")
	check(p.dents >= 1, "dented round them")
	check(p.body.linear_velocity.x > 0.05 or p.body.global_position.x > 0.01, "and it's moving off along the shot")
	check(not p.broken, "brass doesn't break")


func test_a_kick_sends_it_rolling_dented_and_it_spills() -> void:
	var p := await _put(&"spittoon")
	var before := _verts(p)
	check_eq(p.take_blow(p.body.global_position + Vector3(-0.15, 0.12, 0), Vector3(48.0, 0, 0)), &"moved", "a boot moves it")
	check(p.body.linear_velocity.length() > 3.0, "the boot and 2 kg go on together at %.1f m/s" % p.body.linear_velocity.length())
	var after := _verts(p)
	var moved := 0
	for i in mini(before.size(), after.size()):
		if before[i].distance_to(after[i]) > 0.001:
			moved += 1
	check(moved > 0, "its brass is pushed in where the boot landed (%d vertices)" % moved)
	var other := await _put(&"spittoon", Vector3(1.2, 0.3, 1.2))
	check(_verts(other) == before, "another spittoon's not dented with it (its own mesh)")
	await physics_frames(120)
	check(p.body.global_position.x > 0.5, "it's gone off across the floor (%.2f m)" % p.body.global_position.x)
	check(p.body.global_basis.y.y < 0.5, "over on its side")
	check(p.spilt and spilled.any(func(s: Dictionary) -> bool: return s.liquid == &"spit"), "what was in it's on the boards")


func test_its_table_going_over_takes_the_cup_and_a_blast_throws_one() -> void:
	var table := PropKit.spawn(&"card_table")
	table.position = Vector3(0, 0.3, 0)
	world.add_child(table)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	var cup := await _put(&"tin_cup", Vector3(0.1, 0.3 + 0.761, 0.1))
	check(not cup.loose, "it stands on the table")
	table.go_loose(Vector3.ZERO, Vector3(160.0, 0, 0), table.global_position + Vector3(0, 0.75, 0))
	await physics_frames(2)
	check(cup.loose, "the table going over takes it")
	var far := await _put(&"tin_cup", Vector3(-1.5, 0.3, 1.5))
	Events.exploded.emit(far.body.global_position + Vector3(-1.5, 0.05, 0), Blast.t().tnt_per_stick)
	await physics_frames(2)
	check(far.loose, "a stick 1.5 m off throws it")
	await physics_frames(90)
	check(not far.broken and not cup.broken, "tin doesn't break")


func test_it_doesnt_burn() -> void:
	var p := await _put(&"spittoon")
	var fire := FireSystem.new()
	world.add_child(fire)
	fire.spill(p.body.global_position)
	await physics_frames(600)
	check(not p.broken and not p.loose, "ten seconds in the flames and it's still there")
