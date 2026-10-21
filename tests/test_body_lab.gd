extends TestCase
## The body lab (experiments/body_lab/): its bench aims, fires and treats as it says, and its
## bridge file loads as a lab. Mechanics only; the lab's numbers are its baseline, not rules.

const Bench := preload("res://experiments/body_lab/wound_bench.gd")

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
	await physics_frames(1)


func test_the_lab_names_every_scenario() -> void:
	var names: Array = Bench.scenarios().map(func(s: Dictionary) -> String: return s.name)
	var d := Bench.data()
	check_eq(names.size(), d.weapons.size() * d.ranges.size() * d.spots.size() + d.dynamite.distances.size() + d.spots.size() + 2,
			"every weapon at every range into every spot, the dynamite, the grabs, the check, the probe")
	check(names.has("revolver_05m_thigh") and names.has("shotgun_30m_hand") and names.has("dynamite_1m"), "named as the README says")


func test_the_treatments_do_what_they_say() -> void:
	var femoral := Bench.vessel(&"femoral_r")
	check(femoral.outcomes.none.dead_s != null, "a cut femoral artery alone kills untreated")
	check(femoral.outcomes.tourniquet.applicable and femoral.outcomes.tourniquet.dead_s == null, "a belt at 30 s saves him")
	var p := Physiology.new()
	p.apply_trace({"segment": &"thigh_r", "track_cm": 0.0, "hits": [{"id": &"femoral_r", "kind": &"artery", "effect": &"cut"}]})
	var before := p.total_bleed_rate()
	check(Bench.treat(p, "packing"), "packing has something to press on")
	check_near(p.total_bleed_rate(), before * p.tuning.pressure_factor, 0.01, "packing keeps the game's pressure share")
	check(Bench.treat(p, "doctor"), "the doctor has work")
	check_near(p.total_bleed_rate(), 0.0, 0.0001, "and every bleed is tied off")
	var neck := Physiology.new()
	neck.apply_trace({"segment": &"neck", "track_cm": 0.0, "hits": [{"id": &"carotid_r", "kind": &"artery", "effect": &"cut"}]})
	check(not Bench.treat(neck, "tourniquet"), "no belt goes round a neck")


func test_a_perfect_aim_at_the_thigh_crosses_the_femoral() -> void:
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(10)
	var rng := RandomNumberGenerator.new()
	var spot: Dictionary = Bench.data().spots.thigh
	var shots := Bench.fire(ballistics, Vector3(0, 1.5, -5.0), Bench.spot_world(man, spot), Bench.gun("revolver"), rng)
	await wait_until(func() -> bool: return not shots[0].alive, 60)
	var crossed := []
	for w: Dictionary in man.wounds:
		for h: Dictionary in w.hits:
			crossed.append(String(h.id))
	check(crossed.has("femoral_r"), "the ball crosses what the spot aims for (%s)" % ", ".join(crossed))


func test_its_bridge_file_is_a_lab() -> void:
	var lab: Variant = (load("res://experiments/body_lab/bridge.gd") as Script).new()
	check(lab is BridgeLab, "bridge.gd is a BridgeLab")
	if lab is BridgeLab:
		var cmds := (lab as BridgeLab).commands()
		check(cmds.size() >= 5 and cmds.keys().all(func(c: String) -> bool: return c.begins_with("body_") and (lab as Object).has_method("_cmd_" + c)),
				"its commands are its own (body_...) and each has its method")
		(lab as Node).free()
