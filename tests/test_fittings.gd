extends TestCase
## Fittings fall when what holds them goes (Sean: "lamps and stuff floating in the air after the
## wall they were attached to burns down"): a lit lamp on a wall comes down when the wall's board
## is burnt away, and breaks and spills its burning oil where it lands; what stands on the ground
## is left alone; the street's lamps and props are found.

var world: Node3D
var fire: FireSystem
var fittings: Fittings


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
	fire = FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


## A board standing on the ground and a lit lamp on its face, 1.4 m up.
func _wall_with_lamp() -> Array:
	var s := Structure.new()
	s.structure_id = &"wall"
	s.collapses = false
	world.add_child(s)
	var board := s.add_member("b", &"board", &"weathered_pine", Vector3(1.0, 2.2, 0.025), Vector3(0, 1.1, 0))
	s.infer_supports()
	var lamp := OilLamp.new()
	lamp.name = "WallLamp"
	s.add_child(lamp)
	lamp.position = Vector3(0, 1.4, 0.09)
	lamp.set_lit(true)
	fittings = Fittings.new()
	world.add_child(fittings)
	await physics_frames(Fittings.SETTLE_FRAMES + 2)
	return [s, board, lamp]


func test_a_lamp_on_a_burnt_wall_falls_and_spills_its_oil() -> void:
	var made := await _wall_with_lamp()
	var board: StructureMember = made[1]
	var lamp: OilLamp = made[2]
	var held := fittings.items.filter(func(it: Dictionary) -> bool: return it.node == lamp)
	check_eq(held.size(), 1, "the lamp's a fitting")
	if held.is_empty():
		return
	check((held[0].members as Array).any(func(e: Array) -> bool: return e[0] == board), "held by the board")
	await physics_frames(30)
	check(lamp.global_position.y > 1.3, "still up while the board stands (%.2f)" % lamp.global_position.y)
	# The board burns away.
	board.consumed = true
	board.visible = false
	board.collision_layer = 0
	var down := await wait_until(func() -> bool: return lamp.global_position.y < 0.5, 60 * 3)
	check(down, "it falls (at %.2f)" % lamp.global_position.y)
	await physics_frames(30)
	check(lamp.broken, "and breaks where it lands")
	check(fire.spills.size() >= 1, "its burning oil spilt (%d)" % fire.spills.size())


func test_what_stands_on_the_ground_is_left_alone() -> void:
	var barrel := PropLibrary.spawn(&"barrel")
	world.add_child(barrel)
	barrel.position = Vector3(0.6, 0, 0.5)
	await _wall_with_lamp()
	check(not fittings.items.any(func(it: Dictionary) -> bool: return it.node == barrel), "a barrel on the ground isn't one")


func test_the_street_has_its_fittings() -> void:
	world.queue_free()
	await physics_frames(1)
	world = load("res://scenes/test_street.tscn").instantiate()
	add_child(world)
	await physics_frames(Fittings.SETTLE_FRAMES + 3)
	var f := world.get_node(^"Fittings") as Fittings
	check(f.items.size() > 30, "lamps, lanterns and props found (%d)" % f.items.size())
	var counter_lamp := world.get_node(^"Store/CounterLamp")
	check(f.items.any(func(it: Dictionary) -> bool: return it.node == counter_lamp), "the store's counter lamp among them")
	var sconces := f.items.filter(func(it: Dictionary) -> bool: return (it.node as Node).get_meta(&"prop_id", &"") == &"wall_sconce")
	check(sconces.size() >= 4, "the saloon's sconces among them (%d)" % sconces.size())
	# (The painted signs are the sign member's own: they go with it.)
