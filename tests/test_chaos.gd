extends TestCase
## Chaos (docs/briefs/automated-checks.md, item 3): blasts, fires and shots thrown at the street
## at random from a seed, with the gang and the townsfolk in it. Whatever happens, the world stays a
## world (nothing through the ground or flung off the map, no position that isn't a number, the dead
## stay dead, every member standing, rubble or gone, no script error: the runner fails on any), and
## the same seed gives the same result.

const SECONDS := 14.0
const EVENT_EVERY := 1.5
## Nothing below this (the ground is y 0; cellars don't exist).
const FLOOR_Y := -1.5
const MAP_RADIUS := 400.0

var street: Node3D
var _dead := {}
var _broken_seen := {}
var _problems: Array[String] = []


func before_each() -> void:
	Settings.autosave = false
	street = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await process_frames(3)
	(street.get_node(^"Player") as Player).input_enabled = false
	(street.get_node(^"TownLife") as TownLife).bring_gang()
	await physics_frames(30)
	_dead.clear()
	_broken_seen.clear()
	_problems.clear()


func after_each() -> void:
	street.queue_free()
	await process_frames(3)


## Throw things at the street for SECONDS from `seed`, checking as it goes. Returns what's left.
func _chaos(seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var members: Array = street.find_children("*", "StructureMember", true, false)
	var people: Array = get_tree().get_nodes_in_group(&"people")
	var fire := FireSystem.find(get_tree())
	var ballistics := street.find_child("Ballistics", true, false) as Ballistics
	var gun: RevolverTuning = load("res://config/revolver.tres")
	var ticks := int(SECONDS * 60.0)
	var every := int(EVENT_EVERY * 60.0)
	var happened: Array[String] = []
	for tick in ticks:
		if tick % every == 0:
			match rng.randi_range(0, 2):
				0:
					var m: StructureMember = members[rng.randi_range(0, members.size() - 1)]
					if is_instance_valid(m) and not m.broken:
						var at := m.global_position + Vector3(rng.randf_range(-1, 1), 0.3, rng.randf_range(-1, 1))
						Blast.detonate(street, at, 0.2)
						happened.append("blast %s" % m.member_id)
				1:
					var m: StructureMember = members[rng.randi_range(0, members.size() - 1)]
					if is_instance_valid(m) and not m.broken and not m.burning:
						fire.ignite(m)
						happened.append("fire %s" % m.member_id)
				2:
					var from := Vector3(rng.randf_range(-30, 30), rng.randf_range(0.5, 2.5), rng.randf_range(-20, 5))
					var to := Vector3(rng.randf_range(-30, 30), rng.randf_range(0.2, 3.0), rng.randf_range(-25, 10))
					if not people.is_empty() and rng.randf() < 0.5:
						var p: Node3D = people[rng.randi_range(0, people.size() - 1)]
						if is_instance_valid(p):
							to = p.global_position + Vector3.UP * 1.2
					for k in 3:
						ballistics.fire(from, (to - from).normalized(), gun.muzzle_velocity, gun.bullet_mass, gun.bullet_diameter)
					happened.append("shots")
		await physics_frames(1)
		if tick % 30 == 0:
			_check_world(tick / 60.0)
	_check_world(SECONDS)
	return _digest(happened)


func _check_world(t: float) -> void:
	for n in street.find_children("*", "Node3D", true, false):
		var node := n as Node3D
		if not node.is_inside_tree() or not (node is PhysicsBody3D):
			continue
		var p := node.global_position
		if not (is_finite(p.x) and is_finite(p.y) and is_finite(p.z)):
			_problem("%.1f s: %s isn't anywhere (%s)" % [t, node.name, p])
		elif p.y < FLOOR_Y and not (node is StaticBody3D):
			_problem("%.1f s: %s under the ground (y %.1f)" % [t, node.get_path(), p.y])
		elif Vector2(p.x, p.z).length() > MAP_RADIUS:
			_problem("%.1f s: %s flung off the map (%s)" % [t, node.name, p])
	for n in get_tree().get_nodes_in_group(&"people"):
		var man := n as HumanBody
		if man == null or man.physiology == null:
			continue
		if _dead.has(man.person_id) and man.physiology.alive:
			_problem("%.1f s: %s came back from the dead" % [t, man.person_id])
		if not man.physiology.alive:
			_dead[man.person_id] = true
		if man.physiology.blood_ml < -1.0 or not is_finite(man.physiology.blood_ml):
			_problem("%.1f s: %s has %s ml of blood" % [t, man.person_id, man.physiology.blood_ml])
	for n in street.find_children("*", "StructureMember", true, false):
		var m := n as StructureMember
		if _broken_seen.has(m.member_id) and not m.broken:
			_problem("%.1f s: %s mended itself" % [t, m.member_id])
		if m.broken:
			_broken_seen[m.member_id] = true


func _problem(text: String) -> void:
	if _problems.size() < 12:
		_problems.append(text)


func _digest(happened: Array[String]) -> Dictionary:
	var broken: Array[String] = []
	var burning := 0
	for n in street.find_children("*", "StructureMember", true, false):
		var m := n as StructureMember
		if m.broken:
			broken.append(String(m.member_id))
		if m.burning:
			burning += 1
	broken.sort()
	var people := {}
	for n in get_tree().get_nodes_in_group(&"people"):
		var man := n as HumanBody
		if man and man.physiology:
			people[String(man.person_id)] = [man.physiology.alive, man.wounds.size()]
	return {"log": happened, "broken": broken, "burning": burning, "people": people}


func test_the_world_survives_chaos() -> void:
	var d := await _chaos(1873)
	check(_problems.is_empty(), "no broken invariants: %s" % "; ".join(_problems))
	check(d.log.size() >= 6, "plenty happened (%s)" % ", ".join(d.log))
	check(not d.broken.is_empty(), "timber broke (%d members)" % d.broken.size())
	var hurt: int = d.people.values().filter(func(v: Array) -> bool: return v[1] > 0).size()
	print("    %d events, %d members broken, %d burning, %d people hurt, %d dead" % [d.log.size(), d.broken.size(), d.burning, hurt, _dead.size()])


func test_the_same_seed_gives_the_same_chaos() -> void:
	var first := await _chaos(77)
	await after_each()
	await before_each()
	var second := await _chaos(77)
	check_eq(first.log, second.log, "the same things happened")
	check_eq(first.broken, second.broken, "the same timber broke (%d)" % first.broken.size())
	check_eq(first.people, second.people, "the same people alive and hurt")
	check(_problems.is_empty(), "and no invariant broke: %s" % "; ".join(_problems))
