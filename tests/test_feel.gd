extends TestCase
## Feel ranges (docs/briefs/automated-checks.md, item 4): numbers that make the game feel right,
## measured here and held to the ranges agreed with Sean in config/feel_ranges.json (tests/feel.gd).
## The others are measured where their tests already were (body hits to stop a man, the shotgun at
## 20 m, the store's roof falling in).

const Feel := preload("res://tests/feel.gd")

var world: Node3D


func _test_world() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	world.add_child(ground)
	world.add_child(Ballistics.new())
	await physics_frames(2)


func _free_world() -> void:
	if world:
		world.queue_free()
		world = null
	await physics_frames(2)


## An outlaw facing a standing, unarmed man `d` metres off, set on fighting him. Shots and hits
## over `trials` men (a fresh one when the last is down, or after `per_man` shots).
func _hit_rate(d: float, trials: int, per_man: int) -> float:
	await _test_world()
	var shots := [0]
	var hits := [0]
	var outlaw := HumanBody.new()
	outlaw.person_id = &"shooter"
	outlaw.rng_seed = 61
	var brain := OutlawBrain.new()
	brain.name = "Brain"
	brain.nerve = 99.0
	brain.flee_chance = 0.0
	outlaw.add_child(brain)
	world.add_child(outlaw)
	outlaw.global_position = Vector3(0, 0, 0)
	var on_shot := func(_o: Vector3, _dir: Vector3, who: Node) -> void:
		if who == outlaw:
			shots[0] += 1
	Events.shot_fired.connect(on_shot)
	for trial in trials:
		var target := HumanBody.new()
		target.person_id = StringName("target%d" % trial)
		target.has_gun = false
		target.rng_seed = 900 + trial
		world.add_child(target)
		target.global_position = Vector3(0, 0, -d)
		target.rotation.y = PI
		outlaw.look_at(target.global_position, Vector3.UP, true)
		var on_hit := func(info: Dictionary) -> void:
			if info.get("person") == target and info.get("kind") != &"blow":
				hits[0] += 1
		Events.body_hit.connect(on_hit)
		await physics_frames(3)
		brain.relations.provoke(target)
		var before: int = shots[0]
		await wait_until(func() -> bool:
			return shots[0] - before >= per_man or target.limp or not target.physiology.alive, 60 * 40)
		await physics_frames(30)  # the last ball lands
		Events.body_hit.disconnect(on_hit)
		brain.relations.stand_down(target)
		target.queue_free()
		await physics_frames(2)
	Events.shot_fired.disconnect(on_shot)
	await _free_world()
	print("    at %.0f m: %d hits from %d shots" % [d, hits[0], shots[0]])
	return float(hits[0]) / maxf(float(shots[0]), 1.0)


func test_outlaw_hit_rates() -> void:
	Feel.within(self, "outlaw_hit_rate_5m", await _hit_rate(5.0, 4, 4))
	Feel.within(self, "outlaw_hit_rate_15m", await _hit_rate(15.0, 4, 5))
	Feel.within(self, "outlaw_hit_rate_30m", await _hit_rate(30.0, 4, 6))


# -- On the street: the duel and backing down ------------------------------------------------------

var street: Node3D
var town: TownLife
var player: Player


func _street() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	town = street.get_node(^"TownLife")
	town.gang_arrives = 99999.0
	add_child(street)
	await physics_frames(5)
	var range_man := (street.get_node(^"OutlawSpawn") as OutlawSpawner).outlaw
	if range_man:
		range_man.queue_free()
	player = street.get_node(^"Player")
	await physics_frames(3)


func _free_street() -> void:
	street.queue_free()
	await physics_frames(3)


func _man(id: StringName) -> HumanBody:
	for g in town.gang:
		if is_instance_valid(g) and g.person_id == id:
			return g
	return null


func _face(point: Vector3) -> void:
	var to := point - player.camera.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	player.head.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())


func test_duel_standoff() -> void:
	# Lyle faces you in the street for a duel; you stand there, hand off your gun. How long before
	# he goes for his.
	await _street()
	town.bring_gang([&"lyle"])
	var lyle := _man(&"lyle")
	var b := lyle.get_node(^"Brain") as OutlawBrain
	b.nerve = 99.0
	lyle.global_position = Vector3(6.0, 0.0, -9.0)
	player.global_position = Vector3(-6.0, 0.0, -9.0)
	player.rotation = Vector3(0, deg_to_rad(-90.0), 0)
	await physics_frames(5)
	b.agenda = [{"do": &"duel", "who": player}]
	b._step_started = false
	var start := Time.get_ticks_msec()
	var frames := [0]
	var drew := await wait_until(func() -> bool:
		frames[0] += 1
		return not lyle.gun_holstered, 60 * 15)
	check(drew, "he draws in the end")
	Feel.within(self, "duel_draw_seconds", frames[0] / 60.0)
	await _free_street()


func test_back_down_rate() -> void:
	# Each of the gang on his own, standing in the street; you walk up to 6 m with your gun out and
	# hold it on him for 25 s.
	var backed := 0
	var who := [&"brody", &"lyle", &"kid"]
	var outcome := []
	for id: StringName in who:
		await _street()
		town.bring_gang([id])
		var man := _man(id)
		var b := man.get_node(^"Brain") as OutlawBrain
		b.agenda = [{"do": &"wait", "seconds": 999.0}]
		b._step_started = false
		man.global_position = Vector3(0.0, 0.0, -9.0)
		player.global_position = Vector3(6.0, 0.0, -9.0)
		await physics_frames(10)
		var gun := player.revolver()
		gun.needs_captured_mouse = false
		gun.take_out()
		var cowed := await wait_until(func() -> bool:
			_face((man.parts[&"chest"] as Node3D).global_position)
			return b.relations.entry(player).cowed or b.mood == OutlawBrain.Mood.FIGHTING, 60 * 25)
		var backed_down: bool = cowed and b.relations.entry(player).cowed
		outcome.append("%s %s" % [id, "backed down" if backed_down else ("drew" if b.mood == OutlawBrain.Mood.FIGHTING else "held")])
		if backed_down:
			backed += 1
		await _free_street()
	print("    %s" % ", ".join(outcome))
	Feel.within(self, "back_down_share", float(backed) / who.size())
