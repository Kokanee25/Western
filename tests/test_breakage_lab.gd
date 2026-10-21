extends TestCase
## The breakage lab (experiments/breakage_lab/): its scenarios read, its bridge commands load, and
## its copy of Blast's rule for a member (runner.gd blast_demand) agrees with what Blast.detonate
## does to that member. The lab measures the game; this keeps it from drifting when the game changes.

const Runner := preload("res://experiments/breakage_lab/runner.gd")

var world: Node3D


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
	world.add_child(Ballistics.new())
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_every_scenario_has_a_definition() -> void:
	var d := Runner.data()
	var names := Runner.names()
	check_eq(names.size(), d.targets.size() * d.weapons.size() + d.extras.size(), "a scenario per target and weapon, and the extras")
	for n: String in names:
		var s := Runner.spec_of(n, d)
		check(not s.is_empty() and s.has("weapon") and s.has("building"), "%s has a target and a weapon" % n)
	check(Runner.spec_of("nothing_here", d).is_empty(), "an unknown name has none")


func test_its_bridge_commands_load() -> void:
	var lab: Variant = load("res://experiments/breakage_lab/bridge.gd").new()
	check(lab is BridgeLab, "bridge.gd is a BridgeLab")
	var cmds: Dictionary = (lab as BridgeLab).commands()
	for c in ["breakage", "breakage_list", "breakage_aim"]:
		check(cmds.has(c) and (lab as Object).has_method("_cmd_" + c), "it answers %s" % c)
	(lab as Node).free()


func test_its_blast_rule_matches_blast() -> void:
	var store := FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	await physics_frames(2)
	# A board in the middle of the left side wall (the store's -x side), a charge 0.3 m outside it
	# at knee height.
	var boards: Array[StructureMember] = []
	for m in store.get_members():
		if String(m.member_id).contains("left/siding"):
			boards.append(m)
	var board: StructureMember = boards[boards.size() / 2] if not boards.is_empty() else null
	check(board != null, "a side board")
	var timber: TimberTuning = load("res://config/timber.tres")
	var near := Runner.blast_demand(board, Vector3(board.global_position.x - 0.3, 0.6, board.global_position.z), 0.2, timber)
	var far := Runner.blast_demand(board, Vector3(board.global_position.x - 4.0, 0.6, board.global_position.z), 0.2, timber)
	check(float(near.ratio) > float(far.ratio), "nearer, harder (%.2f vs %.2f)" % [near.ratio, far.ratio])
	check(float(near.ratio) > 1.0 and not near.bedded, "0.3 m off, the lab says it breaks (%.2f)" % near.ratio)
	Blast.detonate(world, Vector3(board.global_position.x - 0.3, 0.6, board.global_position.z), 0.2)
	await physics_frames(2)
	check(board.broken, "and Blast breaks it (a lone building: its query finds the board)")
