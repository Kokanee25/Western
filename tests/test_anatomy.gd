extends TestCase
## The wound rules: where a .45 goes through a man and what that does to him over time.
## Directions are in the body's rest pose: he faces -Z, his right is +X, feet at 0.

const E45 := 475.0  # joules, .45 Colt black powder at the muzzle
const R45 := 0.0057  # bullet radius

var anatomy: Anatomy
var rng: RandomNumberGenerator


func before_each() -> void:
	anatomy = Anatomy.shared()
	rng = RandomNumberGenerator.new()
	rng.seed = 7


func _shoot(p: Physiology, segment: StringName, from: Vector3, dir: Vector3, energy := E45) -> Dictionary:
	var tr := anatomy.trace(segment, from, dir, energy, R45, rng)
	p.apply_trace(tr)
	return tr


func _hit_ids(tr: Dictionary) -> Array:
	return tr.hits.map(func(h: Dictionary) -> StringName: return h.id)


## Run the body forward in 1 s steps until `stop` holds or `max_seconds` pass. Returns seconds taken.
func _run(p: Physiology, max_seconds: float, stop: Callable) -> float:
	var t := 0.0
	while t < max_seconds and not stop.call():
		p.step(1.0)
		t += 1.0
	return t


func test_the_anatomy_loads() -> void:
	check_eq(anatomy.segments.size(), 17, "head, neck, chest, abdomen, pelvis and both arms and legs")
	check(anatomy.structure(&"femoral_r").kind == &"artery", "femoral arteries")
	check(anatomy.structure(&"index_l").kind == &"finger", "fingers")
	check_eq(anatomy.segments_below(&"upper_arm_r"), [&"upper_arm_r", &"forearm_r", &"hand_r"] as Array[StringName], "arm hangs together")


func test_ray_capsule() -> void:
	var s := Anatomy.ray_capsule(Vector3(0, 0.5, -1), Vector3.BACK, Vector3.ZERO, Vector3.UP, 0.2)
	check_near(s.x, 0.8, 0.001, "enters the side of the cylinder")
	check_near(s.y, 1.2, 0.001, "and leaves the far side")
	s = Anatomy.ray_capsule(Vector3(0, -1, 0), Vector3.UP, Vector3.ZERO, Vector3.UP, 0.2)
	check_near(s.x, 0.8, 0.001, "end on: enters the bottom cap")
	check_near(s.y, 2.2, 0.001, "leaves the top cap")
	s = Anatomy.ray_capsule(Vector3(0.5, 0.5, -1), Vector3.BACK, Vector3.ZERO, Vector3.UP, 0.2)
	check(s.x == INF, "misses")


func test_femoral_bleeds_out_in_minutes() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"thigh_r", Vector3(0.075, 0.7, -0.4), Vector3.BACK)
	check(_hit_ids(tr).has(&"femoral_r"), "cuts the femoral artery (hit %s)" % [_hit_ids(tr)])
	check(p.is_conscious(), "still on his feet at first")
	var out := _run(p, 900, func() -> bool: return not p.is_conscious())
	var dead := out + _run(p, 900, func() -> bool: return not p.alive)
	check(out > 90 and out < 240, "passes out in two to four minutes (%d s)" % out)
	check(dead < 360, "dead in minutes without a tourniquet (%d s)" % dead)
	check_eq(p.cause_of_death, &"blood_loss", "from blood loss")


func test_tourniquet_saves_the_leg_shot() -> void:
	var p := Physiology.new()
	_shoot(p, &"thigh_r", Vector3(0.075, 0.7, -0.4), Vector3.BACK)
	_run(p, 30, func() -> bool: return false)
	check(p.apply_tourniquet(&"thigh_r") > 0, "tourniquet on the thigh")
	_run(p, 1800, func() -> bool: return not p.alive)
	check(p.alive and p.is_conscious(), "alive and awake half an hour later (lost %.0f%%)" % (p.blood_loss() * 100))


func test_pressure_slows_bleeding() -> void:
	var p := Physiology.new()
	_shoot(p, &"thigh_r", Vector3(0.075, 0.7, -0.4), Vector3.BACK)
	var before := p.total_bleed_rate()
	p.apply_pressure(&"thigh_r")
	check(p.total_bleed_rate() < before * 0.5, "pressure slows it (%.1f -> %.1f ml/s)" % [before, p.total_bleed_rate()])


func test_gut_shot_lasts_hours() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"abdomen", Vector3(-0.05, 1.02, -0.4), Vector3.BACK)
	check(_hit_ids(tr).has(&"gut"), "holes the gut (hit %s)" % [_hit_ids(tr)])
	var hour := p.tuning.game_hour_seconds
	_run(p, hour * 3, func() -> bool: return false)
	check(p.alive and p.is_conscious(), "conscious and talking three game hours later")
	check(not p.can_run(), "but not running anywhere")
	_run(p, hour * 5, func() -> bool: return false)
	check(p.alive, "still alive at eight hours")
	_run(p, hour * 30, func() -> bool: return not p.alive)
	check(not p.alive, "dead within a day and a half without a doctor")
	check_eq(p.cause_of_death, &"gut_wound", "from the gut wound")


func test_heart_shot_is_quick() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"chest", Vector3(-0.03, 1.29, -0.4), Vector3.BACK)
	check(_hit_ids(tr).has(&"heart"), "through the heart (hit %s)" % [_hit_ids(tr)])
	var t := _run(p, 120, func() -> bool: return not p.alive)
	check(t <= 40, "dead in under a minute (%d s)" % t)


func test_head_shot_kills_outright() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"head", Vector3(0, 1.64, -0.4), Vector3.BACK)
	check(_hit_ids(tr).has(&"skull") and _hit_ids(tr).has(&"brain"), "through the skull into the brain")
	check(not p.alive, "dead at once")


func test_lung_shot_takes_the_breath() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"chest", Vector3(0.09, 1.3, -0.4), Vector3.BACK)
	check(_hit_ids(tr).has(&"lung_r"), "holes the right lung (hit %s)" % [_hit_ids(tr)])
	_run(p, 90, func() -> bool: return false)
	check(p.is_conscious(), "awake")
	check(not p.can_run(), "too short of breath to run (breath %.2f)" % p.breath_capacity())


func test_bone_breaks_or_stops_the_ball() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"thigh_r", Vector3(0.4, 0.7, 0.0), Vector3.LEFT)
	check(p.broken.has(&"femur_r"), "a full-power ball breaks the femur (hit %s)" % [_hit_ids(tr)])
	check(not p.can_stand(), "and he goes down")
	check(p.is_conscious() and p.can_hold("r"), "but can still shoot from the ground")
	var q := Physiology.new()
	tr = _shoot(q, &"thigh_r", Vector3(0.4, 0.7, 0.0), Vector3.LEFT, 150.0)
	check(tr.stop != null and tr.exit == null, "a spent ball lodges")
	check(not q.broken.has(&"femur_r") and _hit_ids(tr).has(&"femur_r"), "against the bone, without breaking it")


func test_through_and_through() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"forearm_r", Vector3(0.23, 1.0, -0.3), Vector3.BACK)
	check(tr.exit != null, "a forearm doesn't stop a .45")
	check(tr.energy_out > 200.0, "and it carries on with plenty left (%.0f J)" % tr.energy_out)


func test_upper_arm_drops_the_gun() -> void:
	var p := Physiology.new()
	_shoot(p, &"upper_arm_r", Vector3(0.21, 1.3, -0.3), Vector3.BACK)
	check(p.broken.has(&"humerus_r"), "breaks the upper arm bone")
	check(not p.can_hold("r"), "that hand can't hold a gun")
	check(p.can_hold("l"), "the other one can")


func test_a_finger_comes_off() -> void:
	var p := Physiology.new()
	var tr := _shoot(p, &"hand_r", Vector3(0.5, 0.73, -0.045), Vector3.LEFT)
	check_eq(p.lost_fingers.keys(), [&"index_r"], "takes the trigger finger (hit %s)" % [_hit_ids(tr)])
	check_eq(p.trigger_finger("r"), &"middle_r", "shoots with the middle finger now")
	check(p.can_hold("r"), "still holds a gun")


func test_adrenaline_delays_pain() -> void:
	var p := Physiology.new()
	_shoot(p, &"thigh_r", Vector3(0.4, 0.7, 0.0), Vector3.LEFT)
	check(p.felt_pain() < 0.05, "doesn't feel it at the moment of the hit")
	p.step(0.5)
	var early := p.felt_pain()
	_run(p, 10, func() -> bool: return false)
	check(p.felt_pain() > early * 2.0, "it comes a few seconds later (%.2f -> %.2f)" % [early, p.felt_pain()])
	_run(p, 300, func() -> bool: return false)
	check(p.felt_pain() > 0.4, "and gets worse as the adrenaline fades (%.2f)" % p.felt_pain())


func test_physiology_round_trips() -> void:
	var p := Physiology.new()
	_shoot(p, &"abdomen", Vector3(-0.05, 1.02, -0.4), Vector3.BACK)
	_shoot(p, &"hand_r", Vector3(0.5, 0.73, -0.045), Vector3.LEFT)
	_run(p, 60, func() -> bool: return false)
	var q := Physiology.new()
	q.from_dict(p.to_dict())
	check_near(q.blood_ml, p.blood_ml, 0.001, "blood")
	check_eq(q.lost_fingers, p.lost_fingers, "fingers")
	check_eq(q.bleeds.size(), p.bleeds.size(), "bleeds")
	q.step(10.0)
	p.step(10.0)
	check_near(q.blood_ml, p.blood_ml, 0.001, "and carries on the same")
