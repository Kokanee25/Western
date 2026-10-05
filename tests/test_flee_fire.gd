extends TestCase
## Townsfolk get clear of fire (both playtests: five townsfolk burnt at their posts without a
## word): fire near him and a townsman shouts it, runs clear, watches it burn, and goes back to his
## post once it's out.

var world: Node3D
var fire: FireSystem
var man: HumanBody
var brain: CivilianBrain
var said: Array[String] = []


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
	man = HumanBody.new()
	man.has_gun = false
	man.person_id = &"townsman"
	brain = CivilianBrain.new()
	brain.name = "Brain"
	brain.post = Vector3(0, 0, 3)
	brain.faces = Vector3(0, 1.4, 0)
	man.add_child(brain)
	world.add_child(man)
	man.global_position = brain.post
	said.clear()
	Events.spoke.connect(_on_spoke)
	await physics_frames(3)


func after_each() -> void:
	Events.spoke.disconnect(_on_spoke)
	world.queue_free()
	await physics_frames(2)


func _on_spoke(who: Node, text: String) -> void:
	if who == man:
		said.append(text)


## A wall of boards alight 3 m from him, held burning (the fire's own clock stopped).
func _wall_alight() -> Array[StructureMember]:
	var s := Structure.new()
	s.structure_id = &"wall"
	s.collapses = false
	world.add_child(s)
	var boards: Array[StructureMember] = []
	for i in 6:
		boards.append(s.add_member("b%d" % i, &"board", &"weathered_pine", Vector3(0.24, 2.4, 0.025), Vector3(-0.6 + i * 0.25, 1.2, 0)))
	s.infer_supports()
	for b in boards:
		fire.ignite(b)
	fire.step(0.25)  # the fire's grid of where things are
	fire.set_physics_process(false)
	return boards


func test_he_shouts_it_and_gets_clear() -> void:
	_wall_alight()
	var fled := await wait_until(func() -> bool: return brain.mood == CivilianBrain.Mood.FLEEING, 60 * 2)
	check(fled, "fire 3 m off: he's off")
	await physics_frames(60 * 2)
	check(said.size() >= 1 and CivilianBrain.LINES[&"fire"].has(said[0]), "he shouts it: %s" % [said])
	var clear := await wait_until(func() -> bool: return man.global_position.length() > CivilianBrain.FIRE_CLEAR - 1.0, 60 * 12)
	check(clear, "he gets clear (%.1f m from it)" % man.global_position.length())
	check(man.physiology.burns == 0.0, "unburnt")
	check_eq(brain.mood, CivilianBrain.Mood.FLEEING, "and stays clear while it burns")


func test_he_goes_back_when_its_out() -> void:
	var boards := _wall_alight()
	await wait_until(func() -> bool: return man.global_position.length() > CivilianBrain.FIRE_CLEAR - 1.0, 60 * 14)
	for b in boards:
		b.burning = false
		fire.active.erase(b)
	var back := await wait_until(func() -> bool: return man.global_position.distance_to(brain.post) < 0.5, 60 * (CivilianBrain.FIRE_OVER + 30))
	check(back, "back at his post (%.1f m off)" % man.global_position.distance_to(brain.post))
	check(brain.mood != CivilianBrain.Mood.FLEEING, "not fleeing now")


func test_no_fire_he_minds_his_post() -> void:
	await physics_frames(60 * 3)
	check_eq(brain.mood, CivilianBrain.Mood.CALM, "calm")
	check(man.global_position.distance_to(brain.post) < 0.3, "at his post")


func test_a_calm_outlaw_gets_clear_too() -> void:
	var gun := HumanBody.new()
	var b := OutlawBrain.new()
	b.name = "Brain"
	gun.add_child(b)
	world.add_child(gun)
	gun.global_position = Vector3(2, 0, -3)
	man.queue_free()
	await physics_frames(3)
	_wall_alight()
	var clear := await wait_until(func() -> bool: return gun.global_position.length() > OutlawBrain.FIRE_CLEAR - 2.0, 60 * 14)
	check(clear, "he gets clear (%.1f m from it)" % gun.global_position.length())
	check_eq(b.mood, OutlawBrain.Mood.CALM, "no fight in it")


## A trough near the fire: once he's clear, he carries water to it till it's out, and says so.
func test_he_carries_water_to_it_till_its_out() -> void:
	var trough := WaterTrough.new()
	trough.structure_id = &"trough"
	world.add_child(trough)
	trough.position = Vector3(-6.0, 0, 4.0)
	var boards := _wall_alight()
	var out := await wait_until(func() -> bool: return boards.all(func(m: StructureMember) -> bool: return not m.burning), 60 * 120)
	check(out, "he put it out (%d boards still burning)" % boards.filter(func(m: StructureMember) -> bool: return m.burning).size())
	check(said.any(func(t: String) -> bool: return CivilianBrain.LINES[&"buckets"].has(t)), "he called for buckets: %s" % [said])
	check(man.physiology.burns < 0.5, "not badly burnt (%.2f)" % man.physiology.burns)
	await physics_frames(60 * 3)
	check(not brain.is_in_group(&"bucket_runners"), "and stopped carrying")


## Past saving, nobody goes near it.
func test_past_saving_they_let_it_burn() -> void:
	var trough := WaterTrough.new()
	trough.structure_id = &"trough"
	world.add_child(trough)
	trough.position = Vector3(-6.0, 0, 4.0)
	var s := Structure.new()
	s.structure_id = &"big"
	s.collapses = false
	world.add_child(s)
	for i in 50:
		var m := s.add_member("b%d" % i, &"board", &"weathered_pine", Vector3(0.24, 2.4, 0.025), Vector3(-6.0 + i * 0.25, 1.2, 0))
		fire.ignite(m)
	s.infer_supports()
	fire.step(0.25)
	fire.set_physics_process(false)
	await wait_until(func() -> bool: return said.any(func(t: String) -> bool: return CivilianBrain.LINES[&"lost"].has(t)), 60 * 20)
	check(said.any(func(t: String) -> bool: return CivilianBrain.LINES[&"lost"].has(t)), "he says it's lost: %s" % [said])
	check(not brain.is_in_group(&"bucket_runners"), "and carries no water")
