extends TestCase
## The inside woods (Sean's A, 2026-10-26, #405): a building's inside floor and framing are drawn
## in R1 darkened (`int_r1_floor`, `int_r1_framing`) through the member's `look`, while its `wood`
## still decides how it bears, breaks, burns and stops a ball. The porch is outside: R1.

var world: Node3D


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
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _material_of(m: StructureMember) -> Material:
	return (m.drawn_node() as MeshInstance3D).material_override


func test_inside_woods_are_promoted() -> void:
	for wood in [&"int_r1_floor", &"int_r1_framing"]:
		check(WoodMaterials.get_material(wood, 0) is ShaderMaterial, "%s drawn" % wood)
		var stub := FileAccess.get_file_as_string("res://assets/textures/woods/%s_b0.png.import" % wood)
		check(stub.contains("compress/mode=2"), "%s VRAM-compressed" % wood)
	# A strip a batch: the inside woods draw in as many batches as the woods they stand in for.
	check_eq(WoodMaterials.strip_count(&"int_r1_floor"), WoodMaterials.strip_count(&"floor"), "floor strips")
	check_eq(WoodMaterials.strip_count(&"int_r1_framing"), WoodMaterials.strip_count(&"framing"), "framing strips")


func test_a_building_is_drawn_inside_in_the_inside_woods() -> void:
	var b := FalseFrontBuilding.new()
	b.structure_id = &"inside_test"
	b.width = 7.0
	b.depth = 10.0
	b.furnished = false
	world.add_child(b)
	await physics_frames(2)
	var inside := {}
	var porch := 0
	for m in b.get_members():
		if String(m.member_id).contains("/porch/"):
			porch += 1
			check(m.look == &"", "%s, on the porch, drawn in its own wood" % m.member_id)
		elif m.look != &"":
			inside[m.wood] = inside.get(m.wood, 0) + 1
			check_eq(m.look, FalseFrontBuilding.INSIDE_LOOK[m.wood], "%s's look" % m.member_id)
			check(m.wood in [&"floor", &"framing"], "%s keeps its wood for the physics" % m.member_id)
	check(inside.get(&"floor", 0) > 10, "the inside floor in the inside wood (%s)" % inside)
	check(inside.get(&"framing", 0) > 10, "the inside framing in the inside wood (%s)" % inside)
	check(porch > 0, "a porch to keep outside")


func test_a_look_draws_another_wood_and_is_kept_when_cut() -> void:
	var s := Structure.new()
	s.structure_id = &"look_test"
	world.add_child(s)
	var m := s.add_member("board", &"floor_board", &"floor", Vector3(2.0, 0.03, 0.15), Vector3(0, 1, 0))
	var own := _material_of(m)
	m.look = &"int_r1_floor"
	check_eq(m.drawn_wood(), &"int_r1_floor", "drawn in its look")
	check(_material_of(m) != own, "its mesh takes the look's material")
	check_eq(m.wood, &"floor", "its wood unchanged")
	check(_material_of(m) == WoodMaterials.get_material(&"int_r1_floor", hash(m.member_id)), "the look's own material")
	var plain := s.add_member("plain", &"floor_board", &"floor", Vector3(2.0, 0.03, 0.15), Vector3(0, 1, 1))
	plain.look = &"int_r1_floor"
	plain.look = &""
	check_eq(_material_of(plain), WoodMaterials.get_material(&"floor", hash(plain.member_id)), "an empty look draws its own wood again")
	var left := s.cut_member(m, -0.3, 0.3)
	check_eq(left.size(), 2, "cut in two")
	for p in left:
		check_eq(p.look, &"int_r1_floor", "a cut piece keeps the look")
		check_eq(p.wood, &"floor", "and the wood")
