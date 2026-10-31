extends TestCase
## The prop kit's props that shatter (GlassProp: the whiskey bottle, the oil lamp): they stand
## where they're put; a ball goes through and breaks them; a fall breaks a lamp's chimney but not
## always a thick bottle; their table going over takes them; a blast close by breaks them, further
## off throws them; what they held is let go (a lit lamp's oil burns).

var world: Node3D
var floor_s: Structure
var spilled: Array = []


func before_each() -> void:
	FireSystem.in_play = true  # a lit lamp smashed starts a fire here (off in the game, #458)
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
	for x in [-1.0, 1.0]:
		floor_s.add_member("joist%d" % int(x), &"joist", &"framing", Vector3(0.05, 0.25, 3.0), Vector3(x, 0.125, 0))
	for i in 12:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(2.4, 0.05, 0.25), Vector3(0, 0.275, -1.375 + 0.25 * i))
	floor_s.infer_supports()
	spilled.clear()
	Events.liquid_spilled.connect(_on_spilled)


func after_each() -> void:
	FireSystem.in_play = "--fire" in OS.get_cmdline_user_args()
	Events.liquid_spilled.disconnect(_on_spilled)
	world.queue_free()
	await physics_frames(2)


func _on_spilled(at: Vector3, liquid: StringName, litres: float, _source: Node) -> void:
	spilled.append([at, liquid, litres])


func _glass(id: StringName, at: Vector3) -> GlassProp:
	var g := PropKit.make(id) as GlassProp
	g.position = at
	world.add_child(g)
	return g


func _table(at := Vector3(0, 0.3, 0)) -> KitProp:
	var t := PropKit.spawn(&"card_table")
	t.position = at
	world.add_child(t)
	return t


func _revolver(target: Vector3, from_side := Vector3(-5, 0, 0)) -> Ballistics.Bullet:
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var from := target + from_side
	return ballistics.fire(from, (target - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)


func test_a_bottle_stands_on_the_table_and_a_ball_goes_through_it() -> void:
	_table()
	var bottle := _glass(&"whiskey_bottle", Vector3(-0.2, 0.3 + 0.761, 0.1))
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	check(not bottle.loose and not bottle.broken, "it stands where it's put")
	var b := _revolver(bottle.global_position + Vector3.UP * 0.12)
	await physics_frames(3)
	check(bottle.broken, "a .45 ball breaks it")
	check(b.hits.size() >= 1 and b.hits[0].penetrated, "and goes on through")
	check(get_tree().get_nodes_in_group(&"glass_shards").size() >= 10, "shards of it fly")
	check(spilled.size() == 1 and spilled[0][1] == &"whiskey" and float(spilled[0][2]) > 0.5, "its whiskey is let go (%s)" % [spilled])


func test_a_lit_lamp_shot_throws_its_burning_oil_and_an_unlit_one_lets_its_oil_go() -> void:
	var fire := FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)
	_table()
	var lamp := _glass(&"oil_lamp", Vector3(0.12, 0.3 + 0.761, -0.1))
	var light := OilLamp.new()
	light.name = "Light"
	light.show_mesh = false
	lamp.add_child(light)
	light.position.y = 0.04
	light.set_lit(true)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	var b := _revolver(lamp.global_position + Vector3.UP * 0.25)
	await physics_frames(3)
	check(lamp.broken and light.broken, "the ball breaks the chimney and the lamp's out (glass %s, light %s, hits %s)" % [lamp.broken, light.broken, b.hits.map(func(h: Dictionary) -> String: return str(h.collider))])
	check(fire.spills.size() == 1, "its burning oil splashes down")
	var dark := _glass(&"oil_lamp", Vector3(-0.3, 0.3 + 0.761, 0.2))
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	_revolver(dark.global_position + Vector3.UP * 0.25)
	await physics_frames(3)
	check(dark.broken and spilled.any(func(e: Array) -> bool: return e[1] == &"lamp_oil"), "an unlit lamp lets its oil go")


func test_a_stick_smashes_a_lit_lamp_and_its_oil_burns_an_unlit_one_lights_nothing() -> void:
	# The only way a blast starts a fire (Sean, 2026-10-28): the lamp it breaks, if it was lit.
	var fire := FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)
	var lamps: Array[OilLamp] = []
	for x in [-0.8, 0.8]:
		var g := _glass(&"oil_lamp", Vector3(x, 0.3, 0.0))
		var light := OilLamp.new()
		light.name = "Light"
		light.show_mesh = false
		g.add_child(light)
		light.position.y = 0.04
		light.set_lit(x < 0.0)
		lamps.append(light)
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	Blast.detonate(world, Vector3(0.0, 0.35, 0.0), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(lamps[0].broken and lamps[1].broken, "80 cm from a stick both lamps smash (lit %s, dark %s)" % [lamps[0].broken, lamps[1].broken])
	check_eq(fire.spills.size(), 1, "the lit one's oil burns where it lands, the dark one's doesn't")
	fire.step(Blast.t().ignite_delay.y + 0.1)
	check_eq(fire.spills.size(), 1, "the blast lit nothing else")


func test_off_the_table_a_lamp_breaks_and_a_bottle_mostly_doesnt() -> void:
	var lamp := _glass(&"oil_lamp", Vector3(0.0, 0.3 + 0.8, 0.0))
	var bottle := _glass(&"whiskey_bottle", Vector3(0.4, 0.3 + 0.8, 0.0))
	var high := _glass(&"whiskey_bottle", Vector3(-0.4, 0.3 + 1.8, 0.0))
	await wait_until(func() -> bool: return lamp.broken and high.broken, 120)
	check(lamp.broken, "a lamp falling 0.8 m breaks its chimney (%.1f m/s against 1.5)" % sqrt(2.0 * 9.81 * 0.8))
	check(not bottle.broken, "a thick bottle falling 0.8 m onto boards doesn't (%.1f m/s against 4.5)" % sqrt(2.0 * 9.81 * 0.8))
	check(high.broken, "one falling 1.8 m does (%.1f m/s)" % sqrt(2.0 * 9.81 * 1.8))


func test_the_table_going_over_takes_them_with_it() -> void:
	var table := _table()
	var bottle := _glass(&"whiskey_bottle", Vector3(-0.2, 0.3 + 0.761, 0.1))
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	table.go_loose(Vector3(2.0, 0.5, 0))
	await physics_frames(1)
	check(bottle.loose, "the moment the table goes, the bottle's loose with it")


func test_a_stick_close_by_breaks_a_bottle_and_further_off_throws_it() -> void:
	var near := _glass(&"whiskey_bottle", Vector3(0.0, 0.3, 0.0))
	var far := _glass(&"whiskey_bottle", Vector3(0.0, 0.3, 1.2))
	await physics_frames(GlassProp.SETTLE_FRAMES + 4)
	Events.exploded.emit(Vector3(-0.4, 0.32, 0.0), Blast.t().tnt_per_stick)
	await physics_frames(2)
	check(near.broken, "40 cm from a stick it breaks where it stands")
	check(far.loose or far.broken, "1.3 m off it's thrown")
