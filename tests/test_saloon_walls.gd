extends TestCase
## Saloon B's walls (#1030, the prop lab's S5): the foot rail stands on the floor, the rifle holds on its
## pegs, and the spec's S5 batch names kit props that exist and sit in the rooms they're meant for.

var world: Node3D
var wall: Structure


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
	wall = Structure.new()
	wall.structure_id = &"wall"
	world.add_child(wall)
	for x in [-1.2, -0.6, 0.0, 0.6, 1.2]:
		wall.add_member("stud%d" % int(x * 10), &"stud", &"framing", Vector3(0.05, 3.0, 0.1), Vector3(x, 1.5, -0.07))
	for i in 20:
		wall.add_member("board%d" % i, &"board", &"framing", Vector3(2.6, 0.15, 0.02), Vector3(0, 0.075 + 0.15 * i, -0.01))
	wall.infer_supports()


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_the_rifle_holds_on_its_pegs_on_the_wall() -> void:
	var p := PropKit.make(&"rifle_pegs") as KitProp
	p.position = Vector3(0, 1.6, 0)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 3)
	check(p.hung() and not p.loose, "hung and held")
	check(p.settle().is_empty(), "nothing falls: the rifle lies on the pegs")
	var box := AABB()
	for m in p.get_members():
		box = m.structure_aabb() if box.size == Vector3.ZERO else box.merge(m.structure_aabb())
	check(box.size.x > 1.0 and box.size.x < 1.15, "a carbine's length (%.2f m)" % box.size.x)


func test_the_foot_rail_stands_on_the_floor_and_is_a_section_long() -> void:
	var p := PropKit.make(&"foot_rail") as KitProp
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 3)
	check(p.settle().is_empty(), "stands")
	var box := AABB()
	for m in p.get_members():
		box = m.structure_aabb() if box.size == Vector3.ZERO else box.merge(m.structure_aabb())
	check_near(box.size.x, 2.9, 0.05, "a bar section long")
	check(box.size.y > 0.2 and box.size.y < 0.26, "a foot off the floor (%.2f m)" % box.size.y)


func test_the_walls_batch_names_real_props_in_their_rooms() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/buildings/saloon_b.json"))
	var entries: Array = PropDressing.expand(spec.dressing.batches.S5)
	check(entries.size() > 40, "the batch has its props (%d)" % entries.size())
	var ids := {}
	for en: Dictionary in entries:
		check(not ids.has(en.id), "id %s is its own" % en.id)
		ids[en.id] = true
		check(not PropKit.definition(StringName(en.kit)).is_empty(), "%s: the kit has %s" % [en.id, en.kit])
		# Inside the building's 16.46 x 21.95 footprint, the ground floor (below 4 m) or the upper floors'.
		check(float(en.at[0]) > 0.0 and float(en.at[0]) < 16.4 and float(en.at[2]) > 0.0 and float(en.at[2]) < 21.9,
				"%s is inside the building %s" % [en.id, en.at])
	check(ids.has("wall_clock") and ids.has("steer_skull") and ids.has("stag") and ids.has("rifle"), "the clock, trophies and rifle are placed")
