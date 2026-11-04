extends TestCase
## Dynamite bundles (#647, brief docs/briefs/dynamite-bundles.md): a bundle is its sticks' kg, tied
## one stick at a time in your hand up to the most a bundle holds and what you carry; planted it waits
## unlit and a match aimed at it lights it; no more than `max_bundles` wait at once; a save keeps a
## planted, unlit one; on the trestle a bundle cuts the 12x12 post it's on, and not the one beside it.

const LAB_LINE := preload("res://experiments/trestle_lab/lab_line.gd")

var world: Node3D
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
	world.add_child(Ballistics.new())
	booms.clear()
	Events.exploded.connect(_on_boom)
	await physics_frames(2)


func after_each() -> void:
	Events.exploded.disconnect(_on_boom)
	for a in [&"fire", &"cock", &"aim", &"reload", &"shove"]:
		Input.action_release(a)
	world.queue_free()
	await physics_frames(2)


func _on_boom(at: Vector3, kg: float) -> void:
	booms.append([at, kg])


func _store() -> FalseFrontBuilding:
	var store := FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	await physics_frames(2)
	return store


func _side_board(store: FalseFrontBuilding) -> StructureMember:
	var boards: Array[StructureMember] = []
	for m in store.get_members():
		if String(m.member_id).contains("left/siding"):
			boards.append(m)
	return boards[boards.size() / 2] if not boards.is_empty() else null


func _player() -> Player:
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	await physics_frames(3)
	var d := player.dynamite()
	player.select_weapon(d)
	await wait_until(func() -> bool: return d.is_ready_in_hand(), 180)
	d.needs_captured_mouse = false
	return player


## The player in the store `off` m in from its side wall, facing it, looking `pitch` degrees.
func _facing_wall(off: float, pitch: float) -> Array:
	var store := await _store()
	var player := await _player()
	var board := _side_board(store)
	player.global_position = Vector3(off, store.floor_top + 0.05, board.global_position.z - 3.0)
	player.rotation.y = PI * 0.5
	player.add_look(Vector2(0.0, pitch - player.get_pitch_degrees()), false)
	await physics_frames(10)
	return [store, player]


func _key(action: StringName, down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _tap(action: StringName) -> void:
	_key(action, true)
	await physics_frames(2)
	_key(action, false)
	await physics_frames(1)


func _bundles() -> Array:
	return get_tree().get_nodes_in_group(&"dynamite").filter(func(n: Node) -> bool: return n is DynamiteStick and not n.is_queued_for_deletion())


func test_a_bundle_is_its_sticks_kg() -> void:
	var bt := Blast.t()
	var s := DynamiteStick.make(world, Vector3(0, 6.0, 0), Vector3.ZERO, 0.05, 4)
	check_eq(s.sticks, 4, "four sticks")
	check_near(s.kg, 4.0 * bt.tnt_per_stick, 1e-6, "their kg (%.2f)" % s.kg)
	check(s.is_bundle(), "a bundle")
	check(DynamiteStick.radius_of(4) > DynamiteStick.RADIUS * 2.0, "fatter than a stick")
	check(s.find_child("Paper3", false, false) != null and s.find_child("Paper4", false, false) == null, "drawn as four sticks")
	s.gravity_scale = 0.0
	s.light()
	await wait_until(func() -> bool: return not booms.is_empty(), 60)
	check_eq(booms.size(), 1, "one blast, not four")
	if booms.size() == 1:
		check_near(float(booms[0][1]), 4.0 * bt.tnt_per_stick, 0.01, "as its four sticks in the air (%.2f kg)" % float(booms[0][1]))
	var one := DynamiteStick.make(world, Vector3(5, 0.3, 0))
	check_eq(one.sticks, 1, "a stick is still one")
	check_near(one.kg, bt.tnt_per_stick, 1e-6, "of one stick's kg")


func test_tied_one_stick_at_a_time_to_what_you_carry() -> void:
	var bt := Blast.t()
	var player := await _player()
	var d := player.dynamite()
	d.sticks = 3
	check_eq(d.bundle, 1, "a lone stick in hand")
	await _tap(&"reload")
	check(d.tying >= 0.0, "R starts tying one on")
	await physics_frames(int(bt.tie_time * 30.0))
	check_eq(d.bundle, 1, "not before it's tied")
	await wait_until(func() -> bool: return d.bundle == 2, int(bt.tie_time * 60.0) + 20)
	check_eq(d.bundle, 2, "two tied")
	check(d.stick_node.find_child("Paper1", false, false) != null, "the hand holds two")
	d.tie()
	await wait_until(func() -> bool: return d.tying < 0.0, int(bt.tie_time * 60.0) + 20)
	check_eq(d.bundle, 3, "three")
	d.tie()
	check(d.tying < 0.0, "no fourth: you carry three")
	d.sticks = bt.bundle_max_sticks + 4
	for k in bt.bundle_max_sticks + 2:
		d.tie()
		if d.tying >= 0.0:
			d.tying = bt.tie_time  # (tied at once)
		await physics_frames(2)
	check_eq(d.bundle, bt.bundle_max_sticks, "no more than a bundle holds (%d)" % bt.bundle_max_sticks)
	# Thrown, its sticks go off what you carry and a lone stick comes out.
	var carried := d.sticks
	d.windup = 0.5
	var s := d.throw()
	check(s != null and s.sticks == bt.bundle_max_sticks, "the bundle's thrown whole")
	check_eq(d.sticks, carried - bt.bundle_max_sticks, "its sticks gone from what you carry")
	check_eq(d.bundle, 1, "a lone stick next")
	check(s.linear_velocity.length() < bt.throw_speed_max * 0.75, "and not as far as a stick (%.1f m/s)" % s.linear_velocity.length())
	s.queue_free()


func test_planted_it_waits_unlit_and_a_match_lights_it() -> void:
	var bt := Blast.t()
	var r := await _facing_wall(0.9, -35.0)
	var player: Player = r[1]
	var d := player.dynamite()
	d.sticks = 6
	d.bundle = 3
	await physics_frames(3)
	check(d.claims_use(), "a wall in reach")
	_key(&"shove", true)
	await physics_frames(int(bt.plant_time * 60.0) + 6)
	_key(&"shove", false)
	await physics_frames(20)
	var set_down := _bundles()
	check_eq(set_down.size(), 1, "the bundle set down")
	if set_down.size() != 1:
		return
	var s: DynamiteStick = set_down[0]
	check_eq(s.sticks, 3, "all three")
	check(s.planted and s.freeze, "planted, held")
	check(not s.lit, "left unlit when you let go")
	check_eq(d.sticks, 3, "three left in hand")
	check(d.aimed_charge() == s, "aimed at it, in reach")
	await _tap(&"cock")
	check(d.lighting > 0.0 and d.lighting_planted == s, "a match struck for it")
	check(not d.lit, "not the stick in your hand")
	await wait_until(func() -> bool: return s.lit, 90)
	check(s.lit, "lit")
	check_near(s.fuse_left, bt.plant_fuse_seconds, 0.2, "a planted charge's fuse")
	check_eq(d.sticks, 3, "and you still have yours")
	await wait_until(func() -> bool: return not booms.is_empty(), int(bt.plant_fuse_seconds * 60.0) + 30)
	check_eq(booms.size(), 1, "it goes")


func test_no_more_than_the_cap_wait_at_once() -> void:
	var bt := Blast.t()
	var r := await _facing_wall(0.9, -35.0)
	var player: Player = r[1]
	var d := player.dynamite()
	d.sticks = 4 * (bt.max_bundles + 1) + 2
	var space := World.space(d)
	var cam := player.camera
	for k in bt.max_bundles + 1:
		d.bundle = 4
		var look := -cam.global_basis.z + cam.global_basis.x * (0.25 * float(k) - 0.4)
		var spot := DynamiteViewmodel.plant_spot(space, cam.global_position, look, bt.plant_reach, [player.get_rid()], DynamiteStick.radius_of(4))
		check(not spot.is_empty(), "a spot for bundle %d" % (k + 1))
		var s := d.plant(spot)
		d.planted = null
		if k < bt.max_bundles:
			check(s != null and s.sticks == 4, "bundle %d set" % (k + 1))
		else:
			check(s == null, "no bundle past the cap (%d)" % bt.max_bundles)
			check(d.at_cap(), "at the cap")
	check_eq(DynamiteStick.bundles_set(get_tree()).size(), bt.max_bundles, "%d waiting" % bt.max_bundles)
	d.bundle = 1
	check(not d.at_cap(), "a lone stick isn't held back")
	var one := d.plant(DynamiteViewmodel.plant_spot(space, cam.global_position, -cam.global_basis.z, bt.plant_reach, [player.get_rid()]))
	check(one != null and one.sticks == 1, "and still plants")
	d.planted = null
	# One goes off: room for another.
	DynamiteStick.bundles_set(get_tree())[0].detonate()
	await physics_frames(3)
	d.bundle = 4
	check(not d.at_cap(), "one gone, one more may go")


func test_a_save_keeps_a_planted_unlit_bundle() -> void:
	var store := await _store()
	var board := _side_board(store)
	var at := board.global_position + Vector3(0.1, 0.0, 0.0)
	var s := DynamiteStick.make(world, at, Vector3.ZERO, Blast.t().plant_fuse_seconds, 5)
	var basis := Basis(Vector3.UP, 0.7)
	s.global_basis = basis
	s.stick_to(board)
	var lone := DynamiteStick.make(world, Vector3(4, 0.3, 4))
	await physics_frames(3)
	var saved := DynamiteStick.save_all(get_tree())
	check_eq(saved.size(), 2, "both in the save")
	saved = JSON.parse_string(JSON.stringify(saved))  # through a file's text
	s.free()
	lone.free()
	await physics_frames(2)
	check(_bundles().is_empty(), "gone")
	var back := DynamiteStick.restore_all(world, saved)
	await physics_frames(3)
	check_eq(back.size(), 2, "both back")
	var b: DynamiteStick = back[0] if back[0].sticks == 5 else back[1]
	check_eq(b.sticks, 5, "five sticks")
	check_near(b.kg, 5.0 * Blast.t().tnt_per_stick, 1e-6, "their kg")
	check(b.global_position.distance_to(at) < 0.005, "where it was")
	check(b.global_basis.z.distance_to(basis.z) < 0.01, "lying as it was")
	check(b.planted and b.stuck_to == board and b.freeze, "planted on the same board")
	check(not b.lit, "unlit")
	await physics_frames(30)
	check(b.global_position.distance_to(at) < 0.005, "held there")
	store.break_member(board)
	await physics_frames(5)
	check(not b.freeze, "let go when its board goes, as before the save")


## On the trestle (the lab's viaduct, #623): a charge on a bottom-story post's inner face cuts that
## 12x12 post and never the one beside it, 0.9 m off (a bundle takes the post it's on, at any size;
## brief). Set on it as E sets it (touching), one stick cuts it; 3.5 cm off the face one doesn't and a
## bundle of four does (the trestle lab's "one doesn't, two do" was 5 cm off, #638).
func test_on_the_trestle_a_bundle_cuts_the_post_its_on() -> void:
	var line: TrackLine = LAB_LINE.build(world, load("res://config/train.tres"), LAB_LINE.ROUTE, null, "start", false)
	var tr: Trestle = line.trestles[0]
	tr.settle()
	# [sticks, gap off the face (m), cut]
	var cases := [[1, 0.003, true], [1, 0.035, false], [4, 0.035, true], [8, 0.003, true]]
	var bi := 16
	for c: Array in cases:
		var bent: Dictionary = tr.bents[bi]
		bi += 5
		var posts: Array = (bent.stories as Array).back().posts
		var n := posts.size()
		var p: StructureMember = posts[n / 2 - 1]
		var q: StructureMember = posts[n / 2]
		var foot := p.global_transform * Vector3(0, 0, -p.size.z * 0.5)
		var toward := (q.global_position - p.global_position)
		toward.y = 0.0
		toward = toward.normalized()
		var at := foot + p.global_transform.basis.z.normalized() * 0.6 + toward * (p.size.x * 0.5 + DynamiteStick.radius_of(int(c[0])) + float(c[1]))
		check_near(p.size.x, 0.305, 0.01, "a 12 in post")
		var s := DynamiteStick.make(tr.get_parent(), at, Vector3.ZERO, 0.05, int(c[0]))
		s.stick_to(p)
		s.light()
		var before := booms.size()
		await wait_until(func() -> bool: return booms.size() > before, 60)
		var cut := p.broken or p.has_meta(&"cut_pieces")
		var other := q.broken or q.has_meta(&"cut_pieces")
		check_eq(cut, bool(c[2]), "%d stick(s) %.1f cm off the post: %s" % [int(c[0]), float(c[1]) * 100.0, "cut" if c[2] else "stands"])
		check(not other, "%d stick(s): the post 0.9 m off stands" % int(c[0]))
		await physics_frames(2)
