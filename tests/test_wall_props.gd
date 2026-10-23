extends TestCase
## The prop kit's wall props (docs/briefs/prop-lab.md): the deer head and the framed painting hung
## on nails (KitProp "hangs"), the sconce a glass prop hung on one (GlassProp). They hold while a
## nail's in the wall; the board a nail's in shot out or burnt, they fall; hung on air, they fall;
## the sconce smashes where it lands. A blast close by tears them off.

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
	# A wall facing +Z, its face at z = 0: studs, and boards across them 15 cm wide.
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


func _hang(id: StringName, at: Vector3) -> Node3D:
	var p := PropKit.make(id)
	p.position = at
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 3)
	return p


func test_the_head_and_the_painting_hang_on_the_wall_as_big_as_the_drawn_ones() -> void:
	for id: StringName in [&"deer_head", &"framed_painting"]:
		var p := await _hang(id, Vector3(0, 2.0, 0)) as KitProp
		check(p.hung(), "%s hangs" % id)
		check(p.member_count() >= 4, "%s is built of members (%d)" % [id, p.member_count()])
		check(p.settle().is_empty(), "%s: nothing breaks or falls" % id)
		check(not p.loose, "%s holds on its nails" % id)
		check(p.batch_count() <= 6, "%s draws in a few batches (%d)" % [id, p.batch_count()])
		var box := AABB()
		for m in p.get_members():
			box = m.structure_aabb() if box.size == Vector3.ZERO else box.merge(m.structure_aabb())
		var drawn := PropLibrary.size_of(id)
		check(box.size.x <= drawn.x + 0.02 and box.size.y <= drawn.y + 0.02, "%s no bigger than the drawn one (%s)" % [id, box.size])
		check_near(box.position.z, 0.0, 0.03, "%s's back against the wall" % id)
		p.queue_free()
		await physics_frames(1)


func test_hung_on_air_it_falls() -> void:
	var p := await _hang(&"framed_painting", Vector3(0, 2.0, 1.0)) as KitProp
	check(p.loose, "nothing behind its nail: it falls")


func test_the_board_its_nails_are_in_shot_out_it_falls() -> void:
	var head := await _hang(&"deer_head", Vector3(0, 2.0, 0)) as KitProp
	var held := head._feet.values().filter(func(u: Array) -> bool: return not u.is_empty()).size()
	check(held > 0, "its nails are in the wall")
	for m: StructureMember in head._feet:
		for e: Array in head._feet[m]:
			if e[0] != null:
				wall.break_member(e[0])
	await physics_frames(int(KitProp.CHECK_EVERY * 60.0) + 4)
	check(head.loose, "what its nails were in gone, it falls")


func test_the_painting_burns_and_its_canvas_goes_first() -> void:
	var fire := FireSystem.new()
	world.add_child(fire)
	var p := await _hang(&"framed_painting", Vector3(0, 1.5, 0)) as KitProp
	var canvas := p.get_member(StringName("%s/canvas" % p.structure_id))
	fire.ignite(canvas)
	await wait_until(func() -> bool: return canvas.consumed or canvas.broken, 60 * 240)
	check(canvas.consumed or canvas.broken, "the canvas burns away")


func test_a_stick_close_by_tears_the_head_off_its_nails_and_one_far_off_leaves_it() -> void:
	var near := await _hang(&"deer_head", Vector3(-0.8, 2.0, 0)) as KitProp
	Events.exploded.emit(near.global_position + Vector3(0, -1.0, 1.5), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(near.loose, "a stick 2 m off tears it off the wall")
	var far := await _hang(&"framed_painting", Vector3(0.8, 2.0, 0)) as KitProp
	Events.exploded.emit(far.global_position + Vector3(0, -1.5, 15.0), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(not far.loose, "15 m off it stays")


func test_the_sconce_hangs_and_when_its_board_goes_it_falls_and_smashes() -> void:
	var s := await _hang(&"wall_sconce", Vector3(0, 1.9, 0)) as GlassProp
	var light := OilLamp.new()
	light.name = "Light"
	light.show_mesh = false
	s.add_child(light)
	light.position = Vector3(0, 0.08, 0.12)
	await physics_frames(2)
	check(not s.loose and not s.broken, "it hangs on its nail")
	check(not s._under.is_empty(), "its nail is in the wall")
	for e: Array in s._under:
		if e[0] != null:
			wall.break_member(e[0])
	await wait_until(func() -> bool: return s.broken, 120)
	check(s.loose, "its board gone, it falls")
	check(s.broken, "and smashes on the floor below")
	check(light.broken, "its lamp with it")
