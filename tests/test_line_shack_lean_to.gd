extends TestCase
## The line shack's lean-to (#1279): what stands out of doors there (the dressing's `out` entries: the
## saddle rack and its three saddles, the woodpile) stands on the ground, not at the shack floor's
## height. Put down 0.32 m in the air they went loose at once and fell; one saddle off the rack crashing
## was "Dutch heard timber", the hideout's alarm before you'd got there (main red from build 5494).

const SpecBuilding := preload("res://src/structures/spec_building.gd")
const OUT := ["Rack", "Saddle1", "Saddle2", "Saddle3", "Wood"]
var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	world.add_child(floor_body)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_the_lean_tos_props_stand_on_the_ground_and_nothing_falls() -> void:
	var sb := SpecBuilding.new()
	sb.spec_path = "res://config/buildings/line_shack.json"
	sb.spec = SpecBuilding.load_spec(sb.spec_path)
	sb.structure_id = &"hideout_shack"
	sb.name = "HideoutShack"
	var noises: Array = []
	var heard := func(at: Vector3, _loud: float, kind: StringName, _src: Node) -> void:
		noises.append([kind, at])
	Events.noise.connect(heard)
	world.add_child(sb)
	await physics_frames(240)
	Events.noise.disconnect(heard)
	for want: String in OUT:
		var p := sb.find_child("HideoutShackDress" + want, true, false) as KitProp
		check(p != null, "the lean-to's %s is there" % want)
		if p:
			check(not p.loose, "the lean-to's %s stands where it's put (not loose)" % want)
	var rack := sb.find_child("HideoutShackDressRack", true, false) as Node3D
	if rack:
		check(absf(rack.global_position.y) < 0.05, "the rack on the ground (y %.2f)" % rack.global_position.y)
	check(noises.filter(func(n: Array) -> bool: return n[0] == &"timber").is_empty(),
			"nothing breaks or crashes as it's built (%s)" % [noises])
