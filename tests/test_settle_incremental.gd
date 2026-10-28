extends TestCase
## An analysis carried over (StructuralAnalysis.begin_update: only what a change reaches is worked
## out again, Structure.start_analysis) gives a building the same loads as one done from the top,
## through a break, a cut, a hole and a blast; and a blast settles the same members whichever way.
## Issue #374: a stick in the spec saloon settled in 64 rounds of all 5,150 members, 10 s on one
## frame; a round of the carried-over analysis is the few dozen members near the damage.

const Lab := preload("res://experiments/building_lab/lab.gd")

var world: Node3D
var ballistics: Ballistics


func before_each() -> void:
	Structure.incremental = true
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
	await physics_frames(2)


func after_each() -> void:
	Structure.incremental = true
	world.queue_free()
	await physics_frames(2)


func _store() -> FalseFrontBuilding:
	var store := FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	await physics_frames(2)
	return store


func _find(s: Structure, has: String, kind: StringName = &"") -> StructureMember:
	var found: Array[StructureMember] = []
	for m in s.get_members():
		if not m.broken and String(m.member_id).contains(has) and (kind == &"" or m.kind == kind):
			found.append(m)
	return found[found.size() / 2] if not found.is_empty() else null


## A point `off` m outside a wall board, knee high (as test_dynamite's).
func _outside(store: FalseFrontBuilding, board: StructureMember, off: float) -> Vector3:
	var inside := store.global_transform * Vector3(0, 1.0, 0)
	var c := board.global_position
	var out := c - inside
	out.y = 0.0
	var n := Vector3.ZERO
	var t := INF
	for i in 3:
		if board.size[i] < t:
			t = board.size[i]
			n = board.global_transform.basis[i].normalized()
	if n.dot(out) < 0.0:
		n = -n
	return Vector3(c.x, 0.5, c.z) + n * off


## The carried-over analysis against one from the top, member by member.
func _same_as_full(s: Structure, what: String) -> void:
	var inc := s.last_analysis
	var full := StructuralAnalysis.new(s.tuning).analyse(s)
	check(inc != null and inc.left() == 0, "%s: the kept analysis is finished" % what)
	if inc == null:
		return
	var inc_falling := inc.falling.duplicate()
	var full_falling := full.falling.duplicate()
	inc_falling.sort()
	full_falling.sort()
	check(inc_falling == full_falling, "%s: the same members falling (%s vs %s)" % [what, inc_falling.slice(0, 4), full_falling.slice(0, 4)])
	var missing := 0
	var extra := 0
	var off := 0
	var worst := 0.0
	for id: StringName in full.load:
		if not inc.load.has(id):
			missing += 1
			continue
		var d: float = absf(float(inc.load[id]) - float(full.load[id])) / maxf(1.0, absf(float(full.load[id])))
		worst = maxf(worst, d)
		if d > 1e-6:
			off += 1
	for id: StringName in inc.load:
		if not full.load.has(id):
			extra += 1
	check(missing == 0 and extra == 0, "%s: the same members carry loads (%d missing, %d extra of %d)" % [what, missing, extra, full.load.size()])
	check(off == 0, "%s: every load the same (%d differ, worst %.9f)" % [what, off, worst])
	var u_off := 0
	var u_worst := 0.0
	var m_off := 0
	for id: StringName in full.utilisation:
		if not inc.utilisation.has(id):
			u_off += 1
			continue
		var d: float = absf(float(inc.utilisation[id]) - float(full.utilisation[id])) / maxf(1.0, absf(float(full.utilisation[id])))
		u_worst = maxf(u_worst, d)
		if d > 1e-6:
			u_off += 1
		if inc.mode.get(id) != full.mode.get(id):
			m_off += 1
	check(u_off == 0 and inc.utilisation.size() == full.utilisation.size(), "%s: every utilisation the same (%d differ of %d, worst %.9f)" % [what, u_off, full.utilisation.size(), u_worst])
	check(m_off == 0, "%s: the same governing mode (%d differ)" % [what, m_off])
	check_near(inc.ground_load, full.ground_load, maxf(1.0, full.ground_load * 1e-6), "%s: the same load on the ground" % what)


func test_a_carried_over_analysis_matches_one_from_the_top() -> void:
	var store := await _store()
	store.settle()  # the first: from the top, kept
	_same_as_full(store, "as built")
	var full_n := store.member_count()
	# A stud knocked out.
	var stud := _find(store, "left/stud", &"stud")
	check(stud != null, "a stud to break")
	var worked := []
	if stud:
		store.break_member(stud)
		worked.append(store.last_analysis._sorted.size())
		_same_as_full(store, "a stud broken")
	# A board cut (a charge's hole).
	var board := _find(store, "left/siding", &"board")
	check(board != null, "a board to cut")
	if board:
		store.cut_member(board, -0.3, 0.3)
		store.settle()
		worked.append(store.last_analysis._sorted.size())
		_same_as_full(store, "a board cut")
	# A joist shot through: weaker, the same loads.
	var joist := _find(store, "joist", &"joist")
	check(joist != null, "a joist to hole")
	if joist:
		joist.add_hole(joist.global_position + Vector3.UP * 0.2, joist.global_position + Vector3.DOWN * 0.2, 0.02)
		await physics_frames(1)  # the hole's settle_soon (deferred)
		store.settle()
		worked.append(store.last_analysis._sorted.size())
		_same_as_full(store, "a joist holed")
	# A stick by the wall: cuts, snaps and drops in one settle.
	var siding := _find(store, "left/siding", &"board")
	if siding:
		Blast.detonate(world, _outside(store, siding, 0.25), 0.15)
		worked.append(store.last_analysis._sorted.size())
		_same_as_full(store, "a blast")
	print("  members worked a round, carried over: %s of %d" % [worked, full_n])
	check(worked.all(func(n: int) -> bool: return n < full_n / 2), "each round works a part of the building, not all of it (%s of %d)" % [worked, full_n])


func test_a_blast_breaks_the_same_members_either_way() -> void:
	var results := []
	for mode in [true, false]:
		Structure.incremental = mode
		var store := await _store()
		var siding := _find(store, "left/siding", &"board")
		var report := Blast.detonate(world, _outside(store, siding, 0.25), 0.15)
		var broken: Array = []
		for m in store.get_members():
			if m.broken:
				broken.append(String(m.member_id))
		broken.sort()
		var direct: Array = Array(report.broken).map(func(id: StringName) -> String: return String(id))
		direct.sort()
		results.append({"broken": broken, "direct": direct, "rubble": store.rubble.size()})
		store.queue_free()
		await physics_frames(2)
	Structure.incremental = true
	print("  the blast: %d broken (%d in the report), %d pieces" % [results[0].broken.size(), results[0].direct.size(), results[0].rubble])
	check(results[0].broken.size() > 2, "the stick breaks something (%d)" % results[0].broken.size())
	check(results[0].broken == results[1].broken, "the same members broken carried over as from the top (%d vs %d)" % [results[0].broken.size(), results[1].broken.size()])
	check(results[0].direct == results[1].direct, "and the blast's report names the same")
	check_eq(results[0].rubble, results[1].rubble, "the same pieces")


## Sean's freeze (issue #374): a stick on the spec saloon's hall floor froze the game for seconds
## (11.6 s on this workspace's core, the settle's 64 rounds over 5,150 members). The frame it goes
## off on is now bounded, and the collapse still comes, over the frames after.
func test_a_stick_in_the_spec_saloon_doesnt_freeze_the_frame() -> void:
	var lab := Lab.new()
	add_child(lab)
	await physics_frames(10)
	var saloon: Structure = lab.building
	var members := saloon.member_count()
	var t0 := Time.get_ticks_usec()
	var report := Blast.detonate(lab, Vector3(6.0, 0.8, 6.0), 0.15)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	var direct := 0
	for id: StringName in report.broken:
		if saloon.members.has(id):
			direct += 1
	await physics_frames(300)
	var broken := 0
	for m in saloon.get_members():
		if m.broken:
			broken += 1
	print("  the stick's frame: %.0f ms (%d members); %d broken by the blast, %d broken 5 s on, %d pieces" % [ms, members, direct, broken, saloon.rubble.size()])
	check(members > 4000, "the spec saloon (%d members)" % members)
	check(direct >= 10, "the blast holes the floor (%d)" % direct)
	check(ms < 400.0, "the frame the stick goes off on is bounded (%.0f ms; was 11,600)" % ms)
	check(broken > direct, "and what the holes left unsupported comes down over the frames after (%d > %d)" % [broken, direct])
	check(lab.fire._to_settle.is_empty() and lab.fire._check == null, "the settle is finished 5 s on")
	lab.queue_free()
	await physics_frames(2)


## The fire's load checks on a worker (more-cores step 8): its results come on a tick fixed by the
## count of members, so the spec saloon's stick comes down the same with the worker as without
## (`--analysis-worker=off`: the same work on the main thread, on the same ticks).
func test_the_worker_brings_it_down_the_same_as_the_main_thread() -> void:
	var results := []
	for worker in [true, false]:
		FireSystem.analysis_worker = worker
		var lab := Lab.new()
		add_child(lab)
		await physics_frames(10)
		var saloon: Structure = lab.building
		Blast.detonate(lab, Vector3(6.0, 0.8, 6.0), 0.15)
		var settled_at := -1
		for f in 400:
			await physics_frames(1)
			if settled_at < 0 and lab.fire._to_settle.is_empty() and lab.fire._check == null:
				settled_at = f
		var broken: Array = []
		for m in saloon.get_members():
			if m.broken:
				broken.append(String(m.member_id))
		broken.sort()
		results.append({"broken": broken, "settled_at": settled_at})
		lab.queue_free()
		await physics_frames(2)
	FireSystem.analysis_worker = true
	print("  worker / main thread: %d / %d broken, settled after %d / %d frames" % [results[0].broken.size(),
			results[1].broken.size(), results[0].settled_at, results[1].settled_at])
	check(results[0].broken.size() > 10, "the stick brings something down (%d)" % results[0].broken.size())
	check(results[0].broken == results[1].broken, "the same members broken with the worker as without")
	check_eq(results[0].settled_at, results[1].settled_at, "and done on the same frame")
