extends TestCase
## Falls from height (issue #759; Sean's table on #762; experiments/falls_lab/): a landing hurts by
## the height he came down from and how he lands (Falls, HumanBody._step_fall), the player too
## (PlayerWounds.take_fall), what a landing does deep inside ramps up evenly (Physiology.axial), and
## a body landing on roof boards breaks them only from a height (BodyImpacts' from-above case).

var world: Node3D


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
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


# --- The rules ---------------------------------------------------------------------------------

func test_flat_every_part_takes_its_own_stop() -> void:
	var ft := FallTuning.new()
	var out := Falls.share_out(100.0, {"a": 30.0, "b": 10.0}, {"a": 30.0}, ft, &"flat")
	check_near(float(out.a), 75.0, 0.01, "flat: by stop alone (a)")
	check_near(float(out.b), 25.0, 0.01, "flat: by stop alone (b)")


func test_head_first_the_first_part_carries_the_fall() -> void:
	var ft := FallTuning.new()
	var out := Falls.share_out(100.0, {"head": 5.0, "chest": 50.0}, {"head": 5.0}, ft, &"head")
	check_near(float(out.head), 100.0 * ft.lead_share, 0.01, "the head takes the lead share, light as it is")
	check_near(float(out.chest), 100.0 * (1.0 - ft.lead_share), 0.01, "the chest the rest")
	var feet := Falls.share_out(100.0, {"foot_l": 5.0, "thigh_l": 20.0}, {"foot_l": 5.0}, ft, &"feet")
	check_near(float(feet.foot_l), 100.0 * ft.feet_lead_share, 0.01, "feet first: his legs give")
	var alone := Falls.share_out(100.0, {"head": 5.0}, {"head": 5.0}, ft, &"head")
	check_near(float(alone.head), 100.0, 0.01, "nothing else stopped: all of it")


func test_how_he_landed() -> void:
	check_eq(Falls.landing_kind([&"head"], 1.0, {&"head": 0.1}), &"head", "head down, his middle over it")
	check_eq(Falls.landing_kind([&"foot_r", &"shin_r"], 0.9, {&"foot_r": 0.05, &"shin_r": 0.3}), &"feet", "on his feet")
	check_eq(Falls.landing_kind([&"chest", &"head"], 0.15, {&"chest": 0.12, &"head": 0.1}), &"flat", "his middle down with them: flat")


func test_the_energy_is_what_stopped() -> void:
	var ft := FallTuning.new()
	check_near(Falls.hurt_energy(80.0, 10.0, 0.0, ft), 0.5 * 80.0 * 100.0 * ft.injury_share, 0.01, "stopped dead")
	check_near(Falls.hurt_energy(80.0, 10.0, 8.0, ft), 0.5 * 80.0 * 36.0 * ft.injury_share, 0.01, "going on through: only what stopped")


func test_deep_injuries_ramp_evenly() -> void:
	var p := Physiology.new(null, Anatomy.shared())
	var rng := RandomNumberGenerator.new()
	var b: Dictionary = p.tuning.blunt
	check(p.axial(&"neck", float(b.neck) * 0.99, rng).is_empty(), "under where it starts: never")
	var hits := 0
	for i in 200:
		var q := Physiology.new(null, Anatomy.shared())
		if not q.axial(&"neck", (float(b.neck) + float(b.neck_all)) * 0.5, rng).is_empty():
			hits += 1
	check(hits > 70 and hits < 130, "half way up the ramp about half (%d of 200)" % hits)
	var torn := Physiology.new(null, Anatomy.shared())
	check(torn.axial(&"aorta", float(b.aorta_all) * 1.01, rng).has("aorta torn"), "past the top: always")
	for i in 60:
		torn.step(1.0)
	check(not torn.alive, "a torn aorta bleeds him out inside a minute (%s)" % torn.cause_of_death)
	var back := Physiology.new(null, Anatomy.shared())
	back.axial(&"spine", float(b.spine_all) * 1.01, rng)
	check(back.legs_paralysed() and back.alive, "the low back broken: his legs gone, alive")


# --- A man falling -----------------------------------------------------------------------------

## A man limp in the air at `h` (his lowest part), turned `deg` about his right (0 feet first, 180 head
## first), let go still. Returns him once he's lain `seconds`.
func _drop(h: float, deg: float, seconds := 3.0) -> HumanBody:
	var man := HumanBody.new()
	man.rng_seed = 7
	world.add_child(man)
	man.global_position = Vector3(0, h, 0)
	await physics_frames(2)
	man.go_limp(Vector3.ZERO)
	var r := Basis(Vector3.RIGHT, deg_to_rad(deg))
	var com := Vector3.ZERO
	var m := 0.0
	for rb: Variant in man.parts.values():
		com += (rb as RigidBody3D).global_position * (rb as RigidBody3D).mass
		m += (rb as RigidBody3D).mass
	com /= m
	var low := INF
	for sid: StringName in man.parts:
		var rb := man.parts[sid] as RigidBody3D
		rb.global_transform = Transform3D(r * rb.global_basis, com + r * (rb.global_position - com))
		low = minf(low, rb.global_position.y - float(man.anatomy.segments[sid].radius) - 0.06)
	for rb: Variant in man.parts.values():
		(rb as RigidBody3D).global_position += Vector3.UP * (h - low)
		(rb as RigidBody3D).linear_velocity = Vector3.ZERO
		(rb as RigidBody3D).angular_velocity = Vector3.ZERO
	await physics_frames(int(seconds * 60.0))
	return man


func test_a_man_falling_over_takes_nothing_new() -> void:
	var man := await _drop(1.0, 0.0)
	check(man.last_fall.is_empty(), "a 1 m drop isn't a fall from height")
	check(man.physiology.wounds == 0, "nothing hurt him")


func test_feet_first_from_three_metres_lives() -> void:
	var man := await _drop(3.0, 0.0)
	check_eq(man.last_fall.get("kind", &""), &"feet", "landed on his feet")
	check(float(man.last_fall.get("speed", 0.0)) > 7.0, "at the speed of the drop (%.1f)" % float(man.last_fall.get("speed", 0.0)))
	for i in 600:
		man.physiology.step(1.0)
	check(man.physiology.alive, "lives (%s)" % man.physiology.cause_of_death)


func test_head_first_from_nine_metres_kills() -> void:
	var man := await _drop(9.0, 180.0)
	check_eq(man.last_fall.get("kind", &""), &"head", "landed on his head")
	for i in 600:
		man.physiology.step(1.0)
	check(not man.physiology.alive, "dead of it")


# --- The player ----------------------------------------------------------------------------------

func test_the_player_lands_hurt_by_height() -> void:
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	await physics_frames(3)
	var w := player.wounds
	check(w.take_fall(sqrt(2.0 * 9.8 * 1.0)).is_empty() and w.physiology.wounds == 0, "a 1 m drop: nothing")
	check(w.take_fall(player.tuning.jump_velocity).is_empty() and w.physiology.wounds == 0, "a jump's landing: nothing")
	var harm := w.take_fall(sqrt(2.0 * 9.8 * 22.0))
	check(harm.has("aorta torn"), "off the Jump-off: torn inside (%s)" % ", ".join(harm))
	for i in 120:
		w.physiology.step(1.0)
	check(not w.physiology.alive, "and dead of it")


# --- Through the boards --------------------------------------------------------------------------

## Roof boards (1x8 weathered pine) across rafters 0.61 apart on two beams, their top at 3 m (the
## saloon's roof, as the falls lab's bed).
func _roof() -> Structure:
	var s: Structure = load("res://experiments/falls_lab/lab_roof.gd").new()
	s.set(&"kind", "roof")
	s.set(&"top", 3.0)
	s.structure_id = &"test_roof"
	world.add_child(s)
	return s


func _broken(s: Structure) -> int:
	var n := 0
	for m in s.get_members():
		if m.broken:
			n += 1
	return n


func test_a_roof_board_takes_a_mans_weight() -> void:
	var s := _roof()
	await physics_frames(2)
	var board := s.get_member(&"test_roof/roof_board07")
	var mid := StructuralAnalysis.geometry_of(board, s)
	# Mid-span between two rafters: ~4.3 kN breaks it there (M L / (a b)); a man of 80 kg standing on
	# it is ~0.8 kN.
	var span := BodyImpacts.span_at(s, board, board.global_position + Vector3(0.405, 0, 0))
	check(span.y - span.x > 0.5 and span.y - span.x < 0.7, "between rafters 0.61 apart (%.2f)" % (span.y - span.x))
	var at := s.global_transform * ((mid.origin as Vector3) + (mid.axis as Vector3) * ((span.x + span.y) * 0.5))
	var j := BodyImpacts.capacity_above(s, board, at)
	check_near(j / s.tuning.body_stop, 4300.0, 400.0, "its breaking load mid-span (%.0f N)" % (j / s.tuning.body_stop))


func test_lying_on_a_roof_breaks_nothing() -> void:
	var s := _roof()
	await physics_frames(2)
	var man := await _drop(3.25, 90.0, 3.0)
	check_eq(_broken(s), 0, "a man let go just over it, lying there")
	check(man.last_fall.is_empty(), "and no fall")


func test_a_man_landing_on_a_roof_from_high_breaks_boards() -> void:
	var s := _roof()
	await physics_frames(2)
	await _drop(3.0 + 6.0, 0.0, 3.0)
	check(_broken(s) > 0, "6 m onto it feet first: through the boards (%d)" % _broken(s))
