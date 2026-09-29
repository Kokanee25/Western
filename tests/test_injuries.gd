extends TestCase
## The smaller and blunter hurts: a ball that only skims leaves a furrow, not a hole; a window
## broken near someone cuts them; timber falling on a man bruises, breaks and bursts things inside
## him, and a knock on the head puts him out for a while.

var world: Node3D
var rng: RandomNumberGenerator


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
	rng = RandomNumberGenerator.new()
	rng.seed = 11
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func test_a_skimming_ball_is_a_graze() -> void:
	var a := Anatomy.shared()
	# Along the outside of the right thigh, a centimetre under the skin.
	var tr := a.trace(&"thigh_r", Vector3(0.166, 0.7, -0.4), Vector3.BACK, 475.0, 0.0057, rng)
	check(tr.graze, "a graze (%.1f cm deep)" % (tr.depth * 100.0))
	check(tr.exit != null and tr.energy_out > 350.0, "the ball goes on")
	var p := Physiology.new()
	p.apply_trace(tr)
	check(p.broken.is_empty() and p.cut.is_empty(), "nothing broken or cut deep")
	check(p.total_bleed_rate() > 0.05 and p.total_bleed_rate() < 1.5, "it bleeds a little (%.2f ml/s)" % p.total_bleed_rate())
	check(p.wound_pain > 0.1, "and stings")
	var deep := a.trace(&"thigh_r", Vector3(0.1, 0.7, -0.4), Vector3.BACK, 475.0, 0.0057, rng)
	check(not deep.graze, "straight through the middle is no graze")


func test_a_graze_in_the_world() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(2)
	var part: Node3D = man.parts[&"thigh_r"]
	var at := part.global_transform * (Vector3(0.166, 0.7, 0.0) - man.anatomy.segment_center(&"thigh_r"))
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(at + Vector3(0, 0, -5), Vector3.BACK, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	check_eq(man.wounds.size(), 1, "one wound")
	if man.wounds.size() == 1:
		check_eq(man.wounds[0].kind, &"graze", "a graze")
	check(not man.limp, "he's still on his feet")


func test_a_window_shot_out_cuts_the_man_behind_it() -> void:
	var s := Structure.new()
	s.structure_id = &"window"
	s.collapses = false
	world.add_child(s)
	var pane := s.add_member("pane", &"glass", &"glass", Vector3(1.0, 1.0, 0.004), Vector3(0, 1.4, 0))
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	man.global_position = Vector3(0, 0, 0.7)
	await physics_frames(2)
	pane.shatter(Vector3(0, 1.4, 0), Vector3.BACK)
	var cuts := man.wounds.filter(func(w: Dictionary) -> bool: return w.kind == &"cut")
	check(cuts.size() >= 1, "he's cut by the glass (%d cuts)" % cuts.size())
	check(man.physiology.total_bleed_rate() < 3.0, "cuts, not a killing wound (%.1f ml/s)" % man.physiology.total_bleed_rate())
	check(man.physiology.alive and man.physiology.is_conscious(), "he's fine, apart from that")


func test_a_blow_to_the_belly_bleeds_inside() -> void:
	var p := Physiology.new()
	var harm := p.blow(&"abdomen", 600.0, rng)
	check(p.torn.has(&"spleen") or p.torn.has(&"liver"), "something burst inside (%s)" % [harm])
	var inside := p.bleeds.filter(func(b: Dictionary) -> bool: return b.kind == &"internal")
	check(not inside.is_empty(), "bleeding inside")
	for i in 480:
		p.step(1.0)
	check(p.blood_loss() > 0.15, "he's lost blood with nothing to show (%.0f%%)" % (p.blood_loss() * 100.0))
	check(p.describe().contains("no wound"), "and it's a puzzle: %s" % p.describe())


func test_a_knock_on_the_head_puts_him_out_for_a_while() -> void:
	var p := Physiology.new()
	p.blow(&"head", 120.0, rng)
	check(not p.is_conscious(), "out cold")
	for i in 60:
		p.step(1.0)
	check(p.is_conscious(), "comes round a minute later")
	check(p.alive, "alive")


func test_light_blows_only_bruise() -> void:
	var p := Physiology.new()
	var harm := p.blow(&"chest", 30.0, rng)
	check_eq(harm, PackedStringArray(["bruised"]), "just a bruise")
	check(p.is_conscious() and p.broken.is_empty(), "no harm done")


func test_a_falling_beam_hurts_the_man_under_it() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	var s := Structure.new()
	s.structure_id = &"gallows"
	world.add_child(s)
	s.add_member("left", &"post", &"framing", Vector3(0.15, 3.0, 0.15), Vector3(-1.2, 1.5, 0))
	s.add_member("right", &"post", &"framing", Vector3(0.15, 3.0, 0.15), Vector3(1.2, 1.5, 0))
	s.add_member("beam", &"beam", &"framing", Vector3(2.6, 0.25, 0.25), Vector3(0, 3.125, 0))
	s.infer_supports()
	await physics_frames(3)
	s.break_member(s.get_member(&"gallows/left"))
	s.break_member(s.get_member(&"gallows/right"))
	var hurt := await wait_until(func() -> bool: return man.physiology.wound_pain > 0.0, 60 * 3)
	check(hurt, "the beam comes down on him")
	var blows := man.wounds.size()
	check(man.physiology.wound_pain > 0.1, "and it hurts (%s)" % man.physiology.describe())
