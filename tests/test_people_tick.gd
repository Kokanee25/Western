extends TestCase
## PeopleTick (more-cores step 4): the people tick from one place, in the order they came into the
## world, each man's own nodes after him in the order the tree has them; a node's switch is still
## its own.

var world: Node3D
var log_ticks: Array[String] = []


## A node of a man's with a tick of its own, as his brain, face and senses have: it notes each tick.
class Recorder:
	extends Node
	var out: Array[String]

	func _enter_tree() -> void:
		(get_parent() as HumanBody).add_ticker(self)

	func _exit_tree() -> void:
		(get_parent() as HumanBody).remove_ticker(self)

	func _ready() -> void:
		set_physics_process(true)

	func tick(_delta: float) -> void:
		out.append("%s/%s" % [get_parent().name, name])


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
	log_ticks.clear()


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _man(n: String, at: Vector3, seed_value: int) -> HumanBody:
	var man := HumanBody.new()
	man.name = n
	man.rng_seed = seed_value
	man.has_gun = false
	world.add_child(man)
	man.global_position = at
	return man


func _recorder(man: HumanBody, n: String) -> Recorder:
	var r := Recorder.new()
	r.name = n
	r.out = log_ticks
	man.add_child(r)
	return r


func test_people_tick_in_the_order_they_came() -> void:
	var men: Array[HumanBody] = []
	for i in 3:
		men.append(_man("M%d" % i, Vector3(i * 2.0, 0, 0), 11 + i))
	_recorder(men[1], "A")
	_recorder(men[1], "B")
	_recorder(men[0], "A")
	_recorder(men[2], "A")
	await physics_frames(3)
	check(men[0].tick_index < men[1].tick_index and men[1].tick_index < men[2].tick_index,
			"indices in the order they came (%d, %d, %d)" % [men[0].tick_index, men[1].tick_index, men[2].tick_index])
	var tick := men[2].get_child(0, true)
	check(tick is PeopleTick, "PeopleTick stands where the last man in does (his first, internal child)")
	log_ticks.clear()
	await physics_frames(1)
	check_eq(log_ticks, ["M0/A", "M1/A", "M1/B", "M2/A"] as Array[String], "one frame: each man in turn, his nodes in tree order")
	# His index is his for good: out of the world and back, he keeps his place.
	var was := men[0].tick_index
	world.remove_child(men[0])
	world.add_child(men[0])
	log_ticks.clear()
	await physics_frames(1)
	check_eq(men[0].tick_index, was, "kept his index")
	check_eq(log_ticks, ["M0/A", "M1/A", "M1/B", "M2/A"] as Array[String], "still first, though last in the tree now")
	check(men[2].get_child(0, true) is PeopleTick, "the node stays with the last by index")
	# A man added before the frame's ticks ticks in it, as before.
	men[1].queue_free()
	men[2].queue_free()
	men[0].queue_free()
	await physics_frames(2)
	var late := _man("M9", Vector3.ZERO, 19)
	_recorder(late, "A")
	log_ticks.clear()
	await physics_frames(1)
	check_eq(log_ticks, ["M9/A"] as Array[String], "the first man in ticks in the frame he came")


func test_a_switch_off_is_still_his_own() -> void:
	var a := _man("M0", Vector3.ZERO, 21)
	var b := _man("M1", Vector3(2, 0, 0), 22)
	var ra := _recorder(a, "A")
	_recorder(b, "A")
	await physics_frames(2)
	ra.set_physics_process(false)
	b.process_mode = Node.PROCESS_MODE_DISABLED
	log_ticks.clear()
	await physics_frames(2)
	check_eq(log_ticks, [] as Array[String], "physics processing off, or disabled: not ticked")
	ra.set_physics_process(true)
	log_ticks.clear()
	await physics_frames(1)
	check_eq(log_ticks, ["M0/A"] as Array[String], "back on: ticked again")
