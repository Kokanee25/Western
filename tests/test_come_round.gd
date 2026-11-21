extends TestCase
## Blacking out isn't free (DESIGN.md §3, "Death": you wake up at the doctor's, hurt, poorer, and
## the town knows): you come round hours later, patched up but still hurt, and the fight that put
## you down is over; the men who did it have gone about their day.

var world: Node3D
var player: Player
var clock: DayCycle


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
	clock = DayCycle.new()
	clock.config = load("res://config/day_cycle.tres")
	world.add_child(clock)
	clock.set_physics_process(false)
	clock.set_time(17.0)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	await physics_frames(3)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


## Blood loss enough to put you out: `seconds` later you're awake again.
func _knock_out() -> void:
	player.wounds.physiology.blood_ml = 2800.0
	await physics_frames(10)
	check(player.wounds.out_cold > 0.0, "out cold")
	await physics_frames(60 * 5)
	check(player.wounds.physiology.is_conscious(), "comes round")


func test_you_come_round_hours_later_still_hurt() -> void:
	var p := player.wounds.physiology
	# A ball through the thigh: the femoral cut, bleeding hard.
	var t: RevolverTuning = load("res://config/revolver.tres")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var leg := player.global_position + Vector3(0.1, 0.75, 0.0)
	ballistics.fire(leg - player.global_basis.z * 5.0, player.global_basis.z, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, [])
	await physics_frames(20)
	check(p.wounds > 0, "hit (%d wounds)" % p.wounds)
	var wounds := p.wounds
	var broken := p.broken.size()
	check(p.total_bleed_rate() > 0.1, "bleeding (%.1f ml/s)" % p.total_bleed_rate())
	await _knock_out()
	check_eq(p.wounds, wounds, "the wounds are still there")
	check_eq(p.broken.size(), broken, "broken bones stay broken")
	check(p.total_bleed_rate() < 0.01, "bound up: no bleeding (%.2f ml/s)" % p.total_bleed_rate())
	check(p.blood_loss() > 0.05, "still short of blood (%.2f)" % p.blood_loss())
	check_near(player.wounds.recovering, float(PlayerWounds.OUT_HOURS), 0.01, "a quarter of the way mended (#1125)")
	check(p.describe() != "Unhurt.", "not unhurt: %s" % p.describe())
	check_near(clock.time_of_day, 17.0 + PlayerWounds.OUT_HOURS, 0.05, "the clock moved on")
	# And you stay up: nothing about you puts you straight back down.
	await physics_frames(60 * 3)
	check(p.is_conscious(), "still awake")
	check(player.wounds.out_cold == 0.0, "not out again")


## The gunfight lab, its played fight over with you down: you stay as you are (#595: "Dead (brain)",
## then 4 s later "you came round" at the doctor's).
func test_held_down_you_stay_down() -> void:
	var at := player.global_position
	player.wounds.stays_down = true
	player.wounds.physiology.blood_ml = 2800.0
	await physics_frames(60 * 6)
	check(not player.wounds.physiology.is_conscious(), "still out cold after 6 s")
	check(player.global_position.distance_to(at) < 0.5, "where you fell")


func test_killed_you_still_wake() -> void:
	var p := player.wounds.physiology
	p.blood_ml = 2000.0
	await physics_frames(5)
	check(not p.alive, "bled out")
	await physics_frames(60 * 5)
	check(p.alive and p.is_conscious(), "came round all the same")
	check_eq(p.cause_of_death, &"", "no cause of death")


func test_the_man_who_downed_you_has_gone_about_his_day() -> void:
	var places := Waypoints.test_street()
	# A gang man with a day in town, in a fight with you.
	var gang := HumanBody.new()
	gang.person_id = &"brody"
	var b := OutlawBrain.new()
	b.name = "Brain"
	b.places = places
	gang.add_child(b)
	world.add_child(gang)
	gang.global_position = Vector3(0, 0, -30)
	# A man with no day to go about (the range's outlaw), in a fight with you too.
	var other := HumanBody.new()
	var ob := OutlawBrain.new()
	ob.name = "Brain"
	other.add_child(ob)
	world.add_child(other)
	other.global_position = Vector3(10, 0, -30)
	await physics_frames(3)
	b.relations.provoke(player)
	ob.relations.provoke(player)
	check_eq(b.relations.stance(player), Relations.Stance.FIGHT, "in a fight with you")
	player.set_meta(&"last_hit_by", gang)
	await _knock_out()
	await physics_frames(2)
	check(not is_instance_valid(gang), "the town man has gone")
	check(is_instance_valid(other), "the other man's still there")
	check(ob.relations.stance(player) != Relations.Stance.FIGHT, "and the fight's over for him")
	check(not player.has_meta(&"last_hit_by"), "who hit you last is forgotten")
	check(player.wounds._message.text.contains("Brody shot you down"), "told who did it: %s" % player.wounds._message.text)


## #1125: the riders went in the black-out with no word: who left is an event and a line.
func test_the_men_who_left_while_you_were_out_are_told() -> void:
	var places := Waypoints.test_street()
	var gang := HumanBody.new()
	gang.person_id = &"lyle"
	var b := OutlawBrain.new()
	b.name = "Brain"
	b.places = places
	gang.add_child(b)
	world.add_child(gang)
	gang.global_position = Vector3(0, 0, -30)
	await physics_frames(3)
	var left: Array = []
	var on_left := func(who: Node, why: StringName) -> void: left.append([who, why])
	Events.person_left.connect(on_left)
	await _knock_out()
	Events.person_left.disconnect(on_left)
	check_eq(left.size(), 1, "one man left (%s)" % [left])
	if left.size() == 1:
		check_eq(left[0][1], &"day_done", "his day done")
	check(player.wounds._message.text.contains("Lyle rode out while you were under"), "told: %s" % player.wounds._message.text)


## #1125: a townsman hurt before you went under: his wounds ran on through the hours (the bleeding
## clotted off, his blood lost on the way), they're still on him, and up again he doesn't cry out at
## a shot six hours old.
func test_a_hurt_townsman_runs_on_through_the_hours() -> void:
	var man := HumanBody.new()
	man.person_id = &"widow"
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = Vector3(4, 0, -6)
	brain.faces = Vector3(4, 0, -10)
	man.add_child(brain)
	world.add_child(man)
	man.global_position = Vector3(4, 0, -6)
	await physics_frames(5)
	var p := man.physiology
	# A ball through his forearm: a bleed that clots off in minutes.
	var t: RevolverTuning = load("res://config/revolver.tres")
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var arm := man.global_position + Vector3(0.0, 1.05, 0.0)
	var hit := false
	for side: float in [0.22, -0.22, 0.3, -0.3]:
		ballistics.fire(arm + Vector3(side, 0, 5.0), Vector3.FORWARD, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, [])
		await physics_frames(10)
		if p.wounds > 0:
			hit = true
			break
	check(hit, "hit (%d wounds)" % p.wounds)
	var wounds := p.wounds
	var blood := p.blood_ml
	var said: Array = []
	var on_spoke := func(who: Node, text: String) -> void:
		if who == man:
			said.append(text)
	await _knock_out()
	Events.spoke.connect(on_spoke)
	check_eq(p.wounds, wounds, "his wounds still on him")
	check(not p.alive or p.total_bleed_rate() < 0.05, "the bleeding's run its course (%.2f ml/s)" % p.total_bleed_rate())
	check(p.blood_ml <= blood, "his blood didn't come back by magic (%.0f -> %.0f)" % [blood, p.blood_ml])
	check(brain._hurt_spent or not brain.hurt, "the fright of it's spent")
	await physics_frames(60 * 8)
	Events.spoke.disconnect(on_spoke)
	for line: String in said:
		check(not line in CivilianBrain.LINES[&"cower"] and not line in CivilianBrain.LINES[&"hurt"], "no cry at an old shot: %s" % line)


## #1125 (Sean on #1093: your wounds don't last; fully recovered within a day, nothing permanent):
## at the doctor's the bleeding's stopped and a broken leg's splinted (you stand on it); half the day
## on the bones have knit; by the day's end you're as you were.
func test_a_day_after_the_doctors_youre_mended() -> void:
	var p := player.wounds.physiology
	p.break_bone(&"femur_r")
	p.lost_fingers[&"finger_index_r"] = true
	p.wounds += 3
	check(not p.leg_ok("r"), "the broken leg won't hold you")
	await _knock_out()
	check(p.splinted.has("r") and p.leg_ok("r"), "splinted: you stand on it")
	check(p.broken.has(&"femur_r"), "not mended yet")
	check(player.wounds._message.text.contains("right in a day"), "told: %s" % player.wounds._message.text)
	# The clock runs on (ticked by hand: the test's clock is still): the rest of the half day.
	for i in 70:
		clock.pass_hours(0.1)
		await physics_frames(1)
	check(not p.broken.has(&"femur_r"), "half a day on: the bone's knit (%.1f h)" % player.wounds.recovering)
	check(p.wounds > 0, "not all of it yet")
	Events.hours_passed.emit(13.0, &"test")
	check_eq(p.wounds, 0, "a day on: no wounds")
	check(p.lost_fingers.is_empty(), "nothing permanent")
	check_near(p.blood_ml, p.tuning.blood_ml, 1.0, "your blood back")
	check_eq(p.describe(), "Unhurt.", "unhurt")
	check(player.wounds.recovering < 0.0, "done mending")


## #1125's 5: a broken leg and a man over your shoulder, you went 3-6 m in 30 s with no word why (the
## forced crouch's pace, the leg's, the carry's, all three). The carry's pace isn't cut again by
## the crouch; the leg still slows you, and the screen says so.
func test_hurt_and_carrying_you_go_slow_but_steady_and_are_told_why() -> void:
	var man := HumanBody.new()
	man.person_id = &"earl"
	world.add_child(man)
	man.global_position = player.global_position + Vector3(0.0, 0.0, -1.0)
	await physics_frames(5)
	man.go_limp()
	await physics_frames(30)
	var p := player.wounds.physiology
	p.break_bone(&"tibia_r")
	await physics_frames(2)
	check(player.carry.take(man), "over your shoulder")
	var from := player.global_position
	var told: Array = []
	var on_shown := func(text: String) -> void: told.append(text)
	player.wounds.shown.connect(on_shown)
	Input.action_press(&"move_forward")
	await physics_frames(60 * 5)
	Input.action_release(&"move_forward")
	player.wounds.shown.disconnect(on_shown)
	var went := Vector2(player.global_position.x - from.x, player.global_position.z - from.z).length()
	# Carry pace (1.0 m/s) x the leg's 0.35: ~1.7 m in 5 s (it was ~0.9: the crouch's pace again).
	check(went > 1.3, "slow but going (%.2f m in 5 s)" % went)
	check(player.wounds.slow_why.contains("broken"), "why: %s" % player.wounds.slow_why)
	check(told.any(func(l: String) -> bool: return l.contains("Your leg's broken")), "told: %s" % [told])
	player.carry.start_over()


## #1125's 6: a piece of the store thrown by a blast 10 m off had a man cry "He shot me!", and a man
## hit in the chest "My arm!". What he cries is by what hit him.
func test_a_man_hurt_by_a_blast_says_so_not_he_shot_me() -> void:
	var man := HumanBody.new()
	man.person_id = &"porch_loafer"
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = Vector3(4, 0, -6)
	brain.faces = Vector3(4, 0, -10)
	man.add_child(brain)
	world.add_child(man)
	man.global_position = Vector3(4, 0, -6)
	await physics_frames(5)
	var said: Array = []
	var on_spoke := func(who: Node, text: String) -> void:
		if who == man:
			said.append(text)
	Events.spoke.connect(on_spoke)
	man.hit.emit({"person": man, "segment": &"hand_l", "kind": &"blow"})
	man.physiology.wounds += 1
	await physics_frames(20)
	Events.spoke.disconnect(on_spoke)
	check(not said.is_empty() and said[0] in CivilianBrain.LINES[&"hurt_blast"], "a blast's line (%s)" % [said])
	brain._hit_kind = &"bullet"
	brain._hit_seg = &"chest"
	check_eq(brain.hurt_line(), &"hurt", "a ball in the chest: a ball's line")
	brain._hit_seg = &"upper_arm_r"
	check_eq(brain.hurt_line(), &"hurt_arm", "in the arm: his arm")
	check(not "Ah—! My arm! My arm!" in CivilianBrain.LINES[&"hurt"], "no 'my arm' for the chest")


## #1125's 7: the gang called "spotted" at you 100 m off at night. Not reproduced (two runs through
## the bridge: none of them saw you past 26 m at 22:00); held here: at night, 90 m off on open
## ground, three of them in a fight with you never see you nor call it.
func test_at_night_the_gang_dont_spot_you_90_m_off() -> void:
	clock.set_time(22.0)
	var places := Waypoints.test_street()
	var men: Array[OutlawBrain] = []
	for i in 3:
		var m := HumanBody.new()
		m.person_id = StringName(["brody", "lyle", "kid"][i])
		var b := OutlawBrain.new()
		b.name = "Brain"
		b.places = places
		m.add_child(b)
		world.add_child(m)
		m.global_position = Vector3(float(i) * 1.5, 0.0, -90.0)
		men.append(b)
	await physics_frames(3)
	var called: Array = []
	var on_call := func(s: Node, kind: StringName, about: Node, _at: Vector3) -> void:
		if kind == &"spotted" and about == player:
			called.append(s)
	Events.callout.connect(on_call)
	for b in men:
		b.relations.provoke(player)
	var saw := false
	for i in 60 * 8:
		await physics_frames(1)
		for b in men:
			saw = saw or b.senses.sees(player)
	Events.callout.disconnect(on_call)
	check(not saw, "nobody saw you at 90 m by night (sight on you %.1f m)" % men[0].senses.range_to(player))
	check(called.is_empty(), "nobody called you spotted (%d)" % called.size())
