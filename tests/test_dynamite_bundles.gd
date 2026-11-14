extends TestCase
## Dynamite bundles (#647, brief docs/briefs/dynamite-bundles.md; Sean's calls on #648): a bundle is
## its sticks' kg; R held ~12 s makes one from your loose sticks (the work kept if you let go), a tap
## switches stick and bundle in hand; planted it's wired to the plunger and waits unlit (a match aimed
## at it lights its fuse); no more than `max_bundles` wait at once; the plunger (5) sets every wired
## bundle off together; a save keeps a planted, wired one; on the trestle a bundle of four cuts the 12x12
## post it's on, and not the one beside it.

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
	for a in [&"fire", &"cock", &"aim", &"reload", &"shove", &"weapon_plunger"]:
		Input.action_release(a)
	world.queue_free()
	await physics_frames(2)


var frames: Array = []


func _on_boom(at: Vector3, kg: float) -> void:
	booms.append([at, kg])
	frames.append(Engine.get_physics_frames())


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


## Sean (#648): "you need to prep them first ... 10-15 seconds of holding down a key". R held makes
## one whole bundle from your loose sticks at `make_time`; let go early and the work's kept; a tap
## puts a stick or a bundle in your hand; too few sticks, none's made.
func test_r_held_makes_a_bundle_and_a_tap_switches() -> void:
	var bt := Blast.t()
	check(bt.make_time >= 10.0 and bt.make_time <= 15.0, "10-15 s to make one (%.0f)" % bt.make_time)
	var player := await _player()
	var d := player.dynamite()
	d.sticks = bt.bundle_sticks + 2
	check_eq(d.in_hand(), 1, "a lone stick in hand")
	_key(&"reload", true)
	await physics_frames(int(bt.make_time * 30.0))
	check(d.is_making(), "R held: tying one")
	check_eq(d.bundles, 0, "not made at half the time")
	_key(&"reload", false)
	await physics_frames(5)
	var kept := d.making
	check(kept > bt.make_time * 0.4, "let go, the work's kept (%.1f s)" % kept)
	check_eq(d.in_hand(), 1, "and the tap didn't count (it was a hold)")
	_key(&"reload", true)
	await wait_until(func() -> bool: return d.bundles == 1, int(bt.make_time * 60.0))
	var left_frames := int((bt.make_time - kept) * 60.0)
	check_eq(d.bundles, 1, "made")
	check_eq(d.sticks, 2, "of %d loose sticks" % bt.bundle_sticks)
	check(d.hold_bundle and d.in_hand() == bt.bundle_sticks, "in your hand")
	_key(&"reload", false)
	await physics_frames(5)
	check_eq(d.making, 0.0, "nothing more started (two sticks aren't enough) (%d frames to finish)" % left_frames)
	check(d.stick_node.find_child("Paper%d" % (bt.bundle_sticks - 1), false, false) != null, "the hand holds the bundle")
	await _tap(&"reload")
	await physics_frames(2)
	check_eq(d.in_hand(), 1, "a tap: a stick in hand")
	await _tap(&"reload")
	await physics_frames(2)
	check_eq(d.in_hand(), bt.bundle_sticks, "again: the bundle")
	_key(&"reload", true)
	await physics_frames(int(bt.make_time * 20.0))
	check_eq(d.making, 0.0, "too few loose sticks: nothing's made")
	_key(&"reload", false)
	await physics_frames(3)
	# Thrown, the bundle goes off what you carry and a stick comes out.
	await physics_frames(40)
	d.hold_bundle = true
	d.windup = 0.5
	var s := d.throw()
	check(s != null and s.sticks == bt.bundle_sticks, "the bundle's thrown whole")
	check_eq(d.bundles, 0, "gone from what you carry")
	check_eq(d.in_hand(), 1, "a stick next")
	check(s.linear_velocity.length() < bt.throw_speed_max * 0.75, "and not as far as a stick (%.1f m/s)" % s.linear_velocity.length())
	s.queue_free()


## A planted bundle's fuse is still there to light by hand: a match aimed at it (Q).
func test_planted_it_waits_unlit_and_a_match_lights_it() -> void:
	var bt := Blast.t()
	var r := await _facing_wall(0.9, -35.0)
	var player: Player = r[1]
	var d := player.dynamite()
	d.sticks = 3
	d.bundles = 1
	d.hold_bundle = true
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
	check_eq(s.sticks, Blast.t().bundle_sticks, "the whole bundle")
	check(s.planted and s.freeze, "planted, held")
	check(s.wired, "wired to the plunger as it's set")
	check(not s.lit, "left unlit when you let go")
	check_eq(d.bundles, 0, "off what you carry")
	check_eq(d.in_hand(), 1, "a stick in hand next")
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
	d.sticks = 2
	d.bundles = bt.max_bundles + 1
	var space := World.space(d)
	var cam := player.camera
	for k in bt.max_bundles + 1:
		d.hold_bundle = true
		var look := -cam.global_basis.z + cam.global_basis.x * (0.25 * float(k) - 0.4)
		var spot := DynamiteViewmodel.plant_spot(space, cam.global_position, look, bt.plant_reach, [player.get_rid()], DynamiteStick.radius_of(4))
		check(not spot.is_empty(), "a spot for bundle %d" % (k + 1))
		var s := d.plant(spot)
		d.planted = null
		if k < bt.max_bundles:
			check(s != null and s.sticks == bt.bundle_sticks, "bundle %d set" % (k + 1))
		else:
			check(s == null, "no bundle past the cap (%d)" % bt.max_bundles)
			check(d.at_cap(), "at the cap")
	check_eq(DynamiteStick.bundles_set(get_tree()).size(), bt.max_bundles, "%d waiting" % bt.max_bundles)
	d.hold_bundle = false
	check(not d.at_cap(), "a lone stick isn't held back")
	var one := d.plant(DynamiteViewmodel.plant_spot(space, cam.global_position, -cam.global_basis.z, bt.plant_reach, [player.get_rid()]))
	check(one != null and one.sticks == 1, "and still plants")
	d.planted = null
	# One goes off: room for another.
	DynamiteStick.bundles_set(get_tree())[0].detonate()
	await physics_frames(3)
	d.hold_bundle = true
	check(not d.at_cap(), "one gone, one more may go")


func test_a_save_keeps_a_planted_unlit_bundle() -> void:
	var store := await _store()
	var board := _side_board(store)
	var at := board.global_position + Vector3(0.1, 0.0, 0.0)
	var s := DynamiteStick.make(world, at, Vector3.ZERO, Blast.t().plant_fuse_seconds, 5)
	var basis := Basis(Vector3.UP, 0.7)
	s.global_basis = basis
	s.stick_to(board)
	s.wire()
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
	check(b.wired and b.get_node_or_null(^"Cap") != null, "still on the wire")
	var l: DynamiteStick = back[1] if b == back[0] else back[0]
	check(not l.wired and not l.is_bundle(), "the loose stick isn't")
	await physics_frames(30)
	check(b.global_position.distance_to(at) < 0.005, "held there")
	store.break_member(board)
	await physics_frames(5)
	check(not b.freeze, "let go when its board goes, as before the save")


## Sean (#648): fired together from one plunger, and "it doesn't need to be messy": planted
## bundles are on the wire with no more to it; 5 brings out the box; fire held pushes the handle home
## and every wired bundle goes, on consecutive ticks (`fire_spread_ticks`); let go short, nothing;
## a loose stick and a bundle that isn't wired stay.
func test_the_plunger_sets_off_every_wired_bundle_at_once() -> void:
	var bt := Blast.t()
	var player := await _player()
	player.global_position = Vector3(0, 0.05, 0)
	var spots := [Vector3(18, 0.1, 0), Vector3(-18, 0.1, 6), Vector3(0, 0.1, 22)]
	var wired: Array[DynamiteStick] = []
	for at: Vector3 in spots:
		var b := DynamiteStick.make(world, at, Vector3.ZERO, bt.plant_fuse_seconds, bt.bundle_sticks)
		b.planted = true
		b.wire()
		wired.append(b)
	var lone := DynamiteStick.make(world, Vector3(-30, 0.1, -30))
	var unwired := DynamiteStick.make(world, Vector3(30, 0.1, -30), Vector3.ZERO, bt.plant_fuse_seconds, bt.bundle_sticks)
	unwired.planted = true
	var p := player.plunger()
	check(p != null, "a plunger box on you")
	player.select_weapon(p)
	await wait_until(func() -> bool: return p.is_ready_in_hand(), 180)
	p.needs_captured_mouse = false
	check(p.is_ready_in_hand(), "the box in your hands")
	booms.clear()
	frames.clear()
	_key(&"fire", true)
	await physics_frames(int(bt.push_time * 30.0))
	_key(&"fire", false)
	await physics_frames(10)
	check(booms.is_empty(), "let go half way: nothing")
	check(p.push == 0.0, "the handle back up")
	_key(&"fire", true)
	await wait_until(func() -> bool: return booms.size() >= spots.size(), int(bt.push_time * 60.0) + 30)
	_key(&"fire", false)
	await physics_frames(10)
	check_eq(booms.size(), spots.size(), "all %d bundles went" % spots.size())
	if frames.size() == spots.size():
		var span: int = frames.max() - frames.min()
		check(span <= (spots.size() - 1) * maxi(bt.fire_spread_ticks, 1), "together: within %d ticks (%d)" % [(spots.size() - 1) * maxi(bt.fire_spread_ticks, 1), span])
	for b in wired:
		check(not is_instance_valid(b), "a wired bundle gone")
	check(is_instance_valid(lone) and not lone.is_queued_for_deletion(), "the loose stick stays")
	check(is_instance_valid(unwired) and not unwired.is_queued_for_deletion(), "the unwired bundle stays")
	check(player.wounds.physiology.severed_segments.is_empty(), "and you're whole, 18 m off")


## On the trestle (the lab's viaduct, #623): a charge on a bottom-story post's inner face cuts that
## 12x12 post and never the one beside it, 0.9 m off (a bundle takes the post it's on, at any size;
## brief). Heavy timber is tough (Sean, #648; BlastTuning.heavy_*): set on it as E sets it
## (touching), a bundle of four cuts it and three sticks, or one, don't.
func test_on_the_trestle_a_bundle_cuts_the_post_its_on() -> void:
	var line: TrackLine = LAB_LINE.build(world, load("res://config/train.tres"), LAB_LINE.ROUTE, null, "start", false)
	var tr: Trestle = line.trestles[0]
	tr.settle()
	# [sticks, gap off the face (m), cut]
	var cases := [[1, 0.003, false], [3, 0.003, false], [4, 0.003, true], [8, 0.003, true]]
	# Bents about the tallest, three apart (no charge reaches the next one tried).
	var mid := 0
	for i in tr.bents.size():
		if float(tr.bents[i].height) > float(tr.bents[mid].height):
			mid = i
	var picks := [mid, mid - 3, mid + 3, mid - 6]
	for ci in cases.size():
		var c: Array = cases[ci]
		var bent: Dictionary = tr.bents[clampi(picks[ci], 1, tr.bents.size() - 2)]
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
