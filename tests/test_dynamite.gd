extends TestCase
## Dynamite: the blast's pressure and impulse by distance (Kinney-Graham), what it breaks (plank
## siding and the studs right by it, not the sills, plates or roof; panes much further out), a way
## out blown through a wall, splinters flown as projectiles,
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
	for a in [&"fire", &"cock", &"aim", &"weapon_dynamite", &"shove"]:
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


## The face's sum taken the plain way (impulse() and reflection(overpressure_kpa()) per strip, as
## face_impulse was before #538 inlined them): the same to the last bit, so the same boards break
## and are cut the same.
static func _face_reference(m: StructureMember, at: Vector3, kg: float, window := INF, center := NAN) -> float:
	var length := m.length()
	var cs := m.cross_section()
	var width := maxf(cs.x, cs.y)
	var half := length * 0.5
	var t0 := clampf((at - m.global_position).dot(m.axis()), -half, half)
	var tc := t0 if is_nan(center) else clampf(center, -half, half)
	var perp := Blast._nearest_on(m, at).distance_to(at)
	var out := Blast._out_from_face(m, at)
	var offsets := [0.0]
	for d in [0.03, 0.08, 0.15, 0.3, 0.6, 1.2, 2.4, 4.8]:
		offsets.append(d)
		offsets.append(-d)
	var ts: Array[float] = []
	for o: float in offsets:
		var t := clampf(t0 + o, -half, half)
		if not ts.has(t):
			ts.append(t)
	if tc != t0 and window < INF:
		for o: float in [0.0, -0.4, -0.15, 0.15, 0.4]:
			var t := clampf(tc + o * window, -half, half)
			if not ts.has(t):
				ts.append(t)
	ts.sort()
	var total := 0.0
	for i in ts.size():
		var lo := -half if i == 0 else (ts[i - 1] + ts[i]) * 0.5
		var hi := half if i == ts.size() - 1 else (ts[i] + ts[i + 1]) * 0.5
		if window < INF:
			lo = maxf(lo, tc - window * 0.5)
			hi = minf(hi, tc + window * 0.5)
		var seg := hi - lo
		if seg <= 0.0:
			continue
		var along := ts[i] - t0
		var r := maxf(sqrt(perp * perp + along * along), 0.02)
		var mean := 0.0
		for k in 3:
			var off := width * (k - 1) / 3.0
			var rk := sqrt(r * r + off * off)
			var square_on := clampf(out / rk, 0.0, 1.0)
			mean += Blast.impulse(kg, rk) * (1.0 + (Blast.reflection(Blast.overpressure_kpa(kg, rk)) - 1.0) * square_on)
		total += mean / 3.0 * seg * width
	return total


func test_the_face_sum_is_the_plain_one_to_the_bit() -> void:
	var store := await _store()
	var rng := RandomNumberGenerator.new()
	rng.seed = 538
	var members := store.get_members()
	var n := 0
	var most_ok := true
	for i in 120:
		var m := members[rng.randi() % members.size()]
		var at := m.global_position + Vector3(rng.randf_range(-2, 2), rng.randf_range(-1, 1), rng.randf_range(-2, 2))
		var kg := rng.randf_range(0.05, 1.5)
		if Blast.face_impulse(m, at, kg) == _face_reference(m, at, kg):
			n += 1
		var c := rng.randf_range(-1.0, 1.0)
		if Blast.face_impulse(m, at, kg, 0.3, c) == _face_reference(m, at, kg, 0.3, c):
			n += 1
		most_ok = most_ok and Blast.face_impulse(m, at, kg) <= Blast.most_face_impulse(m, at, kg) * (1.0 + 1e-9)
	check_eq(n, 240, "face_impulse is the plain sum exactly, whole and windowed (%s)" % ("native" if Blast.native else "script"))
	check(most_ok, "and never more than most_face_impulse (what KitProp skips a blast by)")


## The plugin's sums (BlastCore, #538) against the script's own: the same to the bit, so the same
## boards break and are cut the same with it or without (the web runs without).
func test_the_native_face_sum_is_the_scripts() -> void:
	if Blast.native == null:
		check(true, "no plugin here: the script's sums are the game's")
		return
	var store := await _store()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5380
	var members := store.get_members()
	var timber: TimberTuning = load("res://config/timber.tres")
	var faces := 0
	var cuts := 0
	var cut_some := 0
	var native: Object = Blast.native
	for i in 150:
		var m := members[rng.randi() % members.size()]
		var at := m.global_position + Vector3(rng.randf_range(-1.5, 1.5), rng.randf_range(-1, 1), rng.randf_range(-1.5, 1.5))
		var kg := rng.randf_range(0.05, 1.5)
		var c := rng.randf_range(-1.0, 1.0)
		var a := [Blast.face_impulse(m, at, kg), Blast.face_impulse(m, at, kg, 0.3, c), Blast.torn_stretch(m, at, kg, timber)]
		Blast.native = null
		var b := [Blast.face_impulse(m, at, kg), Blast.face_impulse(m, at, kg, 0.3, c), Blast.torn_stretch(m, at, kg, timber)]
		Blast.native = native
		faces += int(a[0] == b[0]) + int(a[1] == b[1])
		cuts += int(a[2] == b[2])
		cut_some += int((b[2] as Vector2).y > (b[2] as Vector2).x)
	check_eq(faces, 300, "the native face sum is the script's to the bit, whole and windowed")
	print("  native vs script: %d faces, %d stretches the same, %d of them torn" % [faces, cuts, cut_some])
	check_eq(cuts, 150, "and the stretch it tears out the same (%d of them a stretch)" % cut_some)


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
	check(broken_framing >= 1 and broken_framing <= 5, "the studs by it go, not the wall's framing (%d broken)" % broken_framing)
	check(report.broken.size() < store.member_count() / 4, "a hole, not the whole store (%d of %d)" % [report.broken.size(), store.member_count()])
	check(report.splinters > 0, "splinters thrown (%d)" % report.splinters)
	check_eq(booms.size(), 1, "announced")


## On a crowded street there are thousands of things in a stick's reach: what's beside it is still
## looked at (it was left out once, the breakage lab, 2026-10-21) and the panes far off still are.
func test_a_crowded_street_doesnt_hide_whats_beside_it() -> void:
	var store := await _store()
	for i in 4:
		var other := FalseFrontBuilding.new()
		other.structure_id = StringName("other%d" % i)
		other.build_seed = 20 + i
		world.add_child(other)
		other.position = Vector3(-11.0 if i % 2 == 0 else 11.0, 0.0, -11.0 if i < 2 else 0.0)
	await physics_frames(2)
	var siding := _side_board(store)
	var at := _outside(store, siding, 0.25)
	var shape := SphereShape3D.new()
	shape.radius = Blast.reach(0.15)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY, at)
	q.collision_mask = Layers.WORLD | Layers.DEBRIS | Layers.BODY_PARTS
	var in_reach := world.get_world_3d().direct_space_state.intersect_shape(q, 1 << 16).size()
	check(in_reach > 1024, "a crowded street: %d things in reach, more than the old query took" % in_reach)
	var looked := Blast.gather(world, at, 0.15)
	check(siding in looked, "the board beside it is looked at")
	var near := 0
	var missed := 0
	for m in store.get_members():
		if Blast._nearest_on(m, at).distance_to(at) <= 1.0:
			near += 1
			if not m in looked:
				missed += 1
	check_eq(missed, 0, "nothing within a metre left out (of %d)" % near)
	var panes := 0
	for s: Node in world.get_children():
		if s is Structure:
			for m in (s as Structure).panes():
				if Blast._nearest_on(m, at).distance_to(at) <= Blast.reach(0.15):
					panes += 1
					check(m in looked, "a pane in reach is looked at (%s)" % m.member_id)
	check(panes > 4, "panes across the street in reach (%d)" % panes)
	var report := Blast.detonate(world, at, 0.15)
	check(siding.broken, "and the board beside it goes (%d broken)" % report.broken.size())


## cut, not whole boards gone): a hole to crawl through, at least. Three in a bundle: a way to walk out.
## cut, not whole boards gone): a hole to crawl through. Three in a bundle: a way to walk out.
func test_a_stick_inside_against_the_wall_blows_a_way_out() -> void:
	var store := await _store()
	# 3 m toward the front (five stud bays): the bare wall, clear of the store's shelves (the prop
	# kit's: a stick by them throws them into the hole and widens it).
	var at := _inside_wall_foot(store, -3.0)
	var report := Blast.detonate(world, at, Blast.t().tnt_per_stick)
	var kinds := {}
	for id: StringName in report.broken:
		var m := store.get_member(id)
		if m:
			kinds[m.kind] = kinds.get(m.kind, 0) + 1
	print("  a stick inside against the wall: %s" % kinds)
	check(kinds.get(&"stud", 0) >= 2, "the studs either side of it are broken (%d)" % kinds.get(&"stud", 0))
	for k: StringName in [&"sill", &"plate", &"rafter", &"ridge", &"post"]:
		check_eq(kinds.get(k, 0), 0, "no %s broken: the building stands round the hole" % k)
	var cut := 0
	var whole := 0
	for m in store.get_members():
		if m.broken and m.kind == &"board" and String(m.member_id).contains("left/siding"):
			if m.has_meta(&"cut"):
				cut += 1
			else:
				whole += 1
	check(cut >= 3 and whole == 0, "the boards are holed, not gone whole (%d cut, %d whole)" % [cut, whole])
	await physics_frames(120)
	check(_way_through(store, at, 0.6), "a hole in the wall a man can crawl through")
	# Not checked since the ground counts (#220, a stick on the floor hits as ~1.4-1.8 of its TNT):
	# that it isn't one he walks through upright. Along this wall one stick now blows a full-height
	# slot at 5 spots in 8 and a ~1.4 m hole at the rest (before: 4 in 8, and 1.0-1.3 m holes); Sean's
	# call on it is #484 (experiments/body_lab/results/2026-10-28_dynamite_c/README.md).


func test_a_bundle_inside_against_the_wall_blows_a_door() -> void:
	var store := await _store()
	var at := _inside_wall_foot(store)
	Blast.detonate(world, at, Blast.t().tnt_per_stick * 3.0)
	await physics_frames(120)
	check(_way_through(store, at, 1.3), "three sticks: a hole a man can walk through")
	# (Three sticks in a room this size take some of the rafters over it too.)
	for m in store.get_members():
		if m.kind in [&"sill", &"plate"]:
			check(not m.broken, "the walls stand round it (%s)" % m.member_id)


## On the floor against the inside of the side wall, between two studs.
func _inside_wall_foot(store: FalseFrontBuilding, along := 0.0) -> Vector3:
	var siding := _side_board(store)
	return Vector3(0.02, store.floor_top + DynamiteStick.RADIUS, siding.global_position.z + along)


## A way through the wall by the charge: half a metre wide and `tall` from just over the floor,
## clear of anything standing (loose rubble is pushed aside).
func _way_through(store: FalseFrontBuilding, at: Vector3, tall: float) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, tall, 0.5)
	q.shape = box
	q.collision_mask = Layers.WORLD
	for k in range(-10, 11):
		q.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, store.floor_top + 0.07 + tall * 0.5, at.z + k * 0.05))
		var standing := world.get_world_3d().direct_space_state.intersect_shape(q, 8).filter(
				func(h: Dictionary) -> bool: return not h.collider is RigidBody3D)
		if standing.is_empty():
			return true
	return false


func test_on_its_sill_it_leaves_the_wall_standing() -> void:
	var store := await _store()
	# On the ground outside, against the sill: a charge like this cuts the sill, but it still lies
	# on its footing and carries the wall.
	var siding := _side_board(store)
	var report := Blast.detonate(world, Vector3(-0.045, 0.02, siding.global_position.z), Blast.t().tnt_per_stick)
	var heavy := (report.broken as Array).filter(func(id: StringName) -> bool:
		var m := store.get_member(id)
		return m != null and m.kind in [&"sill", &"plate", &"rafter", &"roof_board"])
	check_eq(heavy.size(), 0, "the sill holds and the roof stays up (%s)" % [heavy])


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


func test_it_lights_nothing_itself() -> void:
	# Sean, 2026-10-28: dry siding in the flash, four sticks, and nothing catches; a fire after a
	# blast comes from a lamp it smashed (test_glass_props).
	var store := await _store()
	var fire := FireSystem.new()
	world.add_child(fire)
	await physics_frames(1)
	var siding := _side_board(store)
	for k in 4:
		Blast.detonate(world, _outside(store, siding, 0.3) + Vector3.UP * 0.4 * k, 0.15)
		await physics_frames(1)
	fire.step(Blast.t().ignite_delay.y + 0.1)
	check_eq(fire.burning_members().size(), 0, "no wood alight after the flash")
	check_eq(fire.spills.size(), 0, "and nothing burning on the ground")


## On the ground a charge blasts a hemisphere: it hits as 1.8 times its TNT, fading to its own by a
## third of a metre up (#220, Sean's option c).
func test_on_the_ground_it_hits_harder() -> void:
	var kg := Blast.t().tnt_per_stick
	check_near(Blast.ground_share(kg, 0.0), 1.8, 0.001, "lying on the ground: x1.8")
	check_near(Blast.ground_share(kg, 1.2), 1.0, 0.001, "held at the chest: its own")
	check_near(Blast.ground_share(kg, INF), 1.0, 0.001, "nothing under it: its own")
	var report := Blast.detonate(world, Vector3(0, DynamiteStick.RADIUS, 0), kg)
	check(float(report.kg) > kg * 1.7, "a stick on the dirt hits as %.2f kg" % float(report.kg))
	var high := Blast.detonate(world, Vector3(10, 1.5, 0), kg)
	check_near(float(high.kg), kg, 0.001, "one going off 1.5 m up hits as its own")
	check_eq(booms[0][1], report.kg, "the town hears the blast as it hit")
	# What faces it takes the reflected pressure: 2x weak, toward 8x strong.
	check_near(Blast.reflected_kpa(1.0), 2.0, 0.05, "a weak shock: twice")
	check(Blast.reflected_kpa(1000.0) > 5.0 * 1000.0, "a strong one: more than five times")


# --- People -------------------------------------------------------------------------------------------

## A stick lying on the ground a metre in front of him (Sean's pick, #220, the body lab's
## results/2026-10-28_dynamite_c/): his feet go, his lungs are bruised, his eardrums burst.
func test_a_stick_on_the_ground_a_metre_off_takes_his_feet() -> void:
	var man := await _man(Vector3.ZERO)
	Blast.detonate(world, Vector3(0, 0.05, -1.0), Blast.t().tnt_per_stick)
	var p := man.physiology
	check(p.severed_segments.has(&"foot_r") and p.severed_segments.has(&"foot_l"), "both feet gone (%s)" % str(p.severed_segments.keys()))
	check(not p.severed_segments.has(&"thigh_r") and not p.severed_segments.has(&"thigh_l"), "his thighs left")
	check_eq(p.eardrums_burst.size(), 2, "both eardrums")
	check(" ".join(man.describe_wounds()).contains("lungs bruised"), "lungs bruised: %s" % "; ".join(man.describe_wounds()))


func test_five_metres_off_on_his_feet() -> void:
	var man := await _man(Vector3.ZERO)
	Blast.detonate(world, Vector3(0, 0.05, -5.5), Blast.t().tnt_per_stick)
	check(man.physiology.severed_segments.is_empty() and not man.limp, "whole and standing at 5.5 m")



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


## Where a stick's chest wounds end (docs/briefs/blast-surfaces.md, "What a stick does to people"):
## the distance from the charge to the skin at which the reflected pressure falls to `kpa`.
func _radius(kg: float, kpa: float) -> float:
	var lo := 0.02
	var hi := 100.0
	for i in 60:
		var mid := (lo + hi) * 0.5
		if Blast.reflected_kpa(Blast.overpressure_kpa(kg, mid)) > kpa:
			lo = mid
		else:
			hi = mid
	return lo


## The stick's people radii as the brief states them: lungs bruised within 1.7 m of the chest's
## skin, torn within 1.3 m, eardrums from 5.0 m in (a 0.2 kg stick on the ground, 1.8x).
func test_a_sticks_radii_are_the_briefs() -> void:
	var bt := Blast.t()
	var kg := bt.tnt_per_stick * bt.ground_factor
	check_near(_radius(kg, bt.lung_kpa), 1.7, 0.05, "lungs bruised within 1.7 m")
	check_near(_radius(kg, bt.lung_severe_kpa), 1.3, 0.05, "lungs torn within 1.3 m")
	check_near(_radius(kg, bt.eardrum_kpa), 5.0, 0.1, "eardrums from 5 m")


## A stick on the street (#488: every townsperson in its reach was logged "hit (chest)"): no chest
## is wounded beyond its injury radius, and a man it does nothing to has no wound and no hit; the
## one by it has both.
func test_a_stick_on_the_street_wounds_no_chest_beyond_its_radius() -> void:
	var bt := Blast.t()
	var radius := _radius(bt.tnt_per_stick * bt.ground_factor, bt.lung_kpa)
	var men: Array[HumanBody] = []
	# A fan of men round it, none in another's way: 1, 3, 6, 10 and 17 m off.
	var offs := [1.0, 3.0, 6.0, 10.0, 17.0]
	for k in offs.size():
		var a := TAU * k / offs.size()
		men.append(await _man(Vector3(sin(a), 0.0, cos(a)) * float(offs[k])))
	var hits := {}
	var on_hit := func(info: Dictionary) -> void: hits[info.get("person")] = info.get("harm")
	Events.body_hit.connect(on_hit)
	Blast.detonate(world, Vector3(0, 0.05, 0), bt.tnt_per_stick)
	Events.body_hit.disconnect(on_hit)
	for man in men:
		var chest := (man.parts[&"chest"] as Node3D).global_position
		var lungs := " ".join(man.describe_wounds()).contains("lungs")
		var away := chest.distance_to(Vector3(0, 0.05, 0))
		var blasted := man.wounds.filter(func(w: Dictionary) -> bool: return w.kind == &"blast")
		if away > radius + 0.3:
			check(not lungs, "no chest wound %.1f m off" % away)
		if blasted.is_empty():
			check(not hits.has(man), "unhurt %.1f m off, so no hit (%s)" % [away, str(hits.get(man))])
		else:
			check(hits.has(man) and not (hits[man] as PackedStringArray).is_empty(), "a blast wound %.1f m off is its harm, hit" % away)
	var far := men.slice(3)
	for man: HumanBody in far:
		check(man.wounds.is_empty() and not hits.has(man), "nothing at all %.0f m off" % man.global_position.length())
	check(hits.has(men[0]), "the man a metre off is hit (%s)" % str(hits.get(men[0])))


## You, a stick going off 12 m away: ringing, no wound, no hit (#488).
func test_a_stick_across_the_street_isnt_a_hit_on_you() -> void:
	var player := await _player()
	var hits := []
	var on_hit := func(info: Dictionary) -> void: hits.append(info)
	Events.body_hit.connect(on_hit)
	Blast.detonate(world, player.global_position + Vector3(12.0, 0.05, 0.0), Blast.t().tnt_per_stick)
	Events.body_hit.disconnect(on_hit)
	check(hits.is_empty(), "no hit on you (%s)" % str(hits))
	check(player.wounds.wounds.is_empty(), "no wound")


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


## The blast throws him along its own way out from the charge, with nothing added (it had a lift
## of a third again upward on top: experiments/physics_lab, 2026-10-21).
func test_the_blast_pushes_him_along_its_line() -> void:
	var man := await _man(Vector3.ZERO)
	var chest := (man.parts[&"chest"] as Node3D).global_position
	# Level with his chest, a metre and a bit in front: the wind is level.
	man.take_blast(chest + Vector3(0, 0, -1.1), 0.15)
	check(man.limp, "thrown down")
	var v := (man.parts[&"chest"] as RigidBody3D).linear_velocity
	print("  chest thrown at (%.2f, %.2f, %.2f) m/s" % [v.x, v.y, v.z])
	check(v.z > 0.5, "away from the charge (%.2f m/s)" % v.z)
	check(absf(v.y) < v.z * 0.15, "and not lifted (%.2f up, %.2f away)" % [v.y, v.z])


## A limb torn off goes with what tore it off, and no spin is thrown in.
func test_a_torn_off_limb_isnt_spun() -> void:
	var man := await _man(Vector3.ZERO)
	man.sever_limb(&"forearm_r")
	var w := (man.parts[&"forearm_r"] as RigidBody3D).angular_velocity.length()
	check(w < 1.0, "no spin thrown in (%.2f rad/s)" % w)
	check(man.limp, "he's down")


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


# --- Planted at a wall's foot (#506: hold E by a wall, lit when you let go) -------------------------

## The player in the store, `off` m in from its side wall, facing it and looking `pitch` degrees
## (down is less than 0), the stick in hand.
func _facing_wall(off: float, pitch: float) -> Array:
	var store := await _store()
	var player := await _player()
	var board := _side_board(store)
	player.global_position = Vector3(off, store.floor_top + 0.05, board.global_position.z - 3.0)
	player.rotation.y = PI * 0.5  # -Z turned to -X: at the wall
	player.add_look(Vector2(0.0, pitch - player.get_pitch_degrees()), false)
	await physics_frames(10)
	return [store, player]


func _key(down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = &"shove"
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _sticks() -> Array:
	return get_tree().get_nodes_in_group(&"dynamite").filter(func(n: Node) -> bool: return n is DynamiteStick and not n.is_queued_for_deletion())


func test_held_by_a_wall_it_plants_and_lights_on_letting_go() -> void:
	var r := await _facing_wall(0.9, -35.0)
	var store: FalseFrontBuilding = r[0]
	var player: Player = r[1]
	var d := player.dynamite()
	check(d.claims_use(), "a wall in reach: E is the stick's")
	var sticks := d.sticks
	var hisses := []
	var on_noise := func(at: Vector3, _l: float, kind: StringName, _s: Node) -> void:
		if kind == &"fuse":
			hisses.append(at)
	Events.noise.connect(on_noise)
	_key(true)
	await physics_frames(int(Blast.t().plant_time * 60.0) + 6)
	var set_down := _sticks()
	check_eq(set_down.size(), 1, "a stick set down")
	check_eq(player.shove.move, &"", "no shove or kick")
	check(player.shove.holding < 0.0, "nor one wound up")
	if set_down.size() == 1:
		var s: DynamiteStick = set_down[0]
		check(not s.lit, "unlit while you hold the key")
		check(s.planted, "planted, not thrown")
		var aim := _aimed(player)
		check(s.global_position.distance_to(aim) < 0.03, "where you aimed (%s, aimed %s)" % [s.global_position, aim])
		check(aim.y > store.floor_top + 0.6, "up the wall, not at its foot (%.2f)" % aim.y)
		check(absf(s.global_basis.z.normalized().y) < 0.2 or absf(s.global_basis.z.normalized().y) > 0.95, "lying along the board or the stud")
		check_eq(d.sticks, sticks - 1, "one fewer in hand")
		await physics_frames(30)
		check(not s.lit, "still unlit, key down")
		check(s.global_position.distance_to(aim) < 0.03, "held there, not fallen")
		_key(false)
		await physics_frames(3)
		check(s.lit, "lit as the key comes up")
		check_near(s.fuse_left, Blast.t().plant_fuse_seconds, 0.2, "a fuse to get round a corner")
		await physics_frames(70)
		check(not hisses.is_empty(), "its hiss is a noise men hear (%d)" % hisses.size())
		await wait_until(func() -> bool: return not booms.is_empty(), int(Blast.t().plant_fuse_seconds * 60.0) + 30)
		check_eq(booms.size(), 1, "and it goes")
	Events.noise.disconnect(on_noise)


func test_let_go_too_soon_sets_nothing() -> void:
	var r := await _facing_wall(0.9, -35.0)
	var player: Player = r[1]
	var sticks := player.dynamite().sticks
	_key(true)
	await physics_frames(int(Blast.t().plant_time * 30.0))
	_key(false)
	await physics_frames(20)
	check(_sticks().is_empty(), "nothing set down")
	check_eq(player.dynamite().sticks, sticks, "still in hand")
	check_eq(player.shove.move, &"", "and no shove either")


## Where the player's eye line meets the store, a stick's radius out from it.
func _aimed(player: Player) -> Vector3:
	var cam := player.camera
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_basis.z * 3.0, Layers.WORLD)
	q.exclude = [player.get_rid()]
	var hit := world.get_world_3d().direct_space_state.intersect_ray(q)
	return (hit.position as Vector3) + (hit.normal as Vector3) * (DynamiteStick.RADIUS + 0.003) if not hit.is_empty() else Vector3.INF


func test_it_goes_where_you_aim() -> void:
	var store := await _store()
	var space := world.get_world_3d().direct_space_state
	var z := _side_board(store).global_position.z - 3.0
	var eye := Vector3(1.0, store.floor_top + 1.6, z)
	# The wall high and low, the floor in front of it.
	for look: Vector3 in [Vector3(-1, -0.1, 0), Vector3(-1, -1.4, 0), Vector3(-0.3, -1, 0)]:
		var spot := DynamiteViewmodel.plant_spot(space, eye, look, 2.2)
		check(not spot.is_empty(), "a spot looking %s" % look)
		if spot.is_empty():
			continue
		var q := PhysicsRayQueryParameters3D.create(eye, eye + look.normalized() * 2.2, Layers.WORLD)
		var hit := space.intersect_ray(q)
		check((spot.at as Vector3).distance_to(hit.position) < 0.02, "right where the line meets it (%s)" % look)
	# A stud: up it, along it.
	var stud: StructureMember = null
	for m in store.get_members():
		if m.kind == &"stud" and String(m.member_id).contains("left/stud") and absf(m.global_position.z - z) < 1.5:
			stud = m
			break
	check(stud != null, "a stud by you")
	if stud:
		var at := stud.global_position + Vector3(0.3, 0.0, 0.0)
		var spot := DynamiteViewmodel.plant_spot(space, at + Vector3(0.6, 0.0, 0.0), Vector3(-1, 0, 0), 2.2)
		check(not spot.is_empty() and spot.collider == stud, "on the stud (%s)" % [spot.get("collider")])
		if not spot.is_empty():
			check(absf((spot.basis as Basis).z.y) > 0.95, "lying up it")
	check(DynamiteViewmodel.plant_spot(space, eye, Vector3(1, -0.2, 0), 1.6).is_empty(), "nothing that way in reach")
	# A man in front: no spot (E is the shove).
	await _man(Vector3(0.45, store.floor_top, z))
	check(DynamiteViewmodel.plant_spot(space, eye, Vector3(-1, -0.4, 0), 2.2).is_empty(), "not through a man")


func test_on_a_stud_until_the_stud_goes() -> void:
	var store := await _store()
	var stud: StructureMember = null
	for m in store.get_members():
		if m.kind == &"stud" and String(m.member_id).contains("left/stud"):
			stud = m
			break
	var s := DynamiteStick.make(world, stud.global_position + Vector3(0.1, 0.4, 0.0))
	s.stick_to(stud)
	await physics_frames(30)
	check_near(s.global_position.y, stud.global_position.y + 0.4, 0.01, "held on the stud")
	(stud.get_parent() as Structure).break_member(stud)
	await physics_frames(40)
	check(not s.freeze, "let go when the stud breaks")
	check(s.global_position.y < stud.global_position.y + 0.3, "and it falls (%.2f)" % s.global_position.y)


func test_aimed_at_nothing_in_reach_e_is_still_the_shove() -> void:
	var player := await _player()
	player.add_look(Vector2(0.0, -20.0 - player.get_pitch_degrees()), false)
	await physics_frames(5)
	check(not player.dynamite().claims_use(), "nothing to set it against")
	_key(true)
	await physics_frames(3)
	check(player.shove.holding >= 0.0 or player.shove.move != &"", "E winds up the shove")
	_key(false)
	await physics_frames(3)
	check(_sticks().is_empty(), "no stick set down")


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
	# From the walk, a couple of paces from the front beside the door: it lands at the wall and
	# breaks what's there. (Whether the siding goes turns on where it comes to rest, a hand's breadth
	# either way: by the contact order of every body in the street, 0 to 23 timber in trials; the
	# siding's own test is test_a_stick_by_the_wall_blows_a_hole_in_the_siding. Thrown from the street
	# it ended up against the walk's edge, on the porch roof or at the door.)
	var store := street.get_node(^"Store") as FalseFrontBuilding
	player.global_position = store.to_global(Vector3(store.door_rect.get_center().x - 1.6, store.floor_top, -1.8))
	player.rotation = Vector3(0, PI, 0)
	await physics_frames(5)
	var broken := []
	var on_broken := func(id: StringName) -> void: broken.append(id)
	Events.member_broken.connect(on_broken)
	await _throw_from(player, 0.3)
	await wait_until(func() -> bool: return not booms.is_empty(), 500)
	Events.member_broken.disconnect(on_broken)
	check(not booms.is_empty(), "it went off")
	if booms.is_empty():
		return
	var at := store.to_local(booms[0][0])
	print("  thrown at the store: went off %.2f m off its front, %d broken" % [-at.z, broken.size()])
	check(at.z > -1.2 and at.z < 0.3 and at.x > 0.0 and at.x < store.width, "it lands at the store's front (%s)" % at)
	check(broken.size() >= 3, "it breaks things where it lands (%d)" % broken.size())
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
