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
	check(p.blood_loss() >= PlayerWounds.WAKE_BLOOD_LOSS - 0.01, "still short of blood (%.2f)" % p.blood_loss())
	check(p.describe() != "Unhurt.", "not unhurt: %s" % p.describe())
	check_near(clock.time_of_day, 17.0 + PlayerWounds.OUT_HOURS, 0.05, "the clock moved on")
	# And you stay up: nothing about you puts you straight back down.
	await physics_frames(60 * 3)
	check(p.is_conscious(), "still awake")
	check(player.wounds.out_cold == 0.0, "not out again")


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
