extends TestCase
## Dynamite: the blast's pressure and impulse by distance (Kinney-Graham), what it breaks (plank
## siding near it, not heavy framing; panes much further out), splinters flown as projectiles,
## fire in dry wood, people (ears, lungs, thrown down, limbs at close range, burns), the fuse,
## and the stick in the player's hand.

var world: Node3D
var ballistics: Ballistics
var booms: Array = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	booms.clear()
	Events.exploded.connect(_on_boom)
	await physics_frames(2)


func after_each() -> void:
	Events.exploded.disconnect(_on_boom)
	for a in [&"fire", &"cock", &"aim", &"weapon_dynamite"]:
		Input.action_release(a)
	world.queue_free()
	await physics_frames(2)


func _on_boom(at: Vector3, kg: float) -> void:
	booms.append([at, kg])


func _man(at: Vector3) -> HumanBody:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	man.global_position = at
	await physics_frames(2)
	return man


func _store() -> FalseFrontBuilding:
	var store := FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	await physics_frames(2)
	return store


## A board of the store's left side wall, and a point `off` metres outside it at knee height.
func _side_board(store: FalseFrontBuilding) -> StructureMember:
	var boards: Array[StructureMember] = []
	for m in store.get_members():
		if String(m.member_id).contains("left/siding"):
			boards.append(m)
	return boards[boards.size() / 2] if not boards.is_empty() else null


func _outside(store: FalseFrontBuilding, board: StructureMember, off: float) -> Vector3:
	var inside := store.global_transform * Vector3(0, 1.0, 0)
	var c := board.global_position
	var out := c - inside
	out.y = 0.0
	# The wall's normal is along the board's thinnest side.
	var n := Vector3.ZERO
	var t := INF
	for i in 3:
		if board.size[i] < t:
			t = board.size[i]
			n = board.global_basis[i].normalized()
	if n.dot(out) < 0.0:
		n = -n
	return Vector3(c.x, 0.6, c.z) + n * off


# --- The shock wave -------------------------------------------------------------------------------

func test_pressure_falls_with_distance() -> void:
	var kg := 0.15
	check_near(Blast.overpressure_kpa(kg, 1.0), 237.0, 25.0, "one stick at 1 m: ~240 kPa (bursts eardrums, bruises lungs)")
	check_near(Blast.overpressure_kpa(kg, 3.0), 23.0, 4.0, "at 3 m: ~23 kPa")
	check(Blast.overpressure_kpa(kg, 10.0) > 3.5, "at 10 m still enough to crack a pane")
	check(Blast.overpressure_kpa(kg, 0.3) > 2500.0, "at arm's length: thousands")
	check(Blast.overpressure_kpa(1.5, 3.0) > Blast.overpressure_kpa(0.15, 3.0) * 3.0, "ten sticks hit much harder")
	check(Blast.impulse(kg, 1.0) > Blast.impulse(kg, 3.0), "impulse falls off too")


# --- Buildings --------------------------------------------------------------------------------------

func test_a_stick_by_the_wall_blows_a_hole_in_the_siding() -> void:
	var store := await _store()
	# Against the outside of the store's side wall, knee high.
	var siding := _side_board(store)
	check(siding != null, "found a siding board")
	if siding == null:
		return
	var at := _outside(store, siding, 0.25)
	var report := Blast.detonate(world, at, 0.15)
	var broken_siding := 0
	var broken_framing := 0
	for id: StringName in report.broken:
		var m := store.get_member(id)
		if m and m.kind == &"board":
			broken_siding += 1
		elif m and m.kind in [&"post", &"beam", &"sill", &"plate", &"stud", &"joist"]:
			broken_framing += 1
	print("  one stick at 25 cm from the wall: %d boards, %d framing, %d in all, %d splinters" % [broken_siding, broken_framing, report.broken.size(), report.splinters])
	check(broken_siding >= 2, "siding boards blown in (%d)" % broken_siding)
	check(broken_framing <= 2, "the heavy framing mostly stands (%d broken)" % broken_framing)
	check(report.broken.size() < store.member_count() / 4, "a hole, not the whole store (%d of %d)" % [report.broken.size(), store.member_count()])
	check(report.splinters > 0, "splinters thrown (%d)" % report.splinters)
	check_eq(booms.size(), 1, "announced")


func test_far_off_it_only_cracks_panes() -> void:
	var store := await _store()
	var glass: StructureMember = null
	for m in store.get_members():
		if m.kind == &"glass":
			glass = m
			break
	check(glass != null, "the store has a window")
	if glass == null:
		return
	var out := (glass.global_position - store.global_position)
	out.y = 0.0
	var at := glass.global_position + out.normalized() * 7.0
	at.y = 0.2
	var report := Blast.detonate(world, at, 0.15)
	var timber := 0
	for id: StringName in report.broken:
		var m := store.get_member(id)
		if m and m.kind != &"glass":
			timber += 1
	check(glass.broken, "the pane at 7 m cracked")
	check_eq(timber, 0, "no timber broken from 7 m")


func test_it_can_start_a_fire() -> void:
	var store := await _store()
	var fire := FireSystem.new()
	world.add_child(fire)
	await physics_frames(1)
	var siding := _side_board(store)
	var lit := 0
	for k in 4:
		Blast.detonate(world, _outside(store, siding, 0.3) + Vector3.UP * 0.4 * k, 0.15)
		await physics_frames(1)
	lit = fire.burning_members().size()
	check(lit >= 1, "dry wood caught (%d burning)" % lit)


# --- People -------------------------------------------------------------------------------------------

func test_a_man_a_metre_off() -> void:
	var man := await _man(Vector3.ZERO)
	var chest := (man.parts[&"chest"] as Node3D).global_position
	man.take_blast(chest + Vector3(0, 0, -1.1), 0.15)
	var p := man.physiology
	check(p.eardrums_burst.size() >= 1, "eardrums burst")
	check(man.limp, "knocked off his feet")
	check(p.severed_segments.is_empty(), "nothing torn off at a metre")
	check(" ".join(man.describe_wounds()).contains("blast"), "the doctor sees blast injuries: %s" % "; ".join(man.describe_wounds()))


func test_across_the_street_ringing_but_whole() -> void:
	var man := await _man(Vector3.ZERO)
	var chest := (man.parts[&"chest"] as Node3D).global_position
	man.take_blast(chest + Vector3(0, 0, -9.0), 0.15)
	check(man.physiology.eardrums_burst.is_empty(), "eardrums fine at 9 m")
	check(not man.limp, "still on his feet")
	check(man.physiology.alive, "alive")


func test_at_his_feet_it_takes_a_leg() -> void:
	var man := await _man(Vector3.ZERO)
	var foot := (man.parts[&"foot_r"] as Node3D).global_position
	man.take_blast(foot + Vector3(0.05, 0.0, -0.12), 0.15)
	var p := man.physiology
	check(p.severed_segments.has(&"foot_r"), "the foot's gone (%s)" % str(p.severed_segments.keys()))
	check(p.total_bleed_rate() > 3.0, "the stump bleeds hard (%.1f ml/s)" % p.total_bleed_rate())
	check(not man.has_node(^"Joint_foot_r") or (man.get_node(^"Joint_foot_r") as Node).is_queued_for_deletion() \
			or p.severed_segments.has(&"shin_r"), "the joint let go")
	check(man.is_open(&"shin_r") or man.is_open(&"thigh_r"), "the stump's open")
	check(" ".join(man.describe_wounds()).contains("torn off"), "described: %s" % "; ".join(man.describe_wounds()))


func test_a_wall_between_shields_him() -> void:
	var man := await _man(Vector3.ZERO)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.3)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 1.5, -1.0)
	world.add_child(wall)
	await physics_frames(2)
	var chest := (man.parts[&"chest"] as Node3D).global_position
	man.take_blast(chest + Vector3(0, 0, -2.0), 0.15)
	check(man.physiology.eardrums_burst.size() <= 1, "the wall took most of it")


# --- The stick -------------------------------------------------------------------------------------------

func test_the_fuse_burns_down_then_it_goes() -> void:
	var s := DynamiteStick.make(world, Vector3(0, 0.3, 0), Vector3.ZERO, 1.0)
	s.light()
	await physics_frames(30)
	check(booms.is_empty(), "not yet at half a second")
	await wait_until(func() -> bool: return not booms.is_empty(), 90)
	check_eq(booms.size(), 1, "went off when the fuse ran out")


func test_an_unlit_stick_just_lies_there() -> void:
	var s := DynamiteStick.make(world, Vector3(0, 0.3, 0), Vector3.ZERO, 0.5)
	await physics_frames(90)
	check(booms.is_empty() and is_instance_valid(s), "unlit, nothing")


func test_one_blast_sets_off_a_stick_beside_it() -> void:
	var s := DynamiteStick.make(world, Vector3(0.2, 0.1, 0), Vector3.ZERO, 5.0)
	await physics_frames(3)
	Blast.detonate(world, Vector3(0, 0.1, 0), 0.15)
	await physics_frames(3)
	check_eq(booms.size(), 2, "the other stick went with it")
	check(not is_instance_valid(s), "gone")


# --- In your hand ----------------------------------------------------------------------------------------

func _player() -> Player:
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	await physics_frames(3)
	var d := player.dynamite()
	player.select_weapon(d)
	await wait_until(func() -> bool: return d.is_ready_in_hand(), 180)
	d.needs_captured_mouse = false
	return player


func test_light_and_throw() -> void:
	var player := await _player()
	var d := player.dynamite()
	check(d.is_ready_in_hand(), "dynamite in hand")
	var sticks := d.sticks
	d.strike_match()
	await wait_until(func() -> bool: return d.lit, 120)
	check(d.lit, "the fuse is lit")
	d.windup = 1.0
	var s := d.throw()
	check(s != null and s.lit, "thrown, still burning")
	check_eq(d.sticks, sticks - 1, "one fewer")
	var start := player.global_position
	await physics_frames(60)
	if is_instance_valid(s):
		var flat := Vector2(s.global_position.x - start.x, s.global_position.z - start.z).length()
		check(flat > 5.0, "it flew (%.1f m)" % flat)
	await wait_until(func() -> bool: return not booms.is_empty(), 400)
	check_eq(booms.size(), 1, "and went off out there")
	check(player.wounds.physiology.severed_segments.is_empty(), "you're whole")


func test_hold_it_too_long() -> void:
	var player := await _player()
	var d := player.dynamite()
	d.strike_match()
	await wait_until(func() -> bool: return d.lit, 120)
	d.fuse_left = 0.1
	await wait_until(func() -> bool: return not booms.is_empty(), 60)
	var p := player.wounds.physiology
	check(p.severed_segments.has(&"hand_r"), "your hand's gone (%s)" % str(p.severed_segments.keys()))
	check(player.wounds.ringing > 5.0, "your ears ring (%.0f s)" % player.wounds.ringing)
	check(not p.can_hold("r"), "you can't hold anything in it")


# --- On the real street (Sean: "it doesn't destroy the buildings nor damage the bad guy") ------

func _street() -> Node3D:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	return street


func _throw_from(player: Player, windup: float) -> DynamiteStick:
	var d := player.dynamite()
	player.select_weapon(d)
	await wait_until(func() -> bool: return d.is_ready_in_hand(), 200)
	d.strike_match()
	await wait_until(func() -> bool: return d.lit, 200)
	d.windup = windup
	return d.throw()


func test_thrown_at_the_store_it_breaks_things() -> void:
	var street := await _street()
	var player: Player = street.get_node(^"Player")
	# Close enough that it lands on the walk by the door, not skittering along it (where it ends up
	# there turns on the contact order of every body in the street). With the walk up on steps (no
	# ramp along its edge) a stick that falls short stops against it in the street: from 7 m it
	# did, from 5 m it flew over onto the porch roof; from 6 m it lands at the door.
	var store := street.get_node(^"Store") as FalseFrontBuilding
	player.global_position = store.to_global(Vector3(store.door_rect.get_center().x, 0.0, -6.0))
	player.rotation = Vector3(0, PI, 0)
	await physics_frames(5)
	var broken := []
	var on_broken := func(id: StringName) -> void: broken.append(id)
	Events.member_broken.connect(on_broken)
	await _throw_from(player, 0.3)
	await wait_until(func() -> bool: return not booms.is_empty(), 500)
	Events.member_broken.disconnect(on_broken)
	var timber := broken.filter(func(id: StringName) -> bool: return not String(id).contains("glass"))
	print("  thrown at the store: %d broken, %d of them timber" % [broken.size(), timber.size()])
	check(timber.size() >= 3, "it breaks timber where it lands (%d)" % timber.size())
	street.queue_free()


func test_on_the_floor_it_blows_through_the_boards() -> void:
	var store := await _store()
	var board: StructureMember = null
	for m in store.get_members():
		if String(m.member_id).contains("floor/board"):
			board = m
			break
	var top := board.global_position + Vector3.UP * (board.size.y * 0.5 + DynamiteStick.RADIUS)
	var report := Blast.detonate(world, top, Blast.t().tnt_per_stick)
	var floor := (report.broken as Array).filter(func(id: StringName) -> bool: return String(id).contains("floor/board"))
	check(floor.size() >= 2, "floorboards blown through (%d)" % floor.size())


func test_thrown_near_him_it_hurts_him() -> void:
	var street := await _street()
	var player: Player = street.get_node(^"Player")
	var man: HumanBody = street.find_child("OutlawSpawn", true, false).spawn()
	await physics_frames(5)
	man.get_node(^"Brain").set_physics_process(false)
	var from := man.global_position - Vector3(10, 0, 0)
	player.global_position = from
	player.look_at_from_position(from, Vector3(man.global_position.x, 0, man.global_position.z))
	await physics_frames(5)
	await _throw_from(player, 0.35)
	await wait_until(func() -> bool: return not booms.is_empty(), 500)
	await physics_frames(10)
	var d: float = (booms[0][0] as Vector3).distance_to(man.global_position) if not booms.is_empty() else -1.0
	var lines := man.describe_wounds()
	print("  went off %.1f m from him: %s" % [d, "; ".join(lines)])
	check(d >= 0.0 and d < 3.0, "it landed near him (%.1f m)" % d)
	check(man.limp, "knocked down")
	check(lines.size() >= 1, "hurt: %s" % "; ".join(lines))
	street.queue_free()
