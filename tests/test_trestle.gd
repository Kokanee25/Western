extends TestCase
## The timber viaduct (the trestle lab, #623; src/train/trestle.gd): it's built from the route's
## crossing and the ground under it, stands under its own weight at rest, carries the train across
## with nothing failing, falls by its load paths when its posts are cut, a light charge leaves it
## standing empty and the engine's weight finishes it, the train goes with it keeping its momentum,
## and a save keeps the wreck.

const LAB_LINE := preload("res://experiments/trestle_lab/lab_line.gd")

var world: Node3D
var tuning: TrainTuning


func before_each() -> void:
	tuning = load("res://config/train.tres")
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _line(with_train := false) -> TrackLine:
	return LAB_LINE.build(world, tuning, LAB_LINE.ROUTE, null, "start", with_train)


func test_the_viaduct_is_built_and_stands() -> void:
	var line := _line()
	check_eq(line.trestles.size(), 1, "the route's crossing is a Trestle")
	var tr: Trestle = line.trestles[0]
	var rep := tr.report()
	print("  trestle: %s" % [rep])
	check(float(rep.tallest) > 60.0 and float(rep.tallest) < 76.0, "60-75 m at the middle (%.1f)" % float(rep.tallest))
	check(float(rep.length) > 250.0, "250-350 m long (%.0f)" % float(rep.length))
	check(tr.members_without_load_path().is_empty(), "every member has a load path to the ground")
	var a := StructuralAnalysis.new(tr.tuning).analyse(tr)
	var worst := ""
	var u := 0.0
	for id in a.utilisation:
		if float(a.utilisation[id]) > u:
			u = float(a.utilisation[id])
			worst = String(id)
	print("  worst under its own weight: %s %.3f (%s)" % [worst, u, a.mode.get(StringName(worst), "")])
	check(a.overloaded().is_empty(), "nothing overloaded under its own weight")
	var broke := tr.settle()
	check(broke.is_empty(), "nothing breaks under its own weight (%d)" % broke.size())
	var resting := 0
	for m in tr.get_members():
		if m.resting():
			resting += 1
	check_eq(resting, tr.member_count(), "every member at rest in its batch")


## The middle (tallest) bent.
func _mid(tr: Trestle) -> Dictionary:
	var best: Dictionary = tr.bents[0]
	for b in tr.bents:
		if float(b.height) > float(best.height):
			best = b
	return best


## Every post of a bent's bottom story cut outright (what a big enough charge does).
func _cut_bottom(tr: Trestle, bent: Dictionary) -> void:
	var st: Dictionary = (bent.stories as Array).back()
	var posts: Array[StructureMember] = []
	var pushes: Array[Vector3] = []
	for p: StructureMember in st.posts:
		posts.append(p)
		pushes.append(Vector3.ZERO)
	tr.break_members(posts, pushes)


## The train standing with its engine's middle at s (its loads put on: every panel, sound or not).
func _stand(line: TrackLine, tr: Trestle, s: float, everywhere := false) -> Train:
	var train := Train.new()
	train.name = "Train"
	line.add_child(train)
	train.setup(line, tuning)
	var c0: Dictionary = train.sim.cars[0]
	train.place(s + (float(c0.trucks.x) + float(c0.trucks.y)) * 0.5)
	tr.only_weak = not everywhere
	for k in tr.tt.load_every:
		tr.carry(train)
	return train


func _worst(tr: Trestle, kinds: Array) -> Array:
	var a := StructuralAnalysis.new(tr.tuning).analyse(tr)
	var u := 0.0
	var id := &""
	for k in a.utilisation:
		var m := tr.get_member(k)
		if m and (kinds.is_empty() or m.kind in kinds) and float(a.utilisation[k]) > u:
			u = float(a.utilisation[k])
			id = k
	return [u, id, a.mode.get(id, &"")]


## On a sound deck the engine and its tender can't break anything, wherever they stand: the full
## analysis with the train's weight everywhere (no shortcut) leaves the hardest-worked member under
## half its strength, and the bents under it under a tenth. That's why only the weakened panels
## take the train's weight into the analysis as it crosses (Trestle.only_weak) and an intact bent's
## posts aren't worked out again under a moving load (closure_stop): neither changes what breaks.
func test_a_sound_deck_carries_the_train_anywhere() -> void:
	var line := _line()
	var tr: Trestle = line.trestles[0]
	tr.settle()
	var mid := _mid(tr)
	var worst := 0.0
	var worst_bent := 0.0
	var what := ""
	for off in [-2.44, -1.2, 0.0, 1.2, 2.44]:
		var train := _stand(line, tr, float(mid.s) + float(off), true)
		var w := _worst(tr, [])
		var wb := _worst(tr, [&"post", &"bent_sill"])
		if float(w[0]) > worst:
			worst = float(w[0])
			what = "%s %s" % [w[1], w[2]]
		worst_bent = maxf(worst_bent, float(wb[0]))
		check(tr.settle().is_empty(), "nothing breaks with the engine at %+.1f m from the tallest bent" % float(off))
		train.free()
		for d: Dictionary in tr.stringers:
			(d.member as StructureMember).extra_points = PackedVector2Array()
	print("  under the engine: worst %.3f (%s), the bent's posts and sills %.3f" % [worst, what, worst_bent])
	check(worst < 0.5, "the hardest-worked member under half its strength (%.3f)" % worst)
	check(worst_bent < 0.1, "the bent's posts and sills under a tenth (%.3f)" % worst_bent)


## Cut every post of the tallest bent's bottom story: the support graph brings down everything
## above the cut in that bent (its stories, its cap); the stringers over it hold, the chords that
## span it now twice as far and those jointed on its cap as cantilevers off the next bent (their
## other end still on two caps), so the deck holds empty: no rail gone, everything left has a load
## path, the next bent stands.
func test_cut_posts_fall_by_the_load_paths_and_the_deck_holds_empty() -> void:
	var line := _line()
	var tr: Trestle = line.trestles[0]
	tr.settle()
	var mid := _mid(tr)
	_cut_bottom(tr, mid)
	tr.settle()
	await physics_frames(2)
	check((mid.cap as StructureMember).broken, "the bent's cap came down with it")
	var all_gone := true
	for st: Dictionary in mid.stories:
		for p: StructureMember in st.posts:
			all_gone = all_gone and p.broken
	check(all_gone, "every story of the bent above the cut fell")
	var over := 0
	for d: Dictionary in tr.stringers:
		if int(d.u) < int(mid.index) and int(d.v) > int(mid.index):
			over += 1
		if int(d.u) <= int(mid.index) and int(d.v) >= int(mid.index):
			check(not (d.member as StructureMember).broken, "a stringer over the cut bent holds empty (%s)" % (d.member as StructureMember).member_id)
	check_eq(over, 2, "one chord a rail spans the cut bent")
	for r: Dictionary in tr.rails:
		check(not (r.member as StructureMember).broken, "the rails stay")
	check(tr.members_without_load_path().is_empty(), "everything left has a load path")
	var neighbour: Dictionary = tr.bents[tr.bents.find(mid) + 1]
	check(not (neighbour.cap as StructureMember).broken, "the next bent stands")
	check(line.state.first_ahead(tr.from_s, 1, tr.to_s - tr.from_s).is_empty(), "the line's state calls the deck sound (empty)")


## The train coming on at `kmh` from `back` m short of s.
func _coming(line: TrackLine, s: float, back: float, kmh: float) -> Train:
	var train := Train.new()
	train.name = "Train"
	line.add_child(train)
	train.setup(line, tuning)
	train.place(s - back)
	train.sim.set_speed(kmh / 3.6)
	return train


## A light charge's work (the tallest bent's two inner bottom posts cut): it stands empty, two posts
## gone and nothing else; the engine rolling onto it brings the bent down under it, the deck goes,
## and the train leaves the rails there (the bridge's own way: kind `fell`).
func test_a_light_charge_holds_empty_and_the_engine_finishes_it() -> void:
	var line := _line()
	var tr: Trestle = line.trestles[0]
	tr.settle()
	var mid := _mid(tr)
	var st: Dictionary = (mid.stories as Array).back()
	var posts: Array = st.posts
	var n := posts.size()
	var inner: Array[StructureMember] = [posts[n / 2 - 1], posts[n / 2]]
	tr.break_members(inner, [Vector3.ZERO, Vector3.ZERO] as Array[Vector3])
	tr.settle()
	await physics_frames(10)
	var broken := 0
	for m in tr.get_members():
		if m.broken:
			broken += 1
	check_eq(broken, 2, "empty, only the two posts are gone")
	check(not (mid.cap as StructureMember).broken, "the bent stands empty")
	var train := _coming(line, float(mid.s), 60.0, 15.0)
	var ok := await wait_until(func() -> bool: return not train.derail.is_empty(), 60 * 30)
	check(ok, "the train leaves the rails on the bridge")
	if ok:
		check_eq(String(train.derail.kind), "fell", "the deck went from under it")
		check_near(float(train.derail.s), float(mid.s), 12.0, "where the bent was (%.1f of %.1f)" % [float(train.derail.s), float(mid.s)])
	check((mid.cap as StructureMember).broken, "the engine's weight brought the bent down")


## Three bents side by side cut: the deck over them falls empty (two leave a bare panel ~5-9 m long,
## cantilevers either side, that the 9.4 m engine can bridge at speed; the lab's runs have it); the
## train coming on at 30 km/h goes off the end, handed to its bodies at its speed (momentum kept),
## and its engine goes down into the gorge.
func test_the_train_goes_down_with_its_momentum() -> void:
	var line := _line()
	var tr: Trestle = line.trestles[0]
	tr.settle()
	var mid := _mid(tr)
	var i := tr.bents.find(mid)
	for k in 3:
		_cut_bottom(tr, tr.bents[i + k])
	tr.settle()
	await physics_frames(60 * 5)
	check(not line.state.first_ahead(tr.from_s, 1, tr.to_s - tr.from_s).is_empty(), "the deck over them is gone (empty)")
	var train := _coming(line, float(mid.s), 70.0, 30.0)
	var p1d := [0.0]
	train.derailed.connect(func(_i: Dictionary) -> void:
		var p := Vector3.ZERO
		var m := 0.0
		for b: Dictionary in train.wreck.bodies:
			var rb := b.body as RigidBody3D
			p += rb.linear_velocity * rb.mass
			m += rb.mass
		p1d[0] = p.length() / m)
	var ok := await wait_until(func() -> bool: return not train.derail.is_empty(), 60 * 20)
	check(ok, "it goes off the end of the deck")
	if not ok:
		return
	check_eq(String(train.derail.kind), "fell", "the bridge's hand-off")
	check_near(float(p1d[0]), float(train.derail.kmh) / 3.6, 0.6, "handed over at its speed (%.2f m/s of %.2f)" % [float(p1d[0]), float(train.derail.kmh) / 3.6])
	await physics_frames(60 * 6)
	var deck_y := line.point_at(float(mid.s)).y
	var down := 0
	for k in train.wreck.bodies.size():
		var rb := train.wreck.body(k)
		if rb != null and (line.global_transform.affine_inverse() * rb.global_position).y < deck_y - 20.0:
			down += 1
	check(down >= 1, "the engine's gone down into the gorge (%d bodies below the deck)" % down)


## A save keeps the wreck: the bridge built again and the save put back has the same members broken,
## its rubble where it lay, and nothing more falls.
func test_a_save_keeps_the_bridge_wreck() -> void:
	var line := _line()
	var tr: Trestle = line.trestles[0]
	tr.settle()
	_cut_bottom(tr, _mid(tr))
	tr.settle()
	await physics_frames(60 * 4)
	var d := tr.save_dict()
	var was := (d.broken as Array).duplicate()
	was.sort()
	var pieces := (d.rubble as Array).size()
	check(was.size() > 50 and pieces > 0, "something to keep (%d broken, %d pieces)" % [was.size(), pieces])
	var json: Dictionary = JSON.parse_string(JSON.stringify(d))
	line.free()
	await physics_frames(2)
	var again := _line()
	var tr2: Trestle = again.trestles[0]
	var missed := tr2.restore_dict(json)
	check_eq(missed, 0, "every member found")
	tr2.settle()
	await physics_frames(10)
	var now := (tr2.save_dict().broken as Array).duplicate()
	now.sort()
	check_eq(now, was, "the same members broken, and nothing more fell")
	var alive := 0
	for rb in tr2.rubble:
		if is_instance_valid(rb):
			alive += 1
	check(alive > 0 and alive <= pieces, "its rubble put back (%d of %d pieces)" % [alive, pieces])
	# Each restored piece against where the save had the piece its first member was in (a member
	# snapped in two lies whole where its first half lay: half its length off, so the median).
	var saved_at := {}
	for p: Dictionary in d.rubble:
		for path in p.members:
			if not saved_at.has(path):
				saved_at[path] = Vector3(p.origin[0], p.origin[1], p.origin[2])
	var offs: Array[float] = []
	var prefix := String(tr2.structure_id) + "/"
	for rb in tr2.rubble:
		if not is_instance_valid(rb):
			continue
		var ids: Array = rb.get_meta(&"members", [])
		var key := String(ids[0]).trim_prefix(prefix) if not ids.is_empty() else ""
		if saved_at.has(key):
			offs.append((tr2.crossing_frame().affine_inverse() * rb.global_position).distance_to(saved_at[key]))
	offs.sort()
	var median := offs[offs.size() / 2] if not offs.is_empty() else INF
	check(median < 0.25, "its pieces where they lay (median %.2f m off, %d pieces)" % [median, offs.size()])

