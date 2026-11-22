extends TestCase
## The save (#1138, SaveGame; docs/briefs/saving.md): the file (versioned, whole or not at all, the
## one before kept), each system's state out and back (a structure's breaks, holes, cuts and rubble;
## a man's wounds and how he lies; the floor's marks and the blood), and the whole of it: a valley
## where a lot has happened, saved, read into a valley built fresh, and the two compared system by
## system.

const SLOT := "test_save_game"

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	_wipe()


func after_each() -> void:
	_wipe()
	SaveGame.MIGRATIONS.clear()
	StoryState.wipe()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _wipe() -> void:
	for ext: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SaveGame.path_of(SLOT) + ext):
			DirAccess.remove_absolute(SaveGame.path_of(SLOT) + ext)


func _same(a: Variant, b: Variant, what: String, tol_m := 1e-3, skip: Array = [], tol := 1e-4) -> bool:
	var diff := SaveGame.differences(a, b, tol, tol_m, skip)
	return check(diff.is_empty(), "%s comes back the same (%d differ: %s)" % [what, diff.size(), ", ".join(diff.slice(0, 6))])


# --- The file ----------------------------------------------------------------------------------

func test_file_comes_back_whole() -> void:
	var d := {"version": SaveGame.VERSION, "world": "valley", "clock": {"hour": 21.5, "day": 3},
			"things": [Vector3(1, 2, 3), &"a_name", Transform3D(Basis(Vector3.UP, 0.4), Vector3(4, 5, 6)), 0.1, {"k": [1, 2]}]}
	check_eq(SaveGame.write(d, SLOT), OK, "it writes")
	check(not FileAccess.file_exists(SaveGame.path_of(SLOT) + ".tmp"), "no temp file left")
	var back := SaveGame.read(SLOT)
	check(back == d, "what's read is what was written, types and all")
	check(back.things[1] is StringName and back.things[0] is Vector3, "a name stays a name, a point a point")
	var head := SaveGame.head(SLOT)
	check_eq(int(head.get("version", -1)), SaveGame.VERSION, "the top line gives the version")
	check_eq(int(head.get("day", -1)), 3, "and the day, for a Continue button")
	check(SaveGame.read("no_such_slot").is_empty() and SaveGame.last_error != "", "no save: nothing, and it says so")


func test_a_broken_file_falls_back_to_the_one_before() -> void:
	SaveGame.write({"version": SaveGame.VERSION, "n": 1}, SLOT)
	SaveGame.write({"version": SaveGame.VERSION, "n": 2}, SLOT)
	check(FileAccess.file_exists(SaveGame.path_of(SLOT) + ".bak"), "the save before is kept")
	check_eq(SaveGame.read(SLOT).get("n"), 2, "the newest is read")
	# Cut short (the power went as it was written over): the one before.
	var whole := FileAccess.get_file_as_bytes(SaveGame.path_of(SLOT))
	var f := FileAccess.open(SaveGame.path_of(SLOT), FileAccess.WRITE)
	f.store_buffer(whole.slice(0, whole.size() - 9))
	f.close()
	check_eq(SaveGame.read(SLOT).get("n"), 1, "cut short, the one before is read")
	f = FileAccess.open(SaveGame.path_of(SLOT), FileAccess.WRITE)
	f.store_string("not a save at all")
	f.close()
	check_eq(SaveGame.read(SLOT).get("n"), 1, "rubbish, the one before is read")


func test_versions() -> void:
	SaveGame.write({"version": SaveGame.VERSION + 1, "n": 1}, SLOT)
	check(SaveGame.read(SLOT).is_empty(), "a newer build's save isn't loaded")
	check(SaveGame.last_error.contains("newer"), "and it says why (%s)" % SaveGame.last_error)
	_wipe()
	SaveGame.write({"version": SaveGame.VERSION - 1, "old_name": 7}, SLOT)
	check(SaveGame.read(SLOT).is_empty(), "an older save with no way up isn't loaded")
	SaveGame.MIGRATIONS[SaveGame.VERSION - 1] = func(d: Dictionary) -> Dictionary:
		d["new_name"] = d.old_name
		d.erase("old_name")
		return d
	var back := SaveGame.read(SLOT)
	check_eq(back.get("new_name"), 7, "with its migration, it's brought up")
	check_eq(back.get("version"), SaveGame.VERSION, "to this version")


# --- A structure -------------------------------------------------------------------------------

func _frame(world: Node3D) -> Structure:
	var s := Structure.new()
	s.structure_id = &"frame"
	world.add_child(s)
	s.add_member("sill", &"sill", &"framing", Vector3(3.0, 0.1, 0.15), Vector3(0.0, 0.05, 0.0))
	for i in 4:
		s.add_member("stud_%d" % i, &"stud", &"framing", Vector3(0.05, 2.4, 0.1), Vector3(-1.2 + i * 0.8, 1.3, 0.0))
	s.add_member("plate", &"plate", &"framing", Vector3(3.0, 0.1, 0.15), Vector3(0.0, 2.55, 0.0))
	for i in 6:
		s.add_member("board_%d" % i, &"board", &"weathered_pine", Vector3(3.0, 0.15, 0.022), Vector3(0.0, 0.4 + i * 0.3, 0.061))
	s.infer_supports()
	s.settle()
	return s


func _room() -> Node3D:
	var world := Node3D.new()
	add_child(world)
	holder = world
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	return world


func test_a_structure_comes_back() -> void:
	var world := _room()
	var s := _frame(world)
	await physics_frames(2)
	var b2 := s.get_member(&"frame/board_2")
	b2.carve_hit(b2.global_position + Vector3(0.3, 0.0, 0.05), b2.global_position + Vector3(0.3, 0.0, -0.05), true, Vector3.BACK * -1.0, 0.0057, 400.0, 0.0)
	b2.carve_hit(b2.global_position + Vector3(-0.5, 0.02, 0.05), b2.global_position + Vector3(-0.5, 0.02, -0.05), true, Vector3.FORWARD, 0.0057, 400.0, 0.0)
	s.cut_member(s.get_member(&"frame/board_4"), -0.4, 0.3, Vector3(0, 1, -3))
	s.break_member(s.get_member(&"frame/board_0"), Vector3(0, 0, -2))
	s.break_member(s.get_member(&"frame/board_5"), Vector3(0, 0, -2))
	s.get_member(&"frame/board_1").char_depth = 0.004
	await wait_until(func() -> bool:
		return s.rubble.all(func(rb: RigidBody3D) -> bool: return not is_instance_valid(rb) or rb.sleeping), 600)
	var saved := s.to_dict()
	check(saved.broken.size() >= 3 and saved.holes.size() == 1 and saved.cuts.size() == 1 and not saved.rubble.is_empty(),
			"there's something of each kind to keep (%d broken, %d holed, %d cut, %d pieces)" % [saved.broken.size(), saved.holes.size(), saved.cuts.size(), saved.rubble.size()])
	check(not Structure.untouched(saved), "it isn't as authored")
	var solid: float = b2.solid_share
	# Through the file and onto the same frame built fresh.
	SaveGame.write({"version": SaveGame.VERSION, "s": saved}, SLOT)
	var read: Dictionary = SaveGame.read(SLOT).s
	world.queue_free()
	await physics_frames(2)
	world = _room()
	var fresh := _frame(world)
	check(Structure.untouched(fresh.to_dict()), "built fresh, it's as authored")
	await physics_frames(2)
	check_eq(fresh.from_dict(read), 0, "every member the save names is found")
	await physics_frames(3)
	var back := fresh.to_dict()
	_same(_sorted(saved.broken), _sorted(back.broken), "what's broken")
	_same(saved.cuts, back.cuts, "what's cut")
	_same(saved.holes, back.holes, "the holes", 1e-4)
	_same(saved.fire, back.fire, "the char")
	check(fresh.get_member(&"frame/board_4/a") != null and not fresh.get_member(&"frame/board_4/a").broken, "the cut board's end stands")
	check_near(fresh.get_member(&"frame/board_2").solid_share, solid, 1e-6, "the holed board has the same wood left")
	# Every piece of rubble (a snapped board's two halves, the cut stretch's short pieces) where it lay.
	check_eq(back.rubble.size(), saved.rubble.size(), "as many pieces of rubble lie about")
	check(saved.rubble.any(func(p: Dictionary) -> bool: return p.has("len")), "some of them parts of a member")
	for p: Dictionary in saved.rubble:
		var at := Vector3(p.origin[0], p.origin[1], p.origin[2])
		var there := func(q: Dictionary) -> bool:
			return q.members == p.members and Vector3(q.origin[0], q.origin[1], q.origin[2]).distance_to(at) < 0.03 \
					and absf(float(q.get("len", 0.0)) - float(p.get("len", 0.0))) < 1e-3
		check(back.rubble.any(there), "a piece of %s lies where it lay" % p.members[0])
	for rb in fresh.rubble:
		check(rb.sleeping or rb.linear_velocity.length() < 0.05, "and lies still")


func _sorted(list: Array) -> Array:
	var out := list.duplicate()
	out.sort()
	return out


# --- A man -------------------------------------------------------------------------------------

func _man(world: Node3D, id: StringName, at: Vector3) -> HumanBody:
	var man := HumanBody.new()
	man.person_id = id
	man.name = String(id)
	world.add_child(man)
	man.global_position = at
	return man


## How far the furthest part of a limp man is from where a save had it.
func _worst_off(man: HumanBody, lie: Dictionary) -> float:
	var worst := 0.0
	for sid: StringName in lie:
		worst = maxf(worst, (man.parts[sid] as Node3D).global_position.distance_to((lie[sid] as Transform3D).origin))
	return worst


func _ball(man: HumanBody, seg: StringName, dir := Vector3.FORWARD) -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var at := (man.parts[seg] as Node3D).global_position
	man.take_bullet(man.parts[seg], at - dir * 0.15, dir, 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity,
			t.bullet_diameter * 0.5, t.bullet_mass, 5.0)


func test_a_man_comes_back() -> void:
	var world := _room()
	var hurt := _man(world, &"hurt", Vector3(0, 0, 0))
	var dead := _man(world, &"dead", Vector3(3, 0, 0))
	await physics_frames(3)
	_ball(hurt, &"thigh_r")
	hurt.physiology.apply_tourniquet(&"thigh_r")
	_ball(dead, &"chest")
	_ball(dead, &"head")
	await wait_until(func() -> bool: return not dead.physiology.alive, 600)
	check(not dead.physiology.alive, "one's dead")
	await wait_until(func() -> bool: return (dead.parts[&"pelvis"] as RigidBody3D).sleeping, 1200)
	var a := {"hurt": hurt.save_dict(), "dead": dead.save_dict()}
	check(a.dead.limp and not a.dead.lie.is_empty(), "the dead man's lie is kept")
	SaveGame.write({"version": SaveGame.VERSION, "p": a}, SLOT)
	var read: Dictionary = SaveGame.read(SLOT).p
	world.queue_free()
	await physics_frames(2)
	world = _room()
	var died := []
	var on_died := func(p: Node, _c: StringName) -> void: died.append(p)
	Events.person_died.connect(on_died)
	var on_fell := func(p: Node, _c: bool) -> void: died.append(p)
	Events.person_fell.connect(on_fell)
	var hurt2 := _man(world, &"hurt", Vector3(9, 0, 9))
	var dead2 := HumanBody.made_from(read.dead)
	world.add_child(dead2)
	await physics_frames(3)
	dead2.load_dict(read.dead)
	hurt2.load_dict(read.hurt)
	var b := {"hurt": hurt2.save_dict(), "dead": dead2.save_dict()}
	_same(a.hurt, b.hurt, "the hurt man", 0.02)
	_same(a.dead, b.dead, "the dead man", 0.02)
	await physics_frames(90)
	Events.person_died.disconnect(on_died)
	Events.person_fell.disconnect(on_fell)
	check(died.is_empty(), "nobody's death or fall is told again")
	check(dead2.limp and not dead2.physiology.alive, "he's dead and down")
	var pelvis: Vector3 = (dead2.parts[&"pelvis"] as Node3D).global_position
	check(_worst_off(dead2, a.dead.lie) < 0.03, "and lies where he lay (%.2f m off at worst)" % _worst_off(dead2, a.dead.lie))
	check_eq(hurt2.wounds.size(), hurt.wounds.size() if is_instance_valid(hurt) else hurt2.wounds.size(), "the hurt man has his wounds")
	check(hurt2.physiology.bleeds.any(func(x: Dictionary) -> bool: return x.get("tourniquet", false)), "and his belt on")


func test_marks_and_blood_come_back() -> void:
	var world := _room()
	var marks := FloorMarks.new()
	world.add_child(marks)
	await physics_frames(1)
	marks.add_liquid(Vector3(1, 0, 1), &"blood", 40.0)
	marks.add_dirt(Vector3(2, 0, 1), 30.0, 0.5)
	Blood.splat(world, Vector3(0, 0, 3), Vector3.UP, 20.0)
	Blood.splat(world, Vector3(4, 0, 3), Vector3.UP, 60.0, Vector3(3, -1, 0))
	Blood.dry(2.0)
	var a := {"floor": marks.save_dict(), "blood": Blood.save_list()}
	check(not a.floor.is_empty() and a.blood.size() == 2, "there are marks and blood to keep")
	SaveGame.write({"version": SaveGame.VERSION, "m": a}, SLOT)
	var read: Dictionary = SaveGame.read(SLOT).m
	world.queue_free()
	await physics_frames(2)
	Blood.clear()
	world = _room()
	marks = FloorMarks.new()
	world.add_child(marks)
	await physics_frames(1)
	marks.load_dict(read.floor)
	Blood.load_list(world, read.blood)
	_same(a, {"floor": marks.save_dict(), "blood": Blood.save_list()}, "the floor and the blood")


# --- The whole valley --------------------------------------------------------------------------

func _valley() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func test_the_valley_saved_and_loaded_matches() -> void:
	ValleyFolk.murder_auto = false
	await _valley()
	# Nothing's happened yet: there's next to nothing to keep.
	var quiet := SaveGame.save(get_tree(), SLOT)
	var first := SaveGame.read(SLOT)
	check(first.structures.is_empty(), "a valley nothing's happened in keeps no structures (%s)" % [first.structures.keys().slice(0, 4)])
	print("    untouched valley: %d bytes, capture %.1f ms, write %.1f ms, %d people" % [quiet.bytes, quiet.capture_ms, quiet.write_ms, first.people.size()])
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 3
	clock.set_time(10.5)
	valley.folk._look = 0.0
	await physics_frames(20)
	# The story.
	StoryState.set_fact("sheriff.care", "good", 1, 8.0)
	StoryState.set_fact("nolaw.murder", "seen", 2, 22.5)
	StoryState.mark_checkpoint()
	StoryState.set_fact("nojustice.ending", "arrest", 3, 9.0)
	# Two of the town: one shot in the leg and bound, one shot dead.
	var out: Array = valley.folk.people.keys().filter(func(id: StringName) -> bool: return valley.folk.folk_man(id) != null)
	check(out.size() >= 2, "there are townsfolk out at half past ten (%d)" % out.size())
	if out.size() < 2:
		return
	var hurt: HumanBody = valley.folk.folk_man(out[0])
	var dead: HumanBody = valley.folk.folk_man(out[1])
	_ball(hurt, &"shin_l")
	hurt.physiology.bind_up(&"shin_l")
	_ball(dead, &"head")
	_ball(dead, &"chest")
	# A wall: holed, a member broken, a board cut, and a charge against it.
	var building: Structure = null
	for s: Variant in valley.buildings.values():
		if s is Structure:
			building = s
			break
	check(building != null, "the valley has a spec building")
	if building == null:
		return
	var boards: Array = building.get_members().filter(func(m: StructureMember) -> bool: return m.kind == &"board" and m.length() > 1.0)
	check(boards.size() > 8, "with boards to break (%d)" % boards.size())
	var holed: StructureMember = boards[0]
	holed.carve_hit(holed.global_position + holed.global_basis.z * 0.05, holed.global_position - holed.global_basis.z * 0.05, true, -holed.global_basis.z, 0.0057, 400.0, 0.0)
	building.break_member(boards[3], Vector3(0, 1, 0))
	building.cut_member(boards[5], -0.3, 0.3, Vector3(0, 1, 0))
	Blast.detonate(valley, (boards[8] as StructureMember).global_position + Vector3(0, 0.2, 0), 0.4)
	# You: moved, hurt, three rounds gone, no shotgun, sticks used.
	var p := _player()
	p.global_position += Vector3(2.0, 0.0, 1.0)
	p.rotation.y = 1.1
	p.wounds.physiology.blood_ml -= 350.0
	p.revolver().state.belt -= 3
	p.lack(&"shotgun")
	p.dynamite().sticks = 9
	Blood.splat(valley, hurt.global_position, Vector3.UP, 30.0)
	await wait_until(func() -> bool: return not dead.physiology.alive, 900)
	check(not dead.physiology.alive, "one of them's dead")
	await physics_frames(420)
	await wait_until(func() -> bool: return (dead.parts[&"pelvis"] as RigidBody3D).sleeping, 900)
	# Saved, through the file (timed: a save mustn't hitch more than the sleep's fade hides).
	var timed := SaveGame.save(get_tree(), SLOT)
	check_eq(timed.error, OK, "it saves")
	check(timed.capture_ms + timed.write_ms < 500.0, "saving takes under half a second (%.0f ms)" % (timed.capture_ms + timed.write_ms))
	var a := SaveGame.capture(get_tree())
	check((a.warnings as Array).is_empty(), "nothing in the valley shares a name (%s)" % [a.warnings])
	check(a.structures.size() >= 1 and a.people.size() >= 2, "the save has the wall and the people (%d structures, %d people)" % [a.structures.size(), a.people.size()])
	check_eq(SaveGame.write(a, SLOT), OK, "it writes")
	var size := FileAccess.get_file_as_bytes(SaveGame.path_of(SLOT)).size()
	check(size < 2_000_000, "the file's small (%d bytes)" % size)
	# A new game, the save read into it.
	holder.queue_free()
	holder = null
	await physics_frames(3)
	GameReset.clear_statics()
	await _valley()
	await physics_frames(10)
	var d := SaveGame.read(SLOT)
	check(not d.is_empty(), "it reads (%s)" % SaveGame.last_error)
	var u := Time.get_ticks_usec()
	var report := SaveGame.apply(get_tree(), d)
	var load_ms := (Time.get_ticks_usec() - u) / 1000.0
	check(load_ms < 1500.0, "putting it back takes under a second and a half (%.0f ms)" % load_ms)
	check((report.missed as Array).is_empty(), "everything in it finds its place (%s)" % [report.missed])
	await physics_frames(1)
	await physics_frames(2)
	var b := SaveGame.capture(get_tree())
	_same(a.story, b.story, "the story")
	_same(a.clock, b.clock, "the clock", 1e-3)
	check(StoryState.checkpoint == a.story.checkpoint, "the checkpoint")
	_same(a.player, b.player, "you", 0.05, [], 0.01)
	# (The news keeps its frames as how long ago: the counts themselves are the new run's.)
	_same(a.folk, b.folk, "the town's day and its news", 1e-3, ["frame", "last_frame", "body"])
	check(not (a.folk.news.records as Array).is_empty(), "there was news to keep (the shooting)")
	_same(a.floor, b.floor, "the floor's marks")
	_same(a.blood, b.blood, "the blood")
	check_eq(b.people.keys().size(), a.people.keys().size(), "the same people are in the world")
	for id: StringName in a.people:
		if not b.people.has(id):
			check(false, "%s is in the world" % id)
			continue
		var pa: Dictionary = a.people[id]
		var pb: Dictionary = b.people[id]
		# (A living man's on his feet and about his day: a step in three frames. The dead lie as they lay.)
		# His mood isn't kept (he wakes to his day), so nor is a cower.
		_same(pa, pb, "%s" % id, 0.12 if not pa.physiology.alive else 0.5, ["mind", "pose"] if pa.physiology.alive else ["mind"], 0.2)
		_same(pa.mind.get("relations", {}), pb.mind.get("relations", {}), "%s's opinions" % id)
	check_eq(b.structures.keys().size(), a.structures.keys().size(), "the same structures are changed")
	for id: String in a.structures:
		if not b.structures.has(id):
			check(false, "%s is changed" % id)
			continue
		var sa: Dictionary = a.structures[id]
		var sb: Dictionary = b.structures[id]
		_same(_sorted(sa.broken), _sorted(sb.broken), "%s's broken members" % id)
		_same(sa.cuts, sb.cuts, "%s's cuts" % id)
		_same(sa.holes, sb.holes, "%s's holes" % id)
		_same(sa.fire, sb.fire, "%s's char" % id)
		_same(sa.dents, sb.dents, "%s's dents" % id)
	# And a while on, the dead still lie where they lay (nothing thrown as the world wakes).
	await physics_frames(90)
	for id: StringName in a.people:
		if not a.people[id].physiology.alive:
			var man: HumanBody = valley.folk.folk_man(id)
			check(man != null and _worst_off(man, a.people[id].lie) < 0.03, "%s still lies where he lay (%.2f m off at worst)" % [id, _worst_off(man, a.people[id].lie) if man else -1.0])
	print("    save: %d bytes, capture %.1f ms, write %.1f ms; load %.1f ms %s" % [size, timed.capture_ms, timed.write_ms, load_ms, report.ms])
