extends TestCase
## What a kit prop holds (PropContents; docs/briefs/prop-lab.md): a full barrel weighs its
## contents, so a kick hardly moves it; a ball through a stave below the level leaks at the rate
## Torricelli's law gives for the hole and the head over it, and the jet lands out from the hole; a
## hole above the level doesn't leak; a stave gone gushes; blown apart, the lot goes at once; lamp
## oil running into flames catches.

var world: Node3D
var floor_s: Structure
var spilled: Array = []


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
	floor_s = Structure.new()
	floor_s.structure_id = &"floor"
	world.add_child(floor_s)
	for x in [-1.8, -0.6, 0.6, 1.8]:
		floor_s.add_member("joist%d" % int(x * 10), &"joist", &"framing", Vector3(0.05, 0.25, 4.0), Vector3(x, 0.125, 0))
	for i in 16:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(4.0, 0.05, 0.25), Vector3(0, 0.275, -1.875 + 0.25 * i))
	floor_s.infer_supports()
	spilled.clear()
	Events.liquid_spilled.connect(_on_spilled)


func after_each() -> void:
	Events.liquid_spilled.disconnect(_on_spilled)
	world.queue_free()
	await physics_frames(2)


func _on_spilled(at: Vector3, liquid: StringName, litres: float, _source: Node) -> void:
	spilled.append({"at": at, "liquid": liquid, "litres": litres})


func _place(id: StringName, at := Vector3(0, 0.3, 0)) -> KitProp:
	var p := PropKit.spawn(id)
	p.position = at
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	return p


func _m(p: KitProp, id: String) -> StructureMember:
	return p.get_member(StringName("%s/%s" % [p.structure_id, id]))


## A ball's hole straight through `stave` at `height` over the barrel's foot (world points in,
## out), as Ballistics leaves one.
func _hole(p: KitProp, stave: StructureMember, height: float, radius := 0.0057) -> void:
	var c := stave.global_position
	var out := Vector3(c.x - p.global_position.x, 0.0, c.z - p.global_position.z).normalized()
	var at := Vector3(c.x, p.global_position.y + height, c.z)
	stave.add_hole(at + out * 0.02, at - out * 0.02, radius)


func _spilled_litres() -> float:
	var l := 0.0
	for s: Dictionary in spilled:
		l += float(s.litres)
	return l


func test_a_full_barrel_holds_its_shape_full_and_weighs_it() -> void:
	var barrel := await _place(&"whiskey_barrel")
	var c := barrel.contents
	check(c != null, "the whiskey barrel has contents")
	check(c.capacity > 150.0 and c.capacity < 190.0, "a forty-odd gallon cask holds %.0f l" % c.capacity)
	check_near(c.litres, c.capacity, 0.01, "it's full")
	check_near(c.level(), 0.85, 0.001, "to the top head")
	check_near(c.level_of(c.capacity * 0.5), 0.45, 0.01, "half of it stands half way up (the bulge is in the middle)")
	check(barrel.mass() > 190.0, "full, it weighs ~200 kg (%.0f)" % barrel.mass())
	check(barrel.settle().is_empty() and not barrel.loose, "and stands")
	var empty := await _place(&"barrel", Vector3(1.2, 0.3, 0))
	check(empty.contents == null, "the plain barrel is empty")
	check(empty.mass() < 50.0, "an empty cask is ~40 kg (%.0f)" % empty.mass())


func test_a_kick_barely_moves_a_full_barrel() -> void:
	var barrel := await _place(&"water_barrel")
	var stave := _m(barrel, "stave10")
	check_eq(barrel.take_blow(stave, stave.global_position, Vector3(48.0, 0, 0)), &"held", "a boot doesn't shift 200 kg of water")
	check(not barrel.loose, "it stands where it was")


func test_a_ball_below_the_level_leaks_at_torricellis_rate() -> void:
	var barrel := await _place(&"whiskey_barrel")
	var c := barrel.contents
	var stave := _m(barrel, "stave10")
	_hole(barrel, stave, 0.3)
	await physics_frames(2)
	check_eq(c.leaks.size(), 1, "one hole, one leak")
	var before := c.litres
	await physics_frames(120)
	var per_s := (before - c.litres) / 2.0
	# By hand: Cd x area x sqrt(2 g h), h the level over the hole.
	var r := 0.0057 * StructureMember.voxel_damage_tuning().channel_scale
	var h := c.level() - 0.3
	var want := 0.61 * PI * r * r * sqrt(2.0 * 9.81 * h) * 1000.0
	check_near(per_s, want, want * 0.05, "%.3f l/s out of a .45 hole under %.2f m of whiskey (%.3f by hand)" % [per_s, h, want])
	await physics_frames(40)
	check(not spilled.is_empty() and spilled.all(func(s: Dictionary) -> bool: return s.liquid == &"whiskey"), "it's on the floor as whiskey")
	var landed: Vector3 = spilled[-1].at
	var hole_at := Vector3(stave.global_position.x, 0.0, stave.global_position.z)
	var out_by := Vector2(landed.x, landed.z).distance_to(Vector2(barrel.global_position.x, barrel.global_position.z)) \
			- Vector2(hole_at.x, hole_at.z).distance_to(Vector2(barrel.global_position.x, barrel.global_position.z))
	check(out_by > 0.25, "the jet lands out from the hole (%.2f m)" % out_by)
	check_near(landed.y, 0.3, 0.02, "on the boards")
	check_near(c.spilled + c.litres, c.capacity, 0.01, "what's run out is what's left it")
	check_near(_spilled_litres(), c.spilled, 0.1, "and it's on the bus (but the last half second's)")


func test_the_level_falls_and_the_jet_slows() -> void:
	var barrel := await _place(&"water_barrel")
	var c := barrel.contents
	_hole(barrel, _m(barrel, "stave3"), 0.1, 0.02)  # a big ragged hole, low down
	await physics_frames(2)
	var first := c.flow(c.leaks[0])
	var v0 := c.jet_speed(c.leaks[0])
	await physics_frames(600)
	check(c.flow(c.leaks[0]) < first * 0.9, "the flow falls with the level (%.2f -> %.2f l/s)" % [first, c.flow(c.leaks[0])])
	check(c.jet_speed(c.leaks[0]) < v0, "and the jet with it")
	check(c.level() < 0.85, "the level's down to %.2f" % c.level())


func test_a_hole_above_the_level_doesnt_leak() -> void:
	var barrel := await _place(&"water_barrel")
	var c := barrel.contents
	c.litres = c.capacity * 0.4
	_hole(barrel, _m(barrel, "stave5"), 0.7)
	await physics_frames(60)
	check_eq(c.leaks.size(), 1, "the hole's noted")
	check_near(c.litres, c.capacity * 0.4, 0.001, "but nothing runs out of it over the level")
	check(spilled.is_empty(), "and nothing's on the floor")


func test_a_ball_that_stops_in_the_wood_makes_no_leak() -> void:
	var barrel := await _place(&"whiskey_barrel")
	var stave := _m(barrel, "stave10")
	var at := stave.global_position + Vector3(0, -0.1, 0)
	stave.add_hole(at, null, 0.0057)
	await physics_frames(10)
	check(barrel.contents.leaks.is_empty(), "a blind hole lets nothing out")


func test_a_real_ball_through_a_full_barrel_leaks_from_the_near_stave() -> void:
	var barrel := await _place(&"whiskey_barrel")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var stave := _m(barrel, "stave10")
	var aim := stave.global_position + Vector3(0, -0.15, 0)
	var from := aim + Vector3(-5, 0.3, 0)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(from, (aim - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	await physics_frames(30)
	check(barrel.contents.leaks.size() >= 1, "the ball's hole leaks (%d)" % barrel.contents.leaks.size())
	check(barrel.contents.litres < barrel.contents.capacity, "whiskey's running out")
	check(not barrel.loose, "and the barrel stands")


func test_a_stave_gone_gushes_and_empties_it_fast() -> void:
	var barrel := await _place(&"water_barrel")
	var c := barrel.contents
	barrel.break_member(_m(barrel, "stave7"))
	await physics_frames(3)
	if barrel.loose:
		check(c.released, "gone over with a side out, it's let it all go")
		return
	check(c.leaks.any(func(l: Dictionary) -> bool: return l.has("slot")), "a slot down its side")
	await physics_frames(600)
	check(c.litres < c.capacity * 0.15, "most of it's out in ten seconds (%.0f l left)" % c.litres)


func test_a_stick_at_its_foot_blows_it_apart_and_the_lot_goes() -> void:
	var barrel := await _place(&"whiskey_barrel")
	var cap := barrel.contents.capacity
	# A foot off its staves (a metre off, it's shoved whole: a full cask is too heavy to throw far
	# enough to burst landing, as an empty one does).
	Blast.detonate(world, barrel.global_position + Vector3(-0.6, 0.02, 0), Blast.t().tnt_per_stick)
	await physics_frames(20)
	check(barrel.contents.released or barrel.contents.litres < cap * 0.5, "blown open, it lets its whiskey go")
	await physics_frames(400)
	check(_spilled_litres() > cap * 0.9, "the lot's on the floor (%.0f of %.0f l)" % [_spilled_litres(), cap])


func test_a_blast_throws_a_full_barrel_less_than_an_empty_one() -> void:
	var empty := await _place(&"barrel", Vector3(0, 0.3, -1.0))
	var full := await _place(&"water_barrel", Vector3(0, 0.3, 1.0))
	Events.exploded.emit(Vector3(-1.5, 0.4, 0), Blast.t().tnt_per_stick)
	await physics_frames(3)
	check(empty.loose, "the empty one's thrown")
	var speed := func(p: KitProp) -> float:
		var v := 0.0
		for rb in p.rubble:
			if is_instance_valid(rb):
				v = maxf(v, rb.linear_velocity.length())
		return v
	check(not full.loose or speed.call(full) < speed.call(empty) * 0.5,
			"the full one's not, or slower (%.2f vs %.2f m/s)" % [speed.call(full), speed.call(empty)])
	if full.loose:
		check(full.contents.litres > full.contents.capacity * 0.9, "thrown whole, it keeps its water")


func test_lamp_oil_running_into_flames_catches() -> void:
	var barrel := await _place(&"oil_barrel")
	var fire := FireSystem.new()
	world.add_child(fire)
	var stave := _m(barrel, "stave0")
	_hole(barrel, stave, 0.2, 0.01)
	await physics_frames(2)
	var land := barrel.contents.landing(barrel.contents.leaks[0])
	# The boards where it lands are alight.
	var near: StructureMember = null
	for m in floor_s.get_members():
		if m.kind == &"floor_board" and (near == null or absf(m.global_position.z - land.z) < absf(near.global_position.z - land.z)):
			near = m
	fire.ignite(near)
	await physics_frames(70)
	check(fire.spills.size() >= 1, "the oil catches where it runs into the fire")
	check(spilled.any(func(s: Dictionary) -> bool: return s.liquid == &"lamp_oil"), "and it's on the floor as lamp oil")


func test_blown_open_its_staves_go_no_faster_than_a_blast_throws_anything() -> void:
	# Its throw is reckoned with the liquid in; the liquid's gone as it goes loose, and what's left
	# mustn't take the full barrel's push (it went 150 m/s, off the map: test_chaos).
	var fastest := 0.0
	for at: float in [0.5, 0.6, 0.8, 1.0]:
		var barrel := await _place(&"water_barrel", Vector3(0, 0.3, 0))
		Blast.detonate(world, barrel.global_position + Vector3(-at, 0.02, 0), Blast.t().tnt_per_stick)
		for i in 30:
			await physics_frames(1)
			for rb in barrel.rubble:
				if is_instance_valid(rb):
					fastest = maxf(fastest, rb.linear_velocity.length())
		barrel.queue_free()
		await physics_frames(2)
	check(fastest <= Blast.t().max_throw * 1.05, "no stave faster than %.0f m/s (%.1f)" % [Blast.t().max_throw, fastest])

