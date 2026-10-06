extends TestCase
## A bucket brigade (Sean: "a chain of people for the water bucket throwing on the fire while
## actually passing a bucket"): townsfolk fighting a fire from one trough stand in a line from it
## to the fire, the buckets are handed up the line full and back down it empty, the man at the
## fire throws them, and it goes out.

var world: Node3D
var fire: FireSystem
var men: Array[HumanBody] = []
var brains: Array[CivilianBrain] = []
var trough: WaterTrough


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	fire = FireSystem.new()
	world.add_child(fire)
	trough = WaterTrough.new()
	trough.structure_id = &"trough"
	world.add_child(trough)
	trough.position = Vector3(-1.0, 0.0, 11.0)
	men.clear()
	brains.clear()
	for k in 5:
		var man := HumanBody.new()
		man.has_gun = false
		man.person_id = StringName("townsman%d" % k)
		var brain := CivilianBrain.new()
		brain.name = "Brain"
		brain.post = Vector3(-3.0 + k * 1.5, 0.0, 4.0)
		brain.faces = Vector3(0, 1.4, 0)
		man.add_child(brain)
		world.add_child(man)
		man.global_position = brain.post
		men.append(man)
		brains.append(brain)
	await physics_frames(3)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


## A wall of boards 4 m wide alight, held burning (the fire's own clock stopped), 11 m from the
## trough: several buckets' worth, the line moving along it as each patch goes out.
func _wall_alight() -> Array[StructureMember]:
	var s := Structure.new()
	s.structure_id = &"wall"
	s.collapses = false
	world.add_child(s)
	var boards: Array[StructureMember] = []
	for i in 16:
		boards.append(s.add_member("b%d" % i, &"board", &"weathered_pine", Vector3(0.24, 2.4, 0.025), Vector3(-1.9 + i * 0.25, 1.2, 0)))
	s.infer_supports()
	for b in boards:
		fire.ignite(b)
	fire.step(0.25)
	fire.set_physics_process(false)
	return boards


func test_they_form_a_line_and_pass_the_buckets_up_it() -> void:
	var boards := _wall_alight()
	var formed := await wait_until(func() -> bool:
		var l := get_tree().get_first_node_in_group(&"bucket_lines") as BucketLine
		return l != null and l.links.size() >= 4, 60 * 20)
	check(formed, "four or more of them in one line")
	var line := get_tree().get_first_node_in_group(&"bucket_lines") as BucketLine
	if line == null:
		return
	check_eq(get_tree().get_nodes_in_group(&"bucket_lines").size(), 1, "one line for the one trough")
	check(line.buckets.size() >= 2, "a bucket for every two men (%d)" % line.buckets.size())
	# Once it's working, they stand along the way, the first by the water and the last by the fire.
	var working := await wait_until(func() -> bool: return is_instance_valid(line) and line.thrown >= 2, 60 * 40)
	check(working, "buckets reaching the fire")
	if not is_instance_valid(line) or not working:
		return
	var first := line.links[0].body.global_position
	var last := line.links[line.links.size() - 1].body.global_position
	check(first.distance_to(line.water_spot) < 2.5, "the first man at the water (%.1f m off)" % first.distance_to(line.water_spot))
	var near := fire.fire_near(last, 6.0)
	check(near.count > 0 and last.distance_to(line.throw_spot) < 2.5, "the last man at the fire (%.1f m off his place)" % last.distance_to(line.throw_spot))
	# A bucket in a man's hand is in his hand.
	for i in line.links.size():
		var b := line.holding[i]
		if b >= 0:
			var bucket: Node3D = line.buckets[b].node
			var hand := (line.links[i].body.parts[&"hand_r"] as Node3D).global_position
			check(bucket.global_position.distance_to(hand) < 0.5, "man %d's bucket is in his hand (%.2f m)" % [i, bucket.global_position.distance_to(hand)])
	var out := await wait_until(func() -> bool: return boards.all(func(m: StructureMember) -> bool: return not m.burning), 60 * 120)
	check(out, "they put it out (%d boards still burning)" % boards.filter(func(m: StructureMember) -> bool: return m.burning).size())
	if is_instance_valid(line):
		check(line.passed >= line.thrown, "buckets handed on (%d passes, %d thrown)" % [line.passed, line.thrown])
	await physics_frames(60 * 5)
	check(get_tree().get_nodes_in_group(&"bucket_lines").is_empty(), "and the line's broken up")
	check(get_tree().get_nodes_in_group(&"bucket_runners").is_empty(), "nobody still carrying")
	for m in men:
		check(m.physiology.burns < 0.5, "%s not badly burnt (%.2f)" % [m.person_id, m.physiology.burns])


func test_handing_a_bucket_on_a_full_going_up_and_an_empty_coming_down_swap() -> void:
	var line := BucketLine.new()
	line.water = trough
	line.fire = fire
	world.add_child(line)
	line.set_physics_process(false)  # driven by hand here
	line.water_spot = Vector3(-1, 0, 10)
	line.throw_spot = Vector3(0, 0, 2.2)
	for k in 3:
		line._add(brains[k])
	await physics_frames(2)
	# Man 0 has a full one for man 1, who has an empty one for man 0.
	var full := 0
	var empty := 1 if line.buckets.size() > 1 else -1
	check(empty >= 0, "two buckets for three men")
	if empty < 0:
		return
	line.holding = [full, empty, -1]
	line.buckets[full].full = true
	line.buckets[empty].full = false
	check(line._can_take(1, 0), "a man with an empty going back can take a full going on")
	line._hand(0, 1)
	for k in 40:
		line._move_buckets(1.0 / 60.0)
	check_eq(line.holding[0], empty, "the empty in man 0's hand")
	check_eq(line.holding[1], full, "the full in man 1's")
	check_eq(line.passed, 2, "two hand-overs")
	line.disband()


## Seen in the street: the fire climbed to a porch roof and the man at the fire was sent to stand on
## the roof (the ray that finds standing room started above it), so nobody threw. He stands below.
func test_the_man_at_the_fire_stands_on_the_ground_not_a_roof() -> void:
	var roof := StaticBody3D.new()
	roof.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 0.1, 8)
	shape.shape = box
	roof.add_child(shape)
	world.add_child(roof)
	roof.position = Vector3(0, 3.0, 0)
	var line := BucketLine.new()
	line.water = trough
	line.fire = fire
	world.add_child(line)
	line.set_physics_process(false)
	await physics_frames(2)
	line.water_spot = Vector3(-1, 0, 10)
	var spot := line._stand_by(Vector3(0, 3.1, 0))
	check(spot.y < 0.5, "he stands in the street (%.2f m up)" % spot.y)
	line.disband()
