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


## Going limp swaps his parts for rigid bodies the space doesn't hold until it next steps: a ball
## flown that same tick (a blast's gravel, the rest of a charge) passed through him
## (experiments/body_lab, same_tick).
func test_a_ball_on_the_tick_he_goes_limp_still_hits_him() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(10)
	var part: Node3D = man.parts[&"thigh_r"]
	var at := part.global_position
	man.go_limp()
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(at + Vector3(0, 0, -3), Vector3.BACK, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	check_eq(man.wounds.size(), 1, "the ball finds him")


## The heart, great vessels, liver and spleen bleed into him: nothing pressed on the outside
## reaches it (experiments/body_lab/results/2026-10-21_packing).
func test_a_ball_through_the_heart_bleeds_inside() -> void:
	var p := Physiology.new()
	p.apply_trace({"segment": &"chest", "track_cm": 0.0, "hits": [{"id": &"heart", "kind": &"organ", "effect": &"torn"}]})
	check_eq(p.bleeds[0].kind, &"internal", "inside")
	var before := p.total_bleed_rate()
	p.apply_pressure(&"chest")
	check_near(p.total_bleed_rate(), before, 0.001, "pressing on his chest doesn't slow it")


## Packing an artery holds it about half the time; held, it clots under the pressure.
func test_packing_holds_an_artery_some_of_the_time() -> void:
	var held := 0
	for k in 40:
		var p := Physiology.new()
		p.roll_rng.seed = hash(["test", k])
		p.apply_trace({"segment": &"thigh_r", "track_cm": 0.0, "hits": [{"id": &"femoral_r", "kind": &"artery", "effect": &"cut"}]})
		p.apply_pressure(&"thigh_r")
		for i in 1800:  # packed and not held, a femoral kills in about 18 minutes
			p.step(1.0)
		if p.alive:
			held += 1
			check(p.total_bleed_rate() < 0.1, "a held artery has stopped (%.2f ml/s)" % p.total_bleed_rate())
	check(held >= 10 and held <= 30, "about half hold (%d of 40)" % held)


## A broken thigh bone bleeds into the thigh, about 1.2 litres, and stops there.
func test_a_broken_femur_bleeds_into_the_thigh() -> void:
	var p := Physiology.new()
	p.apply_trace({"segment": &"thigh_r", "track_cm": 0.0, "hits": [{"id": &"femur_r", "kind": &"bone", "effect": &"broken"}]})
	check_eq(p.bleeds.size(), 1, "one bleed")
	check_eq(p.bleeds[0].kind, &"internal", "inside the thigh")
	for i in 7200:
		p.step(1.0)
	check(p.alive, "he lives through it")
	check_near(5000.0 - p.blood_ml, 1200.0, 60.0, "about 1.2 L gone (%.0f ml)" % (5000.0 - p.blood_ml))
	check_near(p.total_bleed_rate(), 0.0, 0.0001, "and it's stopped")


## An artery's jet leaves at the speed the pressure behind it gives (Bernoulli, less the hole's
## losses): a few metres a second at a healthy man's pressure, weaker as he bleeds out.
func test_an_arterial_jet_has_the_speed_of_its_pressure() -> void:
	check_near(BloodJet.jet_speed(120.0) / BloodJet.DISCHARGE, 5.5, 0.1, "Bernoulli at 120 mmHg is ~5.5 m/s")
	check(BloodJet.jet_speed(120.0) > BloodJet.jet_speed(80.0), "a beat's systole throws it further than diastole")
	check(BloodJet.jet_speed(60.0) < BloodJet.jet_speed(120.0) * 0.75, "in shock it falls short")
	check_eq(BloodJet.jet_speed(0.0), 0.0, "no pressure, no jet")


## A drop that lands at a slant draws out along its flight; one straight down lands round
## (width / length = sin of the angle it came in at).
func test_a_drop_at_a_slant_lands_long() -> void:
	Blood.clear()
	var slant: Variant = Blood.throw(world, Vector3(0, 0.4, 0), Vector3(5, 0, 0), 2.0)
	var down: Variant = Blood.throw(world, Vector3(4, 0.4, 3), Vector3(0, -3, 0), 2.0)
	check(slant != null and down != null, "both came down")
	var long: Decal = null
	var round: Decal = null
	for d: Node in get_tree().get_nodes_in_group(&"blood_splats"):
		var dec := d as Decal
		if dec.global_position.distance_to(slant) < 0.01:
			long = dec
		elif dec.global_position.distance_to(down) < 0.01:
			round = dec
	check(long != null and long.size.z > long.size.x * 1.8, "the slanting drop's stain is long (%s)" % (long.size if long else null))
	check(long != null and absf(long.global_basis.z.normalized().x) > 0.9, "and points the way it flew")
	check(round != null and absf(round.size.z - round.size.x) < 0.001, "the one straight down is round")
	Blood.clear()


## Soft lead on bone (the gore lab): a ball through the thigh bone flattens and goes on wider; it
## sometimes splits on so strong a bone, two tracks and two holes out.
func test_a_ball_through_the_femur_flattens_or_splits() -> void:
	var a := Anatomy.shared()
	var flat := 0
	var split := 0
	for k in 60:
		var r := RandomNumberGenerator.new()
		r.seed = hash(["femur", k])
		var y := 0.58 + k * 0.004  # up the bone, each a different spot on it
		var tr := a.trace(&"thigh_r", Vector3(0.0975, y, -0.4), Vector3.BACK, 475.0, 0.0057, r)
		var broke: bool = tr.hits.any(func(h: Dictionary) -> bool: return h.id == &"femur_r" and h.effect == &"broken")
		if not broke:
			continue
		check(tr.flattened, "a ball that broke the femur flattened (seed %d)" % k)
		if tr.split:
			split += 1
			check(tr.has("second"), "a split ball goes two ways (its halves often stay in him)")
		else:
			flat += 1
			check(float(tr.radius) > 0.0057 * 1.4, "and went on wider (%.1f mm)" % (float(tr.radius) * 1000.0))
	check(flat > 0 and split > 0, "some flatten, some split (%d / %d)" % [flat, split])
	check(split < flat, "splitting is the rarer (%d of %d)" % [split, flat + split])


## A ball that meets a bone nearly side-on skips off it: the bone's chipped, not broken, and the
## ball leaves on a bent line.
func test_a_ball_side_on_to_a_bone_skips_off_it() -> void:
	var a := Anatomy.shared()
	var skipped := 0
	for k in 40:
		var r := RandomNumberGenerator.new()
		r.seed = hash(["skip", k])
		var y := 0.6 + k * 0.005
		var tr := a.trace(&"thigh_r", Vector3(0.0973 + 0.0222 + (0.7 - y) * 0.013, y, -0.4), Vector3.BACK, 475.0, 0.0057, r)
		var femur: Array = tr.hits.filter(func(h: Dictionary) -> bool: return h.id == &"femur_r")
		if tr.skipped:
			skipped += 1
			check(not femur.is_empty() and femur[0].effect == &"chipped", "the bone's chipped (%s)" % [femur])
			check((tr.out_dir as Vector3).angle_to(Vector3.BACK) > 0.1, "and it goes on bent (%.0f deg)" % rad_to_deg((tr.out_dir as Vector3).angle_to(Vector3.BACK)))
	check(skipped > 10 and skipped < 35, "it skips most times, not every time (%d of 40)" % skipped)


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


## A ball through his clothes carries a plug of them into him more often than not when it stays in
## him, less when it goes through; it's said in what the wound is.
func test_a_ball_carries_his_clothes_in() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	await physics_frames(2)
	var part: Node3D = man.parts[&"abdomen"]
	var carried := 0
	var shots := 0
	for i in 24:
		var at := part.global_transform * (Vector3(-0.08 + i * 0.007, 0.0, 0.0))
		var res := man.take_bullet(part, at + Vector3(0, 0, -0.3), Vector3.BACK, 300.0, 0.0057)
		var w: Dictionary = res.wound
		if w.kind == &"graze":
			continue
		shots += 1
		if w.get("cloth", &"") != &"":
			carried += 1
			check(", ".join(man._hit_words(w)).contains("carried in"), "said: %s" % ", ".join(man._hit_words(w)))
	check(shots > 10, "shots into him (%d)" % shots)
	check(carried > shots / 5 and carried < shots, "some carry cloth in, not all (%d of %d)" % [carried, shots])


func _man() -> HumanBody:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	await physics_frames(3)
	return man


## A knife: a stab goes in narrow and deep; a slash across the throat opens the vessels under it.
func test_a_knife_stabs_deep_and_slashes_open() -> void:
	var man := await _man()
	var belly := man.parts[&"abdomen"] as Node3D
	var stab := man.take_knife(belly, belly.global_position + Vector3(0.03, 0, -0.2), Vector3.BACK, true, 0.12)
	check_eq(stab.kind, &"stab", "a stab")
	check(not stab.hits.is_empty(), "it reaches what's inside (%s)" % [stab.hits])
	var neck := man.parts[&"neck"] as Node3D
	var center := man.anatomy.segment_center(&"neck")
	var start := neck.global_transform * (Vector3(0.06, 1.5, -0.04) - center)
	var cut := man.take_knife(neck, start, Vector3.BACK, false, 0.035, Vector3.LEFT, 0.12)
	check_eq(cut.kind, &"slash", "a slash")
	check(cut.hits.any(func(h: Dictionary) -> bool: return String(h.id).begins_with("carotid") or String(h.id).begins_with("jugular")),
			"across the throat it opens a great vessel (%s)" % [cut.hits])
	check(man._describe_one(cut).contains("knife"), "said: %s" % man._describe_one(cut))


func test_glass_and_splinters_stay_standing_in_him() -> void:
	var man := await _man()
	var arm := man.parts[&"forearm_r"] as Node3D
	man.take_cut(arm, arm.global_position + Vector3(0, 0, -0.1), Vector3.BACK, 0.01, true)
	var vis := man.visuals[&"forearm_r"] as Node3D
	check(vis.find_children("Shard", "MeshInstance3D", false, false).size() == 1, "a shard of glass stands in his arm")
	var leg := man.parts[&"thigh_l"] as Node3D
	var res := man.take_bullet(leg, leg.global_position + Vector3(0, 0, -0.2), Vector3.BACK, 6.0, 0.004, 0.002, 2.0, 0.0, &"splinter")
	if res.wound.lodged:
		check((man.visuals[&"thigh_l"] as Node3D).find_children("Splinter", "MeshInstance3D", false, false).size() == 1, "a splinter stands in his thigh")


## Fired from close, the powder burns and tattoos round the hole; burns from a fire mark him.
func test_close_shots_powder_burn_and_fire_burns_him() -> void:
	var man := await _man()
	var chest := man.parts[&"chest"] as Node3D
	var res := man.take_bullet(chest, chest.global_position + Vector3(0.05, 0, -0.2), Vector3.BACK, 475.0, 0.0057, 0.0165, 0.4)
	check(float(res.wound.get("powder", 0.0)) > 0.0, "powder round the hole from 40 cm")
	check(man._describe_one(res.wound).contains("powder"), "said: %s" % man._describe_one(res.wound))
	Events.scorched.emit(man, 0.6)
	check(man.find_children("Burn", "Decal", true, false).size() >= 1, "and the fire's burns are on him")
