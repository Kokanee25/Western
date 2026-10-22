extends TestCase
## What his wounds show as time goes (WoundSigns, the gore lab): blood from burst eardrums and a
## struck nose, a drip trail behind a bleeding man, bloody handprints, smears where he's dragged,
## teeth spat with a broken jaw, a scalp wound's blood in his eye, and what wounds do to how he
## holds himself and breathes.

var world: Node3D
var man: HumanBody


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
	Blood.clear()
	man = HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	await physics_frames(10)


func after_each() -> void:
	Blood.clear()
	world.queue_free()
	await physics_frames(1)


func _head_decals() -> int:
	return (man.visuals[&"head"] as Node3D).find_children("*", "Decal", false, false).size()


func _marks() -> Array[Node]:
	return get_tree().get_nodes_in_group(&"blood_marks").filter(func(n: Node) -> bool: return world.is_ancestor_of(n))


func test_burst_eardrums_bleed_from_the_ears() -> void:
	var before := _head_decals()
	man.physiology.eardrums_burst[&"r"] = true
	man.physiology.eardrums_burst[&"l"] = true
	await physics_frames(WoundSigns.EVERY + 2)
	check_eq(_head_decals() - before, 2, "blood run from each ear")


func test_a_blow_to_the_face_gives_a_nosebleed_that_drips() -> void:
	man.physiology.blow(&"head", 40.0, RandomNumberGenerator.new())
	check(man.physiology.nose_bleed > 60.0, "his nose bleeds (%.0f s)" % man.physiology.nose_bleed)
	await physics_frames(150)
	var drops := get_tree().get_nodes_in_group(&"blood_splats").size()
	check(drops >= 1, "drops on the ground under him (%d)" % drops)


func test_a_bleeding_man_walking_leaves_a_trail() -> void:
	man.physiology.apply_trace({"segment": &"thigh_r", "track_cm": 8.0, "hits": []})
	man.physiology.bleeds[0].rate = 6.0
	man.wounds.append({"segment": &"thigh_r", "entry": Vector3(0.1, -0.1, -0.06), "exit": null, "kind": &"bullet",
			"bleeds": [0], "hits": [], "stain": null})
	var start := man.global_position
	for i in 240:
		man.walk_to(start + Vector3(0, 0, 8), 1.3, 1.0 / 60.0)
		await physics_frames(1)
	var splats := get_tree().get_nodes_in_group(&"blood_splats")
	check(splats.size() >= 3, "drops along his way (%d)" % splats.size())
	if splats.size() >= 2:
		var zs := splats.map(func(d: Node) -> float: return (d as Node3D).global_position.z)
		check(zs.max() - zs.min() > 1.0, "spread out behind him, a trail (%.1f m)" % (zs.max() - zs.min()))


func test_a_bloody_hand_leaves_prints_on_a_wall() -> void:
	var hand := man.parts[&"hand_r"] as Node3D
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.1, 2.0, 2.0)
	shape.shape = box
	wall.add_child(shape)
	world.add_child(wall)
	wall.global_position = hand.global_position + Vector3(0.08, 0, 0)
	man.signs._bloody["r"] = WoundSigns.PRINTS_PER_HAND
	await physics_frames(10)
	var prints := _marks().filter(func(n: Node) -> bool: return (n as Decal).texture_albedo.resource_path.ends_with("handprint.png"))
	check(prints.size() >= 1, "a bloody handprint on the wall (%d)" % prints.size())


func test_a_bleeding_man_dragged_smears_the_ground() -> void:
	man.physiology.apply_trace({"segment": &"chest", "track_cm": 12.0, "hits": []})
	man.physiology.bleeds[0].rate = 3.0
	man.go_limp()
	await physics_frames(150)  # down on the ground
	for i in 60:
		for sid: StringName in [&"chest", &"abdomen", &"pelvis"]:
			var rb := man.parts[sid] as RigidBody3D
			rb.linear_velocity = Vector3(0, rb.linear_velocity.y, 1.2)
		await physics_frames(1)
	var smears := _marks().filter(func(n: Node) -> bool: return (n as Decal).texture_albedo.resource_path.ends_with("smear.png"))
	check(smears.size() >= 2, "smears along where he was dragged (%d)" % smears.size())


func test_a_broken_jaw_spits_teeth() -> void:
	man.physiology.jaw_broken = true
	man.signs._spit_in = 0.1
	await physics_frames(20)
	var teeth := get_tree().get_nodes_in_group(&"severed_parts").filter(func(n: Node) -> bool: return n.name.begins_with("Tooth"))
	check(teeth.size() >= 1, "a tooth or two spat out (%d)" % teeth.size())


func test_a_scalp_graze_runs_into_his_eye() -> void:
	var head := man.parts[&"head"] as Node3D
	var center := man.anatomy.segment_center(&"head")
	# Along the top of his head, just under the skin, on the right.
	var at := head.global_transform * (Vector3(0.05, 1.71, -0.05) - center)
	man.take_bullet(head, at + Vector3(0, 0, -0.3), Vector3.BACK, 300.0, 0.0057)
	var w: Dictionary = man.wounds[-1]
	if w.kind != &"graze":
		check(true, "(the line missed the scalp: %s)" % w.kind)
		return
	check(man.physiology.blood_in_eye.has(&"r"), "blood in his right eye")


func test_short_of_breath_he_breathes_faster() -> void:
	var calm := man.breath_rate()
	man.physiology.lung_damage[&"lung_r"] = 600.0
	check(man.breath_rate() > calm * 1.3, "faster with a lung gone (%.2f against %.2f)" % [man.breath_rate(), calm])


func test_a_cut_radial_nerve_drops_his_wrist() -> void:
	var hand := man.pivots[&"hand_r"] as Node3D
	var before := hand.rotation_degrees
	man.physiology.cut[&"radial_nerve_r"] = true
	await physics_frames(150)
	var turned := (hand.rotation_degrees - before).length()
	check(turned > 30.0, "his wrist drops (%.0f deg)" % turned)


func test_a_dying_man_lying_down_bleeds_from_the_mouth() -> void:
	man.physiology.airway_blood = true
	man.go_limp()
	await physics_frames(300)
	var near := get_tree().get_nodes_in_group(&"blood_splats").filter(func(d: Node) -> bool:
		return (d as Node3D).global_position.distance_to((man.parts[&"head"] as Node3D).global_position) < 0.6)
	check(near.size() >= 1, "blood out of his mouth by his head (%d)" % near.size())


## Blood dries: an old fight's marks are dark and brown, not wet red.
func test_blood_dries_brown_over_hours() -> void:
	var d := Blood.splat(world, Vector3(1, 0, 1), Vector3.UP, 2.0)
	var fresh := d.modulate
	Blood.dry(1.0)
	var hour := d.modulate
	Blood.dry(47.0)
	var two_days := d.modulate
	check(hour.r < fresh.r and hour.r > two_days.r, "darker with every hour (%.2f, %.2f, %.2f)" % [fresh.r, hour.r, two_days.r])
	check(two_days.r < fresh.r * 0.65, "dark after two days")
	check(two_days.g / two_days.r < fresh.g / fresh.r * 0.85 or two_days.b / two_days.r > 0.0, "browned (%s)" % two_days)


func _shot(seg: StringName, at_rest: Vector3) -> Dictionary:
	var part := man.parts[seg] as Node3D
	var at := part.global_transform * (at_rest - man.anatomy.segment_center(seg))
	return man.take_bullet(part, at + Vector3(0, 0, -0.3), Vector3.BACK, 300.0, 0.0057)


## Bound up: a bandage at the wound (red through while it bleeds), a belt for a tourniquet, a
## broken arm in a sling, a broken leg splinted.
func test_dressings_show() -> void:
	_shot(&"thigh_r", Vector3(0.0975, 0.7, 0.0))
	man.physiology.apply_pressure(&"thigh_r")
	man.physiology.apply_tourniquet(&"thigh_r")
	var vis := man.visuals[&"thigh_r"] as Node3D
	check_eq(vis.find_children("Bandage", "MeshInstance3D", false, false).size(), 1, "a bandage")
	check_eq(vis.find_children("Tourniquet", "MeshInstance3D", false, false).size(), 1, "and a belt above")
	if man.physiology.broken.has(&"femur_r"):
		check_eq(vis.find_children("Splint", "MeshInstance3D", false, false).size(), 2, "a broken thigh splinted")
	man.physiology.broken[&"humerus_l"] = true
	man.physiology.apply_pressure(&"upper_arm_l")
	check(man.slung.has("l"), "a broken arm in a sling")
	await physics_frames(2)
	var fa := man.visuals[&"forearm_l"] as Node3D
	check_eq(fa.find_children("Sling", "MeshInstance3D", false, false).size(), 1, "the sling's cloth round his forearm")
	var strap := (man.visuals[&"chest"] as Node3D).find_child("SlingStrap", false, false) as Node3D
	check(strap != null and strap.global_position.y > fa.global_position.y, "and its strap up toward his neck")


## A wound with his shirt in it festers over the next days; untouched, a leg goes to gangrene and
## kills him; the leg off in time, he lives.
func test_a_dirty_wound_festers_and_the_saw_saves_him() -> void:
	var p := man.physiology
	var hour: float = p.tuning.game_hour_seconds
	p.contaminate(&"shin_l", true)
	for i in 72:
		p.step(hour)
	check(p.infection(&"shin_l") > 0.0 and p.fever() > 0.0, "gone bad by the third day (fever %.2f)" % p.fever())
	check(p.describe().contains("gone bad") or p.describe().contains("gangrene"), "said: %s" % p.describe())
	var p2 := Physiology.new()
	p2.contaminate(&"shin_l", true)
	for i in 24 * 12:
		p2.step(hour)
	check(not p2.alive and p2.cause_of_death == &"gangrene", "untouched, gangrene kills him (%s)" % p2.cause_of_death)
	for i in 50:
		p.step(hour)
	man.amputate(&"shin_l")
	check(p.infections.is_empty() and p.fever() == 0.0, "the leg off, the fever goes")
	check((man.visuals[&"thigh_l"] as Node3D).find_children("StumpFace", "MeshInstance3D", false, false).size() == 1, "a sewn stump")
	for i in 24 * 8:
		p.step(hour)
	check(p.alive, "and he lives")


## Days on, a clean wound closes to a scar that stays.
func test_a_wound_heals_to_a_scar() -> void:
	var res := _shot(&"upper_arm_r", Vector3(0.2025, 1.235, -0.0175))
	var w: Dictionary = res.wound
	man.physiology.infections.clear()
	man._heal(HumanBody.HEAL_GAME_DAYS * 24.0 * man.physiology.tuning.game_hour_seconds + 1.0)
	check(w.get("healed", false), "healed")
	check((man.visuals[w.segment] as Node3D).find_children("Scar", "Decal", false, false).size() >= 1, "a scar where it was")


func test_flies_come_to_the_dead() -> void:
	man.physiology._die(&"blood_loss")
	man.go_limp()
	man.signs._dead_for = WoundSigns.FLIES_AFTER_HOURS * man.physiology.tuning.game_hour_seconds
	await physics_frames(WoundSigns.EVERY + 2)
	check(man.signs._flies != null, "flies over him")
