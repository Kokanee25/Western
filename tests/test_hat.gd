extends TestCase
## A man's hat can be shot off his head (docs/DESTRUCTION_BRIEF.md Part 5): its own thin hitbox,
## a ball through the crown takes it off and it lands as a thing of its own, and the man takes it
## as the nearest miss there is.

var world: Node3D
var ballistics: Ballistics
var said: Array[String] = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	world.add_child(ground)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	said.clear()
	Events.spoke.connect(_on_spoke)
	await physics_frames(2)


func after_each() -> void:
	Events.spoke.disconnect(_on_spoke)
	world.queue_free()
	await physics_frames(2)


func _on_spoke(_who: Node, text: String) -> void:
	said.append(text)


func _man(with_brain: bool) -> HumanBody:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	man.global_position = Vector3(0, 0, -6)
	if with_brain:
		var brain := OutlawBrain.new()
		man.add_child(brain)
	await physics_frames(3)
	return man


## A ball across the top of his crown, from in front of him.
func _through_the_crown(man: HumanBody) -> Ballistics.Bullet:
	var hat: Node3D = man.hat_body
	var crown_top: Vector3 = hat.global_position + Vector3.UP * 0.05
	var gun := RevolverTuning.new()
	var b := ballistics.fire(crown_top + Vector3(0, 0, 6.0), Vector3.FORWARD, gun.muzzle_velocity, gun.bullet_mass, gun.bullet_diameter)
	for i in 30:
		if not b.alive:
			break
		await physics_frames(1)
	return b


func test_a_ball_through_the_crown_takes_his_hat_off() -> void:
	var man: HumanBody = await _man(false)
	check(man.hat_body != null and man.hat_body.collision_layer == Layers.HATS, "his hat has its own hitbox")
	var b := await _through_the_crown(man)
	check(man.hat_off, "the hat's off his head")
	check(man.hat_body == null, "and its hitbox gone")
	check(not b.hits.is_empty() and b.hits[0].get("hat", false), "the ball met the hat")
	check(b.hits[0].penetrated and float(b.hits[0].energy_after) > 500.0, "and went on through the felt (%.0f J)" % float(b.hits[0].energy_after))
	check(man.wounds.is_empty(), "over his head: he's not hurt")
	var hats := get_tree().get_nodes_in_group(&"hats")
	check_eq(hats.size(), 1, "the hat's a thing of its own")
	var hat := hats[0] as RigidBody3D
	check_eq(hat.collision_layer, Layers.DEBRIS, "on the debris layer")
	check(hat.linear_velocity.z < -0.5, "knocked off the way the ball went (%s)" % hat.linear_velocity)
	await physics_frames(90)
	check(hat.global_position.y < 0.6, "and it falls to the ground (%.2f m)" % hat.global_position.y)
	for mi: MeshInstance3D in man.body_meshes(&"head"):
		if String(mi.name).begins_with("Hat"):
			check(not mi.visible, "he's not wearing it any more (%s)" % mi.name)


func test_a_man_whose_hat_is_shot_off_is_frightened_and_says_so() -> void:
	var man: HumanBody = await _man(true)
	var brain: OutlawBrain = man.get_node(^"OutlawBrain") if man.has_node(^"OutlawBrain") else null
	if brain == null:
		for c in man.get_children():
			if c is OutlawBrain:
				brain = c
	var before := brain.fear
	await _through_the_crown(man)
	check(brain.fear >= before + brain.fear_hat_shot, "his fear jumps (%.2f → %.2f)" % [before, brain.fear])
	check(said.any(func(t: String) -> bool: return t in OutlawBrain.LINES[&"hat"]), "and he says so (%s)" % [said])


func test_a_man_with_no_hat_has_nothing_to_shoot_off() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	man.hat_color = Color(0, 0, 0, 0)
	world.add_child(man)
	await physics_frames(2)
	check(man.hat_body == null, "no hat, no hat hitbox")
	check(man.knock_hat_off() == null, "and nothing to knock off")
