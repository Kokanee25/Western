extends TestCase
## Scenes that hold their cast (SceneHold, #1050): the cast walked beat by beat, a quiet zone round it
## that townsfolk keep off its marks and chairs and armed men stay out of, and you break it: a shot,
## a drawn gun, a hit, you on a mark. Written as the issue's measures:
## - a held actor reaches his mark with a townsman walking across his path;
## - a townsman never takes a held chair;
## - an armed townsman stops at the zone's edge (an unarmed one walks in);
## - an armed man in the zone doesn't engage a held actor, unless the actor turns on him;
## - a shot inside the zone lets everyone go within the frame, and the actors fight or flee by their
##   own brains.

var world: Node3D
var player: Player


func before_each() -> void:
	SceneHold.clear_all()
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	world.add_child(Ballistics.new())


func after_each() -> void:
	SceneHold.clear_all()
	world.queue_free()
	player = null
	await physics_frames(2)


func _player(at: Vector3) -> Player:
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = at
	player.rotation = Vector3.ZERO
	return player


func _man(id: String, at: Vector3, armed := false, brain: Node = null) -> HumanBody:
	var man := HumanBody.new()
	man.person_id = StringName(id)
	man.name = id.capitalize()
	man.rng_seed = 900 + id.hash() % 97
	man.has_gun = armed
	man.start_holstered = true
	if brain != null:
		brain.name = "Brain"
		if brain is CivilianBrain:
			(brain as CivilianBrain).post = at
			(brain as CivilianBrain).faces = at + Vector3(0, 1.5, -2)
		man.add_child(brain)
	world.add_child(man)
	man.global_position = at
	return man


func _chair(at: Vector3, yaw := 0.0) -> KitProp:
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	return chair


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- The cast held --------------------------------------------------------------------------------

func test_a_held_actor_reaches_his_mark_with_a_townsman_crossing_his_path() -> void:
	var actor := _man("actor", Vector3(0, 0, 4))
	var mark := Vector3(0, 0, -5)
	var hold := SceneHold.claim(world, {"label": &"test", "cast": [actor], "marks": [mark], "centre": Vector3.ZERO, "radius": 7.0})
	# A townsman on his way across, timed to meet the actor halfway.
	var tb := CivilianBrain.new()
	var towns := _man("towns", Vector3(-4.5, 0, 0), false, tb)
	await physics_frames(3)
	tb.go_to(Vector3(4.5, 0, 0), Vector3(4.5, 1.5, -3))
	# A second one stood on the mark itself as the scene starts: he steps off it.
	var sb := CivilianBrain.new()
	var stood := _man("stood", mark + Vector3(0.2, 0, 0.1), false, sb)
	sb.go_to(mark + Vector3(0.2, 0, 0.1))
	await physics_frames(3)
	var got := false
	var closest := INF
	for i in 60 * 14:
		if actor.walk_to(mark, 1.3, 1.0 / 60.0):
			got = true
			break
		closest = minf(closest, _flat(actor.global_position, towns.global_position))
		await physics_frames(1)
	check(got, "the actor reaches his mark (at %s, %.2f m off; the townsman came within %.2f m)" % [actor.global_position, _flat(actor.global_position, mark), closest])
	check(_flat(stood.global_position, mark) >= SceneHold.MARK_R * 0.6 or got, "the man on the mark made way (%.2f m)" % _flat(stood.global_position, mark))
	check(hold.on, "nothing of the townsmen's broke it")


func test_a_townsman_never_takes_a_held_chair() -> void:
	var held_chair := _chair(Vector3(0, 0, -2))
	var other := _chair(Vector3(3.0, 0, -2))
	var hold := SceneHold.claim(world, {"chairs": [held_chair], "centre": Vector3(0, 0, -2), "radius": 5.0})
	var man := _man("sitter", Vector3(-1.5, 0, 0.5))
	await physics_frames(3)
	check(Seating.free_chair_near(get_tree(), man.global_position, Seating.NEAR, man) == other, "the held chair isn't free to him: the other one is")
	for i in 60 * 6:
		Seating.sit_step(man, held_chair, 1.0 / 60.0)
		await physics_frames(1)
	check(held_chair.seated == null, "he never sat in it (%s)" % held_chair.seated)
	check(_flat(man.global_position, Seating.spot(held_chair)) >= SceneHold.MARK_R - 0.05, "and stood off its seat (%.2f m)" % _flat(man.global_position, Seating.spot(held_chair)))
	# The scene over, it's a chair like any other.
	hold.release()
	var sat := false
	for i in 60 * 6:
		if Seating.sit_step(man, held_chair, 1.0 / 60.0):
			sat = true
			break
		await physics_frames(1)
	check(sat, "let go, he sits in it")


func test_an_armed_townsman_stops_at_the_zones_edge() -> void:
	var c := Vector3(0, 0, 0)
	var actor := _man("actor", c)
	SceneHold.claim(world, {"cast": [actor], "centre": c, "radius": 6.0})
	var armed := _man("armed", Vector3(14, 0, 0), true)
	var plain := _man("plain", Vector3(-14, 0, 0))
	await physics_frames(3)
	for i in 60 * 14:
		armed.walk_to(c + Vector3(1.5, 0, 1.5), 1.4, 1.0 / 60.0)
		plain.walk_to(c + Vector3(-2.0, 0, 1.5), 1.4, 1.0 / 60.0)
		await physics_frames(1)
	check(_flat(armed.global_position, c) >= 6.0, "the armed man stopped outside it (%.2f m from its centre)" % _flat(armed.global_position, c))
	check(_flat(armed.global_position, c) < 7.5, "at its edge, not short of it (%.2f m)" % _flat(armed.global_position, c))
	check(_flat(plain.global_position, c) < 3.5, "an unarmed man walks in (%.2f m)" % _flat(plain.global_position, c))


func test_an_armed_man_in_the_zone_leaves_a_held_actor_be() -> void:
	_player(Vector3(0, 0, 12))
	var actor := _man("shooter", Vector3(0, 0, 0), true)
	var ob := OutlawBrain.new()
	ob.nerve = 99.0
	var guard := _man("guard", Vector3(4, 0, 0), true, ob)
	var hold := SceneHold.claim(world, {"cast": [actor], "centre": Vector3.ZERO, "radius": 8.0})
	await physics_frames(5)
	# The actor draws in front of him: on his ladder it comes to a fight.
	actor.draw_gun()
	Events.deed.emit(actor, &"draw", null, actor.global_position)
	ob.relations.provoke(actor)
	await physics_frames(60 * 3)
	check(ob.target != actor, "he doesn't take on the held actor (target %s, mood %s)" % [ob.target, ob.mood])
	# The actor turns his gun on him: then he may answer.
	Events.deed.emit(actor, &"aim_at", guard, actor.global_position)
	ob._start_fight(actor)
	check(ob.target == actor, "turned on, he answers (%s)" % ob.target)
	check(hold.on, "still held: nothing of yours")


func test_a_shot_lets_everyone_go_within_the_frame() -> void:
	var p := _player(Vector3(0, 0, 6))
	var gunman := _man("gunman", Vector3(-1.0, 0, 0), true)  # brought in brainless, as acts do
	var talker := _man("talker", Vector3(1.0, 0, 0))
	var cb := CivilianBrain.new()
	var held_civ := _man("held_civ", Vector3(0, 0, -2), false, cb)
	var ob := OutlawBrain.new()
	var watcher := _man("watcher", Vector3(5, 0, -1), true, ob)
	var hold := SceneHold.claim(world, {"cast": [gunman, talker, held_civ], "centre": Vector3.ZERO, "radius": 6.0})
	var why := [&""]
	hold.broken.connect(func(w: StringName) -> void: why[0] = w)
	await physics_frames(5)
	check(cb.held, "the held townsman's brain is held")
	var f0 := Engine.get_physics_frames()
	Events.noise.emit(p.global_position + Vector3.UP * 1.4, 1.0, &"gunshot", p)
	Events.shot_fired.emit(p.global_position + Vector3.UP * 1.4, Vector3.FORWARD, p)
	check(not hold.on and why[0] == &"shot" and hold.ended_frame == f0, "the shot let it go on its frame (%s)" % hold.report())
	check(SceneHold.live.is_empty(), "no hold left live")
	check(not cb.held, "his brain's his own")
	check(gunman.get_node_or_null(^"Brain") is OutlawBrain and talker.get_node_or_null(^"Brain") is CivilianBrain,
			"the brainless got brains: the armed one an outlaw's, the other a townsman's")
	var gb := gunman.get_node(^"Brain") as OutlawBrain
	var fought := await wait_until(func() -> bool: return gb.mood == OutlawBrain.Mood.FIGHTING and gb.target == p, 60 * 3)
	check(fought, "the gunman fights you by his own brain (mood %s, target %s)" % [gb.mood, gb.target])
	var tb := talker.get_node(^"Brain") as CivilianBrain
	var reacted := await wait_until(func() -> bool: return tb.reaction.stage != Reaction.Stage.NONE or tb.mood != CivilianBrain.Mood.CALM, 60 * 3)
	check(reacted, "the talker reacts by his own (stage %s, mood %s)" % [tb.reaction.stage, tb.mood])
	check(not SceneHold.spares(ob.body, gunman), "the watcher may take the gunman on now")


func test_your_gun_drawn_breaks_it_and_a_mark_breaks_it() -> void:
	var p := _player(Vector3(0, 0, 9))
	var actor := _man("a", Vector3.ZERO)
	var hold := SceneHold.claim(world, {"cast": [actor], "centre": Vector3.ZERO, "radius": 5.0})
	await physics_frames(2)
	Events.deed.emit(p, &"draw", null, p.global_position)
	check(not hold.on and hold.why == &"draw", "a drawn gun (%s)" % hold.report())
	var mark := Vector3(2, 0, 0)
	var hold2 := SceneHold.claim(world, {"cast": [actor], "marks": [mark], "centre": Vector3.ZERO, "radius": 5.0})
	await physics_frames(2)
	check(hold2.on, "you off its marks: it holds")
	p.global_position = mark + Vector3(0.1, 0, 0)
	await physics_frames(2)
	check(not hold2.on and hold2.why == &"mark", "you on a mark (%s)" % hold2.report())
	# The scene's own shots, and yours far off, don't.
	var hold3 := SceneHold.claim(world, {"cast": [actor], "centre": Vector3.ZERO, "radius": 5.0, "breaks": [&"shot"]})
	Events.shot_fired.emit(actor.global_position, Vector3.FORWARD, actor)
	p.global_position = Vector3(0, 0, 40)
	Events.shot_fired.emit(p.global_position, Vector3.BACK, p)  # (away: at the actor it would be)
	check(hold3.on, "an actor's shot, or yours 40 m off and away from it, isn't a break (%s)" % hold3.report())
