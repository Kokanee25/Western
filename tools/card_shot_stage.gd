extends Node
## The stage of tools/card_shot.gd (#1294): loaded once the autoloads are up.

var out := "build/cards_shot"


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _shot(name_: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("%s/%s.png" % [out, name_])
	print("shot ", name_)


func _run() -> void:
	var world := Node3D.new()
	world.name = "Main"
	get_tree().root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.06, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.45, 0.35)
	e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.8, 0.55)
	lamp.light_energy = 2.2
	lamp.omni_range = 4.0
	lamp.shadow_enabled = true
	world.add_child(lamp)
	lamp.position = Vector3(0.3, 1.9, -0.2)
	var floor_ := StaticBody3D.new()
	floor_.collision_layer = 1
	var fs := CollisionShape3D.new()
	var fb := BoxShape3D.new()
	fb.size = Vector3(12, 0.1, 12)
	fs.shape = fb
	floor_.add_child(fs)
	var fm := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = fb.size
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.32, 0.22, 0.14)
	fbm.material = fmat
	fm.mesh = fbm
	floor_.add_child(fm)
	world.add_child(floor_)
	floor_.position = Vector3(0, -0.05, 0)
	# The table and its chairs, north, east, south, west, each turned to face it.
	var table = PropKit.spawn(&"card_table")
	world.add_child(table)
	var chairs := []
	for d: Vector3 in [Vector3(0, 0, -0.68), Vector3(0.68, 0, 0), Vector3(0, 0, 0.68), Vector3(-0.68, 0, 0)]:
		var c = PropKit.spawn(&"chair")
		world.add_child(c)
		c.position = d
		await _frames(1)
		var f: Vector3 = Seating.faces(c) - Seating.spot(c)
		f.y = 0.0
		var want := -d
		c.rotation.y = atan2(f.x, f.z) - atan2(want.x, want.z)
		c.rotation.y = -c.rotation.y
		chairs.append(c)
	await _frames(10)
	# Two of the roster's men in the east and west chairs (the north left free).
	var folk_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/valley_folk.json"))
	var maker = ValleyFolk.new()
	maker.data = folk_data
	var men := []
	for pair in [[&"earl", 1], [&"drifter", 3]]:
		var man = maker._make(maker._person(pair[0]))
		world.add_child(man)
		var ch = chairs[pair[1]]
		man.global_position = Seating.spot(ch) - ch.global_basis.z * 0.4
		men.append(man)
		for i in 300:
			if Seating.sit_step(man, ch, 1.0 / 60.0):
				break
			await get_tree().physics_frame
	maker.free()
	# You, sat at the south chair.
	var p = load("res://scenes/player.tscn").instantiate()
	world.add_child(p)
	var south = chairs[2]
	p.global_position = Seating.spot(south) - south.global_basis.z * 0.5
	var to: Vector3 = -Vector3(0, 0, 0.68)
	p.rotation.y = atan2(-to.x, -to.z)
	await _frames(5)
	p.seat.use()
	await _frames(30)
	print("sat: ", p.seat.seated())
	var g = CardGame.new()
	g.table = table
	g.chairs.assign(chairs)
	g.rng.seed = 1294
	world.add_child(g)
	g.speed = 3.0
	# Dealt, your turn: the table from your chair, looking down at it.
	for i in 60 * 60:
		await get_tree().physics_frame
		if g.you_in() and g.your_turn():
			break
	print(g.report())
	g.speed = 0.0
	p.add_look(Vector2(0.0, -26.0 - p.get_pitch_degrees()))
	await _frames(20)
	await _shot("1_table")
	p.cards.force_lift = true
	await _frames(30)
	await _shot("2_hand")
	p.cards.force_lift = false
	g.speed = 3.0
	g.you_call()
	for i in 60 * 60:
		await get_tree().physics_frame
		if g.your_turn():
			g.you_call()
		if g.you_drawing or not g.you_in():
			break
	if g.you_drawing:
		g.speed = 0.0
		var cs: Array = g.your_cards()
		var order := [0, 1, 2, 3, 4]
		order.sort_custom(func(a: int, b: int) -> bool: return Poker.rank(cs[a]) < Poker.rank(cs[b]))
		g.you_mark(order[0])
		g.you_mark(order[1])
		p.cards.pick = order[1]
		await _frames(30)
		await _shot("3_draw")
		g.you_draw()
		g.speed = 3.0
	var start: int = g.hands
	for i in 60 * 90:
		await get_tree().physics_frame
		if g.your_turn():
			g.you_call()
		if g.hands > start:
			break
	g.speed = 0.0
	p.add_look(Vector2(0.0, -34.0 - p.get_pitch_degrees()))
	await _frames(20)
	await _shot("4_showdown")
	print(g.report())
	get_tree().quit()
